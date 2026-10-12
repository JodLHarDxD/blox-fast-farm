"""Test race V3 / V4 (2026-10-12, build 2026-10-12.5).

Two parts, both cut out of the REAL fast_farm.lua every run and run in luau.exe:
  1. RACE LOGIC (pure): the V4 gate, the user's V3 clock (28 s from a SEEN
     activation, then a T every 0.5 s; no signal ever = a 3 s burst, the next
     wait from its end - simulated against a fake server cooldown: never a
     miss, lateness bounded), whose effect it is (yours, not an ally's roar),
     V4's weapons (real weapons only, order, form, keys), M1s in turn.
     race_stubs.lua + the block + race_cases.lua.
  2. THE TICKER on a fake game (the whole RACE section): V4 fired at a full
     meter (the game's Y, then the Awakening call, the way that worked kept,
     both refused = 3 s), V3 pressed on the clock (the FX roar / the ability
     child / your own T seen; an ally's roar and an ability TOOL not), the
     moon turn, no tool / dead / switched off, the probe file, the panel
     lines, unhook. race_live_stubs.lua + the section + race_live_cases.lua.

usage: python tools/race_test.py [path-to-luau.exe]
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


def cut(src, start, end):
    a = src.index(start)
    b = src.index(end, a)
    return src[a:b]


def run(code):
    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
        f.write(code)
        path = f.name
    r = subprocess.run([LUAU, path], capture_output=True, text=True)
    os.unlink(path)
    return r.stdout + r.stderr


src = read(os.path.join("..", "fast_farm.lua"))
logic = cut(src, "        -- RACE LOGIC (pure", "        -- (end of race logic)")
section = cut(src, "-- RACE V3 / V4\n", "-- (end of race)")

out1 = run(read("race_stubs.lua") + logic + read("race_cases.lua"))
out2 = run(read("race_live_stubs.lua") + section + read("race_live_cases.lua"))
print(out1 + out2)
ok = "ALL PASS (logic)" in out1 and "ALL PASS (live)" in out2
sys.exit(0 if ok else 1)
