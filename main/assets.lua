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
    "aoc_skins",
}

Assets = {
    -- inventoryimages
    Asset("IMAGE", "images/apocalypse-of-the-constant.tex"),
    Asset("ATLAS", "images/apocalypse-of-the-constant.xml"),
    Asset("ATLAS_BUILD", "images/apocalypse-of-the-constant.xml", 256), -- for minisign
}

AssetUtil.RegisterImageAtlas("images/apocalypse-of-the-constant.xml")
