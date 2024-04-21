require("stategraphs/commonstates")
local SoundUtil = require("utils/soundutil")
local ReplaceSound = SoundUtil.ReplaceSound
local AddStategraphState = AddStategraphState
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local states = {
    State {
        name = "lunar_spark_blade_leap",
        tags = { "attack", "busy", "abouttoattack", "pausepredict", "nointerrupt" },
    
        onenter = function(inst, data)
            inst.components.locomotor:Stop()
    
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
    
            inst.sg.statemem.target = target
    
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
    
            inst.Transform:SetEightFaced()
    
    
            inst.AnimState:PlayAnimation("atk_leap")
    
            inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
    
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
        end,
    
        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst)
                local target = inst.sg.statemem.target
                if target then
                    local mypos = inst:GetPosition()
                    local tarpos = target:GetPosition()
    
    
                    local dist = (tarpos - mypos):Length()
                    local duration = 13 * FRAMES
                    -- local speed = math.min(20, dist / duration)
                    local speed = dist / duration
    
                    inst:ForceFacePoint(tarpos)
    
                    inst.Physics:SetMotorVel(speed, 0, 0)
                end
            end),
    
            TimeEvent(13 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("abouttoattack")
                inst.sg:RemoveStateTag("nointerrupt")
    
                inst.Physics:Stop()
    
                inst:PerformBufferedAction()
                -- inst.components.playercontroller:Enable(false)
                ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, inst, 20)
    
                inst.SoundEmitter:PlaySound("dontstarve/common/destroy_smoke", nil, nil, true)
            end),
    
            TimeEvent(24 * FRAMES, function(inst)
                -- inst.sg:RemoveStateTag("busy")
                -- inst.sg:RemoveStateTag("attack")
                -- inst.sg:RemoveStateTag("nointerrupt")
                -- inst.sg:RemoveStateTag("pausepredict")
                -- inst.sg:AddStateTag("idle")
                -- inst.components.playercontroller:Enable(true)
    
                inst.sg:GoToState("idle", true)
            end),
    
        },
    
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    
        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
    
            inst.Transform:SetFourFaced()
    
            inst.Physics:Stop()
            -- inst:DoTaskInTime(0, function(inst)
            --     if inst.components.playercontroller then
            --         inst.components.playercontroller:Enable(true)
            --     end
            -- end)
            -- if inst.components.playercontroller then
            --     inst.components.playercontroller:Enable(true)
            -- end
        end,
    }
}

for _, state in ipairs(states) do
    AddStategraphState("wilson", state)
end

local Old_PlayMiningFX = PlayMiningFX
function PlayMiningFX(inst, target, nosound)
    if target ~= nil and target:IsValid() then
        local frozen = target:HasTag("frozen")
        local moonglass = target:HasTag("moonglass")
        local crystal = target:HasTag("crystal")
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if not equip then
            return Old_PlayMiningFX(inst, target, nosound)
        end
        if target.Transform ~= nil then
            SpawnPrefab(
                (frozen and "mining_ice_fx") or
                (moonglass and "mining_moonglass_fx") or
                (crystal and "mining_crystal_fx") or
                "mining_fx"
            ).Transform:SetPosition(target.Transform:GetWorldPosition())
        end
        if not nosound and inst.SoundEmitter ~= nil then
            inst.SoundEmitter:PlaySound(
                (frozen and "dontstarve_DLC001/common/iceboulder_hit") or
                ((moonglass or crystal) and "turnoftides/common/together/moon_glass/mine") or
                (equip:HasTag("dread_pickaxes") and "daywalker/pillar/pickaxe_hit_unbreakable") or
                "dontstarve/wilson/use_pick_rock"
            )
        end
    else
        Old_PlayMiningFX(inst, target, nosound)
    end
end

local function postinitfn(sg)
    -- 获取原来的attack状态中onenter函数
    local old_attack_onenter = sg.states["attack"].onenter
    sg.states["attack"].onenter = function(inst, ...)
        -- 获取手中的装备
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        -- 如果装备存在且装备有dreadsword标签，那么将attack_weapon替换为hit_metal
        if equip ~= nil and equip:HasTag("dreadsword") then
            ReplaceSound("dontstarve/wilson/attack_weapon", "rifts2/thrall_wings/projectile")
        end

        -- 执行原来的onenter函数
        old_attack_onenter(inst, ...)

        -- 播放完后把音效改回去
        ReplaceSound("dontstarve/wilson/attack_weapon", nil)
    end

    local mine_timeevent = TimeEvent(7 * FRAMES, function(inst)
        if inst.sg.statemem.action ~= nil then
            PlayMiningFX(inst, inst.sg.statemem.action.target)
        end
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equip ~= nil and equip:HasTag("dread_pickaxe") then
            inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
        end
        inst.sg.statemem.recoilstate = "mine_recoil"
        inst:PerformBufferedAction()
    end)

    local old_hammer_timeline = sg.states["mine"].timeline
    table.remove(old_hammer_timeline, 1)
    table.insert(old_hammer_timeline, 1, mine_timeevent)

    local mine_recoil_timeevent = TimeEvent(7 * FRAMES, function(inst)
        inst.sg.statemem.recoilstate = "mine_recoil"
        inst.SoundEmitter:PlaySound(inst.sg.statemem.action ~= nil and inst.sg.statemem.action.invobject ~= nil and
            inst.sg.statemem.action.invobject.hit_skin_sound or "dontstarve/wilson/hit")
        inst:PerformBufferedAction()
    end)

    local old_hammer_timeline = sg.states["hammer"].timeline
    table.remove(old_hammer_timeline, 1)
    table.insert(old_hammer_timeline, 1, mine_recoil_timeevent)

    local old_CASTAOE = sg.actionhandlers[ACTIONS.CASTAOE].deststate
    sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
        local weapon = action.invobject
        if weapon then
            local can_cast = weapon.components.aoetargeting:IsEnabled()
                and (weapon.components.rechargeable == nil or weapon.components.rechargeable:IsCharged())

            if can_cast then
                if weapon.prefab == "dreadsword" and weapon._skill_define:value() == 1 then
                    return "scythe"
                end
                -- if weapon.prefab == "dread_lantern" then
                --     if inst.IsChannelCasting then
                --         if not inst:IsChannelCasting() then
                --             return "start_channelcast"
                --         elseif inst:IsChannelCastingItem() then
                --             return "stop_channelcast"
                --         end
                --     end
                -- end
            end
        end
        return old_CASTAOE(inst, action)
    end

    local old_ATTACK = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        local weapon = inst.components.combat:GetWeapon()
        local target = action.target
        if weapon then
            if weapon.prefab == "lunar_spark_blade" then
                if target and not target:IsNear(inst, weapon.leap_range) then
                    return "lunar_spark_blade_leap"
                end
            end
        end
        return old_ATTACK(inst, action, ...)
    end
end

AddStategraphPostInit("wilson", postinitfn)
