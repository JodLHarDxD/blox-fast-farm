"""Test THE FRUIT GUARD: a physical fruit is never listed as a weapon, never
found to equip, and never clicked while in your hand - a click EATS it and
replaces your fruit (user's main account). The real code is cut out of
fast_farm.lua every run and run in luau.exe.

usage: python tools/fruitguard_test.py [path-to-luau.exe]
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
a = src.index("-- A PHYSICAL FRUIT")
b = src.index('-- "Blox Fruit", "Melee"', a)
c = src.index("local function pressM1()")
d = src.index("-- =========================================================", c)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("fruitguard_stubs.lua") + src[a:b] + src[c:d] + read("fruitguard_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
