-- Script Auto Buy Seed untuk Game "Grow a Garden"
-- Dibuat untuk Delta Executor
-- Versi: 1.0

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()

local Window = library:CreateWindow({
    Title = "Grow a Garden Auto Seed",
    Center = true,
    AutoShow = true
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Settings = Window:AddTab("Settings")
}

local AutoBuySection = Tabs.Main:AddLeftGroupbox("Auto Buy Seed")
AutoBuySection:AddToggle("AutoBuyToggle", {
    Text = "Enable Auto Buy",
    Default = false,
    Tooltip = "Aktifkan untuk membeli seed secara otomatis"
})

AutoBuySection:AddDropdown("SeedType", {
    Values = {"Sunflower", "Tulip", "Rose", "Lavender", "Cactus", "All"},
    Default = 1,
    Multi = false,
    Text = "Seed Type",
    Tooltip = "Pilih jenis seed yang ingin dibeli"
})

AutoBuySection:AddSlider("BuyDelay", {
    Text = "Buy Delay (seconds)",
    Default = 5,
    Min = 1,
    Max = 60,
    Rounding = 0,
    Compact = false
})

AutoBuySection:AddLabel("Status: Tidak aktif"):AddColorPicker("StatusColor", {
    Default = Color3.fromRGB(255, 0, 0)
})

local FarmingSection = Tabs.Main:AddRightGroupbox("Auto Farming")
FarmingSection:AddToggle("AutoFarmToggle", {
    Text = "Enable Auto Farm",
    Default = false,
    Tooltip = "Aktifkan untuk farming coin secara otomatis"
})

FarmingSection:AddSlider("FarmDelay", {
    Text = "Farm Delay (seconds)",
    Default = 10,
    Min = 5,
    Max = 120,
    Rounding = 0,
    Compact = false
})

local SettingsGroup = Tabs.Settings:AddLeftGroupbox("Menu Settings")
SettingsGroup:AddButton("Unload", function() library:Unload() end)
SettingsGroup:AddLabel("Menu Bind"):AddKeyPicker("MenuKeybind", { 
    Default = "RightShift", 
    NoUI = true, 
    Text = "Menu keybind" 
})

library:SetWindowKeybind("MenuKeybind")

ThemeManager:SetLibrary(library)
ThemeManager:SetFolder("GrowAGarden")
ThemeManager:ApplyToTab(Tabs.Settings)

local function findSeedButton(seedName)
    -- Fungsi untuk mencari tombol seed di GUI game
    local gui = game:GetService("Players").LocalPlayer.PlayerGui
    local seedButtons = {}
    
    -- Cari semua frame yang mungkin berisi tombol seed
    for _, screenGui in pairs(gui:GetChildren()) do
        if screenGui:IsA("ScreenGui") then
            local seedShop = findSeedShop(screenGui)
            if seedShop then
                for _, element in pairs(seedShop:GetDescendants()) do
                    if element:IsA("TextButton") and string.find(element.Name:lower(), seedName:lower()) then
                        table.insert(seedButtons, element)
                    end
                end
            end
        end
    end
    
    return seedButtons
end

local function findSeedShop(gui)
    -- Fungsi untuk mencari shop di GUI
    for _, child in pairs(gui:GetDescendants()) do
        if child:IsA("Frame") and (string.find(child.Name:lower(), "shop") or string.find(child.Name:lower(), "store")) then
            return child
        end
    end
    return nil
end

local function canAffordSeed(seedButton)
    -- Fungsi untuk memeriksa apakah pemain mampu membeli seed
    -- Implementasi ini mungkin perlu disesuaikan dengan game
    local priceText = seedButton:FindFirstChild("Price") or seedButton:FindFirstChild("Cost")
    if priceText and priceText:IsA("TextLabel") then
        local price = tonumber(string.match(priceText.Text, "%d+"))
        -- Dapatkan jumlah coin pemain (ini perlu disesuaikan dengan game)
        local playerCoins = --[[ Implementasi untuk mendapatkan coin pemain ]] 0
        
        return playerCoins >= price
    end
    return false
end

local function buySeed(seedName)
    -- Fungsi untuk membeli seed
    local seedButtons = findSeedButton(seedName)
    
    for _, button in pairs(seedButtons) do
        if button.Visible and canAffordSeed(button) then
            -- Simulasi klik pada tombol
            local clickEvent = button:FindFirstChildWhichIsA("RemoteEvent") or button:FindFirstChildWhichIsA("BindableEvent")
            if clickEvent then
                clickEvent:FireServer()
            else
                -- Jika tidak ada event, gunakan fireclickdetector
                local clickDetector = button:FindFirstChildWhichIsA("ClickDetector")
                if clickDetector then
                    fireclickdetector(clickDetector)
                else
                    -- Coba klik langsung
                    pcall(function()
                        button:Activate()
                    end)
                end
            end
            return true
        end
    end
    return false
end

local function autoBuySeed()
    while library.Flags.AutoBuyToggle do
        local seedType = library.Flags.SeedType
        local delay = library.Flags.BuyDelay
        
        if seedType == "All" then
            local seedTypes = {"Sunflower", "Tulip", "Rose", "Lavender", "Cactus"}
            for _, seed in pairs(seedTypes) do
                if library.Flags.AutoBuyToggle then
                    buySeed(seed)
                    wait(1) -- Delay antara pembelian seed berbeda
                else
                    break
                end
            end
        else
            buySeed(seedType)
        end
        
        -- Update status
        local statusLabel = AutoBuySection:FindFirstChild("StatusLabel")
        if statusLabel then
            statusLabel.Text = "Status: Aktif - Terakhir membeli: " .. os.date("%X")
        end
        
        wait(delay)
    end
    
    -- Update status ketika nonaktif
    local statusLabel = AutoBuySection:FindFirstChild("StatusLabel")
    if statusLabel then
        statusLabel.Text = "Status: Tidak aktif"
    end
end

local function autoFarm()
    while library.Flags.AutoFarmToggle do
        -- Implementasi auto farm coin
        -- Ini perlu disesuaikan dengan mekanisme farming di game
        local delay = library.Flags.FarmDelay
        
        -- Contoh: Cari tanaman yang sudah siap panen dan panen
        local harvestablePlants = findHarvestablePlants()
        for _, plant in pairs(harvestablePlants) do
            if not library.Flags.AutoFarmToggle then break end
            harvestPlant(plant)
            wait(1)
        end
        
        wait(delay)
    end
end

-- Hook untuk toggle auto buy
library:OnFlagChanged("AutoBuyToggle", function()
    if library.Flags.AutoBuyToggle then
        coroutine.wrap(autoBuySeed)()
    end
end)

-- Hook untuk toggle auto farm
library:OnFlagChanged("AutoFarmToggle", function()
    if library.Flags.AutoFarmToggle then
        coroutine.wrap(autoFarm)()
    end
end)

-- Fungsi bantu yang perlu diimplementasi sesuai game
function findHarvestablePlants()
    -- Implementasi untuk menemukan tanaman yang siap panen
    return {}
end

function harvestPlant(plant)
    -- Implementasi untuk memanen tanaman
end

-- Inisialisasi status label
AutoBuySection:AddLabel(" "):AddColorPicker("SpacerColor", {Default = Color3.fromRGB(0, 0, 0)})
local statusLabel = AutoBuySection:AddLabel("Status: Tidak aktif")
statusLabel.Name = "StatusLabel"

-- Notifikasi ketika script dimuat
library:Notify("Script Grow a Garden Auto Seed loaded! Press RightShift to open menu.")

-- Jalankan service
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
    library:Unload()
end)
