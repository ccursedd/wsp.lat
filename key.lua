-- VoidAuth Loader - Reads KEY from global environment
local VoidAuth = {}
local HttpService = game:GetService("HttpService")

VoidAuth.endpoint = "https://tqninassljbrerabkcyd.supabase.co/rest/v1/rpc/check_license"
VoidAuth.apikey   = "sb_publishable_pXlWJepgj8moF0WN9ZSllA_yR8Ukwtb"

local function httpRequest(url, body)
    local fn = syn and syn.request or http and http.request or request or http_request
    if not fn then
        return nil, "No HTTP function found"
    end
    local ok, res = pcall(fn, {
        Url = url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["apikey"] = VoidAuth.apikey,
        },
        Body = body,
    })
    if not ok then return nil, "Request failed" end
    return res, nil
end

local function getHWID()
    if syn and syn.get_hwid then return syn.get_hwid() end
    if get_hwid then return get_hwid() end
    local success, stored = pcall(readfile, "voidauth_hwid.txt")
    if success and stored and #stored > 0 then return stored end
    local id = HttpService:GenerateGUID(false):gsub("-", "")
    pcall(writefile, "voidauth_hwid.txt", id)
    return id
end

function VoidAuth.check(key)
    if not key or key == "" then return false, "No key provided" end
    local hwid = getHWID()
    local body = HttpService:JSONEncode({ license_key = key, hwid = hwid })
    local res, err = httpRequest(VoidAuth.endpoint, body)
    if not res then return false, err end
    local success, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not success then return false, "Bad response" end
    return data.success == true, data.reason
end

local USER_KEY = getgenv and getgenv().KEY or _G.KEY or KEY
if not USER_KEY or USER_KEY == "" then
    error("No KEY provided! Set: local KEY = 'your-key'")
end

local authorized, reason = VoidAuth.check(USER_KEY)
if not authorized then
    error("Access denied: " .. (reason or "invalid key"))
end

print("loading compass.lol!")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Function to destroy ALL compass related GUIs
local function destroyAllCompassUIs()
    -- Find and destroy any GUI that might be from this script
    local guisToDestroy = {}
    
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            -- Destroy any GUI that has compass-related names or our specific GUIs
            if gui.Name == "CompassGui" or 
               gui.Name == "CompassDragGui" or 
               gui.Name == "AntiVCGui" or
               gui.Name == "CompassHub" or
               string.find(gui.Name:lower(), "compass") then
                table.insert(guisToDestroy, gui)
            end
        end
    end
    
    -- Also check for any stray billboards
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("CompassNameTag")
                if billboard then
                    pcall(function() billboard:Destroy() end)
                end
            end
        end
    end
    
    -- Destroy all found GUIs
    for _, gui in ipairs(guisToDestroy) do
        pcall(function() gui:Destroy() end)
    end
end

destroyAllCompassUIs()

-- Wait a moment to ensure cleanup is complete
task.wait(0.1)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

-- =============================================
-- NAMETAG VARIABLES
-- =============================================
local SPRITE_ID = "rbxassetid://87446161788560"
local AVATAR_IMAGE_ID = "rbxassetid://72691867478792"
local FRAME_W = 100
local FRAME_H = 100
local FRAMES_PER_ROW = 4
local TOTAL_FRAMES = 16
local ANIM_FPS = 12

local nametagsEnabled = true
local activeBillboards = {}
local activeConnections = {}

-- =============================================
-- NAMETAG FUNCTIONS
-- =============================================
local function fadeBillboard(billboard, fadeOut, callback)
    if not billboard then return end
    
    local targetTransparency = fadeOut and 1 or 0.3
    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    
    local bg = billboard:FindFirstChildWhichIsA("Frame")
    if bg then
        TweenService:Create(bg, tweenInfo, { BackgroundTransparency = targetTransparency }):Play()
        
        local stroke = bg:FindFirstChildWhichIsA("UIStroke")
        if stroke then
            TweenService:Create(stroke, tweenInfo, { Transparency = fadeOut and 1 or 0.78 }):Play()
        end
        
        local imageBox = bg:FindFirstChildWhichIsA("ImageLabel")
        if imageBox then
            TweenService:Create(imageBox, tweenInfo, { ImageTransparency = fadeOut and 1 or 0 }):Play()
            TweenService:Create(imageBox, tweenInfo, { BackgroundTransparency = fadeOut and 1 or 0.4 }):Play()
            
            local spriteContainer = imageBox:FindFirstChild("Frame")
            if spriteContainer then
                local sprite = spriteContainer:FindFirstChildWhichIsA("ImageLabel")
                if sprite then
                    TweenService:Create(sprite, tweenInfo, { ImageTransparency = fadeOut and 1 or 0.3 }):Play()
                end
            end
            
            local boxStroke = imageBox:FindFirstChildWhichIsA("UIStroke")
            if boxStroke then
                TweenService:Create(boxStroke, tweenInfo, { Transparency = fadeOut and 1 or 0.5 }):Play()
            end
        end
        
        local textFrame = bg:FindFirstChild("Frame")
        if textFrame then
            for _, label in ipairs(textFrame:GetChildren()) do
                if label:IsA("TextLabel") then
                    TweenService:Create(label, tweenInfo, { TextTransparency = fadeOut and 1 or 0 }):Play()
                end
            end
        end
    end
    
    if fadeOut then
        task.delay(0.45, function()
            if callback then callback() end
        end)
    elseif callback then
        callback()
    end
end

