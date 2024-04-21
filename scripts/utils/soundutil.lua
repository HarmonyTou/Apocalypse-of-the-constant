local replace_sound = {}

local _PlaySound = SoundEmitter.PlaySound
function SoundEmitter:PlaySound(soundname, ...)
    return _PlaySound(self, replace_sound[soundname] or soundname, ...)
end

local function ReplaceSound(name, alias)
    replace_sound[name] = alias
end

return {
    ReplaceSound = ReplaceSound,
}