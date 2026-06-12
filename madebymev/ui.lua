--[[
	compass.lol UI Library
	Single-file module. Use as a ModuleScript or via loadstring.
	
	Usage:
		local Compass = require(path.to.Compass)
		local Window = Compass:CreateWindow({ Name = "compass.lol" })
		local Tab = Window:CreateTab("Main", "rbxassetid://10723407389")
		Tab:AddToggle({ Name = "Toggle", Default = false, Callback = function(State) end })
		Tab:AddButton({ Name = "Click", Callback = function() end })
		Tab:AddLabel("Hello")
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Compass = {}
Compass.__index = Compass
Compass.Version = "1.0.0"

--// Theme
local Theme = {
	WindowBg = Color3.fromRGB(0, 0, 0),
	WindowBorder = Color3.fromRGB(12, 12, 12),
	MainBg = Color3.fromRGB(3, 3, 3),
	MainTransparency = 0.65,
	TabsBg = Color3.fromRGB(3, 3, 3),
	TabSelected = Color3.fromRGB(255, 255, 255),
	TabUnselected = Color3.fromRGB(150, 150, 150),
	ControlBg = Color3.fromRGB(13, 13, 13),
	ControlTransparency = 0.55,
	ControlText = Color3.fromRGB(164, 164, 164),
	ControlTextSize = 23,
	ToggleBg = Color3.fromRGB(19, 19, 19),
	ToggleKnob = Color3.fromRGB(255, 255, 255),
	Font = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
}

--// Utilities
local function new(class, props)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	return obj
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 8)
	c.Parent = parent
	return c
end

--// Tab
local Tab = {}
Tab.__index = Tab

function Tab.new(name, icon, tabContainer, theme)
	local self = setmetatable({}, Tab)
	self.Name = name
	self.Theme = theme
	self.Controls = {}
	self.Visible = true

	self.Button = new("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = icon or "", Size = UDim2.fromOffset(28, 27),
		Name = name,
	})

	self.Container = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(500, 10),
		Name = name .. "Container", Visible = false, Parent = tabContainer,
	})

	self._layout = new("UIListLayout", {
		Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Container,
	})

	self._layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local h = math.max(self._layout.AbsoluteContentSize.Y + 10, 10)
		self.Container.Size = UDim2.fromOffset(500, h)
	end)

	return self
end

function Tab:SetActive(active)
	self.Container.Visible = active
	self.Button.ImageColor3 = active and self.Theme.TabSelected or self.Theme.TabUnselected
end

function Tab:SetCallback(callback)
	self.Button.MouseButton1Click:Connect(function()
		if callback then callback(self) end
	end)
end

function Tab:SetIcon(icon)
	self.Button.Image = icon or ""
end

function Tab:SetName(name)
	self.Name = name
	self.Button.Name = name
end

