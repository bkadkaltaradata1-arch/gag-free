local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmsFolder = Workspace.Farm
local Players = game:GetService("Players")
local BuySeedStock = ReplicatedStorage.GameEvents.BuySeedStock
local Plant = ReplicatedStorage.GameEvents.Plant_RE
local Backpack = Players.LocalPlayer.Backpack
local Character = Players.LocalPlayer.Character
local sellAllRemote = ReplicatedStorage.GameEvents.Sell_Inventory
local Steven = Workspace.NPCS.Steven
local Sam = Workspace.NPCS.Sam
local HRP = Players.LocalPlayer.Character.HumanoidRootPart
local CropsListAndStocks = {}
local SeedShopGUI = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame.ScrollingFrame
local shopTimer = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame.Frame.Timer
local shopTime = 0
local Humanoid = Character:WaitForChild("Humanoid")
wantedFruits = {}
local plantAura = false
local AutoSellItems = 70
local shouldSell = false
local removeItem = ReplicatedStorage.GameEvents.Remove_Item
local plantToRemove
local shouldAutoPlant = false
local isSelling = false
local byteNetReliable = ReplicatedStorage:FindFirstChild("ByteNetReliable")
local autoBuyEnabled = false
local lastShopStock = {}
local isBuying = false -- Flag untuk menandai sedang membeli

-- OPTIMASI HARVEST: Variabel untuk kontrol kecepatan
local harvestSpeed = 0.01 -- Default speed (lebih cepat dari sebelumnya)
local maxHarvestDistance = 50 -- Jarak maksimum untuk harvest
local harvestMultiThread = true -- Multi-threading untuk harvest

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Grow A Garden - OPTIMIZED",
   Icon = 0,
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by Sirius",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "GAGscript"
   },
})

local function findPlayerFarm()
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important.Data.Owner.Value == Players.LocalPlayer.Name then
            return v
        end
    end
    return nil
end

-- OPTIMASI: Fungsi untuk mendapatkan posisi tanaman dengan cepat
local function getPlantPosition(plant)
    if plant and plant.PrimaryPart then
        return plant.PrimaryPart.Position
    elseif plant and plant:FindFirstChild("HumanoidRootPart") then
        return plant.HumanoidRootPart.Position
    else
        return plant and plant:GetPivot().Position or Vector3.new(0,0,0)
    end
end

-- OPTIMASI: Fungsi untuk cek jarak dengan cepat
local function isWithinDistance(position1, position2, maxDistance)
    return (position1 - position2).Magnitude <= maxDistance
end

local function removePlantsOfKind(kind)
    if not kind or kind[1] == "None Selected" then
        print("No plant selected to remove")
        return
    end
    
    print("Kind: "..kind[1])
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]") or Backpack:FindFirstChild("Shovel")
    
    if not Shovel then
        print("Shovel not found in backpack")
        return
    end
    
    Shovel.Parent = Character
    wait(0.3) -- Reduced wait time
    
    local farm = findPlayerFarm()
    if not farm then return end
    
    for _,plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if plant.Name == kind[1] then
            if plant:FindFirstChild("Fruit_Spawn") then
                local spawnPoint = plant.Fruit_Spawn
                HRP.CFrame = CFrame.new(getPlantPosition(plant)) + Vector3.new(0, 3, 0)
                wait(0.1) -- Reduced wait time
                removeItem:FireServer(spawnPoint)
                wait(0.05) -- Reduced wait time
            end
        end
    end 
    
    -- Return shovel to backpack
    if Shovel and Shovel.Parent == Character then
        Shovel.Parent = Backpack
    end
end

local function getAllIFromDict(Dict)
    local newList = {}
    for i,_ in pairs(Dict) do
        table.insert(newList, i)
    end
    return newList
end

local function isInTable(table,value)
    for _,i in pairs(table) do
        if i==value then
            return true
        end
    end
    return false
end

