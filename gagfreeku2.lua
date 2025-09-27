-- LocalScript di StarterPlayerScripts111
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Tunggu sampai player ready
if not player then
    player = Players.LocalPlayer
end

player:WaitForChild("PlayerGui")

-- Variabel sistem
local trackedRemoteEvents = {}
local remoteEventLogs = {}
local isMonitoring = true
local buttonConnections = {}
local remoteEventConnections = {}

-- Buat UI debug yang lebih besar dengan kontrol
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedDebugGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 250)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Header dengan kontrol
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.18, 0)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.BackgroundTransparency = 0.1
header.Parent = mainFrame

local cornerHeader = Instance.new("UICorner")
cornerHeader.CornerRadius = UDim.new(0, 8)
cornerHeader.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6, 0, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 0)
title.Text = "⚡ DEBUG SYSTEM ⚡"
title.Font = Enum.Font.Code
title.TextSize = 16
title.Parent = header

-- Tombol Start/Stop
local startStopButton = Instance.new("TextButton")
startStopButton.Size = UDim2.new(0.35, 0, 0.6, 0)
startStopButton.Position = UDim2.new(0.63, 0, 0.2, 0)
startStopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
startStopButton.Text = "STOP"
startStopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startStopButton.Font = Enum.Font.Code
startStopButton.TextSize = 14
startStopButton.Parent = header

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = startStopButton

-- Status indicator
local statusIndicator = Instance.new("Frame")
statusIndicator.Size = UDim2.new(0.02, 0, 0.4, 0)
statusIndicator.Position = UDim2.new(0.59, 0, 0.3, 0)
statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
statusIndicator.Parent = header

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 4)
statusCorner.Parent = statusIndicator

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.1, 0, 0.4, 0)
statusLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "ON"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 12
statusLabel.Parent = header

-- Kontrol panel
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, 0, 0.15, 0)
controlFrame.Position = UDim2.new(0, 0, 0.18, 0)
controlFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controlFrame.BackgroundTransparency = 0.3
controlFrame.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 6)
controlCorner.Parent = controlFrame

-- Tombol kontrol
local buttonScanBtn = Instance.new("TextButton")
buttonScanBtn.Size = UDim2.new(0.3, 0, 0.7, 0)
buttonScanBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
buttonScanBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 200)
buttonScanBtn.Text = "🔍 Scan Buttons"
buttonScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buttonScanBtn.Font = Enum.Font.Code
buttonScanBtn.TextSize = 12
buttonScanBtn.Parent = controlFrame

local eventScanBtn = Instance.new("TextButton")
eventScanBtn.Size = UDim2.new(0.3, 0, 0.7, 0)
eventScanBtn.Position = UDim2.new(0.34, 0, 0.15, 0)
eventScanBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
eventScanBtn.Text = "📡 Scan Events"
eventScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
eventScanBtn.Font = Enum.Font.Code
eventScanBtn.TextSize = 12
eventScanBtn.Parent = controlFrame

local clearLogsBtn = Instance.new("TextButton")
clearLogsBtn.Size = UDim2.new(0.3, 0, 0.7, 0)
clearLogsBtn.Position = UDim2.new(0.66, 0, 0.15, 0)
clearLogsBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 70)
clearLogsBtn.Text = "🧹 Clear Logs"
clearLogsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearLogsBtn.Font = Enum.Font.Code
clearLogsBtn.TextSize = 12
clearLogsBtn.Parent = controlFrame

-- Area display
local displayFrame = Instance.new("Frame")
displayFrame.Size = UDim2.new(1, 0, 0.67, 0)
displayFrame.Position = UDim2.new(0, 0, 0.33, 0)
displayFrame.BackgroundTransparency = 1
displayFrame.Parent = mainFrame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.95, 0, 1, 0)
label.Position = UDim2.new(0.025, 0, 0, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Text = "System ready. Click START to begin monitoring..."
label.TextWrapped = true
label.Font = Enum.Font.Code
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Parent = displayFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.95, 0, 1, 0)
scrollFrame.Position = UDim2.new(0.025, 0, 0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.Visible = false
scrollFrame.Parent = displayFrame

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

print("Advanced Debug GUI dengan kontrol berhasil dibuat!")

-- Fungsi untuk update debug info
local function updateDebugInfo(debugType, details, data)
    if not isMonitoring then return end
    
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
- Time: %s
- Status: %s

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
    isMonitoring and "ACTIVE" or "PAUSED",
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
    print("=== DEBUG ===")
    print("Type: " .. debugType)
    print("Details: " .. details)
    print("Status: " .. (isMonitoring and "ACTIVE" or "PAUSED"))
    print("=============")
end

-- Fungsi untuk memulai monitoring
local function startMonitoring()
    if isMonitoring then return end
    
    isMonitoring = true
    startStopButton.Text = "STOP"
    startStopButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    statusLabel.Text = "ON"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    
    updateDebugInfo("SYSTEM", "Monitoring Started", "All monitoring functions are now ACTIVE")
    
    -- Animasi
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(statusIndicator, tweenInfo, {BackgroundColor3 = Color3.fromRGB(0, 255, 0)})
    tween:Play()
end

-- Fungsi untuk menghentikan monitoring
local function stopMonitoring()
    if not isMonitoring then return end
    
    isMonitoring = false
    startStopButton.Text = "START"
    startStopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    statusLabel.Text = "OFF"
    statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    
    updateDebugInfo("SYSTEM", "Monitoring Stopped", "All monitoring functions are now PAUSED")
    
    -- Animasi
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(statusIndicator, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 0, 0)})
    tween:Play()
end

