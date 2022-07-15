local rand = require("disk/utils/rand")

local API = {}

local modem = peripheral.getName(peripheral.find("modem"))

local api = {
    endpoints = {},
    numThreads = 4,
    servicename = "API"
}

api.__index = api

function api.registerEndpoint(self, endpoint, handler)
    self.endpoints[endpoint] = handler
end

function api.host_thread(self, id)
    self.threadStatus[id] = "idle"

    return function(thread)
        print("API Thread " .. id .. " Started")
        while true do
            local event, data = os.pullEvent("api_thread_" .. id)
            self.threadStatus[id] = "working"
            if data then
                local endpoint = data[1]
                local params = data[2]
                local replyProtocol = data[3]
                local replyAddress = data[4]
                if self.endpoints[endpoint] then
                    local response = {self.endpoints[endpoint](table.unpack(params))}
                    if replyProtocol and replyAddress then
                        rednet.send(replyAddress, response, replyProtocol)
                    end
                end
            end
            if #self.backlog > 0 then
                os.queueEvent("api_thread_" .. id, table.remove(self.backlog))
            else
                self.threadStatus[id] = "idle"
            end
        end
    end
end

function api.host_router(self, threads)
    self.backlog = {}
    self.threadStatus = {}

    print("API Router Started")

    for i = 1, self.numThreads do
        -- table.insert(threads, self:host_thread(i))
        local thread = self:host_thread(i)
        threads.spawnChild(thread)
    end

    while true do
        print("Waiting on " .. self.servicename)
        local id, message = rednet.receive(self.servicename)
        -- Messages in form {funcname, params, replyProtocol, replyID(auto)}

        if message[1] == "index" then
            local response = {}
            for endpoint, _ in pairs(self.endpoints) do
                table.insert(response, endpoint)
            end
            rednet.send(id, response, message[3])
        else

            message[4] = message[4] or id

            local responseToQueue = true

            -- while responseToQueue do
            for tid, tstatus in ipairs(self.threadStatus) do
                if tstatus == "idle" then
                    print("Sending task (" .. message[1] .. ") to thread #" .. tid)
                    os.queueEvent("api_thread_" .. tid, message)
                    responseToQueue = false
                    break
                end
            end
            if responseToQueue then
                table.insert(self.backlog, message)

            end
            -- end
        end
    end
end

function api.host(self, threads)
    rednet.open(modem)
    rednet.host(self.servicename, "api_host_" .. os.getComputerID())

    self:host_router(threads)

end

function API.createServer(servicename)
    local out_api = {}
    setmetatable(out_api, api)
    out_api.servicename = servicename or "API"
    return out_api
end

function API.findService(servicename, serverID)
    rednet.open(modem)
    local out = {}

    servicename = servicename or "API"

    while serverID == nil do
        serverID = rednet.lookup(servicename)
    end

    local indexRetProto = rand.randString()

    rednet.send(serverID, {"index", nil, indexRetProto}, servicename)

    local id, endpoints = rednet.receive(indexRetProto)

    for _, endpoint in ipairs(endpoints) do
        out[endpoint] = function(...)
            local args = {...}
            local retProto = rand.randString()
            while true do
                rednet.send(serverID, {endpoint, args, retProto}, servicename)
                local id, response = rednet.receive(retProto, 60)
                if id then
                    return table.unpack(response)
                end
            end
        end
    end

    return out
end

return API