local function toggleAllNametags(enabled)
    for _, data in ipairs(activeBillboards) do
        if data.billboard and data.billboard.Parent then
            if enabled then
                data.billboard.Enabled = true
                fadeBillboard(data.billboard, false)
            else
                fadeBillboard(data.billboard, true, function()
                    if data.billboard and data.billboard.Parent then
                        data.billboard.Enabled = false
                    end
                end)
            end
        end
    end
end

local function buildTag(char)
    task.wait(0.5)

    local head = char:FindFirstChild("Head")
    if not head then return end

    local old = head:FindFirstChild("CompassNameTag")
    if old then 
        for i, data in ipairs(activeBillboards) do
            if data.billboard == old then
                if data.connection then
                    data.connection:Disconnect()
                end
                table.remove(activeBillboards, i)
                break
            end
        end
        old:Destroy() 
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CompassNameTag"
    billboard.Size = UDim2.new(0, 220, 0, 66)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = false
    billboard.ResetOnSpawn = false
    billboard.Enabled = nametagsEnabled
    billboard.MaxDistance = 50
    billboard.Parent = head
    
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MaxSize = Vector2.new(220, 66)
    sizeConstraint.MinSize = Vector2.new(220, 66)
    sizeConstraint.Parent = billboard

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    bg.BackgroundTransparency = nametagsEnabled and 0.3 or 1
    bg.BorderSizePixel = 0
    bg.Parent = billboard

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 10)
    bgCorner.Parent = bg

    local bgStroke = Instance.new("UIStroke")
    bgStroke.Color = Color3.fromRGB(255, 255, 255)
    bgStroke.Thickness = 1
    bgStroke.Transparency = nametagsEnabled and 0.78 or 1
    bgStroke.Parent = bg

    local imageBox = Instance.new("ImageLabel")
    imageBox.Size = UDim2.new(0, 50, 0, 50)
    imageBox.Position = UDim2.new(0, 8, 0.5, -25)
    imageBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    imageBox.BackgroundTransparency = nametagsEnabled and 0.4 or 1
    imageBox.BorderSizePixel = 0
    imageBox.ClipsDescendants = true
    imageBox.Image = AVATAR_IMAGE_ID
    imageBox.ScaleType = Enum.ScaleType.Stretch
    imageBox.ImageTransparency = nametagsEnabled and 0 or 1
    imageBox.Parent = bg
    
    local imageSizeConstraint = Instance.new("UISizeConstraint")
    imageSizeConstraint.MaxSize = Vector2.new(50, 50)
    imageSizeConstraint.MinSize = Vector2.new(50, 50)
    imageSizeConstraint.Parent = imageBox

    local imageBoxCorner = Instance.new("UICorner")
    imageBoxCorner.CornerRadius = UDim.new(0, 8)
    imageBoxCorner.Parent = imageBox

    local imageBoxStroke = Instance.new("UIStroke")
    imageBoxStroke.Color = Color3.fromRGB(255, 255, 255)
    imageBoxStroke.Thickness = 1
    imageBoxStroke.Transparency = nametagsEnabled and 0.5 or 1
    imageBoxStroke.Parent = imageBox

    local spriteContainer = Instance.new("Frame")
    spriteContainer.Size = UDim2.new(1, 0, 1, 0)
    spriteContainer.BackgroundTransparency = 1
    spriteContainer.ClipsDescendants = true
    spriteContainer.Parent = imageBox

    local rows = math.ceil(TOTAL_FRAMES / FRAMES_PER_ROW)
    local spriteWidth = FRAME_W * FRAMES_PER_ROW
    local spriteHeight = FRAME_H * rows

    local sprite = Instance.new("ImageLabel")
    sprite.Size = UDim2.new(0, spriteWidth, 0, spriteHeight)
    sprite.Position = UDim2.new(0, 0, 0, 0)
    sprite.Image = SPRITE_ID
    sprite.BackgroundTransparency = 1
    sprite.ScaleType = Enum.ScaleType.Stretch
    sprite.ImageTransparency = nametagsEnabled and 0.3 or 1
    sprite.Parent = spriteContainer

    local textFrame = Instance.new("Frame")
    textFrame.Size = UDim2.new(1, -70, 1, 0)
    textFrame.Position = UDim2.new(0, 65, 0, 0)
    textFrame.BackgroundTransparency = 1
    textFrame.Parent = bg
    
    local textSizeConstraint = Instance.new("UISizeConstraint")
    textSizeConstraint.MaxSize = Vector2.new(150, 66)
    textSizeConstraint.Parent = textFrame

    local scriptLabel = Instance.new("TextLabel")
    scriptLabel.Size = UDim2.new(1, 0, 0, 28)
    scriptLabel.Position = UDim2.new(0, 0, 0, 8)
    scriptLabel.BackgroundTransparency = 1
    scriptLabel.Font = Enum.Font.GothamBold
    scriptLabel.Text = "compass.lol - founder"
    scriptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    scriptLabel.TextSize = 14
    scriptLabel.TextXAlignment = Enum.TextXAlignment.Left
    scriptLabel.TextScaled = false
    scriptLabel.TextTransparency = nametagsEnabled and 0 or 1
    scriptLabel.Parent = textFrame

    local userLabel = Instance.new("TextLabel")
    userLabel.Size = UDim2.new(1, 0, 0, 20)
    userLabel.Position = UDim2.new(0, 0, 0, 36)
    userLabel.BackgroundTransparency = 1
    userLabel.Font = Enum.Font.Gotham
    userLabel.Text = "@" .. LocalPlayer.Name
    userLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
    userLabel.TextSize = 14
    userLabel.TextXAlignment = Enum.TextXAlignment.Left
    userLabel.TextScaled = false
    userLabel.TextTransparency = nametagsEnabled and 0 or 1
    userLabel.Parent = textFrame

    local currentFrame = 0
    local lastTick = tick()

    local conn = nil
    conn = RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then
            conn:Disconnect()
            return
        end
        if not nametagsEnabled then return end

        local now = tick()
        if now - lastTick < (1 / ANIM_FPS) then
            return
        end
        lastTick = now

        local col = currentFrame % FRAMES_PER_ROW
        local row = math.floor(currentFrame / FRAMES_PER_ROW)

        sprite.Position = UDim2.new(0, -col * FRAME_W, 0, -row * FRAME_H)

        currentFrame = currentFrame + 1
        if currentFrame >= TOTAL_FRAMES then
            currentFrame = 0
        end
    end)
    
    table.insert(activeBillboards, {
        billboard = billboard,
        connection = conn,
        character = char
    })
