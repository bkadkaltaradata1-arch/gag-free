-- Script Auto Buy Seed untuk Game "Grow a Garden"
-- Dioptimalkan untuk Delta Executor Mobile
-- Versi: 1.1a Mobile

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Variabel global
local AutoBuyEnabled = false
local AutoFarmEnabled = false
local SelectedSeed = "Sunflower"
local BuyDelay = 5
local FarmDelay = 10

-- Buat GUI sederhana untuk mobile
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileAutoBuyGUI"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Frame utama
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
MainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Judul
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0.1, 0)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "Grow a Garden Auto Seed"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Parent = MainFrame

-- Toggle Auto Buy
local AutoBuyToggle = Instance.new("TextButton")
AutoBuyToggle.Name = "AutoBuyToggle"
AutoBuyToggle.Size = UDim2.new(0.9, 0, 0.1, 0)
AutoBuyToggle.Position = UDim2.new(0.05, 0, 0.12, 0)
AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
AutoBuyToggle.Text = "Auto Buy: OFF"
AutoBuyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBuyToggle.TextScaled = true
AutoBuyToggle.Parent = MainFrame

-- Dropdown untuk seed type (simulasi dengan button cycle)
local SeedButton = Instance.new("TextButton")
SeedButton.Name = "SeedButton"
SeedButton.Size = UDim2.new(0.9, 0, 0.1, 0)
SeedButton.Position = UDim2.new(0.05, 0, 0.25, 0)
SeedButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
SeedButton.Text = "Seed: Sunflower"
SeedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SeedButton.TextScaled = true
SeedButton.Parent = MainFrame

-- Slider untuk buy delay (simulasi dengan button)
local DelayButton = Instance.new("TextButton")
DelayButton.Name = "DelayButton"
DelayButton.Size = UDim2.new(0.9, 0, 0.1, 0)
DelayButton.Position = UDim2.new(0.05, 0, 0.38, 0)
DelayButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
DelayButton.Text = "Buy Delay: 5s"
DelayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayButton.TextScaled = true
DelayButton.Parent = MainFrame

-- Toggle Auto Farm
local AutoFarmToggle = Instance.new("TextButton")
AutoFarmToggle.Name = "AutoFarmToggle"
AutoFarmToggle.Size = UDim2.new(0.9, 0, 0.1, 0)
AutoFarmToggle.Position = UDim2.new(0.05, 0, 0.51, 0)
AutoFarmToggle.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
AutoFarmToggle.Text = "Auto Farm: OFF"
AutoFarmToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoFarmToggle.TextScaled = true
AutoFarmToggle.Parent = MainFrame

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
StatusLabel.Position = UDim2.new(0.05, 0, 0.64, 0)
StatusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
StatusLabel.Text = "Status: Tidak aktif"
StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
StatusLabel.TextScaled = true
StatusLabel.TextWrapped = true
StatusLabel.Parent = MainFrame

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0.4, 0, 0.1, 0)
CloseButton.Position = UDim2.new(0.05, 0, 0.82, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
CloseButton.Text = "Close"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextScaled = true
CloseButton.Parent = MainFrame

-- Open button (akan muncul setelah menutup)
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0.2, 0, 0.1, 0)
OpenButton.Position = UDim2.new(0.02, 0, 0.02, 0)
OpenButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
OpenButton.Text = "Open"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextScaled = true
OpenButton.Visible = false
OpenButton.Parent = ScreenGui

-- Daftar seed yang tersedia
local SeedTypes = {"Sunflower", "Tulip", "Rose", "Lavender", "Cactus", "All"}
local CurrentSeedIndex = 1

-- Fungsi untuk update status
local function updateStatus(message, color)
    StatusLabel.Text = "Status: " .. message
    StatusLabel.TextColor3 = color
end

-- Fungsi untuk mencari tombol seed di GUI game
local function findSeedButton(seedName)
    local gui = game:GetService("Players").LocalPlayer.PlayerGui
    local seedButtons = {}
    
    -- Cari semua screen GUI
    for _, screenGui in pairs(gui:GetChildren()) do
        if screenGui:IsA("ScreenGui") then
            -- Cari frame shop/store
            for _, child in pairs(screenGui:GetDescendants()) do
                if child:IsA("Frame") and (string.find(child.Name:lower(), "shop") or string.find(child.Name:lower(), "store")) then
                    -- Cari tombol seed di dalam shop
                    for _, element in pairs(child:GetDescendants()) do
                        if element:IsA("TextButton") and 
                          (string.find(element.Name:lower(), seedName:lower()) or 
                           string.find(element.Text:lower(), seedName:lower())) then
                            table.insert(seedButtons, element)
                        end
                    end
                end
            end
        end
    end
    
    return seedButtons
