local AssetUtil = require("utils/assetutil")

--注册预制体
PrefabFiles = {
    "dreadsword",
    "dread_pickaxe",
    "dreadsword_wave",
    "dread_lantern",
    "lunar_spark_blade",
    "dread_cloak",
    "dread_axe",
}

Assets = {
    -- inventoryimages
    Asset("IMAGE", "images/dread_tools.tex"),
    Asset("ATLAS", "images/dread_tools.xml"),
    Asset("ATLAS_BUILD", "images/dread_tools.xml", 256), -- for minisign
}

AssetUtil.RegisterImageAtlas("images/dread_tools.xml")
