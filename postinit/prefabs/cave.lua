local AddPrefabPostInit = AddPrefabPostInit
local UpvalueUtil = require("utils/upvalueutil")
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("cave", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("dc_knightmare_spawner")
end)
