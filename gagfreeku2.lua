-- GROW GARDEN BOT - SMART EVENT DETECTION
-- Auto detect event names untuk berbagai game

if _G.GardenBot then return end
_G.GardenBot = true

print("🌻 Starting Smart Garden Bot...")

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

-- Deteksi Event Names Otomatis
local function FindEvent(eventNames)
    for _, eventName in ipairs(eventNames) do
        local event = ReplicatedStorage:FindFirstChild(eventName) 
                    or ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild(eventName)
                    or ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild(eventName)
        
        if event and event:IsA("RemoteEvent") then
            print("✅ Found event: " .. eventName)
            return event
        end
    end
    return nil
end

-- Deteksi semua event yang mungkin
local PlantEvents = {"PlantSeed", "Plant", "AddSeed", "SowSeed", "PlantCrop"}
local WaterEvents = {"WaterPlant", "Water", "Hydrate", "WaterCrop", "Irrigate"}
local HarvestEvents = {"HarvestPlant", "Harvest", "Collect", "PickCrop", "Gather"}
local SellEvents = {"SellCrops", "Sell", "SellHarvest", "SellItems", "SellProduce"}

local PlantEvent = FindEvent(PlantEvents)
local WaterEvent = FindEvent(WaterEvents)
local HarvestEvent = FindEvent(HarvestEvents)
local SellEvent = FindEvent(SellEvents)

print("🔍 Event Detection Results:")
print("🌱 Plant Event: " .. (PlantEvent and PlantEvent.Name or "Not Found"))
print("💧 Water Event: " .. (WaterEvent and WaterEvent.Name or "Not Found"))
print("📦 Harvest Event: " .. (HarvestEvent and HarvestEvent.Name or "Not Found"))
print("💰 Sell Event: " .. (SellEvent and SellEvent.Name or "Not Found"))

-- Variables
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

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = MiniButton

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 450)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
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
TitleText.Text = "🌻 SMART GARDEN BOT 🌻"
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
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
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

-- FUNGSI HARVEST YANG SMART
function HarvestPlants()
    if not HarvestEvent then
        print("❌ No harvest event found")
        return false
    end
    
    print("📦 Searching for plants to harvest...")
    
    local harvested = false
    
    -- Cari di berbagai lokasi yang mungkin
    local searchLocations = {
        Workspace,
        Workspace:FindFirstChild("GardenPlot"),
        Workspace:FindFirstChild("FarmArea"),
        Workspace:FindFirstChild("Plants"),
        Workspace:FindFirstChild("Crops"),
        Workspace:FindFirstChild("Garden"),
        Workspace:FindFirstChild("Farm")
    }
    
    for _, location in ipairs(searchLocations) do
        if location then
            for _, plant in ipairs(location:GetChildren()) do
                if plant.Name:find("Plant") or plant.Name:find("Crop") or plant:FindFirstChild("Ready") then
                    -- Coba harvest dengan berbagai parameter
                    local success = pcall(function()
                        HarvestEvent:FireServer(plant)
                        print("✅ Harvested: " .. plant.Name)
                        harvested = true
                        wait(0.3)
                    end)
                    
                    if not success then
                        -- Coba tanpa parameter
                        pcall(function()
                            HarvestEvent:FireServer()
                            print("✅ Harvested (no parameter)")
                            harvested = true
                            wait(0.3)
                        end)
                    end
                end
            end
        end
    end
    
    return harvested
end

-- FUNGSI PLANT
function PlantSeeds()
    if not PlantEvent then
        print("❌ No plant event found")
        return false
    end
    
    print("🌱 Planting seed...")
    
    -- Coba dengan berbagai parameter
    local success = pcall(function()
        PlantEvent:FireServer("Sunflower")
        print("✅ Planted Sunflower")
    end)
    
    if not success then
        pcall(function()
            PlantEvent:FireServer()
            print("✅ Planted (no parameter)")
        end)
    end
    
    return true
end

-- FUNGSI WATER
function WaterPlants()
    if not WaterEvent then
        print("❌ No water event found")
        return false
    end
    
    print("💧 Watering plants...")
    
    pcall(function()
        WaterEvent:FireServer()
        print("✅ Watered plants")
    end)
    
    return true
end