function Tab:AddToggle(options)
	options = options or {}
	local name = options.Name or "Toggle"
	local default = options.Default or false
	local callback = options.Callback or function() end

	local frame = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = self.Theme.ControlBg,
		Size = UDim2.fromOffset(500, 41), Name = name,
		BackgroundTransparency = self.Theme.ControlTransparency,
		Parent = self.Container,
	})
	addCorner(frame, UDim.new(0, 5))

	local tog = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = self.Theme.ToggleBg,
		Size = UDim2.fromOffset(55, 24), Position = UDim2.new(0.87, 0, 0.16362, 0),
		BorderColor3 = self.Theme.ToggleBg, Name = "Main", Parent = frame,
	})
	addCorner(tog, UDim.new(0, 5))

	local offPos = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 21),
		Position = UDim2.fromOffset(0, 1), Name = "Off", Parent = tog,
	})
	addCorner(offPos, UDim.new(0, 5))

	local onPos = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 21),
		Position = UDim2.new(0.63182, 0, 0.08333, 0), Name = "On", Parent = tog,
	})
	addCorner(onPos, UDim.new(0, 5))

	local knob = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = self.Theme.ToggleKnob,
		Size = UDim2.fromOffset(20, 21), Position = UDim2.fromOffset(0, 1),
		Name = "Moving", Parent = tog,
	})
	addCorner(knob, UDim.new(0, 5))

	local hit = new("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = self.Theme.ToggleBg,
		Size = UDim2.fromOffset(55, 24), Name = "Hit", Parent = tog,
	})
	addCorner(hit, UDim.new(0, 5))

	local bigHit = new("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = self.Theme.ToggleBg,
		Size = UDim2.fromOffset(490, 40),
		Position = UDim2.new(-7.90909, 0, -0.27951, 0), Name = "BigHit", Parent = tog,
	})
	addCorner(bigHit, UDim.new(0, 5))

	new("TextLabel", {
		BorderSizePixel = 0, TextSize = self.Theme.ControlTextSize,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1,
		FontFace = self.Theme.Font, TextColor3 = self.Theme.ControlText,
		Size = UDim2.fromOffset(116, 27), Text = name,
		Position = UDim2.new(0.02, 0, 0.14634, 0), Parent = frame,
	})

	local isOn = default
	local animTime = 0.2

	local function getKnobX()
		local onX = onPos.AbsolutePosition.X
		local offX = offPos.AbsolutePosition.X
		local conX = tog.AbsolutePosition.X
		local t = isOn and (onX - conX) or (offX - conX)
		return (t ~= t) and (isOn and 35 or 0) or t
	end

	local function snap()
		local tween = TweenService:Create(knob, TweenInfo.new(animTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Position = UDim2.fromOffset(getKnobX(), knob.Position.Y.Offset)
		})
		tween:Play()
	end

	local function toggle()
		isOn = not isOn; snap(); task.spawn(callback, isOn)
	end

	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
	end)
	bigHit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
	end)

	task.wait(0.1)
	knob.Position = UDim2.fromOffset(default and getKnobX() or 0, knob.Position.Y.Offset)

	local ctrl = { Frame = frame }
	function ctrl:Set(state) isOn = state; snap() end
	function ctrl:Get() return isOn end
	function ctrl:Toggle() toggle() end
	table.insert(self.Controls, ctrl)
	return ctrl
end

function Tab:AddButton(options)
	options = options or {}
	local name = options.Name or "Button"
	local callback = options.Callback or function() end

	local frame = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = self.Theme.ControlBg,
		Size = UDim2.fromOffset(500, 41), Name = name,
		BackgroundTransparency = self.Theme.ControlTransparency,
		Parent = self.Container,
	})
	addCorner(frame, UDim.new(0, 5))

	new("TextLabel", {
		BorderSizePixel = 0, TextSize = self.Theme.ControlTextSize,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1,
		FontFace = self.Theme.Font, TextColor3 = self.Theme.ControlText,
		Size = UDim2.fromOffset(200, 27), Text = name,
		Position = UDim2.new(0.02, 0, 0.14634, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = frame,
	})

	local btn = new("ImageButton", {
		BorderSizePixel = 0, BackgroundColor3 = self.Theme.ToggleBg,
		Size = UDim2.fromOffset(55, 24), Position = UDim2.new(0.87, 0, 0.16362, 0),
		BorderColor3 = self.Theme.ToggleBg, Name = "Button", Parent = frame,
	})
	addCorner(btn, UDim.new(0, 5))

	btn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			task.spawn(callback)
		end
	end)

	local ctrl = { Frame = frame }
	table.insert(self.Controls, ctrl)
	return ctrl
end

function Tab:AddLabel(text)
	text = text or ""

	local label = new("TextLabel", {
		BorderSizePixel = 0, TextSize = 18,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1,
		FontFace = self.Theme.Font, TextColor3 = self.Theme.ControlText,
		Size = UDim2.fromOffset(500, 30), Text = text,
		Position = UDim2.new(0.02, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = self.Container,
	})

	local ctrl = { Frame = label }
	table.insert(self.Controls, ctrl)
	return ctrl
end

function Tab:Destroy()
	self.Button:Destroy()
	self.Container:Destroy()
end

function Tab:Clear()
	for _, ctrl in ipairs(self.Controls) do
		pcall(function() ctrl.Frame:Destroy() end)
	end
	table.clear(self.Controls)
end

--// Window
local Window = {}
Window.__index = Window

function Window.new(lib, options)
	local self = setmetatable({}, Window)
	self.Lib = lib
	self.Options = options or {}
	self.Tabs = {}
	self.ActiveTab = nil
	self._destroyed = false

	local name = self.Options.Name or "compass.lol"
	local size = self.Options.Size or UDim2.fromOffset(563, 462)
	local pos = self.Options.Position or UDim2.new(0.20873, 0, 0.20225, 0)

	-- ScreenGui
	self.ScreenGui = new("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})

	-- Main Frame
	self.Frame = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Theme.WindowBg,
		Size = size, Position = pos, BorderColor3 = Theme.WindowBorder,
		Name = "CompassFrame", Parent = self.ScreenGui,
	})
	addCorner(self.Frame, UDim.new(0, 8))

	-- Titlebar
	self:_buildTitlebar(name)

	-- Tabs sidebar
	self:_buildTabs()

	-- Main content
	self:_buildContent()

	-- Dragging
	self:_setupDrag()

	-- Viewport
	if self.Options.ShowViewport ~= false then
		self:_buildViewport()
	end

	-- Snowfall
	if self.Options.Snowfall ~= false then
		self:_startSnowfall()
	end

	return self
