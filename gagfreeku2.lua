local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Tunggu sampai game fully loaded
local player = Players.LocalPlayer
local Character = player.CharacterAdded:Wait()
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
local CropsListAndStocks = {}
local wantedFruits = {}
local plantToRemove = {"None Selected"}
local plantAura = false
local AutoSellItems = 70
local shouldSell = false
local shouldAutoPlant = false
local isSelling = false
local autoBuyEnabled = false
local isBuying = false

-- Load Rayfield dengan cara yang lebih reliable
local Rayfield
local success, errorMessage = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success then
    -- Fallback ke library lain jika Rayfield gagal
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end

-- Create Window dengan konfigurasi yang sederhana
local Window = Rayfield:CreateWindow({
    Name = "Grow A Garden - OPTIMIZED",
    LoadingTitle = "Loading Auto Farm System...",
    LoadingSubtitle = "by Sirius",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "GrowAGardenConfig"
    },
    KeySystem = false,
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

local function getAllIFromDict(Dict)
    local newList = {"None Selected"}
    for i in pairs(Dict) do
        table.insert(newList, i)
    end
    return newList
end

local function getPlantedFruitTypes()
    local list = {"None Selected"}
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

-- Remove Plants System
local function removePlantsOfKind(kind)
    if not kind or kind[1] == "None Selected" then return end
    
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]") or Backpack:FindFirstChild("Shovel")
    if not Shovel then return end
    
    Shovel.Parent = Character
    task.wait(0.3)
    
    local farm = findPlayerFarm()
    if not farm then return end
    
    for _, plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if plant.Name == kind[1] and plant:FindFirstChild("Fruit_Spawn") then
            HRP.CFrame = plant.PrimaryPart.CFrame
            task.wait(0.1)
            pcall(function()
                removeItem:FireServer(plant.Fruit_Spawn)
            end)
            task.wait(0.05)
        end
    end 
    
    if Shovel.Parent == Character then
        Shovel.Parent = Backpack
    end
end

-- Shop System
local function StripPlantStock(UnstrippedStock)
    local num = string.match(UnstrippedStock, "%d+")
    return tonumber(num) or 0
end

local function getCropsListAndStock()
    local oldStock = CropsListAndStocks
    CropsListAndStocks = {}
    
    local seedShopGui = player.PlayerGui:FindFirstChild("Seed_Shop")
    if not seedShopGui then return false end
    
    local scrollingFrame = seedShopGui.Frame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return false end
    
    for _, plantGui in pairs(scrollingFrame:GetChildren()) do
        if plantGui:FindFirstChild("Main_Frame") then
            local mainFrame = plantGui.Main_Frame
            local stockText = mainFrame:FindFirstChild("Stock_Text")
            if stockText then
                local plantName = plantGui.Name
                local plantStock = StripPlantStock(stockText.Text)
                CropsListAndStocks[plantName] = plantStock
            end
        end
    end
    return false
end

-- Harvesting System
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

local function collectPlant(plant)
    if not plant then return end
    
    local prompt = plant:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
        return
    end
    
    for _, child in pairs(plant:GetChildren()) do
        local childPrompt = child:FindFirstChildOfClass("ProximityPrompt")
        if childPrompt then
            fireproximityprompt(childPrompt)
            break
        end
    end
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

local function CollectAllPlants()
    local plants = GetAllPlants()
    if #plants == 0 then return end
    
    for i = #plants, 2, -1 do
        local j = math.random(i)
        plants[i], plants[j] = plants[j], plants[i]
    end
    
    for _, plant in pairs(plants) do
        if plant and plant.Parent then
            collectPlant(plant)
        end
        task.wait(0.01)
    end
end

-- Auto Harvest Aura
local auraConnection
local function togglePlantAura(value)
    plantAura = value
    
    if auraConnection then
        auraConnection:Disconnect()
        auraConnection = nil
    end
    
    if value then
        auraConnection = RunService.Heartbeat:Connect(function()
            local plants = GetAllPlants()
            for _, plant in pairs(plants) do
                if plant and plant.Parent then
                    collectPlant(plant)
                end
            end
        end)
    end
end

-- Planting System
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

local function plantAllSeeds()
    local farm = findPlayerFarm()
    if not farm then return end
    if not areThereSeeds() then return end
    
    local edges = getPlantingBoundaries(farm)
    
    while areThereSeeds() do
        for _, item in pairs(Backpack:GetChildren()) do
            if item:FindFirstChild("Seed Local Script") then
                item.Parent = Character
                task.wait(0.1)
                
                local location = getRandomPlantingLocation(edges)
                local seedType = item:GetAttribute("Seed")
                
                if seedType then
                    pcall(function()
                        Plant:FireServer(location.Position, seedType)
                    end)
                end
                
                task.wait(0.1)
                
                if item and item.Parent == Character then
                    item.Parent = Backpack
                end
            end
        end
        task.wait(0.2)
    end
end

-- Auto Buy System
local function buyCropSeeds(cropName)
    local success = pcall(function()
        BuySeedStock:FireServer(cropName)
    end)
    return success
end

local function buyWantedCropSeeds()
    if #wantedFruits == 0 or isBuying then return false end
    
    isBuying = true
    local beforePos = HRP.CFrame
    
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    task.wait(1.5)
    
    local totalBought = 0
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        if stock > 0 then
            for i = 1, stock do
                if buyCropSeeds(fruitName) then
                    totalBought = totalBought + 1
                end
                task.wait(0.1)
            end
        end
    end
    
    task.wait(0.5)
    HRP.CFrame = beforePos
    isBuying = false
    return totalBought > 0
