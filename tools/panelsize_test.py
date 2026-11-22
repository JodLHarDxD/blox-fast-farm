"""Test the panel's resize helpers (R3 Task 1b): panelScaleClamp,
panelHeightClamp, panelScaleDrag, panelHeightDrag, panelKeepOnScreen and the
CFG defaults. The real block is cut out of fast_farm.lua every run and run in
luau.exe.

usage: python tools/panelsize_test.py [path-to-luau.exe]
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
a = src.index("-- PANEL SIZE (R3")
b = src.index("-- PACKS END", a)
c = src.index("local CFG = {")
cfg = src[c:src.index("\n}\n", c) + 3]

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(cfg + src[a:b] + read("panelsize_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
