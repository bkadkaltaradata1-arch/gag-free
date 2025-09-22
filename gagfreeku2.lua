-- v1nmmm
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmsFolder = Workspace.Farm
local Players = game:GetService("Players")
local BuySeedStock = ReplicatedStorage.GameEvents.BuySeedStock
local Plant = ReplicatedStorage.GameEvents.Plant_RE
local Backpack = Players.LocalPlayer.Backpack
local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local sellAllRemote = ReplicatedStorage.GameEvents.Sell_Inventory
local Steven = Workspace.NPCS.Steven
local Sam = Workspace.NPCS.Sam
local HRP = Character:WaitForChild("HumanoidRootPart")
local CropsListAndStocks = {}
local SeedShopGUI = Players.LocalPlayer.PlayerGui:WaitForChild("Seed_Shop").Frame.ScrollingFrame
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

-- Fix Rayfield loading with error handling
local Rayfield = nil
local Window = nil

local function loadRayfield()
    local success, err = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
        Window = Rayfield:CreateWindow({
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
    end)
    
    if not success then
        warn("Failed to load Rayfield: " .. tostring(err))
        -- Fallback to simple GUI or notify user
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Grow A Garden Script",
            Text = "Failed to load UI library. Please try again.",
            Duration = 5
        })
        return false
    end
    return true
end

-- Load Rayfield
if not loadRayfield() then
    return -- Stop execution if Rayfield fails to load
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

-- Fungsi untuk mencari dan mengklik carrot seed terlebih dahulu
local function clickCarrotSeed()
    -- Cari frame carrot seed di GUI toko
    local carrotFrame = SeedShopGUI:FindFirstChild("Carrot")
    if not carrotFrame then
        print("Carrot seed not found in shop!")
        return false
    end
    
    -- Cari tombol utama carrot seed (biasanya ImageButton atau TextButton)
    local carrotButton = carrotFrame:FindFirstChildWhichIsA("ImageButton") or carrotFrame:FindFirstChildWhichIsA("TextButton")
    
    if carrotButton then
        -- Simulasikan klik pada carrot seed untuk membuka menu pembelian
        pcall(function()
            carrotButton:FireEvent("MouseButton1Click")
            carrotButton:FireEvent("Activated")
        end)
        print("Clicked Carrot seed to open purchase menu")
        wait(0.5) -- Tunggu menu terbuka
        return true
    else
        print("Carrot seed button not found")
        return false
    end
end

-- Fungsi untuk mencari dan mengklik tombol coin berdasarkan gambar yang diberikan
local function clickCoinButton()
    -- Berdasarkan gambar, tombol coin memiliki harga "100" dan kemungkinan berada di posisi tertentu
    local coinButtons = {}
    
    -- Cari semua tombol di GUI yang mungkin merupakan tombol coin
    for _, guiObject in pairs(Players.LocalPlayer.PlayerGui:GetDescendants()) do
        if guiObject:IsA("TextButton") and guiObject.Visible then
            -- Cari tombol dengan teks "100" (harga coin)
            if guiObject.Text == "10" then
                table.insert(coinButtons, guiObject)
            end
            
            -- Juga cari tombol yang mengandung angka (kemungkinan harga)
            if tonumber(guiObject.Text) then
                table.insert(coinButtons, guiObject)
            end
        end
    end
    
    -- Jika tidak ditemukan tombol dengan teks "100", cari berdasarkan urutan
    if #coinButtons == 0 then
        -- Cari semua tombol yang terlihat
        local allButtons = {}
        for _, guiObject in pairs(Players.LocalPlayer.PlayerGui:GetDescendants()) do
            if guiObject:IsA("TextButton") and guiObject.Visible then
                table.insert(allButtons, guiObject)
            end
        end
        
        -- Urutkan berdasarkan posisi X (tombol paling kiri biasanya coin)
        table.sort(allButtons, function(a, b)
            return a.AbsolutePosition.X < b.AbsolutePosition.X
        end)
        
        -- Ambil tombol pertama sebagai coin button
        if #allButtons >= 1 then
            coinButtons = {allButtons[1]}
        end
    end
    
    if #coinButtons > 0 then
        -- Klik tombol coin pertama yang ditemukan
        pcall(function()
            coinButtons[1]:FireEvent("MouseButton1Click")
            coinButtons[1]:FireEvent("Activated")
            
            -- Juga coba panggil fungsi onclick jika ada
            if coinButtons[1]:FindFirstChild("OnClick") then
                coinButtons[1].OnClick:Invoke()
            end
        end)
        print("Clicked coin button with price: " .. coinButtons[1].Text)
        return true
    else
        print("Coin button not found")
        return false
    end
