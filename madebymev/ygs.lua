--[[
	compass.lol UI Library
	
	HOW TO USE:
	
	local Compass = loadstring(game:HttpGet(
		"https://raw.githubusercontent.com/ccursedd/wsp.lat/refs/heads/main/madebymev/ui.lua"
	))()
	
	local Window = Compass:CreateWindow({ Name = "compass.lol" })
	
	local Tab = Window:CreateTab("Main", "rbxassetid://10723407389")
	Tab:AddToggle({ Name = "Toggle", Default = false, Callback = function(State) print(State) end })
	Tab:AddButton({ Name = "Click", Callback = function() print("clicked") end })
	Tab:AddLabel("Hello world")
	
	Window:Minimize()
	Window:Maximize()
	Window:Destroy()
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunSvc = game:GetService("RunService")
local TweenSvc = game:GetService("TweenService")

local function INS(className, props)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	return inst
end

-- helpers
local function C(parent, radius)
	local c = INS("UICorner")
	c.CornerRadius = radius or UDim.new(0, 8)
	c.Parent = parent
	return c
end

--=======================================================
--  THEME
--=======================================================
local T = {
	WinBg    = Color3.fromRGB(0, 0, 0),
	WinBrd   = Color3.fromRGB(12, 12, 12),
	MainBg   = Color3.fromRGB(3, 3, 3),
	MainTr   = 0.65,
	TabBg    = Color3.fromRGB(3, 3, 3),
	TabOn    = Color3.fromRGB(255, 255, 255),
	TabOff   = Color3.fromRGB(150, 150, 150),
	CtlBg    = Color3.fromRGB(13, 13, 13),
	CtlTr    = 0.55,
	CtlTx    = Color3.fromRGB(164, 164, 164),
	CtlSz    = 23,
	TogBg    = Color3.fromRGB(19, 19, 19),
	TogKnob  = Color3.fromRGB(255, 255, 255),
	Font     = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
}

--=======================================================
--  TAB
--=======================================================
local TabMT = {}
TabMT.__index = TabMT

function TabMT.New(name, icon)
	local self = setmetatable({}, TabMT)
	self.Name = name
	self.Buttons = {}  -- controls
	self.Container = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(500, 10),
		Visible = false, Name = name.."Container",
	})
	-- layout for controls inside this tab
	local lay = INS("UIListLayout", {
		Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Container,
	})
	lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.Container.Size = UDim2.fromOffset(500, math.max(lay.AbsoluteContentSize.Y + 10, 10))
	end)
	self._lay = lay
	-- sidebar button
	self.Button = INS("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Image = icon or "", Size = UDim2.fromOffset(28, 27),
		Name = name,
	})
	return self
end

function TabMT:SetActive(on)
	self.Container.Visible = on
	self.Button.ImageColor3 = on and T.TabOn or T.TabOff
end

function TabMT:SetIcon(id)
	self.Button.Image = id or ""
end

