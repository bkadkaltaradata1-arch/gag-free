-- Grow A Garden Auto Farm Scripta
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Wait for player to load
if not Player then
    Player = Players.PlayerAdded:Wait()
end

-- Wait for character to load
local Character = Player.Character or Player.CharacterAdded:Wait()
local Backpack = Player:WaitForChild("Backpack")
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Wait for other services
local FarmsFolder = Workspace:WaitForChild("Farm")
local BuySeedStock = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock")
local Plant = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Plant_RE")
local sellAllRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory")
local removeItem = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

-- Find NPCs safely
local Steven = Workspace:FindFirstChild("NPCS") and Workspace.NPCS:FindFirstChild("Steven")
local Sam = Workspace:FindFirstChild("NPCS") and Workspace.NPCS:FindFirstChild("Sam")

-- Initialize variables
local CropsListAndStocks = {}
local wantedFruits = {}
local plantAura = false
local AutoSellItems = 70
local shouldSell = false
local plantToRemove = {"None Selected"}
local shouldAutoPlant = false
local isSelling = false
local autoBuyEnabled = false
local lastShopStock = {}
local isBuying = false

-- Sheckles Buy Variables
local Sheckles_Buy = ReplicatedStorage.GameEvents:FindFirstChild("Sheckles_Buy")
local autoShecklesBuyEnabled = false
local shecklesBuyCooldown = 5
local lastShecklesBuyTime = 0

-- GUI Variables
local SeedShopGUI = Player.PlayerGui:FindFirstChild("Seed_Shop") and Player.PlayerGui.Seed_Shop.Frame:FindFirstChild("ScrollingFrame")
local shopTimer = Player.PlayerGui:FindFirstChild("Seed_Shop") and Player.PlayerGui.Seed_Shop.Frame.Frame:FindFirstChild("Timer")

-- Load Rayfield UI
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Failed to load Rayfield UI!")
    return
end

-- Create main window
local Window = Rayfield:CreateWindow({
   Name = "Grow A Garden Auto Farm",
   LoadingTitle = "Grow A Garden Script",
   LoadingSubtitle = "Loading...",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "GAGscript",
      FileName = "Config"
   },
})

-- Utility functions
local function findPlayerFarm()
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important and v.Important.Data and v.Important.Data.Owner and v.Important.Data.Owner.Value == Player.Name then
            return v
        end
    end
    return nil
end

local function getAllIFromDict(Dict)
    local newList = {"None Selected"}
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
    local list = {"None Selected"}
    local farm = findPlayerFarm()
    if not farm then return list end
    
    if farm.Important and farm.Important.Plants_Physical then
        for _,plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
            if not(isInTable(list, plant.Name)) then
                table.insert(list, plant.Name)
            end
        end
    end
    return list
end

local function StripPlantStock(UnstrippedStock)
    local num = string.match(UnstrippedStock, "%d+")
    return num
end

function getCropsListAndStock()
    local oldStock = CropsListAndStocks
    CropsListAndStocks = {}
    
    if SeedShopGUI then
        for _,Plant in pairs(SeedShopGUI:GetChildren()) do
            if Plant:FindFirstChild("Main_Frame") and Plant.Main_Frame:FindFirstChild("Stock_Text") then
                local PlantName = Plant.Name
                local PlantStock = StripPlantStock(Plant.Main_Frame.Stock_Text.Text)
                CropsListAndStocks[PlantName] = PlantStock
            end
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

local function getPlantingBoundaries(farm)
    local offset = Vector3.new(15.2844,0,28.356)
    local edges = {}
    
    if farm.Important and farm.Important.Plant_Locations then
        local PlantingLocations = farm.Important.Plant_Locations:GetChildren()
        if #PlantingLocations >= 2 then
            local rect1Center = PlantingLocations[1].Position
            local rect2Center = PlantingLocations[2].Position
            edges["1TopLeft"] = rect1Center + offset
            edges["1BottomRight"] = rect1Center - offset
            edges["2TopLeft"] = rect2Center + offset
            edges["2BottomRight"] = rect2Center - offset
        end
    end
    return edges
end

local function getRandomPlantingLocation(edges)
    if not edges["1TopLeft"] then
        return CFrame.new(0, 0, 0)
    end
    
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

local function areThereSeeds()
    for _,Item in pairs(Backpack:GetChildren()) do
        if Item:FindFirstChild("Seed Local Script") then
            return true
        end
    end
    return false
