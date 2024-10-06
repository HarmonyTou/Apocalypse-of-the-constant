local DCKnightmareSpawner = Class(function(self, inst)
    self.inst = inst

    self.knightmare = nil

    self.threshold_spawn_knightmare = 10 * TUNING.TOTAL_DAY_TIME
    self.threshold_spawn_knightmare_2 = 3 * TUNING.TOTAL_DAY_TIME
    self.timer_spawn_knightmare = self.threshold_spawn_knightmare
    self.timer_spawn_knightmare_running = false

    self.threshold_spawn_clue = 3 * TUNING.TOTAL_DAY_TIME
    self.timer_spawn_clue = self.threshold_spawn_clue
    self.timer_spawn_clue_running = false
    self.clue_spawned = false

    self._onriftchanged = function()
        self:CheckRift()
    end

    self._onknightmaredeath = function(ent)
        self:UnlinkKnightmare(ent)
        self.knightmare = nil
    end

    self._onknightmareremove = function(ent)
        self:UnlinkKnightmare(ent)
        self.knightmare = nil
    end


    inst:ListenForEvent("ms_riftaddedtopool", self._onriftchanged, TheWorld)
    inst:ListenForEvent("ms_riftremovedfrompool", self._onriftchanged, TheWorld)
    inst:ListenForEvent("ms_shadowrift_maxsize", self._onriftchanged, TheWorld)

    inst:StartUpdatingComponent(self)

    inst:DoTaskInTime(3, function()
        print("Init CheckRift()")
        self:CheckRift()
    end)
end)


function DCKnightmareSpawner:StartTimer_Knightmare(duration)
    self.timer_spawn_knightmare = duration
    self.timer_spawn_knightmare_running = true
end

function DCKnightmareSpawner:StopTimer_Knightmare()
    self.timer_spawn_knightmare_running = false
end

function DCKnightmareSpawner:TimerDone_Knightmare()
    self:StopTimer_Knightmare()

    self.knightmare = self:SpawnKnightmare()

    -- Spawn failed
    if self.knightmare == nil then
        print(("This round spawn kinghtmare failed, will try after %d seconds"):format(self.threshold_spawn_knightmare_2))
        self:StartTimer_Knightmare(self.threshold_spawn_knightmare_2)
        return
    end

    self:LinkKnightmare(self.knightmare)

    for _, v in pairs(AllPlayers) do
        if v and v.components.talker then
            v.components.talker:Say("我感到内心一阵空虚，有什么东西从我身体里消失了（弃誓骑士已生成）。")
        end
    end


    print("Knightmare spaw success, position:", self.knightmare:GetPosition(), "entity:", self.knightmare)
end

function DCKnightmareSpawner:StartTimer_Clue(duration)
    self.timer_spawn_clue = duration
    self.timer_spawn_clue_running = true
end

function DCKnightmareSpawner:StopTimer_Clue()
    self.timer_spawn_clue_running = false
end

function DCKnightmareSpawner:TimerDone_Clue()
    self:StopTimer_Clue()

    local clue, lucky_player = self:SpawnClue()

    -- Spawn failed
    if clue == nil then
        print("Clue spawn failed, will try again !")
        self:StartTimer_Clue(self.threshold_spawn_clue)
        return
    end

    if lucky_player then
        local dist = (clue:GetPosition() - lucky_player:GetPosition()):Length()

        if lucky_player and lucky_player.components.talker then
            lucky_player.components.talker:Say(("我认为弃誓骑士的线索可能就在附近（线索距离我%d码）"):format(dist))
        end
    end


    self.clue_spawned = true
    print("Clue spaw success, position:", clue:GetPosition(), "entity:", clue)
end

-- When clue disappeared, it runs this code.
function DCKnightmareSpawner:HandleDisapperedClue(clue)
    self:StopTimer_Clue()
    self.clue_spawned = false
    self:CheckRift()

    for _, v in pairs(AllPlayers) do
        if v and v.components.talker then
            if self.timer_spawn_clue_running then
                v.components.talker:Say("弃誓骑士的线索消失了，但是我觉得还是其他线索！")
            else
                v.components.talker:Say("弃誓骑士的线索彻底消失了，它成了埋葬在黑暗中的另一个谜团！")
            end
        end
    end
