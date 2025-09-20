-- Script untuk membeli seeds dari NPC Sam di Grow Garden
-- Versi Terbaru untuk Delta Executor - Termasuk Carrot

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/ThemeManager.lua"))()

local Window = library:CreateWindow({
    Title = "Grow Garden - Auto Buy Seeds",
    Center = true,
    AutoShow = true
})

local Tabs = {
    Main = Window:AddTab("Main"),
    ['NPC Locations'] = Window:AddTab("NPC Locations"),
    Settings = Window:AddTab("Settings")
}

local AutoBuySection = Tabs.Main:AddLeftGroupbox("Auto Buy Seeds")
local NPCInfoSection = Tabs.Main:AddRightGroupbox("NPC Information")
local TeleportSection = Tabs['NPC Locations']:AddLeftGroupbox("Teleport to NPCs")

-- Variabel untuk Auto Buy
local buyingEnabled = false
local selectedSeed = "Sunflower"
local buyAmount = 1
local buyDelay = 1

-- Daftar seeds yang tersedia dari NPC Sam (termasuk Carrot)
local availableSeeds = {
    "Sunflower",
    "Tulip",
    "Rose",
    "Daisy",
    "Lavender",
    "Cactus",
    "Aloe",
    "Venus Flytrap",
    "Carrot"  -- Seed Carrot yang diminta
}

-- Informasi NPC (nama dan posisi)
local npcLocations = {
    Sam = {x = 125, y = 25, z = -45},  -- Contoh posisi, sesuaikan dengan game
    Lily = {x = 80, y = 25, z = -20},
    Ben = {x = 160, y = 25, z = 10}
}

-- Fungsi untuk mencari NPC Sam
function findSamNPC()
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then
        -- Coba mencari di tempat lain
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "Sam" or string.find(obj.Name:lower(), "sam") then
                return obj
            end
        end
        return nil
    end
    
    for _, npc in ipairs(npcs:GetChildren()) do
        if npc.Name == "Sam" or string.find(npc.Name:lower(), "sam") then
            return npc
        end
    end
    
    -- Coba mencari di tempat lain jika tidak ditemukan di folder NPCs
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "Sam" or string.find(obj.Name:lower(), "sam") then
            return obj
        end
    end
    
    return nil
end

-- Fungsi untuk teleport ke NPC
function teleportToNPC(npcName)
    if npcLocations[npcName] then
        local pos = npcLocations[npcName]
        local humanoidRootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CFrame = CFrame.new(pos.x, pos.y, pos.z)
            library:Notify("Teleported to " .. npcName, 3)
        end
    else
        library:Notify("NPC " .. npcName .. " location not defined!", 3)
    end
end

-- Fungsi untuk membeli seed
function buySeed(seedName, amount)
    local sam = findSamNPC()
    if not sam then
        library:Notify("NPC Sam tidak ditemukan! Gunakan teleport untuk menemukannya.", 3)
        return false
    end
    
    local humanoidRootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        library:Notify("Character not found!", 3)
        return false 
    end
    
    -- Teleport ke NPC Sam
    local samPosition = sam:FindFirstChild("HumanoidRootPart") or sam:FindFirstChild("Head") or sam:FindFirstChild("Torso")
    if samPosition then
        humanoidRootPart.CFrame = CFrame.new(samPosition.Position + Vector3.new(0, 3, 0))
        task.wait(0.5)
    end
    
    -- Interaksi dengan NPC
    local interaction = sam:FindFirstChild("Interaction") or findProximityPrompt(sam)
    if interaction then
        fireproximityprompt(interaction, 0)
        task.wait(0.5)
        
        -- Cari GUI untuk membeli seeds
        local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local shopScreen = playerGui:FindFirstChild("ShopScreen") or playerGui:FindFirstChild("SeedShop") or playerGui:FindFirstChild("Shop")
            if shopScreen and (shopScreen.Enabled or shopScreen.Visible) then
                -- Logic untuk memilih seed tertentu
                for _, seed in ipairs(availableSeeds) do
                    if seed == seedName then
                        -- Simulasi klik pada seed yang dipilih
                        for i = 1, amount do
                            local buyButton = findBuyButton(seedName)
                            if buyButton then
                                if buyButton:IsA("TextButton") or buyButton:IsA("ImageButton") then
                                    -- Untuk button GUI
                                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(
                                        buyButton.AbsolutePosition.X + buyButton.AbsoluteSize.X/2,
                                        buyButton.AbsolutePosition.Y + buyButton.AbsoluteSize.Y/2,
                                        0, true, game, 1
                                    )
                                    task.wait(0.1)
                                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(
                                        buyButton.AbsolutePosition.X + buyButton.AbsoluteSize.X/2,
                                        buyButton.AbsolutePosition.Y + buyButton.AbsoluteSize.Y/2,
                                        0, false, game, 1
                                    )
                                else
                                    -- Untuk ClickDetector
                                    fireclickdetector(buyButton)
                                end
                                task.wait(buyDelay)
                            else
                                library:Notify("Buy button for " .. seedName .. " not found!", 3)
                            end
                        end
                        return true
                    end
                end
            else
                library:Notify("Shop screen not found!", 3)
            end
        end
    else
        library:Notify("Interaction not found on NPC Sam!", 3)
    end
    
    return false
end

