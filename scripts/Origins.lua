-- Required script
local tail = require("scripts.Tail")
local s, origins = pcall(require, "lib.OriginsAPI")
if not s then return end -- Kills script early if Origins.lua isnt found

-- Lock tag
local lockTag = "Origins"

-- Checked powers
local checkedPowers = {
	"origins:swim_speed"
	--"taurserver:legless" ;)
}

function events.TICK()
	
	-- Powers
	local powers = origins.getPowerData(player)
	
	-- Check for powers
	for _, v in ipairs(checkedPowers) do
		if powers[v] then
			
			-- If found, force tail to form
			tail.type:update(5)
			tail.locked = lockTag
			return
			
		end
	end
	
	-- If no powers found, remove lock, unless another script has set a lock.
	if tail.locked == lockTag then
		tail.locked = nil
	end
	
end