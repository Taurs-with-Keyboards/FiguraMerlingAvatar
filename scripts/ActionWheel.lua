-- Disables code if not avatar host
if not host:isHost() then return end

-- Table setup
local t = {}

-- Set starting page to main page
local main = action_wheel:newPage("Main")
action_wheel:setPage(main)

-- Logs pages order for navigation
t.navigation = {}

-- Go forward a page
function t:descend(page)
	
	t.navigation[#t.navigation + 1] = action_wheel:getCurrentPage() 
	action_wheel:setPage(page)
	
end

-- Go back a page
function t:ascend()
	
	action_wheel:setPage(table.remove(t.navigation, #t.navigation))
	
end

-- Reset to main page
function t:reset()
	
	t.navigation = {}
	action_wheel:setPage(main)
	
end

-- Wrap item functions in the action API in the itemCheck lib function
local itemCheck = require("lib.ItemCheck")
local oldActionIndex = figuraMetatables.Action.__index
local adjFuncs = {}
local adjKeys = {
	"setItem",
	"setToggleItem",
	"setHoverItem"
}

-- Create functions to override API
for _, k in ipairs(adjKeys) do
	
	-- Get old function
	local oldFunc = oldActionIndex(nil, k)
	
	-- Create wrapper around function
	adjFuncs[k] = function(self, ...)
		local item = itemCheck(...)
		return oldFunc(self, item)
	end
	
	-- Copy new function to alias
	adjFuncs[k:gsub("^set(%u)", string.lower)] = adjFuncs[k]
	
end

-- Apply to API
function figuraMetatables.Action.__index(self, key)
	return adjFuncs[key] or oldActionIndex(self, key)
end

-- Action back to previous page
local backAct = action_wheel:newAction()
	:title(toJson(
		{text = "Go Back?", bold = true, color = "red"}
	))
	:hoverColor(vectors.hexToRGB("FF5555"))
	:item("barrier")
	:onLeftClick(function() t:ascend() end)
	:onRightClick(function() t:reset() end)

-- After all pages are created, add a back button to all pages except main
function events.ENTITY_INIT()
	
	for k, v in pairs(action_wheel:getPage()) do
		if k ~= "Main" then
			v:setAction(-1, backAct)
		end
	end
	
end

-- Provides color inputs (provided by script)
local s, c = pcall(require, "scripts.ColorProperties")
if not s then c = {} end

-- Return tables and functions
return t, c