
---@class Role: ModelInstance, ModelClass
---@field roleID number?
---@field roleName string
---@field permlvl number
---@field is_default boolean
Role = Model{
    __tablename__ = "Roles",
    Fields.Integer("roleID"):PrimaryKey():AutoIncrement(),
    Fields.String("roleName"):MaxLength(191):Unique():NotNull(),
    Fields.Integer("permlvl"):NotNull(),
    Fields.Boolean("is_default"):NotNull()
}
function Role.create(rolename, permlvl, is_default)
  return Role({
    roleName = rolename,
    permlvl = permlvl,
    is_default = is_default
  })
end