-- v0.8.1 rollback lock: v0.8.0 full-avatar explorer rejected. This build restores the good board-room tabletop direction.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.TableRush.Shared.Constants)
local GameCatalog = require(ReplicatedStorage.TableRush.Shared.GameCatalog)
local DungeonDoorsSpec = require(ReplicatedStorage.TableRush.Shared.DungeonDoorsSpec)

local folder = ReplicatedStorage:FindFirstChild(Constants.REMOTES_FOLDER)
if not folder then folder = Instance.new("Folder"); folder.Name = Constants.REMOTES_FOLDER; folder.Parent = ReplicatedStorage end
local function remote(name)
    local r = folder:FindFirstChild(name)
    if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = folder end
    return r
end

local clientEvent = remote(Constants.REMOTES.ClientEvent)
local joinGame = remote(Constants.REMOTES.RequestJoinGame)
local spectateGame = remote(Constants.REMOTES.RequestSpectateGame)
local submitAction = remote(Constants.REMOTES.SubmitAction)
local submitChoice = remote(Constants.REMOTES.SubmitChoice)
local tableClick = remote(Constants.REMOTES.TableClick)
local backpackAction = remote(Constants.REMOTES.BackpackAction)
local claimDailyTask = remote(Constants.REMOTES.ClaimDailyTask)
local requestProfile = remote(Constants.REMOTES.RequestProfile)

local okWorld, worldOrErr = pcall(function() return require(script.Parent.WorldBuilder).Build() end)
if not okWorld then warn("Table Rush world build failed:", worldOrErr) end

local profiles = {}
local joinedGame = {}
local playerStates = {}

local function todaySeed() local t=os.date("!*t"); return (t.year*10000)+(t.month*100)+t.day end
local DAILY_TASK_POOL = {
    {Key="MoveTiles", Title="Cross tiles", Description="Move through room tiles.", RewardCoins=120, RewardTickets=1, Target=3, Track="StepAround", Tier="easy"},
    {Key="SurviveTrap", Title="Survive danger", Description="Trigger or block a trap.", RewardCoins=180, RewardTickets=1, Target=1, Track="TrapEvent", Tier="easy"},
    {Key="StrikeEnemy", Title="Strike enemies", Description="Use Strike against enemies.", RewardCoins=180, RewardTickets=1, Target=2, Track="StrikeEnemy", Tier="medium"},
    {Key="FindTreasure", Title="Find treasure", Description="Reveal treasure tiles.", RewardCoins=250, RewardTickets=2, Target=2, Track="FindTreasure", Tier="medium"},
    {Key="HardClear", Title="Clear threats", Description="Defeat enemies.", RewardCoins=380, RewardTickets=3, Target=2, Track="DefeatEnemy", Tier="hard"},
    {Key="HighRollSurvive", Title="High-roll: survive the deep", Description="Reach three exits.", RewardCoins=750, RewardTickets=5, Target=3, Track="UnlockExit", Tier="rare"},
}
local function copyTask(t, seed) return {Key=t.Key.."_"..tostring(seed), BaseKey=t.Key, Title=t.Title, Description=t.Description, RewardCoins=t.RewardCoins, RewardTickets=t.RewardTickets, Progress=0, Target=t.Target, Claimed=false, Track=t.Track, Tier=t.Tier, DateSeed=seed} end
local function defaultDailyTasks() local seed=todaySeed(); local tasks={}; for _,t in ipairs(DAILY_TASK_POOL) do table.insert(tasks, copyTask(t, seed)) end; return tasks end
local function refreshDailyIfNeeded(profile) local seed=todaySeed(); if #(profile.DailyTasks or {})==0 or profile.DailyTasks[1].DateSeed ~= seed then profile.DailyTasks=defaultDailyTasks() end end
local function getProfile(player)
    profiles[player.UserId] = profiles[player.UserId] or {UserId=player.UserId, Name=player.DisplayName, Coins=1500, Tickets=0, XP=0, Level=1, PersonalLabelUnlocked=false, PersonalLabel="New Table", UnlockedGames={DungeonDoors=true}, DailyTasks=defaultDailyTasks()}
    profiles[player.UserId].Name = player.DisplayName
    refreshDailyIfNeeded(profiles[player.UserId])
    return profiles[player.UserId]
end
local function progressTask(profile, trackKey, amount) refreshDailyIfNeeded(profile); amount=amount or 1; for _,task in ipairs(profile.DailyTasks or {}) do if (task.Track==trackKey or task.BaseKey==trackKey or task.Key==trackKey) and not task.Claimed then task.Progress=math.clamp((task.Progress or 0)+amount,0,task.Target or 1) end end end
local function claimTask(player, taskKey) local profile=getProfile(player); for _,task in ipairs(profile.DailyTasks or {}) do if task.Key==taskKey then if task.Claimed then return end; if (task.Progress or 0)<(task.Target or 1) then return end; task.Claimed=true; profile.Coins += task.RewardCoins or 0; profile.Tickets += task.RewardTickets or 0; clientEvent:FireClient(player, Constants.TOPICS.Profile, profile); return end end end

