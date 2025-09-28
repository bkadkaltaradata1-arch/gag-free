-- v1
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Player References
local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local Backpack = player.Backpack
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Remote Events
local BuySeedStock = ReplicatedStorage.GameEvents.BuySeedStock
local Plant = ReplicatedStorage.GameEvents.Plant_RE
local sellAllRemote = ReplicatedStorage.GameEvents.Sell_Inventory
local removeItem = ReplicatedStorage.GameEvents.Remove_Item

-- Game References
local FarmsFolder = Workspace.Farm
local Steven = Workspace.NPCS.Steven
local Sam = Workspace.NPCS.Sam

-- Variables
local plantAura = false
local shouldAutoPlant = false
local shouldSell = false
local autoBuyEnabled = false
local isSelling = false
local isBuying = false
local AutoSellItems = 50
local wantedFruits = {}
local plantToRemove = "None"
local CropsListAndStocks = {}

-- Load Venus UI (PASTI WORK)
local Venus = loadstring(game:HttpGet('https://raw.githubusercontent.com/RegularVynixu/UI-Libraries/main/Venus/ui-lib.lua'))()

-- Create Window
local window = Venus:New({
    title = "🌱 Grow A Garden - AUTO FARM",
    caption = "Auto Harvest, Plant, Buy & Sell",
    icon = "rbxassetid://6034287591",
    color = Color3.fromRGB(0, 170, 0),
    isCentered = true,
    size = UDim2.new(0, 500, 0, 400),
})

-- Basic Functions
local function findPlayerFarm()
    for _, farm in pairs(FarmsFolder:GetChildren()) do
        if farm.Important.Data.Owner.Value == player.Name then
            return farm
        end
    end
    return nil
end

local function getPlantedFruitTypes()
    local list = {"None"}
    local farm = findPlayerFarm()
    if not farm then return list end
    
    local seen = {}
    for _, plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if not seen[plant.Name] then
            seen[plant.Name] = true
            table.insert(list, plant.Name)
        end
    end
    return list
end

local function collectPlant(plant)
    if not plant or not plant.Parent then return false end
    
    local prompt = plant:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
        return true
    end
    
    for _, child in pairs(plant:GetChildren()) do
        local childPrompt = child:FindFirstChildOfClass("ProximityPrompt")
        if childPrompt then
            fireproximityprompt(childPrompt)
            return true
        end
    end
    return false
end

local function GetAllPlants()
    local plantsTable = {}
    local farm = findPlayerFarm()
    if not farm then return plantsTable end
    
    for _, plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if plant:FindFirstChild("Fruits") then
            for _, fruit in pairs(plant.Fruits:GetChildren()) do
                table.insert(plantsTable, fruit)
            end
        else
            table.insert(plantsTable, plant)
        end
    end
    return plantsTable
end

local function getPlantingBoundaries(farm)
    local offset = Vector3.new(15.2844, 0, 28.356)
    local edges = {}
    local plantingLocations = farm.Important.Plant_Locations:GetChildren()
    
    if #plantingLocations >= 2 then
        local rect1Center = plantingLocations[1].Position
        local rect2Center = plantingLocations[2].Position
        edges["1TopLeft"] = rect1Center + offset
        edges["1BottomRight"] = rect1Center - offset
        edges["2TopLeft"] = rect2Center + offset
        edges["2BottomRight"] = rect2Center - offset
    end
    return edges
end

