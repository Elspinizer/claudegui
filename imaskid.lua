local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ContextActionService = game:GetService("ContextActionService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local TOGGLE_KEY = Enum.KeyCode.X

-- Theme (ACCENT changes when the user picks a colour)
local BG = Color3.fromRGB(11, 12, 16)
local PANEL = Color3.fromRGB(17, 19, 25)
local ELEMENT = Color3.fromRGB(24, 27, 35)
local ELEMENT_HOVER = Color3.fromRGB(31, 35, 45)
local NESTED_BG = Color3.fromRGB(16, 18, 24)    -- cards inside a dropdown module
local NESTED_HOVER = Color3.fromRGB(21, 24, 31)
local ACCENT = Color3.fromRGB(0, 255, 170)
local TEXT = Color3.fromRGB(228, 232, 238)
local MUTED = Color3.fromRGB(112, 120, 134)
local DANGER = Color3.fromRGB(255, 85, 100)

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MONO = Enum.Font.Code

-- ============================================================
-- Helpers
-- ============================================================
local connections = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

-- Accent colour system: anything that uses the accent registers here
local accentUpdaters = {}
local function onAccent(fn)
	fn(ACCENT)
	table.insert(accentUpdaters, fn)
end
local function setAccent(color)
	ACCENT = color
	for _, fn in ipairs(accentUpdaters) do fn(color) end
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function stroke(parent, color, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Transparency = transparency or 0
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function tween(obj, time, props)
	local t = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function label(parent, text, size, color, font, xAlign)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = font
	l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function getHumanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function keyDown(k)
	return UserInputService:IsKeyDown(k)
end

-- Cards placed inside a dropdown module use darker colours so they stand out
local function styleFor(page)
	if page:GetAttribute("Nested") then
		return NESTED_BG, NESTED_HOVER, ELEMENT
	end
	return ELEMENT, ELEMENT_HOVER, BG
end

local originalHumanoid = getHumanoid()
local originalSpeed = originalHumanoid and originalHumanoid.WalkSpeed or 16
local originalJump = originalHumanoid and originalHumanoid.JumpPower or 50
local originalFOV = camera.FieldOfView
local originalGravity = workspace.Gravity

local appliedSpeed, appliedJump = nil, nil
local fovChanged, gravityChanged = false, false

-- ============================================================
-- Window
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "HackGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

-- separate layer for ESP tracers (sits under the menu)
local tracerGui = Instance.new("ScreenGui")
tracerGui.Name = "HackGuiTracers"
tracerGui.ResetOnSpawn = false
tracerGui.IgnoreGuiInset = true
tracerGui.DisplayOrder = 99
tracerGui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(380, 440)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui
corner(main, 12)
local mainStroke = stroke(main, ACCENT, 0.7, 1)
onAccent(function(c) mainStroke.Color = c end)

local scale = Instance.new("UIScale")
scale.Scale = 0.92
scale.Parent = main

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = PANEL
titleBar.BorderSizePixel = 0
titleBar.Parent = main
corner(titleBar, 12)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = PANEL
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(8, 8)
dot.Position = UDim2.new(0, 18, 0.5, -4)
dot.BackgroundColor3 = ACCENT
dot.BorderSizePixel = 0
dot.Parent = titleBar
corner(dot, 4)
local dotStroke = stroke(dot, ACCENT, 0.6, 3)
onAccent(function(c)
	dot.BackgroundColor3 = c
	dotStroke.Color = c
end)

local title = label(titleBar, "HACK.EXE", 14, TEXT, FONT_BOLD)
title.Position = UDim2.fromOffset(36, 0)
title.Size = UDim2.new(0, 100, 1, 0)

local version = label(titleBar, "v1.2", 11, MUTED, FONT_MONO)
version.Position = UDim2.fromOffset(112, 1)
version.Size = UDim2.new(0, 50, 1, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = DANGER
closeBtn.BackgroundTransparency = 1
closeBtn.AutoButtonColor = false
closeBtn.Font = FONT_BOLD
closeBtn.Text = "✕"
closeBtn.TextColor3 = MUTED
closeBtn.TextSize = 13
closeBtn.Parent = titleBar
corner(closeBtn, 7)

connect(closeBtn.MouseEnter, function()
	tween(closeBtn, 0.12, { BackgroundTransparency = 0.8, TextColor3 = DANGER })
end)
connect(closeBtn.MouseLeave, function()
	tween(closeBtn, 0.12, { BackgroundTransparency = 1, TextColor3 = MUTED })
end)

-- Tab bar
local TAB_W, TAB_STEP = 80, 84

local tabBar = Instance.new("Frame")
tabBar.Position = UDim2.fromOffset(0, 44)
tabBar.Size = UDim2.new(1, 0, 0, 36)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabLine = Instance.new("Frame")
tabLine.Position = UDim2.new(0, 16, 1, -1)
tabLine.Size = UDim2.new(1, -32, 0, 1)
tabLine.BackgroundColor3 = ELEMENT
tabLine.BorderSizePixel = 0
tabLine.Parent = tabBar

local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.fromOffset(TAB_W, 2)
tabIndicator.Position = UDim2.fromOffset(16, 34)
tabIndicator.BackgroundColor3 = ACCENT
tabIndicator.BorderSizePixel = 0
tabIndicator.Parent = tabBar
corner(tabIndicator, 1)
onAccent(function(c) tabIndicator.BackgroundColor3 = c end)

-- Content area
local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(16, 92)
content.Size = UDim2.new(1, -32, 0, 310)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = main

local function makePage()
	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = ACCENT
	page.ScrollBarImageTransparency = 0.5
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new()
	page.Visible = false
	page.Parent = content
	onAccent(function(c) page.ScrollBarImageColor3 = c end)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = page

	return page
end

local pages, tabButtons = {}, {}
local function selectTab(name)
	for tabName, page in pairs(pages) do
		page.Visible = (tabName == name)
		tween(tabButtons[tabName], 0.15, { TextColor3 = tabName == name and TEXT or MUTED })
	end
	local btn = tabButtons[name]
	tween(tabIndicator, 0.2, { Position = UDim2.fromOffset(btn.Position.X.Offset, 34) })
end

local function makeTab(name, index)
	pages[name] = makePage()

	local btn = Instance.new("TextButton")
	btn.Position = UDim2.fromOffset(16 + (index - 1) * TAB_STEP, 0)
	btn.Size = UDim2.fromOffset(TAB_W, 34)
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	btn.Font = FONT_BOLD
	btn.Text = name
	btn.TextColor3 = MUTED
	btn.TextSize = 11
	btn.Parent = tabBar
	tabButtons[name] = btn

	connect(btn.MouseButton1Click, function() selectTab(name) end)
	return pages[name]
end

local playerPage = makeTab("PLAYER", 1)
local visualsPage = makeTab("VISUALS", 2)
local customizePage = makeTab("CUSTOMIZE", 3)
local logPage = makeTab("LOG", 4)
logPage:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 3)

-- Footer
local footer = label(main, "[X] toggle   •   drag the title bar to move", 11, MUTED, FONT, Enum.TextXAlignment.Center)
footer.Position = UDim2.new(0, 0, 1, -28)
footer.Size = UDim2.new(1, 0, 0, 20)

-- ============================================================
-- LOG (a little terminal that prints what you switch on/off)
-- ============================================================
local logLines = {}
local logCount = 0

local function log(text, color)
	logCount += 1
	local l = label(logPage, string.format("[%s] %s", os.date("%H:%M:%S"), text), 12, color or TEXT, FONT_MONO)
	l.LayoutOrder = logCount
	l.Size = UDim2.new(1, 0, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.TextWrapped = true
	table.insert(logLines, l)
	if #logLines > 60 then
		table.remove(logLines, 1):Destroy()
	end
	task.defer(function()
		if logPage.Parent then logPage.CanvasPosition = Vector2.new(0, 1e6) end
	end)
end

-- ============================================================
-- REUSABLE COMPONENTS
-- Every component works on the main pages AND inside a module's body
-- ============================================================

-- makeSlider(page, order, "Name", min, max, default, callback, live)
--   live = false -> shows an APPLY button, callback fires when clicked
--   live = true  -> no button, callback fires as you drag
-- Returns: setter(value), card
local function makeSlider(page, order, name, minV, maxV, default, callback, live)
	local cardBg, _, insetBg = styleFor(page)

	local card = Instance.new("Frame")
	card.LayoutOrder = order
	card.Size = UDim2.new(1, 0, 0, live and 66 or 100)
	card.BackgroundColor3 = cardBg
	card.BorderSizePixel = 0
	card.Parent = page
	corner(card, 9)

	local nameLabel = label(card, name, 13, TEXT, FONT)
	nameLabel.Position = UDim2.fromOffset(14, 10)
	nameLabel.Size = UDim2.new(0.6, 0, 0, 18)

	local valueLabel = label(card, tostring(default), 15, ACCENT, FONT_MONO, Enum.TextXAlignment.Right)
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.new(1, -14, 0, 9)
	valueLabel.Size = UDim2.fromOffset(70, 20)

	local track = Instance.new("Frame")
	track.Position = UDim2.fromOffset(14, 43)
	track.Size = UDim2.new(1, -28, 0, 6)
	track.BackgroundColor3 = insetBg
	track.BorderSizePixel = 0
	track.Parent = card
	corner(track, 3)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = ACCENT
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 3)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.fromScale(0, 0.5)
	knob.BackgroundColor3 = TEXT
	knob.BorderSizePixel = 0
	knob.ZIndex = 2
	knob.Parent = track
	corner(knob, 8)
	local knobStroke = stroke(knob, ACCENT, 1, 4)

	onAccent(function(c)
		valueLabel.TextColor3 = c
		fill.BackgroundColor3 = c
		knobStroke.Color = c
	end)

	local hitbox = Instance.new("TextButton")
	hitbox.BackgroundTransparency = 1
	hitbox.Text = ""
	hitbox.Position = UDim2.fromOffset(14, 31)
	hitbox.Size = UDim2.new(1, -28, 0, 30)
	hitbox.ZIndex = 3
	hitbox.Parent = card

	local value = default
	local function setAlpha(alpha, fire)
		alpha = math.clamp(alpha, 0, 1)
		value = math.round(minV + alpha * (maxV - minV))
		local snapped = (value - minV) / (maxV - minV)
		fill.Size = UDim2.fromScale(snapped, 1)
		knob.Position = UDim2.fromScale(snapped, 0.5)
		valueLabel.Text = tostring(value)
		if live and fire then callback(value) end
	end
	setAlpha((default - minV) / (maxV - minV), false)

	local dragging = false
	local function updateFromX(x)
		setAlpha((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, true)
	end

	connect(hitbox.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			tween(knobStroke, 0.12, { Transparency = 0.6 })
			updateFromX(input.Position.X)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			tween(knobStroke, 0.15, { Transparency = 1 })
		end
	end)

	if not live then
		local apply = Instance.new("TextButton")
		apply.Position = UDim2.fromOffset(14, 64)
		apply.Size = UDim2.new(1, -28, 0, 26)
		apply.BackgroundColor3 = ACCENT
		apply.AutoButtonColor = false
		apply.Font = FONT_BOLD
		apply.Text = "APPLY"
		apply.TextColor3 = BG
		apply.TextSize = 12
		apply.Parent = card
		corner(apply, 7)
		onAccent(function(c) apply.BackgroundColor3 = c end)

		connect(apply.MouseEnter, function()
			tween(apply, 0.12, { BackgroundColor3 = ACCENT:Lerp(Color3.new(1, 1, 1), 0.3) })
		end)
		connect(apply.MouseLeave, function()
			tween(apply, 0.12, { BackgroundColor3 = ACCENT })
		end)
		connect(apply.MouseButton1Click, function()
			callback(value)
			apply.Text = "APPLIED ✓"
			task.delay(0.8, function()
				if apply.Parent then apply.Text = "APPLY" end
			end)
		end)
	end

	return function(v)
		setAlpha((v - minV) / (maxV - minV), false)
	end, card
end

local disableCallbacks = {} -- used on unload to switch everything off

-- makeCheckbox(page, order, "Name", "description", callback(enabled), startsOn)
-- Returns: set(value), row
local function makeCheckbox(page, order, name, desc, callback, startsOn)
	local cardBg, hoverBg, insetBg = styleFor(page)
	local checked = false

	local row = Instance.new("TextButton")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 46)
	row.BackgroundColor3 = cardBg
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.Parent = page
	corner(row, 9)

	local nameLabel = label(row, name, 13, TEXT, FONT)
	nameLabel.Position = UDim2.fromOffset(14, 7)
	nameLabel.Size = UDim2.new(1, -60, 0, 18)

	local descLabel = label(row, desc, 11, MUTED, FONT)
	descLabel.Position = UDim2.fromOffset(14, 24)
	descLabel.Size = UDim2.new(1, -60, 0, 16)

	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -14, 0.5, 0)
	box.Size = UDim2.fromOffset(20, 20)
	box.BackgroundColor3 = insetBg
	box.BorderSizePixel = 0
	box.Parent = row
	corner(box, 6)
	local boxStroke = stroke(box, MUTED, 0.2, 1)

	local tick = Instance.new("Frame")
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5, 0.5)
	tick.Size = UDim2.fromOffset(0, 0)
	tick.BackgroundColor3 = ACCENT
	tick.BorderSizePixel = 0
	tick.Parent = box
	corner(tick, 4)

	onAccent(function(c)
		tick.BackgroundColor3 = c
		if checked then boxStroke.Color = c end
	end)

	local function set(value, silent)
		checked = value
		tween(tick, 0.15, { Size = checked and UDim2.fromOffset(12, 12) or UDim2.fromOffset(0, 0) })
		tween(boxStroke, 0.15, { Color = checked and ACCENT or MUTED })
		callback(checked)
		if not silent then log(name .. (checked and " enabled" or " disabled"), checked and ACCENT or MUTED) end
	end

	connect(row.MouseEnter, function() tween(row, 0.12, { BackgroundColor3 = hoverBg }) end)
	connect(row.MouseLeave, function() tween(row, 0.12, { BackgroundColor3 = cardBg }) end)
	connect(row.MouseButton1Click, function() set(not checked) end)

	table.insert(disableCallbacks, function()
		if checked then callback(false) end
	end)

	if startsOn then set(true, true) end
	return set, row