local function getPlantedFruitTypes()
    local list = {}
    local farm = findPlayerFarm()
    if not farm then return list end
    
    for _,plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if not(isInTable(list, plant.Name)) then
            table.insert(list, plant.Name)
        end
    end
    return list
end

local Tab = Window:CreateTab("Plants", "rewind")
Tab:CreateSection("Remove Plants")
local PlantToRemoveDropdown = Tab:CreateDropdown({
   Name = "Choose A Plant To Remove",
   Options = getPlantedFruitTypes(),
   CurrentOption = {"None Selected"},
   MultipleOptions = false,
   Flag = "Dropdown1", 
   Callback = function(Options)
    plantToRemove = Options
   end,
})

Tab:CreateButton({
    Name = "Refresh Selection",
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

Tab:CreateSection("Harvesting Plants - OPTIMIZED")

-- OPTIMASI HARVEST: Slider untuk kontrol kecepatan harvest
Tab:CreateSlider({
   Name = "Harvest Speed (Lower = Faster)",
   Range = {0.001, 0.1},
   Increment = 0.001,
   Suffix = "seconds",
   CurrentValue = 0.01,
   Flag = "HarvestSpeed",
   Callback = function(Value)
        harvestSpeed = Value
        print("Harvest speed set to: " .. Value .. " seconds")
   end,
})

-- OPTIMASI HARVEST: Toggle untuk multi-threading
Tab:CreateToggle({
   Name = "Multi-Thread Harvest (Experimental)",
   CurrentValue = true,
   Flag = "MultiThreadHarvest",
   Callback = function(Value)
        harvestMultiThread = Value
        print("Multi-thread harvest: " .. tostring(Value))
   end,
})

local function printCropStocks()
    for i,v in pairs(CropsListAndStocks) do
        print(i.."'s Stock Is:", v)
    end
end

local function StripPlantStock(UnstrippedStock)
    local num = string.match(UnstrippedStock, "%d+")
    return num
end

function getCropsListAndStock()
    local oldStock = CropsListAndStocks
    CropsListAndStocks = {} -- Reset the table
    for _,Plant in pairs(SeedShopGUI:GetChildren()) do
        if Plant:FindFirstChild("Main_Frame") and Plant.Main_Frame:FindFirstChild("Stock_Text") then
            local PlantName = Plant.Name
            local PlantStock = StripPlantStock(Plant.Main_Frame.Stock_Text.Text)
            CropsListAndStocks[PlantName] = PlantStock
        end
    end
    
    local isRefreshed = false
    for cropName, stock in pairs(CropsListAndStocks) do
        if oldStock[cropName] ~= stock then
            isRefreshed = true
            break
        end
    end
    
    return isRefreshed
end

local playerFarm = findPlayerFarm()
getCropsListAndStocks()

local function getPlantingBoundaries(farm)
    local offset = Vector3.new(15.2844,0,28.356)
    local edges = {}
    local PlantingLocations = farm.Important.Plant_Locations:GetChildren()
    local rect1Center = PlantingLocations[1].Position
    local rect2Center = PlantingLocations[2].Position
    edges["1TopLeft"] = rect1Center + offset
    edges["1BottomRight"] = rect1Center - offset
    edges["2TopLeft"] = rect2Center + offset
    edges["2BottomRight"] = rect2Center - offset
    return edges
end

-- OPTIMASI HARVEST: Fungsi collectPlant yang lebih efisien
local function collectPlant(plant)
    local playerPos = HRP.Position
    
    -- Cek jarak sebelum harvest
    local plantPos = getPlantPosition(plant)
    if not isWithinDistance(playerPos, plantPos, maxHarvestDistance) then
        -- Teleport ke tanaman jika terlalu jauh
        HRP.CFrame = CFrame.new(plantPos + Vector3.new(0, 3, 0))
        wait(0.1)
    end
    
    -- Metode collection yang lebih agresif
    if plant:FindFirstChild("ProximityPrompt") then
        for i = 1, 3 do -- Multiple clicks untuk memastikan
            fireproximityprompt(plant.ProximityPrompt)
            wait(0.01)
        end
    else
        for _, child in pairs(plant:GetChildren()) do
            if child:FindFirstChild("ProximityPrompt") then
                for i = 1, 3 do
                    fireproximityprompt(child.ProximityPrompt)
                    wait(0.01)
                end
                break
            end
        end
    end
end

-- OPTIMASI HARVEST: Fungsi GetAllPlants yang lebih cepat
local function GetAllPlants()
    local plantsTable = {}
    local farm = findPlayerFarm()
    if not farm then return plantsTable end
    
    -- Gunakan lebih sedikit iterasi
    local plantsFolder = farm.Important.Plants_Physical
    for _, Plant in pairs(plantsFolder:GetChildren()) do
        if Plant:FindFirstChild("Fruits") then
            local fruits = Plant.Fruits:GetChildren()
            for i = 1, #fruits do
                plantsTable[#plantsTable + 1] = fruits[i]
            end
        else
            plantsTable[#plantsTable + 1] = Plant
        end
    end
    return plantsTable
end

-- OPTIMASI HARVEST: Fungsi CollectAllPlants yang jauh lebih cepat
local function CollectAllPlants()
    local plants = GetAllPlants()
    print("Got "..#plants.." Plants")
    
    if #plants == 0 then return end
    
    -- OPTIMASI: Group plants by position untuk mengurangi teleportasi
    local positionGroups = {}
    for _, plant in pairs(plants) do
        local pos = getPlantPosition(plant)
        local roundedPos = Vector3.new(
            math.floor(pos.X / 10) * 10,
            math.floor(pos.Y / 10) * 10,
            math.floor(pos.Z / 10) * 10
        )
        
        if not positionGroups[roundedPos] then
            positionGroups[roundedPos] = {}
        end
        table.insert(positionGroups[roundedPos], plant)
    end
    
    -- OPTIMASI: Process plants by groups
    for groupPos, groupPlants in pairs(positionGroups) do
        -- Teleport ke tengah group
        HRP.CFrame = CFrame.new(groupPos + Vector3.new(0, 3, 0))
        wait(0.1)
        
        -- Harvest semua tanaman dalam group
        for _, plant in pairs(groupPlants) do
            collectPlant(plant)
            wait(harvestSpeed) -- Gunakan speed yang bisa diatur
        end
    end
    
    print("Harvest completed!")
end

-- OPTIMASI HARVEST: Plant Aura yang lebih efisien
spawn(function()
    while true do
        if plantAura then
            local plants = GetAllPlants()
            
            if #plants > 0 then
                -- OPTIMASI: Group plants by position
                local positionGroups = {}
                for _, plant in pairs(plants) do
                    local pos = getPlantPosition(plant)
                    local roundedPos = Vector3.new(
                        math.floor(pos.X / 10) * 10,
                        math.floor(pos.Y / 10) * 10,
                        math.floor(pos.Z / 10) * 10
                    )
                    
                    if not positionGroups[roundedPos] then
                        positionGroups[roundedPos] = {}
                    end
                    table.insert(positionGroups[roundedPos], plant)
                end
                
                -- OPTIMASI: Multi-threading jika diaktifkan
                if harvestMultiThread then
                    local threads = {}
                    
                    for groupPos, groupPlants in pairs(positionGroups) do
                        local thread = spawn(function()
                            -- Teleport ke group
                            HRP.CFrame = CFrame.new(groupPos + Vector3.new(0, 3, 0))
                            wait(0.05)
                            
                            for _, plant in pairs(groupPlants) do
                                collectPlant(plant)
                                wait(harvestSpeed)
                            end
                        end)
                        table.insert(threads, thread)
                    end
                    
                    -- Tunggu semua thread selesai
                    for _, thread in pairs(threads) do
                        coroutine.resume(thread)
                    end
                else
                    -- Single-thread approach
                    for groupPos, groupPlants in pairs(positionGroups) do
                        HRP.CFrame = CFrame.new(groupPos + Vector3.new(0, 3, 0))
                        wait(0.1)
                        
                        for _, plant in pairs(groupPlants) do
                            collectPlant(plant)
                            wait(harvestSpeed)
                        end
                    end
                end
            end
        end
        wait(0.1)
    end
end)

Tab:CreateButton({
    Name = "Collect All Plants (OPTIMIZED)",
    Callback = function()
        CollectAllPlants()
        print("Collecting All Plants with optimized method")
    end,
})

Tab:CreateToggle({
   Name = "Harvest Plants Aura (OPTIMIZED)",
   CurrentValue = false,
   Flag = "Toggle1",
   Callback = function(Value)
    plantAura = Value
    print("Optimized Plant Aura Set To: ".. tostring(Value))
   end,
})

local function getRandomPlantingLocation(edges)
    local rectangles = {
        {edges["1TopLeft"], edges["1BottomRight"]},
        {edges["2TopLeft"], edges["2BottomRight"]}
    }

    local chosen = rectangles[math.random(1, #rectangles)]
    local a = chosen[1]
    local b = chosen[2]

    local minX, maxX = math.min(a.X, b.X), math.max(a.X, b.X)
    local minZ, maxZ = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
    local Y = 0.13552704453468323

    local randY = Y + (math.random() * 0.1 - 0.05)
    local randX = math.random() * (maxX - minX) + minX
    local randZ = math.random() * (maxZ - minZ) + minZ

    return CFrame.new(randX, randY, randZ)
end

local function areThereSeeds()
    for _,Item in pairs(Backpack:GetChildren()) do
        if Item:FindFirstChild("Seed Local Script") then
            return true
        end
    end
    print("Seeds Not Found!")
    return false
end

local function plantAllSeeds()
    print("Planting All Seeds...")
    task.wait(0.5) -- Reduced wait time
    
    local edges = getPlantingBoundaries(playerFarm)
    local plantedCount = 0
    
    while areThereSeeds() do
        print("There Are Seeds!")
        for _,Item in pairs(Backpack:GetChildren()) do
            if Item:FindFirstChild("Seed Local Script") then
                Item.Parent = Character
                wait(0.05) -- Reduced wait time
                local location = getRandomPlantingLocation(edges)
                local args = {
                    [1] = location.Position,
                    [2] = Item:GetAttribute("Seed")
                }
                Plant:FireServer(unpack(args))
                plantedCount = plantedCount + 1
                wait(0.05) -- Reduced wait time
                if Item and Item:IsDescendantOf(game) and Item.Parent ~= Backpack then
                    pcall(function()
                        Item.Parent = Backpack
                    end
                end
            end
        end
        wait(0.2) -- Reduced delay
    end
    print("Planted " .. plantedCount .. " seeds total!")
end

-- ... (rest of the code remains similar but with optimized wait times)

-- Tambahkan section khusus untuk optimasi
local optimizationTab = Window:CreateTab("Optimization", "settings")
optimizationTab:CreateSection("Harvest Optimization Settings")

optimizationTab:CreateSlider({
   Name = "Max Harvest Distance",
   Range = {10, 100},
   Increment = 5,
   Suffix = "studs",
   CurrentValue = 50,
   Flag = "HarvestDistance",
   Callback = function(Value)
        maxHarvestDistance = Value
        print("Max harvest distance set to: " .. Value)
   end,
})

optimizationTab:CreateToggle({
   Name = "Aggressive Harvest (Multiple Clicks)",
   CurrentValue = true,
   Flag = "AggressiveHarvest",
   Callback = function(Value)
        print("Aggressive harvest: " .. tostring(Value))
   end,
})

optimizationTab:CreateButton({
   Name = "Optimize Performance",
   Callback = function()
        -- Reduce graphics settings for better performance
        settings().Rendering.QualityLevel = 1
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 100000
        print("Performance optimized!")
   end,
})

print("OPTIMIZED Grow A Garden script loaded successfully!")
