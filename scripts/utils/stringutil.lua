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

local Languages = {
    zh = "chinese_s", -- Simplified Chinese
    zht = "chinese_t", -- Traditional Chinese
    chs = "chinese_s",
    cht = "chinese_t",
    sc = "chinese_s",
    cant = "cantonese",
}
local function MergeTranslationFromPO(base_path, override_lang)
    local _defaultlang = LanguageTranslator.defaultlang
    local lang = override_lang or _defaultlang
    print("Loading language file " .. tostring(Languages[lang]))
    if not Languages[lang] then return end
    local filepath = base_path .. "/aoc_" .. Languages[lang] .. ".po"
    if not resolvefilepath_soft(filepath) then
        print("Could not find a language file matching " .. filepath .. " in any of the search paths.")
        return
    end
    local temp_lang = lang .. "_temp"
    LanguageTranslator:LoadPOFile(filepath, temp_lang)
    merge_table(LanguageTranslator.languages[lang], LanguageTranslator.languages[temp_lang])
    TranslateStringTable(STRINGS)
    LanguageTranslator.languages[temp_lang] = nil
    LanguageTranslator.defaultlang = _defaultlang
end

local function MergeStringsToGLOBAL(strings, custom_field, no_override)
    merge_table(custom_field or STRINGS, strings, no_override)
end

return {
    ImportStringsFile = ImportStringsFile,
    MergeTranslationFromPO = MergeTranslationFromPO,
    MergeStringsToGLOBAL = MergeStringsToGLOBAL,
    merge_table = merge_table,
    is_array = is_array,
}
