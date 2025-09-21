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
    local playerFarm = findPlayerFarm()
    if not playerFarm then return {} end
    
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
    
    -- Shuffle the plants table to randomize collection order
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
    print("Seeds Not Found!")
    return false
end

local function plantAllSeeds()
    print("Planting All Seeds...")
    task.wait(1)
    
    local playerFarm = findPlayerFarm()
    if not playerFarm then 
        print("Farm not found!")
        return 
    end
    
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
        wait(0.5) -- Small delay to prevent infinite loop
    end
end

local function printCropStocks()
    print("=== SEED STOCK INFORMATION ===")
    for i,v in pairs(CropsListAndStocks) do
        print(i.."'s Stock Is:", v)
    end
    print("==============================")
end

local function getAllCropNames()
    local cropNames = {}
    for cropName, _ in pairs(CropsListAndStocks) do
        table.insert(cropNames, cropName)
    end
    table.sort(cropNames)
    return cropNames
end

local function openSeedShop()
    local humanoid = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    -- Simpan posisi awal
    local originalPosition = HRP.CFrame
    
    -- Pergi ke NPC Sam
    humanoid:MoveTo(Sam.HumanoidRootPart.Position + Vector3.new(0, 0, 5))
    
    -- Tunggu sampai sampai di dekat NPC
    local startTime = tick()
    while (HRP.Position - Sam.HumanoidRootPart.Position).Magnitude > 10 and tick() - startTime < 5 do
        wait(0.1)
    end
    
    -- Hadap ke NPC
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(0.5)
    
    -- Aktifkan prompt interaksi dengan NPC
    if Sam:FindFirstChild("Head") and Sam.Head:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(Sam.Head.ProximityPrompt)
        print("Berbicara dengan NPC Sam...")
        wait(1)
        
        -- Cek apakah toko seed terbuka
        if Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop") and 
           Players.LocalPlayer.PlayerGui.Seed_Shop.Enabled then
            print("Toko seed berhasil dibuka!")
            
            -- Ambil data stok seed terbaru
            getCropsListAndStock()
            return true
        end
    end
    
    -- Kembali ke posisi semula jika gagal
    HRP.CFrame = originalPosition
    print("Gagal membuka toko seed")
    return false
end

local function buyCropSeeds(cropName)
    if isBuying then
        print("Sedang dalam proses pembelian, tunggu sebentar...")
        return false
    end
    
    local args = {[1] = cropName}
    local success, errorMsg = pcall(function()
        BuySeedStock:FireServer(unpack(args))
    end)
    
    if not success then
        print("Error buying " .. cropName .. " seeds:", errorMsg)
        return false
    end
    
    print("Berhasil membeli seed: " .. cropName)
    return true
end

local function buyWantedCropSeeds()
    if #wantedFruits == 0 then
        print("Tidak ada seed yang dipilih untuk dibeli")
        return false
    end
    
    if isBuying then
        print("Sedang dalam proses pembelian, tunggu sebentar...")
        return false
    end
    
    isBuying = true
    
    -- Buka toko seed terlebih dahulu
    if not openSeedShop() then
        isBuying = false
        return false
    end
    
    -- Ambil data stok terbaru
    getCropsListAndStock()
    
    local boughtAny = false
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        print("Mencoba membeli " .. fruitName .. ", stok: " .. tostring(stock))
        
        if stock > 0 then
            for j = 1, stock do
                local success = buyCropSeeds(fruitName)
                if success then
                    boughtAny = true
                    print("Berhasil membeli " .. fruitName .. " seed " .. j .. "/" .. stock)
                else
                    print("Gagal membeli " .. fruitName)
                end
                wait(0.2) -- Tunggu sebentar antara pembelian
            end
        else
            print("Stok habis untuk " .. fruitName)
        end
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
end

-- Tab untuk informasi stok seed
local stockTab = Window:CreateTab("Seed Stock", "rbxassetid://4483345998")
stockTab:CreateSection("Informasi Stok Seed")

-- Paragraph untuk menampilkan informasi stok
local stockInfo = stockTab:CreateParagraph({
    Title = "Status Stok Seed",
    Content = "Klik 'Refresh Stock' untuk melihat stok terkini"
})

