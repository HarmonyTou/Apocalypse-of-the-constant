local UIAnim = require "widgets/uianim"

AddClassPostConstruct("widgets/itemtile", function(self, invitem)
    if self.item:HasTag("dc_chargeable_item") then
        self.dc_charge_progress = self:AddChild(UIAnim())
        self.dc_charge_progress:GetAnimState():SetBank("obsidian_tool_meter")
        self.dc_charge_progress:GetAnimState():SetBuild("obsidian_tool_meter")
        -- self.dc_charge_progress:GetAnimState():OverrideSymbol("meter", "spoiled_meter", "meter_yellow")
        -- self.dc_charge_progress:GetAnimState():OverrideSymbol("frame", "spoiled_meter", "frame_yellow")
        -- self.dc_charge_progress:GetAnimState():SetMultColour(1, 0, 0, 1)
        self.dc_charge_progress:GetAnimState():AnimateWhilePaused(false)


        self.dc_charge_progress:SetClickable(false)
        self.dc_charge_progress:MoveToBack()




        self.inst:ListenForEvent("dc_chargeable_percent_dirty",
            function(invitem)
                self:SetDCChargeProgress(invitem.replica.dc_chargeable_item:GetPercent())
            end,
            self.item)
    end


    function self:SetDCChargeProgress(percent)
        self.dc_charge_progress:GetAnimState():SetPercent("anim", math.clamp(percent, 0, .99))
    end

    local old_refresh = self.Refresh
    self.Refresh = function(self, ...)
        if self.item:HasTag("dc_chargeable_item") and self.item.replica.dc_chargeable_item then
            self:SetDCChargeProgress(self.item.replica.dc_chargeable_item:GetPercent())
        end
        return old_refresh(self, ...)
    end
end)
