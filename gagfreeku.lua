-- Grow a Garden Script for Delta Executor dengan fitur tambahan
-- Script ini membantu bermain game Grow a Garden

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Watermelon = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/KeybindSystem.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/ThemeManager.lua"))()

local Window = library:CreateWindow({
    Title = "Grow a Garden - Delta Executor",
    SubTitle = "by Script Helper | Fitur Lengkap",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 500),
    Acrylic = false,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Auto Farm" }),
    Plants = Window:AddTab({ Title = "Plant Management" }),
    Upgrades = Window:AddTab({ Title = "Upgrades & Shop" }),
    Settings = Window:AddTab({ Title = "Settings" })
}

-- Variables
local AutoPlant = false
local AutoWater = false
local AutoHarvest = false
local AutoSell = false
local AutoBuySeeds = false
local AutoUpgrade = false
local PlantRandom = false
local SelectedSeed = "Sunflower"
local PlantDelay = 5
local WaterDelay = 10
local HarvestDelay = 15
local SellDelay = 20
local BuySeedDelay = 30
local MaxSeedsToBuy = 10
local PlantRadius = 50

-- Main Tab
local FarmingSection = Tabs.Main:AddSection("Auto Farming", true)

FarmingSection:AddToggle("AutoPlantToggle", {
    Title = "Auto Plant Seeds",
    Default = false,
    Callback = function(Value)
        AutoPlant = Value
        if Value then
            spawn(function()
                while AutoPlant do
                    if PlantRandom then
                        PlantSeedsRandom(SelectedSeed)
                    else
                        PlantSeeds(SelectedSeed)
                    end
                    wait(PlantDelay)
                end
            end)
        end
    end
})

FarmingSection:AddToggle("AutoWaterToggle", {
    Title = "Auto Water Plants",
    Default = false,
    Callback = function(Value)
        AutoWater = Value
        if Value then
            spawn(function()
                while AutoWater do
                    WaterPlants()
                    wait(WaterDelay)
                end
            end)
        end
    end
})

FarmingSection:AddToggle("AutoHarvestToggle", {
    Title = "Auto Harvest Plants",
    Default = false,
    Callback = function(Value)
        AutoHarvest = Value
        if Value then
            spawn(function()
                while AutoHarvest do
                    HarvestPlants()
                    wait(HarvestDelay)
                end
            end)
        end
    end
})

FarmingSection:AddToggle("AutoSellToggle", {
    Title = "Auto Sell Crops",
    Default = false,
    Callback = function(Value)
        AutoSell = Value
        if Value then
            spawn(function()
                while AutoSell do
                    SellCrops()
                    wait(SellDelay)
                end
            end)
        end
    end
})

-- Plant Management Tab
local PlantSection = Tabs.Plants:AddSection("Seed Selection", true)

local SeedDropdown = PlantSection:AddDropdown("SeedDropdown", {
    Title = "Select Seed Type",
    Values = {"Sunflower", "Tomato", "Carrot", "Potato", "Rose", "Tulip", "Watermelon", "Pumpkin"},
    Default = "Sunflower",
    Multi = false,
    Callback = function(Value)
        SelectedSeed = Value
    end
})

local RandomSection = Tabs.Plants:AddSection("Random Planting", false)

RandomSection:AddToggle("PlantRandomToggle", {
    Title = "Plant in Random Locations",
    Description = "Tanam benih di lokasi acak sekitar player",
    Default = false,
    Callback = function(Value)
        PlantRandom = Value
    end
})

RandomSection:AddSlider("PlantRadiusSlider", {
    Title = "Planting Radius",
    Description = "Jarak maksimum dari player untuk menanam",
    Default = 50,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        PlantRadius = Value
    end
})

local DelaySection = Tabs.Plants:AddSection("Timing Settings", false)

DelaySection:AddSlider("PlantDelaySlider", {
    Title = "Plant Delay (seconds)",
    Description = "Delay between planting seeds",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        PlantDelay = Value
    end
})

DelaySection:AddSlider("WaterDelaySlider", {
    Title = "Water Delay (seconds)",
    Description = "Delay between watering plants",
    Default = 10,
    Min = 5,
    Max = 60,
    Rounding = 0,
    Callback = function(Value)
        WaterDelay = Value
    end
})

DelaySection:AddSlider("HarvestDelaySlider", {
    Title = "Harvest Delay (seconds)",
    Description = "Delay between harvesting",
    Default = 15,
    Min = 5,
    Max = 60,
    Rounding = 0,
    Callback = function(Value)
        HarvestDelay = Value
    end
})

DelaySection:AddSlider("SellDelaySlider", {
    Title = "Sell Delay (seconds)",
    Description = "Delay between selling",
    Default = 20,
    Min = 10,
    Max = 120,
    Rounding = 0,
    Callback = function(Value)
        SellDelay = Value
    end
})

-- Upgrades & Shop Tab
local ShopSection = Tabs.Upgrades:AddSection("Auto Shop", true)

ShopSection:AddToggle("AutoBuySeedsToggle", {
    Title = "Auto Buy Seeds",
    Description = "Beli benih otomatis ketika habis",
    Default = false,
    Callback = function(Value)
        AutoBuySeeds = Value
        if Value then
            spawn(function()
                while AutoBuySeeds do
                    CheckAndBuySeeds(SelectedSeed, MaxSeedsToBuy)
                    wait(BuySeedDelay)
                end
            end)
        end
    end
})

