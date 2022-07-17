local network = {}

function network.create(protocol, serverID)
    protocol = protocol or "samba_share"

    local api = utils.api.findService(protocol, serverID)

    api.open = function(path, mode)
        local info = api.open_file(path, mode)
        local id = info[1]
        local funcs = info[2]

        local out = {}
        for i, func in ipairs(funcs) do
            out[func] = function(...)
                return api[func .. "_file"](id, ...)
            end
        end

        return out
    end

    return api
end

function network.host(thrd, protocol, fs)
    protocol = protocol or "samba_share"
    local files = {}

    local api = utils.api.createServer(protocol)

    for name, impl in pairs(fs) do
        api:registerEndpoint(name, impl)
    end

    api.endpoints.open = nil

    api:registerEndpoint("open_file", function(path, mode)
        local id = #files + 1
        files[id] = 1
        files[id] = fs.open(path, mode)
        local opts = utils.table.entries(files[id])
        return {id, opts}
    end)

    api:registerEndpoint("close_file", function(id)
        files[id].close()
        files[id] = nil
    end)

    api:registerEndpoint("readLine_file", function(id)
        return files[id].readLine()
    end)

    api:registerEndpoint("readAll", function(id)
        return files[id].readAll()
    end)

    api:registerEndpoint("write_file", function(id, data)
        files[id].write(data)
    end)

    api:registerEndpoint("writeLine_file", function(id, data)
        files[id].writeLine(data)
    end)

    api:registerEndpoint("flush", function(id)
        files[id].flush()
    end)

    api:registerEndpoint("read", function(id)
        return files[id].read()
    end)

    api:host(thrd)
end

return network
