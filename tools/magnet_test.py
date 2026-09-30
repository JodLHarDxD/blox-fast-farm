"""Test the magnet's frame (magnetTick): every pulled enemy is frozen the way
the public hubs freeze theirs, and each keeps its own place on the ring for
as long as it is in the pile.

The REAL magnetTick is cut out of fast_farm.lua every run -- from "Every
frame, after physics." to "WHY NO DAMAGE." -- and run in luau.exe between
magnet_stubs.lua and magnet_cases.lua.

usage: python tools/magnet_test.py [path-to-luau.exe]
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
a = src.index("-- Every frame, after physics.")
b = src.index("-- WHY NO DAMAGE.", a)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("magnet_stubs.lua") + src[a:b] + read("magnet_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
