local assets = {
    Asset("ANIM", "anim/dreadsword.zip"),
    Asset("ANIM", "anim/swap_dreadsword.zip")
}

local fx_assets = {
    Asset("ANIM", "anim/dreadsword.zip"),
    Asset("ANIM", "anim/night_edge.zip"),
}

local prefabs =
{
    "hitsparks_fx",
    "dreadsword_fx",
}


local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_dreadstone")
end

local function SetFxOwner(inst, owner)
    if owner ~= nil then
        inst.blade1.entity:SetParent(owner.entity)
        inst.blade2.entity:SetParent(owner.entity)
        inst.blade1.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 0)
        inst.blade2.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 5, 8)
        inst.blade1.components.highlightchild:SetOwner(owner)
        inst.blade2.components.highlightchild:SetOwner(owner)
    else
        inst.blade1.entity:SetParent(inst.entity)
        inst.blade2.entity:SetParent(inst.entity)
        inst.blade1.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 0, 0)
        inst.blade2.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 5, 8)
        inst.blade1.components.highlightchild:SetOwner(inst)
        inst.blade2.components.highlightchild:SetOwner(inst)
    end
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "dreadsword", "swap_dreadsword")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    SetFxOwner(inst, owner)

    inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function OnUnEquip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst:RemoveEventCallback("blocked", OnBlocked, owner)

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    SetFxOwner(inst, nil)
end


local function commonfn(common_postinit, master_postinit)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("dreadsword")
    inst.AnimState:SetBuild("dreadsword")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetSymbolBloom("dreadsword_fx")
    inst.AnimState:SetSymbolLightOverride("dreadsword_fx", .6)
    inst.AnimState:SetLightOverride(.1)

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("shadowlevel")
    inst:AddTag("shadow_item")

    common_postinit(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local frame = 1
    inst.AnimState:SetFrame(frame)
    inst.blade1 = SpawnPrefab("dreadsword_fx")
    inst.blade2 = SpawnPrefab("dreadsword_fx")
    inst.blade2.AnimState:PlayAnimation("swap_loop2", true)
    inst.blade1.AnimState:SetFrame(frame)
    inst.blade2.AnimState:SetFrame(frame)
    SetFxOwner(inst, nil)

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnEquip)

    inst:AddComponent("weapon")
    master_postinit(inst)

    return inst
end

local function nightmare_common_postinit(inst)
	inst:AddTag("nosteal")
end

local function nightmare_master_postinit (inst)
	inst.persists = false
    inst.components.weapon:SetDamage(75)
    inst.components.inventoryitem:SetOnDroppedFn(inst.Remove)

    inst:AddComponent("parryweapon")
    inst.components.parryweapon:SetParryArc(178)
end


local function nightmarefn()
    return commonfn(nightmare_common_postinit,nightmare_master_postinit)
end


local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("dreadsword")
    inst.AnimState:SetBuild("dreadsword")
    inst.AnimState:PlayAnimation("swap_loop1", true)
    inst.AnimState:SetSymbolBloom("dreadsword_fx")
    inst.AnimState:SetSymbolLightOverride("dreadsword_fx", 1.5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("knightmare_npc_sword", nightmarefn, assets, prefabs),
    Prefab("dreadsword_fx", fxfn, fx_assets)