end

-- Selling System
local function sellAll()
    if isSelling then return end
    
    isSelling = true
    local beforePos = HRP.CFrame
    
    HRP.CFrame = Steven.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    task.wait(1.5)
    
    local startTime = tick()
    while #Backpack:GetChildren() > 0 and tick() - startTime < 10 do
        pcall(function()
            sellAllRemote:FireServer()
        end)
        task.wait(0.3)
    end
    
    HRP.CFrame = beforePos
    isSelling = false
end

-- Auto Systems
local autoSellConnection
local function toggleAutoSell(value)
    shouldSell = value
    
    if autoSellConnection then
        autoSellConnection:Disconnect()
        autoSellConnection = nil
    end
    
    if value then
        autoSellConnection = RunService.Heartbeat:Connect(function()
            if not isSelling and #Backpack:GetChildren() >= AutoSellItems then
                sellAll()
            end
        end)
    end
end

local autoPlantConnection
local function toggleAutoPlant(value)
    shouldAutoPlant = value
    
    if autoPlantConnection then
        autoPlantConnection:Disconnect()
        autoPlantConnection = nil
    end
    
    if value then
        autoPlantConnection = RunService.Heartbeat:Connect(function()
            if areThereSeeds() then
                plantAllSeeds()
                task.wait(1)
            end
        end)
    end
end

-- Create UI Tabs
local Tab = Window:CreateTab("Plants", "rbxassetid://4483345998")

Tab:CreateSection("Remove Plants")

local PlantToRemoveDropdown = Tab:CreateDropdown({
    Name = "Choose Plant To Remove",
    Options = getPlantedFruitTypes(),
    CurrentOption = {"None Selected"},
    MultipleOptions = false,
    Callback = function(Options)
        plantToRemove = Options
    end,
})

Tab:CreateButton({
    Name = "Refresh Plant List",
    Callback = function()
        PlantToRemoveDropdown:Refresh(getPlantedFruitTypes())
    end,
})

Tab:CreateButton({
    Name = "Remove Selected Plant",
    Callback = function()
        removePlantsOfKind(plantToRemove)
    end,
})

Tab:CreateSection("Harvesting")

Tab:CreateButton({
    Name = "Collect All Plants",
    Callback = CollectAllPlants
})

Tab:CreateToggle({
    Name = "Plant Harvest Aura",
    CurrentValue = false,
    Callback = togglePlantAura,
})

Tab:CreateSection("Planting")

Tab:CreateButton({
    Name = "Plant All Seeds",
    Callback = plantAllSeeds
})

Tab:CreateToggle({
    Name = "Auto Plant Seeds",
    CurrentValue = false,
    Callback = toggleAutoPlant,
})

-- Seeds Tab
local SeedsTab = Window:CreateTab("Seeds", "rbxassetid://4483345998")

getCropsListAndStock()
local cropOptions = getAllIFromDict(CropsListAndStocks)

SeedsTab:CreateDropdown({
    Name = "Select Fruits To Buy",
    Options = cropOptions,
    CurrentOption = {},
    MultipleOptions = true,
    Callback = function(Options)
        wantedFruits = {}
        for _, option in ipairs(Options) do
            if option ~= "None Selected" then
                table.insert(wantedFruits, option)
            end
        end
    end,
})

SeedsTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Callback = function(Value)
        autoBuyEnabled = Value
    end,
})

SeedsTab:CreateButton({
    Name = "Buy Selected Seeds Now",
    Callback = buyWantedCropSeeds,
})

-- Sell Tab
local SellTab = Window:CreateTab("Sell", "rbxassetid://4483345998")

SellTab:CreateToggle({
    Name = "Enable Auto Sell",
    CurrentValue = false,
    Callback = toggleAutoSell,
})

SellTab:CreateSlider({
    Name = "Items Threshold For Auto Sell",
    Range = {10, 200},
    Increment = 5,
    Suffix = "Items",
    CurrentValue = 70,
    Callback = function(Value)
        AutoSellItems = Value
    end,
})

SellTab:CreateButton({
    Name = "Sell All Items Now",
    Callback = sellAll,
})

-- Player Tab
local PlayerTab = Window:CreateTab("Player", "rbxassetid://4483345998")

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(Value)
        Humanoid.WalkSpeed = Value
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 10,
    Suffix = "Power",
    CurrentValue = 50,
    Callback = function(Value)
        Humanoid.JumpPower = Value
    end,
})

PlayerTab:CreateButton({
    Name = "Reset Movement",
    Callback = function()
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
    end,
})

PlayerTab:CreateButton({
    Name = "Create TP Wand",
    Callback = function()
        local mouse = player:GetMouse()
        local TPWand = Instance.new("Tool")
        TPWand.Name = "TP Wand"
        TPWand.RequiresHandle = false
        TPWand.Parent = Backpack
        
        TPWand.Activated:Connect(function()
            HRP.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
        end)
    end,
})

-- Load completed
Rayfield:Notify({
    Title = "Script Loaded",
    Content = "Grow A Garden Optimized is ready!",
    Duration = 5,
})

print("Grow A Garden script loaded successfully!")
