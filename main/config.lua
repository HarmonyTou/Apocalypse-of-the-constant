local GetModConfigData = GetModConfigData
local ENV = env
GLOBAL.setfenv(1, GLOBAL)

aoc_config = {
	locale = GetModConfigData("locale"),
	include_voidcloth = GetModConfigData("include_voidcloth"),
	dreadsword_enable = GetModConfigData("dreadsword_enable"),
	dread_pickaxe_enable = GetModConfigData("dread_pickaxe_enable"),
	talking_sword = GetModConfigData("talking_sword"),
}

ENV.aoc_config = aoc_config
