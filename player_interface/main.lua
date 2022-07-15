local utils = require("disk/utils/utils")
utils:loadUtil("api")

return function()
    print("Hi. I am the player interface")
    local api = utils.api.findService("dmc_storage_system")
    if api.ping() == "pong" then
        print("API is working")
    else
        print("API is broken")
        return
    end

    local storages = api.getItemStorages()
    print("Found " .. #storages .. " storages")

    api.addStorageConf("ironchests:obsidian_chest_0")

    storages = api.getItemStorages()
    print("Found " .. #storages .. " storages")
end
