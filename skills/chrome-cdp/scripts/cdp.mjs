#!/usr/bin/env bun
// cdp - lightweight Chrome DevTools Protocol CLI
// Requires Node 22+ (built-in WebSocket and fetch).
// Requires Chrome launched with --remote-debugging-port=<port> (default 9222).
// Override port with CDP_PORT env var.

import { writeFileSync } from 'fs';

const PORT = process.env.CDP_PORT || '9222';
const HOST = '127.0.0.1';
const HTTP_BASE = `http://${HOST}:${PORT}`;
const TIMEOUT = 15000;
const NAVIGATION_TIMEOUT = 30000;
const MIN_TARGET_PREFIX_LEN = 8;

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

// ---------------------------------------------------------------------------
// Target discovery (HTTP)
// ---------------------------------------------------------------------------

async function fetchPages() {
  let res;
  try {
    res = await fetch(`${HTTP_BASE}/json/list`);
  } catch {
    throw new Error(`Cannot reach Chrome at ${HTTP_BASE}. Launch Chrome with --remote-debugging-port=${PORT} (override via CDP_PORT).`);
  }
  const targets = await res.json();
  return targets.filter(t => t.type === 'page' && !t.url.startsWith('chrome://'));
}

function resolvePrefix(prefix, pages) {
  if (!prefix) throw new Error('Target ID prefix required. Run "cdp list" first.');
  const upper = prefix.toUpperCase();
  const matches = pages.filter(p => p.id.toUpperCase().startsWith(upper));
  if (matches.length === 0) throw new Error(`No target matching prefix "${prefix}". Run "cdp list".`);
  if (matches.length > 1) throw new Error(`Ambiguous prefix "${prefix}" — matches ${matches.length} targets. Use more characters.`);
  return matches[0];
}

function displayPrefixLength(ids) {
  if (!ids.length) return MIN_TARGET_PREFIX_LEN;
  const maxLen = Math.max(...ids.map(id => id.length));
  for (let len = MIN_TARGET_PREFIX_LEN; len <= maxLen; len++) {
    if (new Set(ids.map(id => id.slice(0, len).toUpperCase())).size === ids.length) return len;
  }
  return maxLen;
}

function formatPageList(pages) {
  const len = displayPrefixLength(pages.map(p => p.id));
  return pages.map(p => {
    const id = p.id.slice(0, len).padEnd(len);
    const title = (p.title || '').substring(0, 54).padEnd(54);
    return `${id}  ${title}  ${p.url}`;
  }).join('\n');
}

// ---------------------------------------------------------------------------
// CDP WebSocket client (one connection per command, bound to a page)
// ---------------------------------------------------------------------------

class CDP {
  #ws; #id = 0; #pending = new Map(); #eventHandlers = new Map();

