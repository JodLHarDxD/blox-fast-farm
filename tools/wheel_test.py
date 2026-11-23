"""Test the Attack wheel's pure parts (R3 Task 3): fightType / fightWeapons (only
real fight weapons), wheelShown (5 most used + "+N" past 6), wheelLayout
(labels never overlap each other, MIX or the dial, and stay in the box).
The real block is cut out of fast_farm.lua every run and run in luau.exe.

usage: python tools/wheel_test.py [path-to-luau.exe]
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

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("packs_stubs.lua") + src[a:b] + read("wheel_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
