"""Test the pure FIGHT WITH helpers (Plan 2 R2): fightPick, fightGoalDone, fightLabel.
The real block is cut out of fast_farm.lua every run and run in luau.exe.

usage: python tools/fightwith_test.py [path-to-luau.exe]
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
a = src.index("-- PACKS (2026-11-22)")
b = src.index("-- PACKS END", a)

# the engine block: P.fightWeapon / P.weaponsFor / P.fightGoalTick, as shipped
ea = src.index("-- FIGHT WITH (Plan 2 R2, 2026-11-22): ONE decider per mode")
ea = src.index("\ndo\n", ea) + 1
eb = src.index("-- The weapons that are on AND in your backpack", ea)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("packs_stubs.lua") + read("fightwith_stubs.lua") + src[a:b] + src[ea:eb]
            + read("fightwith_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
