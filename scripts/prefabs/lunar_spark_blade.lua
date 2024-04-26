local assets =
{
    Asset("ANIM", "anim/spear.zip"),
    Asset("ANIM", "anim/swap_spear.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_spear", "swap_spear")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function OnChargeValChange(inst, old, new)
    if inst.components.dc_chargeable_item:GetPercent() >= 0.66 then
        inst._leap_range:set(1.9)
        inst.components.weapon:SetRange(10, 0)
    else
        inst._leap_range:set(0)
        inst.components.weapon:SetRange(0)
    end
end

local function OnAttack(inst, attacker, target)
    inst.components.dc_chargeable_item:DoDelta(1)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("spear")
    inst.AnimState:SetBuild("swap_spear")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.05, { 1.1, 0.5, 1.1 }, true, -9)

    -- Large than leap_range should leap
    inst._leap_range = net_float(inst.GUID, "inst._leap_range")
    inst._leap_range:set(0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("dc_chargeable_item")
    inst.components.dc_chargeable_item:SetMax(20)
    inst.components.dc_chargeable_item:SetDrainPerSecond(1)
    inst.components.dc_chargeable_item:SetResumeDrainCD(2)
    inst.components.dc_chargeable_item:SetOnValChangeFn(OnChargeValChange)
    inst.components.dc_chargeable_item:SetVal(0)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(34)
    -- inst.components.weapon:SetRange(10, 0)
    inst.components.weapon:SetRange(0)
    inst.components.weapon:SetOnAttack(OnAttack)
    -------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(500)
    inst.components.finiteuses:SetUses(500)

    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "spear"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("lunar_spark_blade", fn, assets)
