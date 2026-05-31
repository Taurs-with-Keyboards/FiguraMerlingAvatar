-- Required scripts
local parts   = require("lib.PartsAPI")
local sync    = require("lib.LetThatSyncFig")
local lerp    = require("lib.LerpAPI")
local ground  = require("lib.GroundCheck")
local effects = require("scripts.SyncedVariables")

-- Synced variables setup
local tailType  = sync.new("TailType", 4):config()
local earsType  = sync.new("TailEarsType", tailType.curr):config()
local small     = sync.new("TailSmall", true):config()
local smallSize = sync.new("TailSmallSize", 0.6):config()
local dryTimer  = sync.new("TailDryTimer", 400):config()
local legsForm  = sync.new("TailLegsForm", 0.75):config()
local gradual   = sync.new("TailGradual", true):config()
local fallSound = sync.new("TailFallSound", true):config()

-- Variables setup
local tailTimer = 0
local earsTimer = 0
local wasInAir  = false

-- Lerp variables
local scale = {
	tail = lerp.new(tailType.curr == 5 and 1 or 0),
	legs = lerp.new(tailType.curr ~= 5 and 1 or 0),
	ears = lerp.new(earsType.curr == 5 and 1 or 0)
}

-- Data sent to other scripts
local tailData = {
	isLarge = tailTimer >  (dryTimer.curr * legsForm.curr),
	isSmall = tailTimer <= (dryTimer.curr * legsForm.curr) and scale.tail.currTick > 0.01,
	dry     = dryTimer.curr,
	scale   = scale.tail.currPos,
	legs    = scale.legs.currPos
}

-- Check if a splash potion is broken near the player
local splashed = false
function events.ON_PLAY_SOUND(id, pos, vol, pitch, loop, category, path)
	
	-- Don't trigger if the sound was played by Figura
	if not path then return end
	
	-- Don't do anything if the user isn't loaded
	if not player:isLoaded() then return end
	
	-- Make sure the sound is happening near the player
	if (player:getPos() - pos):length() > 2 then return end
	
	-- If sound contains "potion.break", and the user isnt already splashed, consider the user splashed
	if id:find("potion.break") and not splashed then
		splashed = true
	end
	
end

-- Water state table
local waterTypes = {
	{
		check = function()
			return false
		end
	},
	{
		dry = true,
		check = function()
			return player:isUnderwater() or world.getBlockState(player:getPos() + vec(0, player:getEyeHeight(), 0)).id == "minecraft:lava"
		end
	},
	{
		dry = true,
		check = function()
			return player:isInWater() or player:isInLava()
		end
	},
	{
		dry = true,
		check = function()
			return player:isWet() or (player:getActiveItem():getUseAction() == "DRINK" and player:getActiveItemTime() > 20) or splashed or player:isInLava()
		end
	},
	{
		check = function()
			return true
		end
	}
}

