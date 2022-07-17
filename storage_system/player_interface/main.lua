require("disk.setupUtils")

function main(threads)
    term.clear()
    local api = utils.api.findService("dmc_storage_system")
    if api.ping() ~= "pong" then
        print("API broken")
        return
    end

    if not fs.exists("conf") then
        fs.makeDir("conf")
        -- Create file storages.lua with contents `return {\n\n}`
        utils.fsu.write("conf/interface_storage.lua",
            "return " .. textutils.serialize(read(term.write("ID of storage interface: "))))
    end

    -- Load Configs from Files 
    local conf_interface_storage = require("conf/interface_storage")

    local function save_conf()
        utils.fsu.write("conf/interface_storage.lua", "return " .. textutils.serialize(conf_interface_storage))
    end

    local tabd = utils.tabbed.createTabbed(threads)

    tabd:addTab("I", require("disk/player_interface/subprograms/itemList")(api, conf_interface_storage))
    tabd:addTab("C", require("disk/player_interface/subprograms/chestList")(api, conf_interface_storage))
    tabd:addTab("S", function(thrd)
        _ENV.api = api
        shell.run("shell")
    end)

    tabd:init()

end

return function()
    local threadSys = require("disk/utils/threads")
    threadSys(main)
end