end

function Window:_buildTitlebar(name)
	-- Profile icon
	self._icon = new("ImageLabel", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		Size = UDim2.fromOffset(30, 31), Position = UDim2.new(0.01776, 0, 0.02165, 0),
		Parent = self.Frame,
	})
	addCorner(self._icon, UDim.new(0, 20))

	-- Load profile pic
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		if ok and content then self._icon.Image = content end
	end)

	-- Title
	new("TextLabel", {
		TextWrapped = true, BorderSizePixel = 0, TextSize = 19,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1,
		FontFace = Theme.Font, TextColor3 = Color3.fromRGB(182, 182, 182),
		Size = UDim2.fromOffset(111, 25), Text = name,
		Position = UDim2.new(0.08171, 0, 0.03463, 0), Parent = self.Frame,
	})

	-- Minimize
	self._minBtn = new("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "rbxassetid://10734896206",
		Size = UDim2.fromOffset(28, 27), Position = UDim2.new(0.8881, 0, 0.02165, 0),
		Name = "Minimize", Parent = self.Frame,
	})

	-- Close
	self._closeBtn = new("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "rbxassetid://10747384394",
		Size = UDim2.fromOffset(28, 27), Position = UDim2.new(0.93783, 0, 0.02165, 0),
		Name = "Close", Parent = self.Frame,
	})

	self._minimized = false
	self._origSize = self.Frame.Size
	self._origPos = self.Frame.Position

	self._closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)
	self._minBtn.MouseButton1Click:Connect(function() self:ToggleMinimize() end)
end

function Window:ToggleMinimize()
	self._minimized = not self._minimized
	if self._minimized then
		self._origSize = self.Frame.Size
		self._origPos = self.Frame.Position
		local t = TweenService:Create(self.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Size = UDim2.fromOffset(563, 40),
			Position = UDim2.new(self.Frame.Position.X.Scale, self.Frame.Position.X.Offset, 0.20225, 0),
		})
		t:Play()
		if self._main then self._main.Visible = false end
		if self._tabsFrame then self._tabsFrame.Visible = false end
		if self._viewport then self._viewport.frame.Visible = false end
	else
		local t = TweenService:Create(self.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Size = self._origSize, Position = self._origPos,
		})
		t:Play()
		t.Completed:Connect(function()
			if self._main then self._main.Visible = true end
			if self._tabsFrame then self._tabsFrame.Visible = true end
			if self._viewport then self._viewport.frame.Visible = true end
		end)
	end
end

function Window:Minimize()
	if not self._minimized then self:ToggleMinimize() end
end

function Window:Maximize()
	if self._minimized then self:ToggleMinimize() end
end

function Window:_buildTabs()
	self._tabsFrame = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Theme.TabsBg,
		Size = UDim2.fromOffset(40, 231), Position = UDim2.new(-0.09059, 0, 0.26623, 0),
		Name = "TabsFrame", Parent = self.Frame,
	})
	addCorner(self._tabsFrame, UDim.new(0, 8))

	self._tabScroll = new("ScrollingFrame", {
		Active = true, BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(40, 225),
		Position = UDim2.fromOffset(0, 5), ScrollBarThickness = 0,
		Parent = self._tabsFrame,
	})

	new("UIListLayout", {
		Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self._tabScroll,
	})
	new("UIPadding", {
		PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 7),
		Parent = self._tabScroll,
	})
end

function Window:_buildContent()
	self._main = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Theme.MainBg,
		Size = UDim2.fromOffset(520, 385), Position = UDim2.new(0.0373, 0, 0.12338, 0),
		BackgroundTransparency = Theme.MainTransparency, Name = "MainFrame",
		Parent = self.Frame,
	})
	addCorner(self._main, UDim.new(0, 8))

	self._scroll = new("ScrollingFrame", {
		Active = true, BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(520, 377),
		Position = UDim2.fromOffset(0, 7), ScrollBarThickness = 2,
		Parent = self._main,
	})
