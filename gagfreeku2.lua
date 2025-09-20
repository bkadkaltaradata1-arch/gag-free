-- v1ctambahkan menu disamping seed adalah stock seed dan bisa dibeli langsung
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

-- Variabel untuk Activity Monitor
local activeTasks = {}
local taskIdCounter = 0
local activityLogs = {}
local maxLogEntries = 50

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

-- Fungsi untuk Activity Monitor
local function addActivityLog(message, taskType)
    local timestamp = os.date("%H:%M:%S")
    local logEntry = "[" .. timestamp .. "] " .. message
    
    table.insert(activityLogs, 1, logEntry)
    
    -- Batasi jumlah entri log
    if #activityLogs > maxLogEntries then
        table.remove(activityLogs, #activityLogs)
    end
    
    -- Update UI jika sudah dibuat
    if activityMonitorParagraph then
        activityMonitorParagraph:Set({
            Title = "Activity Logs",
            Content = table.concat(activityLogs, "\n")
        })
    end
    
    print(logEntry)
end

local function startTask(taskName, taskType)
    taskIdCounter = taskIdCounter + 1
    local taskId = taskIdCounter
    
    activeTasks[taskId] = {
        name = taskName,
        type = taskType,
        startTime = os.time(),
        status = "Running"
    }
    
    addActivityLog("Started: " .. taskName, taskType)
    
    -- Update task list UI jika sudah dibuat
    updateTaskListUI()
    
    return taskId
end

local function endTask(taskId, status)
    if activeTasks[taskId] then
        local task = activeTasks[taskId]
        local duration = os.time() - task.startTime
        
        task.status = status or "Completed"
        task.endTime = os.time()
        task.duration = duration
        
        addActivityLog("Finished: " .. task.name .. " (" .. status .. ", " .. duration .. "s)", task.type)
        
        -- Update task list UI jika sudah dibuat
        updateTaskListUI()
        
        -- Hapus task setelah beberapa saat
        delay(10, function()
            activeTasks[taskId] = nil
            updateTaskListUI()
        end)
    end
end

local function updateTaskListUI()
    if taskListParagraph then
        local taskLines = {}
        
        for id, task in pairs(activeTasks) do
            local duration = task.duration or (os.time() - task.startTime)
            local statusText = task.status == "Running" and "RUNNING" or task.status
            table.insert(taskLines, string.format("[%s] %s - %s (%ds)", 
                task.type, task.name, statusText, duration))
        end
        
        if #taskLines == 0 then
            table.insert(taskLines, "No active tasks")
        end
        
        taskListParagraph:Set({
            Title = "Active Tasks",
            Content = table.concat(taskLines, "\n")
        })
    end
end

local function findPlayerFarm()
    local taskId = startTask("Finding Player Farm", "INFO")
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important.Data.Owner.Value == Players.LocalPlayer.Name then
            endTask(taskId, "Completed")
            return v
        end
    end
    endTask(taskId, "Failed")
    return nil
end

local function removePlantsOfKind(kind)
    if not kind or kind[1] == "None Selected" then
        addActivityLog("No plant selected to remove", "WARNING")
        return
    end
    
    local taskId = startTask("Removing plants: " .. kind[1], "ACTION")
    
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]") or Backpack:FindFirstChild("Shovel")
    
    if not Shovel then
        addActivityLog("Shovel not found in backpack", "ERROR")
        endTask(taskId, "Failed")
        return
    end
    
    Shovel.Parent = Character
    wait(0.5) -- Wait for shovel to equip
    
    local removedCount = 0
    for _,plant in pairs(findPlayerFarm().Important.Plants_Physical:GetChildren()) do
        if plant.Name == kind[1] then
            if plant:FindFirstChild("Fruit_Spawn") then
                local spawnPoint = plant.Fruit_Spawn
                HRP.CFrame = plant.PrimaryPart.CFrame
                wait(0.2)
                removeItem:FireServer(spawnPoint)
                removedCount = removedCount + 1
                wait(0.1)
            end
        end
    end 
    
    -- Return shovel to backpack
    if Shovel and Shovel.Parent == Character then
        Shovel.Parent = Backpack
    end
    
    addActivityLog("Removed " .. removedCount .. " plants of type: " .. kind[1], "SUCCESS")
    endTask(taskId, "Completed")
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

