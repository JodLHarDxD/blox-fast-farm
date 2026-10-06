"""Test the Volcanic Magnet step before the Prehistoric hunt sails: held =
sail; 15 Blaze Ember + 10 Scrap Metal = crafted (from here, else at the
Dragon Hunter; 3 refusals = sail without it); scrap short = Forest Pirates
(or Pirate Millionaires) fought, else flown to; embers short = the Ember
hunt's quests borrowed (blocked = sail without it). The REAL section is cut
out of fast_farm.lua (-- VOLCANIC MAGNET .. -- LEARNED KEYS, KEPT).

usage: python tools/vmagnet_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
src = open(os.path.join(HERE, "..", "fast_farm.lua"), encoding="utf-8").read()
SEP = "-- =========================================================\n"
a = src.index("-- VOLCANIC MAGNET\n")
sec = src[a:src.index(SEP + "-- LEARNED KEYS, KEPT", a)]
stubs = open(os.path.join(HERE, "vmagnet_stubs.lua"), encoding="utf-8").read()
cases = open(os.path.join(HERE, "vmagnet_cases.lua"), encoding="utf-8").read()
with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write("local realPrint = print\n" + stubs + sec + "\n" + cases)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
