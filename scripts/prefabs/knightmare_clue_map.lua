local assets =
{
    Asset("ANIM", "anim/stash_map.zip"),

    Asset("MINIMAP_IMAGE", "pirate_stash"),
}

local function InitTaskFn(inst)
    print(inst, "init fx and timer !")
    -- Spawn ground claw fxs
    local pos = inst:GetPosition()
    for i = 1, 5 do
        local offset = FindWalkableOffset(pos, math.random() * TWOPI, math.random() * 6, 10, nil, false, nil, false,
            false)
        if offset then
            local fx = SpawnAt("knightmare_clue_ground_fx", pos + offset)
            local name = "knightmare_clue_ground_fx" .. i
            inst.components.entitytracker:TrackEntity(name, fx)
        end
    end

    -- Start 1 day timer to remove self
    inst.components.timer:StartTimer("remove_self", TUNING.TOTAL_DAY_TIME)
end

local function OnInterract(inst)
    print(inst, "interracted !")

    local names = {}
    for name, v in pairs(inst.components.entitytracker.entities) do
        if v.inst and v.inst:IsValid() then
            table.insert(names, name)

            v.inst.persists = false
            v.inst:DoTaskInTime(TUNING.TOTAL_DAY_TIME + math.random() * 10, v.inst.Remove)
        end
    end

    for _, v in pairs(names) do
        inst.components.entitytracker:ForgetEntity(v)
    end

    if inst.components.timer:TimerExists("remove_self") then
        inst.components.timer:StopTimer("remove_self")
    end
end

local function OnPickUp(inst)
    OnInterract(inst)
end

local function OnTimerDone(inst, data)
    if data.name == "remove_self" then
        print(inst, "Remove-self timer done, this clue will disappear !")

        local ents = {}
        for name, v in pairs(inst.components.entitytracker.entities) do
            if v.inst and v.inst:IsValid() then
                table.insert(ents, v.inst)
            end
        end

        for _, v in pairs(ents) do
            v:Remove()
        end

        if TheWorld.components.dc_knightmare_spawner then
            TheWorld.components.dc_knightmare_spawner:HandleDisapperedClue(inst)
        end

        inst:Remove()
    end
end

local function SpawnXMark(inst, pos)
    SpawnAt("knightmare_clue_mark", pos)
end

local function PreRevealFn(inst)
    OnInterract(inst)
    return true
end

local function GetRevealTargetPos(inst, doer)
    local knightmare = TheWorld.components.dc_knightmare_spawner and TheWorld.components.dc_knightmare_spawner
        .knightmare

    if knightmare and knightmare:IsValid() then
        return Vector3(knightmare.Transform:GetWorldPosition())
    end

    return false, "NO_TARGET"
end


local function OnSave(inst, data)

end

local function OnLoad(inst, data)
    if inst.init_task then
        inst.init_task:Cancel()
        inst.init_task = nil
    end

    if data ~= nil then

    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("stash_map")
    inst.AnimState:SetBuild("stash_map")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("cattoy")

    MakeInventoryFloatable(inst, "med", nil, 0.75)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("erasablepaper")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "stash_map"
    inst.components.inventoryitem:SetOnPickupFn(OnPickUp)

    inst:AddComponent("tradable")

    inst:AddComponent("mapspotrevealer")
    inst.components.mapspotrevealer:SetGetTargetFn(GetRevealTargetPos)
    inst.components.mapspotrevealer:SetPreRevealFn(PreRevealFn)
    inst.components.mapspotrevealer.postreveal = function(inst)
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
    end

    -- inst:AddComponent("stackable")
    -- inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    inst:AddComponent("entitytracker")

    inst:AddComponent("timer")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    inst.init_task = inst:DoTaskInTime(0.1, InitTaskFn)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("on_reveal_map_spot_pre", SpawnXMark)

    return inst
end


local function markfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("pirate_stash.png")

    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:DoPeriodicTask(5, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        if FindClosestPlayerInRangeSq(x, y, z, 9) then
            inst:Remove()
        end
    end)

    return inst
end



return Prefab("knightmare_clue_map", fn, assets),
    Prefab("knightmare_clue_mark", markfn, assets)
