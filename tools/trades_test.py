"""Test the trade counter (TRADES, 2026-11-08): the rules against jodl_37's 29
real trades and the 3 counts the game showed him (all four fit, the wiki's
day and the 24 h rules do not), the game's next count ruling rules out, the
one needing the fewest unseen trades shown, a trade read off TradeEvent and
off the game's "Trade completed (n/5)" (CommE or a new label, either first,
both ways = one), this panel's and the chat's words ignored, a title not a
message, trades the script never saw ("by"), the moment trades come back
said once, the file kept and judged again, clear.

The REAL code is cut out of fast_farm.lua every run -- the TRADES section --
and run in luau.exe between trades_stubs.lua and trades_cases.lua, wrapped
in a function so a case can build it again (a new load).

usage: python tools/trades_test.py [path-to-luau.exe]
"""
import os
import re
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
a = src.index("-- TRADES\n")
section = src[a:src.index("-- (end of trades)", a)]

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(read("trades_stubs.lua") + "local function SECTION()\n" + section + "\nend\n" + read("trades_cases.lua"))
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)

# The counter is only as good as its wiring.
wired = {
    "the strip leads with your trades": 'add("trades", h.tone, h.title, h.body)' in src,
    "the news lets TRADES say BREAKING": "N.breaking = breaking" in src,
    "the chip shows trades when the moon is off": "pcall(tr.chip)" in src,
    "trades start ticked": re.search(r"NewsShow\s*=\s*\{[^}]*trades\s*=\s*true", src, re.S) is not None,
    "a tick for them on Breaking news": '{ "trades", "Your trades: left, back at" }' in src,
    "listened to from load": "pcall(P.trades.listen)" in src and "pcall(P.trades.tick)" in src,
    "Fruits -> Trades": 'navRow(v, "Trades"' in src and 'makeView("trades")' in src and 'trades = "Trades"' in src,
}
for name, ok in wired.items():
    print(("PASS " if ok else "FAIL ") + name)
sys.exit(0 if "ALL PASS" in r.stdout and all(wired.values()) else 1)
