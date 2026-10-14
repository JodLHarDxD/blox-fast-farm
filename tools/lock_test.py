"""Test the SETTINGS LOCK (2026-10-14): what you changed is written to your
workspace folder and comes back at every load; what you never touched gets the
new defaults of a later build; a setting whose kind changed is left at its new
default; a list is yours whole; unlock = the next load starts from defaults;
an executor that cannot write / a broken file. The REAL section is cut out of
fast_farm.lua (-- SETTINGS LOCK .. -- (end of settings lock)) and run once per
"load" on lock_stubs.lua.

usage: python tools/lock_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
src = open(os.path.join(HERE, "..", "fast_farm.lua"), encoding="utf-8").read()
a = src.index("-- SETTINGS LOCK\n")
sec = src[a:src.index("-- (end of settings lock)", a)]
# luau.exe's _G is read-only: the section's loop guard reads _G.BFF; point it at a local.
sec = sec.replace("_G.BFF == P", "_G_BFF == P")
stubs = open(os.path.join(HERE, "lock_stubs.lua"), encoding="utf-8").read()
cases = open(os.path.join(HERE, "lock_cases.lua"), encoding="utf-8").read()
code = stubs + "\nlocal _G_BFF = nil\nlocal function runSection()\n" + sec + "\nend\n" + cases
with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(code)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS (lock)" in r.stdout else 1)
