local ENV = env
local MODROOT = MODROOT
local StringUtil = require("utils/stringutil")
GLOBAL.setfenv(1, GLOBAL)

local locale = dread_crafts_config.locale

local function MergeStringsToGLOBAL(strings, custom_field, no_override)
    StringUtil.merge_table(custom_field or STRINGS, strings, no_override)
end

local Languages = {
    -- en = "strings.pot",
    -- de = "german",  -- german
    -- es = "spanish",  -- spanish
    -- fr = "french",  -- french
    -- it = "italian",  -- italian
    -- ko = "korean",  -- korean
    -- pt = "portuguese_br",  -- portuguese and brazilian portuguese
    -- br = "portuguese_br",  -- brazilian portuguese
    -- pl = "polish",  -- polish
    -- ru = "russian",  -- russian
    zh = "chinese_s",  -- chinese
    chs = "chinese_s", -- chinese mod
    sc = "chinese_s", -- simple chinese
    tc = "chinese_t", -- simple chinese
    cht = "chinese_t",  -- simple chinese
}
local function MergeTranslationFromPO(base_path, override_lang)
    local _defaultlang = LanguageTranslator.defaultlang
    local lang = override_lang or _defaultlang
    if not Languages[lang] then return end
    local filepath = base_path.."/"..Languages[lang]..".po"
    if not resolvefilepath_soft(filepath) then
        print("Could not find a language file matching "..filepath.." in any of the search paths.")
        return
    end
    local temp_lang = lang.."_temp"
    LanguageTranslator:LoadPOFile(filepath, temp_lang)
    StringUtil.merge_table(LanguageTranslator.languages[lang], LanguageTranslator.languages[temp_lang])
    TranslateStringTable(STRINGS)
    LanguageTranslator.languages[temp_lang] = nil
    LanguageTranslator.defaultlang = _defaultlang
end

local characters = {
    "generic",  -- wilson
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
    CHARACTERS = {
        -- GENERIC = StringUtil.ImportStringsFile("generic", ENV),
        -- WILLOW = StringUtil.ImportStringsFile("willow", ENV),
        -- WOLFGANG = StringUtil.ImportStringsFile("wolfgang", ENV),
        -- WENDY = StringUtil.ImportStringsFile("wendy", ENV),
        -- WX78 = StringUtil.ImportStringsFile("wx78", ENV),
        -- WICKERBOTTOM = StringUtil.ImportStringsFile("wickerbottom", ENV),
        -- WOODIE = StringUtil.ImportStringsFile("woodie", ENV),
        -- WAXWELL = StringUtil.ImportStringsFile("waxwell", ENV),
        -- WATHGRITHR = StringUtil.ImportStringsFile("wathgrithr", ENV),
        -- WEBBER = StringUtil.ImportStringsFile("webber", ENV),
        -- WINONA = StringUtil.ImportStringsFile("winona", ENV),
        -- WARLY = StringUtil.ImportStringsFile("warly", ENV),
        -- WORTOX = StringUtil.ImportStringsFile("wortox", ENV),
        -- WORMWOOD = StringUtil.ImportStringsFile("wormwood", ENV),
        -- WURT = StringUtil.ImportStringsFile("wurt", ENV),
        -- WALTER = StringUtil.ImportStringsFile("walter", ENV),
        -- WANDA = StringUtil.ImportStringsFile("wanda", ENV),
    }
}

for _, v in pairs(characters) do
    strings.CHARACTERS[string.upper(v)] = StringUtil.ImportStringsFile(v, ENV)
end

for k, v in pairs(StringUtil) do
    print(k)
end

MergeStringsToGLOBAL(StringUtil.ImportStringsFile("common", ENV))
MergeStringsToGLOBAL(strings)
MergeTranslationFromPO(MODROOT.."scripts/languages", Languages[locale])
