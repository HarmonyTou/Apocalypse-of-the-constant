--[[

我瞎几把写，你瞎几把看

]]

local modimport = modimport

local modules = {
	"config",
	"postinit",
	"assets",
	"tuning",
	"recipes",
	"strings",
	"actions",
	"commands"
}

for i = 1, #modules do
	modimport("main/" .. modules[i])
end
