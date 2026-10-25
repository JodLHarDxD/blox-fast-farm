"""Test ROUTES (user, 2026-10-25: "the Home button, the portals, the shortest
path"), real code cut out of fast_farm.lua every run and run in luau.exe:
  plan  P.routePlan, Dijkstra over START / GOAL / HOME / each pad's entry and
        exit: a short trip = straight; Sea of Tears -> Hydra = Home, the
        Castle's Hydra pad; Floating Turtle -> Port Town = Home (Home off =
        the Mansion's pad to the Castle); a pad whose ride's end is not known
        is never planned; Home only from where you start; a dear Home loses
  live  the ROUTES block on a fake Third Sea: pads by their tag (pairs by
        name, the Pivot, kept in bff_routes.json and read back), your Home
        Point in this sea only (another sea's never), the Home button (the
        countdown, its landing + seconds learned; from outside a safe zone:
        did not move you = only from inside one after that), a pad stood in
        and touched (the game's own handler), the client's own steps when the
        touch did nothing, a locked pad (GetInfo) never again, a server that
        pulls you back = refused, R.go end to end (Home, then the Hydra pad)

usage: python tools/route_test.py [path-to-luau.exe]
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
a = src.index("-- THE PLAN (pure). net =")
b = src.index('        local CS = game:GetService("CollectionService")', a)
b = src.rindex("\ndo\n", a, b) + 1
plan = src[a:b]
e = src.index("    build()\nend\n", b) + len("    build()\nend\n")
live = src[b:e]

runs = [
    ("plan", read("route_stubs.lua") + plan + read("routeplan_cases.lua")),
    ("live", read("route_stubs.lua") + plan + live + read("routelive_cases.lua")),
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
