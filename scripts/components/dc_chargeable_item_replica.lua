local DCChargeableItem = Class(function(self, inst)
    self.inst = inst
    -- self.percent = net_byte(inst.GUID, "DCChargeableItem.percent", "dc_chargeable_percent_dirty")
    self.percent = net_float(inst.GUID, "DCChargeableItem.percent", "dc_chargeable_percent_dirty")
end)

function DCChargeableItem:SetPercent(percent)
    -- self.percent:set(math.clamp(math.floor(percent * 100), 0, 100))
    self.percent:set(math.clamp(percent, 0, 1))
end

function DCChargeableItem:GetPercent()
    -- return self.percent:value() / 100.0
    return self.percent:value()
end

return DCChargeableItem
