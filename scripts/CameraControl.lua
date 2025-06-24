-- Required scripts
local parts = require("lib.PartsAPI")
local pose  = require("scripts.Posing")

-- Config setup
config:name("Merling")
local camPos       = config:load("CameraPos") or false
local savedServers = config:load("CameraServers") or {}

-- Get server id
local serverData = client:getServerData()
local serverId   = serverData.ip and serverData.ip or serverData.name or "none"

-- Establish server, and set eyePos to server
savedServers[serverId] = savedServers[serverId] or false
local eyePos = savedServers[serverId]

-- Variable setup
local head = parts.group.Head

-- Sleep rotations
local dirRot = {
	north = 0,
	east  = 270,
	south = 180,
	west  = 90
}

-- Get part matrix of part and parent parts
local function calcMatrix(p)
	return p and p ~= models and (calcMatrix(p:getParent()) * p:getPositionMatrix()) or matrices.mat4()
end

-- Box check
local function inBox(pos, box_min, box_max)
	return pos.x >= box_min.x and pos.x <= box_max.x and
		   pos.y >= box_min.y and pos.y <= box_max.y and
		   pos.z >= box_min.z and pos.z <= box_max.z
end

function events.RENDER(delta, context)
	if context == "FIRST_PERSON" or context == "RENDER" or (not client.isHudEnabled() and context ~= "MINECRAFT_GUI") then
		
		-- Variables
		local yaw = player:getBodyYaw(delta)
		
		-- Pehkui scaling
		local nbt   = player:getNbt()
		local types = nbt["pehkui:scale_data_types"]
		local playerScale = (
			types and
			types["pehkui:base"] and
			types["pehkui:base"]["scale"] or 1)
		local width = (
			types and
			types["pehkui:width"] and
			types["pehkui:width"]["scale"] or 1)
		local modelWidth = (
			types and
			types["pehkui:model_width"] and
			types["pehkui:model_width"]["scale"] or 1)
		local height = (
			types and
			types["pehkui:height"] and
			types["pehkui:height"]["scale"] or 1)
		local modelHeight = (
			types and
			types["pehkui:model_height"] and
			types["pehkui:model_height"]["scale"] or 1)
		local modelEyeHeight = (
			types and
			types["pehkui:eye_height"] and
			types["pehkui:eye_height"]["scale"] or 1)
		local offsetScale = vec(width * modelWidth, height * modelHeight, width * modelWidth) * playerScale
		
		-- Camera offset
		local posOffset  = calcMatrix(head):apply(head:getPivot()) / 16
		local nameOffset = posOffset + vec(0, 0.85, 0)
		
		if pose.stand or pose.crouch then
			
			-- If standing, lower camera offset
			posOffset = posOffset - vec(0, 24 * modelEyeHeight, 0) / 16
			
		else
			
			-- else, slightly lower camera offset
			posOffset  = posOffset - vec(0, (pose.sleep and 24 or pose.elytra and 0 or 16), 0) / 16
			nameOffset = posOffset - vec(0, (pose.sleep and 4 or -4) * modelEyeHeight, -20) / 16
			
			-- else, rotate camera offset on x axis
			posOffset  = vectors.rotateAroundAxis(-player:getRot().x - 90, posOffset,  vec(1, 0, 0))
			nameOffset = vectors.rotateAroundAxis(-player:getRot().x - 90, nameOffset, vec(1, 0, 0))
			
		end
		
		-- Rotate camera offset on y axis
		if pose.sleep then
			
			-- Find block
			local block = world.getBlockState(player:getPos())
			local sleepRot = dirRot[block.properties["facing"]]
			
			posOffset  = vectors.rotateAroundAxis(sleepRot, posOffset,  vec(0, 1, 0))
			nameOffset = vectors.rotateAroundAxis(sleepRot, nameOffset, vec(0, 1, 0))
			
		else
			
			posOffset  = vectors.rotateAroundAxis(-yaw + 180, posOffset,  vec(0, 1, 0))
			nameOffset = vectors.rotateAroundAxis(-yaw + 180, nameOffset, vec(0, 1, 0))
			
		end
		
		-- Apply offset
		posOffset = posOffset * offsetScale
		
		-- Check for block obstruction
		local obstructed = false
		local cameraPos = parts.group.Body:partToWorldMatrix():apply() + vec(0, 0.2, 0) + client:getCameraDir() * 0.1
		local blockPos = cameraPos:copy():floor()
		local block = world.getBlockState(blockPos)
		local boxes = block:getCollisionShape()
		if boxes then
			for i = 1, #boxes do
				local box = boxes[i]
				if inBox(cameraPos, blockPos + box[1], blockPos + box[2]) then
					obstructed = true
					break
				end
			end
		end
		
		-- Renders offset
		renderer
			:offsetCameraPivot(camPos and not obstructed and posOffset or 0)
			:eyeOffset(eyePos and camPos and not obstructed and posOffset or 0)
		
		-- Nameplate placement
		nameplate.ENTITY
			:pivot(nameOffset)
		
	end
	
	-- Disable head if first person mod is active
	head:visible(context ~= "OTHER")
	
end

-- Camera pos toggle
function pings.setCameraPos(boolean)
	
	camPos = boolean
	config:save("CameraPos", camPos)
	
end

-- Eye pos toggle
function pings.setCameraEye(boolean)
	
	eyePos = boolean
	savedServers[serverId] = boolean
	config:save("CameraServers", savedServers)
	
end

-- Sync variables
function pings.syncCamera(a, b)
	
	camPos = a
	eyePos = b
	
end

-- Host only instructions
if not host:isHost() then return end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncCamera(camPos, eyePos)
	end
	
end

-- Required scripts
local s, wheel, itemCheck, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.Player") -- Tries to find script, not required

-- Pages
local parentPage = action_wheel:getPage("Player") or action_wheel:getPage("Main")
local cameraPage = action_wheel:newPage("Camera")

-- Actions table setup
local a = {}

-- Actions
a.pageAct = parentPage:newAction()
	:item(itemCheck("redstone"))
	:onLeftClick(function() wheel:descend(cameraPage) end)
	
a.posAct = cameraPage:newAction()
	:item(itemCheck("skeleton_skull"))
	:toggleItem(itemCheck("player_head{SkullOwner:"..avatar:getEntityName().."}"))
	:onToggle(pings.setCameraPos)
	:toggled(camPos)

a.eyeAct = cameraPage:newAction()
	:item(itemCheck("ender_pearl"))
	:toggleItem(itemCheck("ender_eye"))
	:onToggle(pings.setCameraEye)
	:toggled(eyePos)

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
					{text = "Sets the camera position to where your avatar\'s head is.\n\n", color = c.secondary},
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