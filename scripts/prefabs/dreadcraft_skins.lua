local prefs = {}

table.insert(prefs, CreatPrefabSkin("night_edge",
{
    base_prefab = "dreadsword",
    type = "item",
	rarity = "Elegant",
    init_fn = function(inst) dreadsword_init_fn(inst, "night_edge") end,
	skin_tags = { "DREADSWORD", "CRAFTABLE", },
}
))

return unpack(prefs)