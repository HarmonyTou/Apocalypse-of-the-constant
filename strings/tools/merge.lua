package.path = package.path .. ";../?.lua"
package.path = package.path .. ";".. "Q:/SteamLibrary/steamapps/common/Don't Starve Together/mods/Apocalypse-of-the-constant" .. "/?.lua"

require("fns")

local translator = python.eval("lua_translator")
local keys = require("describe")
local output_path = "../"
local file_prefix = "aoc_"
local output_potpath = "../../scripts/languages/"
local output_popath = output_potpath .. file_prefix
local po_path = "en"
local override = false

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

    -- -- sw character
    -- "walani",
    -- -- "wilbur",  -- monkey,no speech
    -- "woodlegs",

    -- -- hamlet character
    -- "wheeler",
    -- "wilba",
    -- "wagstaff",
    -- -- "warbucks"  -- discard

    -- dst_new_character
    "winona",
    "wortox",
    "wurt",
    "walter",
    "wanda",
}

local languages = {
    -- en = "strings.pot",
    -- de = "german",  -- german
    -- es = "spanish",  -- spanish
    -- fr = "french",  -- french
    -- it = "italian",  -- italian
    -- ko = "korean",  -- korean
    -- pt = "portuguese_br",  -- portuguese and brazilian portuguese
    -- pl = "polish",  -- polish
    -- ru = "russian",  -- russian
    ["zh-CN"] = "chinese_s",  -- chinese
    ["zh-TW"] = "chinese_t",  -- traditional chinese
    ["zh-Yue"] = "cantonese",  -- traditional chinese
}

local geted_strings = {}
local overed_indexs = {}
local invert_overed_indexs = {}
local data_strings = load_string(characters, output_path)  -- this mod old string
merge_table(geted_strings, data_strings)

local translates = {}
for language, file_name in pairs(languages) do
    translates[language] = {}
    merge_table(translates[language], load_pofile(output_popath .. file_name .. ".po"), true)  -- this mod old translate
end

data_strings = describe

local _data_strings = {}
for key, over_key in pairs(keys) do  -- get strings by key
    local key_strings = get_string(data_strings, key:upper(), over_key:upper())
    merge_table(_data_strings, key_strings, override)
end

if languages[po_path] then  -- if input other language, translat to en
    local __data_strings = deepcopy(_data_strings)
    local data_index = table_index_to_str(__data_strings, "STRINGS")  -- keep old language
    for msgctxt, msgstr in pairs(data_index) do
        data_index[msgctxt] = "msgstr \"" .. msgstr .. "\""
    end
    merge_table(translates[po_path], data_index, override)
    translate_table(_data_strings, function(str) return translator(str, po_path, "en") end)
end

for key, over_key in pairs(keys) do  -- get strings by key
    local key_strings = get_string(_data_strings, key:upper(), over_key:upper())
    if key:upper() ~= over_key:upper() then
        local overed_strings = get_string(_data_strings, key:upper())
        local overed_key_indexs = table_index_to_str(overed_strings, "STRINGS")
        local invert_overed_key_indexs = {}
        for msgctxt, msgstr in pairs(overed_key_indexs) do
            local over_str = string.gsub(msgctxt, key:upper(), over_key:upper())
            invert_overed_key_indexs[over_str] = msgctxt
        end
        merge_table(invert_overed_indexs, invert_overed_key_indexs, override)
        merge_table(overed_indexs, overed_key_indexs, override)
    end

    merge_table(geted_strings, key_strings, override)
end

local string_indexs = table_index_to_str(geted_strings, "STRINGS")
if not languages[po_path] and po_path ~= "en" then
    for l, file_name in pairs(languages) do
        merge_table(translates[l], load_pofile(po_path .. file_name .. ".po", string_indexs), override)  -- get translate
        merge_table(translates[l], load_pofile(po_path .. file_name .. ".po", overed_indexs), override)  -- get translate
    end
end

languages["en"] = "strings"
for l, file_name in pairs(languages) do
    -- write po file
    local package = ""

    -- head
    if l == "en" then
        package = package .. "\"Application: Dont' Starve\\n\"" .. "\n"
        package = package .. "\"POT Version: 2.0\\n\"" .. "\n\n"
    else
        package = package .. "msgid \"\"" .. "\n"
        package = package .. "msgstr \"\"" .. "\n"
        package = package .. "\"Language: " .. l .. "\\n\"" .. "\n"
        package = package .. "\"Content-Type: text/plain; charset=utf-8\\n\"" .. "\n"
        package = package .. "\"Content-Transfer-Encoding: 8bit\\n\"" .. "\n"
        package = package .. "\"POT Version: 2.0\"" .. "\n\n"
    end

    for msgctxt, msgid in pairs_by_keys(string_indexs) do
        if l ~= "en" and not translates[l][msgctxt] and not translates[l][invert_overed_indexs[msgctxt]] then  -- if not translate in po file, use Google Translate
            print("could not find", l, msgctxt, "use Google Translate")

            local soure = "en"
            local strs = msgid
            if l == "zh-TW" and translates["zh-CN"][msgctxt] then
                soure = "zh-CN"
                strs = string.gsub(translates["zh-CN"][msgctxt], "msgstr \"", "")
                strs = string.gsub(strs, "\"", "")
            end

            translates[l][msgctxt] = "msgstr \"" .. translator(strs, soure, l) .. "\""
        end

        local index_str = string.gsub(msgctxt, "msgctxt \"", "")
        index_str = string.gsub(index_str, "\"", "")

        package = package .. "#. " .. index_str  .. "\n"
        package = package .. msgctxt .. "\n"
        msgid = string.gsub(msgid, '"', '\\"')
        package = package .. "msgid " .. "\"" .. msgid .. "\"".. "\n"
        package = package .. (l == "en" and "msgstr \"\"" or translates[l][msgctxt] or translates[l][invert_overed_indexs[msgctxt]]) .. "\n\n"
    end

    local po_file_name = l == "en" and "strings.pot" or (file_prefix .. file_name .. ".po")
    local pl_file = io.open(output_potpath .. po_file_name, "w+")
    pl_file:write(package)
    pl_file:close()
end

local CHARACTERS = geted_strings.CHARACTERS
geted_strings.CHARACTERS = nil

-- write lua file
write_lua_table(output_path .. "common.lua", geted_strings)
for _, character in pairs(characters) do
    write_lua_table(output_path .. character .. ".lua", CHARACTERS[string.upper(character)])
end