end

local function onCharacterAdded(char)
    task.spawn(buildTag, char)
end

local function cleanupAllTags()
    for _, data in ipairs(activeBillboards) do
        if data.connection then
            data.connection:Disconnect()
        end
        if data.billboard and data.billboard.Parent then
            data.billboard:Destroy()
        end
    end
    activeBillboards = {}
    activeConnections = {}
end

local function initNametags()
    cleanupAllTags()
    if LocalPlayer.Character then
        task.spawn(buildTag, LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

-- =============================================
-- TOP RIGHT STATS BAR
-- =============================================
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Fps = Instance.new("TextLabel")
local Fpsnum = Instance.new("TextLabel")
local Ping = Instance.new("TextLabel")
local Pingnum = Instance.new("TextLabel")
local Title = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")
local Divider1 = Instance.new("Frame")
local Divider2 = Instance.new("Frame")
local Frame_2 = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local ImageButton = Instance.new("ImageButton")

ScreenGui.Name = "CompassGui"
ScreenGui.Parent = PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
Frame.BorderSizePixel = 0
Frame.AnchorPoint = Vector2.new(1, 0)
Frame.Position = UDim2.new(1, -8, 0, -50)
Frame.Size = UDim2.new(0, 280, 0, 34)
Frame.BackgroundTransparency = 1

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Stroke = Instance.new("UIStroke")
Stroke.Parent = Frame
Stroke.Color = Color3.fromRGB(70, 70, 75)
Stroke.Thickness = 1
Stroke.Transparency = 1

Title.Name = "Title"
Title.Parent = Frame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(0, 80, 1, 0)
Title.Font = Enum.Font.GothamSemibold
Title.Text = "Compass.lol"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextTransparency = 1

Divider1.Parent = Frame
Divider1.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
Divider1.BorderSizePixel = 0
Divider1.Position = UDim2.new(0, 100, 0.2, 0)
Divider1.Size = UDim2.new(0, 1, 0.6, 0)
Divider1.BackgroundTransparency = 1

Fps.Name = "Fps"
Fps.Parent = Frame
Fps.BackgroundTransparency = 1
Fps.Position = UDim2.new(0, 112, 0, 0)
Fps.Size = UDim2.new(0, 34, 1, 0)
Fps.Font = Enum.Font.Gotham
Fps.Text = "fps"
Fps.TextColor3 = Color3.fromRGB(140, 140, 145)
Fps.TextSize = 11
Fps.TextTransparency = 1

Fpsnum.Name = "Fpsnum"
Fpsnum.Parent = Frame
Fpsnum.BackgroundTransparency = 1
Fpsnum.Position = UDim2.new(0, 148, 0, 0)
Fpsnum.Size = UDim2.new(0, 40, 1, 0)
Fpsnum.Font = Enum.Font.GothamSemibold
Fpsnum.Text = "..."
Fpsnum.TextColor3 = Color3.fromRGB(255, 255, 255)
Fpsnum.TextSize = 12
Fpsnum.TextXAlignment = Enum.TextXAlignment.Left
Fpsnum.TextTransparency = 1

Divider2.Parent = Frame
Divider2.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
Divider2.BorderSizePixel = 0
Divider2.Position = UDim2.new(0, 192, 0.2, 0)
Divider2.Size = UDim2.new(0, 1, 0.6, 0)
Divider2.BackgroundTransparency = 1

Ping.Name = "Ping"
Ping.Parent = Frame
Ping.BackgroundTransparency = 1
Ping.Position = UDim2.new(0, 202, 0, 0)
Ping.Size = UDim2.new(0, 36, 1, 0)
Ping.Font = Enum.Font.Gotham
Ping.Text = "ping"
Ping.TextColor3 = Color3.fromRGB(140, 140, 145)
Ping.TextSize = 11
Ping.TextTransparency = 1

Pingnum.Name = "Pingnum"
Pingnum.Parent = Frame
Pingnum.BackgroundTransparency = 1
Pingnum.Position = UDim2.new(0, 240, 0, 0)
Pingnum.Size = UDim2.new(0, 38, 1, 0)
Pingnum.Font = Enum.Font.GothamSemibold
Pingnum.Text = "..."
Pingnum.TextColor3 = Color3.fromRGB(255, 255, 255)
Pingnum.TextSize = 12
Pingnum.TextXAlignment = Enum.TextXAlignment.Left
Pingnum.TextTransparency = 1

Frame_2.Parent = ScreenGui
Frame_2.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
Frame_2.BorderSizePixel = 0
Frame_2.AnchorPoint = Vector2.new(1, 0)
Frame_2.Position = UDim2.new(1, -298, 0, -50)
Frame_2.Size = UDim2.new(0, 34, 0, 34)
Frame_2.BackgroundTransparency = 1

UICorner_2.CornerRadius = UDim.new(0, 8)
UICorner_2.Parent = Frame_2

local Stroke2 = Instance.new("UIStroke")
Stroke2.Parent = Frame_2
Stroke2.Color = Color3.fromRGB(70, 70, 75)
Stroke2.Thickness = 1
Stroke2.Transparency = 1

ImageButton.Parent = Frame_2
ImageButton.BackgroundTransparency = 1
ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
ImageButton.Position = UDim2.new(0.5, 0, 0.5, 0)
ImageButton.Size = UDim2.new(0, 16, 0, 16)
ImageButton.Image = "rbxassetid://10734976528"
ImageButton.ImageColor3 = Color3.fromRGB(140, 140, 145)
ImageButton.ScaleType = Enum.ScaleType.Fit
ImageButton.ImageTransparency = 1

local fadeTime = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
TweenService:Create(Frame,    fadeTime, { BackgroundTransparency = 0.15 }):Play()
TweenService:Create(Frame_2,  fadeTime, { BackgroundTransparency = 0.15 }):Play()
TweenService:Create(ImageButton, fadeTime, { ImageTransparency = 0 }):Play()
TweenService:Create(Stroke,   fadeTime, { Transparency = 0 }):Play()
TweenService:Create(Stroke2,  fadeTime, { Transparency = 0 }):Play()
TweenService:Create(Divider1, fadeTime, { BackgroundTransparency = 0 }):Play()
TweenService:Create(Divider2, fadeTime, { BackgroundTransparency = 0 }):Play()
for _, label in ipairs({ Fps, Fpsnum, Ping, Pingnum, Title }) do
    TweenService:Create(label, fadeTime, { TextTransparency = 0 }):Play()
end

local lastTime = tick()
local frameCount = 0
RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = tick()
    local elapsed = now - lastTime
    if elapsed >= 1 then
        local fps = math.round(frameCount / elapsed)
        Fpsnum.Text = tostring(fps)
        if fps >= 50 then
            Fpsnum.TextColor3 = Color3.fromRGB(100, 210, 100)
        elseif fps >= 30 then
            Fpsnum.TextColor3 = Color3.fromRGB(220, 180, 60)
        else
            Fpsnum.TextColor3 = Color3.fromRGB(210, 80, 80)
        end
        local ping = math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        Pingnum.Text = tostring(ping)
        if ping <= 80 then
            Pingnum.TextColor3 = Color3.fromRGB(100, 210, 100)
        elseif ping <= 150 then
            Pingnum.TextColor3 = Color3.fromRGB(220, 180, 60)
        else
            Pingnum.TextColor3 = Color3.fromRGB(210, 80, 80)
        end
        frameCount = 0
        lastTime = now
    end
end)

