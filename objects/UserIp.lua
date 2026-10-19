---@class UserIp: ModelInstance, ModelClass
---@field ip_id number?
---@field beammpid number
---@field ip string
---@field is_banned boolean
UserIp = Model{
    __tablename__ = "UserIps",
    Fields.Integer("ip_id"):PrimaryKey():AutoIncrement(),
    Fields.Integer("beammpid"):ForeignKey("Users", "beammpid"),
    Fields.String("ip"):MaxLength(191),
    Fields.Boolean("is_banned"):NotNull():Default(false)
}
function UserIp.create(beammpid, ip)
  return UserIp({
    beammpid = beammpid,
    ip = ip,
    is_banned = false
  })
end