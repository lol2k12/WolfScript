-- Crosshair Menu - PC + Mobile Ready
-- PC: follows mouse
-- Mobile: center screen crosshair
-- Default OFF + Floating/Draggable Button/Menu
-- Image Crosshairs + Simple Crosshairs
-- Color option only for Simple Crosshairs
-- Supports named colors + HEX + RGB

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local WHITE = Color3.fromRGB(255, 255, 255)
local CYAN = Color3.fromRGB(0, 200, 255)

local crosshairEnabled = false -- DEFAULT OFF
local hideDefaultMouse = true

local currentGui = nil
local followConnection = nil

local crosshairSize = 44
local crosshairColor = WHITE

local imageCrosshairs = {
    {kind = "image", name = "Precision Circle", id = "104322687020478"},
    {kind = "image", name = "Tactical Corners", id = "99542071388975"},
    {kind = "image", name = "Target Focus", id = "139696778583255"},
    {kind = "image", name = "Arrow Lock", id = "108466490720803"},
    {kind = "image", name = "Diagonal Strike", id = "78211887498083"},
}

local simpleCrosshairs = {
    {kind = "simple", name = "Classic Plus"},
    {kind = "simple", name = "Gap Plus"},
    {kind = "simple", name = "Center Dot"},
    {kind = "simple", name = "Small Dot"},
    {kind = "simple", name = "Box Reticle"},
    {kind = "simple", name = "Corner Reticle"},
    {kind = "simple", name = "Circle Reticle"},
}

local quickColors = {
    {name = "White", color = Color3.fromRGB(255, 255, 255)},
    {name = "Red", color = Color3.fromRGB(255, 0, 0)},
    {name = "Green", color = Color3.fromRGB(0, 255, 0)},
    {name = "Blue", color = Color3.fromRGB(0, 120, 255)},
    {name = "Cyan", color = Color3.fromRGB(0, 220, 255)},
    {name = "Yellow", color = Color3.fromRGB(255, 230, 0)},
    {name = "Purple", color = Color3.fromRGB(180, 80, 255)},
}

