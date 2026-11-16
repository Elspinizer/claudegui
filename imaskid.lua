local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MIN_SPEED, MAX_SPEED = 1, 100
local TOGGLE_KEY = Enum.KeyCode.X

local selectedValue = 16
local appliedSpeed = nil

-- Palette
local BG = Color3.fromRGB(14, 16, 20)
local PANEL = Color3.fromRGB(22, 25, 31)
local ACCENT = Color3.fromRGB(0, 255, 170)
local TEXT = Color3.fromRGB(225, 230, 235)
local MUTED = Color3.fromRGB(120, 128, 140)
local DANGER = Color3.fromRGB(255, 85, 100)

-- Every connection goes through here so unloading can disconnect them all
local connections = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function getHumanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local originalSpeed = (getHumanoid() and getHumanoid().WalkSpeed) or 16

-- ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "HackGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

-- Main window
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(320, 330)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui
corner(main, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = ACCENT
stroke.Transparency = 0.6
stroke.Thickness = 1
stroke.Parent = main

local scale = Instance.new("UIScale")
scale.Scale = 0.9
scale.Parent = main

-- Title bar (also the drag handle)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = PANEL
titleBar.BorderSizePixel = 0
titleBar.Parent = main
corner(titleBar, 10)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = PANEL
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(8, 8)
dot.Position = UDim2.new(0, 14, 0.5, -4)
dot.BackgroundColor3 = ACCENT
dot.BorderSizePixel = 0
dot.Parent = titleBar
corner(dot, 4)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(30, 0)
title.Size = UDim2.new(1, -70, 1, 0)
title.Font = Enum.Font.Code
title.Text = "im claude carried"
title.TextColor3 = TEXT
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Close (unload) button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(26, 26)
closeBtn.Position = UDim2.new(1, -32, 0.5, -13)
closeBtn.BackgroundTransparency = 1
closeBtn.AutoButtonColor = false
closeBtn.Font = Enum.Font.Code
closeBtn.Text = "X"
closeBtn.TextColor3 = MUTED
closeBtn.TextSize = 15
closeBtn.Parent = titleBar
corner(closeBtn, 6)

connect(closeBtn.MouseEnter, function()
	TweenService:Create(closeBtn, TweenInfo.new(0.12), { TextColor3 = DANGER }):Play()
end)
connect(closeBtn.MouseLeave, function()
	TweenService:Create(closeBtn, TweenInfo.new(0.12), { TextColor3 = MUTED }):Play()
end)

-- Speed label + value readout
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Position = UDim2.fromOffset(20, 50)
label.Size = UDim2.fromOffset(150, 20)
label.Font = Enum.Font.Code
label.Text = "WALKSPEED"
label.TextColor3 = MUTED
label.TextSize = 13
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = main

local valueLabel = Instance.new("TextLabel")
valueLabel.BackgroundTransparency = 1
valueLabel.Position = UDim2.new(1, -90, 0, 50)
valueLabel.Size = UDim2.fromOffset(70, 20)
valueLabel.Font = Enum.Font.Code
valueLabel.Text = tostring(selectedValue)
valueLabel.TextColor3 = ACCENT
valueLabel.TextSize = 16
valueLabel.TextXAlignment = Enum.TextXAlignment.Right
valueLabel.Parent = main

-- Slider
local track = Instance.new("Frame")
track.Name = "Track"
track.Position = UDim2.fromOffset(20, 88)
track.Size = UDim2.new(1, -40, 0, 6)
track.BackgroundColor3 = PANEL
track.BorderSizePixel = 0
track.Parent = main
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

local hitbox = Instance.new("TextButton")
hitbox.BackgroundTransparency = 1
hitbox.Text = ""
hitbox.Position = UDim2.fromOffset(20, 76)
hitbox.Size = UDim2.new(1, -40, 0, 30)
hitbox.ZIndex = 3
hitbox.Parent = main

-- Apply button
local apply = Instance.new("TextButton")
apply.Position = UDim2.fromOffset(20, 116)
apply.Size = UDim2.new(1, -40, 0, 32)
apply.BackgroundColor3 = ACCENT
apply.AutoButtonColor = false
apply.Font = Enum.Font.Code
apply.Text = "APPLY"
apply.TextColor3 = BG
apply.TextSize = 15
apply.Parent = main
corner(apply, 6)

-- Divider + modules header
local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(20, 164)
divider.Size = UDim2.new(1, -40, 0, 1)
divider.BackgroundColor3 = PANEL
divider.BorderSizePixel = 0
divider.Parent = main

local modulesLabel = Instance.new("TextLabel")
modulesLabel.BackgroundTransparency = 1
modulesLabel.Position = UDim2.fromOffset(20, 172)
modulesLabel.Size = UDim2.fromOffset(150, 18)
modulesLabel.Font = Enum.Font.Code
modulesLabel.Text = "MODULES"
modulesLabel.TextColor3 = MUTED
modulesLabel.TextSize = 13
modulesLabel.TextXAlignment = Enum.TextXAlignment.Left
modulesLabel.Parent = main

-- Slider logic
local function setFromAlpha(alpha)
	alpha = math.clamp(alpha, 0, 1)
	selectedValue = math.round(MIN_SPEED + alpha * (MAX_SPEED - MIN_SPEED))
	local snapped = (selectedValue - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
	fill.Size = UDim2.fromScale(snapped, 1)
	knob.Position = UDim2.fromScale(snapped, 0.5)
	valueLabel.Text = tostring(selectedValue)
end

local function updateFromX(x)
	setFromAlpha((x - track.AbsolutePosition.X) / track.AbsoluteSize.X)
end

local dragging = false

connect(hitbox.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
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
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

setFromAlpha((selectedValue - MIN_SPEED) / (MAX_SPEED - MIN_SPEED))

-- Apply logic
connect(apply.MouseEnter, function()
	TweenService:Create(apply, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 255, 200) }):Play()
end)
connect(apply.MouseLeave, function()
	TweenService:Create(apply, TweenInfo.new(0.15), { BackgroundColor3 = ACCENT }):Play()
end)

connect(apply.MouseButton1Click, function()
	appliedSpeed = selectedValue
	local humanoid = getHumanoid()
	if humanoid then humanoid.WalkSpeed = appliedSpeed end
	apply.Text = "APPLIED"
	task.delay(0.8, function()
		if apply.Parent then apply.Text = "APPLY" end
	end)
end)

connect(player.CharacterAdded, function(character)
	local humanoid = character:WaitForChild("Humanoid")
	if appliedSpeed then humanoid.WalkSpeed = appliedSpeed end
end)

-- ============================================================
-- REUSABLE CHECKBOX
-- makeCheckbox("Label", rowIndex, function(enabled) ... end)
-- Returns a function you can call to set the state in code: setter(true/false)
-- ============================================================
local CHECKBOX_START_Y = 196
local CHECKBOX_ROW_HEIGHT = 30
local disableCallbacks = {} -- used on unload to switch everything off

local function makeCheckbox(text, rowIndex, callback)
	local checked = false

	local row = Instance.new("TextButton")
	row.BackgroundTransparency = 1
	row.AutoButtonColor = false
	row.Text = ""
	row.Position = UDim2.fromOffset(20, CHECKBOX_START_Y + (rowIndex - 1) * CHECKBOX_ROW_HEIGHT)
	row.Size = UDim2.new(1, -40, 0, 26)
	row.Parent = main

	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(18, 18)
	box.Position = UDim2.new(0, 0, 0.5, -9)
	box.BackgroundColor3 = PANEL
	box.BorderSizePixel = 0
	box.Parent = row
	corner(box, 4)

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = MUTED
	boxStroke.Thickness = 1
	boxStroke.Parent = box

	local tick = Instance.new("Frame")
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5, 0.5)
	tick.Size = UDim2.fromOffset(0, 0)
	tick.BackgroundColor3 = ACCENT
	tick.BorderSizePixel = 0
	tick.Parent = box
	corner(tick, 3)

	local text_ = Instance.new("TextLabel")
	text_.BackgroundTransparency = 1
	text_.Position = UDim2.fromOffset(28, 0)
	text_.Size = UDim2.new(1, -28, 1, 0)
	text_.Font = Enum.Font.Code
	text_.Text = text
	text_.TextColor3 = TEXT
	text_.TextSize = 14
	text_.TextXAlignment = Enum.TextXAlignment.Left
	text_.Parent = row

	local function set(value)
		checked = value
		TweenService:Create(tick, TweenInfo.new(0.12), {
			Size = checked and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
		}):Play()
		TweenService:Create(boxStroke, TweenInfo.new(0.12), {
			Color = checked and ACCENT or MUTED,
		}):Play()
		callback(checked)
	end

	connect(row.MouseButton1Click, function() set(not checked) end)
	table.insert(disableCallbacks, function()
		if checked then callback(false) end
	end)

	return set
