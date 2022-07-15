if _G._dmcThreadSystemData then
    print("Some non-main process is trying to access top-level threads api.")
    return
end
_G._dmcThreadSystemData = {
    rootThread = {
        children = {},
        coroutine = nil,
        filter = nil,
        alive = true,
        overrides = {}
    },
    daemonThread = {
        children = {},
        coroutine = coroutine.create(function()
        end),
        filter = nil,
        alive = false,
        overrides = {}
    }
}

local tableutil = require("disk/utils/table")

local function createThread(thread_parent, fn, overrides)
    if type(fn) ~= "function" then
        error("bad argument (expected function, got " .. type(fn) .. ")", 3)
    end

    local thread = {
        parent = thread_parent,
        children = {},
        coroutine = nil,
        alive = true,
        filter = nil
    }

    thread.messages = {}

    thread.coroutine = coroutine.create(function()
        fn({
            spawnChild = function(fn, id)
                return createThread(thread, fn, id)
            end,
            spawnSibling = function(fn, id)
                return createThread(thread.parent, fn, id)
            end,
            spawnDaemon = function(fn, id)
                return createThread(_G._dmcThreadSystemData.daemonThread, fn, id)
            end,
            getMessage = function(type)
                if type then

                    while true do
                        for i, message in ipairs(thread.messages) do
                            if message.type == type then
                                table.remove(thread.messages, i)
                                return message.type, table.unpack(message)
                            end
                        end

                        os.pullEvent("thread_message")
                    end
                else
                    while true do
                        if #thread.messages > 0 then
                            local message = table.remove(thread.messages)
                            return message.type, table.unpack(message)
                        end

                        os.pullEvent("thread_message")
                    end
                end
            end
        })
    end)

    local id = #thread_parent.children + 1

    if type(overrides) == "string" then
        id = overrides
    elseif overrides and type(overrides.id) == "string" then
        id = overrides.id
    end
    -- print("Creating thread with id: " .. id)

    thread.overrides = overrides or {}

    thread_parent.children[id] = thread

    return function(type, ...)
        table.insert(thread.messages, {
            type = type,
            ...
        })
    end
end

return function(fn)
    if type(fn) ~= "function" then
        error("bad argument (expected function, got " .. type(fn) .. ")", 3)
    end
    -- createThread(_G._dmcThreadSystemData.rootThread, fn)
    _G._dmcThreadSystemData.rootThread.coroutine = coroutine.create(function()
        fn({
            spawnChild = function(fn, id)
                return createThread(_G._dmcThreadSystemData.rootThread, fn, id)
            end,
            spawnSibling = function(fn, id)
                return createThread(_G._dmcThreadSystemData.rootThread, fn, id)
            end,
            spawnDaemon = function(fn, id)
                return createThread(_G._dmcThreadSystemData.daemonThread, fn, id)
            end,
            getMessage = function()
            end
        })
    end)

    local function tickCoroutines(parent_thread, eventData)
        -- Tick parent_thread coroutine

        if parent_thread.alive then

            if (parent_thread.filter == nil and ((not eventData[1]) or
                (parent_thread.overrides.eventPrefix == eventData[1]:sub(1, #parent_thread.overrides.eventPrefix)))) or
                parent_thread.filter == ((parent_thread.overrides.eventPrefix or "") .. eventData[1]) or eventData[1] ==
                "terminate" then

                local prefixed = eventData[1] and parent_thread.overrides.eventPrefix and eventData[1] ~= "terminate"

                if prefixed then
                    eventData[1] = eventData[1]:sub(#parent_thread.overrides.eventPrefix + 1)
                end

                if parent_thread.overrides.preResume then
                    parent_thread.overrides.preResume(eventData)
                end

                local ok, event_name =
                    coroutine.resume(parent_thread.coroutine, table.unpack(eventData, 1, eventData.n))

                if parent_thread.overrides.postResume then
                    parent_thread.overrides.postResume(eventData)
                end

                if prefixed then
                    eventData[1] = parent_thread.overrides.eventPrefix .. eventData[1]
                end

                if not ok then
                    -- error
                    -- parent_thread.alive = false
                    -- Check for number of childs
                    error(event_name, 0)

                else
                    parent_thread.filter = event_name
                end

                if coroutine.status(parent_thread.coroutine) == "dead" then
                    parent_thread.alive = false
                end
            end
            if parent_thread.filter == "thread_message" and #parent_thread.messages > 0 then
                local ok, event_name = coroutine.resume(parent_thread.coroutine, "thread_message")

                if not ok then
                    parent_thread.alive = false
                    -- Check for number of childs
                else
                    parent_thread.filter = event_name
                end
            end
        end
        if not parent_thread.alive then
            if #parent_thread.children == 0 and parent_thread.parent then
                -- No children, kill parent
                parent_thread.parent.children[tableutil.find(parent_thread.parent.children, parent_thread)] = nil
            end
        end

        -- Tick children coroutines
        for _, child_thread in pairs(parent_thread.children) do
            tickCoroutines(child_thread, eventData)
        end
    end

    local eventData = {
        n = 0
    }
    while true do
        tickCoroutines(_G._dmcThreadSystemData.rootThread, eventData)
        tickCoroutines(_G._dmcThreadSystemData.daemonThread, eventData)
        eventData = table.pack(os.pullEventRaw())
    end

end
