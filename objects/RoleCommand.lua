---@class RoleCommand: ModelInstance, ModelClass
---@field roleID number
---@field commandID number
RoleCommand = Model{
    __tablename__ = "RoleCommands",
    Fields.Integer("roleID"):ForeignKey("Roles", "roleID"):PrimaryKey(),
    Fields.Integer("commandID"):ForeignKey("Commands", "commandID"):PrimaryKey()
}
function RoleCommand.create(roleID, commandID)
    return RoleCommand({roleID = roleID, commandID = commandID})
end