-- =============================================
-- NAMETAG TOGGLE
-- =============================================
local isRotating = false

local function toggleNametagsFromButton()
    nametagsEnabled = not nametagsEnabled
    
    if not isRotating then
        isRotating = true
        local rotateIn = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local rotateOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        
        TweenService:Create(ImageButton, rotateIn, { Rotation = 180 }):Play()
        task.wait(0.2)
        
        if nametagsEnabled then
            ImageButton.ImageColor3 = Color3.fromRGB(100, 210, 100)
        else
            ImageButton.ImageColor3 = Color3.fromRGB(210, 80, 80)
        end
        
        TweenService:Create(ImageButton, rotateOut, { Rotation = 0 }):Play()
        task.wait(0.2)
        isRotating = false
    end
    
    toggleAllNametags(nametagsEnabled)
end

ImageButton.MouseButton1Click:Connect(toggleNametagsFromButton)

ImageButton.MouseEnter:Connect(function()
    TweenService:Create(ImageButton, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(200, 200, 200) }):Play()
end)

ImageButton.MouseLeave:Connect(function()
    if nametagsEnabled then
        TweenService:Create(ImageButton, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(100, 210, 100) }):Play()
    else
        TweenService:Create(ImageButton, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(210, 80, 80) }):Play()
    end
end)

ImageButton.ImageColor3 = Color3.fromRGB(100, 210, 100)

-- =============================================
-- MAIN HUB UI (Draggable with Buttons)
-- =============================================
local DragGui = Instance.new("ScreenGui")
local MainPanel = Instance.new("Frame")
local MainUICorner = Instance.new("UICorner")
local MainStroke = Instance.new("UIStroke")
local TitleBar = Instance.new("Frame")
local TitleText = Instance.new("TextLabel")
local DragDots = Instance.new("TextLabel")
local SearchBox = Instance.new("TextBox")
local SearchIcon = Instance.new("ImageLabel")
local SearchCorner = Instance.new("UICorner")
local DividerLine = Instance.new("Frame")
local ButtonsScrollingFrame = Instance.new("ScrollingFrame")
local ButtonsLayout = Instance.new("UIListLayout")
local ButtonsPadding = Instance.new("UIPadding")

DragGui.Name = "CompassDragGui"
DragGui.Parent = PlayerGui
DragGui.ResetOnSpawn = false

MainPanel.Parent = DragGui
MainPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainPanel.BorderSizePixel = 0
MainPanel.Position = UDim2.new(1, -230, 0, -50)
MainPanel.AnchorPoint = Vector2.new(1, 0)
MainPanel.Size = UDim2.new(0, 220, 0, 340)
MainPanel.BackgroundTransparency = 1

