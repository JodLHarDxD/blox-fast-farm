"""Test the hidden aim, frame by frame: the REAL camera block (from
"local aimPixel" to the TRAVEL section) runs in a simulated frame loop --
input, render steps by priority with a camera script that builds the view
from the current camera, drawn, Heartbeat. Every drawn frame must be exactly
the player's own view; every key read during a cast must see the aim.

usage: python tools/hidden_test.py [path-to-luau.exe]
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
a = src.index("local aimPixel = nil")
b = src.index("\n-- TRAVEL\n", a)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("hidden_stubs.lua") + src[a:b] + read("hidden_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
