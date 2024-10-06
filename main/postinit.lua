local modimport = modimport

local postinit = {
    prefabs = {
        "cave",
        "daywalker",
        "dreadstonehat",
        "armordreadstone",
    },
    components = {
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
