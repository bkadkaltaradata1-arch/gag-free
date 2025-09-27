-- LocalScript di StarterPlayerScripts
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
local lastButtonClick = {}
local lastRemoteEvent = {}

-- Buat UI debug yang lebih besar dengan kontrol
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedDebugGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 300)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Header dengan kontrol
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.15, 0)
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
title.Text = "⚡ DETAILED DEBUG SYSTEM ⚡"
title.Font = Enum.Font.Code
title.TextSize = 14
title.Parent = header

-- Tombol Start/Stop
local startStopButton = Instance.new("TextButton")
startStopButton.Size = UDim2.new(0.35, 0, 0.6, 0)
startStopButton.Position = UDim2.new(0.63, 0, 0.2, 0)
startStopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
startStopButton.Text = "STOP"
startStopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startStopButton.Font = Enum.Font.Code
startStopButton.TextSize = 12
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

-- Kontrol panel
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, 0, 0.2, 0)
controlFrame.Position = UDim2.new(0, 0, 0.15, 0)
controlFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controlFrame.BackgroundTransparency = 0.2
controlFrame.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 6)
controlCorner.Parent = controlFrame

-- Tombol kontrol
local buttons = {
    {name = "🔍 Scan Buttons", color = Color3.fromRGB(70, 70, 200), pos = 0.02},
    {name = "📡 Scan Events", color = Color3.fromRGB(200, 70, 70), pos = 0.18},
    {name = "📊 Button Stats", color = Color3.fromRGB(70, 200, 70), pos = 0.34},
    {name = "🔔 Event Stats", color = Color3.fromRGB(200, 70, 200), pos = 0.50},
    {name = "🧹 Clear Logs", color = Color3.fromRGB(200, 200, 70), pos = 0.66},
    {name = "📝 Last Events", color = Color3.fromRGB(70, 200, 200), pos = 0.82}
}

local controlButtons = {}
for i, btnInfo in ipairs(buttons) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.16, 0, 0.7, 0)
    btn.Position = UDim2.new(btnInfo.pos, 0, 0.15, 0)
    btn.BackgroundColor3 = btnInfo.color
    btn.Text = btnInfo.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 10
    btn.TextWrapped = true
    btn.Parent = controlFrame
    controlButtons[btnInfo.name] = btn
end

