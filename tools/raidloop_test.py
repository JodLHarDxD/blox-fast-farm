"""Test raid mode's life, real code (user, 2026-10-10): the raid over = stay
where the game put you (stale island markers never flown to, nothing fought
outside a raid); the stuck watch (no HP off for RaidStuckSecs = relocate:
the nearest one THE target, fought where it stands from a new spot, its skip
forgotten - also the straggler outside RaidRadius; inside a fight too); the
loop (a chip for the cheapest stored fruit under the cap via LoadFruit - three
inventory reads; a dearer fruit carried = nothing traded; none = the $100,000
way; level 0 = loop off; the button flown to and clicked; no raid = again
later, you stay).

The REAL code is cut out of fast_farm.lua every run -- the RAID MODE section
and buildRaidPile -- and run in luau.exe between raidloop_stubs.lua and
raidloop_cases.lua.

usage: python tools/raidloop_test.py [path-to-luau.exe]
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


pile = cut("local function buildRaidPile()", "-- ONE AT A TIME, WHERE IT STANDS")
raid = cut("-- RAID MODE\n", "-- ELITE HUNT AND THE SERVER HOP")

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("raidloop_stubs.lua") + pile + "\n" + raid + "\n" + read("raidloop_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
