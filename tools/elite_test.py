"""Test the elite hunt's decisions, cut out of fast_farm.lua every run and
run in luau.exe:

  pure   eliteReply / eliteIsle / browserRows / pickServers / pruneVisited
  hop    hop() itself: THE CHALICE -- held, seen earlier, or arriving mid-hop
         -- means not one more teleport; order, five a round, marks, stop
  carry  takeCarry(): what the next server's copy takes over, and when it
         starts by itself

usage: python tools/elite_test.py [path-to-luau.exe]
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


def cut(start, end):
    a = src.index(start)
    return src[a:src.index(end, a)]


pure = cut("local ELITES    = {", "-- Everything the hunt knows.")
hop = cut("local function hop(why)", "function P.hopNow()")
carry = cut("local function takeCarry()", "P.takeCarry = takeCarry")

runs = [
    ("pure", read("elite_stubs.lua") + pure + read("elite_cases.lua")),
    ("hop", read("hop_stubs.lua") + pure + hop + read("hop_cases.lua")),
    ("carry", read("carry_stubs.lua") + carry + read("carry_cases.lua")),
]
ok = True
for name, code in runs:
    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
        f.write(code)
        path = f.name
    r = subprocess.run([LUAU, path], capture_output=True, text=True)
    os.unlink(path)
    print("== " + name)
    print(r.stdout + r.stderr)
    ok = ok and "ALL PASS" in r.stdout
sys.exit(0 if ok else 1)
