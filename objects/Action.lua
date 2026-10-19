---@class Action: ModelInstance, ModelClass
---@field actionID number?
---@field actionName string
Action = Model{
    __tablename__ = "Actions",
    Fields.Integer("actionID"):PrimaryKey():AutoIncrement(),
    Fields.String("actionName"):MaxLength(191):Unique():NotNull()
}
function Action.create(actname)
  return Action({actionName = actname})
end