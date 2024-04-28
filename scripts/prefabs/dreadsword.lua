-- 我瞎几把写，你瞎几把看
local assets = {
    Asset("ANIM", "anim/dreadsword.zip"),
    -- Asset("ANIM", "anim/swap_dreadsword.zip")
}

local fx_dreadsword_assets = {
    Asset("ANIM", "anim/dreadsword.zip"),
    Asset("ANIM", "anim/night_edge.zip"),
}

local prefabs =
{
    "hitsparks_fx",
    "fx_dreadsword",
}

------------------------------------------------------------------------------------------------------------------------
-- Weapon skill definations

local COOLDOWN_PARRY = 10
local RE_COOLDOWN_PERCENT = 0
local COOLDOWN_WAVE = 4.5


local SKILL_EQUIP_PREFAB_1 = "lunarplanthat"
local SKILL_EQUIP_PREFAB_2 = "voidclothhat"

local function ReticuleTargetFn_Parry()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn_Parry(inst, mousepos)
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

local function ReticuleUpdatePositionFn_Parry(inst, pos, reticule, ease, smoothing, dt)
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


local function ReticuleTargetFn_Wave()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn_Wave(inst, mousepos)
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

local function ReticuleUpdatePositionFn_Wave(inst, pos, reticule, ease, smoothing, dt)
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

local function OnSkillChangeClient(inst)
    local val = inst._skill_define:value()

    if val == 0 then
        -- Weapon skill parry
        inst.components.aoetargeting.reticule.reticuleprefab = "reticulearc"
        inst.components.aoetargeting.reticule.pingprefab = "reticulearcping"
        inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn_Parry
        inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn_Parry
        inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn_Parry

        inst.skillname_index = "DREADSWORD_SKILL_PARRY"
    elseif val == 1 then
        -- Weapon skill wave
        inst.components.aoetargeting.reticule.reticuleprefab = "reticulelongmulti"
        inst.components.aoetargeting.reticule.pingprefab = "reticulelongmultiping"
        inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn_Wave
        inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn_Wave
        inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn_Wave

        inst.skillname_index = "DREADSWORD_SKILL_WAVE"
    else
        inst.skillname_index = "DREADSWORD_SKILL_UNKNOWN"
    end
end

local function CastParrySkill(inst, doer, pos)
    local head_equip = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if not (head_equip and head_equip.prefab == SKILL_EQUIP_PREFAB_1) then
        inst.components.rechargeable:Discharge(1)

        doer.sg:AddStateTag("idle") -- allow talker state to take over
        doer.components.talker:Say(GetString(doer, "ANNOUNCE_DREADSWORD_CANT_PARRY"))

        return
    end
    inst.components.parryweapon:EnterParryState(doer, doer:GetAngleToPoint(pos), 5)

    inst.components.rechargeable:Discharge(COOLDOWN_PARRY)
end

local function HitAndTryParryFn(inst, doer, attacker, damage)
    doer:ShakeCamera(CAMERASHAKE.SIDE, 0.1, 0.03, 0.3)
    doer.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable", nil, 1.0)

    if inst.components.rechargeable:GetPercent() > RE_COOLDOWN_PERCENT then
        inst.components.rechargeable:SetPercent(RE_COOLDOWN_PERCENT)
    end
end

local function CastWaveSkill(inst, doer, pos)
    SpawnAt("dreadsword_wave", doer).components.complexprojectile:Launch(pos, doer)
    doer.SoundEmitter:PlaySound("rifts2/thrall_wings/cast_f25")

    inst.components.rechargeable:Discharge(COOLDOWN_WAVE)
end

local function OnSkillChangeServer(inst)
    local val = inst._skill_define:value()

    if inst.components.parryweapon then
        inst:RemoveComponent("parryweapon")
    end

    if val == 0 then
        -- Weapon skill parry
        inst.components.aoespell:SetSpellFn(CastParrySkill)

        inst:AddComponent("parryweapon")
        inst.components.parryweapon:SetParryArc(178)
        inst.components.parryweapon:SetOnParryFn(HitAndTryParryFn)
    elseif val == 1 then
        -- Weapon skill wave
        inst.components.aoespell:SetSpellFn(CastWaveSkill)
    else
        inst.components.aoetargeting:SetEnabled(false)
    end
end

local function OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    local val = inst._skill_define:value()
    if val == 0 or val == 1 then
        inst.components.aoetargeting:SetEnabled(true)
    else
        inst.components.aoetargeting:SetEnabled(false)
    end
end