-- Fungsi yang diperbarui untuk membaca stok dari UI baru
function getCropsListAndStock()
    local taskId = startTask("Reading crop stocks", "INFO")
    local oldStock = CropsListAndStocks
    CropsListAndStocks = {} -- Reset the table
    
    for _, Plant in pairs(SeedShopGUI:GetChildren()) do
        if Plant:FindFirstChild("Main_Frame") then
            local PlantName = Plant.Name
            
            -- Mencari teks stok di UI baru
            local stockText = nil
            
            -- Cari di berbagai kemungkinan lokasi teks stok
            if Plant.Main_Frame:FindFirstChild("Stock_Text") then
                stockText = Plant.Main_Frame.Stock_Text.Text
            elseif Plant.Main_Frame:FindFirstChild("StockText") then
                stockText = Plant.Main_Frame.StockText.Text
            elseif Plant.Main_Frame:FindFirstChild("Stock") then
                stockText = Plant.Main_Frame.Stock.Text
            else
                -- Cari child yang mengandung teks "Stock"
                for _, child in pairs(Plant.Main_Frame:GetChildren()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        if string.find(child.Text, "Stock") or string.find(child.Text, "x%d") then
                            stockText = child.Text
                            break
                        end
                    end
                end
            end
            
            if stockText then
                local PlantStock = StripPlantStock(stockText)
                CropsListAndStocks[PlantName] = PlantStock
            end
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
    
    endTask(taskId, "Completed")
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
    -- Fixed collection method using proximity prompts instead of byteNetReliable
    if plant:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(plant.ProximityPrompt)
    else
        -- Check children for proximity prompts
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
    local taskId = startTask("Collecting all plants", "ACTION")
    local plants = GetAllPlants()
    addActivityLog("Found "..#plants.." Plants", "INFO")
    
    -- Shuffle the plants table to randomize collection order
    for i = #plants, 2, -1 do
        local j = math.random(i)
        plants[i], plants[j] = plants[j], plants[i]
    end
    
    local collected = 0
    for _,plant in pairs(plants) do
        collectPlant(plant)
        collected = collected + 1
        task.wait(0.05)
    end
    
    addActivityLog("Collected " .. collected .. " plants", "SUCCESS")
    endTask(taskId, "Completed")
end

Tab:CreateButton({
    Name = "Collect All Plants",
    Callback = function()
        CollectAllPlants()
    end,
})

spawn(function()
    while true do
        if plantAura then
            local plants = GetAllPlants()
            
            -- Shuffle the plants table to randomize collection order
            for i = #plants, 2, -1 do
                local j = math.random(i)
                plants[i], plants[j] = plants[j], plants[i]
            end
            
            local collected = 0
            for _, plant in pairs(plants) do
                if plant:FindFirstChild("Fruits") then
                    for _, miniPlant in pairs(plant.Fruits:GetChildren()) do
                        for _, child in pairs(miniPlant:GetChildren()) do
                            if child:FindFirstChild("ProximityPrompt") then
                                fireproximityprompt(child.ProximityPrompt)
                                collected = collected + 1
                            end
                        end
                        task.wait(0.01)
                    end
                else
                    for _, child in pairs(plant:GetChildren()) do
                        if child:FindFirstChild("ProximityPrompt") then
                            fireproximityprompt(child.ProximityPrompt)
                            collected = collected + 1
                        end
                        task.wait(0.01)
                    end
                end
            end
            
            if collected > 0 then
                addActivityLog("Plant Aura collected " .. collected .. " items", "INFO")
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

    -- Add some randomness to the Y position as well
    local randY = Y + (math.random() * 0.1 - 0.05) -- Small random variation
    
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
    addActivityLog("Seeds Not Found!", "WARNING")
    return false
end

local function plantAllSeeds()
    local taskId = startTask("Planting all seeds", "ACTION")
    addActivityLog("Planting All Seeds...", "INFO")
    task.wait(1)
    
    local edges = getPlantingBoundaries(playerFarm)
    local planted = 0
    
    while areThereSeeds() do
        addActivityLog("There Are Seeds!", "INFO")
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
                planted = planted + 1
                wait(0.1)
                if Item and Item:IsDescendantOf(game) and Item.Parent ~= Backpack then
                    pcall(function()
                        Item.Parent = Backpack
                    end)
                end
            end
        end
        wait(0.5) -- Small delay to prevent infinite loop
    end
    
    addActivityLog("Planted " .. planted .. " seeds", "SUCCESS")
    endTask(taskId, "Completed")
end

Tab:CreateToggle({
   Name = "Harvest Plants Aura",
   CurrentValue = false,
   Flag = "Toggle1",
   Callback = function(Value)
    plantAura = Value
    addActivityLog("Plant Aura Set To: " .. tostring(Value), "SETTING")
   end,
})

local testingTab = Window:CreateTab("Testing","rewind")
testingTab:CreateSection("List Crops Names And Prices")
testingTab:CreateButton({
    Name = "Print Out All Crops Names And Stocks",
    Callback = function()
        printCropStocks()
        addActivityLog("Printed crop stocks to console", "INFO")
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
        addActivityLog("Auto Plant Set To: " .. tostring(Value), "SETTING")
    end,
})

testingTab:CreateSection("Shop")
local RayFieldShopTimer = testingTab:CreateParagraph({Title = "Shop Timer", Content = "Waiting..."})

testingTab:CreateSection("Plot Corners")
testingTab:CreateButton({
    Name = "Teleport edges",
    Callback = function()
        local taskId = startTask("Teleporting to plot edges", "ACTION")
        local edges = getPlantingBoundaries(playerFarm)
        for i,v in pairs(edges) do
            HRP.CFrame = CFrame.new(v)
            wait(2)
        end
        endTask(taskId, "Completed")
    end,
})

testingTab:CreateButton({
    Name = "Teleport random plantable position",
    Callback = function()
        local taskId = startTask("Teleporting to random position", "ACTION")
        HRP.CFrame = getRandomPlantingLocation(getPlantingBoundaries(playerFarm))
        endTask(taskId, "Completed")
    end,
})

local function buyCropSeeds(cropName)
    local args = {[1] = cropName}
    local success, errorMsg = pcall(function()
        BuySeedStock:FireServer(unpack(args))
    end)
    
    if not success then
        addActivityLog("Error buying seeds: " .. errorMsg, "ERROR")
        return false
    end
    return true
end

-- Fungsi yang diperbarui untuk membeli seed berdasarkan UI baru
function buyWantedCropSeeds()
    if #wantedFruits == 0 then
        addActivityLog("No fruits selected to buy", "WARNING")
        return false
    end
    
    if isBuying then
        addActivityLog("Already buying seeds, please wait...", "WARNING")
        return false
    end
    
    local taskId = startTask("Buying selected seeds: " .. table.concat(wantedFruits, ", "), "ACTION")
    isBuying = true
    
    local beforePos = HRP.CFrame
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    -- Pastikan karakter bisa bergerak
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    -- Pergi ke NPC Sam
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4) -- Berdiri di depan NPC
    wait(1.5) -- Tunggu sampai sampai di lokasi
    
    -- Pastikan kita menghadap ke NPC
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(0.5)
    
    local boughtAny = false
    local totalBought = 0
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        addActivityLog("Trying to buy "..fruitName..", stock: "..tostring(stock), "INFO")
        
        if stock > 0 then
            for j = 1, stock do
                local success = buyCropSeeds(fruitName)
                if success then
                    boughtAny = true
                    totalBought = totalBought + 1
                    addActivityLog("Bought "..fruitName.." seed "..j.."/"..stock, "SUCCESS")
                else
                    addActivityLog("Failed to buy "..fruitName, "ERROR")
                    break
                end
                wait(0.2) -- Tunggu sebentar antara pembelian
            end
        else
            addActivityLog("No stock for "..fruitName, "WARNING")
        end
    end
    
    -- Kembali ke posisi semula
    wait(0.5)
    HRP.CFrame = beforePos
    
    isBuying = false
    
    if boughtAny then
        addActivityLog("Successfully bought " .. totalBought .. " seeds", "SUCCESS")
        endTask(taskId, "Completed")
    else
        addActivityLog("No seeds were purchased", "WARNING")
        endTask(taskId, "Failed")
    end
    
    return boughtAny
end

local function onShopRefresh()
    addActivityLog("Shop Refreshed", "INFO")
    getCropsListAndStock()
    if wantedFruits and #wantedFruits > 0 and autoBuyEnabled then
        addActivityLog("Auto-buying selected fruits...", "INFO")
        
        -- Tunggu sebentar sebelum membeli untuk memastikan UI sudah update
        wait(2)
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
    local taskId = startTask("Selling all items", "ACTION")
    local OrgPos = HRP.CFrame
    HRP.CFrame = Steven.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4) -- Berdiri di depan NPC
    wait(1.5)
    
    isSelling = true
    sellAllRemote:FireServer()
    
    -- Wait until items are sold
    local startTime = tick()
    while #Backpack:GetChildren() >= AutoSellItems and tick() - startTime < 10 do
        sellAllRemote:FireServer()
        wait(0.5)
    end
    
    HRP.CFrame = OrgPos
    isSelling = false
    
    addActivityLog("Sold all items", "SUCCESS")
    endTask(taskId, "Completed")
end

spawn(function() 
    while true do
        if shopTimer and shopTimer.Text then
            shopTime = getTimeInSeconds(shopTimer.Text)
            local shopTimeText = "Shop Resets in " .. shopTime .. "s"
            RayFieldShopTimer:Set({Title = "Shop Timer", Content = shopTimeText})
            
            -- Cek jika toko di-refresh dengan membandingkan stok
            local isRefreshed = getCropsListAndStock()
            
            if isRefreshed and autoBuyEnabled and not isBuying then
                addActivityLog("Shop refreshed, auto-buying...", "INFO")
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
        local taskId = startTask("Creating TP Wand", "ACTION")
        local mouse = Players.LocalPlayer:GetMouse()
        local TPWand = Instance.new("Tool", Backpack)
        TPWand.Name = "TP Wand"
        TPWand.RequiresHandle = false
        mouse.Button1Down:Connect(function()
            if Character:FindFirstChild("TP Wand") then
                HRP.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
                addActivityLog("Teleported using TP Wand", "INFO")
            end
        end)
        addActivityLog("TP Wand created", "SUCCESS")
        endTask(taskId, "Completed")
    end,    
})

