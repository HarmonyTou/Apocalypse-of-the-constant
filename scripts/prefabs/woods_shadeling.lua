local assets =
{
	Asset("ANIM", "anim/woods_shadeling.zip"),
}

local prefabs =
{
	--"dread_axe_blueprint",
	"nightmarefuel",
	"horrorfuel",
}

local LOOT =
{
	--"dread_axe_blueprint",
	"nightmarefuel",
}

local LOOT_RIFT =
{
	--"dread_axe_blueprint",
	"horrorfuel",
}

local function CalcSanityAura(inst, observer)
	return observer.components.sanity:IsCrazy()
		and -TUNING.SANITYAURA_MED
		or 0
end

local function KeepTargetFn()
	return false
end

local function DoDropLoot(inst)
	inst.components.lootdropper:DropLoot(inst:GetPosition())
	--inst:PushEvent("woods_shadeling_looted")
	if inst:IsAsleep() then
		inst:Remove()
	else
		inst.despawned = true
	end
end

local function DisableCombat(inst)
	inst:AddTag("NOCLICK")
	inst:AddTag("notarget")
end

local function OnDeath(inst)
	inst:RemoveEventCallback("death", OnDeath)
	inst:ListenForEvent("animover", inst.Remove)
	inst.AnimState:PlayAnimation("run")
	inst:DoTaskInTime(25 * FRAMES, DisableCombat)
	inst:DoTaskInTime(57 * FRAMES, DoDropLoot)
end

local function Despawn(inst)
	if not (inst.despawned or inst.components.health:IsDead()) then
		if inst:IsAsleep() then
			inst:Remove()
		else
			inst.despawned = true
			inst:RemoveEventCallback("death", OnDeath)
			inst:ListenForEvent("animover", inst.Remove)
			inst.AnimState:PlayAnimation("run")
			inst:DoTaskInTime(25 * FRAMES, DisableCombat)
		end
	end
end

local function TryRemoveOffScreen(inst)
	inst.sleeptask = nil
	--just don't want to remove when we're about to drop loot
	if inst.despawned or not inst.components.health:IsDead() then
		inst:Remove()
	end
end

local function OnEntitySleep(inst)
	if inst.sleeptask == nil then
		inst.sleeptask = inst:DoTaskInTime(1, TryRemoveOffScreen)
	end
end

local function OnEntityWake(inst)
	if inst.sleeptask ~= nil then
		inst.sleeptask:Cancel()
		inst.sleeptask = nil
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:SetPhysicsRadiusOverride(.26) --bigger than chair for targeting priority

	inst:AddTag("shadowcreature")
	inst:AddTag("monster")
	inst:AddTag("shadow")
	inst:AddTag("shadow_aligned")
	inst:AddTag("gestaltnoloot")

	inst.AnimState:SetBank("woods_shadeling")
	inst.AnimState:SetBuild("woods_shadeling")
	inst.AnimState:PlayAnimation("idle", true)
	--inst.AnimState:HideSymbol("planaraxe")
	--inst.AnimState:HideSymbol("planarmouth")
    --inst.AnimState:HideSymbol("planarstabup")
    --inst.AnimState:HideSymbol("planarstabdown")
    --inst.AnimState:HideSymbol("face")

	if not TheNet:IsDedicated() then
		-- this is purely view related
		inst:AddComponent("transparentonsanity")
		inst.components.transparentonsanity.most_alpha = .7
		inst.components.transparentonsanity.osc_amp = .1
		inst.components.transparentonsanity:ForceUpdate()
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = CalcSanityAura

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat.hiteffectsymbol = "shad_head"

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(LOOT)

	inst:ListenForEvent("death", OnDeath)
	inst.Despawn = Despawn
	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake
	inst.persists = false

	--[[local function CheckRift()
		local riftspawner = TheWorld.components.riftspawner
		if riftspawner ~= nil and riftspawner:IsShadowPortalActive() then
			if inst.components.planarentity == nil then
				inst:AddComponent("planarentity")
				inst.components.lootdropper:SetLoot(LOOT_RIFT)
				inst.AnimState:ShowSymbol("planaraxe")
				inst.AnimState:ShowSymbol("planarmouth")
                inst.AnimState:ShowSymbol("planarstabup")
                inst.AnimState:ShowSymbol("planarstabdown")
                inst.AnimState:ShowSymbol("face")
				inst.AnimState:SetLightOverride(1)
			end
		elseif inst.components.planarentity ~= nil then
			inst:RemoveComponent("planarentity")
			inst.components.lootdropper:SetLoot(LOOT)
			inst.AnimState:HideSymbol("planaraxe")
	        inst.AnimState:HideSymbol("planarmouth")
            inst.AnimState:HideSymbol("planarstabup")
            inst.AnimState:HideSymbol("planarstabdown")
            inst.AnimState:HideSymbol("face")
			inst.AnimState:SetLightOverride(0)
		end
	end
	inst:ListenForEvent("ms_riftaddedtopool", CheckRift, TheWorld)
	inst:ListenForEvent("ms_riftremovedfrompool", CheckRift, TheWorld)
	CheckRift()]]

	return inst
end

return Prefab("woods_shadeling", fn, assets, prefabs)