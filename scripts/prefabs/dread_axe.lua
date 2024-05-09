local assets = {
    Asset("ANIM", "anim/dread_axe.zip"),
    Asset("ANIM", "anim/dread_axe_throw.zip"),
}

local prefabs = {
    "dread_axe_fx",
}

local function ReticuleTargetFn()
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

local function SetFxOwner(inst, owner)
    if inst._fxowner ~= nil and inst._fxowner.components.colouradder ~= nil then
        inst._fxowner.components.colouradder:DetachChild(inst.fx)
    end
    inst._fxowner = owner
    if owner ~= nil then
        inst.fx.entity:SetParent(owner.entity)
        inst.fx.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 2)
        inst.fx.components.highlightchild:SetOwner(owner)
        inst.fx:ToggleEquipped(true)
        if owner.components.colouradder ~= nil then
            owner.components.colouradder:AttachChild(inst.fx)
        end
    else
        inst.fx.entity:SetParent(inst.entity)
        --For floating
        inst.fx.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 2)
        inst.fx.components.highlightchild:SetOwner(inst)
        inst.fx:ToggleEquipped(false)
    end
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "dread_axe", "dread_axe")
    SetFxOwner(inst, owner)

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    SetFxOwner(inst, nil)
end

local function PushIdleLoop(inst)
    inst.AnimState:PushAnimation("idle")
end

local function OnStopFloating(inst)
    inst.fx.AnimState:SetFrame(0)
    inst:DoTaskInTime(0, PushIdleLoop) --#V2C: #HACK restore the looping anim, timing issues
end

local function SpellFn(inst, caster, pos)
    inst.components.rechargeable:Discharge(5)
    inst:MakeProjectile()

    caster.components.inventory:DropItem(inst)
    inst.components.complexprojectile:Launch(pos, caster)
end

local function StartReturn(inst, attacker)
    inst.Physics:Stop()

    if attacker and attacker:IsValid() then
        attacker:AddChild(inst)
        inst.Transform:SetPosition(0, 0, 0)
        inst.AnimState:PlayAnimation("return")

        inst.Follower:FollowSymbol(attacker.GUID, "swap_object", 0, 0, 0)

        inst:DoTaskInTime(12 * FRAMES, function()
            inst.Follower:StopFollowing()

            attacker:RemoveChild(inst)
            inst.Transform:SetPosition(attacker:GetPosition():Get())


            inst.components.inventoryitem.canbepickedup = true
            inst.components.scaler:ApplyScale()
            inst:MakeNonProjectile()
            inst.AnimState:PlayAnimation("idle", true)

            -- return to attacker
            SpawnPrefab("lucy_transform_fx").entity:AddFollower():FollowSymbol(attacker.GUID, "swap_object", 50,
                -25, -1)
            attacker.components.inventory:Equip(inst)
        end)
    else
        inst.components.inventoryitem.canbepickedup = true
        inst.components.scaler:ApplyScale()
        inst:MakeNonProjectile()
        inst.AnimState:PlayAnimation("idle", true)

        -- Drop on ground
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.components.inventoryitem:DoDropPhysics(x, y, z, true)
    end
end



local function OnLaunch(inst, attacker, targetpos)
    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.components.inventoryitem.canbepickedup = false

    -- Personal params stored in complexprojectile
    inst.components.complexprojectile.startpos  = attacker:GetPosition()
    inst.components.complexprojectile.targetpos = targetpos

    inst.Physics:SetMotorVel(TUNING.DREAD_AXE.ALT_SPEED, 0, 0)
end


local function OnHit(inst, attacker, target)
    inst.AnimState:PlayAnimation("bounce")
    inst.AnimState:PushAnimation("idle")
    if target ~= nil then
        -- DoAttack(targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos)
        attacker.components.combat:DoAttack(target, inst, inst, TUNING.DREAD_AXE.ALT_STIMULI, nil, 999,
            inst:GetPosition())
    end
    inst.Physics:SetMotorVel(5, 0, 0)
    -- inst.components.inventoryitem.pushlandedevents = not attacker
    inst:DoTaskInTime(15 * FRAMES, StartReturn, attacker)
end

local function OnProjectileUpdate(inst, dt)
    dt = dt or FRAMES
    local x, y, z = inst:GetPosition():Get()
    local attacker = inst.components.complexprojectile.attacker
    if attacker == nil then
        print("Warning: attacker = nil")
        return
    end

    if (inst:GetPosition() - inst.components.complexprojectile.startpos):Length() > TUNING.DREAD_AXE.ALT_DIST then
        -- Hit none target, miss...
        inst.components.complexprojectile:Hit()
        return
    end

    local ents = TheSim:FindEntities(x, y, z, TUNING.DREAD_AXE.ALT_HIT_RANGE, { "_combat", "_health" }, { "INLIMBO" })
    for _, v in pairs(ents) do
        if attacker.components.combat:CanTarget(v)
            and not attacker.components.combat:IsAlly(v) then
            inst.components.complexprojectile:Hit(v)
            break
        end
    end

    return true
end

local function MakeProjectile(inst)
    inst:AddTag("NOCLICK")

    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)

    inst.Transform:SetSixFaced()

    inst.AnimState:SetBank("dread_axe_throw")
    inst.AnimState:SetBuild("dread_axe_throw")

    if not inst.components.complexprojectile then
        inst:AddComponent("complexprojectile")
    end

    -- Still required:
    -- TUNING.DREAD_AXE.ALT_SPEED
    -- TUNING.DREAD_AXE.ALT_DIST
    -- TUNING.DREAD_AXE.ALT_HIT_RANGE
    -- TUNING.DREAD_AXE.ALT_STIMULI
    -- TUNING.DREAD_AXE.ALT_DAMAGE
    inst.components.complexprojectile.onupdatefn = OnProjectileUpdate
    inst.components.complexprojectile:SetOnLaunch(OnLaunch)
    inst.components.complexprojectile:SetOnHit(OnHit)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 0, 0))
