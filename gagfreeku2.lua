-- LocalScript di StarterPlayerScripts
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

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

-- Variabel untuk rekam kegiatan
local isRecording = false
local activityLog = {}
local recordedActivities = {}
local isPlayingBack = false
local currentPlaybackIndex = 1

-- Deteksi perangkat mobile
local isMobile = UserInputService.TouchEnabled
local isConsole = UserInputService.GamepadEnabled
local isDesktop = not isMobile and not isConsole

print("Device detected: " .. (isMobile and "Mobile" or isConsole and "Console" or "Desktop"))

-- Konfigurasi UI berdasarkan perangkat
local UI_CONFIG = {
    -- Mobile configuration
    mobile = {
        screenGuiScale = 0.9,
        mainFrameSize = UDim2.new(0.95, 0, 0.4, 0),
        mainFramePosition = UDim2.new(0.025, 0, 0.02, 0),
        headerHeight = 0.12,
        controlFrameHeight = 0.25,
        displayFrameHeight = 0.63,
        buttonFontSize = 10,
        titleFontSize = 14,
        debugFontSize = 11,
        buttonHeight = 0.35,
        buttonSpacing = 0.02,
        cornerRadius = 12
    },
    -- Desktop configuration
    desktop = {
        screenGuiScale = 1,
        mainFrameSize = UDim2.new(0, 500, 0, 350),
        mainFramePosition = UDim2.new(0, 10, 0, 10),
        headerHeight = 0.15,
        controlFrameHeight = 0.2,
        displayFrameHeight = 0.65,
        buttonFontSize = 11,
        titleFontSize = 16,
        debugFontSize = 12,
        buttonHeight = 0.4,
        buttonSpacing = 0.01,
        cornerRadius = 8
    }
}

local config = isMobile and UI_CONFIG.mobile or UI_CONFIG.desktop

-- Buat UI debug yang responsive
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileDebugGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- Background overlay untuk mobile (lebih mudah di-tap)
local backgroundOverlay = Instance.new("Frame")
backgroundOverlay.Size = UDim2.new(1, 0, 1, 0)
backgroundOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backgroundOverlay.BackgroundTransparency = 0.8
backgroundOverlay.Visible = false
backgroundOverlay.ZIndex = 1
backgroundOverlay.Parent = screenGui

-- Main container frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = config.mainFrameSize
mainFrame.Position = config.mainFramePosition
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 2
mainFrame.Parent = screenGui

-- Corner radius untuk mobile yang lebih besar
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, config.cornerRadius)
corner.Parent = mainFrame

-- Shadow effect untuk mobile
if isMobile then
    local shadow = Instance.new("UIStroke")
    shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    shadow.Color = Color3.fromRGB(100, 100, 150)
    shadow.Thickness = 3
    shadow.Parent = mainFrame
end

-- Header dengan kontrol
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, config.headerHeight, 0)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = mainFrame

local cornerHeader = Instance.new("UICorner")
cornerHeader.CornerRadius = UDim.new(0, config.cornerRadius)
cornerHeader.Parent = header

-- Title dengan icon responsive
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6, 0, 0.8, 0)
title.Position = UDim2.new(0.02, 0, 0.1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 0)
title.Text = isMobile and "📱 DEBUG" or "⚡ DEBUG SYSTEM ⚡"
title.Font = Enum.Font.GothamBold
title.TextSize = config.titleFontSize
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = header

-- Tombol minimize/maximize untuk mobile
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0.1, 0, 0.6, 0)
minimizeButton.Position = UDim2.new(0.89, 0, 0.2, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
minimizeButton.Text = isMobile and "─" or "_"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = isMobile and 16 or 14
minimizeButton.ZIndex = 4
minimizeButton.Parent = header

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 6)
minimizeCorner.Parent = minimizeButton

-- Status indicator yang lebih besar untuk mobile
local statusIndicator = Instance.new("Frame")
statusIndicator.Size = isMobile and UDim2.new(0.04, 0, 0.5, 0) or UDim2.new(0.02, 0, 0.4, 0)
statusIndicator.Position = isMobile and UDim2.new(0.75, 0, 0.25, 0) or UDim2.new(0.59, 0, 0.3, 0)
statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
statusIndicator.BorderSizePixel = 0
statusIndicator.ZIndex = 4
statusIndicator.Parent = header

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 4)
statusCorner.Parent = statusIndicator

-- Kontrol panel dengan grid layout untuk mobile
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, 0, config.controlFrameHeight, 0)
controlFrame.Position = UDim2.new(0, 0, config.headerHeight, 0)
controlFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
controlFrame.BorderSizePixel = 0
controlFrame.ZIndex = 3
controlFrame.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, config.cornerRadius)
controlCorner.Parent = controlFrame

