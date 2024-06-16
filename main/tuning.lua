local tuning = {
    DREADSWORD = {
        DAMAGE = 51,
        PLANAR_DAMAGE = 17,
        USES = 200,
        SHADOW_LEVEL = 3,
    },
    DREADSPEAR = {
        DAMAGE = 59.5,
        USES = 250,
        SHADOW_LEVEL = 2,
    },
    DREAD_PICKAXE = {
        DAMAGE = 32.5,
        EFFICIENCY = 1.5,
        USES = 250,
        SHADOW_LEVEL = 2,
        PLANAR_DAMAGE = 10, --same as PICKAXE_LUNARPLANT_PLANAR_DAMAGE
    },

    DREAD_AXE = {
        DAMAGE = 34,
        PLANAR_DAMAGE = 17,
        USES = 300,
        EFFICIENCY = 1.5,
        ALT_DIST = 10,
        ALT_HIT_RANGE = 3,
        ALT_STIMULI = "strong",
        ALT_SPEED = 20,
        ALT_WORK = 10,
        SHADOW_LEVEL = 3,
    },

    KNIGHTMARESET = {
        SHADOW_LEVEL = 3,
        PLANAR_DEF = 7.5,
        ARMOR = 840,--same as ARMORDREADSTONE
        ABSORPTION = 0.9,
        SETBONUS_SHADOW_RESIST = math.sqrt(0.75) / 0.9, --same as ARMOR_VOIDCLOTH_SETBONUS_SHADOW_RESIST and ARMOR_LUNARPLANT_SETBONUS_LUNAR_RESIST
    },

    DREAD_LANTERN = {
        SHADOW_LEVEL = 2,
    },
}

for k, v in pairs(tuning) do
    TUNING[k] = v
end



