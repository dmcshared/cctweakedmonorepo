local strlib = {}

function strlib.split(s, delimiter)
    local result = {};
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match);
    end
    return result;
end

function strlib.chars(s)
    local chars = {}
    for i = 1, #s do
        table.insert(chars, s:sub(i, i))
    end
    return chars
end

return strlib
