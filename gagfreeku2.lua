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
local isBuying = false

-- Cache untuk optimasi
local cache = {
    playerFarm = nil,
    lastFarmCheck = 0,
    farmCheckCooldown = 5,
    plantCache = {},
    lastPlantUpdate = 0,
    plantUpdateCooldown = 1
}

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

-- Fungsi optimasi: cached farm finding
local function findPlayerFarm()
    local now = tick()
    if cache.playerFarm and (now - cache.lastFarmCheck) < cache.farmCheckCooldown then
        return cache.playerFarm
    end
    
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important.Data.Owner.Value == Players.LocalPlayer.Name then
            cache.playerFarm = v
            cache.lastFarmCheck = now
            return v
        end
    end
    return nil
end

-- Optimized plant removal
local function removePlantsOfKind(kind)
    if not kind or kind[1] == "None Selected" then return end
    
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]") or Backpack:FindFirstChild("Shovel")
    if not Shovel then return end
    
    Shovel.Parent = Character
    task.wait(0.3) -- Reduced wait time
    
    local farm = findPlayerFarm()
    if not farm then return end
    
    for _,plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if plant.Name == kind[1] and plant:FindFirstChild("Fruit_Spawn") then
            HRP.CFrame = plant.PrimaryPart.CFrame
            task.wait(0.1) -- Reduced wait time
            removeItem:FireServer(plant.Fruit_Spawn)
            task.wait(0.05) -- Minimal wait
        end
    end 
    
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

-- Optimized plant type detection
local function getPlantedFruitTypes()
    local now = tick()
    if (now - cache.lastPlantUpdate) < cache.plantUpdateCooldown and #cache.plantCache > 0 then
        return cache.plantCache
    end
    
    local list = {}
    local farm = findPlayerFarm()
    if not farm then return list end
    
    -- Gunakan Set untuk menghindari duplikat
    local seen = {}
    for _,plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if not seen[plant.Name] then
            seen[plant.Name] = true
            table.insert(list, plant.Name)
        end
    end
    
    cache.plantCache = list
    cache.lastPlantUpdate = now
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
        cache.lastPlantUpdate = 0 -- Force refresh
        PlantToRemoveDropdown:Refresh(getPlantedFruitTypes())
    end,
})

Tab:CreateButton({
    Name = "Remove Selected Plant",
    Callback = function()
        removePlantsOfKind(plantToRemove)
    end,
})

Tab:CreateSection("Harvesting Plants")

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
    CropsListAndStocks = {}
    
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
getCropsListAndStock()

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

-- OPTIMIZED: Faster plant collection dengan parallel processing
local function collectPlant(plant)
    if plant:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(plant.ProximityPrompt)
        return
    end
    
    -- Cari prompt di children dengan loop yang lebih efisien
    for i = 1, #plant:GetChildren() do
        local child = plant[i]
        if child:FindFirstChild("ProximityPrompt") then
            fireproximityprompt(child.ProximityPrompt)
            break
        end
    end
end

