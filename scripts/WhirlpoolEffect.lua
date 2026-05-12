-- Required scripts
local sync    = require("lib.LetThatSyncFig")
local effects = require("scripts.SyncedVariables")
local pose    = require("scripts.Posing")

-- Synced variable setup
local bubbles = sync.add(config:load("WhirlpoolState"), 2)

-- Bubble state table
--[[
	1 - Always off
	2 - Only with Dolphin's Grace
	3 - Always on
--]]
local bubbleTypes = {
	function() return false end,
	function() return effects.dG end,
	function() return true end
}

-- Bubble spawner
local numBubbles = 8
local function spawnBubbles()
	local mat = models:partToWorldMatrix()
	for i = 1, numBubbles do
		particles["bubble"]
			:pos((mat * matrices.rotation4(0, world.getTime() * 10 - 360/numBubbles * i)):apply(15, 15))
			:spawn()
	end
end

function events.TICK()
	
	-- Reduce number of bubbles if not at max permission
	if avatar:getPermissionLevel() ~= "MAX" and world.getTime() % 2 == 0 then return end
	
	-- Spawn bubbles
	if bubbleTypes[sync[bubbles]]() and pose.swim and player:isInWater() then
		spawnBubbles()
	end
	
end

-- Set Bubbles type
function pings.setWhirlpoolBubbles(i)
	
	sync[bubbles] = ((sync[bubbles] + i - 1) % #bubbleTypes) + 1
	config:save("WhirlpoolState", sync[bubbles])
	if host:isHost() and player:isLoaded() and sync[bubbles] ~= 1 then
		sounds:playSound(sync[bubbles] == 2 and "entity.dolphin.ambient" or "block.bubble_column.upwards_inside", player:getPos(), 0.35)
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Tail") -- Tries to find script, not required

-- Page
local parentPage = action_wheel:getPage("Tail") or action_wheel:getPage("Main")

-- Actions table setup
local a = {}

-- Action
a.bubbleAct = parentPage:newAction()
	:onLeftClick(function() pings.setWhirlpoolBubbles(1) end)
	:onRightClick(function() pings.setWhirlpoolBubbles(-1) end)
	:onScroll(pings.setWhirlpoolBubbles)

-- Water context info table
local BubbleInfo = {
	{
		title = {label = {text = "No Bubbles", color = "red"}, text = "No bubbles will spawn while swimming."},
		item  = "soul_sand",
		color = "000000"
	},
	{
		title = {label = {text = "Dolphin\'s Grace", color = "yellow"}, text = "Bubbles will only spawn when under Dolphin\'s Grace."},
		item  = "dolphin_spawn_egg"
	},
	{
		title = {label = {text = "Always On", color = "green"}, text = "A whirlpool follows in your wake."},
		item  = "magma_block"
	}
}

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		
		local actionSetup = BubbleInfo[sync[bubbles]]
		a.bubbleAct
			:title(toJson(
				{
					"",
					{text = "Whirlpool Effect\n\n", bold = true, color = c.primary},
					{text = "Adjust how bubbles spawn while swimming.\n\n", color = c.secondary},
					{text = "Current configuration: ", bold = true, color = c.secondary},
					{text = actionSetup.title.label.text, color = actionSetup.title.label.color},
					{text = " | "},
					{text = actionSetup.title.text, color = c.secondary}
				}
			))
			:color(actionSetup.color or c.active)
			:item(actionSetup.item)
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover)
		end
		
	end
	
end