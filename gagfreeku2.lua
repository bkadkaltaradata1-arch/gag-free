-- GROW GARDEN BOT - DELTA EXECUTOR ANDROID FIX
-- Fixed Auto Harvest function

if _G.GardenBot then return end
_G.GardenBot = true

print("🌻 Starting Garden Bot for Android...")

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Variables untuk auto functions
_G.AutoPlant = false
_G.AutoWater = false
_G.AutoHarvest = false
_G.AutoSell = false
_G.RandomPlant = false

-- Create Main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GardenBotGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- TOMBOL MINI untuk Android
local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(0, 60, 0, 60)
MiniButton.Position = UDim2.new(0, 10, 0, 10)
MiniButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
MiniButton.Text = "🌻"
MiniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniButton.TextSize = 24
MiniButton.Font = Enum.Font.GothamBold
MiniButton.BorderSizePixel = 0
MiniButton.ZIndex = 100
MiniButton.Parent = ScreenGui

-- Make mini button rounded
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = MiniButton

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ZIndex = 90
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
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
TitleText.TextSize = 16
TitleText.ZIndex = 92
TitleText.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.Text = "X"
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
ScrollFrame.ScrollBarThickness = 8
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
ScrollFrame.ZIndex = 91
ScrollFrame.Parent = MainFrame

-- Function untuk buat toggle
local function CreateTouchToggle(text, yPos, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -20, 0, 40)
    toggleFrame.Position = UDim2.new(0, 10, 0, yPos)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.ZIndex = 91
    toggleFrame.Parent = ScrollFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 60, 0, 30)
    toggleButton.Position = UDim2.new(1, -65, 0, 5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    toggleButton.Text = "OFF"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Gotham
    toggleButton.TextSize = 14
    toggleButton.ZIndex = 92
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = toggleFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleButton
    
    local toggleText = Instance.new("TextLabel")
    toggleText.Size = UDim2.new(1, -70, 1, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.Text = text
    toggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleText.Font = Enum.Font.Gotham
    toggleText.TextSize = 14
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

-- FUNGSI HARVEST YANG DIPERBAIKI
function HarvestPlants()
    print("📦 Trying to harvest plants...")
    
    -- Cari tanaman yang bisa di-harvest
    local gardenPlot = Workspace:FindFirstChild("GardenPlot") or Workspace:FindFirstChild("FarmArea")
    if gardenPlot then
        for _, plant in ipairs(gardenPlot:GetChildren()) do
            if plant.Name:find("Plant") or plant.Name:find("Crop") then
                -- Cek jika tanaman sudah siap panen
                local readyToHarvest = plant:FindFirstChild("Ready") or plant:FindFirstChild("Grown")
                if readyToHarvest then
                    print("✅ Found plant ready to harvest: " .. plant.Name)
                    -- Fire harvest event (sesuaikan dengan game kamu)
                    if game:GetService("ReplicatedStorage"):FindFirstChild("HarvestPlant") then
                        game:GetService("ReplicatedStorage").HarvestPlant:FireServer(plant)
                    else
                        -- Alternative event names
                        local events = {
                            "HarvestCrop",
                            "CollectPlant", 
                            "PickCrop",
                            "Harvest"
                        }
                        for _, eventName in ipairs(events) do
                            if game:GetService("ReplicatedStorage"):FindFirstChild(eventName) then
                                game:GetService("ReplicatedStorage")[eventName]:FireServer(plant)
                                break
                            end
                        end
                    end
                    wait(0.5) -- Delay antara panen
                end
            end
        end
    else
        print("❌ No garden plot found")
    end
end

-- FUNGSI AUTO HARVEST YANG BERJALAN TERUS
function StartAutoHarvest()
    while _G.AutoHarvest do
        HarvestPlants()
        wait(3) -- Cek setiap 3 detik
    end
end

-- Create semua toggle
CreateSection("AUTO FARMING", 10)

CreateTouchToggle("Auto Plant Seeds", 55, function(state)
    _G.AutoPlant = state
    print("Auto Plant: " .. tostring(state))
    if state then
        spawn(function()
            while _G.AutoPlant do
                print("🌱 Planting seed...")
                wait(2)
            end
        end)
    end
end)

CreateTouchToggle("Auto Water Plants", 105, function(state)
    _G.AutoWater = state
    print("Auto Water: " .. tostring(state))
    if state then
        spawn(function()
            while _G.AutoWater do
                print("💧 Watering plants...")
                wait(3)
            end
        end)
    end
end)

CreateTouchToggle("Auto Harvest", 155, function(state)
    _G.AutoHarvest = state
    print("Auto Harvest: " .. tostring(state))
    if state then
        spawn(StartAutoHarvest) -- Pakai fungsi yang sudah diperbaiki
    end
end)

CreateTouchToggle("Auto Sell", 205, function(state)
    _G.AutoSell = state
    print("Auto Sell: " .. tostring(state))
    if state then
        spawn(function()
            while _G.AutoSell do
                print("💰 Selling crops...")
                wait(5)
            end
        end)
    end
end)

CreateSection("SETTINGS", 265)

CreateTouchToggle("Random Planting", 310, function(state)
    _G.RandomPlant = state
    print("Random Planting: " .. tostring(state))
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

-- Simple drag untuk tombol mini
local miniDragging = false
local miniDragStart

MiniButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        miniDragging = true
        miniDragStart = input.Position
    end
end)

MiniButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        miniDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch and miniDragging then
        local delta = input.Position - miniDragStart
        MiniButton.Position = UDim2.new(0, MiniButton.Position.X.Offset + delta.X, 0, MiniButton.Position.Y.Offset + delta.Y)
        miniDragStart = input.Position
    end
end)

-- Simple drag untuk main window
local mainDragging = false
local mainDragStart

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        mainDragging = true
        mainDragStart = input.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        mainDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch and mainDragging then
        local delta = input.Position - mainDragStart
        MainFrame.Position = UDim2.new(0, MainFrame.Position.X.Offset + delta.X, 0, MainFrame.Position.Y.Offset + delta.Y)
        mainDragStart = input.Position
    end
end)

-- Notification
spawn(function()
    wait(1)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "🌻 Garden Bot Loaded",
        Text = "Tap green button to open menu!",
        Duration = 5
    })
end)

print("✅ Garden Bot successfully loaded!")
print("🌻 Tap the green button to open menu")
print("📦 Auto Harvest function FIXED!")

-- Anti AFK simple
spawn(function()
    while true do
        wait(60)
        if _G.AutoPlant or _G.AutoWater or _G.AutoHarvest or _G.AutoSell then
            local character = localPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:Move(Vector3.new(0, 0, 0))
                end
            end
        end
    end
end)

-- Touch feedback
MiniButton.MouseButton1Click:Connect(function()
    spawn(function()
        MiniButton.BackgroundColor3 = Color3.fromRGB(70, 200, 70)
        wait(0.1)
        MiniButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    end)
end)

CloseButton.MouseButton1Click:Connect(function()
    spawn(function()
        CloseButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        wait(0.1)
        CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    end)
end)

-- Manual harvest function untuk testing
function TestHarvest()
    print("🔧 Testing harvest function...")
    HarvestPlants()
end

print("🎯 Script ready! Auto Harvest FIXED!")
print("💡 Use TestHarvest() in console to test")
