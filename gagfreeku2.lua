-- Kode yang sudah diperbaiki dari respons sebelumnya
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Menggunakan WaitForChild untuk memastikan objek sudah dimuat
local player = Players.LocalPlayer
local Backpack = player:WaitForChild("Backpack")
local Character = player.Character or player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local FarmsFolder = Workspace:WaitForChild("Farm")
local BuySeedStock = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock")
local Plant = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Plant_RE")
local sellAllRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory")
local Steven = Workspace:WaitForChild("NPCS"):WaitForChild("Steven")
local Sam = Workspace:WaitForChild("NPCS"):WaitForChild("Sam")
local removeItem = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

-- Variabel dan GUI
local CropsListAndStocks = {}
local SeedShopGUI = player.PlayerGui:WaitForChild("Seed_Shop").Frame.ScrollingFrame
local shopTimer = player.PlayerGui.Seed_Shop.Frame.Frame.Timer

local plantAura = false
local AutoSellItems = 70
local shouldSell = false
local plantToRemove
local shouldAutoPlant = false
local isSelling = false
local autoBuyEnabled = false
local lastShopStock = {}
local isBuying = false
local wantedFruits = {}

-- Load Rayfield UI
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

-- Fungsi-fungsi utama
local function findPlayerFarm()
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important.Data.Owner.Value == player.Name then
            return v
        end
    end
    return nil
end

local function StripPlantStock(UnstrippedStock)
    local num = string.match(UnstrippedStock, "%d+")
    return num and tonumber(num) or 0
end

local function getCropsListAndStock()
    local oldStock = lastShopStock
    local newStock = {}
    for _, Plant in pairs(SeedShopGUI:GetChildren()) do
        if Plant:FindFirstChild("Main_Frame") and Plant.Main_Frame:FindFirstChild("Stock_Text") then
            local PlantName = Plant.Name
            local PlantStock = StripPlantStock(Plant.Main_Frame.Stock_Text.Text)
            newStock[PlantName] = PlantStock
        end
    end
    
    local isRefreshed = false
    if next(oldStock) == nil or table.getn(oldStock) == 0 then
        isRefreshed = true
    else
        for cropName, stock in pairs(newStock) do
            if oldStock[cropName] ~= stock then
                isRefreshed = true
                break
            end
        end
    end
    
    CropsListAndStocks = newStock
    lastShopStock = newStock
    return isRefreshed
end

local function buyCropSeeds(cropName)
    local args = {[1] = cropName}
    -- Menggunakan pcall untuk menghindari script crash
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
    if not Character or not HRP or not Sam or isBuying then
        return false
    end
    if #wantedFruits == 0 then
        print("No fruits selected to buy.")
        return false
    end
    
    isBuying = true
    local beforePos = HRP.CFrame
    
    -- Pindahkan karakter dengan aman dan tunggu
    pcall(function() HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4) end)
    task.wait(1.5)
    
    -- Hadapkan karakter ke NPC
    pcall(function() HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position) end)
    task.wait(0.5)
    
    local boughtAny = false
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        print("Trying to buy "..fruitName..", stock: "..tostring(stock))
        
        if stock > 0 then
            for j = 1, stock do
                if buyCropSeeds(fruitName) then
                    boughtAny = true
                    print("Bought "..fruitName.." seed "..j.."/"..stock)
                else
                    print("Failed to buy "..fruitName.." - stopping.")
                    break
                end
                task.wait(0.2)
            end
        else
            print("No stock for "..fruitName)
        end
    end
    
    -- Kembali ke posisi semula dengan pcall
    task.wait(0.5)
    pcall(function() HRP.CFrame = beforePos end)
    isBuying = false
    return boughtAny
end

-- Loop utama untuk auto-buy dan auto-sell
spawn(function()
    while task.wait(0.5) do
        local isRefreshed = getCropsListAndStock()
        if isRefreshed and autoBuyEnabled and not isBuying then
            print("Shop refreshed, auto-buying...")
            task.spawn(buyWantedCropSeeds)
        end
    end
end)

-- UI
local seedsTab = Window:CreateTab("Seeds")
seedsTab:CreateDropdown({
   Name = "Fruits To Buy",
   Options = {},
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
        wantedFruits = filtered
   end,
})

seedsTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(Value)
        autoBuyEnabled = Value
        if Value and #wantedFruits > 0 and not isBuying then
            task.spawn(buyWantedCropSeeds)
        end
    end,
})

-- Tambahkan fungsi untuk refresh dropdown secara otomatis
local function refreshDropdown()
    local options = {}
    for name, _ in pairs(CropsListAndStocks) do
        table.insert(options, name)
    end
    seedsTab:FindElement("Fruits To Buy"):Refresh(options)
end

-- Panggil refresh dropdown saat skrip pertama kali dimuat
getCropsListAndStock()
refreshDropdown()

print("Grow A Garden script loaded successfully!")
