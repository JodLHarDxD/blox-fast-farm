"""Test water as rock in EVERY mode (user, 2026-10-11: the Legendary Sword
hunt flew them under Kingdom of Rose into the sea - water damage, death):
the line (the sea slab's top + 4, only over the slab, not in the deep sea),
the lock never under it in any mode (a sea fight's own floor if higher),
a body thrown under the water lifted, and a FLIGHT never written under it -
to a point under the water, starting under it, an instant hop; off the slab
and down at Submerged Island nothing changes.

The REAL code is cut out of fast_farm.lua every run (-- BODY: NOCLIP AND THE
LOCK .. the end of TRAVEL) and run in luau.exe between water_stubs.lua and
water_cases.lua.

usage: python tools/water_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"

src = open(os.path.join(HERE, "..", "fast_farm.lua"), encoding="utf-8").read()
SEP = "-- =========================================================\n"
a = src.index("-- BODY: NOCLIP AND THE LOCK\n")
sec = src[a:src.index(SEP + "-- TARGETING", a)]
stubs = open(os.path.join(HERE, "water_stubs.lua"), encoding="utf-8").read()
cases = open(os.path.join(HERE, "water_cases.lua"), encoding="utf-8").read()
with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(stubs + sec + "\n" + cases)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
