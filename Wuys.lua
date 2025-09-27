-- Wuys Auto Movement Script for Roblox
-- Created by Wuysnee
-- Features: Auto Movement & Auto Dodge + Move Continuous + RGB GUI + TP Click

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Default Configuration
local AUTO_MOVE_DISTANCE = {min = 10, max = 30}
local DODGE_DISTANCE = 5
local MOVE_SPEED = 16
local JUMP_POWER = 50
local MOVE_DURATION = 3.0

-- Script States
local autoMovementEnabled = false
local autoDodgeEnabled = false
local continuousMoveEnabled = false
local isDodging = false
local currentMovement = nil
local tpClickEnabled = false

-- GUI Dragging Variables
local dragging = false
local dragInput, dragStart, startPos

-- RGB Color Variables
local rgbEnabled = true
local rgbCycleTime = 7 -- seconds for full cycle
local rgbHue = 0

-- Minimize State
local isMinimized = false
local originalSize = UDim2.new(0, 220, 0, 250)
local minimizedSize = UDim2.new(0, 40, 0, 40)
local originalPosition = UDim2.new(0, 10, 0, 10)

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WuysAutoMoveGUI"
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = originalSize
mainFrame.Position = originalPosition
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title Bar for Dragging
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 25)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)  -- Adjusted for new buttons
title.Position = UDim2.new(0, 5, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Wuys Auto Move"
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Minimize Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 20, 0, 20)
minimizeButton.Position = UDim2.new(1, -50, 0, 2)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "_"
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 12
minimizeButton.Parent = titleBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 4)
minimizeCorner.Parent = minimizeButton

-- RGB Toggle Button
local rgbButton = Instance.new("TextButton")
rgbButton.Size = UDim2.new(0, 20, 0, 20)
rgbButton.Position = UDim2.new(1, -75, 0, 2)
rgbButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
rgbButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rgbButton.Text = "RGB"
rgbButton.Font = Enum.Font.GothamBold
rgbButton.TextSize = 8
rgbButton.Parent = titleBar

local rgbCorner = Instance.new("UICorner")
rgbCorner.CornerRadius = UDim.new(0, 4)
rgbCorner.Parent = rgbButton

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 2)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 12
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeButton

-- Content Area
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -25)
contentFrame.Position = UDim2.new(0, 0, 0, 25)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Minimized Logo (will be loaded from repository)
local minimizedLogo = Instance.new("ImageLabel")
minimizedLogo.Size = UDim2.new(1, -10, 1, -10)
minimizedLogo.Position = UDim2.new(0, 5, 0, 5)
minimizedLogo.BackgroundTransparency = 1
minimizedLogo.Visible = false
minimizedLogo.Parent = mainFrame

-- Function to load logo from repository
local function loadLogoFromRepository()
    local logoUrl = "https://raw.githubusercontent.com/Wuysnee/WuysScripts/main/png/logo.png"
    
    pcall(function()
        minimizedLogo.Image = logoUrl
        print("✅ Logo loaded successfully from repository")
    end)
    
    -- Fallback if repository loading fails
    if minimizedLogo.Image == "" then
        minimizedLogo.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        print("⚠️ Using fallback logo")
    end
end

-- Minimize/Maximize Functions
local function minimizeGUI()
    isMinimized = true
    
    -- Store original position for restoration
    originalPosition = mainFrame.Position
    
    -- Hide content, show only logo
    contentFrame.Visible = false
    titleBar.Visible = false
    minimizedLogo.Visible = true
    
    -- Resize to small square
    mainFrame.Size = minimizedSize
    
    -- Change minimize button to maximize button
    minimizeButton.Text = "□"
    minimizeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    
    print("📱 GUI minimized")
end

local function maximizeGUI()
    isMinimized = false
    
    -- Hide logo, show content
    minimizedLogo.Visible = false
    contentFrame.Visible = true
    titleBar.Visible = true
    
    -- Restore original size and position
    mainFrame.Size = originalSize
    mainFrame.Position = originalPosition
    
    -- Change maximize button back to minimize button
    minimizeButton.Text = "_"
    minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
    
    print("📱 GUI maximized")
end

-- Minimize Button Click
minimizeButton.MouseButton1Click:Connect(function()
    if isMinimized then
        maximizeGUI()
    else
        minimizeGUI()
    end
end)

