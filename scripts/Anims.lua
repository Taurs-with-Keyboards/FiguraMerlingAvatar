-- Required scripts
require("lib.GSAnimBlend")
require("lib.Molang")
local parts   = require("lib.PartsAPI")
local sync    = require("lib.LetThatSyncFig")
local lerp    = require("lib.LerpAPI")
local ground  = require("lib.GroundCheck")
local tail    = require("scripts.Tail")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animations setup
local anims = animations.Merling

-- Synced variables setup
local isShark   = sync.new("AnimsShark", false):config()
local isCrawl   = sync.new("AnimsCrawl", false):config()
local mountDir  = sync.new("AnimsMountDir", false):config()
local mountFlip = sync.new("AnimsMountFlip", false):config()
local armsMove  = sync.new("AnimsArms", false):config()
local isSing    = sync.new("AnimsSing", false)

-- Table setup
v = {}

-- Animation variables
v.strength = 1
v.pitch = 0
v.yaw   = 0
v.roll  = 0
v.headY = 0

v.shark = isShark.curr and 1 or 0

v.tail = 1
v.legs = 1

-- Variables
local waterTimer = 0
local groundTimer = 0
local jump     = 0.0
local canTwirl = false

-- Arms setup
local leftArmLerp  = lerp.new(armsMove.curr and 1 or 0, 0.5)
local rightArmLerp = lerp.new(armsMove.curr and 1 or 0, 0.5)

-- Gets the origin rotation of a part, clamped
local function getOriginRot(part, delta)
	
	return (vanilla_model[part]:getOriginRot(delta) + 180) % 360 - 180
	
end

-- Parrot pivots
local parrots = {
	
	parts.group.LeftParrotPivot,
	parts.group.RightParrotPivot
	
}

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getTrueRot()
	end
	return calculateParentRot(parent) + m:getTrueRot()
	
end

-- Lerps
local strength = lerp.new(1, 1)
local pitch = lerp.new(0, 0.1)
local yaw   = lerp.new(0, 1)
local roll  = lerp.new(0, 0.1)

local shark = lerp.new(isShark.curr and 1 or 0, 0.25)
local mountFlipLerp = lerp.new(mountFlip.curr and 1 or 0)

-- Spawns notes around a model part
local function notes(part, blocks)
	
	local pos   = part:partToWorldMatrix():apply()
	local range = blocks * 16
	particles["note"]
		:pos(pos + vec(math.random(-range, range)/16, math.random(-range, range)/16, math.random(-range, range)/16))
		:setColor(math.random(51,200)/150, math.random(51,200)/150, math.random(51,200)/150)
		:spawn()
	
end

-- Set staticYaw to Yaw on init
local staticYaw = 0
function events.ENTITY_INIT()
	
	staticYaw = player:getBodyYaw()
	
end

