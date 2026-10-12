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
     lines, unhook; nothing at all while the script is idle (no mode running,
     PvP off). race_live_stubs.lua + the section + race_live_cases.lua.
  3. THE START GUARD: no mode on = Start starts nothing.

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

# 3. THE START GUARD (2026-10-12): no mode on = nothing starts (the race then never fires).
guard = cut(src, "function P.start()\n", "    if P.running then P.stop() end\n")
START = """
local SAID = {}
local function say(s) table.insert(SAID, s) end
local REAL_PRINT = print
local function print(_) end
local CFG = {}
local P = {}
""" + guard + """    return "through"
end
local fails = 0
local function check(name, ok) REAL_PRINT((ok and "PASS " or "FAIL ") .. name) if not ok then fails += 1 end end
check("Start with no mode on: nothing starts, it says why", P.start() == nil and SAID[1] == "no mode on - pick one in Modes")
for _, k in ipairs({ "Circuit", "Hunt", "RandomMode", "RaidMode", "LeviFight", "Volcano" }) do
    CFG = { [k] = true }
    check("Start with " .. k .. " on: it starts", P.start() == "through")
end
REAL_PRINT(fails == 0 and "ALL PASS (start)" or (fails .. " FAILED (start)"))
"""

out1 = run(read("race_stubs.lua") + logic + read("race_cases.lua"))
out2 = run(read("race_live_stubs.lua") + section + read("race_live_cases.lua"))
out3 = run(START)
print(out1 + out2 + out3)
ok = "ALL PASS (logic)" in out1 and "ALL PASS (live)" in out2 and "ALL PASS (start)" in out3
sys.exit(0 if ok else 1)
