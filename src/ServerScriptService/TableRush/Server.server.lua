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
local submitAction = remote(Constants.REMOTES.SubmitAction)
local submitChoice = remote(Constants.REMOTES.SubmitChoice)
local backpackAction = remote(Constants.REMOTES.BackpackAction)
local claimDailyTask = remote(Constants.REMOTES.ClaimDailyTask)
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
local playerStates = {}

local function todaySeed()
    local t = os.date("!*t")
    return (t.year * 10000) + (t.month * 100) + t.day
end

local DAILY_TASK_POOL = {
    {Key = "StrikeGoblin", Title = "Strike the goblin", Description = "Use Strike against an enemy.", RewardCoins = 125, RewardTickets = 1, Target = 1, Track = "StrikeGoblin", Tier = "easy", Weight = 16},
    {Key = "SearchSafely", Title = "Search safely", Description = "Use Search on a room tile.", RewardCoins = 100, RewardTickets = 1, Target = 1, Track = "SearchSafely", Tier = "easy", Weight = 16},
    {Key = "ShieldPartner", Title = "Raise your shield", Description = "Use Shield during a run.", RewardCoins = 150, RewardTickets = 1, Target = 1, Track = "ShieldPartner", Tier = "easy", Weight = 14},
    {Key = "StepAround", Title = "Step around", Description = "Move to another tile.", RewardCoins = 90, RewardTickets = 1, Target = 1, Track = "StepAround", Tier = "easy", Weight = 12},
    {Key = "SchemeOnce", Title = "Try a scheme", Description = "Use Scheme once.", RewardCoins = 100, RewardTickets = 1, Target = 1, Track = "SchemeOnce", Tier = "easy", Weight = 10},
    {Key = "StrikeTwice", Title = "Land two strikes", Description = "Use Strike two times.", RewardCoins = 225, RewardTickets = 1, Target = 2, Track = "StrikeGoblin", Tier = "medium", Weight = 9},
    {Key = "SearchTwice", Title = "Careful scout", Description = "Use Search two times.", RewardCoins = 200, RewardTickets = 1, Target = 2, Track = "SearchSafely", Tier = "medium", Weight = 9},
    {Key = "BuildLight", Title = "Build light", Description = "Gain Light from Search.", RewardCoins = 225, RewardTickets = 2, Target = 2, Track = "GainLight", Tier = "medium", Weight = 8},
    {Key = "RaisePot", Title = "Raise the pot", Description = "Use Scheme to raise the pot.", RewardCoins = 250, RewardTickets = 1, Target = 2, Track = "RaisePot", Tier = "medium", Weight = 7},
    {Key = "EquipItem", Title = "Gear up", Description = "Equip one item.", RewardCoins = 240, RewardTickets = 2, Target = 1, Track = "EquipItem", Tier = "medium", Weight = 7},
    {Key = "DefeatEnemy", Title = "Clear a threat", Description = "Defeat an enemy.", RewardCoins = 350, RewardTickets = 2, Target = 1, Track = "DefeatEnemy", Tier = "hard", Weight = 6},
    {Key = "UnlockExit", Title = "Find the way out", Description = "Unlock an exit door.", RewardCoins = 450, RewardTickets = 3, Target = 1, Track = "UnlockExit", Tier = "hard", Weight = 4},
    {Key = "HighRollLoot", Title = "High-roll: treasure run", Description = "Find three treasures today.", RewardCoins = 750, RewardTickets = 5, Target = 3, Track = "FindTreasure", Tier = "rare", Weight = 2},
    {Key = "HighRollClear", Title = "High-roll: clean sweep", Description = "Defeat two enemies today.", RewardCoins = 800, RewardTickets = 5, Target = 2, Track = "DefeatEnemy", Tier = "rare", Weight = 1},
}

local function copyTask(template, dateSeed)
    return {
        Key = template.Key .. "_" .. tostring(dateSeed),
        BaseKey = template.Key,
        Title = template.Title,
        Description = template.Description,
        RewardCoins = template.RewardCoins,
        RewardTickets = template.RewardTickets,
        Progress = 0,
        Target = template.Target,
        Claimed = false,
        Track = template.Track,
        Tier = template.Tier,
        DateSeed = dateSeed,
    }
end

