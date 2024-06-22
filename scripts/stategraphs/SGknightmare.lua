require("stategraphs/commonstates")



local AOE_RANGE_PADDING = 3
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost","abyss" }

local function AOEAttack(inst, dist, radius, targets, mult)
    inst.components.combat.ignorehitrange = true

    local x, y, z = inst.Transform:GetWorldPosition()
    local cos_theta, sin_theta

    if dist ~= 0 then
        local theta = inst.Transform:GetRotation() * DEGREES
        cos_theta = math.cos(theta)
        sin_theta = math.sin(theta)

        x = x + dist * cos_theta
        z = z - dist * sin_theta
    end

    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + AOE_RANGE_PADDING, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
        if v ~= inst and
            not (targets and targets[v]) and
            v:IsValid() and not v:IsInLimbo() and
            not (v.components.health and v.components.health:IsDead())
        then
            local range = radius + v:GetPhysicsRadius(0)
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local dx = x1 - x
            local dz = z1 - z

            if dx * dx + dz * dz < range * range and inst.components.combat:CanTarget(v) then
                inst.components.combat:DoAttack(v)
                if targets then
                    targets[v] = true
                end
                if mult then
                    v:PushEvent("knockback", { knocker = inst, radius = radius + dist, strengthmult = mult })
                end
            end
        end
    end

    inst.components.combat.ignorehitrange = false
end

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local events=
{
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnDeath(),
    EventHandler("attacked", function(inst,data)
        if not inst.components.health:IsDead() then
            if inst.sg:HasStateTag("parrying") then
                if data.redirected then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_hit")
                    inst.sg:GoToState("combat_leap_start",data.target)
                else
                    inst.sg.statemem.parrying = nil
                    inst.sg:GoToState("hit")  
                end
            end        
            if not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("hit")  
            end        
        end
    end),
    EventHandler("leap_atk", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            inst.components.timer:StartTimer("leap_cd", 20) 
            inst.sg:GoToState("combat_leap_start",inst.components.combat.target)
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
                and (data.target ~= nil and data.target:IsValid()) then
            inst.sg:GoToState("attack",data.target)                 
        end            
    end),
    EventHandler("entershield", function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            local target = inst.components.combat.target
            local direction
            if target~=nil and target:IsValid() then
                local pos =target:GetPosition()
                direction =  inst:GetAngleToPoint(pos)
            end
            inst.sg:GoToState("parry_pre",{direction = direction})
        end
    end),
    EventHandler("exitshield", function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead() and inst.sg.statemem.parrying then
            inst.sg:GoToState("parry_pst")
        end
    end),
}

local function OnAnimOver(state)
    return {
        EventHandler("animover", function(inst) inst.sg:GoToState(state) end),
    }
end


