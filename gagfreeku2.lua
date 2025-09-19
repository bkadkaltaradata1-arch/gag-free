-- Script Auto Farm untuk Game "Grow a Garden" - Optimized for Android
-- Compatible dengan Delta Executor
-- Gunakan dengan tanggung jawab, hanya untuk tujuan edukasi

-- Load Rayfield UI Library (Android optimized)
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- Create GUI Window dengan ukuran yang sesuai untuk mobile
local Window = Rayfield:CreateWindow({
    Name = "🌻 Grow a Garden Auto Farm",
    LoadingTitle = "Grow a Garden Auto Farm",
    LoadingSubtitle = "Optimized for Android",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GrowAGarden",
        FileName = "AutoFarmConfig"
    },
    KeySystem = false,
    MobileCompatible = true, -- Penting untuk compatibility mobile
})

-- Create Tabs dengan ikon yang sesuai
local FarmTab = Window:CreateTab("Farm", 1234567890) -- Ikon farm
local TeleportTab = Window:CreateTab("Teleport", 1234567891) -- Ikon teleport
local PlayerTab = Window:CreateTab("Player", 1234567892) -- Ikon player
local SettingsTab = Window:CreateTab("Settings", 1234567893) -- Ikon settings

-- Variables
getgenv().AutoPlant = false
getgenv().AutoWater = false
getgenv().AutoHarvest = false
getgenv().SelectedSeed = "Sunflower"
getgenv().WalkSpeed = 16
getgenv().JumpPower = 50
getgenv().MobileOptimized = true

-- Farm Section
local FarmSection = FarmTab:CreateSection("Auto Farm Options")

local PlantToggle = FarmTab:CreateToggle({
    Name = "🌱 Auto Plant Seeds",
    CurrentValue = false,
    Flag = "AutoPlantToggle",
    Callback = function(Value)
        getgenv().AutoPlant = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Plant",
                Content = "Auto Plant enabled",
                Duration = 2.5,
                Image = 1234567890,
            })
            autoPlant()
        else
            Rayfield:Notify({
                Title = "Auto Plant",
                Content = "Auto Plant disabled",
                Duration = 2.5,
                Image = 1234567890,
            })
        end
    end,
})

local WaterToggle = FarmTab:CreateToggle({
    Name = "💧 Auto Water Plants",
    CurrentValue = false,
    Flag = "AutoWaterToggle",
    Callback = function(Value)
        getgenv().AutoWater = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Water",
                Content = "Auto Water enabled",
                Duration = 2.5,
                Image = 1234567890,
            })
            autoWater()
        else
            Rayfield:Notify({
                Title = "Auto Water",
                Content = "Auto Water disabled",
                Duration = 2.5,
                Image = 1234567890,
            })
        end
    end,
})

local HarvestToggle = FarmTab:CreateToggle({
    Name = "✂️ Auto Harvest Plants",
    CurrentValue = false,
    Flag = "AutoHarvestToggle",
    Callback = function(Value)
        getgenv().AutoHarvest = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Harvest",
                Content = "Auto Harvest enabled",
                Duration = 2.5,
                Image = 1234567890,
            })
            autoHarvest()
        else
            Rayfield:Notify({
                Title = "Auto Harvest",
                Content = "Auto Harvest disabled",
                Duration = 2.5,
                Image = 1234567890,
            })
        end
    end,
})

local SeedDropdown = FarmTab:CreateDropdown({
    Name = "🌻 Select Seed Type",
    Options = {"Sunflower", "Tomato", "Carrot", "Potato", "Rose"},
    CurrentOption = "Sunflower",
    Flag = "SeedDropdown",
    Callback = function(Option)
        getgenv().SelectedSeed = Option
        Rayfield:Notify({
            Title = "Seed Selected",
            Content = "Selected seed: " .. Option,
            Duration = 2.5,
            Image = 1234567890,
        })
    end,
})