end

local function plantAllSeeds()
    local farm = findPlayerFarm()
    if not farm then return end
    
    local edges = getPlantingBoundaries(farm)
    
    while areThereSeeds() do
        for _,Item in pairs(Backpack:GetChildren()) do
            if Item:FindFirstChild("Seed Local Script") then
                Item.Parent = Character
                wait(0.1)
                local location = getRandomPlantingLocation(edges)
                local args = {
                    [1] = location.Position,
                    [2] = Item:GetAttribute("Seed")
                }
                Plant:FireServer(unpack(args))
                wait(0.1)
                if Item and Item:IsDescendantOf(game) and Item.Parent ~= Backpack then
                    pcall(function()
                        Item.Parent = Backpack
                    end)
                end
            end
        end
        wait(0.5)
    end
end

local function GetAllPlants()
    local plantsTable = {}
    local farm = findPlayerFarm()
    if not farm or not farm.Important or not farm.Important.Plants_Physical then return plantsTable end
    
    for _, Plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if Plant:FindFirstChild("Fruits") then
            for _, miniPlant in pairs(Plant.Fruits:GetChildren()) do
                table.insert(plantsTable, miniPlant)
            end
        else
            table.insert(plantsTable, Plant)
        end
    end
    return plantsTable
end

local function collectPlant(plant)
    if plant:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(plant.ProximityPrompt)
    else
        for _, child in pairs(plant:GetChildren()) do
            if child:FindFirstChild("ProximityPrompt") then
                fireproximityprompt(child.ProximityPrompt)
                break
            end
        end
    end
end

local function CollectAllPlants()
    local plants = GetAllPlants()
    
    for i = #plants, 2, -1 do
        local j = math.random(i)
        plants[i], plants[j] = plants[j], plants[i]
    end
    
    for _,plant in pairs(plants) do
        collectPlant(plant)
        task.wait(0.05)
    end
end

local function removePlantsOfKind(kind)
    if not kind or kind[1] == "None Selected" then return end
    
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]") or Backpack:FindFirstChild("Shovel")
    if not Shovel then return end
    
    Shovel.Parent = Character
    wait(0.5)
    
    local farm = findPlayerFarm()
    if farm and farm.Important and farm.Important.Plants_Physical then
        for _,plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
            if plant.Name == kind[1] then
                if plant:FindFirstChild("Fruit_Spawn") then
                    local spawnPoint = plant.Fruit_Spawn
                    HRP.CFrame = plant.PrimaryPart.CFrame
                    wait(0.2)
                    removeItem:FireServer(spawnPoint)
                    wait(0.1)
                end
            end
        end
    end
    
    if Shovel and Shovel.Parent == Character then
        Shovel.Parent = Backpack
    end
end

-- Sheckles Buy Function
local function performShecklesBuy()
    if not Sheckles_Buy then return false end
    
    local currentTime = tick()
    if currentTime - lastShecklesBuyTime < shecklesBuyCooldown then return false end
    
    local success, errorMsg = pcall(function()
        Sheckles_Buy:FireServer()
    end)
    
    if success then
        lastShecklesBuyTime = currentTime
        return true
    else
        return false
    end
end

local function buyCropSeeds(cropName)
    local args = {[1] = cropName}
    local success, errorMsg = pcall(function()
        BuySeedStock:FireServer(unpack(args))
    end)
    return success
end

function buyWantedCropSeeds()
    if #wantedFruits == 0 or isBuying then return false end
    
    isBuying = true
    local beforePos = HRP.CFrame
    
    if Sam then
        HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
        wait(1.5)
        HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
        wait(0.5)
    end
    
    local boughtAny = false
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        if stock > 0 then
            for j = 1, stock do
                if buyCropSeeds(fruitName) then
                    boughtAny = true
                end
                wait(0.2)
            end
        end
    end
    
    if Sam then
        wait(0.5)
        HRP.CFrame = beforePos
    end
    
    isBuying = false
    return boughtAny
end

local function getTimeInSeconds(input)
    if not input then return 0 end
    local minutes = tonumber(input:match("(%d+)m")) or 0
    local seconds = tonumber(input:match("(%d+)s")) or 0
    return minutes * 60 + seconds
end

