-- cekk
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
    wait(0.5) -- Wait for shovel to equip
    
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
    CropsListAndStocks = {} -- Reset the table
    for _,Plant in pairs(SeedShopGUI:GetChildren()) do
        if Plant:FindFirstChild("Main_Frame") and Plant.Main_Frame:FindFirstChild("Stock_Text") then
            local PlantName = Plant.Name
            local PlantStock = StripPlantStock(Plant.Main_Frame.Stock_Text.Text)
            CropsListAndStocks[PlantName] = PlantStock
        end
    end
    
    -- Cek jika stok berubah (toko di-refresh)
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

Tab:CreateButton({
    Name = "Collect All Plants",
    Callback = function()
        CollectAllPlants()
        print("Collecting All Plants")
    end,
})

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

Tab:CreateToggle({
   Name = "Harvest Plants Aura",
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

-- ============================ AUTO-BUY SYSTEM ============================

local function findButtonInFrame(frame)
    local button = frame:FindFirstChild("BuyButton") or frame:FindFirstChild("Buy") or frame:FindFirstChild("Purchase")
    if button then
        print("Found button: " .. button.Name)
        return button
    end
    
    local textButton = frame:FindFirstChildOfClass("TextButton")
    if textButton and (string.lower(textButton.Text):find("buy") or string.lower(textButton.Text):find("purchase")) then
        print("Found text button: " .. textButton.Text)
        return textButton
    end
    
    local imageButton = frame:FindFirstChildOfClass("ImageButton")
    if imageButton then
        print("Found image button")
        return imageButton
    end
    
    if frame:FindFirstChild("Main_Frame") then
        local mainFrame = frame.Main_Frame
        local mainButton = mainFrame:FindFirstChild("BuyButton") or mainFrame:FindFirstChildOfClass("TextButton") or mainFrame:FindFirstChildOfClass("ImageButton")
        if mainButton then
            print("Found button in Main_Frame: " .. mainButton.Name)
            return mainButton
        end
    end
    
    local function searchRecursive(obj)
        for _, child in pairs(obj:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("ImageButton") then
                if child.Name:lower():find("buy") or child.Name:lower():find("purchase") or 
                   (child:IsA("TextButton") and child.Text:lower():find("buy")) then
                    print("Found recursive button: " .. child.Name)
                    return child
                end
            end
            local result = searchRecursive(child)
            if result then return result end
        end
        return nil
    end
    
    local recursiveButton = searchRecursive(frame)
    if recursiveButton then
        return recursiveButton
    end
    
    print("No button found in frame")
    return nil
end

local function findBuyFrameTemplate(seedName)
    print("Searching for seed frame: " .. seedName)
    
    local targetFrame = SeedShopGUI:FindFirstChild(seedName)
    if targetFrame then
        print("Found frame directly: " .. seedName)
        local buyButton = findButtonInFrame(targetFrame)
        if buyButton then
            return buyButton
        end
    end
    
    for _, child in pairs(SeedShopGUI:GetChildren()) do
        if child:IsA("Frame") then
            if string.find(child.Name, seedName) then
                print("Found matching frame: " .. child.Name)
                local buyButton = findButtonInFrame(child)
                if buyButton then
                    return buyButton
                end
            end
        end
    end
    
    print("Frame not found for: " .. seedName)
    return nil
end

local function clickButton(button)
    print("Attempting to click button: " .. button.Name)
    
    local success1 = pcall(function()
        for _, connection in pairs(getconnections(button.MouseButton1Click)) do
            connection:Fire()
            print("Fired MouseButton1Click event")
            return true
        end
    end)
    
    if success1 then return true end
    
    local success2 = pcall(function()
        for _, connection in pairs(getconnections(button.MouseButton1Down)) do
            connection:Fire()
            print("Fired MouseButton1Down event")
            return true
        end
    end)
    
    if success2 then return true end
    
    local success3 = pcall(function()
        for _, connection in pairs(getconnections(button.Activated)) do
            connection:Fire()
            print("Fired Activated event")
            return true
        end
    end)
    
    if success3 then return true end
    
    local success4 = pcall(function()
        local clickDetector = button:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
            print("Fired ClickDetector")
            return true
        end
    end)
    
    if success4 then return true end
    
    local success5 = pcall(function()
        if button:IsA("TextButton") or button:IsA("ImageButton") then
            button:SetAttribute("LastClicked", tick())
            print("Set attribute for button")
            return true
        end
    end)
    
    local success6 = pcall(function()
        for _, child in pairs(button:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                child:FireServer()
                print("Fired RemoteEvent")
                return true
            end
        end
    end)
    
    return success1 or success2 or success3 or success4 or success5 or success6
end

local function buySeedUsingRemote(seedName)
    print("Attempting remote purchase for: " .. seedName)
    
    local success1, result1 = pcall(function()
        BuySeedStock:FireServer(seedName)
        return true
    end)
    
    if success1 then
        print("Remote purchase successful")
        return true
    end
    
    local success2, result2 = pcall(function()
        local alternativeRemote = ReplicatedStorage:FindFirstChild("PurchaseSeed") or 
                                 ReplicatedStorage:FindFirstChild("BuySeed") or
                                 ReplicatedStorage:FindFirstChild("SeedPurchase")
        if alternativeRemote then
            alternativeRemote:FireServer(seedName)
            return true
        end
    end)
    
    if success2 then
        print("Alternative remote purchase successful")
        return true
    end
    
    local success3, result3 = pcall(function()
        BuySeedStock:FireServer(seedName, 1)
        return true
    end)
    
    if success3 then
        print("Remote purchase with quantity successful")
        return true
    end
    
    print("All remote methods failed")
    return false
end

local function buyWithGUIButton(seedName, stock)
    local boughtCount = 0
    
    for i = 1, stock do
        local button = findBuyFrameTemplate(seedName)
        if button then
            local success = clickButton(button)
            if success then
                boughtCount = boughtCount + 1
                print("GUI Purchase " .. i .. "/" .. stock .. " SUCCESS")
                
                if CropsListAndStocks[seedName] then
                    CropsListAndStocks[seedName] = CropsListAndStocks[seedName] - 1
                end
            else
                print("GUI Purchase " .. i .. "/" .. stock .. " FAILED")
            end
        else
            print("Button not found for: " .. seedName)
            return boughtCount > 0
        end
        wait(0.2)
    end
    
    return boughtCount > 0
end

local function buyWithDirectRemote(seedName, stock)
    local boughtCount = 0
    
    for i = 1, stock do
        local success = buySeedUsingRemote(seedName)
        if success then
            boughtCount = boughtCount + 1
            print("Remote Purchase " .. i .. "/" .. stock .. " SUCCESS")
            
            if CropsListAndStocks[seedName] then
                CropsListAndStocks[seedName] = CropsListAndStocks[seedName] - 1
            end
        else
            print("Remote Purchase " .. i .. "/" .. stock .. " FAILED")
        end
        wait(0.2)
    end
    
    return boughtCount > 0
end

local function buyWithHybridMethod(seedName, stock)
    local boughtCount = 0
    
    for i = 1, stock do
        local button = findBuyFrameTemplate(seedName)
        local guiSuccess = false
        
        if button then
            guiSuccess = clickButton(button)
        end
        
        if not guiSuccess then
            guiSuccess = buySeedUsingRemote(seedName)
        end
        
        if guiSuccess then
            boughtCount = boughtCount + 1
            print("Hybrid Purchase " .. i .. "/" .. stock .. " SUCCESS")
            
            if CropsListAndStocks[seedName] then
                CropsListAndStocks[seedName] = CropsListAndStocks[seedName] - 1
            end
        else
            print("Hybrid Purchase " .. i .. "/" .. stock .. " FAILED")
        end
        wait(0.3)
    end
    
    return boughtCount > 0
end

function buyWantedCropSeeds()
    if #wantedFruits == 0 then
        print("No fruits selected to buy")
        return false
    end
    
    if isBuying then
        print("Already buying seeds, please wait...")
        return false
    end
    
    isBuying = true
    
    local beforePos = HRP.CFrame
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    wait(2)
    
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(1)
    
    local boughtAny = false
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        print("=== Buying "..fruitName.." ===")
        print("Stock available: "..tostring(stock))
        
        if stock > 0 then
            local purchaseMethods = {
                {"GUI Button Method", function() return buyWithGUIButton(fruitName, stock) end},
                {"Direct Remote Method", function() return buyWithDirectRemote(fruitName, stock) end},
                {"Hybrid Method", function() return buyWithHybridMethod(fruitName, stock) end}
            }
            
            for _, method in ipairs(purchaseMethods) do
                local methodName, methodFunc = method[1], method[2]
                print("Trying " .. methodName)
                local success, result = pcall(methodFunc)
                if success and result then
                    boughtAny = true
                    print(methodName .. " SUCCESS for " .. fruitName)
                    break
                else
                    print(methodName .. " FAILED for " .. fruitName)
                end
                wait(0.5)
            end
        else
            print("No stock for " .. fruitName)
        end
        wait(1)
    end
    
    wait(1)
    HRP.CFrame = beforePos
    
    isBuying = false
    print("=== Auto-buy session completed ===")
    return boughtAny
end

local function debugSeedShopGUI()
    print("=== DEBUG SEED SHOP GUI ===")
    print("SeedShopGUI children count: " .. #SeedShopGUI:GetChildren())
    
    for i, child in pairs(SeedShopGUI:GetChildren()) do
        print("Child " .. i .. ": " .. child.Name .. " (" .. child.ClassName .. ")")
        
        if child:IsA("Frame") then
            local buttons = {}
            for _, desc in pairs(child:GetDescendants()) do
                if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                    table.insert(buttons, {
                        Name = desc.Name,
                        Class = desc.ClassName,
                        Text = desc:IsA("TextButton") and desc.Text or "N/A"
                    })
                end
            end
            
            if #buttons > 0 then
                print("  Buttons found:")
                for _, btn in ipairs(buttons) do
                    print("    - " .. btn.Name .. " (" .. btn.Class .. ") Text: " .. btn.Text)
                end
            end
        end
    end
    print("=== END DEBUG ===")
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

local function refreshSeedOptions()
    return getAllIFromDict(CropsListAndStocks)
end

local seedDropdown = seedsTab:CreateDropdown({
   Name = "Fruits To Buy",
   Options = refreshSeedOptions(),
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
        print("Selected:", table.concat(filtered, ", "))
        wantedFruits = filtered
        print("Updated!")
   end,
})

seedsTab:CreateButton({
    Name = "Refresh Seed List",
    Callback = function()
        getCropsListAndStock()
        seedDropdown:Refresh(refreshSeedOptions())
        print("Seed list refreshed!")
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
                wait(1)
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

testingTab:CreateSection("Debug Tools")
testingTab:CreateButton({
    Name = "Debug Seed Shop GUI",
    Callback = function()
        debugSeedShopGUI()
    end,
})

testingTab:CreateButton({
    Name = "Test Single Seed Purchase",
    Callback = function()
        if #wantedFruits > 0 then
            local testSeed = wantedFruits[1]
            print("Testing purchase for: " .. testSeed)
            buyWithGUIButton(testSeed, 1)
        else
            print("No seeds selected")
        end
    end,
})

testingTab:CreateButton({
    Name = "Test All Purchase Methods",
    Callback = function()
        if #wantedFruits > 0 then
            local testSeed = wantedFruits[1]
            local stock = tonumber(CropsListAndStocks[testSeed] or 1)
            
            print("=== Testing All Methods ===")
            local methods = {
                {"GUI Method", buyWithGUIButton},
                {"Remote Method", buyWithDirectRemote},
                {"Hybrid Method", buyWithHybridMethod}
            }
            
            for _, method in ipairs(methods) do
                print("Testing: " .. method[1])
                local success = pcall(function()
                    return method[2](testSeed, math.min(stock, 1))
                end)
                print(method[1] .. " result: " .. tostring(success))
                wait(1)
            end
        end
    end,
})

local sellTab = Window:CreateTab("Sell")
sellTab:CreateToggle({
    Name = "Should Sell?",
    CurrentValue = false,
    flag = "Toggle2",
    Callback = function(Value)
        print("set shouldSell to: "..tostring(Value))
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
        print("AutoSellItems updated to: "..Value)
        AutoSellItems = Value
   end,
})

sellTab:CreateButton({
    Name = "Sell All Now",
    Callback = function()
        sellAll()
    end,
})

playerFarm = findPlayerFarm()
if not playerFarm then
    warn("Player farm not found!")
end

print("Grow A Garden script loaded successfully with enhanced auto-buy system!")
