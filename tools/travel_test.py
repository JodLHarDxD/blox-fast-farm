"""Test TRAVEL's choice (user, 2026-10-31: "any type of traveling through the
script goes through the portals and the shortest path"), the real flyTo cut
out of fast_farm.lua every run and run in luau.exe: a long trip with no
options is routed; portal = false never; CFG.TravelRoutes off = only a trip
that asks; a short one never; a flight inside a route (into a pad) is not
routed again; a route that errors is said and the trip goes on; the First /
Second Sea's requestEntrance leg still tried there, not in the Third.

usage: python tools/travel_test.py [path-to-luau.exe]
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
a = src.index("local flyTo       -- declared here")
end_mark = "P.flyTo = function(pos) return flyTo(pos) end\n"
b = src.index(end_mark, a) + len(end_mark)
code = read("travel_stubs.lua") + src[a:b] + read("travel_cases.lua")

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(code)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
