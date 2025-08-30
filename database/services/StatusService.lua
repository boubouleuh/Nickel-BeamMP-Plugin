
local new = require("objects.New")

local userStatus = require("objects.UserStatus")
local sessionServerStorage = require("main.sessionServerStorage")
local interfaceUtils = require("main.client.interfaceUtils")
local utils = require("utils.misc")
---@class StatusService
local Service = {}



function Service.new(beammpid, dbManager)
    local self = {}
    self.dbManager = dbManager  -- You can set this to a specific value if needed
    self.beammpid = beammpid
    local playersDB = sessionServerStorage.get("Players") or {}
    self.userDB = playersDB[beammpid] or nil
    return new._object(Service, self)
end
  

function Service:getAllStatus()
    if self.userDB and type(self.userDB) == "table" and type(self.userDB.statuses) == "table" then
        return self.userDB.statuses
    end
    local status = self.dbManager:withConnection(function()
        return self.dbManager:getAllClassByBeammpId(userStatus, self.beammpid)
    end)
    for _, value in ipairs(status) do
        value.tableName = userStatus.tableName
    end
    return status
end


function Service:getStatus(status_type)
    local status = self:getAllStatus()
    local result = {}
    for _, value in ipairs(status) do
        if value.status_type ~= nil and value.status_type == status_type then
            table.insert(result, value)
        end
    end
    return result
end

function Service:checkStatus(status_type)
    if status_type == nil then return false end
    self:cleanupExpiredTemporary()
    local status = self:getAllStatus()
    for _, value in ipairs(status) do
        if value.status_type ~= nil and value.status_type == status_type and utils.isTruthy(value.is_status_value) then
            return true
        end
    end
    return false
end

function Service:disableStatus(status_type)
    local status = self:getStatus(status_type)
    if not status or #status == 0 then
        return "nickel.nochange"
    end
    local changed = false
    for _, value in ipairs(status) do
        if utils.isTruthy(value.is_status_value) then
            value.is_status_value = 0
            self.dbManager:save(value, true)
            changed = true
        end
    end
    if changed then
        interfaceUtils.sendNothingToAll("NKResetPlayerList")
        return 0
    else
        return "nickel.nochange"
    end
end
function Service:removeStatus(status_type)
    local deleted = self.dbManager:withConnection(function()
        local conditions = {
            {"status_type", status_type},
            {"beammpid", self.beammpid}
        }
        return self.dbManager:deleteObject(userStatus, conditions)
    end)
    interfaceUtils.sendNothingToAll("NKResetPlayerList")
    return deleted or "nickel.nochange"
end

function Service:createStatus(status_type, reason, time)
    local expiry = time
    if expiry == nil then
        expiry = os.time()
    end
    if type(expiry) == "number" and expiry < 100000000000 then
        if self.dbManager.config and self.dbManager.config.database_type == "mysql" then
            expiry = os.date("%Y-%m-%d %H:%M:%S", expiry)
        end
    end
    local userStatusClass = userStatus.new(self.beammpid, status_type, true, reason, expiry)

    local result = self.dbManager:save(userStatusClass, false)
    interfaceUtils.sendNothingToAll("NKResetPlayerList")
    return result
end

function Service:isExpired(status_type)
    if status_type == nil then return false end
    local status = self:getAllStatus()
    local now = os.time()
    for _, value in ipairs(status) do
        if value.status_type ~= nil and value.status_type == status_type and utils.isTruthy(value.is_status_value) then
            local expiry = value.expiry_time
            if type(expiry) == "string" then
                local y,M,d,h,m,s = expiry:match("^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d):(%d%d)")
                if y then
                    expiry = os.time{year=tonumber(y),month=tonumber(M),day=tonumber(d),hour=tonumber(h),min=tonumber(m),sec=tonumber(s)}
                end
            end
            if tonumber(expiry) and tonumber(expiry) < now then
                return true
            end
        end
    end
    return false
end

local function isTemporaryType(stype)
    return type(stype) == "string" and stype:find("temp") ~= nil
end

function Service:cleanupExpiredTemporary()
    local statusList = self:getAllStatus()
    local now = os.time()
    local toDisable = {}
    for _, value in ipairs(statusList) do
        if value.status_type and utils.isTruthy(value.is_status_value) and isTemporaryType(value.status_type) then
            local expiry = value.expiry_time
            if type(expiry) == "string" then
                local y,M,d,h,m,s = expiry:match("^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d):(%d%d)")
                if y then
                    expiry = os.time{year=tonumber(y),month=tonumber(M),day=tonumber(d),hour=tonumber(h),min=tonumber(m),sec=tonumber(s)}
                end
            end
            if tonumber(expiry) and tonumber(expiry) < now then
                table.insert(toDisable, value)
            end
        end
    end
    if #toDisable > 0 then
        for _, statusObj in ipairs(toDisable) do
            statusObj.is_status_value = 0
            self.dbManager:save(statusObj, true)
        end
        interfaceUtils.sendNothingToAll("NKResetPlayerList")
    end
end


return Service