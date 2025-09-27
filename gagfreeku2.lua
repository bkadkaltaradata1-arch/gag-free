-- LocalScript di StarterPlayerScripts11
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")

-- Tunggu sampai player ready
if not player then
    player = Players.LocalPlayer
end

player:WaitForChild("PlayerGui")

-- Variabel sistem
local trackedRemoteEvents = {}
local trackedRemoteFunctions = {}
local remoteEventLogs = {}
local isMonitoring = true
local buttonConnections = {}
local remoteEventConnections = {}
local remoteFunctionConnections = {}
local maxLogEntries = 100 -- Batasi jumlah log

-- State GUI
local isMinimized = false
local isDragging = false
local dragStartPos = nil
local guiStartPos = nil

-- Buat UI debug yang lebih besar dengan kontrol
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedDebugGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 350)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Header dengan kontrol (area drag)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.15, 0)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.BackgroundTransparency = 0.1
header.Parent = mainFrame

local cornerHeader = Instance.new("UICorner")
cornerHeader.CornerRadius = UDim.new(0, 8)
cornerHeader.Parent = header

-- Title dengan drag area
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6, 0, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 0)
title.Text = "🌱 GARDEN DEBUG SYSTEM 🌱"
title.Font = Enum.Font.Code
title.TextSize = 16
title.Parent = header

-- Tombol minimize/maximize
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0.08, 0, 0.6, 0)
minimizeButton.Position = UDim2.new(0.52, 0, 0.2, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
minimizeButton.Text = "−"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Font = Enum.Font.Code
minimizeButton.TextSize = 18
minimizeButton.Parent = header

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 6)
minimizeCorner.Parent = minimizeButton

-- Tombol Start/Stop
local startStopButton = Instance.new("TextButton")
startStopButton.Size = UDim2.new(0.35, 0, 0.6, 0)
startStopButton.Position = UDim2.new(0.61, 0, 0.2, 0)
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
statusIndicator.Position = UDim2.new(0.57, 0, 0.3, 0)
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

-- Kontrol panel (akan disembunyikan saat minimize)
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, 0, 0.18, 0)
controlFrame.Position = UDim2.new(0, 0, 0.15, 0)
controlFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controlFrame.BackgroundTransparency = 0.3
controlFrame.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 6)
controlCorner.Parent = controlFrame

-- Tombol kontrol
local buttonScanBtn = Instance.new("TextButton")
buttonScanBtn.Size = UDim2.new(0.22, 0, 0.7, 0)
buttonScanBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
buttonScanBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 200)
buttonScanBtn.Text = "🔍 Buttons"
buttonScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buttonScanBtn.Font = Enum.Font.Code
buttonScanBtn.TextSize = 12
buttonScanBtn.Parent = controlFrame

local eventScanBtn = Instance.new("TextButton")
eventScanBtn.Size = UDim2.new(0.22, 0, 0.7, 0)
eventScanBtn.Position = UDim2.new(0.26, 0, 0.15, 0)
eventScanBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
eventScanBtn.Text = "📡 Events"
eventScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
eventScanBtn.Font = Enum.Font.Code
eventScanBtn.TextSize = 12
eventScanBtn.Parent = controlFrame

local functionScanBtn = Instance.new("TextButton")
functionScanBtn.Size = UDim2.new(0.22, 0, 0.7, 0)
functionScanBtn.Position = UDim2.new(0.50, 0, 0.15, 0)
functionScanBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 70)
functionScanBtn.Text = "🔧 Functions"
functionScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
functionScanBtn.Font = Enum.Font.Code
functionScanBtn.TextSize = 12
functionScanBtn.Parent = controlFrame

local clearLogsBtn = Instance.new("TextButton")
clearLogsBtn.Size = UDim2.new(0.22, 0, 0.7, 0)
clearLogsBtn.Position = UDim2.new(0.74, 0, 0.15, 0)
clearLogsBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 70)
clearLogsBtn.Text = "🧹 Clear"
clearLogsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearLogsBtn.Font = Enum.Font.Code
clearLogsBtn.TextSize = 12
clearLogsBtn.Parent = controlFrame