local function sellAll()
    if not Steven or isSelling then return end
    
    local OrgPos = HRP.CFrame
    HRP.CFrame = Steven.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    wait(1.5)
    
    isSelling = true
    sellAllRemote:FireServer()
    
    local startTime = tick()
    while #Backpack:GetChildren() >= AutoSellItems and tick() - startTime < 10 do
        sellAllRemote:FireServer()
        wait(0.5)
    end
    
    HRP.CFrame = OrgPos
    isSelling = false
end

-- Create tabs
local Tab = Window:CreateTab("Plants", "rbxassetid://4483345998")
local testingTab = Window:CreateTab("Testing", "rbxassetid://4483345998")
local localPlayerTab = Window:CreateTab("LocalPlayer", "rbxassetid://4483345998")
local seedsTab = Window:CreateTab("Seeds", "rbxassetid://4483345998")
local sellTab = Window:CreateTab("Sell", "rbxassetid://4483345998")

-- Plants Tab
Tab:CreateSection("Remove Plants")

local PlantToRemoveDropdown = Tab:CreateDropdown({
   Name = "Choose A Plant To Remove",
   Options = getPlantedFruitTypes(),
   CurrentOption = "None Selected",
   MultipleOptions = false,
   Callback = function(Option)
        plantToRemove = {Option}
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

Tab:CreateSection("Harvesting Plants")

Tab:CreateToggle({
   Name = "Harvest Plants Aura",
   CurrentValue = false,
   Callback = function(Value)
        plantAura = Value
   end,
})

Tab:CreateButton({
    Name = "Collect All Plants",
    Callback = function()
        CollectAllPlants()
    end,
})

Tab:CreateSection("Planting")

Tab:CreateButton({
    Name = "Plant all Seeds",
    Callback = function()
        plantAllSeeds()
    end,
})

Tab:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = false,
    Callback = function(Value)
        shouldAutoPlant = Value
    end,
})

-- Testing Tab
testingTab:CreateSection("Debug Info")

testingTab:CreateButton({
    Name = "Print Player Info",
    Callback = function()
        print("Player:", Player.Name)
        print("Farm:", findPlayerFarm() and "Found" or "Not Found")
        print("Sheckles_Buy:", Sheckles_Buy and "Exists" or "Not Found")
    end,
})

testingTab:CreateSection("Shop Info")

local RayFieldShopTimer = testingTab:CreateParagraph({Title = "Shop Timer", Content = "Waiting..."})

testingTab:CreateButton({
    Name = "Print Crop Stocks",
    Callback = function()
        for i,v in pairs(CropsListAndStocks) do
            print(i.."'s Stock Is:", v)
        end
    end,
})

-- LocalPlayer Tab
localPlayerTab:CreateSection("Movement")

local speedSlider = localPlayerTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 500},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = 16,
   Callback = function(Value)
        if Humanoid then
            Humanoid.WalkSpeed = Value
        end
   end,
})

local jumpSlider = localPlayerTab:CreateSlider({
   Name = "Jump Power",
   Range = {50, 500},
   Increment = 5,
   Suffix = "Jump Power",
   CurrentValue = 50,
   Callback = function(Value)
        if Humanoid then
            Humanoid.JumpPower = Value
        end
   end,
})

localPlayerTab:CreateButton({
    Name = "Default Speed",
    Callback = function()
        speedSlider:Set(16)
        jumpSlider:Set(50)
    end,
})

localPlayerTab:CreateSection("Teleport")

localPlayerTab:CreateButton({
    Name = "Create TP Wand",
    Callback = function()
        local mouse = Player:GetMouse()
        local TPWand = Instance.new("Tool", Backpack)
        TPWand.Name = "TP Wand"
        TPWand.RequiresHandle = false
        mouse.Button1Down:Connect(function()
            if Character:FindFirstChild("TP Wand") then
                HRP.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
            end
        end)
    end,
})

localPlayerTab:CreateButton({
    Name = "Destroy TP Wand",
    Callback = function()
        if Backpack:FindFirstChild("TP Wand") then
            Backpack:FindFirstChild("TP Wand"):Destroy()
        end
        if Character:FindFirstChild("TP Wand") then
            Character:FindFirstChild("TP Wand"):Destroy()
        end
    end,
})

-- Seeds Tab
seedsTab:CreateSection("Seed Selection")

local initialCrops = getAllIFromDict(CropsListAndStocks)

