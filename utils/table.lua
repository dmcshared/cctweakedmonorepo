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

function out.filter(t, fnKeep)
    local j, n = 1, #t;
    local removed = {}
    for i = 1, n do
        print('i:' .. i, 'j:' .. j);
        if (fnKeep(t[i])) then
            if (i ~= j) then
                print('keeping:' .. i, 'moving to:' .. j);
                -- Keep i's value, move it to j's pos.
                t[j] = t[i];
                t[i] = nil;
            else
                -- Keep i's value, already at j's pos.
                print('keeping:' .. i, 'already at:' .. j);
            end
            j = j + 1;
        else
            table.insert(removed, t[i]);
            t[i] = nil;
        end
    end
    return t, removed;
end

function out.set(keys)
    local out = {}
    for _, key in pairs(keys) do
        out[key] = true
    end
    return out
end

return out
