local utils = require("disk/utils/utils")
utils:loadUtil("table")

return function(api, interfaceInv)
    return function(threads)
        local currentQuery = ""

        local capitalized = false
        local control = false
        local w, h = term.getSize()
        local itemInfo = {}

        local function redrawInventory()
            term.clear()
            term.setCursorPos(1, 1)
            term.write("> " .. currentQuery)

            local usedChests = utils.table.set(api.getItemStorages())
            itemInfo = {}
            for i, chest in ipairs({peripheral.find("inventory")}) do
                if not usedChests[peripheral.getName(chest)] then
                    table.insert(itemInfo, peripheral.getName(chest))
                end
            end

            for i, item in ipairs(itemInfo) do
                term.setCursorPos(1, i + 1)
                term.write(item)

            end
        end

        redrawInventory()

        threads.spawnChild(function()
            while true do
                while not capitalized do
                    local event, key, is_held = os.pullEvent("key")
                    if key == keys.leftShift then
                        capitalized = true
                    end
                end

                while capitalized do
                    local event, key, is_held = os.pullEvent("key_up")
                    if key == keys.leftShift then
                        capitalized = false
                    end
                end
            end
        end)
        threads.spawnChild(function()
            while true do
                while not control do
                    local event, key, is_held = os.pullEvent("key")
                    if key == keys.leftAlt then
                        control = true
                    end
                end

                while control do
                    local event, key, is_held = os.pullEvent("key_up")
                    if key == keys.leftAlt then
                        control = false
                    end
                end
            end
        end)
        threads.spawnChild(function()
            while true do
                local event, key, is_held = os.pullEvent("key")
                if key == 259 then
                    currentQuery = currentQuery:sub(1, #currentQuery - 1)
                    redrawInventory()

                end
            end
        end)

        threads.spawnChild(function(thrd)
            while true do
                local event, button, x, y = os.pullEvent("mouse_click")
                -- print(event)
                if y > 1 then

                    api.addStorageConf(itemInfo[y - 1])

                    redrawInventory()
                end
            end
        end)

        while true do
            redrawInventory()

            local event, key = os.pullEvent("char")
            if capitalized then
                currentQuery = currentQuery .. key:upper()
            else
                currentQuery = currentQuery .. key:lower()
            end
        end
    end
end
