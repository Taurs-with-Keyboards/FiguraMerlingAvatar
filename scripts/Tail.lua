-- Required scripts
local parts   = require("lib.PartsAPI")
local lerp    = require("lib.LerpAPI")
local ground  = require("lib.GroundCheck")
local effects = require("scripts.SyncedVariables")

-- Config setup
config:name("Merling")
local tailType  = config:load("TailType") or 4
local earsType  = config:load("TailEarsType") or tailType
local small     = config:load("TailSmall")
local smallSize = config:load("TailSmallSize") or 0.5
local dryTimer  = config:load("TailDryTimer") or 400
local legsForm  = config:load("TailLegsForm") or 0.75
local gradual   = config:load("TailGradual")
local fallSound = config:load("TailFallSound")
if small     == nil then small = true end
if gradual   == nil then gradual = true end
if fallSound == nil then fallSound = true end

-- Variables setup
local tailTimer = 0
local earsTimer = 0
local wasInAir  = false

-- Lerp variables
local smallLerp = lerp:new(0.2, smallSize)
local scale = {
	tail  = lerp:new(0.2, tailType == 5 and 1 or 0),
	legs  = lerp:new(0.2, tailType ~= 5 and 1 or 0),
	ears  = lerp:new(0.2, earsType == 5 and 1 or 0),
	small = lerp:new(0.2, small and 1 or 0)
}

