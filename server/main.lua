local utils = require("disk/utils/utils")

--[[
    Todo:
    * add autoCrafting
    * create custom fs with mount support
]] --

local buffer = utils.gfx.buffer.createBuffer()

local function indexStorage(index, container, containerName, threads)

    buffer:addLine("Enabling Storage: " .. containerName)

    container.size()

    local complete = {}

    buffer:addLine("Spawning Threads for container " .. containerName)
    for i = 1, container.size() do
        complete[i] = false
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

                local itemObj = index.byName[itemName .. ":" .. itemMeta]

                itemObj.totalCount = itemObj.totalCount + itemCount

                table.insert(itemObj.slots, {
                    count = itemCount,
                    resCount = 0,
                    slot = i,
                    container = container,
                    containerID = containerName,
                    locked = false
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
            os.pullEventRaw()
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

local function findItemInIndex(index, item)
    if not index.byName[item.id] then
        return nil
    end

    -- Item is of type {id: string, count: number}
    local itemName = item.id
    local itemCount = item.count

    local currentCount = 0

    for i, slot in ipairs(index.byName[itemName].slots) do
        if not slot.locked then
            currentCount = currentCount + slot.count
        end
    end

    if currentCount < itemCount then
        return nil
    end

    local slots = {}
    for i, slot in ipairs(index.byName[itemName].slots) do
        if itemCount > 0 and not slot.locked then
            table.insert(slots, {
                slot = slot,
                count = math.min(itemCount, slot.count)
            })
            itemCount = itemCount - slot.count
        end
    end

    return slots
end

local function moveItems(index, storages, items, target, threads)
    -- items is an array of itemids + nbt and count

    local itemsInIndex = {}
    for i, item in pairs(items) do
        itemsInIndex[item.id] = findItemInIndex(index, item)
        if not itemsInIndex[item.id] then
            return false
        end
    end

    for i, item in pairs(itemsInIndex) do
        for j, slot in ipairs(item) do
            slot.slot.locked = true
            slot.slot.count = slot.slot.count - slot.count
            index.byName[i].totalCount = index.byName[i].totalCount - slot.count
        end
    end

    local target_storage = storages[target] or peripheral.wrap(target)

    if not target_storage then
        for i, item in pairs(itemsInIndex) do
            for j, slot in ipairs(item) do
                slot.slot.count = slot.slot.count + slot.count
                index.byName[i].totalCount = index.byName[i].totalCount + slot.count
                slot.slot.locked = false
            end
        end
        return false
    end

    local complete = {}

    for i, item in pairs(itemsInIndex) do
        for j, slot in ipairs(item) do
            local threadID = #complete + 1
            complete[threadID] = false
            threads.spawnChild(function(thrd)
                local remaining = slot.count

                while remaining > 0 do
                    remaining = remaining - target_storage.pullItems(slot.slot.containerID, slot.slot.slot, remaining)
                end

                complete[threadID] = true
            end)
        end
    end

    for tid, isComplete in ipairs(complete) do
        while not complete[tid] do
            os.pullEventRaw()
        end
    end

    for i, item in pairs(itemsInIndex) do
        for j, slot in ipairs(item) do

            slot.slot.locked = false
        end
    end

    for i, item in pairs(items) do
        local id = item.id

        local removed = utils.table.filter(index.byName[id].slots, function(slot)
            return slot.count > 0 or slot.locked
        end)

        for j, slot in ipairs(removed) do
            slot.locked = false
            table.insert(index.freeSlots, {
                container = slot.container,
                slot = slot.slot
            })
        end
    end

    return true

end

local function depositItems(index, target, threads)

    local target_storage = peripheral.wrap(target)

    if not target_storage then
        return false
    end

    local itemsToDeposit = target_storage.size()

    -- TODO support for storage drawers

    local complete = {}

    for slotID = 1, itemsToDeposit do
        local threadID = #complete + 1
        complete[threadID] = false
        threads.spawnChild(function(thrd)
            local item = target_storage.getItemDetail(slotID)
            if item then
                local itemName = item.name
                local itemCount = item.count
                local itemMeta = item.nbt or "00000000000000000000000000000000"

                local id = itemName .. ":" .. itemMeta

                index.byName[id] = index.byName[id] or {
                    id = itemName,
                    displayName = item.displayName,
                    totalCount = 0,
                    nbt = itemMeta,
                    maxCount = item.maxCount,
                    slots = {}
                }

                local indexItem = index.byName[id]

                if indexItem then
                    for i, slot in ipairs(indexItem.slots) do
                        if slot.count < indexItem.maxCount and not slot.locked and itemCount > 0 then
                            slot.locked = true
                            local moved = slot.container.pullItems(target, slotID, itemCount, slot.slot)
                            itemCount = itemCount - moved
                            slot.count = slot.count + moved
                            indexItem.totalCount = indexItem.totalCount + moved
                            slot.locked = false
                        end
                    end
                end

                if itemCount > 0 then
                    local newSlot = table.remove(index.freeSlots)
                    if newSlot then
                        local moved = newSlot.container.pullItems(target, slotID, itemCount, newSlot.slot)
                        indexItem.totalCount = indexItem.totalCount + moved
                        table.insert(indexItem.slots, {
                            count = moved,
                            resCount = 0,
                            slot = newSlot.slot,
                            container = newSlot.container,
                            containerID = peripheral.getName(newSlot.container),
                            locked = false
                        })
                    end
                end
            end
            complete[threadID] = true
        end)
    end

    for tid, isComplete in ipairs(complete) do
        while not complete[tid] do
            os.pullEventRaw()
        end
    end
end

local function main(threads)

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
            -- buffer:render(1, 1, 51, 19)
            buffer:render(25, 1, 51 - 25, 19)
        end
    end, "logs")

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
        -- buffer:addLine("Found Storage: " .. storage.name)
        all_storages_by_name[storage.name] = storage
    end

    for storage, enabled in pairs(conf_storages) do
        buffer:addLine("Indexing Storage: " .. storage)
        if enabled then
            if all_storages_by_name[storage] then
                item_storages[storage] = all_storages_by_name[storage]
                -- threads.spawnChild(function(threads)
                indexStorage(index, item_storages[storage], storage, threads)
                -- end)
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
                    totalCount = info.totalCount,
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

    api:registerEndpoint("moveItems", function(items, target)
        return moveItems(index, all_storages, items, target, threads)
    end)

    api:registerEndpoint("depositItems", function(target)
        return depositItems(index, target, threads)
    end)

    api:registerEndpoint("reboot", function()
        buffer:addLine("Rebooting...")
        os.reboot()
    end)

    api:registerEndpoint("freeSlotCount", function()
        return #index.freeSlots
    end)

    threads.spawnChild(function(thrd)
        api.buffer = buffer
        api:host(thrd)
    end, "api")

    threads.spawnChild(function(thrd)
        _G.rt = _G._dmcThreadSystemData.rootThread
        shell.run("lua")
    end, "shell")

    os.sleep(1)
end

return function()
    local threadSys = require("disk/utils/threads")
    threadSys(main)
end
