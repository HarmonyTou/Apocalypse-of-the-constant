if not GLOBAL.IsInFrontEnd() then return end
local modimport = modimport

PrefabFiles = {
    "aoc_skins",
}

Assets = {}

modimport("main/config")
modimport("main/strings")
modimport("main/prefabskin")