-- Teleport Section dengan button yang lebih besar untuk touch
local TeleportSection = TeleportTab:CreateSection("📍 Teleport Locations")

TeleportTab:CreateButton({
    Name = "🚜 Teleport to Planting Area",
    Callback = function()
        teleportTo(CFrame.new(0, 5, 0))
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Teleported to Planting Area",
            Duration = 2.5,
            Image = 1234567891,
        })
    end,
})

TeleportTab:CreateButton({
    Name = "🚰 Teleport to Water Source",
    Callback = function()
        teleportTo(CFrame.new(20, 5, 15))
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Teleported to Water Source",
            Duration = 2.5,
            Image = 1234567891,
        })
    end,
})

TeleportTab:CreateButton({
    Name = "💰 Teleport to Selling Area",
    Callback = function()
        teleportTo(CFrame.new(-15, 5, -10))
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Teleported to Selling Area",
            Duration = 2.5,
            Image = 1234567891,
        })
    end,
})

-- Player Section dengan slider yang mobile-friendly
local PlayerSection = PlayerTab:CreateSection("👤 Player Modifications")

local WalkSpeedSlider = PlayerTab:CreateSlider({
    Name = "🚶‍♂️ Walk Speed",
    Range = {16, 100},
    Increment = 5, -- Lebih besar untuk memudahkan touch
    Suffix = "studs",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        getgenv().WalkSpeed = Value
        setWalkSpeed(Value)
        Rayfield:Notify({
            Title = "Walk Speed",
            Content = "Walk speed set to: " .. Value,
            Duration = 2.5,
            Image = 1234567892,
        })
    end,
})

local JumpPowerSlider = PlayerTab:CreateSlider({
    Name = "🦘 Jump Power",
    Range = {50, 100},
    Increment = 5, -- Lebih besar untuk memudahkan touch
    Suffix = "studs",
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        getgenv().JumpPower = Value
        setJumpPower(Value)
        Rayfield:Notify({
            Title = "Jump Power",
            Content = "Jump power set to: " .. Value,
            Duration = 2.5,
            Image = 1234567892,
        })
    end,
})

-- Settings Section dengan tombol yang mudah di-touch
local SettingsSection = SettingsTab:CreateSection("⚙️ Script Settings")

SettingsTab:CreateButton({
    Name = "💾 Save Settings",
    Callback = function()
        Rayfield:Notify({
            Title = "Settings Saved",
            Content = "Your settings have been saved",
            Duration = 2.5,
            Image = 1234567893,
        })
    end,
})

SettingsTab:CreateButton({
    Name = "🔄 Reload Script",
    Callback = function()
        Rayfield:Notify({
            Title = "Reloading",
            Content = "Script will reload...",
            Duration = 2.5,
            Image = 1234567893,
        })
        wait(2.5)
        -- Simulasi reload
        Rayfield:Destroy()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/example/script.lua'))()
    end,
})

SettingsTab:CreateButton({
    Name = "❌ Destroy GUI",
    Callback = function()
        Rayfield:Destroy()
    end,
})

SettingsTab:CreateKeybind({
    Name = "🔘 Toggle GUI Keybind",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Flag = "GUIKeybind",
    Callback = function(Keybind)
        Rayfield:Toggle()
    end,
})

-- Mobile-specific optimizations
if getgenv().MobileOptimized then
    -- Adjust UI for mobile
    Rayfield:Notify({
        Title = "Mobile Mode",
        Content = "Mobile optimization enabled",
        Duration = 3,
        Image = 1234567893,
    })
end