function TabMT:AddToggle(opt)
	opt = opt or {}
	local label = opt.Name or "Toggle"
	local def = opt.Default or false
	local cb = opt.Callback or function() end

	local f = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = T.CtlBg,
		Size = UDim2.fromOffset(500, 41), Name = label,
		BackgroundTransparency = T.CtlTr, Parent = self.Container,
	}); C(f, UDim.new(0, 5))

	local tog = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = T.TogBg,
		Size = UDim2.fromOffset(55, 24), Position = UDim2.new(0.87, 0, 0.16362, 0),
		BorderColor3 = T.TogBg, Name = "Tog", Parent = f,
	}); C(tog, UDim.new(0, 5))

	local offD = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 21),
		Position = UDim2.fromOffset(0, 1), Name = "OffD", Parent = tog,
	}); C(offD, UDim.new(0, 5))

	local onD = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 21),
		Position = UDim2.new(0.63182, 0, 0.08333, 0), Name = "OnD", Parent = tog,
	}); C(onD, UDim.new(0, 5))

	local knob = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = T.TogKnob,
		Size = UDim2.fromOffset(20, 21), Position = UDim2.fromOffset(0, 1),
		Name = "Knob", Parent = tog,
	}); C(knob, UDim.new(0, 5))

	local hit = INS("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = T.TogBg, Size = UDim2.fromOffset(55, 24),
		Name = "Hit", Parent = tog,
	}); C(hit, UDim.new(0, 5))

	local big = INS("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = T.TogBg, Size = UDim2.fromOffset(490, 40),
		Position = UDim2.new(-7.90909, 0, -0.27951, 0), Name = "Big", Parent = tog,
	}); C(big, UDim.new(0, 5))

	INS("TextLabel", {
		BorderSizePixel = 0, TextSize = T.CtlSz,
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		FontFace = T.Font, TextColor3 = T.CtlTx,
		Size = UDim2.fromOffset(116, 27), Text = label,
		Position = UDim2.new(0.02, 0, 0.14634, 0), Parent = f,
	})

	local on = def
	local function snap()
		local ox = onD.AbsolutePosition.X
		local cx = tog.AbsolutePosition.X
		local target = on and (ox - cx) or 0
		if target ~= target then target = on and 35 or 0 end
		local tw = TweenSvc:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Position = UDim2.fromOffset(target, knob.Position.Y.Offset)
		})
		tw:Play()
	end
	local function toggle()
		on = not on; snap(); task.spawn(cb, on)
	end
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
	end)
	big.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
	end)
	task.spawn(function()
		task.wait(0.15)
		if def then snap() end
	end)
	local ctrl = { Frame = f, Set = function(s) on = s; snap() end, Get = function() return on end, Toggle = toggle }
	table.insert(self.Buttons, ctrl)
	return ctrl
end

function TabMT:AddButton(opt)
	opt = opt or {}
	local label = opt.Name or "Button"
	local cb = opt.Callback or function() end

	local f = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = T.CtlBg,
		Size = UDim2.fromOffset(500, 41), Name = label,
		BackgroundTransparency = T.CtlTr, Parent = self.Container,
	}); C(f, UDim.new(0, 5))

	INS("TextLabel", {
		BorderSizePixel = 0, TextSize = T.CtlSz,
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		FontFace = T.Font, TextColor3 = T.CtlTx,
		Size = UDim2.fromOffset(200, 27), Text = label,
		Position = UDim2.new(0.02, 0, 0.14634, 0), TextXAlignment = Enum.TextXAlignment.Left,
		Parent = f,
	})
	local btn = INS("ImageButton", {
		BorderSizePixel = 0, BackgroundColor3 = T.TogBg,
		Size = UDim2.fromOffset(55, 24), Position = UDim2.new(0.87, 0, 0.16362, 0),
		BorderColor3 = T.TogBg, Name = "Btn", Parent = f,
	}); C(btn, UDim.new(0, 5))
	btn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then task.spawn(cb) end
	end)

	local ctrl = { Frame = f }
	table.insert(self.Buttons, ctrl)
	return ctrl
end

function TabMT:AddLabel(text)
	text = text or ""
	local lb = INS("TextLabel", {
		BorderSizePixel = 0, TextSize = 18,
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		FontFace = T.Font, TextColor3 = T.CtlTx,
		Size = UDim2.fromOffset(500, 30), Text = text,
		Position = UDim2.new(0.02, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Container,
	})
	local ctrl = { Frame = lb }
	table.insert(self.Buttons, ctrl)
	return ctrl
end

function TabMT:Destroy()
	self.Button:Destroy()
	self.Container:Destroy()
end

--=======================================================
--  WINDOW
--=======================================================
local WinMT = {}
WinMT.__index = WinMT

function WinMT.New(opt)
	local self = setmetatable({}, WinMT)
	opt = opt or {}
	self.Tabs = {}
	self.ActiveTab = nil
	self._dead = false

	local title = opt.Name or "compass.lol"
	local size = opt.Size or UDim2.fromOffset(563, 462)
	local pos = opt.Position or UDim2.new(0.20873, 0, 0.20225, 0)

	-- ScreenGui
	self.SG = INS("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})

	-- Window frame
	self.Frame = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = T.WinBg,
		Size = size, Position = pos, BorderColor3 = T.WinBrd,
		Name = "CompassFrame", Parent = self.SG,
	}); C(self.Frame)

	-- Title bar
	self:_Titlebar(title)

	-- Tabs sidebar
	self:_Sidebar()

	-- Main content
	self:_Content()

	-- Dragging
	self:_Drag()

	-- Viewport
	if opt.ShowViewport ~= false then self:_Viewport() end

	-- Snowfall
	if opt.Snowfall ~= false then self:_Snow() end

	return self
