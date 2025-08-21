local LevelTables = {}

LevelTables._tables = {
  speed = {
    { level = 1, value = 1, cost = 100 },
    { level = 2, value = 2, cost = 200 },
    { level = 3, value = 3, cost = 300 },
    { level = 4, value = 4, cost = 400 },
    { level = 5, value = 5, cost = 500 },
  },
  item = {
    { level = 1, value = 1, cost = 100 },
    { level = 2, value = 2, cost = 200 },
    { level = 3, value = 3, cost = 300 },
    { level = 4, value = 4, cost = 400 },
    { level = 5, value = 5, cost = 500 },
  },
}

function LevelTables.setLevelTable(key, levelTable)
  assert(type(key) == "string" and key ~= "", "key 必须是非空字符串")
  assert(type(levelTable) == "table", "levelTable 必须是表")
  LevelTables._tables[key] = levelTable
end

function LevelTables.setLevelTables(tables)
  assert(type(tables) == "table", "tables 必须是表")
  for k, v in pairs(tables) do
    LevelTables.setLevelTable(k, v)
  end
end

function LevelTables.getTable(key)
  return LevelTables._tables[key]
end

function LevelTables.getLevelEntry(tableKey, level)
  local tbl = LevelTables._tables[tableKey]
  if not tbl or level <= 0 then return nil end
  return tbl[level]
end

function LevelTables.getMaxLevel(tableKey)
  local tbl = LevelTables._tables[tableKey]
  return tbl and #tbl or 0
end

return LevelTables