local function getRandomPlantingLocation(edges)
    if not edges or not edges["1TopLeft"] then 
        return CFrame.new(0, 5, 0)
    end
    
    local rectangles = {
        {edges["1TopLeft"], edges["1BottomRight"]},
        {edges["2TopLeft"], edges["2BottomRight"]}
    }

    local chosen = rectangles[math.random(1, #rectangles)]
    local a, b = chosen[1], chosen[2]

    local minX, maxX = math.min(a.X, b.X), math.max(a.X, b.X)
    local minZ, maxZ = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
    local Y = 0.13552704453468323

    local randX = math.random() * (maxX - minX) + minX
    local randZ = math.random() * (maxZ - minZ) + minZ

    return CFrame.new(randX, Y, randZ)
end

local function areThereSeeds()
    for _, item in pairs(Backpack:GetChildren()) do
        if item:FindFirstChild("Seed Local Script") then
            return true
        end
    end
    return false
end

-- Harvesting System
local function HarvestAllPlants()
    local plants = GetAllPlants()
    if #plants == 0 then
        Venus:Notify("Harvest", "No plants found to harvest!", "rbxassetid://6034287591")
        return
    end
    
    Venus:Notify("Harvest", "Harvesting " .. #plants .. " plants...", "rbxassetid://6034287591")
    
    local collected = 0
    for _, plant in pairs(plants) do
        if plant and plant.Parent then
            if collectPlant(plant) then
                collected = collected + 1
            end
        end
        task.wait(0.02)
    end
    
    Venus:Notify("Harvest Complete", "Collected " .. collected .. " plants!", "rbxassetid://6034287591")
end

-- Auto Harvest Aura
local auraConnection
local function toggleAutoHarvest(state)
    plantAura = state
    
    if auraConnection then
        auraConnection:Disconnect()
        auraConnection = nil
    end
    
    if state then
        Venus:Notify("Auto Harvest", "Aura activated!", "rbxassetid://6034287591")
        
        auraConnection = RunService.Heartbeat:Connect(function()
            local plants = GetAllPlants()
            for _, plant in pairs(plants) do
                if plant and plant.Parent then
                    collectPlant(plant)
                end
            end
        end)
    else
        Venus:Notify("Auto Harvest", "Aura deactivated!", "rbxassetid://6034287591")
    end
end

-- Planting System
local function PlantAllSeeds()
    local farm = findPlayerFarm()
    if not farm then
        Venus:Notify("Error", "Farm not found!", "rbxassetid://6034287591")
        return
    end
    
    if not areThereSeeds() then
        Venus:Notify("Info", "No seeds found in backpack!", "rbxassetid://6034287591")
        return
    end
    
    Venus:Notify("Planting", "Planting all seeds...", "rbxassetid://6034287591")
    
    local edges = getPlantingBoundaries(farm)
    local plantedCount = 0
    
    while areThereSeeds() do
        local plantedThisRound = false
        
        for _, item in pairs(Backpack:GetChildren()) do
            if item:FindFirstChild("Seed Local Script") then
                item.Parent = Character
                task.wait(0.1)
                
                local location = getRandomPlantingLocation(edges)
                local seedType = item:GetAttribute("Seed")
                
                if seedType then
                    local success = pcall(function()
                        Plant:FireServer(location.Position, seedType)
                        plantedCount = plantedCount + 1
                        plantedThisRound = true
                    end)
                end
                
                task.wait(0.1)
                
                if item and item.Parent == Character then
                    item.Parent = Backpack
                end
            end
        end
        
        if not plantedThisRound then break end
        task.wait(0.2)
    end
    
    Venus:Notify("Planting Complete", "Planted " .. plantedCount .. " seeds!", "rbxassetid://6034287591")
end

-- Auto Plant System
local autoPlantConnection
local function toggleAutoPlant(state)
    shouldAutoPlant = state
    
    if autoPlantConnection then
        autoPlantConnection:Disconnect()
        autoPlantConnection = nil
    end
    
    if state then
        Venus:Notify("Auto Plant", "Auto planting activated!", "rbxassetid://6034287591")
        
        autoPlantConnection = RunService.Heartbeat:Connect(function()
            if areThereSeeds() then
                PlantAllSeeds()
                task.wait(2)
            end
        end)
    else
        Venus:Notify("Auto Plant", "Auto planting deactivated!", "rbxassetid://6034287591")
    end
end

-- Selling System
local function SellAllItems()
    if isSelling then return end
    
    isSelling = true
    local beforePos = HRP.CFrame
    local itemsBefore = #Backpack:GetChildren()
    
    if itemsBefore == 0 then
        Venus:Notify("Sell", "No items to sell!", "rbxassetid://6034287591")
        isSelling = false
        return
    end
    
    Venus:Notify("Selling", "Selling " .. itemsBefore .. " items...", "rbxassetid://6034287591")
    
    -- Go to Steven
    HRP.CFrame = Steven.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    task.wait(1.5)
    
    local startTime = tick()
    local transactions = 0
    
    while #Backpack:GetChildren() > 0 and tick() - startTime < 15 do
        local success = pcall(function()
            sellAllRemote:FireServer()
            transactions = transactions + 1
        end)
        task.wait(0.3)
    end
    
    local itemsAfter = #Backpack:GetChildren()
    local itemsSold = itemsBefore - itemsAfter
    
    -- Return to original position
    HRP.CFrame = beforePos
    isSelling = false
    
    Venus:Notify("Sell Complete", "Sold " .. itemsSold .. " items!", "rbxassetid://6034287591")
end

-- Auto Sell System
local autoSellConnection
local function toggleAutoSell(state)
    shouldSell = state
    
    if autoSellConnection then
        autoSellConnection:Disconnect()
        autoSellConnection = nil
    end
    
    if state then
        Venus:Notify("Auto Sell", "Auto sell activated! Threshold: " .. AutoSellItems, "rbxassetid://6034287591")
        
        autoSellConnection = RunService.Heartbeat:Connect(function()
            if not isSelling and #Backpack:GetChildren() >= AutoSellItems then
                SellAllItems()
            end
        end)
    else
        Venus:Notify("Auto Sell", "Auto sell deactivated!", "rbxassetid://6034287591")
    end
end

-- Remove Plants System
local function RemoveSelectedPlants()
    if plantToRemove == "None" then
        Venus:Notify("Error", "Please select a plant type to remove!", "rbxassetid://6034287591")
        return
    end
    
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]") or Backpack:FindFirstChild("Shovel")
    if not Shovel then
        Venus:Notify("Error", "Shovel not found in backpack!", "rbxassetid://6034287591")
        return
    end
    
    local farm = findPlayerFarm()
    if not farm then
        Venus:Notify("Error", "Farm not found!", "rbxassetid://6034287591")
        return
    end
    
    Shovel.Parent = Character
    task.wait(0.3)
    
    local removedCount = 0
    for _, plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if plant.Name == plantToRemove and plant:FindFirstChild("Fruit_Spawn") then
            HRP.CFrame = plant.PrimaryPart.CFrame
            task.wait(0.1)
            pcall(function()
                removeItem:FireServer(plant.Fruit_Spawn)
                removedCount = removedCount + 1
            end)
            task.wait(0.05)
        end
    end
    
    if Shovel.Parent == Character then
        Shovel.Parent = Backpack
    end
    
    Venus:Notify("Remove Complete", "Removed " .. removedCount .. " " .. plantToRemove .. " plants!", "rbxassetid://6034287591")
end

-- TP Wand System
local function CreateTPWand()
    -- Remove existing wand
    if Backpack:FindFirstChild("TP Wand") then
        Backpack:FindFirstChild("TP Wand"):Destroy()
    end
    if Character:FindFirstChild("TP Wand") then
        Character:FindFirstChild("TP Wand"):Destroy()
    end
    
    local TPWand = Instance.new("Tool")
    TPWand.Name = "TP Wand"
    TPWand.RequiresHandle = false
    TPWand.Parent = Backpack
    
    TPWand.Activated:Connect(function()
        local mouse = player:GetMouse()
        HRP.CFrame = mouse.Hit + Vector3.new(0, 5, 0)
    end)
    
    Venus:Notify("TP Wand", "TP Wand created! Equip from backpack.", "rbxassetid://6034287591")
end

-- Create Tabs
local farmTab = window:Tab("🌱 Farm")
local playerTab = window:Tab("👤 Player")
local extrasTab = window:Tab("⚙️ Extras")

-- Farm Tab
farmTab:Section("Auto Features")

farmTab:Toggle({
    text = "🌀 Auto Harvest Aura",
    flag = "auto_harvest",
    callback = toggleAutoHarvest
})

farmTab:Toggle({
    text = "🌱 Auto Plant Seeds", 
    flag = "auto_plant",
    callback = toggleAutoPlant
})

farmTab:Toggle({
    text = "💰 Auto Sell Items",
    flag = "auto_sell",
    callback = toggleAutoSell
})

farmTab:Section("Manual Actions")

farmTab:Button({
    text = "🌾 Harvest All Plants",
    callback = HarvestAllPlants
})

farmTab:Button({
    text = "🌱 Plant All Seeds",
    callback = PlantAllSeeds
})

farmTab:Button({
    text = "💰 Sell All Items Now", 
    callback = SellAllItems
})

farmTab:Section("Remove Plants")

local plantOptions = getPlantedFruitTypes()

farmTab:Dropdown({
    text = "Select Plant to Remove",
    flag = "plant_remove",
    list = plantOptions,
    callback = function(value)
        plantToRemove = value
    end
})

farmTab:Button({
    text = "🗑️ Remove Selected Plants",
    callback = RemoveSelectedPlants
})

-- Player Tab
playerTab:Section("Movement Settings")

playerTab:Slider({
    text = "Walk Speed",
    flag = "walk_speed",
    min = 16,
    max = 200,
    value = 16,
    callback = function(value)
        Humanoid.WalkSpeed = value
    end
})

playerTab:Slider({
    text = "Jump Power",
    flag = "jump_power", 
    min = 50,
    max = 200,
    value = 50,
    callback = function(value)
        Humanoid.JumpPower = value
    end
})

playerTab:Button({
    text = "🔄 Reset Movement",
    callback = function()
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
        Venus:Notify("Movement Reset", "Speed reset to default!", "rbxassetid://6034287591")
    end
})

playerTab:Section("Teleport")

playerTab:Button({
    text = "🧙‍♂️ Create TP Wand",
    callback = CreateTPWand
})

playerTab:Button({
    text = "📍 Teleport to Farm",
    callback = function()
        local farm = findPlayerFarm()
        if farm then
            HRP.CFrame = farm.Important.Plant_Locations[1].CFrame + Vector3.new(0, 5, 0)
            Venus:Notify("Teleport", "Teleported to farm!", "rbxassetid://6034287591")
        end
    end
})

playerTab:Button({
    text = "🏪 Teleport to Shop",
    callback = function()
        HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
        Venus:Notify("Teleport", "Teleported to seed shop!", "rbxassetid://6034287591")
    end
})

playerTab:Button({
    text = "💰 Teleport to Sell",
    callback = function()
        HRP.CFrame = Steven.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
        Venus:Notify("Teleport", "Teleported to sell NPC!", "rbxassetid://6034287591")
    end
})

-- Extras Tab
extrasTab:Section("Settings")

extrasTab:Slider({
    text = "Auto Sell Threshold",
    flag = "sell_threshold",
    min = 10,
    max = 200,
    value = 50,
    callback = function(value)
        AutoSellItems = value
    end
})

extrasTab:Button({
    text = "📊 Check Backpack",
    callback = function()
        local itemCount = #Backpack:GetChildren()
        Venus:Notify("Backpack", itemCount .. " items in backpack", "rbxassetid://6034287591")
    end
})

extrasTab:Button({
    text = "🔄 Refresh Farm",
    callback = function()
        local farm = findPlayerFarm()
        if farm then
            Venus:Notify("Farm", "Farm found! " .. #farm.Important.Plants_Physical:GetChildren() .. " plants", "rbxassetid://6034287591")
        else
            Venus:Notify("Farm", "Farm not found!", "rbxassetid://6034287591")
        end
    end
})

extrasTab:Section("Information")

extrasTab:Label("Script Features:")
extrasTab:Label("✅ Auto Harvest Aura")
extrasTab:Label("✅ Auto Plant Seeds") 
extrasTab:Label("✅ Auto Sell Items")
extrasTab:Label("✅ Speed & Jump Hack")
extrasTab:Label("✅ TP Wand & Teleports")

-- Auto Systems
task.spawn(function()
    while true do
        -- Auto sell check
        if shouldSell and not isSelling and #Backpack:GetChildren() >= AutoSellItems then
            SellAllItems()
        end
        task.wait(1)
    end
end)

-- Character respawn handler
player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HRP = newCharacter:WaitForChild("HumanoidRootPart")
    Humanoid = newCharacter:WaitForChild("Humanoid")
    Backpack = player.Backpack
    
    -- Reset movement speeds
    Humanoid.WalkSpeed = 16
    Humanoid.JumpPower = 50
    
    Venus:Notify("Character Respawned", "Movement speeds reset!", "rbxassetid://6034287591")
end)

-- Initialization Complete
Venus:Notify("🌱 Script Loaded!", "Grow A Garden Auto Farm is ready!\n\nFeatures:\n• Auto Harvest Aura\n• Auto Plant Seeds\n• Auto Sell Items\n• Speed & Jump Hack\n• TP Wand", "rbxassetid://6034287591")

print("🎯 Grow A Garden Auto Farm loaded successfully!")
print("🌱 Features: Auto Harvest, Auto Plant, Auto Sell")
print("⚡ Optimized for maximum performance")
print("🎮 GUI should be visible on screen!")

-- Load completed
wait(1)
local farm = findPlayerFarm()
if farm then
    print("✅ Farm found: " .. farm.Name)
else
    print("❌ Farm not found!")
end
