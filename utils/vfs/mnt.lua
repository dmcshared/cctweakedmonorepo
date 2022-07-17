-- Allows you to combine various FS compatible systems into one mega-system with mount points
local out = {}

local realFS = _G.fs

local proto = {}
proto.__index = proto

-- Absolute paths only, in form "disk/banana"
function proto.mount(self, path, fsapi)

    if not realFS.isDir(path) then
        error("Path must be a folder")
    end

    local pathParts = utils.strlib.split(path, "/")

    local current = self.mountTable
    for i, part in ipairs(pathParts) do
        if current.children[part] == nil then
            current.children[part] = {
                mountHere = nil,
                children = {},
                parent = current,
                part = part
            }
        end
        current = current.children[part]
    end
    current.mountHere = fsapi
    return self
end

function proto.unmount(self, path)
    local pathParts = utils.strlib.split(path, "/")

    local current = self.mountTable
    for i, part in ipairs(pathParts) do
        if current.children[part] == nil then
            return false
        end
        current = current.children[part]
    end
    current.mountHere = nil

    -- Clean up dangling mounts

    while current.parent do
        current.parent.children[current.part] = nil
        if current.parent.mountHere == nil then
            current = current.parent
        else
            return true
        end
    end

    return true
end

function proto.resolveMount(self, path)
    -- Returns the mount point and the path relative to the mount point
    local pathParts = utils.strlib.split(path, "/")

    local lastSafe = {self.mountTable.mountHere, path}
    local current = self.mountTable
    for i, part in ipairs(pathParts) do
        if current.mountHere then
            lastSafe = {current.mountHere, utils.strlib.join(table.pack(table.unpack(pathParts, i)), "/")}
        end
        if current.children[part] == nil then
            return table.unpack(lastSafe)
        end
        current = current.children[part]
    end
    return table.unpack(lastSafe)
end

-- fs api impl
--[[ 
isDriveRoot(path)
complete(path, location [, include_files , include_dirs])
list(path)
combine(path, ...)
getName(path)
getDir(path)
getSize(path)
exists(path)
isDir(path)
isReadOnly(path)
makeDir(path)
move(path, dest)
copy(path, dest)
delete(path)
open(path, mode)
getDrive(path)
getFreeSpace(path)
find(path)
getCapacity(path)
attributes(path)
]] --

function out.create(rootFS)
    local self = setmetatable({}, proto)
    self.mountTable = {
        mountHere = rootFS,
        children = {}
    }

    function self.isDriveRoot(path)

        local mount, path = self:resolveMount(path)
        return mount.isDriveRoot(path)
    end

    function self.complete(path, location, include_files, include_dirs)

        local mount, localLoc = self:resolveMount(location)
        return mount.complete(path, localLoc, include_files, include_dirs)
    end

    function self.list(path)

        if path:sub(-1) ~= "/" then
            path = path .. "/"
        end
        local mount, localPath = self:resolveMount(path)
        return mount.list(localPath)
    end

    function self.combine(path, ...)

        return realFS.combine(path, ...)
    end

    function self.getName(path)

        return realFS.getName(path)
    end

    function self.getDir(path)

        return realFS.getDir(path)
    end

    function self.getSize(path)

        local mount, localPath = self:resolveMount(path)
        return mount.getSize(localPath)
    end

    function self.exists(path)

        local mount, localPath = self:resolveMount(path)
        return mount.exists(localPath)
    end

    function self.isDir(path)

        local mount, localPath = self:resolveMount(path)
        return mount.isDir(localPath)
    end

    function self.isReadOnly(path)

        local mount, localPath = self:resolveMount(path)
        return mount.isReadOnly(localPath)
    end

    function self.makeDir(path)

        local mount, localPath = self:resolveMount(path)
        return mount.makeDir(localPath)
    end

    function self.move(path, dest)

        local mount, localPath = self:resolveMount(path)
        local mount2, localPath2 = self:resolveMount(dest)
        if mount == mount2 then
            mount.move(localPath, localPath2)
        else
            mount.copy(localPath, localPath2)
            mount.delete(localPath)
        end
    end

    function self.copy(path, dest)

        local source, err = self.open(path, "rb")
        if source then
            local dest = self.open(dest, "wb")
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

    function self.delete(path)

        local mount, localPath = self:resolveMount(path)
        return mount.delete(localPath)
    end

    function self.open(path, mode)

        local mount, localPath = self:resolveMount(path)

        return mount.open(localPath, mode)
    end

    function self.getDrive(path)

        local mount, localPath = self:resolveMount(path)
        return mount.getDrive(localPath)
    end

    function self.getFreeSpace(path)

        local mount, localPath = self:resolveMount(path)
        return mount.getFreeSpace(localPath)
    end

    function self.find(path)

        -- TODO: Maybe implement this by hand to allow wildcard mount reading? (ie. dev/*/foo.txt)
        local mount, localPath = self:resolveMount(path)
        return mount.find(localPath)
    end

    function self.getCapacity(path)

        local mount, localPath = self:resolveMount(path)
        return mount.getCapacity(localPath)
    end

    function self.attributes(path)

        local mount, localPath = self:resolveMount(path)
        return mount.attributes(localPath)
    end

    return self
end

return out