MainUICorner.CornerRadius = UDim.new(0, 12)
MainUICorner.Parent = MainPanel

MainStroke.Parent = MainPanel
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1
MainStroke.Transparency = 1

TitleBar.Parent = MainPanel
TitleBar.BackgroundTransparency = 1
TitleBar.Size = UDim2.new(1, 0, 0, 40)

TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Position = UDim2.new(0, 14, 0, 0)
TitleText.Size = UDim2.new(1, -36, 1, 0)
TitleText.Font = Enum.Font.GothamSemibold
TitleText.Text = "Compass.lol Hub"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.TextTransparency = 1

DragDots.Parent = TitleBar
DragDots.BackgroundTransparency = 1
DragDots.Position = UDim2.new(1, -22, 0, 10)
DragDots.Size = UDim2.new(0, 16, 0, 16)
DragDots.Font = Enum.Font.GothamBold
DragDots.Text = "⠿"
DragDots.TextColor3 = Color3.fromRGB(255, 255, 255)
DragDots.TextSize = 14
DragDots.TextTransparency = 1

SearchBox.Parent = MainPanel
SearchBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.BorderSizePixel = 0
SearchBox.Position = UDim2.new(0, 12, 0, 48)
SearchBox.Size = UDim2.new(1, -24, 0, 32)
SearchBox.Font = Enum.Font.Gotham
SearchBox.PlaceholderText = "Search features..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 12
SearchBox.BackgroundTransparency = 1
SearchBox.ClearTextOnFocus = false

SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBox

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Parent = SearchBox
SearchStroke.Color = Color3.fromRGB(255, 255, 255)
SearchStroke.Thickness = 1
SearchStroke.Transparency = 1

SearchIcon.Parent = SearchBox
SearchIcon.BackgroundTransparency = 1
SearchIcon.Position = UDim2.new(1, -24, 0.5, -8)
SearchIcon.Size = UDim2.new(0, 16, 0, 16)
SearchIcon.Image = "rbxassetid://6031094111"
SearchIcon.ImageColor3 = Color3.fromRGB(140, 140, 145)
SearchIcon.ImageTransparency = 0

DividerLine.Parent = MainPanel
DividerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DividerLine.BorderSizePixel = 0
DividerLine.Position = UDim2.new(0, 12, 0, 88)
DividerLine.Size = UDim2.new(1, -24, 0, 1)
DividerLine.BackgroundTransparency = 1

ButtonsScrollingFrame.Parent = MainPanel
ButtonsScrollingFrame.BackgroundTransparency = 1
ButtonsScrollingFrame.BorderSizePixel = 0
ButtonsScrollingFrame.Position = UDim2.new(0, 12, 0, 96)
ButtonsScrollingFrame.Size = UDim2.new(1, -24, 1, -110)
ButtonsScrollingFrame.ScrollBarThickness = 4
ButtonsScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 105)
ButtonsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

ButtonsLayout.Parent = ButtonsScrollingFrame
ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
ButtonsLayout.Padding = UDim.new(0, 8)

ButtonsPadding.Parent = ButtonsScrollingFrame
ButtonsPadding.PaddingTop = UDim.new(0, 5)

task.delay(0.15, function()
    local pFade = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(MainPanel, pFade, { BackgroundTransparency = 0.52 }):Play()
    TweenService:Create(MainStroke, pFade, { Transparency = 0.55 }):Play()
    TweenService:Create(SearchBox, pFade, { BackgroundTransparency = 0.88 }):Play()
    TweenService:Create(SearchStroke, pFade, { Transparency = 0.6 }):Play()
    TweenService:Create(DividerLine, pFade, { BackgroundTransparency = 0.82 }):Play()
    TweenService:Create(TitleText, pFade, { TextTransparency = 0.1 }):Play()
    TweenService:Create(DragDots, pFade, { TextTransparency = 0.55 }):Play()
end)

-- =============================================
-- DRAG SYSTEM
-- =============================================
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainPanel:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 0.04, true)
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainPanel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- =============================================
-- ANTI VC BAN DEDICATED UI (Original)
-- =============================================
local AntiVCGui = nil
local antiVCPanelVisible = false

