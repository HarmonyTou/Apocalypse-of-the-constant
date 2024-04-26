local DCChargeableItem = Class(function(self, inst)
    self.inst = inst
    self.total = 100
    self.current = 100
    self.drain_per_second = 1              -- self.current decrease value per second when drained
    self.pause_drain_time_when_recover = 5 -- pause drain time when increasing self.current
    self.val_change_callback = nil         -- when self.current changed, trigger this fn

    self.pause_drain_end_time = nil
    self.drain_paused = false

    self.inst:StartUpdatingComponent(self)
end)

function DCChargeableItem:OnRemoveFromEntity()

end

function DCChargeableItem:GetDebugString()
    return string.format("%.2f/%d%s", self.current, self.total, self.drain_paused and " (drain paused)" or "")
end

function DCChargeableItem:OnSave()
    if self.current ~= self.total then
        return { current = self.current }
    end
end

function DCChargeableItem:OnLoad(data)
    if data ~= nil then
        if data.current ~= nil then
            self:SetVal(data.current)
        end
    end
end

function DCChargeableItem:PauseDrain(cd)
    self.drain_paused = true
    if cd then
        self.pause_drain_end_time = GetTime() + cd
    end
end

function DCChargeableItem:ResumeDrain()
    self.drain_paused = false
    self.pause_drain_end_time = nil
end

function DCChargeableItem:SetDrainPerSecond(val)
    self.drain_per_second = val
end

function DCChargeableItem:SetResumeDrainCD(val)
    self.pause_drain_time_when_recover = val
end

function DCChargeableItem:SetOnValChangeFn(fn)
    self.val_change_callback = fn
end

function DCChargeableItem:SetMax(val)
    self.total = val
end

function DCChargeableItem:SetVal(val)
    local old_val = self.current
    self.current = math.clamp(val, 0, self.total)

    local delta = self.current - old_val
    if val > old_val then
        self:PauseDrain(self.pause_drain_time_when_recover)
    end

    if self.val_change_callback then
        self.val_change_callback(self.inst, old_val, self.current)
    end

    self.inst:PushEvent("dschargechange", { old = old_val, new = self.current })

    return delta
end

function DCChargeableItem:DoDelta(delta)
    return self:SetVal(self.current + delta)
end

function DCChargeableItem:GetUses()
    return self.current
end

function DCChargeableItem:GetPercent()
    return self.current / self.total
end

function DCChargeableItem:SetPercent(amount)
    self:SetVal(self.total * amount)
end

function DCChargeableItem:OnUpdate(dt)
    if self.drain_paused and self.pause_drain_end_time and GetTime() >= self.pause_drain_end_time then
        self:ResumeDrain()
    end

    if not self.drain_paused then
        self:DoDelta(-dt * self.drain_per_second)
    else

    end
end

return DCChargeableItem
