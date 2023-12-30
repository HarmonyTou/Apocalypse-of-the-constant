local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

require("stategraphs/commonstates")

local _PlayMiningFX = PlayMiningFX
function PlayMiningFX(inst, target, nosound)
    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if target ~= nil and target:IsValid() and equip:HasTag("dread_pickaxes") then
        local frozen = target:HasTag("frozen")
        local moonglass = target:HasTag("moonglass")
        local crystal = target:HasTag("crystal")
        if target.Transform ~= nil then
            SpawnPrefab(
                (frozen and "mining_ice_fx") or
                (moonglass and "mining_moonglass_fx") or
                (crystal and "mining_crystal_fx") or
                "mining_fx"
            ).Transform:SetPosition(target.Transform:GetWorldPosition())
        end
        if not nosound and inst.SoundEmitter ~= nil   then
            inst.SoundEmitter:PlaySound(
                "daywalker/pillar/pickaxe_hit_unbreakable"
            )
        end
    else
        _PlayMiningFX(inst, target, nosound)
    end
end

local function postinitfn(sg)
    -- 获取原来的attack状态中onenter函数
    local attack_onenter = sg.states["attack"].onenter
    sg.states["attack"].onenter = function(inst, ...)
        -- 获取手中的装备
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        -- 如果装备存在且装备有dreadsword标签，那么将attack_weapon替换为hit_metal
        if equip ~= nil and equip:HasTag("dreadsword") then
            Util.SetSound("dontstarve/wilson/attack_weapon", "rifts2/thrall_wings/projectile")
        end

        -- 执行原来的onenter函数
        attack_onenter(inst, ...)

        -- 播放完后把音效改回去
        Util.SetSound("dontstarve/wilson/attack_weapon", nil)
    end

    local mine_timeevent = TimeEvent(7 * FRAMES, function(inst)
        if inst.sg.statemem.action ~= nil then
            PlayMiningFX(inst, inst.sg.statemem.action.target)
        end
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equip ~= nil and equip:HasTag("dread_pickaxe") then
            inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
        end
        inst.sg.statemem.recoilstate = "mine_recoil"
        inst:PerformBufferedAction()
    end)

    local hammer_timeline = sg.states["mine"].timeline
    table.remove(hammer_timeline, 1)
    table.insert(hammer_timeline, 1, mine_timeevent)

    local mine_recoil_timeevent = TimeEvent(7 * FRAMES, function(inst)
        inst.sg.statemem.recoilstate = "mine_recoil"
        inst.SoundEmitter:PlaySound(inst.sg.statemem.action ~= nil and inst.sg.statemem.action.invobject ~= nil and inst.sg.statemem.action.invobject.hit_skin_sound or "dontstarve/wilson/hit")
        inst:PerformBufferedAction()
    end)

    local hammer_timeline = sg.states["hammer"].timeline
    table.remove(hammer_timeline, 1)
    table.insert(hammer_timeline, 1, mine_recoil_timeevent)

end

AddStategraphPostInit("wilson", postinitfn)