end

function WinMT:_Titlebar(name)
	-- profile pic
	self._pic = INS("ImageLabel", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		Size = UDim2.fromOffset(30, 31), Position = UDim2.new(0.01776, 0, 0.02165, 0),
		Parent = self.Frame,
	}); C(self._pic, UDim.new(0, 20))

	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		if ok and img then self._pic.Image = img end
	end)

	-- title text
	INS("TextLabel", {
		TextWrapped = true, BorderSizePixel = 0, TextSize = 19,
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		FontFace = T.Font, TextColor3 = Color3.fromRGB(182, 182, 182),
		Size = UDim2.fromOffset(111, 25), Text = name,
		Position = UDim2.new(0.08171, 0, 0.03463, 0), Parent = self.Frame,
	})

	-- minimize
	self._min = INS("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Image = "rbxassetid://10734896206",
		Size = UDim2.fromOffset(28, 27), Position = UDim2.new(0.8881, 0, 0.02165, 0),
		Name = "Min", Parent = self.Frame,
	})

	-- close
	self._clo = INS("ImageButton", {
		BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Image = "rbxassetid://10747384394",
		Size = UDim2.fromOffset(28, 27), Position = UDim2.new(0.93783, 0, 0.02165, 0),
		Name = "Close", Parent = self.Frame,
	})

	self._minimized = false
	self._origS = self.Frame.Size
	self._origP = self.Frame.Position

	self._clo.MouseButton1Click:Connect(function() self:Destroy() end)
	self._min.MouseButton1Click:Connect(function() self:ToggleMin() end)
end

function WinMT:ToggleMin()
	self._minimized = not self._minimized
	if self._minimized then
		self._origS = self.Frame.Size
		self._origP = self.Frame.Position
		TweenSvc:Create(self.Frame, TweenInfo.new(0.3), {
			Size = UDim2.fromOffset(563, 40),
			Position = UDim2.new(self.Frame.Position.X.Scale, self.Frame.Position.X.Offset, 0.20225, 0),
		}):Play()
		if self._main then self._main.Visible = false end
		if self._side then self._side.Visible = false end
		if self._vp then self._vp.frame.Visible = false end
	else
		local tw = TweenSvc:Create(self.Frame, TweenInfo.new(0.3), {
			Size = self._origS, Position = self._origP,
		})
		tw:Play()
		tw.Completed:Connect(function()
			if self._main then self._main.Visible = true end
			if self._side then self._side.Visible = true end
			if self._vp then self._vp.frame.Visible = true end
		end)
	end
end

function WinMT:Minimize()
	if not self._minimized then self:ToggleMin() end
end

function WinMT:Maximize()
	if self._minimized then self:ToggleMin() end
end

function WinMT:_Sidebar()
	self._side = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = T.TabBg,
		Size = UDim2.fromOffset(40, 231), Position = UDim2.new(-0.09059, 0, 0.26623, 0),
		Name = "Sidebar", Parent = self.Frame,
	}); C(self._side)

	self._tabBox = INS("ScrollingFrame", {
		Active = true, BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		Size = UDim2.fromOffset(40, 225), Position = UDim2.fromOffset(0, 5),
		ScrollBarThickness = 0, Parent = self._side,
	})
	INS("UIListLayout", {
		Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self._tabBox,
	})
	INS("UIPadding", {
		PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 7),
		Parent = self._tabBox,
	})
end

function WinMT:_Content()
	self._main = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = T.MainBg,
		Size = UDim2.fromOffset(520, 385), Position = UDim2.new(0.0373, 0, 0.12338, 0),
		BackgroundTransparency = T.MainTr, Name = "Main", Parent = self.Frame,
	}); C(self._main, UDim.new(0, 8))

	self._scroll = INS("ScrollingFrame", {
		Active = true, BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		Size = UDim2.fromOffset(520, 377), Position = UDim2.fromOffset(0, 7),
		ScrollBarThickness = 2, Parent = self._main,
	})

	-- layout for tab containers inside the scroll frame
	local scrollLay = INS("UIListLayout", {
		Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self._scroll,
	})
	INS("UIPadding", {
		PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 10),
		Parent = self._scroll,
	})
	scrollLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self._scroll.CanvasSize = UDim2.fromOffset(0, scrollLay.AbsoluteContentSize.Y + 20)
	end)
