
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage.TableRush.Shared.Constants)
local GameCatalog = require(ReplicatedStorage.TableRush.Shared.GameCatalog)
local DungeonDoorsSpec = require(ReplicatedStorage.TableRush.Shared.DungeonDoorsSpec)
local UIStyle = require(ReplicatedStorage.TableRush.Shared.UIStyle)
local Util = require(ReplicatedStorage.TableRush.Shared.Util)

local remotes = ReplicatedStorage:WaitForChild(Constants.REMOTES_FOLDER, 15)
if not remotes then
    warn("TableRushRemotes was not created. Check ServerScriptService/TableRush/Server.server.lua.")
    return
end

local clientEvent = remotes:WaitForChild(Constants.REMOTES.ClientEvent, 15)
local joinRemote = remotes:WaitForChild(Constants.REMOTES.RequestJoinGame, 15)
local spectateRemote = remotes:WaitForChild(Constants.REMOTES.RequestSpectateGame, 15)
local submitActionRemote = remotes:WaitForChild(Constants.REMOTES.SubmitAction, 15)
local submitChoiceRemote = remotes:WaitForChild(Constants.REMOTES.SubmitChoice, 15)
local tableClickRemote = remotes:WaitForChild(Constants.REMOTES.TableClick, 15)
local backpackActionRemote = remotes:WaitForChild(Constants.REMOTES.BackpackAction, 15)
local claimDailyTaskRemote = remotes:WaitForChild(Constants.REMOTES.ClaimDailyTask, 15)
local requestProfile = remotes:WaitForChild(Constants.REMOTES.RequestProfile, 15)

if not clientEvent or not joinRemote or not spectateRemote or not submitActionRemote or not submitChoiceRemote or not tableClickRemote or not backpackActionRemote or not claimDailyTaskRemote or not requestProfile then
    warn("Missing one or more Table Rush remotes. Check server boot.")
    return
end

local C = UIStyle.Colors
local F = UIStyle.Fonts

-- Shell colors are intentionally cool/slate. Game/action cards stay cream.
local Shell = {
    Panel = Color3.fromRGB(8, 12, 18),
    Panel2 = Color3.fromRGB(13, 20, 30),
    Row = Color3.fromRGB(18, 28, 41),
    Row2 = Color3.fromRGB(21, 34, 48),
    Border = C.Border,
    Text = C.Text,
    Muted = C.Muted,
    Blue = C.Blue,
    Gold = C.Gold,
    Green = C.Green,
    Ink = C.Ink,
}

local TeamPurple = Color3.fromRGB(170, 112, 255)
local DangerRed = Color3.fromRGB(230, 82, 76)
local TaskDark = Color3.fromRGB(18, 28, 41)
local TaskButtonDark = Color3.fromRGB(25, 38, 54)

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
    backpackOpen = false,
    lastPopupId = nil,
}


-- UIStabilityLock_v082:
-- Hard rule: no text/button overlap, no text-scale flashing, no UI pieces fighting for the same space.
local function applyTextSafety(label, textSize, padX, padY)
    if not label or not label.Parent or (not label:IsA("TextLabel") and not label:IsA("TextButton")) then return end
    label.TextWrapped = true
    label.TextTruncate = Enum.TextTruncate.None
    label.TextScaled = false
    label.TextSize = textSize or label.TextSize or 14
    label.LineHeight = 1.05
    label.ClipsDescendants = true
    local existing = label:FindFirstChild("UIStabilityPadding")
    if existing then existing:Destroy() end
    local pad = Instance.new("UIPadding")
    pad.Name = "UIStabilityPadding"
    pad.PaddingLeft = UDim.new(0, padX or 10)
    pad.PaddingRight = UDim.new(0, padX or 10)
    pad.PaddingTop = UDim.new(0, padY or 6)
    pad.PaddingBottom = UDim.new(0, padY or 6)
    pad.Parent = label
end

local function applyContainerSafety(frame, padX, padY)
    if not frame or not frame:IsA("GuiObject") then return end
    frame.ClipsDescendants = false
    local existing = frame:FindFirstChild("UIStabilityContainerPadding")
    if existing then existing:Destroy() end
    local pad = Instance.new("UIPadding")
    pad.Name = "UIStabilityContainerPadding"
    pad.PaddingLeft = UDim.new(0, padX or 8)
    pad.PaddingRight = UDim.new(0, padX or 8)
    pad.PaddingTop = UDim.new(0, padY or 8)
    pad.PaddingBottom = UDim.new(0, padY or 8)
    pad.Parent = frame
end

local function viewport()
    return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
end

local function isTouch()
    return UserInputService.TouchEnabled
end

local function layoutMode()
    local v = viewport()
    if isTouch() and v.Y > v.X then
        return "PortraitBlocked"
    end
    if isTouch() or v.X < 900 then
        return "MobileLandscape"
    elseif v.Y < 650 or v.X < 1100 then
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
    if not obj then return nil end
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, obj)
end

local function stroke(obj, thickness, color, transparency)
    if not obj then return nil end

    -- v0.8.5 compatibility:
    -- Original helper was stroke(obj, thickness, color, transparency).
    -- Some rebuilt UI code accidentally called stroke(obj, color, thickness, transparency).
    -- Support both so render code cannot crash on UIStroke property types.
    if typeof(thickness) == "Color3" then
        local passedColor = thickness
        local passedThickness = color
        thickness = passedThickness
        color = passedColor
    end

    return make("UIStroke", {
        Thickness = type(thickness) == "number" and thickness or 1,
        Color = typeof(color) == "Color3" and color or Shell.Border,
        Transparency = type(transparency) == "number" and transparency or 0.25,
    }, obj)
end

local function pad(obj, l, r, t, b)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or l or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
    }, obj)
end

local function clear(frame)
    if not frame then return end
    for _, child in ipairs(frame:GetChildren()) do
        if not child:IsA("UICorner")
            and not child:IsA("UIStroke")
            and not child:IsA("UIPadding")
            and not child:IsA("UIListLayout")
            and not child:IsA("UIScale") then
            child:Destroy()
        end
    end
end

-- v0.8.5 command-bar compatibility aliases.
-- Newer UI code should not call undefined helpers.
local function clearChildren(frame)
    return clear(frame)
end

local function corner(obj, radius)
    return round(obj, radius)
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
    BackgroundColor3 = Shell.Panel,
    BackgroundTransparency = 0.04,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 10),
    Size = UDim2.fromOffset(670, 46),
    ZIndex = 20,
}, root)
round(topBar, 16)
stroke(topBar, 1, Shell.Border, 0.36)
pad(topBar, 14, 14, 4, 4)

local topText = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Font = F.Heading,
    TextSize = 16,
    TextColor3 = Shell.Text,
    Text = "Table Rush",
    ZIndex = 21,
}, topBar)

-- Rotate overlay. Phone card games should be played landscape.
local rotateOverlay = make("Frame", {
    Name = "RotateOverlay",
    BackgroundColor3 = Color3.fromRGB(7, 10, 15),
    BackgroundTransparency = 0.02,
    Size = UDim2.fromScale(1, 1),
    Visible = false,
    ZIndex = 300,
}, root)

local rotateCard = make("Frame", {
    BackgroundColor3 = Shell.Panel2,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(310, 230),
    ZIndex = 301,
}, rotateOverlay)
round(rotateCard, 24)
stroke(rotateCard, 2, Shell.Border, 0.22)
pad(rotateCard, 22, 22, 18, 18)

make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 50),
    Font = F.Heading,
    TextSize = 28,
    TextColor3 = Shell.Gold,
    Text = "↻",
    ZIndex = 302,
}, rotateCard)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 58),
    Size = UDim2.new(1, 0, 0, 36),
    Font = F.Heading,
    TextSize = 20,
    TextColor3 = Shell.Text,
    Text = "Rotate to play",
    ZIndex = 302,
}, rotateCard)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 104),
    Size = UDim2.new(1, 0, 0, 70),
    Font = F.Body,
    TextSize = 13,
    TextWrapped = true,
    TextColor3 = Shell.Muted,
    Text = "Table Rush is a card/table game. Turn your phone sideways so the board, hand, and buttons fit cleanly.",
    ZIndex = 302,
}, rotateCard)

-- Bottom dock
local bottomDock = make("Frame", {
    Name = "BottomDock",
    BackgroundColor3 = Shell.Panel,
    BackgroundTransparency = 0.04,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -14),
    Size = UDim2.fromOffset(310, 52),
    ZIndex = 70,
}, root)
round(bottomDock, 18)
stroke(bottomDock, 1, Shell.Border, 0.42)
pad(bottomDock, 8, 8, 8, 8)

local playButton = make("TextButton", {
    BackgroundColor3 = Shell.Gold,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(0.58, -4, 1, 0),
    Font = F.Heading,
    TextSize = 16,
    TextColor3 = Shell.Ink,
    Text = "Play",
    ZIndex = 71,
}, bottomDock)
round(playButton, 13)

local dailyButton = make("TextButton", {
    BackgroundColor3 = Shell.Row,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0.42, -4, 1, 0),
    Font = F.Heading,
    TextSize = 15,
    TextColor3 = Shell.Text,
    Text = "Daily",
    ZIndex = 71,
}, bottomDock)
round(dailyButton, 13)
stroke(dailyButton, 1, Shell.Border, 0.45)

-- Play panel: fixed bottom landscape ticket. No child may exceed this frame.
local hub = make("Frame", {
    Name = "HubMenu",
    BackgroundColor3 = Shell.Panel,
    BackgroundTransparency = 0.015,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -82),
    Size = UDim2.fromOffset(760, 336),
    Visible = false,
    ZIndex = 50,
}, root)
round(hub, 24)
stroke(hub, 2, Shell.Border, 0.18)
pad(hub, 18, 18, 14, 14)

local hubTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -180, 0, 24),
    Font = F.Heading,
    TextSize = 20,
    TextColor3 = Shell.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Play",
    ZIndex = 51,
}, hub)

local profilePill = make("TextLabel", {
    BackgroundColor3 = Shell.Row2,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.fromOffset(170, 28),
    Font = F.Heading,
    TextSize = 12,
    TextColor3 = Shell.Gold,
    Text = "Lv 1 • 0 coins",
    ZIndex = 52,
}, hub)
round(profilePill, 10)
stroke(profilePill, 1, Shell.Border, 0.55)

local playContent = make("ScrollingFrame", {
    Name = "PlayContent",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 34),
    Size = UDim2.new(1, 0, 1, -36),
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 4,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 51,
}, hub)

local playContentLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, playContent)

pad(playContent, 2, 8, 0, 4)

-- Daily panel: fixed bottom drawer. Small rows, no giant reward blocks.
local dailyPanel = make("Frame", {
    Name = "DailyPanel",
    BackgroundColor3 = Shell.Panel,
    BackgroundTransparency = 0.015,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -82),
    Size = UDim2.fromOffset(460, 318),
    Visible = false,
    ZIndex = 80,
}, root)
round(dailyPanel, 20)
stroke(dailyPanel, 2, Shell.Border, 0.24)
pad(dailyPanel, 16, 16, 12, 12)

local dailyTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 24),
    Font = F.Heading,
    TextSize = 18,
    TextColor3 = Shell.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Daily Tasks",
    ZIndex = 81,
}, dailyPanel)

local dailySubtitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 26),
    Size = UDim2.new(1, 0, 0, 20),
    Font = F.Body,
    TextSize = 11,
    TextColor3 = Shell.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Quick quests. Simple rewards.",
    ZIndex = 81,
}, dailyPanel)

local dailyList = make("ScrollingFrame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 56),
    Size = UDim2.new(1, 0, 1, -58),
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 4,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 81,
}, dailyPanel)
local dailyLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, dailyList)

pad(dailyList, 0, 8, 0, 2)

-- Center choice panel: move choices, door choices, and equipment replacement.
local choicePanel = make("Frame", {
    Name = "ChoicePanel",
    BackgroundColor3 = Shell.Panel,
    BackgroundTransparency = 0.02,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.42),
    Size = UDim2.fromOffset(560, 220),
    Visible = false,
    ZIndex = 120,
}, root)
round(choicePanel, 20)
stroke(choicePanel, 2, Shell.Border, 0.25)
pad(choicePanel, 16, 16, 12, 12)

local choiceTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 24),
    Font = F.Heading,
    TextSize = 18,
    TextColor3 = Shell.Text,
    Text = "Choose",
    ZIndex = 121,
}, choicePanel)

local choiceRow = make("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 38),
    Size = UDim2.new(1, 0, 1, -42),
    ZIndex = 121,
}, choicePanel)
local choiceLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 12),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, choiceRow)

-- Animated event card popup.
local eventPopup = make("Frame", {
    Name = "EventPopup",
    BackgroundColor3 = Color3.fromRGB(238, 221, 177),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.45),
    Size = UDim2.fromOffset(260, 330),
    Visible = false,
    ZIndex = 160,
}, root)
round(eventPopup, 22)
stroke(eventPopup, 3, Shell.Gold, 0.15)
pad(eventPopup, 16, 16, 14, 14)
local eventScale = make("UIScale", {Scale = 0.92}, eventPopup)

local eventKind = make("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(54, 42, 29),
    Size = UDim2.new(1, 0, 0, 28),
    Font = F.Heading,
    TextSize = 12,
    TextColor3 = Shell.Gold,
    Text = "EVENT",
    ZIndex = 161,
}, eventPopup)
round(eventKind, 10)

local eventArt = make("Frame", {
    BackgroundColor3 = Color3.fromRGB(35, 42, 48),
    Position = UDim2.fromOffset(0, 42),
    Size = UDim2.new(1, 0, 0, 118),
    ZIndex = 161,
}, eventPopup)
round(eventArt, 14)

local eventArtText = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Font = F.Heading,
    TextSize = 30,
    TextColor3 = Shell.Gold,
    Text = "◆",
    ZIndex = 162,
}, eventArt)

local eventTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 174),
    Size = UDim2.new(1, 0, 0, 28),
    Font = F.Heading,
    TextSize = 19,
    TextColor3 = Shell.Ink,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Event",
    ZIndex = 161,
}, eventPopup)

local eventSubtitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 204),
    Size = UDim2.new(1, 0, 0, 20),
    Font = F.Heading,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(94, 70, 44),
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "",
    ZIndex = 161,
}, eventPopup)

local eventBody = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 232),
    Size = UDim2.new(1, 0, 0, 64),
    Font = F.Body,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(70, 53, 38),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Text = "",
    ZIndex = 161,
}, eventPopup)

-- Backpack UI
local backpackButton = make("TextButton", {
    Name = "BackpackButton",
    BackgroundColor3 = Shell.Row2,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.fromOffset(118, 42),
    Font = F.Heading,
    TextSize = 14,
    TextColor3 = Shell.Text,
    Text = "Backpack",
    Visible = false,
    ZIndex = 74,
}, root)
round(backpackButton, 14)
stroke(backpackButton, 1, Shell.Border, 0.38)

local backpackPanel = make("Frame", {
    Name = "BackpackPanel",
    BackgroundColor3 = Shell.Panel,
    BackgroundTransparency = 0.02,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -70),
    Size = UDim2.fromOffset(390, 330),
    Visible = false,
    ZIndex = 130,
}, root)
round(backpackPanel, 20)
stroke(backpackPanel, 2, Shell.Border, 0.25)
pad(backpackPanel, 16, 16, 12, 12)

local backpackTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 24),
    Font = F.Heading,
    TextSize = 18,
    TextColor3 = Shell.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Backpack",
    ZIndex = 131,
}, backpackPanel)

local backpackList = make("ScrollingFrame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 36),
    Size = UDim2.new(1, 0, 1, -38),
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 4,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 131,
}, backpackPanel)
local backpackLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, backpackList)
pad(backpackList, 0, 8, 0, 2)

local routeRollPanel = make("Frame", {
    Name = "RouteRollPanel",
    BackgroundColor3 = Shell.Panel,
    BackgroundTransparency = 0.04,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(360, 300),
    Visible = false,
    ZIndex = 190,
}, root)
round(routeRollPanel, 24)
stroke(routeRollPanel, 2, TeamPurple, 0.20)
pad(routeRollPanel, 18, 18, 14, 14)

local routeRollTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 26),
    Font = F.Heading,
    TextSize = 19,
    TextColor3 = Shell.Text,
    Text = "Route Roll",
    ZIndex = 191,
}, routeRollPanel)

local routeRollSubtitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 28),
    Size = UDim2.new(1, 0, 0, 20),
    Font = F.Body,
    TextSize = 11,
    TextColor3 = Shell.Muted,
    Text = "Split vote: 50 / 50",
    ZIndex = 191,
}, routeRollPanel)

local routeWheel = make("Frame", {
    BackgroundColor3 = Shell.Text,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.50, 0),
    Size = UDim2.fromOffset(136, 136),
    Rotation = 0,
    ZIndex = 191,
}, routeRollPanel)
round(routeWheel, 999)
stroke(routeWheel, 4, Shell.Text, 0.35)

local routeGradient = make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Shell.Blue),
        ColorSequenceKeypoint.new(0.499, Shell.Blue),
        ColorSequenceKeypoint.new(0.5, TeamPurple),
        ColorSequenceKeypoint.new(1, TeamPurple),
    }),
    Rotation = 90,
}, routeWheel)

local routeNeedle = make("TextLabel", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.22, 0),
    Size = UDim2.fromOffset(42, 42),
    Font = F.Heading,
    TextSize = 31,
    TextColor3 = Shell.Text,
    Text = "▼",
    ZIndex = 193,
}, routeRollPanel)

local routeRollText = make("TextLabel", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -16),
    Size = UDim2.new(1, -30, 0, 46),
    Font = F.Heading,
    TextSize = 12,
    TextColor3 = Shell.Muted,
    TextWrapped = true,
    Text = "Blue = your route. Purple = teammate route.",
    ZIndex = 191,
}, routeRollPanel)


local dangerFlash = make("Frame", {
    Name = "DangerFlash",
    BackgroundColor3 = Color3.fromRGB(190, 35, 35),
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 250,
}, root)

local roomSound = make("Sound", {
    Name = "RoomSound",
    Volume = 0.28,
    Looped = true,
}, gui)

local eventSound = make("Sound", {
    Name = "EventSound",
    Volume = 0.65,
    Looped = false,
}, gui)


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
    Position = UDim2.new(0.5, 0, 1, -92),
    Size = UDim2.fromOffset(960, 270),
    Visible = false,
    ClipsDescendants = false,
    ZIndex = 35,
}, root)

local actionScroll = make("ScrollingFrame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 22),
    Size = UDim2.new(1, 0, 1, -30),
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X,
    ScrollBarThickness = 4,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    ZIndex = 36,
}, actionLayer)
pad(actionScroll, 14, 14, 10, 10)

local actionLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 12),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, actionScroll)

local ticker = make("TextLabel", {
    Name = "Ticker",
    BackgroundColor3 = Shell.Panel,
    BackgroundTransparency = 0.04,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -286),
    Size = UDim2.fromOffset(760, 56),
    Font = F.Heading,
    TextSize = 14,
    TextColor3 = Shell.Text,
    Text = "",
    Visible = false,
    ZIndex = 45,
}, root)
round(ticker, 14)
stroke(ticker, 1, Shell.Border, 0.45)

local toast = make("TextLabel", {
    BackgroundColor3 = Shell.Panel,
    BackgroundTransparency = 0.04,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 70),
    Size = UDim2.fromOffset(440, 40),
    Font = F.Heading,
    TextSize = 14,
    TextColor3 = Shell.Text,
    Text = "",
    Visible = false,
    ZIndex = 100,
}, root)
round(toast, 14)
stroke(toast, 1, Shell.Border, 0.45)

local renderFolder = Instance.new("Folder")
renderFolder.Name = "ClientDungeonBoardRender"
renderFolder.Parent = workspace

local function findClickableAncestor(instance)
    local node = instance
    while node and node ~= renderFolder do
        if node:GetAttribute("TableRushClickable") == true then
            return node
        end
        node = node.Parent
    end
    return nil
end

local function handleTableInput(screenPosition)
    if state.layout == "PortraitBlocked" or state.dailyOpen or hub.Visible or state.backpackOpen then
        return
    end
    if state.activeGame ~= Constants.GAME_KEYS.DungeonDoors or not state.fakeState then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {renderFolder}
    params.IgnoreWater = true

    local result = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
    if not result or not result.Instance then return end

    local clickable = findClickableAncestor(result.Instance)
    if not clickable then return end

    local kind = clickable:GetAttribute("TableRushClickKind")
    local id = clickable:GetAttribute("TableRushClickId")
    if kind and id then
        tableClickRemote:FireServer({Kind = kind, Id = id})
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        handleTableInput(input.Position)
    end
end)

local function showToast(message)
    toast.Text = tostring(message or "")
    toast.Visible = true
    toast.TextTransparency = 0
    toast.BackgroundTransparency = 0.04
    task.delay(2.1, function()
        -- v0.8.2 removed text transparency flash
        task.wait(0.3)
        toast.BackgroundTransparency = 0.04
        toast.Visible = false
    end)
end

local function showTicker(message)
    if not message or message == "" then return end
    ticker.Text = tostring(message)
    ticker.Visible = true
    ticker.TextTransparency = 0
    ticker.BackgroundTransparency = 0.04
    task.delay(2.4, function()
        if ticker.Text == tostring(message) then
            -- v0.8.2 removed text transparency flash
            task.wait(0.3)
            ticker.Visible = false
            ticker.TextTransparency = 0
            ticker.BackgroundTransparency = 0.04
        end
    end)
end

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
    local bgui = Instance.new("BillboardGui")
    bgui.Name = "Label"
    bgui.Size = size or UDim2.fromOffset(160, 44)
    bgui.StudsOffset = offset or Vector3.new(0, 2, 0)
    bgui.AlwaysOnTop = true
    bgui.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = F.Heading
    label.TextScaled = true
    label.TextColor3 = color or Shell.Text
    label.TextStrokeTransparency = 0.45
    label.Text = text
    label.Parent = bgui
end

local function doorColor(doorType)
    if doorType == Constants.DOOR_TYPES.Treasure then return Shell.Gold end
    if doorType == Constants.DOOR_TYPES.Danger then return C.Red end
    if doorType == Constants.DOOR_TYPES.Shop then return C.Green end
    if doorType == Constants.DOOR_TYPES.Curse then return C.Purple end
    if doorType == Constants.DOOR_TYPES.Portal then return C.Blue end
    if doorType == Constants.DOOR_TYPES.Boss then return Color3.fromRGB(28, 27, 31) end
    if doorType == Constants.DOOR_TYPES.Locked then return Color3.fromRGB(40, 48, 58) end
    return Color3.fromRGB(126, 78, 42)
