author = 'Bouboule'
description = 'example extension'
version = '1.0.0'
enabled = true
server_scripts = {
    "/extensions/example_extension/main/money.lua",
    "/extensions/example_extension/main/test.lua",
    "/extensions/example_extension/commands/*",
}
-- The scripts are loaded in order, so money.lua is loaded before test.lua