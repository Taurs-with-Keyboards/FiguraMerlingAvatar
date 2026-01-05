-- Required scripts
local effects = require("scripts.SyncedVariables")
local pose    = require("scripts.Posing")

-- Config setup
config:name("Merling")
local bubbles       = config:load("WhirlpoolBubbles")
local dolphinsGrace = config:load("WhirlpoolDolphinsGrace") or false
if bubbles == nil then bubbles = true end

-- Bubble spawner
local numBubbles = 8
function events.TICK()
	
	if dolphinsGrace and not effects.dG then return end
	if pose.swim and bubbles and player:isInWater() then
		local worldMatrix = models:partToWorldMatrix()
		for i = 1, numBubbles do
			particles:newParticle("bubble",
				(worldMatrix * matrices.rotation4(0, world.getTime() * 10 - 360/numBubbles * i)):apply(15, 15)
			)
		end
	end
	
end

-- Bubbles toggle
function pings.setWhirlpoolBubbles(boolean)
	
	bubbles = boolean
	config:save("WhirlpoolBubbles", bubbles)
	if host:isHost() and player:isLoaded() and bubbles then
		sounds:playSound("block.bubble_column.upwards_inside", player:getPos(), 0.35)
	end
	
end

-- Dolphins Grace toggle
function pings.setWhirlpoolDolphinsGrace(boolean)
	
	dolphinsGrace = boolean
	config:save("WhirlpoolDolphinsGrace", dolphinsGrace)
	if host:isHost() and player:isLoaded() and dolphinsGrace then
		sounds:playSound("entity.dolphin.ambient", player:getPos(), 0.35)
	end
	
end

-- Sync variables
function pings.syncWhirlpool(...)
	
	bubbles, dolphinsGrace = ...
	
end

-- Host only instructions
if not host:isHost() then return end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncWhirlpool(bubbles, dolphinsGrace)
	end
	
end

-- Required scripts
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Tail") -- Tries to find script, not required

-- Pages
local parentPage    = action_wheel:getPage("Tail") or action_wheel:getPage("Main")
local whirlpoolPage = action_wheel:newPage("Whirlpool")

-- Actions table setup
local a = {}

-- Actions
a.pageAct = parentPage:newAction()
	:item("magma_block")
	:onLeftClick(function() wheel:descend(whirlpoolPage) end)

a.bubbleAct = whirlpoolPage:newAction()
	:item("soul_sand")
	:toggleItem("magma_block")
	:onToggle(pings.setWhirlpoolBubbles)
	:toggled(bubbles)

a.dolphinsGraceAct = whirlpoolPage:newAction()
	:item("egg")
	:toggleItem("dolphin_spawn_egg")
	:onToggle(pings.setWhirlpoolDolphinsGrace)
	:toggled(dolphinsGrace)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		a.pageAct
			:title(toJson(
				{text = "Whirlpool Settings", bold = true, color = c.primary}
			))
		
		a.bubbleAct
			:title(toJson(
				{
					"",
					{text = "Whirlpool Effect Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the whirlpool created while swimming.", color = c.secondary}
				}
			))
		
		a.dolphinsGraceAct
			:title(toJson(
				{
					"",
					{text = "Dolphin\'s Grace Toggle\n\n", bold = true, color = c.primary},
					{text = "Toggles the whirlpool based on having the Dolphin\'s Grace Effect.", color = c.secondary}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end