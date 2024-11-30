-- Kill script if `mermod_tail` is not found
if not mermod_tail then return {} end 

-- Disable mermod tail
if mermod_tail.setVisible then -- 1.19+
	mermod_tail:setVisible(false)
end
if mermod_tail.setDisabled then -- 1.18
	mermod_tail.setDisabled(true)
end

-- Kill script if unable to style tail
if not mermod_tail.getTailStyle then return {} end

-- Required scripts
local parts = require("lib.PartsAPI")
local sync  = require("lib.LetThatSyncFig")

-- Synced variables setup
local override = sync.new("MermodOverride", false):config("MermodOverride")

-- Mermod parts
local mermodParts = parts:createTable(function(part) return part:getName():find("_[mM]ermod") end)

-- Variables
local _swap = nil
local _style = {}
pcall(require, "scripts.ColorProperties")
local initAvatarColor = vectors.hexToRGB(avatar:getColor() or "default")
local grayMat = matrices.mat4(
	vec(0.65, 0.65, 0.65, 0),
	vec(0.65, 0.65, 0.65, 0),
	vec(0.65, 0.65, 0.65, 0),
	vec(0, 0, 0, 1)
)

-- Main textures
local mermodTextures = {
	
	primary   = textures:copy("mermodTail",   textures["textures.tail"]   or textures["Merling.tail"]),
	secondary = textures:copy("mermodTail_e", textures["textures.tail_e"] or textures["Merling.tail_e"])
	
}

-- Apply main textures
for _, part in ipairs(mermodParts) do
	
	part
		:primaryTexture("CUSTOM", mermodTextures.primary)
		:secondaryTexture("CUSTOM", mermodTextures.secondary)
	
end

-- Tails table
local tailParts = {
	
	{parts.group.Tail1},
	{
		parts.group.Tail2,
		parts.group.Tail2LeftFin,
		parts.group.Tail2RightFin
	},
	{parts.group.Tail3},
	{parts.group.Tail4},
	{parts.group.Fluke}
	
}

-- Establish tail textures
local segmentTextures = {}
local function applyGradTex(m, i)
	
	for _, c in ipairs(m:getChildren()) do
		
		if c:getName():find("_[mM]ermod") then
			c:primaryTexture("CUSTOM", segmentTextures[i].primary):secondaryTexture("CUSTOM", segmentTextures[i].secondary)
		end
		
	end
	
end
for i, k in ipairs(tailParts) do
	
	segmentTextures[i] = {
		primary   = textures:copy(mermodTextures.primary:getName()..i,       mermodTextures.primary),
		secondary = textures:copy(mermodTextures.primary:getName()..i.."_e", mermodTextures.secondary)
	}
	
	for _, part in ipairs(k) do
		applyGradTex(part, i)
	end
	
end

-- Apply color
local function applyColor(tex, color, typ)
	
	local mat = math.lerp(matrices.mat4(), grayMat, typ)
	
	local dimensions = tex:getDimensions()
	tex:restore():applyMatrix(0, 0, dimensions.x, dimensions.y, mat:scale(color), true):update()
	
end

function events.RENDER(delta, context)
	
	-- Variable
	local style = mermod_tail:getTailStyle()
	local swap = override.curr and style and true or false
	
	local changed = false
	for k in pairs(style or {}) do
		if style[k] and _style[k] and style[k] ~= _style[k] then
			changed = true
			break
		end
	end
	
	if swap ~= _swap or changed then
		
		-- Variables
		local color = swap and vec(style.tailColorR, style.tailColorG, style.tailColorB) or vec(1, 1, 1)
		local grad = swap and style.hasGradient and vec(style.gradientColorR, style.gradientColorG, style.gradientColorB) or color
		local typ = swap and 1 or 0
		
		-- Tail textures
		for _, tex in pairs(mermodTextures) do
			applyColor(tex, color, typ)
		end
		for k, v in ipairs(segmentTextures) do
			
			local setColor = math.lerp(color, grad, k/#tailParts)
			for _, tex in pairs(v) do
				applyColor(tex, setColor, typ)
			end
			
		end
		
		-- Avatar color
		avatar:color(math.lerp(initAvatarColor, (color + grad) / 2, typ))
		
	end
	
	-- Store data
	_swap = swap
	_style = style or {}
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Tail") -- Tries to find script, not required
pcall(require, "scripts.WhirlpoolEffect") -- Tries to find script, not required

-- Dont preform if color properties is empty
if next(c) ~= nil then
	
	-- Store init colors
	local initColors = {}
	for k, v in pairs(c) do
		initColors[k] = v
	end
	
	-- Update action wheel colors
	function events.RENDER(delta, context)
	
		-- Variables
		local style = mermod_tail:getTailStyle()
		local swap  = override.curr and style and true or false
		local color = swap and vec(style.tailColorR, style.tailColorG, style.tailColorB) or vec(1, 1, 1)
		local grad  = swap and style.hasGradient and vec(style.gradientColorR, style.gradientColorG, style.gradientColorB) or color
		
		-- Create mermod colors
		local mermodColors = {
			hover     = color,
			active    = grad,
			primary   = "#"..vectors.rgbToHex(color),
			secondary = "#"..vectors.rgbToHex(grad)
		}
		
		-- Update action wheel colors
		for k in pairs(c) do
			c[k] = swap and mermodColors[k] or initColors[k]
		end
		
	end
	
end

-- Check for if page already exists
local pageExists = action_wheel:getPage("Tail")

-- Pages
local parentPage = action_wheel:getPage("Main")
local tailPage   = pageExists or action_wheel:newPage("Tail")

-- Actions table setup
local a = {}

-- Actions
if not pageExists then
	a.pageAct = parentPage:newAction()
		:item("tropical_fish")
		:onLeftClick(function() wheel:descend(tailPage) end)
end

a.overrideAct = tailPage:newAction()
	:onToggle(function(bool)
		override:update(bool)
	end)
	:toggled(override.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if a.pageAct then
			a.pageAct
				:title(toJson(
					{text = "Tail Settings", bold = true, color = c.primary}
				))
		end
		
		-- Color variables
		local style = mermod_tail:getTailStyle()
		local necklace = style and vec(style.tailColorR, style.tailColorG, style.tailColorB) or vec(1, 1, 1)
		
		a.overrideAct
			:title(toJson(
				{
					"",
					{text = "Toggle Mermod Override\n\n", bold = true, color = c.primary},
					{text = "Allows mermod to apply various features onto the avatar.\n\nThis includes:\n- Tail color\n- Gradient", color = c.secondary}
				}
			))
			:item("mermod:sea_necklace{display:{color:"..vectors.rgbToInt(necklace).."}}")
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end