-- Toggle monitoring
startStopButton.MouseButton1Click:Connect(function()
    if isMonitoring then
        stopMonitoring()
    else
        startMonitoring()
    end
end)

-- Fungsi untuk melacak RemoteEvent
local function trackRemoteEvent(remoteEvent)
    if trackedRemoteEvents[remoteEvent] then return end
    
    trackedRemoteEvents[remoteEvent] = true
    local eventName = remoteEvent.Name
    
    local success, errorMsg = pcall(function()
        local connection = remoteEvent.OnClientEvent:Connect(function(...)
            if not isMonitoring then return end
            
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
                string.format("Arguments Count: %d\nEvent: %s", #args, eventName))
        end)
        
        remoteEventConnections[remoteEvent] = connection
    end)
    
    if success then
        print("Now tracking RemoteEvent: " .. eventName)
    else
        warn("Gagal melacak RemoteEvent " .. eventName .. ": " .. errorMsg)
    end
end

-- Scan RemoteEvents
local function scanRemoteEvents()
    trackedRemoteEvents = {}
    remoteEventConnections = {}
    
    -- Putuskan koneksi lama
    for _, connection in pairs(remoteEventConnections) do
        connection:Disconnect()
    end
    
    -- Scan ReplicatedStorage
    for _, remoteEvent in ipairs(ReplicatedStorage:GetDescendants()) do
        if remoteEvent:IsA("RemoteEvent") then
            trackRemoteEvent(remoteEvent)
        end
    end
    
    -- Scan workspace
    for _, remoteEvent in ipairs(workspace:GetDescendants()) do
        if remoteEvent:IsA("RemoteEvent") then
            trackRemoteEvent(remoteEvent)
        end
    end
    
    updateDebugInfo("SYSTEM", "RemoteEvent Scan Complete", 
        string.format("Total RemoteEvents tracked: %d", table.getn(trackedRemoteEvents)))
end

eventScanBtn.MouseButton1Click:Connect(function()
    scanRemoteEvents()
end)

-- Scan buttons
local function scanButtons()
    -- Putuskan koneksi lama
    for _, connection in pairs(buttonConnections) do
        connection:Disconnect()
    end
    
    buttonConnections = {}
    wait(1)
    
    local guis = player.PlayerGui:GetDescendants()
    local buttonCount = 0
    
    for _, guiElement in ipairs(guis) do
        if guiElement:IsA("TextButton") or guiElement:IsA("ImageButton") then
            local success, errorMsg = pcall(function()
                local connection = guiElement.MouseButton1Click:Connect(function()
                    if not isMonitoring then return end
                    
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
                
                buttonConnections[guiElement] = connection
                buttonCount += 1
            end)
            
            if not success then
                warn("Gagal connect ke button " .. guiElement.Name .. ": " .. errorMsg)
            end
        end
    end
    
    updateDebugInfo("SYSTEM", "Button Scan Complete", 
        string.format("Total buttons connected: %d\nGUI elements scanned: %d", buttonCount, #guis))
end

buttonScanBtn.MouseButton1Click:Connect(function()
    scanButtons()
end)

-- Clear logs
clearLogsBtn.MouseButton1Click:Connect(function()
    remoteEventLogs = {}
    updateDebugInfo("SYSTEM", "Logs Cleared", "All event logs have been cleared")
end)

-- Monitor untuk RemoteEvents baru
ReplicatedStorage.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("RemoteEvent") then
        wait(0.5)
        trackRemoteEvent(descendant)
    end
end)

-- Input detection untuk backup
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not isMonitoring then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        updateDebugInfo("MOUSE CLICK", "Left Mouse Button", 
            string.format("Mouse Position: %s", tostring(mousePos)))
    end
end)

-- Hotkey system
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        if #remoteEventLogs == 0 then
            updateDebugInfo("REMOTEEVENT LOGS", "No events tracked", "No RemoteEvent activity recorded")
            return
        end
        
        local logText = "📊 REMOTEEVENT ACTIVITY LOG:\n\n"
        for i, log in ipairs(remoteEventLogs) do
            logText = logText .. string.format("[%d] %s - %s: %s\nArgs Count: %d\n\n", 
                i, log.timestamp, log.type, log.event, #log.args)
        end
        updateDebugInfo("REMOTEEVENT LOGS", "Recent Activity", logText)
        
    elseif input.KeyCode == Enum.KeyCode.F5 then
        -- Toggle monitoring dengan F5
        if isMonitoring then
            stopMonitoring()
        else
            startMonitoring()
        end
    end
end)

-- System info display
local function updateSystemInfo()
    while true do
        wait(3)
        local success, fps = pcall(function()
            return math.floor(1/RunService.Heartbeat:Wait())
        end)
        
        if not success then fps = 0 end
        
        -- Update title dengan info real-time
        title.Text = string.format("⚡ DEBUG | FPS: %d | Events: %d | %s ⚡", 
            fps, #remoteEventLogs, isMonitoring and "ACTIVE" or "PAUSED")
    end
end

-- Initialize system
local function initializeSystem()
    -- Mulai dalam keadaan aktif
    startMonitoring()
    scanRemoteEvents()
    scanButtons()
    spawn(updateSystemInfo)
    
    updateDebugInfo("SYSTEM", "Initialization Complete", 
        string.format("Debug system ready!\nUse F5 to toggle monitoring\nF1 to view logs"))
    
    print("=== ADVANCED DEBUG SYSTEM READY ===")
    print("F1 - Show RemoteEvent Logs")
    print("F5 - Toggle Monitoring")
    print("Click STOP button to pause monitoring")
    print("===================================")
end

-- Tunggu sebentar sebelum initialize
wait(2)
initializeSystem()
