local out = {}

function out.loadUtil(self, name, path)
    path = path or "disk/utils/"
    local util = require(path .. name)

    self[name] = util
end

-- automatic import
local function createAutoImport(baseObj, path)
    baseObj = baseObj or {}
    setmetatable(baseObj, {
        __index = function(self, key)
            if fs.isDir(path .. key) then
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

createAutoImport(out, "/disk/utils/")

return out

