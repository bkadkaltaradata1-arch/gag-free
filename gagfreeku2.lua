-- Advanced Remote Event Debug System
-- LocalScript di StarterPlayerScripts55

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

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
local dataStreamLogs = {}

-- Buat UI debug yang advanced
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DataStreamDebugger"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 350)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Header dengan tabs
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.12, 0)
header.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
header.BackgroundTransparency = 0.1
header.Parent = mainFrame

local cornerHeader = Instance.new("UICorner")
cornerHeader.CornerRadius = UDim.new(0, 10)
cornerHeader.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.5, 0, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.Text = "🌐 DATASTREAM DEBUGGER"
title.Font = Enum.Font.Code
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0.02, 0, 0, 0)
title.Parent = header

-- Status panel
local statusPanel = Instance.new("Frame")
statusPanel.Size = UDim2.new(0.45, 0, 0.7, 0)
statusPanel.Position = UDim2.new(0.53, 0, 0.15, 0)
statusPanel.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
statusPanel.Parent = header

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusPanel

local statusIndicator = Instance.new("Frame")
statusIndicator.Size = UDim2.new(0.08, 0, 0.6, 0)
statusIndicator.Position = UDim2.new(0.1, 0, 0.2, 0)
statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
statusIndicator.Parent = statusPanel

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.7, 0, 1, 0)
statusLabel.Position = UDim2.new(0.25, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "MONITORING ACTIVE"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusPanel

-- Kontrol panel
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, 0, 0.15, 0)
controlFrame.Position = UDim2.new(0, 0, 0.12, 0)
controlFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
controlFrame.Parent = mainFrame

-- Tombol kontrol
local buttons = {
    {name = "🔍 Scan Events", pos = 0.02, color = Color3.fromRGB(0, 150, 255)},
    {name = "📊 View Logs", pos = 0.18, color = Color3.fromRGB(100, 200, 100)},
    {name = "🧹 Clear Data", pos = 0.34, color = Color3.fromRGB(255, 100, 100)},
    {name = "⏸️ Pause", pos = 0.50, color = Color3.fromRGB(255, 150, 50)},
    {name = "📋 Export", pos = 0.66, color = Color3.fromRGB(200, 100, 255)},
}

local controlButtons = {}

for i, btnInfo in ipairs(buttons) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.15, 0, 0.7, 0)
    button.Position = UDim2.new(btnInfo.pos, 0, 0.15, 0)
    button.BackgroundColor3 = btnInfo.color
    button.Text = btnInfo.name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Code
    button.TextSize = 11
    button.Parent = controlFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = button
    
    controlButtons[btnInfo.name] = button
end

-- Display area dengan tabs
local displayTabs = Instance.new("Frame")
displayTabs.Size = UDim2.new(1, 0, 0.73, 0)
displayTabs.Position = UDim2.new(0, 0, 0.27, 0)
displayTabs.BackgroundTransparency = 1
displayTabs.Parent = mainFrame

-- Tab buttons
local tabButtons = {}
local activeTab = "events"

local tabs = {
    {name = "📡 Events", key = "events"},
    {name = "📈 Stats", key = "stats"}, 
    {name = "🔧 System", key = "system"}
}

for i, tab in ipairs(tabs) do
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(0.32, 0, 0.08, 0)
    tabButton.Position = UDim2.new(0.01 + (i-1)*0.33, 0, 0, 0)
    tabButton.BackgroundColor3 = tab.key == "events" and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(40, 45, 60)
    tabButton.Text = tab.name
    tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabButton.Font = Enum.Font.Code
    tabButton.TextSize = 12
    tabButton.Parent = displayTabs
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 5)
    tabCorner.Parent = tabButton
    
    tabButtons[tab.key] = tabButton
end

