-- Auto Movement Script for Roblox
-- Created by Wuysnee
-- Features: Auto Movement & Auto Dodge

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local AUTO_MOVE_DISTANCE = {min = 10, max = 30}
local DODGE_DISTANCE = 5
local MOVE_SPEED = 16
local JUMP_POWER = 50

-- Script States
local autoMovementEnabled = false
local autoDodgeEnabled = false
local isDodging = false
local currentMovement = nil

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MovementScriptGUI"
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 120)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Auto Movement Script"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = mainFrame

-- Auto Movement Toggle
local autoMoveButton = Instance.new("TextButton")
autoMoveButton.Size = UDim2.new(0.9, 0, 0, 30)
autoMoveButton.Position = UDim2.new(0.05, 0, 0, 35)
autoMoveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
autoMoveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoMoveButton.Text = "Auto Movement: OFF"
autoMoveButton.Font = Enum.Font.Gotham
autoMoveButton.TextSize = 12
autoMoveButton.Parent = mainFrame

local autoMoveCorner = Instance.new("UICorner")
autoMoveCorner.CornerRadius = UDim.new(0, 6)
autoMoveCorner.Parent = autoMoveButton

-- Auto Dodge Toggle
local autoDodgeButton = Instance.new("TextButton")
autoDodgeButton.Size = UDim2.new(0.9, 0, 0, 30)
autoDodgeButton.Position = UDim2.new(0.05, 0, 0, 75)
autoDodgeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
autoDodgeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoDodgeButton.Text = "Auto Dodge: OFF"
autoDodgeButton.Font = Enum.Font.Gotham
autoDodgeButton.TextSize = 12
autoDodgeButton.Parent = mainFrame

local autoDodgeCorner = Instance.new("UICorner")
autoDodgeCorner.CornerRadius = UDim.new(0, 6)
autoDodgeCorner.Parent = autoDodgeButton

-- Functions
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
    local duration = distance / MOVE_SPEED
    
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

-- Main loops
local autoMoveConnection
local dodgeConnection

local function startAutoMovement()
    autoMovementEnabled = true
    autoMoveButton.Text = "Auto Movement: ON"
    autoMoveButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    
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
    autoMoveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    
    if autoMoveConnection then
        autoMoveConnection:Disconnect()
        autoMoveConnection = nil
    end
    
    if currentMovement then
        currentMovement:Cancel()
        currentMovement = nil
    end
end

local function startAutoDodge()
    autoDodgeEnabled = true
    autoDodgeButton.Text = "Auto Dodge: ON"
    autoDodgeButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    
    dodgeConnection = RunService.Heartbeat:Connect(function()
        if not autoDodgeEnabled then return end
        
        local nearbyPlayers = getNearbyPlayers()
        
        if #nearbyPlayers > 0 and autoMovementEnabled then
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
    autoDodgeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    
    if dodgeConnection then
        dodgeConnection:Disconnect()
        dodgeConnection = nil
    end
    
    isDodging = false
end

-- Button click events
autoMoveButton.MouseButton1Click:Connect(function()
    if autoMovementEnabled then
        stopAutoMovement()
    else
        startAutoMovement()
    end
end)

autoDodgeButton.MouseButton1Click:Connect(function()
    if autoDodgeEnabled then
        stopAutoDodge()
    else
        startAutoDodge()
    end
end)

-- Character respawn handling
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    if autoMovementEnabled then
        stopAutoMovement()
        startAutoMovement()
    end
    
    if autoDodgeEnabled then
        stopAutoDodge()
        startAutoDodge()
    end
end)

print("✅ Kalitor Script Loaded Successfully!")
print("📝 Features: Auto Movement & Auto Dodge")
print("🎮 GUI is visible on screen")