-- OPTIMIZED: Faster plant gathering dengan batch processing
local function GetAllPlants()
    local now = tick()
    local plantsTable = {}
    local farm = findPlayerFarm()
    if not farm then return plantsTable end
    
    local Plants_Physical = farm.Important.Plants_Physical
    local numPlants = #Plants_Physical:GetChildren()
    
    for i = 1, numPlants do
        local Plant = Plants_Physical[i]
        if Plant and Plant:FindFirstChild("Fruits") then
            local Fruits = Plant.Fruits
            local numFruits = #Fruits:GetChildren()
            for j = 1, numFruits do
                local miniPlant = Fruits[j]
                if miniPlant then
                    plantsTable[#plantsTable + 1] = miniPlant
                end
            end
        elseif Plant then
            plantsTable[#plantsTable + 1] = Plant
        end
    end
    
    return plantsTable
end

-- OPTIMIZED: Ultra-fast collection dengan task.spawn
local function CollectAllPlants()
    local plants = GetAllPlants()
    print("Collecting "..#plants.." Plants")
    
    -- Gunakan task.spawn untuk parallel processing
    local tasks = {}
    local batchSize = 5 -- Process 5 plants at once
    
    for i = 1, #plants, batchSize do
        local batch = {}
        for j = i, math.min(i + batchSize - 1, #plants) do
            batch[#batch + 1] = plants[j]
        end
        
        local taskId = task.spawn(function(batchPlants)
            for _, plant in ipairs(batchPlants) do
                if plant and plant.Parent then
                    collectPlant(plant)
                    task.wait(0.01) -- Reduced delay
                end
            end
        end, batch)
        
        tasks[#tasks + 1] = taskId
    end
    
    -- Tunggu semua task selesai
    for _, taskId in ipairs(tasks) do
        task.wait(taskId)
    end
end

Tab:CreateButton({
    Name = "Collect All Plants (FAST)",
    Callback = function()
        CollectAllPlants()
    end,
})

-- OPTIMIZED: Plant Aura dengan performance improvements
spawn(function()
    local lastAuraRun = 0
    local auraCooldown = 0.05 -- Increased speed
    
    while true do
        if plantAura then
            local currentTime = tick()
            if currentTime - lastAuraRun >= auraCooldown then
                lastAuraRun = currentTime
                
                local plants = GetAllPlants()
                local numPlants = #plants
                
                if numPlants > 0 then
                    -- Process plants in smaller batches for better performance
                    for i = 1, numPlants, 3 do -- Process 3 plants at a time
                        for j = i, math.min(i + 2, numPlants) do
                            local plant = plants[j]
                            if plant and plant.Parent then
                                if plant:FindFirstChild("Fruits") then
                                    local Fruits = plant.Fruits
                                    for k = 1, #Fruits:GetChildren() do
                                        local miniPlant = Fruits[k]
                                        if miniPlant then
                                            for l = 1, #miniPlant:GetChildren() do
                                                local child = miniPlant[l]
                                                if child:FindFirstChild("ProximityPrompt") then
                                                    fireproximityprompt(child.ProximityPrompt)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                else
                                    for k = 1, #plant:GetChildren() do
                                        local child = plant[k]
                                        if child:FindFirstChild("ProximityPrompt") then
                                            fireproximityprompt(child.ProximityPrompt)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(0.01) -- Small delay between batches
                    end
                end
            end
        end
        task.wait(0.02) -- Reduced main loop delay
    end
end)

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

    local randX = math.random() * (maxX - minX) + minX
    local randZ = math.random() * (maxZ - minZ) + minZ

    return CFrame.new(randX, Y, randZ)
end

-- OPTIMIZED: Faster seed checking
local function areThereSeeds()
    for i = 1, #Backpack:GetChildren() do
        local Item = Backpack[i]
        if Item:FindFirstChild("Seed Local Script") then
            return true
        end
    end
    return false
end

-- OPTIMIZED: Faster planting dengan reduced delays
local function plantAllSeeds()
    print("Planting All Seeds...")
    task.wait(0.5) -- Reduced initial wait
    
    local edges = getPlantingBoundaries(playerFarm)
    local backpackChildren = Backpack:GetChildren()
    
    while areThereSeeds() do
        local planted = false
        
        for i = 1, #backpackChildren do
            local Item = backpackChildren[i]
            if Item and Item.Parent == Backpack and Item:FindFirstChild("Seed Local Script") then
                Item.Parent = Character
                task.wait(0.05) -- Reduced equip wait
                
                local location = getRandomPlantingLocation(edges)
                local args = {
                    [1] = location.Position,
                    [2] = Item:GetAttribute("Seed")
                }
                Plant:FireServer(unpack(args))
                task.wait(0.05) -- Reduced plant wait
                
                if Item and Item:IsDescendantOf(game) and Item.Parent ~= Backpack then
                    pcall(function()
                        Item.Parent = Backpack
                    end)
                end
                planted = true
            end
        end
        
        if not planted then break end
        task.wait(0.1) -- Reduced loop delay
        backpackChildren = Backpack:GetChildren() -- Refresh cache
    end
end

Tab:CreateToggle({
   Name = "Harvest Plants Aura (OPTIMIZED)",
   CurrentValue = false,
   Flag = "Toggle1",
   Callback = function(Value)
    plantAura = Value
    print("Plant Aura Set To: ".. tostring(Value))
   end,
})

local testingTab = Window:CreateTab("Testing","rewind")
testingTab:CreateSection("List Crops Names And Prices")
testingTab:CreateButton({
    Name = "Print Out All Crops Names And Stocks",
    Callback = function()
        printCropStocks()
        print("Printed")
    end,
})

Tab:CreateSection("Plant")
Tab:CreateButton({
    Name = "Plant all Seeds (FAST)",
    Callback = function()
        plantAllSeeds()
    end,
})

Tab:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = false,
    flag = "ToggleAutoPlant",
    Callback = function(Value)
        shouldAutoPlant = Value
        if Value then
            spawn(function()
                while shouldAutoPlant and areThereSeeds() do
                    plantAllSeeds()
                    task.wait(1)
                end
            end)
        end
    end,
})

testingTab:CreateSection("Shop")
local RayFieldShopTimer = testingTab:CreateParagraph({Title = "Shop Timer", Content = "Waiting..."})

testingTab:CreateSection("Plot Corners")
testingTab:CreateButton({
    Name = "Teleport edges",
    Callback = function()
        local edges = getPlantingBoundaries(playerFarm)
        for i,v in pairs(edges) do
            HRP.CFrame = CFrame.new(v)
            task.wait(1) -- Reduced wait time
        end
    end,
})

testingTab:CreateButton({
    Name = "Teleport random plantable position",
    Callback = function()
        HRP.CFrame = getRandomPlantingLocation(getPlantingBoundaries(playerFarm))
    end,
})

-- OPTIMIZED: Faster buying dengan reduced delays
local function buyCropSeeds(cropName)
    local args = {[1] = cropName}
    local success = pcall(function()
        BuySeedStock:FireServer(unpack(args))
    end)
    return success
end

function buyWantedCropSeeds()
    if #wantedFruits == 0 or isBuying then return false end
    
    isBuying = true
    local beforePos = HRP.CFrame
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    -- Faster teleportation
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    task.wait(1) -- Reduced wait time
    
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    task.wait(0.3) -- Reduced wait time
    
    local boughtAny = false
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        if stock > 0 then
            -- Buy in batches untuk mengurangi delay
            for j = 1, stock, 3 do -- Buy 3 at a time
                local batchCount = math.min(3, stock - j + 1)
                for k = 1, batchCount do
                    if buyCropSeeds(fruitName) then
                        boughtAny = true
                    end
                end
                task.wait(0.15) -- Reduced delay between batches
            end
        end
    end
    
    task.wait(0.3) -- Reduced wait time
    HRP.CFrame = beforePos
    isBuying = false
    return boughtAny
end

local function onShopRefresh()
    print("Shop Refreshed")
    getCropsListAndStock()
    if #wantedFruits > 0 and autoBuyEnabled and not isBuying then
        task.wait(1.5) -- Reduced wait time
        buyWantedCropSeeds()
    end
end

local function getTimeInSeconds(input)
    if not input then return 0 end
    local minutes = tonumber(input:match("(%d+)m")) or 0
    local seconds = tonumber(input:match("(%d+)s")) or 0
    return minutes * 60 + seconds
end

-- OPTIMIZED: Faster selling
local function sellAll()
    local OrgPos = HRP.CFrame
    HRP.CFrame = Steven.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    task.wait(1) -- Reduced wait time
    
    isSelling = true
    local startTime = tick()
    
    while #Backpack:GetChildren() >= AutoSellItems and tick() - startTime < 8 do -- Reduced timeout
        sellAllRemote:FireServer()
        task.wait(0.3) -- Reduced delay
    end
    
    HRP.CFrame = OrgPos
    isSelling = false
end

-- OPTIMIZED: Main loop dengan better performance
spawn(function() 
    local lastStockCheck = 0
    local stockCheckCooldown = 1
    
    while true do
        local currentTime = tick()
        
        if shopTimer and shopTimer.Text then
            shopTime = getTimeInSeconds(shopTimer.Text)
            RayFieldShopTimer:Set({Title = "Shop Timer", Content = "Shop Resets in " .. shopTime .. "s"})
            
            if currentTime - lastStockCheck >= stockCheckCooldown then
                lastStockCheck = currentTime
                local isRefreshed = getCropsListAndStock()
                
                if isRefreshed and autoBuyEnabled and not isBuying then
                    onShopRefresh()
                end
            end
        end
        
        if shouldSell and #Backpack:GetChildren() >= AutoSellItems and not isSelling then
            sellAll()
        end
        
        task.wait(0.3) -- Increased main loop speed
    end
end)

-- ... (sisanya tetap sama, tapi dengan task.wait menggantikan wait)

print("Grow A Garden OPTIMIZED script loaded successfully!")