end

function WinMT:_Drag()
	local d = { active = false, start = nil, last = nil, goal = nil }

	self.Frame.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			d.active = true
			d.start = self.Frame.Position
			d.last = UIS:GetMouseLocation()
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then d.active = false end
			end)
		end
	end)

	RunSvc.Heartbeat:Connect(function(dt)
		if not d.start then return end
		if not d.active and d.goal then
			self.Frame.Position = UDim2.new(
				d.start.X.Scale,
				self.Frame.Position.X.Offset + (d.goal.X.Offset - self.Frame.Position.X.Offset) * 0.5,
				d.start.Y.Scale,
				self.Frame.Position.Y.Offset + (d.goal.Y.Offset - self.Frame.Position.Y.Offset) * 0.5
			)
			return
		end
		local delta = d.last - UIS:GetMouseLocation()
		local xg = d.start.X.Offset - delta.X
		local yg = d.start.Y.Offset - delta.Y
		d.goal = UDim2.new(d.start.X.Scale, xg, d.start.Y.Scale, yg)
		self.Frame.Position = UDim2.new(
			d.start.X.Scale,
			self.Frame.Position.X.Offset + (xg - self.Frame.Position.X.Offset) * 0.5,
			d.start.Y.Scale,
			self.Frame.Position.Y.Offset + (yg - self.Frame.Position.Y.Offset) * 0.5
		)
	end)
end

