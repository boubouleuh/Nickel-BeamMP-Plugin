local action = {
    type="user",
    args = {
        "beammpId"
    }
}

function action.init(sender_id, sender_name, beammpId)
    MessagesManager:SendMessage(sender_id, "Advanced user info for user ID: " .. beammpId)
    return true
end

if RegisterNickelAction then
    RegisterNickelAction("seeAdvancedUserInfos", action)
end

return action