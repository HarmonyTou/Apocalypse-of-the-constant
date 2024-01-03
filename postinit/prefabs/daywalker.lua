local AddSimPostInit = AddSimPostInit
GLOBAL.setfenv(1, GLOBAL)

local function postinitfn(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    local daywalker_loots = LootTables["daywalker"]
    if daywalker_loots ～= nil then
        table.insert(daywalker_loots, {"dreadsword_blueprint", 1})
    end
end

AddSimPostInit(postinitfn)
