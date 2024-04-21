local AddSimPostInit = AddSimPostInit


local function postinitfn(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    local loots = LootTables["daywalker"]
    if loots then
        table.insert(loots, { "dreadsword_blueprint", 1 })
    end
end

AddSimPostInit(postinitfn)