end

function Window:_setupDrag()
	local drag = { dragging = false, startPos = nil, lastMouse = nil, goal = nil, speed = 8 }

	local function lerp(a, b, m) return a + (b - a) * m end

	self.Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			drag.dragging = true
			drag.startPos = self.Frame.Position
			drag.lastMouse = UserInputService:GetMouseLocation()
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					drag.dragging = false
				end
			end)
		end
	end)

	self.Frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			-- just register the input
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		if not drag.startPos then return end
		if not drag.dragging and drag.goal then
			self.Frame.Position = UDim2.new(
				drag.startPos.X.Scale,
				lerp(self.Frame.Position.X.Offset, drag.goal.X.Offset, dt * drag.speed),
				drag.startPos.Y.Scale,
				lerp(self.Frame.Position.Y.Offset, drag.goal.Y.Offset, dt * drag.speed)
			)
			return
		end
		local delta = drag.lastMouse - UserInputService:GetMouseLocation()
		local xg = drag.startPos.X.Offset - delta.X
		local yg = drag.startPos.Y.Offset - delta.Y
		drag.goal = UDim2.new(drag.startPos.X.Scale, xg, drag.startPos.Y.Scale, yg)
		self.Frame.Position = UDim2.new(
			drag.startPos.X.Scale,
			lerp(self.Frame.Position.X.Offset, xg, dt * drag.speed),
			drag.startPos.Y.Scale,
			lerp(self.Frame.Position.Y.Offset, yg, dt * drag.speed)
		)
	end)
end

