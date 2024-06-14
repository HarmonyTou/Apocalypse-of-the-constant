-- GLOBAL.setfenv(1, GLOBAL)
local SkinHandler = require("utils/skinhandler")

dreadsword_init_fn = function(inst, build_name)
    if not TheWorld.ismastersim then
        return
    end

    basic_init_fn(inst, build_name, "dreadsword")

    if inst.blade1 ~= nil then
        inst.blade1.AnimState:SetBuild(build_name)
        inst.blade1.AnimState:SetBank(build_name)
        inst.blade2.AnimState:SetBuild(build_name)
        inst.blade2.AnimState:SetBank(build_name)
    end
end

dreadsword_clear_fn = function(inst)
    basic_clear_fn(inst, "dreadsword")

    if inst.blade1 ~= nil then
        inst.blade1.AnimState:SetBuild("dreadsword")
        inst.blade1.AnimState:SetBank("dreadsword")
        inst.blade2.AnimState:SetBuild("dreadsword")
        inst.blade2.AnimState:SetBank("dreadsword")
    end
end

SkinHandler.AddModSkins({
    dreadsword = { "night_edge" }
})