-- Fungsi untuk membuat tombol yang responsive
local function createMobileButton(name, positionX, positionY, color, icon)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.23, 0, config.buttonHeight, 0)
    button.Position = UDim2.new(positionX, 0, positionY, 0)
    button.BackgroundColor3 = color
    button.Text = icon .. (isMobile and "" or "\n" .. name)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = config.buttonFontSize
    button.ZIndex = 4
    button.Parent = controlFrame
    
    -- Tombol lebih besar dan rounded di mobile
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, isMobile and 8 or 6)
    buttonCorner.Parent = button
    
    -- Hover effect hanya untuk desktop
    if not isMobile then
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(
                math.min(color.R * 255 + 30, 255),
                math.min(color.G * 255 + 30, 255),
                math.min(color.B * 255 + 30, 255)
            )
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = color
        end)
    end
    
    -- Touch feedback untuk mobile
    if isMobile then
        local function animateTap()
            local originalSize = button.Size
            local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local shrinkTween = TweenService:Create(button, tweenInfo, {Size = originalSize * 0.9})
            local growTween = TweenService:Create(button, tweenInfo, {Size = originalSize})
            
            shrinkTween:Play()
            shrinkTween.Completed:Wait()
            growTween:Play()
        end
        
        button.MouseButton1Click:Connect(animateTap)
    end
    
    return button
end

-- Baris pertama tombol kontrol
local buttonScanBtn = createMobileButton("Scan Buttons", 0.02, 0.1, Color3.fromRGB(70, 70, 200), "🔍")
local eventScanBtn = createMobileButton("Scan Events", 0.27, 0.1, Color3.fromRGB(200, 70, 70), "📡")
local clearLogsBtn = createMobileButton("Clear Logs", 0.52, 0.1, Color3.fromRGB(200, 200, 70), "🧹")
local recordButton = createMobileButton("Record", 0.77, 0.1, Color3.fromRGB(200, 70, 150), "🔴")

-- Baris kedua tombol kontrol
local saveButton = createMobileButton("Save", 0.02, 0.55, Color3.fromRGB(70, 150, 70), "💾")
local playButton = createMobileButton("Play", 0.27, 0.55, Color3.fromRGB(70, 150, 200), "▶")
local loadButton = createMobileButton("Load", 0.52, 0.55, Color3.fromRGB(150, 100, 70), "📂")

-- Tombol tambahan untuk mobile
local helpButton = createMobileButton("Help", 0.77, 0.55, Color3.fromRGB(150, 70, 200), "❓")

-- Area display yang responsive
local displayFrame = Instance.new("Frame")
displayFrame.Size = UDim2.new(1, 0, config.displayFrameHeight, 0)
displayFrame.Position = UDim2.new(0, 0, config.headerHeight + config.controlFrameHeight, 0)
displayFrame.BackgroundTransparency = 1
displayFrame.ZIndex = 3
displayFrame.Parent = mainFrame

-- Scroll frame untuk konten panjang
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.96, 0, 0.98, 0)
scrollFrame.Position = UDim2.new(0.02, 0, 0.01, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
scrollFrame.ScrollBarThickness = isMobile and 8 or 6
scrollFrame.ZIndex = 4
scrollFrame.Parent = displayFrame

local scrollLabel = Instance.new("TextLabel")
scrollLabel.Size = UDim2.new(1, 0, 0, 0) -- Auto-size
scrollLabel.BackgroundTransparency = 1
scrollLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scrollLabel.Text = "System initializing..."
scrollLabel.TextWrapped = true
scrollLabel.Font = Enum.Font.Gotham
scrollLabel.TextSize = config.debugFontSize
scrollLabel.TextXAlignment = Enum.TextXAlignment.Left
scrollLabel.TextYAlignment = Enum.TextYAlignment.Top
scrollLabel.ZIndex = 4
scrollLabel.Parent = scrollFrame

-- Drag functionality untuk mobile/desktop
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Resize functionality untuk desktop
if not isMobile then
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Size = UDim2.new(0, 20, 0, 20)
    resizeHandle.Position = UDim2.new(1, -20, 1, -20)
    resizeHandle.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
    resizeHandle.Text = "⤢"
    resizeHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
    resizeHandle.Font = Enum.Font.GothamBold
    resizeHandle.TextSize = 12
    resizeHandle.ZIndex = 4
    resizeHandle.Parent = mainFrame
    
    local resizeCorner = Instance.new("UICorner")
    resizeCorner.CornerRadius = UDim.new(0, 4)
    resizeCorner.Parent = resizeHandle
    
    local resizing = false
    local resizeStart, resizeStartSize
    
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            resizeStartSize = mainFrame.Size
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newSize = UDim2.new(
                resizeStartSize.X.Scale, 
                math.max(300, resizeStartSize.X.Offset + delta.X),
                resizeStartSize.Y.Scale,
                math.max(200, resizeStartSize.Y.Offset + delta.Y)
            )
            mainFrame.Size = newSize
        end
    end)
end

