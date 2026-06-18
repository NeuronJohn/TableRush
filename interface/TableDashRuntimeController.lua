local StarterGui = game:GetService("StarterGui")
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local gui = script.Parent
local root = gui:WaitForChild("Root")
local canvas = root:WaitForChild("ReferenceCanvas")
local pageRoot = canvas:WaitForChild("PageRoot")
local bottomBar = canvas:WaitForChild("BottomBar")
local modals = canvas:WaitForChild("TD_Modals")
local shade = modals:WaitForChild("ModalShade")

local playPage = pageRoot:WaitForChild("PlayPage")
local playPanel = playPage:WaitForChild("PlayPanel")
local currentGame = nil
local sortModeIndex = 1
local sortModes = {"Popular", "Entry Low", "Entry High", "A-Z"}

local gameData = {
	GameCard_WhatThat = {display="What That", cost=200, players="2 - 6 Players", sort=1},
	GameCard_Better = {display="Better or Worse", cost=200, players="2 - 8 Players", sort=2},
	GameCard_WordBomb = {display="Word Bomb Duel", cost=500, players="2 - 6 Players", sort=3},
	GameCard_Simon = {display="Simon Dash", cost=400, players="2 - 4 Players", sort=4},
	GameCard_Stack = {display="Stack or Crash", cost=400, players="2 - 4 Players", sort=5},
}

local cardOrder = {"GameCard_WhatThat", "GameCard_Better", "GameCard_WordBomb", "GameCard_Simon", "GameCard_Stack"}

local function desc(rootObj, name)
	for _, d in ipairs(rootObj:GetDescendants()) do
		if d.Name == name then return d end
	end
	return nil
end

local function allDesc(rootObj, name)
	local results = {}
	for _, d in ipairs(rootObj:GetDescendants()) do
		if d.Name == name then table.insert(results, d) end
	end
	return results
end

local function getStroke(obj)
	return obj and obj:FindFirstChildOfClass("UIStroke")
end

local function setGradient(obj, c1, c2)
	if not obj then return end
	local g = obj:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	})
	g.Rotation = 90
	g.Parent = obj
end

local function clickify(obj, callback)
	if not obj then return end
	if obj:IsA("TextButton") or obj:IsA("ImageButton") then
		obj.MouseButton1Click:Connect(callback)
	else
		local hit = obj:FindFirstChild("ClickHitbox")
		if not hit then
			hit = Instance.new("TextButton")
			hit.Name = "ClickHitbox"
			hit.Text = ""
			hit.BackgroundTransparency = 1
			hit.BorderSizePixel = 0
			hit.Size = UDim2.fromScale(1, 1)
			hit.Position = UDim2.fromScale(0, 0)
			hit.ZIndex = obj.ZIndex + 20
			hit.Parent = obj
		end
		hit.MouseButton1Click:Connect(callback)
	end
end

