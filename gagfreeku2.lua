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
local playerPositionLabel
local playerPositionUpdateConnection

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

-- Tampilkan posisi pemain
playerPositionLabel = PlayerTab:CreateLabel("Position: Loading...")

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
        if playerPositionUpdateConnection then
            playerPositionUpdateConnection:Disconnect()
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
    if playerPositionUpdateConnection then
        playerPositionUpdateConnection:Disconnect()
    end
    
    playerPositionUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local position = character.HumanoidRootPart.Position
            playerPositionLabel:SetText(string.format("Position: X:%.1f, Y:%.1f, Z:%.1f", position.X, position.Y, position.Z))
        else
            playerPositionLabel:SetText("Position: Character not found")
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
                    teleportTo(plot.CFrame)
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
                    teleportTo(plant.PrimaryPart.CFrame)
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
                    teleportTo(plant.PrimaryPart.CFrame)
                    harvestPlant(plant)
                    wait(0.5)
                end
                Rayfield:Notify({
                    Title = "Auto Harvest",
                    Content = "Harvested " .. #plants .. " plants",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            wait(2)
        end
    end)
end

-- Game Interaction Functions (Improved implementations)
function findEmptyPlots()
    -- Implementasi untuk mencari plot kosong
    local emptyPlots = {}
    local plots = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Garden") or workspace:FindFirstChild("Farm")
    
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            if plot:IsA("Part") and (plot.Name:find("Plot") or plot.Name:find("Soil")) and not hasPlant(plot) then
                table.insert(emptyPlots, plot)
            end
        end
    else
        -- Fallback: cari part dengan nama tertentu yang mungkin merupakan plot
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("Part") and (part.Name:find("Plot") or part.Name:find("Soil")) and not hasPlant(part) then
                table.insert(emptyPlots, part)
            end
        end
    end
    
    return emptyPlots
end

function hasPlant(plot)
    -- Cek apakah plot sudah memiliki tanaman
    for _, child in ipairs(plot:GetChildren()) do
        if child:IsA("Model") and (child.Name:find("Plant") or child.Name:find("Crop")) then
            return true
        end
    end
    return false
end

function findDryPlants()
    -- Implementasi untuk mencari tanaman yang perlu disiram
    local dryPlants = {}
    
    -- Cari semua tanaman di workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:find("Plant") or obj.Name:find("Crop")) then
            -- Cek jika tanaman perlu disiram (berdasarkan attribute atau warna)
            if obj:GetAttribute("NeedsWater") or (obj.PrimaryPart and obj.PrimaryPart.Color.r > 0.7) then
                table.insert(dryPlants, obj)
            end
        end
    end
    
    return dryPlants
end

function findMaturePlants()
    -- Implementasi untuk mencari tanaman yang siap panen
    local maturePlants = {}
    
    -- Cari semua tanaman di workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:find("Plant") or obj.Name:find("Crop")) then
            -- Cek jika tanaman sudah matang (berdasarkan attribute, size, atau warna)
            if obj:GetAttribute("IsMature") or 
               (obj.PrimaryPart and (obj.PrimaryPart.Size.Y > 3 or obj.PrimaryPart.Color.G < 0.5)) then
                table.insert(maturePlants, obj)
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
        -- Simulasikan klik mouse
        if tool:FindFirstChild("Handle") then
            tool.Handle.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
        end
        tool:Activate()
        wait(0.5)
    end
end

function waterPlant()
    -- Implementasi untuk menyiram tanaman
    local tool = findTool("Watering Can") or findTool("Water") or findTool("Can")
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        tool:Activate()
        wait(0.5)
    end
end

function harvestPlant(plant)
    -- Implementasi untuk memanen tanaman
    local tool = findTool("Harvest Tool") or findTool("Sickle") or findTool("Axe") or findTool("Knife")
    
    if not tool then
        -- Jika tidak ada tool khusus, coba gunakan tangan
        tool = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
    end
    
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.2)
        
        -- Arahkan tool ke tanaman
        if plant and plant.PrimaryPart then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = plant.PrimaryPart.CFrame * CFrame.new(0, 0, 3)
        end
        
        tool:Activate()
        wait(0.5)
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
    
    -- Cek juga di karakter
    local character = game.Players.LocalPlayer.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") and (item.Name == toolName or item.Name:find(toolName)) then
                return item
            end
        end
    end
    
    return nil
end

function teleportTo(cframe)
    -- Teleport player ke posisi tertentu
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
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
    Content = "Grow a Garden Auto Farm successfully loaded!",
    Duration = 6,
    Image = 4483362458,
})

-- Close GUI with RightShift (default)
-- You can minimize/maximize the GUI with the keybind