--// Viewport
function Window:_buildViewport()
	local vf = new("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.fromOffset(306, 431), Position = UDim2.new(1.01724, 0, 0.0335, 0),
		Name = "ViewportFrame", Parent = self.Frame,
	})
	addCorner(vf, UDim.new(0, 8))

	local vp = new("ViewportFrame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(313, 426),
		Position = UDim2.fromOffset(0, 1), Parent = vf,
	})

	local wm = Instance.new("WorldModel")
	wm.Parent = vp

	local cam = Instance.new("Camera")
	cam.CameraType = Enum.CameraType.Scriptable
	cam.Parent = vp
	vp.CurrentCamera = cam

	local light = Instance.new("PointLight")
	light.Range = 60; light.Brightness = 3; light.Parent = cam

	local state = {
		center = Vector3.new(0, 0, 0), distance = 8, height = 0,
		theta = math.pi, phi = 0.15, tTheta = math.pi, tPhi = 0.15,
		dTheta = math.pi, dPhi = 0.15, phiMin = -1.4, phiMax = 1.4,
		dragging = false, lmx = 0, lmy = 0, lastTime = 0,
		returnDelay = 1.5, smooth = 0.12, clone = nil,
	}

	local function updateCam()
		local x = math.sin(state.theta) * math.cos(state.phi) * state.distance
		local z = math.cos(state.theta) * math.cos(state.phi) * state.distance
		local y = math.sin(state.phi) * state.distance + state.height
		cam.CFrame = CFrame.new(state.center + Vector3.new(x, y, z), state.center)
	end

	local function frameModel(model)
		if not model then return end
		local cf, sz = model:GetBoundingBox()
		state.center = cf.Position
		state.distance = math.max(sz.X, sz.Y, sz.Z) * 1.4
		state.height = 0
		state.theta = state.dTheta; state.phi = state.dPhi
		state.tTheta = state.dTheta; state.tPhi = state.dPhi
		updateCam()
	end

	local function attachAcc(character, accessory)
		local handle = accessory:FindFirstChild("Handle")
		if not handle then return end
		local ha = handle:FindFirstChildWhichIsA("Attachment")
		if not ha then return end
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("Attachment") and d.Name == ha.Name then
				local p = d.Parent
				if p and p:IsA("BasePart") then
					handle.CFrame = p.CFrame * d.CFrame * ha.CFrame:Inverse()
					handle.Anchored = true
					return
				end
			end
		end
	end

	local function loadClone()
		if state.clone then return end
		local char = Players.LocalPlayer.Character
		if not char then return end
		char.Archivable = true
		for _, o in ipairs(char:GetDescendants()) do o.Archivable = true end

		local c = char:Clone()
		for _, o in ipairs(c:GetDescendants()) do
			if o:IsA("Script") or o:IsA("LocalScript") then
				o:Destroy()
			elseif o:IsA("BasePart") then
				o.CanCollide = false; o.CanQuery = false; o.CanTouch = false
			end
		end

		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = true; hum.JumpPower = 0; hum.WalkSpeed = 0; hum.AutoRotate = false
		end

		local root = c:FindFirstChild("HumanoidRootPart")
		if root then c.PrimaryPart = root; c:SetPrimaryPartCFrame(CFrame.new(0, 0, 0)) end

		for _, o in ipairs(c:GetDescendants()) do
			if o:IsA("BasePart") then o.Anchored = true end
		end
		for _, o in ipairs(c:GetDescendants()) do
			if o:IsA("Motor6D") or o:IsA("AnimationController") or o:IsA("Animator") then
				o:Destroy()
			end
		end

		c.Parent = wm; state.clone = c
		for _, acc in ipairs(c:GetChildren()) do
			if acc:IsA("Accessory") then attachAcc(c, acc) end
		end
		frameModel(c)
	end

	local function rebuildClone()
		if state.clone then state.clone:Destroy(); state.clone = nil end
		loadClone()
	end

	local function watchChar(char)
		if not char then return end
		local function onAdd(child)
			if child:IsA("Accessory") then
				task.wait(0.1)
				if not state.clone then return end
				if state.clone:FindFirstChild(child.Name) then return end
				local a = child:Clone()
				for _, o in ipairs(a:GetDescendants()) do
					if o:IsA("Script") or o:IsA("LocalScript") then o:Destroy()
					elseif o:IsA("BasePart") then o.Anchored = true; o.CanCollide = false; o.CanQuery = false; o.CanTouch = false end
				end
				a.Parent = state.clone; attachAcc(state.clone, a); frameModel(state.clone)
			elseif child:IsA("Shirt") or child:IsA("ShirtGraphic") or child:IsA("Pants") or child:IsA("BodyColors") then
				if not state.clone then return end
				local cls = child.ClassName
				local existing = state.clone:FindFirstChildWhichIsA(cls)
				if existing then existing:Destroy() end
				local n = child:Clone(); n.Parent = state.clone; frameModel(state.clone)
			elseif child:IsA("CharacterMesh") then
				if not state.clone then return end
				local e = state.clone:FindFirstChild(child.Name)
				if e then e:Destroy() end
				child:Clone().Parent = state.clone
			end
		end
		local function onRemove(child)
			if not state.clone then return end
			local c = state.clone:FindFirstChild(child.Name)
			if c then c:Destroy(); frameModel(state.clone) end
		end
		char.ChildAdded:Connect(onAdd)
		char.ChildRemoved:Connect(onRemove)
	end

	Players.LocalPlayer.CharacterAppearanceLoaded:Connect(function(char)
		task.wait(0.2); rebuildClone(); watchChar(char)
	end)
	if Players.LocalPlayer.Character then
		task.wait(0.5)
		if not state.clone then loadClone(); if state.clone then watchChar(Players.LocalPlayer.Character) end end
	end

	-- Input
	vp.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			state.dragging = true; state.lmx = i.Position.X; state.lmy = i.Position.Y; state.lastTime = tick()
		end
	end)
	vp.InputChanged:Connect(function(i)
		if state.dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			state.tTheta = state.tTheta - ((i.Position.X - state.lmx) * 0.01)
			state.tPhi = math.clamp(state.tPhi + ((i.Position.Y - state.lmy) * 0.01), state.phiMin, state.phiMax)
			state.lmx = i.Position.X; state.lmy = i.Position.Y; state.lastTime = tick()
		end
	end)
	vp.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			state.dragging = false; state.lastTime = tick()
		end
	end)
	vp.MouseLeave:Connect(function()
		if state.dragging then state.dragging = false; state.lastTime = tick() end
	end)

	-- Camera loop
	local function angleLerp(cur, tgt, f)
		local d = tgt - cur
		while d > math.pi do d = d - 2 * math.pi end
		while d < -math.pi do d = d + 2 * math.pi end
		return cur + d * f
	end

	RunService.RenderStepped:Connect(function()
		if not state.clone then return end
		if state.dragging then
			state.theta = angleLerp(state.theta, state.tTheta, state.smooth)
			state.phi = state.phi + (state.tPhi - state.phi) * state.smooth
			updateCam(); return
		end
		local idle = tick() - state.lastTime
		if idle >= state.returnDelay then
			state.tTheta = state.dTheta; state.tPhi = state.dPhi
			state.theta = angleLerp(state.theta, state.tTheta, 0.04)
			state.phi = state.phi + (state.tPhi - state.phi) * 0.04
		else
			state.theta = angleLerp(state.theta, state.tTheta, state.smooth)
			state.phi = state.phi + (state.tPhi - state.phi) * state.smooth
		end
		updateCam()
	end)

	vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		cam.ViewportSize = vp.AbsoluteSize
	end)
	cam.ViewportSize = vp.AbsoluteSize

	self._viewport = { frame = vf, viewport = vp, state = state, world = wm }
