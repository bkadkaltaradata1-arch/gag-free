-- v6
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

-- Fungsi untuk mencari tombol buy di UI seed shop yang benar (bukan padding)
local function findAndClickBuyButton(seedName)
    local seedShopGui = Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop")
    if not seedShopGui then
        print("Seed shop GUI not found")
        return false
    end
    
    -- Cari scrolling frame
    local scrollingFrame = seedShopGui.Frame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then
        print("ScrollingFrame not found")
        return false
    end
    
    -- Cari frame untuk seed tertentu (bukan yang _padding)
    local seedFrame
    for _, child in pairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name == seedName then
            seedFrame = child
            break
        end
    end
    
    if not seedFrame then
        print("Seed frame not found for: " .. seedName)
        return false
    end
    
    -- Cari main frame
    local mainFrame = seedFrame:FindFirstChild("Main_Frame")
    if not mainFrame then
        print("Main frame not found for: " .. seedName)
        return false
    end
    
    -- Cari tombol buy - coba beberapa kemungkinan nama
    local buyButton = mainFrame:FindFirstChild("Buy_Button") or 
                     mainFrame:FindFirstChild("BuyButton") or
                     mainFrame:FindFirstChild("Button") or
                     mainFrame:FindFirstChild("Purchase") or
                     mainFrame:FindFirstChildOfClass("TextButton") or
                     mainFrame:FindFirstChildOfClass("ImageButton")
    
    if buyButton then
        print("Found buy button: " .. buyButton.Name .. " (" .. buyButton.ClassName .. ")")
        
        -- Simulasikan klik pada tombol
        local success, errorMsg = pcall(function()
            if buyButton:IsA("TextButton") or buyButton:IsA("ImageButton") then
                -- Coba fire mouse click event
                buyButton.MouseButton1Click:Fire()
                print("Clicked buy button for: " .. seedName)
                return true
            end
        end)
        
        if not success then
            print("Error clicking button: " .. errorMsg)
            -- Coba metode alternatif: panggil remote event langsung
            local buySuccess, buyError = pcall(function()
                BuySeedStock:FireServer(seedName)
                return true
            end)
            return buySuccess
        end
        return success
    else
        print("Buy button not found for: " .. seedName)
        -- Fallback: coba panggil remote event langsung
        local success, errorMsg = pcall(function()
            BuySeedStock:FireServer(seedName)
            return true
        end)
        return success
    end
end

-- Fungsi untuk membeli seed dengan metode yang berbeda
local function buySeedAlternative(seedName)
    print("Attempting to buy: " .. seedName)
    
    -- Pastikan toko terbuka dengan benar
    if Sam and Sam:FindFirstChild("Head") and Sam.Head:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(Sam.Head.ProximityPrompt)
        wait(1.5) -- Tunggu toko terbuka
    end
    
    -- Coba metode pertama: klik tombol di UI
    local success1 = findAndClickBuyButton(seedName)
    if success1 then
        print("UI button click successful for: " .. seedName)
        return true
    end
    
    -- Coba metode kedua: langsung fire server
    wait(0.5)
    local success2, result2 = pcall(function()
        BuySeedStock:FireServer(seedName)
        return true
    end)
    
    if success2 then
        print("Direct fire server successful for: " .. seedName)
        return true
    end
    
    -- Coba metode ketiga: gunakan remote event yang berbeda
    local alternativeRemote = ReplicatedStorage:FindFirstChild("BuySeed") or 
                             ReplicatedStorage:FindFirstChild("PurchaseSeed") or
                             ReplicatedStorage:FindFirstChild("BuySeedStock")
    
    if alternativeRemote then
        wait(0.5)
        local success3, result3 = pcall(function()
            alternativeRemote:FireServer(seedName)
            return true
        end)
        
        if success3 then
            print("Alternative remote successful for: " .. seedName)
            return true
        end
    end
    
    print("All purchase methods failed for: " .. seedName)
    return false
end

-- Fungsi untuk mendapatkan daftar seed yang tersedia (hanya yang bukan padding)
local function getAvailableSeeds()
    local seedsList = {}
    local seedShopGui = Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop")
    
    if seedShopGui then
        local scrollingFrame = seedShopGui.Frame:FindFirstChild("ScrollingFrame")
        if scrollingFrame then
            for _, child in pairs(scrollingFrame:GetChildren()) do
                if child:IsA("Frame") and not string.find(child.Name, "padding") and not string.find(child.Name, "Padding") then
                    if child:FindFirstChild("Main_Frame") then
                        table.insert(seedsList, child.Name)
                    end
                end
            end
        end
    end
    
    -- Fallback: gunakan CropsListAndStocks jika tidak ada GUI
    if #seedsList == 0 then
        for seedName, _ in pairs(CropsListAndStocks) do
            table.insert(seedsList, seedName)
        end
    end
    
    return seedsList
