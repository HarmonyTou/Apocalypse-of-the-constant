local ENV = env
local RegisterInventoryItemAtlas = RegisterInventoryItemAtlas
local resolvefilepath = GLOBAL.resolvefilepath
GLOBAL.setfenv(1, GLOBAL)

Util = {}
ENV.Util = Util

function Util.RegisterInventoryItemAtlas(atlas_path)
    local atlas = resolvefilepath(atlas_path)

    local file = io.open(atlas, "r")
    local data = file:read("*all")
    file:close()

    local str = string.gsub(data, "%s+", "")
    local _, _, elements = string.find(str, "<Elements>(.-)</Elements>")

    for s in string.gmatch(elements, "<Element(.-)/>") do
        local _, _, image = string.find(s, "name=\"(.-)\"")
        if image ~= nil then
            RegisterInventoryItemAtlas(atlas, image)
            RegisterInventoryItemAtlas(atlas, hash(image))  -- for client
        end
    end
end

function Util.GetUpvalue(fn, name, recurse_levels)
    assert(type(fn) == "function")

    recurse_levels = recurse_levels or 0
    local source_fn = fn
    local i = 1

    while true do
        local _name, value = debug.getupvalue(fn, i)
        if _name == nil then
            return
        elseif _name == name then
            return value, i, source_fn
        elseif type(value) == "function" and recurse_levels > 0 then
            local _value, _i, _source_fn = Util.GetUpvalue(value, name, recurse_levels - 1)
            if _value ~= nil then
                return _value, _i, _source_fn
            end
        end

        i = i + 1
    end
end

function Util.SetUpvalue(fn, value, name, recurse_levels)
    local _, i, source_fn = Util.GetUpvalue(fn, name, recurse_levels)
    if source_fn and i and value then
        debug.setupvalue(source_fn, i, value)
    end
end

local sound = {}

local PlaySound = SoundEmitter.PlaySound
function SoundEmitter:PlaySound(soundname, ...)
    return PlaySound(self, sound[soundname] or soundname, ...)
end

function Util.SetSound(name, alias)
    sound[name] = alias
end
