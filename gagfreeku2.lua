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
wantedFruits = {"Carrot"} -- Default pilih carrot
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

-- Variabel untuk anti-AFK
local antiAFKEnabled = false
local lastPosition = HRP.Position
local afkCheckInterval = 30
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

-- Fungsi untuk cek apakah toko berhasil terbuka
local function isShopOpen()
    local playerGui = Players.LocalPlayer.PlayerGui
    local possibleShopGUIs = {
        "SeedShop", "Seed_Shop", "ShopGUI", "SamShop", "PlantShop", "SeedStore",
        "ShopFrame", "MainShop", "ShopMenu", "SeedMenu", "PlantMenu"
    }
    
    for _, guiName in pairs(possibleShopGUIs) do
        local gui = playerGui:FindFirstChild(guiName)
        if gui then
            if gui:IsA("ScreenGui") and gui.Enabled then
                return true, guiName
            elseif (gui:IsA("Frame") or gui:IsA("ScrollingFrame")) and gui.Visible then
                return true, guiName
            end
        end
    end
    
    for _, guiObject in pairs(playerGui:GetDescendants()) do
        if guiObject:IsA("GuiObject") and guiObject.Visible then
            local text = ""
            if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
                text = guiObject.Text or ""
            end
            
            if string.lower(text):find("shop") or string.lower(text):find("seed") or 
               string.lower(text):find("plant") or string.lower(guiObject.Name):find("shop") then
                return true, guiObject.Name
            end
        end
    end
    
    return false, nil
end

-- Fungsi untuk membuka toko NPC SAM hanya dengan Method 1 (ProximityPrompt)
local function openSamShop()
    if not Sam or not Sam:FindFirstChild("HumanoidRootPart") then
        print("❌ NPC Sam tidak ditemukan!")
        return false
    end
    
    print("🚀 Membuka toko Sam dengan Method 1: ProximityPrompt...")
    
    local originalPosition = HRP.CFrame
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    print("📍 Menuju ke NPC Sam...")
    
    local targetCFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    HRP.CFrame = targetCFrame
    wait(2)
    
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(0.5)
    
    local foundProximityPrompt = false
    
    -- Method 1: ProximityPrompt
    print("🔍 Mencari ProximityPrompt...")
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent then
                local parentPosition
                local positionSuccess = pcall(function()
                    if parent:IsA("BasePart") then
                        parentPosition = parent.Position
                    elseif parent:IsA("Model") and parent.PrimaryPart then
                        parentPosition = parent.PrimaryPart.Position
                    end
                end)
                
                if positionSuccess and parentPosition and (parentPosition - Sam.HumanoidRootPart.Position).Magnitude < 10 then
                    print("   ✅ Found ProximityPrompt: " .. parent.Name)
                    fireproximityprompt(obj)
                    foundProximityPrompt = true
                    print("   🔥 ProximityPrompt di-trigger!")
                    break
                end
            end
        end
    end
    
    if not foundProximityPrompt then
        print("❌ Tidak menemukan ProximityPrompt di sekitar NPC Sam")
        HRP.CFrame = originalPosition
        return false
    end
    
    -- Tunggu dan cek jika toko terbuka
    wait(2)
    local isOpen, guiName = isShopOpen()
    
    if isOpen then
        print("🎉 BERHASIL! Toko Sam terbuka")
        return true
    else
        print("❌ Gagal membuka toko Sam")
        HRP.CFrame = originalPosition
        return false
    end
end

-- Fungsi untuk membeli seed carrot secara otomatis
local function buyCarrotSeeds()
    if isBuying then
        print("⚠️ Sedang proses pembelian sebelumnya, tunggu...")
        return false
    end
    
    isBuying = true
    print("🥕 Memulai pembelian seed carrot...")
    
    local originalPosition = HRP.CFrame
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    -- Buka toko Sam terlebih dahulu
    local shopOpened = openSamShop()
    
    if not shopOpened then
        print("❌ Gagal membuka toko, tidak bisa membeli seed")
        isBuying = false
        return false
    end
    
    print("🛒 Toko terbuka, memulai pembelian carrot seeds...")
    
    -- Tunggu sebentar untuk memastikan GUI toko fully loaded
    wait(2)
    
    -- Dapatkan stok carrot terbaru
    getCropsListAndStock()
    local carrotStock = tonumber(CropsListAndStocks["Carrot"] or 0)
    
    if carrotStock == 0 then
        print("❌ Stok carrot habis!")
        -- Tutup toko
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
        wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
        HRP.CFrame = originalPosition
        isBuying = false
        return false
    end
    
    print("🥕 Stok carrot: " .. carrotStock)
    
    -- Beli semua seed carrot yang tersedia
    local totalBought = 0
    for i = 1, carrotStock do
        local success, errorMsg = pcall(function()
            BuySeedStock:FireServer("Carrot")
        end)
        
        if success then
            totalBought = totalBought + 1
            print("✅ Berhasil membeli carrot seed " .. i .. "/" .. carrotStock)
        else
            print("❌ Gagal membeli carrot seed: " .. tostring(errorMsg))
        end
        
        -- Tunggu sebentar antara pembelian
        wait(0.3)
    end
    
    print("📦 Total carrot seeds yang dibeli: " .. totalBought .. "/" .. carrotStock)
    
    -- Tutup toko
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
    wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
    
    -- Kembali ke posisi semula
    wait(0.5)
    HRP.CFrame = originalPosition
    
    isBuying = false
    
    if totalBought > 0 then
        print("🎉 Pembelian carrot seeds selesai!")
        return true
    else
        print("💥 Gagal membeli carrot seeds")
        return false
    end
