local assets =
{
    Asset("ANIM", "anim/scorched_ground.zip"),
}

local anim_names_ground_fx =
{
    "idle",
}

for i = 2, 10 do
    table.insert(anim_names_ground_fx, "idle" .. tostring(i))
end

local function OnSave(inst, data)
    data.anim = inst.anim
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.anim ~= nil then
            inst.anim = data.anim
            inst.AnimState:PlayAnimation(inst.anim)
        end
    end
end

local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("scorched_ground")
    inst.AnimState:SetBank("scorched_ground")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.anim = GetRandomItem(anim_names_ground_fx)
    inst.AnimState:PlayAnimation(inst.anim)

    inst.Transform:SetRotation(math.random() * 360)

    inst:AddComponent("savedrotation")

    -- inst:AddComponent("timer")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("knightmare_clue_ground_fx", fxfn, assets)
