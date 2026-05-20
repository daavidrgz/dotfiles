---
name: outline-second-brain
description: >
  Operate David's Outline workspace as a living second brain. This skill should be used in
  virtually EVERY conversation. Use it whenever: the user mentions "brain" followed by a command
  (save, capture, person, daily, ingest, find, recap, challenge); the conversation produces
  information worth preserving (decisions made, people met, projects discussed, tasks completed,
  lessons learned, ideas worth keeping); the user asks to search, review, or reflect on past
  notes, ideas, or decisions; the user discusses work, projects, goals, people, or strategies;
  the user asks Claude to remember, note, or save anything; the user mentions Outline, notes,
  or knowledge management; or the conversation reaches 10+ substantive exchanges without saving.
  When in doubt, USE this skill — unsaved knowledge is lost knowledge. This skill connects to
  Outline via MCP tools (Outline:create_document, Outline:list_documents, Outline:update_document).
---

# Outline Second Brain

> Claude operates David's Outline workspace as a living knowledge OS.
> Everything worth remembering gets saved. Every update propagates everywhere it belongs.

---

## Brain Structure in Outline

**Collection:** 🧠 Brain (`9b1f6f9e-94ea-4b19-a1ba-b5b5a6179e32`)

| Document | ID | Purpose |
|---|---|---|
| **Index** | `d812d13c-4092-4c6c-aeb7-f1ec1bf936f3` | Catalog of all pages. Read FIRST to navigate. |
| **Log** | `7b37d0fa-b98f-452f-9411-1a3c485c6d44` | Chronological operation log. Append-only. |
| **Entities** | `1a0fd09a-d4bc-4e6d-b952-c052bf29d6ee` | People, companies, tools |
| **Concepts** | `84cb3807-097c-4acf-9480-3d43878d5c46` | Ideas, frameworks, methodologies |
| **Projects** | `38411d87-39aa-4c13-aa3b-4f03b94f4e28` | Active and archived projects |
| **Decisions** | `7d8dbde8-590d-473e-8384-a4da8d3c3b67` | Decision records (ADRs) |
| **Daily** | `c371546c-2943-40cd-a780-2af99bd8a137` | Daily notes |
| **Sources** | `c01b48bd-ddda-4cdd-9794-ca68fad95840` | Ingested source material (immutable) |

New documents are **nested under their section** using `parentDocumentId`.

**Other collections** (reference only, don't move content):
Work (Omnia), Personal, Side Projects, Server, Jobs.

---

## Core Principles

### 1. Never create in isolation
Every new doc links from: Index, today's Daily, and any related entity/project. Zero orphans.

### 2. Search before creating
`Outline:list_documents(query="...")` before any create. Duplicates are brain rot.

### 3. Two-output rule
Every insight produces: (1) the chat answer, (2) a brain update.

### 4. Bi-temporal facts
When a fact changes, NEVER delete old. Append new with dates:
```
## Historial
- 2024-01 → 2026-03: CTO en Acme Corp
- 2026-04 → presente: Architect en Acme Corp (aprendido: 2026-04-07)
```

### 5. Log everything
Every operation → append to Log: `## YYYY-MM-DD action | Description`

### 6. Keep Index current
After any create/delete, update the relevant Index section.

---

## Commands

### `brain save`
Scan the entire conversation. Extract all vault-worthy items: decisions, tasks, people, ideas, learnings. Create/update docs in correct sections (search first). Update Index, Log, and Daily.

### `brain capture [idea]`
Quick idea capture. Search Concepts for similar. Create new nested under Concepts or update existing. Update Index and Daily.

### `brain person [name]`
Create or update entity nested under Entities. Fill: role, company, context, interactions. Update Index and Daily.

### `brain daily`
Create or update today's note nested under Daily. Sections: Activity, People, Decisions, Ideas.

### `brain ingest [URL or text]`
Fetch source → extract entities, concepts, claims → save original under Sources (immutable) → **REWRITE existing docs** with new info → update Index, Log, Daily. Brain must be DIFFERENT after, not just bigger.

### `brain find [query]`
Search brain with `Outline:list_documents(query="...")`. Return results with context.

### `brain recap [today|week|month]`
Read Daily notes for period. Synthesize narrative summary.

### `brain challenge [idea]`
Red-team: search brain for counter-evidence, past failures, contradictions. Cite specific docs. Do NOT be agreeable.

---

## Propagation Table

| Event | Also update |
|---|---|
| New project | Projects + Index + Daily |
| New person | Entities + Index + Daily |
| Decision made | Decisions + relevant project + Daily |
| Idea captured | Concepts + Index + Daily |
| Source ingested | Sources + affected entities/concepts + Index + Log + Daily |
| Any write | Log (always) |

---

## Proactive Behavior

- After 10+ productive exchanges → suggest `brain save`
- When user signals wrap-up ("ok", "thanks", "done") → suggest saving
- When a work block completes → suggest saving
- When conversation mentions a person, project, or decision already in the brain → reference it
- Never skip reminders — unsaved conversations are lost knowledge

---

## Document Formats

See `references/formats.md` for full templates. Quick reference:

**Entity:** Type, Role, Company, Last interaction, Context, Historial, Interactions
**Concept:** Estado (active/graduated/archived), Description, Connections
**Project:** Estado (active/planning/completed/archived/on-hold), Description, Key decisions, Recent activity
**Daily:** Date, Activity, People, Decisions, Ideas
**Source:** Type, URL, Ingestion date, Summary, Key extracts (IMMUTABLE after creation)
**Decision:** Estado (accepted/superseded/deprecated), Decision, Context, Options, Rationale, Consequences

---

## Outline MCP Tools

- `Outline:list_documents(query?, collectionId?, limit?)` — Search/list docs
- `Outline:create_document(title, text?, collectionId?, parentDocumentId?, icon?)` — Create doc
- `Outline:update_document(id, text?, title?, editMode?)` — Update doc. Use `editMode: "append"` for Log and Daily.
- `Outline:list_collections()` — List collections
- `Outline:move_document(id, collectionId?, parentDocumentId?)` — Move doc

Always use `parentDocumentId` to nest under the correct section.
Always use `editMode: "append"` on Log and Daily notes.
