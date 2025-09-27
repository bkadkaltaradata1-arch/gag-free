-- LocalScript di 
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Tunggu sampai player ready
if not player then
    player = Players.LocalPlayer
end

player:WaitForChild("PlayerGui")

-- Buat UI debug yang lebih besar
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedDebugGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 200)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.BackgroundTransparency = 0.1
title.TextColor3 = Color3.fromRGB(255, 255, 0)
title.Text = "⚡ ADVANCED DEBUG SYSTEM ⚡"
title.Font = Enum.Font.Code
title.TextSize = 16
title.Parent = frame

local cornerTitle = Instance.new("UICorner")
cornerTitle.CornerRadius = UDim.new(0, 8)
cornerTitle.Parent = title

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.95, 0, 0.8, 0)
label.Position = UDim2.new(0.025, 0, 0.2, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Text = "Klik tombol atau gunakan RemoteEvent untuk melihat debug info..."
label.TextWrapped = true
label.Font = Enum.Font.Code
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Parent = frame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.95, 0, 0.75, 0)
scrollFrame.Position = UDim2.new(0.025, 0, 0.2, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.Visible = false
scrollFrame.Parent = frame

local scrollLabel = Instance.new("TextLabel")
scrollLabel.Size = UDim2.new(1, 0, 2, 0)
scrollLabel.BackgroundTransparency = 1
scrollLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scrollLabel.Text = ""
scrollLabel.TextWrapped = true
scrollLabel.Font = Enum.Font.Code
scrollLabel.TextSize = 12
scrollLabel.TextXAlignment = Enum.TextXAlignment.Left
scrollLabel.TextYAlignment = Enum.TextYAlignment.Top
scrollLabel.Parent = scrollFrame

print("Advanced Debug UI berhasil dibuat!")

-- Variabel untuk melacak RemoteEvents
local trackedRemoteEvents = {}
local remoteEventLogs = {}

-- Fungsi untuk update debug info
local function updateDebugInfo(debugType, details, data)
    local character = player.Character
    local charName = "No Character"
    local position = "Unknown"
    local health = "N/A"
    
    if character then
        charName = character.Name
        if character:FindFirstChild("HumanoidRootPart") then
            local pos = character.HumanoidRootPart.Position
            position = string.format("X:%.1f, Y:%.1f, Z:%.1f", pos.X, pos.Y, pos.Z)
        end
        if character:FindFirstChild("Humanoid") then
            health = string.format("%.0f/%.0f", character.Humanoid.Health, character.Humanoid.MaxHealth)
        end
    end
    
    local fps = math.floor(1/RunService.Heartbeat:Wait())
    
    local debugText = string.format([[
🔍 DEBUG TYPE: %s
📋 DETAILS: %s

👤 CHARACTER INFO:
- Name: %s
- Health: %s
- Position: %s

⚡ PERFORMANCE:
- FPS: %d
- Server Time: %s

📊 DATA:
%s
    ]], 
    debugType, 
    details,
    charName,
    health,
    position,
    fps,
    os.date("%H:%M:%S"),
    data or "No additional data")
    
    -- Tampilkan di scrolling frame untuk data panjang
    if #debugText > 500 then
        label.Visible = false
        scrollFrame.Visible = true
        scrollLabel.Text = debugText
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLabel.TextBounds.Y + 20)
    else
        scrollFrame.Visible = false
        label.Visible = true
        label.Text = debugText
    end
    
    -- Print ke console juga
    print("=== ADVANCED DEBUG ===")
    print("Type: " .. debugType)
    print("Details: " .. details)
    print("Character: " .. charName)
    print("Position: " .. position)
    print("======================")
end