local function ChangeSkillByEquip(inst, owner)
    local skill_enabled = false
    local head_equip = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if head_equip then
        if head_equip.prefab == SKILL_EQUIP_PREFAB_1 then
            inst._skill_define:set(0)
            skill_enabled = true
        elseif head_equip.prefab == SKILL_EQUIP_PREFAB_2 then
            inst._skill_define:set(1)
            skill_enabled = true
        else
            inst._skill_define:set(2)
        end
    else
        inst._skill_define:set(2)
    end

    if skill_enabled and inst.components.rechargeable:IsCharged() then
        inst.components.aoetargeting:SetEnabled(true)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_dreadstone")
end

local function OnFinished(inst)
    inst:Remove()
end

local function SwordTalk(inst, talkid)
    if aoc_config.talking_sword and talkid == 1 then
        local list = STRINGS.DREADSWORD_TALK.TALK
        local index = math.random(#list)
        local item = list[index]
        inst.components.talker:Say(item)
    else
        if aoc_config.talking_sword and talkid == 2 then
            local list = STRINGS.DREADSWORD_TALK.ATTTALK
            local index = math.random(#list)
            local item = list[index]
            inst.components.talker:Say(item)
        end
    end
end

local function PushIdleLoop(inst)
    inst.AnimState:PushAnimation("idle")
end

local function OnStopFloating(inst) --回归帧
    inst.blade1.AnimState:SetFrame(0)
    inst.blade2.AnimState:SetFrame(0)
    inst:DoTaskInTime(0, PushIdleLoop)
end

local function DoRegen(inst, owner)
    if owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode() and not (inst.components.finiteuses:GetPercent() == 1) then
        local setbonus = inst.components.setbonus ~= nil and
            inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.DREADSTONE) and TUNING.DREADSWORD.REGEN_SETBONUS or 1
        local rate = 1 /
            Lerp(1 / TUNING.DREADSWORD.REGEN_MAXRATE, 1 / TUNING.DREADSWORD.REGEN_MINRATE,
                 owner.components.sanity:GetPercent())
        if inst.isonattack then
            rate = rate * 2.5
        end
        inst.components.finiteuses:Repair(inst.components.finiteuses.total * rate * setbonus)

        if inst.isonattack then
            inst.task = inst:DoPeriodicTask(2, function()
                inst.isonattack = false
                if inst.task then
                    inst.task:Cancel()
                    inst.task = nil
                end
            end)
        end
    end
end

local function StartRegen(inst, owner)
    if inst.regentask == nil then
        inst.regentask = inst:DoPeriodicTask(TUNING.DREADSWORD.REGEN_PERIOD, DoRegen, nil, owner)
    end
end

local function StopRegen(inst)
    if inst.regentask ~= nil then
        inst.regentask:Cancel()
        inst.regentask = nil
    end
end

local function GetSetBonusEquip(inst, owner, isbonus)
    local inventory = owner.components.inventory
    local hat = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    local armor = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil
    if isbonus then
        return hat ~= nil and hat.prefab == "dreadstonehat" and hat and armor ~= nil and
            armor.prefab == "armordreadstone" and armor or nil
    end
    return hat ~= nil and hat.prefab == "dreadstonehat" and hat or
        armor ~= nil and armor.prefab == "armordreadstone" and armor or nil
end

local function CalcDapperness(inst, owner)
    local insanity = owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode()
    local other = GetSetBonusEquip(inst, owner)
    if other ~= nil then
        return (insanity and (inst.regentask ~= nil or other.regentask ~= nil) and 0 or 0)
    end
    return insanity and inst.regentask ~= nil and TUNING.CRAZINESS_SMALL or 0
end

local function SetFxOwner(inst, owner)
    if owner ~= nil then
        inst.blade1.entity:SetParent(owner.entity)
        inst.blade2.entity:SetParent(owner.entity)
        inst.blade1.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 0)
        inst.blade2.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 5, 8)
        inst.blade1.components.highlightchild:SetOwner(owner)
        inst.blade2.components.highlightchild:SetOwner(owner)
    else
        inst.blade1.entity:SetParent(inst.entity)
        inst.blade2.entity:SetParent(inst.entity)
        --通过以空图层覆盖，使用特效跟随来等效覆盖效果并更可控（其实不）
        inst.blade1.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 0, 0) --xyz偏移量？
        inst.blade2.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 5, 8)
        inst.blade1.components.highlightchild:SetOwner(inst)
        inst.blade2.components.highlightchild:SetOwner(inst)
    end
end

local function OnEquip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    SetFxOwner(inst, owner)

    inst:ListenForEvent("blocked", OnBlocked, owner)

    if owner.components.sanity ~= nil then
        StartRegen(inst, owner)
    else
        StopRegen(inst)
    end
    if owner.components.sanity ~= nil and owner.components.sanity:GetPercent() <= 0.5 and inst.canTalk2 then
        SwordTalk(inst, 1)
        inst.canTalk2 = false
        inst:DoTaskInTime(5, function(inst)
            inst.canTalk2 = true
        end)
    end

    --------------------------------------------------------------------------

    ChangeSkillByEquip(inst, owner)
    inst._listen_owner_equip = function()
        ChangeSkillByEquip(inst, owner)
    end

    inst:ListenForEvent("equip", inst._listen_owner_equip, owner)
    inst:ListenForEvent("unequip", inst._listen_owner_equip, owner)

    --------------------------------------------------------------------------
