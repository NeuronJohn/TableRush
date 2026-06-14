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
    local promptPart = part(model, name, Vector3.new(3.2, 1.2, 3.2), model.PrimaryPart.CFrame * CFrame.new(localPos), Color3.fromRGB(90, 170, 255), Enum.Material.SmoothPlastic)
    promptPart.Transparency = 1
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

    local base = part(model, "Base", Vector3.new(12, 2.8, 8), CFrame.new(center + Vector3.new(0, 1.25, 0)), Color3.fromRGB(12, 18, 27), Enum.Material.Wood)
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


local function topLabel(partObj, text, textColor)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Top
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 56
    gui.Parent = partObj

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = textColor or Color3.fromRGB(42, 32, 24)
    label.Text = text
    label.Parent = gui
end

local function addDungeonTablePolish(parent, tableModel)
    local top = tableModel and tableModel:FindFirstChild("Top")
    if not top then return end

    local function detail(name, size, offset, color, material, transparency)
        local p = part(parent, name, size, top.CFrame * offset, color, material or Enum.Material.SmoothPlastic)
        p.CanCollide = false
        p.Transparency = transparency or 0
        return p
    end

    -- clean trim so the featured table looks crafted, not a flat slab
    detail("DungeonTrim_N", Vector3.new(18.6, 0.16, 0.2), CFrame.new(0, 0.65, -6.08), Color3.fromRGB(28, 19, 13), Enum.Material.Wood)
    detail("DungeonTrim_S", Vector3.new(18.6, 0.16, 0.2), CFrame.new(0, 0.65, 6.08), Color3.fromRGB(28, 19, 13), Enum.Material.Wood)
    detail("DungeonTrim_E", Vector3.new(0.2, 0.16, 12.2), CFrame.new(9.08, 0.65, 0), Color3.fromRGB(28, 19, 13), Enum.Material.Wood)
    detail("DungeonTrim_W", Vector3.new(0.2, 0.16, 12.2), CFrame.new(-9.08, 0.65, 0), Color3.fromRGB(28, 19, 13), Enum.Material.Wood)

    -- inset lines / board texture
    for i = 1, 6 do
        local x = -6.3 + (i * 1.8)
        detail("DungeonRuneLine_X_" .. tostring(i), Vector3.new(0.045, 0.05, 9.2), CFrame.new(x, 0.76, 0), Color3.fromRGB(78, 68, 54), Enum.Material.Slate, 0.22)
    end

    for i = 1, 5 do
        local z = -4.1 + (i * 1.38)
        detail("DungeonRuneLine_Z_" .. tostring(i), Vector3.new(14.6, 0.05, 0.045), CFrame.new(0, 0.77, z), Color3.fromRGB(78, 68, 54), Enum.Material.Slate, 0.22)
    end

    -- candles / tiny light props
    local candleOffsets = {
        CFrame.new(-7.8, 0.95, -5.05),
        CFrame.new(7.8, 0.95, -5.05),
        CFrame.new(-7.8, 0.95, 5.05),
        CFrame.new(7.8, 0.95, 5.05),
    }
    for i, offset in ipairs(candleOffsets) do
        local candle = detail("DungeonCandle_" .. tostring(i), Vector3.new(0.18, 0.45, 0.18), offset, Color3.fromRGB(230, 215, 176), Enum.Material.SmoothPlastic)
        candle.Shape = Enum.PartType.Cylinder
        local flame = detail("DungeonCandleFlame_" .. tostring(i), Vector3.new(0.18, 0.18, 0.18), offset * CFrame.new(0, 0.35, 0), Color3.fromRGB(255, 160, 58), Enum.Material.Neon, 0.06)
        flame.Shape = Enum.PartType.Ball
    end

    -- coins with a simple top label; not fancy enough to break, but reads as coins
    for i = 1, 8 do
        local coin = detail("DungeonCoin_" .. tostring(i), Vector3.new(0.26, 0.055, 0.26), CFrame.new(-7.4 + (i * 0.27), 0.84, 5.55), Color3.fromRGB(245, 190, 72), Enum.Material.Metal)
        coin.Shape = Enum.PartType.Cylinder
        topLabel(coin, "$", Color3.fromRGB(72, 49, 18))
    end

    -- simple crates / chest forms
    detail("DungeonCrate_A", Vector3.new(0.62, 0.38, 0.46), CFrame.new(-6.55, 0.88, 5.35), Color3.fromRGB(90, 58, 34), Enum.Material.Wood)
    detail("DungeonCrate_B", Vector3.new(0.46, 0.32, 0.40), CFrame.new(-5.95, 0.86, 5.42), Color3.fromRGB(62, 42, 28), Enum.Material.Wood)
    local chest = detail("DungeonMiniChest", Vector3.new(0.70, 0.34, 0.44), CFrame.new(6.45, 0.88, 5.35), Color3.fromRGB(82, 47, 28), Enum.Material.Wood)
    detail("DungeonMiniChestBand", Vector3.new(0.75, 0.07, 0.49), CFrame.new(6.45, 1.08, 5.35), Color3.fromRGB(230, 184, 70), Enum.Material.Metal)

    -- spooky silhouettes in back, low enough not to block table reads
    for i = 1, 3 do
        local x = -1.9 + ((i - 1) * 1.9)
        detail("DungeonArchBase_" .. tostring(i), Vector3.new(0.98, 0.16, 0.18), CFrame.new(x, 0.92, -5.55), Color3.fromRGB(34, 30, 42), Enum.Material.Slate)
        detail("DungeonArchL_" .. tostring(i), Vector3.new(0.15, 0.62, 0.15), CFrame.new(x - 0.42, 1.20, -5.55), Color3.fromRGB(34, 30, 42), Enum.Material.Slate)
        detail("DungeonArchR_" .. tostring(i), Vector3.new(0.15, 0.62, 0.15), CFrame.new(x + 0.42, 1.20, -5.55), Color3.fromRGB(34, 30, 42), Enum.Material.Slate)
        detail("DungeonArchTop_" .. tostring(i), Vector3.new(0.98, 0.15, 0.15), CFrame.new(x, 1.55, -5.55), Color3.fromRGB(34, 30, 42), Enum.Material.Slate)
    end