end

-- Fungsi anti-AFK
local function antiAFKAction()
    if not antiAFKEnabled or not Character or not HRP then return end
    
    local currentTime = tick()
    local currentPosition = HRP.Position
    
    if (currentPosition - lastPosition).Magnitude < 1 then
        if currentTime - lastMovementCheck > afkCheckInterval then
            print("Anti-AFK: Melakukan tindakan pencegahan...")
            
            local randomAction = math.random(1, 5)
            
            if randomAction == 1 then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                print("Anti-AFK: Melompat")
                
            elseif randomAction == 2 then
                VirtualInputManager:SendMouseMoveEvent(10, 10, game)
                wait(0.1)
                VirtualInputManager:SendMouseMoveEvent(-10, -10, game)
                print("Anti-AFK: Menggerakkan mouse")
                
            elseif randomAction == 3 then
                local keys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space}
                local randomKey = keys[math.random(1, #keys)]
                VirtualInputManager:SendKeyEvent(true, randomKey, false, game)
                wait(0.1)
                VirtualInputManager:SendKeyEvent(false, randomKey, false, game)
                print("Anti-AFK: Menekan tombol " .. tostring(randomKey))
                
            elseif randomAction == 4 then
                local camera = Workspace.CurrentCamera
                if camera then
                    local originalCF = camera.CFrame
                    camera.CFrame = originalCF * CFrame.Angles(0, math.rad(10), 0)
                    wait(0.2)
                    camera.CFrame = originalCF * CFrame.Angles(0, math.rad(-10), 0)
                    print("Anti-AFK: Memutar kamera")
                end
                
            elseif randomAction == 5 then
                local originalPosition = HRP.CFrame
                HRP.CFrame = originalPosition * CFrame.new(2, 0, 0)
                wait(0.5)
                HRP.CFrame = originalPosition
                print("Anti-AFK: Menggerakkan karakter")
            end
            
            lastMovementCheck = currentTime
        end
    else
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
            
            if isRefreshed and autoBuyEnabled then
                print("🛒 Shop refreshed, auto-buying carrot seeds...")
                wait(2)
                buyCarrotSeeds()
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
   CurrentOption = {"Carrot"}, -- Default pilih carrot
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
    Name = "Enable Auto-Buy Carrot Seeds",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(Value)
        autoBuyEnabled = Value
        print("Auto-Buy Carrot set to: "..tostring(Value))
        
        if Value then
            spawn(function()
                wait(1)
                buyCarrotSeeds()
            end)
        end
    end,
})

seedsTab:CreateButton({
    Name = "Buy Carrot Seeds Now",
    Callback = function()
        buyCarrotSeeds()
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

utilityTab:CreateSection("NPC Sam Shop - Carrot Only")

utilityTab:CreateButton({
    Name = "Buka Toko Sam & Beli Carrot",
    Callback = function()
        local success = buyCarrotSeeds()
        if success then
            Rayfield:Notify({
                Title = "Berhasil!",
                Content = "Berhasil membeli carrot seeds",
                Duration = 5,
                Image = 0
            })
        else
            Rayfield:Notify({
                Title = "Gagal",
                Content = "Gagal membeli carrot seeds",
                Duration = 5,
                Image = 0
            })
        end
    end,
})

utilityTab:CreateToggle({
    Name = "Auto Buka & Beli Carrot Setiap Refresh",
    CurrentValue = false,
    Flag = "AutoBuyCarrot",
    Callback = function(Value)
        if Value then
            spawn(function()
                while wait(5) do
                    if shopTime and shopTime <= 5 then
                        print("🥕 Shop hampir refresh, auto-beli carrot...")
                        buyCarrotSeeds()
                        wait(10)
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

-- Initialize the player farm reference
playerFarm = findPlayerFarm()
if not playerFarm then
    warn("Player farm not found!")
end

print("Grow A Garden script loaded successfully!")
print("🥕 Script siap untuk auto-beli carrot seeds!")