-- Content area
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(0.98, 0, 0.9, 0)
contentFrame.Position = UDim2.new(0.01, 0, 0.1, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 8
contentFrame.Parent = displayTabs

local contentLabel = Instance.new("TextLabel")
contentLabel.Size = UDim2.new(1, 0, 0, 0)
contentLabel.BackgroundTransparency = 1
contentLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
contentLabel.Text = "DataStream Debugger Ready..."
contentLabel.TextWrapped = true
contentLabel.Font = Enum.Font.Code
contentLabel.TextSize = 13
contentLabel.TextXAlignment = Enum.TextXAlignment.Left
contentLabel.TextYAlignment = Enum.TextYAlignment.Top
contentLabel.Parent = contentFrame

print("🌐 Advanced DataStream Debugger Loaded!")

-- Fungsi untuk log datastream activity
local function logDataStream(eventType, eventName, data, direction)
    if not isMonitoring then return end
    
    local timestamp = os.date("%H:%M:%S")
    local logEntry = {
        type = eventType,
        event = eventName,
        data = data,
        direction = direction or "SERVER→CLIENT",
        timestamp = timestamp,
        player = player.Name,
        tick = tick()
    }
    
    table.insert(dataStreamLogs, logEntry)
    
    -- Keep only last 100 logs
    if #dataStreamLogs > 100 then
        table.remove(dataStreamLogs, 1)
    end
    
    return logEntry
end

-- Fungsi untuk mendapatkan ukuran text yang tepat
local function getTextSize(text, fontSize, font)
    local success, result = pcall(function()
        return TextService:GetTextSize(text, fontSize, font, Vector2.new(450, 10000))
    end)
    
    if success then
        return result.Y
    else
        return #text * 0.5 -- Fallback estimation
    end
end

-- Fungsi update display berdasarkan tab aktif
local function updateDisplay()
    if activeTab == "events" then
        local displayText = "📡 LIVE DATASTREAM ACTIVITY\n" .. string.rep("=", 50) .. "\n\n"
        
        if #dataStreamLogs == 0 then
            displayText = displayText .. "No datastream activity detected yet...\n\n"
            displayText = displayText .. "Waiting for RemoteEvents to fire..."
        else
            -- Show last 10 events
            for i = math.max(1, #dataStreamLogs - 9), #dataStreamLogs do
                local log = dataStreamLogs[i]
                displayText = displayText .. string.format(
                    "🕒 [%s] %s\n📍 %s: %s\n📊 Data: %s\n%s\n\n",
                    log.timestamp,
                    log.direction,
                    log.type,
                    log.event,
                    tostring(log.data),
                    string.rep("-", 40)
                )
            end
        end
        
        contentLabel.Text = displayText
        
    elseif activeTab == "stats" then
        local statsText = "📈 DATASTREAM STATISTICS\n" .. string.rep("=", 50) .. "\n\n"
        
        -- Hitung statistik
        local eventCounts = {}
        local directionCounts = {["SERVER→CLIENT"] = 0, ["CLIENT→SERVER"] = 0}
        
        for _, log in ipairs(dataStreamLogs) do
            eventCounts[log.type] = (eventCounts[log.type] or 0) + 1
            directionCounts[log.direction] = (directionCounts[log.direction] or 0) + 1
        end
        
        statsText = statsText .. string.format("Total Events: %d\n", #dataStreamLogs)
        statsText = statsText .. string.format("Monitoring Time: %.1f seconds\n", tick() - (dataStreamLogs[1] and dataStreamLogs[1].tick or tick()))
        statsText = statsText .. string.format("Tracked RemoteEvents: %d\n\n", #trackedRemoteEvents)
        
        statsText = statsText .. "📊 Event Types:\n"
        for eventType, count in pairs(eventCounts) do
            statsText = statsText .. string.format("  %s: %d\n", eventType, count)
        end
        
        statsText = statsText .. "\n🔄 Directions:\n"
        for direction, count in pairs(directionCounts) do
            statsText = statsText .. string.format("  %s: %d\n", direction, count)
        end
        
        contentLabel.Text = statsText
        
    elseif activeTab == "system" then
        local systemText = "🔧 SYSTEM INFORMATION\n" .. string.rep("=", 50) .. "\n\n"
        
        -- Performance info
        local fps = math.floor(1/RunService.Heartbeat:Wait())
        local memory = math.floor(collectgarbage("count"))
        
        -- Character info
        local charInfo = "No character"
        if player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and root then
                charInfo = string.format("Health: %d/%d | Position: (%.1f, %.1f, %.1f)", 
                    humanoid.Health, humanoid.MaxHealth, root.Position.X, root.Position.Y, root.Position.Z)
            end
        end
        
        systemText = systemText .. string.format("FPS: %d\n", fps)
        systemText = systemText .. string.format("Memory: %d KB\n", memory)
        systemText = systemText .. string.format("Player: %s\n", player.Name)
        systemText = systemText .. string.format("Character: %s\n", charInfo)
        systemText = systemText .. string.format("Monitoring: %s\n", isMonitoring and "ACTIVE" or "PAUSED")
        systemText = systemText .. string.format("UI Visible: %s\n", screenGui.Enabled and "YES" or "NO")
        
        systemText = systemText .. "\n🎯 HOTKEYS:\n"
        systemText = systemText .. "F1 - Toggle Monitoring\n"
        systemText = systemText .. "F2 - Quick Stats\n"
        systemText = systemText .. "F3 - Export Logs\n"
        
        contentLabel.Text = systemText
    end
    
    -- Update canvas size secara aman
    local textHeight = getTextSize(contentLabel.Text, 13, Enum.Font.Code)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(textHeight + 20, 200))
end

-- Fungsi untuk melacak RemoteEvent
local function trackRemoteEvent(remoteEvent)
    if trackedRemoteEvents[remoteEvent] then return end
    
    trackedRemoteEvents[remoteEvent] = true
    local eventName = remoteEvent.Name
    local eventPath = remoteEvent:GetFullName()
    
    print("🔗 Now tracking RemoteEvent: " .. eventPath)
    
    local success, errorMsg = pcall(function()
        local connection = remoteEvent.OnClientEvent:Connect(function(...)
            if not isMonitoring then return end
            
            local args = {...}
            local dataSummary = string.format("Args: %d | Values: ", #args)
            
            -- Limit data preview untuk avoid spam
            for i, arg in ipairs(args) do
                if i <= 3 then  -- Hanya tampilkan 3 argumen pertama
                    dataSummary = dataSummary .. tostring(arg) .. ", "
                end
            end
            
            if #args > 3 then
                dataSummary = dataSummary .. "..."
            end
            
            local logEntry = logDataStream("REMOTE_EVENT", eventName, dataSummary, "SERVER→CLIENT")
            
            -- Update UI jika di tab events
            if activeTab == "events" then
                updateDisplay()
            end
            
            -- Print ke console untuk important events
            if #args > 0 then
                print(string.format("📨 [%s] %s → %s", logEntry.timestamp, eventName, dataSummary))
            end
        end)
        
        remoteEventConnections[remoteEvent] = connection
    end)
    
    if not success then
        warn("❌ Failed to track RemoteEvent " .. eventName .. ": " .. errorMsg)
    end
end

-- Scan semua RemoteEvents
local function scanRemoteEvents()
    print("🔍 Scanning for RemoteEvents...")
    
    -- Reset tracking
    trackedRemoteEvents = {}
    for _, conn in pairs(remoteEventConnections) do
        conn:Disconnect()
    end
    remoteEventConnections = {}
    
    local eventCount = 0
    
    -- Scan di ReplicatedStorage
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            trackRemoteEvent(obj)
            eventCount += 1
        end
    end
    
    -- Scan di Workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            trackRemoteEvent(obj)
            eventCount += 1
        end
    end
    
    logDataStream("SYSTEM", "Event Scan", string.format("Found %d RemoteEvents", eventCount), "SYSTEM")
    updateDisplay()
    
    return eventCount
end

-- Fungsi toggle monitoring
local function toggleMonitoring()
    isMonitoring = not isMonitoring
    
    if isMonitoring then
        statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        statusLabel.Text = "MONITORING ACTIVE"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        controlButtons["⏸️ Pause"].Text = "⏸️ Pause"
        controlButtons["⏸️ Pause"].BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    else
        statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        statusLabel.Text = "MONITORING PAUSED"
        statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        controlButtons["⏸️ Pause"].Text = "▶️ Resume"
        controlButtons["⏸️ Pause"].BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end
    
    logDataStream("SYSTEM", "Monitoring", isMonitoring and "STARTED" or "PAUSED", "SYSTEM")
    updateDisplay()
end

-- Fungsi clear data
local function clearData()
    dataStreamLogs = {}
    logDataStream("SYSTEM", "Data Clear", "All logs cleared", "SYSTEM")
    updateDisplay()
    print("🧹 DataStream logs cleared!")
end

-- Fungsi export logs (simplified tanpa setclipboard)
local function exportLogs()
    local exportText = "DATASTREAM DEBUGGER EXPORT\n" .. string.rep("=", 50) .. "\n\n"
    exportText = exportText .. string.format("Export Time: %s\n", os.date("%Y-%m-%d %H:%M:%S"))
    exportText = exportText .. string.format("Player: %s\n", player.Name)
    exportText = exportText .. string.format("Total Events: %d\n\n", #dataStreamLogs)
    
    for i, log in ipairs(dataStreamLogs) do
        exportText = exportText .. string.format("[%d] %s | %s | %s: %s\n",
            i, log.timestamp, log.direction, log.type, log.event)
        exportText = exportText .. string.format("     Data: %s\n\n", log.data)
    end
    
    -- Print ke console sebagai alternatif export
    print("📋 EXPORTED LOGS:")
    print(exportText)
    
    logDataStream("SYSTEM", "Export", "Logs printed to console", "SYSTEM")
end

-- Setup tab handlers
for tabKey, tabButton in pairs(tabButtons) do
    tabButton.MouseButton1Click:Connect(function()
        activeTab = tabKey
        
        -- Update semua tab colors
        for key, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = key == tabKey and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(40, 45, 60)
        end
        
        updateDisplay()
    end)
end

-- Setup control button handlers
controlButtons["🔍 Scan Events"].MouseButton1Click:Connect(function()
    local count = scanRemoteEvents()
    logDataStream("SYSTEM", "Manual Scan", string.format("Scanned %d events", count), "SYSTEM")
end)

controlButtons["📊 View Logs"].MouseButton1Click:Connect(function()
    activeTab = "events"
    for key, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = key == "events" and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(40, 45, 60)
    end
    updateDisplay()
end)

controlButtons["🧹 Clear Data"].MouseButton1Click:Connect(clearData)
controlButtons["⏸️ Pause"].MouseButton1Click:Connect(toggleMonitoring)
controlButtons["📋 Export"].MouseButton1Click:Connect(exportLogs)

-- Hotkey system
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        toggleMonitoring()
    elseif input.KeyCode == Enum.KeyCode.F2 then
        activeTab = "stats"
        for key, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = key == "stats" and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(40, 45, 60)
        end
        updateDisplay()
    elseif input.KeyCode == Enum.KeyCode.F3 then
        exportLogs()
    end
end)

-- Auto-detect new RemoteEvents
ReplicatedStorage.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("RemoteEvent") then
        wait(0.5)  -- Tunggu sedikit untuk initialization
        trackRemoteEvent(descendant)
        logDataStream("SYSTEM", "Auto-Detect", "New RemoteEvent: " .. descendant:GetFullName(), "SYSTEM")
    end
end)

-- Real-time updates
spawn(function()
    while true do
        wait(2)
        if isMonitoring then
            -- Update title dengan real-time info
            local fps = math.floor(1/RunService.Heartbeat:Wait())
            title.Text = string.format("🌐 DATASTREAM DEBUGGER | Events: %d | FPS: %d", 
                #dataStreamLogs, fps)
            
            -- Auto-refresh display jika di tab events
            if activeTab == "events" and #dataStreamLogs > 0 then
                updateDisplay()
            end
        end
    end
end)

-- Initialize system
wait(1)
local eventCount = scanRemoteEvents()
updateDisplay()

print("🎯 DataStream Debugger Initialized!")
print("📊 Found " .. eventCount .. " RemoteEvents")
print("🎮 Hotkeys: F1 (Toggle) | F2 (Stats) | F3 (Export)")
