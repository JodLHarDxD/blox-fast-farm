"""Test the sea hunt and the volcano event: the meters from the Tiki dealer,
the heading and the turn, the wheel (speed, cap, water line, knocked off,
stopped, boat gone), the hunt's steps (buy at the back dealer, sit, sail, the
far edge = the next server, the boat lost far out / near Tiki, the island up =
off the boat and held there), the event's phases (start at the relic, defend,
loot, idle), the vents (four live signs, fruit first, aimed at the vent, a key
that does not fire left out, an aimed M1 when all cool, closed = counted), the
golems (held in the cage while vents close, the fight broken by a vent, magnet
off = golems first, counted once), the lava taken off, the bones and the egg.

The REAL code is cut out of fast_farm.lua every run -- the SEA HUNT section --
and run in luau.exe between sea_stubs.lua and sea_cases.lua.

usage: python tools/sea_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"


def read(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read()


src = read(os.path.join("..", "fast_farm.lua"))


def cut(start, end):
    a = src.index(start)
    return src[a:src.index(end, a)]


sea = cut("-- SEA HUNT\n", "-- MAIN LOOP\n")

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("sea_stubs.lua") + "local function SECTION()\n" + sea + "\nend\n" + read("sea_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
