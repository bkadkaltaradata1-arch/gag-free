-- Script Auto Farm untuk Game "Grow a Garden" dengan GUI Minimizable
-- Compatible dengan Delta Executor dan Mobile Devices
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
getgenv().HarvestKey = "E"
getgenv().RandomPosition = true
getgenv().HarvestRange = 20

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
                Content = "Auto Harvest enabled (Press " .. getgenv().HarvestKey .. ")",
                Duration = 5,
                Image = 4483362458,
            })
            setupHarvestKey()
        else
            if getgenv().HarvestConnection then
                getgenv().HarvestConnection:Disconnect()
            end
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

-- Harvest Settings
local HarvestSection = FarmTab:CreateSection("Harvest Settings")

local HarvestKeybind = FarmTab:CreateKeybind({
    Name = "Harvest Keybind",
    CurrentKeybind = "E",
    HoldToInteract = false,
    Flag = "HarvestKeybind",
    Callback = function(Keybind)
        getgenv().HarvestKey = Keybind
        if getgenv().AutoHarvest and getgenv().HarvestConnection then
            getgenv().HarvestConnection:Disconnect()
            setupHarvestKey()
        end
        Rayfield:Notify({
            Title = "Harvest Key",
            Content = "Harvest key set to: " .. Keybind,
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

local RandomToggle = FarmTab:CreateToggle({
    Name = "Random Harvest Position",
    CurrentValue = true,
    Flag = "RandomToggle",
    Callback = function(Value)
        getgenv().RandomPosition = Value
        Rayfield:Notify({
            Title = "Random Position",
            Content = Value and "Random position enabled" or "Random position disabled",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

local RangeSlider = FarmTab:CreateSlider({
    Name = "Harvest Range",
    Range = {5, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 20,
    Flag = "RangeSlider",
    Callback = function(Value)
        getgenv().HarvestRange = Value
        Rayfield:Notify({
            Title = "Harvest Range",
            Content = "Harvest range set to: " .. Value,
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

-- Player Section
local PlayerSection = PlayerTab:CreateSection("Player Modifications")

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

-- Auto Farm Functions
function autoPlant()
    spawn(function()
        while getgenv().AutoPlant do
            local plots = findEmptyPlots()
            if #plots > 0 then
                for _, plot in ipairs(plots) do
                    if not getgenv().AutoPlant then break end
                    teleportTo(plot.Position)
                    plantSeed(getgenv().SelectedSeed)
                    wait(0.5)
                end
                Rayfield:Notify({
                    Title = "Auto Plant",
                    Content = "Planted in " .. #plots .. " plots",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            wait(2)
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
                    wait(0.5)
                end
                Rayfield:Notify({
                    Title = "Auto Water",
                    Content = "Watered " .. #plants .. " plants",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            wait(2)
        end
    end)
end

function setupHarvestKey()
    if getgenv().HarvestConnection then
        getgenv().HarvestConnection:Disconnect()
    end
    
    getgenv().HarvestConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode[getgenv().HarvestKey] or input.UserInputType == Enum.UserInputType.Keyboard and string.upper(string.char(input.KeyCode.Value)) == getgenv().HarvestKey then
            if getgenv().AutoHarvest then
                harvestPlantsInRange()
            end
        end
    end)
end

function harvestPlantsInRange()
    spawn(function()
        local plants = findMaturePlants()
        local harvested = 0
        
        if #plants > 0 then
            for _, plant in ipairs(plants) do
                if not getgenv().AutoHarvest then break end
                
                -- Check if plant is in range
                local character = game.Players.LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - plant.Position).Magnitude
                    
                    if distance <= getgenv().HarvestRange then
                        -- Move to random position near plant if enabled
                        if getgenv().RandomPosition then
                            local randomOffset = Vector3.new(
                                math.random(-3, 3),
                                0,
                                math.random(-3, 3)
                            )
                            teleportTo(CFrame.new(plant.Position + randomOffset))
                            wait(0.2)
                        else
                            teleportTo(CFrame.new(plant.Position))
                            wait(0.2)
                        end
                        
                        -- Harvest the plant
                        harvestPlant()
                        harvested = harvested + 1
                        wait(0.3)
                    end
                end
            end
            
            if harvested > 0 then
                Rayfield:Notify({
                    Title = "Auto Harvest",
                    Content = "Harvested " .. harvested .. " plants",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
        end
    end)
end

-- Game Interaction Functions (Updated for mobile compatibility)
function findEmptyPlots()
    -- Implementasi untuk mencari plot kosong
    local emptyPlots = {}
    local plots = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Garden") or workspace:FindFirstChild("Farm")
    
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            if plot:IsA("Part") and plot.Name:find("Plot") and not plot:FindFirstChild("Plant") then
                table.insert(emptyPlots, plot)
            end
        end
    end
    
    return emptyPlots
end

function findDryPlants()
    -- Implementasi untuk mencari tanaman yang perlu disiram
    local dryPlants = {}
    local plants = workspace:FindFirstChild("Plants") or workspace:FindFirstChild("Crops")
    
    if plants then
        for _, plant in ipairs(plants:GetChildren()) do
            if plant:IsA("Model") and (plant:GetAttribute("NeedsWater") or plant:FindFirstChild("Dry")) then
                table.insert(dryPlants, plant)
            end
        end
    end
    
    return dryPlants
end

function findMaturePlants()
    -- Implementasi untuk mencari tanaman yang siap panen
    local maturePlants = {}
    local plants = workspace:FindFirstChild("Plants") or workspace:FindFirstChild("Crops")
    
    if plants then
        for _, plant in ipairs(plants:GetChildren()) do
            if plant:IsA("Model") and (plant:GetAttribute("IsMature") or plant:FindFirstChild("Ready") or plant:FindFirstChild("Ripe")) then
                -- Get the position of the plant
                local primaryPart = plant.PrimaryPart or plant:FindFirstChild("Head") or plant:FindFirstChild("Main")
                if primaryPart then
                    local plantData = {
                        Instance = plant,
                        Position = primaryPart.Position
                    }
                    table.insert(maturePlants, plantData)
                end
            end
        end
    end
    
    return maturePlants
end

function plantSeed(seedType)
    -- Implementasi untuk menanam biji (mobile compatible)
    local tool = findTool(seedType)
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        -- Mobile compatible activation
        if tool:FindFirstChild("Activate") then
            tool.Activate:Invoke()
        else
            -- Simulate touch event for mobile
            tool:Activate()
        end
    end
end

function waterPlant()
    -- Implementasi untuk menyiram tanaman (mobile compatible)
    local tool = findTool("Watering Can")
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        -- Mobile compatible activation
        if tool:FindFirstChild("Activate") then
            tool.Activate:Invoke()
        else
            -- Simulate touch event for mobile
            tool:Activate()
        end
    end
end

function harvestPlant()
    -- Implementasi untuk memanen tanaman (mobile compatible)
    local tool = findTool("Harvest Tool") or findTool("Sickle") or findTool("Axe")
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        -- Mobile compatible activation
        if tool:FindFirstChild("Activate") then
            tool.Activate:Invoke()
        else
            -- Simulate touch event for mobile
            tool:Activate()
        end
    else
        -- Fallback: try to use touch interaction if no tool found
        local character = game.Players.LocalPlayer.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                -- Try to find the plant to harvest
                local plants = workspace:FindFirstChild("Plants") or workspace:FindFirstChild("Crops")
                if plants then
                    for _, plant in ipairs(plants:GetChildren()) do
                        if plant:IsA("Model") and (plant:GetAttribute("IsMature") or plant:FindFirstChild("Ready")) then
                            if (humanoidRootPart.Position - plant:GetModelCFrame().Position).Magnitude < 10 then
                                -- Try to fire the plant's interaction event
                                local interaction = plant:FindFirstChild("Interaction") or plant:FindFirstChild("ClickDetector")
                                if interaction then
                                    if interaction:IsA("ClickDetector") then
                                        fireclickdetector(interaction)
                                    elseif interaction:IsA("RemoteEvent") then
                                        interaction:FireServer("Harvest")
                                    elseif interaction:IsA("RemoteFunction") then
                                        interaction:InvokeServer("Harvest")
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end
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
    return nil
end

function teleportTo(position)
    -- Teleport player ke posisi tertentu (menerima Vector3 atau CFrame)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if typeof(position) == "Vector3" then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
        else
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = position
        end
    end
end

function setWalkSpeed(speed)
    -- Mengatur walk speed player
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
    end
end

function setJumpPower(power)
    -- Mengatur jump power player
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = power
    end
end

-- Initialize
setWalkSpeed(getgenv().WalkSpeed)
setJumpPower(getgenv().JumpPower)

Rayfield:Notify({
    Title = "Script Loaded",
    Content = "Grow a Garden Auto Farm successfully loaded! Press " .. getgenv().HarvestKey .. " to harvest.",
    Duration = 6,
    Image = 4483362458,
})

-- Close GUI with RightShift (default)
-- You can minimize/maximize the GUI with the keybind