-- Filter panel
local filterFrame = Instance.new("Frame")
filterFrame.Size = UDim2.new(1, 0, 0.12, 0)
filterFrame.Position = UDim2.new(0, 0, 0.33, 0)
filterFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
filterFrame.BackgroundTransparency = 0.4
filterFrame.Parent = mainFrame

local filterLabel = Instance.new("TextLabel")
filterLabel.Size = UDim2.new(0.15, 0, 0.6, 0)
filterLabel.Position = UDim2.new(0.02, 0, 0.2, 0)
filterLabel.BackgroundTransparency = 1
filterLabel.Text = "Filter:"
filterLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
filterLabel.Font = Enum.Font.Code
filterLabel.TextSize = 12
filterLabel.Parent = filterFrame

local filterTextBox = Instance.new("TextBox")
filterTextBox.Size = UDim2.new(0.8, 0, 0.6, 0)
filterTextBox.Position = UDim2.new(0.18, 0, 0.2, 0)
filterTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
filterTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
filterTextBox.PlaceholderText = "Cari event/function (plant, grow, harvest, dll)..."
filterTextBox.Font = Enum.Font.Code
filterTextBox.TextSize = 12
filterTextBox.Parent = filterFrame

-- Area display (konten utama)
local displayFrame = Instance.new("Frame")
displayFrame.Size = UDim2.new(1, 0, 0.55, 0)
displayFrame.Position = UDim2.new(0, 0, 0.45, 0)
displayFrame.BackgroundTransparency = 1
displayFrame.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.98, 0, 1, 0)
scrollFrame.Position = UDim2.new(0.01, 0, 0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 0)
scrollFrame.Parent = displayFrame

local scrollLabel = Instance.new("TextLabel")
scrollLabel.Size = UDim2.new(1, 0, 0, 0)
scrollLabel.AutomaticSize = Enum.AutomaticSize.Y
scrollLabel.BackgroundTransparency = 1
scrollLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scrollLabel.Text = "System ready. Click START to begin monitoring..."
scrollLabel.TextWrapped = true
scrollLabel.Font = Enum.Font.Code
scrollLabel.TextSize = 12
scrollLabel.TextXAlignment = Enum.TextXAlignment.Left
scrollLabel.TextYAlignment = Enum.TextYAlignment.Top
scrollLabel.Parent = scrollFrame

print("🌱 Advanced Garden Debug GUI berhasil dibuat!")

-- Fungsi untuk minimize GUI
local function minimizeGUI()
    if isMinimized then return end
    
    isMinimized = true
    minimizeButton.Text = "+"
    minimizeButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    
    -- Simpan size dan position sebelum minimize
    mainFrame.ClipsDescendants = true
    
    -- Animasi minimize
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(mainFrame, tweenInfo, {
        Size = UDim2.new(0, 300, 0, 60)
    })
    tween:Play()
    
    -- Sembunyikan konten
    controlFrame.Visible = false
    filterFrame.Visible = false
    displayFrame.Visible = false
    
    -- Update title untuk minimized state
    title.Text = "🌱 DEBUG [MINIMIZED]"
    
    updateDebugInfo("SYSTEM", "GUI Minimized", "GUI has been minimized. Click + to maximize.")
end

-- Fungsi untuk maximize GUI
local function maximizeGUI()
    if not isMinimized then return end
    
    isMinimized = false
    minimizeButton.Text = "−"
    minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    
    -- Animasi maximize
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(mainFrame, tweenInfo, {
        Size = UDim2.new(0, 500, 0, 350)
    })
    tween:Play()
    
    -- Tampilkan konten setelah animasi
    wait(0.3)
    mainFrame.ClipsDescendants = false
    controlFrame.Visible = true
    filterFrame.Visible = true
    displayFrame.Visible = true
    
    -- Update title
    title.Text = "🌱 GARDEN DEBUG SYSTEM 🌱"
    
    updateDebugInfo("SYSTEM", "GUI Maximized", "GUI has been maximized.")