local function createAntiVCUI()
    if AntiVCGui then return end
    
    AntiVCGui = Instance.new("ScreenGui")
    local BlurFrame = Instance.new("Frame")
    local UICornerBlur = Instance.new("UICorner")
    local DragFrame = Instance.new("Frame")
    local UICornerDrag = Instance.new("UICorner")
    local StrokeDrag = Instance.new("UIStroke")
    local TitleBarAnti = Instance.new("TextLabel")
    local DragDotsAnti = Instance.new("TextLabel")
    local PanelDivider = Instance.new("Frame")
    local AntiVCButton = Instance.new("TextButton")
    local UICornerBtn = Instance.new("UICorner")
    local BtnStroke = Instance.new("UIStroke")
    local StatusLabel = Instance.new("TextLabel")
    local CloseButton = Instance.new("ImageButton")
    
    AntiVCGui.Name = "AntiVCGui"
    AntiVCGui.Parent = PlayerGui
    AntiVCGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    AntiVCGui.ResetOnSpawn = false
    AntiVCGui.Enabled = false
    
    BlurFrame.Parent = AntiVCGui
    BlurFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    BlurFrame.BorderSizePixel = 0
    BlurFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
    BlurFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    BlurFrame.Size = UDim2.new(0, 200, 0, 110)
    BlurFrame.BackgroundTransparency = 1
    UICornerBlur.CornerRadius = UDim.new(0, 12)
    UICornerBlur.Parent = BlurFrame
    
    DragFrame.Parent = AntiVCGui
    DragFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DragFrame.BorderSizePixel = 0
    DragFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
    DragFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    DragFrame.Size = UDim2.new(0, 200, 0, 110)
    DragFrame.BackgroundTransparency = 1
    
    UICornerDrag.CornerRadius = UDim.new(0, 12)
    UICornerDrag.Parent = DragFrame
    
    StrokeDrag.Parent = DragFrame
    StrokeDrag.Color = Color3.fromRGB(255, 255, 255)
    StrokeDrag.Thickness = 1
    StrokeDrag.Transparency = 1
    
    TitleBarAnti.Parent = DragFrame
    TitleBarAnti.BackgroundTransparency = 1
    TitleBarAnti.Position = UDim2.new(0, 14, 0, 0)
    TitleBarAnti.Size = UDim2.new(1, -36, 0, 30)
    TitleBarAnti.Font = Enum.Font.GothamSemibold
    TitleBarAnti.Text = "Compass.lol Anti VC Ban"
    TitleBarAnti.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleBarAnti.TextSize = 12
    TitleBarAnti.TextXAlignment = Enum.TextXAlignment.Left
    TitleBarAnti.TextTransparency = 1
    
    DragDotsAnti.Parent = DragFrame
    DragDotsAnti.BackgroundTransparency = 1
    DragDotsAnti.Position = UDim2.new(1, -22, 0, 6)
    DragDotsAnti.Size = UDim2.new(0, 16, 0, 16)
    DragDotsAnti.Font = Enum.Font.GothamBold
    DragDotsAnti.Text = "⠿"
    DragDotsAnti.TextColor3 = Color3.fromRGB(255, 255, 255)
    DragDotsAnti.TextSize = 14
    DragDotsAnti.TextTransparency = 1
    
    CloseButton.Parent = DragFrame
    CloseButton.BackgroundTransparency = 1
    CloseButton.Position = UDim2.new(1, -28, 0, 6)
    CloseButton.Size = UDim2.new(0, 16, 0, 16)
    CloseButton.Image = "rbxassetid://6031094111"
    CloseButton.ImageColor3 = Color3.fromRGB(255, 100, 100)
    CloseButton.ImageTransparency = 0
    
    PanelDivider.Parent = DragFrame
    PanelDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PanelDivider.BorderSizePixel = 0
    PanelDivider.Position = UDim2.new(0, 14, 0, 30)
    PanelDivider.Size = UDim2.new(1, -28, 0, 1)
    PanelDivider.BackgroundTransparency = 1
    
    AntiVCButton.Parent = DragFrame
    AntiVCButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    AntiVCButton.BorderSizePixel = 0
    AntiVCButton.Position = UDim2.new(0.5, -76, 0, 40)
    AntiVCButton.Size = UDim2.new(0, 152, 0, 30)
    AntiVCButton.Font = Enum.Font.GothamSemibold
    AntiVCButton.Text = "Anti VC Ban"
    AntiVCButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AntiVCButton.TextSize = 12
    AntiVCButton.BackgroundTransparency = 1
    AntiVCButton.AutoButtonColor = false
    
    UICornerBtn.CornerRadius = UDim.new(0, 7)
    UICornerBtn.Parent = AntiVCButton
    
    BtnStroke.Parent = AntiVCButton
    BtnStroke.Color = Color3.fromRGB(255, 255, 255)
    BtnStroke.Thickness = 1
    BtnStroke.Transparency = 1
    
    StatusLabel.Parent = DragFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 0, 76)
    StatusLabel.Size = UDim2.new(1, 0, 0, 18)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "idle"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.TextSize = 10
    StatusLabel.TextTransparency = 1
    
    -- Fade in
    local pFade = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(BlurFrame, pFade, { BackgroundTransparency = 0.45 }):Play()
    TweenService:Create(DragFrame, pFade, { BackgroundTransparency = 0.92 }):Play()
    TweenService:Create(StrokeDrag, pFade, { Transparency = 0.75 }):Play()
    TweenService:Create(PanelDivider, pFade, { BackgroundTransparency = 0.82 }):Play()
    TweenService:Create(AntiVCButton, pFade, { BackgroundTransparency = 0.88 }):Play()
    TweenService:Create(BtnStroke, pFade, { Transparency = 0.6 }):Play()
    TweenService:Create(TitleBarAnti, pFade, { TextTransparency = 0.1 }):Play()
    TweenService:Create(DragDotsAnti, pFade, { TextTransparency = 0.55 }):Play()
    TweenService:Create(StatusLabel, pFade, { TextTransparency = 0.45 }):Play()
    
    -- Drag system for anti VC panel
    local draggingAnti = false
    local dragStartAnti = nil
    local startPosAnti = nil
    local dragInputAnti = nil
    
    local function updateAnti(input)
        local delta = input.Position - dragStartAnti
        DragFrame:TweenPosition(UDim2.new(startPosAnti.X.Scale, startPosAnti.X.Offset + delta.X, startPosAnti.Y.Scale, startPosAnti.Y.Offset + delta.Y), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 0.04, true)
        BlurFrame:TweenPosition(UDim2.new(startPosAnti.X.Scale, startPosAnti.X.Offset + delta.X, startPosAnti.Y.Scale, startPosAnti.Y.Offset + delta.Y), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 0.04, true)
    end
    
    TitleBarAnti.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingAnti = true
            dragStartAnti = input.Position
            startPosAnti = DragFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingAnti = false
                end
            end)
        end
    end)
    
    TitleBarAnti.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInputAnti = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInputAnti and draggingAnti then
            updateAnti(input)
        end
    end)
    
    -- Close button
    CloseButton.MouseButton1Click:Connect(function()
        AntiVCGui.Enabled = false
        antiVCPanelVisible = false
    end)
    
    -- Button hover effects
    AntiVCButton.MouseEnter:Connect(function()
        TweenService:Create(AntiVCButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.75 }):Play()
        TweenService:Create(BtnStroke, TweenInfo.new(0.2), { Transparency = 0.3 }):Play()
    end)
    
    AntiVCButton.MouseLeave:Connect(function()
        TweenService:Create(AntiVCButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.88 }):Play()
        TweenService:Create(BtnStroke, TweenInfo.new(0.2), { Transparency = 0.6 }):Play()
    end)
    
    AntiVCButton.MouseButton1Down:Connect(function()
        TweenService:Create(AntiVCButton, TweenInfo.new(0.1), { BackgroundTransparency = 0.65 }):Play()
    end)
    
    AntiVCButton.MouseButton1Up:Connect(function()
        TweenService:Create(AntiVCButton, TweenInfo.new(0.1), { BackgroundTransparency = 0.88 }):Play()
    end)
    
    -- Anti VC Ban Logic
    local ran = false
    
    AntiVCButton.MouseButton1Click:Connect(function()
        if ran then return end
        ran = true
        
        AntiVCButton.TextColor3 = Color3.fromRGB(180, 180, 185)
        StatusLabel.Text = "running..."
        StatusLabel.TextColor3 = Color3.fromRGB(220, 180, 60)
        StatusLabel.TextTransparency = 0.1
        
        task.spawn(function()
            local clonereference = cloneref or function(...) return ... end
            local clonefunction = clonefunction or function(...) return ... end
            
            local voicechatservice = clonereference(game:GetService("VoiceChatService"))
            local voicechatinternal = clonereference(game:GetService("VoiceChatInternal"))
            local coregui = game:GetService("CoreGui")
            local startergui = game:GetService("StarterGui")
            local players = game:GetService("Players")
            local localplayer = players.LocalPlayer
            local getconnectionsfunc = clonefunction(getconnections)
            
            local mutedimage = "rbxasset://textures/ui/VoiceChat/MicLight/Muted.png"
            local ismuted = true
            local hiddenfolder = Instance.new("Folder", game:GetService("RobloxReplicatedStorage"))
            
            local topbarapp = coregui:WaitForChild("TopBarApp", 15):WaitForChild("TopBarApp", 15)
            local unibarleft = topbarapp:WaitForChild("UnibarLeftFrame", 15)
            local unibarmenu = unibarleft:WaitForChild("UnibarMenu", 15) or unibarleft:WaitForChild("ChromeMenu", 15)
            local unibarcontainer
            
            pcall(function()
                unibarcontainer = unibarmenu:WaitForChild("2", 15):WaitForChild("3", 15)
            end)
            
            local micmutebutton = unibarcontainer and unibarcontainer:FindFirstChild("toggle_mic_mute", true)
            
            local function geticonlabel(button)
                button = button or micmutebutton
                return button:WaitForChild("IntegrationIconFrame", 15):WaitForChild("IntegrationIcon", 15)["1"]
            end
            
            local function setmutestate(state)
                local audiodereviceinput = localplayer:FindFirstChildWhichIsA("AudioDeviceInput", true)
                if audiodereviceinput then
                    audiodereviceinput.Active = not state
                else
                    voicechatinternal:PublishPause(state)
                end
            end
            
            if not micmutebutton then
                voicechatservice:joinVoice()
                pcall(function()
                    unibarcontainer = unibarmenu:WaitForChild("2", 15):WaitForChild("3", 15)
                    micmutebutton = unibarcontainer:WaitForChild("toggle_mic_mute", 15)
                end)
            end
            
            if not micmutebutton then
                StatusLabel.Text = "mic not found"
                StatusLabel.TextColor3 = Color3.fromRGB(210, 80, 80)
                ran = false
                return
            end
            
            startergui:SetCore("SendNotification", {
                Title = "Compass.lol",
                Text = "Unmute to continue.",
                Duration = 5
            })
            
            StatusLabel.Text = "waiting for unmute..."
            StatusLabel.TextColor3 = Color3.fromRGB(220, 180, 60)
            
            repeat task.wait(2) until geticonlabel().Image ~= mutedimage
            
            StatusLabel.Text = "applying patch..."
            
            voicechatservice:leaveVoice()
            task.wait(2)
            
            local connections = getconnectionsfunc(voicechatinternal.StateChanged)
            for i = 7, #connections do
                if connections[i] then connections[i]:Disable() end
            end
            
            task.wait(2)
            voicechatservice:joinVoice()
            
            pcall(function()
                unibarcontainer = unibarmenu:WaitForChild("2", 15):WaitForChild("3", 15)
                micmutebutton = unibarcontainer:WaitForChild("toggle_mic_mute", 15)
            end)
            
            if micmutebutton and unibarcontainer then
                local clonedmutebutton = micmutebutton:Clone()
                micmutebutton.Parent = hiddenfolder
                clonedmutebutton.Name = "toggle_mic_mute_new"
                clonedmutebutton.Parent = unibarcontainer
                
                local clonedicon = geticonlabel(clonedmutebutton)
                local originalicon = geticonlabel(micmutebutton)
                
                setmutestate(true)
                clonedmutebutton:WaitForChild("IconHitArea_toggle_mic_mute", 15).Activated:Connect(function()
                    ismuted = not ismuted
                    setmutestate(ismuted)
                    if ismuted then
                        clonedicon.Image = mutedimage
                    else
                        clonedicon.Image = originalicon.Image
                    end
                end)
                
                StatusLabel.Text = "active ✓"
                StatusLabel.TextColor3 = Color3.fromRGB(100, 210, 100)
                AntiVCButton.Text = "Anti VC Ban ✓"
            else
                StatusLabel.Text = "failed"
                StatusLabel.TextColor3 = Color3.fromRGB(210, 80, 80)
                ran = false
            end
        end)
    end)
