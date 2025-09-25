local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmsFolder = Workspace.Farm
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
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

-- Variabel untuk anti-AFK
local antiAFKEnabled = false
local lastPosition = HRP.Position
local afkCheckInterval = 30 -- detik
local lastMovementCheck = tick()

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

-- Fungsi untuk cek apakah toko berhasil terbuka
local function isShopOpen()
    local playerGui = Players.LocalPlayer.PlayerGui
    local possibleShopGUIs = {
        "SeedShop",
        "Seed_Shop", 
        "ShopGUI",
        "SamShop",
        "PlantShop",
        "SeedStore",
        "ShopFrame",
        "MainShop"
    }
    
    for _, guiName in pairs(possibleShopGUIs) do
        local gui = playerGui:FindFirstChild(guiName)
        if gui and gui.Enabled then
            return true, guiName
        end
        
        -- Cek juga di children yang lebih dalam
        for _, child in pairs(playerGui:GetDescendants()) do
            if child:IsA("GuiObject") and child.Visible and child.Name:lower():find("shop") then
                return true, child.Name
            end
        end
    end
    return false, nil
end

-- Fungsi untuk membuka toko NPC SAM yang lebih efektif dengan debug info
local function openSamShop()
    if not Sam or not Sam:FindFirstChild("HumanoidRootPart") then
        print("❌ NPC Sam tidak ditemukan!")
        return false, "NPC not found"
    end
    
    print("🚀 Memulai proses membuka toko Sam...")
    
    -- Simpan posisi awal
    local originalPosition = HRP.CFrame
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    -- Pastikan karakter bisa bergerak
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    print("📍 Menuju ke NPC Sam...")
    
    -- Pergi ke NPC Sam dengan jarak yang tepat
    local targetCFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    HRP.CFrame = targetCFrame
    wait(2) -- Tunggu sampai karakter sampai
    
    -- Pastikan menghadap ke NPC
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(0.5)
    
    local successfulMethod = nil
    local methodDetails = ""
    
    -- Method 1: Cari dan trigger ProximityPrompt
    print("🔍 Mencoba Method 1: ProximityPrompt...")
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and (obj.Parent.Position - Sam.HumanoidRootPart.Position).Magnitude < 10 then
            print("   ✅ Found ProximityPrompt: " .. obj.Parent.Name)
            fireproximityprompt(obj)
            successfulMethod = 1
            methodDetails = "ProximityPrompt pada " .. obj.Parent.Name
            wait(1)
            break
        end
    end
    
    -- Cek jika Method 1 berhasil
    if successfulMethod then
        local isOpen, guiName = isShopOpen()
        if isOpen then
            print("🎉 METHOD 1 BERHASIL! Toko terbuka dengan: " .. methodDetails)
            wait(3)
            -- Tutup toko
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
            wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
            HRP.CFrame = originalPosition
            return true, successfulMethod
        else
            print("❌ Method 1 gagal, mencoba method berikutnya...")
            successfulMethod = nil
        end
    end
    
    -- Method 2: Coba ClickDetector
    print("🔍 Mencoba Method 2: ClickDetector...")
    for _, child in pairs(Sam:GetDescendants()) do
        if child:IsA("ClickDetector") then
            print("   ✅ Found ClickDetector")
            fireclickdetector(child)
            successfulMethod = 2
            methodDetails = "ClickDetector pada NPC Sam"
            wait(1)
            break
        end
    end
    
    -- Cek jika Method 2 berhasil
    if successfulMethod then
        local isOpen, guiName = isShopOpen()
        if isOpen then
            print("🎉 METHOD 2 BERHASIL! Toko terbuka dengan: " .. methodDetails)
            wait(3)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
            wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
            HRP.CFrame = originalPosition
            return true, successfulMethod
        else
            print("❌ Method 2 gagal, mencoba method berikutnya...")
            successfulMethod = nil
        end
    end
    
    -- Method 3: Coba Remote Events khusus
    print("🔍 Mencoba Method 3: Remote Events...")
    local remoteEvents = {
        "OpenShop",
        "OpenSeedShop", 
        "OpenSamShop",
        "ToggleShop",
        "PromptTriggered",
        "InteractNPC"
    }
    
    for i, eventName in pairs(remoteEvents) do
        local remote = ReplicatedStorage:FindFirstChild(eventName) or 
                      ReplicatedStorage.GameEvents:FindFirstChild(eventName) or
                      ReplicatedStorage.Remotes:FindFirstChild(eventName)
        if remote then
            print("   ✅ Trying remote event: " .. eventName)
            pcall(function()
                remote:FireServer("Sam")
                successfulMethod = 3
                methodDetails = "RemoteEvent: " .. eventName
            end)
            wait(1)
            
            -- Cek jika berhasil
            local isOpen, guiName = isShopOpen()
            if isOpen then
                print("🎉 METHOD 3 BERHASIL! Toko terbuka dengan: " .. methodDetails)
                wait(3)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
                wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
                HRP.CFrame = originalPosition
                return true, successfulMethod
            else
                print("❌ Remote event " .. eventName .. " gagal")
            end
        end
    end
    
    -- Method 4: Coba interact dengan part khusus
    print("🔍 Mencoba Method 4: Shop Parts...")
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("Part") and (part.Name:lower():find("shop") or part.Name:lower():find("npc")) and 
           (part.Position - Sam.HumanoidRootPart.Position).Magnitude < 15 then
            print("   ✅ Found shop part: " .. part.Name)
            HRP.CFrame = part.CFrame * CFrame.new(0, 0, 3)
            wait(1)
            
            -- Coba klik part tersebut
            if part:FindFirstChildOfClass("ClickDetector") then
                fireclickdetector(part:FindFirstChildOfClass("ClickDetector"))
                successfulMethod = 4
                methodDetails = "Shop Part: " .. part.Name
                wait(1)
            end
            
            -- Cek jika berhasil
            local isOpen, guiName = isShopOpen()
            if isOpen then
                print("🎉 METHOD 4 BERHASIL! Toko terbuka dengan: " .. methodDetails)
                wait(3)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
                wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
                HRP.CFrame = originalPosition
                return true, successfulMethod
            else
                print("❌ Method 4 gagal, mencoba method berikutnya...")
                successfulMethod = nil
            end
            break
        end
    end
    
    -- Method 5: Gunakan TouchInterest sebagai last resort
    print("🔍 Mencoba Method 5: Touch Interest...")
    local partsToTouch = {}
    for _, part in pairs(Sam:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(partsToTouch, part)
        end
    end
    
    -- Juga cari part di sekitar Sam
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and (part.Position - Sam.HumanoidRootPart.Position).Magnitude < 10 then
            if not table.find(partsToTouch, part) then
                table.insert(partsToTouch, part)
            end
        end
    end
    
    for i, part in pairs(partsToTouch) do
        print("   ✅ Touching part " .. i .. ": " .. part.Name)
        HRP.CFrame = part.CFrame * CFrame.new(0, 0, 2)
        wait(0.5)
    end
    
    successfulMethod = 5
    methodDetails = "Touch Interest pada " .. #partsToTouch .. " parts"
    wait(2)
    
    -- Cek jika Method 5 berhasil
    local isOpen, guiName = isShopOpen()
    if isOpen then
        print("🎉 METHOD 5 BERHASIL! Toko terbuka dengan: " .. methodDetails)
        wait(3)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
        wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
        HRP.CFrame = originalPosition
        return true, successfulMethod
    else
        print("❌ Method 5 juga gagal")
        successfulMethod = nil
    end
    
    -- Jika semua method gagal
    print("💥 SEMUA METHOD GAGAL! Tidak bisa membuka toko Sam")
    HRP.CFrame = originalPosition
    return false, "All methods failed"
end

-- Fungsi anti-AFK yang lebih advanced
local function antiAFKAction()
    if not antiAFKEnabled or not Character or not HRP then return end
    
    local currentTime = tick()
    local currentPosition = HRP.Position
    
    -- Cek jika karakter tidak bergerak dalam interval tertentu
    if (currentPosition - lastPosition).Magnitude < 1 then
        if currentTime - lastMovementCheck > afkCheckInterval then
            print("Anti-AFK: Melakukan tindakan pencegahan...")
            
            -- Lakukan berbagai aksi acak untuk menghindari AFK
            local randomAction = math.random(1, 5)
            
            if randomAction == 1 then
                -- Lompat
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                print("Anti-AFK: Melompat")
                
            elseif randomAction == 2 then
                -- Gerakkan mouse sedikit
                VirtualInputManager:SendMouseMoveEvent(10, 10, game)
                wait(0.1)
                VirtualInputManager:SendMouseMoveEvent(-10, -10, game)
                print("Anti-AFK: Menggerakkan mouse")
                
            elseif randomAction == 3 then
                -- Tekan tombol keyboard acak
                local keys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space}
                local randomKey = keys[math.random(1, #keys)]
                VirtualInputManager:SendKeyEvent(true, randomKey, false, game)
                wait(0.1)
                VirtualInputManager:SendKeyEvent(false, randomKey, false, game)
                print("Anti-AFK: Menekan tombol " .. tostring(randomKey))
                
            elseif randomAction == 4 then
                -- Putar kamera sedikit
                local camera = Workspace.CurrentCamera
                if camera then
                    local originalCF = camera.CFrame
                    camera.CFrame = originalCF * CFrame.Angles(0, math.rad(10), 0)
                    wait(0.2)
                    camera.CFrame = originalCF * CFrame.Angles(0, math.rad(-10), 0)
                    print("Anti-AFK: Memutar kamera")
                end
                
            elseif randomAction == 5 then
                -- Gerakkan karakter sedikit
                local originalPosition = HRP.CFrame
                HRP.CFrame = originalPosition * CFrame.new(2, 0, 0)
                wait(0.5)
                HRP.CFrame = originalPosition
                print("Anti-AFK: Menggerakkan karakter")
            end
            
            lastMovementCheck = currentTime
        end
    else
        -- Update posisi terakhir dan reset timer
        lastPosition = currentPosition
        lastMovementCheck = currentTime
    end
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

local function buyCropSeeds(cropName)
    local args = {[1] = cropName}
    local success, errorMsg = pcall(function()
        BuySeedStock:FireServer(unpack(args))
    end)
    
    if not success then
        print("Error buying seeds:", errorMsg)
        return false
    end
    return true
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
    
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    wait(1.5)
    
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(0.5)
    
    local boughtAny = false
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        print("Trying to buy "..fruitName..", stock: "..tostring(stock))
        
        if stock > 0 then
            for j = 1, stock do
                local success = buyCropSeeds(fruitName)
                if success then
                    boughtAny = true
                    print("Bought "..fruitName.." seed "..j.."/"..stock)
                else
                    print("Failed to buy "..fruitName)
                end
                wait(0.2)
            end
        else
            print("No stock for "..fruitName)
        end
    end
    
    wait(0.5)
    HRP.CFrame = beforePos
    
    isBuying = false
    return boughtAny
end

local function onShopRefresh()
    print("Shop Refreshed")
    getCropsListAndStock()
    if wantedFruits and #wantedFruits > 0 and autoBuyEnabled then
        print("Auto-buying selected fruits...")
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

-- Anti-AFK System
spawn(function()
    while true do
        if antiAFKEnabled then
            antiAFKAction()
        end
        wait(10)
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
        print("Selected:", table.concat(filtered, ", "))
        wantedFruits = filtered
        print("Updated!")
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

-- Tab untuk Anti-AFK dan Toko SAM
local utilityTab = Window:CreateTab("Utility", "settings")

utilityTab:CreateSection("NPC Sam Shop")

utilityTab:CreateButton({
    Name = "Buka Toko Sam",
    Callback = function()
        local success, method = openSamShop()
        if success then
            Rayfield:Notify({
                Title = "Berhasil!",
                Content = "Toko Sam berhasil dibuka dengan Method " .. method,
                Duration = 5,
                Image = 0
            })
        else
            Rayfield:Notify({
                Title = "Gagal",
                Content = "Tidak bisa membuka toko Sam",
                Duration = 5,
                Image = 0
            })
        end
    end,
})

utilityTab:CreateToggle({
    Name = "Auto Buka Toko Sam Setiap Refresh",
    CurrentValue = false,
    Flag = "AutoOpenSamShop",
    Callback = function(Value)
        if Value then
            spawn(function()
                while wait(5) do
                    if antiAFKEnabled then
                        if shopTime and shopTime <= 5 then
                            print("🕒 Membuka toko Sam karena hampir refresh...")
                            local success, method = openSamShop()
                            if success then
                                print("✅ Auto-buka berhasil dengan Method " .. method)
                            else
                                print("❌ Auto-buka gagal")
                            end
                            wait(10)
                        end
                    else
                        break
                    end
                end
            end)
        end
    end,
})

utilityTab:CreateSection("Anti-AFK System")

utilityTab:CreateToggle({
    Name = "Enable Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        antiAFKEnabled = Value
        print("Anti-AFK: " .. tostring(Value))
    end,
})

utilityTab:CreateSlider({
    Name = "Anti-AFK Check Interval",
    Range = {10, 120},
    Increment = 5,
    Suffix = "detik",
    CurrentValue = 30,
    Flag = "AntiAFKInterval",
    Callback = function(Value)
        afkCheckInterval = Value
        print("Anti-AFK interval: " .. Value .. " detik")
    end,
})

utilityTab:CreateSection("Character Safety")

utilityTab:CreateToggle({
    Name = "Auto Respawn Jika Terjebak",
    CurrentValue = false,
    Flag = "AutoRespawnToggle",
    Callback = function(Value)
        if Value then
            spawn(function()
                while wait(5) do
                    if antiAFKEnabled and Character and HRP then
                        local currentPosition = HRP.Position
                        wait(3)
                        local newPosition = HRP.Position
                        
                        if (newPosition - currentPosition).Magnitude < 0.1 then
                            print("Karakter mungkin terjebak, mencoba respawn...")
                            
                            HRP.CFrame = CFrame.new(0, 10, 0)
                            wait(2)
                            
                            if (HRP.Position - currentPosition).Magnitude < 1 then
                                Humanoid.Health = 0
                                print("Force respawn dilakukan")
                            end
                        end
                    else
                        break
                    end
                end
            end)
        end
    end,
})

-- Function untuk refresh dropdown fruits
local function refreshFruitsDropdown()
    getCropsListAndStock()
    local fruitsDropdown = seedsTab:FindFirstChild("Fruits To Buy")
    if fruitsDropdown then
        fruitsDropdown:Refresh(getAllIFromDict(CropsListAndStocks))
    end
end

utilityTab:CreateButton({
    Name = "Refresh Fruits List",
    Callback = function()
        refreshFruitsDropdown()
        print("Fruits list refreshed!")
    end,
})

-- Auto-refresh fruits list ketika shop timer reset
spawn(function()
    while true do
        if shopTime and shopTime <= 1 then
            wait(2)
            refreshFruitsDropdown()
            print("Auto-refreshed fruits list setelah shop reset")
        end
        wait(1)
    end
end)

-- Monitoring karakter
spawn(function()
    while true do
        if antiAFKEnabled then
            if Character and HRP then
                local currentPos = HRP.Position
                
                if currentPos.Y < -100 then
                    print("Karakter jatuh dari map, teleport ke tempat aman...")
                    HRP.CFrame = CFrame.new(0, 50, 0)
                end
            end
        end
        wait(5)
    end
end)

-- Initialize the player farm reference
playerFarm = findPlayerFarm()
if not playerFarm then
    warn("Player farm not found!")
end

print("Grow A Garden script loaded successfully!")
