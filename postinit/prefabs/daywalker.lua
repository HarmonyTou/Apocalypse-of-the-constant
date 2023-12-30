local AddSimPostInit = AddSimPostInit
GLOBAL.setfenv(1, GLOBAL)

local function postinitfn(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    local loots = LootTables["daywalker"]
    if loots then
        table.insert(loots, {"dreadsword_blueprint", 1})
    end
end

AddSimPostInit(postinitfn)
