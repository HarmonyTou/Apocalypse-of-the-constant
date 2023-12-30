--注册预制体
PrefabFiles = {
	"dreadsword",
    "dread_pickaxe",
    "dreadcraft_skins"
}

Assets = {
    -- inventoryimages
    Asset("IMAGE", "images/dread_tools.tex"),
    Asset("ATLAS", "images/dread_tools.xml"),
    Asset("ATLAS_BUILD", "images/dread_tools.xml", 256),  -- for minisign
}

Util.RegisterInventoryItemAtlas("images/dread_tools.xml")
