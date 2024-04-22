GLOBAL.setfenv(1, GLOBAL)
local SkinHandler = require("utils/skinhandler")

dreadsword_init_fn = function(inst, build_name)
    if not TheWorld.ismastersim then
        return
    end

    basic_init_fn(inst, build_name, "dreadsword")
end

dreadsword_clear_fn = function(inst)
    basic_clear_fn(inst, "night_edge")
end

SkinHandler.AddModSkins({
    dreadsword = {"night_edge"}
})
