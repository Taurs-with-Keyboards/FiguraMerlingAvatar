-- Kills script if squAPI cannot be found
local s, squapi = pcall(require, "lib.SquAPI")
if not s then return {} end

-- Required scripts
local parts     = require("lib.PartsAPI")
local lerp      = require("lib.LerpAPI")
local tailScale = require("scripts.Tail")
local pose      = require("scripts.Posing")
local effects   = require("scripts.SyncedVariables")

-- Animation setup
local anims = animations.Merling

-- Config setup
config:name("Merling")
local armsMove = config:load("SquapiArmsMove") or false

-- Lerp tables
local leftArmLerp  = lerp:new(armsMove and 1 or 0, 0.5)
local rightArmLerp = lerp:new(armsMove and 1 or 0, 0.5)

-- Squishy ears
local ears = squapi.ear:new(
	parts.group.LeftEar,
	parts.group.RightEar,
	0.35,  -- Range Multiplier (0.35)
	true,  -- Horizontal (true)
	1,     -- Bend Strength (1)
	false, -- Do Flick (false)
	400,   -- Flick Chance (400)
	0.1,   -- Stiffness (0.1)
	0.9    -- Bounce (0.9)
)

-- Tails table
local tailParts = {
	
	parts.group.Tail1,
	parts.group.Tail2,
	parts.group.Tail3,
	parts.group.Tail4,
	parts.group.Fluke
	
}

-- Squishy tail
local tail = squapi.tail:new(
	tailParts,
	0,     -- Intensity X (0)
	0,     -- Intensity Y (0)
	0,     -- Speed X (0)
	0,     -- Speed Y (0)
	2,     -- Bend (2)
	1,     -- Velocity Push (1)
	0,     -- Initial Offset (0)
	0,     -- Seg Offset (0)
	0.015, -- Stiffness (0.015)
	0.95,  -- Bounce (0.95)
	0,     -- Fly Offset (0)
	-15,   -- Down Limit (-15)
	25     -- Up Limit (25)
)

-- Tail strength variables
local tailStrength  = tail.bendStrength
local tailVelPush   = tail.velocityPush
local tailFlyOffset = tail.flyingOffset

-- Squishy vanilla arms
local leftArm = squapi.arm:new(
	parts.group.LeftArm,
	1,     -- Strength (1)
	false, -- Right Arm (false)
	true   -- Keep Position (true)
)

local rightArm = squapi.arm:new(
	parts.group.RightArm,
	1,    -- Strength (1)
	true, -- Right Arm (true)
	true  -- Keep Position (true)
)

-- Arm strength variables
local leftArmStrength  = leftArm.strength
local rightArmStrength = rightArm.strength

