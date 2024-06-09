-- 我瞎几把写，你瞎几把看
local assets = {
    Asset("ANIM", "anim/dreadspear.zip"),
    -- Asset("ANIM", "anim/swap_dreadspear.zip")
}

local prefabs =
{
    "hitsparks_fx",
    "fx_dreadspear",
}


local function OnFinished(inst)
    inst:Remove()
end


local function SetFxOwner(inst, owner)
    if owner ~= nil then
        inst.blade1.entity:SetParent(owner.entity)
        inst.blade2.entity:SetParent(owner.entity)
        inst.blade1.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 3)
        inst.blade2.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 5, 8)
        inst.blade1.components.highlightchild:SetOwner(owner)
        inst.blade2.components.highlightchild:SetOwner(owner)
    else
        inst.blade1.entity:SetParent(inst.entity)
        inst.blade2.entity:SetParent(inst.entity)
        --通过以空图层覆盖，使用特效跟随来等效覆盖效果并更可控（其实不）
        inst.blade1.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 0, 3)--xyz偏移量？
        inst.blade2.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 5, 8)
        inst.blade1.components.highlightchild:SetOwner(inst)
        inst.blade2.components.highlightchild:SetOwner(inst)
    end
end

local function PushIdleLoop(inst)
    inst.AnimState:PushAnimation("idle")
end

local function OnStopFloating(inst)--回归帧
    inst.blade1.AnimState:SetFrame(0)
    inst.blade2.AnimState:SetFrame(0)
    inst:DoTaskInTime(0, PushIdleLoop)
end

local function GetSetBonusEquip(inst, owner)
    local inventory = owner.components.inventory
    local hat = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    local armor = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil
    return hat ~= nil and hat.prefab == "dreadstonehat" and hat
           or 
           armor ~= nil and armor.prefab == "armordreadstone" and armor
           or
           nil
end

local function OnEquip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_dreadspear", inst.GUID, "swap_dreadspear")
    else
        owner.AnimState:OverrideSymbol("swap_object", "dreadspear", "swap_dreadspear")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    SetFxOwner(inst, owner)

end

local function OnUnEquip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")


    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    SetFxOwner(inst, nil)
end

local function OnAttack(inst, attacker, target)
    if target ~= nil then
        if target ~= nil and target:IsValid() then
            local spark = SpawnPrefab("hitsparks_fx")
            spark:Setup(attacker, target, nil)
            spark.black:set(true)
        end
        end

        if attacker.components.sanity ~= nil and GetSetBonusEquip(inst, attacker) then
            local inventory = attacker.components.inventory
            local hat = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
            local armor = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil

            if hat ~= nil then
                hat.isonattack = true
            end

            if armor ~= nil then
                armor.isonattack = true
            end

            inst.isonattack = true
        end
    end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("dreadspear")
    inst.AnimState:SetBuild("dreadspear")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetSymbolLightOverride("dreadspear_fx", 1)--该方法可以针对图层设定光覆盖
    inst.AnimState:SetLightOverride(.0)--该方法对整个实体贴图设定光覆盖

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("dreadspear")
    inst:AddTag("shadowlevel")
    inst:AddTag("shadow_item")

    local swap_data = { sym_build = "dreadspear", sym_name = "dreadspear" }
    MakeInventoryFloatable(inst, "med", 0.05, { 0.75, 0.4, 0.75 }, true, -13, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local frame = 1
    inst.AnimState:SetFrame(frame)
    inst.blade1 = SpawnPrefab("fx_dreadspear")
    inst.blade2 = SpawnPrefab("fx_dreadspear")
    inst.blade2.AnimState:PlayAnimation("swap_loop2", true)
    inst.blade1.AnimState:SetFrame(frame)
    inst.blade2.AnimState:SetFrame(frame)
    SetFxOwner(inst, nil)
    inst:ListenForEvent("floater_stopfloating", OnStopFloating)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.DREADSPEAR.DAMAGE)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.DREADSPEAR.SHADOW_LEVEL)

    local damagetypebonus = inst:AddComponent("damagetypebonus")
    damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.WEAPONS_VOIDCLOTH_VS_LUNAR_BONUS)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.DREADSPEAR.USES)
    inst.components.finiteuses:SetUses(TUNING.DREADSPEAR.USES)
    inst.components.finiteuses:SetOnFinished(OnFinished)

    inst:AddComponent("equippable")
    inst.components.equippable.is_magic_dapperness = true
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnEquip)

    inst.isonattack = false

	MakeHauntableLaunch(inst)

    return inst
end

local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("dreadspear")
    inst.AnimState:SetBuild("dreadspear")
    inst.AnimState:PlayAnimation("swap_loop1", true)
    inst.AnimState:SetSymbolLightOverride("dreadspear_fx", 1)
    inst.AnimState:SetLightOverride(.0)

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("dreadspear", fn, assets, prefabs),
       Prefab("fx_dreadspear", fxfn, assets)
