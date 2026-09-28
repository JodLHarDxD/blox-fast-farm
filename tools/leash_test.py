"""Test the leash measurement in checkPutBack: a pulled enemy that stops
taking damage while one pulled from nearer its spawn still takes it sets the
limit for its kind; no contrast, no limit.

The REAL checkPutBack is cut out of fast_farm.lua every run and run in
luau.exe between leash_stubs.lua and leash_cases.lua.

usage: python tools/leash_test.py [path-to-luau.exe]
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
a = src.index("local function checkPutBack()")
b = src.index("-- Where skills are aimed", a)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("leash_stubs.lua") + src[a:b] + read("leash_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
