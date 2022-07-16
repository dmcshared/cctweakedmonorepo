return function(api, interfaceInv)
    return function(threads)
        local currentQuery = ""

        local capitalized = false
        local control = false
        local w, h = term.getSize()
        local itemInfo = api.getItemInfoByName(currentQuery, 17)

        local vending = false

        local function redrawInventory()
            if vending then
                return
            end
            term.clear()
            term.setCursorPos(1, 1)
            term.write("> " .. currentQuery)

            itemInfo = api.getItemInfoByName(currentQuery, 17)
            for i, item in ipairs(itemInfo) do
                term.setCursorPos(1, i + 1)
                term.write(item.displayName)
                term.setCursorPos(w - 4 - 2, i + 1)
                term.write("x " .. item.totalCount)

            end
        end

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
                if key == 259 and not vending then
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
                    vending = true

                    term.clear()
                    term.setCursorPos(1, 1)
                    print(itemInfo[y - 1].id)
                    local amount = math.min(read(term.write("How many " .. itemInfo[y - 1].displayName .. "? (Max: " ..
                                                                itemInfo[y - 1].totalCount .. ") ")),
                        itemInfo[y - 1].totalCount)
                    api.moveItems({{
                        id = itemInfo[y - 1].id .. ":" .. itemInfo[y - 1].nbt,
                        count = amount
                    }}, interfaceInv)

                    vending = false

                    redrawInventory()
                end
            end
        end)

        while true do

            redrawInventory()

            local event, key = os.pullEvent("char")
            if not vending then
                if control then
                    if key == "d" then
                        api.depositItems(interfaceInv)
                    elseif key == "r" then
                        api.reboot()
                    end
                else
                    if capitalized then
                        currentQuery = currentQuery .. key:upper()
                    else
                        currentQuery = currentQuery .. key:lower()
                    end
                end
            end

        end
    end
end
