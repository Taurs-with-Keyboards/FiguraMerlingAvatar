-- Required scripts
local parts = require("lib.PartsAPI")
local sync  = require("lib.LetThatSyncFig")
local lerp  = require("lib.LerpAPI")
local tail  = require("scripts.Tail")

-- Synced variables setup
local toggle  = sync.new("GlowToggle", true):config()
local dynamic = sync.new("GlowDynamic", false):config()
local water   = sync.new("GlowWater", false):config()
local unique  = sync.new("GlowUnique", false):config()

-- Glowing parts
local glowingParts = parts:createTable(function(part) return part:getName():find("_[gG]low") end)

for i, part in ipairs(glowingParts) do
	
	glowingParts[i] = {
		part   = part,
		splash = false,
		timer  = 0,
		glow   = lerp.new(toggle.curr and 1 or 0)
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
		
		if toggle.curr and index.part:getVisible() then
			
			-- Init apply
			index.glow.target = 1
			
			-- Get pos
			local pos = unique.curr and index.part:getParent():partToWorldMatrix():apply() or player:getPos()
			
			-- Light level check
			if dynamic.curr then
				
				-- Variable
				local light = math.map(world.getLightLevel(pos), 0, 15, 1, 0)
				
				-- Apply
				index.glow.target = index.glow.target * light
				
			end
			
			-- Water check
			if water.curr then
				
				-- Variables
				local wet = false
				
				if unique.curr then
					
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

-- Apply sound function
toggle:applyFunc(function()
	if player:isLoaded() and toggle.curr then
		sounds:playSound("entity.glow_squid.ambient", player:getPos(), 0.75)
	end
end)

-- Host only instructions
if not host:isHost() then return end

-- Apply sound functions
dynamic:applyFunc(function()
	if player:isLoaded() and dynamic.curr then
		sounds:playSound("entity.generic.drink", player:getPos(), 0.35)
	end
end)
water:applyFunc(function()
	if player:isLoaded() and water.curr then
		sounds:playSound("ambient.underwater.enter", player:getPos(), 0.35)
	end
end)

-- Required script
local keybound = require("lib.Keybound")

-- Setup keybind
local toggleKeybind = keybound.new(
	keybinds
		:newKeybind("Glow Toggle", "key.keyboard.keypad.4")
		:onPress(function() toggle:update(not toggle.curr) end),
	"GlowToggleKeybind"
)

-- Required script
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found

-- Pages
local parentPage = action_wheel:getPage("Main")
local glowPage   = action_wheel:newPage("Glow")

-- Actions table setup
local a = {}

-- Actions
a.pageAct = parentPage:newAction()
	:item("glow_ink_sac")
	:onLeftClick(function() wheel:descend(glowPage) end)

a.toggleAct = glowPage:newAction()
	:item("ink_sac")
	:toggleItem("glow_ink_sac")
	:onToggle(function(bool)
		toggle:update(bool)
	end)

a.dynamicAct = glowPage:newAction()
	:item("light")
	:onToggle(function(bool)
		dynamic:update(bool)
	end)
	:toggled(dynamic.curr)

a.waterAct = glowPage:newAction()
	:item("bucket")
	:toggleItem("water_bucket")
	:onToggle(function(bool)
		water:update(bool)
	end)
	:toggled(water.curr)

a.uniqueAct = glowPage:newAction()
	:item("prismarine_shard")
	:toggleItem("prismarine_crystals")
	:onToggle(function(bool)
		unique:update(bool)
	end)
	:toggled(unique.curr)

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
			:toggled(toggle.curr)
		
		a.dynamicAct
			:title(toJson(
				{
					"",
					{text = "Toggle Dynamic Glowing\n\n", bold = true, color = c.primary},
					{text = "Toggles glowing based on lightlevel.\nThe darker the location, the brighter your tail glows.", color = c.secondary}
				}
			))
			:toggleItem("light{BlockStateTag:{level:"..math.map(world.getLightLevel(player:getPos()), 0, 15, 15, 0).."}}")
		
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