-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local NOW = 1800000000
local live, gone = NOW + 3600, NOW - 3600

check("no key: open", packState("pvp", nil, nil, NOW) == "open")
check("owner: everything open, owner tools too",
    packState("pvp", { farm = 0 }, "owner", NOW) == "open" and packState("fruit", {}, "owner", NOW) == "open")
check("GRIND bought: circuit open", packState("circuit", { farm = live }, "buyer", NOW) == "open")
check("GRIND bought: sea locked", packState("seaevents", { farm = live }, "buyer", NOW) == "locked")
check("expired GRIND: locked", packState("random", { farm = gone }, "buyer", NOW) == "locked")
check("forever (0): open", packState("pvp", { pvp = 0 }, "friend", NOW) == "open")
check("BOSSES = raid: elite and sword open", packState("elite", { raid = live }, "buyer", NOW) == "open"
    and packState("sword", { raid = live }, "buyer", NOW) == "open")
check("mirage jobs are SEA", packState("gear", { sea = live }, "buyer", NOW) == "open"
    and packState("dealer", { farm = live }, "buyer", NOW) == "locked")
check("owner tools hidden from a buyer", packState("fruit", { farm = live }, "buyer", NOW) == "hidden"
    and packState("halloween", { events = live }, "trial", NOW) == "hidden")
check("fruits flag shows owner tools", packState("berry", { fruits = 0 }, "friend", NOW) == "open")
check("settings pages: free with any key", packState("attack", { farm = gone }, "buyer", NOW) == "open")
check("PACKS has the 5 packs with prices", PACKS.farm.price == "$0.99" and PACKS.sea.price == "$1.49"
    and PACKS.prehistoric and PACKS.pvp and PACKS.raid)

print(all and "ALL PASS" or "SOME FAILED")
