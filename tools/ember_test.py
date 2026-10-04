"""Test the Blaze Ember hunt: the quest text read, the trees' order (giants
never, bamboo last, a kind that broke first), the quest asked for from afar
then at the Dragon Hunter when afar does not take, the "Head back" notice,
embers taken first, the stop when he gives nothing / you have enough. The
REAL section is cut out of fast_farm.lua (-- EMBER HUNT .. -- MAIN LOOP).

usage: python tools/ember_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
src = open(os.path.join(HERE, "..", "fast_farm.lua"), encoding="utf-8").read()
a = src.index("-- EMBER HUNT\n")
sec = src[a:src.index("-- =========================================================\n-- MAIN LOOP", a)]
stubs = open(os.path.join(HERE, "ember_stubs.lua"), encoding="utf-8").read()
cases = open(os.path.join(HERE, "ember_cases.lua"), encoding="utf-8").read()
with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(stubs + sec + "\n" + cases)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
