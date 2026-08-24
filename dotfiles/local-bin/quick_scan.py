import asyncio
from bleak import BleakScanner

async def main():
    print("Scanez 5 secunde...")
    devices = await BleakScanner.discover(timeout=5.0)
    if not devices:
        print("Nimic găsit.")
    for d in devices:
        print(d.address, "-", d.name)

asyncio.run(main())