-- Area display
local displayFrame = Instance.new("Frame")
displayFrame.Size = UDim2.new(1, 0, 0.65, 0)
displayFrame.Position = UDim2.new(0, 0, 0.35, 0)
displayFrame.BackgroundTransparency = 1
displayFrame.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.98, 0, 1, 0)
scrollFrame.Position = UDim2.new(0.01, 0, 0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = displayFrame

local scrollLabel = Instance.new("TextLabel")
scrollLabel.Size = UDim2.new(1, 0, 0, 0)
scrollLabel.BackgroundTransparency = 1
scrollLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scrollLabel.Text = "System ready. Click START to begin monitoring..."
scrollLabel.TextWrapped = true
scrollLabel.Font = Enum.Font.Code
scrollLabel.TextSize = 12
scrollLabel.TextXAlignment = Enum.TextXAlignment.Left
scrollLabel.TextYAlignment = Enum.TextYAlignment.Top
scrollLabel.Parent = scrollFrame

print("Detailed Debug GUI berhasil dibuat!")

-- Fungsi untuk format data arguments
local function formatArguments(args, maxDepth, currentDepth)
    if currentDepth >= maxDepth then
        return "{...}"  -- Prevent infinite recursion
    end
    
    local result = {}
    for i, arg in ipairs(args) do
        local argType = typeof(arg)
        if argType == "table" then
            table.insert(result, "table[" .. tostring(#arg) .. " items]")
        elseif argType == "Instance" then
            table.insert(result, arg:GetFullName())
        elseif argType == "Vector3" then
            table.insert(result, string.format("Vector3(%.2f, %.2f, %.2f)", arg.X, arg.Y, arg.Z))
        elseif argType == "CFrame" then
            local x, y, z = arg:GetComponents()
            table.insert(result, string.format("CFrame(%.2f, %.2f, %.2f, ...)", x, y, z))
        elseif argType == "string" and #arg > 50 then
            table.insert(result, string.format("%q...", string.sub(arg, 1, 50)))
        else
            table.insert(result, tostring(arg))
        end
    end
    return "{" .. table.concat(result, ", ") .. "}"
end

-- Fungsi untuk update debug info dengan auto-scroll
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
    isMonitoring and "ACTIVE" : "PAUSED",
    data or "No additional data")
    
    scrollLabel.Text = debugText
    
    -- Auto-adjust scroll frame size
    local textSize = TextService:GetTextSize(debugText, 12, Enum.Font.Code, Vector2.new(480, 1000))
    scrollLabel.Size = UDim2.new(1, 0, 0, textSize.Y + 20)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, textSize.Y + 20)
    
    -- Auto-scroll to top
    scrollFrame.CanvasPosition = Vector2.new(0, 0)
    
    -- Print ke console juga
    print("=== DETAILED DEBUG ===")
    print("Type: " .. debugType)
    print("Details: " .. details)
    print("======================")
end

-- Fungsi untuk mendapatkan info detail button
local function getButtonDetailedInfo(button)
    local info = {}
    
    -- Basic info
    info["🔹 Button Name"] = button.Name
    info["🔹 Class"] = button.ClassName
    info["🔹 Full Path"] = button:GetFullName()
    info["🔹 Parent"] = button.Parent and button.Parent:GetFullName() or "None"
    
    -- Visibility and state
    info["👀 Visibility"] = button.Visible and "✅ Visible" : "❌ Hidden"
    info["🎯 Active"] = button.Active and "✅ Active" : "❌ Inactive"
    info["🎨 Background Color"] = tostring(button.BackgroundColor3)
    info["📏 Background Transparency"] = tostring(button.BackgroundTransparency)
    
    -- Position and size
    local absSize = button.AbsoluteSize
    local absPos = button.AbsolutePosition
    info["📐 Absolute Size"] = string.format("%d x %d", absSize.X, absSize.Y)
    info["📍 Absolute Position"] = string.format("X:%d, Y:%d", absPos.X, absPos.Y)
    info["🎮 Anchor Point"] = tostring(button.AnchorPoint)
    
    -- Text properties (if TextButton)
    if button:IsA("TextButton") then
        info["📝 Text"] = button.Text ~= "" and button.Text or "Empty"
        info["🔤 Text Color"] = tostring(button.TextColor3)
        info["📚 Text Size"] = tostring(button.TextSize)
        info["🔡 Font"] = tostring(button.Font)
        info["📐 Text Scaled"] = tostring(button.TextScaled)
    end
    
    -- Image properties (if ImageButton)
    if button:IsA("ImageButton") then
        info["🖼️ Image"] = button.Image ~= "" and button.Image or "No Image"
        info["🎭 Image Color"] = tostring(button.ImageColor3)
        info["📐 Image Rect Size"] = tostring(button.ImageRectSize)
    end
    
    -- ZIndex and layout order
    info["📊 ZIndex"] = tostring(button.ZIndex)
    info["🔢 Layout Order"] = tostring(button.LayoutOrder)
    
    -- Format info menjadi string
    local result = ""
    for key, value in pairs(info) do
        result = result .. key .. ": " .. value .. "\n"
    end
    
    return result
end

-- Fungsi untuk memulai/menghentikan monitoring
local function startMonitoring()
    if isMonitoring then return end
    isMonitoring = true
    startStopButton.Text = "STOP"
    startStopButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    updateDebugInfo("SYSTEM", "Monitoring Started", "All monitoring functions are now ACTIVE")
end

local function stopMonitoring()
    if not isMonitoring then return end
    isMonitoring = false
    startStopButton.Text = "START"
    startStopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    updateDebugInfo("SYSTEM", "Monitoring Stopped", "All monitoring functions are now PAUSED")
end

startStopButton.MouseButton1Click:Connect(function()
    if isMonitoring then stopMonitoring() else startMonitoring() end
end)

-- Fungsi untuk melacak RemoteEvent dengan detail arguments
local function trackRemoteEvent(remoteEvent)
    if trackedRemoteEvents[remoteEvent] then return end
    
    trackedRemoteEvents[remoteEvent] = true
    local eventName = remoteEvent.Name
    
    local success, errorMsg = pcall(function()
        local connection = remoteEvent.OnClientEvent:Connect(function(...)
            if not isMonitoring then return end
            
            local args = {...}
            local argsDetail = formatArguments(args, 3, 0)
            
            local logEntry = {
                type = "RECEIVED_FROM_SERVER",
                event = eventName,
                args = args,
                argsDetail = argsDetail,
                timestamp = os.date("%H:%M:%S"),
                player = player.Name
            }
            
            table.insert(remoteEventLogs, logEntry)
            lastRemoteEvent = logEntry
            
            local eventInfo = string.format([[
📡 EVENT: %s
📍 LOCATION: %s
⏰ TIME: %s
👤 PLAYER: %s
📦 ARGUMENTS (%d):
%s

📋 FULL PATH: %s
            ]], 
            eventName,
            remoteEvent:GetFullName(),
            logEntry.timestamp,
            player.Name,
            #args,
            argsDetail,
            remoteEvent:GetFullName())
            
            updateDebugInfo("REMOTEEVENT RECEIVED", "Server → Client", eventInfo)
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
controlButtons["📡 Scan Events"].MouseButton1Click:Connect(function()
    trackedRemoteEvents = {}
    for _, connection in pairs(remoteEventConnections) do
        connection:Disconnect()
    end
    
    local eventCount = 0
    local locations = {ReplicatedStorage, workspace}
    
    for _, location in ipairs(locations) do
        for _, remoteEvent in ipairs(location:GetDescendants()) do
            if remoteEvent:IsA("RemoteEvent") then
                trackRemoteEvent(remoteEvent)
                eventCount += 1
            end
        end
    end
    
    updateDebugInfo("SYSTEM", "RemoteEvent Scan Complete", 
        string.format("Total RemoteEvents found: %d\nLocations scanned: ReplicatedStorage, Workspace", eventCount))
end)

-- Scan buttons dengan info detail
controlButtons["🔍 Scan Buttons"].MouseButton1Click:Connect(function()
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
                    
                    local buttonInfo = getButtonDetailedInfo(guiElement)
                    lastButtonClick = {
                        button = guiElement,
                        timestamp = os.date("%H:%M:%S"),
                        info = buttonInfo
                    }
                    
                    local clickInfo = string.format(["
🕒 CLICK TIME: %s
👤 PLAYER: %s

%s
                    ]], 
                    lastButtonClick.timestamp, 
                    player.Name,
                    buttonInfo)
                    
                    updateDebugInfo("BUTTON CLICK", "Button: " .. guiElement.Name, clickInfo)
                    
                    -- Highlight effect
                    local originalBg = guiElement.BackgroundColor3
                    guiElement.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    wait(0.1)
                    guiElement.BackgroundColor3 = originalBg
                end)
                
                buttonConnections[guiElement] = connection
                buttonCount += 1
            end)
        end
    end
    
    updateDebugInfo("SYSTEM", "Button Scan Complete", 
        string.format("Total buttons connected: %d\nGUI elements scanned: %d", buttonCount, #guis))
end)

-- Tampilkan statistik button
controlButtons["📊 Button Stats"].MouseButton1Click:Connect(function()
    local buttonStats = {}
    local guis = player.PlayerGui:GetDescendants()
    
    for _, guiElement in ipairs(guis) do
        if guiElement:IsA("TextButton") or guiElement:IsA("ImageButton") then
            local buttonType = guiElement.ClassName
            buttonStats[buttonType] = (buttonStats[buttonType] or 0) + 1
            
            local parentName = guiElement.Parent and guiElement.Parent.Name or "Unknown"
            buttonStats[parentName] = (buttonStats[parentName] or 0) + 1
        end
    end
    
    local statsText = "📊 BUTTON STATISTICS:\n\n"
    statsText = statsText .. string.format("Total Buttons: %d\n", #buttonConnections)
    statsText = statsText .. "By Type:\n"
    
    for btnType, count in pairs(buttonStats) do
        if not string.find(btnType, "Gui") then
            statsText = statsText .. string.format("- %s: %d\n", btnType, count)
        end
    end
    
    if lastButtonClick.timestamp then
        statsText = statsText .. string.format("\n⏰ Last Click: %s", lastButtonClick.timestamp)
    end
    
    updateDebugInfo("BUTTON STATS", "Button Statistics", statsText)
end)

-- Tampilkan statistik remote event
controlButtons["🔔 Event Stats"].MouseButton1Click:Connect(function()
    local eventStats = {}
    local totalEvents = 0
    
    for _, log in ipairs(remoteEventLogs) do
        eventStats[log.event] = (eventStats[log.event] or 0) + 1
        totalEvents += 1
    end
    
    local statsText = "📡 REMOTEEVENT STATISTICS:\n\n"
    statsText = statsText .. string.format("Total Events Logged: %d\n", totalEvents)
    statsText = statsText .. "Events by Type:\n"
    
    for eventName, count in pairs(eventStats) do
        statsText = statsText .. string.format("- %s: %d\n", eventName, count)
    end
    
    statsText = statsText .. string.format("\nTracked Events: %d", #trackedRemoteEvents)
    
    if lastRemoteEvent.timestamp then
        statsText = statsText .. string.format("\n⏰ Last Event: %s - %s", lastRemoteEvent.event, lastRemoteEvent.timestamp)
    end
    
    updateDebugInfo("EVENT STATS", "RemoteEvent Statistics", statsText)
end)

-- Tampilkan last events
controlButtons["📝 Last Events"].MouseButton1Click:Connect(function()
    if #remoteEventLogs == 0 then
        updateDebugInfo("LAST EVENTS", "No Events", "No RemoteEvent activity recorded yet")
        return
    end
    
    local lastEventsText = "📝 LAST 10 REMOTEEVENTS:\n\n"
    local startIndex = math.max(1, #remoteEventLogs - 9)
    
    for i = startIndex, #remoteEventLogs do
        local log = remoteEventLogs[i]
        lastEventsText = lastEventsText .. string.format("[%d] %s - %s\n", 
            i, log.timestamp, log.event)
        lastEventsText = lastEventsText .. string.format("   Args: %s\n\n", log.argsDetail)
    end
    
    updateDebugInfo("LAST EVENTS", "Recent Activity", lastEventsText)
end)

-- Clear logs
controlButtons["🧹 Clear Logs"].MouseButton1Click:Connect(function()
    remoteEventLogs = {}
    lastButtonClick = {}
    lastRemoteEvent = {}
    updateDebugInfo("SYSTEM", "Logs Cleared", "All logs and statistics have been cleared")
end)

-- Auto-scan pada startup
local function initializeSystem()
    startMonitoring()
    
    -- Auto scan events dan buttons
    spawn(function()
        wait(2)
        controlButtons["📡 Scan Events"].MouseButton1Click:Wait()
        wait(1)
        controlButtons["🔍 Scan Buttons"].MouseButton1Click:Wait()
    end)
    
    updateDebugInfo("SYSTEM", "Initialization Complete", 
        "Detailed debug system ready!\nUse the control buttons to explore features.")
    
    print("=== DETAILED DEBUG SYSTEM READY ===")
end

wait(2)
initializeSystem()
