local assets = {
	Asset("ANIM", "anim/dread_pickaxe.zip"),
	Asset("ANIM", "anim/swap_dread_pickaxe.zip")
}

local function OnEquip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_dread_pickaxe", inst.GUID, "swap_dread_pickaxe")
    else
        owner.AnimState:OverrideSymbol("swap_object", "swap_dread_pickaxe", "swap_dread_pickaxe")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
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
    --shadowlevel (from shadowlevel component) added to pristine state for optimization
	inst:AddTag("shadowlevel")
    inst:AddTag("shadow_item")

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

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.MINE, TUNING.DREAD_PICKAXE.EFFICIENCY)
	inst.components.tool:SetAction(ACTIONS.HAMMER, TUNING.DREAD_PICKAXE.EFFICIENCY)
    inst.components.tool:EnableToughWork(true)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.DREAD_PICKAXE.USES)
    inst.components.finiteuses:SetUses(TUNING.DREAD_PICKAXE.USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.MINE, TUNING.HAMMER_USES / TUNING.PICKAXE_USES)
	inst.components.finiteuses:SetConsumption(ACTIONS.HAMMER, 1)

    inst:AddComponent("equippable")
    inst.components.equippable.dapperness = TUNING.CRAZINESS_SMALL
    inst.components.equippable.is_magic_dapperness = true
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(TUNING.DREAD_PICKAXE.SHADOW_LEVEL)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("dread_pickaxe", fn, assets)
