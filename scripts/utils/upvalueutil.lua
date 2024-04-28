---@param fn function
---@param name string
---@return any, number | nil
local function get_upvalue(fn, name)
    local i = 1
    while true do
        local value_name, value = debug.getupvalue(fn, i)
        if value_name == name then
            return value, i
        elseif value_name == nil then
            return
        end
        i = i + 1
    end
end

---@param fn function
---@param path string
---@return any, number, function
local function GetUpvalue(fn, path)
    local value, prv, i = fn, nil, nil ---@type any function | nil, number | nil
    for part in path:gmatch("[^%.]+") do
        print(part)
        prv = fn
        value, i = get_upvalue(value, part)
        assert(i ~= nil, "could't find " .. path .. " from: ", fn)
    end
    return value, i, prv
end

---@param fn function
---@param path string
---@param value any
local function SetUpvalue(fn, value, path)
    local _, i, source_fn = GetUpvalue(fn, path)
    debug.setupvalue(source_fn, i, value)
end

return {
    GetUpvalue = GetUpvalue,
    SetUpvalue = SetUpvalue,
}
