local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage.TableRush.Shared.Constants)
local GameCatalog = require(ReplicatedStorage.TableRush.Shared.GameCatalog)
local DungeonDoorsSpec = require(ReplicatedStorage.TableRush.Shared.DungeonDoorsSpec)
local UIStyle = require(ReplicatedStorage.TableRush.Shared.UIStyle)
local Util = require(ReplicatedStorage.TableRush.Shared.Util)

local remotes = ReplicatedStorage:WaitForChild(Constants.REMOTES_FOLDER, 15)
if not remotes then
    warn("TableRushRemotes was not created. Check ServerScriptService/TableRush/Server.server.lua for server errors.")
    return
end

local clientEvent = remotes:WaitForChild(Constants.REMOTES.ClientEvent, 15)
local joinRemote = remotes:WaitForChild(Constants.REMOTES.RequestJoinGame, 15)
local spectateRemote = remotes:WaitForChild(Constants.REMOTES.RequestSpectateGame, 15)
local requestProfile = remotes:WaitForChild(Constants.REMOTES.RequestProfile, 15)

if not clientEvent or not joinRemote or not spectateRemote or not requestProfile then
    warn("Missing one or more Table Rush remotes. Check server boot.")
    return
end

local C = UIStyle.Colors
local F = UIStyle.Fonts

local state = {
    profile = nil,
    tableList = {},
    activeGame = nil,
    fakeState = DungeonDoorsSpec.FakeState,
    layout = "Desktop",
    selectedAction = nil,
    selectedDoor = nil,
    renderMode = nil,
    dailyOpen = false,
}

local function viewport()
    return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
end

local function layoutMode()
    local v = viewport()
    if UserInputService.TouchEnabled or v.X < 720 then
        return "Mobile"
    elseif v.Y < 650 or v.X < 1000 then
        return "Compact"
    else
        return "Desktop"
    end
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, obj)
end

local function stroke(obj, thickness, color, transparency)
    make("UIStroke", {
        Thickness = thickness or 1,
        Color = color or C.Border,
        Transparency = transparency or 0.25,
    }, obj)
end

local function pad(obj, l, r, t, b)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or l or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
    }, obj)
end

local function clear(frame)
    for _, child in ipairs(frame:GetChildren()) do
        if not child:IsA("UICorner") and not child:IsA("UIStroke") and not child:IsA("UIPadding") and not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local gui = make("ScreenGui", {
    Name = "TableRushGui",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

local root = make("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
}, gui)

local topBar = make("Frame", {
    Name = "TopBar",
    BackgroundColor3 = Color3.fromRGB(22, 18, 15),
    BackgroundTransparency = 0.06,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 10),
    Size = UDim2.fromOffset(670, 50),
    ZIndex = 20,
}, root)
round(topBar, 18)
stroke(topBar, 1, C.Border, 0.35)
pad(topBar, 14, 14, 4, 4)

local topText = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Font = F.Heading,
    TextSize = 20,
    TextColor3 = C.Text,
    Text = "Table Rush",
    ZIndex = 21,
}, topBar)

local hub = make("Frame", {
    Name = "HubMenu",
    BackgroundColor3 = Color3.fromRGB(25, 21, 18),
    BackgroundTransparency = 0.02,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.55),
    Size = UDim2.fromOffset(760, 420),
    ZIndex = 50,
}, root)
round(hub, 24)
stroke(hub, 2, C.Border, 0.22)
pad(hub, 22, 22, 18, 18)

local hubTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -210, 0, 36),
    Font = F.Heading,
    TextSize = 26,
    TextColor3 = C.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Table Rush Hall",
    ZIndex = 51,
}, hub)

local profilePill = make("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(39, 31, 24),
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.fromOffset(200, 36),
    Font = F.Heading,
    TextSize = 14,
    TextColor3 = C.Gold,
    Text = "Coins 0",
    ZIndex = 52,
}, hub)
round(profilePill, 12)
stroke(profilePill, 1, C.Border, 0.45)

local gameCards = make("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 56),
    Size = UDim2.new(1, 0, 1, -60),
    ZIndex = 51,
}, hub)

local gameListLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Padding = UDim.new(0, 16),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, gameCards)

local playerLayer = make("Frame", {
    Name = "PlayerMats",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 30,
}, root)

