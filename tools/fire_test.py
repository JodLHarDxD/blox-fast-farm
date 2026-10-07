"""Test where fireM1 sends each M1 way (remote / click / hold / gunshot / keys).

The REAL block from "local fireM1" to "local function describeWay" is cut out
of fast_farm.lua every run and sandwiched between fire_stubs.lua and
fire_cases.lua, then run in luau.exe. (2026-10-07: an edit adding the gun ways
dropped the fruit-click branch and no test noticed.)

usage: python tools/fire_test.py [path-to-luau.exe]
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
a = src.index("local fireM1\n")
b = src.index("local function describeWay(", a)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("fire_stubs.lua") + src[a:b] + read("fire_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