end

local zoneOffsets = {
    Front = Vector3.new(-3.6, 0, 0),
    Center = Vector3.new(0, 0, 0),
    Back = Vector3.new(3.6, 0, 0),
}

local function renderDungeonBoard3D(fake)
    renderFolder:ClearAllChildren()

    local map = workspace:FindFirstChild("TableRushMap") or workspace:FindFirstChild("TableRushHall")
    local tableModel = map and map:FindFirstChild("DungeonDoorsTable")
    local top = tableModel and tableModel:FindFirstChild("Top")
    if not top then
        return
    end

    local base = top.CFrame * CFrame.new(0, 0.74, 0)
    local boardBase = part(renderFolder, "BoardBase", Vector3.new(14.6, 0.28, 8.4), base, Color3.fromRGB(48, 55, 62), Enum.Material.Slate)
    billboard(boardBase, fake.CurrentRoom.Name, UDim2.fromOffset(220, 46), Vector3.new(0, 1.15, -3.7), Shell.Gold)

    if fake.Board and fake.Board.Tiles then
        local atmosphere = fake.Board.Atmosphere or {}
        local function rgb(t, fallback)
            if type(t) == "table" then
                return Color3.fromRGB(t[1] or fallback.R * 255, t[2] or fallback.G * 255, t[3] or fallback.B * 255)
            end
            return fallback
        end

        local tableColor = rgb(atmosphere.TableColor, Color3.fromRGB(48, 55, 62))
        local glowColor = rgb(atmosphere.Glow, Shell.Blue)
        boardBase.Color = tableColor
        boardBase.Material = Enum.Material[atmosphere.Material or "Slate"] or Enum.Material.Slate

        local glow = part(renderFolder, "RoomGlow", Vector3.new(15.2, 0.08, 8.9), base * CFrame.new(0, 0.38, 0), glowColor, Enum.Material.Neon)
        glow.Transparency = 0.78
        glow.CanCollide = false

        -- Room ambience is intentionally silent until curated loop assets are added.

        local function tileColor(tile, clickable)
            local baseTheme = tableColor:Lerp(glowColor, 0.24)

            if clickable then
                return glowColor:Lerp(Color3.fromRGB(255, 255, 255), 0.14)
            end
            if not tile.Revealed then
                return tableColor:Lerp(glowColor, 0.34)
            end
            if tile.Kind == "Enemy" and not tile.Cleared then
                return Color3.fromRGB(170, 70, 84):Lerp(glowColor, 0.12)
            end
            if tile.Kind == "Trap" and not tile.Cleared then
                return Color3.fromRGB(170, 68, 72):Lerp(tableColor, 0.18)
            end
            if tile.Kind == "Treasure" and not tile.Cleared then
                return tableColor:Lerp(Color3.fromRGB(180, 134, 72), 0.30):Lerp(glowColor, 0.08)
            end
            if tile.Kind == "Discovery" and not tile.Cleared then
                return tableColor:Lerp(glowColor, 0.42)
            end
            if tile.Kind == "Exit" then
                return tableColor:Lerp(glowColor, 0.40)
            end
            if tile.Kind == "Start" then
                return tableColor:Lerp(glowColor, 0.30)
            end

            return baseTheme
        end

        local clickableTileIds = {}
        if fake.MoveOptions then
            for _, option in ipairs(fake.MoveOptions) do
                clickableTileIds[option.Id] = true
            end
        end

        local clickableDoorIds = {}
        if fake.DoorOptions then
            for _, door in ipairs(fake.DoorOptions) do
                clickableDoorIds[door.Id] = true
            end
        end

        local function makeTileShapeParts(tile, x, z, clickable, baseColor, material, w, d, rot)
            local shape = tile.Layout and tile.Layout.Shape or "square"
            local parts = {}
            local orthoRot = ((math.floor(((rot or 0) + 45) / 90) % 4) * 90)

            local function addShapePart(name, sx, sz, ox, oz, color, partMaterial, trans)
                local p = part(renderFolder, name, Vector3.new(sx, clickable and 0.24 or 0.17, sz), base * CFrame.new(x + ox, 0.22, z + oz), color, partMaterial)
                p.CFrame = p.CFrame * CFrame.Angles(0, math.rad(orthoRot), 0)
                p.CanCollide = false
                p.Transparency = trans or 0
                table.insert(parts, p)
                return p
            end

            addShapePart("Tile_" .. tile.Id .. "_Main", w, d, 0, 0, baseColor, material, 0)

            -- Inset inner room panel: slightly darker, gives each tile a nicer layered room-within-room look.
            local insetW = math.max(0.72, w - 0.34)
            local insetD = math.max(0.54, d - 0.28)
            local insetColor = baseColor:Lerp(tableColor, 0.18)
            local inset = part(renderFolder, "Tile_" .. tile.Id .. "_Inset", Vector3.new(insetW, clickable and 0.08 or 0.06, insetD), base * CFrame.new(x, clickable and 0.27 or 0.205, z), insetColor, Enum.Material.SmoothPlastic)
            inset.CFrame = inset.CFrame * CFrame.Angles(0, math.rad(orthoRot), 0)
            inset.CanCollide = false
            inset.Transparency = clickable and 0.02 or 0.04
            table.insert(parts, inset)

            if shape == "lshape" then
                addShapePart("Tile_" .. tile.Id .. "_L", math.max(0.62, w * 0.36), math.max(0.50, d * 0.46), (w * 0.22), (d * 0.25), baseColor:Lerp(glowColor, 0.06), material, 0.02)
            elseif shape == "split" then
                addShapePart("Tile_" .. tile.Id .. "_SplitA", math.max(0.58, w * 0.26), d * 0.72, -(w * 0.27), 0, baseColor:Lerp(tableColor, 0.08), material, 0.04)
                addShapePart("Tile_" .. tile.Id .. "_SplitB", math.max(0.58, w * 0.26), d * 0.72, (w * 0.27), 0, baseColor:Lerp(glowColor, 0.05), material, 0.04)
            elseif shape == "alcove" then
                addShapePart("Tile_" .. tile.Id .. "_Alcove", w * 0.34, d * 0.42, 0, -(d * 0.31), baseColor:Lerp(glowColor, 0.06), material, 0.03)
            end

            return parts
        end

        local function markClickableOn(parts, kind, id)
            for _, p in ipairs(parts) do
                p:SetAttribute("TableRushClickable", true)
                p:SetAttribute("TableRushClickKind", kind)
                p:SetAttribute("TableRushClickId", id)
            end
        end

        local function decorOffset(tile, slot)
            local seed = tile.Layout and tile.Layout.DecorSeed or 0
            local positions = {
                Vector3.new(0.76, 0, 0.50),
                Vector3.new(-0.76, 0, 0.50),
                Vector3.new(0.76, 0, -0.50),
                Vector3.new(-0.76, 0, -0.50),
                Vector3.new(0, 0, 0.68),
                Vector3.new(0, 0, -0.68),
            }
            return positions[((seed + slot) % #positions) + 1]
        end

        local function decorRotation(tile, slot)
            local seed = tile.Layout and tile.Layout.DecorSeed or 0
            local rots = {0, 90, 180, 270}
            return rots[((seed + slot) % #rots) + 1]
        end

        local function themedPropColor(color, material)
            local themeBase = tableColor:Lerp(glowColor, 0.30)

            -- Keep intentional gameplay accents readable.
            if material == Enum.Material.Neon then
                return color:Lerp(glowColor, 0.18)
            end
            if color == Shell.Gold then
                return color:Lerp(themeBase, 0.08)
            end

            local danger = Color3.fromRGB(215, 70, 60)
            local redDistance = math.abs(color.R - danger.R) + math.abs(color.G - danger.G) + math.abs(color.B - danger.B)
            if redDistance < 0.65 then
                return color:Lerp(themeBase, 0.18)
            end

            -- Normal clutter/floor chunks are mostly theme-tinted so they do not look like random gray slabs.
            return themeBase:Lerp(color, 0.10)
        end


        local function safeDecorPart(tile, name, size, x, z, offset, color, material, y, slot)
            local finalMaterial = material or Enum.Material.SmoothPlastic
            local finalColor = themedPropColor(color, finalMaterial)
            local p = part(renderFolder, name, size, base * CFrame.new(x + offset.X, y or 0.72, z + offset.Z), finalColor, finalMaterial)
            p.CanCollide = false
            p.CFrame = p.CFrame * CFrame.Angles(0, math.rad(decorRotation(tile, slot or 1)), 0)
            return p
        end

        local function addProfileDecor(tile, x, z, w, d, glowColor)
            if not tile.Revealed then return end
            local profile = tile.Layout and tile.Layout.DecorProfile or "stone_clutter"
            local seed = tile.Layout and tile.Layout.DecorSeed or 0
            local count = 1 + (seed % 3)

            local function add(slot, size, color, material, y)
                safeDecorPart(tile, "TileProfile_" .. tile.Id .. "_" .. tostring(slot), size, x, z, decorOffset(tile, slot), color, material, y or 0.66, slot)
            end

            if profile == "candle_ruin" then
                add(1, Vector3.new(0.16, 0.42, 0.16), Color3.fromRGB(34, 29, 42), Enum.Material.Slate, 0.86)
                add(2, Vector3.new(0.16, 0.16, 0.16), Color3.fromRGB(164, 94, 232), Enum.Material.Neon, 1.12)
                if count >= 2 then add(3, Vector3.new(0.52, 0.08, 0.24), Color3.fromRGB(38, 34, 42), Enum.Material.Slate, 0.65) end
            elseif profile == "mist_stones" then
                add(1, Vector3.new(0.70, 0.07, 0.36), tableColor:Lerp(glowColor, 0.40), Enum.Material.SmoothPlastic, 0.66)
                if count >= 2 then add(2, Vector3.new(0.32, 0.18, 0.28), tableColor:Lerp(glowColor, 0.22), Enum.Material.SmoothPlastic, 0.69) end
            elseif profile == "web_crates" then
                add(1, Vector3.new(0.72, 0.04, 0.72), tableColor:Lerp(glowColor, 0.40), Enum.Material.SmoothPlastic, 0.66)
                if count >= 2 then add(2, Vector3.new(0.42, 0.28, 0.36), Color3.fromRGB(68, 48, 36), Enum.Material.Wood, 0.74) end
            elseif profile == "spikes_plate" then
                for s = 1, count do add(s, Vector3.new(0.14, 0.26, 0.14), Color3.fromRGB(215, 70, 60), Enum.Material.Metal, 0.80) end
            elseif profile == "coin_crates" then
                add(1, Vector3.new(0.40, 0.08, 0.40), Shell.Gold, Enum.Material.Metal, 0.68)
                if count >= 2 then add(2, Vector3.new(0.48, 0.30, 0.40), Color3.fromRGB(86, 52, 30), Enum.Material.Wood, 0.75) end
                if count >= 3 then add(3, Vector3.new(0.24, 0.06, 0.24), Shell.Gold, Enum.Material.Metal, 0.70) end
            elseif profile == "chain_blocks" then
                add(1, Vector3.new(0.72, 0.10, 0.18), Color3.fromRGB(128, 128, 138), Enum.Material.Metal, 0.72)
                if count >= 2 then add(2, Vector3.new(0.18, 0.46, 0.18), Color3.fromRGB(72, 72, 82), Enum.Material.Metal, 0.84) end
            elseif profile == "water_stones" then
                add(1, Vector3.new(0.82, 0.05, 0.46), tableColor:Lerp(glowColor, 0.36), Enum.Material.SmoothPlastic, 0.65)
                if count >= 2 then add(2, Vector3.new(0.34, 0.16, 0.28), tableColor:Lerp(glowColor, 0.24), Enum.Material.SmoothPlastic, 0.70) end
            elseif profile == "mushroom_blocks" then
                add(1, Vector3.new(0.22, 0.30, 0.22), Color3.fromRGB(82, 190, 92), Enum.Material.Grass, 0.80)
                if count >= 2 then add(2, Vector3.new(0.34, 0.14, 0.34), Color3.fromRGB(46, 72, 46), Enum.Material.Grass, 0.68) end
            elseif profile == "ember_blocks" then
                add(1, Vector3.new(0.62, 0.08, 0.36), Color3.fromRGB(235, 108, 54), Enum.Material.Neon, 0.66)
                if count >= 2 then add(2, Vector3.new(0.32, 0.20, 0.28), Color3.fromRGB(68, 34, 22), Enum.Material.Basalt, 0.72) end
            elseif profile == "bone_slabs" then
                add(1, Vector3.new(0.58, 0.08, 0.18), Color3.fromRGB(190, 184, 166), Enum.Material.Slate, 0.68)
                if count >= 2 then add(2, Vector3.new(0.26, 0.12, 0.18), Color3.fromRGB(148, 144, 130), Enum.Material.Slate, 0.70) end
            elseif profile == "rune_stones" then
                add(1, Vector3.new(0.58, 0.08, 0.58), glowColor, Enum.Material.Neon, 0.68)
                if count >= 2 then add(2, Vector3.new(0.22, 0.34, 0.22), tableColor:Lerp(glowColor, 0.28), Enum.Material.SmoothPlastic, 0.84) end
            elseif profile == "metal_crates" then
                add(1, Vector3.new(0.52, 0.28, 0.38), Color3.fromRGB(98, 104, 112), Enum.Material.Metal, 0.74)
                if count >= 2 then add(2, Vector3.new(0.66, 0.10, 0.20), Color3.fromRGB(148, 148, 158), Enum.Material.Metal, 0.74) end
            elseif profile == "vault_blocks" then
                add(1, Vector3.new(0.70, 0.34, 0.26), Color3.fromRGB(82, 66, 60), Enum.Material.Granite, 0.78)
                add(2, Vector3.new(0.62, 0.08, 0.32), Color3.fromRGB(215, 70, 60), Enum.Material.Neon, 0.96)
                if count >= 3 then add(3, Vector3.new(0.24, 0.44, 0.24), Color3.fromRGB(46, 38, 40), Enum.Material.Metal, 0.86) end
            elseif profile == "holy_cache" then
                add(1, Vector3.new(0.56, 0.10, 0.56), Color3.fromRGB(245, 230, 170), Enum.Material.Neon, 0.68)
                if count >= 2 then add(2, Vector3.new(0.34, 0.26, 0.34), Color3.fromRGB(92, 90, 72), Enum.Material.Marble, 0.76) end
            elseif profile == "broken_floor" then
                add(1, Vector3.new(0.78, 0.05, 0.28), Color3.fromRGB(70, 58, 42), Enum.Material.WoodPlanks, 0.66)
                if count >= 2 then add(2, Vector3.new(0.42, 0.08, 0.26), Color3.fromRGB(50, 42, 34), Enum.Material.Wood, 0.67) end
            else
                for s = 1, count do add(s, (s == 1) and Vector3.new(0.28, 0.12, 0.34) or Vector3.new(0.36, 0.10, 0.20), tableColor:Lerp(glowColor, 0.18), Enum.Material.SmoothPlastic, 0.66) end
            end
        end


        local tileById = {}
        for _, t in ipairs(fake.Board.Tiles) do
            tileById[t.Id] = t
        end

        local function connectionAlpha(a, b)
            if not a or not b then return nil end

            -- Always preview real neighbor connections because hidden rooms are already visible.
            -- Stronger when both sides are revealed, medium when one side is reachable/clickable,
            -- softer when it is just an undiscovered hallway preview.
            if a.Revealed and b.Revealed then return 0 end
            if (a.Revealed and clickableTileIds[b.Id]) or (b.Revealed and clickableTileIds[a.Id]) then return 0 end
            if a.Revealed or b.Revealed then return 0 end
            return 0
        end

        local function shouldShowConnection(a, b)
            return connectionAlpha(a, b) ~= nil
        end

        local drawnConnections = {}
        for _, a in ipairs(fake.Board.Tiles) do
            for _, bid in ipairs(a.Neighbors or {}) do
                local b = tileById[bid]
                if b then
                    local key = tostring(a.Id) < tostring(b.Id) and (tostring(a.Id) .. "_" .. tostring(b.Id)) or (tostring(b.Id) .. "_" .. tostring(a.Id))
                    local alpha = connectionAlpha(a, b)
                    if not drawnConnections[key] and alpha ~= nil then
                        drawnConnections[key] = true
                        local ax = (a.X or 0) * 2.95 - 4.45
                        local az = (a.Y or 0) * 2.18
                        local bx = (b.X or 0) * 2.95 - 4.45
                        local bz = (b.Y or 0) * 2.18
                        local corridorColor = tableColor:Lerp(glowColor, 0.52)

                        if math.abs(ax - bx) < 0.05 or math.abs(az - bz) < 0.05 then
                            local cx = (ax + bx) / 2
                            local cz = (az + bz) / 2
                            local sx = math.max(0.28, math.abs(ax - bx))
                            local sz = math.max(0.28, math.abs(az - bz))
                            local c = part(renderFolder, "Corridor_" .. key, Vector3.new(sx + 0.36, 0.055, sz + 0.36), base * CFrame.new(cx, 0.16, cz), corridorColor, Enum.Material.SmoothPlastic)
                            c.Transparency = 0
                            c.CanCollide = false
                        else
                            local midX = bx
                            local midZ = az
                            local c1 = part(renderFolder, "CorridorA_" .. key, Vector3.new(math.max(0.28, math.abs(ax - midX)) + 0.36, 0.055, 0.32), base * CFrame.new((ax + midX) / 2, 0.16, az), corridorColor, Enum.Material.SmoothPlastic)
                            c1.Transparency = 0
                            c1.CanCollide = false
                            local c2 = part(renderFolder, "CorridorB_" .. key, Vector3.new(0.32, 0.055, math.max(0.28, math.abs(az - bz)) + 0.36), base * CFrame.new(bx, 0.16, (az + bz) / 2), corridorColor, Enum.Material.SmoothPlastic)
                            c2.Transparency = 0
                            c2.CanCollide = false
                        end
                    end
                end
            end
        end

        for _, tile in ipairs(fake.Board.Tiles) do
            local x = (tile.X or 0) * 2.95 - 4.45
            local z = (tile.Y or 0) * 2.18
            local layout = tile.Layout or {}
            local w = math.clamp(layout.W or 2.0, 1.35, 2.42)
            local d = math.clamp(layout.D or 1.35, 0.95, 1.78)
            local rot = ((math.floor(((layout.Rot or 0) + 45) / 90) % 4) * 90)
            local clickable = clickableTileIds[tile.Id] == true
            local material = clickable and Enum.Material.Neon or Enum.Material.SmoothPlastic

            local baseColor = tileColor(tile, clickable)
            local tileParts = makeTileShapeParts(tile, x, z, clickable, baseColor, material, w, d, rot)
            local labelBase = tileParts[1]
            local labelText = tile.Revealed and tile.Label or "?"
            local labelYOffset = tile.Revealed and (0.72 + (((tile.X or 0) + math.abs(tile.Y or 0)) % 2) * 0.18) or 0.58
            local labelSize = tile.Revealed and UDim2.fromOffset(100, 26) or UDim2.fromOffset(44, 24)
            local labelColor = tile.Kind == "Treasure" and Color3.fromRGB(255, 226, 150) or Shell.Text
            billboard(labelBase, labelText, labelSize, Vector3.new(0, labelYOffset, 0), labelColor)

            if clickable then
                markClickableOn(tileParts, "Tile", tile.Id)

                local ringParts = makeTileShapeParts(tile, x, z, true, glowColor, Enum.Material.Neon, w + 0.16, d + 0.16, rot)
                for _, ring in ipairs(ringParts) do
                    ring.Name = "TileGlow_" .. tile.Id
                    ring.Transparency = 0.66
                    ring.CanCollide = false
                    ring:SetAttribute("TableRushClickable", true)
                    ring:SetAttribute("TableRushClickKind", "Tile")
                    ring:SetAttribute("TableRushClickId", tile.Id)
                end

                local pad = part(renderFolder, "TileClickPad_" .. tile.Id, Vector3.new(w + 0.75, 0.08, d + 0.75), base * CFrame.new(x, 0.56, z), tableColor:Lerp(glowColor, 0.30), Enum.Material.SmoothPlastic)
                pad.Transparency = 1
                pad.CanCollide = false
                pad.CFrame = pad.CFrame * CFrame.Angles(0, math.rad(rot), 0)
                pad:SetAttribute("TableRushClickable", true)
                pad:SetAttribute("TableRushClickKind", "Tile")
                pad:SetAttribute("TableRushClickId", tile.Id)
            end

            if fake.PlayerTile == tile.Id then
                local token = part(renderFolder, "PlayerToken", Vector3.new(0.65, 0.5, 0.65), base * CFrame.new(x - 0.30, 0.62, z - 0.14), Shell.Blue, Enum.Material.SmoothPlastic)
                token.Shape = Enum.PartType.Ball
                billboard(token, "P1", UDim2.fromOffset(42, 20), Vector3.new(0, 1.02, 0), Shell.Text)
            end

            if fake.PartnerTile == tile.Id then
                local token2 = part(renderFolder, "PartnerToken", Vector3.new(0.65, 0.5, 0.65), base * CFrame.new(x + 0.30, 0.62, z + 0.14), TeamPurple, Enum.Material.SmoothPlastic)
                token2.Shape = Enum.PartType.Ball
                billboard(token2, "P2", UDim2.fromOffset(42, 20), Vector3.new(0, 1.02, 0), Shell.Text)
            end

            if tile.Kind == "Enemy" and not tile.Cleared and tile.Revealed then
                local enemy = part(renderFolder, "Enemy_" .. tile.Id, Vector3.new(0.78, 0.7, 0.78), base * CFrame.new(x, 0.7, z + 0.48), Color3.fromRGB(200, 80, 70), Enum.Material.Neon)
                enemy.Shape = Enum.PartType.Ball
                billboard(enemy, tostring(tile.HP or 1) .. " HP", UDim2.fromOffset(72, 24), Vector3.new(0, 0.9, 0), Shell.Text)
            end

            -- Decorations stay around edges/corners so they do not clip P1/P2 token positions.
            if tile.Revealed then
                addProfileDecor(tile, x, z, w, d, glowColor)

                if tile.Kind == "Treasure" and not tile.Cleared then
                    local off = decorOffset(tile, 1)
                    safeDecorPart(tile, "TileChest_" .. tile.Id, Vector3.new(0.54, 0.28, 0.36), x, z, off, Color3.fromRGB(94, 56, 34), Enum.Material.Wood, 0.74, 1)
                    safeDecorPart(tile, "TileChestBand_" .. tile.Id, Vector3.new(0.60, 0.07, 0.40), x, z, off, Shell.Gold, Enum.Material.Metal, 0.92, 2)
                elseif tile.Kind == "Trap" and not tile.Cleared then
                    for s = 1, 3 do
                        local off = decorOffset(tile, s)
                        safeDecorPart(tile, "TileSpike_" .. tile.Id .. "_" .. tostring(s), Vector3.new(0.11, 0.24, 0.11), x, z, off, Color3.fromRGB(215, 70, 60), Enum.Material.Metal, 0.80, s)
                    end
                elseif tile.Kind == "Discovery" and not tile.Cleared then
                    local off = decorOffset(tile, 2)
                    local marker = safeDecorPart(tile, "TileRune_" .. tile.Id, Vector3.new(0.52, 0.08, 0.52), x, z, off, glowColor, Enum.Material.Neon, 0.70, 2)
                    marker.Transparency = 0.24
                    safeDecorPart(tile, "TileRunePost_" .. tile.Id, Vector3.new(0.14, 0.34, 0.14), x, z, off + Vector3.new(0.18, 0, 0.18), tableColor:Lerp(glowColor, 0.28), Enum.Material.SmoothPlastic, 0.88, 3)
                elseif tile.Kind == "Exit" and fake.Board.Theme == "Boss" then
                    -- End vault exception: final room can look special.
                    local off = Vector3.new(0, 0, d * 0.34)
                    safeDecorPart(tile, "TileFinalVault_" .. tile.Id, Vector3.new(1.10, 0.42, 0.28), x, z, off, Color3.fromRGB(54, 42, 46), Enum.Material.Metal, 0.86, 1)
                    safeDecorPart(tile, "TileFinalVaultGlow_" .. tile.Id, Vector3.new(0.92, 0.08, 0.32), x, z, off + Vector3.new(0, 0, 0.18), Color3.fromRGB(215, 70, 60), Enum.Material.Neon, 1.12, 2)
                end


            else
                local fog = part(renderFolder, "TileFog_" .. tile.Id, Vector3.new(math.max(1.1, w * 0.62), 0.07, math.max(0.70, d * 0.55)), base * CFrame.new(x, 0.62, z), tableColor:Lerp(glowColor, 0.30), Enum.Material.SmoothPlastic)
                fog.Transparency = 0.58
                fog.CanCollide = false
                fog.CFrame = fog.CFrame * CFrame.Angles(0, math.rad(rot), 0)
            end
        end
        -- Door markers become clickable on the actual table when an exit is reached.
        for i, door in ipairs(fake.Board.Doors or {}) do
            local dx = -2 + ((i - 1) * 2.2)
            local dz = 3.9
            local clickable = clickableDoorIds[door.Id] == true
            local doorPart = part(renderFolder, "TableDoor_" .. door.Id, Vector3.new(1.55, 0.35, 0.9), base * CFrame.new(dx, 0.55, dz), clickable and glowColor or Color3.fromRGB(75, 58, 44), clickable and Enum.Material.Neon or Enum.Material.Wood)
            doorPart.CanCollide = false
            billboard(doorPart, door.Icon or "↑", UDim2.fromOffset(60, 34), Vector3.new(0, 0.75, 0), clickable and Shell.Text or Shell.Muted)
            -- Route choice is handled by the UI vote panel, not physical arrow/door blocks.
        end

        -- Tiny atmosphere props: cheap primitives, better room vibe than bare cubes.
        local props = fake.Board.Props or {}
        for i, propName in ipairs(props) do
            local px = -6.3 + (i - 1) * 1.15
            local pz = -3.75
            local color = glowColor
            local mat = Enum.Material.Neon
            local size = Vector3.new(0.35, 0.55, 0.35)
            if propName == "Chests" or propName == "Crates" then
                color = Color3.fromRGB(94, 64, 40)
                mat = Enum.Material.Wood
                size = Vector3.new(0.55, 0.45, 0.45)
            elseif propName == "Chains" or propName == "Locks" then
                color = Color3.fromRGB(130, 130, 138)
                mat = Enum.Material.Metal
                size = Vector3.new(0.7, 0.25, 0.25)
            elseif propName == "Water" then
                color = Color3.fromRGB(30, 95, 120)
                mat = Enum.Material.Glass
                size = Vector3.new(0.9, 0.08, 0.5)
            elseif propName == "Webs" or propName == "Mist" or propName == "Smoke" or propName == "RedFog" then
                size = Vector3.new(0.95, 0.08, 0.95)
                mat = Enum.Material.ForceField
            end
            local prop = part(renderFolder, "Prop_" .. tostring(i), size, base * CFrame.new(px, 0.62, pz), color, mat)
            prop.Transparency = (propName == "Mist" or propName == "Smoke" or propName == "RedFog" or propName == "Webs") and 0.55 or 0
            prop.CanCollide = false
        end

        return
    end

    local zoneNames = {"Front", "Center", "Back"}
    for i, zone in ipairs(zoneNames) do
        local x = -4.0 + (i-1)*4.0
        local zpart = part(renderFolder, "Zone_" .. zone, Vector3.new(3.4, 0.18, 5.2), base * CFrame.new(x, 0.18, 0), Color3.fromRGB(70, 78, 84), Enum.Material.Slate)
        billboard(zpart, string.upper(zone), UDim2.fromOffset(105, 30), Vector3.new(0, 0.55, 2.25), Shell.Muted)
    end

    local entrance = part(renderFolder, "EntranceDoor", Vector3.new(1.3, 2.5, 3.2), base * CFrame.new(-7.7, 1.25, 0), Color3.fromRGB(116, 74, 42), Enum.Material.Wood)
    billboard(entrance, "IN", UDim2.fromOffset(80, 30), Vector3.new(0, 1.75, 0), Shell.Text)

    for i, door in ipairs(fake.Doors or {}) do
        local dz = (#fake.Doors == 1) and 0 or (-1.8 + (i-1)*3.6)
        local d = part(renderFolder, "Door_" .. door.Key, Vector3.new(1.35, 2.8, 2.8), base * CFrame.new(7.75, 1.4, dz), doorColor(door.Type), Enum.Material.Wood)
        billboard(d, door.Label, UDim2.fromOffset(100, 36), Vector3.new(0, 1.9, 0), door.Type == Constants.DOOR_TYPES.Treasure and Shell.Ink or Shell.Text)
    end

    for i, ps in ipairs(fake.Players or {}) do
        local offset = zoneOffsets[ps.Zone] or zoneOffsets.Front
        local z = i == 1 and -0.95 or 0.95
        local token = part(renderFolder, "PlayerToken_" .. tostring(i), Vector3.new(0.9, 0.55, 0.9), base * CFrame.new(offset.X, 0.62, z), i == 1 and Shell.Blue or Shell.Gold, Enum.Material.SmoothPlastic)
        billboard(token, i == 1 and "P1" or "P2", UDim2.fromOffset(70, 30), Vector3.new(0, 1.0, 0), Shell.Text)
    end

    for i, enemy in ipairs(fake.Enemies or {}) do
        local offset = zoneOffsets[enemy.Zone] or zoneOffsets.Center
        local z = 1.85 + (i-1)*0.3
        local enemyPart = part(renderFolder, "Enemy_" .. enemy.Id, Vector3.new(1.0, 0.75, 1.0), base * CFrame.new(offset.X, 0.72, z), Color3.fromRGB(200, 80, 70), Enum.Material.SmoothPlastic)
        billboard(enemyPart, enemy.IntentIcon .. " " .. enemy.Name .. "\nHP " .. tostring(enemy.HP) .. "/" .. tostring(enemy.MaxHP), UDim2.fromOffset(150, 54), Vector3.new(0, 1.25, 0), Shell.Text)
    end

    local chest = part(renderFolder, "SuspiciousChest", Vector3.new(1.25, 0.65, 0.9), base * CFrame.new(3.7, 0.65, -1.65), Shell.Gold, Enum.Material.SmoothPlastic)
    billboard(chest, "CHEST?", UDim2.fromOffset(100, 32), Vector3.new(0, 1.0, 0), Shell.Ink)

    local pot = part(renderFolder, "PotMarker", Vector3.new(2.2, 0.28, 1.0), base * CFrame.new(0, 0.35, -3.65), Color3.fromRGB(42, 32, 20), Enum.Material.SmoothPlastic)
    billboard(pot, "POT " .. tostring(fake.Pot) .. "\nTHREAT " .. tostring(fake.Threat), UDim2.fromOffset(150, 48), Vector3.new(0, 0.9, 0), Shell.Gold)
end

local function renderTop()
    local fake = state.fakeState
    if state.activeGame == Constants.GAME_KEYS.DungeonDoors and fake then
        topText.Text = string.format("Room %d/%d  •  Pot %s  •  Threat %d  •  %s", fake.RoomIndex, fake.RoomsToWin, Util.formatNumber(fake.Pot), fake.Threat, fake.Phase)
    else
        topText.Text = "Table Rush  •  Choose a table"
    end

    if state.profile then
        profilePill.Text = string.format("Lv %d • %s coins", state.profile.Level or 1, Util.formatNumber(state.profile.Coins or 0))
    end
end


local function makeSectionTitle(parent, text, order)
    local label = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 22),
        Font = F.Heading,
        TextSize = 13,
        TextColor3 = Shell.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        LayoutOrder = order,
        ZIndex = 52,
    }, parent)
    return label
end

local function makeTinyChip(parent, text, color, order)
    local chip = make("TextLabel", {
        BackgroundColor3 = Shell.Row2,
        Size = UDim2.fromOffset(104, 24),
        Font = F.Heading,
        TextSize = 10,
        TextColor3 = color,
        Text = text,
        LayoutOrder = order or 1,
        ZIndex = 55,
    }, parent)
    round(chip, 8)
    stroke(chip, 1, Shell.Border, 0.62)
    return chip
end

local function makeTableTicket(parent, config)
    local isMobileLandscape = state.layout == "MobileLandscape"
    local height = config.Locked and 96 or (isMobileLandscape and 142 or 126)

    local card = make("Frame", {
        BackgroundColor3 = config.Locked and Color3.fromRGB(11, 17, 25) or Shell.Panel2,
        Size = UDim2.new(1, -8, 0, height),
        LayoutOrder = config.LayoutOrder or 1,
        ZIndex = 52,
    }, parent)
    round(card, 18)
    stroke(card, 2, config.Accent or Shell.Border, config.Locked and 0.62 or 0.30)
    pad(card, 14, 14, 12, 12)

    local leftWidth = isMobileLandscape and 92 or 136
    local preview = make("Frame", {
        BackgroundColor3 = Shell.Row,
        Size = UDim2.fromOffset(leftWidth, height - 24),
        ZIndex = 53,
    }, card)
    round(preview, 14)
    stroke(preview, 1, config.Accent or Shell.Blue, 0.55)

    make("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 10),
        Size = UDim2.new(1, -14, 0, 18),
        Font = F.Heading,
        TextSize = isMobileLandscape and 11 or 12,
        TextColor3 = Shell.Text,
        Text = config.ShortLabel or "TABLE",
        ZIndex = 54,
    }, preview)

    local tileRow = make("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.54, 0),
        Size = UDim2.fromOffset(leftWidth - 24, 34),
        ZIndex = 54,
    }, preview)

    for i = 1, 3 do
        local tileSize = isMobileLandscape and 22 or 28
        local gap = isMobileLandscape and 25 or 33
        local tile = make("Frame", {
            BackgroundColor3 = (i == 2 and not config.Locked) and Shell.Gold or Color3.fromRGB(55, 70, 84),
            Position = UDim2.fromOffset((i - 1) * gap, i == 2 and 0 or 4),
            Size = UDim2.fromOffset(tileSize, tileSize),
            Rotation = (i - 2) * 4,
            ZIndex = 55,
        }, tileRow)
        round(tile, 7)
    end

    make("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -8),
        Size = UDim2.new(1, -12, 0, 16),
        Font = F.Body,
        TextSize = 9,
        TextColor3 = config.Accent or Shell.Blue,
        Text = config.PreviewText or "table",
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 54,
    }, preview)

    local right = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(leftWidth + 14, 0),
        Size = UDim2.new(1, -(leftWidth + 14), 1, 0),
        ZIndex = 53,
    }, card)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 24),
        Font = F.Heading,
        TextSize = isMobileLandscape and 17 or 20,
        TextColor3 = Shell.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = config.Title,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 54,
    }, right)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 26),
        Size = UDim2.new(1, 0, 0, 18),
        Font = F.Body,
        TextSize = isMobileLandscape and 10 or 11,
        TextColor3 = Shell.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = config.Subtitle,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 54,
    }, right)

    local chipRow = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 50),
        Size = UDim2.new(1, 0, 0, 24),
        ZIndex = 54,
    }, right)

    local chipLayout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, chipRow)

    if config.Chips then
        for i, chip in ipairs(config.Chips) do
            makeTinyChip(chipRow, chip.Text, chip.Color, i)
        end
    end

    if config.Locked then
        local locked = make("TextLabel", {
            BackgroundColor3 = Shell.Row2,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 32),
            Font = F.Heading,
            TextSize = 12,
            TextColor3 = Shell.Muted,
            Text = config.LockedText or "Coming Later",
            ZIndex = 54,
        }, right)
        round(locked, 11)
        stroke(locked, 1, Shell.Border, 0.60)
        return
    end

    local buttonRow = make("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 54,
    }, right)

    local buttonLayout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, buttonRow)

    local join = make("TextButton", {
        BackgroundColor3 = Shell.Gold,
        Size = UDim2.new(0.60, -5, 1, 0),
        Font = F.Heading,
        TextSize = isMobileLandscape and 13 or 14,
        TextColor3 = Shell.Ink,
        Text = config.PrimaryText or "Join Table",
        LayoutOrder = 1,
        ZIndex = 55,
    }, buttonRow)
    round(join, 12)

    local spectate = make("TextButton", {
        BackgroundColor3 = Shell.Row2,
        Size = UDim2.new(0.40, -5, 1, 0),
        Font = F.Heading,
        TextSize = isMobileLandscape and 12 or 13,
        TextColor3 = Shell.Text,
        Text = config.SecondaryText or "Spectate",
        LayoutOrder = 2,
        ZIndex = 55,
    }, buttonRow)
    round(spectate, 12)
    stroke(spectate, 1, Shell.Border, 0.36)

    if config.OnPrimary then
        join.Activated:Connect(config.OnPrimary)
    end

    if config.OnSecondary then
        spectate.Activated:Connect(config.OnSecondary)
    end