-- Move Duration Input
local durationLabel = Instance.new("TextLabel")
durationLabel.Size = UDim2.new(0.4, 0, 0, 20)
durationLabel.Position = UDim2.new(0.05, 0, 0, 10)
durationLabel.BackgroundTransparency = 1
durationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
durationLabel.Text = "Move Time (s):"
durationLabel.Font = Enum.Font.Gotham
durationLabel.TextSize = 11
durationLabel.TextXAlignment = Enum.TextXAlignment.Left
durationLabel.Parent = contentFrame

local durationTextBox = Instance.new("TextBox")
durationTextBox.Size = UDim2.new(0.5, 0, 0, 20)
durationTextBox.Position = UDim2.new(0.5, 0, 0, 10)
durationTextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
durationTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
durationTextBox.Text = "3.0"
durationTextBox.Font = Enum.Font.Gotham
durationTextBox.TextSize = 11
durationTextBox.PlaceholderText = "e.g., 3.5"
durationTextBox.Parent = contentFrame

local durationCorner = Instance.new("UICorner")
durationCorner.CornerRadius = UDim.new(0, 4)
durationCorner.Parent = durationTextBox

-- Dodge Distance Input
local dodgeLabel = Instance.new("TextLabel")
dodgeLabel.Size = UDim2.new(0.4, 0, 0, 20)
dodgeLabel.Position = UDim2.new(0.05, 0, 0, 35)
dodgeLabel.BackgroundTransparency = 1
dodgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
dodgeLabel.Text = "Dodge Distance:"
dodgeLabel.Font = Enum.Font.Gotham
dodgeLabel.TextSize = 11
dodgeLabel.TextXAlignment = Enum.TextXAlignment.Left
dodgeLabel.Parent = contentFrame

local dodgeTextBox = Instance.new("TextBox")
dodgeTextBox.Size = UDim2.new(0.5, 0, 0, 20)
dodgeTextBox.Position = UDim2.new(0.5, 0, 0, 35)
dodgeTextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
dodgeTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
dodgeTextBox.Text = "5"
dodgeTextBox.Font = Enum.Font.Gotham
dodgeTextBox.TextSize = 11
dodgeTextBox.PlaceholderText = "e.g., 7"
dodgeTextBox.Parent = contentFrame

local dodgeCorner = Instance.new("UICorner")
dodgeCorner.CornerRadius = UDim.new(0, 4)
dodgeCorner.Parent = dodgeTextBox

-- Auto Movement Toggle
local autoMoveButton = Instance.new("TextButton")
autoMoveButton.Size = UDim2.new(0.9, 0, 0, 30)
autoMoveButton.Position = UDim2.new(0.05, 0, 0, 65)
autoMoveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
autoMoveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoMoveButton.Text = "Auto Movement: OFF"
autoMoveButton.Font = Enum.Font.Gotham
autoMoveButton.TextSize = 12
autoMoveButton.Parent = contentFrame

local autoMoveCorner = Instance.new("UICorner")
autoMoveCorner.CornerRadius = UDim.new(0, 6)
autoMoveCorner.Parent = autoMoveButton

-- Continuous Movement Toggle
local continuousMoveButton = Instance.new("TextButton")
continuousMoveButton.Size = UDim2.new(0.9, 0, 0, 30)
continuousMoveButton.Position = UDim2.new(0.05, 0, 0, 105)
continuousMoveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
continuousMoveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
continuousMoveButton.Text = "Continuous Move: OFF"
continuousMoveButton.Font = Enum.Font.Gotham
continuousMoveButton.TextSize = 12
continuousMoveButton.Parent = contentFrame

local continuousMoveCorner = Instance.new("UICorner")
continuousMoveCorner.CornerRadius = UDim.new(0, 6)
continuousMoveCorner.Parent = continuousMoveButton

-- Auto Dodge Toggle
local autoDodgeButton = Instance.new("TextButton")
autoDodgeButton.Size = UDim2.new(0.9, 0, 0, 30)
autoDodgeButton.Position = UDim2.new(0.05, 0, 0, 145)
autoDodgeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
autoDodgeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoDodgeButton.Text = "Auto Dodge: OFF"
autoDodgeButton.Font = Enum.Font.Gotham
autoDodgeButton.TextSize = 12
autoDodgeButton.Parent = contentFrame

local autoDodgeCorner = Instance.new("UICorner")
autoDodgeCorner.CornerRadius = UDim.new(0, 6)
autoDodgeCorner.Parent = autoDodgeButton