end

--// Snowfall
function Window:_startSnowfall()
	local flakes = {}
	local maxF = 240; local rate = 0.12; local running = true

	local function make()
		local sz = self.Frame.AbsoluteSize
		if sz.X <= 0 or sz.Y <= 0 then return end
		local size = math.random(2, 4)
		local pad = size + 14
		local uw = sz.X - pad * 2
		if uw <= 0 then return end
		local x = pad + math.random() * uw

		local dot = new("Frame", {
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.fromOffset(x, -size),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = math.random(30, 60) / 100,
			BorderSizePixel = 0, ZIndex = 0, Parent = self.Frame,
		})
		addCorner(dot, UDim.new(1, 0))

		table.insert(flakes, {
			object = dot, speed = math.random(12, 28),
			phase = math.random() * math.pi * 2, sx = x, y = -size, life = 0, size = size,
		})
	end

	task.spawn(function()
		while running and self.Frame.Parent do
			if #flakes < maxF then make() end
			task.wait(rate)
		end
	end)

	local con = RunService.RenderStepped:Connect(function(dt)
		local sz = self.Frame.AbsoluteSize
		if sz.Y <= 0 then return end
		for i = #flakes, 1, -1 do
			local d = flakes[i]
			if not d.object.Parent then
				table.remove(flakes, i)
			else
				d.life += dt; d.y += d.speed * dt
				local rx = d.sx + math.sin(d.life * 1.2 + d.phase) * 12
				local x = math.clamp(rx, d.size, sz.X - d.size)
				if d.y > sz.Y + d.size then
					d.object:Destroy(); table.remove(flakes, i)
				else
					d.object.Position = UDim2.fromOffset(x, d.y)
				end
			end
		end
	end)

	self._stopSnow = function()
		running = false; con:Disconnect()
		for _, d in ipairs(flakes) do
			if d.object and d.object.Parent then d.object:Destroy() end
		end
		table.clear(flakes)
	end
end

--// Public Window API
function Window:CreateTab(name, icon)
	local tab = Tab.new(name, icon, self._scroll, Theme)
	tab.Button.Parent = self._tabScroll
	tab:SetCallback(function(t)
		self:SelectTab(t.Name)
	end)
	self.Tabs[name] = tab
	if not self.ActiveTab then
		self:SelectTab(name)
	end
	return tab
end

function Window:RemoveTab(name)
	local tab = self.Tabs[name]
	if tab then
		if self.ActiveTab == tab then
			self.ActiveTab = nil
			-- select first available tab
			for k, t in pairs(self.Tabs) do
				if t ~= tab then self:SelectTab(k) break end
			end
		end
		tab:Destroy()
		self.Tabs[name] = nil
	end
end

function Window:SelectTab(name)
	if self.ActiveTab then self.ActiveTab:SetActive(false) end
	local tab = self.Tabs[name]
	if tab then
		self.ActiveTab = tab
		tab:SetActive(true)
	end
end

function Window:GetTab(name)
	return self.Tabs[name]
end

function Window:SetIcon(imageId)
	-- update profile icon
	self._icon.Image = imageId or "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

function Window:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	if self._stopSnow then self._stopSnow() end
	for _, tab in pairs(self.Tabs) do tab:Destroy() end
	if self._viewport and self._viewport.state and self._viewport.state.clone then
		self._viewport.state.clone:Destroy()
	end
	if self.ScreenGui then self.ScreenGui:Destroy() end
	self.Lib._windows[self] = nil
end

--// Library API
function Compass:CreateWindow(options)
	local win = Window.new(self, options)
	self._windows = self._windows or {}
	self._windows[win] = win
	return win
end

function Compass:DestroyAll()
	for win, _ in pairs(self._windows or {}) do
		win:Destroy()
	end
end

return Compass