local namedColorHex = {
    aliceblue="f0f8ff", antiquewhite="faebd7", aqua="00ffff", aquamarine="7fffd4",
    azure="f0ffff", beige="f5f5dc", bisque="ffe4c4", black="000000",
    blanchedalmond="ffebcd", blue="0000ff", blueviolet="8a2be2", brown="a52a2a",
    burlywood="deb887", cadetblue="5f9ea0", chartreuse="7fff00", chocolate="d2691e",
    coral="ff7f50", cornflowerblue="6495ed", cornsilk="fff8dc", crimson="dc143c",
    cyan="00ffff", darkblue="00008b", darkcyan="008b8b", darkgoldenrod="b8860b",
    darkgray="a9a9a9", darkgrey="a9a9a9", darkgreen="006400", darkkhaki="bdb76b",
    darkmagenta="8b008b", darkolivegreen="556b2f", darkorange="ff8c00",
    darkorchid="9932cc", darkred="8b0000", darksalmon="e9967a",
    darkseagreen="8fbc8f", darkslateblue="483d8b", darkslategray="2f4f4f",
    darkslategrey="2f4f4f", darkturquoise="00ced1", darkviolet="9400d3",
    deeppink="ff1493", deepskyblue="00bfff", dimgray="696969", dimgrey="696969",
    dodgerblue="1e90ff", firebrick="b22222", floralwhite="fffaf0",
    forestgreen="228b22", fuchsia="ff00ff", gainsboro="dcdcdc",
    ghostwhite="f8f8ff", gold="ffd700", goldenrod="daa520", gray="808080",
    grey="808080", green="008000", greenyellow="adff2f", honeydew="f0fff0",
    hotpink="ff69b4", indianred="cd5c5c", indigo="4b0082", ivory="fffff0",
    khaki="f0e68c", lavender="e6e6fa", lavenderblush="fff0f5",
    lawngreen="7cfc00", lemonchiffon="fffacd", lightblue="add8e6",
    lightcoral="f08080", lightcyan="e0ffff", lightgoldenrodyellow="fafad2",
    lightgray="d3d3d3", lightgrey="d3d3d3", lightgreen="90ee90",
    lightpink="ffb6c1", lightsalmon="ffa07a", lightseagreen="20b2aa",
    lightskyblue="87cefa", lightslategray="778899", lightslategrey="778899",
    lightsteelblue="b0c4de", lightyellow="ffffe0", lime="00ff00",
    limegreen="32cd32", linen="faf0e6", magenta="ff00ff", maroon="800000",
    mediumaquamarine="66cdaa", mediumblue="0000cd", mediumorchid="ba55d3",
    mediumpurple="9370db", mediumseagreen="3cb371", mediumslateblue="7b68ee",
    mediumspringgreen="00fa9a", mediumturquoise="48d1cc",
    mediumvioletred="c71585", midnightblue="191970", mintcream="f5fffa",
    mistyrose="ffe4e1", moccasin="ffe4b5", navajowhite="ffdead",
    navy="000080", oldlace="fdf5e6", olive="808000", olivedrab="6b8e23",
    orange="ffa500", orangered="ff4500", orchid="da70d6", palegoldenrod="eee8aa",
    palegreen="98fb98", paleturquoise="afeeee", palevioletred="db7093",
    papayawhip="ffefd5", peachpuff="ffdab9", peru="cd853f", pink="ffc0cb",
    plum="dda0dd", powderblue="b0e0e6", purple="800080", rebeccapurple="663399",
    red="ff0000", rosybrown="bc8f8f", royalblue="4169e1", saddlebrown="8b4513",
    salmon="fa8072", sandybrown="f4a460", seagreen="2e8b57", seashell="fff5ee",
    sienna="a0522d", silver="c0c0c0", skyblue="87ceeb", slateblue="6a5acd",
    slategray="708090", slategrey="708090", snow="fffafa", springgreen="00ff7f",
    steelblue="4682b4", tan="d2b48c", teal="008080", thistle="d8bfd8",
    tomato="ff6347", turquoise="40e0d0", violet="ee82ee", wheat="f5deb3",
    white="ffffff", whitesmoke="f5f5f5", yellow="ffff00", yellowgreen="9acd32",

    lightred="ff6464", darkpurple="5a008c", neon="39ff14",
    neonblue="0078ff", neonred="ff1414", neongreen="39ff14",
    neonyellow="ffff00", neonpink="ff1493",
}

local selected = imageCrosshairs[1]

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function getViewport()
    local cam = workspace.CurrentCamera
    if cam then
        return cam.ViewportSize
    end
    return Vector2.new(800, 600)
end

local oldMenu = PlayerGui:FindFirstChild("CrosshairMenu")
if oldMenu then oldMenu:Destroy() end

local oldCrosshair = PlayerGui:FindFirstChild("CustomCrosshair")
if oldCrosshair then oldCrosshair:Destroy() end

local function addCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = obj
    return c
end

local function setMouseVisible(visible)
    pcall(function()
        UserInputService.MouseIconEnabled = visible
    end)
end

local function hexToColor(hex)
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    return Color3.fromRGB(r, g, b)
end

local function parseColorText(text)
    text = tostring(text or ""):lower()
    text = text:gsub("[%s_%-%/]+", "")

    if namedColorHex[text] then
        return hexToColor(namedColorHex[text])
    end

    local hex = text:gsub("#", "")
    if #hex == 6 and hex:match("^[%da-f]+$") then
        return hexToColor(hex)
    end

    local r, g, b = text:match("^rgb%((%d+),(%d+),(%d+)%)$")
    if not r then
        r, g, b = text:match("^(%d+),(%d+),(%d+)$")
    end

    if r and g and b then
        r = math.clamp(tonumber(r), 0, 255)
        g = math.clamp(tonumber(g), 0, 255)
        b = math.clamp(tonumber(b), 0, 255)
        return Color3.fromRGB(r, g, b)
    end

    return nil
end

local function stopFollow()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
end

local function destroyCrosshair()
    stopFollow()

    if currentGui then
        currentGui:Destroy()
        currentGui = nil
    end
end

local function makeLine(parent, size, pos)
    local line = Instance.new("Frame")
    line.Parent = parent
    line.Size = size
    line.Position = pos
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = crosshairColor
    line.BorderSizePixel = 0
    line.ZIndex = 999999
    return line
