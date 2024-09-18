local UpvalueUtil = require("utils/upvalueutil")
local AddComponentAction = AddComponentAction
local AddAction = AddAction
GLOBAL.setfenv(1, GLOBAL)

local AOC_ACTIONS = {
    AOC_OPEN_DIMENSON_CONTAINER = Action(),
    AOC_CLOSE_DIMENSON_CONTAINER = Action(),
}

for name, ACTION in pairs(AOC_ACTIONS) do
    ACTION.id = name
    ACTION.str = STRINGS.ACTIONS[name] or "Unknown ACTION"
    AddAction(ACTION)
end

ACTIONS.AOC_OPEN_DIMENSON_CONTAINER.fn = function(act)
    if act.doer and act.doer:IsValid()
        and act.invobject and act.invobject:IsValid()
        and act.invobject.components.aoc_dimenson_container_linker
        and not act.invobject.components.aoc_dimenson_container_linker:IsOpened() then
        act.invobject.components.aoc_dimenson_container_linker:Open(act.doer)
        return true
    end
end

ACTIONS.AOC_CLOSE_DIMENSON_CONTAINER.fn = function(act)
    if act.doer and act.doer:IsValid()
        and act.invobject and act.invobject:IsValid()
        and act.invobject.components.aoc_dimenson_container_linker then
        if act.invobject.components.aoc_dimenson_container_linker:IsOpened() then
            act.invobject.components.aoc_dimenson_container_linker:Close(act.doer)
        end
        return true
    end
end

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
    local sanity_precent = worker ~= nil and worker.components.sanity ~= nil and
    worker.components.sanity:GetPercent()

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


local AOC_COMPONENT_ACTIONS = {
    SCENE = {
    },

    USEITEM = {
    },

    POINT = {
    },

    EQUIPPED = {
    },

    INVENTORY = {
        aoc_dimenson_container_linker = function(inst, doer, actions, right)
            if doer and doer:HasTag("player") and inst.replica.equippable and inst.replica.equippable:IsEquipped() then
                if inst:HasTag("aoc_dimenson_container_opened") then
                    table.insert(actions, ACTIONS.AOC_CLOSE_DIMENSON_CONTAINER)
                else
                    table.insert(actions, ACTIONS.AOC_OPEN_DIMENSON_CONTAINER)
                end
            end
        end
    },

    ISVALID = {
    },
}

for actiontype, actons in pairs(AOC_COMPONENT_ACTIONS) do
    for component, fn in pairs(actons) do
        AddComponentAction(actiontype, component, fn)
    end
end