end

-- makeButton(page, order, "Name", "description", "BUTTON TEXT", callback)
-- Returns: row
local function makeButton(page, order, name, desc, btnText, callback)
	local cardBg = styleFor(page)

	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 46)
	row.BackgroundColor3 = cardBg
	row.BorderSizePixel = 0
	row.Parent = page
	corner(row, 9)

	local nameLabel = label(row, name, 13, TEXT, FONT)
	nameLabel.Position = UDim2.fromOffset(14, 7)
	nameLabel.Size = UDim2.new(1, -120, 0, 18)

	local descLabel = label(row, desc, 11, MUTED, FONT)
	descLabel.Position = UDim2.fromOffset(14, 24)
	descLabel.Size = UDim2.new(1, -120, 0, 16)

	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -12, 0.5, 0)
	btn.Size = UDim2.fromOffset(92, 26)
	btn.BackgroundColor3 = ACCENT
	btn.AutoButtonColor = false
	btn.Font = FONT_BOLD
	btn.Text = btnText
	btn.TextColor3 = BG
	btn.TextSize = 11
	btn.Parent = row
	corner(btn, 7)
	onAccent(function(c) btn.BackgroundColor3 = c end)

	connect(btn.MouseEnter, function()
		tween(btn, 0.12, { BackgroundColor3 = ACCENT:Lerp(Color3.new(1, 1, 1), 0.3) })
	end)
	connect(btn.MouseLeave, function()
		tween(btn, 0.12, { BackgroundColor3 = ACCENT })
	end)
	connect(btn.MouseButton1Click, callback)

	return row
