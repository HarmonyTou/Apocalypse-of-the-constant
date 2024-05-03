local replace_emitter = {}

local _PlaySound = SoundEmitter.PlaySound
function SoundEmitter:PlaySound(emitter, event, name, volume, ...)
    _PlaySound(self, replace_emitter[emitter] or emitter, event, name, volume, ...)
end

local function ReplaceSound(_emitter, emitter)
    replace_emitter[_emitter] = emitter
end

return {
    ReplaceSound = ReplaceSound,
}
