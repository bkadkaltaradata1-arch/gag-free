-- Script Auto Farm untuk Game "Grow a Garden"
-- Compatible dengan Delta Executor
-- Gunakan dengan tanggung jawab, hanya untuk tujuan edukasi

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Watermelon = library:CreateWindow("Auto Farm Grow a Garden")

local Tabs = {
    Main = Watermelon:AddTab("Main"),
    Settings = Watermelon:AddTab("Settings")
}

local AutoFarm = Tabs.Main:AddLeftGroupbox("Auto Farm")
local Teleports = Tabs.Main:AddRightGroupbox("Teleports")
local Settings = Tabs.Settings:AddLeftGroupbox("Settings")

-- Variables
getgenv().AutoPlant = false
getgenv().AutoWater = false
getgenv().AutoHarvest = false
getgenv().SelectedSeed = "Sunflower"
getgenv().WalkSpeed = 16
getgenv().JumpPower = 50

-- Auto Plant Toggle
AutoFarm:AddToggle("AutoPlantToggle", {
    Text = "Auto Plant Seeds",
    Default = false,
    Tooltip = "Automatically plants seeds in empty plots"
})

Toggles.AutoPlantToggle:OnChanged(function(value)
    getgenv().AutoPlant = value
    if value then
        library:Notify("Auto Plant enabled")
        autoPlant()
    else
        library:Notify("Auto Plant disabled")
    end
end)

-- Auto Water Toggle
AutoFarm:AddToggle("AutoWaterToggle", {
    Text = "Auto Water Plants",
    Default = false,
    Tooltip = "Automatically waters plants that need water"
})

Toggles.AutoWaterToggle:OnChanged(function(value)
    getgenv().AutoWater = value
    if value then
        library:Notify("Auto Water enabled")
        autoWater()
    else
        library:Notify("Auto Water disabled")
    end
end)

-- Auto Harvest Toggle
AutoFarm:AddToggle("AutoHarvestToggle", {
    Text = "Auto Harvest Plants",
    Default = false,
    Tooltip = "Automatically harvests mature plants"
})

Toggles.AutoHarvestToggle:OnChanged(function(value)
    getgenv().AutoHarvest = value
    if value then
        library:Notify("Auto Harvest enabled")
        autoHarvest()
    else
        library:Notify("Auto Harvest disabled")
    end
end)

-- Seed Selection Dropdown
local seeds = {"Sunflower", "Tomato", "Carrot", "Potato", "Rose"}
AutoFarm:AddDropdown("SeedDropdown", {
    Text = "Select Seed",
    Default = "Sunflower",
    Values = seeds,
    Tooltip = "Choose which seed to plant"
})

Options.SeedDropdown:OnChanged(function(value)
    getgenv().SelectedSeed = value
    library:Notify("Selected seed: " .. value)
end)

-- WalkSpeed Slider
Settings:AddSlider("WalkSpeedSlider", {
    Text = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Tooltip = "Adjust player walk speed"
})

Options.WalkSpeedSlider:OnChanged(function(value)
    getgenv().WalkSpeed = value
    setWalkSpeed(value)
end)

-- JumpPower Slider
Settings:AddSlider("JumpPowerSlider", {
    Text = "Jump Power",
    Default = 50,
    Min = 50,
    Max = 100,
    Rounding = 0,
    Tooltip = "Adjust player jump power"
})

Options.JumpPowerSlider:OnChanged(function(value)
    getgenv().JumpPower = value
    setJumpPower(value)
end)

-- Teleport Buttons
local locations = {
    ["Planting Area"] = CFrame.new(0, 5, 0),
    ["Water Source"] = CFrame.new(20, 5, 15),
    ["Selling Area"] = CFrame.new(-15, 5, -10)
}

for name, pos in pairs(locations) do
    Teleports:AddButton(name, function()
        teleportTo(pos)
    end)
end

-- Functions
function autoPlant()
    spawn(function()
        while getgenv().AutoPlant do
            -- Cari plot kosong dan tanam biji
            local plots = findEmptyPlots()
            for _, plot in ipairs(plots) do
                if not getgenv().AutoPlant then break end
                teleportTo(plot.Position)
                plantSeed(getgenv().SelectedSeed)
                wait(0.5)
            end
            wait(2)
        end
    end)
end

function autoWater()
    spawn(function()
        while getgenv().AutoWater do
            -- Cari tanaman yang perlu disiram
            local plants = findDryPlants()
            for _, plant in ipairs(plants) do
                if not getgenv().AutoWater then break end
                teleportTo(plant.Position)
                waterPlant()
                wait(0.5)
            end
            wait(2)
        end
    end)
end

function autoHarvest()
    spawn(function()
        while getgenv().AutoHarvest do
            -- Cari tanaman yang siap panen
            local plants = findMaturePlants()
            for _, plant in ipairs(plants) do
                if not getgenv().AutoHarvest then break end
                teleportTo(plant.Position)
                harvestPlant()
                wait(0.5)
            end
            wait(2)
        end
    end)
end

function findEmptyPlots()
    -- Implementasi untuk mencari plot kosong
    -- Ini adalah placeholder, perlu disesuaikan dengan game sebenarnya
    local emptyPlots = {}
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            if plot:FindFirstChild("Soil") and not plot:FindFirstChild("Plant") then
                table.insert(emptyPlots, plot)
            end
        end
    end
    return emptyPlots
end

function findDryPlants()
    -- Implementasi untuk mencari tanaman yang perlu disiram
    local dryPlants = {}
    local plants = workspace:FindFirstChild("Plants")
    if plants then
        for _, plant in ipairs(plants:GetChildren()) do
            if plant:GetAttribute("NeedsWater") then
                table.insert(dryPlants, plant)
            end
        end
    end
    return dryPlants
end

function findMaturePlants()
    -- Implementasi untuk mencari tanaman yang siap panen
    local maturePlants = {}
    local plants = workspace:FindFirstChild("Plants")
    if plants then
        for _, plant in ipairs(plants:GetChildren()) do
            if plant:GetAttribute("IsMature") then
                table.insert(maturePlants, plant)
            end
        end
    end
    return maturePlants
end

function plantSeed(seedType)
    -- Implementasi untuk menanam biji
    local tool = findTool(seedType)
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        mouse1click()
    end
end

function waterPlant()
    -- Implementasi untuk menyiram tanaman
    local tool = findTool("Watering Can")
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        mouse1click()
    end
end

function harvestPlant()
    -- Implementasi untuk memanen tanaman
    local tool = findTool("Harvest Tool")
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        mouse1click()
    end
end

function findTool(toolName)
    -- Mencari tool di backpack player
    local backpack = game.Players.LocalPlayer.Backpack
    for _, item in ipairs(backpack:GetChildren()) do
        if item.Name == toolName or item:FindFirstChild(toolName) then
            return item
        end
    end
    return nil
end

function teleportTo(cframe)
    -- Teleport player ke posisi tertentu
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
end

function setWalkSpeed(speed)
    -- Mengatur walk speed player
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
end

function setJumpPower(power)
    -- Mengatur jump power player
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = power
end

-- Init
library:Notify("Script loaded successfully!")
setWalkSpeed(getgenv().WalkSpeed)
setJumpPower(getgenv().JumpPower)

-- Save settings
library:SetLibraryFlag("UITheme", "Dark")
library:SetLibraryFlag("AutoSaveConfig", true)
library:SetLibraryFlag("ConfigFolder", "GrowAGarden")