function events.TICK()
	
	-- Variables
	local vel = player:getVelocity()
	local bodyYaw = player:getBodyYaw()
	local dir = vec(math.sin(math.rad(-bodyYaw)), 0, math.cos(math.rad(-bodyYaw)))
	local onGround = ground()
	if not (player:isInWater() or player:isInLava()) then
		-- Not sure when misfires player:isOnGround() under water. Otherwise, it's likely to be true when the entity cannot fall down
		onGround = onGround or player:isOnGround()
	end

	local isRidingChainConveyor = false
	if player.isRidingChainConveyor ~= nil then
		isRidingChainConveyor = player:isRidingChainConveyor()
	end

	-- Timer settings
	if player:isInWater() or player:isInLava() then
		waterTimer = 20
	else
		waterTimer = math.max(waterTimer - 1, 0)
	end

	if onGround then
		jump = 0.0
		groundTimer = 12
	else
		if groundTimer == 12 then
			jump = vel.y
		end
		groundTimer = math.max(groundTimer - 1, 0)
		-- Transition to mid-air 'swim' animation
		-- 0.52 is value that avoid firing by pushing up by vanilla piston
		if vel.y > 0.52 or (jump <= 0.0 and vel.y < -0.08) or (jump > 0.0 and vel.y < -jump * 0.8) then
			if vel.y > 0.0 then
				if groundTimer > 1 then
					groundTimer = isCrawl and 0 or 1
				end
			elseif groundTimer > 3 then
				groundTimer = 3
			end
		end
	end

	-- Animation variables
	local largeTail  = tail.isLarge
	local smallTail  = tail.isSmall
	local groundAnim = (onGround or waterTimer == 0) and not (pose.swim or pose.elytra or pose.crawl or pose.climb or pose.spin or pose.sleep or player:getVehicle() or effects.cF or isRidingChainConveyor or groundTimer == 0)

	-- Directional velocity
	local fbVel = vel:dot((dir.x_z):normalized())
	local lrVel = vel:crossed(dir.x_z:normalized()).y
	local udVel = vel.y
	local diagCancel = math.abs(lrVel) - math.abs(fbVel)

	-- Motion velocity (for walking on ground or entity)
	local mot = player:getNbt().Motion
	local motX = mot[1]
	local motZ = mot[3]
	local motXZ = vectors.vec3(motX, 0.0, motZ):scale(1.8316) -- Motion value returns 0.11785 bpt max on walking on normal blocks, scale to 0.21585 bpt (4.317 m/s)
	--printTable({player:getVelocity(), motX, motZ, motXZ})
	local fbVelW = motXZ:dot((dir.x_z):normalize())
	local lrVelW = motXZ:cross(dir.x_z:normalize()).y
	velW = vectors.vec2(fbVelW, lrVelW)

	-- Static yaw
	staticYaw = math.clamp(staticYaw, bodyYaw - 45, bodyYaw + 45)
	staticYaw = math.lerp(staticYaw, bodyYaw, onGround and math.clamp(vel:length(), 0, 1) or 0.25)
	local yawDif = staticYaw - bodyYaw
	
	-- Speed control
	local speed     = player:getVehicle() and 1 or math.min(vel:length() * 3, 3) + 1
	local landSpeed = math.clamp(fbVelW < -0.05 and math.min(fbVelW, math.abs(lrVelW)) * 6 - 0.5 or math.max(fbVelW, math.abs(lrVelW)) * 6 + 0.5, -6, 6)

	-- Animation speeds
	anims.swim:speed(speed)
	anims.stand:speed(landSpeed)
	anims.crawl:speed(landSpeed)
	anims.small:speed(speed)
	anims.ears:speed(speed)
	
	-- Strength control
	strength.target = player:getVehicle() and 1 or math.clamp((groundAnim and velW or vel):length() * 2 + 1, 1, 2)

	-- Axis controls
	-- X axis control
	if pose.elytra then
		
		-- When using elytra
		pitch.target = math.clamp(-udVel * 20 * (-math.abs(player:getLookDir().y) + 1), -20, 20)
		
	elseif pose.climb or not largeTail or pose.spin then
		
		-- Assumed climbing
		pitch.target = 0
		
	elseif (pose.swim or waterTimer == 0 and groundTimer > 0) and not (effects.cF or isRidingChainConveyor) then
		
		-- While "swimming" or outside of water
		pitch.target = math.clamp(-udVel * 40 * -(math.abs(player:getLookDir().y * 2) - 1), -20, 20)
		
	else
		
		-- Assumed floating in water
		pitch.target = math.clamp((fbVel + math.max(-udVel, 0) + (math.abs(lrVel) * diagCancel) * 4) * 80, -20, 20)
		
	end
	
	-- Y axis control
	yaw.target = yawDif
	
	-- Z Axis control
	if effects.dG then
		
		-- Dolphin's grace applied
		roll.target = 0
		
	elseif pose.elytra then
		
		-- When using an elytra
		roll.target = math.clamp((-lrVel * 20) - (yawDif * math.clamp(fbVel, -1, 1)), -20, 20)
		
	else
		
		-- Assumed floating in water
		roll.target = math.clamp((-lrVel * diagCancel * 80) - (yawDif * math.clamp(fbVel, -1, 1)), -20, 20)
		
	end
	
	-- Shark control
	shark.target = isShark.curr and 1 or 0
	
	-- Mount rot target
	mountFlipLerp.target = mountFlip.curr and 1 or -1
	
	-- Animation states
	local swim      = ((not onGround and waterTimer ~= 0) or (smallTail or pose.climb or pose.swim or pose.crawl or pose.elytra or player:getVehicle()) or effects.cF or isRidingChainConveyor or groundTimer == 0) and not pose.sleep
	local stand     = largeTail and not isCrawl.curr and groundAnim
	local crawl     = largeTail and     isCrawl.curr and groundAnim
	local small     = smallTail and not (pose.swim or pose.crawl or pose.elytra)
	local smallSwim = smallTail and     (pose.swim or pose.crawl or pose.elytra)
	local mountUp   = largeTail and player:getVehicle() and mountDir.curr
	local mountDown = largeTail and player:getVehicle() and not mountDir.curr
	local sleep     = pose.sleep
	local ears      = player:isUnderwater()
	local sing      = isSing.curr and not pose.sleep
	
	-- Animations
	anims.swim:playing(swim)
	anims.stand:playing(stand)
	anims.crawl:playing(crawl)
	anims.small:playing(small)
	anims.smallSwim:playing(smallSwim)
	anims.mountUp:playing(mountUp)
	anims.mountDown:playing(mountDown)
	anims.sleep:playing(sleep)
	anims.ears:playing(ears)
	anims.sing:playing(sing)
	
	-- Spawns notes around head while singing
	if sing and world.getTime() % 5 == 0 then
		notes(parts.group.Head, 1)
	end
	
	-- Determins when to stop twirl animaton
	canTwirl = isRidingChainConveyor or not ((largeTail and onGround) or pose.sleep or groundTimer > 0)
	if not canTwirl then
		anims.twirl:stop()
	end
	
	-- Twirl speed
	anims.twirl:speed(waterTimer == 0 and 1 or 0.75)
	
	-- Arm variables
	local handedness = player:isLeftHanded()
	local mainL = not handedness and "OFF_HAND" or "MAIN_HAND"
	local mainR = handedness and "OFF_HAND" or "MAIN_HAND"
	local swingL = player:getSwingArm() == mainL
	local swingR = player:getSwingArm() == mainR
	local using = player:isUsingItem()
	local active = player:getActiveHand()
	local itemL = player:getHeldItem(not handedness)
	local itemR = player:getHeldItem(handedness)
	local usingL = using and active == mainL and itemL:getUseAction()
	local usingR = using and active == mainR and itemR:getUseAction()
	local bow = (usingL or usingR or ""):find("BOW") or (itemL:getTag().Charged or itemR:getTag().Charged) == 1
	
	-- Arms movement override
	local armShouldMove = (not (player:isUnderwater() or player:isInLava()) and not effects.cF) or smallTail or anims.crawl:isPlaying()
	
	-- Arms movement targets
	leftArmLerp.target  = (armsMove.curr or armShouldMove or swingL or usingL or bow) and 0 or -1
	rightArmLerp.target = (armsMove.curr or armShouldMove or swingR or usingR or bow) and 0 or -1
	