local actionLayer = make("Frame", {
    Name = "ActionCards",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -18),
    Size = UDim2.fromOffset(880, 220),
    Visible = false,
    ZIndex = 35,
}, root)

local actionList = make("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 36,
}, actionLayer)

local actionLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 16),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, actionList)

local ticker = make("TextLabel", {
    Name = "Ticker",
    BackgroundColor3 = Color3.fromRGB(22, 18, 15),
    BackgroundTransparency = 0.04,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -250),
    Size = UDim2.fromOffset(640, 42),
    Font = F.Heading,
    TextSize = 16,
    TextColor3 = C.Text,
    Text = "Board renderer loaded.",
    Visible = false,
    ZIndex = 45,
}, root)
round(ticker, 14)
stroke(ticker, 1, C.Border, 0.45)

local toast = make("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(22, 18, 15),
    BackgroundTransparency = 0.04,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 70),
    Size = UDim2.fromOffset(440, 42),
    Font = F.Heading,
    TextSize = 15,
    TextColor3 = C.Text,
    Text = "",
    Visible = false,
    ZIndex = 100,
}, root)
round(toast, 14)
stroke(toast, 1, C.Border, 0.45)

local bottomDock = make("Frame", {
    Name = "BottomDock",
    BackgroundColor3 = Color3.fromRGB(22, 18, 15),
    BackgroundTransparency = 0.04,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -16),
    Size = UDim2.fromOffset(310, 52),
    ZIndex = 70,
}, root)
round(bottomDock, 18)
stroke(bottomDock, 1, C.Border, 0.42)
pad(bottomDock, 8, 8, 8, 8)

local playButton = make("TextButton", {
    BackgroundColor3 = C.Gold,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(0.58, -4, 1, 0),
    Font = F.Heading,
    TextSize = 16,
    TextColor3 = C.Ink,
    Text = "Play",
    ZIndex = 71,
}, bottomDock)
round(playButton, 13)

local dailyButton = make("TextButton", {
    BackgroundColor3 = Color3.fromRGB(38, 31, 25),
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0.42, -4, 1, 0),
    Font = F.Heading,
    TextSize = 15,
    TextColor3 = C.Text,
    Text = "Daily",
    ZIndex = 71,
}, bottomDock)
round(dailyButton, 13)
stroke(dailyButton, 1, C.Border, 0.45)

local dailyPanel = make("Frame", {
    Name = "DailyPanel",
    BackgroundColor3 = Color3.fromRGB(24, 20, 17),
    BackgroundTransparency = 0.02,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -82),
    Size = UDim2.fromOffset(500, 360),
    Visible = false,
    ZIndex = 80,
}, root)
round(dailyPanel, 20)
stroke(dailyPanel, 2, C.Border, 0.24)
pad(dailyPanel, 18, 18, 14, 14)

local dailyTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -74, 0, 28),
    Font = F.Heading,
    TextSize = 19,
    TextColor3 = C.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Daily Tasks",
    ZIndex = 81,
}, dailyPanel)

local dailySubtitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 29),
    Size = UDim2.new(1, -10, 0, 22),
    Font = F.Body,
    TextSize = 12,
    TextColor3 = C.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Finish small goals. Earn coins and tickets.",
    ZIndex = 81,
}, dailyPanel)

local dailyList = make("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 60),
    Size = UDim2.new(1, 0, 1, -62),
    ZIndex = 81,
}, dailyPanel)
local dailyLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, dailyList)

