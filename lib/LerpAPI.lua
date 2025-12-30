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
-- Version: 1.2.4

-- Create API
local lerpAPI = {}

-- Lerps table
local lerps = {}

-- Interal lerp data
local lerpInternal = {}

-- Meta table setup
local lerpMeta = {
	__index = lerpInternal,
	__newindex = function(t, key, value)
		rawset(type(value) ~= "function" and t or lerpInternal, key, value)
	end,
	__type = "LerpObject"
}

-- Create a lerp object
function lerpAPI:new(pos, stiff, damp, mass)
	
	-- Create object
	pos = pos or 0
	local obj = setmetatable(
		{
			prevTick = pos,
			currTick = pos,
			target   = pos,
			currPos  = pos,
			vel      = 0,
			stiff    = stiff or 0.2,
			damp     = damp or 1,
			mass     = mass or 1,
			enabled  = true
		},
		lerpMeta
	)
	
	-- Checks if mass is set to 0
	if mass == 0 then error("\n\n§6Mass cannot be 0.\n§c", 2) end
	
	-- Add object to list
	lerps[obj] = obj
	
	-- Return object
	return obj
	
end

-- Iterate through the lerps to set the next tick of each lerp
events.TICK:register(function()
	for _, obj in pairs(lerps) do
		if obj.enabled then
			
			-- Reset ticks
			obj.prevTick = obj.currTick
			
			-- Calc
			local fSpring = -obj.stiff * (obj.currTick - obj.target)
			local fDamp   = -obj.damp * obj.vel
			local acc     = (fSpring + fDamp) / obj.mass
			
			-- Apply
			obj.vel = obj.vel + acc
			obj.currTick = obj.currTick + obj.vel
			
		end
	end
end, "lerpTick")

-- Iterate through the lerps to smooth the lerp each frame
events.RENDER:register(function(delta, context)
	for _, obj in pairs(lerps) do
		if obj.enabled then
			
			-- Apply
			obj.currPos = math.lerp(obj.prevTick, obj.currTick, delta)
			
		end
	end
end, "lerpRender")

-- Sets enabled
function lerpInternal:setEnabled(bool)
	
	--[[
		Enabled:
		Determines if the lerp should function
		Saves on instructions if the lerp is not in use
	--]]
	self.enabled = bool
	
	-- Return object
	return self
	
end

-- Sets target
function lerpInternal:setTarget(val)
	
	--[[
		Target:
		The position the lerp will attempt to reach in a smooth manner
	--]]
	self.target = val
	
	-- Return object
	return self
	
end

-- Gets position
function lerpInternal:getPos()
	
	--[[
		Position:
		The current position of the lerp on its way to the target
	--]]
	return self.currPos
	
end

-- Sets stiffness
function lerpInternal:setStiff(val)
	
	--[[
		Stiffness:
		How fast the object moves towards its target (in percentage each tick)
		0 means it will never approach the target
		1 means it will reach the target within the tick
	--]]
	self.stiff = val
	
	-- Return object
	return self
	
end

-- Sets damping
function lerpInternal:setDamp(val)
	
	--[[
		Damping:
		How much an object is allowed to bounce around its target
		0 means it will never reach its target due to bouncing
		1 means it wont bounce around the target
	--]]
	self.damp = val
	
	-- Return object
	return self
	
end

-- Sets mass
function lerpInternal:setMass(val)
	
	--[[
		Mass:
		How long it takes for the object to change velocity
		Cannot have a mass of 0, otherwise divide by 0 errors will occur
		You can *still* do 0 by changing it in field, but ur asking for issues at that point
	--]] 
	if val == 0 then error("\n\n§6Mass cannot be 0.\n§c", 2) end
	self.mass = val
	
	-- Return object
	return self
	
end

-- Resets lerp, with optional target
function lerpInternal:reset(pos)
	
	--[[
		Lerp variables:
		The initial variables the lerp uses to control it position, in tick and render
	--]]
	pos = pos or 0
	self.prevTick = pos
	self.currTick = pos
	self.target   = pos
	self.currPos  = pos
	self.vel      = 0
	
	-- Return object
	return self
	
end

-- Flips velocity and "Bounces" position off of provided value
-- Great for creating limits to lerp when using spring lerping
function lerpInternal:bounce(val)
	
	-- Apply
	self.currTick = val
	self.vel = -self.vel
	
	-- Return object
	return self
	
end

-- Removes lerp
function lerpInternal:remove()
	
	lerps[self] = nil
	
end

-- Return API
return lerpAPI