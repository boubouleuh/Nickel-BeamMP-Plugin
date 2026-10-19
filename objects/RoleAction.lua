---@class RoleAction: ModelInstance, ModelClass
---@field roleID number
---@field actionID number
RoleAction = Model{
    __tablename__ = "RoleActions",
    Fields.Integer("roleID"):ForeignKey("Roles", "roleID"):PrimaryKey(),
    Fields.Integer("actionID"):ForeignKey("Actions", "actionID"):PrimaryKey()
}
function RoleAction.create(roleID, actionID)
    return RoleAction({roleID = roleID, actionID = actionID})
end