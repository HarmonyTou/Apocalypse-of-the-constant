local function is_array(t)
    if type(t) ~= "table" or not next(t) then
        return false
    end

    local n = #t
    for i, v in pairs(t) do
        if type(i) ~= "number" or i <= 0 or i > n then
            return false
        end
    end

    return true
end

local function merge_table(target, add_table, override)
    target = target or {}

    for k, v in pairs(add_table) do
        if type(v) == "table" then
            if not target[k] then
                target[k] = {}
            elseif type(target[k]) ~= "table" then
                if override then
                    target[k] = {}
                else
                    error("Can not override" .. k .. " to a table")
                end
            end

            merge_table(target[k], v, override)
        else
            if is_array(target) and not override then
                table.insert(target, v)
            elseif not target[k] or override then
                target[k] = v
            end
        end
    end
end

local function ImportStringsFile(module_name, env)
    module_name = string.lower(module_name) .. ".lua"
    print("modimport (strings file): " .. env.MODROOT .. "strings/" .. module_name)
    local result = kleiloadlua(env.MODROOT .. "strings/" .. module_name)

    if result == nil then
        error("Error in custom import: Stringsfile " .. module_name .. " not found!")
    elseif type(result) == "string" then
        error("Error in custom import: Pork Land importing strings/" .. module_name .. "!\n" .. result)
    else
        setfenv(result, env) -- in case we use mod data
        return result()
    end
end

return {
    ImportStringsFile = ImportStringsFile,

    merge_table = merge_table,
    is_array = is_array,
}
