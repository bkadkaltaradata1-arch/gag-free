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
    local shopGUI = playerGui:FindFirstChild("Seed_Shop")
    if shopGUI and shopGUI.Enabled then
        return true, "Seed_Shop"
    end
    return false, nil
end

-- Fungsi untuk mencari dan klik tombol buy berdasarkan nama seed
local function findAndClickBuyButton(seedName)
    local playerGui = Players.LocalPlayer.PlayerGui
    local shopGUI = playerGui:FindFirstChild("Seed_Shop")
    
    if not shopGUI or not shopGUI.Enabled then
        print("❌ GUI toko tidak terbuka")
        return false
    end
    
    -- Cari frame yang sesuai dengan nama seed
    local seedFrame = nil
    for _, child in pairs(shopGUI:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            if string.lower(child.Text or "") == string.lower(seedName) then
                seedFrame = child.Parent
                if seedFrame:FindFirstChild("Main_Frame") then
                    seedFrame = seedFrame.Main_Frame
                end
                break
            end
        end
    end
    
    if not seedFrame then
        -- Coba cari berdasarkan nama object
        seedFrame = shopGUI:FindFirstChild(seedName, true)
    end
    
    if not seedFrame then
        print("❌ Tidak menemukan frame untuk: " .. seedName)
        return false
    end
    
    print("✅ Found seed frame: " .. seedFrame.Name)
    
    -- Cari tombol buy (biasanya TextButton dengan text harga)
    local buyButton = nil
    for _, child in pairs(seedFrame:GetDescendants()) do
        if child:IsA("TextButton") then
            -- Cek jika tombol berisi angka (harga)
            local text = child.Text or ""
            if string.match(text, "%d+") or string.find(text, "Buy") or string.find(text, "Beli") then
                buyButton = child
                print("✅ Found buy button: " .. text)
                break
            end
        end
    end
    
    if not buyButton then
        -- Coba cari ImageButton jika TextButton tidak ditemukan
        for _, child in pairs(seedFrame:GetDescendants()) do
            if child:IsA("ImageButton") then
                buyButton = child
                print("✅ Found image buy button")
                break
            end
        end
    end
    
    if buyButton then
        -- Dapatkan posisi tombol di screen
        local absolutePosition = buyButton.AbsolutePosition
        local absoluteSize = buyButton.AbsoluteSize
        local centerX = absolutePosition.X + absoluteSize.X / 2
        local centerY = absolutePosition.Y + absoluteSize.Y / 2
        
        print(string.format("🖱️ Clicking button at position: X=%d, Y=%d", centerX, centerY))
        
        -- Klik tombol
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
        
        print("✅ Berhasil klik tombol buy untuk: " .. seedName)
        return true
    else
        print("❌ Tidak menemukan tombol buy untuk: " .. seedName)
        return false
    end
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
    wait(3)
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

-- Fungsi untuk membeli seed carrot secara otomatis dengan GUI click
local function buyCarrotSeeds()
    if isBuying then
        print("⚠️ Sedang proses pembelian sebelumnya, tunggu...")
        return false
    end
    
    isBuying = true
    print("🥕 Memulai pembelian seed carrot...")
    
    local originalPosition = HRP.CFrame
    
    -- Buka toko Sam terlebih dahulu
    local shopOpened = openSamShop()
    
    if not shopOpened then
        print("❌ Gagal membuka toko, tidak bisa membeli seed")
        isBuying = false
        return false
    end
    
    print("🛒 Toko terbuka, memulai pembelian carrot seeds...")
    
    -- Tunggu sebentar untuk memastikan GUI toko fully loaded
    wait(3)
    
    -- Cek stok carrot dari GUI
    local carrotStock = 0
    local playerGui = Players.LocalPlayer.PlayerGui
    local shopGUI = playerGui:FindFirstChild("Seed_Shop")
    
    if shopGUI and shopGUI.Enabled then
        -- Cari frame carrot dan baca stok
        for _, child in pairs(shopGUI:GetDescendants()) do
            if child:IsA("TextLabel") then
                if string.lower(child.Text or "") == "carrot" then
                    -- Cari text stok di sekitar frame yang sama
                    local parentFrame = child.Parent
                    if parentFrame:FindFirstChild("Main_Frame") then
                        parentFrame = parentFrame.Main_Frame
                    end
                    
                    for _, sibling in pairs(parentFrame:GetDescendants()) do
                        if sibling:IsA("TextLabel") then
                            local stockText = sibling.Text or ""
                            local stockNumber = string.match(stockText, "%d+")
                            if stockNumber then
                                carrotStock = tonumber(stockNumber)
                                print("🥕 Stok carrot: " .. carrotStock)
                                break
                            end
                        end
                    end
                    break
                end
            end
        end
    end
    
    if carrotStock == 0 then
        print("❌ Stok carrot habis atau tidak ditemukan!")
        -- Tutup toko
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
        wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
        HRP.CFrame = originalPosition
        isBuying = false
        return false
    end
    
    -- Beli semua seed carrot yang tersedia dengan klik GUI
    local totalBought = 0
    local maxAttempts = carrotStock * 2 -- Beri buffer untuk attempts
    
    for attempt = 1, maxAttempts do
        if totalBought >= carrotStock then
            break
        end
        
        print("🛒 Attempt " .. attempt .. ": Mencoba membeli carrot seed...")
        
        -- Cari dan klik tombol buy untuk carrot
        local clickSuccess = findAndClickBuyButton("Carrot")
        
        if clickSuccess then
            totalBought = totalBought + 1
            print("✅ Berhasil membeli carrot seed " .. totalBought .. "/" .. carrotStock)
            
            -- Tunggu sebentar sebelum klik berikutnya
            wait(0.5)
            
            -- Cek jika stok sudah habis dengan membaca ulang GUI
            local currentStock = 0
            if shopGUI and shopGUI.Enabled then
                for _, child in pairs(shopGUI:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local stockText = child.Text or ""
                        local stockNumber = string.match(stockText, "%d+")
                        if stockNumber then
                            currentStock = tonumber(stockNumber)
                            if currentStock == 0 then
                                break
                            end
                        end
                    end
                end
            end
            
            if currentStock == 0 then
                print("📦 Stok sudah habis, berhenti membeli")
                break
            end
        else
            print("❌ Gagal klik tombol buy, attempt " .. attempt)
        end
        
        wait(0.3) -- Tunggu sebelum attempt berikutnya
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

-- ... (rest of the existing functions remain the same) ...

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

-- ... (rest of the existing UI code remains the same) ...

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
    Name = "Buy Carrot Seeds Now (GUI Click)",
    Callback = function()
        buyCarrotSeeds()
    end,
})

-- ... (rest of the existing UI code remains the same) ...

-- Tab untuk Anti-AFK dan Toko SAM
local utilityTab = Window:CreateTab("Utility", "settings")

utilityTab:CreateSection("NPC Sam Shop - Carrot Only")

utilityTab:CreateButton({
    Name = "Buka Toko & Beli Carrot (GUI Click)",
    Callback = function()
        local success = buyCarrotSeeds()
        if success then
            Rayfield:Notify({
                Title = "Berhasil!",
                Content = "Berhasil membeli carrot seeds dengan GUI click",
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

-- ... (rest of the existing code remains the same) ...

-- Initialize the player farm reference
playerFarm = findPlayerFarm()
if not playerFarm then
    warn("Player farm not found!")
end

print("Grow A Garden script loaded successfully!")
print("🥕 Script siap untuk auto-beli carrot seeds dengan GUI click!")