localPlayerTab:CreateButton({
    Name = "Destroy TP Wand",
    Callback = function()
        local taskId = startTask("Destroying TP Wand", "ACTION")
        if Backpack:FindFirstChild("TP Wand") then
            Backpack:FindFirstChild("TP Wand"):Destroy()
        end
        if Character:FindFirstChild("TP Wand") then
            Character:FindFirstChild("TP Wand"):Destroy()
        end
        addActivityLog("TP Wand destroyed", "SUCCESS")
        endTask(taskId, "Completed")
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
        addActivityLog("Walk speed set to: " .. Value, "SETTING")
   end,
})

localPlayerTab:CreateButton({
    Name = "Default Speed",
    Callback = function()
        speedSlider:Set(20)
        addActivityLog("Walk speed reset to default", "SETTING")
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
        addActivityLog("Jump power set to: " .. Value, "SETTING")
   end,
})

localPlayerTab:CreateButton({
    Name = "Default Jump Power",
    Callback = function()
        jumpSlider:Set(50)
        addActivityLog("Jump power reset to default", "SETTING")
    end,
})

local seedsTab = Window:CreateTab("Seeds")
seedsTab:CreateDropdown({
   Name = "Fruits To Buy",
   Options = getAllIFromDict(CropsListAndStocks),
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
        addActivityLog("Selected fruits: " .. table.concat(filtered, ", "), "SETTING")
        wantedFruits = filtered
   end,
})

