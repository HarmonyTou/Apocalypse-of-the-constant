require("stategraphs/commonstates")
local SoundUtil = require("utils/soundutil")
local ReplaceSound = SoundUtil.ReplaceSound
local StateGraphUtil = require("utils/stategraphutil")
local AddTimeEventPostInit = StateGraphUtil.AddTimeEventPostInit
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
            local weapon = inst.components.combat:GetWeapon()
            inst.sg.statemem.target = target
            inst.sg.statemem.weapon = weapon

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

                local target = inst.sg.statemem.target
                local weapon = inst.sg.statemem.weapon

                -- print(target, target:IsValid())
                -- print(weapon, weapon:IsValid())

                if target and target:IsValid() and weapon and weapon:IsValid() and weapon.prefab == "lunar_spark_blade" then
                    local delta_vec = (target:GetPosition() - inst:GetPosition()):GetNormalized()
                    local spawn_pos = inst:GetPosition() + delta_vec * 3

                    weapon._leap_fx_pos_x:set(spawn_pos.x)
                    weapon._leap_fx_pos_z:set(spawn_pos.z)
                    weapon._leap_fx_spawn_event:push()
                end


                -- inst.components.playercontroller:Enable(false)
                ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, inst, 20)

                inst.SoundEmitter:PlaySound("Aoc/spark", nil, nil, true)
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
    },

    State {
        name = "chop_attack",
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },

        onenter = function(inst)
            if inst.components.combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
                return
            end
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
            end
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local cooldown = inst.components.combat.min_attack_period
            if equip ~= nil then
                inst.AnimState:PlayAnimation(inst.AnimState:IsCurrentAnimation("woodie_chop_loop") and
                    inst.AnimState:GetCurrentAnimationFrame() <= 7 and "woodie_chop_atk_pre" or "woodie_chop_pre")
                inst.AnimState:PushAnimation("woodie_chop_loop", false)
                inst.sg.statemem.ischop = true
                cooldown = math.max(cooldown, 11 * FRAMES)
            end

            inst.sg:SetTimeout(cooldown)

            if target ~= nil then
                inst.components.combat:BattleCry()
                if target:IsValid() then
                    inst:FacePoint(target:GetPosition())
                    inst.sg.statemem.attacktarget = target
                    inst.sg.statemem.retarget = target
                end
            end
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                if inst.sg.statemem.ischop then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end),
        },

        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
        end,
    },

    State {
        name = "lunar_spark_blade_scythe_attack",
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },

        onenter = function(inst)
            if inst.components.combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
                return
            end

            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
            end

            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("scythe_pre")
            inst.AnimState:PushAnimation("scythe_loop", false)
        end,

        timeline =
        {
            -- FrameEvent(14, function(inst)
            --     inst.SoundEmitter:PlaySound("rifts2/thrall_wings/projectile")
            -- end),
            -- FrameEvent(15, function(inst)
            --     inst:PerformBufferedAction()
            --     inst.sg:RemoveStateTag("abouttoattack")
            -- end),
            -- FrameEvent(18, function(inst)
            --     inst.sg:RemoveStateTag("attack")
            --     inst.sg:AddStateTag("idle")
            -- end),

            FrameEvent(5, function(inst)
                inst.SoundEmitter:PlaySound("grotto/creatures/centipede/attack")
            end),
            FrameEvent(15, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end),
            FrameEvent(18, function(inst)
                inst.sg:GoToState("idle", true)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        },

        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
        end,
    },

    State {
        name = "lunar_spark_blade_skill_entry",
        tags = { "aoe", "doing", "busy", "nointerrupt", "nomorph", "nopredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("lunge_lag")
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("combat_lunge", function(inst, data)
                inst.sg:GoToState("combat_lunge", data)
            end),
        },
    },
}

for _, state in ipairs(states) do
    AddStategraphState("wilson", state)
end

-- local _PlayMiningFX = PlayMiningFX
-- overwrite it
function PlayMiningFX(inst, target, nosound)
    if target ~= nil and target:IsValid() then
        local frozen = target:HasTag("frozen")
        local moonglass = target:HasTag("moonglass")
        local crystal = target:HasTag("crystal")
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
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
                (equip ~= nil and equip:HasTag("dread_pickaxes") and "daywalker/pillar/pickaxe_hit_unbreakable") or
                "dontstarve/wilson/use_pick_rock"
            )
        end
    end
end

local function fn(sg)
    -- 获取原来的attack状态中onenter函数
    local _attack_onenter = sg.states["attack"].onenter
    sg.states["attack"].onenter = function(inst, ...)
        -- 获取手中的装备
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        -- 如果装备存在且装备有dreadsword标签，那么将attack_weapon替换为hit_metal
        if equip ~= nil and equip:HasTag("dreadsword") then
            ReplaceSound("dontstarve/wilson/attack_weapon", "rifts2/thrall_wings/projectile")
        end

        -- 执行原来的onenter函数
        if _attack_onenter ~= nil then
            _attack_onenter(inst, ...)
        end

        -- 播放完后把音效改回去
        ReplaceSound("dontstarve/wilson/attack_weapon", nil)
    end

    AddTimeEventPostInit(sg, "mine", 1, function(inst)
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equip ~= nil and equip:HasTag("dread_pickaxe") then
            inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
        end
    end)

    local _castaoe_actionhandler = sg.actionhandlers[ACTIONS.CASTAOE].deststate
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

                if weapon.prefab == "lunar_spark_blade" then
                    return "lunar_spark_blade_skill_entry"
                end
            end
        end

        if _castaoe_actionhandler ~= nil then
            return _castaoe_actionhandler(inst, action)
        end
    end

    local _attack_actionhandler = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        inst.sg.mem.localchainattack = not action.forced or nil
        local playercontroller = inst.components.playercontroller
        local attack_tag =
            playercontroller ~= nil and
            playercontroller.remote_authority and
            playercontroller.remote_predicting and
            "abouttoattack" or
            "attack"
        local target = action.target
        if not (inst.sg:HasStateTag(attack_tag) and action.target == inst.sg.statemem.attacktarget or inst.components.health:IsDead()) then
            local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil
            if weapon ~= nil then
                if weapon.prefab == "lunar_spark_blade" then
                    if target and weapon._leap_range:value() > 0 and not target:IsNear(inst, weapon._leap_range:value()) then
                        return "lunar_spark_blade_leap"
                    else
                        return "lunar_spark_blade_scythe_attack"
                    end
                elseif weapon:HasTag("chop_attack") then
                    return "chop_attack"
                end
            end
        end

        if _attack_actionhandler ~= nil then
            return _attack_actionhandler(inst, action, ...)
        end
    end
end

AddStategraphPostInit("wilson", fn)
