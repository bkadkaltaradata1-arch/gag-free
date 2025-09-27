-- LocalScript di StarterPlayerScripts
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Tunggu sampai player ready
player:WaitForChild("PlayerGui")

-- Variabel untuk menyimpan riwayat kegiatan
local activityHistory = {}
local MAX_HISTORY = 50 -- Maksimal riwayat yang disimpan

-- Buat UI debug utama
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ButtonDebugGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 120)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.95, 0, 0.9, 0)
label.Position = UDim2.new(0.025, 0, 0.05, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Text = "Klik tombol untuk melihat debug info..."
label.TextWrapped = true
label.Font = Enum.Font.Code
label.TextSize = 16
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.2, 0)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.BackgroundTransparency = 0.2
title.TextColor3 = Color3.fromRGB(255, 255, 0)
title.Text = "DEBUG BUTTON INFO"
title.Font = Enum.Font.Code
title.TextSize = 14
title.Parent = frame

local cornerTitle = Instance.new("UICorner")
cornerTitle.CornerRadius = UDim.new(0, 8)
cornerTitle.Parent = title

-- Buat UI untuk riwayat kegiatan (bisa di-toggle)
local historyFrame = Instance.new("Frame")
historyFrame.Size = UDim2.new(0, 400, 0, 200)
historyFrame.Position = UDim2.new(0, 10, 0, 140)
historyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
historyFrame.BackgroundTransparency = 0.3
historyFrame.BorderSizePixel = 2
historyFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
historyFrame.Visible = false -- Awalnya tersembunyi
historyFrame.Parent = screenGui

local historyCorner = Instance.new("UICorner")
historyCorner.CornerRadius = UDim.new(0, 8)
historyCorner.Parent = historyFrame

local historyTitle = Instance.new("TextLabel")
historyTitle.Size = UDim2.new(1, 0, 0.15, 0)
historyTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
historyTitle.BackgroundTransparency = 0.2
historyTitle.TextColor3 = Color3.fromRGB(255, 255, 0)
historyTitle.Text = "ACTIVITY HISTORY (0)"
historyTitle.Font = Enum.Font.Code
historyTitle.TextSize = 14
historyTitle.Parent = historyFrame

local historyScroll = Instance.new("ScrollingFrame")
historyScroll.Size = UDim2.new(0.95, 0, 0.8, 0)
historyScroll.Position = UDim2.new(0.025, 0, 0.2, 0)
historyScroll.BackgroundTransparency = 1
historyScroll.BorderSizePixel = 0
historyScroll.ScrollBarThickness = 6
historyScroll.Parent = historyFrame

local historyLayout = Instance.new("UIListLayout")
historyLayout.Padding = UDim.new(0, 5)
historyLayout.Parent = historyScroll

-- Tombol untuk toggle history
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 120, 0, 25)
toggleButton.Position = UDim2.new(0, 230, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "Show History"
toggleButton.Font = Enum.Font.Code
toggleButton.TextSize = 12
toggleButton.Parent = frame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 4)
toggleCorner.Parent = toggleButton

print("Debug UI berhasil dibuat!")

-- Fungsi untuk menambahkan kegiatan ke riwayat
local function addToHistory(buttonName, additionalInfo)
    local character = player.Character
    local charName = "No Character"
    local position = "Unknown"
    
    if character and character:FindFirstChild("HumanoidRootPart") then
        charName = character.Name
        local pos = character.HumanoidRootPart.Position
        position = string.format("X:%.1f, Y:%.1f, Z:%.1f", pos.X, pos.Y, pos.Z)
    end
    
    local activity = {
        timestamp = os.date("%H:%M:%S"),
        buttonName = buttonName,
        character = charName,
        position = position,
        info = additionalInfo or ""
    }
    
    table.insert(activityHistory, 1, activity) -- Masukkan di awal
    
    -- Batasi jumlah riwayat
    if #activityHistory > MAX_HISTORY then
        table.remove(activityHistory, MAX_HISTORY + 1)
    end
    
    -- Update tampilan riwayat
    updateHistoryDisplay()
    
    return activity
end