end

-- makeKeybind(page, order, "Name", "description", Enum.KeyCode.T, function(newKey) end)
-- Click the button, then press any key to bind it (Escape cancels)
local listeningForKey = false

local function makeKeybind(page, order, name, desc, default, onChange)
	local cardBg, _, insetBg = styleFor(page)
	local key = default
	local waiting = false

	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 46)
	row.BackgroundColor3 = cardBg
	row.BorderSizePixel = 0
	row.Parent = page
	corner(row, 9)

	local nameLabel = label(row, name, 13, TEXT, FONT)
	nameLabel.Position = UDim2.fromOffset(14, 7)
	nameLabel.Size = UDim2.new(1, -120, 0, 18)

	local descLabel = label(row, desc, 11, MUTED, FONT)
	descLabel.Position = UDim2.fromOffset(14, 24)
	descLabel.Size = UDim2.new(1, -120, 0, 16)

	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -12, 0.5, 0)
	btn.Size = UDim2.fromOffset(92, 26)
	btn.BackgroundColor3 = insetBg
	btn.AutoButtonColor = false
	btn.Font = FONT_MONO
	btn.Text = key.Name
	btn.TextColor3 = TEXT
	btn.TextSize = 12
	btn.Parent = row
	corner(btn, 7)
	local btnStroke = stroke(btn, MUTED, 0.2, 1)

	local function finish()
		waiting = false
		btn.Text = key.Name
		btn.TextColor3 = TEXT
		btnStroke.Color = MUTED
		task.defer(function() listeningForKey = false end) -- after every other handler has seen this key press
	end

	connect(btn.MouseButton1Click, function()
		if listeningForKey then return end
		waiting = true
		listeningForKey = true
		btn.Text = "press a key..."
		btn.TextColor3 = ACCENT
		btnStroke.Color = ACCENT
	end)

	connect(UserInputService.InputBegan, function(input)
		if not waiting then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode == Enum.KeyCode.Unknown then return end
		if input.KeyCode ~= Enum.KeyCode.Escape then
			key = input.KeyCode
			onChange(key)
			log(name .. " set to " .. key.Name)
		end
		finish()
	end)

	return row
