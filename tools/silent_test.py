"""Test the silent aim's argument swap: a value a remote is sent that IS your
real mouse's (its hit point within 3 studs, its ray's unit direction, a CFrame
at its hit point) becomes the target's; everything else is left alone; no
hook installed where the executor cannot hook. The REAL section is cut out of
fast_farm.lua (-- SILENT AIM .. -- (end of silent aim)).

usage: python tools/silent_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
src = open(os.path.join(HERE, "..", "fast_farm.lua"), encoding="utf-8").read()
a = src.index("-- SILENT AIM\n")
sec = src[a:src.index("-- (end of silent aim)", a)]
stubs = open(os.path.join(HERE, "silent_stubs.lua"), encoding="utf-8").read()
cases = open(os.path.join(HERE, "silent_cases.lua"), encoding="utf-8").read()
with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(stubs + sec + "\n" + cases)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
