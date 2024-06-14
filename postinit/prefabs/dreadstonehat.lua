local AddPrefabPostInit = AddPrefabPostInit
local UpvalueUtil = require("utils/upvalueutil")
-- GLOBAL.setfenv(1, GLOBAL)

local function DoRegen(inst, owner)
    if owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode() then
        local setbonus = inst.components.setbonus ~= nil and
            inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.DREADSTONE) and TUNING.ARMOR_DREADSTONE_REGEN_SETBONUS or
            1
        local rate = 1 /
            Lerp(1 / TUNING.ARMOR_DREADSTONE_REGEN_MAXRATE, 1 / TUNING.ARMOR_DREADSTONE_REGEN_MINRATE,
                owner.components.sanity:GetPercent())
        if inst.isonattack then
            rate = rate * 4
        end
        inst.components.armor:Repair(inst.components.armor.maxcondition * rate * setbonus)
    end

    if inst.isonattack then
        inst.task = inst:DoPeriodicTask(TUNING.ARMOR_DREADSTONE_REGEN_PERIOD, function()
            inst.isonattack = false
            if inst.task then
                inst.task:Cancel()
                inst.task = nil
            end
        end)
    end

    if not inst.components.armor:IsDamaged() then
        inst.regentask:Cancel()
        inst.regentask = nil
    end
end

local function dreadstone_startregen(inst, owner)
    if inst.regentask == nil then
        inst.regentask = inst:DoPeriodicTask(TUNING.ARMOR_DREADSTONE_REGEN_PERIOD, DoRegen, nil, owner)
    end
end

local function dreadstone_stopregen(inst)
    if inst.regentask ~= nil then
        inst.regentask:Cancel()
        inst.regentask = nil
    end

    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function postinitfn(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst.isonattack = false

    -- Hook
    local _OnEquip = inst.components.equippable.onequipfn
    local _OnUnequip = inst.components.equippable.onunequipfn

    UpvalueUtil.SetUpvalue(_OnEquip, dreadstone_startregen, "dreadstone_startregen")
    UpvalueUtil.SetUpvalue(_OnUnequip, dreadstone_stopregen, "dreadstone_stopregen")
end

AddPrefabPostInit("dreadstonehat", postinitfn)