local function chooseWeighted(pool, rng, used)
    local total = 0
    for _, item in ipairs(pool) do
        if not used[item.Key] then
            total += item.Weight or 1
        end
    end
    if total <= 0 then return nil end

    local roll = rng:NextInteger(1, total)
    local running = 0
    for _, item in ipairs(pool) do
        if not used[item.Key] then
            running += item.Weight or 1
            if roll <= running then
                used[item.Key] = true
                return item
            end
        end
    end
    return nil
end

local function defaultDailyTasks()
    local dateSeed = todaySeed()
    local rng = Random.new(dateSeed)
    local tasks = {}
    local used = {}

    local function addTier(tier, count)
        local pool = {}
        for _, item in ipairs(DAILY_TASK_POOL) do
            if item.Tier == tier then
                table.insert(pool, item)
            end
        end
        for _ = 1, count do
            local chosen = chooseWeighted(pool, rng, used)
            if chosen then
                table.insert(tasks, copyTask(chosen, dateSeed))
            end
        end
    end

    addTier("easy", 4)
    addTier("medium", 2)
    addTier("hard", 1)
    if rng:NextInteger(1, 100) <= 35 then
        addTier("rare", 1)
    else
        addTier("medium", 1)
    end

    return tasks
end

local function refreshDailyIfNeeded(profile)
    local currentSeed = todaySeed()
    local tasks = profile.DailyTasks or {}
    if #tasks == 0 or tasks[1].DateSeed ~= currentSeed then
        profile.DailyTasks = defaultDailyTasks()
    end
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
        UnlockedGames = { DungeonDoors = true },
        DailyTasks = defaultDailyTasks(),
    }

    profiles[player.UserId].Name = player.DisplayName
    refreshDailyIfNeeded(profiles[player.UserId])
    return profiles[player.UserId]
end

local function progressTask(profile, trackKey, amount)
    refreshDailyIfNeeded(profile)
    amount = amount or 1

    for _, task in ipairs(profile.DailyTasks or {}) do
        if (task.Track == trackKey or task.BaseKey == trackKey or task.Key == trackKey) and not task.Claimed then
            task.Progress = math.clamp((task.Progress or 0) + amount, 0, task.Target or 1)
        end
    end
end

local function claimTask(player, taskKey)
    local profile = getProfile(player)
    refreshDailyIfNeeded(profile)

    for _, task in ipairs(profile.DailyTasks or {}) do
        if task.Key == taskKey then
            if task.Claimed then
                clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Already claimed."})
                return
            end
            if (task.Progress or 0) < (task.Target or 1) then
                clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Task not finished yet."})
                return
            end
            task.Claimed = true
            profile.Coins += task.RewardCoins or 0
            profile.Tickets += task.RewardTickets or 0
            clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Claimed +" .. tostring(task.RewardCoins or 0) .. " coins."})
            clientEvent:FireClient(player, Constants.TOPICS.Profile, profile)
            return
        end
    end

    clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Task not found."})
end

local ITEM_LIBRARY = {
    RustySword = {Id = "RustySword", Name = "Rusty Sword", Type = "Weapon", Slot = "Weapon", Power = 1, Body = "+1 Strike damage."},
    IronSword = {Id = "IronSword", Name = "Iron Sword", Type = "Weapon", Slot = "Weapon", Power = 2, Body = "+2 Strike damage."},
    WoolBoots = {Id = "WoolBoots", Name = "Wool Boots", Type = "Armor", Slot = "Boots", Power = 1, Body = "Soft steps. Traps hurt less."},
    IronBoots = {Id = "IronBoots", Name = "Iron Boots", Type = "Armor", Slot = "Boots", Power = 2, Body = "Heavy boots. Better trap protection."},
    LeatherArmor = {Id = "LeatherArmor", Name = "Leather Armor", Type = "Armor", Slot = "Armor", Power = 1, Body = "+1 safe max HP for the test loop."},
    SmallPotion = {Id = "SmallPotion", Name = "Small Potion", Type = "Consumable", Slot = nil, Power = 1, Body = "Use from backpack to heal 1 HP."},
    BrassKey = {Id = "BrassKey", Name = "Brass Key", Type = "Key", Slot = nil, Power = 1, Body = "A future locked-door key."},
}

local LOOT_TABLE = {"RustySword", "WoolBoots", "SmallPotion", "IronBoots", "LeatherArmor", "BrassKey", "IronSword"}

