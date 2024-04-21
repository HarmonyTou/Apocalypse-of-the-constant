local function GetUpvalue(fn, name, recurse_levels)
    assert(type(fn) == "function")

    recurse_levels = recurse_levels or 0
    local source_fn = fn
    local i = 1

    while true do
        local _name, value = debug.getupvalue(fn, i)
        if _name == nil then
            return
        elseif _name == name then
            return value, i, source_fn
        elseif type(value) == "function" and recurse_levels > 0 then
            local _value, _i, _source_fn = GetUpvalue(value, name, recurse_levels - 1)
            if _value ~= nil then
                return _value, _i, _source_fn
            end
        end

        i = i + 1
    end
end

local function SetUpvalue(fn, value, name, recurse_levels)
    local _, i, source_fn = GetUpvalue(fn, name, recurse_levels)
    if source_fn and i and value then
        debug.setupvalue(source_fn, i, value)
    end
end

return {
    GetUpvalue = GetUpvalue,
    SetUpvalue = SetUpvalue,
}