end

-- Toggle minimize/maximize
minimizeButton.MouseButton1Click:Connect(function()
    if isMinimized then
        maximizeGUI()
    else
        minimizeGUI()
    end
end)

-- Fungsi untuk drag GUI
local function startDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
        guiStartPos = mainFrame.Position
    end
end

local function endDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        dragStartPos = nil
        guiStartPos = nil
    end
end

local function updateDrag(input)
    if isDragging and dragStartPos and guiStartPos then
        local delta = Vector2.new(
            input.Position.X - dragStartPos.X,
            input.Position.Y - dragStartPos.Y
        )
        
        local newPosition = UDim2.new(
            guiStartPos.X.Scale, 
            guiStartPos.X.Offset + delta.X,
            guiStartPos.Y.Scale, 
            guiStartPos.Y.Offset + delta.Y
        )
        
        -- Batasi agar tidak keluar layar
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local frameSize = mainFrame.AbsoluteSize
        
        if newPosition.Offset.X < 0 then
            newPosition = UDim2.new(newPosition.X.Scale, 0, newPosition.Y.Scale, newPosition.Y.Offset)
        elseif newPosition.Offset.X + frameSize.X > viewportSize.X then
            newPosition = UDim2.new(newPosition.X.Scale, viewportSize.X - frameSize.X, newPosition.Y.Scale, newPosition.Y.Offset)
        end
        
        if newPosition.Offset.Y < 0 then
            newPosition = UDim2.new(newPosition.X.Scale, newPosition.X.Offset, newPosition.Y.Scale, 0)
        elseif newPosition.Offset.Y + frameSize.Y > viewportSize.Y then
            newPosition = UDim2.new(newPosition.X.Scale, newPosition.X.Offset, newPosition.Y.Scale, viewportSize.Y - frameSize.Y)
        end
        
        mainFrame.Position = newPosition
    end
end

-- Setup drag events untuk header
header.InputBegan:Connect(startDrag)
header.InputEnded:Connect(endDrag)
header.InputChanged:Connect(updateDrag)

-- Juga buat title bisa di-drag
title.InputBegan:Connect(startDrag)
title.InputEnded:Connect(endDrag)
title.InputChanged:Connect(updateDrag)

-- Fungsi untuk format data arguments
local function formatArguments(args)
    if not args or #args == 0 then
        return "No arguments"
    end
    
    local formatted = {}
    for i, arg in ipairs(args) do
        local argType = typeof(arg)
        local argValue = tostring(arg)
        
        -- Truncate long strings
        if argType == "string" and #argValue > 50 then
            argValue = argValue:sub(1, 50) .. "..."
        end
        
        -- Special formatting for common types
        if argType == "Vector3" then
            argValue = string.format("Vector3(%.1f, %.1f, %.1f)", arg.X, arg.Y, arg.Z)
        elseif argType == "CFrame" then
            argValue = "CFrame(...)"
        elseif argType == "Instance" then
            argValue = arg:GetFullName()
        end
        
        table.insert(formatted, string.format("[%d] %s: %s", i, argType, argValue))
    end
    
    return table.concat(formatted, "\n")
end

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
🎯 DEBUG TYPE: %s
📋 DETAILS: %s

👤 PLAYER INFO:
- Name: %s
- Health: %s
- Position: %s

⚡ PERFORMANCE:
- FPS: %d
- Time: %s
- Status: %s
- GUI: %s

📊 DATA:
%s
    ]], 
    debugType, 
    details,
    player.Name,
    health,
    position,
    fps,
    os.date("%H:%M:%S"),
    isMonitoring and "ACTIVE" or "PAUSED",
    isMinimized and "MINIMIZED" or "MAXIMIZED",
    data or "No additional data")
    
    scrollLabel.Text = debugText
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLabel.TextBounds.Y + 20)
    
    -- Print ke console juga
    print("🌱=== GARDEN DEBUG ===")
    print("Type: " .. debugType)
    print("Details: " .. details)
    print("Status: " .. (isMonitoring and "ACTIVE" or "PAUSED"))
    print("GUI: " .. (isMinimized and "MINIMIZED" or "MAXIMIZED"))
    print("=====================🌱")