-- Tambahkan toggle untuk enable/disable auto-buy
seedsTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(Value)
        autoBuyEnabled = Value
        addActivityLog("Auto-Buy set to: " .. tostring(Value), "SETTING")
        
        -- Jika diaktifkan, langsung coba beli
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

-- Tambahkan section Stock Seed di samping menu Seeds
local stockSeedTab = Window:CreateTab("Stock Seed", "shopping-cart") -- Icon shopping-cart untuk tab Stock Seed

stockSeedTab:CreateSection("Stock Seed Information")

-- Function untuk mendapatkan informasi stok seed
local function getSeedStockInfo()
    local stockInfo = {}
    for cropName, stock in pairs(CropsListAndStocks) do
        table.insert(stockInfo, cropName .. ": " .. stock)
    end
    return stockInfo
end

-- Display stock information
local stockInfoParagraph = stockSeedTab:CreateParagraph({
    Title = "Current Seed Stocks",
    Content = table.concat(getSeedStockInfo(), "\n")
})

-- Refresh stock info button
stockSeedTab:CreateButton({
    Name = "Refresh Stock Info",
    Callback = function()
        getCropsListAndStock()
        stockInfoParagraph:Set({
            Title = "Current Seed Stocks",
            Content = table.concat(getSeedStockInfo(), "\n")
        })
        addActivityLog("Refreshed seed stock info", "INFO")
    end,
})

