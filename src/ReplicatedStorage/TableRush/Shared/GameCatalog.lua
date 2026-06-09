local Constants = require(script.Parent.Constants)

local GameCatalog = {}

GameCatalog.Games = {
    {
        Key = Constants.GAME_KEYS.DungeonDoors,
        DisplayName = "Dungeon Doors",
        ShortName = "Doors",
        Tagline = "Reveal rooms. Choose doors. Survive the dungeon board.",
        Status = "Featured",
        MinPlayers = 1,
        MaxPlayers = 2,
        IsUnlockedByDefault = true,
        TableWorldName = "DungeonDoorsTable",
        DailyGroup = "DungeonDoors",
    },

    {
        Key = "FutureCards",
        DisplayName = "Future Card Table",
        ShortName = "Cards",
        Tagline = "A future Table Rush game.",
        Status = "Coming Soon",
        MinPlayers = 2,
        MaxPlayers = 4,
        IsUnlockedByDefault = false,
        TableWorldName = "FutureTableA",
        DailyGroup = "Future",
    },

    {
        Key = "FutureDice",
        DisplayName = "Future Dice Table",
        ShortName = "Dice",
        Tagline = "A future dice/board game.",
        Status = "Coming Soon",
        MinPlayers = 2,
        MaxPlayers = 4,
        IsUnlockedByDefault = false,
        TableWorldName = "FutureTableB",
        DailyGroup = "Future",
    },
}

function GameCatalog.GetGame(key)
    for _, gameInfo in ipairs(GameCatalog.Games) do
        if gameInfo.Key == key then
            return gameInfo
        end
    end
    return nil
end

function GameCatalog.GetPublicList()
    local list = {}
    for _, gameInfo in ipairs(GameCatalog.Games) do
        table.insert(list, gameInfo)
    end
    return list
end

return GameCatalog
