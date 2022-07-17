local rand = {}

function rand.sample(arr)
    return arr[math.random(#arr)]
end

function rand.randString(length, dict)
    length = length or 16
    dict = utils.strlib.chars(dict or "ABCDEF0123456789")

    local out = ""
    for i = 1, length do
        out = out .. rand.sample(dict)
    end

    return out
end

return rand