-- Fungsi untuk melacak RemoteEvent (versi aman)
local function trackRemoteEvent(remoteEvent)
    if trackedRemoteEvents[remoteEvent] then
        return -- Sudah dilacak
    end
    
    trackedRemoteEvents[remoteEvent] = true
    local eventName = remoteEvent.Name
    
    -- Lacak ketika client menerima dari server
    local success, errorMsg = pcall(function()
        remoteEvent.OnClientEvent:Connect(function(...)
            local args = {...}
            local logEntry = {
                type = "RECEIVED_FROM_SERVER",
                event = eventName,
                args = args,
                timestamp = os.date("%H:%M:%S"),
                player = player.Name
            }
            
            table.insert(remoteEventLogs, logEntry)
            
            updateDebugInfo("REMOTEEVENT RECEIVED", 
                "Server → Client: " .. eventName,
                string.format("Arguments Count: %d", #args))
        end)
    end)
    
    if not success then
        warn("Gagal melacak RemoteEvent " .. eventName .. ": " .. errorMsg)
    else
        print("Now tracking RemoteEvent: " .. eventName)
    end
end

-- Auto-track existing RemoteEvents
local function trackExistingRemoteEvents()
    -- Cari di ReplicatedStorage
    for _, remoteEvent in ipairs(ReplicatedStorage:GetDescendants()) do
        if remoteEvent:IsA("RemoteEvent") then
            trackRemoteEvent(remoteEvent)
        end
    end
    
    -- Cari di workspace
    for _, remoteEvent in ipairs(workspace:GetDescendants()) do
        if remoteEvent:IsA("RemoteEvent") then
            trackRemoteEvent(remoteEvent)
        end
    end
end

-- Monitor untuk RemoteEvents baru
ReplicatedStorage.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("RemoteEvent") then
        wait(0.5)
        trackRemoteEvent(descendant)
    end
end)

-- Method 1: Direct button connection
local function connectToButtons()
    wait(2)
    
    local guis = player.PlayerGui:GetDescendants()
    local buttonCount = 0
    
    for _, guiElement in ipairs(guis) do
        if guiElement:IsA("TextButton") or guiElement:IsA("ImageButton") then
            local success, errorMsg = pcall(function()
                guiElement.MouseButton1Click:Connect(function()
                    local additionalInfo = ""
                    if guiElement:IsA("TextButton") then
                        additionalInfo = "Teks: " .. (guiElement.Text or "N/A")
                    end
                    
                    local buttonInfo = string.format([[
Button Name: %s
Parent: %s
Visible: %s
Size: %s
Position: %s
%s
                    ]],
                    guiElement.Name,
                    guiElement.Parent and guiElement.Parent.Name or "N/A",
                    tostring(guiElement.Visible),
                    tostring(guiElement.AbsoluteSize),
                    tostring(guiElement.AbsolutePosition),
                    additionalInfo)
                    
                    updateDebugInfo("BUTTON CLICK", "Button: " .. guiElement.Name, buttonInfo)
                    
                    -- Highlight effect
                    local originalBg = guiElement.BackgroundColor3
                    guiElement.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    wait(0.1)
                    guiElement.BackgroundColor3 = originalBg
                end)
            end)
            
            if success then
                buttonCount += 1
            else
                warn("Gagal connect ke button " .. guiElement.Name .. ": " .. errorMsg)
            end
        end
    end
    
    updateDebugInfo("SYSTEM", "Button Connection Complete", 
        string.format("Total buttons connected: %d\nGUI elements scanned: %d", buttonCount, #guis))
end

-- Method 2: Input detection untuk backup
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        
        updateDebugInfo("MOUSE CLICK", "Left Mouse Button", 
            string.format("Mouse Position: %s", tostring(mousePos)))
    end
end)

-- Fungsi untuk menampilkan log RemoteEvent
local function showRemoteEventLogs()
    if #remoteEventLogs == 0 then
        updateDebugInfo("REMOTEEVENT LOGS", "No events tracked yet", "Start interacting with the game to see RemoteEvent activity.")
        return
    end
    
    local logText = "📊 REMOTEEVENT ACTIVITY LOG:\n\n"
    
    for i, log in ipairs(remoteEventLogs) do
        logText = logText .. string.format("[%d] %s - %s: %s\nArgs Count: %d\n\n", 
            i, log.timestamp, log.type, log.event, #log.args)
    end
    
    updateDebugInfo("REMOTEEVENT LOGS", "Recent Activity", logText)
end

-- Tambah hotkey untuk debug info
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        showRemoteEventLogs()
    elseif input.KeyCode == Enum.KeyCode.F2 then
        connectToButtons() -- Re-scan buttons
    elseif input.KeyCode == Enum.KeyCode.F3 then
        trackExistingRemoteEvents() -- Re-scan RemoteEvents
    end
end)

-- System info display
local function updateSystemInfo()
    while true do
        wait(5)
        local success, fps = pcall(function()
            return math.floor(1/RunService.Heartbeat:Wait())
        end)
        
        if not success then
            fps = 0
        end
        
        -- Update title dengan info real-time
        title.Text = string.format("⚡ DEBUG SYSTEM | FPS: %d | Events: %d ⚡", 
            fps, #remoteEventLogs)
    end
end

-- Jalankan sistem dengan error handling
local function initializeSystem()
    local success, errorMsg = pcall(function()
        trackExistingRemoteEvents()
        connectToButtons()
        spawn(updateSystemInfo)
        
        print("=== ADVANCED DEBUG SYSTEM READY ===")
        print("F1 - Show RemoteEvent Logs")
        print("F2 - Re-scan Buttons")
        print("F3 - Re-scan RemoteEvents")
        print("===================================")
    end)
    
    if not success then
        warn("Error initializing debug system: " .. errorMsg)
        updateDebugInfo("ERROR", "System Initialization Failed", errorMsg)
    end
end

-- Tunggu sebentar sebelum initialize
wait(1)
initializeSystem()
