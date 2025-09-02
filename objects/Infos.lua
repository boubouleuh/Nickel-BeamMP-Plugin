Infos = {}
Infos.tableName = "Infos"

function Infos.new(infoKey, infoValue)
  local self = {}
  self.infoID = nil
  self.infoKey = infoKey
  self.infoValue = infoValue
  return self
end

function Infos.getColumns()
    return {
      "infoID INTEGER PRIMARY KEY AUTOINCREMENT",
      "infoKey TEXT UNIQUE NOT NULL",
      "infoValue TEXT UNIQUE NOT NULL",
    }
end