local ROOM_TEMPLATES = {
    {
        Name = "Dusty Entry",
        Theme = "Tutorial",
        Tiles = {
            {Id = "start", Label = "Entry", Kind = "Start", X = 0, Y = 0, Neighbors = {"goblin", "cache"}},
            {Id = "goblin", Label = "Door Goblin", Kind = "Enemy", Enemy = "Door Goblin", HP = 2, X = 1, Y = 0, Neighbors = {"start", "exit"}},
            {Id = "cache", Label = "Dusty Cache", Kind = "Treasure", X = 0, Y = 1, Neighbors = {"start", "exit"}},
            {Id = "exit", Label = "Exit Door", Kind = "Exit", X = 2, Y = 0, Neighbors = {"goblin", "cache"}},
        },
        Doors = {
            {Id = "safe", Icon = "↑", Label = "Safe Door", Hint = "Normal risk."},
            {Id = "greed", Icon = "→", Label = "Greed Door", Hint = "More loot, more danger."},
        },
    },
    {
        Name = "Crooked Hall",
        Theme = "Movement",
        Tiles = {
            {Id = "start", Label = "Crooked Entry", Kind = "Start", X = 0, Y = 0, Neighbors = {"rat", "trap"}},
            {Id = "rat", Label = "Bone Rat", Kind = "Enemy", Enemy = "Bone Rat", HP = 1, X = 1, Y = -1, Neighbors = {"start", "shrine"}},
            {Id = "trap", Label = "Loose Floor", Kind = "Trap", X = 1, Y = 1, Neighbors = {"start", "shrine", "exit"}},
            {Id = "shrine", Label = "Lantern Nook", Kind = "Discovery", X = 2, Y = 0, Neighbors = {"rat", "trap", "exit"}},
            {Id = "exit", Label = "Forked Door", Kind = "Exit", X = 3, Y = 0, Neighbors = {"trap", "shrine"}},
        },
        Doors = {
            {Id = "north", Icon = "↑", Label = "Lantern Door", Hint = "More information."},
            {Id = "east", Icon = "→", Label = "Treasure Door", Hint = "More loot."},
            {Id = "south", Icon = "↓", Label = "Danger Door", Hint = "Harder room."},
        },
    },
    {
        Name = "Mimic Storage",
        Theme = "Greed",
        Tiles = {
            {Id = "start", Label = "Storage Entry", Kind = "Start", X = 0, Y = 0, Neighbors = {"mimic", "chest"}},
            {Id = "mimic", Label = "Mimic Lurker", Kind = "Enemy", Enemy = "Mimic Lurker", HP = 3, X = 1, Y = 0, Neighbors = {"start", "exit"}},
            {Id = "chest", Label = "Heavy Chest", Kind = "Treasure", X = 1, Y = 1, Neighbors = {"start", "exit"}},
            {Id = "trap2", Label = "Needle Trap", Kind = "Trap", X = 2, Y = 1, Neighbors = {"chest", "exit"}},
            {Id = "exit", Label = "Storage Exit", Kind = "Exit", X = 3, Y = 0, Neighbors = {"mimic", "chest", "trap2"}},
        },
        Doors = {
            {Id = "safe", Icon = "↑", Label = "Safe Door", Hint = "Steadier route."},
            {Id = "vault", Icon = "→", Label = "Vault Door", Hint = "Loot route."},
        },
    },
    {
        Name = "Lantern Shrine",
        Theme = "Discovery",
        Tiles = {
            {Id = "start", Label = "Shrine Entry", Kind = "Start", X = 0, Y = 0, Neighbors = {"wisp", "fountain"}},
            {Id = "wisp", Label = "Lantern Wisp", Kind = "Enemy", Enemy = "Lantern Wisp", HP = 2, X = 1, Y = -1, Neighbors = {"start", "secret"}},
            {Id = "fountain", Label = "Light Fountain", Kind = "Discovery", X = 1, Y = 1, Neighbors = {"start", "secret"}},
            {Id = "secret", Label = "Secret Tile", Kind = "Treasure", X = 2, Y = 0, Neighbors = {"wisp", "fountain", "exit"}},
            {Id = "exit", Label = "Glowing Door", Kind = "Exit", X = 3, Y = 0, Neighbors = {"secret"}},
        },
        Doors = {
            {Id = "chain", Icon = "↑", Label = "Chained Door", Hint = "Control enemy ahead."},
            {Id = "quiet", Icon = "→", Label = "Quiet Door", Hint = "Safer path."},
        },
    },
    {
        Name = "Chained Exit",
        Theme = "Control",
        Tiles = {
            {Id = "start", Label = "Chain Entry", Kind = "Start", X = 0, Y = 0, Neighbors = {"warden", "key"}},
            {Id = "warden", Label = "Chain Warden", Kind = "Enemy", Enemy = "Chain Warden", HP = 4, X = 1, Y = 0, Neighbors = {"start", "exit"}},
            {Id = "key", Label = "Key Hook", Kind = "Discovery", X = 1, Y = 1, Neighbors = {"start", "locked"}},
            {Id = "locked", Label = "Locked Cache", Kind = "Treasure", X = 2, Y = 1, Neighbors = {"key", "exit"}},
            {Id = "exit", Label = "Boss Door", Kind = "Exit", X = 3, Y = 0, Neighbors = {"warden", "locked"}},
        },
        Doors = {
            {Id = "boss", Icon = "↑", Label = "Boss Door", Hint = "The Doorwarden waits."},
        },
    },
    {
        Name = "Doorwarden's Vault",
        Theme = "Boss",
        Tiles = {
            {Id = "start", Label = "Vault Entry", Kind = "Start", X = 0, Y = 0, Neighbors = {"warden"}},
            {Id = "warden", Label = "The Doorwarden", Kind = "Enemy", Enemy = "Doorwarden", HP = 6, X = 1, Y = 0, Neighbors = {"start", "vault"}},
            {Id = "vault", Label = "Final Vault", Kind = "Treasure", X = 2, Y = 0, Neighbors = {"warden", "exit"}},
            {Id = "exit", Label = "Run Complete", Kind = "Exit", X = 3, Y = 0, Neighbors = {"vault"}},
        },
        Doors = {},
    },
}

