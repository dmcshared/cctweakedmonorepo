local out = {}

function out.loadUtil(self, name)
    local util = require("disk/utils/" .. name)
    self[name] = util
end

return out

