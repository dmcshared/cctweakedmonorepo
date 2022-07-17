local rfs = {}

local realFS = _G.fs

local fns = {"isDriveRoot", "complete", "list", "combine", "getName", "getDir", "getSize", "exists", "isDir",
             "isReadOnly", "makeDir", "move", "copy", "delete", "open", "getDrive", "getFreeSpace", "find",
             "getCapacity", "attributes"}

function rfs.create(raw_fs, prefix)
    local out = {}

    for i, fn in ipairs(fns) do
        out[fn] = function(path, ...)
            if path:find("[.][.]") then
                throw(path .. ": Access Denied")
            end

            return raw_fs[fn](prefix .. "/" .. path, ...)
        end
    end

    function out.complete(path, location, include_files, include_dirs)
        if location:find("[.][.]") or path:find("[.][.]") then
            throw(location .. ": Access Denied")
        end

        return raw_fs.complete(path, location, include_files, include_dirs)
    end

    function out.combine(path, ...)
        return realFS.combine(path, ...)
    end

    function out.getName(path)
        realFS.getName(path)
    end

    function out.getDir(path)
        realFS.getDir(path)
    end

    function out.move(path, dest)
        if path:find("[.][.]") or dest:find("[.][.]") then
            throw(path .. ": Access Denied")
        end

        return raw_fs.move(prefix .. "/" .. path, prefix .. "/" .. dest)
    end

    function out.copy(path, dest)
        if path:find("[.][.]") or dest:find("[.][.]") then
            throw(path .. ": Access Denied")
        end

        return raw_fs.copy(prefix .. "/" .. path, prefix .. "/" .. dest)
    end

    return out

end

return rfs
