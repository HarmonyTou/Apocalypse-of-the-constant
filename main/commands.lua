-- GLOBAL.setfenv(1, GLOBAL)

function c_revealmap()
    local size = 2 * TheWorld.Map:GetSize()
    local player = ThePlayer
    for x = -size, size, 32 do
        for z = -size, size, 32 do
            player.player_classified.MapExplorer:RevealArea(x, 0, z)
        end
    end
end

function c_spawndaywalker()
    local world = TheWorld
    if world.components.daywalkerspawner == nil then
        world:AddComponent("daywalkerspawner")
    end

    local x, y, z = ThePlayer.Transform:GetWorldPosition()

    if world.components.daywalkerspawner ~= nil then
        world.components.daywalkerspawner:SpawnDayWalkerArena(x, y, z)
    end
end
