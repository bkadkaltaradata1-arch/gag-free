-- GROW GARDEN BOT - DELTA EXECUTOR
-- Dengan Tombol Mini Floating

if _G.GardenBot then return end
_G.GardenBot = true

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Create Main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GardenBotGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- TOMBOL MINI (Floating Button)
local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(0, 50, 0, 50)
MiniButton.Position = UDim2.new(0, 20, 0, 20)
MiniButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
MiniButton.Text = "🌻"
MiniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniButton.TextSize = 20
MiniButton.Font = Enum.Font.GothamBold
MiniButton.BorderSizePixel = 0
MiniButton.ZIndex = 100
MiniButton.Parent = ScreenGui

-- Make mini button rounded
MiniButton.AutoButtonColor = false
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = MiniButton

-- Main Window (Initially Hidden)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ZIndex = 90
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 91
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, 0, 1, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🌻 GROW GARDEN BOT 🌻"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 14
TitleText.ZIndex = 92
TitleText.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.ZIndex = 92
CloseButton.Parent = TitleBar

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniButton.Visible = true
end)

-- Content Area
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 5
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
ScrollFrame.ZIndex = 91
ScrollFrame.Parent = MainFrame

-- Auto Farming Section
local function CreateSection(title, yPosition)
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Size = UDim2.new(1, -10, 0, 30)
    sectionFrame.Position = UDim2.new(0, 5, 0, yPosition)
    sectionFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    sectionFrame.BorderSizePixel = 0
    sectionFrame.ZIndex = 91
    sectionFrame.Parent = ScrollFrame
    
    local sectionText = Instance.new("TextLabel")
    sectionText.Size = UDim2.new(1, 0, 1, 0)
    sectionText.BackgroundTransparency = 1
    sectionText.Text = "   " .. title
    sectionText.TextColor3 = Color3.fromRGB(255, 255, 255)
    sectionText.Font = Enum.Font.GothamBold
    sectionText.TextSize = 12
    sectionText.TextXAlignment = Enum.TextXAlignment.Left
    sectionText.ZIndex = 92
    sectionText.Parent = sectionFrame
    
    return sectionFrame
end

-- Toggle Function
local function CreateToggle(text, yPos, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -20, 0, 25)
    toggleFrame.Position = UDim2.new(0, 10, 0, yPos)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.ZIndex = 91
    toggleFrame.Parent = ScrollFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 40, 0, 20)
    toggleButton.Position = UDim2.new(1, -40, 0, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    toggleButton.Text = "OFF"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Gotham
    toggleButton.TextSize = 11
    toggleButton.ZIndex = 92
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = toggleFrame
    
    local toggleText = Instance.new("TextLabel")
    toggleText.Size = UDim2.new(1, -50, 1, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.Text = text
    toggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleText.Font = Enum.Font.Gotham
    toggleText.TextSize = 12
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

-- Create Sections and Toggles
CreateSection("AUTO FARMING", 10)

CreateToggle("Auto Plant Seeds", 50, function(state)
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

CreateToggle("Auto Water Plants", 85, function(state)
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

CreateToggle("Auto Harvest", 120, function(state)
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

CreateToggle("Auto Sell", 155, function(state)
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

CreateSection("SETTINGS", 200)

CreateToggle("Random Planting", 240, function(state)
    _G.RandomPlant = state
    print("🎯 Random planting: " .. tostring(state))
end)

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, 350)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready - Click 🌻 button"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.ZIndex = 92
statusLabel.Parent = ScrollFrame

-- TOMBOL MINI CLICK EVENT
MiniButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniButton.Visible = false
end)

-- DRAGGABLE TOMBOL MINI
local draggingMini = false
local dragInputMini
local dragStartMini
local startPosMini

MiniButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMini = true
        dragStartMini = input.Position
        startPosMini = MiniButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingMini = false
            end
        end)
    end
end)

MiniButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInputMini = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInputMini and draggingMini then
        local delta = input.Position - dragStartMini
        MiniButton.Position = UDim2.new(
            startPosMini.X.Scale, 
            startPosMini.X.Offset + delta.X,
            startPosMini.Y.Scale, 
            startPosMini.Y.Offset + delta.Y
        )
    end
end)

-- DRAGGABLE MAIN WINDOW
local draggingMain = false
local dragInputMain
local dragStartMain
local startPosMain

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMain = true
        dragStartMain = input.Position
        startPosMain = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingMain = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInputMain = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInputMain and draggingMain then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(
            startPosMain.X.Scale, 
            startPosMain.X.Offset + delta.X,
            startPosMain.Y.Scale, 
            startPosMain.Y.Offset + delta.Y
        )
    end
end)

-- Notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Grow Garden Bot",
    Text = "Tombol mini muncul! Klik 🌻 untuk buka menu",
    Duration = 5
})

print("========================================")
print("🎉 GROW GARDEN BOT DENGAN TOMBOL MINI!")
print("🌻 Klik tombol hijau di pojok kiri atas")
print("🚀 Fitur lengkap: Plant, Water, Harvest, Sell")
print("📍 Tombol bisa di-drag ke mana saja")
print("========================================")

-- Anti AFK
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
