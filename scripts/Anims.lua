-- Required scripts
require("lib.GSAnimBlend")
require("lib.Molang")
local parts   = require("lib.PartsAPI")
local lerp    = require("lib.LerpAPI")
local ground  = require("lib.GroundCheck")
local tail    = require("scripts.Tail")
local pose    = require("scripts.Posing")
local effects = require("scripts.SyncedVariables")

-- Animations setup
local anims = animations.Merling

-- Config setup
config:name("Merling")
local isShark   = config:load("AnimShark") or false
local isCrawl   = config:load("AnimCrawl") or false
local mountDir  = config:load("AnimMountDir") or false
local mountFlip = config:load("AnimMountFlip") or false

-- Table setup
v = {}

-- Animation variables
v.strength = 1
v.pitch = 0
v.yaw   = 0
v.roll  = 0
v.headY = 0

v.shark = isShark and 1 or 0

v.tail = 1
v.legs = 1

-- Variables
local waterTimer = 0
local canTwirl = false
local isSing   = false

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
local strength = lerp:new(1, 1)
local pitch = lerp:new(0, 0.1)
local yaw   = lerp:new(0, 1)
local roll  = lerp:new(0, 0.1)

local shark = lerp:new(isShark and 1 or 0, 0.25)
local mountFlipLerp = lerp:new(mountFlip and 1 or 0)

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
	
	-- Timer settings
	if player:isInWater() or player:isInLava() then
		waterTimer = 20
	else
		waterTimer = math.max(waterTimer - 1, 0)
	end
	
	-- Animation variables
	local largeTail  = tail.isLarge
	local smallTail  = tail.isSmall
	local groundAnim = (onGround or waterTimer == 0) and not (pose.swim or pose.elytra or pose.crawl or pose.climb or pose.spin or pose.sleep or player:getVehicle() or effects.cF)
	
	-- Directional velocity
	local fbVel = vel:dot((dir.x_z):normalized())
	local lrVel = vel:crossed(dir.x_z:normalized()).y
	local udVel = vel.y
	local diagCancel = math.abs(lrVel) - math.abs(fbVel)
	
	-- Static yaw
	staticYaw = math.clamp(staticYaw, bodyYaw - 45, bodyYaw + 45)
	staticYaw = math.lerp(staticYaw, bodyYaw, onGround and math.clamp(vel:length(), 0, 1) or 0.25)
	local yawDif = staticYaw - bodyYaw
	
	-- Speed control
	local speed     = player:getVehicle() and 1 or math.min(vel:length() * 3, 3) + 1
	local landSpeed = math.clamp(fbVel * 6 + (fbVel < -0.05 and -0.5 or 0.5), -6, 6)
	
	-- Animation speeds
	anims.swim:speed(speed)
	anims.stand:speed(landSpeed)
	anims.crawl:speed(landSpeed)
	anims.small:speed(speed)
	anims.ears:speed(speed)
	
	-- Strength control
	strength.target = player:getVehicle() and 1 or math.clamp((groundAnim and vel.xz or vel):length() * 2 + 1, 1, 2)
	
	-- Axis controls
	-- X axis control
	if pose.elytra then
		
		-- When using elytra
		pitch.target = math.clamp(-udVel * 20 * (-math.abs(player:getLookDir().y) + 1), -20, 20)
		
	elseif pose.climb or not largeTail or pose.spin then
		
		-- Assumed climbing
		pitch.target = 0
		
	elseif (pose.swim or waterTimer == 0) and not effects.cF then
		
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
	shark.target = isShark and 1 or 0
	
	-- Mount rot target
	mountFlipLerp.target = mountFlip and 1 or -1
	
	-- Animation states
	local swim      = ((not onGround and waterTimer ~= 0) or (smallTail or pose.climb or pose.swim or pose.crawl or pose.elytra or player:getVehicle()) or effects.cF) and not pose.sleep
	local stand     = largeTail and not isCrawl and groundAnim
	local crawl     = largeTail and     isCrawl and groundAnim
	local small     = smallTail and not (pose.swim or pose.crawl or pose.elytra)
	local smallSwim = smallTail and     (pose.swim or pose.crawl or pose.elytra)
	local mountUp   = largeTail and player:getVehicle() and mountDir
	local mountDown = largeTail and player:getVehicle() and not mountDir
	local sleep     = pose.sleep
	local ears      = player:isUnderwater()
	local sing      = isSing and not pose.sleep
	
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
	if isSing and world.getTime() % 5 == 0 then
		notes(parts.group.Head, 1)
	end
	
	-- Determins when to stop twirl animaton
	canTwirl = (waterTimer ~= 0 or effects.cF) and not (onGround or pose.sleep)
	if not canTwirl then
		anims.twirl:stop()
	end
	