end

-- Fungsi untuk membeli seed
local function buySeed(seedName)
    if seedName == "All" then
        for _, seed in pairs(SeedTypes) do
            if seed ~= "All" and AutoBuyEnabled then
                buySeed(seed)
                wait(0.5)
            end
        end
        return true
    end
    
    local seedButtons = findSeedButton(seedName)
    
    for _, button in pairs(seedButtons) do
        if button.Visible then
            -- Coba klik tombol
            pcall(function()
                if button:FindFirstChildWhichIsA("RemoteEvent") then
                    button:FindFirstChildWhichIsA("RemoteEvent"):FireServer()
                elseif button:FindFirstChildWhichIsA("BindableEvent") then
                    button:FindFirstChildWhichIsA("BindableEvent"):Fire()
                else
                    -- Gunakan api send mouse button
                    if game:GetService("VirtualInputManager") then
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(
                            button.AbsolutePosition.X + button.AbsoluteSize.X/2,
                            button.AbsolutePosition.Y + button.AbsoluteSize.Y/2,
                            0, true, game, 0
                        )
                        wait()
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(
                            button.AbsolutePosition.X + button.AbsoluteSize.X/2,
                            button.AbsolutePosition.Y + button.AbsoluteSize.Y/2,
                            0, false, game, 0
                        )
                    else
                        button:Activate()
                    end
                end
            end)
            return true
        end
    end
    
    return false
end

-- Fungsi auto buy seed
local function autoBuySeed()
    while AutoBuyEnabled do
        local success = buySeed(SelectedSeed)
        
        if success then
            updateStatus("Berhasil membeli " .. SelectedSeed .. " - " .. os.date("%X"), Color3.fromRGB(100, 255, 100))
        else
            updateStatus("Gagal membeli " .. SelectedSeed .. " - " .. os.date("%X"), Color3.fromRGB(255, 100, 100))
        end
        
        wait(BuyDelay)
    end
end

-- Fungsi auto farm
local function autoFarm()
    while AutoFarmEnabled do
        -- Implementasi dasar auto farm
        updateStatus("Auto Farm aktif - " .. os.date("%X"), Color3.fromRGB(100, 200, 255))
        wait(FarmDelay)
    end
end

-- Event handlers untuk tombol
AutoBuyToggle.MouseButton1Click:Connect(function()
    AutoBuyEnabled = not AutoBuyEnabled
    if AutoBuyEnabled then
        AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        AutoBuyToggle.Text = "Auto Buy: ON"
        updateStatus("Auto Buy aktif", Color3.fromRGB(100, 255, 100))
        spawn(autoBuySeed)
    else
        AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        AutoBuyToggle.Text = "Auto Buy: OFF"
        updateStatus("Auto Buy nonaktif", Color3.fromRGB(255, 100, 100))
    end
end)

SeedButton.MouseButton1Click:Connect(function()
    CurrentSeedIndex = CurrentSeedIndex + 1
    if CurrentSeedIndex > #SeedTypes then
        CurrentSeedIndex = 1
    end
    SelectedSeed = SeedTypes[CurrentSeedIndex]
    SeedButton.Text = "Seed: " .. SelectedSeed
    updateStatus("Seed diubah: " .. SelectedSeed, Color3.fromRGB(200, 200, 100))
end)

DelayButton.MouseButton1Click:Connect(function()
    BuyDelay = BuyDelay + 5
    if BuyDelay > 30 then
        BuyDelay = 5
    end
    DelayButton.Text = "Buy Delay: " .. BuyDelay .. "s"
    updateStatus("Delay diubah: " .. BuyDelay .. "s", Color3.fromRGB(200, 200, 100))
end)

AutoFarmToggle.MouseButton1Click:Connect(function()
    AutoFarmEnabled = not AutoFarmEnabled
    if AutoFarmEnabled then
        AutoFarmToggle.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        AutoFarmToggle.Text = "Auto Farm: ON"
        updateStatus("Auto Farm aktif", Color3.fromRGB(100, 200, 255))
        spawn(autoFarm)
    else
        AutoFarmToggle.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        AutoFarmToggle.Text = "Auto Farm: OFF"
        updateStatus("Auto Farm nonaktif", Color3.fromRGB(255, 100, 100))
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)

-- Bukan GUI secara default
MainFrame.Visible = true
OpenButton.Visible = false

-- Notifikasi
updateStatus("Script loaded! Tap buttons to control", Color3.fromRGB(100, 200, 255))

-- Cleanup ketika script dihentikan
game:GetService("UserInputService").WindowFocusReleased:Connect(function()
    if not AutoBuyEnabled and not AutoFarmEnabled then
        ScreenGui:Destroy()
    end
end)
