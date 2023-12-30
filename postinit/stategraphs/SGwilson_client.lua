local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local function postinitfn(sg)
    local attack_onenter = sg.states["attack"].onenter
    sg.states["attack"].onenter = function(inst, ...)
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if equip ~= nil and equip:HasTag("dreadsword") then
            Util.SetSound("dontstarve/wilson/attack_weapon", "wintersfeast2019/winters_feast/oven/start")
        end

        attack_onenter(inst, ...)

        Util.SetSound("dontstarve/wilson/attack_weapon", nil)
    end
end

AddStategraphPostInit("wilson_client", postinitfn)
