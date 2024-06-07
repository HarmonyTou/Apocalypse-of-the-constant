local AOCDimensonContainerLinker = Class(function(self, inst)
    self.inst = inst
    self.container_prefab = "dread_cloak_container"
    self.loop_sound = "maxwell_rework/shadow_magic/storage_void_LP"
    self.loop_sound_index = "dread_cloak_container_loop_sound"
end)

function AOCDimensonContainerLinker:Open(doer)
    if self.container == nil then
        self.container = SpawnPrefab(self.container_prefab)
        self.container.Network:SetClassifiedTarget(doer)
        self.container.item = self.inst
        self.container.doer = doer

        self.container.components.container_proxy:SetOnCloseFn(function(container)
            self:Close(doer)
        end)
    end
    doer:PushEvent("opencontainer", { container = self.container.components.container_proxy:GetMaster() })
    self.container.components.container_proxy:Open(doer)
    if doer.SoundEmitter ~= nil and not doer.SoundEmitter:PlayingSound(self.loop_sound_index) then
        doer.SoundEmitter:PlaySound(self.loop_sound, self.loop_sound_index)
    end
end

function AOCDimensonContainerLinker:Close(doer)
    if self.container ~= nil then
        self.container.components.container_proxy:Close(doer)
        doer:PushEvent("closecontainer", { container = self.container.components.container_proxy:GetMaster() })
        self.container:Remove()
        self.container = nil
    end
    if doer.SoundEmitter ~= nil and doer.SoundEmitter:PlayingSound(self.loop_sound_index) then
        doer.SoundEmitter:KillSound(self.loop_sound_index)
    end
end

return
