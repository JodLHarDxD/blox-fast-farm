"""Test "where a species is" (campOf, nearestLoaded) and the pile (buildPile).

The REAL code is cut out of fast_farm.lua every run -- from "WHERE A SPECIES
IS" to just before "Every frame, after physics." -- and run in luau.exe
between locate_stubs.lua (a fake world: loaded enemies, EnemySpawns, parked
enemies) and locate_cases.lua (including the Sky Bandit case that hung the
farm in the open sky).

usage: python tools/locate_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
SEP = "-- =========================================================\n"


def read(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read()


src = read(os.path.join("..", "fast_farm.lua"))
a = src.rfind(SEP, 0, src.index("-- WHERE A SPECIES IS"))
b = src.index("-- Every frame, after physics.")

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("locate_stubs.lua") + src[a:b] + read("locate_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