local fruitDropdown = seedsTab:CreateDropdown({
   Name = "Fruits To Buy",
   Options = initialCrops,
   CurrentOption = "None Selected",
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

seedsTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Callback = function(Value)
        autoBuyEnabled = Value
    end,
})

seedsTab:CreateButton({
    Name = "Buy Selected Fruits Now",
    Callback = function()
        buyWantedCropSeeds()
    end,
})

seedsTab:CreateSection("Sheckles Buy")

if Sheckles_Buy then
    seedsTab:CreateToggle({
        Name = "Auto Sheckles Buy",
        CurrentValue = false,
        Callback = function(Value)
            autoShecklesBuyEnabled = Value
        end,
    })

    seedsTab:CreateSlider({
       Name = "Sheckles Buy Cooldown",
       Range = {1, 60},
       Increment = 1,
       Suffix = "seconds",
       CurrentValue = 5,
       Callback = function(Value)
            shecklesBuyCooldown = Value
       end,
    })

    seedsTab:CreateButton({
        Name = "Sheckles Buy Now",
        Callback = function()
            performShecklesBuy()
        end,
    })
else
    seedsTab:CreateLabel({
        Name = "Sheckles_Buy feature not available",
        Description = "The Sheckles_Buy remote was not found in the game"
    })
end

-- Sell Tab
sellTab:CreateSection("Auto Sell")

sellTab:CreateToggle({
    Name = "Auto Sell Enabled",
    CurrentValue = false,
    Callback = function(Value)
        shouldSell = Value
    end,
})

sellTab:CreateSlider({
   Name = "Items Threshold for Auto Sell",
   Range = {1, 200},
   Increment = 1,
   Suffix = "Items",
   CurrentValue = 70,
   Callback = function(Value)
        AutoSellItems = Value
   end,
})

sellTab:CreateButton({
    Name = "Sell All Now",
    Callback = function()
        sellAll()
    end,
})

-- Main loops
spawn(function()
    while true do
        if autoShecklesBuyEnabled and Sheckles_Buy then
            performShecklesBuy()
        end
        wait(shecklesBuyCooldown)
    end
end)

spawn(function()
    while true do
        if shopTimer and shopTimer.Text then
            local shopTime = getTimeInSeconds(shopTimer.Text)
            RayFieldShopTimer:Set({Title = "Shop Timer", Content = "Shop Resets in " .. shopTime .. "s"})
            
            local isRefreshed = getCropsListAndStock()
            if isRefreshed and autoBuyEnabled and not isBuying then
                wait(2)
                buyWantedCropSeeds()
            end
        end
        
        if shouldSell and #Backpack:GetChildren() >= AutoSellItems and not isSelling then
            sellAll()
        end
        
        wait(0.5)
    end
end)

spawn(function()
    while true do
        if plantAura then
            local plants = GetAllPlants()
            for i = #plants, 2, -1 do
                local j = math.random(i)
                plants[i], plants[j] = plants[j], plants[i]
            end
            
            for _, plant in pairs(plants) do
                if plant:FindFirstChild("Fruits") then
                    for _, miniPlant in pairs(plant.Fruits:GetChildren()) do
                        for _, child in pairs(miniPlant:GetChildren()) do
                            if child:FindFirstChild("ProximityPrompt") then
                                fireproximityprompt(child.ProximityPrompt)
                            end
                        end
                        task.wait(0.01)
                    end
                else
                    for _, child in pairs(plant:GetChildren()) do
                        if child:FindFirstChild("ProximityPrompt") then
                            fireproximityprompt(child.ProximityPrompt)
                        end
                        task.wait(0.01)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Auto Plant loop
spawn(function()
    while true do
        if shouldAutoPlant then
            plantAllSeeds()
        end
        wait(5)
    end
end)

-- Update references on character respawn
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HRP = newCharacter:WaitForChild("HumanoidRootPart")
    Humanoid = newCharacter:WaitForChild("Humanoid")
    
    if speedSlider then
        Humanoid.WalkSpeed = speedSlider.CurrentValue
    end
    if jumpSlider then
        Humanoid.JumpPower = jumpSlider.CurrentValue
    end
end)

-- Initial setup
local playerFarm = findPlayerFarm()
getCropsListAndStock()

print("Grow A Garden script loaded successfully!")
Rayfield:Notify({
    Title = "Script Loaded",
    Content = "Grow A Garden script has been loaded successfully!",
    Duration = 5
})