end

function events.RENDER(delta, context)
	
	-- Store animation variables
	v.strength = strength.currPos
	v.pitch = pitch.currPos
	v.yaw   = yaw.currPos
	v.roll  = roll.currPos
	v.headY = (vanilla_model.HEAD:getOriginRot().y + 180) % 360 - 180
	
	v.shark = shark.currPos
	
	v.tail = tail.scale
	v.legs = tail.legs
	
	-- Animation blending
	anims.small:blend(tail.scale * 0.2 + 1)
	anims.smallSwim:blend(tail.scale * 0.2 + 1)
	anims.mountUp:blend(mountFlipLerp.currPos)
	anims.mountDown:blend(mountFlipLerp.currPos)
	
	-- Parrot rot offset
	for _, parrot in pairs(parrots) do
		parrot:rot(-calculateParentRot(parrot:getParent()) - vanilla_model.BODY:getOriginRot())
	end
	
	-- Spyglass rotations
	local headRot = vanilla_model.HEAD:getOriginRot()
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

-- Shark anim toggle
function pings.setAnimShark(boolean)
	
	isShark = boolean
	config:save("AnimShark", isShark)
	
end

-- Crawl anim toggle
function pings.setAnimCrawl(boolean)
	
	isCrawl = boolean
	config:save("AnimCrawl", isCrawl)
	
end

-- Mount direction anim toggle
function pings.setAnimMountDir()
	
	mountDir = not mountDir
	config:save("AnimMountDir", mountDir)
	
end

-- Set mount rotation
function pings.setAnimMountFlip()
	
	mountFlip = not mountFlip
	config:save("AnimMountFlip", mountFlip)
	
end

-- Play twirl anim
function pings.animPlayTwirl()
	
	if canTwirl then
		anims.twirl:play()
	end
	
end

-- Singing anim toggle
function pings.setAnimSing(boolean)
	
	isSing = boolean
	
end

-- Sync variables
function pings.syncAnims(a, b, c, d, e)
	
	isShark   = a
	isCrawl   = b
	mountDir  = c
	mountFlip = d
	isSing    = e
	
end

-- Host only instructions
if not host:isHost() then return end

-- Twirl keybind
local twirlBind   = config:load("AnimTwirlKeybind") or "key.keyboard.keypad.6"
local setTwirlKey = keybinds:newKeybind("Twirl Animation"):onPress(pings.animPlayTwirl):key(twirlBind)

-- Sing keybind
local singBind   = config:load("AnimSingKeybind") or "key.keyboard.keypad.7"
local setSingKey = keybinds:newKeybind("Singing Animation"):onPress(function() pings.setAnimSing(not isSing) end):key(singBind)

-- Keybind updaters
function events.TICK()
	
	local twirlKey = setTwirlKey:getKey()
	local singKey  = setSingKey:getKey()
	if twirlKey ~= twirlBind then
		twirlBind = twirlKey
		config:save("AnimTwirlKeybind", twirlKey)
	end
	if singKey ~= singBind then
		singBind = singKey
		config:save("AnimSingKeybind", singKey)
	end
	
end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncAnims(isShark, isCrawl, mountDir, mountFlip, isSing)
	end
	
end

-- Required script
local s, wheel, itemCheck, c = pcall(require, "scripts.ActionWheel")
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
		:item(itemCheck("jukebox"))
		:onLeftClick(function() wheel:descend(animsPage) end)
end

a.sharkAct = animsPage:newAction()
	:item(itemCheck("dolphin_spawn_egg"))
	:toggleItem(itemCheck("guardian_spawn_egg"))
	:onToggle(pings.setAnimShark)
	:toggled(isShark)

a.crawlAct = animsPage:newAction()
	:item(itemCheck("armor_stand"))
	:toggleItem(itemCheck("oak_boat"))
	:onToggle(pings.setAnimCrawl)
	:toggled(isCrawl)

a.mountAct = animsPage:newAction()
	:item(itemCheck("saddle"))
	:onLeftClick(pings.setAnimMountDir)
	:onRightClick(pings.setAnimMountFlip)

a.twirlAct = animsPage:newAction()
	:item(itemCheck("cod"))
	:onLeftClick(pings.animPlayTwirl)

a.singAct = animsPage:newAction()
	:item(itemCheck("music_disc_blocks"))
	:toggleItem(itemCheck("music_disc_cat"))
	:onToggle(pings.setAnimSing)

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
					{text = mountDir and "Up" or "Down"},
					{text = " & "},
					{text = mountFlip and "Front" or "Back"}
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
			:toggled(isSing)
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end