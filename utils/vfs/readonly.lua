local out = {}

local fns = {"isDriveRoot", "complete", "list", "combine", "getName", "getDir", "getSize", "exists", "isDir",
             "isReadOnly", "makeDir", "move", "copy", "delete", "open", "getDrive", "getFreeSpace", "find",
             "getCapacity", "attributes"}

function out.create(raw_fs)
    local out = {}

    for i, fn in ipairs(fns) do
        out[fn] = function(...)
            return raw_fs[fn](...)
        end
    end

    function out.isReadOnly(path)
        return true
    end

    function out.makeDir(path)
        throw(path .. ": Access Denied")
    end

    function out.move(path, dest)
        throw(path .. ": Access Denied")
    end

    function out.delete(path)
        throw(path .. ": Access Denied")
    end

    function out.open(path, flags)
        if flags:sub(1, 1) == "w" then
            throw(path .. ": Access Denied")
        else
            return raw_fs.open(path, flags)
        end
    end

    function out.attributes(path)
        local temp = raw_fs.attributes(path)
        temp.isReadOnly = true
        return temp
    end

    return out

end

return out
