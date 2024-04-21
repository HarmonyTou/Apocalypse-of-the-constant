local modimport = modimport


local prefabs_postinit = {
    "daywalker",
    "dreadstonehat",
    "armordreadstone",
}

local stategraph_postinit = {
    "wilson",
    "wilson_client"
}

for _, v in pairs(prefabs_postinit) do
    modimport("postinit/prefabs/" .. v)
end

for _, v in pairs(stategraph_postinit) do
    modimport("postinit/stategraphs/SG" .. v)
end