end

local function MakeNonProjectile(inst)
    inst:RemoveTag("NOCLICK")

    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)

    inst.Transform:SetNoFaced()

    inst.AnimState:SetBank("dread_axe")
    inst.AnimState:SetBuild("dread_axe")

    if inst.components.complexprojectile then
        inst:RemoveComponent("complexprojectile")
    end
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
    -- inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddFollower()

    MakeInventoryPhysics(inst)

    -- inst.MiniMapEntity:SetIcon("dread_axe.png")

    inst.AnimState:SetBank("dread_axe")
    inst.AnimState:SetBuild("dread_axe")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("throw_line")
    inst:AddTag("chop_attack")

    --tool (from tool component) added to pristine state for optimization
    inst:AddTag("tool")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --rechargeable (from rechargeable component) added to pristine state for optimization
    -- inst:AddTag("rechargeable")

    --shadowlevel (from shadowlevel component) added to pristine state for optimization
    inst:AddTag("shadowlevel")

    inst:AddTag("shadow_item")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulelong"
    inst.components.aoetargeting.reticule.pingprefab = "reticulelongping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    local swap_data = { sym_build = "dread_axe", bank = "dread_axe" }
    MakeInventoryFloatable(inst, "small", 0.05, { 1.2, 0.75, 1.2 }, true, -11, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(frame)
    inst.fx = SpawnPrefab("dread_axe_fx")
    inst.fx.AnimState:SetFrame(frame)
    SetFxOwner(inst, nil)
    inst:ListenForEvent("floater_stopfloating", OnStopFloating)


    inst.MakeProjectile = MakeProjectile
    inst.MakeNonProjectile = MakeNonProjectile

    inst:AddComponent("scaler")
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.DREAD_AXE.DAMAGE * .5)

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, 1.5)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(TUNING.DREAD_AXE.PLANAR_DAMAGE)

    inst:AddComponent("damagetypebonus")
    inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.WEAPONS_VOIDCLOTH_VS_LUNAR_BONUS)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.VOIDCLOTH_SCYTHE_SHADOW_LEVEL)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.DREADSTONE)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.DREAD_AXE.USES)
    inst.components.finiteuses:SetUses(TUNING.DREAD_AXE.USES)

    inst:AddComponent("equippable")
    inst.components.equippable.dapperness = -TUNING.DAPPERNESS_MED
    inst.components.equippable.is_magic_dapperness = true
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    MakeHauntableLaunch(inst)

    return inst
end

local FX_DEFS = {
    { anim = "swap_loop_1", frame_begin = 0, frame_end = 2 },
    --{ anim = "swap_loop_3", frame_begin = 2 },
    { anim = "swap_loop_6", frame_begin = 5 },
    { anim = "swap_loop_7", frame_begin = 6 },
    { anim = "swap_loop_8", frame_begin = 7 },
}

local function CreateFxFollowFrame()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst:AddTag("FX")

    inst.AnimState:SetBank("dread_axe")
    inst.AnimState:SetBuild("dread_axe")

    inst:AddComponent("highlightchild")

    inst.persists = false

    return inst
end

local function FxRemoveAll(inst)
    for i = 1, #inst.fx do
        inst.fx[i]:Remove()
        inst.fx[i] = nil
    end
end

local function FxColourChanged(inst, r, g, b, a)
    for i = 1, #inst.fx do
        inst.fx[i].AnimState:SetAddColour(r, g, b, a)
    end
end

local function FxOnEquipToggle(inst)
    local owner = inst.equiptoggle:value() and inst.entity:GetParent() or nil
    if owner ~= nil then
        if inst.fx == nil then
            inst.fx = {}
        end
        local frame = inst.AnimState:GetCurrentAnimationFrame()
        for i, v in ipairs(FX_DEFS) do
            local fx = inst.fx[i]
            if fx == nil then
                fx = CreateFxFollowFrame()
                fx.AnimState:PlayAnimation(v.anim, true)
                inst.fx[i] = fx
            end
            fx.entity:SetParent(owner.entity)
            fx.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, v.frame_begin, v.frame_end)
            fx.AnimState:SetFrame(frame)
            fx.components.highlightchild:SetOwner(owner)
        end
        inst.components.colouraddersync:SetColourChangedFn(FxColourChanged)
        inst.OnRemoveEntity = FxRemoveAll
    elseif inst.OnRemoveEntity ~= nil then
        inst.OnRemoveEntity = nil
        inst.components.colouraddersync:SetColourChangedFn(nil)
        FxRemoveAll(inst)
    end
end

local function FxToggleEquipped(inst, equipped)
    if equipped ~= inst.equiptoggle:value() then
        inst.equiptoggle:set(equipped)
        --Dedicated server does not need to spawn the local fx
        if not TheNet:IsDedicated() then
            FxOnEquipToggle(inst)
        end
    end
end

local function FollowSymbolFxFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("dread_axe")
    inst.AnimState:SetBuild("dread_axe")
    inst.AnimState:PlayAnimation("swap_loop_3", true) --frame 3 is used for floating

    inst:AddComponent("highlightchild")
    inst:AddComponent("colouraddersync")

    inst.equiptoggle = net_bool(inst.GUID, "dread_axe_fx.equiptoggle", "equiptoggledirty")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("equiptoggledirty", FxOnEquipToggle)
        return inst
    end

    inst.ToggleEquipped = FxToggleEquipped
    inst.persists = false

    return inst
end

return Prefab("dread_axe", fn, assets, prefabs),
    Prefab("dread_axe_fx", FollowSymbolFxFn, assets)
