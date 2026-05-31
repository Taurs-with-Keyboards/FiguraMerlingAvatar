-- LetThatSyncFig
-- By:
--   _________  ________  _________  ________  ___
--  |\___   ___\\   __  \|\___   ___\\   __  \|\  \
--  \|___ \  \_\ \  \|\  \|___ \  \_\ \  \|\  \ \  \
--       \ \  \ \ \  \\\  \   \ \  \ \ \   __  \ \  \
--        \ \  \ \ \  \\\  \   \ \  \ \ \  \ \  \ \  \____
--         \ \__\ \ \_______\   \ \__\ \ \__\ \__\ \_______\
--          \|__|  \|_______|    \|__|  \|__|\|__|\|_______|
--
-- Special thanks: Grandpa Scout, Pool & Mangodev
-- Version: 1.1.4

-- Create API
local syncAPI = {}

-- Syncs table
local syncs = {}

-- Interal sync data
local syncInternal = {}

-- Meta table setup
local syncMeta = {
	__index = syncInternal,
	__type = "SyncObject"
}

-- Type checker that errors if type isnt what's needed
local errorOverride = false -- Unique ID error message likes to fight the typeCheck error message for some reason, this prevents that
local function typeCheck(v, t)
	
	if type(v) ~= t then
		errorOverride = true
		error("\n\n§6Argument must be a "..t.."!\n§c", 3)
	end
	
end

-- Create a sync object
function syncAPI.new(id, ...)
	
	-- Check if the id is a string
	typeCheck(id, "string")
	
	-- Check if the id already exists
	for k, v in ipairs(syncs) do
		if v.id == id then
			if not errorOverride then
				error("\n\n§6ID must be unique!\n§c", 2)
			end
		end
	end
	
	-- Determine which value should be applied, checking for nil before returning
	local result
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if v ~= nil then
			result = v
		end
	end
	
	-- Create object
	local obj = setmetatable(
		{
			prev = result,
			curr = result,
			id = id
		},
		syncMeta
	)
	
	-- Add object to table
	table.insert(syncs, obj)
	
	-- Return object
	return obj
	
end

-- Sorts table deterministically
function events.ENTITY_INIT()
	
	-- Sorts table alphabetically
	table.sort(syncs, function(a, b)
		return a.id < b.id
	end)
	
	-- Grants each object a numerical id to be used when pinging
	for k, v in ipairs(syncs) do
		v.nid = k
	end
	
end

-- Updates sync values
local function updateValues(obj, v)
	
	-- Update current value
	obj.curr = v
	
	-- If value changed, preform the update
	if obj.curr ~= obj.prev then
		
		-- Preform optional function if it exists
		if obj.fn then obj.fn() end
		
		-- Update config if it exists
		if obj.cfg ~= nil then config:save(obj.cfg, v) end
		
		-- Update previous value
		obj.prev = v
		
	end
	
end

-- Sync variable via ping
function pings.sendSyncUpdate(k, v)
	
	-- Find sync object
	local obj = syncs[k]
	
	-- Update values
	updateValues(obj, v)
	
end

-- Sync ALL variables via ping
function pings.sendSyncUpdateAll(...)
	
	for k, v in ipairs({...}) do
		
		-- Find sync object
		local obj = syncs[k]
		
		-- Update values
		updateValues(obj, v)
		
	end
	
end

-- Update a sync object
function syncInternal:update(v, buffer)
	
	-- Check if change occured, and send ping
	-- Prevents spam caused by user
	if v ~= self.prev then
		
		-- If a buffer is provided
		if buffer ~= nil then
			
			-- Check if buffer is a number
			typeCheck(buffer, "number")
			
			-- Update on host only
			-- Ping will instead be sent when timer is decreased below
			self.timer = buffer
			updateValues(self, v)
			
			-- Return object
			return self
			
		end
		
		-- Send ping
		pings.sendSyncUpdate(self.nid, v)
		
	end
	
	-- Return object
	return self
	
end

-- Apply a function
function syncInternal:applyFunc(func)
	
	-- Checks if function is actually a function
	typeCheck(func, "function")
	
	-- Apply function to sync
	self.fn = func
	
	-- Return object
	return self
	
end

-- Apply a config key
function syncInternal:config(cfgName)
	
	-- Kill function if not host
	if not host:isHost() then return self end
	
	-- Check if the name is a string
	if cfgName ~= nil then
		typeCheck(cfgName, "string")
	end
	
	-- Apply config to sync
	self.cfg = cfgName or self.id
	
	-- Get config value
	local cfgValue = config:load(self.cfg)
	
	-- Update object if config has value
	if cfgValue ~= nil then
		updateValues(self, cfgValue)
	end
	
	-- Return object
	return self
	
end

-- Host only instructions
if not host:isHost() then return syncAPI end

-- Sync on tick
events.TICK:register(function()
	
	-- Sync variables
	if world.getTime() % 200 == 0 then
		
		-- Gather values
		local syncTables = {} 
		for k, v in ipairs(syncs) do
			syncTables[k] = v.curr
		end
		
		-- Send values
		pings.sendSyncUpdateAll(table.unpack(syncTables))
		
	end
	
	-- Countdown buffers
	for k, v in ipairs(syncs) do
		if v.timer then
			
			-- Decrement timer
			v.timer = math.max(v.timer - 1, 0)
			
			-- If timer is 0, send ping
			if v.timer == 0 then
				v.timer = nil
				pings.sendSyncUpdate(v.nid, v.curr)
			end
			
		end
	end
	
end, "tickSync")

-- Return API
return syncAPI