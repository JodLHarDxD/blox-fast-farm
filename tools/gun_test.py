"""Test THE GUN (held like a player, past the heat, the mastery farm) offline.

The REAL "THE GUN: HELD LIKE A PLAYER" section is cut out of fast_farm.lua every
run and sandwiched between gun_stubs.lua (the game, faked: a clock, a pile, a
tool with the game's own attributes, the mouse button, WeaponData and the
CombatController's upvalues) and gun_cases.lua, then run in luau.exe.

usage: python tools/gun_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
SEP = "-- =========================================================\n"


def read(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read()


src = read(os.path.join("..", "fast_farm.lua"))
a = src.rfind(SEP, 0, src.index("-- THE GUN: HELD LIKE A PLAYER"))
b = src.rfind(SEP, 0, src.index("-- HAKI, AND WHAT A DEATH TAKES WITH IT"))

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("gun_stubs.lua") + src[a:b] + read("gun_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