local ITEM_LIBRARY = {
    RustySword={Id="RustySword",Name="Rusty Sword",Type="Weapon",Slot="Weapon",Power=1,Body="+1 Strike damage."}, IronSword={Id="IronSword",Name="Iron Sword",Type="Weapon",Slot="Weapon",Power=2,Body="+2 Strike damage."},
    WoolBoots={Id="WoolBoots",Name="Wool Boots",Type="Armor",Slot="Boots",Power=1,Body="Traps hurt less."}, IronBoots={Id="IronBoots",Name="Iron Boots",Type="Armor",Slot="Boots",Power=2,Body="Better trap protection."},
    LeatherArmor={Id="LeatherArmor",Name="Leather Armor",Type="Armor",Slot="Armor",Power=1,Body="Can block weak counterattacks."}, SmallPotion={Id="SmallPotion",Name="Small Potion",Type="Consumable",Slot=nil,Power=2,Body="Heal 2 HP."}, BrassKey={Id="BrassKey",Name="Brass Key",Type="Key",Slot=nil,Power=1,Body="Useful later."},
}
local LOOT_TABLE = {"RustySword","WoolBoots","SmallPotion","IronBoots","LeatherArmor","BrassKey","IronSword"}
local ROOM_TEMPLATES = {
    {Id="room_1", Name="Dusty Entry", Theme="Tutorial", Difficulty=1, Atmosphere={TableColor={48,55,62}, Glow={72,178,225}, Material="Slate", Sound="rbxassetid://9113420778"}, Props={"Crates","Lantern"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Door Goblin", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Door Goblin", HP=2},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_2", Name="Whisper Hall", Theme="Spooky", Difficulty=1, Atmosphere={TableColor={23,34,46}, Glow={104,172,214}, Material="Cobblestone", Sound="rbxassetid://9113420778"}, Props={"Mist","Candles"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Candle Shade", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Candle Shade", HP=2},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_3", Name="Rat Run", Theme="Vermin", Difficulty=1, Atmosphere={TableColor={48,39,34}, Glow={160,120,70}, Material="Ground", Sound="rbxassetid://9113420778"}, Props={"Bones","Crates"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"trap","discovery"}},{Id="trap", Label="Snare", Kind="Trap", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="discovery", Label="Clue", Kind="Discovery", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Bone Rat", Kind="Enemy", X=2, Y=-1, Neighbors={"trap","exit"}, Enemy="Bone Rat", HP=2},{Id="treasure", Label="Niche", Kind="Treasure", X=2, Y=1, Neighbors={"discovery","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_4", Name="Cracked Pantry", Theme="Loot", Difficulty=1, Atmosphere={TableColor={64,46,28}, Glow={245,190,72}, Material="Wood", Sound="rbxassetid://9113420778"}, Props={"Chests","Crates"}, SearchOutcomes={{Id="loot", Weight=45, Text="Treasure luck spikes.", Effect="Coins"},{Id="good", Weight=25, Text="Find Light and a key.", Effect="Light"},{Id="bad", Weight=20, Text="Mimic noise raises Danger.", Effect="Danger"},{Id="nothing", Weight=10, Text="Dust only.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Mimic Lurker", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Mimic Lurker", HP=2},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_5", Name="Crooked Hall", Theme="Movement", Difficulty=2, Atmosphere={TableColor={37,46,35}, Glow={85,205,165}, Material="WoodPlanks", Sound="rbxassetid://9113420778"}, Props={"Roots","BrokenBridge"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Bone Rat", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Bone Rat", HP=3},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_6", Name="Moss Stairs", Theme="Growth", Difficulty=2, Atmosphere={TableColor={25,54,34}, Glow={82,190,92}, Material="Grass", Sound="rbxassetid://9113420778"}, Props={"Vines","Mushrooms"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Spore Crawler", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Spore Crawler", HP=3},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_7", Name="Lantern Nook", Theme="Discovery", Difficulty=2, Atmosphere={TableColor={34,47,40}, Glow={85,205,165}, Material="Marble", Sound="rbxassetid://9113420778"}, Props={"Lanterns","Shrine"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"trap","discovery"}},{Id="trap", Label="Snare", Kind="Trap", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="discovery", Label="Clue", Kind="Discovery", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Lantern Wisp", Kind="Enemy", X=2, Y=-1, Neighbors={"trap","exit"}, Enemy="Lantern Wisp", HP=3},{Id="treasure", Label="Niche", Kind="Treasure", X=2, Y=1, Neighbors={"discovery","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_8", Name="Old Armory", Theme="Gear", Difficulty=2, Atmosphere={TableColor={45,48,55}, Glow={185,185,196}, Material="Metal", Sound="rbxassetid://9113420778"}, Props={"Anvil","Weapons"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Chain Warden", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Chain Warden", HP=3},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_9", Name="Mimic Storage", Theme="Greed", Difficulty=2, Atmosphere={TableColor={66,48,30}, Glow={245,190,72}, Material="Wood", Sound="rbxassetid://9113420778"}, Props={"Chests","Coins"}, SearchOutcomes={{Id="loot", Weight=45, Text="Treasure luck spikes.", Effect="Coins"},{Id="good", Weight=25, Text="Find Light and a key.", Effect="Light"},{Id="bad", Weight=20, Text="Mimic noise raises Danger.", Effect="Danger"},{Id="nothing", Weight=10, Text="Dust only.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=55, Text="Big pot gain, bigger risk.", Effect="Pot"},{Id="loot", Weight=20, Text="A risky cache appears.", Effect="Loot"},{Id="backfire", Weight=20, Text="Greed bites back.", Effect="Damage"},{Id="curse", Weight=5, Text="Lose 50 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Mimic Lurker", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Mimic Lurker", HP=3},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_10", Name="Flooded Crypt", Theme="Danger", Difficulty=3, Atmosphere={TableColor={20,42,52}, Glow={72,178,225}, Material="Slate", Sound="rbxassetid://9113420778"}, Props={"Water","Bones"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Drowned Guard", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Drowned Guard", HP=4},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_11", Name="Black Candle Room", Theme="Fear", Difficulty=3, Atmosphere={TableColor={24,18,30}, Glow={164,94,232}, Material="Basalt", Sound="rbxassetid://9113420778"}, Props={"BlackCandles","Smoke"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"trap","discovery"}},{Id="trap", Label="Snare", Kind="Trap", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="discovery", Label="Clue", Kind="Discovery", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Candle Shade", Kind="Enemy", X=2, Y=-1, Neighbors={"trap","exit"}, Enemy="Candle Shade", HP=4},{Id="treasure", Label="Niche", Kind="Treasure", X=2, Y=1, Neighbors={"discovery","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_12", Name="Spider Pantry", Theme="Ambush", Difficulty=3, Atmosphere={TableColor={32,28,38}, Glow={164,94,232}, Material="Cobblestone", Sound="rbxassetid://9113420778"}, Props={"Webs","Eggs"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Pale Spider", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Pale Spider", HP=4},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_13", Name="Bone Chapel", Theme="Undead", Difficulty=3, Atmosphere={TableColor={42,42,46}, Glow={180,180,190}, Material="Granite", Sound="rbxassetid://9113420778"}, Props={"Bones","Coffin"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Bone Knight", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Bone Knight", HP=4},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_14", Name="Rotten Bridge", Theme="Trap", Difficulty=3, Atmosphere={TableColor={58,38,32}, Glow={230,90,62}, Material="Cobblestone", Sound="rbxassetid://9113420778"}, Props={"Spikes","PressurePlate"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Needle Fiend", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Needle Fiend", HP=4},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_15", Name="Moonwell Shrine", Theme="Discovery", Difficulty=3, Atmosphere={TableColor={34,47,40}, Glow={85,205,165}, Material="Marble", Sound="rbxassetid://9113420778"}, Props={"Lanterns","Shrine"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"trap","discovery"}},{Id="trap", Label="Snare", Kind="Trap", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="discovery", Label="Clue", Kind="Discovery", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Lantern Wisp", Kind="Enemy", X=2, Y=-1, Neighbors={"trap","exit"}, Enemy="Lantern Wisp", HP=4},{Id="treasure", Label="Niche", Kind="Treasure", X=2, Y=1, Neighbors={"discovery","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_16", Name="Cursed Library", Theme="Curse", Difficulty=3, Atmosphere={TableColor={38,26,45}, Glow={164,94,232}, Material="Basalt", Sound="rbxassetid://9113420778"}, Props={"Lantern"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Candle Shade", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Candle Shade", HP=4},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_17", Name="Chain Gallery", Theme="Control", Difficulty=4, Atmosphere={TableColor={44,42,50}, Glow={185,185,196}, Material="Metal", Sound="rbxassetid://9113420778"}, Props={"Chains","Locks"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Chain Warden", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Chain Warden", HP=5},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_18", Name="Silver Prison", Theme="Control", Difficulty=4, Atmosphere={TableColor={44,42,50}, Glow={185,185,196}, Material="Metal", Sound="rbxassetid://9113420778"}, Props={"Chains","Locks"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Chain Warden", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Chain Warden", HP=5},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_19", Name="Warden Post", Theme="Enemy", Difficulty=4, Atmosphere={TableColor={55,35,34}, Glow={215,70,60}, Material="Slate", Sound="rbxassetid://9113420778"}, Props={"Spikes","Bones"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"trap","discovery"}},{Id="trap", Label="Snare", Kind="Trap", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="discovery", Label="Clue", Kind="Discovery", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Door Goblin", Kind="Enemy", X=2, Y=-1, Neighbors={"trap","exit"}, Enemy="Door Goblin", HP=5},{Id="treasure", Label="Niche", Kind="Treasure", X=2, Y=1, Neighbors={"discovery","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_20", Name="Bleeding Vault", Theme="Greed", Difficulty=4, Atmosphere={TableColor={66,48,30}, Glow={245,190,72}, Material="Wood", Sound="rbxassetid://9113420778"}, Props={"Chests","Coins"}, SearchOutcomes={{Id="loot", Weight=45, Text="Treasure luck spikes.", Effect="Coins"},{Id="good", Weight=25, Text="Find Light and a key.", Effect="Light"},{Id="bad", Weight=20, Text="Mimic noise raises Danger.", Effect="Danger"},{Id="nothing", Weight=10, Text="Dust only.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=55, Text="Big pot gain, bigger risk.", Effect="Pot"},{Id="loot", Weight=20, Text="A risky cache appears.", Effect="Loot"},{Id="backfire", Weight=20, Text="Greed bites back.", Effect="Damage"},{Id="curse", Weight=5, Text="Lose 50 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Mimic Lurker", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Mimic Lurker", HP=5},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_21", Name="Glass Hall", Theme="Trap", Difficulty=4, Atmosphere={TableColor={58,38,32}, Glow={230,90,62}, Material="Cobblestone", Sound="rbxassetid://9113420778"}, Props={"Spikes","PressurePlate"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Needle Fiend", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Needle Fiend", HP=5},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_22", Name="Goblin Tollgate", Theme="Enemy", Difficulty=4, Atmosphere={TableColor={55,35,34}, Glow={215,70,60}, Material="Slate", Sound="rbxassetid://9113420778"}, Props={"Spikes","Bones"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Door Goblin", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Door Goblin", HP=5},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_23", Name="Fungal Nest", Theme="Poison", Difficulty=4, Atmosphere={TableColor={31,52,35}, Glow={82,190,92}, Material="Grass", Sound="rbxassetid://9113420778"}, Props={"Mushrooms","Vines"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"trap","discovery"}},{Id="trap", Label="Snare", Kind="Trap", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="discovery", Label="Clue", Kind="Discovery", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Spore Crawler", Kind="Enemy", X=2, Y=-1, Neighbors={"trap","exit"}, Enemy="Spore Crawler", HP=5},{Id="treasure", Label="Niche", Kind="Treasure", X=2, Y=1, Neighbors={"discovery","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_24", Name="Mirror Cell", Theme="Fear", Difficulty=4, Atmosphere={TableColor={24,18,30}, Glow={164,94,232}, Material="Basalt", Sound="rbxassetid://9113420778"}, Props={"BlackCandles","Smoke"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Candle Shade", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Candle Shade", HP=5},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}},
    {Id="room_25", Name="Ash Kitchen", Theme="Fire", Difficulty=5, Atmosphere={TableColor={68,34,22}, Glow={235,108,54}, Material="Basalt", Sound="rbxassetid://9113420778"}, Props={"Ash","Embers"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Ash Imp", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Ash Imp", HP=6},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_26", Name="Sunken Reliquary", Theme="Treasure", Difficulty=5, Atmosphere={TableColor={68,52,31}, Glow={245,190,72}, Material="Marble", Sound="rbxassetid://9113420778"}, Props={"Lantern"}, SearchOutcomes={{Id="loot", Weight=45, Text="Treasure luck spikes.", Effect="Coins"},{Id="good", Weight=25, Text="Find Light and a key.", Effect="Light"},{Id="bad", Weight=20, Text="Mimic noise raises Danger.", Effect="Danger"},{Id="nothing", Weight=10, Text="Dust only.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=55, Text="Big pot gain, bigger risk.", Effect="Pot"},{Id="loot", Weight=20, Text="A risky cache appears.", Effect="Loot"},{Id="backfire", Weight=20, Text="Greed bites back.", Effect="Damage"},{Id="curse", Weight=5, Text="Lose 50 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Mimic Lurker", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Mimic Lurker", HP=6},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_27", Name="Raven Balcony", Theme="Ambush", Difficulty=5, Atmosphere={TableColor={32,28,38}, Glow={164,94,232}, Material="Cobblestone", Sound="rbxassetid://9113420778"}, Props={"Webs","Eggs"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"trap","discovery"}},{Id="trap", Label="Snare", Kind="Trap", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="discovery", Label="Clue", Kind="Discovery", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Pale Spider", Kind="Enemy", X=2, Y=-1, Neighbors={"trap","exit"}, Enemy="Pale Spider", HP=6},{Id="treasure", Label="Niche", Kind="Treasure", X=2, Y=1, Neighbors={"discovery","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_28", Name="Locked Observatory", Theme="Discovery", Difficulty=5, Atmosphere={TableColor={34,47,40}, Glow={85,205,165}, Material="Marble", Sound="rbxassetid://9113420778"}, Props={"Lanterns","Shrine"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Lantern Wisp", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Lantern Wisp", HP=6},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_29", Name="Needle Gauntlet", Theme="Trap", Difficulty=5, Atmosphere={TableColor={58,38,32}, Glow={230,90,62}, Material="Cobblestone", Sound="rbxassetid://9113420778"}, Props={"Spikes","PressurePlate"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Needle Fiend", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Needle Fiend", HP=6},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_30", Name="Screaming Well", Theme="Fear", Difficulty=5, Atmosphere={TableColor={24,18,30}, Glow={164,94,232}, Material="Basalt", Sound="rbxassetid://9113420778"}, Props={"BlackCandles","Smoke"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Candle Shade", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Candle Shade", HP=6},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_31", Name="Iron Mausoleum", Theme="Undead", Difficulty=5, Atmosphere={TableColor={42,42,46}, Glow={180,180,190}, Material="Granite", Sound="rbxassetid://9113420778"}, Props={"Bones","Coffin"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"trap","discovery"}},{Id="trap", Label="Snare", Kind="Trap", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="discovery", Label="Clue", Kind="Discovery", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Bone Knight", Kind="Enemy", X=2, Y=-1, Neighbors={"trap","exit"}, Enemy="Bone Knight", HP=6},{Id="treasure", Label="Niche", Kind="Treasure", X=2, Y=1, Neighbors={"discovery","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_32", Name="Gold Maw", Theme="Greed", Difficulty=5, Atmosphere={TableColor={66,48,30}, Glow={245,190,72}, Material="Wood", Sound="rbxassetid://9113420778"}, Props={"Chests","Coins"}, SearchOutcomes={{Id="loot", Weight=45, Text="Treasure luck spikes.", Effect="Coins"},{Id="good", Weight=25, Text="Find Light and a key.", Effect="Light"},{Id="bad", Weight=20, Text="Mimic noise raises Danger.", Effect="Danger"},{Id="nothing", Weight=10, Text="Dust only.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=55, Text="Big pot gain, bigger risk.", Effect="Pot"},{Id="loot", Weight=20, Text="A risky cache appears.", Effect="Loot"},{Id="backfire", Weight=20, Text="Greed bites back.", Effect="Damage"},{Id="curse", Weight=5, Text="Lose 50 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Mimic Lurker", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Mimic Lurker", HP=6},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_33", Name="Pale Spider Court", Theme="Ambush", Difficulty=6, Atmosphere={TableColor={32,28,38}, Glow={164,94,232}, Material="Cobblestone", Sound="rbxassetid://9113420778"}, Props={"Webs","Eggs"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Pale Spider", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Pale Spider", HP=7},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_34", Name="Drowned Throne", Theme="Danger", Difficulty=6, Atmosphere={TableColor={20,42,52}, Glow={72,178,225}, Material="Slate", Sound="rbxassetid://9113420778"}, Props={"Water","Bones"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Drowned Guard", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Drowned Guard", HP=7},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_35", Name="Candle Catacomb", Theme="Fear", Difficulty=6, Atmosphere={TableColor={24,18,30}, Glow={164,94,232}, Material="Basalt", Sound="rbxassetid://9113420778"}, Props={"BlackCandles","Smoke"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"trap","discovery"}},{Id="trap", Label="Snare", Kind="Trap", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="discovery", Label="Clue", Kind="Discovery", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Candle Shade", Kind="Enemy", X=2, Y=-1, Neighbors={"trap","exit"}, Enemy="Candle Shade", HP=7},{Id="treasure", Label="Niche", Kind="Treasure", X=2, Y=1, Neighbors={"discovery","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_36", Name="Chain Warden Hall", Theme="Control", Difficulty=6, Atmosphere={TableColor={44,42,50}, Glow={185,185,196}, Material="Metal", Sound="rbxassetid://9113420778"}, Props={"Chains","Locks"}, SearchOutcomes={{Id="good", Weight=25, Text="Find +1 Light and +25 pouch.", Effect="Light"},{Id="bad", Weight=30, Text="Noise raises Danger.", Effect="Danger"},{Id="loot", Weight=20, Text="Find loose coins.", Effect="Coins"},{Id="nothing", Weight=25, Text="Nothing useful.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Chain Warden", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Chain Warden", HP=7},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_37", Name="Mimic Banquet", Theme="Greed", Difficulty=6, Atmosphere={TableColor={66,48,30}, Glow={245,190,72}, Material="Wood", Sound="rbxassetid://9113420778"}, Props={"Chests","Coins"}, SearchOutcomes={{Id="loot", Weight=45, Text="Treasure luck spikes.", Effect="Coins"},{Id="good", Weight=25, Text="Find Light and a key.", Effect="Light"},{Id="bad", Weight=20, Text="Mimic noise raises Danger.", Effect="Danger"},{Id="nothing", Weight=10, Text="Dust only.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=55, Text="Big pot gain, bigger risk.", Effect="Pot"},{Id="loot", Weight=20, Text="A risky cache appears.", Effect="Loot"},{Id="backfire", Weight=20, Text="Greed bites back.", Effect="Damage"},{Id="curse", Weight=5, Text="Lose 50 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"enemy","cache"}},{Id="enemy", Label="Mimic Lurker", Kind="Enemy", X=1, Y=0, Neighbors={"start","exit"}, Enemy="Mimic Lurker", HP=7},{Id="cache", Label="Side Cache", Kind="Treasure", X=0, Y=1, Neighbors={"start","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=2, Y=0, Neighbors={"enemy","cache"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_38", Name="Black Door Antechamber", Theme="BossPrep", Difficulty=7, Atmosphere={TableColor={32,22,28}, Glow={215,70,60}, Material="Granite", Sound="rbxassetid://9113420778"}, Props={"RedFog","Locks"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"north","south"}},{Id="north", Label="Cold Mark", Kind="Discovery", X=1, Y=-1, Neighbors={"start","enemy"}},{Id="south", Label="Bad Floor", Kind="Trap", X=1, Y=1, Neighbors={"start","treasure"}},{Id="enemy", Label="Chain Warden", Kind="Enemy", X=2, Y=-1, Neighbors={"north","exit"}, Enemy="Chain Warden", HP=8},{Id="treasure", Label="Gleam", Kind="Treasure", X=2, Y=1, Neighbors={"south","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","treasure"}}}, Doors={{Id="deep", Label="Deep Door", Hint="Hard route.", Bias=3},{Id="vault", Label="Vault Door", Hint="Greed route.", Bias=4},{Id="secret", Label="Strange Door", Hint="Rare special route.", Bias=2}}},
    {Id="room_39", Name="Doorwarden Vault", Theme="Boss", Difficulty=8, Atmosphere={TableColor={30,18,20}, Glow={215,70,60}, Material="Granite", Sound="rbxassetid://9113420778"}, Props={"Vault","RedFog","Pillars"}, SearchOutcomes={{Id="bad", Weight=45, Text="Something hears you.", Effect="Danger"},{Id="trap", Weight=25, Text="Search hurts you.", Effect="Damage"},{Id="good", Weight=15, Text="Find a clue.", Effect="Light"},{Id="nothing", Weight=15, Text="Nothing answers.", Effect="Nothing"}}, SchemeOutcomes={{Id="backfire", Weight=45, Text="This room punishes greed.", Effect="Damage"},{Id="payoff", Weight=25, Text="Big pot risk.", Effect="Pot"},{Id="curse", Weight=20, Text="Danger surges.", Effect="Danger"},{Id="shortcut", Weight=10, Text="Open a route clue.", Effect="Reveal"}}, Tiles={{Id="start", Label="Vault Entry", Kind="Start", X=0, Y=0, Neighbors={"boss"}},{Id="boss", Label="The Doorwarden", Kind="Enemy", X=1, Y=0, Neighbors={"start","vault"}, Enemy="The Doorwarden", HP=12},{Id="vault", Label="Final Vault", Kind="Treasure", X=2, Y=0, Neighbors={"boss","exit"}},{Id="exit", Label="Run Complete", Kind="Exit", X=3, Y=0, Neighbors={"vault"}}}, Doors={}},
    {Id="room_40", Name="Secret Saint Room", Theme="Secret", Difficulty=4, Atmosphere={TableColor={40,45,58}, Glow={245,230,170}, Material="Marble", Sound="rbxassetid://9113420778"}, Props={"Shrine","GoldLight"}, SearchOutcomes={{Id="loot", Weight=45, Text="Treasure luck spikes.", Effect="Coins"},{Id="good", Weight=25, Text="Find Light and a key.", Effect="Light"},{Id="bad", Weight=20, Text="Mimic noise raises Danger.", Effect="Danger"},{Id="nothing", Weight=10, Text="Dust only.", Effect="Nothing"}}, SchemeOutcomes={{Id="payoff", Weight=35, Text="+80 pot, +1 Danger.", Effect="Pot"},{Id="backfire", Weight=35, Text="Backfire: +2 Danger and -1 HP.", Effect="Damage"},{Id="shortcut", Weight=15, Text="Reveal a safer clue.", Effect="Reveal"},{Id="curse", Weight=15, Text="Lose 35 pouch.", Effect="Lose"}}, Tiles={{Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"fork"}},{Id="fork", Label="Fork", Kind="Discovery", X=1, Y=0, Neighbors={"start","enemy","trap","treasure"}},{Id="enemy", Label="Lantern Wisp", Kind="Enemy", X=2, Y=-1, Neighbors={"fork","exit"}, Enemy="Lantern Wisp", HP=5},{Id="trap", Label="Pressure Tile", Kind="Trap", X=2, Y=0, Neighbors={"fork","exit"}},{Id="treasure", Label="Cache", Kind="Treasure", X=2, Y=1, Neighbors={"fork","exit"}},{Id="exit", Label="Exit", Kind="Exit", X=3, Y=0, Neighbors={"enemy","trap","treasure"}}}, Doors={{Id="safe", Label="Safe Door", Hint="Lower danger route.", Bias=1},{Id="greed", Label="Greed Door", Hint="More loot, more risk.", Bias=2},{Id="deep", Label="Deep Door", Hint="Harder next room.", Bias=3}}}
}

local TWIN_SEAL_GATE_ROOM = {
    Id="puzzle_twin_seal_gate",
    Name="Twin Seal Gate",
    Theme="Puzzle",
    Difficulty=2,
    Atmosphere={TableColor={35,42,58}, Glow={90,185,235}, Material="Slate", Sound=""},
    Props={"Gate","Seal","Plate"},
    SearchOutcomes={{Id="seal", Weight=100, Text="A hidden lever rises from the floor.", Effect="Puzzle"}},
    SchemeOutcomes={},
    Tiles={
        {Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"clue","plate"}},
        {Id="clue", Label="Seal Clue", Kind="Discovery", PuzzleRole="LeverSearch", X=1, Y=-1, Neighbors={"start","lever","gate"}},
        {Id="plate", Label="Partner Plate", Kind="Discovery", PuzzleRole="Plate", X=1, Y=1, Neighbors={"start","gate"}},
        {Id="lever", Label="Hidden Lever", Kind="Discovery", PuzzleRole="Lever", HiddenObject=true, X=2, Y=-1, Neighbors={"clue","gate"}},
        {Id="gate", Label="Sealed Gate", Kind="Trap", PuzzleRole="Gate", X=2, Y=0, Neighbors={"clue","plate","lever","monster","exit"}},
        {Id="monster", Label="Seal Brute", Kind="Enemy", PuzzleRole="ShieldedMonster", X=3, Y=0, Neighbors={"gate","exit"}, Enemy="Seal Brute", HP=5, MaxHP=5, Shielded=true, FirstAction=false},
        {Id="exit", Label="Exit", Kind="Exit", X=4, Y=0, Neighbors={"gate","monster"}},
    },
    Doors={{Id="next", Label="Next Room", Hint="Continue.", Bias=1}}
}

