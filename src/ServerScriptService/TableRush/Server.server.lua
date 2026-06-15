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
    RustySword={Id="RustySword",Name="Rusty Sword",Type="Weapon",Slot="Weapon",Power=1,Body="Reliable blade. +1 Strike damage."},
    HookBlade={Id="HookBlade",Name="Hook Blade",Type="Weapon",Slot="Weapon",Power=1,Body="Strike can interrupt pulls, skitters, and fleeing enemies."},
    LanternSpear={Id="LanternSpear",Name="Lantern Spear",Type="Weapon",Slot="Weapon",Power=2,Body="+2 Strike. Extra bite against Candledead and cursed rooms."},
    ChainAxe={Id="ChainAxe",Name="Chain Axe",Type="Weapon",Slot="Weapon",Power=2,Body="Breaks chain locks and hurts wardens harder."},
    GlassDagger={Id="GlassDagger",Name="Glass Dagger",Type="Weapon",Slot="Weapon",Power=4,Fragile=true,Body="Huge one-time Strike. It may break after a heavy hit."},

    LeatherArmor={Id="LeatherArmor",Name="Leather Armor",Type="Armor",Slot="Armor",Power=1,Body="Blocks 1 damage from enemy intent."},
    ChainVest={Id="ChainVest",Name="Chain Vest",Type="Armor",Slot="Armor",Power=1,Body="Blocks pull, bind, and chain effects once per room."},
    CandleCloak={Id="CandleCloak",Name="Candle Cloak",Type="Armor",Slot="Armor",Power=1,Body="Resists curse and Light drain."},
    FloodBoots={Id="FloodBoots",Name="Flood Boots",Type="Armor",Slot="Boots",Power=2,Body="Reduces flooded and trap damage."},
    SpiderhideBoots={Id="SpiderhideBoots",Name="Spiderhide Boots",Type="Armor",Slot="Boots",Power=2,Body="Ignore Webbed Floor movement penalties."},

    Torch={Id="Torch",Name="Torch",Type="Tool",Power=1,Body="Use to reveal a nearby room clue or weaken shades."},
    Rope={Id="Rope",Name="Rope",Type="Tool",Power=1,Body="Fix bridge gaps or escape when a route is blocked."},
    Lockpick={Id="Lockpick",Name="Lockpick",Type="Tool",Power=1,Body="Open a locked route without spending a Key."},
    Bomb={Id="Bomb",Name="Bomb",Type="Tool",Power=2,Body="Break cracked walls or damage a monster. Loud and risky."},
    HolySalt={Id="HolySalt",Name="Holy Salt",Type="Tool",Power=1,Body="Cancel one curse, haunt, or shade effect."},
    Bandage={Id="Bandage",Name="Bandage",Type="Consumable",Power=2,Body="Heal 2 HP or help revive a downed teammate."},

    DeathCandle={Id="DeathCandle",Name="Death Candle",Type="Relic",Power=1,DeathSave=true,Body="Breaks instead of dying once."},
    BrokenCompass={Id="BrokenCompass",Name="Broken Compass",Type="Relic",Power=1,Body="Route Scheme is stronger; can reveal safer doors."},
    SpiderEye={Id="SpiderEye",Name="Spider Eye",Type="Relic",Power=1,Body="Search in web rooms is safer."},
    SaintCoin={Id="SaintCoin",Name="Saint Coin",Type="Relic",Power=1,DeathSave=true,Body="Prevents death once, but raises Threat."},
    GoldKey={Id="GoldKey",Name="Gold Key",Type="Key",Power=1,Body="Opens the optional Gold Key Vault after the boss."},
}
local LOOT_TABLE = {"Bandage","Torch","Rope","Lockpick","LeatherArmor","FloodBoots","HookBlade","CandleCloak","HolySalt","SpiderhideBoots","ChainVest","LanternSpear","Bomb","BrokenCompass","DeathCandle"}

