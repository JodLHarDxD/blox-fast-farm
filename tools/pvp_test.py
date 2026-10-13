"""Test PvP mode (2026-10-11).

Two parts, both cut out of the REAL fast_farm.lua every run and run in luau.exe:
  1. PVP LOGIC (pure): who is picked, the speed attribute math, the dash
     measuring, the Ken retry clock, which screen effects count as blinding.
     pvp_stubs.lua + the block + pvp_cases.lua.
  2. THE KEN VIEW switch (wrap / unwrap) on a fake ObservationManager object:
     the game's OFF dropped while PvP is on, let through for a dead life,
     given back on unwrap. pvp_view_stubs.lua + the block + pvp_view_cases.lua.

usage: python tools/pvp_test.py [path-to-luau.exe]
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
logic = cut(src, "        -- PVP LOGIC (pure", "        -- (end of pvp logic)")
view = cut(src, "        -- ---------- THE KEN VIEW ----------", "        local function viewTick(now)")
# 3. THE AIM WIRING (2026-10-13): the logic + the real state table, then the
#    real AIM .. facing code on Roblox stubs - pick, his path, ping, floor,
#    the aim points per attack kind, the aim sent while a move plays, the
#    game's gun snap, facing.
state = cut(src, "        -- PVP LOGIC (pure", "        local function hold(c)")
aim = cut(src, "        -- ---------- AIM ----------", "        -- ---------- THE MARK")

out1 = run(read("pvp_stubs.lua") + logic + read("pvp_cases.lua"))
out2 = run(read("pvp_view_stubs.lua") + view + read("pvp_view_cases.lua"))
out3 = run(read("pvp_aim_stubs.lua") + state + aim + read("pvp_aim_cases.lua"))
print(out1 + out2 + out3)
ok = "ALL PASS (logic)" in out1 and "ALL PASS (view)" in out2 and "ALL PASS (aim)" in out3
sys.exit(0 if ok else 1)
