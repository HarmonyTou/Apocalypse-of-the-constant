local assets =
{
    Asset("ANIM", "anim/swap_dread_cloak.zip"),
    Asset("ANIM", "anim/swap_dread_cloak2.zip"),
}

local function DoRegen(inst, owner)
    if owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode() then
        local setbonus = inst.components.setbonus ~= nil and
        inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.DREADSTONE) and TUNING.ARMOR_DREADSTONE_REGEN_SETBONUS or 1 -- Cassielu: need constant for new EQUIPMENTSETNAMES?
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
    inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.KNIGHTMARESET.SETBONUS_SHADOW_RESIST, "setbonus")
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
    inst.components.planardefense:SetBaseDefense(TUNING.TUNING.KNIGHTMARESET.PLANAR_DEF)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.ARMOR or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMORDREADSTONE_SHADOW_RESIST)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.DREADSTONE) -- Cassielu: need constant for new EQUIPMENTSETNAMES?
    inst.components.setbonus:SetOnEnabledFn(InSetBonusEnabled)
    inst.components.setbonus:SetOnDisabledFn(OnSetBonusDisabled)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.KNIGHTMARESET.SHADOW_LEVEL)

    --inst:AddComponent("aoc_dimenson_container_linker")
    --这个组件01还没上传

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

    inst.swap_anims.cloak_up.AnimState:PlayAnimation("idle1", true)
    inst.swap_anims.cloak_side.AnimState:PlayAnimation("idle4", true)
    inst.swap_anims.cloak_down.AnimState:PlayAnimation("idle1", true)

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
