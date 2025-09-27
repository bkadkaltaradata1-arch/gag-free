-- Grow a Garden Auto Farm Script
-- Created by Assistant

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- GUI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()

local MainWindow = Library:NewWindow("Grow a Garden Auto Farm")
local MainTab = MainWindow:NewSection("Main Features")
local AutoTab = MainWindow:NewSection("Auto Farm Settings")
local TeleportTab = MainWindow:NewSection("Teleport Locations")
local MiscTab = MainWindow:NewSection("Miscellaneous")

-- Variables
local AutoFarmEnabled = false
local AutoPlantEnabled = false
local AutoHarvestEnabled = false
local AutoBuyEnabled = false
local SelectedSeed = "Sunflower"
local FarmSpeed = 1

-- Get important game objects
function getGardenPlot()
    local plot = workspace:FindFirstChild("GardenPlot") or workspace:FindFirstChild("Plot") or workspace:FindFirstChild("Garden")
    return plot
end

function getSeedShop()
    local shop = workspace:FindFirstChild("SeedShop") or workspace:FindFirstChild("Shop") or workspace:FindFirstChild("SeedStore")
    return shop
end

function getSeedsFolder()
    local seeds = workspace:FindFirstChild("Seeds") or workspace:FindFirstChild("Plants") or workspace:FindFirstChild("Crops")
    return seeds
end

-- Auto Farm Functions
function buySeed(seedName)
    local shop = getSeedShop()
    if shop then
        local seed = shop:FindFirstChild(seedName)
        if seed then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:MoveTo(seed.Position)
                wait(1)
                -- Simulate click to buy
                fireclickdetector(seed:FindFirstChildOfClass("ClickDetector"), 0)
            end
        end
    end
end

function plantSeed()
    local plot = getGardenPlot()
    if plot then
        local emptySpots = plot:GetChildren()
        for _, spot in pairs(emptySpots) do
            if spot:FindFirstChild("Soil") and not spot:FindFirstChild("Plant") then
                LocalPlayer.Character:MoveTo(spot.Position)
                wait(0.5)
                -- Plant logic here
                break
            end
        end
    end
end

function harvestPlants()
    local seedsFolder = getSeedsFolder()
    if seedsFolder then
        for _, plant in pairs(seedsFolder:GetChildren()) do
            if plant:FindFirstChild("Ready") or plant:FindFirstChild("Grown") then
                LocalPlayer.Character:MoveTo(plant.Position)
                wait(0.5)
                -- Harvest logic
                if plant:FindFirstChildOfClass("ClickDetector") then
                    fireclickdetector(plant:FindFirstChildOfClass("ClickDetector"), 0)
                end
            end
        end
    end
end

-- Main Auto Farm Loop
local FarmConnection
function startAutoFarm()
    if FarmConnection then
        FarmConnection:Disconnect()
    end
    
    FarmConnection = RunService.Heartbeat:Connect(function()
        if AutoHarvestEnabled then
            harvestPlants()
        end
        
        if AutoPlantEnabled then
            plantSeed()
        end
        
        if AutoBuyEnabled then
            buySeed(SelectedSeed)
        end
    end)
end

function stopAutoFarm()
    if FarmConnection then
        FarmConnection:Disconnect()
        FarmConnection = nil
    end
end

-- GUI Elements
MainTab:CreateToggle("Enable Auto Farm", function(value)
    AutoFarmEnabled = value
    if value then
        startAutoFarm()
    else
        stopAutoFarm()
    end
end)

AutoTab:CreateToggle("Auto Harvest", function(value)
    AutoHarvestEnabled = value
end)

AutoTab:CreateToggle("Auto Plant", function(value)
    AutoPlantEnabled = value
end)

AutoTab:CreateToggle("Auto Buy Seeds", function(value)
    AutoBuyEnabled = value
end)

AutoTab:CreateDropdown("Select Seed", {"Sunflower", "Rose", "Tulip", "Daisy", "Lily", "Orchid"}, function(seed)
    SelectedSeed = seed
end)

AutoTab:CreateSlider("Farm Speed", 1, 10, 1, function(value)
    FarmSpeed = value
end)

-- Teleport Locations
TeleportTab:CreateButton("Teleport to Shop", function()
    local shop = getSeedShop()
    if shop then
        LocalPlayer.Character:MoveTo(shop.Position)
    end
end)

TeleportTab:CreateButton("Teleport to Garden", function()
    local plot = getGardenPlot()
    if plot then
        LocalPlayer.Character:MoveTo(plot.Position)
    end
end)

TeleportTab:CreateButton("Teleport to Spawn", function()
    LocalPlayer.Character:MoveTo(Vector3.new(0, 10, 0))
end)

-- Miscellaneous Features
MiscTab:CreateToggle("Anti-AFK", function(value)
    if value then
        local VirtualUser = game:GetService("VirtualUser")
        game:GetService("Players").LocalPlayer.Idled:connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

MiscTab:CreateButton("Collect All Coins", function()
    -- Coin collection logic
    for _, coin in pairs(workspace:GetChildren()) do
        if coin.Name:lower():find("coin") and coin:IsA("Part") then
            LocalPlayer.Character:MoveTo(coin.Position)
            wait(0.2)
        end
    end
end)

MiscTab:CreateButton("Rejoin Game", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightControl then
        AutoFarmEnabled = not AutoFarmEnabled
        if AutoFarmEnabled then
            startAutoFarm()
        else
            stopAutoFarm()
        end
    end
end)

-- Notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Grow a Garden Auto Farm",
    Text = "Script Loaded Successfully! Press RightCtrl to toggle",
    Duration = 5
})

print("Grow a Garden Auto Farm Script Loaded!")
print("Controls:")
print("- Right Control: Toggle Auto Farm")
print("- GUI: Open with mouse")