end

local function makeDot(parent, size)
    local dot = makeLine(parent, UDim2.new(0, size, 0, size), UDim2.new(0.5, 0, 0.5, 0))
    addCorner(dot, 999)
    return dot
end

local function createCrosshair()
    if not crosshairEnabled then return end

    destroyCrosshair()

    if isMobile() then
        setMouseVisible(true)
    else
        setMouseVisible(not hideDefaultMouse)
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CustomCrosshair"
    gui.Parent = PlayerGui
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999

    local holder = Instance.new("Frame")
    holder.Name = "CrosshairHolder"
    holder.Parent = gui
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Size = UDim2.new(0, crosshairSize, 0, crosshairSize)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 999999

    followConnection = RunService.RenderStepped:Connect(function()
        if isMobile() then
            local viewport = getViewport()
            holder.Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2)
        else
            local mousePos = UserInputService:GetMouseLocation()
            holder.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
        end
    end)

    if selected.kind == "image" then
        local img = Instance.new("ImageLabel")
        img.Parent = holder
        img.AnchorPoint = Vector2.new(0.5, 0.5)
        img.Position = UDim2.new(0.5, 0, 0.5, 0)
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.BorderSizePixel = 0
        img.ImageColor3 = WHITE
        img.Image = "rbxthumb://type=Asset&id=" .. tostring(selected.id) .. "&w=150&h=150"
        img.ZIndex = 999999
    else
        local t = selected.name

        if t == "Classic Plus" then
            makeLine(holder, UDim2.new(0, 26, 0, 3), UDim2.new(0.5, 0, 0.5, 0))
            makeLine(holder, UDim2.new(0, 3, 0, 26), UDim2.new(0.5, 0, 0.5, 0))

        elseif t == "Gap Plus" then
            makeLine(holder, UDim2.new(0, 13, 0, 3), UDim2.new(0.5, -17, 0.5, 0))
            makeLine(holder, UDim2.new(0, 13, 0, 3), UDim2.new(0.5, 17, 0.5, 0))
            makeLine(holder, UDim2.new(0, 3, 0, 13), UDim2.new(0.5, 0, 0.5, -17))
            makeLine(holder, UDim2.new(0, 3, 0, 13), UDim2.new(0.5, 0, 0.5, 17))
            makeDot(holder, 3)

        elseif t == "Center Dot" then
            makeDot(holder, 7)

        elseif t == "Small Dot" then
            makeDot(holder, 4)

        elseif t == "Box Reticle" then
            makeLine(holder, UDim2.new(0, 24, 0, 3), UDim2.new(0.5, 0, 0.5, -12))
            makeLine(holder, UDim2.new(0, 24, 0, 3), UDim2.new(0.5, 0, 0.5, 12))
            makeLine(holder, UDim2.new(0, 3, 0, 24), UDim2.new(0.5, -12, 0.5, 0))
            makeLine(holder, UDim2.new(0, 3, 0, 24), UDim2.new(0.5, 12, 0.5, 0))

        elseif t == "Corner Reticle" then
            makeLine(holder, UDim2.new(0, 12, 0, 3), UDim2.new(0.5, -18, 0.5, -18))
            makeLine(holder, UDim2.new(0, 3, 0, 12), UDim2.new(0.5, -24, 0.5, -12))
            makeLine(holder, UDim2.new(0, 12, 0, 3), UDim2.new(0.5, 18, 0.5, -18))
            makeLine(holder, UDim2.new(0, 3, 0, 12), UDim2.new(0.5, 24, 0.5, -12))
            makeLine(holder, UDim2.new(0, 12, 0, 3), UDim2.new(0.5, -18, 0.5, 18))
            makeLine(holder, UDim2.new(0, 3, 0, 12), UDim2.new(0.5, -24, 0.5, 12))
            makeLine(holder, UDim2.new(0, 12, 0, 3), UDim2.new(0.5, 18, 0.5, 18))
            makeLine(holder, UDim2.new(0, 3, 0, 12), UDim2.new(0.5, 24, 0.5, 12))

        elseif t == "Circle Reticle" then
            local circle = Instance.new("TextLabel")
            circle.Parent = holder
            circle.AnchorPoint = Vector2.new(0.5, 0.5)
            circle.Position = UDim2.new(0.5, 0, 0.5, -2)
            circle.Size = UDim2.new(1.4, 0, 1.4, 0)
            circle.BackgroundTransparency = 1
            circle.Text = "○"
            circle.TextColor3 = crosshairColor
            circle.TextSize = math.floor(crosshairSize * 0.9)
            circle.Font = Enum.Font.GothamBold
            circle.ZIndex = 999999
        end
    end

    currentGui = gui
