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
  doors the REAL seeds (P.ROUTE_SEEDS) + the user's bff_routes.json of
        2026-11-13 (its undated "Home only from a safe zone" not believed, the
        Tiki pad pair not doubled): Floating Turtle -> Haunted Castle is not a
        straight flight; the Mansion / Hydra portals (the old requestEntrance
        doors) known unseen, flown into where they really stand, touched,
        asked, the ANSWER WRITTEN; a far ask answered = no flight, refused =
        the door and far asks left 6 h (then tried again); pulled back =
        refused; rip_indra not beaten = not planned; the Second Sea's Cursed
        Ship by its door, both ways, not under level 1000; each sea its own

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

sa = src.index("P.ROUTE_SEEDS = {")
seeds = src[sa:src.index("\n}\n", sa) + 3]
# The user's file as it stood on 2026-11-13 (bff_routes.json in the executor's workspace).
old_file = """
FILES["bff_routes.json"] = { v = 1, homeOutside = false, portalSecs = 0.744, homeSecs = 5.62,
    pads = {
        ["MapTeleportC@-5098,-3179"] = { name = "MapTeleportC", hit = { -5097, 319, -3178 },
            pivot = { -5085, 319, -3156 }, landed = { -16813, 62, 305 } },
        ["MapTeleportC@-16800,291"] = { name = "MapTeleportC", hit = { -16799, 84, 291 },
            pivot = { -16813, 62, 305 }, landed = { -5085, 318, -3156 } },
    },
    homes = { ["9:3:Castle on the Sea"] = { -5018, 318, -3014 } } }
"""
runs = [
    ("plan", read("route_stubs.lua") + plan + read("routeplan_cases.lua")),
    ("live", read("route_stubs.lua") + plan + live + read("routelive_cases.lua")),
    ("doors", read("route_stubs.lua") + old_file + seeds + plan + live + read("routedoor_cases.lua")),
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