-- Data sent to other scripts
local initScale = math.lerp(smallLerp.currPos * scale.small.currPos, 1, scale.tail.currPos)
local tailData = {
	isLarge   = scale.tail.currPos >= legsForm,
	isSmall   = initScale > 0.01 and scale.tail.currPos < legsForm,
	legs      = scale.legs.currPos,
	height    = math.max(math.lerp(smallLerp.currPos * scale.small.currPos, 1, scale.tail.currPos), scale.legs.currPos),
	smallSize = smallLerp.currPos,
	dry       = dryTimer
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
	tailTimer = waterTypes[tailType].check() and dryTimer or waterTypes[tailType].dry and math.clamp(tailTimer - dryRate, 0, dryTimer) or 0
	earsTimer = waterTypes[earsType].check() and dryTimer or waterTypes[earsType].dry and math.clamp(earsTimer - dryRate, 0, dryTimer) or 0
	
	-- Targets
	smallLerp.target = smallSize
	scale.tail.target = gradual and tailTimer / math.max(dryTimer, 1) or tailTimer ~= 0 and 1 or 0
	scale.ears.target = gradual and earsTimer / math.max(dryTimer, 1) or earsTimer ~= 0 and 1 or 0
	scale.legs.target = scale.tail.target <= legsForm and 1 or 0
	scale.small.target = small and 1 or 0
	
	-- Play sound if conditions are met
	if fallSound and wasInAir and ground() and scale.legs.target ~= 1 and not player:getVehicle() and not player:isInWater() and not effects.cF then
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
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local tailApply = math.lerp(smallLerp.currPos * scale.small.currPos, 1, scale.tail.currPos)
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
	parts.group.LeftEarSkull:scale(earsApply)
	parts.group.RightEarSkull:scale(earsApply)
	
	-- Update tail data
	tailData.isLarge   = scale.tail.currPos >= legsForm
	tailData.isSmall   = tailApply > 0.01 and scale.tail.currPos < legsForm
	tailData.legs      = scale.legs.currPos
	tailData.height    = math.max(tailApply, scale.legs.currPos)
	tailData.smallSize = smallLerp.currPos
	tailData.dry       = dryTimer
	
end

-- Set sensitivity
local function setSensitivity(sen, i)
	
	sen = ((sen + i - 1) % 5) + 1
	if player:isLoaded() and host:isHost() then
		sounds:playSound("ambient.underwater.enter", player:getPos(), 0.35)
	end
	
	return sen
	
end

-- Tail sensitivity
function pings.setTailType(i)
	
	tailType = setSensitivity(tailType, i)
	config:save("TailType", tailType)
	
end

-- Ears sensitivity
function pings.setTailEarsType(i)
	
	earsType = setSensitivity(earsType, i)
	config:save("TailEarsType", earsType)
	
end

-- Small toggle
function pings.setTailSmall(boolean)
	
	small = boolean
	config:save("TailSmall", small)
	
end

-- Set small size
local function setSmallSize(x)
	
	smallSize = math.clamp(smallSize + (x * 0.05), 0.25, 1)
	config:save("TailSmallSize", smallSize)
	
end

-- Set small size
local function setLegsForm(x)
	
	legsForm = math.clamp(legsForm + (x * 0.05), 0.25, 0.9)
	config:save("TailLegsForm", legsForm)
	
end

-- Set timer
local function setDryTimer(x)
	
	dryTimer = math.clamp(dryTimer + (x * 20), 0, 72000)
	config:save("TailDryTimer", dryTimer)
	
end

-- Gradual toggle
function pings.setTailGradual(boolean)
	
	gradual = boolean
	config:save("TailGradual", gradual)
	
end

-- Sound toggle
function pings.setTailFallSound(boolean)

	fallSound = boolean
	config:save("TailFallSound", fallSound)
	if host:isHost() and player:isLoaded() and fallSound then
		sounds:playSound("entity.puffer_fish.flop", player:getPos(), 0.35, 0.6)
	end
	
end

-- Sync variables
function pings.syncTail(a, b, c, d, e, f, g, h)
	
	tailType  = a
	earsType  = b
	small     = c
	smallSize = d
	dryTimer  = e
	legsForm  = f
	gradual   = g
	fallSound = h
	
end

-- Host only instructions, return tail data
if not host:isHost() then return tailData end

-- Tail Keybind
local tailBind   = config:load("TailTypeKeybind") or "key.keyboard.keypad.1"
local setTailKey = keybinds:newKeybind("Tail Sensitivity Type"):onPress(function() pings.setTailType(1) end):key(tailBind)

-- Ears keybind
local earsBind   = config:load("TailEarsTypeKeybind") or "key.keyboard.keypad.2"
local setEarsKey = keybinds:newKeybind("Ears Sensitivity Type"):onPress(function() pings.setTailEarsType(1) end):key(earsBind)

-- Small tail keybind
local smallBind   = config:load("TailSmallKeybind") or "key.keyboard.keypad.3"
local setSmallKey = keybinds:newKeybind("Small Tail Toggle"):onPress(function() pings.setTailSmall(not small) end):key(smallBind)

-- Keybind updaters
function events.TICK()
	
	local tailKey  = setTailKey:getKey()
	local earsKey  = setEarsKey:getKey()
	local smallKey = setSmallKey:getKey()
	if tailKey ~= tailBind then
		tailBind = tailKey
		config:save("TailTypeKeybind", tailKey)
	end
	if earsKey ~= earsBind then
		earsBind = earsKey
		config:save("TailEarsTypeKeybind", earsKey)
	end
	if smallKey ~= smallBind then
		smallBind = smallKey
		config:save("TailSmallKeybind", smallKey)
	end
	
end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncTail(tailType, earsType, small, smallSize, dryTimer, legsForm, gradual, fallSound)
	end
	
end

-- Required script
local s, wheel, itemCheck, c = pcall(require, "scripts.ActionWheel")
if not s then return tailData end -- Kills script early if ActionWheel.lua isnt found

-- Pages
local parentPage = action_wheel:getPage("Main")
local tailPage   = action_wheel:newPage("Tail")
local dryPage    = action_wheel:newPage("Dry")

-- Actions table setup
local a = {}

-- Actions
a.tailPageAct = parentPage:newAction()
	:item(itemCheck("tropical_fish"))
	:onLeftClick(function() wheel:descend(tailPage) end)

a.tailAct = tailPage:newAction()
	:onLeftClick(function() pings.setTailType(1) end)
	:onRightClick(function() pings.setTailType(-1) end)
	:onScroll(pings.setTailType)

a.earsAct = tailPage:newAction()
	:onLeftClick(function() pings.setTailEarsType(1) end)
	:onRightClick(function() pings.setTailEarsType(-1) end)
	:onScroll(pings.setTailEarsType)

a.smallAct = tailPage:newAction()
	:item(itemCheck("small_amethyst_bud"))
	:onToggle(pings.setTailSmall)
	:onScroll(setSmallSize)

a.dryPageAct = tailPage:newAction()
	:item(itemCheck("sponge"))
	:onLeftClick(function() wheel:descend(dryPage) end)

a.dryAct = dryPage:newAction()
	:onScroll(setDryTimer)
	:onLeftClick(function() dryTimer = 400 config:save("TailDryTimer", dryTimer) end)

a.legsAct = dryPage:newAction()
	:item(itemCheck("rabbit_foot"))
	:onScroll(setLegsForm)

a.gradualAct = dryPage:newAction()
	:item(itemCheck("sugar"))
	:toggleItem(itemCheck("fermented_spider_eye"))
	:onToggle(pings.setTailGradual)

a.soundAct = dryPage:newAction()
	:item(itemCheck("bucket"))
	:toggleItem(itemCheck("water_bucket"))
	:onToggle(pings.setTailFallSound)
	:toggled(fallSound)

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
		
		local actionSetup = waterInfo[tailType]
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
			:item(itemCheck(actionSetup.item.."{CustomPotionColor:"..tostring(0x0094FF).."}"))
		
		local actionSetup = waterInfo[earsType]
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
			:item(itemCheck(actionSetup.item.."{CustomPotionColor:"..tostring(0x0094FF).."}"))
		
		a.smallAct
			:title(toJson(
				{
					"",
					{text = "Toggle Small Tail\n\n", bold = true, color = c.primary},
					{text = "Toggles the appearence of the tail into a smaller tail, only if the tail cannot form.\nScroll to control the size of the small tail.\n\n", color = c.secondary},
					{text = "Small tail size:\n", bold = true, color = c.secondary},
					{text = math.round(smallSize * 100).."% Size"}
				}
			))
			:toggleItem(
				itemCheck(
					smallSize > 0.75 and "amethyst_cluster" or
					smallSize > 0.5 and "large_amethyst_bud" or
					"medium_amethyst_bud"
				)
			)
			:toggled(small)
		
		a.dryPageAct
			:title(toJson(
				{text = "Drying Settings", bold = true, color = c.primary}
			))
		
		-- Timers
		local timers = {
			set  = dryTimer / 20,
			legs = gradual and math.max(math.ceil((tailTimer - (dryTimer * legsForm)) / 20), 0) or nil,
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
			:item(itemCheck((timers.tail ~= 0 or timers.ears ~= 0) and "wet_sponge" or "sponge"))
		
		a.legsAct
			:title(toJson(
				{
					"",
					{text = "Set Legs Threshold\n\n", bold = true, color = c.primary},
					{text = "Scroll to adjust the threshold for when the legs should form.\n\n", color = c.secondary},
					{text = "Legs threshold:\n", bold = true, color = c.secondary},
					{text = math.round(legsForm * 100).."% Wet"}
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
			:toggled(gradual)
		
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