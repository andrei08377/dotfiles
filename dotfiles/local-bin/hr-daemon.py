#!/usr/bin/env python3
import asyncio
import subprocess
import sys

from bleak import BleakClient

ADDRESS = "F0:00:E5:CB:61:51"
HR_UUID = "00002a37-0000-1000-8000-00805f9b34fb"
CACHE_FILE = "/home/andrei/.cache/waybar_hr"


def parse_hr(data: bytearray) -> int:
    flags = data[0]
    return int.from_bytes(data[1:3], "little") if flags & 0x1 else data[1]


async def handle_hr(_, data):
    bpm = parse_hr(data)
    with open(CACHE_FILE, "w") as f:
        f.write(str(bpm))
    print(bpm, flush=True)


async def reset_link():
    """Clear a stale BlueZ connection that blocks reconnecting."""
    subprocess.run(["bluetoothctl", "disconnect", ADDRESS], capture_output=True)
    await asyncio.sleep(2)


async def main():
    while True:
        try:
            async with BleakClient(ADDRESS, timeout=20.0) as client:
                print("connected", file=sys.stderr, flush=True)
                await client.start_notify(HR_UUID, handle_hr)
                while client.is_connected:
                    await asyncio.sleep(1)
                print("disconnected", file=sys.stderr, flush=True)
        except asyncio.CancelledError:
            return
        except Exception as e:
            print(f"error: {e}", file=sys.stderr, flush=True)
        with open(CACHE_FILE, "w") as f:
            f.write("--")
        await asyncio.sleep(5)
        await reset_link()


asyncio.run(main())
