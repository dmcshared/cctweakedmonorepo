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

    return out

end

return out
