#!/usr/bin/env python3
import asyncio
import sys
from bleak import BleakClient

ADDRESS = "F0:00:E5:CB:61:51"
HR_UUID = "00002a37-0000-1000-8000-00805f9b34fb"

def parse_hr(data: bytearray) -> int:
    flags = data[0]
    return int.from_bytes(data[1:3], "little") if flags & 0x1 else data[1]

async def handle_hr(_, data):
    print(f"puls: {parse_hr(data)} bpm", flush=True)

async def main():
    while True:
        try:
            async with BleakClient(ADDRESS) as client:
                print("Conectat. Aștept date...", flush=True)
                await client.start_notify(HR_UUID, handle_hr)
                while client.is_connected:
                    await asyncio.sleep(1)
        except asyncio.CancelledError:
            raise
        except Exception as e:
            print(f"Deconectat ({e}), încerc din nou în 5s...", file=sys.stderr, flush=True)
            await asyncio.sleep(5)

asyncio.run(main())
