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
-- Special thanks: Grandpa Scout & Pool
-- Version: 1.0.4

-- Config setup
config:name("Merling")

-- Create table
local sync = {}

-- Determine which value should be applied, checking for nil before applying
function sync.pick(...)
	
	-- Determine result
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if v ~= nil then
			return v
		end
	end
	
end

-- Adds variable to table under new index, and provides index for access later
function sync.add(...)
	
	-- New index number
	local n = #sync + 1
	
	-- Create synced variable
	sync[n] = sync.pick(...)
	
	-- Return index number
	return n
	
end

-- Sync variables via ping
function pings.syncVars(...)
	
	for i, v in ipairs({...}) do
		sync[i] = v
	end
	
end

-- Host only instructions
if not host:isHost() then return sync end

-- Create keybinds table
local keys = {}

-- Stores keybind in table while creating for syncing config with current state
function sync.keybind(keybind, configName)
	
	-- Attach bind
	keybind:key(config:load(configName) or keybind:getKey())
	
	-- Store keybind 
	keys[keybind] = {
		config = configName,
		key = keybind:getKey()
	}
	
end

-- Sync on tick
events.TICK:register(function()
	
	-- Syncs variables
	if world.getTime() % 200 == 0 then
		pings.syncVars(table.unpack(sync))
	end
	
	-- Syncs keybinds to configs
	if host:getScreen() == "org.figuramc.figura.gui.screens.KeybindScreen" then
		for k, v in pairs(keys) do
			
			-- Get current key
			local key = k:getKey()
			
			-- Compare keys
			if v.key ~= key then
				
				-- Save to config
				config:save(v.config, key)
				
				-- Store data
				v.key = key
				
			end
			
		end
	end
	
end, "tickSync")

-- Return table
return sync