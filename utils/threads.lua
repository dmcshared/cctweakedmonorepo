if _G._dmcThreadSystemData then
    print("Some non-main process is trying to access top-level threads api.")
    return
end
_G._dmcThreadSystemData = {
    rootThread = {
        children = {},
        coroutine = nil,
        filter = nil,
        alive = true
    },
    daemonThread = {
        children = {},
        coroutine = coroutine.create(function()
        end),
        filter = nil,
        alive = false
    }
}

local tableutil = require("disk/utils/table")

local function createThread(thread_parent, fn, id)
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

    local threadMessages = {}

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
                        for i, message in ipairs(threadMessages) do
                            if message.type == type then
                                table.remove(threadMessages, i)
                                return message.type, table.unpack(message)
                            end
                        end

                        os.pullEvent("thread_message")
                    end
                else
                    while true do
                        if #threadMessages > 0 then
                            local message = table.remove(threadMessages)
                            return message.type, table.unpack(message)
                        end

                        os.pullEvent("thread_message")
                    end
                end
            end
        })
    end)

    id = id or (#thread_parent.children + 1)

    thread_parent.children[id] = thread

    return function(type, ...)
        table.insert(threadMessages, {type, ...})
        os.queueEvent("thread_message")
    end
end

return function(fn)
    if type(fn) ~= "function" then
        error("bad argument (expected function, got " .. type(fn) .. ")", 3)
    end
    -- createThread(_G._dmcThreadSystemData.rootThread, fn)
    _G._dmcThreadSystemData.rootThread.coroutine = coroutine.create(function()
        fn({
            spawnChild = function(fn)
                return createThread(_G._dmcThreadSystemData.rootThread, fn)
            end,
            spawnSibling = function(fn)
                return createThread(_G._dmcThreadSystemData.rootThread, fn)
            end,
            spawnDaemon = function(fn)
                return createThread(_G._dmcThreadSystemData.daemonThread, fn)
            end,
            getMessage = function()
            end
        })
    end)

    local function tickCoroutines(parent_thread, eventData)
        -- Tick parent_thread coroutine

        if parent_thread.alive then

            if parent_thread.filter == nil or parent_thread.filter == eventData[1] or eventData[1] == "terminate" then
                local ok, event_name =
                    coroutine.resume(parent_thread.coroutine, table.unpack(eventData, 1, eventData.n))

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
