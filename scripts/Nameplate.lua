-- Required script
local parts = require("lib.PartsAPI")

-- Variable setup
local head = parts.group.Head

-- Offsets
-- The overall height of the nameplate pivot from the player pos is 2.3
-- 0.89282 was chosen because its the exact offset of the nameplate above the pivot point of the players head in world
local headOffset = vec(0, 0.89282, 0)
local offset = vec(0, 0, 0)

-- Head midRender event
function events.ENTITY_INIT()
	function head.midRender(delta)
		
		-- Get positions
		local mat = head:partToWorldMatrix()
		local pos = player:getPos(delta)
		
		-- Apply
		nameplate.ENTITY:pivot((mat:apply() - pos) + headOffset + offset)
		
	end
end