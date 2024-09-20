local ENV = env
local MODROOT = MODROOT
local StringUtil = require("utils/stringutil")
GLOBAL.setfenv(1, GLOBAL)

local characters = {
    "generic", -- wilson
    "willow",
    "wolfgang",
    "wendy",
    "wx78",
    "wickerbottom",
    "woodie",
    -- "wes",
    "waxwell",
    "wathgrithr",
    "webber",
    "wormwood",
    "warly",
    "winona",
    "wortox",
    "wurt",
    "walter",
    "wanda",
}

local strings = {
    CHARACTERS = {}
}

for _, v in pairs(characters) do
    strings.CHARACTERS[string.upper(v)] = StringUtil.ImportStringsFile(v, ENV)
end

local function MergeStringsToGLOBAL(strings, custom_field, no_override)
    StringUtil.merge_table(custom_field or STRINGS, strings, no_override)
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
    StringUtil.merge_table(LanguageTranslator.languages[lang], LanguageTranslator.languages[temp_lang])
    TranslateStringTable(STRINGS)
    LanguageTranslator.languages[temp_lang] = nil
    LanguageTranslator.defaultlang = _defaultlang
end

MergeStringsToGLOBAL(StringUtil.ImportStringsFile("common", ENV))
MergeStringsToGLOBAL(strings)
MergeTranslationFromPO(MODROOT .. "scripts/languages", aoc_config.locale)
