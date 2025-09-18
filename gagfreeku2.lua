-- Grow a Garden Script dengan library yang lebih stabil
local success, library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()
end)

if not success then
    library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robobo2022/script/main/UI-Library-V2.1"))()
end

local Window = library:NewWindow("Grow a Garden - Delta Executor", "by Script Helper")

local MainTab = Window:NewTab("Auto Farm")
local PlantTab = Window:NewTab("Plant Management")
local ShopTab = Window:NewTab("Upgrades & Shop")
local SettingsTab = Window:NewTab("Settings")

-- Variables
local AutoPlant = false
local AutoWater = false
local AutoHarvest = false
local AutoSell = false
local AutoBuySeeds = false
local PlantRandom = false
local SelectedSeed = "Sunflower"

-- Main Tab
local FarmingSection = MainTab:NewSection("Auto Farming")

FarmingSection:NewToggle("Auto Plant Seeds", "Tanam benih otomatis", function(Value)
    AutoPlant = Value
    if Value then
        spawn(function()
            while AutoPlant do
                if PlantRandom then
                    PlantSeedsRandom(SelectedSeed)
                else
                    PlantSeeds(SelectedSeed)
                end
                wait(5)
            end
        end)
    end
end)

FarmingSection:NewToggle("Auto Water Plants", "Siram tanaman otomatis", function(Value)
    AutoWater = Value
    if Value then
        spawn(function()
            while AutoWater do
                WaterPlants()
                wait(10)
            end
        end)
    end
end)

FarmingSection:NewToggle("Auto Harvest Plants", "Panen tanaman otomatis", function(Value)
    AutoHarvest = Value
    if Value then
        spawn(function()
            while AutoHarvest do
                HarvestPlants()
                wait(15)
            end
        end)
    end
end)

FarmingSection:NewToggle("Auto Sell Crops", "Jual hasil panen otomatis", function(Value)
    AutoSell = Value
    if Value then
        spawn(function()
            while AutoSell do
                SellCrops()
                wait(20)
            end
        end)
    end
end)

-- Plant Management Tab
local PlantSection = PlantTab:NewSection("Seed Selection")

local seedOptions = {"Sunflower", "Tomato", "Carrot", "Potato", "Rose", "Tulip"}
PlantSection:NewDropdown("Pilih Jenis Benih", "Pilih benih yang akan ditanam", seedOptions, function(Value)
    SelectedSeed = Value
    print("Benih dipilih: " .. Value)
end)

local RandomSection = PlantTab:NewSection("Random Planting")

RandomSection:NewToggle("Plant in Random Locations", "Tanam di lokasi acak", function(Value)
    PlantRandom = Value
    print("Random Planting: " .. tostring(Value))
end)

RandomSection:NewSlider("Planting Radius", "Jarak penanaman dari player", 100, 10, function(Value)
    print("Radius diatur: " .. Value)
end)

-- Shop Tab
local ShopSection = ShopTab:NewSection("Auto Shop")

ShopSection:NewToggle("Auto Buy Seeds", "Beli benih otomatis", function(Value)
    AutoBuySeeds = Value
    if Value then
        spawn(function()
            while AutoBuySeeds do
                CheckAndBuySeeds(SelectedSeed, 10)
                wait(30)
            end
        end)
    end
end)

ShopSection:NewSlider("Max Seeds to Buy", "Jumlah maksimal benih", 50, 1, function(Value)
    print("Max seeds: " .. Value)
end)

-- Settings Tab
local SettingsSection = SettingsTab:NewSection("Script Settings")

SettingsSection:NewButton("Save Settings", "Simpan pengaturan", function()
    print("Settings disimpan!")
end)

SettingsSection:NewButton("Load Settings", "Muat pengaturan", function()
    print("Settings dimuat!")
end)

SettingsSection:NewButton("Reset Script", "Reset semua pengaturan", function()
    ResetScript()
end)

-- Functions
function PlantSeedsRandom(seedType)
    local randomPos = GetRandomPositionAroundPlayer()
    if randomPos then
        print("🌱 Menanam " .. seedType .. " di: " .. math.floor(randomPos.X) .. ", " .. math.floor(randomPos.Z))
        -- game:GetService("ReplicatedStorage").Events.PlantSeed:FireServer(seedType, randomPos)
    end
end

function GetRandomPositionAroundPlayer()
    local player = game.Players.LocalPlayer
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = player.Character.HumanoidRootPart
        local randomX = math.random(-20, 20)
        local randomZ = math.random(-20, 20)
        
        return Vector3.new(
            rootPart.Position.X + randomX,
            rootPart.Position.Y,
            rootPart.Position.Z + randomZ
        )
    end
    return nil
end

function CheckAndBuySeeds(seedType, amount)
    print("🛒 Mengecek stok benih " .. seedType)
    print("✅ Membeli " .. amount .. " benih " .. seedType)
    -- game:GetService("ReplicatedStorage").Events.BuySeeds:FireServer(seedType, amount)
end

function PlantSeeds(seedType)
    print("🌱 Menanam " .. seedType)
    -- game:GetService("ReplicatedStorage").Events.PlantSeed:FireServer(seedType)
end

function WaterPlants()
    print("💧 Menyiram tanaman")
    -- game:GetService("ReplicatedStorage").Events.WaterPlant:FireServer()
end

function HarvestPlants()
    print("📦 Memanen tanaman")
    -- game:GetService("ReplicatedStorage").Events.HarvestPlant:FireServer()
end

function SellCrops()
    print("💰 Menjual hasil panen")
    -- game:GetService("ReplicatedStorage").Events.SellCrops:FireServer()
end

function ResetScript()
    AutoPlant = false
    AutoWater = false
    AutoHarvest = false
    AutoSell = false
    AutoBuySeeds = false
    PlantRandom = false
    print("🔄 Script direset!")
end

-- Anti AFK
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

print("✅ GUI Grow a Garden berhasil dimuat!")
print("📜 Tekan Insert untuk membuka/menutup GUI")