end

local function makeDraggable(object, handle)
    local dragging = false
    local dragStart
    local startPos
    local moved = false

    handle.Active = true

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local viewport = getViewport()
            local size = object.AbsoluteSize

            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
                moved = true
            end

            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y

            newX = math.clamp(newX, 0, math.max(0, viewport.X - size.X))
            newY = math.clamp(newY, 0, math.max(0, viewport.Y - size.Y))

            object.Position = UDim2.fromOffset(newX, newY)
        end
    end)

    return function()
        local wasMoved = moved
        moved = false
        return wasMoved
    end
end

local menuGui = Instance.new("ScreenGui")
menuGui.Name = "CrosshairMenu"
menuGui.Parent = PlayerGui
menuGui.IgnoreGuiInset = true
menuGui.ResetOnSpawn = false
menuGui.DisplayOrder = 999998

local viewport = getViewport()
local frameWidth = isMobile() and math.min(360, viewport.X - 20) or math.min(400, viewport.X - 40)
local frameHeight = isMobile() and math.min(560, viewport.Y - 30) or math.min(720, viewport.Y - 40)

frameWidth = math.max(frameWidth, 300)
frameHeight = math.max(frameHeight, 360)

local icon = Instance.new("TextButton")
icon.Parent = menuGui
icon.Size = UDim2.fromOffset(isMobile() and 48 or 42, isMobile() and 48 or 42)
icon.Position = UDim2.fromOffset(20, 120)
icon.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
icon.TextColor3 = CYAN
icon.Text = "C"
icon.Font = Enum.Font.GothamBold
icon.TextSize = isMobile() and 22 or 20
icon.BorderSizePixel = 0
icon.ZIndex = 100
addCorner(icon, 8)

local frame = Instance.new("Frame")
frame.Parent = menuGui
frame.Size = UDim2.fromOffset(frameWidth, frameHeight)
frame.Position = UDim2.fromOffset((viewport.X - frameWidth) / 2, (viewport.Y - frameHeight) / 2)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
frame.Visible = false
frame.BorderSizePixel = 0
frame.Active = true
frame.ZIndex = 50
addCorner(frame, 12)

local title = Instance.new("TextLabel")
title.Parent = frame
title.Text = isMobile() and "CROSSHAIR MENU - MOBILE" or "CROSSHAIR MENU - PC"
title.Size = UDim2.new(1, 0, 0, 42)
title.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
title.TextColor3 = CYAN
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.BorderSizePixel = 0
title.ZIndex = 51
addCorner(title, 12)

local content = Instance.new("ScrollingFrame")
content.Parent = frame
content.Size = UDim2.new(1, -20, 1, -55)
content.Position = UDim2.fromOffset(10, 48)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.CanvasSize = UDim2.fromOffset(0, 0)
content.ZIndex = 51

local function makeButton(parent, text, y, h)
    local b = Instance.new("TextButton")
    b.Parent = parent
    b.Size = UDim2.new(1, -20, 0, h or 34)
    b.Position = UDim2.fromOffset(10, y)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamBold
    b.TextSize = isMobile() and 14 or 13
    b.BorderSizePixel = 0
    b.ZIndex = 52
    addCorner(b, 7)
    return b
end

local y = 5

local toggle = makeButton(content, "Crosshair: OFF", y, 38)
toggle.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
y = y + 46

