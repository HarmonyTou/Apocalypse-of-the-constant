local assets = {
	Asset("ANIM", "anim/dread_pickaxe.zip"),
	Asset("ANIM", "anim/swap_dread_pickaxe.zip")
}

local function DoRegen(inst, owner)
    if owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode() and not (inst.components.finiteuses:GetPercent() == 1)  then
        local setbonus = inst.components.setbonus ~= nil and inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.DREADSTONE) and TUNING.DREAD_PICKAXE.REGEN_SETBONUS or 1
        local rate = 1 / Lerp(1 / TUNING.DREAD_PICKAXE.REGEN_MAXRATE, 1 / TUNING.DREAD_PICKAXE.REGEN_MINRATE, owner.components.sanity:GetPercent())
        inst.components.finiteuses:Repair(inst.components.finiteuses.total * rate * setbonus)
    end
end

local function StartRegen(inst, owner)
    if inst.regentask == nil then
        inst.regentask = inst:DoPeriodicTask(TUNING.DREAD_PICKAXE.REGEN_PERIOD, DoRegen, nil, owner)
    end
end

local function StopRegen(inst)
    if inst.regentask ~= nil then
        inst.regentask:Cancel()
        inst.regentask = nil
    end
end

local function OnEquip(inst, owner)
    if not owner:HasTag("toughworker") then
        owner:AddTag("toughworker")
    end

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_dread_pickaxe", inst.GUID, "swap_dread_pickaxe")
    else
        owner.AnimState:OverrideSymbol("swap_object", "swap_dread_pickaxe", "swap_dread_pickaxe")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if owner.components.sanity ~= nil then
        StartRegen(inst, owner)
    else
        StopRegen(inst)
    end
end

local function OnUnequip(inst, owner)
    if owner:HasTag("toughworker") then
        owner:RemoveTag("toughworker")
    end

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    StopRegen(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("dread_pickaxe")
    inst.AnimState:SetBuild("dread_pickaxe")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    --tool (from tool component) added to pristine state for optimization
    inst:AddTag("tool")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    inst:AddTag("dread_pickaxe")

    MakeInventoryFloatable(inst, "med", 0.05, {0.75, 0.4, 0.75})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.DREAD_PICKAXE.DAMAGE)

	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.DREAD_PICKAXE.PLANAR_DAMAGE)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.DREADSTONE)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.MINE, TUNING.DREAD_PICKAXE.EFFICIENCY)
	inst.components.tool:SetAction(ACTIONS.HAMMER, TUNING.DREAD_PICKAXE.EFFICIENCY)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.DREAD_PICKAXE.USES)
    inst.components.finiteuses:SetUses(TUNING.DREAD_PICKAXE.USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.MINE, TUNING.HAMMER_USES / TUNING.PICKAXE_USES)
	inst.components.finiteuses:SetConsumption(ACTIONS.HAMMER, 1)

    inst:AddComponent("equippable")
    inst.components.equippable.dapperness = TUNING.CRAZINESS_SMALL
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("dread_pickaxe", fn, assets)