local function hideAllModals()
	for _, child in ipairs(modals:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Toast" and child.Name ~= "ModalShade" then
			child.Visible = false
		end
	end
	shade.Visible = false
end

local function showModal(name)
	hideAllModals()
	local m = modals:FindFirstChild(name)
	if m then
		shade.Visible = true
		m.Visible = true
	end
end

local function toast(msg)
	local t = modals:FindFirstChild("Toast")
	if not t then return end
	local m = t:FindFirstChild("Message")
	if m then m.Text = msg end
	t.Visible = true
	task.delay(2, function()
		if t then t.Visible = false end
	end)
end

for _, modal in ipairs(modals:GetChildren()) do
	if modal:IsA("Frame") then
		local close = modal:FindFirstChild("CloseModal")
		if close and close:IsA("TextButton") then
			close.MouseButton1Click:Connect(hideAllModals)
		end
	end
end

clickify(shade, hideAllModals)

local function setPage(pageName)
	local ACTIVE_TEXT = Color3.fromRGB(255, 225, 105)
	local ACTIVE_STROKE = Color3.fromRGB(255, 204, 76)

	local INACTIVE_TEXT = Color3.fromRGB(199, 184, 240)
	local INACTIVE_STROKE = Color3.fromRGB(105, 70, 175)

	for _, page in ipairs(pageRoot:GetChildren()) do
		if page:IsA("Frame") then
			page.Visible = pageName ~= nil and page.Name == pageName
		end
	end

	for _, nav in ipairs(bottomBar:GetChildren()) do
		if nav:IsA("TextButton") then
			local active = pageName ~= nil and nav:GetAttribute("TargetPage") == pageName
			local s = getStroke(nav)
			local label = nav:FindFirstChild("Label")
			local line = nav:FindFirstChild("ActiveLine")

			if line then
				line.Visible = active
				line.BackgroundColor3 = ACTIVE_STROKE
			end

			if active then
				nav.BackgroundColor3 = Color3.fromRGB(36, 26, 42)
				setGradient(nav, Color3.fromRGB(42, 30, 58), Color3.fromRGB(18, 14, 30))

				if s then
					s.Color = ACTIVE_STROKE
					s.Thickness = 3
					s.Transparency = 0.03
				end

				if label then
					label.TextColor3 = ACTIVE_TEXT
				end

				nav.TextColor3 = ACTIVE_TEXT
			else
				nav.BackgroundColor3 = Color3.fromRGB(10, 13, 29)
				setGradient(nav, Color3.fromRGB(13, 16, 34), Color3.fromRGB(7, 9, 22))

				if s then
					s.Color = INACTIVE_STROKE
					s.Thickness = 2.5
					s.Transparency = 0.12
				end

				if label then
					label.TextColor3 = INACTIVE_TEXT
				end

				nav.TextColor3 = INACTIVE_TEXT
			end
		end
	end
end

for _, nav in ipairs(bottomBar:GetChildren()) do
	if nav:IsA("TextButton") then
		nav.MouseButton1Click:Connect(function()
			local target = nav:GetAttribute("TargetPage")
			if target then setPage(target) end
		end)
	end
end

local function setTab(tabName)
	local tabs = {
		Quickplay = playPanel:FindFirstChild("QuickplayTab_ACTIVE_DEFAULT"),
		Hosted = playPanel:FindFirstChild("HostedTab"),
		Friends = playPanel:FindFirstChild("FriendsTab"),
	}

	for name, tab in pairs(tabs) do
		if tab then
			local active = name == tabName
			local s = getStroke(tab)
			if active then
				tab.BackgroundColor3 = Color3.fromRGB(34, 25, 42)
				setGradient(tab, Color3.fromRGB(43, 31, 55), Color3.fromRGB(16, 13, 28))
				if s then
					s.Color = Color3.fromRGB(255, 204, 76)
					s.Thickness = 1.8
					s.Transparency = 0.04
				end
				tab.TextColor3 = Color3.fromRGB(255, 225, 105)
			else
				tab.BackgroundColor3 = Color3.fromRGB(11, 13, 30)
				setGradient(tab, Color3.fromRGB(15, 17, 39), Color3.fromRGB(8, 10, 25))
				if s then
					s.Color = Color3.fromRGB(75, 55, 114)
					s.Thickness = 1.5
					s.Transparency = 0.18
				end
				tab.TextColor3 = Color3.fromRGB(199, 184, 240)
			end
		end
	end

	local strip = playPanel:FindFirstChild("GameStrip")
	if strip then strip.Visible = tabName == "Quickplay" end

	local existing = playPanel:FindFirstChild("TabEmptyState")
	if existing then existing:Destroy() end

	if tabName ~= "Quickplay" then
		local empty = Instance.new("TextLabel")
		empty.Name = "TabEmptyState"
		empty.BackgroundTransparency = 1
		empty.Text = tabName == "Hosted" and "Hosted tables will appear here." or "Friends tables will appear here."
		empty.TextColor3 = Color3.fromRGB(199, 184, 240)
		empty.TextSize = 28
		empty.Font = Enum.Font.GothamBlack
		empty.TextXAlignment = Enum.TextXAlignment.Center
		empty.TextYAlignment = Enum.TextYAlignment.Center
		empty.Position = UDim2.fromOffset(0, 300)
		empty.Size = UDim2.new(1, 0, 0, 80)
		empty.ZIndex = 60
		empty.Parent = playPanel
	end
end

clickify(playPanel:FindFirstChild("QuickplayTab_ACTIVE_DEFAULT"), function() setTab("Quickplay") end)
clickify(playPanel:FindFirstChild("HostedTab"), function() setTab("Hosted") end)
clickify(playPanel:FindFirstChild("FriendsTab"), function() setTab("Friends") end)

local function setCorrectCostsAndButtons()
	for cardName, data in pairs(gameData) do
		local card = desc(playPanel, cardName)
		if card then
			card:SetAttribute("GameId", cardName)
			card:SetAttribute("GameDisplay", data.display)
			card:SetAttribute("EntryCost", data.cost)
			card:SetAttribute("Players", data.players)

			local costText = desc(card, "CostText")
			if costText then costText.Text = tostring(data.cost) end

			local title = desc(card, "GameTitle")
			if title then
				title.Text = data.display
				title.TextWrapped = true
				title.TextScaled = true
				local limit = title:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
				limit.MinTextSize = 12
				limit.MaxTextSize = 20
				limit.Parent = title
			end

			local players = desc(card, "Players")
			if players then players.Text = data.players end

			local join = desc(card, "JoinButton_BRIGHT")
			if join then
				join.Text = "JOIN"
				join.TextColor3 = Color3.fromRGB(255, 255, 255)
				join.TextTransparency = 0
				join.MouseButton1Click:Connect(function()
					currentGame = data
					local modal = modals:FindFirstChild("JoinConfirmModal")
					if modal then
						modal.GameName.Text = data.display
						modal.EntryLine.Text = "Entry: " .. data.cost .. " coins"
						modal.PlayersLine.Text = "Players: " .. data.players
					end
					showModal("JoinConfirmModal")
				end)
			end
		end
	end
end

setCorrectCostsAndButtons()

local function sortCards()
	local strip = playPanel:FindFirstChild("GameStrip")
	if not strip then return end

	local mode = sortModes[sortModeIndex]
	local items = {}

	for _, cardName in ipairs(cardOrder) do
		local card = desc(strip, cardName)
		local data = gameData[cardName]
		if card and data then
			table.insert(items, {card=card, data=data, name=cardName})
		end
	end

	if mode == "Entry Low" then
		table.sort(items, function(a, b) return a.data.cost < b.data.cost end)
	elseif mode == "Entry High" then
		table.sort(items, function(a, b) return a.data.cost > b.data.cost end)
	elseif mode == "A-Z" then
		table.sort(items, function(a, b) return a.data.display < b.data.display end)
	else
		table.sort(items, function(a, b) return a.data.sort < b.data.sort end)
	end

	for i, item in ipairs(items) do
		item.card.Position = UDim2.fromOffset((i - 1) * 254, 0)
	end
end

local sortBox = playPanel:FindFirstChild("SortBox")
clickify(sortBox, function()
	sortModeIndex += 1
	if sortModeIndex > #sortModes then sortModeIndex = 1 end
	local mode = sortModes[sortModeIndex]
	local t = sortBox and sortBox:FindFirstChild("SortText")
	if t then t.Text = "Sort: " .. mode end
	sortCards()
end)

local function applySearch(query)
	query = string.lower(query or "")
	for cardName, data in pairs(gameData) do
		local card = desc(playPanel, cardName)
		if card then
			local ok = query == "" or string.find(string.lower(data.display), query, 1, true) ~= nil
			card.Visible = ok
		end
	end
end

local searchBox = playPanel:FindFirstChild("SearchBox")
if searchBox then
	local input = searchBox:FindFirstChild("SearchInput")

	if not input then
		input = Instance.new("TextBox")
		input.Name = "SearchInput"
		input.BackgroundTransparency = 1
		input.BorderSizePixel = 0
		input.Text = ""
		input.PlaceholderText = "Search games..."
		input.PlaceholderColor3 = Color3.fromRGB(199, 184, 240)
		input.TextColor3 = Color3.fromRGB(245, 240, 255)
		input.Font = Enum.Font.GothamBold
		input.TextSize = 18
		input.TextXAlignment = Enum.TextXAlignment.Left
		input.ClearTextOnFocus = false
		input.Position = UDim2.fromOffset(48, 0)
		input.Size = UDim2.new(1, -60, 1, 0)
		input.ZIndex = searchBox.ZIndex + 5
		input.Parent = searchBox
	end

	local oldPlaceholder = searchBox:FindFirstChild("Placeholder")
	if oldPlaceholder then
		oldPlaceholder.Visible = false
	end

	local searchStroke = searchBox:FindFirstChildOfClass("UIStroke")

	local function setSearchFocused(isFocused)
		if isFocused then
			input.PlaceholderText = "Type now..."
			input.PlaceholderColor3 = Color3.fromRGB(255, 230, 105)
			input.TextColor3 = Color3.fromRGB(255, 255, 255)

			searchBox.BackgroundColor3 = Color3.fromRGB(20, 18, 43)

			if searchStroke then
				searchStroke.Color = Color3.fromRGB(255, 204, 76)
				searchStroke.Thickness = 2.5
				searchStroke.Transparency = 0.02
			end
		else
			input.PlaceholderText = "Search games..."
			input.PlaceholderColor3 = Color3.fromRGB(199, 184, 240)
			input.TextColor3 = Color3.fromRGB(245, 240, 255)

			searchBox.BackgroundColor3 = Color3.fromRGB(10, 13, 29)

			if searchStroke then
				searchStroke.Color = Color3.fromRGB(75, 55, 114)
				searchStroke.Thickness = 1.5
				searchStroke.Transparency = 0.25
			end
		end
	end

	input.Focused:Connect(function()
		setSearchFocused(true)
	end)

	input.FocusLost:Connect(function()
		setSearchFocused(false)
	end)

	input:GetPropertyChangedSignal("Text"):Connect(function()
		applySearch(input.Text)
	end)

	-- Lets clicking anywhere on the search box activate typing.
	clickify(searchBox, function()
		input:CaptureFocus()
	end)
end

local function showAdModal()
	showModal("RewardedAdModal")
end

clickify(playPanel:FindFirstChild("TicketButton"), showAdModal)

local top = canvas:FindFirstChild("TopResourceBar")
clickify(top and top:FindFirstChild("Tickets"), showAdModal)
clickify(top and top:FindFirstChild("Coins"), function() showModal("CoinShopModal") end)
clickify(top and top:FindFirstChild("Level"), function() showModal("LevelInfoModal") end)
clickify(top and top:FindFirstChild("Streak"), function() showModal("StreakInfoModal") end)

local passMini = playPanel:FindFirstChild("ArcadePassLvl")
clickify(passMini, function() showModal("ArcadePassBuyModal") end)

local passImageButton = passMini and passMini:FindFirstChildWhichIsA("ImageButton", true)
clickify(passImageButton, function() showModal("ArcadePassBuyModal") end)

clickify(playPanel:FindFirstChild("CloseButton"), function()
	setPage(nil)
end)

for _, nextButton in ipairs(allDesc(playPanel, "NextPageButton")) do
	clickify(nextButton, function()
		toast("More quickplay games coming soon.")
	end)
end

local joinModal = modals:FindFirstChild("JoinConfirmModal")
if joinModal then
	joinModal.UseCoinsButton.MouseButton1Click:Connect(function()
		if currentGame then
			toast("Queued with coins: " .. currentGame.display)
			hideAllModals()
		end
	end)

	joinModal.UseTicketButton.MouseButton1Click:Connect(function()
		if currentGame then
			toast("Queued with Quickplay Ticket: " .. currentGame.display)
			hideAllModals()
		end
	end)

	joinModal.ConfirmJoinButton.MouseButton1Click:Connect(function()
		if currentGame then
			toast("Joining " .. currentGame.display .. "...")
			hideAllModals()
		end
	end)
end

local adModal = modals:FindFirstChild("RewardedAdModal")
if adModal then
	adModal.CancelAdButton.MouseButton1Click:Connect(hideAllModals)
	adModal.WatchAdButton.MouseButton1Click:Connect(function()
		local topBar = canvas:FindFirstChild("TopResourceBar")
		local tickets = topBar and topBar:FindFirstChild("Tickets")
		local val = tickets and tickets:FindFirstChild("Value")
		if val and val:IsA("TextLabel") then
			local n = tonumber(val.Text) or 0
			val.Text = tostring(n + 1)
		end
		hideAllModals()
		toast("Rewarded ad complete: +1 Quickplay Ticket.")
	end)
end

local passModal = modals:FindFirstChild("ArcadePassBuyModal")
if passModal then
	passModal.BuyPassButton.MouseButton1Click:Connect(function()
		toast("Premium Arcade Pass purchase test.")
		hideAllModals()
	end)

	passModal.ViewRewardsButton.MouseButton1Click:Connect(function()
		hideAllModals()
		setPage("PassPage")
	end)
end

setPage("PlayPage")
setTab("Quickplay")
sortCards()

print("Table Dash runtime wired.")
