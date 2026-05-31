-- Required scripts
local parts   = require("lib.PartsAPI")
local sync    = require("lib.LetThatSyncFig")
local lerp    = require("lib.LerpAPI")
local origins = require("lib.OriginsAPI")
local effects = require("scripts.SyncedVariables")

-- Synced variables setup
local toggle      = sync.new("EyesToggle", false):config()
local power       = sync.new("EyesPower", false):config()
local nightVision = sync.new("EyesNightVision", false):config()
local water       = sync.new("EyesWater", false):config()

-- Glowing parts
local glowingParts = parts:createTable(function(part) return part:getName():find("_[eE]ye[gG]low") end)

-- Lerp eyes table
local eyes = lerp.new(toggle.curr and 1 or 0)

function events.TICK()
	
	-- Set eyes target
	-- Toggle check
	if toggle.curr then
		
		eyes.target = 1
		
		-- Origins check
		if power.curr then
			eyes.target = origins.getPowerData(player)["origins:water_vision"] == 1 and eyes.target or 0
		end
		
		-- Night Vision check
		if nightVision.curr then
			eyes.target = effects.nV and 1 or eyes.target
			if effects.nV then goto skip end
		end
		
		-- Water check
		if water.curr then
			eyes.target = not (water.curr and not player:isUnderwater()) and eyes.target or 0
		end
		
		-- Skips water check if night vision confirmed
		::skip::
		
	else
		
		eyes.target = 0
		
	end
	
end

function events.RENDER(delta, context)
	
	-- Apply
	local renderType = context == "RENDER" and "EMISSIVE" or "EYES"
	for _, part in ipairs(glowingParts) do
		part
			:secondaryColor(eyes.currPos)
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
power:applyFunc(function()
	if player:isLoaded() and power.curr then
		sounds:playSound("entity.puffer_fish.flop", player:getPos())
	end
end)
nightVision:applyFunc(function()
	if player:isLoaded() and nightVision.curr then
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
		:newKeybind("Glowing Eyes Toggle", "key.keyboard.keypad.5")
		:onPress(function() toggle:update(not toggle.curr) end),
	"EyesToggleKeybind"
)

-- Required scripts
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.GlowingTail") -- Tries to find script, not required

-- Pages
local parentPage = action_wheel:getPage("Glow") or action_wheel:getPage("Main")
local glowEyesPage = action_wheel:newPage("GlowEyes")

-- Actions table setup
local a = {}

-- Actions
a.pageAct = parentPage:newAction()
	:item("ender_eye")
	:onLeftClick(function() wheel:descend(glowEyesPage) end)

a.toggleAct = glowEyesPage:newAction()
	:item("ender_pearl")
	:toggleItem("ender_eye")
	:onToggle(function(bool)
		toggle:update(bool)
	end)

a.powerAct = glowEyesPage:newAction()
	:item("cod")
	:toggleItem("tropical_fish")
	:onToggle(function(bool)
		power:update(bool)
	end)
	:toggled(power.curr)

a.nightVisionAct = glowEyesPage:newAction()
	:item("glass_bottle")
	:toggleItem("potion{CustomPotionColor:" .. tostring(0x96C54F) .. "}")
	:onToggle(function(bool)
		nightVision:update(bool)
	end)
	:toggled(nightVision.curr)

a.waterAct = glowEyesPage:newAction()
	:item("bucket")
	:toggleItem("water_bucket")
	:onToggle(function(bool)
		water:update(bool)
	end)
	:toggled(water.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		a.pageAct
			:title(toJson(
				{text = "Glowing Eyes Settings", bold = true, color = c.primary}
			))
		
		a.toggleAct
			:title(toJson(
				{
					"",
					{text = "Toggle Glowing Eyes\n\n", bold = true, color = c.primary},
					{text = "Toggles the glowing of the eyes.\n\n", color = c.secondary},
					{text = "WARNING: ", bold = true, color = "dark_red"},
					{text = "This feature has a tendency to not work correctly.\nDue to the rendering properties of emissives, the eyes may not glow.\nIf it does not work, please reload the avatar. Rinse and Repeat.\nThis is the only fix, I have tried everything.\n\n- Total", color = "red"}
				}
			))
			:toggled(toggle.curr)
		
		a.powerAct
			:title(toJson(
				{
					"",
					{text = "Origins Power Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the glowing based on Origin\'s underwater sight power.\nThe eyes will only glow when this power is active.", color = c.secondary}
				}
			))
		
		a.nightVisionAct
			:title(toJson(
				{
					"",
					{text = "Night Vision Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the glowing based on having the Night Vision effect.\nThis setting will ", color = c.secondary},
					{text = "OVERRIDE ", bold = true, color = c.secondary},
					{text = "the other subsettings.", color = c.secondary}
				}
			))
		
		a.waterAct
			:title(toJson(
				{
					"",
					{text = "Water Sensitivity Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the glowing sensitivity to water.\nThe eyes will only glow when underwater.", color = c.secondary}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end