end

-- =============================================
-- HUB BUTTON SYSTEM
-- =============================================
local hubButtons = {}
local buttonObjects = {}

local function createHubButton(name, description, callback, order)
    local button = Instance.new("Frame")
    button.Size = UDim2.new(1, 0, 0, 50)
    button.BackgroundTransparency = 1
    button.LayoutOrder = order or #hubButtons + 1
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bg.BackgroundTransparency = 0.88
    bg.BorderSizePixel = 0
    bg.Parent = button
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = bg
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.6
    stroke.Parent = bg
    
    local textButton = Instance.new("TextButton")
    textButton.Size = UDim2.new(1, 0, 1, 0)
    textButton.BackgroundTransparency = 1
    textButton.Text = ""
    textButton.AutoButtonColor = false
    textButton.Parent = button
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -16, 0, 18)
    titleLabel.Position = UDim2.new(0, 8, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.Text = name
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTransparency = 0.1
    titleLabel.Parent = button
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -16, 0, 14)
    descLabel.Position = UDim2.new(0, 8, 0, 28)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.Text = description or "Click to open"
    descLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
    descLabel.TextSize = 10
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextTransparency = 0.45
    descLabel.Parent = button
    
    textButton.MouseEnter:Connect(function()
        TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundTransparency = 0.75 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), { Transparency = 0.3 }):Play()
    end)
    
    textButton.MouseLeave:Connect(function()
        TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundTransparency = 0.88 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), { Transparency = 0.6 }):Play()
    end)
    
    textButton.MouseButton1Click:Connect(function()
        TweenService:Create(bg, TweenInfo.new(0.1), { BackgroundTransparency = 0.7 }):Play()
        task.wait(0.1)
        TweenService:Create(bg, TweenInfo.new(0.1), { BackgroundTransparency = 0.88 }):Play()
        callback()
    end)
    
    return button