local function showToast(message)
    toast.Text = tostring(message or "")
    toast.Visible = true
    toast.TextTransparency = 0
    task.delay(2.1, function()
        TweenService:Create(toast, TweenInfo.new(0.25), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        toast.BackgroundTransparency = 0.04
        toast.Visible = false
    end)
end

local function showTicker(message)
    ticker.Text = tostring(message or "")
    ticker.Visible = true
    ticker.TextTransparency = 0
    task.delay(3, function()
        if ticker.Text == tostring(message or "") then
            TweenService:Create(ticker, TweenInfo.new(0.25), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            ticker.Visible = false
            ticker.TextTransparency = 0
        end
    end)
end

local renderFolder = Instance.new("Folder")
renderFolder.Name = "ClientDungeonBoardRender"
renderFolder.Parent = workspace

local function part(parent, name, size, cframe, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function billboard(parent, text, size, offset, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Label"
    gui.Size = size or UDim2.fromOffset(160, 44)
    gui.StudsOffset = offset or Vector3.new(0, 2, 0)
    gui.AlwaysOnTop = true
    gui.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = F.Heading
    label.TextScaled = true
    label.TextColor3 = color or C.Text
    label.TextStrokeTransparency = 0.45
    label.Text = text
    label.Parent = gui
end

local function doorColor(doorType)
    if doorType == Constants.DOOR_TYPES.Treasure then return C.Gold end
    if doorType == Constants.DOOR_TYPES.Danger then return C.Red end
    if doorType == Constants.DOOR_TYPES.Shop then return C.Green end
    if doorType == Constants.DOOR_TYPES.Curse then return C.Purple end
    if doorType == Constants.DOOR_TYPES.Portal then return C.Blue end
    if doorType == Constants.DOOR_TYPES.Boss then return Color3.fromRGB(28, 27, 31) end
    return Color3.fromRGB(126, 78, 42)
end

local zoneOffsets = {
    Front = Vector3.new(-3.6, 0, 0),
    Center = Vector3.new(0, 0, 0),
    Back = Vector3.new(3.6, 0, 0),
}

local function renderDungeonBoard3D(fake)
    renderFolder:ClearAllChildren()

    local hall = workspace:FindFirstChild("TableRushHall")
    local tableModel = hall and hall:FindFirstChild("DungeonDoorsTable")
    local top = tableModel and tableModel:FindFirstChild("Top")
    if not top then
        return
    end

    local base = top.CFrame * CFrame.new(0, 0.74, 0)

    local boardBase = part(renderFolder, "BoardBase", Vector3.new(14.6, 0.28, 8.4), base, Color3.fromRGB(48, 47, 42), Enum.Material.Slate)
    billboard(boardBase, fake.CurrentRoom.Name, UDim2.fromOffset(220, 46), Vector3.new(0, 1.15, -3.7), C.Gold)

    -- Room zones.
    local zoneNames = {"Front", "Center", "Back"}
    for i, zone in ipairs(zoneNames) do
        local x = -4.0 + (i-1)*4.0
        local zpart = part(renderFolder, "Zone_" .. zone, Vector3.new(3.4, 0.18, 5.2), base * CFrame.new(x, 0.18, 0), Color3.fromRGB(75, 72, 64), Enum.Material.Slate)
        billboard(zpart, string.upper(zone), UDim2.fromOffset(105, 30), Vector3.new(0, 0.55, 2.25), C.Muted)
    end

    -- Entrance and door choices.
    local entrance = part(renderFolder, "EntranceDoor", Vector3.new(1.3, 2.5, 3.2), base * CFrame.new(-7.7, 1.25, 0), Color3.fromRGB(116, 74, 42), Enum.Material.Wood)
    billboard(entrance, "IN", UDim2.fromOffset(80, 30), Vector3.new(0, 1.75, 0), C.Text)

    for i, door in ipairs(fake.Doors or {}) do
        local dz = (#fake.Doors == 1) and 0 or (-1.8 + (i-1)*3.6)
        local d = part(renderFolder, "Door_" .. door.Key, Vector3.new(1.35, 2.8, 2.8), base * CFrame.new(7.75, 1.4, dz), doorColor(door.Type), Enum.Material.Wood)
        billboard(d, door.Label, UDim2.fromOffset(100, 36), Vector3.new(0, 1.9, 0), door.Type == Constants.DOOR_TYPES.Treasure and C.Ink or C.Text)

        if door.Type == Constants.DOOR_TYPES.Treasure then
            local dust = part(renderFolder, "GoldDust_" .. door.Key, Vector3.new(1.1, 0.08, 0.22), base * CFrame.new(7.0, 0.28, dz - 1.05), C.Gold, Enum.Material.Neon)
            dust.Transparency = 0.15
        end
    end

    -- Player tokens.
    for i, ps in ipairs(fake.Players or {}) do
        local offset = zoneOffsets[ps.Zone] or zoneOffsets.Front
        local z = i == 1 and -0.95 or 0.95
        local token = part(renderFolder, "PlayerToken_" .. tostring(i), Vector3.new(0.9, 0.55, 0.9), base * CFrame.new(offset.X, 0.62, z), i == 1 and C.Blue or C.Gold, Enum.Material.SmoothPlastic)
        billboard(token, i == 1 and "P1" or "P2", UDim2.fromOffset(70, 30), Vector3.new(0, 1.0, 0), C.Text)
    end

    -- Enemies.
    for i, enemy in ipairs(fake.Enemies or {}) do
        local offset = zoneOffsets[enemy.Zone] or zoneOffsets.Center
        local z = 1.85 + (i-1)*0.3
        local enemyPart = part(renderFolder, "Enemy_" .. enemy.Id, Vector3.new(1.0, 0.75, 1.0), base * CFrame.new(offset.X, 0.72, z), C.Red, Enum.Material.SmoothPlastic)
        billboard(enemyPart, enemy.IntentIcon .. " " .. enemy.Name .. "\nHP " .. tostring(enemy.HP) .. "/" .. tostring(enemy.MaxHP), UDim2.fromOffset(150, 54), Vector3.new(0, 1.25, 0), C.Text)
    end

    -- Chest object in back.
    local chest = part(renderFolder, "SuspiciousChest", Vector3.new(1.25, 0.65, 0.9), base * CFrame.new(3.7, 0.65, -1.65), C.Gold, Enum.Material.SmoothPlastic)
    billboard(chest, "CHEST?", UDim2.fromOffset(100, 32), Vector3.new(0, 1.0, 0), C.Ink)

    -- Pot/threat markers.
    local pot = part(renderFolder, "PotMarker", Vector3.new(2.2, 0.28, 1.0), base * CFrame.new(0, 0.35, -3.65), Color3.fromRGB(42, 32, 20), Enum.Material.SmoothPlastic)
    billboard(pot, "POT " .. tostring(fake.Pot) .. "\nTHREAT " .. tostring(fake.Threat), UDim2.fromOffset(150, 48), Vector3.new(0, 0.9, 0), C.Gold)
end




local function renderDaily()
    clear(dailyList)
    local tasks = state.profile and state.profile.DailyTasks or {}

    if #tasks == 0 then
        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 74),
            Font = F.Body,
            TextSize = 13,
            TextColor3 = C.Muted,
            TextWrapped = true,
            Text = "No daily tasks loaded yet.",
            ZIndex = 82,
        }, dailyList)
        return
    end

    for i, task in ipairs(tasks) do
        if i <= 3 then
            local progress = tonumber(task.Progress) or 0
            local target = math.max(1, tonumber(task.Target) or 1)
            local pct = math.clamp(progress / target, 0, 1)
            local complete = pct >= 1

            local card = make("Frame", {
                BackgroundColor3 = complete and Color3.fromRGB(32, 42, 31) or Color3.fromRGB(38, 31, 25),
                Size = UDim2.new(1, 0, 0, 86),
                ZIndex = 82,
            }, dailyList)
            round(card, 14)
            stroke(card, 1, complete and C.Green or C.Border, complete and 0.20 or 0.50)
            pad(card, 14, 14, 10, 10)

            -- Top row: title + compact progress count. No reward block here, so text has room.
            make("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -70, 0, 20),
                Font = F.Heading,
                TextSize = 14,
                TextColor3 = C.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = task.Title or "Daily Task",
                ZIndex = 83,
            }, card)

            local countPill = make("TextLabel", {
                BackgroundColor3 = complete and C.Green or Color3.fromRGB(55, 47, 38),
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.fromOffset(56, 22),
                Font = F.Heading,
                TextSize = 11,
                TextColor3 = complete and C.Text or C.Gold,
                Text = tostring(progress) .. "/" .. tostring(target),
                ZIndex = 83,
            }, card)
            round(countPill, 8)

            -- Middle row: description gets its own line.
            make("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 24),
                Size = UDim2.new(1, 0, 0, 18),
                Font = F.Body,
                TextSize = 11,
                TextColor3 = C.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = tostring(task.Description or ""),
                ZIndex = 83,
            }, card)

            -- Progress bar row.
            local barBack = make("Frame", {
                BackgroundColor3 = Color3.fromRGB(58, 49, 39),
                Position = UDim2.fromOffset(0, 48),
                Size = UDim2.new(1, 0, 0, 8),
                ZIndex = 83,
            }, card)
            round(barBack, 4)

            local barFill = make("Frame", {
                BackgroundColor3 = complete and C.Green or C.Gold,
                Size = UDim2.new(pct, 0, 1, 0),
                ZIndex = 84,
            }, barBack)
            round(barFill, 4)

            -- Bottom row: reward tag is no longer crushing the description.
            local rewardRow = make("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 61),
                Size = UDim2.new(1, 0, 0, 18),
                ZIndex = 83,
            }, card)

            make("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -120, 1, 0),
                Font = F.Body,
                TextSize = 10,
                TextColor3 = complete and C.Green or C.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = complete and "Complete — claim later" or "Reward on completion",
                ZIndex = 84,
            }, rewardRow)

            local rewardText = make("TextLabel", {
                BackgroundColor3 = C.Gold,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(112, 26),
                Font = F.Heading,
                TextSize = 11,
                TextColor3 = C.Ink,
                Text = "+" .. tostring(task.RewardCoins or 0) .. " coins  +" .. tostring(task.RewardTickets or 0) .. "t",
                ZIndex = 84,
            }, rewardRow)
            round(rewardText, 9)
        end
    end
