-- local GetModConfigData = GetModConfigData
-- local ENV = env
-- GLOBAL.setfenv(1, GLOBAL)

GLOBAL.aoc_config = {
	locale = GetModConfigData("locale"),
	talking_sword = GetModConfigData("talking_sword"),
}

-- ENV.aoc_config = aoc_config
