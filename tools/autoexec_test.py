"""Test autoexec_team.lua, the team pick at EVERY join (the farm script
loaded or not): Pirates asked for until you are on it, nothing in any other
game, never a switch of the team you are on, a minute at most, the place read
only once the game has loaded, no error when the remotes are missing.

The REAL autoexec_team.lua is wrapped as RUN(game, task, print) and run in
luau.exe between autoexec_stubs.lua and autoexec_cases.lua.

usage: python tools/autoexec_test.py [path-to-luau.exe]
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


src = read(os.path.join("..", "autoexec_team.lua"))
code = (read("autoexec_stubs.lua")
        + "local function RUN(game, task, print)\n" + src + "\nend\n"
        + read("autoexec_cases.lua"))

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(code)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