end

local function refreshHubButtons()
    for _, obj in ipairs(buttonObjects) do
        if obj.button then
            obj.button:Destroy()
        end
    end
    buttonObjects = {}
    
    table.sort(hubButtons, function(a, b) return (a.order or 0) < (b.order or 0) end)
    
    for i, btn in ipairs(hubButtons) do
        local button = createHubButton(btn.name, btn.description, btn.callback, i)
        button.Parent = ButtonsScrollingFrame
        table.insert(buttonObjects, {
            button = button,
            name = btn.name,
            description = btn.description
        })
    end
    
    task.wait(0.1)
    local canvasHeight = 0
    for _, obj in ipairs(buttonObjects) do
        canvasHeight = canvasHeight + obj.button.AbsoluteSize.Y + 8
    end
    ButtonsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
end

local function filterHubButtons(searchText)
    searchText = searchText:lower()
    for _, obj in ipairs(buttonObjects) do
        local buttonName = obj.name:lower()
        local buttonDesc = obj.description:lower()
        
        if searchText == "" or buttonName:find(searchText) or buttonDesc:find(searchText) then
            obj.button.Visible = true
        else
            obj.button.Visible = false
        end
    end
    
    task.wait(0.05)
    local canvasHeight = 0
    for _, obj in ipairs(buttonObjects) do
        if obj.button.Visible then
            canvasHeight = canvasHeight + obj.button.AbsoluteSize.Y + 8
        end
    end
    ButtonsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
end

local function addHubButton(name, description, callback, order)
    table.insert(hubButtons, {
        name = name,
        description = description,
        callback = callback,
        order = order or #hubButtons + 1
    })
    refreshHubButtons()
end

-- Search functionality
SearchBox.Changed:Connect(function(property)
    if property == "Text" then
        filterHubButtons(SearchBox.Text)
    end
end)

SearchIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        SearchBox.Text = ""
    end
end)

-- Add Anti VC Ban button to hub
addHubButton("Anti VC Ban", "Open Anti VC Ban protection panel", function()
    if not AntiVCGui then
        createAntiVCUI()
    end
    if AntiVCGui then
        antiVCPanelVisible = true
        AntiVCGui.Enabled = true
        local panel = AntiVCGui:FindFirstChildWhichIsA("Frame")
        if panel then
            panel.Position = UDim2.new(0.5, -100, 0.5, -60)
            TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, -100, 0.5, -55) }):Play()
        end
    end
end, 1)

-- =============================================
-- GLOBAL CLEANUP FUNCTION (For external use)
-- =============================================
_G.CompassCleanup = function()
    destroyAllCompassUIs()
    cleanupAllTags()
end

-- =============================================
-- INITIALIZATION
-- =============================================
task.delay(0.5, function()
    initNametags()
end)

-- Global API for adding buttons
_G.CompassAddButton = addHubButton

print("Compass.lol Loaded!")
