local GetModConfigData = GetModConfigData
local ENV = env
GLOBAL.setfenv(1, GLOBAL)

GlassicAPIEnabled = rawget(ENV, "GlassicAPI") ~= nil

GLOBAL.dread_crafts_config = {
	include_voidcloth = GetModConfigData("include_voidcloth"),
	dreadsword_enable = GetModConfigData("dreadsword_enable"),
	dread_pickaxe_enable = GetModConfigData("dread_pickaxe_enable"),
	talking_sword = GetModConfigData("talking_sword"),
}