-- Button untuk refresh stok
stockTab:CreateButton({
    Name = "Refresh Stock",
    Callback = function()
        if openSeedShop() then
            getCropsListAndStock()
            local stockText = ""
            for cropName, stock in pairs(CropsListAndStocks) do
                stockText = stockText .. cropName .. ": " .. stock .. "\n"
            end
            stockInfo:Set({
                Title = "Stok Seed Terkini",
                Content = stockText
            })
            print("Stok seed berhasil diperbarui!")
        end
    end,
})

-- Button untuk mencetak stok di console
stockTab:CreateButton({
    Name = "Print Stock to Console",
    Callback = function()
        getCropsListAndStock()
        printCropStocks()
    end,
})

-- Tab untuk interaksi dengan NPC Sam
local npcTab = Window:CreateTab("NPC Sam", "rbxassetid://4483345998")
npcTab:CreateSection("Interaksi dengan NPC Sam")

npcTab:CreateButton({
    Name = "Buka Toko Seed",
    Callback = function()
        openSeedShop()
    end,
})

npcTab:CreateButton({
    Name = "Teleport ke NPC Sam",
    Callback = function()
        HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    end,
})

-- Tab untuk pembelian seed
local buyTab = Window:CreateTab("Beli Seed", "rbxassetid://4483345998")
buyTab:CreateSection("Pilihan Seed")

-- Dropdown untuk memilih seed yang ingin dibeli
local seedDropdown = buyTab:CreateDropdown({
   Name = "Pilih Seed untuk Dibeli",
   Options = {"Refresh dulu untuk melihat pilihan"},
   CurrentOption = {"None Selected"},
   MultipleOptions = true,
   Flag = "SeedDropdown", 
   Callback = function(Options)
        local filtered = {}
        for _, fruit in ipairs(Options) do
            if fruit ~= "None Selected" then
                table.insert(filtered, fruit)
            end
        end
        wantedFruits = filtered
        print("Seed yang dipilih: " .. table.concat(filtered, ", "))
   end,
})

-- Button untuk refresh pilihan seed
buyTab:CreateButton({
    Name = "Refresh Daftar Seed",
    Callback = function()
        if openSeedShop() then
            getCropsListAndStock()
            seedDropdown:Refresh(getAllCropNames())
            print("Daftar seed berhasil diperbarui!")
        end
    end,
})

-- Toggle untuk auto-buy
buyTab:CreateToggle({
    Name = "Auto-Buy Seed",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(Value)
        autoBuyEnabled = Value
        print("Auto-Buy diatur ke: " .. tostring(Value))
    end,
})

-- Button untuk membeli seed yang dipilih
buyTab:CreateButton({
    Name = "Beli Seed yang Dipilih",
    Callback = function()
        buyWantedCropSeeds()
    end,
})

-- Plants Tab
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

spawn(function()
    while true do
        if plantAura then
            local plants = GetAllPlants()
            
            -- Shuffle the plants table to randomize collection order
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

-- Testing Tab
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
        local playerFarm = findPlayerFarm()
        if playerFarm then
            local edges = getPlantingBoundaries(playerFarm)
            for i,v in pairs(edges) do
                HRP.CFrame = CFrame.new(v)
                wait(2)
            end
        end
    end,
})

testingTab:CreateButton({
    Name = "Teleport random plantable position",
    Callback = function()
        local playerFarm = findPlayerFarm()
        if playerFarm then
            HRP.CFrame = getRandomPlantingLocation(getPlantingBoundaries(playerFarm))
        end
    end,
})

-- LocalPlayer Tab
local localPlayerTab = Window:CreateTab("LocalPlayer")
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

-- Sell Tab
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

-- System untuk memantau refresh toko dan auto-buy
spawn(function() 
    while true do
        if shopTimer and shopTimer.Text then
            -- Update timer display jika diperlukan
            shopTime = getTimeInSeconds(shopTimer.Text)
            local shopTimeText = "Shop Resets in " .. shopTime .. "s"
            RayFieldShopTimer:Set({Title = "Shop Timer", Content = shopTimeText})
            
            -- Cek jika toko di-refresh
            local isRefreshed = getCropsListAndStock()
            
            if isRefreshed and autoBuyEnabled and not isBuying then
                print("Toko di-refresh, melakukan auto-buy...")
                wait(2)  -- Tunggu sebentar sebelum membeli
                buyWantedCropSeeds()
            end
        end
        
        if shouldSell and #(Backpack:GetChildren()) >= AutoSellItems and not isSelling then
            sellAll()
        end
        
        wait(0.5)
    end
end)

-- Inisialisasi awal
print("Grow A Garden script loaded successfully!")
