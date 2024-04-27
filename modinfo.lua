local function en_zh(en, zh)
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end
name = en_zh("Dread Crafts", "绝望工艺")
author = "The Dread Crafts Team"
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
    "Dread Crafts",
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
            { description = "English", data = "en" },
            { description = "简体中文", data = "sc" },
        },
        default = en_zh("en", "sc"),
    },
    {
        name = "include_voidcloth",
        label = en_zh("Choose to include Voidcloth", "自定义配方"),
        hover = en_zh("Toggle on for Voidcloth use", "是否加入碎布"),
        options = enable_option,
        default = true,
    },
    {
        name = "dreadsword_enable",
        label = en_zh("Dread Sword", "绝望剑"),
        hover = en_zh("Optional dreadsword", "物品开关"),
        options = enable_option,
        default = true,
    },
    {
        name = "dread_pickaxe_enable",
        label = en_zh("Dread Pickaxe", "绝望稿"),
        hover = en_zh("Optional dreadpickaxe", "物品开关"),
        options = enable_option,
        default = true,
    },
    {
        name = "talking_sword",
        label = en_zh("Talking Sword", "会说话的剑"),
        hover = en_zh("Optional Talking sword", "开关"),
        options = enable_option,
        default = false,
    }
}
