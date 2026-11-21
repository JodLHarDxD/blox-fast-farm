"""Test queueReload(), the reload a hop queues on the executor: a raw URL
gets "?cb=" byte for byte as before the key gate; a gate URL (it already has
"?k=...") gets "&cb="; the carry and _G.BFF_SOURCE go with it; queued once;
the queued code compiles.

The REAL queueReload is cut out of fast_farm.lua and run in luau.exe.

usage: python tools/queue_test.py [path-to-luau.exe]
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


queue = cut("        local function queueReload(carry)",
            "        -- On load: state carried from the server before")

# _G: luau.exe's is read-only (a sandbox); Roblox's is a writable shared table.
stubs = r'''
local _G = {}
local SOURCE_URL = "https://raw.githubusercontent.com/JodLHarDxD/blox-fast-farm/main/fast_farm.lua"
local E = { queued = false }
local QUEUED
local HAS_QUEUE = true
local function queueFn()
    if not HAS_QUEUE then return nil end
    return function(code) QUEUED = code end
end
'''

cases = r'''
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function run(source, carry)
    _G.BFF_SOURCE = source
    E.queued, QUEUED = false, nil
    queueReload(carry)
    return QUEUED or ""
end

-- 1. no gate: byte for byte the line queued before the key gate
local q = run(nil)
check("raw: ?cb= exactly as before",
    string.find(q, string.format('pcall(function() loadstring(game:HttpGet(%q .. "?cb=" .. tostring(tick())))() end)\n', SOURCE_URL), 1, true) ~= nil, q)
check("raw: the source goes with it", string.find(q, string.format("_G.BFF_SOURCE = %q\n", SOURCE_URL), 1, true) ~= nil, q)

-- 2. through the gate: the URL has ?k= already, so &cb=
local GATE = "https://bff-gate.example.workers.dev/l?k=BFF-AAAA-BBBB-CCCC-DDDD-EEEE&u=111&d=&x=Madium"
q = run(GATE)
check("gate: &cb=", string.find(q, string.format('%q .. "&cb="', GATE), 1, true) ~= nil, q)
check("gate: no ?cb=", string.find(q, '"?cb="', 1, true) == nil, q)
check("gate: the gate URL goes with it", string.find(q, string.format("_G.BFF_SOURCE = %q\n", GATE), 1, true) ~= nil, q)

-- 3. a carried hunt rides along
q = run(GATE, '{"hunt":"elite"}')
check("carry kept", string.find(q, string.format("_G.BFF_CARRY = %q\n", '{"hunt":"elite"}'), 1, true) ~= nil, q)

-- 4. the queued code compiles, both ways
check("raw code compiles", loadstring(run(nil)) ~= nil)
check("gate code compiles", loadstring(run(GATE, '{"x":1}')) ~= nil)

-- 5. queued once per server; no queue_on_teleport = nothing queued
_G.BFF_SOURCE, E.queued, QUEUED = nil, true, nil
queueReload(nil)
check("queued once", QUEUED == nil)
HAS_QUEUE = false
q = run(nil)
check("no queue_on_teleport: nothing", q == "" and E.queued == false, q)

print(all and "ALL PASS" or "SOME FAILED")
'''

with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(stubs + queue + cases)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True)
os.unlink(path)
print(r.stdout + r.stderr)
sys.exit(0 if "ALL PASS" in r.stdout else 1)
