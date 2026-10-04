"""Test the weapon rotation: every weapon you carry (M1 with a fighting
style, AutoKeys of all), the next sword / gun from the inventory (LoadItem:
never-loaded first, then loaded longest ago; not carried, not switched off,
not failed lately, rested), the gap, the volcano asking in any mode, what you
carried put back at the stop - and the saved learned-keys cleaner. The REAL
sections are cut out of fast_farm.lua (-- WEAPON ROTATION, -- LEARNED KEYS, KEPT).

usage: python tools/rotate_test.py [path-to-luau.exe]
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
a = src.index("-- WEAPON ROTATION\n")
rot = src[a:src.index(SEP + "-- M1: THREE WAYS", a)]
b = src.index("-- LEARNED KEYS, KEPT\n")
learn = src[b:src.index(SEP + "-- MAIN LOOP", b)]
stubs = open(os.path.join(HERE, "rotate_stubs.lua"), encoding="utf-8").read()
cases = open(os.path.join(HERE, "rotate_cases.lua"), encoding="utf-8").read()
# The learn section: no files on this "executor" (it only defines the cleaner).
learn_stubs = "local game = { GetService = function() return {} end }\nlocal readfile, isfile, writefile = nil, nil, nil\nlocal _G = {}\n"
with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(stubs + rot + "\n" + learn_stubs + learn + "\n" + cases)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