local ENEMY_REWARDS = {
    ["Door Goblin"] = 80,
    ["Bone Rat"] = 50,
    ["Mimic Lurker"] = 140,
    ["Lantern Wisp"] = 110,
    ["Chain Warden"] = 180,
    ["Doorwarden"] = 400,
}

local function shallowCopyArray(source)
    local t = {}
    for i, value in ipairs(source) do
        if type(value) == "table" then
            local copy = {}
            for k, v in pairs(value) do
                if type(v) == "table" then
                    local nested = {}
                    for ni, nv in ipairs(v) do nested[ni] = nv end
                    copy[k] = nested
                else
                    copy[k] = v
                end
            end
            t[i] = copy
        else
            t[i] = value
        end
    end
    return t
end

local function getTile(state, tileId)
    for _, tile in ipairs(state.Board.Tiles) do
        if tile.Id == tileId then
            return tile
        end
    end
    return nil
end

local function nextEventId(state)
    state.EventCounter = (state.EventCounter or 0) + 1
    return state.EventCounter
end

local function setPopup(state, kind, title, subtitle, body)
    state.EventPopup = {
        Id = nextEventId(state),
        Kind = kind,
        Title = title,
        Subtitle = subtitle or "",
        Body = body or "",
    }
end

local function makeRoomState(roomIndex, entryDoor)
    local template = ROOM_TEMPLATES[math.clamp(roomIndex, 1, #ROOM_TEMPLATES)]
    local tiles = shallowCopyArray(template.Tiles)
    for _, tile in ipairs(tiles) do
        tile.Revealed = tile.Id == "start"
        tile.Cleared = tile.Kind == "Start"
        if tile.Kind == "Enemy" then
            tile.MaxHP = tile.HP
        end
    end

    return {
        Name = template.Name,
        Theme = template.Theme,
        EntryDoor = entryDoor or "start",
        Tiles = tiles,
        Doors = shallowCopyArray(template.Doors or {}),
    }
end

local function availableMoves(state)
    local room = state.Board
    local current = getTile(state, state.PlayerTile)
    local moves = {}
    if not current then return moves end

    for _, id in ipairs(current.Neighbors or {}) do
        local tile = getTile(state, id)
        if tile then
            local icon = "◆"
            if tile.X > current.X then icon = "→" end
            if tile.X < current.X then icon = "←" end
            if tile.Y < current.Y then icon = "↑" end
            if tile.Y > current.Y then icon = "↓" end

            table.insert(moves, {
                Id = tile.Id,
                Icon = icon,
                Label = tile.Revealed and tile.Label or "Unknown Tile",
                Kind = tile.Revealed and tile.Kind or "Hidden",
            })
        end
    end
    return moves
end

local function createStartingBackpack()
    return {
        Items = {
            {Uid = "item_1", Data = ITEM_LIBRARY.RustySword, Equipped = true},
            {Uid = "item_2", Data = ITEM_LIBRARY.SmallPotion, Equipped = false},
        },
        Equipped = {
            Weapon = "item_1",
            Armor = nil,
            Boots = nil,
        },
    }
end

local function getEquippedPower(state, slot)
    local equippedUid = state.Backpack.Equipped[slot]
    if not equippedUid then return 0 end
    for _, entry in ipairs(state.Backpack.Items) do
        if entry.Uid == equippedUid then
            return entry.Data.Power or 0
        end
    end
    return 0
end

local function addItem(state, itemId)
    local data = ITEM_LIBRARY[itemId]
    if not data then return nil end

    local uid = "item_" .. tostring((state.ItemCounter or 2) + 1)
    state.ItemCounter = (state.ItemCounter or 2) + 1

    local entry = {
        Uid = uid,
        Data = data,
        Equipped = false,
    }

    table.insert(state.Backpack.Items, entry)

    if data.Slot then
        local currentUid = state.Backpack.Equipped[data.Slot]
        if currentUid then
            state.PendingEquip = {
                NewUid = uid,
                Slot = data.Slot,
                NewName = data.Name,
                Body = data.Body,
            }
        else
            state.Backpack.Equipped[data.Slot] = uid
            entry.Equipped = true
        end
    end

    return entry
end

local function makeDungeonState(player)
    local room = makeRoomState(1, "start")
    local state = {
        Phase = Constants.DUNGEON_PHASES.ChooseAction,
        RoomIndex = 1,
        RoomsToWin = #ROOM_TEMPLATES,
        Pot = 250,
        Threat = 0,
        CurrentRoom = {
            Key = "Room1",
            Name = room.Name,
            Type = room.Theme,
            Clear = "Move through tiles, reveal events, and reach the exit.",
            DoorText = "Doors appear at the exit.",
        },
        Board = room,
        PlayerTile = "start",
        PartnerTile = "start",
        CanAct = true,
        MoveOptions = nil,
        DoorOptions = nil,
        AwaitingPartner = false,
        EventCounter = 0,
        ItemCounter = 2,
        Backpack = createStartingBackpack(),
        PendingEquip = nil,
        Players = {
            {
                UserId = player.UserId,
                Name = "You",
                Zone = "Entry",
                Pouch = 300,
                Bank = 0,
                HP = 5,
                Keys = 0,
                Light = 0,
                Relics = {},
            },
            {
                UserId = 0,
                Name = "Partner",
                Zone = "Entry",
                Pouch = 300,
                Bank = 0,
                HP = 5,
                Keys = 0,
                Light = 0,
                Relics = {},
            },
        },
        Enemies = {},
        Doors = room.Doors,
        ActionCards = DungeonDoorsSpec.Actions,
        LastEvent = "Dusty Entry loaded. Use Step to choose a tile.",
    }

    setPopup(state, "Room", "Dusty Entry", "Room 1 / 6", "Move tile-by-tile. New rooms reveal enemies, traps, discoveries, and treasure.")
    return state
end

local function syncLegacyFields(state)
    state.CurrentRoom.Name = state.Board.Name
    state.CurrentRoom.Type = state.Board.Theme
    state.Doors = state.Board.Doors
    state.Enemies = {}

    for _, tile in ipairs(state.Board.Tiles or {}) do
        if tile.Kind == "Enemy" and not tile.Cleared then
            table.insert(state.Enemies, {
                Id = tile.Id,
                Name = tile.Enemy,
                Zone = tile.Label,
                HP = tile.HP or 1,
                MaxHP = tile.MaxHP or tile.HP or 1,
                IntentIcon = "!",
                Intent = "Threatens nearby players.",
                Kind = tile.Enemy,
            })
        end
    end

    state.Players[1].Zone = (getTile(state, state.PlayerTile) and getTile(state, state.PlayerTile).Label) or "Unknown"
    state.Players[2].Zone = (getTile(state, state.PartnerTile) and getTile(state, state.PartnerTile).Label) or "Following"
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

local function sendState(player, mode)
    local state = playerStates[player.UserId]
    if not state then return end
    syncLegacyFields(state)

    clientEvent:FireClient(player, Constants.TOPICS.RenderGame, {
        GameKey = Constants.GAME_KEYS.DungeonDoors,
        GameInfo = GameCatalog.GetGame(Constants.GAME_KEYS.DungeonDoors),
        FakeState = state,
        Mode = mode or "Join",
    })
end

local function renderGameFor(player, gameKey, mode)
    local gameInfo = GameCatalog.GetGame(gameKey)
    if not gameInfo then
        clientEvent:FireClient(player, Constants.TOPICS.Toast, {Message = "Unknown table game."})
        return
    end

    if gameKey == Constants.GAME_KEYS.DungeonDoors then
        playerStates[player.UserId] = playerStates[player.UserId] or makeDungeonState(player)
        sendState(player, mode or "Join")
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
    playerStates[player.UserId] = makeDungeonState(player)
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
    playerStates[player.UserId] = playerStates[player.UserId] or makeDungeonState(player)
    renderGameFor(player, gameKey, "Spectate")
end

local function revealTileEvent(player, state, tile)
    local profile = getProfile(player)
    tile.Revealed = true
    state.MoveOptions = nil
    state.CanAct = true
    state.AwaitingPartner = true

    if tile.Kind == "Enemy" then
        state.Phase = "Enemy Revealed"
        state.LastEvent = tile.Enemy .. " appeared on " .. tile.Label .. "."
        setPopup(state, "Enemy", tile.Enemy, tile.Label, "Use Strike to fight, Shield to survive, or Scheme for risk.")
    elseif tile.Kind == "Trap" then
        local boots = getEquippedPower(state, "Boots")
        local damage = boots >= 2 and 0 or 1
        state.Players[1].HP = math.max(1, state.Players[1].HP - damage)
        state.Threat += 1
        tile.Cleared = true
        state.Phase = "Trap Triggered"
        state.LastEvent = damage == 0 and "Your boots blocked the trap." or "A trap hit you for 1 HP."
        setPopup(state, "Trap", "Trap!", tile.Label, state.LastEvent)
    elseif tile.Kind == "Treasure" then
        local lootIndex = ((state.RoomIndex + state.EventCounter + #state.Backpack.Items) % #LOOT_TABLE) + 1
        local itemId = LOOT_TABLE[lootIndex]
        local item = addItem(state, itemId)
        state.Players[1].Pouch += 75
        tile.Cleared = true
        progressTask(profile, "FindTreasure")
        state.Phase = "Treasure Found"
        state.LastEvent = "Found " .. item.Data.Name .. " and +75 pouch."
        setPopup(state, "Treasure", "Treasure", item.Data.Name, item.Data.Body)
    elseif tile.Kind == "Discovery" then
        state.Players[1].Light += 1
        state.Players[1].Keys += 1
        tile.Cleared = true
        progressTask(profile, "GainLight")
        state.Phase = "Discovery"
        state.LastEvent = "Found +1 Light and +1 Key."
        setPopup(state, "Discovery", "Discovery", tile.Label, "You gained +1 Light and +1 Key.")
    elseif tile.Kind == "Exit" then
        tile.Cleared = true
        state.CanAct = false
        state.AwaitingPartner = true
        state.DoorOptions = state.Board.Doors
        state.Phase = "Choose Door"
        if state.RoomIndex >= state.RoomsToWin then
            state.LastEvent = "Run complete. Final vault rewards are coming next."
            setPopup(state, "Victory", "Run Complete", "Doorwarden cleared", "Final vault and scoring will be expanded next.")
        else
            state.LastEvent = "Exit reached. Waiting for teammate, then choose a door."
            setPopup(state, "Door", "Exit Reached", "Choose the next door", "Your teammate catches up before the next room begins.")
        end
        progressTask(profile, "UnlockExit")
    else
        tile.Cleared = true
        state.Phase = "Tile Revealed"
        state.LastEvent = "Revealed " .. tile.Label .. "."
        setPopup(state, "Room", tile.Label, "Safe tile", "Nothing dangerous here.")
    end
end

local function moveToTile(player, state, tileId)
    local valid = false
    for _, option in ipairs(availableMoves(state)) do
        if option.Id == tileId then
            valid = true
            break
        end
    end

    if not valid then
        state.LastEvent = "That tile is not reachable."
        return
    end

    local tile = getTile(state, tileId)
    if not tile then return end

    state.PlayerTile = tileId
    state.PartnerTile = tileId -- test helper: partner catches up automatically in this slice.
    local profile = getProfile(player)
    progressTask(profile, "StepAround")

    revealTileEvent(player, state, tile)
end

local function chooseDoor(player, state, doorId)
    if not state.DoorOptions then return end
    local chosen = nil
    for _, door in ipairs(state.DoorOptions) do
        if door.Id == doorId then
            chosen = door
            break
        end
    end
    if not chosen then return end

    if state.RoomIndex >= state.RoomsToWin then
        state.Phase = "Run Complete"
        state.LastEvent = "Dungeon Doors test run complete."
        state.CanAct = false
        setPopup(state, "Victory", "Victory", "Test run complete", "The full vault minigame comes after the boss loop.")
        return
    end

    state.RoomIndex += 1
    state.Board = makeRoomState(state.RoomIndex, chosen.Id)
    state.PlayerTile = "start"
    state.PartnerTile = "start"
    state.MoveOptions = nil
    state.DoorOptions = nil
    state.PendingEquip = nil
    state.CanAct = true
    state.AwaitingPartner = false
    state.Phase = Constants.DUNGEON_PHASES.ChooseAction
    state.CurrentRoom = {
        Key = "Room" .. tostring(state.RoomIndex),
        Name = state.Board.Name,
        Type = state.Board.Theme,
        Clear = "Explore the room tiles and reach the exit.",
        DoorText = "Doors appear at the exit.",
    }
    state.LastEvent = "Both players arrived at " .. state.Board.Name .. "."
    setPopup(state, "Room", state.Board.Name, "Room " .. tostring(state.RoomIndex) .. " / " .. tostring(state.RoomsToWin), "New room loaded. Use Step to choose a tile.")
end

local function handleChoice(player, choiceId)
    if joinedGame[player.UserId] ~= Constants.GAME_KEYS.DungeonDoors then return end
    local state = playerStates[player.UserId]
    if not state then return end

    if state.MoveOptions then
        moveToTile(player, state, choiceId)
    elseif state.DoorOptions then
        chooseDoor(player, state, choiceId)
    elseif state.PendingEquip then
        if choiceId == "equip" then
            local pending = state.PendingEquip
            for _, entry in ipairs(state.Backpack.Items) do
                if entry.Data.Slot == pending.Slot then
                    entry.Equipped = false
                end
                if entry.Uid == pending.NewUid then
                    entry.Equipped = true
                end
            end
            state.Backpack.Equipped[pending.Slot] = pending.NewUid
            state.PendingEquip = nil
            state.CanAct = true
            state.LastEvent = "Equipped new item."
            setPopup(state, "Item", "Equipped", "Gear changed", "Your backpack equipment updated.")
            progressTask(getProfile(player), "EquipItem")
        elseif choiceId == "keep" then
            state.PendingEquip = nil
            state.CanAct = true
            state.LastEvent = "Kept current equipment."
        end
    end

    sendState(player, "Join")
    clientEvent:FireClient(player, Constants.TOPICS.Profile, getProfile(player))
end

local function submitDungeonAction(player, actionKey)
    if joinedGame[player.UserId] ~= Constants.GAME_KEYS.DungeonDoors then
        return
    end

    local state = playerStates[player.UserId] or makeDungeonState(player)
    playerStates[player.UserId] = state
    local profile = getProfile(player)
    local you = state.Players[1]
    local tile = getTile(state, state.PlayerTile)

    if state.PendingEquip then
        state.LastEvent = "Choose whether to equip the new item first."
        sendState(player, "Join")
        return
    end

    if actionKey == Constants.ACTIONS.Step then
        state.MoveOptions = availableMoves(state)
        state.DoorOptions = nil
        state.CanAct = false
        state.Phase = "Choose Move"
        state.LastEvent = "Choose where to move."
        setPopup(state, "Move", "Choose a Tile", "Move options highlighted", "Pick one reachable tile to reveal or revisit.")
    elseif actionKey == Constants.ACTIONS.Strike then
        if tile and tile.Kind == "Enemy" and not tile.Cleared then
            local damage = 1 + getEquippedPower(state, "Weapon")
            tile.HP = math.max(0, (tile.HP or 1) - damage)
            state.Phase = "Combat"
            state.LastEvent = "You struck " .. tile.Enemy .. " for " .. tostring(damage) .. "."
            progressTask(profile, "StrikeGoblin")
            if tile.HP <= 0 then
                tile.Cleared = true
                local reward = ENEMY_REWARDS[tile.Enemy] or 80
                you.Pouch += reward
                state.Pot += math.floor(reward / 2)
                state.LastEvent = tile.Enemy .. " defeated. +" .. tostring(reward) .. " pouch."
                progressTask(profile, "DefeatEnemy")
                if tile.Enemy == "Door Goblin" then
                    progressTask(profile, "DefeatDoorGoblin")
                end
                setPopup(state, "Combat", "Enemy Defeated", tile.Enemy, "+" .. tostring(reward) .. " pouch added.")
            else
                setPopup(state, "Combat", "Strike", tile.Enemy, "Enemy HP: " .. tostring(tile.HP) .. "/" .. tostring(tile.MaxHP or tile.HP))
            end
        else
            state.LastEvent = "No enemy on your tile."
            setPopup(state, "Info", "No Enemy", "Strike has no target", "Move onto an enemy tile or choose another card.")
        end
    elseif actionKey == Constants.ACTIONS.Search then
        progressTask(profile, "SearchSafely")
        if tile and tile.Kind == "Treasure" and not tile.Cleared then
            revealTileEvent(player, state, tile)
        else
            you.Light += 1
            you.Pouch += 20
            progressTask(profile, "GainLight")
            state.LastEvent = "You searched. +1 Light, +20 pouch."
            setPopup(state, "Discovery", "Search", "Careful scouting", "+1 Light and +20 pouch.")
        end
    elseif actionKey == Constants.ACTIONS.Shield then
        you.HP = math.min(7, you.HP + 1)
        state.LastEvent = "You raised your shield. +1 HP for the test loop."
        state.Phase = "Guard"
        progressTask(profile, "ShieldPartner")
        setPopup(state, "Guard", "Shield Raised", "Defensive stance", "+1 HP for this test loop.")
    elseif actionKey == Constants.ACTIONS.Scheme then
        state.Threat += 1
        state.Pot += 50
        you.Pouch += 25
        state.LastEvent = "You schemed. +50 pot, +25 pouch, +1 Threat."
        state.Phase = "Scheme"
        progressTask(profile, "SchemeOnce")
        progressTask(profile, "RaisePot")
        setPopup(state, "Scheme", "Risky Scheme", "Greed rises", "+50 pot and +25 pouch. Threat increased.")
    else
        state.LastEvent = "Unknown action."
    end

    sendState(player, "Join")
    clientEvent:FireClient(player, Constants.TOPICS.Profile, profile)
end

local function handleBackpackAction(player, payload)
    if joinedGame[player.UserId] ~= Constants.GAME_KEYS.DungeonDoors then return end
    local state = playerStates[player.UserId]
    if not state then return end

    payload = payload or {}
    local action = payload.Action
    local uid = payload.Uid
    local profile = getProfile(player)

    local entryIndex = nil
    local entry = nil
    for i, item in ipairs(state.Backpack.Items or {}) do
        if item.Uid == uid then
            entryIndex = i
            entry = item
            break
        end
    end

    if not entry then
        state.LastEvent = "Item not found."
        sendState(player, "Join")
        return
    end

    if action == "equip" and entry.Data.Slot then
        for _, item in ipairs(state.Backpack.Items) do
            if item.Data.Slot == entry.Data.Slot then
                item.Equipped = false
            end
        end
        entry.Equipped = true
        state.Backpack.Equipped[entry.Data.Slot] = entry.Uid
        state.LastEvent = "Equipped " .. entry.Data.Name .. "."
        setPopup(state, "Item", "Equipped", entry.Data.Name, entry.Data.Body)
        progressTask(profile, "EquipItem")
    elseif action == "use" and entry.Data.Type == "Consumable" then
        state.Players[1].HP = math.min(7, state.Players[1].HP + (entry.Data.Power or 1))
        table.remove(state.Backpack.Items, entryIndex)
        state.LastEvent = "Used " .. entry.Data.Name .. "."
        setPopup(state, "Item", "Used Item", entry.Data.Name, "+1 HP.")
    else
        state.LastEvent = "That item cannot be used that way."
    end

    sendState(player, "Join")
    clientEvent:FireClient(player, Constants.TOPICS.Profile, profile)
end

Players.PlayerAdded:Connect(function(player)
    getProfile(player)
    task.defer(sendProfile, player)
end)

Players.PlayerRemoving:Connect(function(player)
    joinedGame[player.UserId] = nil
    playerStates[player.UserId] = nil
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

submitAction.OnServerEvent:Connect(function(player, actionKey)
    submitDungeonAction(player, actionKey)
end)

submitChoice.OnServerEvent:Connect(function(player, choiceId)
    handleChoice(player, choiceId)
end)

backpackAction.OnServerEvent:Connect(function(player, payload)
    handleBackpackAction(player, payload)
end)

claimDailyTask.OnServerEvent:Connect(function(player, taskKey)
    claimTask(player, taskKey)
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