end


local function renderTop()
    local fake = state.fakeState
    if state.activeGame == Constants.GAME_KEYS.DungeonDoors and fake then
        topText.Text = string.format("Room %d/%d  •  Pot %s  •  Threat %d  •  %s", fake.RoomIndex, fake.RoomsToWin, Util.formatNumber(fake.Pot), fake.Threat, fake.Phase)
    else
        topText.Text = "Table Rush  •  Choose a table in the hall"
    end

    if state.profile then
        profilePill.Text = string.format("Lv %d  •  %s coins", state.profile.Level or 1, Util.formatNumber(state.profile.Coins or 0))
    end
end

local function makeGameCard(gameInfo, tableInfo)
    local card = make("TextButton", {
        BackgroundColor3 = Color3.fromRGB(38, 31, 25),
        Size = UDim2.fromOffset(220, 265),
        AutoButtonColor = false,
        Text = "",
        ZIndex = 52,
    }, gameCards)
    round(card, 18)
    stroke(card, 2, gameInfo.Key == Constants.GAME_KEYS.DungeonDoors and C.Gold or C.Border, 0.25)
    pad(card, 14, 14, 12, 12)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        Font = F.Heading,
        TextSize = 20,
        TextColor3 = C.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = gameInfo.DisplayName,
        ZIndex = 53,
    }, card)

    local art = make("Frame", {
        BackgroundColor3 = gameInfo.Key == Constants.GAME_KEYS.DungeonDoors and C.StoneDark or Color3.fromRGB(44, 43, 48),
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 0, 86),
        ZIndex = 53,
    }, card)
    round(art, 14)
    stroke(art, 1, C.Border, 0.55)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = F.Heading,
        TextSize = 26,
        TextColor3 = gameInfo.Key == Constants.GAME_KEYS.DungeonDoors and C.Gold or C.Muted,
        Text = gameInfo.Key == Constants.GAME_KEYS.DungeonDoors and "DOORS" or "SOON",
        ZIndex = 54,
    }, art)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 148),
        Size = UDim2.new(1, 0, 0, 48),
        Font = F.Body,
        TextSize = 12,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = C.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = gameInfo.Tagline,
        ZIndex = 53,
    }, card)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 202),
        Size = UDim2.new(1, 0, 0, 20),
        Font = F.Heading,
        TextSize = 12,
        TextColor3 = gameInfo.Status == "Featured" and C.Green or C.Purple,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = gameInfo.Status .. "  •  " .. tostring(tableInfo and tableInfo.Count or 0) .. "/" .. tostring(gameInfo.MaxPlayers),
        ZIndex = 53,
    }, card)

    local join = make("TextLabel", {
        BackgroundColor3 = gameInfo.Key == Constants.GAME_KEYS.DungeonDoors and C.Gold or Color3.fromRGB(60, 55, 52),
        Position = UDim2.new(0, 0, 1, -36),
        Size = UDim2.new(1, 0, 0, 36),
        Font = F.Heading,
        TextSize = 14,
        TextColor3 = gameInfo.Key == Constants.GAME_KEYS.DungeonDoors and C.Ink or C.Muted,
        Text = gameInfo.Key == Constants.GAME_KEYS.DungeonDoors and "Render Table" or "Locked",
        ZIndex = 53,
    }, card)
    round(join, 12)

    card.Activated:Connect(function()
        if gameInfo.Key == Constants.GAME_KEYS.DungeonDoors then
            joinRemote:FireServer(gameInfo.Key)
        else
            showToast("Future table slot.")
        end
    end)
