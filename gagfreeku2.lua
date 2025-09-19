-- Script Auto Farm untuk Game "Grow a Garden" dengan GUI Minimizable
-- Compatible dengan Delta Executor
-- Gunakan dengan tanggung jawab, hanya untuk tujuan edukasi

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create GUI Window
local Window = Rayfield:CreateWindow({
    Name = "🌻 Grow a Garden Auto Farm",
    LoadingTitle = "Grow a Garden Auto Farm",
    LoadingSubtitle = "by Script Provider",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GrowAGarden",
        FileName = "AutoFarmConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
})

-- Create Tabs
local FarmTab = Window:CreateTab("Farm", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- Variables
getgenv().AutoPlant = false
getgenv().AutoWater = false
getgenv().AutoHarvest = false
getgenv().SelectedSeed = "Sunflower"
getgenv().WalkSpeed = 16
getgenv().JumpPower = 50

-- Player position display variables
local playerPositionText = PlayerTab:CreateSection("Player Position")
local playerPositionLabel = PlayerTab:CreateParagraph({Title = "Current Position:", Content = "Loading..."})

local positionUpdateConnection

-- Farm Section
local FarmSection = FarmTab:CreateSection("Auto Farm Options")

local PlantToggle = FarmTab:CreateToggle({
    Name = "Auto Plant Seeds",
    CurrentValue = false,
    Flag = "AutoPlantToggle",
    Callback = function(Value)
        getgenv().AutoPlant = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Plant",
                Content = "Auto Plant enabled",
                Duration = 3,
                Image = 4483362458,
            })
            autoPlant()
        else
            Rayfield:Notify({
                Title = "Auto Plant",
                Content = "Auto Plant disabled",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

local WaterToggle = FarmTab:CreateToggle({
    Name = "Auto Water Plants",
    CurrentValue = false,
    Flag = "AutoWaterToggle",
    Callback = function(Value)
        getgenv().AutoWater = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Water",
                Content = "Auto Water enabled",
                Duration = 3,
                Image = 4483362458,
            })
            autoWater()
        else
            Rayfield:Notify({
                Title = "Auto Water",
                Content = "Auto Water disabled",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

local HarvestToggle = FarmTab:CreateToggle({
    Name = "Auto Harvest Plants",
    CurrentValue = false,
    Flag = "AutoHarvestToggle",
    Callback = function(Value)
        getgenv().AutoHarvest = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Harvest",
                Content = "Auto Harvest enabled",
                Duration = 3,
                Image = 4483362458,
            })
            autoHarvest()
        else
            Rayfield:Notify({
                Title = "Auto Harvest",
                Content = "Auto Harvest disabled",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

local SeedDropdown = FarmTab:CreateDropdown({
    Name = "Select Seed Type",
    Options = {"Sunflower", "Tomato", "Carrot", "Potato", "Rose"},
    CurrentOption = "Sunflower",
    Flag = "SeedDropdown",
    Callback = function(Option)
        getgenv().SelectedSeed = Option
        Rayfield:Notify({
            Title = "Seed Selected",
            Content = "Selected seed: " .. Option,
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-- Teleport Section
local TeleportSection = TeleportTab:CreateSection("Teleport Locations")

TeleportTab:CreateButton({
    Name = "Teleport to Planting Area",
    Callback = function()
        teleportTo(CFrame.new(0, 5, 0))
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Teleported to Planting Area",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

TeleportTab:CreateButton({
    Name = "Teleport to Water Source",
    Callback = function()
        teleportTo(CFrame.new(20, 5, 15))
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Teleported to Water Source",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

TeleportTab:CreateButton({
    Name = "Teleport to Selling Area",
    Callback = function()
        teleportTo(CFrame.new(-15, 5, -10))
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Teleported to Selling Area",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-- Player Section dengan tampilan posisi
local PlayerSection = PlayerTab:CreateSection("Player Modifications")

-- Mulai update posisi pemain
startPlayerPositionUpdates()

local WalkSpeedSlider = PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        getgenv().WalkSpeed = Value
        setWalkSpeed(Value)
        Rayfield:Notify({
            Title = "Walk Speed",
            Content = "Walk speed set to: " .. Value,
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

local JumpPowerSlider = PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 100},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        getgenv().JumpPower = Value
        setJumpPower(Value)
        Rayfield:Notify({
            Title = "Jump Power",
            Content = "Jump power set to: " .. Value,
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-- Settings Section
local SettingsSection = SettingsTab:CreateSection("Script Settings")

SettingsTab:CreateButton({
    Name = "Save Settings",
    Callback = function()
        Rayfield:Notify({
            Title = "Settings Saved",
            Content = "Your settings have been saved",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

SettingsTab:CreateButton({
    Name = "Reload Script",
    Callback = function()
        Rayfield:Notify({
            Title = "Reloading",
            Content = "Script will reload...",
            Duration = 3,
            Image = 4483362458,
        })
        wait(3)
        -- Reload script logic would go here
    end,
})

SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        -- Hentikan update posisi sebelum menghancurkan GUI
        if positionUpdateConnection then
            positionUpdateConnection:Disconnect()
        end
        Rayfield:Destroy()
    end,
})

SettingsTab:CreateKeybind({
    Name = "Toggle GUI Keybind",
    CurrentKeybind = "RightShift",
    HoldToInteract = false,
    Flag = "GUIKeybind",
    Callback = function(Keybind)
        -- This callback will be triggered when the keybind is pressed
        Rayfield:Toggle()
    end,
})

-- Fungsi untuk update posisi pemain
function startPlayerPositionUpdates()
    if positionUpdateConnection then
        positionUpdateConnection:Disconnect()
    end
    
    positionUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local player = game.Players.LocalPlayer
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local position = character.HumanoidRootPart.Position
            local x, y, z = math.floor(position.X), math.floor(position.Y), math.floor(position.Z)
            playerPositionLabel:Set({Title = "Current Position:", Content = string.format("X: %d, Y: %d, Z: %d", x, y, z)})
        else
            playerPositionLabel:Set({Title = "Current Position:", Content = "Character not found"})
        end
    end)
end

-- Auto Farm Functions
function autoPlant()
    spawn(function()
        while getgenv().AutoPlant do
            local plots = findEmptyPlots()
            if #plots > 0 then
                for _, plot in ipairs(plots) do
                    if not getgenv().AutoPlant then break end
                    teleportTo(plot.CFrame + Vector3.new(0, 3, 0))
                    plantSeed(getgenv().SelectedSeed)
                    wait(0.5)
                end
                Rayfield:Notify({
                    Title = "Auto Plant",
                    Content = "Planted in " .. #plots .. " plots",
                    Duration = 3,
                    Image = 4483362458,
                })
            else
                Rayfield:Notify({
                    Title = "Auto Plant",
                    Content = "No empty plots found",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            wait(5)
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
                    if plant.PrimaryPart then
                        teleportTo(plant.PrimaryPart.CFrame + Vector3.new(0, 3, 0))
                        waterPlant()
                        wait(0.5)
                    end
                end
                Rayfield:Notify({
                    Title = "Auto Water",
                    Content = "Watered " .. #plants .. " plants",
                    Duration = 3,
                    Image = 4483362458,
                })
            else
                Rayfield:Notify({
                    Title = "Auto Water",
                    Content = "No dry plants found",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            wait(5)
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
                    if plant.PrimaryPart then
                        teleportTo(plant.PrimaryPart.CFrame + Vector3.new(0, 3, 0))
                        harvestPlant(plant)
                        wait(0.5)
                    end
                end
                Rayfield:Notify({
                    Title = "Auto Harvest",
                    Content = "Harvested " .. #plants .. " plants",
                    Duration = 3,
                    Image = 4483362458,
                })
            else
                Rayfield:Notify({
                    Title = "Auto Harvest",
                    Content = "No mature plants found",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            wait(5)
        end
    end)
end

-- Game Interaction Functions
function findEmptyPlots()
    local emptyPlots = {}
    
    -- Cari plot kosong di workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and (obj.Name:lower():find("plot") or obj.Name:lower():find("soil") or obj.Name:lower():find("farm")) then
            if not hasPlant(obj) then
                table.insert(emptyPlots, obj)
            end
        end
    end
    
    return emptyPlots
end

function hasPlant(plot)
    -- Cek area sekitar plot untuk tanaman
    local region = Region3.new(plot.Position - Vector3.new(5, 5, 5), plot.Position + Vector3.new(5, 5, 5))
    local parts = workspace:FindPartsInRegion3(region, nil, 100)
    
    for _, part in ipairs(parts) do
        if part:IsA("Part") and (part.Name:lower():find("plant") or part.Name:lower():find("crop") or part.Name:lower():find("tree")) then
            return true
        end
    end
    return false
end

function findDryPlants()
    local dryPlants = {}
    
    -- Cari tanaman yang perlu disiram
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("plant") or obj.Name:lower():find("crop")) then
            if obj.PrimaryPart and obj.PrimaryPart.Color.R > 0.6 then -- Tanaman kering cenderung lebih merah/coklat
                table.insert(dryPlants, obj)
            end
        end
    end
    
    return dryPlants
end

function findMaturePlants()
    local maturePlants = {}
    
    -- Cari tanaman yang sudah matang
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("plant") or obj.Name:lower():find("crop")) then
            if obj.PrimaryPart and obj.PrimaryPart.Size.Y > 2 then -- Tanaman matang biasanya lebih tinggi
                table.insert(maturePlants, obj)
            end
        end
    end
    
    return maturePlants
end

function plantSeed(seedType)
    local tool = findTool(seedType)
    if tool and game.Players.LocalPlayer.Character then
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:EquipTool(tool)
            wait(0.2)
            tool:Activate()
            wait(0.5)
        end
    end
end

function waterPlant()
    local tool = findTool("watering") or findTool("water") or findTool("can")
    if tool and game.Players.LocalPlayer.Character then
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:EquipTool(tool)
            wait(0.2)
            tool:Activate()
            wait(0.5)
        end
    end
end

function harvestPlant(plant)
    local tool = findTool("harvest") or findTool("sickle") or findTool("axe") or findTool("knife")
    
    if not tool then
        -- Coba gunakan tool pertama yang ditemukan
        local backpack = game.Players.LocalPlayer.Backpack
        if backpack and #backpack:GetChildren() > 0 then
            tool = backpack:GetChildren()[1]
        end
    end
    
    if tool and game.Players.LocalPlayer.Character then
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:EquipTool(tool)
            wait(0.2)
            tool:Activate()
            wait(0.5)
        end
    end
end

function findTool(toolName)
    local lowerToolName = toolName:lower()
    
    -- Cari di backpack
    local backpack = game.Players.LocalPlayer.Backpack
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find(lowerToolName) then
                return item
            end
        end
    end
    
    -- Cari di karakter
    local character = game.Players.LocalPlayer.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find(lowerToolName) then
                return item
            end
        end
    end
    
    return nil
end

function teleportTo(cframe)
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = cframe
    end
end

function setWalkSpeed(speed)
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = speed
    end
end

function setJumpPower(power)
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.JumpPower = power
    end
end

-- Initialize
setWalkSpeed(getgenv().WalkSpeed)
setJumpPower(getgenv().JumpPower)

Rayfield:Notify({
    Title = "Script Loaded",
    Content = "Grow a Garden Auto Farm successfully loaded!",
    Duration = 6,
    Image = 4483362458,
})