local ECHO_BELL_CHAMBER = {
    Id="puzzle_echo_bell_chamber",
    Name="Echo Bell Chamber",
    Theme="Echo",
    Difficulty=3,
    Atmosphere={TableColor={30,34,58}, Glow={145,105,245}, Material="Marble", Sound=""},
    Props={"Bells","Runes","Gate"},
    SearchOutcomes={{Id="sequence", Weight=100, Text="The bell order appears in glowing runes.", Effect="Puzzle"}},
    SchemeOutcomes={},
    Tiles={
        {Id="start", Label="Entry", Kind="Start", X=0, Y=0, Neighbors={"clue","moon","fang"}},
        {Id="clue", Label="Rune Clue", Kind="Discovery", PuzzleRole="BellClue", X=1, Y=0, Neighbors={"start","moon","fang","eye","crown"}},
        {Id="moon", Label="Moon Bell", Kind="Discovery", PuzzleRole="Bell", BellSymbol="Moon", X=2, Y=-1, Neighbors={"clue","eye","warden"}},
        {Id="fang", Label="Fang Bell", Kind="Discovery", PuzzleRole="Bell", BellSymbol="Fang", X=2, Y=1, Neighbors={"clue","crown","warden"}},
        {Id="eye", Label="Eye Bell", Kind="Discovery", PuzzleRole="Bell", BellSymbol="Eye", X=3, Y=-1, Neighbors={"moon","warden","exit"}},
        {Id="crown", Label="Crown Bell", Kind="Discovery", PuzzleRole="Bell", BellSymbol="Crown", X=3, Y=1, Neighbors={"fang","warden","exit"}},
        {Id="warden", Label="Choir Warden", Kind="Enemy", PuzzleRole="ShieldedMonster", X=4, Y=0, Neighbors={"moon","fang","eye","crown","exit"}, Enemy="Choir Warden", HP=6, MaxHP=6, Shielded=true, FirstAction=false},
        {Id="exit", Label="Echo Gate", Kind="Exit", X=5, Y=0, Neighbors={"warden","eye","crown"}},
    },
    Doors={{Id="next", Label="Next Room", Hint="Continue.", Bias=1}}
}