-- FUNGSI SELL
function SellCrops()
    if not SellEvent then
        print("❌ No sell event found")
        return false
    end
    
    print("💰 Selling crops...")
    
    pcall(function()
        SellEvent:FireServer()
        print("✅ Sold crops")
    end)
    
    return true
end

-- AUTO FUNCTIONS
function StartAutoHarvest()
    while _G.AutoHarvest do
        HarvestPlants()
        wait(3)
    end
end

function StartAutoPlant()
    while _G.AutoPlant do
        PlantSeeds()
        wait(2)
    end
end

function StartAutoWater()
    while _G.AutoWater do
        WaterPlants()
        wait(3)
    end
end

function StartAutoSell()
    while _G.AutoSell do
        SellCrops()
        wait(5)
    end
end

-- Create GUI Elements
CreateSection("AUTO FARMING", 10)

CreateTouchToggle("Auto Plant Seeds", 55, function(state)
    _G.AutoPlant = state
    print("Auto Plant: " .. tostring(state))
    if state and PlantEvent then
        spawn(StartAutoPlant)
    elseif state then
        print("❌ Cannot start Auto Plant - Event not found")
    end
end)

CreateTouchToggle("Auto Water Plants", 105, function(state)
    _G.AutoWater = state
    print("Auto Water: " .. tostring(state))
    if state and WaterEvent then
        spawn(StartAutoWater)
    elseif state then
        print("❌ Cannot start Auto Water - Event not found")
    end
end)

CreateTouchToggle("Auto Harvest", 155, function(state)
    _G.AutoHarvest = state
    print("Auto Harvest: " .. tostring(state))
    if state and HarvestEvent then
        spawn(StartAutoHarvest)
    elseif state then
        print("❌ Cannot start Auto Harvest - Event not found")
    end
end)

CreateTouchToggle("Auto Sell", 205, function(state)
    _G.AutoSell = state
    print("Auto Sell: " .. tostring(state))
    if state and SellEvent then
        spawn(StartAutoSell)
    elseif state then
        print("❌ Cannot start Auto Sell - Event not found")
    end
end)

CreateSection("EVENT STATUS", 265)

-- Event Status Labels
local eventStatuses = {
    {name = "Plant Event", event = PlantEvent, yPos = 310},
    {name = "Water Event", event = WaterEvent, yPos = 340},
    {name = "Harvest Event", event = HarvestEvent, yPos = 370},
    {name = "Sell Event", event = SellEvent, yPos = 400}
}

for _, status in ipairs(eventStatuses) do
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 25)
    statusLabel.Position = UDim2.new(0, 10, 0, status.yPos)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = status.name .. ": " .. (status.event and "✅ Found" or "❌ Not Found")
    statusLabel.TextColor3 = status.event and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(255, 80, 80)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.ZIndex = 92
    statusLabel.Parent = ScrollFrame
end

-- Manual Control Buttons
CreateSection("MANUAL CONTROL", 440)

local function CreateManualButton(text, yPos, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 35)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.ZIndex = 92
    button.Parent = ScrollFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

CreateManualButton("🔧 Manual Harvest", 485, HarvestPlants)
CreateManualButton("🔧 Manual Plant", 530, PlantSeeds)
CreateManualButton("🔧 Manual Water", 575, WaterPlants)
CreateManualButton("🔧 Manual Sell", 620, SellCrops)

-- TOMBOL MINI CLICK EVENT
MiniButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniButton.Visible = false
end)

-- DRAG FUNCTIONS (sama seperti sebelumnya)
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

-- Notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🌻 Smart Garden Bot Loaded",
    Text = "Auto-detected events! Tap 🌻 button",
    Duration = 5
})

print("✅ Smart Garden Bot successfully loaded!")
print("🔍 Auto-detected " .. 
      (PlantEvent and "Plant " or "") ..
      (WaterEvent and "Water " or "") ..
      (HarvestEvent and "Harvest " or "") ..
      (SellEvent and "Sell" or ""))
print("👆 Use manual buttons to test functions")

-- Anti AFK
spawn(function()
    while true do
        wait(60)
        if _G.AutoPlant or _G.AutoWater or _G.AutoHarvest or _G.AutoSell then
            local character = localPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid:Move(Vector3.new(0, 0, 0))
            end
        end
    end
end)
