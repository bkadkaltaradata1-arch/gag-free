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

-- Fungsi untuk membuka toko biji
local function openSeedShop()
    if not Sam:FindFirstChild("Head") then return false end
    
    -- Pastikan kita dekat dengan NPC Sam
    local distance = (HRP.Position - Sam.Head.Position).Magnitude
    if distance > 20 then
        HRP.CFrame = Sam.Head.CFrame + Vector3.new(0, 0, 5)
        wait(1)
    end
    
    -- Aktifkan ProximityPrompt untuk membuka toko
    for _, prompt in pairs(Sam:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            fireproximityprompt(prompt)
            wait(0.5)
            return true
        end
    end
    
    return false
end

-- Fungsi untuk menutup toko biji
local function closeSeedShop()
    local seedShopGUI = Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop")
    if seedShopGUI then
        -- Cari tombol close (biasanya berupa ImageButton dengan nama "Close" atau "Exit")
        for _, child in pairs(seedShopGUI:GetDescendants()) do
            if child:IsA("ImageButton") and (child.Name:lower():find("close") or child.Name:lower():find("exit")) then
                firesignal(child.MouseButton1Click)
                wait(0.5)
                return true
            end
        end
    end
    return false
end

local function findPlayerFarm()
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important.Data.Owner.Value == Players.LocalPlayer.Name then
            return v
        end
    end
    return nil
end

-- ... (kode lainnya tetap sama) ...

function getCropsListAndStock()
    local oldStock = CropsListAndStocks
    CropsListAndStocks = {} -- Reset the table
    
    -- Pastikan GUI toko terbuka dan terload
    if not SeedShopGUI or not SeedShopGUI:FindFirstChildWhichIsA("Frame") then
        print("Seed shop GUI not ready")
        return false
    end
    
    for _,Plant in pairs(SeedShopGUI:GetChildren()) do
        if Plant:IsA("Frame") and Plant:FindFirstChild("Main_Frame") then
            local mainFrame = Plant.Main_Frame
            if mainFrame:FindFirstChild("Stock_Text") then
                local PlantName = Plant.Name
                local stockText = mainFrame.Stock_Text.Text
                local PlantStock = tonumber(string.match(stockText, "%d+") or 0)
                CropsListAndStocks[PlantName] = PlantStock
                print("Found crop:", PlantName, "Stock:", PlantStock)
            end
        end
    end
    
    -- Cek jika stok berubah (toko di-refresh)
    local isRefreshed = false
    for cropName, stock in pairs(CropsListAndStocks) do
        if oldStock[cropName] ~= stock then
            isRefreshed = true
            print("Stock changed for", cropName, "from", oldStock[cropName], "to", stock)
            break
        end
    end
    
    return isRefreshed
end

-- ... (kode lainnya) ...

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
    
    -- Buka toko terlebih dahulu
    if not openSeedShop() then
        print("Failed to open seed shop")
        isBuying = false
        return false
    end
    
    wait(2) -- Tunggu GUI toko terbuka sepenuhnya
    
    -- Refresh data stok
    getCropsListAndStock()
    
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
                    wait(0.3) -- Tunggu sebentar antara pembelian
                else
                    print("Failed to buy "..fruitName)
                end
            end
        else
            print("No stock for "..fruitName)
        end
    end
    
    -- Tutup toko
    closeSeedShop()
    
    -- Kembali ke posisi semula
    wait(0.5)
    HRP.CFrame = beforePos
    
    isBuying = false
    return boughtAny
end

-- ... (kode lainnya) ...

spawn(function() 
    while true do
        if shopTimer and shopTimer.Text then
            shopTime = getTimeInSeconds(shopTimer.Text)
            local shopTimeText = "Shop Resets in " .. shopTime .. "s"
            RayFieldShopTimer:Set({Title = "Shop Timer", Content = shopTimeText})
            
            -- Auto-buy ketika toko refresh (timer reset)
            if shopTime >= 178 and shopTime <= 180 and autoBuyEnabled and not isBuying then
                print("Shop about to refresh, preparing to auto-buy...")
                wait(3) -- Tunggu refresh selesai
                
                if autoBuyEnabled and #wantedFruits > 0 then
                    print("Shop refreshed, auto-buying...")
                    buyWantedCropSeeds()
                end
            end
        end
        
        if shouldSell and #(Backpack:GetChildren()) >= AutoSellItems and not isSelling then
            sellAll()
        end
        
        wait(0.5)
    end
end)

-- ... (kode lainnya) ...