end

-- makeModule(page, order, "Name", "description", callback(enabled), hasToggle)
-- A dropdown: click the arrow/title to expand, tick the box to turn it on.
-- Ticking it auto-expands the settings, unticking collapses them.
-- Put your settings inside module.body with the other make* functions:
--   local m = makeModule(page, 1, "Thing", "does a thing", function(on) end)
--   makeSlider(m.body, 1, "Amount", 1, 10, 5, function(v) end, true)
-- Returns a table: { body = Frame, set = function(on), setExpanded = function(open) }
local HEADER_H = 46

local function makeModule(page, order, name, desc, callback, hasToggle)
	if hasToggle == nil then hasToggle = true end
	local checked, expanded = false, false

	local wrapper = Instance.new("Frame")
	wrapper.LayoutOrder = order
	wrapper.Size = UDim2.new(1, 0, 0, HEADER_H)
	wrapper.BackgroundColor3 = ELEMENT
	wrapper.BorderSizePixel = 0
	wrapper.ClipsDescendants = true
	wrapper.Parent = page
	corner(wrapper, 9)

	local header = Instance.new("TextButton")
	header.Size = UDim2.new(1, 0, 0, HEADER_H)
	header.BackgroundTransparency = 1
	header.AutoButtonColor = false
	header.Text = ""
	header.Parent = wrapper

	local chevron = label(header, "›", 20, MUTED, FONT_BOLD, Enum.TextXAlignment.Center)
	chevron.AnchorPoint = Vector2.new(0.5, 0.5)
	chevron.Position = UDim2.fromOffset(20, HEADER_H / 2)
	chevron.Size = UDim2.fromOffset(18, 24)

	local nameLabel = label(header, name, 13, TEXT, FONT)
	nameLabel.Position = UDim2.fromOffset(38, 7)
	nameLabel.Size = UDim2.new(1, hasToggle and -96 or -50, 0, 18)

	local descLabel = label(header, desc, 11, MUTED, FONT)
	descLabel.Position = UDim2.fromOffset(38, 24)
	descLabel.Size = UDim2.new(1, hasToggle and -96 or -50, 0, 16)

	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(10, HEADER_H)
	body.Size = UDim2.new(1, -20, 0, 0)
	body.Parent = wrapper
	body:SetAttribute("Nested", true)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = body

	-- height of whatever is currently visible inside the body
	local function contentHeight()
		local h, count = 0, 0
		for _, child in ipairs(body:GetChildren()) do
			if child:IsA("GuiObject") and child.Visible then
				h += child.Size.Y.Offset
				count += 1
			end
		end
		if count > 1 then h += (count - 1) * 6 end
		return h
	end

	local function resize()
		local h = HEADER_H
		if expanded then h += contentHeight() + 10 end
		tween(wrapper, 0.2, { Size = UDim2.new(1, 0, 0, h) })
	end

	-- keep the size right when children are added, removed, or shown/hidden
	connect(body.ChildAdded, function(child)
		if child:IsA("GuiObject") then
			connect(child:GetPropertyChangedSignal("Visible"), resize)
		end
		resize()
	end)
	connect(body.ChildRemoved, resize)

	local function setExpanded(state)
		expanded = state
		tween(chevron, 0.15, { Rotation = state and 90 or 0, TextColor3 = state and TEXT or MUTED })
		resize()
	end

	connect(header.MouseButton1Click, function() setExpanded(not expanded) end)
	connect(header.MouseEnter, function() tween(wrapper, 0.12, { BackgroundColor3 = ELEMENT_HOVER }) end)
	connect(header.MouseLeave, function() tween(wrapper, 0.12, { BackgroundColor3 = ELEMENT }) end)

	local module = { body = body, setExpanded = setExpanded }

	if hasToggle then
		local hit = Instance.new("TextButton")
		hit.AnchorPoint = Vector2.new(1, 0)
		hit.Position = UDim2.new(1, 0, 0, 0)
		hit.Size = UDim2.fromOffset(48, HEADER_H)
		hit.BackgroundTransparency = 1
		hit.AutoButtonColor = false
		hit.Text = ""
		hit.ZIndex = 2
		hit.Parent = wrapper

		local box = Instance.new("Frame")
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.fromScale(0.5, 0.5)
		box.Size = UDim2.fromOffset(20, 20)
		box.BackgroundColor3 = BG
		box.BorderSizePixel = 0
		box.Parent = hit
		corner(box, 6)
		local boxStroke = stroke(box, MUTED, 0.2, 1)

		local tick = Instance.new("Frame")
		tick.AnchorPoint = Vector2.new(0.5, 0.5)
		tick.Position = UDim2.fromScale(0.5, 0.5)
		tick.Size = UDim2.fromOffset(0, 0)
		tick.BackgroundColor3 = ACCENT
		tick.BorderSizePixel = 0
		tick.Parent = box
		corner(tick, 4)

		onAccent(function(c)
			tick.BackgroundColor3 = c
			if checked then boxStroke.Color = c end
		end)

		local function set(value, silent)
			checked = value
			tween(tick, 0.15, { Size = checked and UDim2.fromOffset(12, 12) or UDim2.fromOffset(0, 0) })
			tween(boxStroke, 0.15, { Color = checked and ACCENT or MUTED })
			setExpanded(value)
			callback(checked)
			if not silent then log(name .. (checked and " enabled" or " disabled"), checked and ACCENT or MUTED) end
		end

		connect(hit.MouseButton1Click, function() set(not checked) end)
		connect(hit.MouseEnter, function() tween(wrapper, 0.12, { BackgroundColor3 = ELEMENT_HOVER }) end)
		connect(hit.MouseLeave, function() tween(wrapper, 0.12, { BackgroundColor3 = ELEMENT }) end)

		table.insert(disableCallbacks, function()
			if checked then callback(false) end
		end)

		module.set = set
	end

	return module
