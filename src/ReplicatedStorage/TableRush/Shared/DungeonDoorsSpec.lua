local Constants = require(script.Parent.Constants)

local DungeonDoorsSpec = {}

DungeonDoorsSpec.Actions = {
    {
        Key = Constants.ACTIONS.Step,
        Title = "Move Figure",
        Icon = "↔",
        Body = "Use WASD or click a connected room. Monsters block doors.",
        Tag = "MOVE",
    },
    {
        Key = Constants.ACTIONS.Strike,
        Title = "Fight",
        Icon = "⚔",
        Body = "Attack the live monster on your figure's tile.",
        Tag = "COMBAT",
    },
    {
        Key = Constants.ACTIONS.Search,
        Title = "Search Tile",
        Icon = "◆",
        Body = "Inspect this tile once. Team-shared; no repeat search.",
        Tag = "CLUE",
    },
    {
        Key = Constants.ACTIONS.Interact,
        Title = "Interact",
        Icon = "✦",
        Body = "Use the chest, lever, shrine, trap, clue, or exit here.",
        Tag = "OBJECT",
    },
    {
        Key = Constants.ACTIONS.Shield,
        Title = "Brace",
        Icon = "⬟",
        Body = "Brace against enemy intent and lower immediate danger.",
        Tag = "DEFEND",
    },
}

DungeonDoorsSpec.FakeState = {
    Phase = Constants.DUNGEON_PHASES.ChooseAction,
    RoomIndex = 3,
    RoomsToWin = 6,
    Pot = 1250,
    Threat = 2,
    CurrentRoom = {
        Key = "MimicStorage",
        Name = "Mimic Storage",
        Type = "Treasure",
        Clear = "Search carefully or wake the Mimic.",
        DoorText = "Safe Door / Greed Door",
    },
    Zones = {"Front", "Center", "Back"},
    Players = {
        {
            UserId = 1,
            Name = "You",
            Zone = "Center",
            Pouch = 420,
            Bank = 600,
            HP = 4,
            Keys = 1,
            Light = 2,
            Relics = {"Rusty Shield", "Door Sense"},
        },
        {
            UserId = 2,
            Name = "Partner",
            Zone = "Front",
            Pouch = 360,
            Bank = 450,
            HP = 5,
            Keys = 0,
            Light = 1,
            Relics = {"Lucky Key"},
        },
    },
    Enemies = {
        {
            Id = "MimicLurker_1",
            Name = "Mimic Lurker",
            Zone = "Back",
            HP = 3,
            MaxHP = 3,
            IntentIcon = "👁",
            Intent = "Bites greedy Search.",
            Kind = "Mimic",
        },
        {
            Id = "BoneRat_1",
            Name = "Bone Rat",
            Zone = "Front",
            HP = 1,
            MaxHP = 1,
            IntentIcon = "!",
            Intent = "Scurries toward weakest player.",
            Kind = "Rat",
        },
    },
    Doors = {
        {
            Key = "Safe",
            Label = "SAFE",
            Type = Constants.DOOR_TYPES.Normal,
            Hint = "Lower risk. Normal reward.",
        },
        {
            Key = "Greed",
            Label = "GREED",
            Type = Constants.DOOR_TYPES.Treasure,
            Hint = "More reward. More danger.",
        },
    },
    ActionCards = DungeonDoorsSpec and nil,
}

DungeonDoorsSpec.FakeState.ActionCards = DungeonDoorsSpec.Actions

DungeonDoorsSpec.EnemyRoster = {
    DoorGoblin = {
        Name = "Door Goblin",
        Purpose = "Blocks exits and teaches basic intent.",
    },
    BoneRat = {
        Name = "Bone Rat",
        Purpose = "Fast nuisance that forces movement.",
    },
    LanternWisp = {
        Name = "Lantern Wisp",
        Purpose = "Hides intent and scrambles door information.",
    },
    MimicLurker = {
        Name = "Mimic Lurker",
        Purpose = "Makes Search and treasure risky.",
    },
    ChainWarden = {
        Name = "Chain Warden",
        Purpose = "Chains doors and creates board puzzles.",
    },
    Doorwarden = {
        Name = "The Doorwarden",
        Purpose = "First boss. Living vault-door control boss.",
    },
}

return DungeonDoorsSpec
