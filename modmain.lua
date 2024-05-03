--[[ 我瞎几把写，你瞎几把看 ]]

-- 灵衣：一键GLOBAL
-- 在env环境中找不到键时，去GLOBAL环境中找
GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local modules = {
	"config",
	"postinit",
	"assets",
	"tuning",
	"recipes",
	"strings",
	"actions",
	"commands",
	"prefabskin",
	"widgets",
}

for i = 1, #modules do
	modimport("main/" .. modules[i])
end