end

local function renderHub()
    clear(gameCards)
    for _, gameInfo in ipairs(GameCatalog.GetPublicList()) do
        local tableInfo = nil
        for _, t in ipairs(state.tableList or {}) do
            if t.Key == gameInfo.Key then
                tableInfo = t
                break
            end
        end
        makeGameCard(gameInfo, tableInfo)
    end

    hub.Visible = state.activeGame == nil
end

local function makePlayerMat(ps, index)
    local mobile = state.layout == "Mobile"
    local compact = state.layout == "Compact"
    local v = viewport()

    local w = mobile and 158 or (compact and 170 or 220)
    local h = mobile and 62 or (compact and 120 or 178)
    local x = index == 1 and 16 or (v.X - w - 16)
    local y = mobile and 70 or (compact and 116 or 150)

    local mat = make("Frame", {
        BackgroundColor3 = Color3.fromRGB(28, 23, 19),
        BackgroundTransparency = 0.02,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        ZIndex = 31,
    }, playerLayer)
    round(mat, mobile and 14 or 18)
    stroke(mat, 2, index == 1 and C.Blue or C.Gold, 0.25)
    pad(mat, 12, 12, 8, 8)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, mobile and 18 or 26),
        Font = F.Heading,
        TextSize = mobile and 12 or 16,
        TextColor3 = C.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = ps.Name,
        ZIndex = 32,
    }, mat)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, mobile and 22 or 34),
        Size = UDim2.new(1, 0, 0, mobile and 24 or 34),
        Font = F.Heading,
        TextSize = mobile and 13 or 20,
        TextColor3 = C.Gold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Pouch " .. tostring(ps.Pouch),
        ZIndex = 32,
    }, mat)

    if not mobile then
        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 68),
            Size = UDim2.new(1, 0, 0, 24),
            Font = F.Heading,
            TextSize = compact and 13 or 16,
            TextColor3 = C.Green,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Bank " .. tostring(ps.Bank) .. "  •  HP " .. tostring(ps.HP),
            ZIndex = 32,
        }, mat)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 96),
            Size = UDim2.new(1, 0, 0, 24),
            Font = F.Body,
            TextSize = compact and 11 or 13,
            TextColor3 = C.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Keys " .. tostring(ps.Keys) .. "  •  Light " .. tostring(ps.Light) .. "  •  " .. ps.Zone,
            ZIndex = 32,
        }, mat)

        if not compact then
            make("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 126),
                Size = UDim2.new(1, 0, 0, 34),
                Font = F.Body,
                TextSize = 12,
                TextWrapped = true,
                TextColor3 = C.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Relics: " .. table.concat(ps.Relics or {}, ", "),
                ZIndex = 32,
            }, mat)
        end
    end
