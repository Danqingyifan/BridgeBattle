local MainStorage = require("MainStorage")
local LevelTables = require(MainStorage.Player.AttributeSystem.LevelTables)
local Attributes = require(MainStorage.Player.AttributeSystem.Attributes)

local AttributeSystem = {}

AttributeSystem._state = {}

-- 简化：代理等级表注入
function AttributeSystem.setLevelTables(tables)
  LevelTables.setLevelTables(tables)
end

function AttributeSystem.setLevelTable(key, levelTable)
  LevelTables.setLevelTable(key, levelTable)
end

-- 辅助：在指定等级获取属性值（0 级为 baseValue）
local function getValueFor(definition, level)
  if level <= 0 then return definition.baseValue end
  local entry = LevelTables.getLevelEntry(definition.tableKey, level)
  return entry and entry.value or definition.baseValue
end

-- 查询某一等级信息
local function getUpgradeInfo(tableKey, Level)
  local entry = LevelTables.getLevelEntry(tableKey, Level)
  if not entry then return nil end
  return { level = Level, value = entry.value, cost = entry.cost }
end


-- 属性注册（代理）
function AttributeSystem.registerAttribute(key, definition)
  return Attributes.registerAttribute(key, definition)
end

-- 初始化/加载玩家
function AttributeSystem.initPlayer(playerId, options)
  assert(playerId ~= nil, "必须提供 playerId")
  if AttributeSystem._state[playerId] ~= nil then return AttributeSystem._state[playerId] end

  local state = {
    currency = (options and options.currency) or 0,
    attributes = {},
  }

  for key, definition in pairs(Attributes.getDefs()) do
    local maxLv = LevelTables.getMaxLevel(definition.tableKey)
    local initialLevel = (options and options.levels and options.levels[key]) or definition.level or 0
    if maxLv > 0 and initialLevel > maxLv then initialLevel = maxLv end
    local value = getValueFor(definition, initialLevel)
    state.attributes[key] = { level = initialLevel, value = value }
    if definition.apply then
      pcall(definition.apply, playerId, value)
    end
  end

  AttributeSystem._state[playerId] = state
  return state
end

-- 序列化
function AttributeSystem:serializeState(playerId)
  local state = AttributeSystem._state[playerId]
  assert(state, "玩家未初始化")
  local saved = { currency = state.currency, levels = {} }
  for key, attr in pairs(state.attributes) do
    saved.levels[key] = attr.level
  end
  return saved
end
-- 从保存数据恢复
function AttributeSystem.loadPlayer(playerId, saved)
  return AttributeSystem.initPlayer(playerId, saved)
end

-- 货币接口
function AttributeSystem:getCurrency(playerId)
  local state = AttributeSystem._state[playerId]
  return state and state.currency or 0
end
-- 设置货币接口
function AttributeSystem:setCurrency(playerId, amount)
  assert(type(amount) == "number", "金额必须是数字")
  local state = AttributeSystem._state[playerId]
  assert(state, "玩家未初始化")
  state.currency = amount
  return state.currency
end
-- 增加货币接口
function AttributeSystem:addCurrency(playerId, amount)
  assert(type(amount) == "number", "金额必须是数字")
  local state = AttributeSystem._state[playerId]
  assert(state, "玩家未初始化")
  state.currency = state.currency + amount
  return state.currency
end
-- 查询等级接口
function AttributeSystem:getAttributeLevel(playerId, key)
  local state = AttributeSystem._state[playerId]
  assert(state, "玩家未初始化")
  local attr = state.attributes[key]
  assert(attr, "未找到属性: " .. tostring(key))
  return attr.level
end
-- 查询属性值接口
function AttributeSystem:getAttributeValue(playerId, key)
  local state = AttributeSystem._state[playerId]
  assert(state, "玩家未初始化")
  local attr = state.attributes[key]
  assert(attr, "未找到属性: " .. tostring(key))
  return attr.value
