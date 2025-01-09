
local new = require("objects.New")
local Action = require("objects.Action")

local utils = require("utils.misc")
---@class ActionsHandler
ActionsHandler = {}

--- init actions
---@param managers managers
function ActionsHandler.init(managers)
    local self = {}

    ---@type MessagesHandler
    self.msgManager = managers.msgManager
    ---@type DatabaseManager
    self.dbManager = managers.dbManager
    ---@type Settings
    self.cfgManager = managers.cfgManager
    ---@type PermissionsHandler
    self.permManager = managers.permManager
    self.actions = {}
    local inbuildActions = FS.ListFiles(utils.script_path() .. "main/actions/all")
    local extensionsActions =  FS.ListFiles(utils.script_path() .. "extensions/actions")

    local files = utils.mergeTables(inbuildActions, extensionsActions)


    local function checkActions()  --WATCH THIS IF ACTION ARE NOT HANDLED CORRECTLY
        self.dbManager:openConnection()

        local actionsFromDB = self.dbManager:getAllEntry(Action)

        -- Remove actions not present in memory from the database
        for _, action in pairs(actionsFromDB) do
            if not self.actions[action.actionName] then
                local conditions = {
                    {"actionName", action.actionName},
                }

                self.dbManager:deleteObject(Action, conditions)
            end
        end


        self.dbManager:closeConnection()
    end



    local function addAction(actionName)

        local action = Action.new(actionName)
        self.dbManager:save(action)

        local success, module = pcall(require, "main.actions.all." .. actionName)
            --if it exist then its a inbuilt command
        if success then
            self.actions[actionName] = module
        else
            self.actions[actionName] = require("extensions.actions." .. actionName)
        end --if not then its an extension command
    end


    for _, file in pairs(files) do
        local string = string.gsub(file, ".lua", "")
        addAction(string)
    end

    checkActions()

    return new._object(ActionsHandler, self)
end

function ActionsHandler:GetActions()
    return self.actions
end

return ActionsHandler