  async connect(wsUrl) {
    return new Promise((res, rej) => {
      this.#ws = new WebSocket(wsUrl);
      this.#ws.onopen = () => res();
      this.#ws.onerror = (e) => rej(new Error('WebSocket error: ' + (e.message || e.type)));
      this.#ws.onmessage = (ev) => {
        const msg = JSON.parse(ev.data);
        if (msg.id && this.#pending.has(msg.id)) {
          const { resolve, reject } = this.#pending.get(msg.id);
          this.#pending.delete(msg.id);
          if (msg.error) reject(new Error(msg.error.message));
          else resolve(msg.result);
        } else if (msg.method && this.#eventHandlers.has(msg.method)) {
          for (const h of [...this.#eventHandlers.get(msg.method)]) h(msg.params || {});
        }
      };
    });
  }

  send(method, params = {}) {
    const id = ++this.#id;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        if (this.#pending.has(id)) { this.#pending.delete(id); reject(new Error(`Timeout: ${method}`)); }
      }, TIMEOUT);
      this.#pending.set(id, {
        resolve: (v) => { clearTimeout(timer); resolve(v); },
        reject:  (e) => { clearTimeout(timer); reject(e); },
      });
      this.#ws.send(JSON.stringify({ id, method, params }));
    });
  }

  onEvent(method, handler) {
    if (!this.#eventHandlers.has(method)) this.#eventHandlers.set(method, new Set());
    const set = this.#eventHandlers.get(method);
    set.add(handler);
    return () => { set.delete(handler); if (!set.size) this.#eventHandlers.delete(method); };
  }

  waitForEvent(method, timeout = TIMEOUT) {
    let off, timer, settled = false;
    const promise = new Promise((resolve, reject) => {
      off = this.onEvent(method, (p) => { if (settled) return; settled = true; clearTimeout(timer); off(); resolve(p); });
      timer = setTimeout(() => { if (settled) return; settled = true; off(); reject(new Error(`Timeout: ${method}`)); }, timeout);
    });
    return { promise, cancel() { if (settled) return; settled = true; clearTimeout(timer); off?.(); } };
  }

  close() { this.#ws?.close(); }
}

async function connectToPage(pageId) {
  const cdp = new CDP();
  await cdp.connect(`ws://${HOST}:${PORT}/devtools/page/${pageId}`);
  return cdp;
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

function shouldShowAxNode(node, compact) {
  const role = node.role?.value || '';
  const name = node.name?.value ?? '';
  const value = node.value?.value;
  if (compact && role === 'InlineTextBox') return false;
  return role !== 'none' && role !== 'generic' && !(name === '' && (value === '' || value == null));
}

function formatAxNode(node, depth) {
  const role = node.role?.value || '';
  const name = node.name?.value ?? '';
  const value = node.value?.value;
  const indent = '  '.repeat(Math.min(depth, 10));
  let line = `${indent}[${role}]`;
  if (name !== '') line += ` ${name}`;
  if (!(value === '' || value == null)) line += ` = ${JSON.stringify(value)}`;
  return line;
}

async function cmdSnap(cdp) {
  const { nodes } = await cdp.send('Accessibility.getFullAXTree');
  const nodesById = new Map(nodes.map(n => [n.nodeId, n]));
  const childrenByParent = new Map();
  for (const n of nodes) {
    if (!n.parentId) continue;
    if (!childrenByParent.has(n.parentId)) childrenByParent.set(n.parentId, []);
    childrenByParent.get(n.parentId).push(n);
  }
  const lines = [];
  const visited = new Set();
  function visit(node, depth) {
    if (!node || visited.has(node.nodeId)) return;
    visited.add(node.nodeId);
    if (shouldShowAxNode(node, true)) lines.push(formatAxNode(node, depth));
    const seen = new Set();
    const children = [];
    for (const cid of node.childIds || []) {
      const c = nodesById.get(cid);
      if (c && !seen.has(c.nodeId)) { seen.add(c.nodeId); children.push(c); }
    }
    for (const c of childrenByParent.get(node.nodeId) || []) {
      if (!seen.has(c.nodeId)) { seen.add(c.nodeId); children.push(c); }
    }
    for (const c of children) visit(c, depth + 1);
  }
  const roots = nodes.filter(n => !n.parentId || !nodesById.has(n.parentId));
  for (const r of roots) visit(r, 0);
  for (const n of nodes) visit(n, 0);
  return lines.join('\n');
}

async function cmdEval(cdp, expression) {
  if (!expression) throw new Error('expression required');
  await cdp.send('Runtime.enable');
  const result = await cdp.send('Runtime.evaluate', {
    expression, returnByValue: true, awaitPromise: true,
  });
  if (result.exceptionDetails) {
    throw new Error(result.exceptionDetails.text || result.exceptionDetails.exception?.description);
  }
  const val = result.result.value;
  return typeof val === 'object' ? JSON.stringify(val, null, 2) : String(val ?? '');
}

async function cmdShot(cdp, filePath) {
  let dpr = 1;
  try {
    const raw = await cmdEval(cdp, 'window.devicePixelRatio');
    const parsed = parseFloat(raw);
    if (parsed > 0) dpr = parsed;
  } catch {}
  const { data } = await cdp.send('Page.captureScreenshot', { format: 'png' });
  const out = filePath || '/tmp/screenshot.png';
  writeFileSync(out, Buffer.from(data, 'base64'));
  const lines = [out, `Screenshot saved. Device pixel ratio (DPR): ${dpr}`, 'Coordinate mapping:'];
  lines.push(`  Screenshot pixels → CSS pixels (for CDP Input events): divide by ${dpr}`);
  lines.push(`  e.g. screenshot point (${Math.round(100 * dpr)}, ${Math.round(200 * dpr)}) → CSS (100, 200) → use clickxy <target> 100 200`);
  if (dpr !== 1) lines.push(`  On this ${dpr}x display: CSS px = screenshot px / ${dpr}`);
  return lines.join('\n');
}

async function cmdHtml(cdp, selector) {
  const expr = selector
    ? `document.querySelector(${JSON.stringify(selector)})?.outerHTML || 'Element not found'`
    : `document.documentElement.outerHTML`;
  return cmdEval(cdp, expr);
}

async function waitForDocumentReady(cdp, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let lastState = '';
  while (Date.now() < deadline) {
    try {
      const state = await cmdEval(cdp, 'document.readyState');
      lastState = state;
      if (state === 'complete') return;
    } catch {}
    await sleep(200);
  }
  throw new Error(`Timed out waiting for navigation (last readyState: ${lastState || 'unknown'})`);
}

async function cmdNav(cdp, url) {
  if (!url) throw new Error('URL required');
  await cdp.send('Page.enable');
  const loadEvent = cdp.waitForEvent('Page.loadEventFired', NAVIGATION_TIMEOUT);
  const result = await cdp.send('Page.navigate', { url });
  if (result.errorText) { loadEvent.cancel(); throw new Error(result.errorText); }
  if (result.loaderId) await loadEvent.promise;
  else loadEvent.cancel();
  await waitForDocumentReady(cdp, 5000);
  return `Navigated to ${url}`;
}

async function cmdNet(cdp) {
  const raw = await cmdEval(cdp, `JSON.stringify(performance.getEntriesByType('resource').map(e => ({
    name: e.name.substring(0, 120), type: e.initiatorType,
    duration: Math.round(e.duration), size: e.transferSize
  })))`);
  return JSON.parse(raw).map(e =>
    `${String(e.duration).padStart(5)}ms  ${String(e.size || '?').padStart(8)}B  ${e.type.padEnd(8)}  ${e.name}`
  ).join('\n');
}

async function cmdClick(cdp, selector) {
  if (!selector) throw new Error('CSS selector required');
  const result = await cmdEval(cdp, `
    (function() {
      const el = document.querySelector(${JSON.stringify(selector)});
      if (!el) return { ok: false, error: 'Element not found: ' + ${JSON.stringify(selector)} };
      el.scrollIntoView({ block: 'center' });
      el.click();
      return { ok: true, tag: el.tagName, text: el.textContent.trim().substring(0, 80) };
    })()`);
  const r = JSON.parse(result);
  if (!r.ok) throw new Error(r.error);
  return `Clicked <${r.tag}> "${r.text}"`;
}

async function cmdClickXy(cdp, x, y) {
  const cx = parseFloat(x), cy = parseFloat(y);
  if (isNaN(cx) || isNaN(cy)) throw new Error('x and y must be numbers (CSS pixels)');
  const base = { x: cx, y: cy, button: 'left', clickCount: 1, modifiers: 0 };
  await cdp.send('Input.dispatchMouseEvent', { ...base, type: 'mouseMoved' });
  await cdp.send('Input.dispatchMouseEvent', { ...base, type: 'mousePressed' });
  await sleep(50);
  await cdp.send('Input.dispatchMouseEvent', { ...base, type: 'mouseReleased' });
  return `Clicked at CSS (${cx}, ${cy})`;
}

async function cmdType(cdp, text) {
  if (!text) throw new Error('text required');
  await cdp.send('Input.insertText', { text });
  return `Typed ${text.length} characters`;
}

async function cmdLoadAll(cdp, selector, intervalMs) {
  if (!selector) throw new Error('CSS selector required');
  let clicks = 0;
  const deadline = Date.now() + 5 * 60 * 1000;
  while (Date.now() < deadline) {
    const exists = await cmdEval(cdp, `!!document.querySelector(${JSON.stringify(selector)})`);
    if (exists !== 'true') break;
    const clicked = await cmdEval(cdp, `
      (function() {
        const el = document.querySelector(${JSON.stringify(selector)});
        if (!el) return false;
        el.scrollIntoView({ block: 'center' });
        el.click();
        return true;
      })()`);
    if (clicked !== 'true') break;
    clicks++;
    await sleep(intervalMs);
  }
  return `Clicked "${selector}" ${clicks} time(s) until it disappeared`;
}

async function cmdEvalRaw(cdp, method, paramsJson) {
  if (!method) throw new Error('CDP method required (e.g. "DOM.getDocument")');
  let params = {};
  if (paramsJson) {
    try { params = JSON.parse(paramsJson); }
    catch { throw new Error(`Invalid JSON params: ${paramsJson}`); }
  }
  return JSON.stringify(await cdp.send(method, params), null, 2);
}

// ---------------------------------------------------------------------------
// CLI dispatch
// ---------------------------------------------------------------------------

const USAGE = `cdp - lightweight Chrome DevTools Protocol CLI (no Puppeteer)

Setup: Chrome must be launched with --remote-debugging-port=9222
       (override port via CDP_PORT env var).
       The default Chrome profile silently ignores this flag — use a
       dedicated --user-data-dir.

Usage: cdp <command> [args]

  list                              List open pages (shows unique target prefixes)
  snap    <target>                  Accessibility tree snapshot
  eval    <target> <expr>           Evaluate JS expression
  shot    <target> [file]           Screenshot (default /tmp/screenshot.png); prints DPR
  html    <target> [selector]       Full page or element HTML
  nav     <target> <url>            Navigate and wait for load
  net     <target>                  Network resource timing entries
  click   <target> <selector>       Click element by CSS selector
  clickxy <target> <x> <y>          Click at CSS pixel coordinates
  type    <target> <text>           Type text via Input.insertText (works in cross-origin iframes)
  loadall <target> <selector> [ms]  Click "load more" until gone (default 1500ms between clicks)
  evalraw <target> <method> [json]  Send arbitrary CDP command; returns JSON

<target> is a unique targetId prefix from "cdp list".

COORDINATE SYSTEM
  shot captures the viewport at native resolution: image px = CSS px × DPR.
  CDP Input events take CSS pixels: CSS px = screenshot px / DPR.
  shot prints the DPR for the current page.

EVAL SAFETY
  Avoid index-based selection (querySelectorAll(...)[i]) across multiple eval calls
  when the DOM can change between them. Use stable selectors or collect data in one eval.
`;

const PAGE_COMMANDS = {
  snap:    (cdp)                 => cmdSnap(cdp),
  eval:    (cdp, [expr])         => cmdEval(cdp, expr),
  shot:    (cdp, [file])         => cmdShot(cdp, file),
  html:    (cdp, [selector])     => cmdHtml(cdp, selector),
  nav:     (cdp, [url])          => cmdNav(cdp, url),
  net:     (cdp)                 => cmdNet(cdp),
  click:   (cdp, [sel])          => cmdClick(cdp, sel),
  clickxy: (cdp, [x, y])         => cmdClickXy(cdp, x, y),
  type:    (cdp, [text])         => cmdType(cdp, text),
  loadall: (cdp, [sel, ms])      => cmdLoadAll(cdp, sel, ms ? parseInt(ms) : 1500),
  evalraw: (cdp, [method, json]) => cmdEvalRaw(cdp, method, json),
};

// Commands whose final argument can contain spaces — join trailing args.
const JOIN_TAIL = new Set(['eval', 'type', 'evalraw']);

async function main() {
  const [cmd, ...args] = process.argv.slice(2);

  if (!cmd || cmd === 'help' || cmd === '--help' || cmd === '-h') {
    console.log(USAGE); return;
  }

  if (cmd === 'list' || cmd === 'ls') {
    const pages = await fetchPages();
    console.log(formatPageList(pages));
    return;
  }

  const handler = PAGE_COMMANDS[cmd];
  if (!handler) { console.error(`Unknown command: ${cmd}\n`); console.log(USAGE); process.exit(1); }

  const [targetPrefix, ...cmdArgs] = args;
  const pages = await fetchPages();
  const page = resolvePrefix(targetPrefix, pages);

  // For commands where the trailing arg can contain spaces, join from index 1 onward
  // (index 0 stays as-is — e.g. for evalraw, method name; for loadall, selector).
  if (JOIN_TAIL.has(cmd) && cmdArgs.length > 1) {
    if (cmd === 'eval' || cmd === 'type') cmdArgs[0] = cmdArgs.join(' ');
    else if (cmd === 'evalraw') cmdArgs[1] = cmdArgs.slice(1).join(' ');
  }

  const cdp = await connectToPage(page.id);
  try {
    const result = await handler(cdp, cmdArgs);
    if (result) console.log(result);
  } finally {
    cdp.close();
  }
}

main().catch(e => { console.error(e.message); process.exit(1); });