end

local function renderPlayerMats()
    clear(playerLayer)
    if not state.activeGame or not state.fakeState then
        return
    end

    for i, ps in ipairs(state.fakeState.Players or {}) do
        makePlayerMat(ps, i)
    end
end

local function makeActionCard(action, order)
    local mobile = state.layout == "Mobile"
    local compact = state.layout == "Compact"
    local w = mobile and 118 or (compact and 132 or 156)
    local h = mobile and 162 or (compact and 178 or 212)

    local card = make("TextButton", {
        BackgroundColor3 = C.Card,
        Size = UDim2.fromOffset(w, h),
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = order,
        Rotation = 0,
        ZIndex = 36,
    }, actionList)
    round(card, 16)
    local cardStroke = stroke(card, 2, state.selectedAction == action.Key and C.Gold or C.Border, state.selectedAction == action.Key and 0 or 0.18)
    local cardScale = make("UIScale", { Scale = state.selectedAction == action.Key and 1.04 or 1 }, card)
    pad(card, 10, 10, 10, 10)

    make("TextLabel", {
        BackgroundColor3 = C.CardDark,
        Size = UDim2.new(1, 0, 0, math.floor(h * 0.36)),
        Font = F.Heading,
        TextSize = mobile and 28 or 38,
        TextColor3 = C.Ink,
        Text = action.Icon,
        ZIndex = 37,
    }, card)
    round(card:FindFirstChildOfClass("TextLabel"), 12)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, math.floor(h * 0.42)),
        Size = UDim2.new(1, 0, 0, 28),
        Font = F.Heading,
        TextSize = mobile and 15 or 19,
        TextColor3 = C.Ink,
        Text = action.Title,
        ZIndex = 37,
    }, card)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, math.floor(h * 0.58)),
        Size = UDim2.new(1, 0, 0, mobile and 54 or 66),
        Font = F.Body,
        TextSize = mobile and 11 or 13,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = Color3.fromRGB(70, 53, 38),
        Text = action.Body,
        ZIndex = 37,
    }, card)

    local tag = make("TextLabel", {
        BackgroundColor3 = Color3.fromRGB(54, 42, 29),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 26),
        Font = F.Heading,
        TextSize = mobile and 10 or 11,
        TextColor3 = C.Gold,
        Text = action.Tag,
        ZIndex = 37,
    }, card)
    round(tag, 9)

    card.MouseEnter:Connect(function()
        if not mobile then
            TweenService:Create(cardScale, TweenInfo.new(0.12), {Scale = 1.055}):Play()
            TweenService:Create(card, TweenInfo.new(0.12), {Rotation = order % 2 == 0 and 1.4 or -1.4}):Play()
            TweenService:Create(cardStroke, TweenInfo.new(0.12), {Transparency = 0.02, Color = C.Gold}):Play()
        end
    end)
    card.MouseLeave:Connect(function()
        if not mobile then
            TweenService:Create(cardScale, TweenInfo.new(0.12), {Scale = state.selectedAction == action.Key and 1.04 or 1}):Play()
            TweenService:Create(card, TweenInfo.new(0.12), {Rotation = 0}):Play()
            TweenService:Create(cardStroke, TweenInfo.new(0.12), {Transparency = state.selectedAction == action.Key and 0 or 0.18, Color = state.selectedAction == action.Key and C.Gold or C.Border}):Play()
        end
    end)

    card.Activated:Connect(function()
        state.selectedAction = action.Key
        showTicker(action.Title .. " selected. Gameplay lock-in comes in v0.2.")
        renderActions()
    end)
