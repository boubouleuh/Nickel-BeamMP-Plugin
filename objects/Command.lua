---@class Command: ModelInstance, ModelClass
---@field commandID number?
---@field commandName string
Command = Model{
    __tablename__ = "Commands",
    Fields.Integer("commandID"):PrimaryKey():AutoIncrement(),
    Fields.String("commandName"):MaxLength(191):Unique():NotNull()
}
function Command.create(cmdname)
  return Command({commandName = cmdname})
end