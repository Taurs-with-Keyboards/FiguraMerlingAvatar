-- Required scripts
local parts   = require("lib.PartsAPI")
local sync    = require("lib.LetThatSyncFig")
local lerp    = require("lib.LerpAPI")
local ground  = require("lib.GroundCheck")
local effects = require("scripts.SyncedVariables")

-- Synced variables setup
local tailType = sync.add(config:load("TailType"), 4)
local earsType = sync.add(config:load("TailEarsType"), sync[tailType])
local small = sync.add(config:load("TailSmall"), true)
local smallSize = sync.add(config:load("TailSmallSize"), 0.5)
local dryTimer = sync.add(config:load("TailDryTimer"), 400)
local legsForm = sync.add(config:load("TailLegsForm"), 0.75)
local gradual = sync.add(config:load("TailGradual"), true)
local fallSound = sync.add(config:load("TailFallSound"), true)

-- Variables setup
local tailTimer = 0
local earsTimer = 0
local wasInAir  = false

-- Lerp variables
local scale = {
	tail = lerp:new(sync[tailType] == 5 and 1 or 0),
	legs = lerp:new(sync[tailType] ~= 5 and 1 or 0),
	ears = lerp:new(sync[earsType] == 5 and 1 or 0)
}

-- Data sent to other scripts
local tailData = {
	isLarge = tailTimer >  (sync[dryTimer] * sync[legsForm]),
	isSmall = tailTimer <= (sync[dryTimer] * sync[legsForm]) and scale.tail.currTick > 0.01,
	dry     = sync[dryTimer],
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
	tailTimer = waterTypes[sync[tailType]].check() and sync[dryTimer] or waterTypes[sync[tailType]].dry and math.clamp(tailTimer - dryRate, 0, sync[dryTimer]) or 0
	earsTimer = waterTypes[sync[earsType]].check() and sync[dryTimer] or waterTypes[sync[earsType]].dry and math.clamp(earsTimer - dryRate, 0, sync[dryTimer]) or 0
	
	-- Targets
	scale.tail.target = sync[gradual] and tailTimer / math.max(sync[dryTimer], 1) or tailTimer ~= 0 and 1 or 0
	scale.ears.target = sync[gradual] and earsTimer / math.max(sync[dryTimer], 1) or earsTimer ~= 0 and 1 or 0
	scale.legs.target = tailTimer <= (sync[dryTimer] * sync[legsForm]) and 1 or 0
	
	-- Modify tail target
	if sync[small] then
		scale.tail.target = math.map(scale.tail.target, 0, 1, sync[smallSize], 1)
	end
	
	-- Play sound if conditions are met
	if sync[fallSound] and wasInAir and ground() and scale.legs.target ~= 1 and not player:getVehicle() and not player:isInWater() and not effects.cF then
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
	tailData.isLarge = tailTimer >  (sync[dryTimer] * sync[legsForm])
	tailData.isSmall = tailTimer <= (sync[dryTimer] * sync[legsForm]) and scale.tail.currTick > 0.01
	tailData.dry     = sync[dryTimer]
	
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
	
	sync[tailType] = setSensitivity(sync[tailType], i)
	config:save("TailType", sync[tailType])
	
end

-- Ears sensitivity
function pings.setTailEarsType(i)
	
	sync[earsType] = setSensitivity(sync[earsType], i)
	config:save("TailEarsType", sync[earsType])
	
end

-- Small toggle
function pings.setTailSmall(boolean)
	
	sync[small] = boolean
	config:save("TailSmall", sync[small])
	
end

-- Set small size
local function setSmallSize(x)
	
	sync[smallSize] = math.clamp(sync[smallSize] + (x * 0.05), 0.25, 1)
	config:save("TailSmallSize", sync[smallSize])
	
end

-- Set leg form threshold
local function setLegsForm(x)
	
	sync[legsForm] = math.clamp(sync[legsForm] + (x * 0.05), 0.25, 0.9)
	config:save("TailLegsForm", sync[legsForm])
	
end

-- Set timer
local function setDryTimer(x)
	
	sync[dryTimer] = math.clamp(sync[dryTimer] + (x * 20), 0, 72000)
	config:save("TailDryTimer", sync[dryTimer])
	
end

-- Gradual toggle
function pings.setTailGradual(boolean)
	
	sync[gradual] = boolean
	config:save("TailGradual", sync[gradual])
	
end

-- Sound toggle
function pings.setTailFallSound(boolean)

	sync[fallSound] = boolean
	config:save("TailFallSound", sync[fallSound])
	if host:isHost() and player:isLoaded() and sync[fallSound] then
		sounds:playSound("entity.puffer_fish.flop", player:getPos(), 0.35, 0.6)
	end
	
end

-- Host only instructions, return tail data
if not host:isHost() then return tailData end

-- Keybinds
local tailKeybind = keybinds:newKeybind("Tail Sensitivity Type", "key.keyboard.keypad.1")
	:onPress(function() pings.setTailType(1) end)
local earsKeybind = keybinds:newKeybind("Ears Sensitivity Type", "key.keyboard.keypad.2")
	:onPress(function() pings.setTailEarsType(1) end)
local smallKeybind = keybinds:newKeybind("Small Tail Toggle", "key.keyboard.keypad.3")
	:onPress(function() pings.setTailSmall(not sync[small]) end)

-- Sync config keybinds
sync.keybind(tailKeybind, "TailTypeKeybind")
sync.keybind(earsKeybind, "TailEarsTypeKeybind")
sync.keybind(smallKeybind, "TailSmallKeybind")

-- Required script
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return tailData end -- Kills script early if ActionWheel.lua isnt found

-- Pages
local parentPage = action_wheel:getPage("Main")
local tailPage   = action_wheel:newPage("Tail")
local dryPage    = action_wheel:newPage("Dry")

-- Actions table setup
local a = {}

-- Actions
a.tailPageAct = parentPage:newAction()
	:item("tropical_fish")
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
	:item("small_amethyst_bud")
	:onToggle(pings.setTailSmall)
	:onScroll(setSmallSize)

a.dryPageAct = tailPage:newAction()
	:item("sponge")
	:onLeftClick(function() wheel:descend(dryPage) end)

a.dryAct = dryPage:newAction()
	:onScroll(setDryTimer)
	:onLeftClick(function() sync[dryTimer] = 400 config:save("TailDryTimer", sync[dryTimer]) end)

a.legsAct = dryPage:newAction()
	:item("rabbit_foot")
	:onScroll(setLegsForm)

a.gradualAct = dryPage:newAction()
	:item("sugar")
	:toggleItem("fermented_spider_eye")
	:onToggle(pings.setTailGradual)

a.soundAct = dryPage:newAction()
	:item("bucket")
	:toggleItem("water_bucket")
	:onToggle(pings.setTailFallSound)
	:toggled(sync[fallSound])

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
		
		local actionSetup = waterInfo[sync[tailType]]
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
		
		local actionSetup = waterInfo[sync[earsType]]
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
					{text = math.round(sync[smallSize] * 100).."% Size"}
				}
			))
			:toggleItem(
				sync[smallSize] > 0.75 and "amethyst_cluster" or
				sync[smallSize] > 0.5 and "large_amethyst_bud" or
				"medium_amethyst_bud"
			)
			:toggled(sync[small])
		
		a.dryPageAct
			:title(toJson(
				{text = "Drying Settings", bold = true, color = c.primary}
			))
		
		-- Timers
		local timers = {
			set  = sync[dryTimer] / 20,
			legs = sync[gradual] and math.max(math.ceil((tailTimer - (sync[dryTimer] * sync[legsForm])) / 20), 0) or nil,
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
					{text = math.round(sync[legsForm] * 100).."% Wet"}
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
			:toggled(sync[gradual])
		
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