local GOLD_KEY_VAULT_ROOM = {
    Id="gold_key_vault",
    Name="Gold Key Vault",
    Theme="Treasure",
    Difficulty=6,
    Atmosphere={TableColor={58,43,26}, Glow={238,184,72}, Material="Marble", Sound=""},
    Props={"Vault","Coins","Pillars"},
    SearchOutcomes={{Id="vault", Weight=100, Text="You find a safe vault notch.", Effect="Loot"}},
    SchemeOutcomes={},
    Tiles={
        {Id="start", Label="Vault Entry", Kind="Start", X=0, Y=0, Neighbors={"chest","enemy"}},
        {Id="enemy", Label="Gold Maw", Kind="Enemy", X=1, Y=-1, Neighbors={"start","exit"}, Enemy="Mimic Lurker", HP=7, MaxHP=7},
        {Id="chest", Label="Vault Chest", Kind="Treasure", X=1, Y=1, Neighbors={"start","exit"}},
        {Id="exit", Label="Leave Vault", Kind="Exit", X=2, Y=0, Neighbors={"enemy","chest"}},
    },
    Doors={}
}

local SECRET_DEATH_ROOM = {
    Id="secret_death_room",
    Name="Gilded Death Room",
    Theme="Secret",
    Difficulty=7,
    Atmosphere={TableColor={58,30,32}, Glow={245,132,72}, Material="Granite", Sound=""},
    Props={"GoldLight","RedFog","Shrine"},
    SearchOutcomes={{Id="deathsave", Weight=60, Text="You find a death-save charm.", Effect="Loot"},{Id="bite", Weight=40, Text="The room bites. -1 HP.", Effect="Damage"}},
    SchemeOutcomes={},
    Tiles={
        {Id="start", Label="Secret Entry", Kind="Start", X=0, Y=0, Neighbors={"altar","enemy"}},
        {Id="altar", Label="Cursed Altar", Kind="Discovery", X=1, Y=0, Neighbors={"start","chest","exit"}},
        {Id="enemy", Label="Gold Maw", Kind="Enemy", X=1, Y=-1, Neighbors={"start","exit"}, Enemy="Mimic Lurker", HP=8, MaxHP=8},
        {Id="chest", Label="Death Chest", Kind="Treasure", X=2, Y=1, Neighbors={"altar","exit"}},
        {Id="exit", Label="Escape", Kind="Exit", X=3, Y=0, Neighbors={"altar","enemy","chest"}},
    },
    Doors={}
}