-- Direct purchase section
stockSeedTab:CreateSection("Direct Purchase")

-- Dropdown untuk memilih seed yang ingin dibeli
local seedPurchaseDropdown = stockSeedTab:CreateDropdown({
    Name = "Select Seed to Purchase",
    Options = getAllIFromDict(CropsListAndStocks),
    CurrentOption = {"None Selected"},
    MultipleOptions = false,
    Flag = "SeedPurchaseDropdown",
    Callback = function(Option)
        -- Callback ketika seed dipilih
    end,
})

-- Slider untuk jumlah pembelian
local purchaseAmountSlider = stockSeedTab:CreateSlider({
    Name = "Purchase Amount",
    Range = {1, 100},
    Increment = 1,
    Suffix = "seeds",
    CurrentValue = 1,
    Flag = "PurchaseAmountSlider",
    Callback = function(Value)
        -- Callback ketika jumlah diubah
    end,
})

-- Tombol untuk membeli seed
stockSeedTab:CreateButton({
    Name = "Purchase Selected Seed",
    Callback = function()
        local selectedSeed = seedPurchaseDropdown.CurrentOption[1]
        local amount = purchaseAmountSlider.CurrentValue
        
        if selectedSeed and selectedSeed ~= "None Selected" then
            -- Pergi ke NPC Sam
            local beforePos = HRP.CFrame
            HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
            wait(1.5)
            
            -- Beli seed sebanyak amount
            local bought = 0
            for i = 1, amount do
                local success = buyCropSeeds(selectedSeed)
                if success then
                    bought = bought + 1
                    addActivityLog("Purchased " .. selectedSeed .. " seed " .. i .. "/" .. amount, "SUCCESS")
                else
                    addActivityLog("Failed to purchase " .. selectedSeed, "ERROR")
                    break
                end
                wait(0.2)
            end
            
            -- Kembali ke posisi semula
            HRP.CFrame = beforePos
            
            -- Refresh stock info
            getCropsListAndStock()
            stockInfoParagraph:Set({
                Title = "Current Seed Stocks",
                Content = table.concat(getSeedStockInfo(), "\n")
            })
            
            addActivityLog("Purchased " .. bought .. " " .. selectedSeed .. " seeds", "SUCCESS")
        else
            addActivityLog("Please select a seed to purchase", "WARNING")
        end
    end,
})

-- Auto-purchase section
stockSeedTab:CreateSection("Auto Purchase Settings")

-- Toggle untuk auto-purchase
local autoPurchaseToggle = stockSeedTab:CreateToggle({
    Name = "Enable Auto-Purchase",
    CurrentValue = false,
    Flag = "AutoPurchaseToggle",
    Callback = function(Value)
        addActivityLog("Auto-Purchase set to: " .. tostring(Value), "SETTING")
    end,
})

-- Dropdown untuk memilih seed yang ingin di-auto-purchase
local autoPurchaseDropdown = stockSeedTab:CreateDropdown({
    Name = "Seed for Auto-Purchase",
    Options = getAllIFromDict(CropsListAndStocks),
    CurrentOption = {"None Selected"},
    MultipleOptions = false,
    Flag = "AutoPurchaseDropdown",
    Callback = function(Option)
        addActivityLog("Auto-Purchase seed set to: " .. Option[1], "SETTING")
    end,
})