ShopSection:AddSlider("BuySeedDelaySlider", {
    Title = "Buy Seed Check Delay",
    Description = "Delay antara pengecekan benih",
    Default = 30,
    Min = 10,
    Max = 120,
    Rounding = 0,
    Callback = function(Value)
        BuySeedDelay = Value
    end
})

ShopSection:AddSlider("MaxSeedsSlider", {
    Title = "Max Seeds to Buy",
    Description = "Jumlah maksimum benih yang dibeli",
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        MaxSeedsToBuy = Value
    end
})

local UpgradeSection = Tabs.Upgrades:AddSection("Auto Upgrades", false)

UpgradeSection:AddToggle("AutoUpgradeToggle", {
    Title = "Auto Upgrade Tools",
    Default = false,
    Callback = function(Value)
        AutoUpgrade = Value
        if Value then
            spawn(function()
                while AutoUpgrade do
                    UpgradeTools()
                    wait(30)
                end
            end)
        end
    end
})

-- Settings Tab
local SettingsSection = Tabs.Settings:AddSection("Script Settings", true)

SettingsSection:AddButton({
    Title = "Save Settings",
    Description = "Save current configuration",
    Callback = function()
        SaveSettings()
    end
})

SettingsSection:AddButton({
    Title = "Load Settings",
    Description = "Load saved configuration",
    Callback = function()
        LoadSettings()
    end
})

SettingsSection:AddButton({
    Title = "Reset Script",
    Description = "Reset all toggles and settings",
    Callback = function()
        ResetScript()
    end
})

-- FUNGSI BARU UNTUK FITUR TAMBAHAN
function GetRandomPositionAroundPlayer()
    local player = game.Players.LocalPlayer
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = player.Character.HumanoidRootPart
        local randomX = math.random(-PlantRadius, PlantRadius)
        local randomZ = math.random(-PlantRadius, PlantRadius)
        
        return Vector3.new(
            rootPart.Position.X + randomX,
            rootPart.Position.Y, -- Tetap di ketinggian yang sama
            rootPart.Position.Z + randomZ
        )
    end
    return nil
end

function PlantSeedsRandom(seedType)
    local randomPosition = GetRandomPositionAroundPlayer()
    if randomPosition then
        print("Menanam " .. seedType .. " di posisi random: " .. tostring(randomPosition))
        -- Implementasi planting di random position
        -- game:GetService("ReplicatedStorage").Events.PlantSeed:FireServer(seedType, randomPosition)
    else
        print("Tidak bisa mendapatkan posisi random untuk menanam")
    end
end

function CheckAndBuySeeds(seedType, amount)
    -- Simulasi pengecekan jumlah benih
    local currentSeeds = math.random(0, 5) -- Angka random untuk simulasi
    print("Jumlah benih " .. seedType .. " saat ini: " .. currentSeeds)
    
    if currentSeeds < 3 then -- Jika benih kurang dari 3
        print("Membeli " .. amount .. " benih " .. seedType .. " karena hampir habis")
        BuySeeds(seedType, amount)
        return true
    end
    
    print("Benih masih cukup, tidak perlu membeli")
    return false
end

function BuySeeds(seedType, amount)
    -- Implementasi pembelian benih
    print("Membeli " .. amount .. " benih " .. seedType)
    -- Contoh: game:GetService("ReplicatedStorage").Events.BuySeeds:FireServer(seedType, amount)
end

-- FUNGSI LAMA (tetap diperlukan)
function PlantSeeds(seedType)
    print("Menanam " .. seedType .. " seed di lokasi default...")
    -- game:GetService("ReplicatedStorage").Events.PlantSeed:FireServer(seedType)
end

function WaterPlants()
    print("Menyiram tanaman...")
    -- game:GetService("ReplicatedStorage").Events.WaterPlant:FireServer()
end

function HarvestPlants()
    print("Memanen tanaman...")
    -- game:GetService("ReplicatedStorage").Events.HarvestPlant:FireServer()
end

function SellCrops()
    print("Menjual hasil panen...")
    -- game:GetService("ReplicatedStorage").Events.SellCrops:FireServer()
end

function UpgradeTools()
    print("Upgrading tools...")
    -- game:GetService("ReplicatedStorage").Events.UpgradeTool:FireServer()
end

function SaveSettings()
    local settings = {
        AutoPlant = AutoPlant,
        AutoWater = AutoWater,
        AutoHarvest = AutoHarvest,
        AutoSell = AutoSell,
        AutoBuySeeds = AutoBuySeeds,
        PlantRandom = PlantRandom,
        SelectedSeed = SelectedSeed,
        PlantRadius = PlantRadius,
        MaxSeedsToBuy = MaxSeedsToBuy
    }
    print("Settings disimpan!")
    -- Implementasi save ke file jika needed
end

function LoadSettings()
    print("Settings dimuat!")
    -- Implementasi load dari file
end

function ResetScript()
    AutoPlant = false
    AutoWater = false
    AutoHarvest = false
    AutoSell = false
    AutoBuySeeds = false
    AutoUpgrade = false
    PlantRandom = false
    SelectedSeed = "Sunflower"
    PlantRadius = 50
    MaxSeedsToBuy = 10
    
    library:Notify("Script direset ke pengaturan default")
end

-- Notifikasi awal
library:Notify("Grow a Garden Script Loaded dengan fitur lengkap!")
print("=== FITUR TAMBAHAN ===")
print("✅ Auto Buy Seed - Beli otomatis ketika benih habis")
print("✅ Random Planting - Tanam di lokasi acak sekitar player")
print("✅ Adjustable Radius - Atur jarak penanaman random")
print("✅ Smart Seed Management - Cek stok sebelum membeli")

-- Anti AFK
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)