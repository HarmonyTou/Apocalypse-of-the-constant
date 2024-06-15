local UpvalueUtil = require("utils/upvalueutil")
-- GLOBAL.setfenv(1, GLOBAL)

local function TriggerAbility(sanity_precent)
    if sanity_precent == 1 then
        return math.random() <= 0.35
    elseif sanity_precent == 0 then
        return math.random() <= 0.65
    elseif sanity_precent < 1 and sanity_precent ~= 0 then
        return math.random() <= 0.45
    else
        return false
    end
end

local _DoToolWork = UpvalueUtil.GetUpvalue(ACTIONS.MINE.fn, "DoToolWork")
local function DoToolWork(act, workaction, ...)
    local equip = act.invobject
    local worker = act.doer
    local target = act.target
    local sanity_precent = act.doer ~= nil and act.doer.components.sanity ~= nil and
        act.doer.components.sanity:GetPercent()

    if worker ~= nil and worker.sg ~= nil and worker:HasTag("player") and equip:HasTag("dread_pickaxe") and worker.sg.statemem.recoilstate ~= nil then
        worker.sg:GoToState(worker.sg.statemem.recoilstate, { target = target })
    end

    if target ~= nil and target.components.workable ~= nil and equip:HasTag("dread_pickaxe") and TriggerAbility(sanity_precent) then
        -- Compatible with corals in island adventure
        -- 兼容岛屿冒险(联机海难)中的珊瑚
        if target:HasTag("coral") and target.components.growable.stage ~= 2 and target.components.growable.stage ~= 1 and workaction ~= ACTIONS.HAMMER then
            local pt = Point(target.Transform:GetWorldPosition())
            target.components.growable:SetStage(2)
            target.components.lootdropper:DropLoot(pt)
        else
            target.components.workable.workleft = 1
        end
    end

    return _DoToolWork(act, workaction, ...)
end

UpvalueUtil.SetUpvalue(ACTIONS.MINE.fn, DoToolWork, "DoToolWork")


local _ACTIONS_CASTAOE_strfn = ACTIONS.CASTAOE.strfn
ACTIONS.CASTAOE.strfn = function(act)
    if act.invobject ~= nil and table.contains({ "dreadsword", "dread_lantern" }, act.invobject.prefab) then
        return act.invobject.skillname_index
    end
    return _ACTIONS_CASTAOE_strfn(act)
end


AddAction("AOC_OPEN_DIMENSON_CONTAINER", "AOC_OPEN_DIMENSON_CONTAINER", function(act)
    if act.doer and act.doer:IsValid()
        and act.invobject and act.invobject:IsValid()
        and act.invobject.components.aoc_dimenson_container_linker
        and not act.invobject.components.aoc_dimenson_container_linker:IsOpened() then
        act.invobject.components.aoc_dimenson_container_linker:Open(act.doer)
        return true
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.AOC_OPEN_DIMENSON_CONTAINER, "dread_cloak_open_container"))
AddStategraphActionHandler("wilson_client",
    ActionHandler(ACTIONS.AOC_OPEN_DIMENSON_CONTAINER, "dread_cloak_open_container"))

AddAction("AOC_CLOSE_DIMENSON_CONTAINER", "AOC_CLOSE_DIMENSON_CONTAINER", function(act)
    if act.doer and act.doer:IsValid()
        and act.invobject and act.invobject:IsValid()
        and act.invobject.components.aoc_dimenson_container_linker then
        if act.invobject.components.aoc_dimenson_container_linker:IsOpened() then
            act.invobject.components.aoc_dimenson_container_linker:Close(act.doer)
        end

        return true
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.AOC_CLOSE_DIMENSON_CONTAINER, "dread_cloak_close_container"))
AddStategraphActionHandler("wilson_client",
    ActionHandler(ACTIONS.AOC_CLOSE_DIMENSON_CONTAINER, "dread_cloak_close_container"))


AddComponentAction("INVENTORY", "aoc_dimenson_container_linker", function(inst, doer, actions, right)
    if doer and doer:HasTag("player") and inst.replica.equippable and inst.replica.equippable:IsEquipped() then
        if inst:HasTag("aoc_dimenson_container_opened") then
            table.insert(actions, ACTIONS.AOC_CLOSE_DIMENSON_CONTAINER)
        else
            table.insert(actions, ACTIONS.AOC_OPEN_DIMENSON_CONTAINER)
        end
    end
end)
