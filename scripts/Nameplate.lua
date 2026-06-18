-- Required script
local parts = require("lib.PartsAPI")

-- Variable setup
local nameGroup = parts.group.Nameplate
local namePivot = parts.group.NameplatePivot
if not nameGroup then return end

-- Head midRender event
function events.ENTITY_INIT()
	function nameGroup.midRender(delta)
		
		-- Variables
		local pos = player:getPos(delta)
		local groupPos = nameGroup:partToWorldMatrix():apply()
		local offset = (groupPos - pos) - (vanilla_model.HEAD:getOriginPos() / 32)
		
		-- Apply
		nameplate.ENTITY:pivot(offset)
		
		-- Kill function early if the namePivot isnt found
		if not namePivot then return end
		
		-- Get pose
		local pose = player:getPose()
		
		-- If any pose that rotates, rotate the pivot to match, and slightly raise pivot
		namePivot:offsetRot((pose ~= "STANDING" and pose ~= "CROUCHING") and player:getRot(delta).x__ + vec(90 * (pose == "SLEEPING" and -1 or 1), 0, 0) or nil)
		nameplate.ENTITY:pivot(nameplate.ENTITY:getPivot() + ((pose ~= "STANDING" and pose ~= "CROUCHING") and vec(0, 0.1, 0) or 0))
		
	end
end