end

-- Fungsi untuk menambah log entry
local function addLogEntry(entry)
    table.insert(remoteEventLogs, entry)
    
    -- Batasi jumlah log entries
    if #remoteEventLogs > maxLogEntries then
        table.remove(remoteEventLogs, 1)
    end
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
    local eventPath = remoteEvent:GetFullName()
    
    local success, errorMsg = pcall(function()
        local connection = remoteEvent.OnClientEvent:Connect(function(...)
            if not isMonitoring then return end
            
            local args = {...}
            local logEntry = {
                type = "REMOTEEVENT_RECEIVED",
                event = eventName,
                path = eventPath,
                args = args,
                timestamp = os.date("%H:%M:%S"),
                player = player.Name
            }
            
            addLogEntry(logEntry)
            
            -- Filter berdasarkan input user
            local filterText = filterTextBox.Text:lower()
            if filterText == "" or eventName:lower():find(filterText, 1, true) then
                updateDebugInfo("🌐 REMOTEEVENT RECEIVED", 
                    "Server → Client: " .. eventName,
                    string.format("Event: %s\nPath: %s\nArguments Count: %d\n\nArguments:\n%s",
                    eventName, eventPath, #args, formatArguments(args)))
            end
        end)
        
        remoteEventConnections[remoteEvent] = connection
    end)
    
    if success then
        print("📡 Now tracking RemoteEvent: " .. eventName .. " at " .. eventPath)
    else
        warn("❌ Gagal melacak RemoteEvent " .. eventName .. ": " .. errorMsg)
    end
end

-- Fungsi untuk melacak RemoteFunction
local function trackRemoteFunction(remoteFunction)
    if trackedRemoteFunctions[remoteFunction] then return end
    
    trackedRemoteFunctions[remoteFunction] = true
    local functionName = remoteFunction.Name
    local functionPath = remoteFunction:GetFullName()
    
    local success, errorMsg = pcall(function()
        -- Simpan function asli
        local originalFunction = remoteFunction.InvokeServer
        
        -- Override function
        remoteFunction.InvokeServer = function(self, ...)
            local args = {...}
            
            if isMonitoring then
                local logEntry = {
                    type = "REMOTEFUNCTION_INVOKED",
                    functionName = functionName,
                    path = functionPath,
                    args = args,
                    timestamp = os.date("%H:%M:%S"),
                    player = player.Name,
                    direction = "CLIENT → SERVER"
                }
                
                addLogEntry(logEntry)
                
                -- Filter berdasarkan input user
                local filterText = filterTextBox.Text:lower()
                if filterText == "" or functionName:lower():find(filterText, 1, true) then
                    updateDebugInfo("🔧 REMOTEFUNCTION INVOKED", 
                        "Client → Server: " .. functionName,
                        string.format("Function: %s\nPath: %s\nArguments Count: %d\n\nArguments:\n%s",
                        functionName, functionPath, #args, formatArguments(args)))
                end
            end
            
            -- Panggil function asli
            return originalFunction(self, ...)
        end
        
        remoteFunctionConnections[remoteFunction] = true
    end)
    
    if success then
        print("🔧 Now tracking RemoteFunction: " .. functionName .. " at " .. functionPath)
    else
        warn("❌ Gagal melacak RemoteFunction " .. functionName .. ": " .. errorMsg)
    end
end

-- Scan RemoteEvents dan RemoteFunctions
local function scanNetworkObjects()
    trackedRemoteEvents = {}
    trackedRemoteFunctions = {}
    
    -- Putuskan koneksi lama
    for _, connection in pairs(remoteEventConnections) do
        connection:Disconnect()
    end
    
    remoteEventConnections = {}
    remoteFunctionConnections = {}
    
    local eventCount = 0
    local functionCount = 0
    
    -- Scan semua tempat umum
    local locationsToScan = {
        ReplicatedStorage,
        workspace,
        game:GetService("Lighting"),
        game:GetService("StarterPack"),
        game:GetService("StarterGui"),
        game:GetService("StarterPlayer")
    }
    
    for _, location in ipairs(locationsToScan) do
        for _, obj in ipairs(location:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                trackRemoteEvent(obj)
                eventCount += 1
            elseif obj:IsA("RemoteFunction") then
                trackRemoteFunction(obj)
                functionCount += 1
            end
        end
    end
    
    updateDebugInfo("SYSTEM", "Network Scan Complete", 
        string.format("RemoteEvents tracked: %d\nRemoteFunctions tracked: %d", eventCount, functionCount))
end

eventScanBtn.MouseButton1Click:Connect(function()
    scanNetworkObjects()
end)

functionScanBtn.MouseButton1Click:Connect(function()
    scanNetworkObjects()
end)

-- Scan buttons
local function scanButtons()
    -- Putuskan koneksi lama
    for _, connection in pairs(buttonConnections) do
        connection:Disconnect()
    end
    
    buttonConnections = {}
    wait(0.5)
    
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
AbsoluteSize: %s
AbsolutePosition: %s
%s
                    ]],
                    guiElement.Name,
                    guiElement.Parent and guiElement.Parent:GetFullName() or "N/A",
                    tostring(guiElement.Visible),
                    tostring(guiElement.Size),
                    tostring(guiElement.Position),
                    tostring(guiElement.AbsoluteSize),
                    tostring(guiElement.AbsolutePosition),
                    additionalInfo)
                    
                    updateDebugInfo("🖱️ BUTTON CLICK", "Button: " .. guiElement.Name, buttonInfo)
                    
                    -- Highlight effect
                    local originalBg = guiElement.BackgroundColor3
                    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(guiElement, tweenInfo, {BackgroundColor3 = Color3.fromRGB(0, 255, 0)})
                    tween:Play()
                    wait(0.3)
                    tween = TweenService:Create(guiElement, tweenInfo, {BackgroundColor3 = originalBg})
                    tween:Play()
                end)
                
                buttonConnections[guiElement] = connection
                buttonCount += 1
            end)
            
            if not success then
                warn("❌ Gagal connect ke button " .. guiElement.Name .. ": " .. errorMsg)
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