local hideMouseBtn = makeButton(content, "Hide Default Cursor: ON", y, 32)
y = y + 40

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Parent = content
selectedLabel.Size = UDim2.new(1, -20, 0, 24)
selectedLabel.Position = UDim2.fromOffset(10, y)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = CYAN
selectedLabel.Font = Enum.Font.GothamBold
selectedLabel.TextSize = 13
selectedLabel.Text = "Selected: " .. selected.name
selectedLabel.ZIndex = 52
y = y + 28

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Parent = content
sizeLabel.Size = UDim2.new(1, -20, 0, 24)
sizeLabel.Position = UDim2.fromOffset(10, y)
sizeLabel.BackgroundTransparency = 1
sizeLabel.TextColor3 = CYAN
sizeLabel.Font = Enum.Font.GothamBold
sizeLabel.TextSize = 13
sizeLabel.Text = "Size: " .. tostring(crosshairSize)
sizeLabel.ZIndex = 52
y = y + 28

local minus = makeButton(content, "-", y, 30)
minus.Size = UDim2.new(0.48, -15, 0, 30)

local plus = makeButton(content, "+", y, 30)
plus.Size = UDim2.new(0.48, -15, 0, 30)
plus.Position = UDim2.new(0.52, 5, 0, y)

y = y + 42

local colorFrame = Instance.new("Frame")
colorFrame.Parent = content
colorFrame.Size = UDim2.new(1, -20, 0, 170)
colorFrame.Position = UDim2.fromOffset(10, y)
colorFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
colorFrame.BorderSizePixel = 0
colorFrame.Visible = false
colorFrame.ZIndex = 52
addCorner(colorFrame, 8)

local colorTitle = Instance.new("TextLabel")
colorTitle.Parent = colorFrame
colorTitle.Size = UDim2.new(1, 0, 0, 24)
colorTitle.BackgroundTransparency = 1
colorTitle.Text = "SIMPLE CROSSHAIR COLOR"
colorTitle.TextColor3 = CYAN
colorTitle.Font = Enum.Font.GothamBold
colorTitle.TextSize = 12
colorTitle.ZIndex = 53

for i, c in ipairs(quickColors) do
    local b = Instance.new("TextButton")
    b.Parent = colorFrame
    b.Size = UDim2.fromOffset(34, 34)
    b.Position = UDim2.fromOffset(13 + ((i - 1) * 44), 34)
    b.BackgroundColor3 = c.color
    b.Text = ""
    b.BorderSizePixel = 0
    b.ZIndex = 53
    addCorner(b, 999)

    b.MouseButton1Click:Connect(function()
        crosshairColor = c.color
        if selected.kind == "simple" and crosshairEnabled then
            createCrosshair()
        end
    end)
end

local colorInput = Instance.new("TextBox")
colorInput.Parent = colorFrame
colorInput.Size = UDim2.new(0.9, 0, 0, 30)
colorInput.Position = UDim2.new(0.05, 0, 0, 82)
colorInput.PlaceholderText = "red / lightblue / #ff0000 / 255,0,0"
colorInput.Text = ""
colorInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
colorInput.TextColor3 = WHITE
colorInput.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
colorInput.Font = Enum.Font.Gotham
colorInput.TextSize = 12
colorInput.BorderSizePixel = 0
colorInput.ClearTextOnFocus = false
colorInput.ZIndex = 53
addCorner(colorInput, 6)

local applyColorBtn = Instance.new("TextButton")
applyColorBtn.Parent = colorFrame
applyColorBtn.Size = UDim2.new(0.9, 0, 0, 30)
applyColorBtn.Position = UDim2.new(0.05, 0, 0, 124)
applyColorBtn.Text = "Apply Custom Color"
applyColorBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
applyColorBtn.TextColor3 = WHITE
applyColorBtn.Font = Enum.Font.GothamBold
applyColorBtn.TextSize = 12
applyColorBtn.BorderSizePixel = 0
applyColorBtn.ZIndex = 53
addCorner(applyColorBtn, 6)

local listTitle = Instance.new("TextLabel")
listTitle.Parent = content
listTitle.Size = UDim2.new(1, -20, 0, 24)
listTitle.BackgroundTransparency = 1
listTitle.Text = "SELECT CROSSHAIR"
listTitle.TextColor3 = CYAN
listTitle.Font = Enum.Font.GothamBold
listTitle.TextSize = 13
listTitle.ZIndex = 52

local allButtons = {}

