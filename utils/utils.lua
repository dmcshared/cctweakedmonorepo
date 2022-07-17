if _G.utils then
    return _G.utils
end

local out = {}

_G.utils = out

function out.loadUtil(self, name, path)
    path = path or "disk/utils/"
    local utilFile = fs.open(path .. name .. ".lua", "r")
    local utilSource = utilFile.readAll()
    utilFile.close()

    local util = load(utilSource)
    setfenv(util, _G)

    self[name] = util()
end

local realFS = fs

-- automatic import
local function createAutoImport(baseObj, path)
    baseObj = baseObj or {}
    setmetatable(baseObj, {
        __index = function(self, key)
            if realFS.isDir(path .. key) then
                self[key] = createAutoImport({}, path .. key .. "/")
            else
                out.loadUtil(self, key, path)
            end
            return self[key]
            -- out.loadUtil(self, key)
            -- return self[key]
        end
    })

    return baseObj
end

createAutoImport(out, _G.utilDrive .. "/utils/")

return out