function events.TICK()
	
	-- Control how fast drying occurs
	local dryRate = player:getItem(1).id == "minecraft:sponge" and 10 or 1
	
	-- Timers
	tailTimer = waterTypes[tailType.curr].check() and dryTimer.curr or waterTypes[tailType.curr].dry and math.clamp(tailTimer - dryRate, 0, dryTimer.curr) or 0
	earsTimer = waterTypes[earsType.curr].check() and dryTimer.curr or waterTypes[earsType.curr].dry and math.clamp(earsTimer - dryRate, 0, dryTimer.curr) or 0
	
	-- Targets
	scale.tail.target = gradual.curr and tailTimer / math.max(dryTimer.curr, 1) or tailTimer ~= 0 and 1 or 0
	scale.ears.target = gradual.curr and earsTimer / math.max(dryTimer.curr, 1) or earsTimer ~= 0 and 1 or 0
	scale.legs.target = tailTimer <= (dryTimer.curr * legsForm.curr) and 1 or 0
	
	-- Modify tail target
	if small.curr then
		scale.tail.target = math.map(scale.tail.target, 0, 1, smallSize.curr, 1)
	end
	
	-- Play sound if conditions are met
	if fallSound.curr and wasInAir and ground() and scale.legs.target ~= 1 and not player:getVehicle() and not player:isInWater() and not effects.cF then
		local vel    = math.abs(-player:getVelocity().y + 1)
		local dry    = scale.tail.currPos
		local volume = math.clamp((vel * dry) / 2, 0, 1)
		
		if volume ~= 0 then
			sounds:playSound("entity.puffer_fish.flop", player:getPos(), volume, math.map(volume, 1, 0, 0.45, 0.65))
		end
	end
	wasInAir = not ground()
	
	-- Disable splashed after check
	if splashed then
		splashed = false
	end
	
	-- Update tail data
	tailData.isLarge = tailTimer >  (dryTimer.curr * legsForm.curr)
	tailData.isSmall = tailTimer <= (dryTimer.curr * legsForm.curr) and scale.tail.currTick > 0.01
	tailData.dry     = dryTimer.curr
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local tailApply = scale.tail.currPos
	local legsApply = scale.legs.currPos
	local earsApply = scale.ears.currPos
	
	-- Apply tail
	parts.group.Tail1:scale(tailApply)
	
	-- Apply legs
	parts.group.LeftLeg:scale(legsApply)
	parts.group.RightLeg:scale(legsApply)
	
	-- Apply ears
	parts.group.LeftEar:scale(earsApply)
	parts.group.RightEar:scale(earsApply)
	
	-- Update tail data
	tailData.scale = tailApply
	tailData.legs  = legsApply
	
end

-- Host only instructions, return tail data
if not host:isHost() then return tailData end

-- Play sound if type is changed
local function typeChangeSound()
	if player:isLoaded() then
		sounds:playSound("ambient.underwater.enter", player:getPos(), 0.35)
	end
end

-- Apply sound functions
tailType:applyFunc(typeChangeSound)
earsType:applyFunc(typeChangeSound)
fallSound:applyFunc(function()
	if player:isLoaded() and fallSound.curr then
		sounds:playSound("entity.puffer_fish.flop", player:getPos(), 0.35, 0.6)
	end
end)

-- Required script
local keybound = require("lib.Keybound")

