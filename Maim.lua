-- =============================================
-- 🐺 WolfAlone Script 1.0
-- =============================================

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local uis = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local rs = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local gui = Instance.new("ScreenGui")
gui.Name = "WolfAloneMenu"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- ==================== FLOATING ICON ====================
local icon = Instance.new("TextButton")
icon.Size = UDim2.new(0, 35, 0, 35)
icon.Position = UDim2.new(0, 20, 0.5, -100)
icon.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
icon.Text = "🐺"
icon.TextScaled = true
icon.Font = Enum.Font.GothamBold
icon.TextColor3 = Color3.new(1,1,1)
icon.BorderSizePixel = 0
icon.BackgroundTransparency = 0.2
icon.Parent = gui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 8)
iconCorner.Parent = icon

-- Icon Dragging
local draggingIcon = false
icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingIcon = true
        dragStart = input.Position
        startPos = icon.Position
    end
end)

uis.InputChanged:Connect(function(input)
    if draggingIcon and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        icon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingIcon = false
    end
end)

-- Main Menu
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 380)
mainFrame.Position = UDim2.new(0, 70, 0.35, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.05
mainFrame.Visible = false
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "🐺 WolfAlone Script 1.0"
title.TextColor3 = Color3.fromRGB(0, 255, 180)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

-- Freeze
local function freezeCharacter()
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if humanoid then humanoid.PlatformStand = true end
        if root then root.Anchored = true end
    end
end

local function unfreezeCharacter()
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if humanoid then humanoid.PlatformStand = false end
        if root then root.Anchored = false end
    end
end

-- Remotes
local backpack = player.Backpack
local controlPad = backpack:FindFirstChild("Control Pad", true)
local setHover = controlPad and controlPad:FindFirstChild("SetHover", true)
local setTargeting = controlPad and controlPad:FindFirstChild("SetTargeting", true)

local healingDrone = workspace:FindFirstChild("Healing Drone", true)
local combatDrone = workspace:FindFirstChild("Combat Drone", true)

local droneEnabled = false
local combatEnabled = false
local powerESPEnabled = false
local supplyESPEnabled = false
local droneSpeed = 250
local originalCameraSubject = nil
local espCache = {}

local function setDronePosition(drone, pos)
    if setHover and drone then
        pcall(function() setHover:FireServer(drone, pos) end)
    end
end

-- Healing Drone CTRL
local function toggleHealingDrone(state)
    droneEnabled = state
    if state and healingDrone and healingDrone.PrimaryPart then
        originalCameraSubject = camera.CameraSubject
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = healingDrone.PrimaryPart
        freezeCharacter()
        print("🎥 Healing Drone CTRL ON")
    else
        camera.CameraSubject = originalCameraSubject
        unfreezeCharacter()
        print("🎥 Healing Drone CTRL OFF")
    end
end

-- Smart Combat Drone (500 studs + Focus)
local currentTarget = nil
local function smartCombatBehavior()
    if not combatEnabled or not combatDrone or not setTargeting then return end
    local root = combatDrone.PrimaryPart
    if not root then return end

    if currentTarget and currentTarget.Parent then
        local dist = (currentTarget.Position - root.Position).Magnitude
        if dist < 500 then
            setTargeting:FireServer(combatDrone, currentTarget)
            return
        end
    end

    local closestEnemy = nil
    local closestDist = math.huge

    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local dist = (hrp.Position - root.Position).Magnitude
            if dist < closestDist and dist < 500 then
                closestDist = dist
                closestEnemy = hrp
            end
        end
    end

    if closestEnemy then
        currentTarget = closestEnemy
        setTargeting:FireServer(combatDrone, closestEnemy)
    else
        currentTarget = nil
        if math.random(1, 30) == 1 then
            local offset = Vector3.new(math.random(-50,50), math.random(15,30), math.random(-50,50))
            setDronePosition(combatDrone, root.Position + offset)
        end
    end
end

local function toggleSmartCombat(state)
    combatEnabled = state
    currentTarget = nil
    print("⚔️ Smart Combat Drone:", state and "ON (500 studs)" or "OFF")
end

-- ESP
local function createESP(obj, text, color)
    if espCache[obj] then return end
    local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = root
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.Parent = root

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 0.6
    label.BackgroundColor3 = Color3.fromRGB(0,0,0)
    label.Text = text
    label.TextColor3 = color
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    espCache[obj] = billboard
end

local function updateESP()
    if not (powerESPEnabled or supplyESPEnabled) then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if powerESPEnabled and (name:find("power armor") or name:find("powerarmour")) then
            createESP(obj, "🛡️ Power Armor", Color3.fromRGB(0, 255, 150))
        elseif supplyESPEnabled and name:find("supply") then
            createESP(obj, "📦 Supply Crate", Color3.fromRGB(255, 215, 0))
        end
    end
end

local function togglePowerESP(state)
    powerESPEnabled = state
    if not state then
        for _, v in pairs(espCache) do pcall(function() v:Destroy() end) end
        espCache = {}
    end
end

local function toggleSupplyESP(state)
    supplyESPEnabled = state
    if not state then
        for _, v in pairs(espCache) do pcall(function() v:Destroy() end) end
        espCache = {}
    end
end

-- Menu Buttons
local y = 55
local function createToggle(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 35, 0, 35)
    btn.Position = UDim2.new(0, 15, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    btn.Text = "OFF"
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = mainFrame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 160, 0, 35)
    lbl.Position = UDim2.new(0, 60, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 9
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = mainFrame

    btn.MouseButton1Click:Connect(function()
        local isOn = btn.BackgroundColor3 == Color3.fromRGB(0,170,0)
        isOn = not isOn
        btn.BackgroundColor3 = isOn and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
        btn.Text = isOn and "ON" or "OFF"
        callback(isOn)
    end)
end

createToggle("Healing Drone CTRL", y, toggleHealingDrone); y += 45
createToggle("Smart Combat Drone", y, toggleSmartCombat); y += 45
createToggle("🛡️ Power Armor ESP", y, togglePowerESP); y += 45
createToggle("📦 Supply Crate ESP", y, toggleSupplyESP)

-- Loops
rs.RenderStepped:Connect(function(dt)
    if not droneEnabled or not healingDrone or not healingDrone.PrimaryPart then return end
    local root = healingDrone.PrimaryPart
    local camLook = camera.CFrame.LookVector
    local camRight = camera.CFrame.RightVector
   
    local forward = Vector3.new(camLook.X, 0, camLook.Z).Unit
    local right = Vector3.new(camRight.X, 0, camRight.Z).Unit
   
    local moveDir = Vector3.new()
    if uis:IsKeyDown(Enum.KeyCode.W) then moveDir += forward end
    if uis:IsKeyDown(Enum.KeyCode.S) then moveDir -= forward end
    if uis:IsKeyDown(Enum.KeyCode.A) then moveDir -= right end
    if uis:IsKeyDown(Enum.KeyCode.D) then moveDir += right end
    if uis:IsKeyDown(Enum.KeyCode.E) then moveDir += Vector3.new(0,1,0) end
    if uis:IsKeyDown(Enum.KeyCode.Q) then moveDir -= Vector3.new(0,1,0) end
   
    if moveDir.Magnitude > 0 then
        local newPos = root.Position + (moveDir.Unit * droneSpeed * dt * 3)
        setDronePosition(healingDrone, newPos)
    end
end)

rs.Heartbeat:Connect(function()
    smartCombatBehavior()
    updateESP()
end)

icon.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

print("🐺 WolfAlone Script 1.0 Loaded Successfully!")
