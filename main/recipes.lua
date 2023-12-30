local AddRecipe2 = AddRecipe2
GLOBAL.setfenv(1, GLOBAL)
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
local dreadsword_ingredients = {Ingredient("dreadstone", 4), Ingredient("horrorfuel", 4)}

if dread_crafts_config.include_voidcloth and dread_crafts_config.dreadsword_enable then
    table.insert(dreadsword_ingredients, Ingredient("voidcloth", 1))
end

if dread_crafts_config.dreadsword_enable then
    AddRecipe2("dreadsword", dreadsword_ingredients, TECH.LOST, {nounlock = false}, {"MAGIC", "WEAPONS"})
    SortBefore("dreadsword", "nightsword", "MAGIC")
    SortAfter("dreadsword", "nightstick", "WEAPONS")
end

local dread_pickaxe_ingredients = {Ingredient("dreadstone", 4), Ingredient("horrorfuel", 4)}

if dread_crafts_config.include_voidcloth and dread_crafts_config.dread_pickaxe_enable then
    table.insert(dread_pickaxe_ingredients, Ingredient("voidcloth", 2))
end

if dread_crafts_config.dread_pickaxe_enable then
    AddRecipe2("dread_pickaxe", dread_pickaxe_ingredients, TECH.SHADOWFORGING_TWO, {station_tag = "shadow_forge"}, {"TOOLS"})
end