end

local function renderPlayPanel()
    clear(playContent)

    local gameInfo = GameCatalog.GetGame(Constants.GAME_KEYS.DungeonDoors)
    if not gameInfo then return end

    local count = 0
    for _, t in ipairs(state.tableList or {}) do
        if t.Key == Constants.GAME_KEYS.DungeonDoors then
            count = t.Count or 0
            break
        end
    end

    makeSectionTitle(playContent, "QUICK PLAY", 1)

    makeTableTicket(playContent, {
        LayoutOrder = 2,
        Title = "Dungeon Doors",
        Subtitle = "Fast match • game-made table",
        ShortLabel = "DOORS",
        PreviewText = "Room 1 test",
        Accent = Shell.Blue,
        Chips = {
            {Text = tostring(count) .. "/" .. tostring(gameInfo.MaxPlayers or 2) .. " seated", Color = Shell.Blue},
            {Text = "Dusty Entry", Color = Shell.Gold},
            {Text = "Actions", Color = Shell.Green},
        },
        PrimaryText = "Quick Play",
        SecondaryText = "Spectate",
        OnPrimary = function()
            joinRemote:FireServer(gameInfo.Key)
        end,
        OnSecondary = function()
            spectateRemote:FireServer(gameInfo.Key)
        end,
    })

    makeTableTicket(playContent, {
        LayoutOrder = 3,
        Title = "Next Table Game",
        Subtitle = "Future game-made quickplay slot",
        ShortLabel = "NEXT",
        PreviewText = "coming",
        Accent = Shell.Muted,
        Locked = true,
        LockedText = "Future quickplay game",
        Chips = {
            {Text = "coming", Color = Shell.Muted},
        },
    })

    makeSectionTitle(playContent, "FRIENDS' HOSTED TABLES", 10)

    makeTableTicket(playContent, {
        LayoutOrder = 11,
        Title = "Friends' tables",
        Subtitle = "Hosted tables from friends will appear here",
        ShortLabel = "HOST",
        PreviewText = "friends",
        Accent = Shell.Green,
        Locked = true,
        LockedText = "No friend-hosted tables yet",
        Chips = {
            {Text = "friends", Color = Shell.Green},
        },
    })

    makeSectionTitle(playContent, "OTHER HOSTED TABLES", 20)

    makeTableTicket(playContent, {
        LayoutOrder = 21,
        Title = "Public hosted tables",
        Subtitle = "Other player-hosted tables will appear here",
        ShortLabel = "OPEN",
        PreviewText = "public",
        Accent = Shell.Blue,
        Locked = true,
        LockedText = "No public hosted tables yet",
        Chips = {
            {Text = "public", Color = Shell.Blue},
        },
    })