end
-- 查询最大等级接口
function AttributeSystem:getMaxLevelFor(playerId, key)
  local definition = Attributes.getDefs()[key]
  assert(definition, "未找到属性定义: " .. tostring(key))
  return LevelTables.getMaxLevel(definition.tableKey)
end

-- 查询某一等级信息
function AttributeSystem:getLevelInfo(playerId, key,Level)
  local definition = Attributes.getDefs()[key]
  assert(definition, "未找到属性定义: " .. tostring(key))
  local state = AttributeSystem._state[playerId]
  assert(state, "玩家未初始化")
  local attr = state.attributes[key]
  assert(attr, "未找到属性: " .. tostring(key))
  return getUpgradeInfo(definition.tableKey, Level)
end
-- 查询升级花费接口
function AttributeSystem:getUpgradeCost(playerId, key,Level)
  local info = AttributeSystem.getLevelInfo(playerId, key,Level)
  return info and info.cost or nil
end

-- 查询升到某一等级花费
function AttributeSystem.getUpgradeCostToLevel(playerId, key, targetLevel)
  local definition = Attributes.getDefs()[key]
  assert(definition, "未找到属性定义: " .. tostring(key))
  local state = AttributeSystem._state[playerId]
  assert(state, "玩家未初始化")
  local attr = state.attributes[key]
  assert(attr, "未找到属性: " .. tostring(key))
  assert(type(targetLevel) == "number" and targetLevel >= 0, "目标等级必须为非负数")

  local maxLv = LevelTables.getMaxLevel(definition.tableKey)
  if maxLv > 0 and targetLevel > maxLv then targetLevel = maxLv end
  if targetLevel <= attr.level then return 0 end

  local info = getUpgradeInfo(definition.tableKey, targetLevel)
  return info and info.cost or 0
end

-- 查询是否可以升到某一等级
function AttributeSystem.canUpgradeToLevel(playerId, key, targetLevel)
  local cost = AttributeSystem.getUpgradeCostToLevel(playerId, key, targetLevel)
  local state = AttributeSystem._state[playerId]
  if cost == 0 then
    local definition = Attributes.getDefs()[key]
    local attr = state.attributes[key]
    local maxLv = LevelTables.getMaxLevel(definition.tableKey)
    if targetLevel <= attr.level or maxLv == attr.level then
      return false, "无需升级或已达最大等级"
    end
  end
  if state.currency < cost then return false, "货币不足" end
  return true
end

-- 升级方法
function AttributeSystem.upgradeToLevel(playerId, key, targetLevel)
  local definition = Attributes.getDefs()[key]
  assert(definition, "未找到属性定义: " .. tostring(key))
  local state = AttributeSystem._state[playerId]
  assert(state, "玩家未初始化")
  local attr = state.attributes[key]
  assert(attr, "未找到属性: " .. tostring(key))
  assert(type(targetLevel) == "number" and targetLevel >= 0, "目标等级必须为非负数")

  local maxLv = LevelTables.getMaxLevel(definition.tableKey)
  if maxLv > 0 and targetLevel > maxLv then targetLevel = maxLv end
  if targetLevel <= attr.level then return false, "目标等级不高于当前等级" end

  local cum = getUpgradeInfo(definition.tableKey, targetLevel)
  if not cum then return false, "无可升级的等级" end
  if state.currency < cum.cost then return false, "货币不足" end

  state.currency = state.currency - cum.cost
  attr.level = cum.level
  attr.value = cum.value
  if definition.apply then
    pcall(definition.apply, playerId, attr.value)
  end
  return true, attr.level, attr.value, state.currency
end
-- 升级接口
function AttributeSystem.upgradeBy(playerId, key, Level)
  assert(type(Level) == "number", "Level 必须是数字")
  if Level <= 0 then return false, "目标等级无效" end
  --local current = AttributeSystem.getAttributeLevel(playerId, key)
  return AttributeSystem.upgradeToLevel(playerId, key,Level)
end

return AttributeSystem
