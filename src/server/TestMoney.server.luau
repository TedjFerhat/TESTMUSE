-- Test helper: keeps the player's cash topped up so you can buy anything.
-- Remove or disable this script before publishing.

local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local EconomyService = require(script.Parent.Services.EconomyService)

local TARGET_CASH = 999999999

local function topUp(player: Player)
    local data = PlayerDataService.GetData(player)
    if data and data.Cash < TARGET_CASH then
        EconomyService.Add(player, TARGET_CASH - data.Cash, "test topup")
    end
end

PlayerDataService.OnLoaded(function(player)
    -- Top up immediately on load
    task.wait(0.5)
    topUp(player)
    -- Then keep topping up every 2 seconds
    task.spawn(function()
        while player.Parent do
            topUp(player)
            task.wait(2)
        end
    end)
end)