-- Setup keybinds
local tailKeybind = keybound.new(
	keybinds
		:newKeybind("Tail Sensitivity Type", "key.keyboard.keypad.1")
		:onPress(function() tailType:update((tailType.curr % #waterTypes) + 1) end),
	"TailTypeKeybind"
)
local earsKeybind = keybound.new(
	keybinds
		:newKeybind("Ears Sensitivity Type", "key.keyboard.keypad.2")
		:onPress(function() earsType:update((earsType.curr % #waterTypes) + 1) end),
	"EarsTypeKeybind"
)
local smallKeybind = keybound.new(
	keybinds
		:newKeybind("Small Tail Toggle", "key.keyboard.keypad.3")
		:onPress(function() small:update(not small.curr) end),
	"TailSmallKeybind"
)

-- Required script
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return tailData end -- Kills script early if ActionWheel.lua isnt found

-- Pages
local parentPage = action_wheel:getPage("Main")
local tailPage   = action_wheel:newPage("Tail")
local dryPage    = action_wheel:newPage("Dry")

-- Actions table setup
local a = {}

-- Set sensitivity type
local function setSensitivityType(part, x)
	return ((part + x - 1) % #waterTypes) + 1
end

-- Actions
a.tailPageAct = parentPage:newAction()
	:item("tropical_fish")
	:onLeftClick(function() wheel:descend(tailPage) end)

a.tailAct = tailPage:newAction()
	:onLeftClick(function() tailType:update(setSensitivityType(tailType.curr, 1)) end)
	:onRightClick(function() tailType:update(setSensitivityType(tailType.curr, -1)) end)
	:onScroll(function(x) tailType:update(setSensitivityType(tailType.curr, x), 20) end)

a.earsAct = tailPage:newAction()
	:onLeftClick(function() earsType:update(setSensitivityType(earsType.curr, 1)) end)
	:onRightClick(function() earsType:update(setSensitivityType(earsType.curr, -1)) end)
	:onScroll(function(x) earsType:update(setSensitivityType(earsType.curr, x), 20) end)

a.smallAct = tailPage:newAction()
	:item("small_amethyst_bud")
	:onToggle(function(bool)
		small:update(bool)
	end)
	:onScroll(function(x)
		smallSize:update(math.clamp(smallSize.curr + (x * 0.05), 0.25, 1), 20)
	end)

a.dryPageAct = tailPage:newAction()
	:item("sponge")
	:onLeftClick(function() wheel:descend(dryPage) end)

a.dryAct = dryPage:newAction()
	:onScroll(function(x)
		dryTimer:update(math.clamp(dryTimer.curr + (x * 20), 0, 72000), 20)
	end)
	:onLeftClick(function() dryTimer:update(400) end)

a.legsAct = dryPage:newAction()
	:item("rabbit_foot")
	:onScroll(function(x)
		legsForm:update(math.clamp(legsForm.curr + (x * 0.05), 0.25, 0.9), 20)
	end)

a.gradualAct = dryPage:newAction()
	:item("sugar")
	:toggleItem("fermented_spider_eye")
	:onToggle(function(bool)
		gradual:update(bool)
	end)
	:toggled(gradual.curr)

a.soundAct = dryPage:newAction()
	:item("bucket")
	:toggleItem("water_bucket")
	:onToggle(function(bool)
		fallSound:update(bool)
	end)
	:toggled(fallSound.curr)

-- Water context info table
local waterInfo = {
	{
		title = {label = {text = "None", color = "red"}, text = "Cannot form."},
		item  = "glass_bottle",
		color = "FF5555"
	},
	{
		title = {label = {text = "Low", color = "yellow"}, text = "Reactive to being underwater."},
		item  = "potion",
		color = "FFFF55"
	},
	{
		title = {label = {text = "Medium", color = "green"}, text = "Reactive to being in water."},
		item  = "splash_potion",
		color = "55FF55"
	},
	{
		title = {label = {text = "High", color = "aqua"}, text = "Reactive to any form of water."},
		item  = "lingering_potion",
		color = "55FFFF"
	},
	{
		title = {label = {text = "Max", color = "blue"}, text = "Always active."},
		item  = "dragon_breath",
		color = "5555FF"
	}
}

-- Creates a clock string
local function timeStr(s)

	local min = s >= 60
		and ("%d Minute%s"):format(s / 60, s >= 120 and "s" or "")
		or nil
	
	local sec = ("%d Second%s"):format(s % 60, s % 60 == 1 and "" or "s")
	
	return min and (min.." "..sec) or sec
	
end

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		a.tailPageAct
			:title(toJson(
				{text = "Tail Settings", bold = true, color = c.primary}
			))
		
		local actionSetup = waterInfo[tailType.curr]
		a.tailAct
			:title(toJson(
				{
					"",
					{text = "Tail Water Sensitivity\n\n", bold = true, color = c.primary},
					{text = "Determines how your tail should form in contact with water.\n\n", color = c.secondary},
					{text = "Current configuration: ", bold = true, color = c.secondary},
					{text = actionSetup.title.label.text, color = actionSetup.title.label.color},
					{text = " | "},
					{text = actionSetup.title.text, color = c.secondary}
				}
			))
			:color(vectors.hexToRGB(actionSetup.color))
			:item(actionSetup.item.."{CustomPotionColor:"..tostring(0x0094FF).."}")
		
		local actionSetup = waterInfo[earsType.curr]
		a.earsAct
			:title(toJson(
				{
					"",
					{text = "Ears Water Sensitivity\n\n", bold = true, color = c.primary},
					{text = "Determines how your ears should form in contact with water.\n\n", color = c.secondary},
					{text = "Current configuration: ", bold = true, color = c.secondary},
					{text = actionSetup.title.label.text, color = actionSetup.title.label.color},
					{text = " | "},
					{text = actionSetup.title.text, color = c.secondary}
				}
			))
			:color(vectors.hexToRGB(actionSetup.color))
			:item(actionSetup.item.."{CustomPotionColor:"..tostring(0x0094FF).."}")
		
		a.smallAct
			:title(toJson(
				{
					"",
					{text = "Toggle Small Tail\n\n", bold = true, color = c.primary},
					{text = "Toggles the appearence of the tail into a smaller tail, only if the tail cannot form.\nScroll to control the size of the small tail.\n\n", color = c.secondary},
					{text = "Small tail size:\n", bold = true, color = c.secondary},
					{text = math.round(smallSize.curr * 100).."% Size"}
				}
			))
			:toggleItem(
				smallSize.curr > 0.75 and "amethyst_cluster" or
				smallSize.curr > 0.5 and "large_amethyst_bud" or
				"medium_amethyst_bud"
			)
			:toggled(small.curr)
		
		a.dryPageAct
			:title(toJson(
				{text = "Drying Settings", bold = true, color = c.primary}
			))
		
		-- Timers
		local timers = {
			set  = dryTimer.curr / 20,
			legs = gradual.curr and math.max(math.ceil((tailTimer - (dryTimer.curr * legsForm.curr)) / 20), 0) or nil,
			tail = math.ceil(tailTimer / 20),
			ears = math.ceil(earsTimer / 20)
		}
		
		-- Countdowns
		local cD = {}
		for k, v in pairs(timers) do
			cD[k] = timeStr(v)
		end
		
		a.dryAct
			:title(toJson(
				{
					"",
					{text = "Set Drying Timer\n\n", bold = true, color = c.primary},
					{text = "Scroll to adjust how long it takes for you to dry.\nLeft click resets timer to 20 seconds.\n\n", color = c.secondary},
					{text = "Drying timer:\n", bold = true, color = c.secondary},
					{text = cD.set.."\n\n"},
					{text = cD.legs and "Legs form:\n" or "", bold = true, color = c.secondary},
					{text = cD.legs and (cD.legs.."\n\n") or ""},
					{text = "Tail fully dry:\n", bold = true, color = c.secondary},
					{text = cD.tail.."\n\n"},
					{text = "Ears fully dry:\n", bold = true, color = c.secondary},
					{text = cD.ears.."\n\n"},
					{text = "Hint: Holding a dry sponge will increase drying rate by x10!", color = "gray"}
				}
			))
			:item((timers.tail ~= 0 or timers.ears ~= 0) and "wet_sponge" or "sponge")
		
		a.legsAct
			:title(toJson(
				{
					"",
					{text = "Set Legs Threshold\n\n", bold = true, color = c.primary},
					{text = "Scroll to adjust the threshold for when the legs should form.\n\n", color = c.secondary},
					{text = "Legs threshold:\n", bold = true, color = c.secondary},
					{text = math.round(legsForm.curr * 100).."% Wet"}
				}
			))
		
		a.gradualAct
			:title(toJson(
				{
					"",
					{text = "Toggle Gradual Dry\n\n", bold = true, color = c.primary},
					{text = "Toggles the scaling of your tail to be gradual rather than instantly changing size.", color = c.secondary}
				}
			))
		
		a.soundAct
			:title(toJson(
				{
					"",
					{text = "Toggle Flop Sound\n\n", bold = true, color = c.primary},
					{text = "Toggles flopping sound effects when landing on the ground.\nIf tail can dry, volume will gradually decrease over time until dry.", color = c.secondary}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end

-- Return tail data
return tailData