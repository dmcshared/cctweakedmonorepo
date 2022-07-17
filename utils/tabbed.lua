function example()
    local tabd = utils.tabbed.createTabbed(threads) -- It creates its own main child thread

    tabd:addTab("I", function()
        shell.run("shell")
    end)

    tabd:init()

end

local out = {}

local proto = {}
proto.__index = proto

function out.createTabbed(threads)
    local self = setmetatable({}, proto)
    threads.spawnChild(function(trds)
        self.threads = trds
        self.windows = {}

        os.pullEvent("never")
    end)
    os.queueEvent("init")
    os.pullEvent("init")
    return self
end

function proto.addTab(self, symbol, func)
    local window = window.create(term.native(), 1, 2, 51, 18, false)
    window.clear()
    local id = utils.rand.randString()
    table.insert(self.windows, {
        symbol = symbol,
        window = window,
        prefix = id .. "_"
    })
    self.threads.spawnChild(func, {
        eventPrefix = id .. "_",
        preResume = function()
            term.redirect(window)
        end,
        postResume = function()
            term.redirect(term.native())
        end
    })
end

function proto.init(self)
    local topBarWindow = window.create(term.current(), 1, 1, ({term.getSize()})[1], 1, true)
    topBarWindow.setBackgroundColor(colors.brown)
    topBarWindow.setTextColor(colors.black)
    topBarWindow.setCursorPos(1, 1)
    topBarWindow.setCursorPos(1, 2)
    topBarWindow.clear()
    self.threads.spawnChild(function(thrd)
        local windowID = 1

        self.windows[windowID].window.setVisible(true)

        os.queueEvent(table.unpack({self.windows[windowID].prefix .. "init", windowID}))

        while true do
            -- Generate Top Bar
            -- topBarWindow.clear()
            local topBarString = ""
            for i, win in ipairs(self.windows) do
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

            if not (event[1]:sub(1, #self.windows[windowID].prefix) == self.windows[windowID].prefix) then

                if event and event[1] and event[1]:sub(1, 5) == "mouse" then
                    if event[4] == 1 then
                        self.windows[windowID].window.setVisible(false)
                        windowID = math.min(math.ceil(event[3] / 2), #self.windows)
                        self.windows[windowID].window.setVisible(true)
                    else
                        event[4] = event[4] - 1
                    end
                end

                -- Resend Events with prefix
                event[1] = self.windows[windowID].prefix .. event[1]
                os.queueEvent(table.unpack(event))
                self.windows[windowID].window.redraw()
            end
        end
    end)
end

return out