end

function renderActions()
    clear(actionList)
    if not state.activeGame or not state.fakeState then
        actionLayer.Visible = false
        return
    end

    actionLayer.Visible = true
    for i, action in ipairs(state.fakeState.ActionCards or {}) do
        makeActionCard(action, i)
    end
end

function renderLayout()
    state.layout = layoutMode()
    local mode = state.layout
    local v = viewport()

    if mode == "Mobile" then
        topBar.Size = UDim2.fromOffset(math.min(v.X - 20, 420), 42)
        topText.TextSize = 13
        hub.Size = UDim2.fromOffset(math.min(v.X - 24, 390), math.min(v.Y - 90, 440))
        hubTitle.TextSize = 20
        profilePill.Visible = false
        gameListLayout.FillDirection = Enum.FillDirection.Vertical
        actionLayer.Size = UDim2.fromOffset(math.min(v.X - 18, 410), 174)
        actionLayer.Position = UDim2.new(0.5, 0, 1, -8)
        actionLayout.Padding = UDim.new(0, 8)
        ticker.Size = UDim2.fromOffset(math.min(v.X - 20, 400), 38)
        ticker.Position = UDim2.new(0.5, 0, 1, -190)
        ticker.TextSize = 12
        bottomDock.Size = UDim2.fromOffset(math.min(v.X - 24, 310), 50)
        bottomDock.Position = UDim2.new(0.5, 0, 1, -8)
        dailyPanel.Size = UDim2.fromOffset(math.min(v.X - 22, 430), math.min(v.Y - 94, 360))
        dailyPanel.Position = UDim2.new(0.5, 0, 1, -64)
        dailyTitle.TextSize = 18
        dailySubtitle.TextSize = 11
    elseif mode == "Compact" then
        topBar.Size = UDim2.fromOffset(math.min(v.X - 40, 600), 46)
        topText.TextSize = 15
        hub.Size = UDim2.fromOffset(math.min(v.X - 40, 700), math.min(v.Y - 100, 390))
        hubTitle.TextSize = 22
        profilePill.Visible = true
        gameListLayout.FillDirection = Enum.FillDirection.Horizontal
        actionLayer.Size = UDim2.fromOffset(math.min(v.X - 30, 740), 190)
        actionLayer.Position = UDim2.new(0.5, 0, 1, -10)
        actionLayout.Padding = UDim.new(0, 10)
        ticker.Size = UDim2.fromOffset(math.min(v.X - 34, 520), 38)
        ticker.Position = UDim2.new(0.5, 0, 1, -210)
        ticker.TextSize = 13
        bottomDock.Size = UDim2.fromOffset(310, 52)
        bottomDock.Position = UDim2.new(0.5, 0, 1, -12)
        dailyPanel.Size = UDim2.fromOffset(math.min(v.X - 34, 470), math.min(v.Y - 110, 360))
        dailyPanel.Position = UDim2.new(0.5, 0, 1, -74)
        dailyTitle.TextSize = 18
        dailySubtitle.TextSize = 12
    else
        topBar.Size = UDim2.fromOffset(670, 50)
        topText.TextSize = 20
        hub.Size = UDim2.fromOffset(760, 420)
        hubTitle.TextSize = 26
        profilePill.Visible = true
        gameListLayout.FillDirection = Enum.FillDirection.Horizontal
        actionLayer.Size = UDim2.fromOffset(880, 220)
        actionLayer.Position = UDim2.new(0.5, 0, 1, -18)
        actionLayout.Padding = UDim.new(0, 16)
        ticker.Size = UDim2.fromOffset(640, 42)
        ticker.Position = UDim2.new(0.5, 0, 1, -250)
        ticker.TextSize = 16
        bottomDock.Size = UDim2.fromOffset(310, 52)
        bottomDock.Position = UDim2.new(0.5, 0, 1, -16)
        dailyPanel.Size = UDim2.fromOffset(500, 360)
        dailyPanel.Position = UDim2.new(0.5, 0, 1, -78)
        dailyTitle.TextSize = 19
        dailySubtitle.TextSize = 12
    end
