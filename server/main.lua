local utils = require("disk/utils/utils")
utils:loadUtil("api")
utils:loadUtil("fsu")
utils:loadUtil("table")

function indexStorage(index, container)

end

return function()
    print("Storage Server Init")

    print("Checking for configuration files")

    if not fs.exists("conf") then
        fs.makeDir("conf")
        -- Create file storages.lua with contents `return {\n\n}`
        utils.fsu.write("conf/storages.lua", "return {\n\n}")
    end

    -- Load Configs from Files 
    local conf_storages = require("conf/storages")

    function save_conf()
        utils.fsu.write("conf/storages.lua", "return " .. textutils.serialize(conf_storages))
    end

    print("Scanning Storage Asyncronously...")

    local all_storages = {peripheral.find("inventory")}
    local all_storages_by_name = {}

    local item_storages = {}

    for _, storage in ipairs(all_storages) do
        storage.name = peripheral.getName(storage)
        all_storages_by_name[storage.name] = storage
        print("Found Storage: " .. storage.name)
    end

    for storage, enabled in ipairs(conf_storages) do
        if enabled then
            if all_storages_by_name[storage] then
                table.insert(item_storages, all_storages_by_name[storage])
                print("Enabled Storage: " .. storage)
            else
                print("Storage " .. storage .. " not found")
            end
        else
            print("Skipped Storage: " .. storage .. " disabled")
        end
    end

    local api = utils.api.createServer("dmc_storage_system")

    api:registerEndpoint("ping", function()
        return "pong"
    end)

    api:registerEndpoint("getStorages", function()
        return ({utils.table.entries(all_storages)})[1]
    end)

    api:registerEndpoint("getItemStorages", function()
        return conf_storages
    end)

    api:registerEndpoint("addStorageConf", function(storage)
        conf_storages[storage] = true
        save_conf()

        if all_storages_by_name[storage] then
            table.insert(item_storages, all_storages_by_name[storage])
        else
            return "ONLY_CONF"
        end

        return "SUCCESS"
    end)

    api:host()
end