-- Slider untuk threshold stok
local stockThresholdSlider = stockSeedTab:CreateSlider({
    Name = "Stock Threshold for Auto-Purchase",
    Range = {1, 50},
    Increment = 1,
    Suffix = "seeds",
    CurrentValue = 5,
    Flag = "StockThresholdSlider",
    Callback = function(Value)
        addActivityLog("Auto-Purchase threshold set to: " .. Value, "SETTING")
    end,
})

-- Fungsi untuk auto-purchase
local function autoPurchaseCheck()
    if not autoPurchaseToggle.CurrentValue then return end
    if autoPurchaseDropdown.CurrentOption[1] == "None Selected" then return end
    
    local selectedSeed = autoPurchaseDropdown.CurrentOption[1]
    local threshold = stockThresholdSlider.CurrentValue
    local currentStock = tonumber(CropsListAndStocks[selectedSeed] or 0)
    
    if currentStock >= threshold then
        addActivityLog("Auto-purchasing " .. selectedSeed .. " (Stock: " .. currentStock .. ")", "INFO")
        
        -- Pergi ke NPC Sam
        local beforePos = HRP.CFrame
        HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
        wait(1.5)
        
        -- Beli seed sebanyak stok yang tersedia
        local bought = 0
        for i = 1, currentStock do
            local success = buyCropSeeds(selectedSeed)
            if success then
                bought = bought + 1
                addActivityLog("Auto-purchased " .. selectedSeed .. " seed " .. i .. "/" .. currentStock, "SUCCESS")
            else
                addActivityLog("Failed to auto-purchase " .. selectedSeed, "ERROR")
                break
            end
            wait(0.2)
        end
        
        -- Kembali ke posisi semula
        HRP.CFrame = beforePos
        
        -- Refresh stock info
        getCropsListAndStock()
        stockInfoParagraph:Set({
            Title = "Current Seed Stocks",
            Content = table.concat(getSeedStockInfo(), "\n")
        })
        
        addActivityLog("Auto-purchased " .. bought .. " " .. selectedSeed .. " seeds", "SUCCESS")
    end
end

-- Jalankan auto-purchase check setiap 5 detik
spawn(function()
    while true do
        autoPurchaseCheck()
        wait(5)
    end
end)

local sellTab = Window:CreateTab("Sell")
sellTab:CreateToggle({
    Name = "Should Sell?",
    CurrentValue = false,
    flag = "Toggle2",
    Callback = function(Value)
        addActivityLog("Auto-Sell set to: " .. tostring(Value), "SETTING")
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
        addActivityLog("Auto-Sell threshold set to: " .. Value, "SETTING")
        AutoSellItems = Value
   end,
})

sellTab:CreateButton({
    Name = "Sell All Now",
    Callback = function()
        sellAll()
    end,
})

-- Tambahkan menu Activity Monitor
local activityTab = Window:CreateTab("Activity Monitor", "bar-chart-2")

activityTab:CreateSection("Active Tasks")
taskListParagraph = activityTab:CreateParagraph({
    Title = "Active Tasks",
    Content = "No active tasks"
})

activityTab:CreateSection("Activity Logs")
activityMonitorParagraph = activityTab:CreateParagraph({
    Title = "Activity Logs",
    Content = "Activity logs will appear here"
})

activityTab:CreateButton({
    Name = "Clear Logs",
    Callback = function()
        activityLogs = {}
        activityMonitorParagraph:Set({
            Title = "Activity Logs",
            Content = "Logs cleared"
        })
        addActivityLog("Activity logs cleared", "INFO")
    end,
})

activityTab:CreateSlider({
    Name = "Max Log Entries",
    Range = {10, 100},
    Increment = 5,
    Suffix = "entries",
    CurrentValue = 50,
    Flag = "MaxLogEntries",
    Callback = function(Value)
        maxLogEntries = Value
        addActivityLog("Max log entries set to: " .. Value, "SETTING")
    end,
})

-- Initialize the player farm reference
playerFarm = findPlayerFarm()
if not playerFarm then
    warn("Player farm not found!")
end

addActivityLog("Grow A Garden script loaded successfully!", "SUCCESS")
print("Grow A Garden script loaded successfully!")
