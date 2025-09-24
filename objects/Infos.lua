Infos = {}
Infos.tableName = "Infos"

function Infos.new(infoKey, infoValue)
  local self = {}
  self.tableName = Infos.tableName
  self.infoID = nil
  self.infoKey = infoKey
  self.infoValue = infoValue
  return self
end

function Infos.getColumns()
    return {
      "infoID INTEGER PRIMARY KEY AUTOINCREMENT",
      "infoKey VARCHAR(191) UNIQUE NOT NULL",
      "infoValue VARCHAR(191) UNIQUE NOT NULL",
    }
end