end

local function OnUnEquip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst:RemoveEventCallback("blocked", OnBlocked, owner)

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    SetFxOwner(inst, nil)

    StopRegen(inst)

    --------------------------------------------------------------------------

    inst:RemoveEventCallback("equip", inst._listen_owner_equip, owner)
    inst:RemoveEventCallback("unequip", inst._listen_owner_equip, owner)
    inst._listen_owner_equip = nil
    --------------------------------------------------------------------------
end

local function OnAttack(inst, attacker, target)
    if target ~= nil then
        if target ~= nil and target:IsValid() then
            local spark = SpawnPrefab("hitsparks_fx")
            spark:Setup(attacker, target, nil)
            spark.black:set(true)
        end

        if target ~= nil and target.components.health ~= nil and target.components.health:GetPercent() <= 0.2 and attacker.components.sanity:GetPercent() <= 0.75 and inst.canTalk then
            SwordTalk(inst, 2)
            inst.canTalk = false
            inst:DoTaskInTime(15, function(inst)
                inst.canTalk = true
            end)
        end

        if attacker.components.sanity ~= nil and GetSetBonusEquip(inst, attacker, true) then
            local inventory = attacker.components.inventory
            local hat = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
            local armor = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil

            if hat ~= nil then
                hat.isonattack = true
            end

            if armor ~= nil then
                armor.isonattack = true
            end

            inst.isonattack = true
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("dreadsword")
    inst.AnimState:SetBuild("dreadsword")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetSymbolBloom("dreadsword_fx")
    inst.AnimState:SetSymbolLightOverride("dreadsword_fx", .6) --该方法可以针对图层设定光覆盖
    inst.AnimState:SetLightOverride(.0)                        --该方法对整个实体贴图设定光覆盖

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("dreadsword")
    inst:AddTag("shadowlevel")
    inst:AddTag("shadow_item")

    local talker = inst:AddComponent("talker")
    talker.fontsize = 30
    talker.font = TALKINGFONT
    talker.colour = Vector3(143 / 255, 41 / 255, 41 / 255)
    talker.offset = Vector3(0, -500, 0)

    local swap_data = { sym_build = "dreadsword", sym_name = "dreadsword" }
    MakeInventoryFloatable(inst, "med", 0.05, { 0.75, 0.4, 0.75 }, true, -13, swap_data)

    -- Weapon skill common
    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true


    inst._skill_define = net_tinybyte(inst.GUID, "inst._skill_define", "inst._skill_define")
    inst._skill_define:set(0)

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("inst._skill_define", OnSkillChangeClient)
        OnSkillChangeClient(inst)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local frame = 1
    inst.AnimState:SetFrame(frame)
    inst.blade1 = SpawnPrefab("fx_dreadsword")
    inst.blade2 = SpawnPrefab("fx_dreadsword")
    inst.blade2.AnimState:PlayAnimation("swap_loop2", true)
    inst.blade1.AnimState:SetFrame(frame)
    inst.blade2.AnimState:SetFrame(frame)
    SetFxOwner(inst, nil)
    inst:ListenForEvent("floater_stopfloating", OnStopFloating)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.DREADSWORD.DAMAGE)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.DREADSWORD.SHADOW_LEVEL)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(TUNING.DREADSWORD.PLANAR_DAMAGE)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.DREADSTONE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.DREADSWORD.USES)
    inst.components.finiteuses:SetUses(TUNING.DREADSWORD.USES)
    inst.components.finiteuses:SetOnFinished(OnFinished)

    inst:AddComponent("equippable")
    inst.components.equippable.is_magic_dapperness = true
    inst.components.equippable.dapperfn = CalcDapperness
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnEquip)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("aoespell")

    inst.isonattack = false
    inst.canTalk = true
    inst.canTalk2 = true

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("inst._skill_define", OnSkillChangeServer)
    OnSkillChangeServer(inst)


    return inst
end

local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("dreadsword")
    inst.AnimState:SetBuild("dreadsword")
    inst.AnimState:PlayAnimation("swap_loop1", true)
    inst.AnimState:SetSymbolBloom("dreadsword_fx")
    inst.AnimState:SetSymbolLightOverride("dreadsword_fx", 1.5)
    inst.AnimState:SetLightOverride(.0)

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("dreadsword", fn, assets, prefabs),
    Prefab("fx_dreadsword", fxfn, fx_dreadsword_assets)