--=======================================================
--  VIEWPORT
--=======================================================
function WinMT:_Viewport()
	local vf = INS("Frame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.fromOffset(306, 431), Position = UDim2.new(1.01724, 0, 0.0335, 0),
		Name = "VpFrame", Parent = self.Frame,
	}); C(vf)

	local vp = INS("ViewportFrame", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(313, 426),
		Position = UDim2.fromOffset(0, 1), Parent = vf,
	})
	local wm = INS("WorldModel", { Parent = vp })
	local cam = INS("Camera", { CameraType = Enum.CameraType.Scriptable, Parent = vp })
	vp.CurrentCamera = cam
	INS("PointLight", { Range = 60, Brightness = 3, Parent = cam })

	local st = {
		center = Vector3.new(0,0,0), dist = 8, ht = 0,
		th = math.pi, ph = 0.15, tth = math.pi, tph = 0.15, dth = math.pi, dph = 0.15,
		phMin = -1.4, phMax = 1.4, drag = false, lx = 0, ly = 0, lt = 0,
		rtn = 1.5, sm = 0.12, clone = nil,
	}

	local function upCam()
		local x = math.sin(st.th) * math.cos(st.ph) * st.dist
		local z = math.cos(st.th) * math.cos(st.ph) * st.dist
		local y = math.sin(st.ph) * st.dist + st.ht
		cam.CFrame = CFrame.new(st.center + Vector3.new(x, y, z), st.center)
	end

	local function frm(m)
		if not m then return end
		local cf, sz = m:GetBoundingBox()
		st.center = cf.Position
		st.dist = math.max(sz.X, sz.Y, sz.Z) * 1.4
		st.ht = 0; st.th = st.dth; st.ph = st.dph
		st.tth = st.dth; st.tph = st.dph; upCam()
	end

	local function att(c, a)
		local h = a:FindFirstChild("Handle")
		if not h then return end
		local ha = h:FindFirstChildWhichIsA("Attachment")
		if not ha then return end
		for _, d in c:GetDescendants() do
			if d:IsA("Attachment") and d.Name == ha.Name then
				local p = d.Parent
				if p and p:IsA("BasePart") then
					h.CFrame = p.CFrame * d.CFrame * ha.CFrame:Inverse()
					h.Anchored = true; return
				end
			end
		end
	end

	local function loadC()
		if st.clone then return end
		local char = Players.LocalPlayer.Character
		if not char then return end
		char.Archivable = true
		for _, o in char:GetDescendants() do o.Archivable = true end
		local c = char:Clone()
		for _, o in c:GetDescendants() do
			if o:IsA("Script") or o:IsA("LocalScript") then o:Destroy()
			elseif o:IsA("BasePart") then o.CanCollide = false; o.CanQuery = false; o.CanTouch = false end
		end
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = true; hum.JumpPower = 0; hum.WalkSpeed = 0; hum.AutoRotate = false end
		local root = c:FindFirstChild("HumanoidRootPart")
		if root then c.PrimaryPart = root; c:SetPrimaryPartCFrame(CFrame.new(0, 0, 0)) end
		for _, o in c:GetDescendants() do if o:IsA("BasePart") then o.Anchored = true end end
		for _, o in c:GetDescendants() do
			if o:IsA("Motor6D") or o:IsA("AnimationController") or o:IsA("Animator") then o:Destroy() end
		end
		c.Parent = wm; st.clone = c
		for _, a in c:GetChildren() do if a:IsA("Accessory") then att(c, a) end end
		frm(c)
	end

	local function rebuild()
		if st.clone then st.clone:Destroy(); st.clone = nil end
		loadC()
	end

	local function watchC(char)
		if not char then return end
		char.ChildAdded:Connect(function(child)
			if not st.clone then return end
			if child:IsA("Accessory") then
				task.wait(0.1)
				if st.clone:FindFirstChild(child.Name) then return end
				local a = child:Clone()
				for _, o in a:GetDescendants() do
					if o:IsA("Script") or o:IsA("LocalScript") then o:Destroy()
					elseif o:IsA("BasePart") then o.Anchored = true; o.CanCollide = false; o.CanQuery = false; o.CanTouch = false end
				end
				a.Parent = st.clone; att(st.clone, a); frm(st.clone)
			elseif child:IsA("Shirt") or child:IsA("ShirtGraphic") or child:IsA("Pants") or child:IsA("BodyColors") then
				local e = st.clone:FindFirstChildWhichIsA(child.ClassName)
				if e then e:Destroy() end
				child:Clone().Parent = st.clone; frm(st.clone)
			elseif child:IsA("CharacterMesh") then
				local e = st.clone:FindFirstChild(child.Name)
				if e then e:Destroy() end
				child:Clone().Parent = st.clone
			end
		end)
		char.ChildRemoved:Connect(function(child)
			if not st.clone then return end
			local c = st.clone:FindFirstChild(child.Name)
			if c then c:Destroy(); frm(st.clone) end
		end)
	end

	Players.LocalPlayer.CharacterAppearanceLoaded:Connect(function(char)
		task.wait(0.2); rebuild(); watchC(char)
	end)
	if Players.LocalPlayer.Character then
		task.wait(0.5)
		if not st.clone then loadC(); if st.clone then watchC(Players.LocalPlayer.Character) end end
	end

	vp.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			st.drag = true; st.lx = i.Position.X; st.ly = i.Position.Y; st.lt = tick()
		end
	end)
	vp.InputChanged:Connect(function(i)
		if st.drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			st.tth = st.tth - ((i.Position.X - st.lx) * 0.01)
			st.tph = math.clamp(st.tph + ((i.Position.Y - st.ly) * 0.01), st.phMin, st.phMax)
			st.lx = i.Position.X; st.ly = i.Position.Y; st.lt = tick()
		end
	end)
	vp.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			st.drag = false; st.lt = tick()
		end
	end)
	vp.MouseLeave:Connect(function()
		if st.drag then st.drag = false; st.lt = tick() end
	end)

	local function aLerp(c, t, f)
		local d = t - c
		while d > math.pi do d = d - 2 * math.pi end
		while d < -math.pi do d = d + 2 * math.pi end
		return c + d * f
	end

	RunSvc.RenderStepped:Connect(function()
		if not st.clone then return end
		if st.drag then
			st.th = aLerp(st.th, st.tth, st.sm)
			st.ph = st.ph + (st.tph - st.ph) * st.sm; upCam(); return
		end
		local idle = tick() - st.lt
		if idle >= st.rtn then
			st.tth = st.dth; st.tph = st.dph
			st.th = aLerp(st.th, st.tth, 0.04)
			st.ph = st.ph + (st.tph - st.ph) * 0.04
		else
			st.th = aLerp(st.th, st.tth, st.sm)
			st.ph = st.ph + (st.tph - st.ph) * st.sm
		end
		upCam()
	end)

	self._vp = { frame = vf, state = st }
