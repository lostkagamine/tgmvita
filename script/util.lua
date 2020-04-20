function deepcopy(orig) -- thanks lua-users
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function tableindex(t, el)
    for i, j in ipairs(t) do
        if j == el then return i end
    end
    return -1
end

function ternary(c, t, f)
    if c then return t else return f end
end

function padstart(s, c, chr)
    local o = s
    while #o < c do
        o = chr .. o
    end
    return o
end