end

-- ============================================================
-- FEATURES
-- ============================================================

-- Walkspeed / JumpPower (re-applied after respawn)
local function applyStats(humanoid)
	if appliedSpeed then humanoid.WalkSpeed = appliedSpeed end
	if appliedJump then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = appliedJump
	end
end

connect(player.CharacterAdded, function(character)
	applyStats(character:WaitForChild("Humanoid"))
end)

-- Infinite Jump
local infiniteJump = false
connect(UserInputService.JumpRequest, function()
	if infiniteJump then
		local humanoid = getHumanoid()
		if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- Noclip
local noclip = false
local noclipTouched = {}
connect(RunService.Stepped, function()
	if not noclip then return end
	local character = player.Character
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			noclipTouched[part] = true
			part.CanCollide = false
		end
	end
end)
local function setNoclip(on)
	noclip = on
	if not on then
		for part in pairs(noclipTouched) do
			if part.Parent then part.CanCollide = true end
		end
		table.clear(noclipTouched)
	end
end

-- Anti-AFK
local antiAfk = false
connect(player.Idled, function()
	if antiAfk then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- Instant Interact: ProximityPrompts need no hold, and can reach further away
local instantOn = false
local promptRange = 1
local promptOrig = {}

local function applyPrompt(p)
	if not promptOrig[p] then
		promptOrig[p] = { hold = p.HoldDuration, dist = p.MaxActivationDistance }
	end
	p.HoldDuration = 0
	p.MaxActivationDistance = promptOrig[p].dist * promptRange
end

local function setInstantInteract(on)
	instantOn = on
	if on then
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("ProximityPrompt") then applyPrompt(d) end
		end
	else
		for p, orig in pairs(promptOrig) do
			if p.Parent then
				p.HoldDuration = orig.hold
				p.MaxActivationDistance = orig.dist
			end
		end
		table.clear(promptOrig)
	end
end

connect(workspace.DescendantAdded, function(d)
	if instantOn and d:IsA("ProximityPrompt") then applyPrompt(d) end
end)

-- Fullbright
local originalLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
}
local function setFullbright(on)
	if on then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 1e6
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(178, 178, 178)
	else
		for prop, value in pairs(originalLighting) do
			Lighting[prop] = value
		end
	end
end

-- Player ESP (options: names, HP, distance, outline, tracers)
local espEnabled = false
local espOpts = { names = true, health = true, distance = true, outline = true, tracers = false }
local espObjects = {}

local function removeESP(plr)
	local data = espObjects[plr]
	if data then
		data.highlight:Destroy()
		data.billboard:Destroy()
		data.line:Destroy()
		espObjects[plr] = nil
	end
end

local function addESP(plr)
	if plr == player or not espEnabled then return end
	removeESP(plr)

	local character = plr.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not head or not root then return end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = ACCENT
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = ACCENT
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = espOpts.outline
	highlight.Parent = character

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = head
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(150, 44)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.Parent = head

	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.Size = UDim2.fromScale(1, 1)
	tag.Font = FONT_MONO
	tag.TextSize = 13
	tag.TextColor3 = ACCENT
	tag.TextStrokeTransparency = 0.5
	tag.Text = ""
	tag.Parent = billboard

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.BackgroundColor3 = ACCENT
	line.BackgroundTransparency = 0.35
	line.BorderSizePixel = 0
	line.Visible = false
	line.Parent = tracerGui

	espObjects[plr] = {
		highlight = highlight, billboard = billboard, label = tag,
		line = line, humanoid = humanoid, root = root,
	}
end

local function hookPlayer(plr)
	if plr == player then return end
	connect(plr.CharacterAdded, function()
		task.wait()
		addESP(plr)
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
connect(Players.PlayerAdded, hookPlayer)
connect(Players.PlayerRemoving, removeESP)

onAccent(function(c)
	for _, data in pairs(espObjects) do
		data.highlight.FillColor = c
		data.highlight.OutlineColor = c
		data.line.BackgroundColor3 = c
	end
end)

connect(RunService.RenderStepped, function()
	if not espEnabled then return end
	local viewport = camera.ViewportSize
	local origin = Vector2.new(viewport.X / 2, viewport.Y)
	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

	for plr, data in pairs(espObjects) do
		local hum = data.humanoid
		if hum and hum.Parent and data.root.Parent then
			-- text
			local lines = {}
			if espOpts.names then table.insert(lines, plr.DisplayName) end
			local info = {}
			if espOpts.health then table.insert(info, math.max(0, math.floor(hum.Health + 0.5)) .. " HP") end
			if espOpts.distance then
				local dist = myRoot and math.floor((myRoot.Position - data.root.Position).Magnitude) or 0
				table.insert(info, dist .. "m")
			end
			if #info > 0 then table.insert(lines, table.concat(info, "  •  ")) end
			data.label.Text = table.concat(lines, "\n")

			local ratio = hum.MaxHealth > 0 and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0
			data.label.TextColor3 = DANGER:Lerp(ACCENT, ratio)
			data.highlight.Enabled = espOpts.outline

			-- tracer
			local screen, onScreen = camera:WorldToViewportPoint(data.root.Position)
			if espOpts.tracers and onScreen and screen.Z > 0 then
				local target = Vector2.new(screen.X, screen.Y)
				local delta = target - origin
				data.line.Size = UDim2.fromOffset(delta.Magnitude, 1.5)
				data.line.Position = UDim2.fromOffset((origin.X + target.X) / 2, (origin.Y + target.Y) / 2)
				data.line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
				data.line.Visible = true
			else
				data.line.Visible = false
			end
		end
	end
end)

local function setESP(on)
	espEnabled = on
	for _, plr in ipairs(Players:GetPlayers()) do
		if on then addESP(plr) else removeESP(plr) end
	end
end

-- Freecam (character stays put, camera flies around)
-- Right-click + drag to look, WASD to move, Space/E up, Ctrl/Q down, Shift = faster
local freecam = {
	enabled = false, looking = false, yaw = 0, pitch = 0,
	pos = Vector3.zero, speed = 50, exitAfterTp = false,
}
local FREECAM_SINK = "HackGuiFreecamSink"
local freecamGoRow -- the "Go to Freecam" row, only shown while freecam is on

local function setFreecam(on)
	camera = workspace.CurrentCamera
	freecam.enabled = on
	if freecamGoRow then freecamGoRow.Visible = on end
	if on then
		local cf = camera.CFrame
		freecam.pos = cf.Position
		freecam.pitch, freecam.yaw = cf:ToOrientation()
		camera.CameraType = Enum.CameraType.Scriptable

		-- swallow movement keys so the character doesn't walk around while you look around
		ContextActionService:BindActionAtPriority(
			FREECAM_SINK,
			function() return Enum.ContextActionResult.Sink end,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
			Enum.KeyCode.Space, Enum.KeyCode.Q, Enum.KeyCode.E,
			Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift
		)
	else
		ContextActionService:UnbindAction(FREECAM_SINK)
		freecam.looking = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		camera.CameraType = Enum.CameraType.Custom
	end
end

connect(UserInputService.InputBegan, function(input, gameProcessed)
	if freecam.enabled and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
		freecam.looking = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end)
connect(UserInputService.InputEnded, function(input)
	if freecam.looking and input.UserInputType == Enum.UserInputType.MouseButton2 then
		freecam.looking = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)
connect(UserInputService.InputChanged, function(input)
	if freecam.enabled and freecam.looking and input.UserInputType == Enum.UserInputType.MouseMovement then
		freecam.yaw -= input.Delta.X * 0.003
		freecam.pitch = math.clamp(freecam.pitch - input.Delta.Y * 0.003, math.rad(-85), math.rad(85))
	end
end)

-- Fly
-- WASD moves relative to where the camera looks, Space/E up, Ctrl/Q down
local fly = { enabled = false, speed = 60, lv = nil, ao = nil, att = nil }

local function destroyFly()
	for _, k in ipairs({ "lv", "ao", "att" }) do
		if fly[k] then
			fly[k]:Destroy()
			fly[k] = nil
		end
	end
	local humanoid = getHumanoid()
	if humanoid then humanoid.PlatformStand = false end
end

local function buildFly()
	destroyFly()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = getHumanoid()
	if not root or not humanoid then return end

	local att = Instance.new("Attachment")
	att.Name = "HackGuiFlyAttachment"
	att.Parent = root

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = math.huge
	lv.VectorVelocity = Vector3.zero
	lv.Parent = root

	local ao = Instance.new("AlignOrientation")
	ao.Attachment0 = att
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.RigidityEnabled = true
	ao.CFrame = root.CFrame.Rotation
	ao.Parent = root

	humanoid.PlatformStand = true
	fly.att, fly.lv, fly.ao = att, lv, ao
end

local function setFly(on)
	fly.enabled = on
	if on then buildFly() else destroyFly() end
end

-- Click Teleport: hold the bound key and left-click anywhere
local clickTp = { enabled = false, key = Enum.KeyCode.T }

connect(UserInputService.InputBegan, function(input)
	if listeningForKey or not clickTp.enabled then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not keyDown(clickTp.key) then return end

	local mouse = UserInputService:GetMouseLocation()

	-- ignore clicks that land on the menu itself
	if main.Visible then
		local p, s = main.AbsolutePosition, main.AbsoluteSize
		if mouse.X >= p.X and mouse.X <= p.X + s.X and mouse.Y >= p.Y and mouse.Y <= p.Y + s.Y then
			return
		end
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local cam = workspace.CurrentCamera
	local ray = cam:ViewportPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
	if result then
		root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) * root.CFrame.Rotation
	end
end)

-- Per-frame loop for freecam + fly
connect(RunService.RenderStepped, function(dt)
	camera = workspace.CurrentCamera
	local typing = UserInputService:GetFocusedTextBox() ~= nil

	local function axis(pos, neg)
		return (keyDown(pos) and 1 or 0) - (keyDown(neg) and 1 or 0)
	end
	local upHeld = keyDown(Enum.KeyCode.Space) or keyDown(Enum.KeyCode.E)
	local downHeld = keyDown(Enum.KeyCode.LeftControl) or keyDown(Enum.KeyCode.Q)
	local vertical = (upHeld and 1 or 0) - (downHeld and 1 or 0)

	if freecam.enabled then
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		local rot = CFrame.fromOrientation(freecam.pitch, freecam.yaw, 0)
		local move = Vector3.zero
		if not typing then
			local localMove = Vector3.new(axis(Enum.KeyCode.D, Enum.KeyCode.A), 0, axis(Enum.KeyCode.S, Enum.KeyCode.W))
			move = rot:VectorToWorldSpace(localMove) + Vector3.new(0, vertical, 0)
		end
		if move.Magnitude > 0 then move = move.Unit end
		local boost = keyDown(Enum.KeyCode.LeftShift) and 3 or 1
		freecam.pos += move * freecam.speed * boost * dt
		camera.CFrame = CFrame.new(freecam.pos) * rot
	end

	if fly.enabled then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = getHumanoid()
		if root and humanoid and humanoid.Health > 0 then
			if not fly.lv or not fly.lv.Parent then buildFly() end
			if fly.lv then
				local dir = Vector3.zero
				if not typing and not freecam.enabled then
					local cf = camera.CFrame
					dir = cf.LookVector * axis(Enum.KeyCode.W, Enum.KeyCode.S)
						+ cf.RightVector * axis(Enum.KeyCode.D, Enum.KeyCode.A)
						+ Vector3.new(0, vertical, 0)
					if dir.Magnitude > 0 then dir = dir.Unit end

					local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
					if flat.Magnitude > 0.05 then
						fly.ao.CFrame = CFrame.lookAt(Vector3.zero, flat)
					end
				end
				fly.lv.VectorVelocity = dir * fly.speed
			end
		end
	end
end)

-- Spectate / teleport to players
local spectating = nil

local function stopSpectate()
	if spectating then log("Stopped spectating", MUTED) end
	spectating = nil
	local humanoid = getHumanoid()
	if humanoid then camera.CameraSubject = humanoid end
end

local function spectate(plr)
	local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
		spectating = plr
		log("Spectating " .. plr.DisplayName)
	end
end

local function teleportToPlayer(plr)
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local theirRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if myRoot and theirRoot then
		myRoot.CFrame = CFrame.new(theirRoot.Position + Vector3.new(0, 3, 0))
		log("Teleported to " .. plr.DisplayName)
	end
end

-- ============================================================
-- BUILD THE MENU (add your own features here)
-- ============================================================
local freecamModule

-- PLAYER tab
makeSlider(playerPage, 1, "Walkspeed", 1, 100, 16, function(v)
	appliedSpeed = v
	local humanoid = getHumanoid()
	if humanoid then humanoid.WalkSpeed = v end
	log("Walkspeed set to " .. v)
end)

makeSlider(playerPage, 2, "Jump Power", 1, 150, 50, function(v)
	appliedJump = v
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = v
	end
	log("Jump Power set to " .. v)
end)

makeSlider(playerPage, 3, "Gravity", 0, 300, math.round(originalGravity), function(v)
	gravityChanged = true
	workspace.Gravity = v
end, true)

makeCheckbox(playerPage, 4, "Infinite Jump", "Jump again while in mid-air", function(on) infiniteJump = on end)
makeCheckbox(playerPage, 5, "Noclip", "Walk straight through walls", setNoclip)

local flyModule = makeModule(playerPage, 6, "Fly", "WASD + Space/E up, Ctrl/Q down", setFly)
makeSlider(flyModule.body, 1, "Fly Speed", 10, 200, 60, function(v) fly.speed = v end, true)

local clickTpModule = makeModule(playerPage, 7, "Click Teleport", "Hold the key, then click to teleport", function(on)
	clickTp.enabled = on
end)
makeKeybind(clickTpModule.body, 1, "Click TP Key", "Hold this while clicking", clickTp.key, function(newKey)
	clickTp.key = newKey
end)

local instantModule = makeModule(playerPage, 8, "Instant Interact", "No hold time on prompts, longer reach", setInstantInteract)
makeSlider(instantModule.body, 1, "Reach Multiplier", 1, 10, 1, function(v)
	promptRange = v
	if instantOn then
		for p, orig in pairs(promptOrig) do
			if p.Parent then p.MaxActivationDistance = orig.dist * promptRange end
		end
	end
end, true)

makeCheckbox(playerPage, 9, "Anti-AFK", "Stops the idle kick", function(on) antiAfk = on end)

local playersModule = makeModule(playerPage, 10, "Players", "Teleport to or spectate other players", function() end, false)
makeButton(playersModule.body, 1, "Stop Spectating", "Return the camera to yourself", "RESET CAMERA", stopSpectate)

local playerRows = {}
local rowCounter = 10

local function smallButton(parent, text, rightOffset, width, callback)
	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, rightOffset, 0.5, 0)
	btn.Size = UDim2.fromOffset(width, 24)
	btn.BackgroundColor3 = ELEMENT
	btn.AutoButtonColor = false
	btn.Font = FONT_BOLD
	btn.Text = text
	btn.TextColor3 = TEXT
	btn.TextSize = 11
	btn.Parent = parent
	corner(btn, 6)
	connect(btn.MouseEnter, function() tween(btn, 0.1, { BackgroundColor3 = ELEMENT_HOVER }) end)
	connect(btn.MouseLeave, function() tween(btn, 0.1, { BackgroundColor3 = ELEMENT }) end)
	connect(btn.MouseButton1Click, callback)
