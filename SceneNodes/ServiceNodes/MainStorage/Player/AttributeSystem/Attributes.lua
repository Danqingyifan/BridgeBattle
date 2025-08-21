local Attributes = {}

local DEFAULT_ATTRIBUTES = {
  movementSpeed = {
    displayName = "移动速度",
    baseValue = 4.0,
    level = 0,
    tableKey = "speed",
    apply = function(playerId, value)
      -- TODO: 接入引擎 API 设置玩家移动速度
    end,
  },
  maxCarryBlocks = {
    displayName = "可携带方块最大数",
    baseValue = 20,
    level = 0,
    tableKey = "item",
    apply = function(playerId, value)
      -- TODO: 接入引擎 API 设置背包容量/携带方块上限
    end,
  },
  shoelaceMaxCount = {
    displayName = "携带物品最大数",
    baseValue = 1,
    level = 0,
    tableKey = "item",
    apply = function(playerId, value)
      -- TODO: 接入引擎 API 设置对应效果
    end,
  },
}

Attributes._defs = DEFAULT_ATTRIBUTES

function Attributes.getDefs()
  return Attributes._defs
end

function Attributes.registerAttribute(key, definition)
  assert(type(key) == "string" and key ~= "", "属性键必须是非空字符串")
  assert(type(definition) == "table", "属性定义必须是表")
  assert(definition.baseValue ~= nil, "缺少 baseValue")
  assert(type(definition.tableKey) == "string" and definition.tableKey ~= "", "缺少 tableKey")
  Attributes._defs[key] = definition
  return true
end

return Attributes
