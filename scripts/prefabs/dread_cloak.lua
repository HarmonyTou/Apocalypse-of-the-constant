local assets =
{
    Asset("ANIM", "anim/swap_dread_cloak.zip"),
    Asset("ANIM", "anim/swap_dread_cloak2.zip"),
}

local function DoRegen(inst, owner)
    if owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode() then
        local setbonus = inst.components.setbonus ~= nil and
            inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.DREADSTONE) and TUNING.ARMOR_DREADSTONE_REGEN_SETBONUS or
            1 -- Cassielu: need constant for new EQUIPMENTSETNAMES?
        local rate = 1 /
            Lerp(1 / TUNING.ARMOR_DREADSTONE_REGEN_MAXRATE, 1 / TUNING.ARMOR_DREADSTONE_REGEN_MINRATE,
                owner.components.sanity:GetPercent())
        if inst.isonattack then
            rate = rate * 4
        end
        inst.components.armor:Repair(inst.components.armor.maxcondition * rate * setbonus)
    end

    if inst.isonattack then
        inst.task = inst:DoPeriodicTask(TUNING.ARMOR_DREADSTONE_REGEN_PERIOD, function()
            inst.isonattack = false
            if inst.task then
                inst.task:Cancel()
                inst.task = nil
            end
        end)
    end

    if not inst.components.armor:IsDamaged() then
        inst.regentask:Cancel()
        inst.regentask = nil
    end
end

local function StartRegen(inst, owner)
    if inst.regentask == nil then
        inst.regentask = inst:DoPeriodicTask(TUNING.ARMOR_DREADSTONE_REGEN_PERIOD, DoRegen, nil, owner)
    end
end

local function StopRegen(inst)
    if inst.regentask ~= nil then
        inst.regentask:Cancel()
        inst.regentask = nil
    end

    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function InSetBonusEnabled(inst)
    inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.KNIGHTMARESET.SETBONUS_SHADOW_RESIST,
        "setbonus")
end

local function OnSetBonusDisabled(inst)
    inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "setbonus")
end

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_dreadstone")
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

        inst.swap_anims.cloak_down.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 9)
        inst.swap_anims.cloak_side.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 3, 6)

        local lut = {
            "armor_down_1",
            "armor_down_2",
            "armor_down_3",

            "armor_side_1",
            "armor_side_2",
            "armor_side_3",

            "armor_up_1",
            "armor_up_2",
            "armor_up_3",
        }

        for i, v in pairs(lut) do
            inst.swap_anims[v].Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, i - 1)
        end

        inst.swap_anims.cloak_up.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 6, 9)


        -- Static symbol, only contains up body anim
        -- owner.AnimState:OverrideSymbol("swap_body", "swap_dread_cloak2", "swap_body")

        inst.swap_anims.cloak_up:TrackOwner(owner)
        inst.swap_anims.cloak_side:TrackOwner(owner)
        inst.swap_anims.cloak_down:TrackOwner(owner)
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

        inst.swap_anims.cloak_up:StopTrackingOwner()
        inst.swap_anims.cloak_side:StopTrackingOwner()
        inst.swap_anims.cloak_down:StopTrackingOwner()
    end
end

local function onequip(inst, owner)
    CheckSwapAnims(inst)

    -- Anim fx
    -- inst.protect_fx = SpawnPrefab("spawnprotectionbuff")
    -- owner:AddChild(inst.protect_fx)

    -- Haunted light fx
    -- owner.AnimState:SetHaunted(true)

    if owner.components.sanity ~= nil and inst.components.armor:IsDamaged() then
        StartRegen(inst, owner)
    else
        StopRegen(inst)
    end
end

