"""Step 2: Download songs listed in songs.csv via @deezload2bot.

Reads queries from the CSV, performs inline search to get Deezer track IDs,
sends deezer.com/track/{id} links, and downloads the resulting FLACs.

Usage:
    python download.py [path/to/songs.csv]
"""

import asyncio
import csv
import sys
from pathlib import Path

from telethon import TelegramClient
from telethon.sessions import StringSession

BOT_USERNAME = "deezload2bot"
CSV_PATH = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp/deezload/songs.csv")
OUTPUT_DIR = Path.home() / "downloads"
TIMEOUT = 60
DELAY_BETWEEN = 3

API_ID = 35254495
API_HASH = "7becc048b8b6e23e62f4dfeedc13d75f"
SESSION = "1BJWap1sBu5TQhFoqFofJItsujtxXoVmClSnwJhOapecMb1mpINwN9FeU5t9CtyAgx9rA609vTNxVX00gWCx4gNGqqdBgCro-tK3-Yy2olJGmL__1EuaRrhowGMW3FGa-ZzoZ3vWlkgUdZ69J93mtFgKCEo2xma9jOnEE5gT3seeUeul58fvpyNzwPS5WidS-f5WBuTcI1w2-YfatfW8R7vY7b0jsjfWCL1wLgycEmwXM_tikNMeIM_WU7U2nemx-XXjs3GgD-3JK1Bwq4pY63fKBsqoBZlzAM80aPV4x-kRueScsOo4R4r3D9fuvK3sHgu5vePWHJaTWS7FKjfpLfNmSrZysvpM="


async def download_song(client, bot, query: str, output_dir: Path) -> bool:
    print(f"  Searching: {query}", flush=True)

    try:
        results = await client.inline_query(bot, query)
    except Exception as e:
        print(f"  Inline query failed: {e}", file=sys.stderr, flush=True)
        return False

    if not results:
        print(f"  No results found", file=sys.stderr, flush=True)
        return False

    track_id = results[0].result.id
    title = getattr(results[0].result, "title", "?")
    desc = getattr(results[0].result, "description", "")
    print(f"  Found: {title} ({desc}) [id={track_id}]", flush=True)

    deezer_link = f"https://www.deezer.com/track/{track_id}"
    await client.send_message(bot, deezer_link)

    start = asyncio.get_event_loop().time()
    while asyncio.get_event_loop().time() - start < TIMEOUT:
        await asyncio.sleep(3)
        messages = await client.get_messages(bot, limit=3)
        for msg in messages:
            if msg.out:
                continue
            if msg.audio or msg.document:
                media = msg.audio or msg.document
                file_name = None
                for attr in media.attributes:
                    if hasattr(attr, "file_name"):
                        file_name = attr.file_name
                if not file_name:
                    file_name = f"{query}.flac"
                path = await client.download_media(msg, file=str(output_dir / file_name))
                print(f"  Downloaded: {path}", flush=True)
                return True

    print(f"  Timed out waiting for file", file=sys.stderr, flush=True)
    return False


async def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with open(CSV_PATH) as fh:
        queries = [row["query"] for row in csv.DictReader(fh)]

    print(f"Loaded {len(queries)} songs from {CSV_PATH}\n", flush=True)

    client = TelegramClient(StringSession(SESSION), API_ID, API_HASH)
    await client.start()

    try:
        bot = await client.get_entity(BOT_USERNAME)
        succeeded = 0
        failed = []

        for i, query in enumerate(queries, 1):
            print(f"[{i}/{len(queries)}]", flush=True)
            ok = await download_song(client, bot, query, OUTPUT_DIR)
            if ok:
                succeeded += 1
            else:
                failed.append(query)
            await asyncio.sleep(DELAY_BETWEEN)

        print(f"\nDone: {succeeded}/{len(queries)} downloaded", flush=True)
        if failed:
            print(f"\nFailed ({len(failed)}):", flush=True)
            for q in failed:
                print(f"  - {q}", flush=True)
    finally:
        await client.disconnect()


if __name__ == "__main__":
    asyncio.run(main())
