"""Test where you hang over the pile (poseTarget / setPose) and the remote
hit's reach (hitTargets): the height counted from the highest enemy, "always
stay above", the Port Town case, 120 up.

The REAL code is cut out of fast_farm.lua every run -- "local wantPose" up to
the WEAPONS section, and hitTargets -- and run in luau.exe between
pose_stubs.lua and pose_cases.lua.

usage: python tools/pose_test.py [path-to-luau.exe]
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
a = src.index("local wantPose")
b = src.index("-- WEAPONS: WHAT EACH ONE FIRES", a)
c = src.index("function P.hitReach()")
d = src.index("local function m1Remote(", c)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("pose_stubs.lua") + src[a:b] + src[c:d] + read("pose_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
