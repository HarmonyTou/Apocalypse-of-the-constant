local function postinitfn(sg)
    local old_onenter = sg.states["attack"].onenter
    sg.states["attack"].onenter = function(inst, ...)
        local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if equip ~= nil and equip:HasTag("dreadsword") then
            Util.SetSound("dontstarve/wilson/attack_weapon", "wintersfeast2019/winters_feast/oven/start")
        end

        old_onenter(inst, ...)

        Util.SetSound("dontstarve/wilson/attack_weapon", nil)
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
end

-- TODO: Change this to wilson_client ?
AddStategraphPostInit("wilson_client", postinitfn)


AddStategraphPostInit("wilson_client", function(sg)
    local old_ATTACK = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        local weapon = inst.replica.combat:GetWeapon()
        local target = action.target
        if weapon then
            if weapon.prefab == "lunar_spark_blade" then
                if target and not target:IsNear(inst, weapon.leap_range) then
                    return "lunar_spark_blade_leap_lag"
                end
            end
        end
        return old_ATTACK(inst, action, ...)
    end
end)




AddStategraphState("wilson_client", State {
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
})
