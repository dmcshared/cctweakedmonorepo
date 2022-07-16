local utils = require("disk/utils/utils")
utils:loadUtil("api")
utils:loadUtil("fsu")
utils:loadUtil("rand")

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

    -- local topBar = " I D _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ S "
    local windows = {}
    local topBarWindow = window.create(term.current(), 1, 1, ({term.getSize()})[1], 1, true)
    topBarWindow.setBackgroundColor(colors.lightGray)
    topBarWindow.setTextColor(colors.black)
    topBarWindow.setCursorPos(1, 1)
    topBarWindow.setCursorBlink(false)
    topBarWindow.clear()
    topBarWindow.write(topBar)
    threads.spawnChild(function(thrd)
        local windowID = 1

        windows[windowID].window.setVisible(true)

        os.queueEvent(table.unpack({windows[windowID].prefix .. "init", windowID}))

        while true do
            -- Generate Top Bar
            -- topBarWindow.clear()
            local topBarString = ""
            for i, win in ipairs(windows) do
                if i == windowID then
                    topBarString = topBarString .. "*"
                else
                    topBarString = topBarString .. " "
                end
                topBarString = topBarString .. win.symbol
            end
            topBarWindow.setCursorPos(1, 1)
            topBarWindow.write(topBarString)
            topBarWindow.setCursorBlink(false)

            -- Handle events (mouse y == 1 goes to top bar, rest to windowID)
            local event = table.pack(os.pullEvent())

            if not (event[1]:sub(1, #windows[windowID].prefix) == windows[windowID].prefix) then

                if event and event[1] and event[1]:sub(1, 5) == "mouse" then
                    if event[4] == 1 then
                        windows[windowID].window.setVisible(false)
                        windowID = math.min(math.ceil(event[3] / 2), #windows)
                        windows[windowID].window.setVisible(true)
                    else
                        event[4] = event[4] - 1
                    end
                end

                -- Resend Events with prefix
                event[1] = windows[windowID].prefix .. event[1]
                print(event[1])
                os.queueEvent(table.unpack(event))
                windows[windowID].window.redraw()
            end
        end
    end)

    do
        local window = window.create(term.native(), 1, 2, 51, 18, false)
        window.setBackgroundColour(colours.yellow)
        window.setTextColour(colours.red)
        window.clear()
        local id = utils.rand.randString()
        table.insert(windows, {
            symbol = "I",
            window = window,
            prefix = id .. "_"
        })
        threads.spawnChild(require("disk/player_interface/subprograms/itemList")(api, conf_interface_storage), {
            eventPrefix = id .. "_",
            preResume = function()
                term.redirect(window)
            end,
            postResume = function()
                term.redirect(term.native())
            end
        })
    end

    do
        local window = window.create(term.native(), 1, 2, 51, 18, false)
        window.setBackgroundColour(colours.yellow)
        window.setTextColour(colours.red)
        window.clear()
        local id = utils.rand.randString()
        table.insert(windows, {
            symbol = "C",
            window = window,
            prefix = id .. "_"
        })
        threads.spawnChild(require("disk/player_interface/subprograms/chestList")(api, conf_interface_storage), {
            eventPrefix = id .. "_",
            preResume = function()
                term.redirect(window)
            end,
            postResume = function()
                term.redirect(term.native())
            end
        })
    end

    local shellWindow = window.create(term.native(), 1, 2, 51, 18, false)
    table.insert(windows, {
        symbol = "S",
        window = shellWindow,
        prefix = "shell_"
    })
    threads.spawnChild(function(thrd)
        _G.api = api
        shell.run("shell")
    end, {
        id = "shell",
        eventPrefix = "shell_",
        preResume = function()
            term.redirect(shellWindow)
        end,
        postResume = function()
            term.redirect(term.native())
        end
    })

end

return function()
    local threadSys = require("disk/utils/threads")
    threadSys(main)
end
