"""Test the M1 probe's verdict: which ways are tried first, what is kept, and
that "nothing landed" is NOT final for the server (it used to be: one bad
probe on arrival = no M1 against that server's elite, ever).

The REAL code is cut out of fast_farm.lua every run -- the plan tables and
m1Due, and probeM1 with P.reprobe -- and run in luau.exe between
probe_stubs.lua and probe_cases.lua.

usage: python tools/probe_test.py [path-to-luau.exe]
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
a = src.index("local m1Plan  = {}")
b = src.index("local lastProbeMethod", a)
c = src.index("local probeM1")
d = src.index("-- THE RHYTHM", c)
d = src.rindex("-- ====", c, d)

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("probe_stubs.lua") + src[a:b] + src[c:d] + read("probe_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
