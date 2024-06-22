require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/wander"
require "behaviours/useshield"


local GOHOMEDSQ = 900
local CHASETIME = 20
local CHASEDIST = 30

local SHIELDTRIGGER = 500


local use_shield_data =
{
    dontupdatetimeonattack = true,
    usecustomanims = true,
    dontshieldforfire = true,
}

local function GoHomeAction(inst)
    local spawnpoint_position = inst.components.knownlocations:GetLocation("spawnpoint")
    if spawnpoint_position == nil or inst:GetDistanceSqToPoint(spawnpoint_position:Get()) < GOHOMEDSQ then
        return nil
    else
        return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, spawnpoint_position)
    end
end

local function ShouldUseAbility(self)
    local target = self.inst.components.combat.target
    --local dsq_to_target = self.inst:GetDistanceSqToInst(target)
    self.abilityname = target~=nil and 
        (self.inst.shouldparry and "entershield") or 
        (not self.inst.components.timer:TimerExists("leap_cd") and "leap_atk")
     or nil
    return self.abilityname ~= nil
end

  

local KnightmareBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)



function KnightmareBrain:OnStart()


    local root =
        PriorityNode(
        {   
            WhileNode(function() return not self.inst.sg:HasStateTag("jumping") end, "Should Attack",
                PriorityNode({
                    UseShield(self.inst, SHIELDTRIGGER, 30, nil, nil, use_shield_data),
                    WhileNode(function() return ShouldUseAbility(self) end, "Ability",
                    ActionNode(function()
                        self.inst:PushEvent(self.abilityname)
                        self.abilityname=nil
                    end)),
                    ChaseAndAttack(self.inst,CHASETIME,CHASEDIST),
                    DoAction(self.inst, GoHomeAction),
                    StandStill(self.inst),

            }))
        },0.5)
    
    self.bt = BT(self.inst, root)


end

function KnightmareBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
end

return KnightmareBrain