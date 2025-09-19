-- Script Auto Farm untuk Game "Grow a Garden" dengan GUI Minimizable
-- Compatible dengan Delta Executor
-- Dioptimalkan untuk Mobile/Android

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Deteksi platform
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Create GUI Window
local Window = Rayfield:CreateWindow({
    Name = "🌻 Grow a Garden Auto Farm" .. (isMobile and " (Mobile)" or ""),
    LoadingTitle = "Grow a Garden Auto Farm",
    LoadingSubtitle = "by Script Provider - Optimized for Mobile",
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
getgenv().HarvestRange = 15 -- Jarak untuk harvest di mobile

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

-- Mobile-specific settings
if isMobile then
    local HarvestRangeSlider = FarmTab:CreateSlider({
        Name = "Harvest Range (Mobile)",
        Range = {5, 30},
        Increment = 1,
        Suffix = "studs",
        CurrentValue = 15,
        Flag = "HarvestRangeSlider",
        Callback = function(Value)
            getgenv().HarvestRange = Value
            Rayfield:Notify({
                Title = "Harvest Range",
                Content = "Harvest range set to: " .. Value .. " studs",
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
end

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

-- Debug Section untuk membantu identifikasi masalah
local DebugSection = SettingsTab:CreateSection("Debug Tools")

SettingsTab:CreateButton({
    Name = "Debug Harvest",
    Callback = function()
        local maturePlants = findMaturePlants()
        Rayfield:Notify({
            Title = "Debug Info",
            Content = "Mature plants: " .. #maturePlants .. ", Is Mobile: " .. tostring(isMobile),
            Duration = 6,
            Image = 4483362458,
        })
        
        -- Print detailed info to console
        print("=== DEBUG HARVEST ===")
        print("Is Mobile:", isMobile)
        print("Mature plants found:", #maturePlants)
        
        local events = getHarvestEvents()
        print("Harvest events found:", #events)
        for _, event in ipairs(events) do
            print("Event:", event:GetFullName())
        end
        
        local touchEvent = getTouchEvent()
        print("Touch event:", touchEvent and touchEvent:GetFullName() or "None")
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

function autoHarvest()
    spawn(function()
        while getgenv().AutoHarvest do
            local plants = findMaturePlants()
            if #plants > 0 then
                for _, plant in ipairs(plants) do
                    if not getgenv().AutoHarvest then break end
                    
                    if isMobile then
                        -- Untuk mobile, gunakan metode yang berbeda
                        mobileHarvest(plant)
                    else
                        -- Untuk desktop, gunakan metode standar
                        teleportTo(plant.PrimaryPart.Position + Vector3.new(0, 3, 0))
                        harvestPlant()
                    end
                    
                    wait(0.3) -- Waktu lebih pendek
                end
                Rayfield:Notify({
                    Title = "Auto Harvest",
                    Content = "Harvested " .. #plants .. " plants",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            wait(1) -- Interval lebih pendek
        end
    end)
end

-- Fungsi khusus untuk harvest di mobile
function mobileHarvest(plant)
    if not plant or not plant.PrimaryPart then return end
    
    -- Method 1: Coba gunakan remote events terlebih dahulu
    local events = getHarvestEvents()
    if #events > 0 then
        for _, event in ipairs(events) do
            event:FireServer(plant)
        end
        return
    end
    
    -- Method 2: Coba gunakan touch event
    local touchEvent = getTouchEvent()
    if touchEvent then
        touchEvent:FireServer(plant)
        return
    end
    
    -- Method 3: Teleport dekat tanaman dan coba interaksi
    local player = game.Players.LocalPlayer
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            -- Teleport ke dekat tanaman
            local harvestPosition = plant.PrimaryPart.Position + Vector3.new(0, 3, getgenv().HarvestRange)
            humanoidRootPart.CFrame = CFrame.new(harvestPosition)
            
            -- Hadapkan karakter ke tanaman
            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, plant.PrimaryPart.Position)
            
            wait(0.2)
            
            -- Coba gunakan tool jika ada
            local tool = findTool("Harvest Tool") or findTool("Sickle") or findTool("Axe")
            if tool then
                -- Equip tool
                player.Character.Humanoid:EquipTool(tool)
                wait(0.2)
                
                -- Coba aktifkan tool
                if tool:FindFirstChild("Activate") then
                    for i = 1, 3 do  -- Coba beberapa kali
                        tool.Activate:Invoke()
                        wait(0.1)
                    end
                end
            end
            
            -- Coba click di posisi tanaman (simulasi touch)
            simulateTouch(plant.PrimaryPart.Position)
        end
    end
end

-- Simulasi touch untuk mobile
function simulateTouch(position)
    if not isMobile then return end
    
    -- Coba temukan cara untuk mensimulasikan touch
    local touchInput = {
        Position = Vector2.new(0, 0), -- Posisi layar (akan dihitung)
        UserInputType = Enum.UserInputType.Touch,
        KeyCode = Enum.KeyCode.Unknown
    }
    
    -- Coba kirim input event (mungkin tidak bekerja di semua environment)
    pcall(function()
        game:GetService("VirtualInputManager"):SendTouchEvent(0, position, Enum.TouchState.Began, touchInput)
        wait(0.1)
        game:GetService("VirtualInputManager"):SendTouchEvent(0, position, Enum.TouchState.Ended, touchInput)
    end)
end

-- Game Interaction Functions
function findEmptyPlots()
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
    local dryPlants = {}
    local plants = workspace:FindFirstChild("Plants") or workspace:FindFirstChild("Crops")
    
    if plants then
        for _, plant in ipairs(plants:GetChildren()) do
            if plant:IsA("Model") and plant:GetAttribute("NeedsWater") then
                table.insert(dryPlants, plant)
            end
        end
    end
    
    return dryPlants
end

function findMaturePlants()
    local maturePlants = {}
    
    -- Cari tanaman di berbagai lokasi yang mungkin
    local possibleParents = {
        workspace:FindFirstChild("Plants"),
        workspace:FindFirstChild("Crops"),
        workspace:FindFirstChild("Garden"),
        workspace:FindFirstChild("Farm"),
        workspace
    }
    
    for _, parent in ipairs(possibleParents) do
        if parent then
            for _, plant in ipairs(parent:GetChildren()) do
                if plant:IsA("Model") and plant.PrimaryPart then
                    -- Beberapa cara untuk mendeteksi tanaman siap panen
                    local isMature = false
                    
                    -- 1. Cek attribute
                    if plant:GetAttribute("IsMature") or plant:GetAttribute("ReadyToHarvest") then
                        isMature = true
                    end
                    
                    -- 2. Cek part color atau transparency (jika ada perubahan visual)
                    for _, part in ipairs(plant:GetDescendants()) do
                        if part:IsA("Part") or part:IsA("MeshPart") then
                            if part.BrickColor == BrickColor.new("Bright yellow") or 
                               part.Transparency < 0.5 or part.Name:find("Ripe") or
                               part.Name:find("Mature") then
                                isMature = true
                                break
                            end
                        end
                    end
                    
                    -- 3. Cek jika ada part khusus untuk tanaman matang
                    if plant:FindFirstChild("Harvestable") or plant:FindFirstChild("Mature") then
                        isMature = true
                    end
                    
                    -- 4. Cek berdasarkan ukuran (tanaman matang biasanya lebih besar)
                    if plant.PrimaryPart.Size.Magnitude > 5 then
                        isMature = true
                    end
                    
                    if isMature then
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
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        
        if isMobile then
            -- Untuk mobile, coba gunakan activate
            if tool:FindFirstChild("Activate") then
                tool.Activate:Invoke()
            else
                -- Coba gunakan remote event
                local plantEvents = getPlantEvents()
                if #plantEvents > 0 then
                    for _, event in ipairs(plantEvents) do
                        event:FireServer()
                    end
                end
            end
        else
            mouse1click()
        end
    end
end

function waterPlant()
    local tool = findTool("Watering Can")
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        
        if isMobile then
            if tool:FindFirstChild("Activate") then
                tool.Activate:Invoke()
            end
        else
            mouse1click()
        end
    end
end

function harvestPlant()
    local tool = findTool("Harvest Tool") or findTool("Sickle") or findTool("Axe")
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        
        if isMobile then
            if tool:FindFirstChild("Activate") then
                tool.Activate:Invoke()
            end
        else
            mouse1click()
        end
    else
        -- Coba tanpa tool
        local events = getHarvestEvents()
        if #events > 0 then
            for _, event in ipairs(events) do
                event:FireServer()
            end
        end
    end
end

function findTool(toolName)
    local backpack = game.Players.LocalPlayer.Backpack
    local character = game.Players.LocalPlayer.Character
    
    -- Cek di backpack
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name == toolName or item.Name:find(toolName)) then
            return item
        end
    end
    
    -- Cek di character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") and (item.Name == toolName or item.Name:find(toolName)) then
                return item
            end
        end
    end
    
    return nil
end

-- Fungsi untuk mendapatkan event panen
function getHarvestEvents()
    local events = {}
    
    local possibleLocations = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Workspace"),
        game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts")
    }
    
    for _, location in ipairs(possibleLocations) do
        if location then
            for _, item in ipairs(location:GetDescendants()) do
                if item:IsA("RemoteEvent") and 
                  (item.Name:find("Harvest") or item.Name:find("Collect") or 
                   item.Name:find("Pick") or item.Name:find("Gather")) then
                    table.insert(events, item)
                end
            end
        end
    end
    
    return events
end

-- Fungsi untuk mendapatkan event planting
function getPlantEvents()
    local events = {}
    
    local possibleLocations = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Workspace"),
        game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts")
    }
    
    for _, location in ipairs(possibleLocations) do
        if location then
            for _, item in ipairs(location:GetDescendants()) do
                if item:IsA("RemoteEvent") and 
                  (item.Name:find("Plant") or item.Name:find("Seed") or 
                   item.Name:find("Grow")) then
                    table.insert(events, item)
                end
            end
        end
    end
    
    return events
end

-- Fungsi khusus untuk mendapatkan event touch yang digunakan di mobile
function getTouchEvent()
    local touchEvent
    
    -- Cek di berbagai lokasi yang mungkin
    local locations = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Workspace"),
        game:GetService("Players").LocalPlayer
    }
    
    for _, location in ipairs(locations) do
        if location then
            if location:FindFirstChild("TouchEvent") then
                touchEvent = location.TouchEvent
                break
            elseif location:FindFirstChild("MobileEvent") then
                touchEvent = location.MobileEvent
                break
            elseif location:FindFirstChild("InteractEvent") then
                touchEvent = location.InteractEvent
                break
            end
        end
    end
    
    return touchEvent
end

function teleportTo(cframe)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
    end
end

function setWalkSpeed(speed)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
    end
end

function setJumpPower(power)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = power
    end
end

-- Initialize
setWalkSpeed(getgenv().WalkSpeed)
setJumpPower(getgenv().JumpPower)

Rayfield:Notify({
    Title = "Script Loaded",
    Content = "Grow a Garden Auto Farm successfully loaded!" .. (isMobile and " (Mobile Mode)" : ""),
    Duration = 6,
    Image = 4483362458,
})
