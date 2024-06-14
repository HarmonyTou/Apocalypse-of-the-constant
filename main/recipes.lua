local AddRecipe2 = AddRecipe2
-- GLOBAL.setfenv(1, GLOBAL)

local function SortRecipe(a, b, filter_name, offset)
    local filter = CRAFTING_FILTERS[filter_name]
    if filter and filter.recipes then
        for sortvalue, product in ipairs(filter.recipes) do
            if product == a then
                table.remove(filter.recipes, sortvalue)
                break
            end
        end

        local target_position = #filter.recipes + 1
        for sortvalue, product in ipairs(filter.recipes) do
            if product == b then
                target_position = sortvalue + offset
                break
            end
        end

        table.insert(filter.recipes, target_position, a)
    end
end

local function SortBefore(a, b, filter_name)
    SortRecipe(a, b, filter_name, 0)
end

local function SortAfter(a, b, filter_name)
    SortRecipe(a, b, filter_name, 1)
end

-- 制作所需要的材料
AddRecipe2("dreadspear", { Ingredient("twigs", 2), Ingredient("rope", 1), Ingredient("dreadstone", 1) }, TECH.LOST,
    { nounlock = false }, { "MAGIC", "WEAPONS" })
SortAfter("dreadspear", "nightsword", "MAGIC")
SortAfter("dreadspear", "nightsword", "WEAPONS")

AddRecipe2("dreadsword", { Ingredient("dreadstone", 4), Ingredient("horrorfuel", 4), Ingredient("voidcloth", 1) },
    TECH.LOST, { nounlock = false }, { "MAGIC", "WEAPONS" })
SortAfter("dreadsword", "nightsword", "MAGIC")
SortAfter("dreadsword", "nightsword", "WEAPONS")

AddRecipe2("dread_pickaxe", { Ingredient("dreadstone", 4), Ingredient("horrorfuel", 4), Ingredient("voidcloth", 2) },
    TECH.SHADOWFORGING_TWO, { nounlock = true, station_tag = "shadow_forge" }, { "CRAFTING_STATION" })
SortAfter("dread_pickaxe", "voidcloth_scythe", "CRAFTING_STATION")

AddRecipe2("dread_axe", { Ingredient("dreadstone", 5), Ingredient("horrorfuel", 5), Ingredient("voidcloth", 2) },
    TECH.SHADOWFORGING_TWO, { nounlock = true, station_tag = "shadow_forge" }, { "CRAFTING_STATION" })

AddRecipe2("lunar_spark_blade",
    { Ingredient("security_pulse_cage_full", 1), Ingredient("moonglass_charged", 3), Ingredient("purebrilliance", 4),
        Ingredient("moonrocknugget", 3) }, TECH.LUNARFORGING_TWO, { nounlock = true, station_tag = "lunar_forge" },
    { "CRAFTING_STATION" })
SortBefore("lunar_spark_blade", "beargerfur_sack", "CRAFTING_STATION")