end


local function renderHub()
    renderPlayPanel()
    hub.Visible = state.activeGame == nil and not state.dailyOpen and hub.Visible
end



local function taskTierColor(task)
    if task.Tier == "rare" then
        return TeamPurple
    elseif task.Tier == "hard" then
        return DangerRed
    elseif task.Tier == "medium" then
        return Shell.Green
    end
    return Shell.Blue
end

local function renderDaily()
    clear(dailyList)
    local tasks = state.profile and state.profile.DailyTasks or {}

    if #tasks == 0 then
        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 0, 72),
            Font = F.Body,
            TextSize = 14,
            TextColor3 = Shell.Muted,
            TextWrapped = true,
            Text = "No daily tasks loaded yet.",
            ZIndex = 82,
        }, dailyList)
        return
    end

    for i, task in ipairs(tasks) do
        local progress = tonumber(task.Progress) or 0
        local target = math.max(1, tonumber(task.Target) or 1)
        local pct = math.clamp(progress / target, 0, 1)
        local complete = pct >= 1
        local claimed = task.Claimed == true
        local tierColor = taskTierColor(task)

        local row = make("Frame", {
            BackgroundColor3 = TaskDark,
            Size = UDim2.new(1, -8, 0, 74),
            LayoutOrder = i,
            ZIndex = 82,
        }, dailyList)
        round(row, 15)
        stroke(row, 1, complete and tierColor or Shell.Border, complete and 0.20 or 0.52)

        -- Small status dot instead of a tall side bar.
        local dot = make("Frame", {
            BackgroundColor3 = claimed and Shell.Green or tierColor,
            Position = UDim2.fromOffset(12, 13),
            Size = UDim2.fromOffset(9, 9),
            ZIndex = 83,
        }, row)
        round(dot, 99)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 7),
            Size = UDim2.new(1, -142, 0, 22),
            Font = F.Heading,
            TextSize = 15,
            TextColor3 = Shell.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = task.Title or "Daily Task",
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 83,
        }, row)

        local desc = tostring(task.Description or "")
        desc = desc:gsub(" in Dungeon Doors%.", ".")
        desc = desc:gsub(" when gameplay arrives%.", ".")
        desc = desc:gsub("Use ", "")
        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 31),
            Size = UDim2.new(1, -142, 0, 17),
            Font = F.Body,
            TextSize = 12,
            TextColor3 = Shell.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = desc,
            ZIndex = 83,
        }, row)

        local barBack = make("Frame", {
            BackgroundColor3 = Color3.fromRGB(31, 47, 62),
            Position = UDim2.fromOffset(28, 55),
            Size = UDim2.new(1, -160, 0, 6),
            ZIndex = 83,
        }, row)
        round(barBack, 3)

        local barFill = make("Frame", {
            BackgroundColor3 = claimed and Shell.Green or tierColor,
            Size = UDim2.new(pct, 0, 1, 0),
            ZIndex = 84,
        }, barBack)
        round(barFill, 3)

        make("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -126, 1, -8),
            Size = UDim2.fromOffset(44, 15),
            Font = F.Heading,
            TextSize = 10,
            TextColor3 = claimed and Shell.Green or Color3.fromRGB(208, 224, 238),
            Text = tostring(progress) .. "/" .. tostring(target),
            ZIndex = 84,
        }, row)

        local claim = make("TextButton", {
            BackgroundColor3 = claimed and Color3.fromRGB(24, 52, 44) or (complete and Color3.fromRGB(36, 62, 49) or TaskButtonDark),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(104, 46),
            Font = F.Heading,
            TextSize = 12,
            TextColor3 = claimed and Shell.Green or (complete and Color3.fromRGB(220, 255, 232) or Color3.fromRGB(226, 235, 244)),
            Text = claimed and "Claimed" or (complete and "Claim\nReward" or ("+" .. tostring(task.RewardCoins or 0) .. "c\n+" .. tostring(task.RewardTickets or 0) .. " ticket")),
            AutoButtonColor = complete and not claimed,
            ZIndex = 83,
        }, row)
        round(claim, 13)
        stroke(claim, 1, claimed and Shell.Green or tierColor, complete and 0.22 or 0.50)

        claim.Activated:Connect(function()
            if complete and not claimed then
                claimDailyTaskRemote:FireServer(task.Key)
            else
                showTicker("Finish the task before claiming.")
            end
        end)
    end