print("Mobile-friendly Debug GUI berhasil dibuat! Device: " .. (isMobile and "Mobile" or "Desktop"))

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
    
    local recordingStatus = isRecording and "🔴 RECORDING" or "⚫ NOT RECORDING"
    local playbackStatus = isPlayingBack and "▶ PLAYING" or "⏸ READY"
    
    local debugText = string.format([[
🔍 %s
📋 %s

👤 CHARACTER:
- Name: %s
- Health: %s
- Position: %s

⚡ PERFORMANCE:
- FPS: %d
- Time: %s
- Status: %s

🎥 RECORDING:
- Status: %s
- Playback: %s
- Activities: %d

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
    recordingStatus,
    playbackStatus,
    #activityLog,
    data or "📊 No additional data")
    
    -- Update scroll label dan auto-size
    scrollLabel.Text = debugText
    scrollLabel.Size = UDim2.new(1, 0, 0, scrollLabel.TextBounds.Y + 10)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLabel.TextBounds.Y + 20)
    
    -- Print ke console juga
    print("=== DEBUG ===")
    print("Type: " .. debugType)
    print("Details: " .. details)
    print("Recording: " .. (isRecording and "ON" or "OFF"))
    print("=============")
end

-- Fungsi toggle minimize/maximize
local isMinimized = false
local originalSize = mainFrame.Size
local minimizedSize = UDim2.new(0.3, 0, 0.1, 0)

local function toggleMinimize()
    if isMinimized then
        -- Maximize
        mainFrame.Size = originalSize
        controlFrame.Visible = true
        displayFrame.Visible = true
        minimizeButton.Text = isMobile and "─" or "_"
        isMinimized = false
    else
        -- Minimize
        mainFrame.Size = minimizedSize
        controlFrame.Visible = false
        displayFrame.Visible = false
        minimizeButton.Text = "⊕"
        isMinimized = true
    end
end

minimizeButton.MouseButton1Click:Connect(toggleMinimize)

-- Fungsi show help
local function showHelp()
    local helpText = [[
🎮 DEBUG SYSTEM HELP

📱 MOBILE CONTROLS:
- Drag window to move
- Tap buttons to activate
- Scroll to view logs

🔧 QUICK ACTIONS:
🔍 Scan Buttons - Find clickable elements
📡 Scan Events - Monitor RemoteEvents
🧹 Clear Logs - Reset all logs
🔴 Record - Start/stop activity recording
💾 Save - Save recorded activities
▶ Play - Replay saved activities
📂 Load - View saved recordings

⚡ HOTKEYS (Desktop):
F1 - Show event logs
F5 - Toggle monitoring
F9 - Toggle recording
F10 - Play recording

❓ Tap Help again to close
    ]]
    
    if scrollLabel.Text:find("DEBUG SYSTEM HELP") then
        updateDebugInfo("HELP", "Help closed", "Returning to normal view")
    else
        scrollLabel.Text = helpText
        scrollLabel.Size = UDim2.new(1, 0, 0, scrollLabel.TextBounds.Y + 10)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLabel.TextBounds.Y + 20)
    end
end

helpButton.MouseButton1Click:Connect(showHelp)

-- ... (Fungsi-fungsi lainnya tetap sama seperti sebelumnya)
-- Fungsi untuk memulai monitoring
local function startMonitoring()
    if isMonitoring then return end
    
    isMonitoring = true
    statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    
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
    statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    
    updateDebugInfo("SYSTEM", "Monitoring Stopped", "All monitoring functions are now PAUSED")
    
    -- Animasi
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(statusIndicator, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 0, 0)})
    tween:Play()
end

-- ========== FITUR REKAM KEGIATAN ==========
-- ... (Fungsi rekam kegiatan sama seperti sebelumnya)

-- Toggle monitoring
startStopButton = createMobileButton("Stop", 0.77, 0.55, Color3.fromRGB(0, 200, 0), "⏹")
startStopButton.MouseButton1Click:Connect(function()
    if isMonitoring then
        stopMonitoring()
        startStopButton.Text = "▶"
        startStopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        startMonitoring()
        startStopButton.Text = "⏹"
        startStopButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end
end)

-- Initialize system
local function initializeSystem()
    -- Mulai dalam keadaan aktif
    startMonitoring()
    
    updateDebugInfo("SYSTEM", "Mobile Debug Ready", 
        string.format("Device: %s\nTouch enabled: %s\n\nTap buttons to start debugging!",
        isMobile and "Mobile" or "Desktop", tostring(isMobile)))
    
    print("=== MOBILE DEBUG SYSTEM READY ===")
    print("Device: " .. (isMobile and "Mobile" or "Desktop"))
    print("=================================")
end

-- Tunggu sebentar sebelum initialize
wait(2)
initializeSystem()

-- System info display
local function updateSystemInfo()
    while true do
        wait(3)
        local success, fps = pcall(function()
            return math.floor(1/RunService.Heartbeat:Wait())
        end)
        
        if not success then fps = 0 end
        
        -- Update title dengan info real-time
        local recordingInfo = isRecording and string.format(" | 🔴:%d", #activityLog) or ""
        local playbackInfo = isPlayingBack and string.format(" | ▶:%d", currentPlaybackIndex) or ""
        
        title.Text = string.format("%s FPS:%d%s%s", 
            isMobile and "📱" or "⚡", fps, recordingInfo, playbackInfo)
    end
end

spawn(updateSystemInfo)
