author = 'Bouboule'
description = 'example extension'
version = '1.0.0'
enabled = true
server_scripts = {
    "main/globals/mouse.lua",
    "main/globals/mouse_scream.lua",
    "main/config.lua",
    "main/money.lua",
    "main/test.lua",
    "commands/*",
}
-- The scripts are loaded in order, so money.lua is loaded before test.lua