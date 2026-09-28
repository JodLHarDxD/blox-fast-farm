-- The island table needs Vector3; nothing else of the game is touched.
local Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }
-- the account this client runs as
local player = { UserId = 1 }
