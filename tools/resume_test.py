"""Test autoexec_resume.lua, the farm back after a CRASH: the Live Guard's
note (bff_crash_resume.json) loads fast_farm once in the server you stay in,
presses Start only if the farm was running, nothing on a stale or missing note
or in any other game, no second copy, no error when the download or Start fails.

The REAL autoexec_resume.lua is wrapped as RUN(game, task, print) and run in
luau.exe between resume_stubs.lua and resume_cases.lua.

usage: python tools/resume_test.py [path-to-luau.exe]
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


src = read(os.path.join("..", "autoexec_resume.lua"))
code = (read("resume_stubs.lua")
        + "local function RUN(game, task, print)\n" + src + "\nend\n"
        + read("resume_cases.lua"))

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(code)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
