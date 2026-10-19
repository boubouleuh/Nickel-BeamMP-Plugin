---@class UserRole: ModelInstance, ModelClass
---@field beammpid number
---@field roleID number
UserRole = Model{
    __tablename__ = "UserRoles",
    Fields.Integer("beammpid"):ForeignKey("Users", "beammpid"):PrimaryKey(),
    Fields.Integer("roleID"):ForeignKey("Roles", "roleID"):PrimaryKey()
}
function UserRole.create(beammpid, roleid)
    return UserRole({beammpid = beammpid, roleID = roleid})
end