"""Test the aim lock's camera solve (rayAim + aimFrame): for every cursor pixel, the line
from the camera through it must land on the pile, with no roll.

The REAL rayAim and aimFrame are cut out of fast_farm.lua every run and run in luau.exe
between aim_stubs.lua (Vector3 / CFrame as plain matrices, Roblox's
conventions) and aim_cases.lua.

usage: python tools/aim_test.py [path-to-luau.exe]
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
a = src.index("local function rayAim(")
b = src.index("-- Turn the camera so the line through the cursor", a)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("aim_stubs.lua") + src[a:b] + read("aim_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
