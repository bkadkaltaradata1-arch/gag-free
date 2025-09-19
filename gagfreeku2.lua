-- GROW GARDEN BOT - DELTA EXECUTOR ANDROID
-- Dioptimalkan untuk touch screen mobile

if _G.GardenBot then return end
_G.GardenBot = true

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Create Main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GardenBotGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- TOMBOL MINI untuk Android (lebih besar untuk touch)
local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(0, 60, 0, 60) -- Lebih besar untuk touch
MiniButton.Position = UDim2.new(0, 10, 0, 10)
MiniButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
MiniButton.Text = "🌻"
MiniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniButton.TextSize = 24 -- Text lebih besar
MiniButton.Font = Enum.Font.GothamBold
MiniButton.BorderSizePixel = 0
MiniButton.ZIndex = 100
MiniButton.Parent = ScreenGui

-- Make mini button rounded
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = MiniButton

-- Main Window untuk Android (responsive size)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 400) -- Lebih kecil untuk mobile
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ZIndex = 90
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40) -- Lebih tinggi untuk touch
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 91
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, 0, 1, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🌻 GARDEN BOT 🌻"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 16 -- Text lebih besar
TitleText.ZIndex = 92
TitleText.Parent = TitleBar

-- Close Button (lebih besar untuk touch)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 18
CloseButton.ZIndex = 92
CloseButton.Parent = TitleBar

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniButton.Visible = true
end)

-- Content Area
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -50)
ScrollFrame.Position = UDim2.new(0, 5, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 8 -- Scrollbar lebih tebal
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 650)
ScrollFrame.ZIndex = 91
ScrollFrame.Parent = MainFrame

-- Function untuk buat tombol touch-friendly
local function CreateTouchToggle(text, yPos, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -20, 0, 40) -- Lebih tinggi untuk touch
    toggleFrame.Position = UDim2.new(0, 10, 0, yPos)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.ZIndex = 91
    toggleFrame.Parent = ScrollFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 60, 0, 30) -- Lebih besar untuk touch
    toggleButton.Position = UDim2.new(1, -65, 0, 5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    toggleButton.Text = "OFF"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Gotham
    toggleButton.TextSize = 14 -- Text lebih besar
    toggleButton.ZIndex = 92
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = toggleFrame
    
    -- Corner untuk toggle button
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleButton
    
    local toggleText = Instance.new("TextLabel")
    toggleText.Size = UDim2.new(1, -70, 1, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.Text = text
    toggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleText.Font = Enum.Font.Gotham
    toggleText.TextSize = 14 -- Text lebih besar
    toggleText.TextXAlignment = Enum.TextXAlignment.Left
    toggleText.ZIndex = 92
    toggleText.Parent = toggleFrame
    
    local isToggled = false
    
    toggleButton.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        if isToggled then
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            toggleButton.Text = "ON"
        else
            toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            toggleButton.Text = "OFF"
        end
        callback(isToggled)
    end)
    
    return toggleFrame
end

-- Create Sections
local function CreateSection(title, yPosition)
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Size = UDim2.new(1, -10, 0, 35)
    sectionFrame.Position = UDim2.new(0, 5, 0, yPosition)
    sectionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    sectionFrame.BorderSizePixel = 0
    sectionFrame.ZIndex = 91
    sectionFrame.Parent = ScrollFrame
    
    local sectionText = Instance.new("TextLabel")
    sectionText.Size = UDim2.new(1, 0, 1, 0)
    sectionText.BackgroundTransparency = 1
    sectionText.Text = "   " .. title
    sectionText.TextColor3 = Color3.fromRGB(255, 255, 255)
    sectionText.Font = Enum.Font.GothamBold
    sectionText.TextSize = 14
    sectionText.TextXAlignment = Enum.TextXAlignment.Left
    sectionText.ZIndex = 92
    sectionText.Parent = sectionFrame
    
    return sectionFrame
end

-- Create semua toggle
CreateSection("AUTO FARMING", 10)

CreateTouchToggle("Auto Plant Seeds", 55, function(state)
    _G.AutoPlant = state
    if state then
        spawn(function()
            while _G.AutoPlant do
                print("🌱 Planting seed...")
                -- game:GetService("ReplicatedStorage").Events.PlantSeed:FireServer("Sunflower")
                wait(2)
            end
        end)
    end
end)

CreateTouchToggle("Auto Water Plants", 105, function(state)
    _G.AutoWater = state
    if state then
        spawn(function()
            while _G.AutoWater do
                print("💧 Watering plants...")
                -- game:GetService("ReplicatedStorage").Events.WaterPlant:FireServer()
                wait(3)
            end
        end)
    end
end)

CreateTouchToggle("Auto Harvest", 155, function(state)
    _G.AutoHarvest = state
    if state then
        spawn(function()
            while _G.AutoHarvest do
                print("📦 Harvesting...")
                -- game:GetService("ReplicatedStorage").Events.HarvestPlant:FireServer()
                wait(4)
            end
        end)
    end
end)

CreateTouchToggle("Auto Sell", 205, function(state)
    _G.AutoSell = state
    if state then
        spawn(function()
            while _G.AutoSell do
                print("💰 Selling crops...")
                -- game:GetService("ReplicatedStorage").Events.SellCrops:FireServer()
                wait(5)
            end
        end)
    end
end)

CreateSection("SETTINGS", 265)

CreateTouchToggle("Random Planting", 310, function(state)
    _G.RandomPlant = state
    print("🎯 Random planting: " .. tostring(state))
end)

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 30)
statusLabel.Position = UDim2.new(0, 5, 0, 370)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready - Tap 🌻 button"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.ZIndex = 92
statusLabel.Parent = ScrollFrame

