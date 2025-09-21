local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local BuySeedStock = ReplicatedStorage.GameEvents.BuySeedStock
local Sam = Workspace.NPCS.Sam
local HRP = Players.LocalPlayer.Character.HumanoidRootPart

local CropsListAndStocks = {}
local SeedShopGUI = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame.ScrollingFrame
local shopTimer = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame.Frame.Timer
local shopTime = 0
local wantedFruits = {}
local autoBuyEnabled = false
local isBuying = false

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Grow A Garden - Seed System",
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

-- Fungsi untuk mendapatkan stok seed dari GUI toko
function getCropsListAndStock()
    local oldStock = CropsListAndStocks
    CropsListAndStocks = {} -- Reset tabel
    
    for _, Plant in pairs(SeedShopGUI:GetChildren()) do
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

-- Fungsi untuk mengekstrak angka dari teks stok
local function StripPlantStock(UnstrippedStock)
    local num = string.match(UnstrippedStock, "%d+")
    return num
end

-- Fungsi untuk mencetak stok seed
local function printCropStocks()
    print("=== SEED STOCK INFORMATION ===")
    for cropName, stock in pairs(CropsListAndStocks) do
        print(cropName .. "'s Stock Is: " .. stock)
    end
    print("==============================")
end

-- Fungsi untuk mendapatkan daftar semua tanaman yang tersedia
local function getAllCropNames()
    local cropNames = {}
    for cropName, _ in pairs(CropsListAndStocks) do
        table.insert(cropNames, cropName)
    end
    table.sort(cropNames)
    return cropNames
end

-- Fungsi untuk membuka toko seed dengan berinteraksi dengan NPC Sam
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

-- Fungsi untuk membeli seed tertentu
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

-- Fungsi untuk membeli semua seed yang dipilih
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

-- System untuk memantau refresh toko dan auto-buy
spawn(function() 
    while true do
        if shopTimer and shopTimer.Text then
            -- Update timer display jika diperlukan
            shopTime = getTimeInSeconds(shopTimer.Text)
            
            -- Cek jika toko di-refresh
            local isRefreshed = getCropsListAndStock()
            
            if isRefreshed and autoBuyEnabled and not isBuying then
                print("Toko di-refresh, melakukan auto-buy...")
                wait(2)  -- Tunggu sebentar sebelum membeli
                buyWantedCropSeeds()
            end
        end
        wait(1)
    end
end)

-- Fungsi pembantu untuk konversi waktu
local function getTimeInSeconds(input)
    if not input then return 0 end
    local minutes = tonumber(input:match("(%d+)m")) or 0
    local seconds = tonumber(input:match("(%d+)s")) or 0
    return minutes * 60 + seconds
end

-- Inisialisasi awal
print("Sistem Seed Grow A Garden loaded successfully!")