-- Filter text change
filterTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    if #remoteEventLogs > 0 then
        updateDebugInfo("FILTER", "Filter Updated", "Filter text: " .. filterTextBox.Text)
    end
end)

-- Monitor untuk RemoteEvents/RemoteFunctions baru
local function setupDescendantMonitoring()
    local function onDescendantAdded(descendant)
        if descendant:IsA("RemoteEvent") then
            wait(0.5)
            trackRemoteEvent(descendant)
        elseif descendant:IsA("RemoteFunction") then
            wait(0.5)
            trackRemoteFunction(descendant)
        end
    end
    
    -- Monitor semua lokasi penting
    local locationsToMonitor = {
        ReplicatedStorage,
        workspace
    }
    
    for _, location in ipairs(locationsToMonitor) do
        location.DescendantAdded:Connect(onDescendantAdded)
    end
end

-- Hotkey system dengan fitur tambahan
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        if #remoteEventLogs == 0 then
            updateDebugInfo("📊 REMOTEEVENT LOGS", "No events tracked", "No network activity recorded")
            return
        end
        
        local logText = "📊 NETWORK ACTIVITY LOG (Recent First):\n\n"
        for i = #remoteEventLogs, 1, -1 do
            local log = remoteEventLogs[i]
            logText = logText .. string.format("--- [%d] %s ---\n", i, log.timestamp)
            logText = logText .. string.format("Type: %s\n", log.type)
            logText = logText .. string.format("Name: %s\n", log.event or log.functionName)
            logText = logText .. string.format("Path: %s\n", log.path)
            logText = logText .. string.format("Args Count: %d\n\n", #log.args)
        end
        updateDebugInfo("📊 ACTIVITY LOGS", "Recent Network Activity", logText)
        
    elseif input.KeyCode == Enum.KeyCode.F2 then
        -- Show player info
        local playerInfo = string.format([[
Player: %s
UserID: %d
Account Age: %d days
Membership: %s

Character: %s
Health: %s
Position: %s
        ]],
        player.Name,
        player.UserId,
        player.AccountAge,
        tostring(player.MembershipType),
        player.Character and player.Character.Name or "None",
        player.Character and player.Character:FindFirstChild("Humanoid") and 
            string.format("%.0f/%.0f", player.Character.Humanoid.Health, player.Character.Humanoid.MaxHealth) or "N/A",
        player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
            string.format("X:%.1f, Y:%.1f, Z:%.1f", 
                player.Character.HumanoidRootPart.Position.X,
                player.Character.HumanoidRootPart.Position.Y,
                player.Character.HumanoidRootPart.Position.Z) or "N/A")
        
        updateDebugInfo("👤 PLAYER INFO", "Detailed Player Information", playerInfo)
        
    elseif input.KeyCode == Enum.KeyCode.F5 then
        -- Toggle monitoring dengan F5
        if isMonitoring then
            stopMonitoring()
        else
            startMonitoring()
        end
    elseif input.KeyCode == Enum.KeyCode.F6 then
        -- Quick scan
        scanNetworkObjects()
    elseif input.KeyCode == Enum.KeyCode.F9 then
        -- Toggle minimize/maximize dengan F9
        if isMinimized then
            maximizeGUI()
        else
            minimizeGUI()
        end
    elseif input.KeyCode == Enum.KeyCode.F10 then
        -- Reset GUI position
        mainFrame.Position = UDim2.new(0, 10, 0, 10)
        updateDebugInfo("SYSTEM", "GUI Position Reset", "GUI has been reset to default position")
    end
end)

