--[[
	
	Hi, Total here.
	This script has been the cause of sleepless nights, headaches, stress beyond belief, and sorrow. I have forgotten if I've cried over this script, but it wouldn't surprise me.
	I am writing this with the soul purpose of telling you to fuck off. I am serious.
	If you have a problem with the camera, I want you to shove it where I don't have to see it. Complaints will go into the shredder before they can be comprehended.
	I've tried my best, I really have. If you believe you can make the camera better, great, contribute to the GitHub repository. That's what it's there for.
	Until then, keep it to yourself. I'm extremely aware of the issues this script has.
	
	Here, let's actually list off some issues this script has, so that you can be annoyed by them too:
	- Frame delay caused by `partToWorldMatrix()`
	- Random "In Wall" damage caused by setting the eye position
	- Head invisible in some cases, usually caused by other mods/shaders
	- Fights freecam mods
	- Etc.
	
	Anyhow, I've spent probably more than 168 hours looking at this script alone, and its many iterations.
	Feel free to wither away here too, if your heart asks you to.
	
	- Total
	
--]]

-- Required scripts
local parts = require("lib.PartsAPI")
local sync  = require("lib.LetThatSyncFig")
local lerp  = require("lib.LerpAPI")

-- Variable setup
local camera = parts.group.Camera
if not camera then return end

-- Get server data
local serverData = client:getServerData()
local serverId = serverData.ip or serverData.name or "none"
local savedServers = config:load("CameraServers") or {}

-- Synced variables setup
local allowCam = sync.new("CameraToggle", false):config()
local allowEye = sync.new("CameraEyeToggle", savedServers[serverId] or false)

-- Set camera parent type
camera:parentType("HEAD")

-- Crosshair lerp (helps prevent jittering)
local crossLerp = lerp.new(vec(0, 0), 1)

-- Box check
local function inBox(pos, box_min, box_max)
	return pos.x >= box_min.x and pos.x <= box_max.x and
		   pos.y >= box_min.y and pos.y <= box_max.y and
		   pos.z >= box_min.z and pos.z <= box_max.z
end

-- Resets the camera
local function cameraReset()
	
	-- Resets camera
	renderer
		:cameraPivot(nil)
		:eyeOffset(nil)
		:crosshairOffset(nil)
	
	-- Show head
	parts.group.Head:visible(true)
	
end

-- Head midRender event
function events.RENDER(delta, context)
	
	-- If camera is allowed
	if allowCam.curr then
		
		-- Get camera position
		local camPos = camera:partToWorldMatrix():apply() + (player:getPose() == "SLEEPING" and vec(0, 0.2, 0) or 0)
		
		-- Check for block obstruction
		local obstructed = false
		local adjustedPos = camPos + client:getCameraDir() * 0.1
		local blockPos = adjustedPos:copy():floor()
		local block = world.getBlockState(blockPos)
		local boxes = block:getCollisionShape()
		if boxes then
			for i = 1, #boxes do
				local box = boxes[i]
				if inBox(adjustedPos, blockPos + box[1], blockPos + box[2]) then
					obstructed = true
					break
				end
			end
		end
		
		-- If camera isn't obstructed
		if not obstructed then
			
			-- Variables
			local pos    = player:getPos(delta)
			local height = player:getEyeHeight()
			local reach  = host:getReachDistance()
			
			-- Positions
			local eyePos = -((pos + vec(0, height, 0)) - camPos)
			local tarEntity, tarEntityPos = player:getTargetedEntity(reach)
			local tarBlock, tarBlockPos = player:getTargetedBlock(true, reach)
			
			-- Get target pos
			local targetPos = (tarEntity and tarEntityPos) or (tarBlock and not tarBlock:isAir() and tarBlockPos) or nil
			
			-- Convert target to screenspace
			crossLerp.target = targetPos and vectors.worldToScreenSpace(targetPos).xy * client:getScaledWindowSize() / 2 or vec(0, 0)
			
			-- Changes camera pivot
			renderer
				:cameraPivot(camPos)
				:eyeOffset(allowEye.curr and eyePos or nil)
				:crosshairOffset(not allowEye.curr and crossLerp.currPos or nil)
			
			-- Hide head
			parts.group.Head:visible(not (renderer:isFirstPerson() and (context == "OTHER" or context == "RENDER")))
			
		else
			
			-- Reset camera
			cameraReset()
			
		end
		
	else
		
		-- Reset camera
		cameraReset()
		
	end
	
end

-- Host only instructions
if not host:isHost() then return end

-- Save server to config
allowEye:applyFunc(function()
	savedServers[serverId] = allowEye.curr
	config:save("CameraServers", savedServers)
end)

-- Required scripts
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Player") -- Tries to find script, not required

-- Pages
local parentPage = action_wheel:getPage("Player") or action_wheel:getPage("Main")
local cameraPage = action_wheel:newPage("Camera")

-- Actions table setup
local a = {}

-- Actions
a.pageAct = parentPage:newAction()
	:item("redstone")
	:onLeftClick(function() wheel:descend(cameraPage) end)

a.posAct = cameraPage:newAction()
	:item("skeleton_skull")
	:toggleItem("player_head{SkullOwner:"..avatar:getEntityName().."}")
	:onToggle(function(bool)
		allowCam:update(bool)
	end)
	:toggled(allowCam.curr)

a.eyeAct = cameraPage:newAction()
	:item("ender_pearl")
	:toggleItem("ender_eye")
	:onToggle(function(bool)
		allowEye:update(bool)
	end)
	:toggled(allowEye.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		a.pageAct
			:title(toJson(
				{text = "Camera Settings", bold = true, color = c.primary}
			))
		
		a.posAct
			:title(toJson(
				{
					"",
					{text = "Camera Position Toggle\n\n", bold = true, color = c.primary},
					{text = "Sets the camera position to where your avatar\'s head is.\nYour crosshair will move to show which block you are targeting.\nAdditionally, hides the head. (Useful for the \"First Person Model\" mod)\n\n", color = c.secondary},
					{text = "To prevent x-ray, the camera will reset to its default position if inside a block.", color = "red"}
				}
			))
		
		a.eyeAct
			:title(toJson(
				{
					"",
					{text = "Eye Position Toggle\n\n", bold = true, color = c.primary},
					{text = "Sets the eye position to match the avatar\'s head.\nRequires camera position toggle.\n\n", color = c.secondary},
					{text = "WARNING: ", bold = true, color = "dark_red"},
					{text = "This feature is dangerous!\nIt can and will be flagged on servers with anticheat!\nFurthermore, \"In Wall\" damage is possible. (The x-ray prevention will try to avoid this)\nThis setting will only be saved on a \"Per-Server\" basis.\n\nPlease use with extreme caution!", color = "red"}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end