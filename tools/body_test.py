"""Test the body lock: lockAt held where asked; a sea fight's floor (P.floorY)
- never under the water, asked or every frame; P.keepLock - a knockback /
pull (under 500 studs) not adopted, a respawn still followed, the old rule
outside a sea fight.

The REAL section is cut out of fast_farm.lua every run (-- BODY: NOCLIP AND
THE LOCK .. the camera's section) and run in luau.exe between body_stubs.lua
and body_cases.lua.

usage: python tools/body_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
src = open(os.path.join(HERE, "..", "fast_farm.lua"), encoding="utf-8").read()
SEP = "-- =========================================================\n"
a = src.index("-- BODY: NOCLIP AND THE LOCK\n")
sec = src[a:src.index(SEP + "-- THE CAMERA, BORROWED", a)]
stubs = open(os.path.join(HERE, "body_stubs.lua"), encoding="utf-8").read()
cases = open(os.path.join(HERE, "body_cases.lua"), encoding="utf-8").read()
with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(stubs + sec + "\n" + cases)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
