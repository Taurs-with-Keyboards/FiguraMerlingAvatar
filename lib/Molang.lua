-- Molang to Lua conversions
Math = {
	sin = function(a)
		return math.sin(math.rad(a))
	end,
	cos = function(a)
		return math.cos(math.rad(a))
	end
}

-- Allow q.anim_time to be interpreted as anim:getTime()
q = {}
local anim
setmetatable(q, {
	__index = function(t, i)
		if i == "anim_time" then
			return anim:getTime()
		end
	end,
		__call = function(t, _, a)
		anim = a
		return 0
	end 
})