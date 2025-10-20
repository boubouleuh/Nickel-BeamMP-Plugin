if not FS.IsDirectory("Resources/Server/Tree-BeamMP-Plugin/") then
    local tree = require("main.tree_init")
    tree.check_tree()
    print("NICKEL :: PLEASE RESTART THE SERVER NOW TO INITIALIZE :: NICKEL")
end
