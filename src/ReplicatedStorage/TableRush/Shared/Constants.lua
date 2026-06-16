local Constants = {}

Constants.VERSION = "v0.8.6"
Constants.EXPERIENCE_NAME = "Table Rush"

Constants.REMOTES_FOLDER = "TableRushRemotes"

Constants.REMOTES = {
    ClientEvent = "ClientEvent",
    RequestJoinGame = "RequestJoinGame",
    RequestSpectateGame = "RequestSpectateGame",
    SubmitAction = "SubmitAction",
    SubmitChoice = "SubmitChoice",
    TableClick = "TableClick",
    BackpackAction = "BackpackAction",
    ClaimDailyTask = "ClaimDailyTask",
    RequestProfile = "RequestProfile",
}

Constants.TOPICS = {
    Profile = "Profile",
    TableList = "TableList",
    RenderGame = "RenderGame",
    Toast = "Toast",
}

Constants.GAME_KEYS = {
    DungeonDoors = "DungeonDoors",
}

Constants.LAYOUT_MODES = {
    Desktop = "Desktop",
    Compact = "Compact",
    Mobile = "Mobile",
}

Constants.DUNGEON_PHASES = {
    RoomReveal = "Room Reveal",
    EnemyIntent = "Enemy Intent",
    ChooseAction = "Choose Action",
    RevealActions = "Reveal Cards",
    Resolve = "Resolve Board",
    DoorChoice = "Choose Door",
    Vault = "Final Vault",
}

Constants.ACTIONS = {
    Step = "Step",
    Strike = "Strike",
    Search = "Search",
    Shield = "Shield",
    Interact = "Interact",
    Scheme = "Scheme", -- legacy-hidden; do not render unless a real named use exists
}

Constants.DOOR_TYPES = {
    Normal = "Normal",
    Treasure = "Treasure",
    Danger = "Danger",
    Shop = "Shop",
    Curse = "Curse",
    Portal = "Portal",
    Boss = "Boss",
    Locked = "Locked",
}

return Constants
