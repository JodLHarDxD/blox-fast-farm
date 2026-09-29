"""Test the team pick every join asks for (Pirates / Marines): SetTeam first,
the ChooseTeam screen's own button when that does not take, the one you
picked (not the default), never a switch of the team you are on, nothing
when picking is off.

The REAL P.pickTeam is cut out of fast_farm.lua every run and run in
luau.exe between team_stubs.lua and team_cases.lua.

usage: python tools/team_test.py [path-to-luau.exe]
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
a = src.index("function P.pickTeam()")
b = src.index("-- Arrived by an elite hunt's hop", a)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("team_stubs.lua") + src[a:b] + read("team_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