local function addSection(text)
    local label = Instance.new("TextLabel")
    label.Parent = content
    label.Size = UDim2.new(1, -20, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CYAN
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.ZIndex = 52
    table.insert(allButtons, {obj = label, section = true})
end

local function addCrosshairButton(ch)
    local btn = Instance.new("TextButton")
    btn.Parent = content
    btn.Size = UDim2.new(1, -20, 0, isMobile() and 36 or 32)
    btn.Text = ch.name
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.TextColor3 = WHITE
    btn.Font = Enum.Font.Gotham
    btn.TextSize = isMobile() and 14 or 13
    btn.BorderSizePixel = 0
    btn.ZIndex = 52
    addCorner(btn, 6)

    btn.MouseButton1Click:Connect(function()
        selected = ch
        selectedLabel.Text = "Selected: " .. selected.name

        if crosshairEnabled then
            createCrosshair()
        end

        refreshLayout()
    end)

    table.insert(allButtons, {obj = btn, section = false})
end

addSection("IMAGE CROSSHAIRS")
for _, ch in ipairs(imageCrosshairs) do
    addCrosshairButton(ch)
end

addSection("SIMPLE CROSSHAIRS")
for _, ch in ipairs(simpleCrosshairs) do
    addCrosshairButton(ch)
end

function refreshLayout()
    local posY = y

    colorFrame.Visible = selected.kind == "simple"

    if selected.kind == "simple" then
        colorFrame.Position = UDim2.fromOffset(10, posY)
        posY = posY + 180
    end

    listTitle.Position = UDim2.fromOffset(10, posY)
    posY = posY + 30

    for _, data in ipairs(allButtons) do
        data.obj.Position = UDim2.fromOffset(10, posY)
        posY = posY + (data.section and 28 or (isMobile() and 42 or 38))
    end

    content.CanvasSize = UDim2.fromOffset(0, posY + 20)
end

local function applyTypedColor()
    local newColor = parseColorText(colorInput.Text)

    if newColor then
        crosshairColor = newColor
        applyColorBtn.Text = "Color Applied"

        if selected.kind == "simple" and crosshairEnabled then
            createCrosshair()
        end

        task.delay(1, function()
            if applyColorBtn then
                applyColorBtn.Text = "Apply Custom Color"
            end
        end)
    else
        applyColorBtn.Text = "Invalid Color"

        task.delay(1, function()
            if applyColorBtn then
                applyColorBtn.Text = "Apply Custom Color"
            end
        end)
    end
end

applyColorBtn.MouseButton1Click:Connect(applyTypedColor)

colorInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        applyTypedColor()
    end
end)

toggle.MouseButton1Click:Connect(function()
    crosshairEnabled = not crosshairEnabled

    if crosshairEnabled then
        toggle.Text = "Crosshair: ON"
        toggle.BackgroundColor3 = Color3.fromRGB(40, 140, 90)
        createCrosshair()
    else
        toggle.Text = "Crosshair: OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
        destroyCrosshair()
        setMouseVisible(true)
    end
end)

hideMouseBtn.MouseButton1Click:Connect(function()
    hideDefaultMouse = not hideDefaultMouse

    if hideDefaultMouse then
        hideMouseBtn.Text = "Hide Default Cursor: ON"
    else
        hideMouseBtn.Text = "Hide Default Cursor: OFF"
    end

    if crosshairEnabled and not isMobile() then
        setMouseVisible(not hideDefaultMouse)
    end
end)

minus.MouseButton1Click:Connect(function()
    crosshairSize = math.max(20, crosshairSize - 4)
    sizeLabel.Text = "Size: " .. tostring(crosshairSize)

    if crosshairEnabled then
        createCrosshair()
    end
end)

plus.MouseButton1Click:Connect(function()
    crosshairSize = math.min(100, crosshairSize + 4)
    sizeLabel.Text = "Size: " .. tostring(crosshairSize)

    if crosshairEnabled then
        createCrosshair()
    end
end)

local iconWasDragged = makeDraggable(icon, icon)
makeDraggable(frame, title)

icon.MouseButton1Click:Connect(function()
    if iconWasDragged() then return end
    frame.Visible = not frame.Visible
end)

refreshLayout()
setMouseVisible(true)

print("[Crosshair Menu] Loaded - PC + Mobile Ready")