local states =
{
    State{
        name = "idle",

        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_sanity_pre")
            inst.AnimState:PushAnimation("idle_sanity_loop")
        end,

    },
      

    State{
        name = "taunt",
        tags = {"busy","canrotate"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pyrocast_pre") --4 frames
			inst.AnimState:PushAnimation("pyrocast", false)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "hit",
        tags = {"hit"},
        onenter = function (inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("parry_pre")
            inst.AnimState:PushAnimation("parry_loop", true)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        events = OnAnimOver("idle")
    },

    State{
        name = "parry_pre",
        tags = {"preparrying", "busy","shield"},
        onenter = function (inst,data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("parry_pre")
            inst.AnimState:PushAnimation("parry_loop", true)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            if data ~= nil then
                if data.direction ~= nil then
                    inst.Transform:SetRotation(data.direction)
                end
            end
            local weapon2 = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if weapon2 ~= nil then
                inst.components.combat.redirectdamagefn = function(inst, attacker, damage, weapon, stimuli)
                    return 
                         weapon2.components.parryweapon:TryParry(inst, attacker, damage, weapon, stimuli)
                        and weapon2
                        or nil
                end
            end
        end,
        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst)
                inst.sg:AddStateTag("parrying")
                
            end),
        },
        onexit = function(inst)
            if not inst.sg.statemem.parrying then
                inst.components.combat.redirectdamagefn = nil
            end
        end,
        ontimeout = function(inst)
            if inst.sg:HasStateTag("parrying") then
                inst.sg.statemem.parrying = true
                --Transfer talk task to parry_idle state
                inst.sg:GoToState("parry_idle", { duration = inst.sg.statemem.parrytime, pauseframes = 30})
            else
                inst.AnimState:PlayAnimation("parry_pst")
                inst.sg:GoToState("idle", true)
            end
        end,
    },

    State{
        name = "parry_idle",
        tags = { "parrying","busy","shield"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            if not inst.AnimState:IsCurrentAnimation("parry_loop") then
                inst.AnimState:PlayAnimation("parry_loop", true)
            end
            inst.sg.statemem.parrying = true
        end,
        onupdate = function (inst)
            local target = inst.components.combat.target
            if target~=nil and target:IsValid() then
                local pos = target:GetPosition()
                local rot = inst.Transform:GetRotation()
				local rot1 = inst:GetAngleToPoint(pos)
                local drot = ReduceAngle(rot1 - rot)
				rot1 = rot + math.clamp(drot, -1, 1)
				inst.Transform:SetRotation(rot1)
            end
        end,

        onexit = function(inst)           
            inst.components.combat.redirectdamagefn = nil
        end,
    },

    State{
        name = "parry_pst",
        tags = {"idle"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("parry_pst")
            inst.components.combat.redirectdamagefn = nil
        end,
        
        events = OnAnimOver("idle")
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            if target ~= nil then
                --inst.components.combat:BattleCry()
                if target:IsValid() then
                    inst:ForceFacePoint(target:GetPosition())
                    inst.sg.statemem.target = target
                end
            end
            
        end,

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end)
        },
        events = OnAnimOver("idle"),
    },

    State{
        name = "combat_leap_start",
        tags = {"attack", "longattack", "busy", "jumping"},

        onenter = function(inst,target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_leap_pre")
            if target and target:IsValid() then
                inst.sg.statemem.target = target
                inst.components.combat:StartAttack()
            end
              
        end,
        onupdate = function(inst)
            if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then             
                inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())  
            end          
        end, 
        events =
        {
            EventHandler("animover", function(inst)
                inst.AnimState:PlayAnimation("atk_leap_lag")
                inst.sg:GoToState("combat_leap",inst.sg.statemem.target )
            end),
        },
    },

    State {
        name = "combat_leap",
        tags = {"attack", "longattack", "busy", "jumping"},
        onenter = function(inst, target)
            
            inst.AnimState:PlayAnimation("atk_leap", false)
            inst.Transform:SetEightFaced()
            ToggleOffPhysics(inst)
            inst.sg.statemem.target=target
            
            inst.sg.statemem.startingpos = inst:GetPosition()
            if inst.sg.statemem.target ~= nil then
                inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
            else
                inst.sg.statemem.targetpos=inst:GetPosition()
            end
            if inst.sg.statemem.startingpos.x ~= inst.sg.statemem.targetpos.x or inst.sg.statemem.startingpos.z ~= inst.sg.statemem.targetpos.z then
                inst.leap_velocity = math.min(math.sqrt(distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z,
                                                        inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)) / (12 * FRAMES),28)
                inst:ForceFacePoint(inst.sg.statemem.targetpos:Get())
                inst.Physics:SetMotorVel(inst.leap_velocity,0,0)
            end
            inst.sg.statemem.flash = 0
        end,
        onupdate = function(inst)
            if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
                inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
                local c = math.min(1, inst.sg.statemem.flash)
                inst.components.colouradder:PushColour("leap", c, c, 0, 0)
            end
        end,
        timeline = {
            TimeEvent( FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
                
                inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/jump")
            end),
            TimeEvent(10 * FRAMES, function(inst) 
                if inst.sg.statemem.flash then 
                    inst.components.colouradder:PushColour("leap", .1, .1, 0, 0) 
                end 
            end),
            TimeEvent(11 * FRAMES, function(inst) 
                if inst.sg.statemem.flash then 
                    inst.components.colouradder:PushColour("leap", .2, .2, 0, 0) 
                end
             end),
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                     inst.components.colouradder:PushColour("leap", .4, .4, 0, 0) 
                    end
                inst.components.locomotor:Stop()
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                --inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
                ToggleOnPhysics(inst)
            end),
            TimeEvent(13 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                    inst.components.bloomer:PushBloom("leap", "shaders/anim.ksh", -2)
                    inst.components.colouradder:PushColour("leap", 1, 1, 0, 0)
                    inst.sg.statemem.flash = 1.3
                    
                end
                AOEAttack(inst,0,5)
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            end),
            TimeEvent(25 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                    inst.components.bloomer:PopBloom("leap")
                end
            end),
        },
        
        onexit = function(inst)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                local x, y, z = inst.Transform:GetWorldPosition()
                if TheWorld.Map:IsPassableAtPoint(x, 0, z) and not TheWorld.Map:IsGroundTargetBlocked(Vector3(x, 0, z)) then
                    inst.Physics:Teleport(x, 0, z)
                else
                    inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
                end
            end
            inst.Transform:SetFourFaced()
            if inst.sg.statemem.flash then
                inst.components.bloomer:PopBloom("leap")
                inst.components.colouradder:PopColour("leap")
            end
        end,
        events = OnAnimOver("idle")
    },

    State{
        name = "death",
        tags = {"busy", "dead"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("death")
            inst.AnimState:Hide("swap_arm_carry")
            inst.SoundEmitter:PlaySound("dontstarve/sanity/creature1/die")
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            inst:AddTag("NOCLICK")
            inst.persists = false
            
        end,
        
        timeline=
        {
            FrameEvent(10, function(inst)
			    SpawnPrefab("shadow_despawn").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end)
        },
    },

}



CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(0, PlayFootstep),
        TimeEvent(12 * FRAMES, PlayFootstep),
    },
})


CommonStates.AddRunStates(states,
{
	runtimeline = {
		TimeEvent(0*FRAMES, PlayFootstep ),
		TimeEvent(10*FRAMES, PlayFootstep ),
	},
})
    
return StateGraph("knightmare", states, events, "idle")