"""Test Light mode: the game's music, camera shake and Fast Mode set for you
in every server, only once you have a team, said twice for the Settings script
that sets them back at join, water parts left as water, anything the game no
longer has reported and skipped. And the fruit look keys under Fast Mode.

The REAL section and P.fruitLooks are cut out of fast_farm.lua every run and
run in luau.exe between light_stubs.lua and light_cases.lua.

usage: python tools/light_test.py [path-to-luau.exe]
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
looks = src[src.index("function P.fruitLooks(c)"):src.index("-- Teach store:")]
light = src[src.index("P.light = {"):src.index("-- (end of light mode)")]
code = ("local io_print = print\n" + read("light_stubs.lua") + looks + light
        + read("light_cases.lua"))

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(code)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True, encoding="utf-8", errors="replace")
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
