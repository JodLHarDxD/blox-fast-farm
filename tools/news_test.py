"""Test the server news: the moon read from the server (the MoonPhase
attribute, the decal as the fallback, the blue moon), the day / night number
round the clock (before and after the noon turn, past midnight), the full
moon tonight / up now / in N nights in real minutes at the MEASURED speed,
the speed itself (day and night apart, midnight, jumps and stops ignored),
the turn hour and order learned and kept in bff_sky.json, the islands (up at
the join, spawned while here, gone, how long it lasted), elites and raid
bosses, Cake Prince's answer, a fruit on the map, the headline order,
BREAKING and the chip.

The REAL code is cut out of fast_farm.lua every run -- the SERVER NEWS
section -- and run in luau.exe between news_stubs.lua and news_cases.lua,
wrapped in a function so a case can build it again (a new server).

usage: python tools/news_test.py [path-to-luau.exe]
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


news = cut("-- SERVER NEWS\n", "-- PANEL\n")

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("news_stubs.lua") + "local function SECTION()\n" + news + "\nend\n" + read("news_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