local ROOM_TEMPLATES = {
    {Id="room_1", Name="Dusty Entry", Family="Ruins", Theme="Tutorial", Trait="Familiar Ground", TraitBody="Low danger. Search reveals useful basics.", Difficulty=1, Atmosphere={TableColor={46,53,60}, Glow={72,178,225}, Material="Slate"}, Props={"Crates","Lantern"}, Objects={"Broken Crate","Old Torch","Cracked Floor"}, EntryEvent="A cold blue torch marks the first safe route.", Tiles={{Id="start",Label="Entry",Kind="Start",X=0,Y=0},{Id="crate",Label="Broken Crate",Kind="Treasure",Object="Crate",X=1,Y=0},{Id="rat",Label="Bone Rat",Kind="Enemy",Enemy="Bone Rat",HP=2,X=2,Y=0},{Id="torch",Label="Old Torch",Kind="Discovery",Object="Torch",X=1,Y=1},{Id="exit",Label="Exit Gate",Kind="Exit",X=3,Y=0}}},
    {Id="room_2", Name="Collapsed Bridge", Family="Puzzle", Theme="Movement", Trait="Broken Crossing", TraitBody="A route can collapse. Search or Scheme repairs a path.", Difficulty=2, Atmosphere={TableColor={38,45,36}, Glow={85,205,165}, Material="WoodPlanks"}, Props={"BrokenBridge","Rope"}, Objects={"Bridge Gap","Loose Rope","Side Ledge"}, EntryEvent="The bridge cracks under the first step.", Tiles={{Id="start",Label="Near Ledge",Kind="Start",X=0,Y=0},{Id="bridge",Label="Bridge Gap",Kind="Puzzle",Object="Bridge",Puzzle="RepairBridge",Blocked=true,X=1,Y=0},{Id="ledge",Label="Side Ledge",Kind="Discovery",Object="Rope",X=1,Y=1},{Id="rat",Label="Rope Rat",Kind="Enemy",Enemy="Bone Rat",HP=3,X=2,Y=1},{Id="cache",Label="Hanging Cache",Kind="Treasure",Object="Hanging Chest",X=2,Y=-1},{Id="exit",Label="Far Gate",Kind="Exit",X=3,Y=0}}},
    {Id="room_3", Name="Pale Spider Court", Family="Web Court", Theme="Ambush", Trait="Webbed Floor", TraitBody="Monsters block deep movement. Search cocoons for loot or eggs.", Difficulty=2, Atmosphere={TableColor={36,27,46}, Glow={170,112,255}, Material="Basalt"}, Props={"Webs","Cocoons"}, Objects={"Cocoon","Egg Cluster","Silk Wall"}, EntryEvent="Webs pull tight across the room.", Tiles={{Id="start",Label="Silk Door",Kind="Start",X=0,Y=0},{Id="cocoon",Label="Cocoon",Kind="Treasure",Object="Cocoon",X=1,Y=0},{Id="eggs",Label="Egg Cluster",Kind="Trap",Object="Eggs",X=1,Y=-1},{Id="spider",Label="Pale Spider",Kind="Enemy",Enemy="Pale Spider",HP=5,X=2,Y=0},{Id="silk",Label="Silk Wall",Kind="Discovery",Object="Secret Silk",SecretHook=true,X=2,Y=1},{Id="exit",Label="Web Gate",Kind="Exit",X=3,Y=0}}},
    {Id="room_4", Name="Mimic Storage", Family="Gilded Hunger", Theme="Greed", Trait="Suspicious Loot", TraitBody="Treasure is stronger, but Search can wake or expose a Mimic.", Difficulty=2, Atmosphere={TableColor={58,43,32}, Glow={225,155,72}, Material="Wood"}, Props={"Chests","Coins"}, Objects={"Suspicious Chest","Locked Box","False Shrine"}, EntryEvent="Several chests breathe out of sync.", Tiles={{Id="start",Label="Storage Door",Kind="Start",X=0,Y=0},{Id="chest",Label="Big Chest",Kind="Treasure",Object="Suspicious Chest",X=1,Y=0},{Id="box",Label="Locked Box",Kind="Puzzle",Object="Lockbox",Puzzle="UnlockChest",X=1,Y=1},{Id="mimic",Label="Mimic Lurker",Kind="Enemy",Enemy="Mimic Lurker",HP=5,X=2,Y=0},{Id="trap",Label="Bait Coins",Kind="Trap",Object="Cursed Coins",X=2,Y=-1},{Id="exit",Label="Store Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_5", Name="Black Candle Room", Family="Candledead", Theme="Curse", Trait="Black Flame", TraitBody="Light matters. Scheme is powerful but cursed.", Difficulty=3, Atmosphere={TableColor={32,24,42}, Glow={164,94,232}, Material="Basalt"}, Props={"Candles","Shrine"}, Objects={"Black Candle","Wax Altar","Cursed Book"}, EntryEvent="The black candle drinks the room light.", Tiles={{Id="start",Label="Dark Door",Kind="Start",X=0,Y=0},{Id="candle",Label="Black Candle",Kind="Puzzle",Object="Black Candle",Puzzle="Extinguish",X=1,Y=0},{Id="shade",Label="Candle Shade",Kind="Enemy",Enemy="Candle Shade",HP=4,X=2,Y=0},{Id="book",Label="Cursed Book",Kind="Discovery",Object="Cursed Book",X=1,Y=1},{Id="altar",Label="Wax Altar",Kind="Trap",Object="Wax Altar",X=2,Y=1},{Id="exit",Label="Cold Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_6", Name="Flooded Crypt", Family="Drowned", Theme="Flood", Trait="Flooded Floor", TraitBody="Traps and movement hurt more unless protected.", Difficulty=3, Atmosphere={TableColor={28,47,56}, Glow={70,170,205}, Material="Slate"}, Props={"Water","Tombs"}, Objects={"Flooded Crate","Drain Lever","Sunken Coffin"}, EntryEvent="Water climbs around the player bases.", Tiles={{Id="start",Label="Wet Steps",Kind="Start",X=0,Y=0},{Id="lever",Label="Drain Lever",Kind="Puzzle",Object="Drain Lever",Puzzle="DrainWater",X=1,Y=0},{Id="coffin",Label="Sunken Coffin",Kind="Treasure",Object="Coffin",X=1,Y=-1},{Id="guard",Label="Drowned Guard",Kind="Enemy",Enemy="Drowned Guard",HP=5,X=2,Y=0},{Id="trap",Label="Sink Trap",Kind="Trap",Object="Sinkhole",X=2,Y=1},{Id="exit",Label="Crypt Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_7", Name="Chain Gallery", Family="Doorbound", Theme="Control", Trait="Chained Room", TraitBody="Run Away can be blocked. Scheme can break control.", Difficulty=3, Atmosphere={TableColor={42,42,50}, Glow={185,185,196}, Material="Metal"}, Props={"Chains","Locks"}, Objects={"Chain Lever","Locked Gate","Hanging Cage"}, EntryEvent="A chain gate slams behind you.", Tiles={{Id="start",Label="Iron Door",Kind="Start",X=0,Y=0},{Id="lever",Label="Chain Lever",Kind="Puzzle",Object="Chain Lever",Puzzle="UnlockGate",X=1,Y=0},{Id="cage",Label="Hanging Cage",Kind="Discovery",Object="Cage",X=1,Y=1},{Id="warden",Label="Chain Warden",Kind="Enemy",Enemy="Chain Warden",HP=7,X=2,Y=0},{Id="gate",Label="Locked Gate",Kind="Puzzle",Object="Locked Gate",Puzzle="OpenGate",Locked=true,X=3,Y=0},{Id="exit",Label="Iron Exit",Kind="Exit",X=4,Y=0}}},
    {Id="room_8", Name="Echo Hall", Family="Ruins", Theme="Fear", Trait="Echoing Stone", TraitBody="Noise raises Threat. Search can reveal hidden walls.", Difficulty=3, Atmosphere={TableColor={36,39,48}, Glow={120,160,210}, Material="Cobblestone"}, Props={"Mist","Statues"}, Objects={"Bell Rope","Cracked Wall","Echo Statue"}, EntryEvent="Every step repeats back wrong.", Tiles={{Id="start",Label="Whisper Door",Kind="Start",X=0,Y=0},{Id="bell",Label="Bell Rope",Kind="Trap",Object="Bell Rope",X=1,Y=-1},{Id="wall",Label="Cracked Wall",Kind="Puzzle",Object="Cracked Wall",Puzzle="BreakWall",SecretHook=true,X=1,Y=0},{Id="statue",Label="Echo Statue",Kind="Discovery",Object="Echo Statue",X=1,Y=1},{Id="goblin",Label="Door Goblin",Kind="Enemy",Enemy="Door Goblin",HP=4,X=2,Y=0},{Id="exit",Label="Silent Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_9", Name="Spider Egg Chapel", Family="Web Court", Theme="Ambush", Trait="Hatching Room", TraitBody="Ignoring eggs makes future enemy turns worse.", Difficulty=4, Atmosphere={TableColor={40,26,42}, Glow={200,120,235}, Material="Basalt"}, Props={"Webs","Eggs"}, Objects={"Egg Nest","Cocoon Altar","Silk Door"}, EntryEvent="The eggs twitch in rows.", Tiles={{Id="start",Label="Chapel Door",Kind="Start",X=0,Y=0},{Id="eggs",Label="Egg Nest",Kind="Trap",Object="Egg Nest",Puzzle="BurnEggs",X=1,Y=0},{Id="altar",Label="Cocoon Altar",Kind="Treasure",Object="Cocoon Altar",X=1,Y=1},{Id="spider",Label="Brood Spider",Kind="Enemy",Enemy="Pale Spider",HP=6,X=2,Y=0},{Id="silk",Label="Silk Door",Kind="Discovery",Object="Silk Door",X=2,Y=-1},{Id="exit",Label="Egg Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_10", Name="Gold Maw", Family="Gilded Hunger", Theme="Greed", Trait="Hungry Gold", TraitBody="Reward is high. Greed can bite back hard.", Difficulty=4, Atmosphere={TableColor={66,46,26}, Glow={230,150,64}, Material="Granite"}, Props={"Coins","Teeth"}, Objects={"Gold Mouth","Coin Pile","Cursed Chest"}, EntryEvent="The gold mouth opens one tooth at a time.", Tiles={{Id="start",Label="Maw Door",Kind="Start",X=0,Y=0},{Id="coins",Label="Coin Pile",Kind="Treasure",Object="Coin Pile",X=1,Y=-1},{Id="maw",Label="Gold Maw",Kind="Enemy",Enemy="Gold Maw",HP=8,X=2,Y=0},{Id="chest",Label="Cursed Chest",Kind="Treasure",Object="Cursed Chest",X=1,Y=1},{Id="plate",Label="Midas Plate",Kind="Trap",Object="Midas Plate",X=2,Y=1},{Id="exit",Label="Maw Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_11", Name="Burnt Shrine", Family="Ash", Theme="Fire", Trait="Spreading Ember", TraitBody="Threat rises if the shrine burns too long.", Difficulty=4, Atmosphere={TableColor={58,32,24}, Glow={235,108,54}, Material="Basalt"}, Props={"Smoke","Embers"}, Objects={"Burning Altar","Coal Path","Cracked Urn"}, EntryEvent="The altar burns hotter each turn.", Tiles={{Id="start",Label="Ash Door",Kind="Start",X=0,Y=0},{Id="altar",Label="Burning Altar",Kind="Puzzle",Object="Burning Altar",Puzzle="DouseFire",X=1,Y=0},{Id="urn",Label="Cracked Urn",Kind="Treasure",Object="Urn",X=1,Y=1},{Id="imp",Label="Ash Imp",Kind="Enemy",Enemy="Ash Imp",HP=4,X=2,Y=0},{Id="coal",Label="Coal Path",Kind="Trap",Object="Coal Path",X=2,Y=-1},{Id="exit",Label="Smoke Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_12", Name="Locked Observatory", Family="Puzzle", Theme="Discovery", Trait="Star Dial", TraitBody="Information room. Search reveals route and secret clues.", Difficulty=3, Atmosphere={TableColor={30,42,58}, Glow={105,180,230}, Material="Metal"}, Props={"Lens","Cabinet"}, Objects={"Telescope","Star Dial","Locked Cabinet"}, EntryEvent="A star map rotates to the next door.", Tiles={{Id="start",Label="Lens Door",Kind="Start",X=0,Y=0},{Id="dial",Label="Star Dial",Kind="Puzzle",Object="Star Dial",Puzzle="AlignStars",X=1,Y=0},{Id="cabinet",Label="Cabinet",Kind="Treasure",Object="Locked Cabinet",X=1,Y=1},{Id="shade",Label="Star Shade",Kind="Enemy",Enemy="Candle Shade",HP=4,X=2,Y=-1},{Id="clue",Label="Route Clue",Kind="Discovery",Object="Route Chart",SecretHook=true,X=2,Y=0},{Id="exit",Label="Star Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_13", Name="Bone Kitchen", Family="Vermin", Theme="Vermin", Trait="Gnawing Pantry", TraitBody="Supplies are at risk. Rats get stronger if ignored.", Difficulty=3, Atmosphere={TableColor={50,39,34}, Glow={170,125,76}, Material="Ground"}, Props={"Bones","Pots"}, Objects={"Bone Pile","Stew Pot","Pantry Shelf"}, EntryEvent="Something chews inside the walls.", Tiles={{Id="start",Label="Kitchen Door",Kind="Start",X=0,Y=0},{Id="pile",Label="Bone Pile",Kind="Discovery",Object="Bone Pile",X=1,Y=0},{Id="rat",Label="Bone Rat",Kind="Enemy",Enemy="Bone Rat",HP=4,X=2,Y=0},{Id="pot",Label="Stew Pot",Kind="Treasure",Object="Stew Pot",X=1,Y=1},{Id="trap",Label="Grease Spill",Kind="Trap",Object="Grease",X=2,Y=1},{Id="exit",Label="Kitchen Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_14", Name="Warden Post", Family="Doorbound", Theme="Control", Trait="Guard Station", TraitBody="A mini-boss space. Disable bell or Warden gains actions.", Difficulty=5, Atmosphere={TableColor={48,40,44}, Glow={205,88,76}, Material="Metal"}, Props={"Chains","Bell"}, Objects={"Guard Bell","Weapon Rack","Locked Chest"}, EntryEvent="The guard bell starts swinging.", Tiles={{Id="start",Label="Post Door",Kind="Start",X=0,Y=0},{Id="bell",Label="Guard Bell",Kind="Puzzle",Object="Guard Bell",Puzzle="SilenceBell",X=1,Y=0},{Id="rack",Label="Weapon Rack",Kind="Treasure",Object="Weapon Rack",X=1,Y=1},{Id="warden",Label="Chain Warden",Kind="Enemy",Enemy="Chain Warden",HP=8,X=2,Y=0},{Id="chest",Label="Locked Chest",Kind="Treasure",Object="Locked Chest",X=2,Y=-1},{Id="exit",Label="Guard Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_15", Name="White Door", Family="Secret", Theme="Secret", Trait="Silent Bargain", TraitBody="A rare room that can reveal the secret death-treasure path.", Difficulty=2, Atmosphere={TableColor={50,48,58}, Glow={245,230,170}, Material="Marble"}, Props={"Shrine","WhiteDoor"}, Objects={"White Door","Prayer Stones","Sealed Light"}, EntryEvent="The room refuses to echo.", Tiles={{Id="start",Label="Quiet Step",Kind="Start",X=0,Y=0},{Id="stones",Label="Prayer Stones",Kind="Discovery",Object="Prayer Stones",SecretHook=true,X=1,Y=0},{Id="light",Label="Sealed Light",Kind="Treasure",Object="Sealed Light",X=1,Y=1},{Id="shade",Label="Quiet Shade",Kind="Enemy",Enemy="Candle Shade",HP=3,X=2,Y=0},{Id="door",Label="White Door",Kind="Puzzle",Object="White Door",Puzzle="OpenWhiteDoor",X=2,Y=-1},{Id="exit",Label="Quiet Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_16", Name="False Vault", Family="Gilded Hunger", Theme="Greed", Trait="Fake Ending", TraitBody="Looks like a vault. Search proves what is real.", Difficulty=5, Atmosphere={TableColor={62,45,30}, Glow={230,144,68}, Material="Granite"}, Props={"Vault","Coins"}, Objects={"Fake Vault Door","Treasure Pedestal","Warning Mark"}, EntryEvent="The vault door smiles before it unlocks.", Tiles={{Id="start",Label="Vault Door",Kind="Start",X=0,Y=0},{Id="pedestal",Label="Pedestal",Kind="Treasure",Object="Pedestal",X=1,Y=0},{Id="mark",Label="Warning Mark",Kind="Discovery",Object="Warning Mark",X=1,Y=1},{Id="mimic",Label="Mimic Lurker",Kind="Enemy",Enemy="Mimic Lurker",HP=7,X=2,Y=0},{Id="trap",Label="False Lock",Kind="Trap",Object="False Lock",X=2,Y=-1},{Id="exit",Label="Real Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_17", Name="Red Lock Chamber", Family="BossPrep", Theme="Control", Trait="Red Lock", TraitBody="Keys, lockpicks, and Scheme can change the boss approach.", Difficulty=5, Atmosphere={TableColor={52,32,36}, Glow={215,70,60}, Material="Metal"}, Props={"Locks","RedFog"}, Objects={"Red Lock","Gold Keyhole","Pressure Plate"}, EntryEvent="The red lock counts your keys.", Tiles={{Id="start",Label="Red Door",Kind="Start",X=0,Y=0},{Id="lock",Label="Red Lock",Kind="Puzzle",Object="Red Lock",Puzzle="PickLock",X=1,Y=0},{Id="keyhole",Label="Gold Keyhole",Kind="Discovery",Object="Gold Keyhole",X=1,Y=-1},{Id="plate",Label="Pressure Plate",Kind="Trap",Object="Pressure Plate",X=2,Y=1},{Id="warden",Label="Door Goblin",Kind="Enemy",Enemy="Door Goblin",HP=5,X=2,Y=0},{Id="exit",Label="Red Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_18", Name="Doorwarden's Vault", Family="Boss", Theme="Boss", Trait="Living Vault", TraitBody="Boss room. Doorwarden locks routes and attacks both players.", Difficulty=6, Atmosphere={TableColor={34,30,36}, Glow={215,70,60}, Material="Metal"}, Props={"Vault","Chains","RedFog"}, Objects={"Vault Heart","Chain Pillars","Red Door"}, EntryEvent="The table becomes a vault door.", Tiles={{Id="start",Label="Vault Edge",Kind="Start",X=0,Y=0},{Id="pillar_a",Label="Chain Pillar",Kind="Puzzle",Object="Chain Pillar",Puzzle="BreakPillar",X=1,Y=-1},{Id="heart",Label="Vault Heart",Kind="Discovery",Object="Vault Heart",X=1,Y=0},{Id="warden",Label="Doorwarden",Kind="Enemy",Enemy="Doorwarden",HP=14,X=2,Y=0},{Id="pillar_b",Label="Red Pillar",Kind="Puzzle",Object="Red Pillar",Puzzle="BreakPillar",X=2,Y=1},{Id="cache",Label="Boss Cache",Kind="Treasure",Object="Boss Cache",X=3,Y=-1},{Id="exit",Label="Broken Vault",Kind="Exit",X=3,Y=0}}},
    {Id="room_19", Name="Gold Key Vault", Family="Bonus", Theme="Treasure", Trait="Gold Key Only", TraitBody="Optional reward room unlocked by the Gold Key. Dangerous but rich.", Difficulty=5, Atmosphere={TableColor={58,44,26}, Glow={245,190,72}, Material="Granite"}, Props={"Coins","Vault"}, Objects={"Gold Lock","Relic Shelf","Trap Chest"}, EntryEvent="The Gold Key melts into the lock.", Tiles={{Id="start",Label="Gold Door",Kind="Start",X=0,Y=0},{Id="shelf",Label="Relic Shelf",Kind="Treasure",Object="Relic Shelf",X=1,Y=0},{Id="chest",Label="Trap Chest",Kind="Trap",Object="Trap Chest",X=1,Y=1},{Id="guard",Label="Gold Maw",Kind="Enemy",Enemy="Gold Maw",HP=9,X=2,Y=0},{Id="key",Label="Vault Prize",Kind="Discovery",Object="Vault Prize",X=2,Y=-1},{Id="exit",Label="Vault Exit",Kind="Exit",X=3,Y=0}}},
    {Id="room_20", Name="Gilded Death Room", Family="Secret", Theme="Secret", Trait="Treasure or Death", TraitBody="Secret room 11. Huge reward, wipe-level danger.", Difficulty=7, Atmosphere={TableColor={66,38,30}, Glow={245,190,72}, Material="Granite"}, Props={"Coins","RedFog","Shrine"}, Objects={"Cursed Altar","Treasure Heaps","Escape Door"}, EntryEvent="Every coin looks like an eye.", Tiles={{Id="start",Label="Secret Drop",Kind="Start",X=0,Y=0},{Id="heaps",Label="Treasure Heaps",Kind="Treasure",Object="Treasure Heaps",X=1,Y=-1},{Id="altar",Label="Cursed Altar",Kind="Puzzle",Object="Cursed Altar",Puzzle="StealTreasure",X=1,Y=0},{Id="maw",Label="Gold Maw",Kind="Enemy",Enemy="Gold Maw",HP=12,X=2,Y=0},{Id="salt",Label="Revive Relic",Kind="Discovery",Object="Death Candle",X=2,Y=1},{Id="trap",Label="Greed Trap",Kind="Trap",Object="Greed Trap",X=3,Y=-1},{Id="exit",Label="Escape Door",Kind="Exit",X=3,Y=0}}},
}

local ROOM_INDEX = {}
for _, room in ipairs(ROOM_TEMPLATES) do ROOM_INDEX[room.Id] = room end

local ENEMY_TEMPLATES = {
    ["Door Goblin"]={Family="Doorbound", HP=3, Reward="Key", Intents={{Id="stab",Icon="⚔",Text="Stab",Damage=1},{Id="snatch",Icon="🗝",Text="Snatch Key",Steal="Key"},{Id="shout",Icon="!",Text="Shout",Threat=1},{Id="duck",Icon="↯",Text="Duck",Guard=1},{Id="run",Icon="↔",Text="Run Ahead",BlockExit=true}}},
    ["Bone Rat"]={Family="Vermin", HP=2, Reward="Supply", Intents={{Id="bite",Icon="⚔",Text="Bite",Damage=1},{Id="gnaw",Icon="▣",Text="Gnaw Supplies",Steal="Supply"},{Id="scurry",Icon="↔",Text="Scurry",Threat=1},{Id="swarm",Icon="!",Text="Call Swarm",Threat=2}}},
    ["Pale Spider"]={Family="Web Court", HP=5, Reward="Tool", Intents={{Id="web_bite",Icon="🕸",Text="Web Bite",Damage=1,Status="Webbed"},{Id="cocoon",Icon="◎",Text="Cocoon",BlockRun=true},{Id="drag",Icon="↙",Text="Drag Back",Damage=1,Status="Dragged"},{Id="egg",Icon="!",Text="Egg Burst",Threat=2},{Id="skitter",Icon="↔",Text="Skitter",Guard=1}}},
    ["Mimic Lurker"]={Family="Gilded Hunger", HP=6, Reward="Relic", Intents={{Id="snap",Icon="⚔",Text="Snap",Damage=2},{Id="fake",Icon="◇",Text="Fake Shine",Threat=1},{Id="devour",Icon="▣",Text="Devour Item",BreakItem=true},{Id="hide",Icon="?",Text="Hide Again",Hide=true},{Id="lure",Icon="$",Text="Lure",Threat=2}}},
    ["Candle Shade"]={Family="Candledead", HP=4, Reward="Light", Intents={{Id="drain",Icon="☾",Text="Drain Light",DrainLight=1},{Id="curse",Icon="✦",Text="Curse Scheme",Status="Cursed"},{Id="flicker",Icon="↯",Text="Flicker",Guard=1},{Id="haunt",Icon="!",Text="Haunt",Threat=2},{Id="possess",Icon="◎",Text="Possess Room",Threat=1,Status="Haunted"}}},
    ["Drowned Guard"]={Family="Drowned", HP=5, Reward="Armor", Intents={{Id="slash",Icon="⚔",Text="Rusted Slash",Damage=1},{Id="drag",Icon="≈",Text="Drag Under",Damage=1,Status="Soaked"},{Id="flood",Icon="≈",Text="Flood Step",BlockRun=true},{Id="guard",Icon="⬟",Text="Guard Relic",Guard=2},{Id="drown",Icon="☾",Text="Drown Light",DrainLight=1}}},
    ["Chain Warden"]={Family="Doorbound", HP=7, Reward="Key", Intents={{Id="slam",Icon="⚔",Text="Heavy Slam",Damage=2},{Id="pull",Icon="⛓",Text="Chain Pull",BlockRun=true},{Id="lockdown",Icon="▣",Text="Lockdown",DisableActions=true},{Id="guard",Icon="⬟",Text="Guard",Guard=2},{Id="bind",Icon="⛓",Text="Bind Partner",BindPartner=true}}},
    ["Ash Imp"]={Family="Ash", HP=4, Reward="Supply", Intents={{Id="spark",Icon="⚔",Text="Spark",Damage=1},{Id="ignite",Icon="🔥",Text="Ignite",Status="Burning"},{Id="feed",Icon="!",Text="Feed Fire",Threat=2},{Id="smoke",Icon="?",Text="Smoke",Hide=true},{Id="laugh",Icon="✦",Text="Laugh",Status="Unlucky"}}},
    ["Gold Maw"]={Family="Gilded Hunger", HP=9, Reward="Relic", Intents={{Id="bite",Icon="⚔",Text="Gold Bite",Damage=3},{Id="curse",Icon="$",Text="Greed Curse",Status="Greed Cursed"},{Id="devour",Icon="▣",Text="Devour Treasure",Threat=2},{Id="lock",Icon="◎",Text="Midas Trap",BreakItem=true},{Id="open",Icon="◇",Text="Maw Opens",Threat=1}}},
    ["Doorwarden"]={Family="Boss", HP=14, Reward="Victory", Intents={{Id="lock",Icon="▣",Text="Lock Door",Threat=2},{Id="slam",Icon="⚔",Text="Vault Slam",Damage=2},{Id="chain",Icon="⛓",Text="Summon Chain",Status="Bound"},{Id="key",Icon="🗝",Text="Consume Key",Steal="Key"},{Id="red",Icon="!",Text="Red Door Opens",Threat=3},{Id="split",Icon="↔",Text="Split Team",BindPartner=true}}},
}
local ENEMY_REWARDS = { ["Door Goblin"]=0,["Bone Rat"]=0,["Candle Shade"]=0,["Mimic Lurker"]=0,["Pale Spider"]=0,["Drowned Guard"]=0,["Chain Warden"]=0,["Doorwarden"]=0,["Ash Imp"]=0,["Gold Maw"]=0 }

local function deepCopy(v) if type(v)~="table" then return v end; local c={}; for k,x in pairs(v) do c[k]=deepCopy(x) end; return c end
local function chooseWeighted(outcomes, rng) local total=0; for _,o in ipairs(outcomes or {}) do total += o.Weight or 1 end; if total<=0 then return nil end; local roll=rng:NextInteger(1,total); local run=0; for _,o in ipairs(outcomes or {}) do run += o.Weight or 1; if roll<=run then return o end end; return outcomes and outcomes[1] end
local function buildRunPlan(seed)
    local pool = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17}
    local rng = Random.new(seed or todaySeed())
    for i = #pool, 2, -1 do
        local j = rng:NextInteger(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local exploration = {}
    local must = {1,2,3,4,5,6,7,8}
    for i = 1, 5 do exploration[i] = must[i] end
    for i = 6, 8 do exploration[i] = pool[i] end
    local secretRoomIndex = rng:NextInteger(3, 8)
    return {Exploration=exploration, SecretRoomIndex=secretRoomIndex, SecretTileId=nil, Seed=seed or todaySeed()}
end

local function pickRoomTemplate(state, entryDoor)
    local idx = state and state.RoomIndex or 1
    if idx == 9 then return ROOM_INDEX["room_18"] end
    if idx == 10 then return ROOM_INDEX["room_19"] end
    if idx == 11 then return ROOM_INDEX["room_20"] end
    local plan = state and state.RunPlan
    if plan and plan.Exploration and plan.Exploration[idx] then
        return ROOM_TEMPLATES[plan.Exploration[idx]] or ROOM_TEMPLATES[1]
    end
    return ROOM_TEMPLATES[math.clamp(idx,1,8)] or ROOM_TEMPLATES[1]
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
    -- v0.7.0 templates own their coordinates. Only fill missing coordinates defensively.
    local fallback = {{0,0},{1,0},{1,1},{2,0},{2,-1},{3,0},{3,1},{4,0},{4,-1}}
    for i, tile in ipairs(tiles) do
        if tile.X == nil or tile.Y == nil then
            local p = fallback[math.min(i, #fallback)]
            tile.X = p[1]
            tile.Y = p[2]
        end
    end
end

local function rebuildOrthogonalNeighbors(tiles)
    for _, tile in ipairs(tiles) do tile.Neighbors = {} end
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

local function assignTokenSlots(tile)
    if tile.Kind == "Enemy" then
        tile.TokenA = {-0.42,-0.32}; tile.TokenB = {0.42,-0.32}; tile.ObjectSlot = {0,0.42}
    elseif tile.Kind == "Treasure" or tile.Kind == "Puzzle" or tile.Kind == "Trap" then
        tile.TokenA = {-0.44,0.34}; tile.TokenB = {0.44,0.34}; tile.ObjectSlot = {0,-0.36}
    else
        tile.TokenA = {-0.32,-0.18}; tile.TokenB = {0.32,0.18}; tile.ObjectSlot = {0,0.42}
    end
end

local function makeRoomDoors(state)
    local idx = state and state.RoomIndex or 1
    if idx < 8 then
        return {{Id="steady",Label="Steady Door",Hint="Normal risk. Keep moving.",Type=Constants.DOOR_TYPES.Normal},{Id="danger",Label="Danger Door",Hint="Harder room, better item chance.",Type=Constants.DOOR_TYPES.Danger},{Id="puzzle",Label="Puzzle Door",Hint="More objects, clues, and route tricks.",Type=Constants.DOOR_TYPES.Portal}}
    elseif idx == 8 then
        return {{Id="boss",Label="Boss Door",Hint="Room 9: Doorwarden's Vault.",Type=Constants.DOOR_TYPES.Boss}}
    elseif idx == 9 then
        local doors = {{Id="finish",Label="Escape",Hint="End the run after the boss.",Type=Constants.DOOR_TYPES.Normal}}
        if state and state.Resources and state.Resources.GoldKey then table.insert(doors,{Id="gold_vault",Label="Gold Key Vault",Hint="Spend the Gold Key for a dangerous bonus room.",Type=Constants.DOOR_TYPES.Treasure}) end
        if state and state.Resources and state.Resources.SecretPath then table.insert(doors,{Id="secret_death",Label="Secret Death Room",Hint="Huge reward, real wipe risk.",Type=Constants.DOOR_TYPES.Curse}) end
        return doors
    elseif idx == 10 then
        local doors = {{Id="finish",Label="Escape",Hint="Leave with the vault reward.",Type=Constants.DOOR_TYPES.Normal}}
        if state and state.Resources and state.Resources.SecretPath then table.insert(doors,{Id="secret_death",Label="Secret Death Room",Hint="One final dangerous secret.",Type=Constants.DOOR_TYPES.Curse}) end
        return doors
    else
        return {{Id="finish",Label="Escape",Hint="End the run.",Type=Constants.DOOR_TYPES.Normal}}
    end
end

local function makeRoomState(state, roomIndex, entryDoor)
    local t = pickRoomTemplate(state, entryDoor)
    local tiles = deepCopy(t.Tiles)
    normalizeRoomGrid(tiles, t)
    rebuildOrthogonalNeighbors(tiles)
    for _, tile in ipairs(tiles) do
        tile.Revealed = tile.Id == "start"
        tile.Cleared = tile.Kind == "Start"
        if tile.Kind == "Enemy" then
            local enemy = ENEMY_TEMPLATES[tile.Enemy or ""]
            tile.HP = tile.HP or (enemy and enemy.HP) or 3
            tile.MaxHP = tile.HP
            local intents = enemy and enemy.Intents or nil
            if intents then
                local intent = intents[((roomIndex or 1) + #(tile.Id or "")) % #intents + 1]
                tile.Intent = intent.Text
                tile.IntentIcon = intent.Icon
                tile.IntentId = intent.Id
            end
        end
        assignTokenSlots(tile)
        tile.Layout = roomShapeFor(tile, t)
        tile.Layout.TokenA = tile.TokenA
        tile.Layout.TokenB = tile.TokenB
        tile.Layout.ObjectSlot = tile.ObjectSlot
        if t.Family == "Boss" or t.Theme == "Boss" then tile.Layout.W = math.max(tile.Layout.W or 2.0, 2.55); tile.Layout.D = math.max(tile.Layout.D or 1.5, 1.85) end
    end
    local board = {Id=t.Id, Name=t.Name, Family=t.Family, Theme=t.Theme, Trait=t.Trait, TraitBody=t.TraitBody, Difficulty=t.Difficulty, Atmosphere=t.Atmosphere, Props=deepCopy(t.Props or {}), Objects=deepCopy(t.Objects or {}), EntryEvent=t.EntryEvent or "The room shifts.", EntryDoor=entryDoor or "start", Tiles=tiles, Doors=makeRoomDoors(state)}
    return board
end

local function getTile(state,id) for _,tile in ipairs(state.Board.Tiles) do if tile.Id==id then return tile end end end
local function nextEventId(state) state.EventCounter=(state.EventCounter or 0)+1; return state.EventCounter end
local function setPopup(state,kind,title,sub,body) state.EventPopup={Id=nextEventId(state),Kind=kind,Title=title,Subtitle=sub or "",Body=body or ""} end
local function currentTileHasLiveMonster(state)
    local current=getTile(state,state.PlayerTile)
    return current and current.Kind=="Enemy" and not current.Cleared and (current.HP or 0)>0
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


local function createStartingBackpack()
    return {Items={{Uid="item_1",Data=ITEM_LIBRARY.RustySword,Equipped=true},{Uid="item_2",Data=ITEM_LIBRARY.Bandage,Equipped=false},{Uid="item_3",Data=ITEM_LIBRARY.Torch,Equipped=false}},Equipped={Weapon="item_1",Armor=nil,Boots=nil}}
end

local function getEquippedPower(state, slot)
    local uid=state.Backpack.Equipped[slot]
    if not uid then return 0 end
    for _,e in ipairs(state.Backpack.Items) do if e.Uid==uid then return e.Data.Power or 0 end end
    return 0
end

local function hasItem(state, itemId)
    for _,e in ipairs(state.Backpack.Items or {}) do if e.Data and e.Data.Id==itemId then return e end end
end

local function removeItem(state, itemId)
    for i,e in ipairs(state.Backpack.Items or {}) do if e.Data and e.Data.Id==itemId then table.remove(state.Backpack.Items,i); return e end end
end

local function addItem(state, itemId)
    local data=ITEM_LIBRARY[itemId]
    if not data then return nil end
    local uid="item_"..tostring((state.ItemCounter or 3)+1)
    state.ItemCounter=(state.ItemCounter or 3)+1
    local e={Uid=uid,Data=data,Equipped=false}
    table.insert(state.Backpack.Items,e)
    if data.Id=="GoldKey" then state.Resources.GoldKey=true end
    if data.DeathSave then state.Resources.DeathSaves=(state.Resources.DeathSaves or 0)+1 end
    if data.Slot and not state.Backpack.Equipped[data.Slot] then state.Backpack.Equipped[data.Slot]=uid; e.Equipped=true end
    return e
end

local function addResource(state,key,amount)
    state.Resources=state.Resources or {}
    state.Resources[key]=math.max(0,(state.Resources[key] or 0)+(amount or 1))
    return state.Resources[key]
end

local function spendResource(state,key,amount)
    amount=amount or 1
    state.Resources=state.Resources or {}
    if (state.Resources[key] or 0) < amount then return false end
    state.Resources[key]-=amount
    return true
end

local function damagePlayer(state,index,amount,reason)
    local ps=state.Players[index or 1]
    if not ps or ps.Dead then return end
    amount=math.max(0,amount or 0)
    local armor=index==1 and getEquippedPower(state,"Armor") or 0
    local guard=state.Guard or 0
    local blocked=math.min(amount, armor + guard)
    amount=math.max(0,amount-blocked)
    if guard>0 then state.Guard=math.max(0,guard-blocked) end
    if amount<=0 then state.LastEvent=(reason or "Hit").." was blocked."; return end
    if ps.HP-amount>0 then ps.HP-=amount; return end
    if (state.Resources.DeathSaves or 0)>0 then
        state.Resources.DeathSaves-=1
        ps.HP=1
        ps.Status="Death saved"
        state.Threat += 1
        state.LastEvent="A death-save relic broke instead of death."
        setPopup(state,"Death Save","Death Prevented",ps.Name or "Player","A relic shattered and kept them at 1 HP. Threat rises.")
        return
    end
    if (state.Resources.Supplies or 0)>0 then
        state.Resources.Supplies-=1
        ps.HP=1
        ps.Status="Bandaged"
        state.LastEvent="Supplies prevented a down."
        setPopup(state,"Survival","Last Bandage",ps.Name or "Player","Supplies were consumed to prevent going down.")
        return
    end
    ps.HP=0
    ps.Downed=true
    ps.Status="Downed"
    ps.DownTimer=3
    state.Phase="Downed"
    state.Threat += 2
    setPopup(state,"Downed","Player Downed",ps.Name or "Player",reason or "They are down. Shield/Help or Bandage can bring them back.")
end

local function revivePlayer(state,index)
    local ps=state.Players[index or 1]
    if not ps or not ps.Downed then return false end
    if spendResource(state,"Supplies",1) or removeItem(state,"Bandage") then
        ps.Downed=false; ps.Status="Revived"; ps.HP=2; ps.DownTimer=nil
        state.LastEvent=(ps.Name or "Player").." was revived."
        return true
    end
    return false
end

local function syncLegacyFields(state)
    state.CurrentRoom.Name=state.Board.Name
    state.CurrentRoom.Type=state.Board.Theme
    state.CurrentRoom.Clear=state.Board.Trait or "Explore"
    state.CurrentRoom.DoorText=state.Board.TraitBody or "Room strategy matters."
    state.Doors=state.Board.Doors
    state.Enemies={}
    for _,tile in ipairs(state.Board.Tiles or {}) do
        if tile.Kind=="Enemy" and not tile.Cleared and tile.Revealed then
            table.insert(state.Enemies,{Id=tile.Id,Name=tile.Enemy,Zone=tile.Label,HP=tile.HP or 1,MaxHP=tile.MaxHP or tile.HP or 1,IntentIcon=tile.IntentIcon or "!",Intent=tile.Intent or "Unknown intent",Kind=tile.Enemy})
        end
    end
    local p1=getTile(state,state.PlayerTile); local p2=getTile(state,state.PartnerTile)
    state.Players[1].Zone=p1 and p1.Label or "Unknown"
    state.Players[2].Zone=p2 and p2.Label or "Following"
    state.Pot=state.Resources and state.Resources.Relics or 0
end

local function makeDungeonState(player)
    local plan=buildRunPlan(todaySeed()+player.UserId)
    local shell={RoomIndex=1,RunPlan=plan,Resources={Threat=1}}
    local room=makeRoomState(shell,1,"start")
    local state={Phase="Your Turn",RoomIndex=1,ExplorationRooms=8,BossRoom=9,RoomsToWin=9,MaxRooms=11,Threat=2,CurrentRoom={Key="Room1",Name=room.Name,Type=room.Theme,Clear=room.Trait,DoorText=room.TraitBody},Board=room,RunPlan=plan,Resources=shell.Resources,PlayerTile="start",PartnerTile="start",CanAct=true,ActionUsed=false,MoveOptions=nil,DoorOptions=nil,DoorVotes={},RouteWheel=nil,RoomActions={SearchUsed=false,SchemeUsed=false,SearchBy=nil,SchemeBy=nil},RoomFlags={},EventCounter=0,ItemCounter=3,Backpack=createStartingBackpack(),PendingEquip=nil,AIPartner=false,PartnerAction=nil,PlayerAction=nil,Combo=nil,Guard=0,Players={{UserId=player.UserId,Name="You",Zone="Entry",Pouch=0,Bank=0,HP=6,MaxHP=6,Keys=0,Light=0,Relics={},Status="Ready"},{UserId=0,Name="Waiting Partner",Zone="Entry",Pouch=0,Bank=0,HP=6,MaxHP=6,Keys=0,Light=0,Relics={},Status="Waiting"}},Enemies={},Doors=room.Doors,ActionCards=DungeonDoorsSpec.Actions,LastEvent="Real room mode: walk the tabletop room, press E near physical objects, and let Threat tell you how hunted you are."}
    setPopup(state,"Room",room.Name,"Room 1 / 8 exploration",room.EntryEvent or "Explore carefully.")
    return state
end

local function tableList() local list={}; for _,g in ipairs(GameCatalog.GetPublicList()) do local count=0; for _,k in pairs(joinedGame) do if k==g.Key then count += 1 end end; table.insert(list,{Key=g.Key,DisplayName=g.DisplayName,Status=g.Status,Count=count,MaxPlayers=g.MaxPlayers,Tagline=g.Tagline}) end; return list end
local function sendState(player,mode) local state=playerStates[player.UserId]; if not state then return end; syncLegacyFields(state); clientEvent:FireClient(player,Constants.TOPICS.RenderGame,{GameKey=Constants.GAME_KEYS.DungeonDoors,GameInfo=GameCatalog.GetGame(Constants.GAME_KEYS.DungeonDoors),FakeState=state,Mode=mode or "Join"}) end
local function sendProfile(player) clientEvent:FireClient(player,Constants.TOPICS.Profile,getProfile(player)); clientEvent:FireClient(player,Constants.TOPICS.TableList,tableList()) end


-- v0.8.0: Real 3D Room Explorer
-- The old small-card room grid is no longer the active feel layer.
-- Dungeon Doors now creates a walkable tabletop room with physical objects, prompts, doors, chests, levers, and monsters.
local explorerConnections = {}

local LIVE_ROOMS = {
    {Name="Dusty Entry", Mood="The first room is quiet, but the table is real now.", Color=Color3.fromRGB(48,58,66), Glow=Color3.fromRGB(88,180,220), Kind="Entry", Monster=nil, Chest=true, Search="Broken crate", Puzzle="Cracked floor"},
    {Name="Collapsed Bridge", Mood="A broken crossing splits the room. Search the debris to reveal a lever.", Color=Color3.fromRGB(45,56,48), Glow=Color3.fromRGB(88,210,166), Kind="Bridge", Monster="Bone Rat", Chest=true, Search="Bridge debris", Puzzle="Repair bridge"},
    {Name="Pale Spider Court", Mood="Webs pull tight across the walls. Cocoons can hide supplies or eggs.", Color=Color3.fromRGB(44,32,58), Glow=Color3.fromRGB(170,112,255), Kind="Web", Monster="Pale Spider", Chest=false, Search="Cocoon", Puzzle="Cut silk wall"},
    {Name="Mimic Storage", Mood="A chest sits too perfectly in the center.", Color=Color3.fromRGB(58,44,34), Glow=Color3.fromRGB(232,156,72), Kind="Chest", Monster="Mimic Lurker", Chest=true, Search="Suspicious chest", Puzzle="Identify mimic"},
    {Name="Black Candle Room", Mood="A black candle turns every shadow toward you.", Color=Color3.fromRGB(34,30,44), Glow=Color3.fromRGB(160,90,240), Kind="Candle", Monster="Candle Shade", Chest=false, Search="Wax altar", Puzzle="Extinguish candle"},
    {Name="Flooded Crypt", Mood="Water covers the floor and something moves underneath.", Color=Color3.fromRGB(34,58,66), Glow=Color3.fromRGB(78,175,210), Kind="Flood", Monster="Drowned Guard", Chest=true, Search="Flooded crate", Puzzle="Drain water"},
    {Name="Chain Gallery", Mood="The gate is chained shut. The room wants to trap you.", Color=Color3.fromRGB(44,44,50), Glow=Color3.fromRGB(170,170,184), Kind="Chain", Monster="Chain Warden", Chest=false, Search="Chain lever", Puzzle="Unlock gate"},
    {Name="White Door", Mood="A silent white door waits for the team to find the right clue.", Color=Color3.fromRGB(54,58,62), Glow=Color3.fromRGB(238,230,190), Kind="Secret", Monster=nil, Chest=true, Search="Prayer stones", Puzzle="Secret path"},
    {Name="Doorwarden's Vault", Mood="Boss room. The vault watches every step.", Color=Color3.fromRGB(42,32,38), Glow=Color3.fromRGB(220,64,64), Kind="Boss", Monster="Doorwarden", Chest=true, Search="Vault pillar", Puzzle="Break lock"},
    {Name="Gold Key Vault", Mood="Optional vault. Rich, loud, and dangerous.", Color=Color3.fromRGB(62,48,32), Glow=Color3.fromRGB(245,190,72), Kind="GoldVault", Monster="Gold Maw", Chest=true, Search="Gold lock", Puzzle="Open vault shelf"},
    {Name="Gilded Death Room", Mood="Secret room. The reward is huge, but the room wants a death.", Color=Color3.fromRGB(70,38,34), Glow=Color3.fromRGB(245,150,72), Kind="Death", Monster="Gold Maw", Chest=true, Search="Cursed altar", Puzzle="Escape with treasure"},
}

local MONSTER_INTENTS = {
    ["Bone Rat"]={"Bite: +1 Threat","Gnaw bridge rope","Scurry behind cover"},
    ["Pale Spider"]={"Web Bite: +2 Threat","Cocoon: blocks the door","Egg Burst: room gets worse"},
    ["Mimic Lurker"]={"Snap: +2 Threat","Fake Shine: chest becomes risky","Devour: breaks a reward"},
    ["Candle Shade"]={"Drain flame: +1 Threat","Curse: next interact hurts","Haunt: +2 Threat"},
    ["Drowned Guard"]={"Drag Under: +2 Threat","Flood Step: door gets harder","Guard Relic: chest gets locked"},
    ["Chain Warden"]={"Heavy Slam: +2 Threat","Chain Pull: blocks escape","Lockdown: disables a prompt briefly"},
    ["Doorwarden"]={"Vault Slam: +3 Threat","Lock Door: exit closes","Red Door Opens: danger surge"},
    ["Gold Maw"]={"Gold Bite: +3 Threat","Greed Curse: chest can hurt","Devour Treasure: reward worsens"},
}

local function exPart(parent, name, size, cframe, color, material, transparency, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Transparency = transparency or 0
    if collide ~= nil then p.CanCollide = collide end
    p.Parent = parent
    return p
end

local function exBillboard(parent, text, size, y, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Label"
    gui.Size = size or UDim2.fromOffset(220, 52)
    gui.StudsOffsetWorldSpace = Vector3.new(0, y or 4, 0)
    gui.AlwaysOnTop = true
    gui.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
    label.BackgroundTransparency = 0.18
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.TextColor3 = color or Color3.fromRGB(245, 240, 225)
    label.Text = text
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label
    return gui
end

local function exPrompt(parent, name, action, object, distance, callback)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = name
    prompt.ActionText = action
    prompt.ObjectText = object
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0.25
    prompt.MaxActivationDistance = distance or 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = parent
    return prompt, prompt.Triggered:Connect(callback)
end

local function getThreatTier(threat)
    threat = threat or 0
    if threat >= 10 then return "DEATH HUNT", Color3.fromRGB(235,48,48), "Monsters hit harder. Mistakes can down you."
    elseif threat >= 7 then return "HUNTING", Color3.fromRGB(235,92,62), "Enemies take nastier actions."
    elseif threat >= 4 then return "UNEASY", Color3.fromRGB(235,170,72), "Traps and chests become riskier."
    else return "QUIET", Color3.fromRGB(90,210,150), "The dungeon is watching, not hunting." end
end

local function addExplorerThreat(state, amount, reason)
    state.Threat = math.max(0, (state.Threat or 0) + (amount or 0))
    state.Resources = {Threat = state.Threat}
    local tier = getThreatTier(state.Threat)
    state.LastEvent = (reason or "Threat changed.") .. " Threat is now " .. tostring(state.Threat) .. " — " .. tier .. "."
end

local function cleanupExplorer(player)
    local id = player.UserId
    if explorerConnections[id] then
        for _, conn in ipairs(explorerConnections[id]) do
            if conn and conn.Disconnect then pcall(function() conn:Disconnect() end) end
        end
    end
    explorerConnections[id] = {}

    local root = workspace:FindFirstChild("TableRushLiveDungeons")
    if root then
        local old = root:FindFirstChild("LiveRoom_" .. tostring(id))
        if old then old:Destroy() end
    end
end

local function makePromptPad(model, name, pos, size, color, label, promptAction, promptObject, callback)
    local p = exPart(model, name, size or Vector3.new(4, 1.2, 4), CFrame.new(pos), color, Enum.Material.SmoothPlastic, 0, true)
    exBillboard(p, label or promptObject, UDim2.fromOffset(190, 44), 3.2)
    local prompt, conn = exPrompt(p, name .. "Prompt", promptAction, promptObject, 12, function(plr)
        if plr ~= model:GetAttribute("OwnerUserId") then return end
    end)
    return p, prompt, conn
end

local function explorerAddPrompt(player, model, partObj, promptName, actionText, objectText, callback)
    local prompt, conn = exPrompt(partObj, promptName, actionText, objectText, 12, function(plr)
        if plr ~= player then return end
        callback()
    end)
    table.insert(explorerConnections[player.UserId], conn)
    return prompt
end

local function updateThreatObelisk(model, state)
    local old = model:FindFirstChild("ThreatObelisk")
    if old then old:Destroy() end
    local tier, color, body = getThreatTier(state.Threat or 0)
    local base = model:GetAttribute("Center")
    local center = base and Vector3.new(base.X, base.Y, base.Z) or Vector3.new(0,0,0)
    local h = math.clamp(3 + ((state.Threat or 0) * 0.45), 3, 9)
    local ob = exPart(model, "ThreatObelisk", Vector3.new(2.2, h, 2.2), CFrame.new(center + Vector3.new(48, 4 + h/2, -28)), color, Enum.Material.Neon, 0.08, false)
    exBillboard(ob, "THREAT " .. tostring(state.Threat or 0) .. "\n" .. tier .. "\n" .. body, UDim2.fromOffset(250, 88), h/2 + 2.5, Color3.fromRGB(255,245,230))
end

local function createRewardSpin(model, pos, finalText, options)
    local wheel = Instance.new("Model")
    wheel.Name = "RewardSpin"
    wheel.Parent = model

    local orb = exPart(wheel, "RewardOrb", Vector3.new(3,3,3), CFrame.new(pos), Color3.fromRGB(245,190,72), Enum.Material.Neon, 0.12, false)
    orb.Shape = Enum.PartType.Ball
    exBillboard(orb, "ROLLING...", UDim2.fromOffset(220, 52), 3.1, Color3.fromRGB(255,245,210))

    task.spawn(function()
        local labels = options or {"Relic","Gold Key","Trap","Charm","Nothing"}
        local gui = orb:FindFirstChild("Label")
        local textLabel = gui and gui:FindFirstChildOfClass("TextLabel")
        for i = 1, 18 do
            if textLabel then textLabel.Text = labels[((i - 1) % #labels) + 1] end
            orb.CFrame = orb.CFrame * CFrame.Angles(0, math.rad(28), 0)
            task.wait(0.055 + (i * 0.006))
        end
        if textLabel then textLabel.Text = "REWARD:\n" .. finalText end
        orb.Color = Color3.fromRGB(110, 235, 165)
        task.wait(2.2)
        if wheel.Parent then wheel:Destroy() end
    end)
end

local function makeMonster(model, room, pos)
    if not room.Monster then return nil end
    local color = Color3.fromRGB(210,70,75)
    if room.Monster == "Pale Spider" then color = Color3.fromRGB(160,90,230)
    elseif room.Monster == "Candle Shade" then color = Color3.fromRGB(120,80,210)
    elseif room.Monster == "Drowned Guard" then color = Color3.fromRGB(72,150,180)
    elseif room.Monster == "Gold Maw" then color = Color3.fromRGB(230,165,60)
    end
    local body = exPart(model, "Monster_" .. room.Monster, Vector3.new(4, 4, 4), CFrame.new(pos + Vector3.new(0, 2.2, 0)), color, Enum.Material.Neon, 0.08, true)
    body.Shape = Enum.PartType.Ball
    local intents = MONSTER_INTENTS[room.Monster] or {"Attack"}
    exBillboard(body, room.Monster .. "\nNext: " .. intents[1], UDim2.fromOffset(250, 70), 4.3, Color3.fromRGB(255,230,230))
    return body
end

local function addRoomWalls(model, center, room)
    local floorColor = room.Color
    local glow = room.Glow
    local y = center.Y

    exPart(model, "TabletopBase", Vector3.new(126, 2, 82), CFrame.new(center + Vector3.new(0, -1.2, 0)), Color3.fromRGB(18,22,26), Enum.Material.Wood, 0, true)
    exPart(model, "RoomFloor", Vector3.new(112, 0.5, 68), CFrame.new(center + Vector3.new(0, 0, 0)), floorColor, Enum.Material.SmoothPlastic, 0, true)
    exPart(model, "RoomInset", Vector3.new(98, 0.28, 56), CFrame.new(center + Vector3.new(0, 0.31, 0)), floorColor:Lerp(Color3.fromRGB(0,0,0), 0.18), Enum.Material.SmoothPlastic, 0.02, true)

    local wallColor = floorColor:Lerp(Color3.fromRGB(0,0,0), 0.35)
    exPart(model, "Wall_N", Vector3.new(116, 8, 2), CFrame.new(center + Vector3.new(0, 4, -35)), wallColor, Enum.Material.Slate, 0, true)
    exPart(model, "Wall_S", Vector3.new(116, 8, 2), CFrame.new(center + Vector3.new(0, 4, 35)), wallColor, Enum.Material.Slate, 0, true)
    exPart(model, "Wall_W", Vector3.new(2, 8, 70), CFrame.new(center + Vector3.new(-57, 4, 0)), wallColor, Enum.Material.Slate, 0, true)
    exPart(model, "Wall_E_Upper", Vector3.new(2, 8, 24), CFrame.new(center + Vector3.new(57, 4, -23)), wallColor, Enum.Material.Slate, 0, true)
    exPart(model, "Wall_E_Lower", Vector3.new(2, 8, 24), CFrame.new(center + Vector3.new(57, 4, 23)), wallColor, Enum.Material.Slate, 0, true)

    local doorGlow = exPart(model, "ExitDoorGlow", Vector3.new(1, 6, 16), CFrame.new(center + Vector3.new(57.6, 3.2, 0)), glow, Enum.Material.Neon, 0.35, false)
    exBillboard(doorGlow, "EXIT DOOR", UDim2.fromOffset(180, 42), 5.1)

    -- Interior room-building chunks; simple model pieces, no weird tiny tile UI.
    exPart(model, "LowWall_A", Vector3.new(34, 3.2, 2), CFrame.new(center + Vector3.new(-19, 1.8, -13)), wallColor:Lerp(glow,0.12), Enum.Material.Slate, 0, true)
    exPart(model, "LowWall_B", Vector3.new(28, 3.2, 2), CFrame.new(center + Vector3.new(16, 1.8, 13)), wallColor:Lerp(glow,0.12), Enum.Material.Slate, 0, true)
    exPart(model, "Pillar_A", Vector3.new(3.2, 5, 3.2), CFrame.new(center + Vector3.new(-38, 2.8, 21)), wallColor:Lerp(glow,0.25), Enum.Material.Slate, 0, true)
    exPart(model, "Pillar_B", Vector3.new(3.2, 5, 3.2), CFrame.new(center + Vector3.new(28, 2.8, -22)), wallColor:Lerp(glow,0.25), Enum.Material.Slate, 0, true)
end

local function setupPlayerForExplorer(player, center)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp then hrp.CFrame = CFrame.new(center + Vector3.new(-43, 5.5, 0)) end
    if hum then
        hum.WalkSpeed = 26
        hum.JumpPower = 0
        hum.JumpHeight = 0
        hum.AutoRotate = true
    end
end

local function configureExplorerState(state, room)
    state.ExplorerMode = true
    state.Phase = "Explore Physical Room"
    state.ActionCards = {}
    state.MoveOptions = nil
    state.DoorOptions = nil
    state.PendingEquip = nil
    state.Resources = {Threat = state.Threat or 1}
    state.CurrentRoom = {Name=room.Name, Type=room.Kind, Clear="Physical room", DoorText=room.Mood}
    state.ExplorerRoomName = room.Name
    state.ExplorerMood = room.Mood
    state.LastEvent = room.Name .. ": " .. room.Mood
end

local function buildPhysicalExplorerRoom(player, state)
    cleanupExplorer(player)
    local root = workspace:FindFirstChild("TableRushLiveDungeons")
    if not root then
        root = Instance.new("Folder")
        root.Name = "TableRushLiveDungeons"
        root.Parent = workspace
    end

    local roomNumber = state.LiveRoomIndex or 1
    local room = LIVE_ROOMS[math.clamp(roomNumber, 1, #LIVE_ROOMS)]
    configureExplorerState(state, room)

    local model = Instance.new("Model")
    model.Name = "LiveRoom_" .. tostring(player.UserId)
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("Center", Vector3.new(0, 7, -8))
    model.Parent = root

    local center = Vector3.new(0, 7, -8)
    addRoomWalls(model, center, room)
    updateThreatObelisk(model, state)

    exBillboard(exPart(model, "RoomTitleAnchor", Vector3.new(1,1,1), CFrame.new(center + Vector3.new(0, 9, -30)), room.Glow, Enum.Material.Neon, 1, false), room.Name .. "\n" .. room.Mood, UDim2.fromOffset(520, 86), 0, Color3.fromRGB(255,245,225))

    -- Bridge puzzle is physical. No tile-clicking, no fake connected-room bug.
    local bridgeBlock = nil
    if room.Kind == "Bridge" then
        exPart(model, "Ravine", Vector3.new(18, 0.25, 32), CFrame.new(center + Vector3.new(4, 0.45, 0)), Color3.fromRGB(8,12,16), Enum.Material.Neon, 0.12, false)
        bridgeBlock = exPart(model, "CollapsedBridgeBlocker", Vector3.new(5, 6, 28), CFrame.new(center + Vector3.new(4, 3.1, 0)), Color3.fromRGB(12,18,20), Enum.Material.ForceField, 0.45, true)
        exBillboard(bridgeBlock, "BRIDGE COLLAPSED\nSearch debris for a way across", UDim2.fromOffset(270, 70), 4.4)
    end

    -- Physical Search object. Search is once per object/tile, not once per room.
    local searchKey = "room" .. tostring(roomNumber) .. "_main_search"
    local searchObj = exPart(model, "SearchObject", Vector3.new(6, 2.5, 4), CFrame.new(center + Vector3.new(-24, 1.7, -16)), room.Color:Lerp(room.Glow, 0.34), Enum.Material.SmoothPlastic, 0, true)
    exBillboard(searchObj, "SEARCHABLE\n" .. (room.Search or "Clue"), UDim2.fromOffset(210, 56), 3.5)
    explorerAddPrompt(player, model, searchObj, "SearchPrompt", "Search", room.Search or "Room Clue", function()
        state.SearchedObjects = state.SearchedObjects or {}
        if state.SearchedObjects[searchKey] then
            state.LastEvent = "Already searched: " .. (room.Search or "this object") .. ". Teammate cannot search the same object either."
            sendState(player, "Join")
            return
        end
        state.SearchedObjects[searchKey] = true
        addExplorerThreat(state, room.Kind == "Candle" and 1 or 0, "You searched " .. (room.Search or "the object") .. ".")

        if room.Kind == "Bridge" then
            local lever = exPart(model, "BridgeLever", Vector3.new(2.4, 4.4, 2.4), CFrame.new(center + Vector3.new(-8, 2.5, 18)), Color3.fromRGB(80,210,150), Enum.Material.Neon, 0.05, true)
            exBillboard(lever, "LEVER REVEALED\nInteract to drop bridge planks", UDim2.fromOffset(250, 64), 4.2, Color3.fromRGB(230,255,235))
            explorerAddPrompt(player, model, lever, "BridgeLeverPrompt", "Interact", "Repair Bridge", function()
                if state.RoomFlags and state.RoomFlags.BridgeFixed then
                    state.LastEvent = "Bridge is already repaired."
                    sendState(player, "Join")
                    return
                end
                state.RoomFlags = state.RoomFlags or {}
                state.RoomFlags.BridgeFixed = true
                if bridgeBlock and bridgeBlock.Parent then bridgeBlock:Destroy() end
                exPart(model, "BridgePlanks", Vector3.new(18, 0.7, 12), CFrame.new(center + Vector3.new(4, 0.95, 0)), Color3.fromRGB(94,62,38), Enum.Material.WoodPlanks, 0, true)
                state.LastEvent = "You pulled the lever. The bridge physically drops into place. Now cross it with your avatar."
                sendState(player, "Join")
            end)
            state.LastEvent = "Search found a hidden lever path. Walk to the green lever and press E."
        elseif room.Kind == "Secret" then
            state.SecretPath = true
            state.LastEvent = "Search revealed a secret path mark. This can unlock the hidden treasure/death room later."
        elseif room.Kind == "Chest" then
            state.LastEvent = "Search revealed scratch marks. The chest may be a mimic. Interact carefully."
        else
            state.LastEvent = "Search found a real clue/object. If a useful interact exists, it appears physically in the room."
        end
        sendState(player, "Join")
    end)

    -- Physical chest with reward-cycle animation.
    if room.Chest then
        local chest = exPart(model, "PhysicalChest", Vector3.new(6, 3, 4.2), CFrame.new(center + Vector3.new(6, 1.9, -20)), Color3.fromRGB(94,54,30), Enum.Material.Wood, 0, true)
        exPart(model, "ChestBand", Vector3.new(6.4, 0.5, 4.6), CFrame.new(center + Vector3.new(6, 3.55, -20)), room.Glow, Enum.Material.Metal, 0.08, true)
        exBillboard(chest, "CHEST\nInteract for animated reward/risk", UDim2.fromOffset(260, 64), 4.1)
        explorerAddPrompt(player, model, chest, "ChestPrompt", "Interact", "Open Chest", function()
            state.OpenedChests = state.OpenedChests or {}
            local key = "room" .. tostring(roomNumber) .. "_chest"
            if state.OpenedChests[key] then
                state.LastEvent = "This chest is already open."
                sendState(player, "Join")
                return
            end
            state.OpenedChests[key] = true
            local options = {"Gold Key","Death Charm","Relic","Trap","Threat"}
            local roll = ((state.Threat or 0) + roomNumber + #room.Name) % #options + 1
            local result = options[roll]
            if result == "Trap" or result == "Threat" then
                addExplorerThreat(state, 2, "The chest snapped open badly.")
            elseif result == "Gold Key" then
                state.HasGoldKey = true
                state.LastEvent = "Chest reward landed on GOLD KEY. The optional vault can open after the boss."
            elseif result == "Death Charm" then
                state.DeathCharm = true
                state.LastEvent = "Chest reward landed on DEATH CHARM. It can break in place of death later."
            else
                state.LastEvent = "Chest reward landed on RELIC. This is a real run reward placeholder."
            end
            createRewardSpin(model, center + Vector3.new(6, 8, -20), result, options)
            updateThreatObelisk(model, state)
            sendState(player, "Join")
        end)
    end

    -- Physical monster prompt. Monster actions are shown as intent, not silent math.
    local monster = makeMonster(model, room, center + Vector3.new(12, 0, 12))
    if monster then
        explorerAddPrompt(player, model, monster, "FightPrompt", "Fight", room.Monster, function()
            state.MonsterHP = state.MonsterHP or 3
            state.MonsterHP -= 1
            local intents = MONSTER_INTENTS[room.Monster] or {"Attack"}
            local intent = intents[((state.Threat or 0) + math.max(0,state.MonsterHP)) % #intents + 1]
            if state.MonsterHP <= 0 then
                monster:Destroy()
                state.LastEvent = room.Monster .. " defeated. The room gets safer and the exit feels earned."
                addExplorerThreat(state, -1, "Monster defeated.")
            else
                addExplorerThreat(state, room.Kind == "Boss" and 3 or 1, room.Monster .. " acts: " .. intent)
            end
            updateThreatObelisk(model, state)
            sendState(player, "Join")
        end)
    end

    -- Exit door: physical room transition, not tile-grid exit.
    local exit = exPart(model, "ExitDoorPromptPart", Vector3.new(4, 6, 12), CFrame.new(center + Vector3.new(52, 3, 0)), room.Glow, Enum.Material.Neon, 0.28, false)
    explorerAddPrompt(player, model, exit, "ExitPrompt", "Enter", "Next Room", function()
        if room.Kind == "Bridge" and not (state.RoomFlags and state.RoomFlags.BridgeFixed) then
            addExplorerThreat(state, 1, "The collapsed bridge blocks the exit route. Search and repair it first.")
            updateThreatObelisk(model, state)
            sendState(player, "Join")
            return
        end
        state.LiveRoomIndex = (state.LiveRoomIndex or 1) + 1
        if state.LiveRoomIndex == 10 and not state.HasGoldKey then
            state.LiveRoomIndex = 11
        end
        if state.LiveRoomIndex > #LIVE_ROOMS then
            state.LiveRoomIndex = 1
            state.LastEvent = "Prototype loop complete. Restarting physical room set."
        end
        buildPhysicalExplorerRoom(player, state)
        sendState(player, "Join")
    end)

    setupPlayerForExplorer(player, center)
end

local function enableExplorerMode(player, state)
    state.LiveRoomIndex = state.LiveRoomIndex or 1
    state.Threat = state.Threat or 1
    state.Resources = {Threat = state.Threat}
    state.ActionCards = {}
    state.SearchedObjects = {}
    state.OpenedChests = {}
    state.RoomFlags = {}
    state.ExplorerMode = true
    state.LastEvent = "Real room mode. Walk your avatar around the tabletop room. Press E near physical objects."
    buildPhysicalExplorerRoom(player, state)
end


local function getCurrentEnemyTile(state)
    local tile=getTile(state,state.PlayerTile)
    if tile and tile.Kind=="Enemy" and not tile.Cleared and (tile.HP or 0)>0 then return tile end
end

local function updateEnemyIntent(tile,state)
    if not tile or not tile.Enemy then return end
    local enemy=ENEMY_TEMPLATES[tile.Enemy]
    if not enemy or not enemy.Intents then return end
    local seed=(state.RoomIndex*31)+(state.Threat*7)+(state.EventCounter or 0)+#(tile.Id or "")
    local intent=enemy.Intents[(seed % #enemy.Intents)+1]
    tile.Intent=intent.Text; tile.IntentIcon=intent.Icon; tile.IntentId=intent.Id
end

local function applyEnemyReward(state,tile)
    local enemy=ENEMY_TEMPLATES[tile.Enemy or ""]
    local reward=enemy and enemy.Reward or "Supply"
    if reward=="Key" then addResource(state,"Keys",1)
    elseif reward=="Light" then addResource(state,"Light",1)
    elseif reward=="Armor" then addItem(state,"ChainVest")
    elseif reward=="Tool" then addItem(state,"Rope")
    elseif reward=="Relic" then addResource(state,"Relics",1); addItem(state,"DeathCandle")
    elseif reward=="Victory" then state.Resources.BossCleared=true
    else addResource(state,"Supplies",1) end
end

local function applyEnemyIntent(player,state,tile)
    if not tile or tile.Cleared or (tile.HP or 0)<=0 then return false end
    local enemy=ENEMY_TEMPLATES[tile.Enemy or ""]
    if not enemy then return false end
    local intent=nil
    for _,it in ipairs(enemy.Intents or {}) do if it.Id==tile.IntentId then intent=it end end
    intent=intent or enemy.Intents[1]
    state.Phase="Enemy Turn"
    state.CanAct=false; state.ActionUsed=true; state.MoveOptions=nil
    local text=(tile.Enemy or "Enemy").." uses "..(intent.Text or "an attack").."."
    if intent.Damage then damagePlayer(state,1,intent.Damage+(state.Threat>=8 and 1 or 0),intent.Text) end
    if intent.Threat then state.Threat += intent.Threat end
    if intent.DrainLight then spendResource(state,"Light",intent.DrainLight) end
    if intent.Steal=="Key" then spendResource(state,"Keys",1) elseif intent.Steal=="Supply" then spendResource(state,"Supplies",1) end
    if intent.Status then state.Players[1].Status=intent.Status end
    if intent.BlockRun then state.RoomFlags.RunBlocked=true end
    if intent.BlockExit then state.RoomFlags.ExitBlocked=true end
    if intent.DisableActions then state.RoomFlags.Lockdown=true end
    if intent.Guard then tile.Guard=(tile.Guard or 0)+intent.Guard end
    if intent.BreakItem then if #state.Backpack.Items>1 then table.remove(state.Backpack.Items,#state.Backpack.Items); text ..=" It breaks your last item." else state.Threat += 1 end end
    if intent.BindPartner then state.Players[2].Status="Bound" end
    if intent.Hide then tile.Intent="Hidden"; tile.IntentIcon="?" end
    updateEnemyIntent(tile,state)
    state.LastEvent=text
    setPopup(state,"Enemy Turn",tile.IntentIcon or "!",tile.Enemy or "Enemy",text)
    return true
end

local function comboName(a,b)
    if not b then return nil end
    if (a==Constants.ACTIONS.Search and b==Constants.ACTIONS.Shield) or (a==Constants.ACTIONS.Shield and b==Constants.ACTIONS.Search) then return "Covered Search" end
    if (a==Constants.ACTIONS.Scheme and b==Constants.ACTIONS.Shield) or (a==Constants.ACTIONS.Shield and b==Constants.ACTIONS.Scheme) then return "Protected Scheme" end
    if (a==Constants.ACTIONS.Strike and b==Constants.ACTIONS.Search) or (a==Constants.ACTIONS.Search and b==Constants.ACTIONS.Strike) then return "Expose and Strike" end
    if (a==Constants.ACTIONS.Strike and b==Constants.ACTIONS.Shield) or (a==Constants.ACTIONS.Shield and b==Constants.ACTIONS.Strike) then return "Covered Attack" end
    if a==Constants.ACTIONS.Strike and b==Constants.ACTIONS.Strike then return "Duo Strike" end
    if a==Constants.ACTIONS.Search and b==Constants.ACTIONS.Scheme or a==Constants.ACTIONS.Scheme and b==Constants.ACTIONS.Search then return "Read the Room" end
    if a==Constants.ACTIONS.Step and b==Constants.ACTIONS.Shield or a==Constants.ACTIONS.Shield and b==Constants.ACTIONS.Step then return "Covered Retreat" end
    return "Duo Action"
end

local function choosePartnerAction(state, playerAction)
    local enemy=getCurrentEnemyTile(state)
    if state.Players[1].Downed then return Constants.ACTIONS.Shield end
    if enemy and (enemy.HP or 0)<=2 then return Constants.ACTIONS.Strike end
    if enemy and (state.Players[1].HP<=2 or state.Threat>=7) then return Constants.ACTIONS.Shield end
    if enemy then return Constants.ACTIONS.Strike end
    local tile=getTile(state,state.PlayerTile)
    if state.RoomActions and not state.RoomActions.SearchUsed and tile and (tile.Object or tile.Kind=="Treasure" or tile.SecretHook) then return Constants.ACTIONS.Search end
    if state.RoomActions and not state.RoomActions.SchemeUsed and tile and (tile.Puzzle or state.Board.Trait or tile.Kind=="Puzzle") then return Constants.ACTIONS.Scheme end
    if state.Threat>=7 then return Constants.ACTIONS.Shield end
    return Constants.ACTIONS.Search
end

local function resolvePartnerAction(player,state,playerAction)
    if not state.AIPartner then
        state.PartnerAction={Key="Waiting",Title="Waiting",Body="No teammate yet."}
        return nil
    end
    local action=choosePartnerAction(state,playerAction)
    state.PartnerAction={Key=action,Title=action,Body="Candle Scout chose "..action.."."}
    local enemy=getCurrentEnemyTile(state)
    if action==Constants.ACTIONS.Strike and enemy then
        local dmg=1
        enemy.HP=math.max(0,(enemy.HP or 1)-dmg)
        if enemy.HP<=0 then enemy.Cleared=true; applyEnemyReward(state,enemy); state.LastEvent="Candle Scout finished "..(enemy.Enemy or "the enemy").."." end
    elseif action==Constants.ACTIONS.Shield then
        state.Guard=(state.Guard or 0)+2
        state.Players[2].Status="Covering"
    elseif action==Constants.ACTIONS.Search and state.RoomActions and not state.RoomActions.SearchUsed then
        addResource(state,"Supplies",1)
        state.RoomActions.SearchUsed=true
        state.LastEvent="Candle Scout searched and found Supplies."
    elseif action==Constants.ACTIONS.Scheme and state.RoomActions and not state.RoomActions.SchemeUsed then
        state.Threat=math.max(0,state.Threat-1)
        state.RoomActions.SchemeUsed=true
        state.LastEvent="Candle Scout schemed the room pressure down."
    end
    state.Combo={Name=comboName(playerAction,action),Player=playerAction,Partner=action}
    return action
end

local function beginNextTurn(player,state,delaySeconds)
    delaySeconds=delaySeconds or 1.2
    state.CanAct=false; state.ActionUsed=true; state.MoveOptions=nil
    if state.DoorOptions or state.PendingEquip then return end
    local partner=resolvePartnerAction(player,state,state.PlayerAction)
    if partner then
        state.Phase="Duo Resolve"
        state.LastEvent="Candle Scout chose "..partner..". Combo: "..(state.Combo and state.Combo.Name or "Duo Action").."."
        sendState(player,"Join")
    end
    task.delay(0.85,function()
        if not player.Parent then return end
        local live=playerStates[player.UserId]
        if live~=state or live.DoorOptions or live.PendingEquip then return end
        local enemy=getCurrentEnemyTile(live)
        if enemy then
            updateEnemyIntent(enemy,live)
            applyEnemyIntent(player,live,enemy)
            sendState(player,"Join")
        end
        task.delay(delaySeconds,function()
            if not player.Parent then return end
            local again=playerStates[player.UserId]
            if again~=state or again.DoorOptions or again.PendingEquip then return end
            if again.Players[1].Downed then
                again.CanAct=true; again.ActionUsed=false; again.Phase="Downed - Need Help"; again.LastEvent="You are downed. Shield/Help uses Supplies or Bandage to revive."
            elseif again.Resources and again.Resources.RunLost then
                again.CanAct=false; again.Phase="Run Lost"; again.LastEvent="The dungeon claimed the run."
            else
                again.CanAct=true; again.ActionUsed=false; again.Phase="Your Turn"; again.LastEvent="Your turn. Read the room, enemy intent, and partner action."
            end
            sendState(player,"Join")
        end)
    end)
end

local function resolveSearch(player,state,tile)
    state.RoomActions.SearchUsed=true; state.RoomActions.SearchBy=player.UserId
    local profile=getProfile(player)
    progressTask(profile,"SearchSafely")
    local text="You search the room."
    if tile and tile.SecretHook then
        state.Resources.SecretPath=true
        text="Secret path discovered. Room 11 can appear after the boss."
        setPopup(state,"Secret","Secret Path",tile.Label,text)
    elseif tile and tile.Blocked then
        tile.Blocked=false; tile.Cleared=true
        addResource(state,"Supplies",1)
        text="You found a safe way through "..tile.Label..". Supplies +1."
    elseif tile and tile.Puzzle then
        if tile.Puzzle=="RepairBridge" then tile.Blocked=false; state.RoomFlags.BridgeFixed=true; addResource(state,"Supplies",1); text="You found rope and repaired the crossing." 
        elseif tile.Puzzle=="Extinguish" then spendResource(state,"Light",1); state.Threat=math.max(0,state.Threat-2); tile.Cleared=true; text="You read the candle marks and weaken the curse."
        elseif tile.Puzzle=="UnlockGate" or tile.Puzzle=="OpenGate" or tile.Puzzle=="PickLock" then addResource(state,"Keys",1); tile.Locked=false; text="You find the lock pattern. Key +1."
        elseif tile.Puzzle=="AlignStars" then state.Resources.RouteClue=true; state.Resources.SecretPath=true; text="The star dial reveals a route clue and a secret path mark."
        else addResource(state,"Supplies",1); text="You understand the puzzle object. Supplies +1." end
    elseif tile and tile.Kind=="Treasure" then
        local itemId=LOOT_TABLE[((state.EventCounter+#state.Backpack.Items+state.RoomIndex)%#LOOT_TABLE)+1]
        if state.Board.Theme=="Greed" and (state.EventCounter+state.RoomIndex)%4==0 then itemId="GoldKey" end
        local item=addItem(state,itemId)
        addResource(state,"Relics", item and item.Data.Type=="Relic" and 1 or 0)
        text="Search finds "..(item and item.Data.Name or "useful gear").."."
    elseif tile and tile.Kind=="Trap" then
        tile.Cleared=true; addResource(state,"Supplies",1); text="Search disarms the trap and salvages Supplies."
    elseif tile and tile.Kind=="Enemy" then
        tile.Exposed=true; tile.Guard=0; text="Search exposes "..(tile.Enemy or "the enemy")..". Next Strike hits harder."
    else
        local r=(state.EventCounter+state.RoomIndex+state.Threat)%4
        if r==0 then addResource(state,"Light",1); text="You find a usable candle. Light +1."
        elseif r==1 then addResource(state,"Supplies",1); text="You find Supplies hidden in the room object."
        elseif r==2 then state.Threat += 1; text="Search makes noise. Threat +1, but you learn the room."
        else addResource(state,"Keys",1); text="You find a small key mark. Keys +1." end
    end
    state.LastEvent=text
    setPopup(state,"Search","Search Result",state.Board.Name,text)
end

local function resolveScheme(player,state,tile)
    state.RoomActions.SchemeUsed=true; state.RoomActions.SchemeBy=player.UserId
    progressTask(getProfile(player),"SchemeOnce")
    local enemy=getCurrentEnemyTile(state)
    local text="You manipulate the room."
    local risky=(state.Board.Theme=="Curse" or state.Board.Theme=="Greed" or state.Threat>=7)
    if enemy then
        enemy.Exposed=true
        enemy.Intent="Stunned"; enemy.IntentIcon="◎"; enemy.IntentId="stunned"
        state.Threat=math.max(0,state.Threat-1)
        text="Scheme tricks "..(enemy.Enemy or "the enemy")..". It is exposed and loses momentum."
    elseif tile and tile.Puzzle then
        tile.Cleared=true; tile.Blocked=false; tile.Locked=false
        state.RoomFlags.ExitBlocked=false; state.RoomFlags.RunBlocked=false; state.Threat=math.max(0,state.Threat-1)
        text="Scheme turns the puzzle object in your favor: "..(tile.Object or tile.Label).." opens."
        if tile.SecretHook then state.Resources.SecretPath=true; text ..=" A secret path mark appears." end
    elseif tile and tile.SecretHook then
        state.Resources.SecretPath=true
        text="Scheme reads the hidden geometry. Secret Room 11 is unlocked after the boss."
    elseif state.Board.Theme=="Greed" then
        local item=addItem(state,"GoldKey")
        state.Threat += 2
        text="Greedy Scheme forces out a Gold Key, but Threat rises."
    else
        state.Threat=math.max(0,state.Threat-2)
        text="Scheme lowers room pressure and improves the route. Threat -2."
    end
    if risky and ((state.EventCounter+state.RoomIndex+state.Threat)%5==0) then
        damagePlayer(state,1,1,"Scheme backfire")
        state.Threat += 1
        text ..=" Backfire: damage and Threat."
    end
    state.LastEvent=text
    setPopup(state,"Scheme","Scheme Result",state.Board.Name,text)
end

local function revealTileEvent(player,state,tile)
    local profile=getProfile(player)
    tile.Revealed=true; state.MoveOptions=nil
    state.Phase="Room Reaction"
    if tile.Blocked then
        state.LastEvent=tile.Label.." blocks the path. Search or Scheme gives a reason to solve it."
        setPopup(state,"Puzzle","Blocked Path",tile.Label,state.LastEvent)
        return
    end
    if tile.SecretHook and state.RoomIndex==(state.RunPlan.SecretRoomIndex or -1) then
        state.LastEvent="This tile hums like a hidden door. Search or Scheme can reveal it."
    end
    if tile.Kind=="Enemy" then
        state.Threat += 1+math.floor((state.Board.Difficulty or 1)/2)
        updateEnemyIntent(tile,state)
        state.Phase="Enemy Revealed"
        state.LastEvent=(tile.Enemy or "Enemy").." appears. Intent: "..(tile.Intent or "Unknown").."."
        setPopup(state,"Enemy",tile.Enemy or "Enemy",tile.Label,"Intent: "..(tile.Intent or "Unknown")..". Choose a card and coordinate with Candle Scout.")
    elseif tile.Kind=="Trap" then
        local dmg=math.max(1,math.floor((state.Board.Difficulty or 1)/2))-getEquippedPower(state,"Boots")
        damagePlayer(state,1,dmg,tile.Object or "Trap")
        state.Threat += 1; tile.Cleared=true; progressTask(profile,"TrapEvent")
        state.Phase="Trap Triggered"; state.LastEvent=(tile.Object or "Trap").." triggers. Search could have disarmed it."
        setPopup(state,"Trap","Trap Triggered",tile.Label,state.LastEvent)
    elseif tile.Kind=="Treasure" then
        state.Phase="Treasure Found"; state.LastEvent="Treasure is visible: "..(tile.Object or tile.Label)..". Search opens it safely; Scheme can force it."
        setPopup(state,"Treasure","Visible Treasure",tile.Label,state.LastEvent)
    elseif tile.Kind=="Discovery" or tile.Kind=="Puzzle" then
        state.Phase="Room Object"; state.LastEvent=(tile.Object or tile.Label).." is present. Search studies it; Scheme manipulates it."
        setPopup(state,"Discovery",tile.Object or tile.Label,state.Board.Trait or "Room object",state.LastEvent)
    elseif tile.Kind=="Exit" then
        tile.Cleared=true; state.CanAct=false; state.ActionUsed=true; state.DoorOptions=state.Board.Doors; state.DoorVotes={}; state.Phase="Choose Door"
        if state.RoomFlags.ExitBlocked then
            state.DoorOptions=nil; state.CanAct=true; state.ActionUsed=false; state.LastEvent="Exit is blocked by room danger. Search/Scheme or defeat the monster."
            setPopup(state,"Puzzle","Exit Blocked",tile.Label,state.LastEvent)
        else
            state.LastEvent="Exit reached. Choose the next route."
            setPopup(state,"Door","Route Choice",tile.Label,"Choose the next route. Optional rooms only appear if unlocked.")
            progressTask(profile,"UnlockExit")
        end
    else
        tile.Cleared=true; state.LastEvent="Revealed "..tile.Label.."."
    end
end

local function moveToTile(player,state,tileId)
    local valid=false
    for _,o in ipairs(state.MoveOptions or {}) do if o.Id==tileId then valid=true end end
    if not valid then state.LastEvent=currentTileHasLiveMonster(state) and "You can only run to revealed tiles while a monster is here." or "Use Step, then click a glowing connected room."; return false end
    local tile=getTile(state,tileId); if not tile then return false end
    if tile.Blocked or tile.Locked then state.LastEvent=(tile.Label or "Path").." needs Search or Scheme first."; setPopup(state,"Puzzle","Path Blocked",tile.Label,state.LastEvent); return false end
    state.PlayerTile=tileId; state.PartnerTile=tileId
    progressTask(getProfile(player),"StepAround")
    revealTileEvent(player,state,tile)
    return true
end

local function availableMoves(state)
    local current=getTile(state,state.PlayerTile)
    local moves={}
    if not current then return moves end
    local fleeing=currentTileHasLiveMonster(state)
    for _,id in ipairs(current.Neighbors or {}) do
        local tile=getTile(state,id)
        if tile and not tile.Blocked and not tile.Locked then
            if not fleeing or tile.Revealed then table.insert(moves,{Id=tile.Id,Label=tile.Label,Kind=tile.Kind,Flee=fleeing}) end
        end
    end
    return moves
end

local function loadNextRoomAfterDoor(player,state,chosen)
    if not chosen then return end
    if chosen.Id=="finish" then state.Phase="Run Complete"; state.CanAct=false; state.LastEvent="Run complete. Rewards/scoring can be added after this core loop."; setPopup(state,"Victory","Run Complete","Escaped the dungeon",state.LastEvent); sendState(player,"Join"); return end
    if chosen.Id=="gold_vault" then state.RoomIndex=10 elseif chosen.Id=="secret_death" then state.RoomIndex=11 else state.RoomIndex += 1 end
    if state.RoomIndex==10 and not (state.Resources and state.Resources.GoldKey) then state.RoomIndex=9; state.LastEvent="Gold Key required."; sendState(player,"Join"); return end
    if state.RoomIndex==11 and not (state.Resources and state.Resources.SecretPath) then state.RoomIndex=9; state.LastEvent="Secret path not discovered."; sendState(player,"Join"); return end
    state.Board=makeRoomState(state,state.RoomIndex,chosen.Id)
    state.PlayerTile="start"; state.PartnerTile="start"; state.MoveOptions=nil; state.DoorOptions=nil; state.DoorVotes={}; state.RouteWheel=nil; state.PendingRouteChoice=nil; state.PendingEquip=nil
    state.RoomActions={SearchUsed=false,SchemeUsed=false,SearchBy=nil,SchemeBy=nil}; state.RoomFlags={}; state.Guard=0
    state.CanAct=true; state.ActionUsed=false; state.Phase="Your Turn"
    state.CurrentRoom={Key="Room"..tostring(state.RoomIndex),Name=state.Board.Name,Type=state.Board.Theme,Clear=state.Board.Trait,DoorText=state.Board.TraitBody}
    state.LastEvent="Entered "..state.Board.Name..". "..(state.Board.EntryEvent or "")
    setPopup(state,"Room",state.Board.Name,"Room "..tostring(state.RoomIndex), (state.Board.EntryEvent or "").." Trait: "..(state.Board.Trait or "None"))
    sendState(player,"Join")
end

local function chooseDoor(player,state,doorId)
    if not state.DoorOptions then return end
    local chosen=nil
    for _,d in ipairs(state.DoorOptions) do if d.Id==doorId then chosen=d; break end end
    if not chosen then return end
    loadNextRoomAfterDoor(player,state,chosen)
end

local function submitDungeonAction(player,actionKey)
    if joinedGame[player.UserId]~=Constants.GAME_KEYS.DungeonDoors then return end
    local state=playerStates[player.UserId] or makeDungeonState(player); playerStates[player.UserId]=state
    local profile=getProfile(player); local you=state.Players[1]; local tile=getTile(state,state.PlayerTile)
    if not state.CanAct or state.ActionUsed or state.PendingEquip or state.DoorOptions then state.LastEvent="Wait for the current decision to resolve."; sendState(player,"Join"); return end
    state.PlayerAction=actionKey; state.PartnerAction=nil; state.Combo=nil
    if you.Downed then
        if actionKey==Constants.ACTIONS.Shield and revivePlayer(state,1) then state.Phase="Revived"; setPopup(state,"Revive","Back Up","Supplies used","You are back in the run.") else state.LastEvent="Downed: use Shield/Help with Supplies or Bandage to revive."; sendState(player,"Join"); return end
    elseif actionKey==Constants.ACTIONS.Step then
        state.MoveOptions=availableMoves(state)
        if #state.MoveOptions==0 then state.LastEvent=currentTileHasLiveMonster(state) and "Monster blocks the way. No revealed escape tile is adjacent." or "No reachable connected room."; setPopup(state,"Info","No Move",state.Board.Name,state.LastEvent); sendState(player,"Join"); return end
        state.CanAct=false; state.ActionUsed=true; state.Phase=currentTileHasLiveMonster(state) and "Run Away" or "Move"; state.LastEvent=currentTileHasLiveMonster(state) and "Run Away: revealed connected rooms only." or "Click a glowing connected room."; sendState(player,"Join"); return
    elseif actionKey==Constants.ACTIONS.Strike then
        if tile and tile.Kind=="Enemy" and not tile.Cleared then
            local damage=1+getEquippedPower(state,"Weapon")+(tile.Exposed and 1 or 0)
            if state.Combo and state.Combo.Name=="Duo Strike" then damage += 1 end
            if tile.Guard then local block=math.min(tile.Guard,damage); tile.Guard-=block; damage-=block end
            tile.HP=math.max(0,(tile.HP or 1)-damage)
            progressTask(profile,"StrikeEnemy")
            if tile.HP<=0 then tile.Cleared=true; applyEnemyReward(state,tile); state.LastEvent=(tile.Enemy or "Enemy").." defeated. Reward changed resources/items, not fake banking."; progressTask(profile,"DefeatEnemy"); setPopup(state,"Combat","Enemy Defeated",tile.Enemy,state.LastEvent) else state.LastEvent="Strike hits for "..tostring(damage)..". Enemy intent remains: "..(tile.Intent or "Unknown").."."; setPopup(state,"Combat","Hit Landed",tile.Enemy,state.LastEvent) end
        else state.LastEvent="No enemy here. Strike needs a monster in your room."; setPopup(state,"Info","No Enemy","Strike has no target",state.LastEvent) end
    elseif actionKey==Constants.ACTIONS.Search then
        if state.RoomActions and state.RoomActions.SearchUsed then state.LastEvent="Search is already spent for this room."; setPopup(state,"Info","Search Spent",state.Board.Name,"One team Search per room."); sendState(player,"Join"); return end
        resolveSearch(player,state,tile)
    elseif actionKey==Constants.ACTIONS.Shield then
        state.Guard=(state.Guard or 0)+2; state.Threat=math.max(0,state.Threat-1); you.Status="Shielded"; state.LastEvent="Shield up. Blocks damage/status and protects risky plays."; progressTask(profile,"ShieldPartner"); setPopup(state,"Guard","Shield Raised","Duo defense","Guard +2. Threat -1.")
    elseif actionKey==Constants.ACTIONS.Scheme then
        if state.RoomActions and state.RoomActions.SchemeUsed then state.LastEvent="Scheme is already spent for this room."; setPopup(state,"Info","Scheme Spent",state.Board.Name,"One team Scheme per room."); sendState(player,"Join"); return end
        resolveScheme(player,state,tile)
    end
    beginNextTurn(player,state,1.15); clientEvent:FireClient(player,Constants.TOPICS.Profile,profile)
end

local function handleTableClick(player,payload)
    if joinedGame[player.UserId]~=Constants.GAME_KEYS.DungeonDoors then return end
    local state=playerStates[player.UserId]; if not state then return end
    payload=payload or {}
    local kind=payload.Kind or payload.kind or payload.Type or payload.type
    local id=payload.Id or payload.id or payload.TileId or payload.tileId
    if kind=="Tile" or id then
        if moveToTile(player,state,id) then beginNextTurn(player,state,1.0) else sendState(player,"Join") end
    else
        state.LastEvent="Click a connected glowing room tile."
        sendState(player,"Join")
    end
end

local function handleChoice(player,choiceId) if joinedGame[player.UserId]~=Constants.GAME_KEYS.DungeonDoors then return end; local state=playerStates[player.UserId]; if not state then return end; if state.PendingEquip then if choiceId=="equip" then local p=state.PendingEquip; for _,e in ipairs(state.Backpack.Items) do if e.Data.Slot==p.Slot then e.Equipped=false end; if e.Uid==p.NewUid then e.Equipped=true end end; state.Backpack.Equipped[p.Slot]=p.NewUid; state.PendingEquip=nil; state.CanAct=true; state.ActionUsed=false; setPopup(state,"Item","Equipped","Gear changed","Your backpack equipment updated."); progressTask(getProfile(player),"EquipItem") elseif choiceId=="keep" then state.PendingEquip=nil; state.CanAct=true; state.ActionUsed=false end elseif state.DoorOptions then chooseDoor(player,state,choiceId) end; sendState(player,"Join"); clientEvent:FireClient(player,Constants.TOPICS.Profile,getProfile(player)) end
local function handleBackpackAction(player,payload) if joinedGame[player.UserId]~=Constants.GAME_KEYS.DungeonDoors then return end; local state=playerStates[player.UserId]; if not state then return end; payload=payload or {}; local entryIndex,entry=nil,nil; for i,item in ipairs(state.Backpack.Items or {}) do if item.Uid==payload.Uid then entryIndex=i; entry=item end end; if not entry then return end; if payload.Action=="equip" and entry.Data.Slot then for _,item in ipairs(state.Backpack.Items) do if item.Data.Slot==entry.Data.Slot then item.Equipped=false end end; entry.Equipped=true; state.Backpack.Equipped[entry.Data.Slot]=entry.Uid; progressTask(getProfile(player),"EquipItem"); setPopup(state,"Item","Equipped",entry.Data.Name,entry.Data.Body) elseif payload.Action=="use" and entry.Data.Type=="Consumable" then state.Players[1].HP=math.min(8,state.Players[1].HP+(entry.Data.Power or 1)); table.remove(state.Backpack.Items,entryIndex); setPopup(state,"Item","Used Item",entry.Data.Name,"Recovered HP.") end; sendState(player,"Join"); clientEvent:FireClient(player,Constants.TOPICS.Profile,getProfile(player)) end
local function renderGameFor(player,gameKey,mode) local gameInfo=GameCatalog.GetGame(gameKey); if not gameInfo then return end; if gameKey==Constants.GAME_KEYS.DungeonDoors then playerStates[player.UserId]=playerStates[player.UserId] or makeDungeonState(player); sendState(player,mode or "Join") end end
local function joinPlayer(player,gameKey)
    local profile=getProfile(player)
    if not profile.UnlockedGames[gameKey] then return end
    joinedGame[player.UserId]=gameKey
    local state=makeDungeonState(player)
    playerStates[player.UserId]=state
    enableExplorerMode(player,state)
    renderGameFor(player,gameKey,"Join")
    task.delay(5,function()
        if not player.Parent then return end
        local live=playerStates[player.UserId]
        if live==state and joinedGame[player.UserId]==Constants.GAME_KEYS.DungeonDoors and not live.AIPartner then
            live.AIPartner=true
            live.Players[2].Name="Candle Scout"
            live.Players[2].Status="AI partner"
            live.LastEvent="Candle Scout is watching the room. Full duo body co-op comes after this physical room foundation."
            -- v0.8 physical room mode: no card popup for AI teammate
            sendState(player,"Join")
        end
    end)
    for _,p in ipairs(Players:GetPlayers()) do clientEvent:FireClient(p,Constants.TOPICS.TableList,tableList()) end
end
local function spectatePlayer(player,gameKey) playerStates[player.UserId]=playerStates[player.UserId] or makeDungeonState(player); renderGameFor(player,gameKey,"Spectate") end
Players.PlayerAdded:Connect(function(player) getProfile(player); task.defer(sendProfile,player) end)
Players.PlayerRemoving:Connect(function(player) cleanupExplorer(player); joinedGame[player.UserId]=nil; playerStates[player.UserId]=nil end)
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