-- TOMBOL MINI CLICK EVENT
MiniButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniButton.Visible = false
end)

-- DRAGGABLE TOMBOL MINI untuk Android
local draggingMini = false
local dragStartMini
local startPosMini

MiniButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        draggingMini = true
        dragStartMini = input.Position
        startPosMini = MiniButton.Position
    end
end)

MiniButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        draggingMini = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch and draggingMini then
        local delta = input.Position - dragStartMini
        MiniButton.Position = UDim2.new(
            startPosMini.X.Scale, 
            startPosMini.X.Offset + delta.X,
            startPosMini.Y.Scale, 
            startPosMini.Y.Offset + delta.Y
        )
    end
end)

-- DRAGGABLE MAIN WINDOW untuk Android
local draggingMain = false
local dragStartMain
local startPosMain

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        dragStartMain = input.Position
        startPosMain = MainFrame.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch and draggingMain then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(
            startPosMain.X.Scale, 
            startPosMain.X.Offset + delta.X,
            startPosMain.Y.Scale, 
            startPosMain.Y.Offset + delta.Y
        )
    end
end)

-- Auto-close GUI jika character mati/respawn
localPlayer.CharacterAdded:Connect(function()
    MainFrame.Visible = false
    MiniButton.Visible = true
    MiniButton.Position = UDim2.new(0, 10, 0, 10)
end)

-- Notification untuk Android
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🌻 Garden Bot Loaded",
    Text = "Tap green button to open menu!",
    Duration = 5
})

print("========================================")
print("📱 GARDEN BOT FOR ANDROID DELTA")
print("🌻 Tap tombol hijau untuk buka menu")
print("👆 Tombol besar untuk touch screen")
print("📍 Drag tombol ke posisi nyaman")
print("========================================")

-- Simple Anti AFK untuk Android
spawn(function()
    while true do
        wait(30)
        if _G.AutoPlant or _G.AutoWater or _G.AutoHarvest or _G.AutoSell then
            -- Simulate movement untuk anti AFK
            local virtualInput = game:GetService("VirtualInputManager")
            virtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            virtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)

-- Touch vibration effect (optional)
MiniButton.MouseButton1Click:Connect(function()
    -- Simulate vibration feedback
    if game:GetService("UserInputService").TouchEnabled then
        spawn(function()
            MiniButton.BackgroundColor3 = Color3.fromRGB(70, 200, 70)
            wait(0.1)
            MiniButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        end)
    end
end)