end

--=======================================================
--  SNOWFALL
--=======================================================
function WinMT:_Snow()
	local flakes = {}
	local maxF = 240; local rate = 0.12; local running = true

	local con = RunSvc.RenderStepped:Connect(function(dt)
		local sz = self.Frame.AbsoluteSize
		if sz.Y <= 0 then return end
		-- spawn
		if #flakes < maxF and running then
			task.spawn(function()
				if sz.X <= 0 then return end
				local size = math.random(2, 4)
				local pad = size + 14
				local uw = sz.X - pad * 2
				if uw <= 0 then return end
				local x = pad + math.random() * uw
				local dot = INS("Frame", {
					Size = UDim2.fromOffset(size, size),
					Position = UDim2.fromOffset(x, -size),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = math.random(30, 60) / 100,
					BorderSizePixel = 0, ZIndex = 0, Parent = self.Frame,
				}); C(dot, UDim.new(1, 0))
				table.insert(flakes, {
					obj = dot, speed = math.random(12, 28),
					ph = math.random() * math.pi * 2, sx = x, y = -size, life = 0, sz = size,
				})
			end)
		end
		-- update
		for i = #flakes, 1, -1 do
			local d = flakes[i]
			if not d.obj.Parent then table.remove(flakes, i)
			else
				d.life = d.life + dt; d.y = d.y + d.speed * dt
				local rx = d.sx + math.sin(d.life * 1.2 + d.ph) * 12
				local x = math.clamp(rx, d.sz, sz.X - d.sz)
				if d.y > sz.Y + d.sz then d.obj:Destroy(); table.remove(flakes, i)
				else d.obj.Position = UDim2.fromOffset(x, d.y) end
			end
		end
	end)

	self._stopSnow = function()
		running = false; con:Disconnect()
		for _, d in ipairs(flakes) do
			if d.obj and d.obj.Parent then d.obj:Destroy() end
		end
		table.clear(flakes)
	end
end

--=======================================================
--  PUBLIC WINDOW API
--=======================================================
function WinMT:CreateTab(name, icon)
	local tab = TabMT.New(name, icon)
	tab.Button.Parent = self._tabBox
	tab.Container.Parent = self._scroll
	tab.Button.MouseButton1Click:Connect(function()
		self:SelectTab(tab.Name)
	end)
	self.Tabs[name] = tab
	if not self.ActiveTab then
		self:SelectTab(name)
	end
	return tab
end

function WinMT:RemoveTab(name)
	local tab = self.Tabs[name]
	if tab then
		if self.ActiveTab == tab then
			self.ActiveTab = nil
			for k, t in pairs(self.Tabs) do
				if t ~= tab then self:SelectTab(k) break end
			end
		end
		tab:Destroy()
		self.Tabs[name] = nil
	end
end

function WinMT:SelectTab(name)
	if self.ActiveTab then
		self.ActiveTab:SetActive(false)
	end
	local tab = self.Tabs[name]
	if tab then
		self.ActiveTab = tab
		tab:SetActive(true)
	end
end

function WinMT:GetTab(name)
	return self.Tabs[name]
end

function WinMT:Destroy()
	if self._dead then return end
	self._dead = true
	if self._stopSnow then self._stopSnow() end
	for _, tab in pairs(self.Tabs) do tab:Destroy() end
	if self._vp and self._vp.state and self._vp.state.clone then
		self._vp.state.clone:Destroy()
	end
	if self.SG then self.SG:Destroy() end
end

--=======================================================
--  LIBRARY ENTRY
--=======================================================
local Lib = {}
Lib.__index = Lib

function Lib:CreateWindow(opt)
	local win = WinMT.New(opt)
	self._wins = self._wins or {}
	self._wins[win] = win
	return win
end

function Lib:DestroyAll()
	for w, _ in pairs(self._wins or {}) do
		w:Destroy()
	end
end

return Lib