end



local function eventIcon(kind)
    if kind == "Enemy" then return "!" end
    if kind == "Trap" then return "⚠" end
    if kind == "Treasure" then return "◆" end
    if kind == "Discovery" then return "✦" end
    if kind == "Door" then return "↗" end
    if kind == "Move" then return "↔" end
    if kind == "Victory" then return "★" end
    if kind == "Item" then return "▣" end
    return "◆"
end

local function showEventPopup(popup)
    if not popup or popup.Id == state.lastPopupId or popup.Kind == "Move" or popup.Kind == "Door" then
        return
    end
    state.lastPopupId = popup.Id

    eventKind.Text = string.upper(tostring(popup.Kind or "Event"))
    eventArtText.Text = eventIcon(popup.Kind)
    eventTitle.Text = tostring(popup.Title or "Event")
    eventSubtitle.Text = tostring(popup.Subtitle or "")
    eventBody.Text = tostring(popup.Body or "")

    eventPopup.Visible = true
    if popup.Kind == "Enemy" or popup.Kind == "Trap" then
        eventPopup.Rotation = -6
        eventScale.Scale = 0.72
    else
        eventPopup.Rotation = -2
        eventScale.Scale = 0.84
    end

    local soundMap = {
        Enemy = "",
        Trap = "",
        Treasure = "",
        Discovery = "",
        Combat = "",
        Item = "",
        Victory = "",
        Room = "",
        Door = "",
        Guard = "",
        Scheme = "",
    }

    -- Sound hooks intentionally disabled until curated audio assets are added.
    -- This prevents invalid asset-type warnings and removes the constant ringing/noise.

    if popup.Kind == "Enemy" or popup.Kind == "Trap" or popup.Kind == "Combat" then
        dangerFlash.BackgroundTransparency = 0.62
        TweenService:Create(dangerFlash, TweenInfo.new(0.28), {BackgroundTransparency = 1}):Play()
    end

    TweenService:Create(eventScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    TweenService:Create(eventPopup, TweenInfo.new(0.20), {Rotation = 0}):Play()

    task.delay(2.4, function()
        if state.lastPopupId == popup.Id then
            TweenService:Create(eventScale, TweenInfo.new(0.18), {Scale = 0.92}):Play()
            task.wait(0.18)
            eventPopup.Visible = false
        end
    end)
end

local function makeChoiceButton(option, order)
    local button = make("TextButton", {
        BackgroundColor3 = Shell.Row2,
        Size = UDim2.fromOffset(156, 104),
        Font = F.Heading,
        TextSize = 24,
        TextColor3 = Shell.Text,
        Text = tostring(option.Icon or "◆"),
        LayoutOrder = order,
        ZIndex = 122,
    }, choiceRow)
    round(button, 16)
    stroke(button, 1, Shell.Border, 0.32)

    make("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -8),
        Size = UDim2.new(1, -12, 0, 24),
        Font = F.Heading,
        TextSize = 12,
        TextColor3 = Shell.Text,
        Text = tostring(option.Label or option.Id or ""),
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 123,
    }, button)

    button.Activated:Connect(function()
        submitChoiceRemote:FireServer(option.Id)
    end)
