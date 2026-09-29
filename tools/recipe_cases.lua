
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

-- he is not here: nothing to do here, said why, nothing bought
reset()
local r = recipeStep(0)
check("not here: false, why, no buy", r == false and E.why == "the Barista Cousin is not here now"
    and #CALLS == 1 and E.offer == "he is not here now", E.why)

-- he teaches one you did not pick (or already have: switched off)
reset() OFFER = "Snow White" RARITY = 3
r = recipeStep(0)
check("not picked: false, names it, no buy", r == false and E.why:find("Snow White", 1, true)
    and #CALLS == 1 and E.offer == "Snow White  (Legendary)", E.why)

-- THE ONE YOU WANT, learned from where you stand
reset() OFFER = "Winter Sky" RARITY = 3 BUY = { 1 }
r = recipeStep(0)
check("wanted: learned from here, no flight", r == true and FLIGHTS == 0 and E.tally.recipes == 1
    and E.recipeNote == "Winter Sky: learned", E.recipeNote)
check("learned = its switch goes off (the hunt goes on for the others)", CFG.RecipeWant["Winter Sky"] == false)

-- not from here: flies to him and tries again
reset() OFFER = "Winter Sky" BUY = { false, 2 } AT = V(10, 20, 30)
r = recipeStep(0)
check("refused from afar: one flight, learned in front of him", r == true and FLIGHTS == 1
    and E.tally.recipes == 1 and CFG.RecipeWant["Winter Sky"] == false, E.recipeNote)

-- cannot pay: the hunt STOPS and says why (another server would not help)
reset() OFFER = "Winter Sky" BUY = { 0, 0 } AT = V(0, 0, 0)
r = recipeStep(0)
check("cannot pay: stopped, said why, switch left on", r == true and STOPPED ~= nil
    and E.recipeNote:find("not enough to pay", 1, true) and CFG.RecipeWant["Winter Sky"] == true, E.recipeNote)

-- every picked recipe learned: stops
reset() CFG.RecipeWant["Winter Sky"] = false OFFER = "Winter Sky"
r = recipeStep(0)
check("none left to learn: stopped, nothing asked", r == true and STOPPED ~= nil and #CALLS == 0)

-- First Sea: he does not exist there
reset() SEA = 1 OFFER = "Winter Sky" BUY = { 1 }
r = recipeStep(0)
check("First Sea: false, nothing asked", r == false and #CALLS == 0 and E.why:find("First Sea", 1, true))

print(all and "ALL PASS" or "SOME FAILED")
