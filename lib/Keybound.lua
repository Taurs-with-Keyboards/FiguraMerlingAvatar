-- Keybound
-- By:
--   _________  ________  _________  ________  ___
--  |\___   ___\\   __  \|\___   ___\\   __  \|\  \
--  \|___ \  \_\ \  \|\  \|___ \  \_\ \  \|\  \ \  \
--       \ \  \ \ \  \\\  \   \ \  \ \ \   __  \ \  \
--        \ \  \ \ \  \\\  \   \ \  \ \ \  \ \  \ \  \____
--         \ \__\ \ \_______\   \ \__\ \ \__\ \__\ \_______\
--          \|__|  \|_______|    \|__|  \|__|\|__|\|_______|
--
-- Version: 1.0.2

-- Host only instructions
if not host:isHost() then return end

-- Create API
local keyAPI = {}

-- Keys table
local keys = {}

-- Store a new keybind
function keyAPI.new(keybind, cfgName)
	
	-- Attach bind
	keybind:key(config:load(cfgName) or keybind:getKey())
	
	-- Store keybind
	keys[keybind] = {
		key = keybind:getKey(),
		cfg = cfgName
	}
	
	-- Return keybind
	return keybind
	
end

-- Sync on tick
events.TICK:register(function()
	if host:getScreen() == "org.figuramc.figura.gui.screens.KeybindScreen" then
		for k, v in pairs(keys) do
			
			-- Get current key
			local key = k:getKey()
			
			-- Compare keys
			if v.key ~= key then
				
				-- Save to config
				config:save(v.cfg, key)
				
				-- Store data
				v.key = key
				
			end
			
		end
	end
end, "tickKeys")

-- Return API
return keyAPI