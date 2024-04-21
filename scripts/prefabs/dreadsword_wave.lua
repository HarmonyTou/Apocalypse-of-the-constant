local assets = {
    Asset("ANIM", "anim/dreadsword_wave.zip"),
    Asset("ANIM", "anim/dreadsword_wave_marker.zip"),

}

local SPEED = 20
local SPEED_DECREASE = 40 * FRAMES

local function OnUpdateFn(inst)
    if (inst:GetPosition() - inst.start_pos):Length() > 15 or GetTime() - inst.start_time > 5 then
        inst.components.complexprojectile:Hit()
        return true
    end

    local owner = inst.components.complexprojectile.attacker

    if not (owner and owner:IsValid()) then
        inst.components.complexprojectile:Hit()
        return true
    end

    local hitted = false
    local x, y, z = inst:GetPosition():Get()
    for k, v in pairs(TheSim:FindEntities(x, y, z, 2.5, { "_combat", "_health" }, { "INLIMBO" })) do
        if owner.components.combat:CanTarget(v) and not owner.components.combat:IsAlly(v) and not inst.hitted_victim[v] then
            owner.components.combat:DoAttack(v, inst, inst, nil, nil, 999, inst:GetPosition())
            inst.hitted_victim[v] = GetTime()
            hitted = true
        end
    end

    if hitted then
        inst.SoundEmitter:PlaySound("rifts2/thrall_wings/projectile")
    end

    return true
end

local function OnLaunchFn(inst, attacker, targetPos)
    inst.Physics:SetMotorVel(SPEED, 0, 0)

    inst.anim.AnimState:PlayAnimation("appear")
    inst.anim.AnimState:PushAnimation("continuous", true)


    inst.start_pos = inst:GetPosition()
    inst.start_time = GetTime()

    inst.SoundEmitter:PlaySound("dontstarve/sanity/creature/terrorbeak/taunt")
end

local function OnHitFn(inst, attacker, target)
    inst.Physics:SetMotorVel(SPEED, 0, 0)
    inst.anim.AnimState:PlayAnimation("disappear")

    inst.stop_task = inst:DoPeriodicTask(0, function()
        local x, _, _ = inst.Physics:GetMotorVel()
        x = x - SPEED_DECREASE
        if x <= 0 then
            inst.Physics:Stop()
            inst.stop_task:Cancel()
        else
            inst.Physics:SetMotorVel(x, 0, 0)
        end
    end)

    inst:ListenForEvent("animover", function()
                            inst:Remove()
                        end, inst.anim)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst)

    inst.AnimState:SetBank("dreadsword_wave_marker")
    inst.AnimState:SetBuild("dreadsword_wave_marker")
    inst.AnimState:PlayAnimation("marker")
    inst.AnimState:SetSymbolMultColour("marker", 0, 0, 0, 0)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst.hitted_victim = {}

    inst.anim = inst:SpawnChild("dreadsword_wave_anim")
    inst.anim.entity:AddFollower()
    inst.anim.Follower:FollowSymbol(inst.GUID, "marker", 0, 0, 0)



    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile.onupdatefn = OnUpdateFn
    inst.components.complexprojectile:SetOnLaunch(OnLaunchFn)
    inst.components.complexprojectile:SetOnHit(OnHitFn)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(1.5, 0, 0))

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(187)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(85)


    return inst
end

local function animfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()


    inst.AnimState:SetBank("dreadsword_wave")
    inst.AnimState:SetBuild("dreadsword_wave")
    inst.AnimState:PlayAnimation("continuous")

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    -- inst.AnimState:SetLayer(LAYER_GROUND)
    -- inst.AnimState:SetSortOrder(1)

    inst.AnimState:SetLightOverride(1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("dreadsword_wave", fn, assets),
    Prefab("dreadsword_wave_anim", animfn, assets)