local MONSTER_ACTIONS = {
    ["Seal Brute"]={{Name="Shield Bash",Icon="⬢",Text="The seal absorbs the hit unless the lever, plate, and gate are solved."},{Name="Ground Slam",Icon="▰",Text="A shockwave rattles the gate."}},
    ["Choir Warden"]={{Name="Echo Bolt",Icon="◉",Text="A ringing shot lashes across the chamber."},{Name="Hide in Echo",Icon="◇",Text="It fades behind the wrong bells."},{Name="Drink Resonance",Icon="✦",Text="It repairs its shield unless the sequence is solved."}},
    ["Door Goblin"]={{Name="Stab",Icon="!",Text="A quick jab."},{Name="Duck",Icon="↯",Text="It avoids part of the next hit."}},
    ["Bone Rat"]={{Name="Bite",Icon="!",Text="It bites low."},{Name="Scurry",Icon="↔",Text="It tries to slip away."}},
    ["Mimic Lurker"]={{Name="Snap",Icon="◆",Text="The chest snaps shut."},{Name="Fake Shine",Icon="?",Text="It baits the next search."}},
    ["The Doorwarden"]={{Name="Vault Slam",Icon="▰",Text="The vault shakes."},{Name="Lock Door",Icon="■",Text="A route locks down."}},
}
local ENEMY_REWARDS = {["Door Goblin"]=80,["Bone Rat"]=60,["Candle Shade"]=120,["Mimic Lurker"]=150,["Pale Spider"]=180,["Drowned Guard"]=180,["Chain Warden"]=240,["Doorwarden"]=650,["Bone Knight"]=210,["Spore Crawler"]=160,["Ash Imp"]=170,["Needle Fiend"]=190,["Lantern Wisp"]=130}
local function deepCopy(v) if type(v)~="table" then return v end; local c={}; for k,x in pairs(v) do c[k]=deepCopy(x) end; return c end
local function chooseWeighted(outcomes, rng) local total=0; for _,o in ipairs(outcomes or {}) do total += o.Weight or 1 end; if total<=0 then return nil end; local roll=rng:NextInteger(1,total); local run=0; for _,o in ipairs(outcomes or {}) do run += o.Weight or 1; if roll<=run then return o end end; return outcomes and outcomes[1] end
local function pickRoomTemplate(state, entryDoor)
    local idx=state and state.RoomIndex or 1
    if idx==1 then return TWIN_SEAL_GATE_ROOM end
    if idx==2 then return ECHO_BELL_CHAMBER end
    if idx==9 then return ROOM_TEMPLATES[39] end
    if idx==10 then return GOLD_KEY_VAULT_ROOM end
    if idx==11 then return SECRET_DEATH_ROOM end
    local cycle={5,8,14,18,23,28}
    return ROOM_TEMPLATES[cycle[((idx-3)%#cycle)+1]] or ROOM_TEMPLATES[5]
end
local function snapRot(seed)
    local rots={0,90,180,270}
    return rots[(math.abs(seed)%4)+1]
end

local function roomShapeFor(tile, room)
    local diff = room.Difficulty or 1
    local theme = room.Theme or "Room"
    local key = tostring(room.Id or room.Name or "") .. "_" .. tostring(tile.Id or "")
    local score = math.abs(#key + ((tile.X or 0) * 7) + ((tile.Y or 0) * 11) + (diff * 5))

    local themeShapes = {
        Fear = {"tall","lshape","split","thin"},
        Spooky = {"tall","alcove","lshape","wide"},
        Ambush = {"split","lshape","thin","tall"},
        Trap = {"thin","split","wide","lshape"},
        Greed = {"wide","alcove","lshape","wide"},
        Treasure = {"wide","alcove","wide","lshape"},
        Control = {"tall","wide","split","thin"},
        Danger = {"wide","thin","lshape","split"},
        Poison = {"lshape","tall","alcove","split"},
        Fire = {"thin","wide","split","lshape"},
        Undead = {"tall","alcove","wide","split"},
        Discovery = {"alcove","lshape","wide","tall"},
        Gear = {"wide","split","alcove","thin"},
        Boss = {"wide","lshape","split","alcove"},
        BossPrep = {"tall","split","wide","lshape"},
        Secret = {"alcove","wide","lshape","split"},
    }

    local shapes = themeShapes[theme] or {"square","wide","tall","lshape","thin","split","alcove"}
    local shape = shapes[(score % #shapes) + 1]

    if tile.Kind == "Enemy" and theme ~= "Greed" then
        shape = (score % 2 == 0) and "wide" or "tall"
    elseif tile.Kind == "Treasure" then
        shape = (score % 2 == 0) and "alcove" or "wide"
    elseif tile.Kind == "Trap" then
        shape = (score % 2 == 0) and "thin" or "split"
    elseif tile.Kind == "Discovery" then
        shape = (score % 2 == 0) and "lshape" or "alcove"
    end

    -- Start and Exit are intentionally normal room tiles now.
    -- Only the end vault uses special props through the Boss theme, not through Start/Exit shape rules.
    if tile.Kind == "Start" or tile.Kind == "Exit" then
        shape = shapes[((score + 2) % #shapes) + 1]
        if shape == "square" then shape = "wide" end
    end

    local sizes = {
        square={1.96,1.36},
        wide={2.34,1.32},
        tall={1.78,1.76},
        thin={2.42,1.02},
        split={2.10,1.46},
        alcove={2.28,1.34},
        lshape={2.06,1.54},
    }
    local s = sizes[shape] or sizes.square

    local decorProfiles = {
        Fear="candle_ruin",
        Spooky="mist_stones",
        Ambush="web_crates",
        Trap="spikes_plate",
        Greed="coin_crates",
        Treasure="coin_crates",
        Control="chain_blocks",
        Danger="water_stones",
        Poison="mushroom_blocks",
        Fire="ember_blocks",
        Undead="bone_slabs",
        Discovery="rune_stones",
        Gear="metal_crates",
        Boss="vault_blocks",
        BossPrep="vault_blocks",
        Secret="holy_cache",
        Loot="coin_crates",
        Vermin="bone_slabs",
        Movement="broken_floor",
        Growth="mushroom_blocks",
        Tutorial="stone_clutter",
        Enemy="spikes_plate",
    }

    return {
        Shape = shape,
        W = s[1],
        D = s[2],
        Rot = snapRot(score),
        DecorSeed = score,
        DecorProfile = decorProfiles[theme] or "stone_clutter",
    }
end


local function normalizeRoomGrid(tiles, room)
    local count = #tiles
    local theme = room.Theme or "Room"
    local shapeIndex = ((room.Difficulty or 1) + #(room.Name or "")) % 4

    local patterns = {
        {
            {0,0},{1,0},{2,0},{3,0},{2,-1},{2,1},{4,0}
        },
        {
            {0,0},{1,0},{2,0},{2,-1},{2,1},{3,0},{4,0}
        },
        {
            {0,0},{1,0},{1,-1},{2,-1},{2,0},{2,1},{3,0}
        },
        {
            {0,0},{0,-1},{1,-1},{1,0},{2,0},{2,1},{3,1}
        },
    }

    if theme == "Trap" or theme == "Ambush" or theme == "Fear" then
        shapeIndex = ((shapeIndex + 1) % 4)
    elseif theme == "Greed" or theme == "Treasure" or theme == "Secret" then
        shapeIndex = ((shapeIndex + 2) % 4)
    end

    local pattern = patterns[shapeIndex + 1]

    for i, tile in ipairs(tiles) do
        local p = pattern[math.min(i, #pattern)]
        tile.X = p[1]
        tile.Y = p[2]
    end

    -- Make the exit land at the furthest right available coordinate so it reads as the route endpoint.
    local exitIndex = nil
    for i, tile in ipairs(tiles) do
        if tile.Kind == "Exit" then
            exitIndex = i
            break
        end
    end
    if exitIndex and exitIndex ~= #tiles then
        local exitTile = tiles[exitIndex]
        local lastTile = tiles[#tiles]
        exitTile.X, lastTile.X = lastTile.X, exitTile.X
        exitTile.Y, lastTile.Y = lastTile.Y, exitTile.Y
    end
end

local function rebuildOrthogonalNeighbors(tiles)
    for _, tile in ipairs(tiles) do
        tile.Neighbors = {}
    end

    for i, a in ipairs(tiles) do
        for j = i + 1, #tiles do
            local b = tiles[j]
            local dx = math.abs((a.X or 0) - (b.X or 0))
            local dy = math.abs((a.Y or 0) - (b.Y or 0))

            if (dx + dy) == 1 then
                table.insert(a.Neighbors, b.Id)
                table.insert(b.Neighbors, a.Id)
            end
        end
    end
end

local function makeRoomState(state, roomIndex, entryDoor)
    local t = pickRoomTemplate(state, entryDoor)
    local tiles=deepCopy(t.Tiles)

    if t.Id ~= "puzzle_twin_seal_gate" and t.Id ~= "puzzle_echo_bell_chamber" and t.Id ~= "gold_key_vault" and t.Id ~= "secret_death_room" then
        normalizeRoomGrid(tiles, t)
        rebuildOrthogonalNeighbors(tiles)
    end

    for _,tile in ipairs(tiles) do
        tile.Revealed = tile.Id=="start" and not tile.HiddenObject
        tile.Cleared = tile.Kind=="Start"
        if tile.Kind=="Enemy" then tile.MaxHP=tile.HP end
        tile.Layout = roomShapeFor(tile, t)
    end
    return {Id=t.Id, Name=t.Name, Theme=t.Theme, Difficulty=t.Difficulty, Atmosphere=t.Atmosphere, Props=deepCopy(t.Props or {}), SearchOutcomes=deepCopy(t.SearchOutcomes or {}), SchemeOutcomes=deepCopy(t.SchemeOutcomes or {}), EntryDoor=entryDoor or "start", Tiles=tiles, Doors=deepCopy(t.Doors or {})}
end

local function getTile(state,id) for _,tile in ipairs(state.Board.Tiles) do if tile.Id==id then return tile end end end
local function nextEventId(state) state.EventCounter=(state.EventCounter or 0)+1; return state.EventCounter end
local function setPopup(state,kind,title,sub,body) state.EventPopup={Id=nextEventId(state),Kind=kind,Title=title,Subtitle=sub or "",Body=body or ""} end
local function currentTileHasLiveMonster(state)
    local current=getTile(state,state.PlayerTile)
    return current and current.Kind=="Enemy" and not current.Cleared and (current.HP or 0)>0
end

local function hasAnyLiveRevealedMonster(state)
    for _, tile in ipairs((state.Board and state.Board.Tiles) or {}) do
        if tile.Revealed and tile.Kind=="Enemy" and not tile.Cleared and (tile.HP or 0)>0 then
            return true, tile
        end
    end
    return false, nil
end

local function tileSearchKey(state, tile)
    return tostring(state.Board and state.Board.Id or "room") .. ":" .. tostring(tile and tile.Id or "none")
end

local function currentTileSearchSpent(state)
    local tile=getTile(state,state.PlayerTile)
    if not tile then return true end
    state.SearchedTiles = state.SearchedTiles or {}
    return state.SearchedTiles[tileSearchKey(state,tile)] == true
end

local function markCurrentTileSearched(state)
    local tile=getTile(state,state.PlayerTile)
    if not tile then return end
    state.SearchedTiles = state.SearchedTiles or {}
    state.SearchedTiles[tileSearchKey(state,tile)] = true
end

local function currentTileHasInteract(state)
    local tile=getTile(state,state.PlayerTile)
    if not tile then return false, "Nothing" end
    if currentTileHasLiveMonster(state) then return false, "Monster blocks interaction" end

    local puzzle=state.PuzzleState or {}
    if tile.PuzzleRole=="Lever" and tile.ObjectVisible and not puzzle.LeverPulled then return true, "Pull Lever" end
    if tile.PuzzleRole=="Plate" and not puzzle.PlateHeld then return true, "Hold Plate" end
    if tile.PuzzleRole=="Gate" and puzzle.LeverPulled and puzzle.PlateHeld and not puzzle.GateOpen then return true, "Open Gate" end
    if tile.PuzzleRole=="Bell" and puzzle.ClueRevealed and not puzzle.Solved then return true, "Ring Bell" end
    if tile.PuzzleRole=="BellClue" and puzzle.ClueRevealed and not puzzle.Solved then return true, "Replay Clue" end

    if tile.Kind=="Treasure" and not tile.Cleared then return true, "Open Chest" end
    if tile.Kind=="Discovery" and not tile.Cleared and tile.SearchClue then return true, "Use Clue" end
    if tile.Kind=="Trap" and not tile.Cleared and tile.SearchClue then return true, "Disarm" end
    if tile.Kind=="Exit" then return true, "Exit" end
    return false, "Nothing"
end

local function puzzleSolvedForMonster(state)
    local p=state.PuzzleState or {}
    if state.Board.Id=="puzzle_twin_seal_gate" then return p.GateOpen==true end
    if state.Board.Id=="puzzle_echo_bell_chamber" then return p.Solved==true end
    return true
end

local function unlockPuzzleMonsterIfSolved(state)
    if not puzzleSolvedForMonster(state) then return end
    for _,tile in ipairs(state.Board.Tiles or {}) do
        if tile.PuzzleRole=="ShieldedMonster" then tile.Shielded=false end
    end
end

local function rebuildCommandList(state)
    local actions={}
    local liveMonster=currentTileHasLiveMonster(state)
    local searched=currentTileSearchSpent(state)
    local hasInteract, interactLabel=currentTileHasInteract(state)

    table.insert(actions,{Key=Constants.ACTIONS.Step,Title=liveMonster and "Run" or "Move",Icon="↔",Body="",Tag=liveMonster and "ESC" or "GO"})
    if liveMonster then
        table.insert(actions,{Key=Constants.ACTIONS.Strike,Title="Fight",Icon="⚔",Body="",Tag="HIT"})
        table.insert(actions,{Key=Constants.ACTIONS.Shield,Title="Guard",Icon="⬟",Body="",Tag="BLOCK"})
    else
        if not searched then table.insert(actions,{Key=Constants.ACTIONS.Search,Title="Search",Icon="◆",Body="",Tag="LOOK"}) end
        if hasInteract then table.insert(actions,{Key=Constants.ACTIONS.Interact,Title=interactLabel,Icon="✦",Body="",Tag="USE"}) end
        table.insert(actions,{Key=Constants.ACTIONS.Shield,Title="Guard",Icon="⬟",Body="",Tag="SAFE"})
    end
    state.ActionCards=actions
end


local function availableMoves(state)
    local current=getTile(state,state.PlayerTile)
    local moves={}
    if not current then return moves end

    local fleeing=currentTileHasLiveMonster(state)

    for _,id in ipairs(current.Neighbors or {}) do
        local tile=getTile(state,id)
        if tile then
            -- If a live monster is on your current tile, Step becomes Run Away.
            -- You may retreat to revealed neighboring tiles only.
            -- You cannot push deeper into unknown rooms while a monster is standing on you.
            if not fleeing or tile.Revealed then
                table.insert(moves,{Id=tile.Id,Label=tile.Label,Kind=tile.Kind,Flee=fleeing})
            end
        end
    end
    return moves
end

local function createStartingBackpack() return {Items={{Uid="item_1",Data=ITEM_LIBRARY.RustySword,Equipped=true},{Uid="item_2",Data=ITEM_LIBRARY.SmallPotion,Equipped=false}},Equipped={Weapon="item_1",Armor=nil,Boots=nil}} end
local function getEquippedPower(state, slot) local uid=state.Backpack.Equipped[slot]; if not uid then return 0 end; for _,e in ipairs(state.Backpack.Items) do if e.Uid==uid then return e.Data.Power or 0 end end; return 0 end
local function addItem(state, itemId)
    local data=ITEM_LIBRARY[itemId]
    if not data then return nil end
    local uid="item_"..tostring((state.ItemCounter or 2)+1)
    state.ItemCounter=(state.ItemCounter or 2)+1
    local e={Uid=uid,Data=data,Equipped=false}
    table.insert(state.Backpack.Items,e)
    if data.Slot then
        local currentUid=state.Backpack.Equipped[data.Slot]
        if currentUid then
            local currentData=nil
            for _,item in ipairs(state.Backpack.Items) do
                if item.Uid==currentUid then currentData=item.Data end
            end
            state.PendingEquip={
                NewUid=uid, Slot=data.Slot, NewName=data.Name, Body=data.Body, NewPower=data.Power or 0,
                CurrentName=currentData and currentData.Name or "Nothing",
                CurrentBody=currentData and currentData.Body or "Empty slot.",
                CurrentPower=currentData and (currentData.Power or 0) or 0,
            }
            state.CanAct=false
        else
            state.Backpack.Equipped[data.Slot]=uid
            e.Equipped=true
        end
    end
    return e
end
local function syncLegacyFields(state)
    state.CurrentRoom.Name=state.Board.Name
    state.CurrentRoom.Type=state.Board.Theme
    state.Doors=state.Board.Doors
    state.Enemies={}
    for _,tile in ipairs(state.Board.Tiles or {}) do
        if tile.Kind=="Enemy" and not tile.Cleared and tile.Revealed then
            table.insert(state.Enemies,{
                Id=tile.Id,
                Name=tile.Enemy,
                Zone=tile.Label,
                HP=tile.HP or 1,
                MaxHP=tile.MaxHP or tile.HP or 1,
                IntentIcon=tile.Shielded and "🛡" or "!",
                Intent=tile.Shielded and "Shielded by the room puzzle." or "Preparing an action.",
                Kind=tile.Enemy,
                Shielded=tile.Shielded,
            })
        end
    end
    state.Players[1].Zone=(getTile(state,state.PlayerTile) and getTile(state,state.PlayerTile).Label) or "Unknown"
    state.Players[2].Zone=(getTile(state,state.PartnerTile) and getTile(state,state.PartnerTile).Label) or "Following"
    rebuildCommandList(state)
end
local function makeDungeonState(player)
    local room=makeRoomState(nil,1,"start")
    local state={
        Phase="Your Turn",
        RoomIndex=1,
        RoomsToWin=9,
        ExplorationRooms=8,
        HasGoldKey=false,
        SecretPath=false,
        CurrentRoom={Key="Room1",Name=room.Name,Type=room.Theme,Clear="Solve the room.",DoorText="Reach the exit."},
        Board=room,
        PlayerTile="start",
        PartnerTile="start",
        CanAct=true,
        ActionUsed=false,
        MoveOptions=nil,
        DoorOptions=nil,
        DoorVotes={},
        RouteWheel=nil,
        RoomActions={},
        SearchedTiles={},
        PuzzleState={LeverPulled=false,PlateHeld=false,GateOpen=false,ClueRevealed=false,Solved=false,BellIndex=1,BellSequence={"Moon","Fang","Eye"},BellWrong=0},
        EventCounter=0,
        ItemCounter=2,
        Backpack=createStartingBackpack(),
        PendingEquip=nil,
        Players={{UserId=player.UserId,Name="You",Zone="Entry",HP=5,Relics={}}, {UserId=0,Name="Partner",Zone="Entry",HP=5,Relics={}}},
        Enemies={},
        Doors=room.Doors,
        ActionCards={},
        LastEvent="Room 1: search the seal clue, reveal the lever, hold the plate, open the gate, then break the brute shield.",
    }
    setPopup(state,"Room","Twin Seal Gate","Puzzle 1 / Room 1","The monster is sealed and cannot be hurt until the lever, plate, and gate puzzle is solved.")
    return state
end
local function tableList() local list={}; for _,g in ipairs(GameCatalog.GetPublicList()) do local count=0; for _,k in pairs(joinedGame) do if k==g.Key then count += 1 end end; table.insert(list,{Key=g.Key,DisplayName=g.DisplayName,Status=g.Status,Count=count,MaxPlayers=g.MaxPlayers,Tagline=g.Tagline}) end; return list end
local function sendState(player,mode) local state=playerStates[player.UserId]; if not state then return end; syncLegacyFields(state); clientEvent:FireClient(player,Constants.TOPICS.RenderGame,{GameKey=Constants.GAME_KEYS.DungeonDoors,GameInfo=GameCatalog.GetGame(Constants.GAME_KEYS.DungeonDoors),FakeState=state,Mode=mode or "Join"}) end
local function sendProfile(player) clientEvent:FireClient(player,Constants.TOPICS.Profile,getProfile(player)); clientEvent:FireClient(player,Constants.TOPICS.TableList,tableList()) end
local function resolveEnemyTurn(player,state)
    local tile=getTile(state,state.PlayerTile)
    if not tile or tile.Kind~="Enemy" or tile.Cleared or (tile.HP or 0)<=0 then return false end
    local you=state.Players[1]
    local actions=MONSTER_ACTIONS[tile.Enemy] or {{Name="Attack",Icon="!",Text="It attacks."},{Name="Hide",Icon="?",Text="It shifts away."}}
    local pick=actions[((state.EventCounter or 0)+state.RoomIndex+#(tile.Enemy or "")) % #actions + 1]
    local armor=getEquippedPower(state,"Armor")
    local damage=tile.Shielded and 0 or math.max(0,1+math.floor((state.Board.Difficulty or 1)/3)-armor)
    state.Phase="Monster Action"
    state.CanAct=false
    state.ActionUsed=true
    state.MoveOptions=nil
    if damage>0 then you.HP=math.max(1,you.HP-damage) end
    state.LastEvent=(tile.Enemy or "Enemy").." uses "..pick.Name.."."
    state.MonsterAction={Id=nextEventId(state),Name=tile.Enemy or "Monster",Action=pick.Name,Icon=pick.Icon,Text=pick.Text,Damage=damage,Shielded=tile.Shielded}
    setPopup(state,"Monster Action",pick.Icon.." "..pick.Name,tile.Enemy or "Monster",pick.Text..(damage>0 and ("  -" .. tostring(damage) .. " HP.") or ""))
    return true
end

local function beginNextTurn(player,state,delaySeconds)
    delaySeconds=delaySeconds or 1.4
    state.CanAct=false
    state.ActionUsed=true
    state.MoveOptions=nil

    if state.DoorOptions or state.PendingEquip then return end

    local function partnerWait()
        if not player.Parent then return end
        local live=playerStates[player.UserId]
        if live~=state then return end
        if live.DoorOptions or live.PendingEquip then return end
        live.Phase="Partner Resolving"
        live.LastEvent="Waiting for teammate..."
        sendState(player,"Join")
        task.delay(1.0,function()
            if not player.Parent then return end
            local again=playerStates[player.UserId]
            if again~=state then return end
            if again.DoorOptions or again.PendingEquip then return end
            again.CanAct=true
            again.ActionUsed=false
            again.Phase="Your Turn"
            again.LastEvent="Teammate resolved. Your turn."
            sendState(player,"Join")
        end)
    end

    if resolveEnemyTurn(player,state) then
        sendState(player,"Join")
        task.delay(delaySeconds,partnerWait)
    else
        partnerWait()
    end
end
local function applyOutcome(player,state,outcome,source)
    local you=state.Players[1]
    if not outcome then return end
    if outcome.Effect=="Damage" then
        you.HP=math.max(1,you.HP-1)
        progressTask(getProfile(player),"TrapEvent")
    elseif outcome.Effect=="Loot" or outcome.Effect=="Coins" then
        addItem(state,LOOT_TABLE[((state.EventCounter+#state.Backpack.Items)%#LOOT_TABLE)+1])
    elseif outcome.Effect=="Reveal" or outcome.Effect=="Light" then
        state.SecretPath=true
    end
    setPopup(state,source or "Discovery",source or "Outcome",state.Board.Name,outcome.Text or "")
    state.LastEvent=outcome.Text or "The room changes."
end

local function revealTileEvent(player,state,tile)
    local profile=getProfile(player)
    tile.Revealed=true
    state.MoveOptions=nil
    if tile.Kind=="Enemy" then
        state.Phase="Monster Intro"
        state.LastEvent=(tile.Enemy or "Enemy").." appears. Read the monster card, then act."
        setPopup(state,"Monster",tile.Enemy or "Enemy",tile.Shielded and "Shielded" or "Monster Card",tile.Shielded and "This monster is invincible until the room puzzle is solved." or "It will act after your turn.")
    elseif tile.Kind=="Trap" then
        state.Phase="Hazard"
        state.LastEvent="Hazard found. Search can reveal how to handle it."
        setPopup(state,"Room","Hazard",tile.Label,"Search first or use the tile if you already know the mechanism.")
    elseif tile.Kind=="Treasure" then
        state.Phase="Treasure"
        state.LastEvent="Chest found. Search can inspect it before opening."
        setPopup(state,"Treasure","Chest spotted",tile.Label,"Open it or search for a safer outcome.")
    elseif tile.Kind=="Discovery" then
        state.Phase="Clue Tile"
        state.LastEvent="Clue tile revealed. Search it to make something visible or usable."
        setPopup(state,"Search","Clue tile",tile.Label,"Search this tile for the room-specific clue.")
    elseif tile.Kind=="Exit" then
        tile.Cleared=true
        local monsterAlive, monsterTile=hasAnyLiveRevealedMonster(state)
        if monsterAlive then
            state.CanAct=true
            state.ActionUsed=false
            state.DoorOptions=nil
            state.Phase="Exit Locked"
            state.LastEvent="Exit is locked while "..tostring(monsterTile.Enemy or "a monster").." is alive."
            setPopup(state,"Door Locked","Monster blocks the exit",monsterTile.Enemy or "Monster","Defeat revealed monsters before leaving.")
        else
            state.CanAct=false
            state.ActionUsed=true
            state.DoorOptions=state.Board.Doors
            state.DoorVotes={}
            state.Phase="Choose Door"
            if state.RoomIndex>=state.RoomsToWin then
                state.LastEvent="Boss cleared. Run complete."
                setPopup(state,"Victory","Run Complete","Doorwarden cleared","Optional rooms unlock through Gold Key / secret path.")
            else
                state.LastEvent="Exit reached. Choose the next route."
            end
            progressTask(profile,"UnlockExit")
        end
    else
        tile.Cleared=true
        state.Phase="Tile Revealed"
        state.LastEvent="Revealed "..tile.Label.."."
    end
end

local function moveToTile(player,state,tileId) local valid=false; for _,o in ipairs(state.MoveOptions or {}) do if o.Id==tileId then valid=true end end; if not valid then state.LastEvent=currentTileHasLiveMonster(state) and "You can only run to revealed tiles while a monster is here." or "Use Step, then click a glowing reachable tile."; return false end; local tile=getTile(state,tileId); if not tile then return false end; state.PlayerTile=tileId; state.PartnerTile=tileId; progressTask(getProfile(player),"StepAround"); revealTileEvent(player,state,tile); return true end
local function loadNextRoomAfterDoor(player,state,chosen)
    if not chosen then return end

    if state.RoomIndex>=state.RoomsToWin then
        if state.HasGoldKey and state.RoomIndex==9 then
            state.RoomIndex=10
        elseif state.SecretPath and state.RoomIndex==10 then
            state.RoomIndex=11
        else
            state.Phase="Run Complete"
            state.CanAct=false
            setPopup(state,"Victory","Victory","Run complete","You cleared the planned dungeon path.")
            sendState(player,"Join")
            return
        end
    else
        state.RoomIndex += 1
    end

    state.Board=makeRoomState(state,state.RoomIndex,chosen.Id)
    state.PlayerTile="start"
    state.PartnerTile="start"
    state.MoveOptions=nil
    state.DoorOptions=nil
    state.DoorVotes={}
    state.RouteWheel=nil
    state.PendingRouteChoice=nil
    state.PendingEquip=nil
    state.RoomActions={}
    state.SearchedTiles={}
    state.PuzzleState={LeverPulled=false,PlateHeld=false,GateOpen=false,ClueRevealed=false,Solved=false,BellIndex=1,BellSequence={"Moon","Fang","Eye"},BellWrong=0}
    state.CanAct=true
    state.ActionUsed=false
    state.Phase="Your Turn"
    state.CurrentRoom={Key="Room"..tostring(state.RoomIndex),Name=state.Board.Name,Type=state.Board.Theme,Clear="Solve/survive.",DoorText="Reach the exit."}
    state.LastEvent="Entered "..state.Board.Name.."."
    setPopup(state,"Room",state.Board.Name,"Room "..tostring(state.RoomIndex).." / "..tostring(state.RoomsToWin),"Search and Use are tile/object based.")
    sendState(player,"Join")
end

local function chooseDoor(player,state,doorId)
    if not state.DoorOptions then return end
    local monsterAlive, monsterTile=hasAnyLiveRevealedMonster(state)
    if monsterAlive then
        state.DoorOptions=nil
        state.CanAct=true
        state.ActionUsed=false
        state.Phase="Exit Locked"
        state.LastEvent="Door choice cancelled. "..tostring(monsterTile.Enemy or "A monster").." is still alive."
        setPopup(state,"Door Locked","Monster blocks route",monsterTile.Enemy or "Monster","Clear revealed monsters before leaving.")
        return
    end
    local chosen=state.DoorOptions[1] or {Id="next",Label="Next"}
    state.DoorOptions=nil
    loadNextRoomAfterDoor(player,state,chosen)
end

local function submitDungeonAction(player,actionKey)
    if joinedGame[player.UserId]~=Constants.GAME_KEYS.DungeonDoors then return end
    local state=playerStates[player.UserId] or makeDungeonState(player)
    playerStates[player.UserId]=state
    local profile=getProfile(player)
    local you=state.Players[1]
    local tile=getTile(state,state.PlayerTile)

    if not state.CanAct or state.ActionUsed or state.PendingEquip or state.DoorOptions then
        state.LastEvent="Wait for the current decision to resolve."
        sendState(player,"Join")
        return
    end

    if actionKey==Constants.ACTIONS.Step then
        state.MoveOptions=availableMoves(state)
        if #state.MoveOptions==0 then
            state.LastEvent=currentTileHasLiveMonster(state) and "No revealed escape route." or "No connected room."
            setPopup(state,"Info","No move",state.Board.Name,state.LastEvent)
            sendState(player,"Join")
            return
        end
        state.CanAct=false
        state.ActionUsed=true
        state.Phase=currentTileHasLiveMonster(state) and "Run" or "Move"
        state.LastEvent=currentTileHasLiveMonster(state) and "Pick a revealed connected room to run." or "Pick a glowing connected room."
        sendState(player,"Join")
        return

    elseif actionKey==Constants.ACTIONS.Strike then
        if tile and tile.Kind=="Enemy" and not tile.Cleared and (tile.HP or 0)>0 then
            if tile.Shielded then
                state.LastEvent=(tile.Enemy or "Enemy").." is protected by the puzzle shield."
                setPopup(state,"Monster","Shielded",tile.Enemy,"Solve the room puzzle first. Your hit sparks off the shield.")
            else
                local damage=1+getEquippedPower(state,"Weapon")
                tile.HP=math.max(0,(tile.HP or 1)-damage)
                progressTask(profile,"StrikeEnemy")
                if tile.HP<=0 then
                    tile.Cleared=true
                    state.LastEvent=(tile.Enemy or "Enemy").." defeated. Doors can open again."
                    progressTask(profile,"DefeatEnemy")
                    setPopup(state,"Combat","Monster defeated",tile.Enemy,"The path is safer.")
                else
                    state.LastEvent=(tile.Enemy or "Enemy").." is wounded. Monster action incoming."
                    setPopup(state,"Combat","Hit",tile.Enemy,"The monster survives and prepares an action.")
                end
            end
        else
            state.LastEvent="No monster here."
            setPopup(state,"Info","No target","Fight","Move onto or reveal an enemy tile first.")
        end

    elseif actionKey==Constants.ACTIONS.Search then
        if not tile then return end
        local key=tileSearchKey(state,tile)
        state.SearchedTiles=state.SearchedTiles or {}
        if state.SearchedTiles[key] then
            state.LastEvent="Already searched. Team-shared search prevents repeats."
            setPopup(state,"Search","Already searched",tile.Label,"This tile cannot be searched again.")
            sendState(player,"Join")
            return
        end
        if currentTileHasLiveMonster(state) then
            state.LastEvent="Too dangerous to search while the monster is here."
            setPopup(state,"Search","Too dangerous",tile.Enemy or "Monster","Fight, guard, or run first.")
            sendState(player,"Join")
            return
        end

        markCurrentTileSearched(state)
        progressTask(profile,"SearchSafely")

        if state.Board.Id=="puzzle_twin_seal_gate" and tile.PuzzleRole=="LeverSearch" then
            local lever=getTile(state,"lever")
            if lever then lever.Revealed=true; lever.ObjectVisible=true; lever.Cleared=false end
            tile.SearchClue="Lever revealed"
            state.LastEvent="The hidden lever rises from the floor. Move to it and Use it."
            setPopup(state,"Search","Lever revealed",tile.Label,"A real lever is now visible on the board.")
        elseif state.Board.Id=="puzzle_echo_bell_chamber" and tile.PuzzleRole=="BellClue" then
            state.PuzzleState.ClueRevealed=true
            state.LastEvent="Bell order revealed: Moon → Fang → Eye."
            setPopup(state,"Puzzle","Bell Sequence","Moon → Fang → Eye","Ring those bells in order. Wrong bells reset the sequence.")
        elseif tile.Kind=="Trap" and not tile.Cleared then
            tile.SearchClue="Mechanism found"
            state.LastEvent="Search revealed the trap mechanism. Use can disarm it."
            setPopup(state,"Search","Mechanism found",tile.Label,"Use this tile to disarm it.")
        elseif tile.Kind=="Treasure" and not tile.Cleared then
            tile.SearchClue="Chest checked"
            state.LastEvent="Search checks the chest. Use it for a safer reward roll."
            setPopup(state,"Search","Chest checked",tile.Label,"The lock looks real. Use opens it.")
        elseif tile.Kind=="Discovery" and not tile.Cleared then
            tile.SearchClue="Clue found"
            state.LastEvent="Search found a usable clue."
            setPopup(state,"Search","Clue found",tile.Label,"Use this tile to activate the clue.")
        else
            applyOutcome(player,state,chooseWeighted(state.Board.SearchOutcomes,Random.new(todaySeed()+state.EventCounter+state.RoomIndex)),"Search")
        end

    elseif actionKey==Constants.ACTIONS.Interact then
        local hasInteract, interactLabel=currentTileHasInteract(state)
        if not hasInteract then
            state.LastEvent="Nothing useful here."
            setPopup(state,"Use","No use",tile and tile.Label or "Unknown","Search or move to a usable object.")
            sendState(player,"Join")
            return
        end

        if state.Board.Id=="puzzle_twin_seal_gate" then
            if tile.PuzzleRole=="Lever" then
                state.PuzzleState.LeverPulled=true
                tile.Cleared=true
                state.LastEvent="Lever pulled. Now the partner plate must be held."
                setPopup(state,"Puzzle","Lever pulled","Twin Seal Gate","The seal line lights up.")
            elseif tile.PuzzleRole=="Plate" then
                state.PuzzleState.PlateHeld=true
                tile.Cleared=true
                state.LastEvent="Partner plate held. The gate is ready."
                setPopup(state,"Puzzle","Plate held","Teamwork","Your partner locks the pressure plate down.")
            elseif tile.PuzzleRole=="Gate" then
                if state.PuzzleState.LeverPulled and state.PuzzleState.PlateHeld then
                    state.PuzzleState.GateOpen=true
                    tile.Cleared=true
                    unlockPuzzleMonsterIfSolved(state)
                    state.LastEvent="Gate opened. The brute shield breaks."
                    setPopup(state,"Puzzle","Gate opened","Shield broken","The Seal Brute is vulnerable now.")
                end
            end
        elseif state.Board.Id=="puzzle_echo_bell_chamber" and tile.PuzzleRole=="Bell" then
            local p=state.PuzzleState
            local expected=p.BellSequence[p.BellIndex]
            if tile.BellSymbol==expected then
                p.BellIndex += 1
                state.LastEvent="Correct bell: "..tile.BellSymbol.."."
                setPopup(state,"Bell","Correct",tile.BellSymbol,"Sequence progress: "..tostring(p.BellIndex-1).."/"..tostring(#p.BellSequence))
                if p.BellIndex>#p.BellSequence then
                    p.Solved=true
                    unlockPuzzleMonsterIfSolved(state)
                    state.LastEvent="Echo sequence solved. Choir Warden shield breaks."
                    setPopup(state,"Puzzle","Sequence solved","Shield broken","The Warden is vulnerable.")
                end
            else
                p.BellWrong=(p.BellWrong or 0)+1
                p.BellIndex=1
                you.HP=math.max(1,you.HP-1)
                state.LastEvent="Wrong bell. Sequence reset. -1 HP."
                setPopup(state,"Bell","Wrong bell",tile.BellSymbol,"The chamber rings back. Sequence reset.")
            end
        elseif tile.Kind=="Treasure" then
            local item=addItem(state,LOOT_TABLE[((state.RoomIndex+state.EventCounter+#state.Backpack.Items)%#LOOT_TABLE)+1])
            tile.Cleared=true
            state.LastEvent="Opened chest: "..(item and item.Data.Name or "reward").."."
            setPopup(state,"Treasure","Chest opened",item and item.Data.Name or "Reward",item and item.Data.Body or "Found something.")
        elseif tile.Kind=="Discovery" then
            tile.Cleared=true
            if state.RoomIndex<=8 and not state.SecretPath and state.Board.Theme=="Secret" then state.SecretPath=true end
            state.LastEvent="Clue used."
            setPopup(state,"Use","Clue used",tile.Label,"The board changes.")
        elseif tile.Kind=="Trap" then
            tile.Cleared=true
            state.LastEvent="Hazard disarmed."
            setPopup(state,"Use","Disarmed",tile.Label,"Good search made the hazard useful.")
        elseif tile.Kind=="Exit" then
            revealTileEvent(player,state,tile)
            sendState(player,"Join")
            return
        end

    elseif actionKey==Constants.ACTIONS.Shield then
        you.HP=math.min(8,you.HP+1)
        state.LastEvent="Guarded. +1 HP."
        progressTask(profile,"ShieldPartner")
        setPopup(state,"Guard","Guarded","Safe turn","+1 HP.")
    end

    beginNextTurn(player,state,1.2)
    clientEvent:FireClient(player,Constants.TOPICS.Profile,profile)
end

local function handleTableClick(player,payload) if type(payload)~="table" then return end; if joinedGame[player.UserId]~=Constants.GAME_KEYS.DungeonDoors then return end; local state=playerStates[player.UserId]; if not state then return end; if (payload.Kind=="Tile" and payload.Id) or (payload.Action=="Move" and payload.TileId) then payload.Id = payload.Id or payload.TileId if state.MoveOptions then local moved=moveToTile(player,state,payload.Id); if moved and not state.DoorOptions and not state.PendingEquip then beginNextTurn(player,state,1.35) else sendState(player,"Join") end; clientEvent:FireClient(player,Constants.TOPICS.Profile,getProfile(player)) else state.LastEvent=currentTileHasLiveMonster(state) and "Use Step to run away to a revealed tile." or "Use Step first, then click a glowing tile."; sendState(player,"Join") end end end
local function handleChoice(player,choiceId) if joinedGame[player.UserId]~=Constants.GAME_KEYS.DungeonDoors then return end; local state=playerStates[player.UserId]; if not state then return end; if state.PendingEquip then if choiceId=="equip" then local p=state.PendingEquip; for _,e in ipairs(state.Backpack.Items) do if e.Data.Slot==p.Slot then e.Equipped=false end; if e.Uid==p.NewUid then e.Equipped=true end end; state.Backpack.Equipped[p.Slot]=p.NewUid; state.PendingEquip=nil; state.CanAct=true; state.ActionUsed=false; setPopup(state,"Item","Equipped","Gear changed","Your backpack equipment updated."); progressTask(getProfile(player),"EquipItem") elseif choiceId=="keep" then state.PendingEquip=nil; state.CanAct=true; state.ActionUsed=false end elseif state.DoorOptions then chooseDoor(player,state,choiceId) end; sendState(player,"Join"); clientEvent:FireClient(player,Constants.TOPICS.Profile,getProfile(player)) end
local function handleBackpackAction(player,payload) if joinedGame[player.UserId]~=Constants.GAME_KEYS.DungeonDoors then return end; local state=playerStates[player.UserId]; if not state then return end; payload=payload or {}; local entryIndex,entry=nil,nil; for i,item in ipairs(state.Backpack.Items or {}) do if item.Uid==payload.Uid then entryIndex=i; entry=item end end; if not entry then return end; if payload.Action=="equip" and entry.Data.Slot then for _,item in ipairs(state.Backpack.Items) do if item.Data.Slot==entry.Data.Slot then item.Equipped=false end end; entry.Equipped=true; state.Backpack.Equipped[entry.Data.Slot]=entry.Uid; progressTask(getProfile(player),"EquipItem"); setPopup(state,"Item","Equipped",entry.Data.Name,entry.Data.Body) elseif payload.Action=="use" and entry.Data.Type=="Consumable" then state.Players[1].HP=math.min(8,state.Players[1].HP+(entry.Data.Power or 1)); table.remove(state.Backpack.Items,entryIndex); setPopup(state,"Item","Used Item",entry.Data.Name,"Recovered HP.") end; sendState(player,"Join"); clientEvent:FireClient(player,Constants.TOPICS.Profile,getProfile(player)) end
local function renderGameFor(player,gameKey,mode) local gameInfo=GameCatalog.GetGame(gameKey); if not gameInfo then return end; if gameKey==Constants.GAME_KEYS.DungeonDoors then playerStates[player.UserId]=playerStates[player.UserId] or makeDungeonState(player); sendState(player,mode or "Join") end end
local function joinPlayer(player,gameKey) local profile=getProfile(player); if not profile.UnlockedGames[gameKey] then return end; joinedGame[player.UserId]=gameKey; playerStates[player.UserId]=makeDungeonState(player); renderGameFor(player,gameKey,"Join"); for _,p in ipairs(Players:GetPlayers()) do clientEvent:FireClient(p,Constants.TOPICS.TableList,tableList()) end end
local function spectatePlayer(player,gameKey) playerStates[player.UserId]=playerStates[player.UserId] or makeDungeonState(player); renderGameFor(player,gameKey,"Spectate") end
Players.PlayerAdded:Connect(function(player) getProfile(player); task.defer(sendProfile,player) end)
Players.PlayerRemoving:Connect(function(player) joinedGame[player.UserId]=nil; playerStates[player.UserId]=nil end)
requestProfile.OnServerEvent:Connect(function(player) sendProfile(player) end)
joinGame.OnServerEvent:Connect(function(player,gameKey) joinPlayer(player,gameKey) end)
spectateGame.OnServerEvent:Connect(function(player,gameKey) spectatePlayer(player,gameKey) end)
submitAction.OnServerEvent:Connect(function(player,actionKey) submitDungeonAction(player,actionKey) end)
submitChoice.OnServerEvent:Connect(function(player,choiceId) handleChoice(player,choiceId) end)
tableClick.OnServerEvent:Connect(function(player,payload) handleTableClick(player,payload) end)
backpackAction.OnServerEvent:Connect(function(player,payload) handleBackpackAction(player,payload) end)
claimDailyTask.OnServerEvent:Connect(function(player,taskKey) claimTask(player,taskKey) end)
if okWorld then local map=workspace:FindFirstChild("TableRushMap"); local dungeon=map and map:FindFirstChild("DungeonDoorsTable"); if dungeon then local jp=dungeon:FindFirstChild("JoinDungeonDoors"); local sp=dungeon:FindFirstChild("SpectateDungeonDoors"); local jpp=jp and jp:FindFirstChildOfClass("ProximityPrompt"); local spp=sp and sp:FindFirstChildOfClass("ProximityPrompt"); if jpp then jpp.Triggered:Connect(function(player) joinPlayer(player,Constants.GAME_KEYS.DungeonDoors) end) end; if spp then spp.Triggered:Connect(function(player) spectatePlayer(player,Constants.GAME_KEYS.DungeonDoors) end) end end end
for _,player in ipairs(Players:GetPlayers()) do task.defer(sendProfile,player) end
