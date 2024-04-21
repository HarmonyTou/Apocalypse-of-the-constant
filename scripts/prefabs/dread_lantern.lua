local assets = {
    Asset("ANIM", "anim/lantern.zip"),
    Asset("ANIM", "anim/swap_lantern.zip"),
    Asset("ANIM", "anim/atrium_gate_overload_fx.zip"),
}

-- From miasma_cloud_fx.lua
local MIASMA_SPACING_RADIUS = SQRT2 * TUNING.MIASMA_SPACING * TILE_SCALE / 2
-- Small overlap is good to make sure players are always in a fog when all squares are in one.
local MIASMA_RADIUS = math.ceil(MIASMA_SPACING_RADIUS)
local FIRE_RADIUS = MIASMA_RADIUS + 1 -- Small fudge factor.


local function AttachOwnerForLight(inst)
    if inst.light and inst.light:IsValid() then
        local owner = inst.components.inventoryitem.owner
        local is_equipped = inst.components.equippable:IsEquipped()

        if is_equipped and owner then
            owner:AddChild(inst.light)
        else
            inst:AddChild(inst.light)
        end
    end
end

local function CreateLight(inst)
    if not (inst.light and inst.light:IsValid()) then
        inst.light = SpawnPrefab("dread_lantern_light")
        AttachOwnerForLight(inst)
    end
end

local function CreateFires(inst, owner, clear_miasma_radius, add_center)
    if clear_miasma_radius == nil then
        clear_miasma_radius = 8
    end

    local count = 12
    local rad_seg = TWOPI / count
    local radius = math.max(1, clear_miasma_radius - FIRE_RADIUS)
    for i = 0, count - 1 do
        local offset = Vector3(math.cos(rad_seg * i), 0, math.sin(rad_seg * i)) * radius
        local fx = owner:SpawnChild("dread_lantern_fire")
        fx.Transform:SetPosition(offset:Get())
        table.insert(inst.firefxs, fx)
    end

    if add_center then
        table.insert(inst.firefxs, owner:SpawnChild("dread_lantern_fire"))
    end
end

local function RemoveFires(inst)
    if inst.firefxs then
        for _, v in pairs(inst.firefxs) do
            if v:IsValid() then
                v:Remove()
            end
        end
    end

    inst.firefxs = nil
end

local function CreateAbsorbFX(inst, owner)
    inst.absorbfx = owner:SpawnChild("dread_lantern_absorbfx")
    inst.absorbfx.entity:AddFollower()

    -- idle
    inst.absorbfx.Follower:FollowSymbol(owner.GUID, "swap_object", 70, 460, 0, true)

    -- overload
    -- inst.absorbfx.Follower:FollowSymbol(owner.GUID, "swap_object", 90, 500, 0, true)


    inst.absorbfx:SetFX("idle")
    -- inst.absorbfx:SetFX("overload")
end

local function RemoveAbsorbFX(inst)
    if inst.absorbfx and inst.absorbfx:IsValid() then
        -- inst.absorbfx:KillFX()
        inst.absorbfx:Remove()
    end
    inst.absorbfx = nil
end

local function FuelUpdate(inst)
    if inst.light ~= nil then
        local fuelpercent = inst.components.fueled:GetPercent()
        inst.light.Light:SetIntensity(Lerp(.4, .6, fuelpercent))
        inst.light.Light:SetRadius(Lerp(3, 5, fuelpercent))
        inst.light.Light:SetFalloff(.9)

        inst.light.Light:Enable(fuelpercent > 0)
    end
end

local function TurnOn(inst)
    if not inst.components.fueled:IsEmpty() then
        inst.components.fueled:StartConsuming()

        FuelUpdate(inst)
        inst.light.Light:Enable(true)

        inst.AnimState:PlayAnimation("idle_on")

        inst.components.machine.ison = true
        inst.components.inventoryitem:ChangeImageName("lantern_lit")
    end
end

local function TurnOff(inst)
    inst.components.fueled:StopConsuming()

    inst.light.Light:Enable(false)

    inst.AnimState:PlayAnimation("idle_off")

    inst.components.machine.ison = false
    inst.components.inventoryitem:ChangeImageName("lantern")
end

local function OnNoFuel(inst)
    TurnOff(inst)
end

local function OnTakeFuel(inst)
    if inst.components.equippable:IsEquipped() or inst.components.inventoryitem.owner == nil then
        TurnOn(inst)
    end
end

local function ChannelingTaskFn(inst, owner)
    local miasmamanager = TheWorld.components.miasmamanager
    local x, y, z = owner:GetPosition():Get()

    if miasmamanager then
        local restore_value = 0

        local miasma_clouds = TheSim:FindEntities(x, y, z, 8, { "miasma" })
        for k, v in pairs(miasma_clouds) do
            local mx, my, mz = v:GetPosition():Get()
            if miasmamanager:GetMiasmaAtPoint(mx, my, mz) ~= nil then
                restore_value = restore_value + 1
            end
        end

        if restore_value >= 0 then
            inst.components.fueled:DoDelta(restore_value)
            if not inst.components.fueled:IsEmpty() and not inst.components.machine.ison then
                TurnOn(inst)
            end
        end
    end

    local shadow_creatures = TheSim:FindEntities(x, y, z, 10, { "_combat", "_health", "shadow" })
    for k, v in pairs(shadow_creatures) do
        if not IsEntityDead(v, true) and not owner.components.combat:IsAlly(v)
            and (inst.hitted_creatures[v] == nil or GetTime() - inst.hitted_creatures[v] >= 1.0) then
            -- owner.components.combat:DoAttack(v)
            v.components.combat:GetAttacked(inst, 20)
            inst.hitted_creatures[v] = GetTime()
        end
    end