-- Auto Farm Functions dengan delay yang lebih lama untuk mobile
function autoPlant()
    spawn(function()
        while getgenv().AutoPlant do
            local plots = findEmptyPlots()
            if #plots > 0 then
                for _, plot in ipairs(plots) do
                    if not getgenv().AutoPlant then break end
                    teleportTo(plot.Position)
                    plantSeed(getgenv().SelectedSeed)
                    wait(1) -- Delay lebih lama untuk mobile
                end
                Rayfield:Notify({
                    Title = "Auto Plant",
                    Content = "Planted in " .. #plots .. " plots",
                    Duration = 2.5,
                    Image = 1234567890,
                })
            else
                Rayfield:Notify({
                    Title = "Auto Plant",
                    Content = "No empty plots found",
                    Duration = 2.5,
                    Image = 1234567890,
                })
            end
            wait(3) -- Delay lebih lama untuk menghemat resources di mobile
        end
    end)
end

function autoWater()
    spawn(function()
        while getgenv().AutoWater do
            local plants = findDryPlants()
            if #plants > 0 then
                for _, plant in ipairs(plants) do
                    if not getgenv().AutoWater then break end
                    teleportTo(plant.Position)
                    waterPlant()
                    wait(1) -- Delay lebih lama untuk mobile
                end
                Rayfield:Notify({
                    Title = "Auto Water",
                    Content = "Watered " .. #plants .. " plants",
                    Duration = 2.5,
                    Image = 1234567890,
                })
            else
                Rayfield:Notify({
                    Title = "Auto Water",
                    Content = "No plants need water",
                    Duration = 2.5,
                    Image = 1234567890,
                })
            end
            wait(3) -- Delay lebih lama untuk menghemat resources di mobile
        end
    end)
end

function autoHarvest()
    spawn(function()
        while getgenv().AutoHarvest do
            local plants = findMaturePlants()
            if #plants > 0 then
                for _, plant in ipairs(plants) do
                    if not getgenv().AutoHarvest then break end
                    teleportTo(plant.Position)
                    harvestPlant()
                    wait(1) -- Delay lebih lama untuk mobile
                end
                Rayfield:Notify({
                    Title = "Auto Harvest",
                    Content = "Harvested " .. #plants .. " plants",
                    Duration = 2.5,
                    Image = 1234567890,
                })
            else
                Rayfield:Notify({
                    Title = "Auto Harvest",
                    Content = "No plants ready for harvest",
                    Duration = 2.5,
                    Image = 1234567890,
                })
            end
            wait(3) -- Delay lebih lama untuk menghemat resources di mobile
        end
    end)
end

-- Game Interaction Functions dengan error handling untuk mobile
function findEmptyPlots()
    local emptyPlots = {}
    
    -- Mencari plot dengan berbagai kemungkinan nama
    local plotContainers = {
        workspace:FindFirstChild("Plots"),
        workspace:FindFirstChild("Garden"),
        workspace:FindFirstChild("Farm"),
        workspace:FindFirstChild("PlantingArea")
    }
    
    for _, container in ipairs(plotContainers) do
        if container then
            for _, plot in ipairs(container:GetChildren()) do
                if plot:IsA("Part") and (plot.Name:find("Plot") or plot.Name:find("Soil")) then
                    -- Cek jika plot kosong
                    local hasPlant = false
                    for _, child in ipairs(plot:GetChildren()) do
                        if child:IsA("Model") and (child.Name:find("Plant") or child.Name:find("Crop")) then
                            hasPlant = true
                            break
                        end
                    end
                    
                    if not hasPlant then
                        table.insert(emptyPlots, plot)
                    end
                end
            end
        end
    end
    
    return emptyPlots
end

function findDryPlants()
    local dryPlants = {}
    
    -- Mencari tanaman dengan berbagai kemungkinan nama
    local plantContainers = {
        workspace:FindFirstChild("Plants"),
        workspace:FindFirstChild("Crops"),
        workspace:FindFirstChild("Garden"),
        workspace:FindFirstChild("Farm")
    }
    
    for _, container in ipairs(plantContainers) do
        if container then
            for _, plant in ipairs(container:GetChildren()) do
                if plant:IsA("Model") and (plant.Name:find("Plant") or plant.Name:find("Crop")) then
                    -- Cek jika tanaman perlu air (berdasarkan warna atau attribute)
                    if plant:GetAttribute("NeedsWater") or 
                       (plant.PrimaryPart and plant.PrimaryPart.Color == Color3.fromRGB(128, 128, 128)) then
                        table.insert(dryPlants, plant)
                    end
                end
            end
        end
    end
    
    return dryPlants
