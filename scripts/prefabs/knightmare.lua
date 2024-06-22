local brain = require("brains/knightmarebrain")
local assets =
{
    Asset("ANIM", "anim/player_basic.zip"),
    Asset("ANIM", "anim/player_idles_shiver.zip"),
    Asset("ANIM", "anim/player_idles_lunacy.zip"),
    Asset("ANIM", "anim/player_actions.zip"),
}

local prefabs = {
    "knightmare_npc_sword",
    "horrorfuel"
}


SetSharedLootTable("knightmare",
{
    {"horrorfuel", 1.00},
})

----------------------------------------------------------
local function OnSpawnShadow(inst, ent)
    --ent.spawnedforplayer = inst
    ent.components.combat:SetTarget(inst)

    inst:ListenForEvent("entitysleep", function()
        inst:DoTaskInTime(0, function() ent:Remove() end)
    end, ent)

    ent:ListenForEvent("onremove", function()
        ent.spawnedforplayer = nil
        ent.persists = false
        ent.wantstodespawn = true
    end, inst)
end


local function shadowcreaturetype()
    return math.random() < 0.5 and "terrorbeak" or "crawlinghorror"
end

local function GetShadowSpawnPoint(inst)
    local pos = inst:GetPosition()
    local dist = 2+6*math.random()
    local angle = math.random()*PI2
    local offset = Vector3(dist*math.cos(angle),0-dist*math.sin(angle))

    if offset ~= nil then
        return pos + offset
    end
end
---------------------------------------------------------------

local TARGET_DIST = 30
local TARGET_DSQ = (TARGET_DIST)^2
local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "INLIMBO", "playerghost", "FX" }
local RETARGET_ONEOF_TAGS = { "shadow_aligned","player_shadow_aligned" }
local function Retarget(inst)
    local spawnpoint_position = inst.components.knownlocations:GetLocation("spawnpoint")

    if spawnpoint_position ~= nil and
            inst:GetDistanceSqToPoint(spawnpoint_position:Get()) >= TARGET_DSQ then
        return nil
    else
        return FindEntity(
            inst,
            TARGET_DIST,
            function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
            RETARGET_ONEOF_TAGS
        )
    end
end

local function keeptargetfn(inst,target)
    return inst.components.combat:CanTarget(target)
end


local function DisplayNameFn(inst)
	return ThePlayer ~= nil and ThePlayer:HasTag("player_shadow_aligned") and STRINGS.NAMES.KNIGHTMARE_ALLEGIANCE or nil
end


local function FullArmored(inst)
    local weapon = SpawnPrefab("knightmare_npc_sword")
    inst.components.inventory:Equip(weapon)

    --[[local helmet = SpawnPrefab("knightmare_npc_hat")
    inst.components.inventory:Equip(helmet)

    local armor = SpawnPrefab("knightmare_npc_armor")
    inst.components.inventory:Equip(armor)]]
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function onkilledtarget(inst, data)
	local target = data ~= nil and data.victim
    if target~=nil and target:IsValid() and target:HasTag("gestaltnoloot") then
        inst.components.health:DoDelta(100)
        local lootdropper = target.components.lootdropper or nil
        if lootdropper ~= nil then
            lootdropper:SetLoot({})
            lootdropper:SetChanceLootTable(nil)
        end
    end
end


-------------------------------------------
local function OnEntityWake(inst)
    if inst._despawntask ~= nil then
        inst._despawntask:Cancel()
        inst._despawntask = nil
    end
end

local function OnDespawn(inst)
    inst._despawntask = nil
    if TheWorld.components.riftspawner ~= nil
        and not TheWorld.components.riftspawner:IsShadowPortalActive()
        and inst:IsAsleep()
        and not inst.components.health:IsDead()
    then
        inst:Remove()
    end
end

local function CheckRift(inst)
    if TheWorld.components.riftspawner ~= nil
        and not TheWorld.components.riftspawner:IsShadowPortalActive()
        and inst:IsAsleep()
        and not inst.components.health:IsDead()
    then
        inst._despawntask = inst:DoTaskInTime(30, OnDespawn)
    end
end

local function OnEntitySleep(inst)
    if inst._despawntask ~= nil then
        inst._despawntask:Cancel()
    end
    inst:CheckRift()
end

-------------------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    
    MakeCharacterPhysics(inst, 100, .5)

    inst.DynamicShadow:SetSize(1.3, .6)

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")
    inst.AnimState:PlayAnimation("idle")


    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")
    inst.AnimState:Hide("HEAD_HAT_NOHELM")
    inst.AnimState:Hide("HEAD_HAT_HELM")


    inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
    inst.AnimState:OverrideSymbol("fx_liquid", "wilson_fx", "fx_liquid")
    inst.AnimState:OverrideSymbol("shadow_hands", "shadow_hands", "shadow_hands")
    inst.AnimState:OverrideSymbol("snap_fx", "player_actions_fishing_ocean_new", "snap_fx")

    

    --[[inst:AddComponent("talker")
    inst.components.talker.fontsize = 40
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(238 / 255, 69 / 255, 105 / 255)
    inst.components.talker.offset = Vector3(0, -400, 0)
    inst.components.talker.symbol = "fossil_chest"
    inst.components.talker:MakeChatter()]]

    inst:AddTag("epic")
    inst:AddTag("hostile")
    --inst:AddTag("character")
    inst:AddTag("crazy")
    inst:AddTag("soulless")
    inst:AddTag("scarytoprey")
    inst:AddTag("noteleport")
    inst:AddTag("abyss")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	

	
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(7000)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(100)
    inst.components.combat:SetAttackPeriod(1)
    inst.components.combat:SetRange(TUNING.DEFAULT_ATTACK_RANGE)
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetRetargetFunction(1, Retarget)

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 6
    inst.components.locomotor.runspeed = 6
    inst.components.locomotor.fasteronroad = true
    inst.components.locomotor.pathcaps = { ignorecreep = true}

    -----------------------------------------------------
    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(20)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("acidinfusible")
    inst.components.acidinfusible:SetFXLevel(2)
    inst.components.acidinfusible:SetMultipliers(TUNING.ACID_INFUSION_MULT.BERSERKER)
    --[[local stunnable = inst:AddComponent("stunnable")
    stunnable.stun_threshold = 500
    stunnable.stun_period = 5
    stunnable.stun_duration = 20
    stunnable.stun_resist = 0
    stunnable.stun_cooldown = 0]]
    ---------------------------------------------
    inst:AddComponent("inventory")

    FullArmored(inst)

    inst:AddComponent("timer")

    inst:AddComponent("knownlocations")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("knightmare")


    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetOnSpawnFn(OnSpawnShadow)
    inst.components.periodicspawner:SetGetSpawnPointFn(GetShadowSpawnPoint)
    inst.components.periodicspawner:SetPrefab(shadowcreaturetype)
    inst.components.periodicspawner.basetime = 15
    inst.components.periodicspawner.randtime = 10
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:Start()

    inst:AddComponent("inspectable")
    ------------------------------------------
    inst:AddComponent("colouradder")

    inst:AddComponent("bloomer")

    inst:SetStateGraph("SGknightmare")
    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("killed", onkilledtarget)
    inst:ListenForEvent("ms_riftaddedtopool", CheckRift, TheWorld)
	inst:ListenForEvent("ms_riftremovedfrompool", CheckRift, TheWorld)

    inst.shouldparry = false
    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep
    inst.displaynamefn = DisplayNameFn


    return inst
end


return Prefab("knightmare", fn, assets, prefabs)