end

-- Fungsi alternatif menggunakan remote event langsung
local function buyCarrotDirectly()
    local success, errorMsg = pcall(function()
        BuySeedStock:FireServer("Carrot")
    end)
    
    if success then
        print("Successfully bought Carrot seed via remote")
        return true
    else
        print("Error buying Carrot seed:", errorMsg)
        return false
    end
end

-- Tambahkan fungsi untuk teleport ke NPC Sam dan membuka toko
local function openSamShop()
    local beforePos = HRP.CFrame
    
    -- Teleport ke NPC Sam
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4) -- Berdiri di depan NPC
    wait(1.5) -- Tunggu sampai sampai di lokasi
    
    -- Pastikan kita menghadap ke NPC
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(0.5)
    
    -- Aktifkan ProximityPrompt untuk membuka toko
    if Sam:FindFirstChild("Head") and Sam.Head:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(Sam.Head.ProximityPrompt)
        print("Opened Sam's seed shop")
    else
        -- Cari ProximityPrompt di semua bagian NPC
        for _, part in pairs(Sam:GetDescendants()) do
            if part:IsA("ProximityPrompt") then
                fireproximityprompt(part)
                print("Opened Sam's seed shop via alternative method")
                break
            end
        end
    end
end

-- Fungsi untuk membeli carrot seed sampai habis
local function buyAllCarrotSeeds()
    if isBuying then
        print("Already buying seeds, please wait...")
        return false
    end
    
    isBuying = true
    local beforePos = HRP.CFrame
    
    -- Pergi ke NPC Sam dan buka toko
    openSamShop()
    
    -- Tunggu toko terbuka
    wait(3)
    
    -- Dapatkan stok carrot seed
    getCropsListAndStock()
    local carrotStock = tonumber(CropsListAndStocks["Carrot"] or 0)
    print("Carrot seed stock: " .. tostring(carrotStock))
    
    -- Beli semua carrot seed yang tersedia
    if carrotStock > 0 then
        for i = 1, carrotStock do
            -- Coba metode langsung terlebih dahulu
            if buyCarrotDirectly() then
                print("Bought Carrot seed " .. i .. "/" .. carrotStock .. " (direct method)")
                wait(0.3)
            else
                -- Jika metode langsung gagal, coba metode GUI
                -- Klik carrot seed terlebih dahulu
                if clickCarrotSeed() then
                    wait(0.5) -- Tunggu menu terbuka
                    
                    -- Klik tombol coin
                    if clickCoinButton() then
                        print("Bought Carrot seed " .. i .. "/" .. carrotStock .. " (GUI method)")
                        wait(0.3) -- Tunggu sebentar antara pembelian
                    else
                        print("Failed to click coin button")
                        break
                    end
                else
                    print("Failed to click Carrot seed")
                    break
                end
            end
        end
    else
        print("No Carrot seeds available in stock")
    end
    
    -- Kembali ke posisi semula
    wait(0.5)
    HRP.CFrame = beforePos
    
    isBuying = false
    return true
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
    
    -- Wait for GUI to load if needed
    if not SeedShopGUI:FindFirstChildWhichIsA("Frame") then
        wait(2)
    end
    
    for _,Plant in pairs(SeedShopGUI:GetChildren()) do
        if Plant:IsA("Frame") and Plant:FindFirstChild("Main_Frame") and Plant.Main_Frame:FindFirstChild("Stock_Text") then
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
    if not playerFarm or not playerFarm.Important or not playerFarm.Important.Plants_Physical then
        return plantsTable
    end
    
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
                wait(0.2) -- Tunggu sebentar antara pembelian
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

spawn(function() 
    while true do
        if shopTimer and shopTimer.Text then
            shopTime = getTimeInSeconds(shopTimer.Text)
            local shopTimeText = "Shop Resets in " .. shopTime .. "s"
            RayFieldShopTimer:Set({Title = "Shop Timer", Content = shopTimeText})
            
            -- Cek jika toko di-refresh dengan membandingkan stok
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
seedsTab:CreateButton({
    Name = "Teleport to Sam & Open Shop",
    Callback = function()
        openSamShop()
    end,
})

seedsTab:CreateButton({
    Name = "Buy All Carrot Seeds",
    Callback = function()
        buyAllCarrotSeeds()
    end,
})

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

-- Tambahkan toggle untuk enable/disable auto-buy
seedsTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(Value)
        autoBuyEnabled = Value
        print("Auto-Buy set to: "..tostring(Value))
        
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
