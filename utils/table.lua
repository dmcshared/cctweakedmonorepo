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

function out.find(tab, el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

function out.slice(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced + 1] = tbl[i]
    end

    return sliced
end

function out.copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return out
