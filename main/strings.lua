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

MergeStringsToGLOBAL(StringUtil.ImportStringsFile("common", ENV))
MergeStringsToGLOBAL(strings)
StringUtil.MergeTranslationFromPO(MODROOT .. "scripts/languages", aoc_config.locale)