end

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

-- Update fungsi getCropsListAndStock untuk hanya mengambil seed yang bukan padding
function getCropsListAndStock()
    local oldStock = CropsListAndStocks
    CropsListAndStocks = {} -- Reset the table
    
    local seedShopGui = Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop")
    if not seedShopGui then return false end
    
    local scrollingFrame = seedShopGui.Frame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return false end
    
    for _, child in pairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") and not string.find(child.Name, "padding") and not string.find(child.Name, "Padding") then
            if child:FindFirstChild("Main_Frame") and child.Main_Frame:FindFirstChild("Stock_Text") then
                local PlantName = child.Name
                local PlantStock = StripPlantStock(child.Main_Frame.Stock_Text.Text)
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

-- Fungsi untuk membeli seed dengan retry mechanism
local function buyCropSeeds(cropName, retryCount)
    retryCount = retryCount or 0
    if retryCount > 3 then
        print("Failed to buy " .. cropName .. " after 3 attempts")
        return false
    end
    
    -- Coba berbagai metode pembelian
    local success = buySeedAlternative(cropName)
    
    if not success then
        print("Error buying " .. cropName .. " seeds (attempt " .. (retryCount + 1) .. ")")
        wait(1) -- Tunggu sebelum retry
        return buyCropSeeds(cropName, retryCount + 1)
    end
    
    return true
end

-- Fungsi untuk mengecek apakah seed berhasil dibeli
local function checkSeedBought(seedName)
    -- Cek apakah seed ada di backpack setelah pembelian
    wait(0.5) -- Tunggu sebentar untuk proses pembelian
    for _, item in pairs(Backpack:GetChildren()) do
        if item:FindFirstChild("Seed Local Script") and item:GetAttribute("Seed") == seedName then
            return true
        end
    end
    return false
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
    
    -- Pastikan karakter bisa bergerak
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    -- Pergi ke NPC Sam
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    wait(2) -- Tunggu lebih lama sampai sampai di lokasi
    
    -- Pastikan kita menghadap ke NPC
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(0.5)
    
    -- Interaksi dengan Sam untuk membuka toko
    if Sam and Sam:FindFirstChild("Head") and Sam.Head:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(Sam.Head.ProximityPrompt)
        wait(2.5) -- Tunggu lebih lama untuk toko terbuka sepenuhnya
    end
    
    -- Refresh informasi stok
    getCropsListAndStock()
    
    local boughtAny = false
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        print("Trying to buy "..fruitName..", stock: "..tostring(stock))
        
        if stock > 0 then
            for j = 1, stock do
                local success = buyCropSeeds(fruitName)
                if success then
                    -- Verifikasi bahwa seed benar-benar dibeli
                    if checkSeedBought(fruitName) then
                        boughtAny = true
                        print("Successfully bought "..fruitName.." seed "..j.."/"..stock)
                        -- Update stok setelah pembelian berhasil
                        CropsListAndStocks[fruitName] = tostring(stock - j)
                    else
                        print("Purchase of "..fruitName.." might have failed (seed not in backpack)")
                    end
                else
                    print("Failed to buy "..fruitName)
                    break -- Berhenti mencoba fruit ini jika ada error
                end
                wait(0.5) -- Tunggu lebih lama antara pembelian
            end
        else
            print("No stock for "..fruitName)
        end
    end
    
    -- Kembali ke posisi semula
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
        
        -- Tunggu lebih lama sebelum membeli untuk memastikan UI sudah update
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

-- Add cooldown mechanism
local lastBuyAttempt = 0
local BUY_COOLDOWN = 10 -- seconds (increased cooldown)

-- Add function to reset buying state
local function resetBuyingState()
    isBuying = false
    print("Buying state reset")
end