-- TP Click Toggle
local tpClickButton = Instance.new("TextButton")
tpClickButton.Size = UDim2.new(0.9, 0, 0, 30)
tpClickButton.Position = UDim2.new(0.05, 0, 0, 185)
tpClickButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
tpClickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
tpClickButton.Text = "TP Click: OFF"
tpClickButton.Font = Enum.Font.Gotham
tpClickButton.TextSize = 12
tpClickButton.Parent = contentFrame

local tpClickCorner = Instance.new("UICorner")
tpClickCorner.CornerRadius = UDim.new(0, 6)
tpClickCorner.Parent = tpClickButton

-- RGB Color Functions
local function HSVToRGB(h, s, v)
    h = h % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    local r, g, b
    
    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end
    
    return Color3.new(r, g, b)
end

local function updateRGBColors()
    if not rgbEnabled then return end
    
    local currentTime = tick()
    rgbHue = (currentTime % rgbCycleTime) / rgbCycleTime
    
    local rgbColor = HSVToRGB(rgbHue, 0.8, 0.8)
    local darkerRgb = HSVToRGB(rgbHue, 0.8, 0.6)
    local darkestRgb = HSVToRGB(rgbHue, 0.8, 0.4)
    
    -- Update main frame
    mainFrame.BackgroundColor3 = darkestRgb
    titleBar.BackgroundColor3 = darkerRgb
    
    -- Update buttons
    if autoMovementEnabled then
        autoMoveButton.BackgroundColor3 = rgbColor
    else
        autoMoveButton.BackgroundColor3 = darkerRgb
    end
    
    if continuousMoveEnabled then
        continuousMoveButton.BackgroundColor3 = rgbColor
    else
        continuousMoveButton.BackgroundColor3 = darkerRgb
    end
    
    if autoDodgeEnabled then
        autoDodgeButton.BackgroundColor3 = rgbColor
    else
        autoDodgeButton.BackgroundColor3 = darkerRgb
    end
    
    if tpClickEnabled then
        tpClickButton.BackgroundColor3 = rgbColor
    else
        tpClickButton.BackgroundColor3 = darkerRgb
    end
    
    -- Update RGB button
    rgbButton.BackgroundColor3 = rgbColor
    
    -- Update minimize button color based on state
    if isMinimized then
        minimizeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    else
        minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
    end
end

-- Start RGB cycle
local rgbConnection
local function startRGB()
    rgbEnabled = true
    rgbButton.Text = "RGB"
    rgbConnection = RunService.Heartbeat:Connect(updateRGBColors)
end

local function stopRGB()
    rgbEnabled = false
    rgbButton.Text = "OFF"
    if rgbConnection then
        rgbConnection:Disconnect()
        rgbConnection = nil
    end
    
    -- Reset to default colors
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    rgbButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    if autoMovementEnabled then
        autoMoveButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    else
        autoMoveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    if continuousMoveEnabled then
        continuousMoveButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    else
        continuousMoveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    if autoDodgeEnabled then
        autoDodgeButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    else
        autoDodgeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    if tpClickEnabled then
        tpClickButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    else
        tpClickButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    -- Reset minimize button
    if isMinimized then
        minimizeButton.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
    else
        minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
    end
end

-- RGB Button Click
rgbButton.MouseButton1Click:Connect(function()
    if rgbEnabled then
        stopRGB()
    else
        startRGB()
    end
end)

-- TP Click Functions
local function findHighestPoint()
    local workspace = game:GetService("Workspace")
    local highestPoint = nil
    local highestY = -math.huge
    
    -- Search for parts in the workspace
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
            -- Check if part is likely to be part of the map (not too small)
            if part.Size.Magnitude > 5 then
                local partTopY = part.Position.Y + part.Size.Y/2
                if partTopY > highestY then
                    highestY = partTopY
                    highestPoint = part.Position + Vector3.new(0, part.Size.Y/2 + 3, 0)
                end
            end
        end
    end
    
    -- If no suitable parts found, try terrain
    if highestY == -math.huge then
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            -- Sample terrain at various points
            for x = -200, 200, 50 do
                for z = -200, 200, 50 do
                    local height = terrain:ReadVoxels(Region3.new(
                        Vector3.new(x, -100, z),
                        Vector3.new(x+1, 1000, z+1)
                    ))
                    if height and height > highestY then
                        highestY = height
                        highestPoint = Vector3.new(x, height + 5, z)
                    end
                end
            end
        end
    end
    
    return highestPoint
