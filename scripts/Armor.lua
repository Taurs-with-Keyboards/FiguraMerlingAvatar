-- Required scripts
local parts        = require("lib.PartsAPI")
local merlingArmor = require("lib.KattArmor")()
local sync         = require("lib.LetThatSyncFig")

-- Synced variables setup
local helmet     = sync.add(config:load("ArmorHelmet"), true)
local chestplate = sync.add(config:load("ArmorChestplate"), true)
local leggings   = sync.add(config:load("ArmorLeggings"), true)
local boots      = sync.add(config:load("ArmorBoots"), true)
local tail       = sync.add(config:load("ArmorTail"), true)

-- Setting the leggings to layer 1
merlingArmor.Armor.Leggings:setLayer(1)

-- Armor parts
merlingArmor.Armor.Leggings
	:addParts(table.unpack(parts:createTable(function(part) return part:getName() == "Leggings" end)))
	:addTrimParts(table.unpack(parts:createTable(function(part) return part:getName() == "LeggingsTrim" end)))
merlingArmor.Armor.Boots
	:addParts(table.unpack(parts:createTable(function(part) return part:getName() == "Boot" end)))
	:addTrimParts(table.unpack(parts:createTable(function(part) return part:getName() == "BootTrim" end)))

-- Leather armor
merlingArmor.Materials.leather
	:setTexture(textures["textures.armor.leatherArmor"] or textures["Merling.leatherArmor"])
	:addParts(merlingArmor.Armor.Leggings, table.unpack(parts:createTable(function(part) return part:getName() == "LeggingsLeather" end)))
	:addParts(merlingArmor.Armor.Boots,    table.unpack(parts:createTable(function(part) return part:getName() == "BootLeather" end)))

-- Chainmail armor
merlingArmor.Materials.chainmail
	:setTexture(textures["textures.armor.chainmailArmor"] or textures["Merling.chainmailArmor"])

-- Iron armor
merlingArmor.Materials.iron
	:setTexture(textures["textures.armor.ironArmor"] or textures["Merling.ironArmor"])

-- Golden armor
merlingArmor.Materials.golden
	:setTexture(textures["textures.armor.goldenArmor"] or textures["Merling.goldenArmor"])

-- Diamond armor
merlingArmor.Materials.diamond
	:setTexture(textures["textures.armor.diamondArmor"] or textures["Merling.diamondArmor"])

-- Netherite armor
merlingArmor.Materials.netherite
	:setTexture(textures["textures.armor.netheriteArmor"] or textures["Merling.netheriteArmor"])

-- Trims
local trims = {
	"bolt",
	"coast",
	"dune",
	"eye",
	"flow",
	"host",
	"raiser",
	"rib",
	"sentry",
	"shaper",
	"silence",
	"snout",
	"spire",
	"tide",
	"vex",
	"ward",
	"wayfinder",
	"wild"
}

-- Apply trims
for _, trim in ipairs(trims) do
	local tex = textures["textures.armor.trims."..trim.."Trim"] or textures["Merling."..trim.."Trim"] or false
	if tex then
		merlingArmor.TrimPatterns[trim]:setTexture(tex)
	end
end

-- Helmet parts
local helmetGroups = {
	
	vanilla_model.HELMET
	
}

-- Chestplate parts
local chestplateGroups = {
	
	vanilla_model.CHESTPLATE
	
}

-- Leggings parts
local leggingsGroups = {
	
	vanilla_model.LEGGINGS,
	table.unpack(parts:createTable(function(part) return part:getName():find("ArmorLeggings") end))
	
}

-- Boots parts
local bootsGroups = {
	
	vanilla_model.BOOTS,
	table.unpack(parts:createTable(function(part) return part:getName():find("ArmorBoot") end))
	
}

-- Tail parts
local tailGroups = parts:createTable(function(part) return part:getName():find("ArmorTail") end)

function events.RENDER(delta, context)
	
	-- Apply
	for _, part in ipairs(helmetGroups) do
		part:visible(sync[helmet])
	end
	
	for _, part in ipairs(chestplateGroups) do
		part:visible(sync[chestplate])
	end
	
	for _, part in ipairs(leggingsGroups) do
		part:visible(sync[leggings])
	end
	
	for _, part in ipairs(bootsGroups) do
		part:visible(sync[boots])
	end
	
	for _, part in ipairs(tailGroups) do
		part:visible(sync[tail])
	end
	
end

-- All toggle
function pings.setArmorAll(boolean)
	
	sync[helmet]     = boolean
	sync[chestplate] = boolean
	sync[leggings]   = boolean
	sync[boots]      = boolean
	sync[tail]       = boolean
	config:save("ArmorHelmet", sync[helmet])
	config:save("ArmorChestplate", sync[chestplate])
	config:save("ArmorLeggings", sync[leggings])
	config:save("ArmorBoots", sync[boots])
	config:save("ArmorTail", sync[tail])
	if player:isLoaded() then
		sounds:playSound("item.armor.equip_generic", player:getPos(), 0.5)
	end
	
