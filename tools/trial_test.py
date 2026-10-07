"""Test v4_trial.lua's pure decisions: which relic a color is, what Next flies
to, the lava guard's floor, Next's route, one frame of travel, the fly keys,
adopting the game's own moves.

The REAL block between "-- PURE: start" and "-- PURE: end" is cut out of
v4_trial.lua every run and sandwiched between trial_stubs.lua and
trial_cases.lua, then run in luau.exe.

usage: python tools/trial_test.py [path-to-luau.exe]
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


src = read(os.path.join("..", "v4_trial.lua"))
a = src.index("-- PURE: start")
b = src.index("-- PURE: end", a)
a = src.index("\n", a) + 1

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("trial_stubs.lua") + src[a:b] + read("trial_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
