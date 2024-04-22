local prefs = {}

table.insert(prefs, CreatePrefabSkin("night_edge", {
    base_prefab = "dreadsword",
    type = "item",
	rarity = "Elegant",
    assets = {
        Asset("DYNAMIC_ANIM", "anim/dynamic/night_edge.zip"),
        Asset("PKGREF", "anim/dynamic/night_edge.dyn"),
    },
    init_fn = function(inst)
        dreadsword_init_fn(inst, "night_edge")
    end,
	skin_tags = { "DREADSWORD", "CRAFTABLE", },
}))

return unpack(prefs)
