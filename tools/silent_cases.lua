local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function close(a, b) return math.abs(a.X - b.X) < 1e-6 and math.abs(a.Y - b.Y) < 1e-6 and math.abs(a.Z - b.Z) < 1e-6 end
local swap = P.swapArgs
local hit, dir = vec(100, 0, 0), vec(1, 0, 0)
local target, from = vec(0, 50, 0), vec(0, 0, 0)

local args = { hit + vec(1, 1, 0), "Z", 5 }
check("a Vector3 at the mouse's hit point becomes the target", swap(args, 3, hit, dir, target, from) and close(args[1], target)
    and args[2] == "Z" and args[3] == 5)
args = { vec(1, 0, 0) }
check("the mouse ray's direction becomes the direction to the target", swap(args, 1, hit, dir, target, from)
    and close(args[1], vec(0, 1, 0)))
args = { cfr(hit, nil) }
check("a CFrame at the mouse's hit point becomes one at the target, facing away from you", swap(args, 1, hit, dir, target, from)
    and close(args[1].Position, target) and args[1].look ~= nil)
args = { vec(400, 0, 0), vec(0, 0, 1), cfr(vec(-50, 0, 0), nil), true, nil }
local changed = swap(args, 5, hit, dir, target, from)
check("anything that is not the mouse's is left alone (your position, other directions)", not changed
    and close(args[1], vec(400, 0, 0)) and close(args[2], vec(0, 0, 1)) and close(args[3].Position, vec(-50, 0, 0)))
args = { hit }
check("no real mouse read: nothing swapped", not swap(args, 1, nil, nil, target, from) and close(args[1], hit))
check("no hook on this executor: says so", P.silentNote == "this executor cannot hook calls - the camera aim only", P.silentNote)
print(all and "ALL PASS" or "SOME FAILED")