end

local function addMapPolish(parent)
    local function deco(name, size, cframe, color, material, transparency)
        local p = part(parent, name, size, cframe, color, material or Enum.Material.SmoothPlastic)
        p.CanCollide = false
        p.Transparency = transparency or 0
        return p
    end

    -- subtle walkway and floor accents
    deco("MainWalkway", Vector3.new(18, 0.06, 72), CFrame.new(0, 0.04, -5), Color3.fromRGB(44, 53, 62), Enum.Material.Slate, 0.12)
    for i = 1, 10 do
        deco("FloorInset_" .. tostring(i), Vector3.new(13, 0.04, 0.08), CFrame.new(0, 0.08, -36 + (i * 6)), Color3.fromRGB(68, 79, 88), Enum.Material.Slate, 0.20)
    end

    -- small lamp posts near the featured table
    for i, x in ipairs({-12, 12}) do
        deco("TableLampPost_" .. tostring(i), Vector3.new(0.28, 3.2, 0.28), CFrame.new(x, 1.35, -8), Color3.fromRGB(22, 22, 26), Enum.Material.Metal)
        local lamp = deco("TableLampGlow_" .. tostring(i), Vector3.new(0.75, 0.75, 0.75), CFrame.new(x, 3.1, -8), Color3.fromRGB(245, 190, 72), Enum.Material.Neon, 0.18)
        lamp.Shape = Enum.PartType.Ball
    end
end


function WorldBuilder.Build()
    local old = workspace:FindFirstChild("TableRushMap")
    if old then old:Destroy() end
    local oldHall = workspace:FindFirstChild("TableRushHall")
    if oldHall then oldHall:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name = "TableRushMap"
    folder.Parent = workspace
    part(folder, "OpenFloor", Vector3.new(150, 1, 120), CFrame.new(0, -0.5, 0), Color3.fromRGB(36, 43, 50), Enum.Material.WoodPlanks)
    addMapPolish(folder)

    sign(folder, "MainTitle", "TABLE RUSH", CFrame.new(0, 10, -43), Vector3.new(26, 5.5, 0.35), Color3.fromRGB(19, 28, 40))
    sign(folder, "SubTitle", "Walk up to a table, spectate, or use Play", CFrame.new(0, 6.5, -42.9), Vector3.new(28, 2.2, 0.3), Color3.fromRGB(15, 22, 32))

    local dungeon = makeTable(folder, "DungeonDoorsTable", Vector3.new(0, 0, -8), Color3.fromRGB(38, 54, 70), "DUNGEON DOORS\nJoin or Spectate", true)
    addPromptPart(dungeon, "JoinDungeonDoors", Vector3.new(-4.8, 3.6, 0), "Join", "Dungeon Doors")
    addPromptPart(dungeon, "SpectateDungeonDoors", Vector3.new(4.8, 3.6, 0), "Spectate", "Dungeon Doors")
    addDungeonTablePolish(folder, dungeon)

    makeTable(folder, "FutureTableA", Vector3.new(-34, 0, 18), Color3.fromRGB(48, 48, 56), "FUTURE TABLE\nComing Later", false)
    makeTable(folder, "FutureTableB", Vector3.new(34, 0, 18), Color3.fromRGB(48, 48, 56), "FUTURE TABLE\nComing Later", false)

    sign(folder, "JoinBoard", "JOIN BOARD\nActive tables later", CFrame.new(-44, 5.8, -24) * CFrame.Angles(0, math.rad(25), 0), Vector3.new(11, 5.2, 0.35), Color3.fromRGB(18, 27, 39))
    sign(folder, "DailyBoard", "DAILY TASKS\nUse the Daily tab for now", CFrame.new(44, 5.8, -24) * CFrame.Angles(0, math.rad(-25), 0), Vector3.new(11, 5.2, 0.35), Color3.fromRGB(18, 27, 39))
    sign(folder, "RewardChest", "REWARD CHEST\nLater", CFrame.new(44, 4.8, 8) * CFrame.Angles(0, math.rad(-65), 0), Vector3.new(10, 4, 0.35), Color3.fromRGB(18, 27, 39))
    sign(folder, "RelicShelf", "RELIC SHELF\nBoss cards later", CFrame.new(-44, 4.8, 8) * CFrame.Angles(0, math.rad(65), 0), Vector3.new(10, 4, 0.35), Color3.fromRGB(18, 27, 39))
    sign(folder, "PersonalLabel", "PERSONAL TABLE LABEL\nBuilt later, code-ready", CFrame.new(0, 4.8, 34), Vector3.new(18, 4.2, 0.35), Color3.fromRGB(19, 28, 40))

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
