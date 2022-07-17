local out = {}

local proto = {}
proto.__index = proto
setmetatable(out, proto)

function proto.combine(path, ...)
    return realFS.combine(path, ...)
end

function proto.getName(path)
    return realFS.getName(path)
end

function proto.getDir(path)
    return realFS.getDir(path)
end

function out.create(write_fs, ...)
    local out = {
        filesystems = {write_fs, ...}
    }

    setmetatable(out, proto)

    function out.isDriveRoot(path)
        return path == ""
    end

    function out.complete(path, location, include_files, include_dirs)
        local outs = {}
        for i, fs in ipairs(out.filesystems) do
            for _, v in ipairs(fs.complete(path, location, include_files, include_dirs)) do
                table.insert(outs, v)
            end
        end
        return outs
    end

    function out.list(path)
        local outs = {}
        for i, fs in ipairs(out.filesystems) do
            for _, v in ipairs(fs.list(path)) do
                table.insert(outs, v)
            end
        end
        return outs
    end

    function out.getSize(path)
        for i, fs in ipairs(out.filesystems) do
            if fs.exists(path) then
                return fs.getSize(path)
            end
        end
        error(path .. ": No such file")
    end

    function out.exists(path)
        for i, fs in ipairs(out.filesystems) do
            if fs.exists(path) then
                return true
            end
        end
        return false
    end

    function out.isDir(path)
        for i, fs in ipairs(out.filesystems) do
            if fs.exists(path) then
                return fs.isDir(path)
            end
        end
        return false
    end

    function out.isReadOnly(path)
        return write_fs.isReadOnly(path)
    end

    function out.makeDir(path)
        write_fs.makeDir(path)
    end

    function out.move(path, dest)
        write_fs.move(path, dest)
    end

    function out.copy(path, dest)
        for i, fs in ipairs(out.filesystems) do
            if fs.exists(path) then
                local source, err = fs.open(path, "rb")
                if source then
                    local dest = write_fs.open(dest, "wb")
                    if dest then
                        local byt = source.read()
                        while byt do
                            dest.write(byt)
                            byt = source.read()
                        end
                        source.close()
                        dest.close()
                        return
                    end
                else
                    error(err, 1)
                end
            end
        end
    end

    function out.delete(path)
        write_fs.delete(path)
    end

    function out.open(path, mode)
        if write_fs.exists(path) then
            return write_fs.open(path, mode)
        end

        for i, fs in ipairs(out.filesystems) do
            if fs.exists(path) then
                if mode:sub(1, 1) == "r" then
                    return fs.open(path, mode)
                end

                out.copy(path, path)
                break
            end
        end

        return write_fs.open(path, mode)
    end

    function out.getDrive(path)
        return "overlayfs"
    end

    function out.getFreeSpace(path)
        return write_fs.getFreeSpace(path)
    end

    function out.find(path)
        local outs = {}
        for i, fs in ipairs(out.filesystems) do
            for _, v in ipairs(fs.find(path)) do
                table.insert(outs, v)
            end
        end

        return outs
    end

    function out.getCapacity(path)
        return write_fs.getCapacity(path)
    end

    function out.attributes(path)
        for i, fs in ipairs(out.filesystems) do
            if fs.exists(path) then
                local temp = fs.attributes(path)
                temp.isReadOnly = write_fs.isReadOnly(path)
                return temp
            end
        end
        return write_fs.attributes(path)
    end

    return out

end

return out
