"""Test Quests by your level: the best ordinary quest your level allows among
this sea's givers, read live from the game, flown to before asking, a running
quest never asked again, a refusal and missing game data handled.

The REAL section is cut out of fast_farm.lua every run and run in luau.exe
between quest_stubs.lua and quest_cases.lua.

usage: python tools/quest_test.py [path-to-luau.exe]
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
cut = src[src.index("P.quest = {"):src.index("-- (end of quests)")]
code = "local io_print = print\n" + read("quest_stubs.lua") + cut + read("quest_cases.lua")

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(code)
    path = f.name
try:
    r = subprocess.run([LUAU, path], capture_output=True, text=True, encoding="utf-8",
                       errors="replace", timeout=60)
    out = r.stdout + r.stderr
except subprocess.TimeoutExpired:
    out = "TIMED OUT"
os.unlink(path)
print(out)
sys.exit(0 if "ALL PASS" in out else 1)
