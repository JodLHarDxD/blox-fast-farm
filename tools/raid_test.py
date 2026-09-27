"""Test raid mode's view of the game (raidState): the raid timer (2026 and
older paths) and the newest "Island N" in _WorldOrigin.Locations.

The REAL raidState is cut out of fast_farm.lua every run and run in luau.exe
between raid_stubs.lua and raid_cases.lua.

usage: python tools/raid_test.py [path-to-luau.exe]
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
a = src.index("local function raidState()")
b = src.index("P.raidState = raidState", a)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("raid_stubs.lua") + src[a:b] + read("raid_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
