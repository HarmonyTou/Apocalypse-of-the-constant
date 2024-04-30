local assets =
{
    Asset("ANIM", "anim/spear.zip"),
    Asset("ANIM", "anim/swap_spear.zip"),
    Asset("ANIM", "anim/lunar_spark_blade.zip"),
}

------------------------------------------------------------------------------------------------------------------------

local function ReticuleTargetFn()
    --Cast range is 8, leave room for error (6.5 lunge)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

------------------------------------------------------------------------------------------------------------------------


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

    inst._owner:set(owner)

    if inst.increase_charge_task then
        inst.increase_charge_task:Cancel()
    end
    inst.increase_charge_task = inst:DoPeriodicTask(0, function()
        inst.components.dc_chargeable_item:DoDelta(FRAMES * 0.5)
    end)
end

local function onunequip(inst, owner)
    CheckSwapAnims(inst)

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst._owner:set(nil)
    if inst.increase_charge_task then
        inst.increase_charge_task:Cancel()
        inst.increase_charge_task = nil
    end
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

local function GetDamage(inst, attacker, target)
    local base_dmg = 85
    local leap_dmg = base_dmg * 1.2
    return (attacker.sg and attacker.sg.currentstate.name == "lunar_spark_blade_leap") and leap_dmg or base_dmg
end

local function OnAttack(inst, attacker, target)
    if attacker.sg and attacker.sg.currentstate.name == "lunar_spark_blade_leap" then
        inst.components.dc_chargeable_item:DoDelta(-1)
    else
        inst.components.dc_chargeable_item:DoDelta(1)
    end
end

local function SpellFn(inst, caster, pos)
    caster:PushEvent("combat_lunge", { targetpos = pos, weapon = inst })
end

local function OnLunged(inst, doer, startingpos, targetpos)
    -- Lightning fx towards targetpos
    local fx = SpawnPrefab("spear_wathgrithr_lightning_lunge_fx")
    fx.Transform:SetPosition(targetpos:Get())
    fx.Transform:SetRotation(doer:GetRotation())

    -- Change weapon skill cd at here
    inst.components.rechargeable:Discharge(3)
end

local function OnLungedHit(inst, doer, target)

end

local function OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    inst.components.aoetargeting:SetEnabled(true)
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
    inst.AnimState:SetSymbolBloom("glow")
    inst.AnimState:SetSymbolLightOverride("glow", 0.5)


    MakeInventoryFloatable(inst, "med", 0.05, { 1.1, 0.5, 1.1 }, true, -9)

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleline"
    inst.components.aoetargeting.reticule.pingprefab = "reticulelineping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    -- if _leap_range > 0 and larger than leap_range should leap
    inst._leap_range = net_float(inst.GUID, "inst._leap_range")
    inst._leap_range:set(-1)

    inst._leap_fx_pos_x = net_float(inst.GUID, "inst._leap_fx_pos_x")
    inst._leap_fx_pos_z = net_float(inst.GUID, "inst._leap_fx_pos_z")
    inst._owner = net_entity(inst.GUID, "inst._owner")
    inst._leap_fx_spawn_event = net_event(inst.GUID, "inst._leap_fx_spawn_event")

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("inst._leap_fx_spawn_event", function()
            local attacker = inst._owner:value()
            if attacker ~= nil and attacker:IsValid() then
                local fx = SpawnAt("moonstorm_ground_lightning_fx",
                    Vector3(inst._leap_fx_pos_x:value(), 0, inst._leap_fx_pos_z:value()))
                fx.Transform:SetRotation(attacker.Transform:GetRotation() - 90)
            end
        end)
    end

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

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(34)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(GetDamage)
    -- inst.components.weapon:SetRange(10, 0)
    inst.components.weapon:SetRange(0)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("aoeweapon_lunge")
    inst.components.aoeweapon_lunge:SetDamage(34) -- lunge weapon skill damage
    inst.components.aoeweapon_lunge:SetSound("moonstorm/characters/wagstaff/goggles/shoot")
    inst.components.aoeweapon_lunge:SetSideRange(1)
    inst.components.aoeweapon_lunge:SetOnLungedFn(OnLunged)
    inst.components.aoeweapon_lunge:SetOnHitFn(OnLungedHit)
    -- inst.components.aoeweapon_lunge:SetStimuli("electric")
    inst.components.aoeweapon_lunge:SetWorkActions()
    inst.components.aoeweapon_lunge:SetTags("_combat")

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("dc_chargeable_item")
    inst.components.dc_chargeable_item:SetMax(20)
    -- inst.components.dc_chargeable_item:SetDrainPerSecond(1)
    -- inst.components.dc_chargeable_item:SetResumeDrainCD(2)
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

    inst.AnimState:SetSymbolBloom("glow")
    inst.AnimState:SetSymbolLightOverride("glow", 0.5)


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