-- Fungsi untuk mencari ProximityPrompt
function findProximityPrompt(model)
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("ProximityPrompt") then
            return child
        end
    end
    return nil
end

-- Fungsi untuk mencari tombol buy (mungkin perlu disesuaikan)
function findBuyButton(seedName)
    -- Implementasi ini tergantung pada struktur UI game
    local playerGui = game.Players.LocalPlayer.PlayerGui
    local shopFrame = playerGui:FindFirstChild("ShopFrame") or 
                     playerGui:FindFirstChild("SeedShopFrame") or 
                     playerGui:FindFirstChild("ShopGui")
    
    if shopFrame then
        -- Cari berdasarkan nama yang mengandung seed name
        for _, child in ipairs(shopFrame:GetDescendants()) do
            if (child:IsA("TextButton") or child:IsA("ImageButton")) and 
               (child.Name == "BuyButton" or string.find(child.Name:lower(), "buy")) then
                if child.Parent and (string.find(child.Parent.Name:lower(), seedName:lower()) or
                   string.find(child.Parent.Parent.Name:lower(), seedName:lower())) then
                    return child
                end
            end
        end
        
        -- Cari berdasarkan teks yang mengandung seed name
        for _, child in ipairs(shopFrame:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                if child.Text and string.find(child.Text:lower(), seedName:lower()) then
                    local buyButton = findBuyButtonNear(child)
                    if buyButton then return buyButton end
                end
            end
        end
    end
    
    -- Coba mencari di workspace untuk model dengan click detector
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") and obj.Parent then
            if string.find(obj.Parent.Name:lower(), seedName:lower()) then
                return obj
            end
        end
    end
    
    return nil
end

-- Fungsi untuk mencari tombol buy di sekitar objek
function findBuyButtonNear(obj)
    local parent = obj.Parent
    if not parent then return nil end
    
    for _, sibling in ipairs(parent:GetChildren()) do
        if (sibling:IsA("TextButton") or sibling:IsA("ImageButton")) and 
           (sibling.Name == "BuyButton" or string.find(sibling.Name:lower(), "buy")) then
            return sibling
        end
    end
    
    return nil
end

-- UI Elements
AutoBuySection:AddDropdown("SelectedSeed", {
    Values = availableSeeds,
    Default = 1,
    Multi = false,
    Text = "Pilih Seed",
    Tooltip = "Pilih jenis seed yang ingin dibeli"
})

AutoBuySection:AddSlider("BuyAmount", {
    Min = 1,
    Max = 100,
    Default = 1,
    Rounding = 0,
    Compact = false,
    Text = "Jumlah yang dibeli",
    Tooltip = "Jumlah seed yang akan dibeli per transaksi"
})

AutoBuySection:AddSlider("BuyDelay", {
    Min = 0.5,
    Max = 5,
    Default = 1,
    Rounding = 1,
    Compact = false,
    Text = "Delay (detik)",
    Tooltip = "Delay antara setiap pembelian"
})

AutoBuySection:AddToggle("AutoBuyEnabled", {
    Text = "Aktifkan Auto Buy",
    Default = false,
    Tooltip = "Mulai membeli seed secara otomatis"
})

AutoBuySection:AddButton("Beli Sekarang", function()
    buySeed(Options.SelectedSeed.Value, Options.BuyAmount.Value)
end)

-- Teleport buttons untuk NPC Locations tab
for npcName, _ in pairs(npcLocations) do
    TeleportSection:AddButton("Teleport to " .. npcName, function()
        teleportToNPC(npcName)
    end)
end

-- Update variables when options change
Options.SelectedSeed:OnChanged(function()
    selectedSeed = Options.SelectedSeed.Value
end)

Options.BuyAmount:OnChanged(function()
    buyAmount = Options.BuyAmount.Value
end)

Options.BuyDelay:OnChanged(function()
    buyDelay = Options.BuyDelay.Value
end)

Options.AutoBuyEnabled:OnChanged(function()
    buyingEnabled = Options.AutoBuyEnabled.Value
end)

-- Auto Buy Loop
task.spawn(function()
    while true do
        if buyingEnabled then
            buySeed(selectedSeed, buyAmount)
        end
        task.wait(buyDelay)
    end
end)

-- NPC Information Section
task.spawn(function()
    while true do
        local sam = findSamNPC()
        if sam then
            local position = sam:FindFirstChild("HumanoidRootPart") or sam:FindFirstChild("Head") or sam:FindFirstChild("Torso")
            if position then
                NPCInfoSection:AddLabel("Sam Position: " .. tostring(math.floor(position.Position.X)) .. 
                                       ", " .. tostring(math.floor(position.Position.Y)) .. 
                                       ", " .. tostring(math.floor(position.Position.Z)))
            else
                NPCInfoSection:AddLabel("Sam Position: Tidak dapat ditemukan")
            end
        else
            NPCInfoSection:AddLabel("NPC Sam: Tidak ditemukan")
        end
        task.wait(5)
    end
end)

-- Settings Tab
library:SetWatermark('Grow Garden Auto Buy | Delta Executor')
library:OnUnload(function()
    print('Unloaded!')
    getgenv().AutoBuy = false
end)

ThemeManager:SetLibrary(library)
ThemeManager:SetFolder('GrowGarden')
ThemeManager:ApplyToTab(Tabs.Settings)

library:Notify("Script loaded successfully! Seed Carrot telah ditambahkan.")
