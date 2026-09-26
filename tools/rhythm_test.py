"""Test the combo rhythm (attackTick) offline.

The REAL rhythm section is cut out of fast_farm.lua every run and sandwiched
between rhythm_stubs.lua (the game, faked: a clock, weapons, cooldowns that
last 5 s) and rhythm_cases.lua (the scenarios), then run in luau.exe.

usage: python tools/rhythm_test.py [path-to-luau.exe]
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
a = src.rfind(SEP, 0, src.index("-- THE RHYTHM"))
b = src.rfind(SEP, 0, src.index("-- WHICH SETUP IS BETTER"))

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("rhythm_stubs.lua") + src[a:b] + read("rhythm_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