end

local function OnNightmarePhaseChanged(inst, phase)
    local is_evil_phase = phase == "wild" or phase == "dawn"
    if is_evil_phase then
        inst.components.fueled.rate = 0
    else
        inst.components.fueled.rate = 1
    end

    if is_evil_phase and inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner
        if owner and owner.components.sanity then
            owner.components.sanity.neg_aura_modifiers:SetModifier(inst, 0, inst.prefab)
        end
    end
end


local function OnEquip(inst, owner)
    AttachOwnerForLight(inst)

    owner.AnimState:OverrideSymbol("swap_object", "swap_lantern", "swap_lantern")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.fueled:IsEmpty() then

    else
        TurnOn(inst)
    end

    if inst.components.channelcastable == nil then
        inst:AddComponent("channelcastable")
        inst.components.channelcastable:SetOnStartChannelingFn(function()
            inst.firefxs = {}
            inst.hitted_creatures = {}
            ChannelingTaskFn(inst, owner)


            CreateFires(inst, owner, 8, true)
            -- CreateFires(inst, owner, 16)
            CreateAbsorbFX(inst, owner)

            inst.channeling_task = inst:DoPeriodicTask(0, function()
                ChannelingTaskFn(inst, owner)
            end)
        end)
        inst.components.channelcastable:SetOnStopChannelingFn(function()
            RemoveFires(inst)
            RemoveAbsorbFX(inst)
            if inst.channeling_task then
                inst.channeling_task:Cancel()
                inst.channeling_task = nil
            end

            inst.hitted_creatures = nil
        end)
    end

    OnNightmarePhaseChanged(inst, TheWorld.state.nightmarephase)
end

local function OnUnequip(inst, owner)
    AttachOwnerForLight(inst)

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    TurnOff(inst)
    if owner and owner.components.sanity then
        owner.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
    end
end

local function OnEquipToModel(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_lantern", "swap_lantern")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function Dapperfn(inst, owner)
    if TheWorld.state.isnightmarewild or TheWorld.state.isnightmaredawn then
        return 1
    end

    return -1
end

local function OnDropped(inst)
    AttachOwnerForLight(inst)
    TurnOn(inst)
end

local function OnPutInInventory(inst)
    AttachOwnerForLight(inst)
    TurnOff(inst)
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", 0.2, 0.65)

    inst.AnimState:SetBank("lantern")
    inst.AnimState:SetBuild("lantern")
    inst.AnimState:PlayAnimation("idle_off")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.light = nil

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "lantern"
    inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable:SetOnEquipToModel(OnEquipToModel)
    inst.components.equippable.dapperfn = Dapperfn

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = TurnOn
    inst.components.machine.turnofffn = TurnOff
    inst.components.machine.cooldowntime = 0

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:InitializeFuelLevel(TUNING.TOTAL_DAY_TIME)
    inst.components.fueled:SetDepletedFn(OnNoFuel)
    inst.components.fueled:SetUpdateFn(FuelUpdate)
    inst.components.fueled:SetTakeFuelFn(OnTakeFuel)
    -- inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled.accepting = true

    CreateLight(inst)

    inst:WatchWorldState("nightmarephase", OnNightmarePhaseChanged)
    OnNightmarePhaseChanged(inst, TheWorld.state.nightmarephase)

    return inst
end

local function lightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst:AddTag("FX")

    inst.Light:SetColour(252 / 255, 251 / 255, 237 / 255)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function firefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable.fxprefab = nil

    inst.components.burnable:Ignite(true)

    return inst
end

local function absorbfxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("atrium_gate_overload_fx")
    inst.AnimState:SetBuild("atrium_gate_overload_fx")

    inst.AnimState:SetLightOverride(1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.anim = nil

    inst.SetFX = function(inst, anim)
        inst.anim = anim
        inst.AnimState:PlayAnimation(inst.anim .. "_pre")
        inst.AnimState:PushAnimation(inst.anim .. "_loop", true)
    end

    inst.KillFX = function()
        if not inst.killed then
            inst.killed = true
            inst.AnimState:PushAnimation((inst.anim or "idle") .. "_pst", false)
            inst:ListenForEvent("animqueueover", inst.Remove)
            inst:DoTaskInTime(4, inst.Remove)
        end
    end

    inst.persists = false

    return inst
end

return Prefab("dread_lantern", fn, assets),
    Prefab("dread_lantern_light", lightfn),
    Prefab("dread_lantern_fire", firefn),
    Prefab("dread_lantern_absorbfx", absorbfxfn, assets)
