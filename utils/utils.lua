local out = {}

function out.loadUtil(self, name)
    local util = require("disk/utils/" .. name)

    local result = {};
    for match in (name .. "."):gmatch("(.-)[./]") do
        table.insert(result, match);
    end

    for i = 1, (#result - 1) do
        local key = result[i]
        if not self[key] then
            self[key] = {}
        end
        self = self[key]
    end

    self[result[#result]] = util
end

return out

