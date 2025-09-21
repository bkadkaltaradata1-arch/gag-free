-- erer
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
local plantToRemove = {"None Selected"}
local shouldAutoPlant = false
local isSelling = false
local byteNetReliable = ReplicatedStorage:FindFirstChild("ByteNetReliable")
local autoBuyEnabled = false
local lastShopStock = {}
local isBuying = false

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Grow A Garden",
   LoadingTitle = "Grow A Garden Automation",
   LoadingSubtitle = "Loading Interface...",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "GrowAGardenConfig",
      FileName = "GAGConfig"
   },
   KeySystem = false,
})

-- Fungsi untuk mendapatkan farm player
local function findPlayerFarm()
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important.Data.Owner.Value == Players.LocalPlayer.Name then
            return v
        end
    end
    return nil
end

-- Fungsi untuk menghapus plants
local function removePlantsOfKind(kind)
    if not kind or kind[1] == "None Selected" then
        print("No plant selected to remove")
        return
    end
    
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]") or Backpack:FindFirstChild("Shovel")
    if not Shovel then
        print("Shovel not found in backpack")
        return
    end
    
    Shovel.Parent = Character
    wait(0.5)
    
    local playerFarm = findPlayerFarm()
    if playerFarm then
        for _,plant in pairs(playerFarm.Important.Plants_Physical:GetChildren()) do
            if plant.Name == kind[1] and plant:FindFirstChild("Fruit_Spawn") then
                HRP.CFrame = plant.PrimaryPart.CFrame
                wait(0.2)
                removeItem:FireServer(plant.Fruit_Spawn)
                wait(0.1)
            end
        end
    end
    
    if Shovel and Shovel.Parent == Character then
        Shovel.Parent = Backpack
    end
end

-- Fungsi untuk mendapatkan daftar tanaman yang sudah ditanam
local function getPlantedFruitTypes()
    local list = {"None Selected"}
    local farm = findPlayerFarm()
    if not farm then return list end
    
    for _,plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if not table.find(list, plant.Name) then
            table.insert(list, plant.Name)
        end
    end
    return list
end

-- Fungsi untuk mendapatkan stok seed
local function StripPlantStock(UnstrippedStock)
    local num = string.match(UnstrippedStock, "%d+")
    return num or 0
end

function getCropsListAndStock()
    local oldStock = CropsListAndStocks
    CropsListAndStocks = {}
    
    if Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop") and Players.LocalPlayer.PlayerGui.Seed_Shop.Enabled then
        for _, Plant in pairs(SeedShopGUI:GetChildren()) do
            if Plant:FindFirstChild("Main_Frame") and Plant.Main_Frame:FindFirstChild("Stock_Text") then
                local PlantName = Plant.Name
                local PlantStock = StripPlantStock(Plant.Main_Frame.Stock_Text.Text)
                CropsListAndStocks[PlantName] = PlantStock
            end
        end
    end
    
    return false
end

-- Fungsi untuk mendapatkan nama semua crops
local function getAllCropNames()
    local cropNames = {"None Selected"}
    for cropName, _ in pairs(CropsListAndStocks) do
        table.insert(cropNames, cropName)
    end
    table.sort(cropNames)
    return cropNames
end

-- Fungsi untuk membuka toko seed
local function openSeedShop()
    local humanoid = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    local originalPosition = HRP.CFrame
    humanoid:MoveTo(Sam.HumanoidRootPart.Position + Vector3.new(0, 0, 5))
    
    local startTime = tick()
    while (HRP.Position - Sam.HumanoidRootPart.Position).Magnitude > 10 and tick() - startTime < 5 do
        wait(0.1)
    end
    
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(0.5)
    
    if Sam:FindFirstChild("Head") and Sam.Head:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(Sam.Head.ProximityPrompt)
        wait(1)
        
        if Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop") and Players.LocalPlayer.PlayerGui.Seed_Shop.Enabled then
            getCropsListAndStock()
            return true
        end
    end
    
    HRP.CFrame = originalPosition
    return false
end

-- Fungsi untuk membeli seed
local function buyCropSeeds(cropName)
    if isBuying then return false end
    
    local args = {[1] = cropName}
    local success = pcall(function()
        BuySeedStock:FireServer(unpack(args))
    end)
    
    return success
end

-- Fungsi untuk membeli seed yang dipilih
local function buyWantedCropSeeds()
    if #wantedFruits == 0 or wantedFruits[1] == "None Selected" then
        print("Tidak ada seed yang dipilih")
        return false
    end
    
    if isBuying then return false end
    isBuying = true
    
    if not openSeedShop() then
        isBuying = false
        return false
    end
    
    getCropsListAndStock()
    local boughtAny = false
    
    for _, fruitName in ipairs(wantedFruits) do
        if fruitName ~= "None Selected" then
            local stock = tonumber(CropsListAndStocks[fruitName] or 0)
            if stock > 0 then
                for j = 1, stock do
                    if buyCropSeeds(fruitName) then
                        boughtAny = true
                        print("Membeli " .. fruitName .. " " .. j .. "/" .. stock)
                    end
                    wait(0.2)
                end
            end
        end
    end
    
    isBuying = false
    return boughtAny
