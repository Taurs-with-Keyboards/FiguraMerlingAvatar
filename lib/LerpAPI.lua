-- LerpAPI
-- By:
--   _________  ________  _________  ________  ___
--  |\___   ___\\   __  \|\___   ___\\   __  \|\  \
--  \|___ \  \_\ \  \|\  \|___ \  \_\ \  \|\  \ \  \
--       \ \  \ \ \  \\\  \   \ \  \ \ \   __  \ \  \
--        \ \  \ \ \  \\\  \   \ \  \ \ \  \ \  \ \  \____
--         \ \__\ \ \_______\   \ \__\ \ \__\ \__\ \_______\
--          \|__|  \|_______|    \|__|  \|__|\|__|\|_______|
--
-- Version: 1.1.0

-- Create API
local lerpAPI = {}

-- Interal lerp data
local lerpInternal = {}

-- Lerps table
local lerps = {}

-- Removes lerp
function lerpInternal:remove()
	
	lerps[self] = nil
	
end

-- Resets lerp, with optional target
function lerpInternal:reset(pos)
	
	pos = pos or 0
	self.prevTick = pos
	self.currTick = pos
	self.target   = pos
	self.currPos  = pos
	
end

-- Create a lerp object
function lerpAPI:new(speed, pos)
	
	-- Create object
	local obj = setmetatable({}, { __index = lerpInternal })
	
	-- Speed
	obj.speed = speed
	
	-- Lerp variables
	obj:reset(pos)
	
	-- Lerp enabled
	obj.enabled = true
	
	-- Add objact to list
	lerps[obj] = obj
	
	-- Return object
	return obj
	
end

-- Iterate through the lerps to set the next tick of each lerp
events.TICK:register(function()
	for _, obj in pairs(lerps) do
		if obj.enabled then
			obj.prevTick = obj.currTick
			obj.currTick = math.lerp(obj.currTick, obj.target, obj.speed)
		end
	end
end, "tickLerp")

-- Iterate through the lerps to smooth the lerp each frame
events.RENDER:register(function(delta, context)
	for _, obj in pairs(lerps) do
		if obj.enabled then
			obj.currPos = math.lerp(obj.prevTick, obj.currTick, delta)
		end
	end
end, "renderLerp")

-- Return API
return lerpAPI