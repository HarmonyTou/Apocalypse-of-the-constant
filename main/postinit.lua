local modimport = modimport

local postinit = {
    prefabs = {
        "daywalker",
        "dreadstonehat",
        "armordreadstone",
    },
    components = {
        "dc_chargeable_item",
        "projectile",
    },
    stategraphs = {
        "SGwilson",
        "SGwilson_client",
    },
    widgets = {
        "itemtile",
    },
}

for k, v in pairs(postinit) do
    for i = 1, #v do
        modimport("postinit/" .. k .. "/" .. postinit[k][i])
    end
end