function events.TICK()
	
	-- Arm variables
	local handedness  = player:isLeftHanded()
	local activeness  = player:getActiveHand()
	local leftActive  = not handedness and "OFF_HAND" or "MAIN_HAND"
	local rightActive = handedness and "OFF_HAND" or "MAIN_HAND"
	local leftSwing   = player:getSwingArm() == leftActive
	local rightSwing  = player:getSwingArm() == rightActive
	local leftItem    = player:getHeldItem(not handedness)
	local rightItem   = player:getHeldItem(handedness)
	local using       = player:isUsingItem()
	local usingL      = activeness == leftActive and leftItem:getUseAction() or "NONE"
	local usingR      = activeness == rightActive and rightItem:getUseAction() or "NONE"
	local bow         = using and (usingL == "BOW" or usingR == "BOW")
	local crossL      = leftItem.tag and leftItem.tag["Charged"] == 1
	local crossR      = rightItem.tag and rightItem.tag["Charged"] == 1
	
	-- Arm movement overrides
	local armShouldMove = (not (player:isUnderwater() or player:isInLava()) and not effects.cF) or tailScale.isSmall or anims.crawl:isPlaying()
	
	-- Control targets based on variables
	leftArmLerp.target  = (armsMove or armShouldMove or leftSwing  or bow or ((crossL or crossR) or (using and usingL ~= "NONE"))) and 1 or 0
	rightArmLerp.target = (armsMove or armShouldMove or rightSwing or bow or ((crossL or crossR) or (using and usingR ~= "NONE"))) and 1 or 0
	
	-- Control the intensity of the tail function based on its scale
	local scale = tailScale.isSmall and 1 or 0
	tail.bendStrength = scale * tailStrength
	tail.velocityPush = not (player:isInWater() or pose.swim or pose.crawl or pose.elytra) and tailVelPush or 0
	tail.flyingOffset = scale * tailFlyOffset
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local idleTimer   = world.getTime(delta)
	local idleRot     = vec(math.deg(math.sin(idleTimer * 0.067) * 0.05), 0, math.deg(math.cos(idleTimer * 0.09) * 0.05 + 0.05))
	local firstPerson = context == "FIRST_PERSON"
	
	-- Adjust arm strengths
	leftArm.strength  = leftArmStrength  * leftArmLerp.currPos
	rightArm.strength = rightArmStrength * rightArmLerp.currPos
	
	-- Adjust arm characteristics after applied by squapi
	parts.group.LeftArm
		:offsetRot(
			parts.group.LeftArm:getOffsetRot()
			+ ((-idleRot + (vanilla_model.BODY:getOriginRot() * 0.75)) * math.map(leftArmLerp.currPos, 0, 1, 1, 0))
			+ (parts.group.LeftArm:getAnimRot() * math.map(leftArmLerp.currPos, 0, 1, 0, -2))
		)
		:pos(parts.group.LeftArm:getPos() * vec(1, 1, -1))
		:visible(not firstPerson)
	
	parts.group.RightArm
		:offsetRot(
			parts.group.RightArm:getOffsetRot()
			+ ((idleRot + (vanilla_model.BODY:getOriginRot() * 0.75)) * math.map(rightArmLerp.currPos, 0, 1, 1, 0))
			+ (parts.group.RightArm:getAnimRot() * math.map(rightArmLerp.currPos, 0, 1, 0, -2))
		)
		:pos(parts.group.RightArm:getPos() * vec(1, 1, -1))
		:visible(not firstPerson)
	
	-- Set visible if in first person
	parts.group.LeftArmFP:visible(firstPerson)
	parts.group.RightArmFP:visible(firstPerson)
	
end

-- Arm movement toggle
function pings.setSquapiArmsMove(boolean)
	
	armsMove = boolean
	config:save("SquapiArmsMove", armsMove)
	
end

-- Sync variable
function pings.syncSquapi(a)
	
	armsMove = a
	
end

-- Host only instructions
if not host:isHost() then return end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncSquapi(armsMove)
	end
	
end

-- Required scripts
local s, wheel, itemCheck, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Anims") -- Tries to find script, not required

-- Check for if page already exists
local pageExists = action_wheel:getPage("Anims")

-- Pages
local parentPage = action_wheel:getPage("Main")
local animsPage  = pageExists or action_wheel:newPage("Anims")

-- Actions table setup
local a = {}

-- Actions
if not pageExists then
	a.pageAct = parentPage:newAction()
		:item(itemCheck("jukebox"))
		:onLeftClick(function() wheel:descend(animsPage) end)
end

a.armsAct = animsPage:newAction()
	:item(itemCheck("red_dye"))
	:toggleItem(itemCheck("rabbit_foot"))
	:onToggle(pings.setSquapiArmsMove)
	:toggled(armsMove)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if a.pageAct then
			a.pageAct
				:title(toJson(
					{text = "Animation Settings", bold = true, color = c.primary}
				))
		end
		
		a.armsAct
			:title(toJson(
				{
					"",
					{text = "Arm Movement Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the movement swing movement of the arms.\nActions are not effected.", color = c.secondary}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end