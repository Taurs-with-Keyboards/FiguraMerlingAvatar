-- Required scripts
local parts = require("lib.PartsAPI")
local lerp  = require("lib.LerpAPI")
local tail  = require("scripts.Tail")

-- Config setup
config:name("Merling")
local toggle  = config:load("GlowToggle")
local dynamic = config:load("GlowDynamic") or false
local water   = config:load("GlowWater") or false
local unique  = config:load("GlowUnique") or false
if toggle == nil then toggle = true end

-- Glowing parts
local glowingParts = parts:createTable(function(part) return part:getName():find("_[gG]low") end)

for i, part in ipairs(glowingParts) do
	
	glowingParts[i] = {
		part   = part,
		splash = false,
		timer  = 0,
		glow   = lerp:new(0.2, toggle and 1 or 0)
	}
	
end

-- Check if a splash potion is broken near a part
function events.ON_PLAY_SOUND(id, pos, vol, pitch, loop, category, path)
	
	if player:isLoaded() then
		for _, index in ipairs(glowingParts) do
			local partPos  = index.part:getParent():partToWorldMatrix():apply()
			local atPos    = pos < partPos + 1.5 and pos > partPos - 1.5
			local splashID = id == "minecraft:entity.splash_potion.break" or id == "minecraft:entity.lingering_potion.break"
			index.splash = atPos and splashID and path
		end
	end
	
end

-- Gradual values
function events.TICK()
	
	-- Arm variables
	local handedness  = player:isLeftHanded()
	local activeness  = player:getActiveHand()
	local leftActive  = not handedness and "OFF_HAND" or "MAIN_HAND"
	local rightActive = handedness and "OFF_HAND" or "MAIN_HAND"
	local leftItem    = player:getHeldItem(not handedness)
	local rightItem   = player:getHeldItem(handedness)
	local using       = player:isUsingItem()
	local drinkingL   = activeness == leftActive and using and leftItem:getUseAction() == "DRINK"
	local drinkingR   = activeness == rightActive and using and rightItem:getUseAction() == "DRINK"
	
	-- Control how fast drying occurs
	local dryRate = player:getItem(1).id == "minecraft:sponge" and 10 or 1
	
	-- Zero check
	local modDryTimer = math.max(tail.dry, 1)
	
	-- Set glow target
	-- Toggle check
	for _, index in ipairs(glowingParts) do
		
		if toggle and index.part:getVisible() then
			
			-- Init apply
			index.glow.target = 1
			
			-- Get pos
			local pos = unique and index.part:getParent():partToWorldMatrix():apply() or player:getPos()
			
			-- Light level check
			if dynamic then
				
				-- Variable
				local light = math.map(world.getLightLevel(pos), 0, 15, 1, 0)
				
				-- Apply
				index.glow.target = index.glow.target * light
				
			end
			
			-- Water check
			if water then
				
				-- Variables
				local wet = false
				
				if unique then
					
					-- Check fluid tags
					local block = world.getBlockState(pos)
					for _, tag in ipairs(block:getFluidTags()) do
						if tag then
							wet = true
							break
						end
					end
					
					-- Check drinking water
					if (drinkingL or drinkingR) and player:getActiveItemTime() > 20
						or world.getRainGradient() > 0.2 and world.isOpenSky(pos) and world.getBiome(pos):getPrecipitation() == "RAIN"
						or index.splash then
						
						wet = true
						index.splash = false
						
					end
					
				else
					
					wet = player:isWet() or (drinkingL or drinkingR) and player:getActiveItemTime() > 20
					
				end
				
				-- Adjust timer
				if wet then
					index.timer = modDryTimer
				else
					index.timer = math.clamp(index.timer - 1 * dryRate, 0, modDryTimer)
				end
				
				-- Apply
				index.glow.target = index.glow.target * (index.timer / modDryTimer)
				
			end
			
		else
			
			-- Apply
			index.glow.target = 0
			
		end
		
		index.glow.enabled = index.part:getVisible()
	end
	
end

function events.RENDER(delta, context)
	
	-- Check render type
	local renderType = context == "RENDER" and "EMISSIVE" or "EYES"
	
	for _, index in ipairs(glowingParts) do
		
		-- Apply
		index.part
			:secondaryColor(index.glow.currPos)
			:secondaryRenderType(renderType)
		
	end
	
end

-- Glow toggle
function pings.setGlowToggle(boolean)
	
	toggle = boolean
	config:save("GlowToggle", toggle)
	if player:isLoaded() and toggle then
		sounds:playSound("entity.glow_squid.ambient", player:getPos(), 0.75)
	end
	
