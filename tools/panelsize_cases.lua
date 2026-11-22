local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function near(a, b) return math.abs(a - b) < 1e-9 end

-- scale: 0.6 - 1.0, junk = 1
check("scale in range stays", near(panelScaleClamp(0.8), 0.8))
check("scale below 0.6 -> 0.6", near(panelScaleClamp(0.2), 0.6))
check("scale above 1 -> 1", near(panelScaleClamp(3), 1))
check("scale junk -> 1", panelScaleClamp(nil) == 1 and panelScaleClamp("x") == 1 and panelScaleClamp(0 / 0) == 1)
check("scale ends are exact", panelScaleClamp(0.6) == 0.6 and panelScaleClamp(1) == 1)

-- height: 0 = full, between min and full
check("height 0 = full", panelHeightClamp(0, 706, 250) == 706)
check("height nil = full", panelHeightClamp(nil, 706, 250) == 706)
check("height junk = full", panelHeightClamp("a", 706, 250) == 706 and panelHeightClamp(0 / 0, 706, 250) == 706)
check("height over full = full", panelHeightClamp(900, 706, 250) == 706)
check("height under min -> min", panelHeightClamp(100, 706, 250) == 250)
check("height in range stays", panelHeightClamp(400, 706, 250) == 400)
check("height negative = full", panelHeightClamp(-5, 706, 250) == 706)
check("full smaller than min: full wins", panelHeightClamp(120, 200, 250) == 200)
check("full grows (live card): a crop below it stays", panelHeightClamp(400, 760, 250) == 400)

-- drags
check("corner down grows", near(panelScaleDrag(0.6, 400, 40), 0.7))
check("corner up shrinks", near(panelScaleDrag(1, 706, -70.6), 0.9))
check("corner drag clamps", panelScaleDrag(1, 706, 500) == 1 and panelScaleDrag(1, 706, -5000) == 0.6)
check("corner drag bad input = same", near(panelScaleDrag(0.8, 0, 10), 0.8) and near(panelScaleDrag(0.8, 500, nil), 0.8))
check("edge drag follows the pointer at scale 1", panelHeightDrag(400, 50, 1, 706, 250) == 450)
check("edge drag is in screen px: at 0.8 a pixel is 1.25 units", near(panelHeightDrag(400, 40, 0.8, 706, 250), 450))
check("edge drag clamps both ends", panelHeightDrag(400, 9999, 1, 706, 250) == 706
    and panelHeightDrag(400, -9999, 1, 706, 250) == 250)

-- on screen
local x, y = panelKeepOnScreen(1000, 18, 342, 706, 1280, 800)
check("on screen already: unchanged", x == 1000 and y == 18)
x, y = panelKeepOnScreen(1400, 18, 342, 706, 1280, 800)
check("right edge past the screen -> pulled back", x == 1280)
x, y = panelKeepOnScreen(200, 18, 342, 706, 1280, 800)
check("left edge off the screen -> right edge = width", x == 342)
x, y = panelKeepOnScreen(1000, 400, 342, 706, 1280, 800)
check("bottom off the screen -> lifted", y == 94)
x, y = panelKeepOnScreen(1000, -50, 342, 706, 1280, 800)
check("above the screen -> 0", y == 0)
x, y = panelKeepOnScreen(300, 40, 342, 706, 300, 400)
check("bigger than the screen: top-left shown", x == 300 and y == 0)

-- the real defaults live in CFG (cut from fast_farm.lua by the runner)
check("CFG.PanelScale default 1.0", CFG.PanelScale == 1.0)
check("CFG.PanelHeight default 0 (full)", CFG.PanelHeight == 0)
print(all and "ALL PASS" or "SOME FAILED")