end

local function addPlayerRow(plr)
	if plr == player or playerRows[plr] then return end
	rowCounter += 1

	local row = Instance.new("Frame")
	row.LayoutOrder = rowCounter
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3 = NESTED_BG
	row.BorderSizePixel = 0
	row.Parent = playersModule.body
	corner(row, 9)

	local nameLabel = label(row, plr.DisplayName, 13, TEXT, FONT)
	nameLabel.Position = UDim2.fromOffset(14, 0)
	nameLabel.Size = UDim2.new(1, -140, 1, 0)
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

	smallButton(row, "TP", -76, 48, function() teleportToPlayer(plr) end)
	smallButton(row, "VIEW", -12, 56, function() spectate(plr) end)

	playerRows[plr] = row
end

for _, plr in ipairs(Players:GetPlayers()) do addPlayerRow(plr) end
connect(Players.PlayerAdded, addPlayerRow)
connect(Players.PlayerRemoving, function(plr)
	if playerRows[plr] then
		playerRows[plr]:Destroy()
		playerRows[plr] = nil
	end
	if spectating == plr then stopSpectate() end
end)

-- VISUALS tab
local espModule = makeModule(visualsPage, 1, "Player ESP", "Highlights players through walls", setESP)
makeCheckbox(espModule.body, 1, "Names", "Show display names", function(on) espOpts.names = on end, true)
makeCheckbox(espModule.body, 2, "Health", "Show HP", function(on) espOpts.health = on end, true)
makeCheckbox(espModule.body, 3, "Distance", "Show distance in studs", function(on) espOpts.distance = on end, true)
makeCheckbox(espModule.body, 4, "Outline", "Glowing player outline", function(on) espOpts.outline = on end, true)
makeCheckbox(espModule.body, 5, "Tracers", "Lines from the bottom of the screen", function(on) espOpts.tracers = on end)

