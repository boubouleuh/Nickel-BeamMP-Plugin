---@class Infos: ModelInstance, ModelClass
---@field infoID number?
---@field infoKey string
---@field infoValue string
Infos = Model{
    __tablename__ = "Infos",
    Fields.Integer("infoID"):PrimaryKey():AutoIncrement(),
    Fields.String("infoKey"):MaxLength(191):Unique():NotNull(),
    Fields.String("infoValue"):MaxLength(191):Unique():NotNull()
}
function Infos.create(infoKey, infoValue)
  return Infos({infoKey = infoKey, infoValue = infoValue})
end