end

local function teleportToHighestPoint()
    local highestPoint = findHighestPoint()
    if highestPoint then
        -- Stop any current movement
        if currentMovement then
            currentMovement:Cancel()
            currentMovement = nil
        end
        
        -- Teleport character
        character:SetPrimaryPartCFrame(CFrame.new(highestPoint))
        print("🚀 Teleported to highest point: " .. tostring(highestPoint))
        return true
    else
        print("❌ Could not find highest point on the map")
        return false
    end
end

local function onMouseClick()
    if not tpClickEnabled then return end
    
    -- Get mouse target
    local mouse = player:GetMouse()
    if mouse.Target then
        -- Teleport to position above the clicked point
        local targetPos = mouse.Hit.Position + Vector3.new(0, 5, 0)
        
        -- Stop any current movement
        if currentMovement then
            currentMovement:Cancel()
            currentMovement = nil
        end
        
        -- Teleport character
        character:SetPrimaryPartCFrame(CFrame.new(targetPos))
        print("🎯 Teleported to clicked position: " .. tostring(targetPos))
    end
end

local function startTPClick()
    tpClickEnabled = true
    tpClickButton.Text = "TP Click: ON"
    if rgbEnabled then
        tpClickButton.BackgroundColor3 = HSVToRGB(rgbHue, 0.8, 0.8)
    else
        tpClickButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end
    
    -- Add click listener
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            onMouseClick()
        end
    end)
    
    print("🎯 TP Click enabled - Click anywhere to teleport")
end

local function stopTPClick()
    tpClickEnabled = false
    tpClickButton.Text = "TP Click: OFF"
    if rgbEnabled then
        tpClickButton.BackgroundColor3 = HSVToRGB(rgbHue, 0.8, 0.6)
    else
        tpClickButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    print("🎯 TP Click disabled")
end

-- TP Click to Highest Point (Double Click)
local lastClickTime = 0
local function onDoubleClick()
    if not tpClickEnabled then return end
    
    local currentTime = tick()
    if currentTime - lastClickTime < 0.5 then  -- Double click within 0.5 seconds
        teleportToHighestPoint()
    end
    lastClickTime = currentTime
end

