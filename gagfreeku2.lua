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

-- Fungsi untuk mencari ProximityPrompt dengan berbagai metode
local function findProximityPrompt(npc)
    -- Cari langsung di NPC
    if npc:FindFirstChildOfClass("ProximityPrompt") then
        return npc:FindFirstChildOfClass("ProximityPrompt")
    end
    
    -- Cari di semua descendants
    for _, descendant in pairs(npc:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            return descendant
        end
    end
    
    return nil
end

-- Fungsi untuk mengklik GUI element dengan berbagai metode
local function clickGUIElement(element, elementName)
    if not element then
        print("Element not found: " .. tostring(elementName))
        return false
    end
    
    -- Method 1: Coba RemoteEvent
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
    
    -- Method 2: Coba BindableEvent
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
    
    -- Method 3: Coba fire mouse click event untuk Button
    if element:IsA("TextButton") or element:IsA("ImageButton") then
        local success, result = pcall(function()
            element.MouseButton1Click:Fire()
            return true
        end)
        if success then
            print("Clicked " .. elementName .. " using MouseButton1Click")
            return true
        end
        
        -- Method 4: Coba trigger events manual
        local success, result = pcall(function()
            -- Simulate mouse enter and click
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
    
    -- Method 5: Coba gunakan tween untuk simulate click visual
    local success, result = pcall(function()
        element.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7) -- Change color to simulate press
        wait(0.1)
        element.BackgroundColor3 = Color3.new(1, 1, 1) -- Change back
        return true
    end)
    
    print("Failed to click " .. elementName)
    return false
end

-- Fungsi untuk membuka toko dengan berbagai alternatif
local function openShopWithNPC()
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    -- Pergi ke NPC Sam dengan posisi yang lebih aman
    local targetPosition = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    HRP.CFrame = targetPosition
    wait(2)
    
    -- Pastikan menghadap ke NPC
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(1)
    
    -- Method 1: Coba proximity prompt
    local prompt = findProximityPrompt(Sam)
    if prompt then
        for i = 1, 3 do -- Coba beberapa kali
            fireproximityprompt(prompt)
            print("Attempt " .. i .. ": Fired ProximityPrompt on NPC Sam")
            wait(1)
            
            -- Cek jika toko terbuka dengan melihat GUI
            if SeedShopGUI.Visible then
                print("Shop opened successfully!")
                return true
            end
        end
    end
    
    -- Method 2: Coba RemoteEvent langsung
    local shopRemote = ReplicatedStorage:FindFirstChild("OpenShop") or ReplicatedStorage:FindFirstChild("OpenSeedShop")
    if shopRemote then
        shopRemote:FireServer()
        print("Used RemoteEvent to open shop")
        wait(2)
        return true
    end
    
    -- Method 3: Coba approach yang lebih dekat
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
    wait(1)
    
    -- Coba lagi proximity prompt dari jarak dekat
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

-- Fungsi untuk mencari dan mengklik Main_Frame
local function clickMainFrame(seedName)
    print("Looking for seed frame: " .. seedName)
    
    -- Tunggu sebentar untuk memastikan GUI sudah loaded
    wait(1)
    
    -- Cari seed frame di ScrollingFrame
    local seedFrame = SeedShopGUI:FindFirstChild(seedName)
    if not seedFrame then
        print("Seed frame not found: " .. seedName)
        -- Coba cari dengan pattern matching
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
    
    -- Cari Main_Frame dalam seed frame
    local mainFrame = seedFrame:FindFirstChild("Main_Frame")
    if not mainFrame then
        print("Main_Frame not found in " .. seedName)
        -- Coba cari element button apapun yang mungkin menjadi Main_Frame
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

-- Fungsi untuk mencari dan mengklik Sheckles_Buy
local function clickShecklesBuy(seedName)
    print("Looking for Sheckles_Buy button...")
    wait(1) -- Tunggu dialog detail terbuka
    
    -- Cari Sheckles_Buy button di berbagai lokasi possible
    local shecklesButton = nil
    
    -- Method 1: Cari di parent frames terlebih dahulu
    local seedShopFrame = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame
    if seedShopFrame then
        -- Cari di berbagai kemungkinan lokasi
        shecklesButton = seedShopFrame:FindFirstChild("Sheckles_Buy", true) -- recursive search
        
        -- Cari button dengan nama mengandung "sheckles" atau "buy"
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
            wait(0.5) -- Tunggu proses pembelian
            return true
        end
    end
    
    -- Method 2: Coba gunakan RemoteEvent langsung jika button tidak ditemukan
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

-- Fungsi utama untuk membeli seed
local function buySeed(seedName)
    if isBuying then
        print("Already in buying process, please wait...")
        return false
    end
    
    isBuying = true
    local originalPosition = HRP.CFrame
    local success = false
    
    print("=== Starting purchase process for: " .. seedName .. " ===")
    
    -- Step 1: Buka toko dengan NPC Sam
    print("Step 1: Opening shop with NPC Sam...")
    local shopOpened = openShopWithNPC()
    
    if shopOpened then
        -- Step 2: Klik Main_Frame untuk seed yang dipilih
        print("Step 2: Clicking Main_Frame for " .. seedName .. "...")
        local mainFrameClicked = clickMainFrame(seedName)
        
        if mainFrameClicked then
            -- Step 3: Klik Sheckles_Buy button
            print("Step 3: Clicking Sheckles_Buy button...")
            success = clickShecklesBuy(seedName)
        else
            print("Failed to click Main_Frame, attempting direct purchase...")
            success = clickShecklesBuy(seedName) -- Coba langsung beli tanpa klik Main_Frame
        end
    else
        print("Failed to open shop, attempting direct purchase...")
        success = clickShecklesBuy(seedName) -- Coba beli tanpa buka toko
    end
    
    -- Kembali ke posisi semula
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

-- ... (fungsi-fungsi lain tetap sama)

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

-- ... (bagian lainnya tetap sama)

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
            for j = 1, math.min(stock, 5) do -- Batasi maksimal 5 pembelian per seed
                local success = buySeed(fruitName)
                if success then
                    boughtAny = true
                    print("✓ Successfully bought "..fruitName.." seed "..j.."/"..stock)
                    -- Tunggu lebih lama setelah success
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

-- ... (bagian auto-buy dan UI lainnya tetap sama)

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

-- ... (bagian sell tab dan lainnya)

-- Initialize
playerFarm = findPlayerFarm()
if not playerFarm then
    warn("Player farm not found!")
end

print("Grow A Garden script loaded successfully!")
print("Auto-buy system ready!")
print("Process: NPC Sam → ProximityPrompt → Main_Frame → Sheckles_Buy")