-- Fungsi untuk update tampilan riwayat
local function updateHistoryDisplay()
    historyTitle.Text = "ACTIVITY HISTORY (" .. #activityHistory .. ")"
    
    -- Hapus entri lama
    for _, child in ipairs(historyScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Tambah entri baru
    for i, activity in ipairs(activityHistory) do
        local entry = Instance.new("TextLabel")
        entry.Size = UDim2.new(1, 0, 0, 40)
        entry.BackgroundTransparency = 1
        entry.TextColor3 = Color3.fromRGB(255, 255, 255)
        entry.Text = string.format("[%s] %s\n%s @ %s", 
            activity.timestamp, 
            activity.buttonName,
            activity.character,
            activity.position)
        entry.TextWrapped = true
        entry.Font = Enum.Font.Code
        entry.TextSize = 12
        entry.TextXAlignment = Enum.TextXAlignment.Left
        entry.Parent = historyScroll
        
        -- Warna bergantian untuk readability
        if i % 2 == 0 then
            entry.BackgroundTransparency = 0.8
            entry.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
    
    -- Auto-scroll ke atas
    historyScroll.CanvasPosition = Vector2.new(0, 0)
end

-- Fungsi untuk update debug info
local function updateDebugInfo(buttonName, additionalInfo)
    local activity = addToHistory(buttonName, additionalInfo)
    
    local debugText = string.format([[
Tombol: %s
Karakter: %s
Posisi: %s
Waktu: %s
%s
    ]], 
    buttonName, 
    activity.character,
    activity.position,
    activity.timestamp,
    additionalInfo or "")
    
    label.Text = debugText
    
    -- Print ke console juga
    print("=== DEBUG BUTTON ===")
    print("Tombol: " .. buttonName)
    print("Karakter: " .. activity.character)
    print("Posisi: " .. activity.position)
    print("Waktu: " .. activity.timestamp)
    if additionalInfo and additionalInfo ~= "" then
        print("Info: " .. additionalInfo)
    end
    print("====================")
end

-- Fungsi untuk toggle tampilan history
local function toggleHistory()
    historyFrame.Visible = not historyFrame.Visible
    if historyFrame.Visible then
        toggleButton.Text = "Hide History"
        updateHistoryDisplay()
    else
        toggleButton.Text = "Show History"
    end
end

toggleButton.MouseButton1Click:Connect(toggleHistory)

-- Method 1: Direct button connection (Lebih reliable)
local function connectToButtons()
    -- Tunggu sebentar untuk memastikan GUI sudah dimuat
    wait(2)
    
    local guis = player.PlayerGui:GetDescendants()
    local buttonCount = 0
    
    for _, guiElement in ipairs(guis) do
        if guiElement:IsA("TextButton") or guiElement:IsA("ImageButton") then
            -- Hapus connection lama jika ada
            for _, connection in ipairs(getconnections(guiElement.MouseButton1Click)) do
                connection:Disconnect()
            end
            
            -- Tambah connection baru
            guiElement.MouseButton1Click:Connect(function()
                local additionalInfo = ""
                if guiElement:IsA("TextButton") then
                    additionalInfo = "Teks: " .. guiElement.Text
                end
                
                updateDebugInfo(guiElement.Name, additionalInfo)
                
                -- Highlight effect dengan tween
                local originalBg = guiElement.BackgroundColor3
                local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tween = TweenService:Create(guiElement, tweenInfo, {BackgroundColor3 = Color3.fromRGB(0, 255, 0)})
                tween:Play()
                
                tween.Completed:Connect(function()
                    local revertTween = TweenService:Create(guiElement, tweenInfo, {BackgroundColor3 = originalBg})
                    revertTween:Play()
                end)
            end)
            
            buttonCount += 1
            print("Debug connected to button: " .. guiElement.Name)
        end
    end
    
    print("Total buttons connected: " .. buttonCount)
    
    if buttonCount == 0 then
        updateDebugInfo("No Buttons Found", "Pastikan GUI sudah dimuat")
    end
end

-- Method 2: Input detection untuk backup
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Cari tombol yang diklik menggunakan Raycast
        local mousePos = UserInputService:GetMouseLocation()
        
        for _, gui in ipairs(player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local buttons = gui:GetDescendants()
                for _, button in ipairs(buttons) do
                    if (button:IsA("TextButton") or button:IsA("ImageButton")) and button.Visible then
                        -- Simple position check (basic detection)
                        updateDebugInfo("Mouse Click", "Position: " .. tostring(mousePos))
                        break
                    end
                end
            end
        end
    end
end)

-- Auto-reconnect ketika GUI berubah
player.PlayerGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") then
        wait(1) -- Tunggu GUI loading
        connectToButtons()
    end
end)

-- Fungsi untuk ekspor riwayat (debug purposes)
local function exportHistory()
    local exportText = "=== BUTTON ACTIVITY HISTORY ===\n"
    for i, activity in ipairs(activityHistory) do
        exportText = exportText .. string.format("%d. [%s] %s - %s @ %s\n", 
            i, activity.timestamp, activity.buttonName, activity.character, activity.position)
        if activity.info ~= "" then
            exportText = exportText .. "   Info: " .. activity.info .. "\n"
        end
    end
    print(exportText)
end

-- Hotkey untuk ekspor riwayat (Ctrl+H)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.H and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        exportHistory()
        print("History exported to console!")
    end
end)

-- Jalankan pertama kali
connectToButtons()

-- Update waktu secara real-time
while true do
    wait(1)
    -- Refresh waktu setiap detik
    if label.Text ~= "Klik tombol untuk melihat debug info..." then
        local currentText = label.Text
        local newText = string.gsub(currentText, "Waktu: %d+:%d+:%d+", "Waktu: " .. os.date("%H:%M:%S"))
        label.Text = newText
    end
end