end

-- Dynamic toggle
function pings.setGlowDynamic(boolean)
	
	dynamic = boolean
	config:save("GlowDynamic", dynamic)
	if host:isHost() and player:isLoaded() and dynamic then
		sounds:playSound("entity.generic.drink", player:getPos(), 0.35)
	end
	
end

-- Water toggle
function pings.setGlowWater(boolean)
	
	water = boolean
	config:save("GlowWater", water)
	if host:isHost() and player:isLoaded() and water then
		sounds:playSound("ambient.underwater.enter", player:getPos(), 0.35)
	end
	
end

-- Unique toggle
function pings.setGlowUnique(boolean)
	
	unique = boolean
	config:save("GlowUnique", unique)
	
end

-- Sync variables
function pings.syncGlow(a, b, c, d)
	
	toggle  = a
	dynamic = b
	water   = c
	unique  = d
	
end

-- Host only instructions
if not host:isHost() then return end

-- Glow keybind
local toggleBind   = config:load("GlowToggleKeybind") or "key.keyboard.keypad.4"
local setToggleKey = keybinds:newKeybind("Glow Toggle"):onPress(function() pings.setGlowToggle(not toggle) end):key(toggleBind)

-- Keybind updater
function events.TICK()
	
	local key = setToggleKey:getKey()
	if key ~= toggleBind then
		toggleBind = key
		config:save("GlowToggleKeybind", key)
	end
	
end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncGlow(toggle, dynamic, water, unique)
	end
	
end

-- Required script
local s, wheel, itemCheck, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found

-- Pages
local parentPage = action_wheel:getPage("Main")
local glowPage   = action_wheel:newPage("Glow")

-- Actions table setup
local a = {}

-- Actions
a.pageAct = parentPage:newAction()
	:item(itemCheck("glow_ink_sac"))
	:onLeftClick(function() wheel:descend(glowPage) end)

a.toggleAct = glowPage:newAction()
	:item(itemCheck("ink_sac"))
	:toggleItem(itemCheck("glow_ink_sac"))
	:onToggle(pings.setGlowToggle)

a.dynamicAct = glowPage:newAction()
	:item(itemCheck("light"))
	:onToggle(pings.setGlowDynamic)
	:toggled(dynamic)

a.waterAct = glowPage:newAction()
	:item(itemCheck("bucket"))
	:toggleItem(itemCheck("water_bucket"))
	:onToggle(pings.setGlowWater)
	:toggled(water)

a.uniqueAct = glowPage:newAction()
	:item(itemCheck("prismarine_shard"))
	:toggleItem(itemCheck("prismarine_crystals"))
	:onToggle(pings.setGlowUnique)
	:toggled(unique)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		a.pageAct
			:title(toJson(
				{text = "Glowing Settings", bold = true, color = c.primary}
			))
		
		a.toggleAct
			:title(toJson(
				{
					"",
					{text = "Toggle Glowing\n\n", bold = true, color = c.primary},
					{text = "Toggles glowing for the tail, and misc parts.\n\n", color = c.secondary},
					{text = "WARNING: ", bold = true, color = "dark_red"},
					{text = "This feature has a tendency to not work correctly.\nDue to the rendering properties of emissives, the tail may not glow.\nIf it does not work, please reload the avatar. Rinse and Repeat.\nThis is the only fix, I have tried everything.\n\n- Total", color = "red"}
				}
			))
			:toggled(toggle)
		
		a.dynamicAct
			:title(toJson(
				{
					"",
					{text = "Toggle Dynamic Glowing\n\n", bold = true, color = c.primary},
					{text = "Toggles glowing based on lightlevel.\nThe darker the location, the brighter your tail glows.", color = c.secondary}
				}
			))
			:toggleItem(itemCheck("light{BlockStateTag:{level:"..math.map(world.getLightLevel(player:getPos()), 0, 15, 15, 0).."}}"))
		
		a.waterAct
			:title(toJson(
				{
					"",
					{text = "Toggle Water Glowing\n\n", bold = true, color = c.primary},
					{text = "Toggles the glowing sensitivity to water.\nAny water will cause your tail to glow.", color = c.secondary}
				}
			))
		
		a.uniqueAct
			:title(toJson(
				{
					"",
					{text = "Toggle Unique Glowing\n\n", bold = true, color = c.primary},
					{text = "Toggles the individual glowing of each part.\nThis relies on the other settings to be noticeable.", color = c.secondary}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end