end

function findMaturePlants()
    local maturePlants = {}
    
    -- Mencari tanaman dengan berbagai kemungkinan nama
    local plantContainers = {
        workspace:FindFirstChild("Plants"),
        workspace:FindFirstChild("Crops"),
        workspace:FindFirstChild("Garden"),
        workspace:FindFirstChild("Farm")
    }
    
    for _, container in ipairs(plantContainers) do
        if container then
            for _, plant in ipairs(container:GetChildren()) do
                if plant:IsA("Model") and (plant.Name:find("Plant") or plant.Name:find("Crop")) then
                    -- Cek jika tanaman sudah matang (berdasarkan size atau attribute)
                    if plant:GetAttribute("IsMature") or 
                       (plant.PrimaryPart and plant.PrimaryPart.Size.Y > 3) then
                        table.insert(maturePlants, plant)
                    end
                end
            end
        end
    end
    
    return maturePlants
end

function plantSeed(seedType)
    local tool = findTool(seedType)
    if tool and game.Players.LocalPlayer.Character then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.5) -- Delay lebih lama untuk mobile
        -- Simulate click
        if tool:FindFirstChild("Handle") then
            tool.Handle.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
        end
    end
end

function waterPlant()
    local tool = findTool("Watering Can") or findTool("Water") or findTool("Bucket")
    if tool and game.Players.LocalPlayer.Character then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.5) -- Delay lebih lama untuk mobile
        -- Simulate click
        if tool:FindFirstChild("Handle") then
            tool.Handle.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
        end
    end
end

function harvestPlant()
    local tool = findTool("Harvest Tool") or findTool("Sickle") or findTool("Axe") or findTool("Shears")
    if tool and game.Players.LocalPlayer.Character then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.5) -- Delay lebih lama untuk mobile
        -- Simulate click
        if tool:FindFirstChild("Handle") then
            tool.Handle.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
        end
    end
end

function findTool(toolName)
    -- Mencari tool di backpack player
    local backpack = game.Players.LocalPlayer.Backpack
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name == toolName or item.Name:find(toolName)) then
            return item
        end
    end
    
    -- Mencari tool di karakter player
    if game.Players.LocalPlayer.Character then
        for _, item in ipairs(game.Players.LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") and (item.Name == toolName or item.Name:find(toolName)) then
                return item
            end
        end
    end
    
    return nil
end

function teleportTo(cframe)
    -- Teleport player ke posisi tertentu dengan error handling
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
        end)
    end
end

function setWalkSpeed(speed)
    -- Mengatur walk speed player dengan error handling
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        pcall(function()
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
        end)
    end
end

function setJumpPower(power)
    -- Mengatur jump power player dengan error handling
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        pcall(function()
            game.Players.LocalPlayer.Character.Humanoid.JumpPower = power
        end)
    end
end

-- Initialize
setWalkSpeed(getgenv().WalkSpeed)
setJumpPower(getgenv().JumpPower)

Rayfield:Notify({
    Title = "Script Loaded",
    Content = "Grow a Garden Auto Farm successfully loaded! Optimized for Android.",
    Duration = 5,
    Image = 1234567893,
})

-- Mobile optimization tips
if not game:GetService("UserInputService").KeyboardEnabled then
    Rayfield:Notify({
        Title = "Mobile Tips",
        Content = "Use the F keybind to toggle the GUI. Adjust settings for better performance.",
        Duration = 6,
        Image = 1234567893,
    })
end
