local modimport = modimport

local postinit = {
    prefabs = {
        "daywalker",
        "dreadstonehat",
        "armordreadstone",
    },
    stategraphs = {
        "SGwilson",
        "SGwilson_client",
    },
}

for k, v in pairs(postinit) do
    for i = 1, #v do
        modimport("postinit/" .. k .. "/" .. postinit[k][i])
    end
end
