local WorldBuilder = {}

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

local function sign(parent, name, text, cframe, size, color)
    local board = part(parent, name, size or Vector3.new(12, 5, 0.35), cframe, color or Color3.fromRGB(42, 30, 22), Enum.Material.Wood)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 42
    gui.Parent = board

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(246, 239, 219)
    label.Text = text
    label.Parent = gui

    return board
end

local function addPromptPart(model, name, localPos, actionText, objectText)
    local promptPart = part(model, name, Vector3.new(3.2, 1.2, 3.2), model.PrimaryPart.CFrame * CFrame.new(localPos), Color3.fromRGB(90, 170, 255), Enum.Material.Neon)
    promptPart.Transparency = 0.82
    promptPart.CanCollide = false

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = name .. "Prompt"
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = promptPart

    return promptPart, prompt
end

local function makeTable(parent, name, center, color, title, isFeatured)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    local base = part(model, "Base", Vector3.new(12, 2.8, 8), CFrame.new(center + Vector3.new(0, 1.25, 0)), Color3.fromRGB(39, 27, 19), Enum.Material.Wood)
    model.PrimaryPart = base

    part(model, "Top", Vector3.new(18, 1, 12), CFrame.new(center + Vector3.new(0, 3, 0)), color, Enum.Material.Wood)
    part(model, "BoardInset", Vector3.new(14, 0.22, 8), CFrame.new(center + Vector3.new(0, 3.62, 0)), Color3.fromRGB(60, 58, 52), Enum.Material.Slate)

    if isFeatured then
        local glow = part(model, "FeaturedGlow", Vector3.new(19, 0.12, 13), CFrame.new(center + Vector3.new(0, 3.69, 0)), Color3.fromRGB(245, 190, 72), Enum.Material.Neon)
        glow.Transparency = 0.76
    end

    sign(model, "TableSign", title, CFrame.new(center + Vector3.new(0, 6.4, -6.4)) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(12, 2.6, 0.28))

    return model
end

function WorldBuilder.Build()
    local old = workspace:FindFirstChild("TableRushMap")
    if old then old:Destroy() end
    local oldHall = workspace:FindFirstChild("TableRushHall")
    if oldHall then oldHall:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name = "TableRushMap"
    folder.Parent = workspace

    workspace.FallenPartsDestroyHeight = -100

    part(folder, "OpenFloor", Vector3.new(150, 1, 120), CFrame.new(0, -0.5, 0), Color3.fromRGB(34, 28, 24), Enum.Material.WoodPlanks)

    sign(folder, "MainTitle", "TABLE RUSH", CFrame.new(0, 10, -43), Vector3.new(26, 5.5, 0.35), Color3.fromRGB(54, 33, 22))
    sign(folder, "SubTitle", "Walk up to a table, spectate, or use Play", CFrame.new(0, 6.5, -42.9), Vector3.new(28, 2.2, 0.3), Color3.fromRGB(34, 25, 20))

    local dungeon = makeTable(folder, "DungeonDoorsTable", Vector3.new(0, 0, -8), Color3.fromRGB(83, 53, 32), "DUNGEON DOORS\nJoin or Spectate", true)
    addPromptPart(dungeon, "JoinDungeonDoors", Vector3.new(-4.8, 3.6, 0), "Join", "Dungeon Doors")
    addPromptPart(dungeon, "SpectateDungeonDoors", Vector3.new(4.8, 3.6, 0), "Spectate", "Dungeon Doors")

    makeTable(folder, "FutureTableA", Vector3.new(-34, 0, 18), Color3.fromRGB(48, 48, 56), "FUTURE TABLE\nComing Later", false)
    makeTable(folder, "FutureTableB", Vector3.new(34, 0, 18), Color3.fromRGB(48, 48, 56), "FUTURE TABLE\nComing Later", false)

    sign(folder, "JoinBoard", "JOIN BOARD\nActive tables later", CFrame.new(-44, 5.8, -24) * CFrame.Angles(0, math.rad(25), 0), Vector3.new(11, 5.2, 0.35), Color3.fromRGB(44, 31, 23))
    sign(folder, "DailyBoard", "DAILY TASKS\nUse the Daily tab for now", CFrame.new(44, 5.8, -24) * CFrame.Angles(0, math.rad(-25), 0), Vector3.new(11, 5.2, 0.35), Color3.fromRGB(44, 31, 23))
    sign(folder, "RewardChest", "REWARD CHEST\nLater", CFrame.new(44, 4.8, 8) * CFrame.Angles(0, math.rad(-65), 0), Vector3.new(10, 4, 0.35), Color3.fromRGB(38, 29, 24))
    sign(folder, "RelicShelf", "RELIC SHELF\nBoss cards later", CFrame.new(-44, 4.8, 8) * CFrame.Angles(0, math.rad(65), 0), Vector3.new(10, 4, 0.35), Color3.fromRGB(38, 29, 24))
    sign(folder, "PersonalLabel", "PERSONAL TABLE LABEL\nBuilt later, code-ready", CFrame.new(0, 4.8, 34), Vector3.new(18, 4.2, 0.35), Color3.fromRGB(54, 33, 22))

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Spawn"
    spawn.Anchored = true
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.CFrame = CFrame.new(0, 0.2, 38)
    spawn.Color = Color3.fromRGB(87, 165, 240)
    spawn.Material = Enum.Material.Neon
    spawn.Transparency = 0.35
    spawn.Parent = folder

    return folder
end

return WorldBuilder
