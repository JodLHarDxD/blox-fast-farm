"""Test the sea events hunt: the HP text, the names (Terrorshark / Piranha /
Shark / every ship raid), the groups (five piranhas = one event, three beasts =
Rumbling Waters = one), the kill verdict (HP 0, gone at 10% or less; despawned
= not counted), the count kept across sessions, the Spy only ever asked, the
goal, the patrol circle and the compass nudge, sailing away from a ship raid,
the beast fight (off the seat, the boat held up, 90 over it, the aim on its
body, in close after 6 s of nothing, waiting over a dive), the fish fight (the
farm's own, M1 + every skill, in place), whose M1 hurts a beast, a lost boat.

The REAL code is cut out of fast_farm.lua every run -- the SEA EVENTS section
-- and run in luau.exe between seaev_stubs.lua and seaev_cases.lua.

usage: python tools/seaev_test.py [path-to-luau.exe]
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


sec = cut("-- SEA EVENTS\n", "-- SERVER NEWS\n")

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("seaev_stubs.lua") + "local function SECTION()\n" + sec + "\nend\n" + read("seaev_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
