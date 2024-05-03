local UIAnim = require "widgets/uianim"
local AddClassPostConstruct = AddClassPostConstruct

AddClassPostConstruct("widgets/itemtile", function(self, invitem)
    if self.item:HasTag("dc_chargeable_item") then
        self.dc_charge_progress = self:AddChild(UIAnim())
        self.dc_charge_progress:GetAnimState():SetBank("lunar_spark_meter")
        self.dc_charge_progress:GetAnimState():SetBuild("lunar_spark_meter")
        self.dc_charge_progress:GetAnimState():AnimateWhilePaused(false)

        self.dc_charge_progress:SetClickable(false)
        self.dc_charge_progress:MoveToBack()

        self.inst:ListenForEvent("dc_chargeable_percent_dirty", function(invitem)
            self:SetDCChargeProgress(invitem.replica.dc_chargeable_item:GetPercent())
        end, self.item)
    end

    function self:SetDCChargeProgress(percent)
        self.dc_charge_progress:GetAnimState():SetPercent("anim", math.clamp(percent, 0, .99))
    end

    local _Refresh = self.Refresh
    self.Refresh = function(self, ...)
        if self.item:HasTag("dc_chargeable_item") and self.item.replica.dc_chargeable_item then
            self:SetDCChargeProgress(self.item.replica.dc_chargeable_item:GetPercent())
        end
        return _Refresh(self, ...)
    end
end)