end

local function CheckPtFn(pt)
    for _, v in pairs(AllPlayers) do
        if (v:GetPosition() - pt):Length() <= 200 then
            return false
        end
    end

    local structures_or_walls = TheSim:FindEntities(pt.x, pt.y, pt.z, 40, nil, { "INLIMBO", "FX" },
        { "structure", "wall" })

    if #structures_or_walls > 0 then
        return false
    end

    local other_things = TheSim:FindEntities(pt.x, pt.y, pt.z, 2, nil, { "INLIMBO", "FX", "_inventoryitem" })

    if #other_things > 0 then
        return false
    end

    return true
end

local manual_tile = {}
local function CheckPtFn_WithManualTile(pt)
    local cur_tile = TheWorld.Map:GetTileAtPoint(pt:Get())
    return not table.contains(manual_tile, cur_tile)
        and TileGroupManager:IsLandTile(cur_tile)
        and CheckPtFn(pt)
end

function DCKnightmareSpawner:SpawnKnightmareInterface(ignore_manual_tile)
    local cands_pos = {}

    for k, node in ipairs(TheWorld.topology.nodes) do
        if TheWorld.Map:IsPassableAtPoint(node.x, 0, node.y, false, true)
            and node.type ~= NODE_TYPE.SeparatedRoom
            and not table.contains(node.tags, "Nightmare")
            and not table.contains(node.tags, "Atrium")
            and not table.contains(node.tags, "lunacyarea")
            and not string.find(TheWorld.topology.ids[k], "RuinedGuarden") then
            local center = Vector3(node.x, 0, node.z)

            for i = 1, 5 do
                local offset = FindWalkableOffset(center, math.random() * TWOPI, math.random() * 10, 1, nil, false,
                    ignore_manual_tile and CheckPtFn or CheckPtFn_WithManualTile, false, false)

                if offset then
                    table.insert(cands_pos, center + offset)
                end
            end
        end
    end

    if #cands_pos > 0 then
        local pos = GetRandomItem(cands_pos)
        return SpawnAt("knightmare", pos)
    end
end

function DCKnightmareSpawner:SpawnKnightmare()
    for i = 1, 5 do
        local knightmare = self:SpawnKnightmareInterface(false)
        if knightmare then
            return knightmare
        end
    end

    print("Spawn kinghtmare with manual tile limit failed, try without manual tile limit !")

    for i = 1, 5 do
        local knightmare = self:SpawnKnightmareInterface(true)
        if knightmare then
            return knightmare
        end
    end

    print("Spawn kinghtmare without manual tile limit failed !")
end

function DCKnightmareSpawner:LinkKnightmare(knightmare)
    self.inst:ListenForEvent("death", self._onknightmaredeath, knightmare)
    self.inst:ListenForEvent("onremove", self._onknightmareremove, knightmare)
end

function DCKnightmareSpawner:UnlinkKnightmare(knightmare)
    self.inst:RemoveEventCallback("death", self._onknightmaredeath, knightmare)
    self.inst:RemoveEventCallback("onremove", self._onknightmareremove, knightmare)
end

function DCKnightmareSpawner:SpawnClue()
    local players = {}
    for _, v in pairs(AllPlayers) do
        if v:HasTag("player_shadow_aligned") then
            players[v] = 2
        else
            players[v] = 1
        end
    end

    local player = weighted_random_choice(players)
    if not player then
        print("No player to spawn clue !")
        return
    end

    local pos = player:GetPosition()

    for i = 1, 50 do
        local offset = FindWalkableOffset(pos, math.random() * TWOPI, math.random(20, 40), 5, nil, false, nil, false,
            false)

        if offset then
            pos = pos + offset
            break
        end
    end

    -- TODO: Finish this clue
    local clue = SpawnAt("stash_map", pos)

    return clue, player
end