end

-- ============================================================
-- FEATURES
-- ============================================================

-- 1) Infinite Jump
local infiniteJump = false
connect(UserInputService.JumpRequest, function()
	if infiniteJump then
		local humanoid = getHumanoid()
		if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- 2) Noclip
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

-- 3) Fullbright
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

-- 4) Player ESP (game-specific: in a game where everyone is hacking,
--    seeing where everyone is through walls is the most useful edge)
local espEnabled = false
local espHighlights = {}

local function removeESP(plr)
	if espHighlights[plr] then
		espHighlights[plr]:Destroy()
		espHighlights[plr] = nil
	end
end

local function addESP(plr)
	if plr == player or not espEnabled then return end
	removeESP(plr)
	local character = plr.Character
	if not character then return end
	local h = Instance.new("Highlight")
	h.FillColor = ACCENT
	h.FillTransparency = 0.75
	h.OutlineColor = ACCENT
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = character
	espHighlights[plr] = h
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

local function setESP(on)
	espEnabled = on
	for _, plr in ipairs(Players:GetPlayers()) do
		if on then addESP(plr) else removeESP(plr) end
	end
end

-- Add the checkboxes (row number, then what happens)
makeCheckbox("Infinite Jump", 1, function(on) infiniteJump = on end)
makeCheckbox("Noclip", 2, setNoclip)
makeCheckbox("Fullbright", 3, setFullbright)
makeCheckbox("Player ESP", 4, setESP)

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
-- Toggle with X
-- ============================================================
local open = false

connect(UserInputService.InputBegan, function(input)
	if input.KeyCode ~= TOGGLE_KEY then return end
	if UserInputService:GetFocusedTextBox() then return end

	open = not open
	if open then
		main.Visible = true
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	else
		local tween = TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 0.9 })
		tween:Play()
		tween.Completed:Once(function()
			if not open then main.Visible = false end
		end)
	end
end)

-- ============================================================
-- Unload (the X button in the corner)
-- ============================================================
local unloaded = false
local function unload()
	if unloaded then return end
	unloaded = true

	-- switch every module off so nothing is left behind
	for _, off in ipairs(disableCallbacks) do off() end

	-- restore walkspeed
	local humanoid = getHumanoid()
	if humanoid and appliedSpeed then humanoid.WalkSpeed = originalSpeed end
	appliedSpeed = nil

	-- disconnect everything (this is what stops the X key from toggling)
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)

	gui:Destroy()
end

closeBtn.MouseButton1Click:Connect(unload)
