"""Test the quest engine offline (acceptFor, syncQuest, the circuit helpers).

The REAL section is cut out of fast_farm.lua every run -- from "TAKING A
QUEST" to just before "Is the running quest's count full?" -- and run in
luau.exe between quest_stubs.lua (a fake server: takes / refuses / hides
quests) and quest_cases.lua (the scenarios).

usage: python tools/quest_test.py [path-to-luau.exe]
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
DASH = "-- ---------------------------------------------------------\n"


def read(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read()


src = read(os.path.join("..", "fast_farm.lua"))
a = src.rfind(DASH, 0, src.index("-- TAKING A QUEST: FROM WHERE YOU STAND"))
b = src.index("-- Is the running quest's count full?")

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("quest_stubs.lua") + src[a:b] + read("quest_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
