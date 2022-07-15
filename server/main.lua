local utils = require("disk/utils/utils")
utils:loadUtil("api")
utils:loadUtil("fsu")
utils:loadUtil("table")
utils:loadUtil("gfx.buffer")

local buffer = utils.gfx.buffer.createBuffer()

local function indexStorage(index, container, containerName, threads)

    buffer:addLine("Enabling Storage: " .. containerName)

    container.size()

    local complete = {}

    for i = 1, container.size() do
        complete[i] = false
        buffer:addLine("Spawning Thread for slot #" .. i .. " of container " .. containerName)
        threads.spawnChild(function(thrd)
            local item = container.getItemDetail(i)
            if item then
                local itemName = item.name
                local itemCount = item.count
                local itemMeta = item.nbt or "00000000000000000000000000000000"

                index.byName[itemName .. ":" .. itemMeta] = index.byName[itemName .. ":" .. itemMeta] or {
                    id = itemName,
                    displayName = item.displayName,
                    totalCount = 0,
                    nbt = itemMeta,
                    maxCount = item.maxCount,
                    slots = {}
                }

                itemObj = index.byName[itemName .. ":" .. itemMeta]

                itemObj.totalCount = itemObj.totalCount + itemCount

                table.insert(itemObj.slots, {
                    count = itemCount,
                    resCount = 0,
                    slot = i,
                    container = container,
                    containerID = containerName
                })
            else
                table.insert(index.freeSlots, {
                    container = container,
                    slot = i
                })
            end
            complete[i] = true
        end)
    end

    for i = 1, container.size() do
        while not complete[i] do
            os.sleep()
        end
    end

    -- local items = container.list()

    -- for i, item in pairs(items) do
    --     local itemName = item.name
    --     local itemCount = item.count
    --     local itemData = item.nbt or "00000000000000000000000000000000"

    --     index.byName[itemName .. ":" .. itemData] = index.byName[itemName .. ":" .. itemData] or {
    --         id = itemName,
    --         displayName = "",
    --         totalCount = itemCount,
    --         nbt = itemData
    --     }

    --     -- todo add specific support for drawers. (ie, reserved slots, skip slot #1 and max_value is arbitrary)
    -- end

end

local function main(threads)
    buffer:addLine("Storage Server Init")

    buffer:addLine("Checking for configuration files")

    if not fs.exists("conf") then
        fs.makeDir("conf")
        -- Create file storages.lua with contents `return {\n\n}`
        utils.fsu.write("conf/storages.lua", "return {\n\n}")
    end

    -- Load Configs from Files 
    local conf_storages = require("conf/storages")

    local function save_conf()
        utils.fsu.write("conf/storages.lua", "return " .. textutils.serialize(conf_storages))
    end

    buffer:addLine("Scanning Storage Asyncronously...")

    local all_storages = {peripheral.find("inventory")}
    local all_storages_by_name = {}

    local item_storages = {}

    local index = {
        byName = {},
        freeSlots = {}
    }

    _G.strindex = index

    for _, storage in ipairs(all_storages) do
        storage.name = peripheral.getName(storage)
        buffer:addLine("Found Storage: " .. storage.name)
        all_storages_by_name[storage.name] = storage
    end

    for storage, enabled in pairs(conf_storages) do
        buffer:addLine("Found Storage: " .. storage)
        if enabled then
            if all_storages_by_name[storage] then
                item_storages[storage] = all_storages_by_name[storage]
                threads.spawnChild(function(thrd)
                    indexStorage(index, item_storages[storage], storage, thrd)
                end)
            else
                buffer:addLine("Storage " .. storage .. " not found")
            end
        else
            buffer:addLine("Skipped Storage: " .. storage .. " disabled")
        end
    end

    local api = utils.api.createServer("dmc_storage_system")

    api:registerEndpoint("ping", function()
        return "pong"
    end)

    api:registerEndpoint("getStorages", function()
        return ({utils.table.entries(all_storages_by_name)})[1]
    end)

    api:registerEndpoint("getItemStorages", function()
        return ({utils.table.entries(conf_storages)})[1]
    end)

    api:registerEndpoint("addStorageConf", function(storage)
        conf_storages[storage] = true
        save_conf()

        if all_storages_by_name[storage] and not item_storages[storage] then
            -- table.insert(item_storages, all_storages_by_name[storage])
            item_storages[storage] = all_storages_by_name[storage]
            threads.spawnChild(function(thrd)
                indexStorage(index, item_storages[storage], storage, thrd)
            end)
        else
            return "ONLY_CONF"
        end

        return "SUCCESS"
    end)

    api:registerEndpoint("removeStorageConf", function(storage)
        conf_storages[storage] = false
        save_conf()

        return "ONLY_CONF"
    end)

    api:registerEndpoint("getItemCount", function(item)
        return index.byName[item].totalCount
    end)

    api:registerEndpoint("getItemInfoByID", function(itemID, limit)
        limit = limit or 20
        local items = {}
        for item, info in pairs(index.byName) do
            if info.id == itemID and #items < 20 then
                table.insert(items, {
                    id = info.id,
                    count = info.totalCount,
                    displayName = info.displayName,
                    nbt = info.nbt
                })
            end
        end
        return items
    end)

    api:registerEndpoint("getItemInfoByName", function(itemName, limit)
        limit = limit or 20
        local items = {}
        for item, info in pairs(index.byName) do
            if string.find(info.displayName, itemName) then
                table.insert(items, {
                    id = info.id,
                    totalCount = info.totalCount,
                    displayName = info.displayName,
                    nbt = info.nbt
                })
            end
        end

        table.sort(items, function(a, b)
            if b.totalCount == a.totalCount then
                return a.displayName < b.displayName
            end

            return b.totalCount < a.totalCount
        end)

        return utils.table.slice(items, 1, math.min(limit, #items))
    end)

    threads.spawnChild(function(thrd)
        api.buffer = buffer
        api:host(thrd)
    end, "api")

    threads.spawnChild(function(thrd)
        local function do_sleep()
            os.sleep(1)
        end
        local function get_scroll_evt()
            local event, dir, x, y = os.pullEvent("mouse_scroll")
            buffer.scroll = math.max(0, buffer.scroll - dir)
        end
        -- Following line PRINT LOGS
        while true do
            parallel.waitForAny(do_sleep, get_scroll_evt)
            buffer:render(1, 1, 51, 19)
        end
    end, "logs")

    threads.spawnChild(function(thrd)
        _G.rt = _G._dmcThreadSystemData.rootThread
        -- shell.run("lua")
    end, "shell")

    os.sleep(1)
end

return function()
    local threadSys = require("disk/utils/threads")
    threadSys(main)
end
