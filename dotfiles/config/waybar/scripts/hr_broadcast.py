#!/usr/bin/env python3
import asyncio, os
from bleak import BleakClient

WATCH_ADDR = "F0:00:E5:CB:61:51"
HR_UUID = "00002a37-0000-1000-8000-00805f9b34fb"
OUT_FILE = os.path.expanduser("~/.cache/waybar_hr")

def parse_hr(data: bytearray) -> int:
    flags = data[0]
    return int.from_bytes(data[1:3], "little") if flags & 0x1 else data[1]

async def handle_hr(_, data):
    bpm = parse_hr(data)
    with open(OUT_FILE, "w") as f:
        f.write(str(bpm))

async def main():
    while True:
        try:
            async with BleakClient(WATCH_ADDR) as client:
                await client.start_notify(HR_UUID, handle_hr)
                while client.is_connected:
                    await asyncio.sleep(1)
        except Exception:
            with open(OUT_FILE, "w") as f:
                f.write("--")
            await asyncio.sleep(5)

asyncio.run(main())
