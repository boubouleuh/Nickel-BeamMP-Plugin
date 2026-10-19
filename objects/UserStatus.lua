---@class UserStatus: ModelInstance, ModelClass
---@field id number?
---@field beammpid number
---@field status_type string
---@field is_status_value boolean
---@field reason string
---@field expiry_time string|number|nil
UserStatus = Model{
    __tablename__ = "UsersStatus",
    Fields.Integer("id"):PrimaryKey():AutoIncrement(),
    Fields.Integer("beammpid"):ForeignKey("Users", "beammpid"):NotNull(),
    Fields.String("status_type"):MaxLength(191),
    Fields.Boolean("is_status_value"):NotNull():Default(false),
    Fields.String("reason"):MaxLength(191),
    Fields.DateTime("expiry_time")
}
function UserStatus.create(beammpid, status_type, status_value, reason, expiry_time)
  return UserStatus({
    beammpid = beammpid or 0,
    status_type = status_type or "",
    is_status_value = status_value or false,
    reason = reason or "",
    expiry_time = expiry_time
  })
end