-- GUI Dragging Functions (updated for minimized state)
local function updateInput(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

local function onTitleBarInput(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end

titleBar.InputBegan:Connect(onTitleBarInput)
minimizedLogo.InputBegan:Connect(onTitleBarInput)  -- Allow dragging from minimized logo too

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

minimizedLogo.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

-- Close Button Functionality
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    if autoMoveConnection then
        autoMoveConnection:Disconnect()
    end
    if continuousMoveConnection then
        continuousMoveConnection:Disconnect()
    end
    if dodgeConnection then
        dodgeConnection:Disconnect()
    end
    if rgbConnection then
        rgbConnection:Disconnect()
    end
    print("❌ Wuys Auto Move GUI Closed")
end)

-- TextBox Validation Functions
local function parseNumber(text)
    local cleanedText = string.gsub(text, ",", ".")
    cleanedText = string.gsub(cleanedText, "[^%d%.]", "")
    local number = tonumber(cleanedText)
    return number
end

local function validateDuration()
    local duration = parseNumber(durationTextBox.Text)
    if duration and duration > 0 and duration <= 60 then
        durationTextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        MOVE_DURATION = duration
        return true
    else
        durationTextBox.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
        return false
    end
end

local function validateDodgeDistance()
    local distance = parseNumber(dodgeTextBox.Text)
    if distance and distance >= 1 and distance <= 20 then
        dodgeTextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        DODGE_DISTANCE = distance
        return true
    else
        dodgeTextBox.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
        return false
    end
end

-- TextBox Focus Events
durationTextBox.FocusLost:Connect(function()
    if not validateDuration() then
        durationTextBox.Text = "3.0"
        MOVE_DURATION = 3.0
        validateDuration()
    end
    print("📊 Move Duration set to: " .. MOVE_DURATION .. " seconds")
end)

dodgeTextBox.FocusLost:Connect(function()
    if not validateDodgeDistance() then
        dodgeTextBox.Text = "5"
        DODGE_DISTANCE = 5
        validateDodgeDistance()
    end
    print("📊 Dodge Distance set to: " .. DODGE_DISTANCE .. " studs")
end)

-- Movement Functions (giữ nguyên)
local function getRandomDirection()
    local directions = {
        Vector3.new(1, 0, 0),   -- Right
        Vector3.new(-1, 0, 0),  -- Left
        Vector3.new(0, 0, 1),   -- Forward
        Vector3.new(0, 0, -1)   -- Backward
    }
    return directions[math.random(1, 4)]
end

local function getRandomDistance()
    return math.random(AUTO_MOVE_DISTANCE.min, AUTO_MOVE_DISTANCE.max)
end

local function shouldJump()
    return math.random(1, 4) == 1
end

local function getNearbyPlayers()
    local nearbyPlayers = {}
    local players = Players:GetPlayers()
    
    for _, otherPlayer in ipairs(players) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherCharacter = otherPlayer.Character
            local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")
            
            if otherRoot then
                local distance = (rootPart.Position - otherRoot.Position).Magnitude
                if distance <= DODGE_DISTANCE then
                    table.insert(nearbyPlayers, {
                        player = otherPlayer,
                        position = otherRoot.Position,
                        distance = distance
                    })
                end
            end
        end
    end
    
    return nearbyPlayers
end

local function calculateDodgeDirection(nearbyPlayers)
    if #nearbyPlayers == 0 then return nil end
    
    local averagePosition = Vector3.new(0, 0, 0)
    for _, nearbyPlayer in ipairs(nearbyPlayers) do
        averagePosition = averagePosition + nearbyPlayer.position
    end
    averagePosition = averagePosition / #nearbyPlayers
    
    local directionAway = (rootPart.Position - averagePosition).Unit
    directionAway = Vector3.new(directionAway.X, 0, directionAway.Z).Unit
    
    local randomAngle = math.rad(math.random(-45, 45))
    local cosAngle = math.cos(randomAngle)
    local sinAngle = math.sin(randomAngle)
    
    return Vector3.new(
        directionAway.X * cosAngle - directionAway.Z * sinAngle,
        0,
        directionAway.X * sinAngle + directionAway.Z * cosAngle
    ).Unit
end

local function moveToPosition(targetPosition, duration)
    if currentMovement then
        currentMovement:Cancel()
    end
    
    humanoid:MoveTo(targetPosition)
    
    currentMovement = {
        target = targetPosition,
        startTime = tick(),
        duration = duration,
        Cancel = function()
            humanoid:MoveTo(rootPart.Position)
        end
    }
end

local function performAutoMovement()
    if isDodging or not autoMovementEnabled then return end
    
    local direction = getRandomDirection()
    local distance = getRandomDistance()
    local targetPosition = rootPart.Position + (direction * distance)
    local duration = MOVE_DURATION
    
    moveToPosition(targetPosition, duration)
    
    if shouldJump() then
        local jumpCount = math.random(1, 2)
        for i = 1, jumpCount do
            wait(0.2)
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.JumpPower = JUMP_POWER
                humanoid.Jump = true
            end
        end
    end
end

-- Continuous Movement Function
local function performContinuousMovement()
    if isDodging or not continuousMoveEnabled then return end
    
    local direction = getRandomDirection()
    local distance = getRandomDistance()
    local targetPosition = rootPart.Position + (direction * distance)
    
    moveToPosition(targetPosition, 0.1)
    
    if shouldJump() and math.random(1, 10) == 1 then
        wait(0.1)
        if humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid.JumpPower = JUMP_POWER
            humanoid.Jump = true
        end
    end
end

-- Main loops
local autoMoveConnection
local continuousMoveConnection
local dodgeConnection

local function startAutoMovement()
    if not validateDuration() then
        durationTextBox.Text = "3.0"
        MOVE_DURATION = 3.0
        validateDuration()
    end
    
    autoMovementEnabled = true
    autoMoveButton.Text = "Auto Movement: ON"
    if rgbEnabled then
        autoMoveButton.BackgroundColor3 = HSVToRGB(rgbHue, 0.8, 0.8)
    else
        autoMoveButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end
    
    autoMoveConnection = RunService.Heartbeat:Connect(function()
        if not autoMovementEnabled then return end
        
        if not currentMovement or (tick() - currentMovement.startTime) >= currentMovement.duration then
            performAutoMovement()
        end
    end)
end

local function stopAutoMovement()
    autoMovementEnabled = false
    autoMoveButton.Text = "Auto Movement: OFF"
    if rgbEnabled then
        autoMoveButton.BackgroundColor3 = HSVToRGB(rgbHue, 0.8, 0.6)
    else
        autoMoveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    if autoMoveConnection then
        autoMoveConnection:Disconnect()
        autoMoveConnection = nil
    end
    
    if currentMovement then
        currentMovement:Cancel()
        currentMovement = nil
    end
end

local function startContinuousMovement()
    continuousMoveEnabled = true
    continuousMoveButton.Text = "Continuous Move: ON"
    if rgbEnabled then
        continuousMoveButton.BackgroundColor3 = HSVToRGB(rgbHue, 0.8, 0.8)
    else
        continuousMoveButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end
    
    continuousMoveConnection = RunService.Heartbeat:Connect(function()
        if not continuousMoveEnabled then return end
        performContinuousMovement()
    end)
end

local function stopContinuousMovement()
    continuousMoveEnabled = false
    continuousMoveButton.Text = "Continuous Move: OFF"
    if rgbEnabled then
        continuousMoveButton.BackgroundColor3 = HSVToRGB(rgbHue, 0.8, 0.6)
    else
        continuousMoveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    if continuousMoveConnection then
        continuousMoveConnection:Disconnect()
        continuousMoveConnection = nil
    end
    
    if currentMovement then
        currentMovement:Cancel()
        currentMovement = nil
    end
end

local function startAutoDodge()
    if not validateDodgeDistance() then
        dodgeTextBox.Text = "5"
        DODGE_DISTANCE = 5
        validateDodgeDistance()
    end
    
    autoDodgeEnabled = true
    autoDodgeButton.Text = "Auto Dodge: ON"
    if rgbEnabled then
        autoDodgeButton.BackgroundColor3 = HSVToRGB(rgbHue, 0.8, 0.8)
    else
        autoDodgeButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end
    
    dodgeConnection = RunService.Heartbeat:Connect(function()
        if not autoDodgeEnabled then return end
        
        local nearbyPlayers = getNearbyPlayers()
        
        if #nearbyPlayers > 0 and (autoMovementEnabled or continuousMoveEnabled) then
            isDodging = true
            
            if currentMovement then
                currentMovement:Cancel()
                currentMovement = nil
            end
            
            local dodgeDirection = calculateDodgeDirection(nearbyPlayers)
            if dodgeDirection then
                local dodgeDistance = DODGE_DISTANCE * 1.5
                local dodgePosition = rootPart.Position + (dodgeDirection * dodgeDistance)
                local dodgeDuration = dodgeDistance / MOVE_SPEED
                
                moveToPosition(dodgePosition, dodgeDuration)
                wait(dodgeDuration)
                isDodging = false
            end
        else
            isDodging = false
        end
    end)
end

local function stopAutoDodge()
    autoDodgeEnabled = false
    autoDodgeButton.Text = "Auto Dodge: OFF"
    if rgbEnabled then
        autoDodgeButton.BackgroundColor3 = HSVToRGB(rgbHue, 0.8, 0.6)
    else
        autoDodgeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    if dodgeConnection then
        dodgeConnection:Disconnect()
        dodgeConnection = nil
    end
    
    isDodging = false
end

-- Button Click Events
autoMoveButton.MouseButton1Click:Connect(function()
    if autoMovementEnabled then
        stopAutoMovement()
    else
        stopContinuousMovement()
        startAutoMovement()
    end
end)

continuousMoveButton.MouseButton1Click:Connect(function()
    if continuousMoveEnabled then
        stopContinuousMovement()
    else
        stopAutoMovement()
        startContinuousMovement()
    end
end)

autoDodgeButton.MouseButton1Click:Connect(function()
    if autoDodgeEnabled then
        stopAutoDodge()
    else
        startAutoDodge()
    end
end)

tpClickButton.MouseButton1Click:Connect(function()
    if tpClickEnabled then
        stopTPClick()
    else
        startTPClick()
    end
end)

-- Double click detection for TP to highest point
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        onDoubleClick()
    end
end)

-- Initial validation
validateDuration()
validateDodgeDistance()

-- Load logo from repository
loadLogoFromRepository()

-- Start with RGB enabled by default
startRGB()

print("🎮 Wuys Auto Movement Script Loaded!")
print("📱 Features: Auto Movement | Continuous Move | Auto Dodge | TP Click | RGB GUI")
print("🎯 Controls: Click to TP | Double-click for highest point | Drag title bar to move GUI")
print("📱 Use minimize button (_) to hide/show GUI")

-- Character respawn handling
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    print("🔄 Character respawned - movement system reset")
end)
