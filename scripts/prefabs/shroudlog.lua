local assets =
{
    Asset("ANIM", "anim/shroudlog.zip"),
}

local SOUND_TORMENTED_SCREAM = "rifts4/shadowthrall_mouth/jump_land"

local function beat(inst)
    inst.AnimState:PlayAnimation("idle2")
    inst.AnimState:PushAnimation("idle1", false)

    inst.beattask = inst:DoTaskInTime(4 + math.random() * 5, beat)
end


local function FuelTaken(inst, taker)
    if taker ~= nil and taker.SoundEmitter ~= nil then
        taker.SoundEmitter:PlaySound(SOUND_TORMENTED_SCREAM)
    end
end

local function allanimalscanscream(inst)
    inst.SoundEmitter:PlaySound(SOUND_TORMENTED_SCREAM)
end

local function onignite(inst)
    allanimalscanscream(inst)
end

local function oneaten(inst)
    allanimalscanscream(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.pickupsound = "wood"

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("shroudlog")
    inst.AnimState:SetBuild("shroudlog")
    inst.AnimState:PlayAnimation("idle1")

    MakeInventoryFloatable(inst, "med", 0.1, 0.7)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.WOOD
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = 0

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL
    inst.components.fuel:SetOnTakenFn(FuelTaken)

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    ---------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "shroudlog"
    inst.components.inventoryitem.atlasname = "images/shroudlog.xml"
    RegisterInventoryItemAtlas(images/shroudlog.tex, shroudlog)

    inst:AddComponent("stackable")

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.WOOD
    inst.components.repairer.healthrepairvalue = TUNING.REPAIR_LOGS_HEALTH * 3
    inst.components.repairer.boatrepairsound = "turnoftides/common/together/boat/repair_with_wood"

    inst:ListenForEvent("onignite", onignite)
    inst:ListenForEvent("oneaten", oneaten)
    inst.incineratesound = SOUND_TORMENTED_SCREAM -- NOTES(JBK): Pleasant orchestra.

    return inst
end

return Prefab("shroudlog", fn, assets)