makeCheckbox(visualsPage, 2, "Fullbright", "Removes darkness and shadows", setFullbright)

makeSlider(visualsPage, 3, "Field of View", 30, 120, math.round(originalFOV), function(v)
	fovChanged = true
	camera.FieldOfView = v
end, true)

freecamModule = makeModule(visualsPage, 4, "Freecam", "Right-click + drag to look, your player stays put", setFreecam)
makeSlider(freecamModule.body, 1, "Freecam Speed", 5, 200, 50, function(v) freecam.speed = v end, true)
makeCheckbox(freecamModule.body, 2, "Exit After Teleport", "Leave freecam when you teleport to it", function(on)
	freecam.exitAfterTp = on
end)
freecamGoRow = makeButton(freecamModule.body, 3, "Go to Freecam", "Teleport your player to the camera", "TELEPORT", function()
	if not freecam.enabled then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	root.CFrame = CFrame.new(freecam.pos) * CFrame.Angles(0, freecam.yaw, 0)
	root.AssemblyLinearVelocity = Vector3.zero
	log("Teleported to freecam")
	if freecam.exitAfterTp then freecamModule.set(false) end
end)
freecamGoRow.Visible = false

-- CUSTOMIZE tab
local swatchColors = {
	Color3.fromRGB(0, 255, 170),   -- mint (default)
	Color3.fromRGB(0, 200, 255),   -- cyan
	Color3.fromRGB(80, 120, 255),  -- blue
	Color3.fromRGB(170, 100, 255), -- purple
	Color3.fromRGB(255, 90, 190),  -- pink
	Color3.fromRGB(255, 85, 100),  -- red
	Color3.fromRGB(255, 150, 50),  -- orange
	Color3.fromRGB(255, 220, 60),  -- yellow
}

