--================================================--
--   _  ___ _    ____      _    ___   __  ____    --
--  | |/ (_) |_ / ___|__ _| |_ / _ \ / /_|___ \   --
--  | ' /| | __| |   / _` | __| (_) | '_ \ __) |  --
--  | . \| | |_| |__| (_| | |_ \__, | (_) / __/   --
--  |_|\_\_|\__|\____\__,_|\__|  /_/ \___/_____|  --
--                                                --
--================================================--

--v4.3.0

---@alias KattArmor.ArmorPartID
---| '"Helmet"'
---| '"Chestplate"'
---| '"Leggings"'
---| '"Boots"'

---@alias KattArmor.ArmorPartSlot
---| 6
---| 5
---| 4
---| 3

---@alias KattArmor.MaterialID string
---| '"leather"'
---| '"chainmail"'
---| '"iron"'
---| '"golden"'
---| '"diamond"'
---| '"netherite"'
---| '"turtle"'
---| true

---@alias KattArmor.TrimPatternID string
---| "coast"
---| "dune"
---| "eye"
---| "host"
---| "raiser"
---| "rib"
---| "sentry"
---| "shaper"
---| "silence"
---| "snout"
---| "spire"
---| "tide"
---| "vex"
---| "ward"
---| "wayfinder"
---| "wild"

---@alias KattArmor.TrimMaterialID string
---| "amethyst"
---| "copper"
---| "diamond"
---| "emerald"
---| "gold"
---| "iron"
---| "lapis"
---| "netherite"
---| "quartz"
---| "redstone"

local function Class()
  local cls = {}
  function cls.__index(_, index) return cls[index] end

  function cls:new(...)
    local i = {}
    if cls.init then cls.init(i, ...) end
    return setmetatable(i, cls)
  end

  return cls;
end

---@type KattArmor.Instance[]
local instances = {}
---@alias KattArmor.onRenderCallback fun(materialID:KattArmor.MaterialID, partID:KattArmor.ArmorPartID, item:ItemStack, visible:boolean, renderType:"EMISSIVE"|"GLINT", color:Vector3, texture:KattArmor.Material.Texture, textureType:"RESOURCE"|"CUSTOM"|nil, texture_e:KattArmor.Material.Texture, textureType_e:"RESOURCE"|"CUSTOM"|nil,damageOverlay:0|nil, trim:boolean, trimPattern:KattArmor.TrimPatternID?, trimMaterial:KattArmor.TrimMaterialID?, trimTexture:KattArmor.Material.Texture?, trimTextureType:"RESOURCE"|"CUSTOM"|nil, trimColor:Vector3?, trimUV:Matrix3?)
local update = true
local function forceUpdate()
  update = true
end
---@alias KattArmor.onChangeCallback fun(partID:KattArmor.ArmorPartID, item:ItemStack):KattArmor.MaterialID?
---@type KattArmor.onChangeCallback[]
local changeCallbacks = {}
---@param fn KattArmor.onChangeCallback
local function registerOnChange(fn)
  table.insert(changeCallbacks, fn)
  forceUpdate()
end
---@type table<KattArmor.ArmorPartID, KattArmor.ArmorPartSlot>
local ArmorPart_SlotID_Map = {
  Helmet = 6,
  Chestplate = 5,
  Leggings = 4,
  Boots = 3,
}
---@type table<KattArmor.ArmorPartSlot, KattArmor.ArmorPartID>
local SlotID_ArmorPart_Map = {
  [6] = "Helmet",
  [5] = "Chestplate",
  [4] = "Leggings",
  [3] = "Boots",
}

---@alias KattArmor.ArmorPart.Layer 1|2

---@class KattArmor.ArmorPart
---@field parts ModelPart[]
---@field trimParts ModelPart[]
---@field layer KattArmor.ArmorPart.Layer
---@field slot KattArmor.ArmorPartSlot
---@field override KattArmor.MaterialID?
---@field overrideTrimNamespace string?
---@field overrideTrimPattern KattArmor.TrimPatternID?
---@field overrideTrimMaterial KattArmor.TrimMaterialID?
---@field prevItem ItemStack
---@field prevMaterial KattArmor.Material
---
---@field new fun(self:self, partID:KattArmor.ArmorPartID):KattArmor.ArmorPart
local ArmorPart = Class()
ArmorPart.__type = "ArmorPart"
function ArmorPart:init(partID)
  self.parts = {}
  self.trimParts = {}
  self.layer = 1
  self.slot = ArmorPart_SlotID_Map[partID]
end

---Add ModelParts that act as Armor Parts, switching textures based on the currently equipped armor.
---@param ... ModelPart
---@return self
function ArmorPart:addParts(...)
  local parts = table.pack(...)
  for i = 1, parts.n do
    local part = parts[i]
    if type(part) ~= "ModelPart" then
      error(
        ("Expected ModelPart, got %s (%s) at index %i in varargs when adding Armor Parts")
        :format(tostring(part), type(part), i),
        2
      )
    end
    table.insert(self.parts, part)
  end
  forceUpdate()
  return self
end

---Add ModelParts that act as Armor Trims, switching textures based on the currently equipped armor's trim.
---@param ... ModelPart
---@return self
function ArmorPart:addTrimParts(...)
  local parts = table.pack(...)
  for i = 1, parts.n do
    local part = parts[i]
    if type(part) ~= "ModelPart" then
      error(
        ("Expected ModelPart, got %s (%s) at index %i in varargs when adding Trim Parts")
        :format(tostring(part), type(part), i),
        2
      )
    end
    local vertices = {}
    local min = vec(1024, 1024, 1024)
    local max = vec(-1024, -1024, -1024)
    for _, group in pairs(part:getAllVertices()) do
      for _, vertex in ipairs(group) do
        local pos = vertex:getPos()
        table.insert(vertices, { pos = pos, vert = vertex })
        min.x = math.min(min.x, pos.x)
        min.y = math.min(min.y, pos.y)
        min.z = math.min(min.z, pos.z)
        max.x = math.max(max.x, pos.x)
        max.y = math.max(max.y, pos.y)
        max.z = math.max(max.z, pos.z)
      end
    end
    local mid = (min + max) / 2
    for _, vert in ipairs(vertices) do
      vert.vert:setPos(math.lerp(mid, vert.pos, 1.01))
    end
    table.insert(self.trimParts, part)
  end
  forceUpdate()
  return self
end

---Sets the texture layer that this ArmorPart uses.
---If there is no layer2 texture defined in the material, the normal texture will be used.
---This is purly just here for vanilla leggings compatibility, though there might be a smart use for this.
---@param layer KattArmor.ArmorPart.Layer
---@return self
function ArmorPart:setLayer(layer)
  if layer ~= 2 then layer = 1 end
  self.layer = layer
  forceUpdate()
  return self
end

---Forces the given material to render, ignoring the auto-found material.
---@param material KattArmor.MaterialID?
---@return self
function ArmorPart:setMaterial(material)
  if material ~= self.override then
    self.override = material
  end
  forceUpdate()
  return self
end

---Forces the trim with the material to render, ignoring whatever nbt data is present.
---@param namespace string?
---@param trim KattArmor.TrimPatternID?
---@param material KattArmor.TrimMaterialID?
---@return self
function ArmorPart:setTrim(namespace, trim, material)
  self.overrideTrimNamespace = namespace
  self.overrideTrimPattern = trim
  self.overrideTrimMaterial = material
  forceUpdate()
  return self
end

---@alias KattArmor.Material.Texture Texture | string | nil

---@class KattArmor.Material
---@field visible boolean
---@field texture table<KattArmor.ArmorPart.Layer, KattArmor.Material.Texture>
---@field texture_e table<KattArmor.ArmorPart.Layer, KattArmor.Material.Texture>
---@field forceGlint boolean|nil
---@field shouldUseColor boolean
---@field defaultColor integer
---@field parts table<KattArmor.ArmorPart, ModelPart[]>
---@field materialPartsColor boolean
---@field damageOverlay boolean
---
---@field new fun():KattArmor.Material
local Material = Class()
Material.__type = "ArmorMaterial"
function Material:init()
  self.parts = {}
  self.visible = true
  self.texture = {}
  self.texture_e = {}
  self.forceGlint = nil
  self.shouldUseColor = true
  self.materialPartsColor = false
  self.damageOverlay = false
end

---Adds ModelParts that will only be active while this Material is active for the given ArmorPart
---@param armorPart KattArmor.ArmorPart | KattArmor.ArmorPartID
---@param ... ModelPart
---@return self
function Material:addParts(armorPart, ...)
  if type(armorPart) == "ArmorPart" then armorPart = SlotID_ArmorPart_Map[armorPart.slot] end
  if not ArmorPart_SlotID_Map[armorPart] then
    error(("%s (%s) is not a valid ArmorPartID."):format(
      tostring(armorPart), type(armorPart)))
  end
  if not self.parts[armorPart] then self.parts[armorPart] = {} end
  local parts = table.pack(...)
  for i = 1, parts.n do
    local part = parts[i]
    if type(part) ~= "ModelPart" then
      error(
        ("Expected ModelPart, got %s (%s) at index %i in varargs when adding Material Parts"):format(
          tostring(part),
          type(part), i), 2)
    end
    table.insert(self.parts[armorPart], part:setVisible(false))
  end
  forceUpdate()
  return self
end

---Should this valid Material render?
---Used for the `[true]` material so that it doesnt render by default.
---@param visible boolean
---@return self
function Material:setVisible(visible)
  self.visible = visible
  forceUpdate()
  return self
end

---Sets the `layer_1` texture for this material.
---@param texture KattArmor.Material.Texture
---@return self
function Material:setTexture(texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  self.texture[1] = texture
  forceUpdate()
  return self
end

---Sets the `layer_2` texture for this material.
---@param texture KattArmor.Material.Texture
---@return self
function Material:setTextureLayer2(texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  self.texture[2] = texture
  forceUpdate()
  return self
end

---Sets the `layer_1` emissive texture for this material.
---@param texture KattArmor.Material.Texture
---@return self
function Material:setEmissiveTexture(texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  self.texture_e[1] = texture
  forceUpdate()
  return self
end

---Sets the `layer_2` emissive texture for this material.
---@param texture KattArmor.Material.Texture
---@return self
function Material:setEmissiveTextureLayer2(texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  self.texture_e[2] = texture
  forceUpdate()
  return self
end

---Sets if the armor should forcefully have glint (true), forcefully not have glint (false), or if glint is determined by the item (nil).
---Default `nil`
---@param glint boolean|nil
---@return self
function Material:setForceGlint(glint)
  self.forceGlint = glint
  forceUpdate()
  return self
end

---Sets if the armor should obey the `display.color` nbt tag.
---Default `true`
---@param bool boolean
---@return self
function Material:setShouldUseColor(bool)
  self.shouldUseColor = bool
  forceUpdate()
  return self
end

---Sets the default color of this material, which will be overriden by the `display.color` nbt tag on the ItemStack, if found.
---This is purly here just for leather armor compatibility.
---@param color integer
---@return self
function Material:setDefaultColor(color)
  self.defaultColor = color
  forceUpdate()
  return self
end

---Sets if the Material Parts that only exist for this material should obey the color set by the item.
---This is purly here just for leather armor compatibility, and Jimmy.
---@param bool boolean
---@return self
function Material:setMaterialPartsColorChange(bool)
  self.materialPartsColor = bool
  forceUpdate()
  return self
end

---Sets if this Material should flash red when the player takes damage.
---Default `false`.
---@param bool boolean
---@return self
function Material:setDamageOverlay(bool)
  self.damageOverlay = bool
  forceUpdate()
  return self
end

---@class KattArmor.TrimPattern
---@field textures table<KattArmor.ArmorPart.Layer, Texture|nil>
---@field textures_e table<KattArmor.ArmorPart.Layer, Texture|nil>
---
---@field new fun():KattArmor.TrimPattern
local TrimPattern = Class()
function TrimPattern:init()
  self.textures = {}
  self.textures_e = {}
end

---Sets the texture used for this trim.
---This texture will blend it's color with the ArmorTrimMaterial's color value.
---A nil value will make the trim use vanilla's textures.
---If you want to use vanilla's color pallates, do that yourself and assign the texture to each trim/material combo yourself.
---@param texture Texture?
---@return self
function TrimPattern:setTexture(texture)
  self.textures[1] = texture
  forceUpdate()
  return self
end

---Sets the texture used for this trim. This is the layer2 texture, meaning the leggings.
---This texture will blend it's color with the ArmorTrimMaterial's color value.
---A nil value will make the trim use vanilla's textures.
---If you want to use vanilla's color pallates, do that yourself and assign the texture to each trim/material combo yourself.
---@param texture Texture?
---@return self
function TrimPattern:setTextureLayer2(texture)
  self.textures[2] = texture
  forceUpdate()
  return self
end

---Sets the texture used for this trim.
---This texture will blend it's color with the ArmorTrimMaterial's color value.
---A nil value will make the trim use vanilla's textures.
---If you want to use vanilla's color pallates, do that yourself and assign the texture to each trim/material combo yourself.
---@param texture Texture?
---@return self
function TrimPattern:setTextureEmissive(texture)
  self.textures_e[1] = texture
  forceUpdate()
  return self
end

---Sets the texture used for this trim. This is the layer2 texture, meaning the leggings.
---This texture will blend it's color with the ArmorTrimMaterial's color value.
---A nil value will make the trim use vanilla's textures.
---If you want to use vanilla's color pallates, do that yourself and assign the texture to each trim/material combo yourself.
---@param texture Texture?
---@return self
function TrimPattern:setTextureEmissiveLayer2(texture)
  self.textures_e[2] = texture
  forceUpdate()
  return self
end

---@class KattArmor.TrimMaterial
---@field color Vector3
---@field textures table<KattArmor.TrimPatternID, table<KattArmor.ArmorPart.Layer|3|4, Texture|nil>>
---@field textures_e table<KattArmor.TrimPatternID, table<KattArmor.ArmorPart.Layer, Texture|nil>>
---
---@field new fun():KattArmor.TrimMaterial
local TrimMaterial = Class()
function TrimMaterial:init()
  self.color = vec(1, 1, 1)
  self.textures = {}
  self.textures_e = {}
end

---Sets the color to augment the trim texture by when no explicit trim material texture is defined.
---@param color Vector3?
---@return self
function TrimMaterial:setColor(color)
  self.color:set(color or vec(1, 1, 1))
  forceUpdate()
  return self
end

---Sets the texture that will be used when this material is used with the given trim.
---This texture will not be modified by KattArmor at all.
---Set to nil to use the trim's actual texture with a color change.
---@param trim KattArmor.TrimPatternID
---@param texture Texture
---@return self
function TrimMaterial:setTexture(trim, texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  if not self.textures[trim] then self.textures[trim] = {} end
  self.textures[trim][1] = texture
  forceUpdate()
  return self
end

---Sets the texture that will be used when this material is used with the given trim.
---This texture will not be modified by KattArmor at all.
---Set to nil to use the trim's actual texture with a color change.
---@param trim KattArmor.TrimPatternID
---@param texture Texture
---@return self
function TrimMaterial:setTextureLayer2(trim, texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  if not self.textures[trim] then self.textures[trim] = {} end
  self.textures[trim][2] = texture
  forceUpdate()
  return self
end

---Sets the texture that will be used when the trimMaterialID matches the armorMaterialID
---Only used when there is a custom texture applied via `TrimMaterial:setTexture`
---@param trim KattArmor.TrimPatternID
---@param texture Texture
---@return self
function TrimMaterial:setTextureDarker(trim, texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  if not self.textures[trim] then self.textures[trim] = {} end
  self.textures[trim][1 + 2] = texture
  forceUpdate()
  return self
end

---Sets the texture that will be used when the trimMaterialID matches the armorMaterialID
---Only used when there is a custom texture applied via `TrimMaterial:setTextureLayer2`
---@param texture Texture
---@return self
function TrimMaterial:setTextureDarkerLayer2(trim, texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  if not self.textures[trim] then self.textures[trim] = {} end
  self.textures[trim][2 + 2] = texture
  forceUpdate()
  return self
end

---Sets the emissive texture that will be used when this material is used with the given trim.
---This texture will not be modified by KattArmor at all.
---Set to nil to use the trim's actual texture with a color change.
---@param trim KattArmor.TrimPatternID
---@param texture Texture
---@return self
function TrimMaterial:setTextureEmissive(trim, texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  if not self.textures_e[trim] then self.textures_e[trim] = {} end
  self.textures_e[trim][1] = texture
  forceUpdate()
  return self
end

---Sets the emissive texture that will be used when this material is used with the given trim.
---This texture will not be modified by KattArmor at all.
---Set to nil to use the trim's actual texture with a color change.
---@param trim KattArmor.TrimPatternID
---@param texture Texture
---@return self
function TrimMaterial:setTextureEmissiveLayer2(trim, texture)
  if texture == nil then
    error(
      "Expected a ResourceID, a Texture, or false. Recieved nil. Make sure the texture path is correct.",
      2)
  end
  if not self.textures_e[trim] then self.textures_e[trim] = {} end
  self.textures_e[trim][2] = texture
  forceUpdate()
  return self
end

---@class KattArmor.Instance
---@field Armor table<KattArmor.ArmorPartID, KattArmor.ArmorPart> # Table that stores all of the ArmorPart objects that can be edited.
---@field Materials table<KattArmor.MaterialID, KattArmor.Material> # Table that stores all of the Materials.<br>Indexing this will create a new Material object that can be modified.
---@field TrimPatterns table<KattArmor.TrimPatternID, KattArmor.TrimPattern> # Table that stores all of the TrimPatterns.<br>Indexing this will create a new TrimPattern object that can be modified.
---@field TrimMaterials table<KattArmor.TrimMaterialID, KattArmor.TrimMaterial> # Table that stores all of the TrimMaterials.<br> Indexing this will create a new TrimMaterial object that can be edited.<br>All vanilla materials have been added to the table, allowing it to be iterated over.
---@field ArmorPart_SlotID_Map table<KattArmor.ArmorPartID, KattArmor.ArmorPartSlot> # A table that maps ArmorParts to Equipment Slots.
---@field SlotID_ArmorPart_Map table<KattArmor.ArmorPartSlot, KattArmor.ArmorPartID> # A table that maps Equipment Slots to ArmorParts.
---@field registerOnChange fun(fn:KattArmor.onChangeCallback) # Registers a function that will be executed when the equipped item has changed, but before KattArmor has determined the Material.<br>The registered function can return a string to override the Material, or nil to allow KattArmor to determine the Material.
---@field registerOnRender fun(fn:KattArmor.onRenderCallback) # Registers a function that will be executed after KattArmor has finished updating all of the Armor and Trim cubes.<br>Every single variable that KattArmor uses to render stuff is accessible as a paramater somewhere.
---@field forceUpdate fun()
---@field private _renderCallbacks KattArmor.onRenderCallback[]

local prevItems = {}
local armorTexturePath = "%s:textures/models/armor/%s_layer_%s.png"
local armorTexturePath1_21_3 = "%s:textures/entity/equipment/%s/%s.png"
local armorTrimSpritePath = "%s:trims/models/armor/%s_%s"
local armorTrimSpritePath1_21_3 = "%s:trims/entity/%s/%s_%s"
local armorTrimAtlasPath = "minecraft:textures/atlas/armor_trims.png"
function events.TICK()
  for slot = 6, 3, -1 do
    local item = player:getItem(slot):copy()
    if not (update or item ~= prevItems[slot]) then goto CONTINUE end

    local partID = SlotID_ArmorPart_Map[slot]

    local materialID
    for _, fn in ipairs(changeCallbacks) do
      materialID = fn(partID, item)
      if materialID then break end
    end

    materialID = materialID
        or item.id:match(("^.*:(.*)_%s"):format(partID:lower()))
        or true

    for _, instance in ipairs(instances) do
      local partData = instance.Armor[partID]

      if partData.prevMaterial and partData.prevMaterial.parts[partID] then
        for _, modelPart in ipairs(partData.prevMaterial.parts[partID]) do
          modelPart:setVisible(false)
        end
      end

      local localMaterialID = partData.override or materialID
      local materialData = instance.Materials[localMaterialID]

      local visible = materialData.visible or false

      local texture = materialData.texture[partData.layer]
      local textureType
      if type(texture) == "Texture" then
        textureType = "CUSTOM"
      elseif type(texture) == "string" then
        textureType = "RESOURCE"
      end

      local texture_e = materialData.texture_e[partData.layer]
      local textureType_e
      if type(texture_e) == "Texture" then
        textureType_e = "CUSTOM"
      elseif type(texture_e) == "string" then
        textureType_e = "RESOURCE"
      end

      local color = vectors.intToRGB(
        materialData.shouldUseColor and item.tag and item.tag.display and item.tag.display.color or
        materialData.defaultColor or 0xFFFFFF
      )
      local renderType
      if materialData.forceGlint ~= nil then
        renderType = materialData.forceGlint and "GLINT" or "EMISSIVE"
      else
        renderType = item:hasGlint() and "GLINT" or "EMISSIVE"
      end

      local damageOverlay = (not materialData.damageOverlay) and 0 or nil

      for _, modelPart in ipairs(partData.parts) do
        modelPart
            :setVisible(visible)
            :setPrimaryTexture(textureType, texture)
            :setSecondaryTexture(textureType_e, texture_e)
            :setColor(color)
            :setSecondaryRenderType(renderType)
            :setOverlay(damageOverlay, 15)
      end

      if materialData.parts[partID] then
        local materialPartsColor = materialData.materialPartsColor and color or 0xFFFFFF
        for _, modelPart in ipairs(materialData.parts[partID]) do
          modelPart
              :setVisible(true)
              :setSecondaryRenderType(renderType)
              :setColor(materialPartsColor)
              :setOverlay(damageOverlay, 15)
        end
      end

      ---@type string, KattArmor.TrimPatternID, KattArmor.TrimMaterialID
      local trimNamespace, trimPattern, trimMaterial
      if partData.overrideTrimPattern and partData.overrideTrimMaterial then
        trimNamespace, trimPattern, trimMaterial =
            partData.overrideTrimNamespace or "minecraft", partData.overrideTrimPattern,
            partData.overrideTrimMaterial
      elseif item.tag and item.tag.Trim and item.tag.Trim.pattern and item.tag.Trim.material then
        if(item.tag.Trim.pattern:find(':', nil, true)) then
          trimNamespace, trimPattern = item.tag.Trim.pattern:match("^(.+):(.+)$")
        else
          trimNamespace, trimPattern = 'minecraft', item.tag.Trim.pattern
        end
        if(item.tag.Trim.pattern:find(':', nil, true)) then
          trimMaterial = item.tag.Trim.material:match("^.+:(.+)$")
        else
          trimMaterial =item.tag.Trim.material
        end
      end

      local trim = (trimPattern and trimMaterial) and true or false
      local trimTexture, trimTextureType, trimColor
      local trimTexture_e
      local trimUV = matrices.mat3()
      if trim then
        local trimPatternData, trimMaterialData =
            instance.TrimPatterns[trimPattern], instance.TrimMaterials[trimMaterial]
        local overrideTrimTexture = trimMaterialData.textures[trimPattern]
        local overrideTrimTexture_e = trimMaterialData.textures_e[trimPattern]
        if overrideTrimTexture and overrideTrimTexture[partData.layer] then
          trimTextureType = "CUSTOM"
          if localMaterialID == trimMaterial and overrideTrimTexture[partData.layer + 2] then
            trimTexture = overrideTrimTexture[partData.layer + 2]
            trimTexture_e = overrideTrimTexture_e[partData.layer + 2]
          else
            trimTexture = overrideTrimTexture[partData.layer]
            trimTexture_e = overrideTrimTexture_e[partData.layer]
          end
        elseif trimPatternData.textures[partData.layer] then
          trimTextureType = "CUSTOM"
          trimTexture = trimPatternData.textures[partData.layer]
          trimTexture_e = trimPatternData.textures_e[partData.layer]
          trimColor = trimMaterialData.color
          if localMaterialID == trimMaterial and trimColor then
            trimColor = trimColor * 0.6
          end
        elseif client.getAtlas(armorTrimAtlasPath) then
          trimTextureType = "RESOURCE"
          trimTexture = armorTrimAtlasPath
          local atlas = client.getAtlas(armorTrimAtlasPath)
          local atlasDimensions = vec(atlas:getWidth(), atlas:getHeight())
          local atlasPattern, atlasMaterial = trimPattern, trimMaterial
          if partData.layer == 2 then atlasPattern = atlasPattern .. "_leggings" end
          if localMaterialID == atlasMaterial then
            atlasMaterial = atlasMaterial .. "_darker"
          elseif localMaterialID == "golden" and atlasMaterial == "gold" then
            atlasMaterial = atlasMaterial .. "_darker"
          end
          local missingnoSpriteData = atlas:getSpriteUV('missingno')
          local spriteData = atlas:getSpriteUV(armorTrimSpritePath:format(trimNamespace, atlasPattern, atlasMaterial))
          if spriteData==missingnoSpriteData then
            spriteData = atlas:getSpriteUV(armorTrimSpritePath1_21_3:format(trimNamespace, partData.layer==2 and "humanoid_leggings" or "humanoid", trimPattern, atlasMaterial))
          end
          trimUV = matrices.mat3()
                :scale((spriteData.zw_ - spriteData.xy_):add(0, 0, 1))
                :translate(spriteData.xy)
        end
      end
      for _, modelPart in ipairs(partData.trimParts) do
        modelPart
            :setVisible(trim and visible)
            :setPrimaryTexture(trimTextureType, trimTexture)
            :setSecondaryTexture(trimTexture_e and trimTextureType or nil, trimTexture_e)
            :setSecondaryRenderType(renderType)
            :setOverlay(damageOverlay, 15)
            :setUVMatrix(trimUV)
            :setColor(trimColor)
      end

      for _, fn in ipairs(instance._renderCallbacks) do
        fn(localMaterialID, partID, item, visible, renderType, color,
          texture, textureType, texture_e, textureType_e, damageOverlay,
          trim, trimPattern, trimMaterial, trimTexture, trimTextureType, trimColor, trimUV)
      end

      partData.prevMaterial = materialData
    end

    prevItems[slot] = item
    ::CONTINUE::
  end
  update = false
end

local armorMetatable = {
  __pairs = function(self)
    local i = 6
    return function(t, k)
      local id = SlotID_ArmorPart_Map[i]
      i = i - 1
      return id, t[id]
    end, self
  end,
}
local materialsMetatable = {
  __index = function(self, index)
    local newMaterial = Material:new()
    if type(index) == "string" and index:match("^[a-z0-9%/%-%_%.]+$") then
      local t = armorTexturePath:format("minecraft", index, "1")
      local t1_21_3 = armorTexturePath1_21_3:format("minecraft", "humanoid", index)
      if client.hasResource(t) then
        newMaterial:setTexture(t)
        local t2 = armorTexturePath:format("minecraft", index, "2")
        if client.hasResource(t2) then
          newMaterial:setTextureLayer2(t2)
        end
        local t_e = armorTexturePath:format("minecraft", index, "1_e")
        if client.hasResource(t_e) then
          newMaterial:setEmissiveTexture(t_e)
          local t2_e = armorTexturePath:format("minecraft", index, "2_e")
          if client.hasResource(t2_e) then
            newMaterial:setEmissiveTextureLayer2(t2_e)
          end
        end
      elseif client.hasResource(t1_21_3) then
        newMaterial:setTexture(t1_21_3)
        local t1_21_3_2 = armorTexturePath1_21_3:format("minecraft", "humanoid_leggings", index)
        if client.hasResource(t1_21_3_2) then
          newMaterial:setTextureLayer2(t1_21_3_2)
        end
      end
    end
    rawset(self, index, newMaterial)
    return newMaterial
  end,
}
local trimPatternsMetatable = {
  __index = function(self, index)
    local newTrim = TrimPattern:new()
    rawset(self, index, newTrim)
    return newTrim
  end,
}
local trimMaterialsMetatable = {
  __index = function(self, index)
    local newMat = TrimMaterial:new()
    rawset(self, index, newMat)
    return newMat
  end,
}
return function()
  ---@type table<KattArmor.ArmorPartID, KattArmor.ArmorPart>
  local armor = setmetatable({
    Helmet = ArmorPart:new("Helmet"),
    Chestplate = ArmorPart:new("Chestplate"),
    Leggings = ArmorPart:new("Leggings"):setLayer(2),
    Boots = ArmorPart:new("Boots"),
  }, armorMetatable)

  ---@type table<KattArmor.MaterialID, KattArmor.Material>
  local materials = setmetatable({}, materialsMetatable)
  materials[true]:setVisible(false):setDamageOverlay(true)
  materials.leather:setDefaultColor(0xA06540)
  rawset(materials, "golden", materials.gold)

  ---@type table<KattArmor.TrimPatternID, KattArmor.TrimPattern>
  local trimPatterns = setmetatable({}, trimPatternsMetatable)

  ---@type table<KattArmor.TrimMaterialID, KattArmor.TrimMaterial>
  local trimMaterials = setmetatable({}, trimMaterialsMetatable)
  trimMaterials.amethyst:setColor(vectors.intToRGB(0x9a5cc6))
  trimMaterials.copper:setColor(vectors.intToRGB(0xb4684d))
  trimMaterials.diamond:setColor(vectors.intToRGB(0x6eecd2))
  trimMaterials.emerald:setColor(vectors.intToRGB(0x0ec754))
  trimMaterials.gold:setColor(vectors.intToRGB(0xecd93f))
  trimMaterials.iron:setColor(vectors.intToRGB(0xbfc9c8))
  trimMaterials.lapis:setColor(vectors.intToRGB(0x1c4d9c))
  trimMaterials.netherite:setColor(vectors.intToRGB(0x443a3b))
  trimMaterials.quartz:setColor(vectors.intToRGB(0xf6eadf))
  trimMaterials.redstone:setColor(vectors.intToRGB(0xbd2008))

  ---@type KattArmor.Instance
  local instance = {
    Armor = armor,
    Materials = materials,
    TrimPatterns = trimPatterns,
    TrimMaterials = trimMaterials,
    ArmorPart_SlotID_Map = ArmorPart_SlotID_Map,
    SlotID_ArmorPart_Map = SlotID_ArmorPart_Map,
    registerOnChange = registerOnChange,
    registerOnRender = nil,
    forceUpdate = forceUpdate,
    _renderCallbacks = {},
  }
  ---@param fn KattArmor.onRenderCallback
  function instance.registerOnRender(fn)
    table.insert(instance._renderCallbacks, fn)
    forceUpdate()
  end

  table.insert(instances, instance)
  return instance
end
