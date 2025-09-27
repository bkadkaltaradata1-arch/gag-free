-- Lot di StarterPlayerScripts
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Tunggu sampai player ready
player:WaitForChild("PlayerGui")

-- Buat UI debug
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

print("Debug UI berhasil dibuat!")

-- Fungsi untuk update debug info
local function updateDebugInfo(buttonName, additionalInfo)
    local character = player.Character
    local charName = "No Character"
    local position = "Unknown"
    
    if character and character:FindFirstChild("HumanoidRootPart") then
        charName = character.Name
        local pos = character.HumanoidRootPart.Position
        position = string.format("X:%.1f, Y:%.1f, Z:%.1f", pos.X, pos.Y, pos.Z)
    end
    
    local debugText = string.format([[
Tombol: %s
Karakter: %s
Posisi: %s
Waktu: %s
%s
    ]], 
    buttonName, 
    charName,
    position,
    os.date("%H:%M:%S"),
    additionalInfo or "")
    
    label.Text = debugText
    
    -- Print ke console juga
    print("=== DEBUG BUTTON ===")
    print("Tombol: " .. buttonName)
    print("Karakter: " .. charName)
    print("Posisi: " .. position)
    print("====================")
end

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
                
                -- Highlight effect
                local originalBg = guiElement.BackgroundColor3
                guiElement.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                wait(0.1)
                guiElement.BackgroundColor3 = originalBg
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