function DCKnightmareSpawner:CheckRift()
    local riftspawner = TheWorld.components.riftspawner
    local portal_active = riftspawner ~= nil and riftspawner:IsShadowPortalActive()
    local knightmare_exists = self.knightmare and self.knightmare:IsValid()
    local portal_maxstage = false

    if portal_active then
        for rift, rift_prefab in pairs(riftspawner:GetRifts()) do
            if rift._stage and rift._stage >= 3 then
                portal_maxstage = true
                break
            end
        end
    end


    if portal_active then
        if not knightmare_exists and not self.timer_spawn_knightmare_running then
            print("Shadow portal active, start knightmare spawn timer !")

            -- Reset clue when knightmare timer is start
            self.clue_spawned = false
            self:StartTimer_Knightmare(self.threshold_spawn_knightmare)
        end
    else
        if self.timer_spawn_knightmare_running then
            print("Shadow portal not active, stop knightmare spawn timer !")

            self:StopTimer_Knightmare()
        end
    end

    if knightmare_exists and portal_maxstage then
        if not self.clue_spawned and not self.timer_spawn_clue_running then
            print("Knightmare exists, portal stage max, start clue timer !")
            self:StartTimer_Clue(self.threshold_spawn_clue)
        end
    else
        self:StopTimer_Clue()
    end
end

function DCKnightmareSpawner:OnUpdate(dt)
    if self.timer_spawn_knightmare_running then
        self.timer_spawn_knightmare = self.timer_spawn_knightmare - dt
        if self.timer_spawn_knightmare <= 0 then
            self:TimerDone_Knightmare()
        end
    end

    if self.timer_spawn_clue_running then
        self.timer_spawn_clue = self.timer_spawn_clue - dt
        if self.timer_spawn_clue <= 0 then
            self:TimerDone_Clue()
        end
    end
end

function DCKnightmareSpawner:OnSave()
    local data = {
        timer_spawn_knightmare_running = self.timer_spawn_knightmare_running,
        timer_spawn_knightmare = self.timer_spawn_knightmare,

        timer_spawn_clue = self.timer_spawn_clue,
        timer_spawn_clue_running = self.timer_spawn_clue_running,
        clue_spawned = self.clue_spawned,
    }

    local references = {}

    if self.knightmare and self.knightmare:IsValid() then
        data.GUID = self.knightmare.GUID
        table.insert(references, self.knightmare.GUID)
    end

    return data, references
end

function DCKnightmareSpawner:OnLoad(data)
    if data ~= nil then
        if data.timer_spawn_knightmare_running ~= nil then
            self.timer_spawn_knightmare_running = data.timer_spawn_knightmare_running
        end

        if data.timer_spawn_knightmare ~= nil then
            self.timer_spawn_knightmare = data.timer_spawn_knightmare
        end

        if data.timer_spawn_clue ~= nil then
            self.timer_spawn_clue = data.timer_spawn_clue
        end

        if data.timer_spawn_clue_running ~= nil then
            self.timer_spawn_clue_running = data.timer_spawn_clue_running
        end

        if data.clue_spawned ~= nil then
            self.clue_spawned = data.clue_spawned
        end
    end
end

function DCKnightmareSpawner:LoadPostPass(newents, savedata)
    if savedata ~= nil then
        if savedata.GUID ~= nil then
            local new_ent = newents[savedata.GUID]
            self.knightmare = new_ent.entity
            self:LinkKnightmare(self.knightmare)
        end
    end
end

-- print(TheWorld.components.dc_knightmare_spawner:GetDebugString())
function DCKnightmareSpawner:GetDebugString()
    local ret = ""
    ret = ret .. ("Knightmare timer: %d"):format(self.timer_spawn_knightmare)
    if not self.timer_spawn_knightmare_running then
        ret = ret .. "(paused)"
    end

    if self.knightmare then
        ret = ret .. ", knightmare: " .. tostring(self.knightmare)
    end

    ret = ret .. (". Clue timer: %d"):format(self.timer_spawn_clue)
    if not self.timer_spawn_clue_running then
        ret = ret .. "(paused)"
    end

    if self.clue_spawned then
        ret = ret .. ", clue spawned."
    end

    return ret
end

DCKnightmareSpawner.OnLongUpdate = DCKnightmareSpawner.OnUpdate

return DCKnightmareSpawner