local swatchCard = Instance.new("Frame")
swatchCard.LayoutOrder = 1
swatchCard.Size = UDim2.new(1, 0, 0, 84)
swatchCard.BackgroundColor3 = ELEMENT
swatchCard.BorderSizePixel = 0
swatchCard.Parent = customizePage
corner(swatchCard, 9)

local swatchTitle = label(swatchCard, "Accent Colour", 13, TEXT, FONT)
swatchTitle.Position = UDim2.fromOffset(14, 10)
swatchTitle.Size = UDim2.new(1, -28, 0, 18)

local swatchRow = Instance.new("Frame")
swatchRow.BackgroundTransparency = 1
swatchRow.Position = UDim2.fromOffset(14, 40)
swatchRow.Size = UDim2.new(1, -28, 0, 28)
swatchRow.Parent = swatchCard

local swatchLayout = Instance.new("UIListLayout")
swatchLayout.FillDirection = Enum.FillDirection.Horizontal
swatchLayout.Padding = UDim.new(0, 12)
swatchLayout.SortOrder = Enum.SortOrder.LayoutOrder
swatchLayout.Parent = swatchRow

local swatches = {}
local hueSet -- assigned below once the hue slider exists

local function selectSwatch(index)
	for i, s in ipairs(swatches) do
		tween(s.ring, 0.12, { Transparency = (i == index) and 0 or 1 })
	end
end

for i, color in ipairs(swatchColors) do
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = i
	btn.Size = UDim2.fromOffset(28, 28)
	btn.BackgroundColor3 = color
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.Parent = swatchRow
	corner(btn, 14)
	local ring = stroke(btn, TEXT, (i == 1) and 0 or 1, 2)
	swatches[i] = { button = btn, ring = ring }

	connect(btn.MouseButton1Click, function()
		setAccent(color)
		selectSwatch(i)
		if hueSet then hueSet(math.round((color:ToHSV()) * 360)) end
	end)
end

hueSet = makeSlider(customizePage, 2, "Custom Hue", 0, 360, math.round((ACCENT:ToHSV()) * 360), function(v)
	setAccent(Color3.fromHSV(v / 360, 1, 1))
	selectSwatch(0)
end, true)

selectTab("PLAYER")
log("HACK.EXE v1.2 loaded")
log("Press X to hide or show the menu", MUTED)

-- ============================================================
-- Draggable window
-- ============================================================
do
	local draggingWindow, dragStart, startPos
	connect(titleBar.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			draggingWindow = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if draggingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			draggingWindow = false
		end
	end)
end

-- ============================================================
-- Open / close (X key), mouse unlock, auto-open
-- ============================================================
local open = false

local function setOpen(state)
	open = state
	if open then
		main.Visible = true
		tween(scale, 0.2, { Scale = 1 })
	else
		local t = tween(scale, 0.15, { Scale = 0.92 })
		t.Completed:Once(function()
			if not open then main.Visible = false end
		end)
	end
end

connect(UserInputService.InputBegan, function(input)
	if input.KeyCode ~= TOGGLE_KEY then return end
	if listeningForKey then return end -- don't toggle while binding a key
	if UserInputService:GetFocusedTextBox() then return end
	setOpen(not open)
end)

-- While the menu is open, keep the mouse free (shift lock / first person try to lock it every frame,
-- so this runs right after the camera scripts). Freecam's right-click look is left alone.
local MOUSE_STEP = "HackGuiMouseUnlock"
RunService:BindToRenderStep(MOUSE_STEP, Enum.RenderPriority.Camera.Value + 1, function()
	if open and not freecam.looking then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)

-- ============================================================
-- Unload
-- ============================================================
local unloaded = false
local function unload()
	if unloaded then return end
	unloaded = true

	RunService:UnbindFromRenderStep(MOUSE_STEP)

	-- switch every module off (fly, freecam, noclip, esp, instant interact, ...)
	for _, off in ipairs(disableCallbacks) do off() end
	stopSpectate()

	local humanoid = getHumanoid()
	if humanoid then
		if appliedSpeed then humanoid.WalkSpeed = originalSpeed end
		if appliedJump then humanoid.JumpPower = originalJump end
	end
	appliedSpeed, appliedJump = nil, nil

	if fovChanged then camera.FieldOfView = originalFOV end
	if gravityChanged then workspace.Gravity = originalGravity end

	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)

	tracerGui:Destroy()
	gui:Destroy()
end

closeBtn.MouseButton1Click:Connect(unload)

-- Open the menu automatically when the script starts
setOpen(true)

