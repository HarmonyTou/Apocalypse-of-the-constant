local function en_zh(en, zh)
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

name = en_zh("Apocalypse of the constant", "永恒启示录")
author = "The AOC Team"
description = ""

version = "1.6"
forumthread = "https://steamcommunity.com/sharedfiles/filedetails/?id=2995403395"
api_version = 10
api_version_dst = 10

dst_compatible = true
client_only_mod = false
all_clients_require_mod = true
priority = -1

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
    "Apocalypse of the constant",
}

local enable_option = {
    { description = en_zh("Enable", "开启"), data = true },
    { description = en_zh("Disable", "关闭"), data = false },
}

--配置项
configuration_options = {
    {
        name = "locale",
        label = en_zh("Translation", "翻译"),
        hover = en_zh("Select your translation.", "选择翻译"),
        options =
        {
            { description = "Auto", data = false },
            { description = "English", data = "en" },
            { description = "简体中文", data = "sc" },
        },
        default = false,
    },
    {
        name = "talking_sword",
        label = en_zh("Talking Sword", "会说话的剑"),
        hover = en_zh("Optional Talking sword", "开关"),
        options = enable_option,
        default = false,
    }
}
