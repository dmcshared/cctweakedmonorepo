local out = {}

local proto = {}
proto.__index = proto

function out.create(raw_fs)
    local out = {}
    setmetatable(out, proto)

    return out
end

function proto.isDriveRoot(path)
    return path == ""
end

function proto.complete(path, location, include_files, include_dirs)
    return {}
end

function proto.list(path)
    return {}
end

function proto.combine(path, ...)
    return realFS.combine(path, ...)
end

function proto.getName(path)
    return realFS.getName(path)
end

function proto.getDir(path)
    return realFS.getDir(path)
end

function proto.getSize(path)
    error(path .. ": No such file")
end

function proto.exists(path)
    return false
end

function proto.isDir(path)
    return false
end

function proto.isReadOnly(path)
    return true
end

function proto.makeDir(path)
    error(path .. ": Permission denied")
end

function proto.move(path, dest)
    error(path .. ": No such file")
end

function proto.copy(path, dest)
    error(path .. ": No such file")
end

function proto.delete(path)
    error(path .. ": No such file")
end

function proto.open(path, flags)
    error(path .. ": No such file")
end

function proto.getDrive(path)
    return "blankfs"
end

function proto.getFreeSpace(path)
    return 0
end

function proto.find(path, name)
    return {}
end

function proto.getCapacity(path)
    return 0
end

function proto.attributes(path)
    error(path .. ": No such file")
end

return out
