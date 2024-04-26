local assets =
{
    Asset("ANIM", "anim/spear.zip"),
    Asset("ANIM", "anim/swap_spear.zip"),
    Asset("ANIM", "anim/lunar_spark_blade.zip"),
}

local function CheckSwapAnims(inst, owneroverride)
    local owner = owneroverride or inst.components.inventoryitem.owner
    if owner and inst.components.equippable:IsEquipped() then
        for _, v in pairs(inst.anim_fxs) do
            v:Show()
            v.entity:SetParent(owner.entity)
            v.components.highlightchild:SetOwner(owner)
            if owner.components.colouradder ~= nil then
                owner.components.colouradder:AttachChild(v)
            end
        end

        inst.anim_fxs[1].Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 3)
        inst.anim_fxs[2].Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 5, 8)
    else
        for _, v in pairs(inst.anim_fxs) do
            v:Hide()
            v.entity:SetParent(inst.entity)
            v.Follower:FollowSymbol(inst.GUID, "lunar_spark_blade", nil, nil, nil, true)
            v.components.highlightchild:SetOwner(inst)
            if owner then
                if owner.components.colouradder ~= nil then
                    owner.components.colouradder:DetachChild(v)
                end
            end
        end
    end
end

local function onequip(inst, owner)
    -- owner.AnimState:OverrideSymbol("swap_object", "swap_spear", "swap_spear")
    owner.AnimState:ClearOverrideSymbol("swap_object")
    CheckSwapAnims(inst)

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    CheckSwapAnims(inst)

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function OnChargeValChange(inst, old, new)
    if inst.components.dc_chargeable_item:GetPercent() >= 0.66 then
        inst._leap_range:set(1.9)
        inst.components.weapon:SetRange(10, 0)
    else
        inst._leap_range:set(-1)
        inst.components.weapon:SetRange(0)
    end
end

local function OnAttack(inst, attacker, target)
    inst.components.dc_chargeable_item:DoDelta(1)
    if attacker and target and attacker.sg and attacker.sg.currentstate.name == "lunar_spark_blade_leap" then
        local delta_vec = (target:GetPosition() - attacker:GetPosition()):GetNormalized()
        local fx = SpawnAt("moonstorm_ground_lightning_fx", attacker:GetPosition() + delta_vec * 3)
        fx.Transform:SetRotation(attacker.Transform:GetRotation() - 90)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("lunar_spark_blade")
    inst.AnimState:SetBuild("lunar_spark_blade")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.05, { 1.1, 0.5, 1.1 }, true, -9)

    -- if _leap_range > 0 and larger than leap_range should leap
    inst._leap_range = net_float(inst.GUID, "inst._leap_range")
    inst._leap_range:set(-1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.anim_fxs = {
        inst:SpawnChild("lunar_spark_blade_swapanim"),
        inst:SpawnChild("lunar_spark_blade_swapanim")
    }
    inst.anim_fxs[1].AnimState:PlayAnimation("swap_loop1", true)
    inst.anim_fxs[2].AnimState:PlayAnimation("swap_loop2", true)
    for _, v in pairs(inst.anim_fxs) do
        v.entity:AddFollower()
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(34)
    -- inst.components.weapon:SetRange(10, 0)
    inst.components.weapon:SetRange(0)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("dc_chargeable_item")
    inst.components.dc_chargeable_item:SetMax(20)
    inst.components.dc_chargeable_item:SetDrainPerSecond(1)
    inst.components.dc_chargeable_item:SetResumeDrainCD(2)
    inst.components.dc_chargeable_item:SetOnValChangeFn(OnChargeValChange)
    inst.components.dc_chargeable_item:SetVal(0)

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
    CheckSwapAnims(inst)

    return inst
end

local function animfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lunar_spark_blade")
    inst.AnimState:SetBuild("lunar_spark_blade")

    inst.AnimState:SetSymbolLightOverride("glow", 1)
    inst.AnimState:SetSymbolMultColour("glow", 1, 1, 1, 0.5)

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("lunar_spark_blade", fn, assets),
    Prefab("lunar_spark_blade_swapanim", animfn, assets)