end

local function renderChoicePanel()
    clear(choiceRow)

    local fake = state.fakeState
    if not fake or state.dailyOpen or hub.Visible or state.backpackOpen or fake.RouteWheel or fake.PendingRouteChoice then
        choicePanel.Visible = false
        return
    end

    if fake.PendingEquip then
        choicePanel.Visible = true
        choiceTitle.Text = "Equip " .. tostring(fake.PendingEquip.NewName or "item") .. "?"
        makeChoiceButton({Id = "equip", Icon = "✓", Label = "Equip"}, 1)
        makeChoiceButton({Id = "keep", Icon = "×", Label = "Keep Old"}, 2)
        return
    end

    if fake.DoorOptions and #fake.DoorOptions > 0 then
        choicePanel.Visible = true
        choiceTitle.Text = "Vote Next Route"
        for i, door in ipairs(fake.DoorOptions) do
            makeChoiceButton({Id = door.Id, Icon = tostring(i), Label = door.Label or door.Id}, i)
        end
        return
    end

    choicePanel.Visible = false
end

local function renderBackpack()
    clear(backpackList)
    backpackButton.Visible = state.activeGame == Constants.GAME_KEYS.DungeonDoors and not state.dailyOpen and not hub.Visible
    backpackPanel.Visible = state.backpackOpen and backpackButton.Visible

    if not backpackPanel.Visible then
        return
    end

    local pack = state.fakeState and state.fakeState.Backpack
    local items = pack and pack.Items or {}

    if #items == 0 then
        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 0, 50),
            Font = F.Body,
            TextSize = 13,
            TextColor3 = Shell.Muted,
            TextWrapped = true,
            Text = "No items yet.",
            ZIndex = 132,
        }, backpackList)
        return
    end

    for i, entry in ipairs(items) do
        local data = entry.Data or {}
        local row = make("Frame", {
            BackgroundColor3 = Shell.Row,
            Size = UDim2.new(1, -8, 0, 78),
            LayoutOrder = i,
            ZIndex = 132,
        }, backpackList)
        round(row, 14)
        stroke(row, 1, entry.Equipped and Shell.Gold or Shell.Border, entry.Equipped and 0.18 or 0.55)
        pad(row, 12, 12, 8, 8)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -112, 0, 20),
            Font = F.Heading,
            TextSize = 14,
            TextColor3 = Shell.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(data.Name or "Item") .. (entry.Equipped and "  • equipped" or ""),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 133,
        }, row)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 24),
            Size = UDim2.new(1, -112, 0, 36),
            Font = F.Body,
            TextSize = 11,
            TextColor3 = Shell.Muted,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = tostring(data.Body or ""),
            ZIndex = 133,
        }, row)

        local canEquip = data.Slot ~= nil
        local canUse = data.Type == "Consumable"
        local actionText = entry.Equipped and "Equipped" or (canEquip and "Equip" or (canUse and "Use" or "Held"))

        local action = make("TextButton", {
            BackgroundColor3 = entry.Equipped and Color3.fromRGB(28, 48, 44) or (canEquip and Shell.Gold or Shell.Row2),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(92, 40),
            Font = F.Heading,
            TextSize = 12,
            TextColor3 = canEquip and not entry.Equipped and Shell.Ink or Shell.Text,
            Text = actionText,
            AutoButtonColor = not entry.Equipped and (canEquip or canUse),
            ZIndex = 133,
        }, row)
        round(action, 12)
        stroke(action, 1, Shell.Border, 0.48)

        action.Activated:Connect(function()
            if entry.Equipped then
                showTicker("Already equipped.")
            elseif canEquip then
                backpackActionRemote:FireServer({Action = "equip", Uid = entry.Uid})
            elseif canUse then
                backpackActionRemote:FireServer({Action = "use", Uid = entry.Uid})
            else
                showTicker("That item is passive.")
            end
        end)
    end
end



local function renderRouteWheel()
    local fake = state.fakeState
    local wheelData = fake and fake.RouteWheel

    if not wheelData then
        return
    end

    local wheelId = wheelData.Id or 0
    if state.lastRouteWheelId == wheelId then
        return
    end

    state.lastRouteWheelId = wheelId
    routeRollPanel.Visible = true
    routeWheel.Rotation = 0
    routeRollTitle.Text = "Route Roll"
    routeRollSubtitle.Text = "Split vote — wheel decides first"
    routeRollText.Text = "Blue = your route. Purple = teammate route."

    local winnerIsPlayer = wheelData.Winner == wheelData.PlayerChoice
    local finalRotation = winnerIsPlayer and 1440 or 1620

    TweenService:Create(routeWheel, TweenInfo.new(1.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Rotation = finalRotation,
    }):Play()

    task.delay(1.48, function()
        if state.lastRouteWheelId == wheelId then
            routeRollText.Text = winnerIsPlayer and "Your route wins." or "Teammate route wins."
        end
    end)

    task.delay(2.7, function()
        if state.lastRouteWheelId == wheelId then
            routeRollPanel.Visible = false
        end
    end)
end

local function makePlayerMat(ps, index)
    local mobile = state.layout == "MobileLandscape"
    local compact = state.layout == "Compact"
    local v = viewport()

    local w = mobile and 150 or (compact and 170 or 220)
    local h = mobile and 58 or (compact and 110 or 168)
    local x = index == 1 and 16 or (v.X - w - 16)
    local y = mobile and 72 or (compact and 112 or 150)

    local mat = make("Frame", {
        BackgroundColor3 = Shell.Panel,
        BackgroundTransparency = 0.02,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        ZIndex = 31,
    }, playerLayer)
    round(mat, mobile and 14 or 18)
    stroke(mat, 2, index == 1 and Shell.Blue or TeamPurple, 0.25)
    pad(mat, 10, 10, 8, 8)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, mobile and 16 or 24),
        Font = F.Heading,
        TextSize = mobile and 11 or 15,
        TextColor3 = Shell.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = ps.Name,
        ZIndex = 32,
    }, mat)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, mobile and 20 or 32),
        Size = UDim2.new(1, 0, 0, mobile and 20 or 30),
        Font = F.Heading,
        TextSize = mobile and 12 or 18,
        TextColor3 = Shell.Gold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Pouch " .. tostring(ps.Pouch),
        ZIndex = 32,
    }, mat)

    if not mobile then
        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 62),
            Size = UDim2.new(1, 0, 0, 22),
            Font = F.Heading,
            TextSize = compact and 12 or 15,
            TextColor3 = Shell.Green,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Bank " .. tostring(ps.Bank) .. "  •  HP " .. tostring(ps.HP),
            ZIndex = 32,
        }, mat)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 88),
            Size = UDim2.new(1, 0, 0, 22),
            Font = F.Body,
            TextSize = compact and 10 or 12,
            TextColor3 = Shell.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Keys " .. tostring(ps.Keys) .. "  •  Light " .. tostring(ps.Light) .. "  •  " .. ps.Zone,
            ZIndex = 32,
        }, mat)
    else
        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 38),
            Size = UDim2.new(1, 0, 0, 14),
            Font = F.Body,
            TextSize = 9,
            TextColor3 = Shell.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "HP " .. tostring(ps.HP) .. " • " .. tostring(ps.Zone),
            ZIndex = 32,
        }, mat)
    end
end

local function renderPlayerMats()
    clear(playerLayer)
    if not state.activeGame or not state.fakeState or state.dailyOpen or hub.Visible or state.backpackOpen then
        return
    end

    for i, ps in ipairs(state.fakeState.Players or {}) do
        makePlayerMat(ps, i)
    end
end

local function makeActionCard(action, stateData, index, mobile)
    local w = mobile and 156 or 198
    local h = mobile and 86 or 98

    local slot = make("Frame", {
        Name = "CommandSlot_" .. tostring(action.Key or index),
        Size = UDim2.fromOffset(w + 12, h + 12),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        LayoutOrder = index or 1,
    })

    local button = make("TextButton", {
        Name = "CommandButton_" .. tostring(action.Key or index),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = action.Disabled and Color3.fromRGB(31, 34, 40) or Color3.fromRGB(18, 27, 40),
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = true,
        ZIndex = 30,
    }, slot)
    corner(button, 16)
    stroke(button, action.Disabled and Color3.fromRGB(64, 68, 76) or Color3.fromRGB(88, 112, 145), 1.5, 0.20)

    local title = make("TextLabel", {
        Name = "CommandTitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 26),
        Font = Enum.Font.GothamBold,
        TextColor3 = action.Disabled and Color3.fromRGB(150, 154, 164) or Color3.fromRGB(246, 241, 224),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = tostring(action.Title or action.Key or "Action"),
        ZIndex = 32,
    }, button)
    applyTextSafety(title, mobile and 12 or 14, 0, 0)

    local body = make("TextLabel", {
        Name = "CommandBody",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 36),
        Size = UDim2.new(1, -24, 1, -44),
        Font = Enum.Font.Gotham,
        TextColor3 = action.Disabled and Color3.fromRGB(126, 132, 144) or Color3.fromRGB(200, 211, 222),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = tostring(action.Body or action.Description or ""),
        ZIndex = 32,
    }, button)
    applyTextSafety(body, mobile and 9 or 10, 0, 0)

    local tag = make("TextLabel", {
        Name = "CommandTag",
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = action.Disabled and Color3.fromRGB(45, 48, 56) or Color3.fromRGB(43, 56, 76),
        Position = UDim2.new(1, -10, 0, 8),
        Size = UDim2.fromOffset(mobile and 54 or 64, 24),
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(232, 238, 246),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = tostring(action.Tag or "READY"),
        ZIndex = 33,
    }, button)
    corner(tag, 9)
    applyTextSafety(tag, mobile and 8 or 9, 5, 2)

    button.MouseEnter:Connect(function()
        if action.Disabled then return end
        button.BackgroundColor3 = Color3.fromRGB(24, 36, 54)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = action.Disabled and Color3.fromRGB(31, 34, 40) or Color3.fromRGB(18, 27, 40)
    end)
    button.MouseButton1Click:Connect(function()
        if action.Disabled then return end
        if submitActionRemote then
            submitActionRemote:FireServer(action.Key)
        end
    end)

    return slot
