local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.TableRush.Shared.Constants)
local GameCatalog = require(ReplicatedStorage.TableRush.Shared.GameCatalog)
local DungeonDoorsSpec = require(ReplicatedStorage.TableRush.Shared.DungeonDoorsSpec)

local folder = ReplicatedStorage:FindFirstChild(Constants.REMOTES_FOLDER)
if not folder then
    folder = Instance.new("Folder")
    folder.Name = Constants.REMOTES_FOLDER
    folder.Parent = ReplicatedStorage
end

local function remote(name)
    local r = folder:FindFirstChild(name)
    if not r then
        r = Instance.new("RemoteEvent")
        r.Name = name
        r.Parent = folder
    end
    return r
end

local clientEvent = remote(Constants.REMOTES.ClientEvent)
local joinGame = remote(Constants.REMOTES.RequestJoinGame)
local spectateGame = remote(Constants.REMOTES.RequestSpectateGame)
local requestProfile = remote(Constants.REMOTES.RequestProfile)

local okWorld, worldOrErr = pcall(function()
    local WorldBuilder = require(script.Parent.WorldBuilder)
    return WorldBuilder.Build()
end)

if not okWorld then
    warn("Table Rush world build failed:", worldOrErr)
end

local profiles = {}
local joinedGame = {}

local function defaultDailyTasks()
    return {
        {
            Key = "ShieldPartner",
            Title = "Shield your partner",
            Description = "Use Shield to protect your partner in Dungeon Doors.",
            RewardCoins = 150,
            RewardTickets = 1,
            Progress = 0,
            Target = 1,
            Claimed = false,
        },
        {
            Key = "SearchSafely",
            Title = "Search safely",
            Description = "Use Search to inspect a chest or door.",
            RewardCoins = 100,
            RewardTickets = 1,
            Progress = 0,
            Target = 1,
            Claimed = false,
        },
        {
            Key = "BeatDoorwarden",
            Title = "Beat The Doorwarden",
            Description = "Defeat the first boss when gameplay arrives.",
            RewardCoins = 300,
            RewardTickets = 2,
            Progress = 0,
            Target = 1,
            Claimed = false,
        },
    }
end

local function getProfile(player)
    profiles[player.UserId] = profiles[player.UserId] or {
        UserId = player.UserId,
        Name = player.DisplayName,
        Coins = 1500,
        Tickets = 0,
        XP = 0,
        Level = 1,
        PersonalLabelUnlocked = false,
        PersonalLabel = "New Table",
        UnlockedGames = {
            DungeonDoors = true,
        },
        DailyTasks = defaultDailyTasks(),
    }
    profiles[player.UserId].Name = player.DisplayName
    return profiles[player.UserId]
end

local function tableList()
    local list = {}
    for _, gameInfo in ipairs(GameCatalog.GetPublicList()) do
        local count = 0
        for _, key in pairs(joinedGame) do
            if key == gameInfo.Key then
                count += 1
            end
        end
        table.insert(list, {
            Key = gameInfo.Key,
            DisplayName = gameInfo.DisplayName,
            Status = gameInfo.Status,
            Count = count,
            MaxPlayers = gameInfo.MaxPlayers,
            Tagline = gameInfo.Tagline,
        })
    end
    return list
end

local function sendProfile(player)
    clientEvent:FireClient(player, Constants.TOPICS.Profile, getProfile(player))
    clientEvent:FireClient(player, Constants.TOPICS.TableList, tableList())
end

local function renderGameFor(player, gameKey, mode)
    local gameInfo = GameCatalog.GetGame(gameKey)
    if not gameInfo then
        clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Unknown table game."})
        return
    end

    if gameKey == Constants.GAME_KEYS.DungeonDoors then
        clientEvent:FireClient(player, Constants.TOPICS.RenderGame, {
            GameKey = gameKey,
            GameInfo = gameInfo,
            FakeState = DungeonDoorsSpec.FakeState,
            Mode = mode or "Join",
        })
    end
end

local function joinPlayer(player, gameKey)
    local profile = getProfile(player)
    if not profile.UnlockedGames[gameKey] then
        clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "That table is locked."})
        return
    end

    local gameInfo = GameCatalog.GetGame(gameKey)
    if not gameInfo then
        clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Unknown table game."})
        return
    end

    joinedGame[player.UserId] = gameKey
    clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Joined " .. gameInfo.DisplayName .. "."})
    renderGameFor(player, gameKey, "Join")

    for _, p in ipairs(Players:GetPlayers()) do
        clientEvent:FireClient(p, Constants.TOPICS.TableList, tableList())
    end
end

local function spectatePlayer(player, gameKey)
    local gameInfo = GameCatalog.GetGame(gameKey)
    if not gameInfo then
        clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Unknown table game."})
        return
    end
    clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Spectating " .. gameInfo.DisplayName .. "."})
    renderGameFor(player, gameKey, "Spectate")
end

Players.PlayerAdded:Connect(function(player)
    getProfile(player)
    task.defer(sendProfile, player)
end)

Players.PlayerRemoving:Connect(function(player)
    joinedGame[player.UserId] = nil
end)

requestProfile.OnServerEvent:Connect(function(player)
    sendProfile(player)
end)

joinGame.OnServerEvent:Connect(function(player, gameKey)
    joinPlayer(player, gameKey)
end)

spectateGame.OnServerEvent:Connect(function(player, gameKey)
    spectatePlayer(player, gameKey)
end)

if okWorld then
    local map = workspace:FindFirstChild("TableRushMap")
    local dungeon = map and map:FindFirstChild("DungeonDoorsTable")
    if dungeon then
        local joinPromptPart = dungeon:FindFirstChild("JoinDungeonDoors")
        local spectatePromptPart = dungeon:FindFirstChild("SpectateDungeonDoors")

        local joinPrompt = joinPromptPart and joinPromptPart:FindFirstChildOfClass("ProximityPrompt")
        local spectatePrompt = spectatePromptPart and spectatePromptPart:FindFirstChildOfClass("ProximityPrompt")

        if joinPrompt then
            joinPrompt.Triggered:Connect(function(player)
                joinPlayer(player, Constants.GAME_KEYS.DungeonDoors)
            end)
        end

        if spectatePrompt then
            spectatePrompt.Triggered:Connect(function(player)
                spectatePlayer(player, Constants.GAME_KEYS.DungeonDoors)
            end)
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    task.defer(sendProfile, player)
end