end

-- Fungsi untuk sell semua items
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

-- Tab untuk Seed Stock
local stockTab = Window:CreateTab("Seed Stock", 4483345998)
stockTab:CreateSection("Informasi Stok Seed")

local stockInfo = stockTab:CreateParagraph({
    Title = "Status Stok Seed",
    Content = "Klik 'Refresh Stock' untuk melihat stok terkini"
})

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
                Content = stockText ~= "" and stockText or "Toko belum terbuka"
            })
        end
    end,
})

-- Tab untuk NPC Sam
local npcTab = Window:CreateTab("NPC Sam", 4483345998)
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

-- Tab untuk Pembelian Seed
local buyTab = Window:CreateTab("Beli Seed", 4483345998)
buyTab:CreateSection("Pilihan Seed")

local seedDropdown = buyTab:CreateDropdown({
   Name = "Pilih Seed untuk Dibeli",
   Options = {"None Selected"},
   CurrentOption = "None Selected",
   MultipleOptions = true,
   Callback = function(Options)
        wantedFruits = Options
        print("Seed dipilih: " .. table.concat(Options, ", "))
   end,
})

buyTab:CreateButton({
    Name = "Refresh Daftar Seed",
    Callback = function()
        if openSeedShop() then
            getCropsListAndStock()
            seedDropdown:Refresh(getAllCropNames())
        end
    end,
})

buyTab:CreateToggle({
    Name = "Auto-Buy Seed",
    CurrentValue = false,
    Callback = function(Value)
        autoBuyEnabled = Value
    end,
})

buyTab:CreateButton({
    Name = "Beli Seed yang Dipilih",
    Callback = function()
        buyWantedCropSeeds()
    end,
})

-- Tab untuk Plants
local plantsTab = Window:CreateTab("Plants", 10734961427)
plantsTab:CreateSection("Remove Plants")

local PlantToRemoveDropdown = plantsTab:CreateDropdown({
   Name = "Pilih Tanaman untuk Dihapus",
   Options = getPlantedFruitTypes(),
   CurrentOption = "None Selected",
   Callback = function(Option)
        plantToRemove = {Option}
   end,
})

plantsTab:CreateButton({
    Name = "Refresh Daftar Tanaman",
    Callback = function()
        PlantToRemoveDropdown:Refresh(getPlantedFruitTypes())
    end,
})

plantsTab:CreateButton({
    Name = "Hapus Tanaman Terpilih",
    Callback = function()
        removePlantsOfKind(plantToRemove)
    end,
})

plantsTab:CreateSection("Harvesting")
plantsTab:CreateToggle({
    Name = "Auto Harvest Aura",
    CurrentValue = false,
    Callback = function(Value)
        plantAura = Value
    end,
})

-- Tab untuk Sell
local sellTab = Window:CreateTab("Sell", 10734922680)
sellTab:CreateSection("Auto Sell Settings")

sellTab:CreateToggle({
    Name = "Auto Sell Items",
    CurrentValue = false,
    Callback = function(Value)
        shouldSell = Value
    end,
})

sellTab:CreateSlider({
   Name = "Jumlah Minimum Items untuk Auto Sell",
   Range = {1, 200},
   Increment = 1,
   Suffix = "Items",
   CurrentValue = 70,
   Callback = function(Value)
        AutoSellItems = Value
   end,
})

sellTab:CreateButton({
    Name = "Sell Semua Sekarang",
    Callback = function()
        sellAll()
    end,
})

-- Tab untuk Player Settings
local playerTab = Window:CreateTab("Player Settings", 10734923139)
playerTab:CreateSection("Character Settings")

local speedSlider = playerTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 200},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = 16,
   Callback = function(Value)
        Humanoid.WalkSpeed = Value
   end,
})

local jumpSlider = playerTab:CreateSlider({
   Name = "Jump Power",
   Range = {50, 200},
   Increment = 5,
   Suffix = "Jump Power",
   CurrentValue = 50,
   Callback = function(Value)
        Humanoid.JumpPower = Value
   end,
})

playerTab:CreateButton({
    Name = "Reset Settings",
    Callback = function()
        speedSlider:Set(16)
        jumpSlider:Set(50)
    end,
})

-- Load UI
print("Grow A Garden Automation Loaded!")
Rayfield:LoadConfiguration()
