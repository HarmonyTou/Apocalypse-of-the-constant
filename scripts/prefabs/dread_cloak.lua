local assets =
{
    Asset("ANIM", "anim/armor_wood.zip"),
    Asset("ANIM", "anim/swap_dread_cloak.zip"),
}

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function CheckSwapAnims(inst)
    if inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner

        inst.anim_up:Show()
        inst.anim_down:Show()
        inst.anim_side:Show()

        inst.anim_up.entity:SetParent(owner.entity)
        inst.anim_down.entity:SetParent(owner.entity)
        inst.anim_side.entity:SetParent(owner.entity)

        inst.anim_up.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 6, 9)
        inst.anim_down.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 9)
        inst.anim_side.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 10)

        inst.anim_up.components.highlightchild:SetOwner(owner)
        inst.anim_down.components.highlightchild:SetOwner(owner)
        inst.anim_side.components.highlightchild:SetOwner(owner)
        if owner.components.colouradder ~= nil then
            owner.components.colouradder:AttachChild(inst.anim_up)
            owner.components.colouradder:AttachChild(inst.anim_down)
            owner.components.colouradder:AttachChild(inst.anim_side)
        end
    else
        inst.anim_up:Hide()
        inst.anim_down:Hide()
        inst.anim_side:Hide()

        inst.anim_up.entity:SetParent(inst.entity)
        inst.anim_down.entity:SetParent(inst.entity)
        inst.anim_side.entity:SetParent(inst.entity)

        inst.anim_up.Follower:FollowSymbol(inst.GUID, "swap_body", nil, nil, nil, true)
        inst.anim_down.Follower:FollowSymbol(inst.GUID, "swap_body", nil, nil, nil, true)
        inst.anim_side.Follower:FollowSymbol(inst.GUID, "swap_body", nil, nil, nil, true)

        inst.anim_up.components.highlightchild:SetOwner(inst)
        inst.anim_down.components.highlightchild:SetOwner(inst)
        inst.anim_side.components.highlightchild:SetOwner(inst)
    end
end

local function onequip(inst, owner)
    CheckSwapAnims(inst)
    inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function onunequip(inst, owner)
    CheckSwapAnims(inst)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)
end



local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("armor_wood")
    inst.AnimState:SetBuild("armor_wood")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    local swap_data = { bank = "armor_wood", anim = "anim" }
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "armorwood"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMORWOOD, TUNING.ARMORWOOD_ABSORPTION)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.ARMOR or EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)


    -- Create swapanims
    inst.anim_up = inst:SpawnChild("dread_cloak_swapanim")
    inst.anim_up.AnimState:PlayAnimation("idle1", true)
    inst.anim_up.entity:AddFollower()

    inst.anim_down = inst:SpawnChild("dread_cloak_swapanim")
    inst.anim_down.AnimState:PlayAnimation("idle1", true)
    inst.anim_down.entity:AddFollower()


    inst.anim_side = inst:SpawnChild("dread_cloak_swapanim")
    inst.anim_side.AnimState:PlayAnimation("idle4", true)
    inst.anim_side.entity:AddFollower()


    CheckSwapAnims(inst)

    return inst
end

local function animfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("swap_dread_cloak")
    inst.AnimState:SetBuild("swap_dread_cloak")

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("dread_cloak", fn, assets),
    Prefab("dread_cloak_swapanim", animfn, assets)