local function onunequip(inst, owner)
    CheckSwapAnims(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    -- if inst.protect_fx and inst.protect_fx:IsValid() then
    --     inst.protect_fx:Remove()
    -- end
    -- inst.protect_fx = nil
    -- owner.AnimState:SetHaunted(false)

    StopRegen(inst)
end

local function OnTakeDamage(inst, amount)
    if inst.regentask == nil and inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil and owner.components.sanity ~= nil then
            StartRegen(inst, owner)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("swap_dread_cloak2")
    inst.AnimState:SetBuild("swap_dread_cloak2")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    local swap_data = { bank = "swap_dread_cloak2", anim = "anim" }
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --shadowlevel (from shadowlevel component) added to pristine state for optimization
    inst:AddTag("shadowlevel")
    inst:AddTag("shadow_item")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "armor_nightmare"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMORDREADSTONE, TUNING.KNIGHTMARESET.ABSORPTION)
    inst.components.armor.ontakedamage = OnTakeDamage

    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(TUNING.KNIGHTMARESET.PLANAR_DEF)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.ARMOR or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = 1.2

    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMORDREADSTONE_SHADOW_RESIST)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.DREADSTONE) -- Cassielu: need constant for new EQUIPMENTSETNAMES?
    inst.components.setbonus:SetOnEnabledFn(InSetBonusEnabled)
    inst.components.setbonus:SetOnDisabledFn(OnSetBonusDisabled)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.KNIGHTMARESET.SHADOW_LEVEL)

    inst:AddComponent("aoc_dimenson_container_linker")

    MakeHauntableLaunch(inst)


    -- Create swapanims
    inst.swap_anims = {
        cloak_up = inst:SpawnChild("dread_cloak_swapanim_cloak"),
        cloak_side = inst:SpawnChild("dread_cloak_swapanim_cloak"),
        cloak_down = inst:SpawnChild("dread_cloak_swapanim_cloak"),


        armor_down_1 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_down_2 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_down_3 = inst:SpawnChild("dread_cloak_swapanim_armor"),

        armor_side_1 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_side_2 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_side_3 = inst:SpawnChild("dread_cloak_swapanim_armor"),

        armor_up_1 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_up_2 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_up_3 = inst:SpawnChild("dread_cloak_swapanim_armor"),
    }

    for k, v in pairs(inst.swap_anims) do
        v.entity:AddFollower()
    end

    inst.swap_anims.cloak_up.idle_anim = "idle1"
    inst.swap_anims.cloak_up.move_pre_anim = "move_pre1"
    inst.swap_anims.cloak_up.move_loop_anim = "move_loop_1"
    inst.swap_anims.cloak_up.move_pst_anim = "move_pst_1"

    inst.swap_anims.cloak_side.idle_anim = "idle4"
    inst.swap_anims.cloak_side.move_pre_anim = "move_pre2"
    inst.swap_anims.cloak_side.move_loop_anim = "move_loop_2"
    inst.swap_anims.cloak_side.move_pst_anim = "move_pst_2"

    inst.swap_anims.cloak_down.idle_anim = "idle1"
    inst.swap_anims.cloak_down.move_pre_anim = "move_pre1"
    inst.swap_anims.cloak_down.move_loop_anim = "move_loop_1"
    inst.swap_anims.cloak_down.move_pst_anim = "move_pst_1"

    inst.swap_anims.cloak_up.AnimState:PlayAnimation(inst.swap_anims.cloak_up.idle_anim, true)
    inst.swap_anims.cloak_side.AnimState:PlayAnimation(inst.swap_anims.cloak_side.idle_anim, true)
    inst.swap_anims.cloak_down.AnimState:PlayAnimation(inst.swap_anims.cloak_down.idle_anim, true)

    inst.swap_anims.armor_down_1.AnimState:PlayAnimation("idle1", true)
    inst.swap_anims.armor_down_2.AnimState:PlayAnimation("idle2", true)
    inst.swap_anims.armor_down_3.AnimState:PlayAnimation("idle3", true)

    inst.swap_anims.armor_side_1.AnimState:PlayAnimation("idle4", true)
    inst.swap_anims.armor_side_2.AnimState:PlayAnimation("idle5", true)
    inst.swap_anims.armor_side_3.AnimState:PlayAnimation("idle6", true)

    inst.swap_anims.armor_up_1.AnimState:PlayAnimation("idle7", true)
    inst.swap_anims.armor_up_2.AnimState:PlayAnimation("idle8", true)
    inst.swap_anims.armor_up_3.AnimState:PlayAnimation("idle9", true)



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

    -- TODO: When bishop finish the anim, add ad here
    inst.idle_anim = "idle1"
    inst.move_pre_anim = ""
    inst.move_loop_anim = ""
    inst.move_pst_anim = ""
    inst.old_owner_moving = false

    inst:AddComponent("updatelooper")

    inst.TrackOwner = function(inst, owner)
        inst.AnimState:PlayAnimation(inst.idle_anim, true)

        if owner:HasTag("locomotor") then
            inst._update_fn = function()
                if not owner:IsValid() then
                    return
                end

                -- local owner_moving = owner:HasTag("moving")
                local owner_moving = owner.sg and owner.sg:HasStateTag("moving")

                if owner_moving and not inst.old_owner_moving then
                    -- TODO: Play moving anim here
                    inst.AnimState:PlayAnimation(inst.move_pre_anim)
                    inst.AnimState:PushAnimation(inst.move_loop_anim, true)
                elseif not owner_moving and inst.old_owner_moving then
                    -- TODO: Play normal anim here
                    inst.AnimState:PlayAnimation(inst.move_pst_anim)
                    inst.AnimState:PushAnimation(inst.idle_anim, true)
                end

                inst.old_owner_moving = owner_moving
            end

            inst.components.updatelooper:AddOnUpdateFn(inst._update_fn)
        end
    end

    inst.StopTrackingOwner = function(inst)
        if inst._update_fn then
            inst.components.updatelooper:RemoveOnUpdateFn(inst._update_fn)
            inst._update_fn = nil
        end
    end

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

local function cloakcontainerfn()
    local inst = CreateEntity()

    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")
    inst:Hide()

    inst:AddComponent("container_proxy")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.container_proxy:SetMaster(TheWorld:GetPocketDimensionContainer("shadow"))

    inst.persists = false

    return inst
end

return Prefab("dread_cloak", fn, assets),
    Prefab("dread_cloak_swapanim_cloak", cloak_animfn, assets),
    Prefab("dread_cloak_swapanim_armor", armor_animfn, assets),
    Prefab("dread_cloak_container", cloakcontainerfn)
