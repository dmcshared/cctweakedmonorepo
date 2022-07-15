local utils = require("disk/utils/utils")
utils:loadUtil("api")

function main(threads)
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

    threads.spawnChild(function(thrd)
        _G.api = api
        shell.run("lua")
    end, "shell")
end

return function()
    local threadSys = require("disk/utils/threads")
    threadSys(main)
end
