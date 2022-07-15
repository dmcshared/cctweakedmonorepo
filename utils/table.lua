local out = {}

function out.entries(obj)
    local keys = {}
    local values = {}
    for k, v in pairs(obj) do
        table.insert(keys, k)
        table.insert(values, v)
    end
    return keys, values
end

return out
