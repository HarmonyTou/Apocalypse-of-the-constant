--[[

我瞎几把写，你瞎几把看

绝望石剑
sword_dreadstone
“为你的敌人带去最深沉的绝望”
制作材料:绝望石*4 纯粹恐惧*4
理智:-10/min
伤害:51基础伤害+17位面伤害
使用次数:150
在被具有理智值的实体装备，且不处于启蒙
值区域时，缓慢恢复耐久。
攻击敌人时 若身上装备了绝望石头盔/绝望
石盔甲 连续攻击时获得2.5倍速度恢复它们
耐久的效果，受到伤害不中断，但停止攻击
超过1秒中断
穿戴任意一件绝望石装备后 绝望石剑的理智
降低效果取消

]]

--[[

绝望石镐
伤害:32.5+10点位面
工作效率1.0
耐久:600
材料:红布x2 绝望石x4 纯粹恐惧x4

与绝望石装备一样拥有恢复耐久的效果

可以敲也可以锤 每次敲/锤都会有被弹开的动画

每次都有概率直接挖完/捶完目标
san越低概率越高（满san25%概率～0san50%概率） 麻烦的话就一直是35%概率

]]

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local GetModConfigData = GetModConfigData

GLOBAL.dread_crafts_config = {
	include_voidcloth = GetModConfigData("include_voidcloth"),
	dreadsword_enable = GetModConfigData("dreadsword_enable"),
	dread_pickaxe_enable = GetModConfigData("dread_pickaxe_enable"),
	talking_sword = GetModConfigData("talking_sword"),
}



local file = {
	"util",
	"postinit",
	"assets",
	"tuning",
	"recipes",
	"strings",
	"actions",
	"commands"
}

for i = 1, #file do
	modimport("main/" .. file[i])
end
