local assets =
{
    Asset("ANIM", "anim/armor_wood.zip"),
    Asset("ANIM", "anim/swap_dread_cloak.zip"),
    Asset("ANIM", "anim/swap_dread_cloak2.zip"),
}

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function CheckSwapAnims(inst, owner_unequip)
    if inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner

        for k, v in pairs(inst.swap_anims) do
            v:Show()
            v.entity:SetParent(owner.entity)

            if v.components.highlightchild then
                v.components.highlightchild:SetOwner(owner)
            end

            if owner.components.colouradder ~= nil then
                owner.components.colouradder:AttachChild(v)
            end
        end


        inst.swap_anims.cloak_up.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 6, 9)
        -- inst.swap_anims.cloak_side.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 10)
        inst.swap_anims.cloak_down.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 9)

        local lut = {
            "armor_up_1",
            "armor_up_2",
            "armor_up_3",
            "armor_side_1",
            "armor_side_2",
            "armor_side_3",
        }

        for i, v in pairs(lut) do
            inst.swap_anims[v].Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, i - 1)
        end

        -- Static symbol, only contains up body anim
        owner.AnimState:OverrideSymbol("swap_body", "swap_dread_cloak2", "swap_body")
    else
        for k, v in pairs(inst.swap_anims) do
            v:Hide()
            v.entity:SetParent(inst.entity)

            v.Follower:FollowSymbol(inst.GUID, "swap_body", nil, nil, nil, true)

            if v.components.highlightchild then
                v.components.highlightchild:SetOwner(inst)
            end

            if owner_unequip and owner_unequip.components.colouradder ~= nil then
                owner_unequip.components.colouradder:DetachChild(v)
            end
        end

        if owner_unequip then
            owner_unequip.AnimState:ClearOverrideSymbol("swap_body")
        end
    end
end

local function onequip(inst, owner)
    CheckSwapAnims(inst)

    -- Anim fx
    -- inst.protect_fx = SpawnPrefab("spawnprotectionbuff")
    -- owner:AddChild(inst.protect_fx)

    -- Haunted light fx
    -- owner.AnimState:SetHaunted(true)


    inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function onunequip(inst, owner)
    CheckSwapAnims(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    -- if inst.protect_fx and inst.protect_fx:IsValid() then
    --     inst.protect_fx:Remove()
    -- end
    -- inst.protect_fx = nil
    -- owner.AnimState:SetHaunted(false)

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
    inst.components.armor:InitCondition(1000, 0.9)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.ARMOR or EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)


    -- Create swapanims
    inst.swap_anims = {
        cloak_up = inst:SpawnChild("dread_cloak_swapanim_cloak"),
        -- cloak_side = inst:SpawnChild("dread_cloak_swapanim_cloak"),
        cloak_down = inst:SpawnChild("dread_cloak_swapanim_cloak"),

        armor_up_1 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_up_2 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_up_3 = inst:SpawnChild("dread_cloak_swapanim_armor"),

        armor_side_1 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_side_2 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_side_3 = inst:SpawnChild("dread_cloak_swapanim_armor"),
    }

    for k, v in pairs(inst.swap_anims) do
        v.entity:AddFollower()
    end

    inst.swap_anims.cloak_up.AnimState:PlayAnimation("idle1", true)
    -- inst.swap_anims.cloak_side.AnimState:PlayAnimation("idle1", true)
    inst.swap_anims.cloak_down.AnimState:PlayAnimation("idle1", true)

    inst.swap_anims.armor_up_1.AnimState:PlayAnimation("idle1", true)
    inst.swap_anims.armor_up_2.AnimState:PlayAnimation("idle2", true)
    inst.swap_anims.armor_up_3.AnimState:PlayAnimation("idle3", true)

    inst.swap_anims.armor_side_1.AnimState:PlayAnimation("idle4", true)
    inst.swap_anims.armor_side_2.AnimState:PlayAnimation("idle5", true)
    inst.swap_anims.armor_side_3.AnimState:PlayAnimation("idle6", true)

    CheckSwapAnims(inst)

    return inst
end

local function cloak_animfn()
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

local function armor_animfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("swap_dread_cloak2")
    inst.AnimState:SetBuild("swap_dread_cloak2")

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("dread_cloak", fn, assets),
    Prefab("dread_cloak_swapanim_cloak", cloak_animfn, assets),
    Prefab("dread_cloak_swapanim_armor", armor_animfn, assets)
