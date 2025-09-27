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

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Grow A Garden",
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

local function findProximityPrompt(npc)
    if npc:FindFirstChildOfClass("ProximityPrompt") then
        return npc:FindFirstChildOfClass("ProximityPrompt")
    end
    
    for _, descendant in pairs(npc:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            return descendant
        end
    end
    
    return nil
end

local function clickGUIElement(element, elementName)
    if not element then
        print("Element not found: " .. tostring(elementName))
        return false
    end
    
    local remoteEvent = element:FindFirstChildOfClass("RemoteEvent")
    if remoteEvent then
        local success, result = pcall(function()
            remoteEvent:FireServer()
            return true
        end)
        if success then
            print("Clicked " .. elementName .. " using RemoteEvent")
            return true
        end
    end
    
    local bindableEvent = element:FindFirstChildOfClass("BindableEvent")
    if bindableEvent then
        local success, result = pcall(function()
            bindableEvent:Fire()
            return true
        end)
        if success then
            print("Clicked " .. elementName .. " using BindableEvent")
            return true
        end
    end
    
    if element:IsA("TextButton") or element:IsA("ImageButton") then
        local success, result = pcall(function()
            element.MouseButton1Click:Fire()
            return true
        end)
        if success then
            print("Clicked " .. elementName .. " using MouseButton1Click")
            return true
        end
        
        local success, result = pcall(function()
            if element.MouseEnter then element.MouseEnter:Fire() end
            if element.MouseButton1Down then element.MouseButton1Down:Fire() end
            if element.MouseButton1Up then element.MouseButton1Up:Fire() end
            if element.Activated then element.Activated:Fire() end
            return true
        end)
        if success then
            print("Clicked " .. elementName .. " using manual events")
            return true
        end
    end
    
    print("Failed to click " .. elementName)
    return false
end

local function openShopWithNPC()
    local targetPosition = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    HRP.CFrame = targetPosition
    wait(2)
    
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(1)
    
    local prompt = findProximityPrompt(Sam)
    if prompt then
        for i = 1, 3 do
            fireproximityprompt(prompt)
            print("Attempt " .. i .. ": Fired ProximityPrompt on NPC Sam")
            wait(1)
            
            if SeedShopGUI.Visible then
                print("Shop opened successfully!")
                return true
            end
        end
    end
    
    local shopRemote = ReplicatedStorage:FindFirstChild("OpenShop") or ReplicatedStorage:FindFirstChild("OpenSeedShop")
    if shopRemote then
        shopRemote:FireServer()
        print("Used RemoteEvent to open shop")
        wait(2)
        return true
    end
    
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
    wait(1)
    
    prompt = findProximityPrompt(Sam)
    if prompt then
        fireproximityprompt(prompt)
        print("Fired ProximityPrompt from closer distance")
        wait(2)
        return true
    end
    
    print("Could not open shop with NPC Sam")
    return false
end

local function clickMainFrame(seedName)
    print("Looking for seed frame: " .. seedName)
    wait(1)
    
    local seedFrame = SeedShopGUI:FindFirstChild(seedName)
    if not seedFrame then
        for _, child in pairs(SeedShopGUI:GetChildren()) do
            if string.find(child.Name:lower(), seedName:lower()) then
                seedFrame = child
                print("Found similar seed frame: " .. child.Name)
                break
            end
        end
    end
    
    if not seedFrame then
        print("Could not find any matching seed frame")
        return false
    end
    
    local mainFrame = seedFrame:FindFirstChild("Main_Frame")
    if not mainFrame then
        for _, child in pairs(seedFrame:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("ImageButton") or child:IsA("Frame") then
                if child.Name:lower():find("main") or child.Name:lower():find("frame") then
                    mainFrame = child
                    print("Found alternative main frame: " .. child.Name)
                    break
                end
            end
        end
    end
    
    if mainFrame then
        print("Found Main_Frame, attempting to click...")
        return clickGUIElement(mainFrame, "Main_Frame for " .. seedName)
    else
        print("Main_Frame not found, trying to click seed frame directly")
        return clickGUIElement(seedFrame, "Seed frame " .. seedName)
    end
end

local function clickShecklesBuy(seedName)
    print("Looking for Sheckles_Buy button...")
    wait(1)
    
    local shecklesButton = nil
    local seedShopFrame = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame
    if seedShopFrame then
        shecklesButton = seedShopFrame:FindFirstChild("Sheckles_Buy", true)
        
        if not shecklesButton then
            for _, descendant in pairs(seedShopFrame:GetDescendants()) do
                if (descendant:IsA("TextButton") or descendant:IsA("ImageButton")) then
                    local nameLower = descendant.Name:lower()
                    if nameLower:find("sheckles") or nameLower:find("buy") or nameLower:find("purchase") then
                        shecklesButton = descendant
                        print("Found potential buy button: " .. descendant.Name)
                        break
                    end
                end
            end
        end
    end
    
    if shecklesButton then
        print("Found Sheckles_Buy button, attempting to click...")
        local success = clickGUIElement(shecklesButton, "Sheckles_Buy")
        if success then
            wait(0.5)
            return true
        end
    end
    
    local buyEvent = ReplicatedStorage.GameEvents:FindFirstChild("BuySeed") 
                    or ReplicatedStorage.GameEvents:FindFirstChild("BuySeedStock")
                    or ReplicatedStorage.GameEvents:FindFirstChild("PurchaseSeed")
    
    if buyEvent then
        print("Using direct RemoteEvent for purchase")
        local success, result = pcall(function()
            buyEvent:FireServer(seedName)
            return true
        end)
        return success
    end
    
    print("Sheckles_Buy button not found and no direct purchase method available")
    return false
end

local function buySeed(seedName)
    if isBuying then
        print("Already in buying process, please wait...")
        return false
    end
    
    isBuying = true
    local originalPosition = HRP.CFrame
    local success = false
    
    print("=== Starting purchase process for: " .. seedName .. " ===")
    
    print("Step 1: Opening shop with NPC Sam...")
    local shopOpened = openShopWithNPC()
    
    if shopOpened then
        print("Step 2: Clicking Main_Frame for " .. seedName .. "...")
        local mainFrameClicked = clickMainFrame(seedName)
        
        if mainFrameClicked then
            print("Step 3: Clicking Sheckles_Buy button...")
            success = clickShecklesBuy(seedName)
        else
            print("Failed to click Main_Frame, attempting direct purchase...")
            success = clickShecklesBuy(seedName)
        end
    else
        print("Failed to open shop, attempting direct purchase...")
        success = clickShecklesBuy(seedName)
    end
    
    wait(1)
    HRP.CFrame = originalPosition
    isBuying = false
    
    if success then
        print("=== Successfully purchased: " .. seedName .. " ===")
    else
        print("=== Failed to purchase: " .. seedName .. " ===")
    end
    
    return success
end

local function buyWantedCropSeeds()
    if #wantedFruits == 0 then
        print("No fruits selected to buy")
        return false
    end
    
    if isBuying then
        print("Already buying seeds, please wait...")
        return false
    end
    
    local boughtAny = false
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        print("Trying to buy "..fruitName..", stock: "..tostring(stock))
        
        if stock > 0 then
            for j = 1, math.min(stock, 5) do
                local success = buySeed(fruitName)
                if success then
                    boughtAny = true
                    print("✓ Successfully bought "..fruitName.." seed "..j.."/"..stock)
                    wait(2)
                else
                    print("✗ Failed to buy "..fruitName.." attempt "..j)
                    wait(1)
                end
            end
        else
            print("No stock for "..fruitName)
        end
    end
    
    return boughtAny
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
    wait(0.5)
    
    for _,plant in pairs(findPlayerFarm().Important.Plants_Physical:GetChildren()) do
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

local function GetAllPlants()
    local plantsTable = {}
    for _, Plant in pairs(playerFarm.Important.Plants_Physical:GetChildren()) do
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

local function CollectAllPlants()
    local plants = GetAllPlants()
    print("Got "..#plants.." Plants")
    
    for i = #plants, 2, -1 do
        local j = math.random(i)
        plants[i], plants[j] = plants[j], plants[i]
    end
    
    for _,plant in pairs(plants) do
        collectPlant(plant)
        task.wait(0.05)
    end
end

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
    task.wait(1)
    
    local edges = getPlantingBoundaries(playerFarm)
    
    while areThereSeeds() do
        print("There Are Seeds!")
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

local function getTimeInSeconds(input)
    if not input then return 0 end
    local minutes = tonumber(input:match("(%d+)m")) or 0
    local seconds = tonumber(input:match("(%d+)s")) or 0
    return minutes * 60 + seconds
end

local function sellAll()
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

local function onShopRefresh()
    print("Shop Refreshed")
    getCropsListAndStock()
    if wantedFruits and #wantedFruits > 0 and autoBuyEnabled then
        print("Auto-buying selected fruits...")
        wait(3)
        buyWantedCropSeeds()
    end
end

-- GUI Creation
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

Tab:CreateSection("Harvesting Plants")

Tab:CreateButton({
    Name = "Collect All Plants",
    Callback = function()
        CollectAllPlants()
        print("Collecting All Plants")
    end,
})

Tab:CreateToggle({
   Name = "Harvest Plants Aura",
   CurrentValue = false,
   Flag = "Toggle1",
   Callback = function(Value)
    plantAura = Value
    print("Plant Aura Set To: ".. tostring(Value))
   end,
})

Tab:CreateSection("Plant")
Tab:CreateButton({
    Name = "Plant all Seeds",
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

testingTab:CreateSection("Shop")
local RayFieldShopTimer = testingTab:CreateParagraph({Title = "Shop Timer", Content = "Waiting..."})

testingTab:CreateSection("Plot Corners")
testingTab:CreateButton({
    Name = "Teleport edges",
    Callback = function()
        local edges = getPlantingBoundaries(playerFarm)
        for i,v in pairs(edges) do
            HRP.CFrame = CFrame.new(v)
            wait(2)
        end
    end,
})

testingTab:CreateButton({
    Name = "Teleport random plantable position",
    Callback = function()
        HRP.CFrame = getRandomPlantingLocation(getPlantingBoundaries(playerFarm))
    end,
})

localPlayerTab = Window:CreateTab("LocalPlayer")
localPlayerTab:CreateButton({
    Name = "TP Wand",
    Callback = function()
        local mouse = Players.LocalPlayer:GetMouse()
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

local speedSlider = localPlayerTab:CreateSlider({
   Name = "Speed",
   Range = {1, 500},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = 20,
   Flag = "Slider1",
   Callback = function(Value)
        Humanoid.WalkSpeed = Value
   end,
})

localPlayerTab:CreateButton({
    Name = "Default Speed",
    Callback = function()
        speedSlider:Set(20)
    end,
})

local jumpSlider = localPlayerTab:CreateSlider({
   Name = "Jump Power",
   Range = {1, 500},
   Increment = 5,
   Suffix = "Jump Power",
   CurrentValue = 50,
   Flag = "Slider2",
   Callback = function(Value)
        Humanoid.JumpPower = Value
   end,
})

localPlayerTab:CreateButton({
    Name = "Default Jump Power",
    Callback = function()
        jumpSlider:Set(50)
    end,
})

local seedsTab = Window:CreateTab("Seeds")

local function refreshCropList()
    getCropsListAndStock()
    return getAllIFromDict(CropsListAndStocks)
end

seedsTab:CreateDropdown({
   Name = "Fruits To Buy",
   Options = refreshCropList(),
   CurrentOption = {"None Selected"},
   MultipleOptions = true,
   Flag = "Dropdown1", 
   Callback = function(Options)
        local filtered = {}
        for _, fruit in ipairs(Options) do
            if fruit ~= "None Selected" then
                table.insert(filtered, fruit)
            end
        end
        print("Selected fruits:", table.concat(filtered, ", "))
        wantedFruits = filtered
   end,
})

seedsTab:CreateButton({
    Name = "Refresh Fruit List",
    Callback = function()
        seedsTab:RefreshDropdown("Dropdown1", refreshCropList())
    end,
})

seedsTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(Value)
        autoBuyEnabled = Value
        print("Auto-Buy set to: "..tostring(Value))
        
        if Value and #wantedFruits > 0 then
            spawn(function()
                wait(2)
                buyWantedCropSeeds()
            end)
        end
    end,
})

seedsTab:CreateButton({
    Name = "Buy Selected Fruits Now",
    Callback = function()
        buyWantedCropSeeds()
    end,
})

local sellTab = Window:CreateTab("Sell")
sellTab:CreateToggle({
    Name = "Should Sell?",
    CurrentValue = false,
    flag = "Toggle2",
    Callback = function(Value)
        shouldSell = Value
    end,
})

sellTab:CreateSlider({
   Name = "Minimum Items to auto sell",
   Range = {1, 200},
   Increment = 1,
   Suffix = "Items",
   CurrentValue = 70,
   Flag = "Slider2",
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

-- Auto loops
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

spawn(function() 
    while true do
        if shopTimer and shopTimer.Text then
            shopTime = getTimeInSeconds(shopTimer.Text)
            local shopTimeText = "Shop Resets in " .. shopTime .. "s"
            RayFieldShopTimer:Set({Title = "Shop Timer", Content = shopTimeText})
            
            local isRefreshed = getCropsListAndStock()
            
            if isRefreshed and autoBuyEnabled and not isBuying then
                print("Shop refreshed, auto-buying...")
                onShopRefresh()
                wait(5)
            end
        end
        
        if shouldSell and #(Backpack:GetChildren()) >= AutoSellItems and not isSelling then
            sellAll()
        end
        
        wait(0.5)
    end
end)

-- Initialize
playerFarm = findPlayerFarm()
if not playerFarm then
    warn("Player farm not found!")
end

print("Grow A Garden script loaded successfully!")
print("Auto-buy system ready!")
print("Process: NPC Sam → ProximityPrompt → Main_Frame → Sheckles_Buy")
