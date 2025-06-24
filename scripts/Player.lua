-- Required script
local parts = require("lib.PartsAPI")

-- Config setup
config:name("Merling")
local vanillaSkin = config:load("AvatarVanillaSkin")
local slim        = config:load("AvatarSlim") or false
if vanillaSkin == nil then vanillaSkin = true end

-- Reenabled parts
parts.group.LeftLeg :visible(true)
parts.group.RightLeg:visible(true)
parts.group.Skull   :visible(true)
parts.group.Portrait:visible(true)

-- Arm parts
local defaultParts = parts:createTable(function(part) return part:getName():find("ArmDefault") end)
local slimParts    = parts:createTable(function(part) return part:getName():find("ArmSlim")    end)

-- Vanilla skin parts
local skinParts = parts:createTable(function(part) return part:getName():find("_[sS]kin") end)

-- Layer parts
local layerTypes = {"HAT", "JACKET", "LEFT_SLEEVE", "RIGHT_SLEEVE", "LEFT_PANTS_LEG", "RIGHT_PANTS_LEG", "CAPE", "TAIL_LAYER"}
local layerParts = {}
for _, type in pairs(layerTypes) do
	layerParts[type] = parts:createTable(function(part) return part:getName():find(type) end)
end

-- Apply translucent cull
local flatParts = parts:createTable(function(part) return part:getName():find("_[fF]lat") end)
for _, part in ipairs(flatParts) do
	part:primaryRenderType("TRANSLUCENT_CULL")
end

-- Determine vanilla player type on init
local vanillaAvatarType
function events.ENTITY_INIT()
	
	vanillaAvatarType = player:getModelType()
	
end

function events.RENDER(delta, context)
	
	-- Model shape
	local slimShape = (vanillaSkin and vanillaAvatarType == "SLIM") or (slim and not vanillaSkin)
	for _, part in ipairs(defaultParts) do
		part:visible(not slimShape)
	end
	for _, part in ipairs(slimParts) do
		part:visible(slimShape)
	end
	
	-- Skin textures
	local skinType = vanillaSkin and "SKIN" or "PRIMARY"
	for _, part in ipairs(skinParts) do
		part:primaryTexture(skinType)
	end
	
	-- Cape textures
	parts.group.Cape:primaryTexture(vanillaSkin and "CAPE" or "PRIMARY")
	
	-- Layer toggling
	for layerType, parts in pairs(layerParts) do
		local enabled
		if layerType == "TAIL_LAYER" then
			enabled = player:isSkinLayerVisible("RIGHT_PANTS_LEG") or player:isSkinLayerVisible("LEFT_PANTS_LEG")
		else
			enabled = player:isSkinLayerVisible(layerType)
		end
		for _, part in ipairs(parts) do
			part:visible(enabled)
		end
	end
	
end

-- Vanilla skin toggle
function pings.setAvatarVanillaSkin(boolean)
	
	vanillaSkin = boolean
	config:save("AvatarVanillaSkin", vanillaSkin)
	
end

-- Model type toggle
function pings.setAvatarModelType(boolean)
	
	slim = boolean
	config:save("AvatarSlim", slim)
	
end

-- Sync variables
function pings.syncPlayer(a, b)
	
	vanillaSkin = a
	slim = b
	
end

-- Host only instructions
if not host:isHost() then return end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncPlayer(vanillaSkin, slim)
	end
	
end

-- Required script
local s, wheel, itemCheck, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found

-- Pages
local parentPage = action_wheel:getPage("Main")
local playerPage = action_wheel:newPage("Player")

-- Actions table setup
local a = {}

-- Actions
a.pageAct = parentPage:newAction()
	:item(itemCheck("armor_stand"))
	:onLeftClick(function() wheel:descend(playerPage) end)

a.vanillaSkinAct = playerPage:newAction()
	:item(itemCheck("player_head{SkullOwner:"..avatar:getEntityName().."}"))
	:onToggle(pings.setAvatarVanillaSkin)
	:toggled(vanillaSkin)

a.modelAct = playerPage:newAction()
	:item(itemCheck("player_head"))
	:toggleItem(itemCheck("player_head{SkullOwner:MHF_Alex}"))
	:onToggle(pings.setAvatarModelType)
	:toggled(slim)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		a.pageAct
			:title(toJson(
				{text = "Player Settings", bold = true, color = c.primary}
			))
		
		a.vanillaSkinAct
			:title(toJson(
				{
					"",
					{text = "Toggle Vanilla Texture\n\n", bold = true, color = c.primary},
					{text = "Toggles the usage of your vanilla skin.", color = c.secondary}
				}
			))
		
		a.modelAct
			:title(toJson(
				{
					"",
					{text = "Toggle Model Shape\n\n", bold = true, color = c.primary},
					{text = "Adjust the model shape to use Default or Slim Proportions.\nWill be overridden by the vanilla skin toggle.", color = c.secondary}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end