local lastShopTime = 0
spawn(function() 
    while true do
        if shopTimer and shopTimer.Text then
            shopTime = getTimeInSeconds(shopTimer.Text)
            local shopTimeText = "Shop Resets in " .. shopTime .. "s"
            RayFieldShopTimer:Set({Title = "Shop Timer", Content = shopTimeText})
            
            -- Check if shop just refreshed (timer reset to max)
            if shopTime > lastShopTime + 50 then  -- Assuming shop resets around 300 seconds
                print("Shop refreshed detected by timer reset!")
                onShopRefresh()
            end
            
            lastShopTime = shopTime
            
            -- Also check stock changes periodically
            local isRefreshed = getCropsListAndStock()
            if isRefreshed and autoBuyEnabled and not isBuying then
                print("Shop stock changed, auto-buying...")
                onShopRefresh()
            end
        end
        
        if shouldSell and #(Backpack:GetChildren()) >= AutoSellItems and not isSelling then
            sellAll()
        end
        
        wait(1) -- Reduced from 0.5 to 1 second to avoid spamming
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
            Backpack:FindFirstChild("TP Wand":Destroy()
        end
        if Character:FindFirstChild("TP Wand") then
            Character:FindFirstChild("TP Wand":Destroy()
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

-- Update dropdown options untuk hanya menampilkan seed yang bukan padding
local seedDropdown = seedsTab:CreateDropdown({
   Name = "Fruits To Buy",
   Options = getAvailableSeeds(),
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

-- Tambahkan fungsi refresh untuk dropdown
seedsTab:CreateButton({
    Name = "Refresh Seed List",
    Callback = function()
        local availableSeeds = getAvailableSeeds()
        seedDropdown:Refresh(availableSeeds)
        Rayfield:Notify({
            Title = "Seed List Refreshed",
            Content = "Available seeds list has been updated",
            Duration = 3,
            Image = 0,
        })
    end,
})

-- Tambahkan toggle untuk enable/disable auto-buy
seedsTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(Value)
        autoBuyEnabled = Value
        print("Auto-Buy set to: "..tostring(Value))
        
        -- Add visual indicator
        if Value then
            Rayfield:Notify({
                Title = "Auto-Buy Enabled",
                Content = "Will automatically buy selected fruits when shop refreshes",
                Duration = 3,
                Image = 0,
            })
        end
        
        -- Jika diaktifkan, langsung coba beli
        if Value and #wantedFruits > 0 then
            spawn(function()
                wait(2) -- Tunggu lebih lama
                buyWantedCropSeeds()
            end)
        end
    end,
})

seedsTab:CreateButton({
    Name = "Buy Selected Fruits Now",
    Callback = function()
        if tick() - lastBuyAttempt < BUY_COOLDOWN then
            print("Please wait before trying to buy again")
            Rayfield:Notify({
                Title = "Cooldown",
                Content = "Please wait " .. math.ceil(BUY_COOLDOWN - (tick() - lastBuyAttempt)) .. " seconds before buying again",
                Duration = 3,
                Image = 0,
            })
            return
        end
        lastBuyAttempt = tick()
        buyWantedCropSeeds()
    end,
})

-- Add button to reset buying state
seedsTab:CreateButton({
    Name = "Reset Buying State (If Stuck)",
    Callback = function()
        resetBuyingState()
    end,
})

-- Add button to manually open shop
seedsTab:CreateButton({
    Name = "Open Shop Manually",
    Callback = function()
        local beforePos = HRP.CFrame
        HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
        wait(1.5)
        if Sam and Sam:FindFirstChild("Head") and Sam.Head:FindFirstChild("ProximityPrompt") then
            fireproximityprompt(Sam.Head.ProximityPrompt)
            Rayfield:Notify({
                Title = "Shop Opened",
                Content = "NPC Sam's shop has been opened",
                Duration = 3,
                Image = 0,
            })
        end
        wait(1)
        HRP.CFrame = beforePos
    end,
})

-- Add button to debug UI elements
seedsTab:CreateButton({
    Name = "Debug Seed Shop UI",
    Callback = function()
        local seedShopGui = Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop")
        if seedShopGui then
            print("=== Seed Shop UI Debug ===")
            print("Found Seed_Shop GUI")
            
            -- Check scrolling frame
            local scrollingFrame = seedShopGui.Frame:FindFirstChild("ScrollingFrame")
            if scrollingFrame then
                print("ScrollingFrame found with " .. #scrollingFrame:GetChildren() .. " children")
                
                -- List all seed frames
                for _, child in pairs(scrollingFrame:GetChildren()) do
                    if child:IsA("Frame") then
                        print("Seed frame: " .. child.Name)
                        
                        -- Check for main frame
                        local mainFrame = child:FindFirstChild("Main_Frame")
                        if mainFrame then
                            print("  Main_Frame found")
                            
                            -- Find all buttons
                            for _, element in pairs(mainFrame:GetChildren()) do
                                if element:IsA("TextButton") or element:IsA("ImageButton") then
                                    print("  Button found: " .. element.Name .. " (" .. element.ClassName .. ")")
                                end
                            end
                        end
                    end
                end
            end
        else
            print("Seed_Shop GUI not found")
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

-- Initialize the player farm reference
playerFarm = findPlayerFarm()
if not playerFarm then
    warn("Player farm not found!")
end

print("Grow A Garden script loaded successfully!")