-- System info display
local function updateSystemInfo()
    while true do
        wait(2)
        if isMonitoring then
            local success, fps = pcall(function()
                return math.floor(1/RunService.Heartbeat:Wait())
            end)
            
            if not success then fps = 0 end
            
            -- Update title dengan info real-time
            local minimizedText = isMinimized and "[MINIMIZED]" or ""
            title.Text = string.format("🌱 DEBUG %s | FPS: %d | Events: %d | %s 🌱", 
                minimizedText, fps, #remoteEventLogs, isMonitoring and "ACTIVE" or "PAUSED")
        end
    end
end

-- Initialize system
local function initializeSystem()
    -- Mulai dalam keadaan aktif
    startMonitoring()
    setupDescendantMonitoring()
    scanNetworkObjects()
    scanButtons()
    spawn(updateSystemInfo)
    
    updateDebugInfo("🌱 SYSTEM READY", "Garden Debug System Initialized", 
        string.format([[
Hotkeys:
F1 - Show Network Activity Logs
F2 - Show Player Info  
F5 - Toggle Monitoring
F6 - Quick Rescan
F9 - Toggle Minimize/Maximize
F10 - Reset GUI Position

Drag: Click and drag header to move GUI
Minimize: Click - button to minimize

Filter: Type in filter box to filter events/functions

Game: Grow a Garden
Player: %s
        ]], player.Name))
    
    print("🌱=== GARDEN DEBUG SYSTEM READY ===")
    print("F1 - Show Network Activity Logs")
    print("F2 - Show Player Info")
    print("F5 - Toggle Monitoring") 
    print("F6 - Quick Rescan")
    print("F9 - Toggle Minimize/Maximize")
    print("F10 - Reset GUI Position")
    print("🌱===================================")
end

-- Tunggu sebentar sebelum initialize
wait(2)
initializeSystem()
