local SkinHandler = require("utils/skinhandler")
GLOBAL.setfenv(1, GLOBAL)

local dreadsword = {
    "night_edge"
}

dreadsword_init_fn = function(inst, build_name)  
    if not TheWorld.ismastersim then
        return
    end

    basic_init_fn(inst, build_name, "dreadsword")
end

if not GlassicAPIEnabled then
    SkinHandler.AddModSkins({
        dreadsword
    })
else
    GlassicAPI.AddModSkins({
        dreadsword
    })
end