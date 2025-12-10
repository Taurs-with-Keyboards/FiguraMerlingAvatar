-- Kills script if squAPI cannot be found
local s, squapi = pcall(require, "lib.SquAPI")
if not s then return {} end

-- Required scripts
local parts     = require("lib.PartsAPI")
local tailScale = require("scripts.Tail")
local pose      = require("scripts.Posing")

-- Squishy ears
local ears = squapi.ear:new(
	parts.group.LeftEar,
	parts.group.RightEar,
	0.35,  -- Range Multiplier (0.35)
	true,  -- Horizontal (true)
	1,     -- Bend Strength (1)
	false, -- Do Flick (false)
	400,   -- Flick Chance (400)
	0.1,   -- Stiffness (0.1)
	0.9    -- Bounce (0.9)
)

-- Tails table
local tailParts = {
	
	parts.group.Tail1,
	parts.group.Tail2,
	parts.group.Tail3,
	parts.group.Tail4,
	parts.group.Fluke
	
}

-- Squishy tail
local tail = squapi.tail:new(
	tailParts,
	0,     -- Intensity X (0)
	0,     -- Intensity Y (0)
	0,     -- Speed X (0)
	0,     -- Speed Y (0)
	2,     -- Bend (2)
	1,     -- Velocity Push (1)
	0,     -- Initial Offset (0)
	0,     -- Seg Offset (0)
	0.015, -- Stiffness (0.015)
	0.95,  -- Bounce (0.95)
	0,     -- Fly Offset (0)
	-15,   -- Down Limit (-15)
	25     -- Up Limit (25)
)

-- Tail strength variables
local tailStrength  = tail.bendStrength
local tailVelPush   = tail.velocityPush
local tailFlyOffset = tail.flyingOffset

function events.TICK()
	
	-- Control the intensity of the tail function based on its scale
	local scale = tailScale.isSmall and 1 or 0
	tail.bendStrength = scale * tailStrength
	tail.velocityPush = not (player:isInWater() or pose.swim or pose.crawl or pose.elytra) and tailVelPush or 0
	tail.flyingOffset = scale * tailFlyOffset
	
end