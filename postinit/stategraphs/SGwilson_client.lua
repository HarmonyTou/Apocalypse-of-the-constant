local SoundUtil = require("utils/soundutil")
local ReplaceSound = SoundUtil.ReplaceSound
local AddStategraphState = AddStategraphState
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local states = {
    State {
        name = "lunar_spark_blade_leap_lag",
        tags = { "busy" },
        server_states = { "lunar_spark_blade_leap" },


        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_leap_pre")
            inst.AnimState:PlayAnimation("atk_leap_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(2)
        end,

        onupdate = function(inst)
            -- if inst.sg:ServerStateMatches() then
            --     if inst.entity:FlattenMovementPrediction() then
            --         inst.sg:GoToState("idle", "atk_leap_lag")
            --     end
            -- elseif inst.bufferedaction == nil then
            --     inst.sg:GoToState("idle")
            -- end

            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State {
        name = "chop_attack",
        tags = { "attack", "notalking", "abouttoattack" },

        onenter = function(inst)
            local combat = inst.replica.combat
            if combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
                return
            end

            local cooldown = combat:MinAttackPeriod()
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
            end
            combat:StartAttack()
            inst.components.locomotor:Stop()
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip ~= nil then
                inst.AnimState:PlayAnimation(inst.AnimState:IsCurrentAnimation("woodie_chop_loop") and
                    inst.AnimState:GetCurrentAnimationFrame() <= 7 and "woodie_chop_atk_pre" or "woodie_chop_pre")
                inst.AnimState:PushAnimation("woodie_chop_loop", false)
                inst.sg.statemem.ischop = true
                cooldown = math.max(cooldown, 11 * FRAMES)
            end

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.target ~= nil and buffaction.target:IsValid() then
                    inst:FacePoint(buffaction.target:GetPosition())
                    inst.sg.statemem.attacktarget = buffaction.target
                    inst.sg.statemem.retarget = buffaction.target
                end
            end

            if cooldown > 0 then
                inst.sg:SetTimeout(cooldown)
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
                inst:ClearBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end),
        },

        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.replica.combat:CancelAttack()
            end
        end,
    },
}

for _, state in ipairs(states) do
    AddStategraphState("wilson_client", state)
end

local function fn(sg)
    local old_onenter = sg.states["attack"].onenter
    sg.states["attack"].onenter = function(inst, ...)
        local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if equip ~= nil and equip:HasTag("dreadsword") then
            ReplaceSound("dontstarve/wilson/attack_weapon", "wintersfeast2019/winters_feast/oven/start")
        end

        old_onenter(inst, ...)

        ReplaceSound("dontstarve/wilson/attack_weapon", nil)
    end

    local old_CASTAOE = sg.actionhandlers[ACTIONS.CASTAOE].deststate
    sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
        local weapon = action.invobject
        if weapon then
            local can_cast = weapon.components.aoetargeting:IsEnabled()

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

    local attack_actionhandler = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or IsEntityDead(inst)) then
            local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local inventoryitem = weapon.replica.inventoryitem
            if (inventoryitem ~= nil and inventoryitem:IsWeapon()) then
                local target = action.target
                if weapon then
                    if weapon.prefab == "lunar_spark_blade" then
                        if target and not target:IsNear(inst, weapon._leap_range:value()) then
                            return "lunar_spark_blade_leap_lag"
                        else
                            return "scythe"
                        end
                    elseif weapon:HasTag("chop_attack") then
                        return "chop_attack"
                    end
                end
            end
        end

        if attack_actionhandler ~= nil then
            return attack_actionhandler(inst, action, ...)
        end
    end
end

AddStategraphPostInit("wilson_client", fn)