end

function renderAll()
    renderLayout()
    renderTop()
    playButton.Text = state.activeGame and "Playing" or "Play"
    renderHub()
    renderPlayerMats()
    renderActions()
    renderDaily()
    if state.activeGame == Constants.GAME_KEYS.DungeonDoors then
        renderDungeonBoard3D(state.fakeState)
    else
        renderFolder:ClearAllChildren()
    end
end


playButton.Activated:Connect(function()
    if state.activeGame == nil then
        state.dailyOpen = false
        dailyPanel.Visible = false
        hub.Visible = not hub.Visible
    else
        showTicker("Already rendering a table. Gameplay starts in v0.2.")
    end
end)

dailyButton.Activated:Connect(function()
    state.dailyOpen = not state.dailyOpen
    dailyPanel.Visible = state.dailyOpen
    if state.dailyOpen then
        renderDaily()
    end
end)

clientEvent.OnClientEvent:Connect(function(topic, payload)
    if topic == Constants.TOPICS.Profile then
        state.profile = payload
        renderAll()
    elseif topic == Constants.TOPICS.TableList then
        state.tableList = payload or {}
        renderAll()
    elseif topic == Constants.TOPICS.RenderGame then
        state.activeGame = payload.GameKey
        state.renderMode = payload.Mode or "Join"
        state.fakeState = payload.FakeState or DungeonDoorsSpec.FakeState
        hub.Visible = false
        showTicker("Dungeon Doors table rendered. v0.2 adds real gameplay.")
        renderAll()
    elseif topic == Constants.TOPICS.Toast then
        showToast(payload and payload.Message or "")
    end
end)

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        task.defer(renderAll)
    end)
end

requestProfile:FireServer()
renderAll()
