"""Test the berry pick (grabBerry): each prompt HELD the way a player holds
it (InputHoldBegin, the prompt's own HoldDuration, InputHoldEnd), the
executor's instant fireproximityprompt only as the fallback -- a game's
server can refuse an instant trigger (2026-09-30: on Velocity about half the
berries were never picked). ~15 s while the berry is still there, then left
for a minute; taken by another = out at once; a stop = out at once.

The REAL grabBerry is cut out of fast_farm.lua every run and run in luau.exe
between berry_stubs.lua and berry_cases.lua.

usage: python tools/berry_test.py [path-to-luau.exe]
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
a = src.index("local function holdPrompt(")       # shared with the Fire Flower hunt
b = src.index("-- AURA RECIPES:", a)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("berry_stubs.lua") + src[a:b] + read("berry_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
