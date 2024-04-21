local AddSimPostInit = AddSimPostInit
GLOBAL.setfenv(1, GLOBAL)

local function postinitfn()
    local daywalker_loots = LootTables["daywalker"]
    if daywalker_loots then
        table.insert(daywalker_loots, { "dreadsword_blueprint", 1 })
    end
end

AddSimPostInit(postinitfn)
