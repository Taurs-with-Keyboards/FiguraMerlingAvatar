---v1.1.0
---Author: kitcat962
---Maintainers: manuel_2867

local originsAPI = {}
---@alias OriginPowerData unknown

---Checks if the given player has the given origin.
---@param playr Player The Player to check
---@param origin string The originID to check
---@param originLayer? string Optionally, only return true if the origin is from this layer
---@return boolean
function originsAPI.hasOrigin(playr, origin, originLayer)
  local nbt=playr:getNbt()
  local origins = nbt.cardinal_components and nbt.cardinal_components["origins:origin"] and nbt.cardinal_components["origins:origin"].OriginLayers -- fabric
    or nbt.ForgeCaps and nbt.ForgeCaps["origins:origins"] and nbt.ForgeCaps["origins:origins"].Origins -- forge
    or nbt["neoforge:attachments"] and nbt["neoforge:attachments"]["origins:entity_origin"] and nbt["neoforge:attachments"]["origins:entity_origin"].origins -- neoforge
  if not origins then return false end
  for layer, _origin in pairs(origins) do
    if type(_origin) == "string" then -- forge, neoforge
      if _origin == origin and (layer == originLayer or originLayer == nil) then
        return true
      end
    elseif _origin.Origin == origin and (_origin.Layer == originLayer or originLayer == nil) then -- fabric
      return true
    end
  end
  return false
end

---Gets the power data for all powers of this player.
---Uses a good amount of instructions, so make sure to only call this function once (per tick) and then lookup any information you need from the table it returns.
---@param playr Player The Player to get the power data from
---@param powerSource? string Optionally, only get the power data if the power has this source
---@return table<string,OriginPowerData> Returns a table with the power names as the keys and the power data as the values. Power data format can vary between modloader versions. I recommend using printTable to figure out the format of a certain power.
function originsAPI.getPowerData(playr, powerSource)
  local nbt=playr:getNbt()
  local powers = nbt.cardinal_components and nbt.cardinal_components["apoli:powers"] and nbt.cardinal_components["apoli:powers"].Powers -- fabric
    or nbt.ForgeCaps and nbt.ForgeCaps["apoli:powers"] and nbt.ForgeCaps["apoli:powers"].Powers -- forge
    or nbt["neoforge:attachments"] and nbt["neoforge:attachments"]["origins:entity_origin"] and nbt["neoforge:attachments"]["origins:entity_origin"].powers -- neoforge
  if not powers then return {} end
  local lookup = {}
  if client:getClientBrand() == "neoforge" then
    -- neoforge
    local components = nbt["neoforge:attachments"]["origins:entity_origin"].components
    if components then
      for source, _powers in pairs(powers) do
        if powerSource == nil or powerSource == source then
          for _, power in ipairs(_powers) do
            lookup[power] = components[power]
          end
        end
      end
    end
  else
    -- forge, fabric
    for _, power in ipairs(powers) do
      local allowed = powerSource == nil
      if not allowed then
        for _, source in ipairs(power.Sources) do
          if source == powerSource then
            allowed = true
            break
          end
        end
      end
      if allowed then
        lookup[power.Type] = power.Data
      end
    end
  end
  return lookup
end

return originsAPI
