"""Test a fruit too good to lose (user, 2026-10-25), real code cut out of
fast_farm.lua every run and run in luau.exe:
  values  P.tradeValue (the trading market's physical value, renamed fruits,
          Dragon, a fruit the list does not know), P.isKeeper (the line,
          0 = off), P.valueWords; THE FRUIT HISTORY: add / set the newest of
          a fruit in a state / summary per fruit dearest first / newest-first
          lines with the server number / 300 kept / the file per account /
          clear
  hold    keepHold(): no keeper = nothing (a held one gone = logged "gone",
          the hunt goes on); a keeper = held at the Mansion in the Third Sea
          (300 up elsewhere), flown there once, again only when far (a
          respawn), never snapped; storage tried every 20 s; the game's
          InSafeZone in the words; a fruit carried from before gets an entry

usage: python tools/fruitkeep_test.py [path-to-luau.exe]
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


values = cut("local MESH_ALIAS", '-- "Meshes/magu_34"')
hold = cut("        -- WHERE A HELD FRUIT WAITS", "        -- BERRIES in this server")
runs = [
    ("values", read("fruitkeep_stubs.lua") + values + read("fruitkeep_cases.lua")),
    ("hold", read("keephold_stubs.lua") + hold + read("keephold_cases.lua")),
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
