"""Test the Fire Flower hunt (Draco V2): the flower found in
workspace.FireFlowers, picked by holding its prompt like a player (the
instant fireproximityprompt every third try), the clock that starts at the
FIRST kill in a server (2 min, user 2026-10-04), the 3-min no-kill safety,
the Third Sea check, hop off = stay, and the camps flown to in turn.

The REAL code is cut out of fast_farm.lua every run -- holdPrompt (shared
with the berry hunt) and the FIRE FLOWERS section -- and run in luau.exe
between flower_stubs.lua and flower_cases.lua.

usage: python tools/flower_test.py [path-to-luau.exe]
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


def cut(start, end):
    a = src.index(start)
    return src[a:src.index(end, a)]


hold = cut("local function holdPrompt(", "-- Fly to the bush and HOLD")
flower = cut("-- FIRE FLOWERS (Draco V2", "local function eliteFight(")

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("flower_stubs.lua") + hold + flower + read("flower_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
