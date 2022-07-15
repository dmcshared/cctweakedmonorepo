return {
    write = function(path, data)
        local f = fs.open(path, "w")
        f.write(data)
        f.close()
    end,
    openIn = function(path, flags, lambda)
        local f = fs.open(path, flags)
        lambda(f)
        f.close()
    end
}
