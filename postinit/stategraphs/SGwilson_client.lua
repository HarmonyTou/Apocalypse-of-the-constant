local SoundUtil = require("utils/soundutil")
local ReplaceSound = SoundUtil.ReplaceSound
local AddStategraphState = AddStategraphState
local AddStategraphPostInit = AddStategraphPostInit
local AddStategraphActionHandler = AddStategraphActionHandler
GLOBAL.setfenv(1, GLOBAL)

local function ClearCachedServerState(inst)
    if inst.player_classified ~= nil then
        inst.player_classified.currentstate:set_local(0)
    end
end

local actionhandlers = {
    ActionHandler(ACTIONS.AOC_OPEN_DIMENSON_CONTAINER, "dread_cloak_open_container"),
    ActionHandler(ACTIONS.AOC_CLOSE_DIMENSON_CONTAINER, "dread_cloak_close_container"),
}

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
        server_states = { "chop_attack" },

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
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
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

    State {
        name = "lunar_spark_blade_scythe_attack",
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


            inst.AnimState:PlayAnimation("scythe_pre")
            inst.AnimState:PushAnimation("scythe_loop", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(2)
        end,

        timeline = {
            FrameEvent(15, function(inst)
                inst:ClearBufferedAction()
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
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.replica.combat:CancelAttack()
            end
        end,
    },

    -- State {
    --     name = "dread_cloak_start_using_container",
    --     tags = { "doing", "busy", "nodangle" },

    --     onenter = function(inst)
    --         inst.components.locomotor:Stop()
    --         inst.AnimState:PlayAnimation("build_pre")
    --         inst.AnimState:PushAnimation("build_loop", true)

    --         inst:PerformPreviewBufferedAction()
    --     end,

    --     timeline =
    --     {
    --         TimeEvent(4 * FRAMES, function(inst)
    --             inst.sg:RemoveStateTag("busy")
    --         end),
    --     },

    --     onexit = function(inst)

    --     end,
    -- },


    State {
        name = "dread_cloak_open_container",
        tags = { "doing", },
        server_states = { "dread_cloak_open_container", },


        onenter = function(inst)
            inst.components.locomotor:Stop()



            inst:PerformPreviewBufferedAction()

            inst.entity:SetIsPredictingMovement(false)

            ClearCachedServerState(inst)

            inst.sg.statemem.anim_played = false

            inst.sg:SetTimeout(2)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if not inst.sg.statemem.anim_played and inst.entity:FlattenMovementPrediction() then
                    if inst.AnimState:IsCurrentAnimation("build_pre") then
                        inst.AnimState:PushAnimation("build_loop", true)
                    elseif inst.AnimState:IsCurrentAnimation("build_loop") then

                    else
                        inst.AnimState:PlayAnimation("build_pre")
                        inst.AnimState:PushAnimation("build_loop", true)
                    end
                    inst.sg.statemem.anim_played = true
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("build_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            if inst.bufferedaction ~= nil and inst.bufferedaction.ispreviewing then
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
            end
        end,

        events =
        {

        },

        onexit = function(inst)
            inst.entity:SetIsPredictingMovement(true)
        end,
    },

    State {
        name = "dread_cloak_close_container",

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst:PerformPreviewBufferedAction()

            inst.AnimState:PlayAnimation("build_pst")
            inst.sg:GoToState("idle", true)
        end,
    },
}

for _, state in ipairs(states) do
    AddStategraphState("wilson_client", state)
end

local function fn(sg)
    local _attack_onenter = sg.states["attack"].onenter
    sg.states["attack"].onenter = function(inst, ...)
        local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if equip ~= nil and equip:HasTag("dreadsword") then
            ReplaceSound("dontstarve/wilson/attack_weapon", "rifts2/thrall_wings/projectile")
        end

        if _attack_onenter ~= nil then
            _attack_onenter(inst, ...)
        end

        ReplaceSound("dontstarve/wilson/attack_weapon", nil)
    end

    local _castaoe_actionhandler = sg.actionhandlers[ACTIONS.CASTAOE].deststate
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
                if weapon.prefab == "lunar_spark_blade" then
                    inst:PerformPreviewBufferedAction()
                    return
                end

                if weapon.prefab == "dread_axe" then
                    return "throw_line"
                end
            end
        end

        if _castaoe_actionhandler ~= nil then
            return _castaoe_actionhandler(inst, action)
        end
    end

    local _attack_actionhandler = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or IsEntityDead(inst)) then
            local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local inventoryitem = weapon ~= nil and weapon.replica.inventoryitem
            if (inventoryitem ~= nil and inventoryitem:IsWeapon()) then
                local target = action.target
                if weapon then
                    if weapon.prefab == "lunar_spark_blade" then
                        if target and weapon._leap_range:value() > 0 and not target:IsNear(inst, weapon._leap_range:value()) then
                            return "lunar_spark_blade_leap_lag"
                        else
                            return "lunar_spark_blade_scythe_attack"
                        end
                    elseif weapon:HasTag("chop_attack") then
                        return "chop_attack"
                    end
                end
            end
        end

        if _attack_actionhandler ~= nil then
            return _attack_actionhandler(inst, action, ...)
        end
    end

    -- local _start_channelcast_actionhandler = sg.actionhandlers[ACTIONS.START_CHANNELCAST].deststate
    -- sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
    --     local item = action.invobject
    --     if item and item.prefab == "dread_cloak" then
    --         return "dread_cloak_start_using_container"
    --     end

    --     return FunctionOrValue(_start_channelcast_actionhandler, inst, action, ...)
    -- end

    -- local _stop_channelcast_actionhandler = sg.actionhandlers[ACTIONS.STOP_CHANNELCAST].deststate
    -- sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
    --     local item = action.invobject
    --     if item and item.prefab == "dread_cloak" then
    --         return "dread_cloak_stop_using_container"
    --     end

    --     return FunctionOrValue(_stop_channelcast_actionhandler, inst, action, ...)
    -- end
end

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilson_client", actionhandler)
end

AddStategraphPostInit("wilson_client", fn)