end

function renderActions(fake)
    fake = fake or state.fakeState
    clear(actionLayer)
    if not fake or not fake.ActionCards then
        actionLayer.Visible = false
        return
    end

    local v = cameraViewport()
    local mobile = v.X < 760
    actionLayer.Visible = true
    actionLayer.AnchorPoint = Vector2.new(0.5, 1)
    actionLayer.Position = UDim2.new(0.5, 0, 1, -18)
    actionLayer.Size = mobile and UDim2.fromOffset(math.min(v.X - 24, 720), 122) or UDim2.fromOffset(math.min(v.X - 80, 1040), 134)
    actionLayer.BackgroundTransparency = 1
    actionLayer.ClipsDescendants = false

    local panel = make("Frame", {
        Name = "CommandBarSafePanel",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 1),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(7, 10, 15),
        BackgroundTransparency = 0.10,
        ClipsDescendants = false,
        ZIndex = 20,
    }, actionLayer)
    corner(panel, 18)
    stroke(panel, Color3.fromRGB(70, 86, 108), 1, 0.36)
    applyContainerSafety(panel, 12, 10)

    local holder = make("Frame", {
        Name = "CommandHolder",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 8),
        Size = UDim2.new(1, -20, 1, -16),
        ClipsDescendants = false,
        ZIndex = 21,
    }, panel)

    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, mobile and 4 or 8),
    }, holder)

    for i, action in ipairs(fake.ActionCards or {}) do
        local command = makeActionCard(action, fake, i, mobile)
        command.Parent = holder
    end
end


-- ClientRenderHotfix_v084:
-- v0.8.3 accidentally called renderLayout/updateTableCamera/cameraViewport without defining them.
-- These are intentionally defensive and must never hard-crash the client.
local function cameraViewport()
    return viewport()
end

local function renderLayout()
    state.layout = layoutMode()

    local blocked = state.layout == "PortraitBlocked"
    if rotateOverlay then
        rotateOverlay.Visible = blocked
    end

    -- Keep visible UI out of portrait-blocked mode.
    if blocked then
        if topBar then topBar.Visible = false end
        if bottomDock then bottomDock.Visible = false end
        if hub then hub.Visible = false end
        if dailyPanel then dailyPanel.Visible = false end
        if actionLayer then actionLayer.Visible = false end
        if ticker then ticker.Visible = false end
        return
    end

    if topBar then topBar.Visible = true end
    if bottomDock then bottomDock.Visible = true end

    local v = viewport()
    if topBar then
        topBar.Size = UDim2.fromOffset(math.min(v.X - 24, 760), 46)
    end
end

local function updateTableCamera()
    local camera = workspace.CurrentCamera
    if not camera then return end

    if state.activeGame == Constants.GAME_KEYS.DungeonDoors and state.layout ~= "PortraitBlocked" then
        local map = workspace:FindFirstChild("TableRushMap") or workspace:FindFirstChild("TableRushHall")
        local tableModel = map and map:FindFirstChild("DungeonDoorsTable")
        local top = tableModel and tableModel:FindFirstChild("Top")

        if top then
            camera.CameraType = Enum.CameraType.Scriptable
            camera.FieldOfView = 48
            camera.CFrame = top.CFrame * CFrame.new(0, 16.5, 4.5) * CFrame.Angles(math.rad(-76), 0, 0)
            return
        end
    end

    if camera.CameraType == Enum.CameraType.Scriptable then
        camera.CameraType = Enum.CameraType.Custom
    end
end

function renderAll()
    if not renderLayout or not updateTableCamera then return end
    renderLayout()
    updateTableCamera()
    if state.layout == "PortraitBlocked" then
        renderFolder:ClearAllChildren()
        return
    end

    renderTop()
    renderHub()
    renderDaily()
    renderPlayerMats()
    renderChoicePanel()
    renderRouteWheel()
    renderBackpack()
    renderActions(state.fakeState)
    if state.fakeState and state.fakeState.EventPopup then
        showEventPopup(state.fakeState.EventPopup)
    end

    if state.activeGame == Constants.GAME_KEYS.DungeonDoors then
        renderDungeonBoard3D(state.fakeState)
    else
        renderFolder:ClearAllChildren()
    end
end

backpackButton.Activated:Connect(function()
    state.backpackOpen = not state.backpackOpen
    if state.backpackOpen then
        hub.Visible = false
        state.dailyOpen = false
        dailyPanel.Visible = false
    end
    renderAll()
end)

playButton.Activated:Connect(function()
    if state.activeGame == nil then
        state.dailyOpen = false
        state.backpackOpen = false
        dailyPanel.Visible = false
        backpackPanel.Visible = false
        hub.Visible = not hub.Visible
        renderAll()
    else
        showTicker("Already rendering a table. Gameplay starts in the test loop.")
    end
end)

dailyButton.Activated:Connect(function()
    state.dailyOpen = not state.dailyOpen
    dailyPanel.Visible = state.dailyOpen
    if state.dailyOpen then
        hub.Visible = false
        state.backpackOpen = false
        backpackPanel.Visible = false
    end
    renderAll()
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
        state.dailyOpen = false
        dailyPanel.Visible = false
        showTicker((state.fakeState and state.fakeState.LastEvent) or "Dungeon Doors table rendered.")
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


-- BoardFigureKeyboardMovementLock v0.8.3:
-- WASD now sends actual table movement through the TableClick remote.
-- E triggers the server's context action. It fights/searches/interacts depending on current tile state.
local boardMoveCooldown = 0
local function tryKeyboardBoardMove(direction)
    if not state.fakeState or not state.fakeState.MoveOptions or not state.fakeState.PlayerTile or os.clock() < boardMoveCooldown then
        return
    end
    boardMoveCooldown = os.clock() + 0.18

    local fake = state.fakeState
    local current
    local tiles = fake.Board and fake.Board.Tiles or {}
    for _, tile in ipairs(tiles) do
        if tile.Id == fake.PlayerTile then
            current = tile
            break
        end
    end
    if not current then return end

    local best, bestScore = nil, -999
    for _, option in ipairs(fake.MoveOptions or {}) do
        local target
        for _, tile in ipairs(tiles) do
            if tile.Id == option.Id then
                target = tile
                break
            end
        end
        if target then
            local dx = (target.X or 0) - (current.X or 0)
            local dy = (target.Y or 0) - (current.Y or 0)
            local score = -999
            if direction == "W" then score = -dy - math.abs(dx) * 0.35
            elseif direction == "S" then score = dy - math.abs(dx) * 0.35
            elseif direction == "A" then score = -dx - math.abs(dy) * 0.35
            elseif direction == "D" then score = dx - math.abs(dy) * 0.35 end
            if score > bestScore then
                bestScore = score
                best = option
            end
        end
    end

    if best and bestScore > 0 then
        tableClickRemote:FireServer({Kind = "Tile", Id = best.Id})
    end
end

local function contextInteract()
    if not state.fakeState or state.activeGame ~= Constants.GAME_KEYS.DungeonDoors then return end
    local fake = state.fakeState
    local current
    for _, tile in ipairs((fake.Board and fake.Board.Tiles) or {}) do
        if tile.Id == fake.PlayerTile then current = tile break end
    end
    if current and current.Kind == "Enemy" and current.Revealed and not current.Cleared and (current.HP or 0) > 0 then
        submitActionRemote:FireServer(Constants.ACTIONS.Strike)
        return
    end
    for _, action in ipairs(fake.ActionCards or {}) do
        if action.Key == Constants.ACTIONS.Interact then
            submitActionRemote:FireServer(Constants.ACTIONS.Interact)
            return
        end
    end
    for _, action in ipairs(fake.ActionCards or {}) do
        if action.Key == Constants.ACTIONS.Search then
            submitActionRemote:FireServer(Constants.ACTIONS.Search)
            return
        end
    end
    showTicker("Nothing to interact with here. Move to a usable tile or Search first.")
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if state.activeGame ~= Constants.GAME_KEYS.DungeonDoors then return end
    if input.KeyCode == Enum.KeyCode.W then tryKeyboardBoardMove("W")
    elseif input.KeyCode == Enum.KeyCode.A then tryKeyboardBoardMove("A")
    elseif input.KeyCode == Enum.KeyCode.S then tryKeyboardBoardMove("S")
    elseif input.KeyCode == Enum.KeyCode.D then tryKeyboardBoardMove("D")
    elseif input.KeyCode == Enum.KeyCode.E then contextInteract()
    end
end)


-- TickerSafety_v082: continuously enforces safe text padding for the main status ticker.
RunService.RenderStepped:Connect(function()
    if ticker and ticker:IsA("GuiObject") then
        ticker.ClipsDescendants = true
        local txt = ticker:IsA("TextLabel") and ticker or ticker:FindFirstChildWhichIsA("TextLabel", true)
        if txt then
            applyTextSafety(txt, 14, 14, 6)
            txt.TextYAlignment = Enum.TextYAlignment.Center
        end
    end
end)


-- GlobalUISafetyPass_v082:
-- Final guardrail: every TextLabel/TextButton gets padding/wrapping and stable size behavior.
local uiSafetyAccumulator = 0
RunService.RenderStepped:Connect(function(dt)
    uiSafetyAccumulator += dt
    if uiSafetyAccumulator < 0.5 then return end
    uiSafetyAccumulator = 0

    local roots = {gui}
    for _, root in ipairs(roots) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    obj.TextScaled = false
                    obj.TextWrapped = true
                    obj.TextTruncate = Enum.TextTruncate.None
                    if obj.TextSize < 10 then obj.TextSize = 10 end
                    if obj.AbsoluteSize.Y < 24 then
                        obj.Size = UDim2.new(obj.Size.X.Scale, obj.Size.X.Offset, obj.Size.Y.Scale, math.max(obj.Size.Y.Offset, 28))
                    end
                    if not obj:FindFirstChild("UIStabilityPadding") then
                        applyTextSafety(obj, obj.TextSize, 8, 4)
                    end
                elseif obj:IsA("TextButton") then
                    obj.TextScaled = false
                    obj.TextWrapped = true
                    obj.TextTruncate = Enum.TextTruncate.None
                    if obj.TextSize < 10 then obj.TextSize = 10 end
                    if obj.AbsoluteSize.Y < 34 then
                        obj.Size = UDim2.new(obj.Size.X.Scale, obj.Size.X.Offset, obj.Size.Y.Scale, math.max(obj.Size.Y.Offset, 38))
                    end
                    if not obj:FindFirstChild("UIStabilityPadding") then
                        applyTextSafety(obj, obj.TextSize, 10, 5)
                    end
                end
            end
        end
    end
end)