end

function events.RENDER(delta, context)
	
	-- Store animation variables
	v.strength = strength.currPos
	v.pitch = pitch.currPos
	v.yaw   = yaw.currPos
	v.roll  = roll.currPos
	v.headY = (getOriginRot("HEAD", delta).y + 180) % 360 - 180
	
	v.shark = shark.currPos
	
	v.tail = tail.scale
	v.legs = tail.legs
	
	-- Animation blending
	anims.small:blend(tail.scale * 0.2 + 1)
	anims.smallSwim:blend(tail.scale * 0.2 + 1)
	anims.mountUp:blend(mountFlipLerp.currPos)
	anims.mountDown:blend(mountFlipLerp.currPos)
	
	-- Arm idle rotation
	local idleTimer = world.getTime(delta)
	local idleRot   = vec(math.deg(math.sin(idleTimer * 0.067) * 0.05), 0, math.deg(math.cos(idleTimer * 0.09) * 0.05 + 0.05))
	
	-- Apply arm rotations
	parts.group.LeftArm:offsetRot((getOriginRot("LEFT_ARM", delta) + idleRot) * leftArmLerp.currPos)
	parts.group.RightArm:offsetRot((getOriginRot("RIGHT_ARM", delta) - idleRot) * rightArmLerp.currPos)
	
	-- Parrot rot offset
	for _, parrot in pairs(parrots) do
		parrot:rot(-calculateParentRot(parrot:getParent()) - getOriginRot("BODY", delta))
	end
	
	-- Spyglass rotations
	local headRot = getOriginRot("HEAD", delta)
	headRot.x = math.clamp(headRot.x, -90, 30)
	parts.group.Spyglass:offsetRot(headRot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	
end

-- GS Blending Setup
local blendAnims = {
	{ anim = anims.swim,      ticks = {7,7} },
	{ anim = anims.stand,     ticks = {7,7} },
	{ anim = anims.crawl,     ticks = {7,7} },
	{ anim = anims.small,     ticks = {7,7} },
	{ anim = anims.smallSwim, ticks = {7,7} },
	{ anim = anims.mountUp,   ticks = {7,7} },
	{ anim = anims.mountDown, ticks = {7,7} },
	{ anim = anims.sleep,     ticks = {7,7} },
	{ anim = anims.ears,      ticks = {7,7} },
	{ anim = anims.sing,      ticks = {3,3} }
}

-- Apply GS Blending
for _, blend in ipairs(blendAnims) do
	if blend.anim ~= nil then
		blend.anim:blendTime(table.unpack(blend.ticks)):blendCurve("easeOutQuad")
	end
end

-- Play twirl anim
function pings.animPlayTwirl()
	
	if canTwirl then
		anims.twirl:play()
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required script
local keybound = require("lib.Keybound")

-- Setup keybinds
local twirlKeybind = keybound.new(
	keybinds
		:newKeybind("Twirl Animation", "key.keyboard.keypad.6")
		:onPress(pings.animPlayTwirl),
	"AnimTwirlKeybind"
)
local singKeybind = keybound.new(
	keybinds
		:newKeybind("Singing Animation", "key.keyboard.keypad.7")
		:onPress(function() isSing:update(not isSing.curr) end),
	"AnimsSingKeybind"
)

-- Required script
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found

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
		:item("jukebox")
		:onLeftClick(function() wheel:descend(animsPage) end)
end

a.sharkAct = animsPage:newAction()
	:item("dolphin_spawn_egg")
	:toggleItem("guardian_spawn_egg")
	:onToggle(function(bool)
		isShark:update(bool)
	end)
	:toggled(isShark.curr)

a.crawlAct = animsPage:newAction()
	:item("armor_stand")
	:toggleItem("oak_boat")
	:onToggle(function(bool)
		isCrawl:update(bool)
	end)
	:toggled(isCrawl.curr)

a.mountAct = animsPage:newAction()
	:item("saddle")
	:onLeftClick(function(bool)
		mountDir:update(not mountDir.curr)
	end)
	:onRightClick(function(bool)
		mountFlip:update(not mountFlip.curr)
	end)

a.twirlAct = animsPage:newAction()
	:item("cod")
	:onLeftClick(pings.animPlayTwirl)

a.singAct = animsPage:newAction()
	:item("music_disc_blocks")
	:toggleItem("music_disc_cat")
	:onToggle(function(bool)
		isSing:update(bool)
	end)

a.armsAct = animsPage:newAction()
	:item("red_dye")
	:toggleItem("rabbit_foot")
	:onToggle(function(bool)
		armsMove:update(bool)
	end)
	:toggled(armsMove.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if a.pageAct then
			a.pageAct
				:title(toJson(
					{text = "Animation Settings", bold = true, color = c.primary}
				))
		end
		
		a.sharkAct
			:title(toJson(
				{
					"",
					{text = "Toggle Shark Animations\n\n", bold = true, color = c.primary},
					{text = "Toggles the movement of the tail to be more shark based.", color = c.secondary}
				}
			))
		
		a.crawlAct
			:title(toJson(
				{
					"",
					{text = "Toggle Crawl Animation\n\n", bold = true, color = c.primary},
					{text = "Toggles crawling over standing when you are touching the ground.", color = c.secondary}
				}
			))
		
		a.mountAct
			:title(toJson(
				{
					"",
					{text = "Set Mount Positioning\n\n", bold = true, color = c.primary},
					{text = "Left and Right click to set the orientation of your tail while mounted/sitting.\n\n", color = c.secondary},
					{text = "Current direction: ", bold = true, color = c.secondary},
					{text = mountDir.curr and "Up" or "Down"},
					{text = " & "},
					{text = mountFlip.curr and "Front" or "Back"}
				}
			))
		
		a.twirlAct
			:title(toJson(
				{text = "Play Twirl animation", bold = true, color = c.primary}
			))
		
		a.singAct
			:title(toJson(
				{text = "Play Singing animation", bold = true, color = c.primary}
			))
			:toggled(isSing.curr)
		
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