end

-- Helmet toggle
function pings.setArmorHelmet(boolean)
	
	sync[helmet] = boolean
	config:save("ArmorHelmet", sync[helmet])
	if player:isLoaded() then
		sounds:playSound("item.armor.equip_generic", player:getPos(), 0.5)
	end
	
end

-- Chestplate toggle
function pings.setArmorChestplate(boolean)
	
	sync[chestplate] = boolean
	config:save("ArmorChestplate", sync[chestplate])
	if player:isLoaded() then
		sounds:playSound("item.armor.equip_generic", player:getPos(), 0.5)
	end
	
end

-- Leggings toggle
function pings.setArmorLeggings(boolean)
	
	sync[leggings] = boolean
	config:save("ArmorLeggings", sync[leggings])
	if player:isLoaded() then
		sounds:playSound("item.armor.equip_generic", player:getPos(), 0.5)
	end
	
end

-- Boots toggle
function pings.setArmorBoots(boolean)
	
	sync[boots] = boolean
	config:save("ArmorBoots", sync[boots])
	if player:isLoaded() then
		sounds:playSound("item.armor.equip_generic", player:getPos(), 0.5)
	end
	
end

-- Tail toggle
function pings.setArmorTail(boolean)
	
	sync[tail] = boolean
	config:save("ArmorTail", sync[tail])
	if player:isLoaded() then
		sounds:playSound("item.armor.equip_generic", player:getPos(), 0.5)
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Player") -- Tries to find script, not required

-- Pages
local parentPage = action_wheel:getPage("Player") or action_wheel:getPage("Main")
local armorPage  = action_wheel:newPage("Armor")

-- Actions table setup
local a = {}

-- Actions
a.pageAct = parentPage:newAction()
	:item("iron_chestplate")
	:onLeftClick(function() wheel:descend(armorPage) end)

a.allAct = armorPage:newAction()
	:item("armor_stand")
	:toggleItem("netherite_chestplate")
	:onToggle(pings.setArmorAll)

a.helmetAct = armorPage:newAction()
	:item("iron_helmet")
	:toggleItem("diamond_helmet")
	:onToggle(pings.setArmorHelmet)

a.chestplateAct = armorPage:newAction()
	:item("iron_chestplate")
	:toggleItem("diamond_chestplate")
	:onToggle(pings.setArmorChestplate)

a.leggingsAct = armorPage:newAction()
	:item("iron_leggings")
	:toggleItem("diamond_leggings")
	:onToggle(pings.setArmorLeggings)

a.bootsAct = armorPage:newAction()
	:item("iron_boots")
	:toggleItem("diamond_boots")
	:onToggle(pings.setArmorBoots)

a.tailAct = armorPage:newAction()
	:item("salmon")
	:toggleItem("cod")
	:onToggle(pings.setArmorTail)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		a.pageAct
			:title(toJson(
				{text = "Armor Settings", bold = true, color = c.primary}
			))
		
		a.allAct
			:title(toJson(
				{
					"",
					{text = "Toggle All Armor\n\n", bold = true, color = c.primary},
					{text = "Toggles visibility of all armor parts.", color = c.secondary}
				}
			))
			:toggled(sync[helmet] and sync[chestplate] and sync[leggings] and sync[boots] and sync[tail])
		
		a.helmetAct
			:title(toJson(
				{
					"",
					{text = "Toggle Helmet\n\n", bold = true, color = c.primary},
					{text = "Toggles visibility of helmet parts.", color = c.secondary}
				}
			))
			:toggled(sync[helmet])
		
		a.chestplateAct
			:title(toJson(
				{
					"",
					{text = "Toggle Chestplate\n\n", bold = true, color = c.primary},
					{text = "Toggles visibility of chestplate parts.", color = c.secondary}
				}
			))
			:toggled(sync[chestplate])
		
		a.leggingsAct
			:title(toJson(
				{
					"",
					{text = "Toggle Leggings\n\n", bold = true, color = c.primary},
					{text = "Toggles visibility of leggings parts.", color = c.secondary}
				}
			))
			:toggled(sync[leggings])
		
		a.bootsAct
			:title(toJson(
				{
					"",
					{text = "Toggle Boots\n\n", bold = true, color = c.primary},
					{text = "Toggles visibility of boots.", color = c.secondary}
				}
			))
			:toggled(sync[boots])
		
		a.tailAct
			:title(toJson(
				{
					"",
					{text = "Toggle Tail Armor\n\n", bold = true, color = c.primary},
					{text = "Toggles visibility of tail armor.", color = c.secondary}
				}
			))
			:toggled(sync[tail])
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end