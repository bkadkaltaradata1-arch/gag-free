-- LocalScript di StarterPlayerScripts
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

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
local carrotSeedTracking = {
    initialCount = 0,
    currentCount = 0,
    buyAttempts = 0,
    successfulBuys = 0,
    buttonClicks = 0
}

-- Buat UI debug yang lebih besar dengan kontrol khusus carrot seed
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
title.Text = "🥕 CARROT SEED DEBUGGER 🥕"
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

-- Kontrol panel utama
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, 0, 0.2, 0)
controlFrame.Position = UDim2.new(0, 0, 0.15, 0)
controlFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controlFrame.BackgroundTransparency = 0.3
controlFrame.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 6)
controlCorner.Parent = controlFrame

-- Tombol kontrol utama
local buttonScanBtn = Instance.new("TextButton")
buttonScanBtn.Size = UDim2.new(0.23, 0, 0.7, 0)
buttonScanBtn.Position = UDim2.new(0.01, 0, 0.15, 0)
buttonScanBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 200)
buttonScanBtn.Text = "🔍 Scan Buttons"
buttonScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buttonScanBtn.Font = Enum.Font.Code
buttonScanBtn.TextSize = 12
buttonScanBtn.Parent = controlFrame

local eventScanBtn = Instance.new("TextButton")
eventScanBtn.Size = UDim2.new(0.23, 0, 0.7, 0)
eventScanBtn.Position = UDim2.new(0.25, 0, 0.15, 0)
eventScanBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
eventScanBtn.Text = "📡 Scan Events"
eventScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
eventScanBtn.Font = Enum.Font.Code
eventScanBtn.TextSize = 12
eventScanBtn.Parent = controlFrame

local clearLogsBtn = Instance.new("TextButton")
clearLogsBtn.Size = UDim2.new(0.23, 0, 0.7, 0)
clearLogsBtn.Position = UDim2.new(0.49, 0, 0.15, 0)
clearLogsBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 70)
clearLogsBtn.Text = "🧹 Clear Logs"
clearLogsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearLogsBtn.Font = Enum.Font.Code
clearLogsBtn.TextSize = 12
clearLogsBtn.Parent = controlFrame

-- Panel khusus carrot seed
local carrotControlFrame = Instance.new("Frame")
carrotControlFrame.Size = UDim2.new(1, 0, 0.2, 0)
carrotControlFrame.Position = UDim2.new(0, 0, 0.35, 0)
carrotControlFrame.BackgroundColor3 = Color3.fromRGB(40, 20, 0)
carrotControlFrame.BackgroundTransparency = 0.2
carrotControlFrame.Parent = mainFrame

local carrotCorner = Instance.new("UICorner")
carrotCorner.CornerRadius = UDim.new(0, 6)
carrotCorner.Parent = carrotControlFrame

local carrotTitle = Instance.new("TextLabel")
carrotTitle.Size = UDim2.new(1, 0, 0.3, 0)
carrotTitle.BackgroundTransparency = 1
carrotTitle.TextColor3 = Color3.fromRGB(255, 165, 0)
carrotTitle.Text = "🥕 CARROT SEED TRACKER 🥕"
carrotTitle.Font = Enum.Font.Code
carrotTitle.TextSize = 14
carrotTitle.Parent = carrotControlFrame

-- Tombol khusus carrot seed
local checkCarrotBtn = Instance.new("TextButton")
checkCarrotBtn.Size = UDim2.new(0.3, 0, 0.6, 0)
checkCarrotBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
checkCarrotBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
checkCarrotBtn.Text = "🔍 Check Seed Count"
checkCarrotBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
checkCarrotBtn.Font = Enum.Font.Code
checkCarrotBtn.TextSize = 12
checkCarrotBtn.Parent = carrotControlFrame

local autoBuyCarrotBtn = Instance.new("TextButton")
autoBuyCarrotBtn.Size = UDim2.new(0.3, 0, 0.6, 0)
autoBuyCarrotBtn.Position = UDim2.new(0.34, 0, 0.4, 0)
autoBuyCarrotBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
autoBuyCarrotBtn.Text = "🔄 Auto Buy Seeds"
autoBuyCarrotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBuyCarrotBtn.Font = Enum.Font.Code
autoBuyCarrotBtn.TextSize = 12
autoBuyCarrotBtn.Parent = carrotControlFrame

local trackCarrotBtn = Instance.new("TextButton")
trackCarrotBtn.Size = UDim2.new(0.3, 0, 0.6, 0)
trackCarrotBtn.Position = UDim2.new(0.66, 0, 0.4, 0)
trackCarrotBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
trackCarrotBtn.Text = "📊 Track Carrot Data"
trackCarrotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
trackCarrotBtn.Font = Enum.Font.Code
trackCarrotBtn.TextSize = 12
trackCarrotBtn.Parent = carrotControlFrame

-- Area display
local displayFrame = Instance.new("Frame")
displayFrame.Size = UDim2.new(1, 0, 0.45, 0)
displayFrame.Position = UDim2.new(0, 0, 0.55, 0)
displayFrame.BackgroundTransparency = 1
displayFrame.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.95, 0, 1, 0)
scrollFrame.Position = UDim2.new(0.025, 0, 0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = displayFrame

local scrollLabel = Instance.new("TextLabel")
scrollLabel.Size = UDim2.new(1, 0, 2, 0)
scrollLabel.BackgroundTransparency = 1
scrollLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scrollLabel.Text = "System ready. Click START to begin monitoring..."
scrollLabel.TextWrapped = true
scrollLabel.Font = Enum.Font.Code
scrollLabel.TextSize = 12
scrollLabel.TextXAlignment = Enum.TextXAlignment.Left
scrollLabel.TextYAlignment = Enum.TextYAlignment.Top
scrollLabel.Parent = scrollFrame

print("Advanced Carrot Seed Debug GUI berhasil dibuat!")

-- Fungsi untuk mencari backpack player dan menghitung seed carrot
local function getCarrotSeedCount()
    local success, result = pcall(function()
        -- Cari backpack player
        local backpack = player:FindFirstChild("Backpack")
        if not backpack then
            return "Backpack tidak ditemukan"
        end
        
        -- Cari tools/items di backpack
        local carrotSeeds = 0
        local seedItems = {}
        
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Folder") or item:IsA("Model") then
                local itemName = string.lower(item.Name)
                
                -- Cek berbagai kemungkinan nama untuk seed carrot
                if string.find(itemName, "carrot") and string.find(itemName, "seed") then
                    carrotSeeds = carrotSeeds + 1
                    table.insert(seedItems, item.Name)
                elseif string.find(itemName, "seed") and string.find(itemName, "carrot") then
                    carrotSeeds = carrotSeeds + 1
                    table.insert(seedItems, item.Name)
                elseif itemName == "carrot seed" or itemName == "seed carrot" then
                    carrotSeeds = carrotSeeds + 1
                    table.insert(seedItems, item.Name)
                end
            end
        end
        
        -- Update tracking data
        carrotSeedTracking.currentCount = carrotSeeds
        if carrotSeedTracking.initialCount == 0 then
            carrotSeedTracking.initialCount = carrotSeeds
        end
        
        return {
            count = carrotSeeds,
            items = seedItems,
            initialCount = carrotSeedTracking.initialCount,
            difference = carrotSeeds - carrotSeedTracking.initialCount
        }
    end)
    
    if not success then
        return {count = 0, items = {}, error = result}
    end
    
    return result
end

-- Fungsi untuk mencari semua button buy seed carrot
local function findCarrotSeedButtons()
    local carrotButtons = {}
    local allButtons = {}
    
    -- Scan seluruh GUI
    local guis = player.PlayerGui:GetDescendants()
    
    for _, guiElement in ipairs(guis) do
        if guiElement:IsA("TextButton") or guiElement:IsA("ImageButton") then
            local buttonName = string.lower(guiElement.Name)
            local buttonText = ""
            
            if guiElement:IsA("TextButton") then
                buttonText = string.lower(guiElement.Text or "")
            end
            
            -- Cek berbagai kemungkinan nama button untuk buy carrot seed
            local isCarrotButton = false
            local matchType = ""
            
            if string.find(buttonName, "carrot") and string.find(buttonName, "buy") then
                isCarrotButton = true
                matchType = "Name contains 'carrot' and 'buy'"
            elseif string.find(buttonName, "carrot") and string.find(buttonName, "seed") then
                isCarrotButton = true
                matchType = "Name contains 'carrot' and 'seed'"
            elseif string.find(buttonText, "carrot") and string.find(buttonText, "buy") then
                isCarrotButton = true
                matchType = "Text contains 'carrot' and 'buy'"
            elseif string.find(buttonText, "carrot") and string.find(buttonText, "seed") then
                isCarrotButton = true
                matchType = "Text contains 'carrot' and 'seed'"
            elseif string.find(buttonName, "buy") and (string.find(buttonName, "seed") or string.find(buttonText, "seed")) then
                isCarrotButton = true
                matchType = "Generic seed buy button"
            end
            
            if isCarrotButton then
                local buttonInfo = {
                    button = guiElement,
                    name = guiElement.Name,
                    text = guiElement:IsA("TextButton") and guiElement.Text or "N/A",
                    path = getFullPath(guiElement),
                    matchType = matchType,
                    visible = guiElement.Visible,
                    enabled = guiElement.Enabled
                }
                table.insert(carrotButtons, buttonInfo)
            end
            
            table.insert(allButtons, {
                button = guiElement,
                name = guiElement.Name,
                text = guiElement:IsA("TextButton") and guiElement.Text or "N/A"
            })
        end
    end
    
    return {
        carrotButtons = carrotButtons,
        allButtons = allButtons,
        totalCarrotButtons = #carrotButtons,
        totalButtons = #allButtons
    }
end

-- Fungsi untuk mendapatkan full path dari instance
local function getFullPath(instance)
    local path = instance.Name
    local current = instance.Parent
    
    while current and current ~= game do
        path = current.Name .. " > " .. path
        current = current.Parent
    end
    
    return path
end

-- Fungsi untuk mencoba semua button buy seed carrot
local function tryAllCarrotSeedButtons()
    local buttonsInfo = findCarrotSeedButtons()
    local carrotButtons = buttonsInfo.carrotButtons
    
    if #carrotButtons == 0 then
        return {
            success = false,
            message = "Tidak ditemukan button buy seed carrot",
            buttonsFound = 0
        }
    end
    
    local attemptedButtons = 0
    local successfulClicks = 0
    local originalCount = carrotSeedTracking.currentCount
    
    -- Catat state sebelum mencoba
    local beforeState = getCarrotSeedCount()
    
    for i, buttonInfo in ipairs(carrotButtons) do
        if buttonInfo.button.Visible and buttonInfo.button.Enabled then
            attemptedButtons = attemptedButtons + 1
            
            -- Simpan original color untuk efek visual
            local originalColor = buttonInfo.button.BackgroundColor3
            
            -- Coba click button
            local success, errorMsg = pcall(function()
                -- Trigger click event
                buttonInfo.button:FireEvent("MouseButton1Click")
                
                -- Visual feedback
                buttonInfo.button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                wait(0.2)
                buttonInfo.button.BackgroundColor3 = originalColor
            end)
            
            if success then
                successfulClicks = successfulClicks + 1
                carrotSeedTracking.buttonClicks = carrotSeedTracking.buttonClicks + 1
            end
            
            wait(0.5) -- Delay antara clicks
        end
    end
    
    -- Tunggu sebentar untuk update state
    wait(1)
    local afterState = getCarrotSeedCount()
    
    -- Cek jika seed count bertambah
    local seedIncreased = afterState.count > beforeState.count
    if seedIncreased then
        carrotSeedTracking.successfulBuys = carrotSeedTracking.successfulBuys + 1
        carrotSeedTracking.buyAttempts = carrotSeedTracking.buyAttempts + attemptedButtons
    end
    
    return {
        success = true,
        attemptedButtons = attemptedButtons,
        successfulClicks = successfulClicks,
        seedIncreased = seedIncreased,
        beforeCount = beforeState.count,
        afterCount = afterState.count,
        difference = afterState.count - beforeState.count,
        totalCarrotButtons = #carrotButtons
    }
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
🔍 DEBUG TYPE: %s
📋 DETAILS: %s

👤 CHARACTER INFO:
- Name: %s
- Health: %s
- Position: %s

🥕 CARROT SEED TRACKING:
- Initial: %d
- Current: %d
- Difference: %d
- Buy Attempts: %d
- Successful Buys: %d
- Button Clicks: %d

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
    carrotSeedTracking.initialCount,
    carrotSeedTracking.currentCount,
    carrotSeedTracking.currentCount - carrotSeedTracking.initialCount,
    carrotSeedTracking.buyAttempts,
    carrotSeedTracking.successfulBuys,
    carrotSeedTracking.buttonClicks,
    fps,
    os.date("%H:%M:%S"),
    isMonitoring and "ACTIVE" or "PAUSED",
    data or "No additional data")
    
    scrollLabel.Text = debugText
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLabel.TextBounds.Y + 20)
    
    -- Print ke console juga
    print("=== CARROT SEED DEBUG ===")
    print("Type: " .. debugType)
    print("Details: " .. details)
    print("Carrot Seeds: " .. carrotSeedTracking.currentCount)
    print("Status: " .. (isMonitoring and "ACTIVE" or "PAUSED"))
    print("=========================")
end

-- Fungsi untuk memulai/menghentikan monitoring (sama seperti sebelumnya)
local function startMonitoring()
    if isMonitoring then return end
    isMonitoring = true
    startStopButton.Text = "STOP"
    startStopButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    statusLabel.Text = "ON"
    updateDebugInfo("SYSTEM", "Monitoring Started", "All monitoring functions are now ACTIVE")
end

local function stopMonitoring()
    if not isMonitoring then return end
    isMonitoring = false
    startStopButton.Text = "START"
    startStopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    statusLabel.Text = "OFF"
    updateDebugInfo("SYSTEM", "Monitoring Stopped", "All monitoring functions are now PAUSED")
end

-- Handler untuk tombol carrot seed
checkCarrotBtn.MouseButton1Click:Connect(function()
    local seedData = getCarrotSeedCount()
    
    local dataText = string.format([[
🥕 CARROT SEED COUNT RESULTS:

Initial Count: %d
Current Count: %d
Difference: %d

Items Found: %d
Item Names: %s

%s
    ]],
    carrotSeedTracking.initialCount,
    seedData.count,
    seedData.count - carrotSeedTracking.initialCount,
    #seedData.items,
    table.concat(seedData.items, ", "),
    seedData.error and "ERROR: " .. seedData.error or "Scan completed successfully")
    
    updateDebugInfo("CARROT SEED CHECK", "Backpack Scan Complete", dataText)
end)

autoBuyCarrotBtn.MouseButton1Click:Connect(function()
    updateDebugInfo("CARROT SEED BUY", "Starting auto buy process", "Scanning for carrot seed buttons...")
    
    local result = tryAllCarrotSeedButtons()
    
    local resultText = string.format([[
🔄 AUTO BUY CARROT SEEDS RESULTS:

Total Carrot Buttons Found: %d
Buttons Attempted: %d
Successful Clicks: %d

Seed Count Before: %d
Seed Count After: %d
Difference: %d
Purchase Successful: %s

%s
    ]],
    result.totalCarrotButtons or 0,
    result.attemptedButtons or 0,
    result.successfulClicks or 0,
    result.beforeCount or 0,
    result.afterCount or 0,
    result.difference or 0,
    result.seedIncreased and "YES 🎉" or "NO ❌",
    result.message or "Auto buy process completed")
    
    updateDebugInfo("CARROT SEED BUY", "Auto Buy Complete", resultText)
end)

trackCarrotBtn.MouseButton1Click:Connect(function()
    local buttonsInfo = findCarrotSeedButtons()
    local seedData = getCarrotSeedCount()
    
    local trackingText = string.format([[
📊 COMPREHENSIVE CARROT SEED TRACKING:

SEED INFORMATION:
- Initial Count: %d
- Current Count: %d
- Difference: %d
- Items in Backpack: %s

BUTTON INFORMATION:
- Total Buttons in GUI: %d
- Carrot Seed Buttons Found: %d

BUY ATTEMPTS:
- Total Buy Attempts: %d
- Successful Purchases: %d
- Total Button Clicks: %d

CARROT BUTTONS DETAILS:
    ]],
    carrotSeedTracking.initialCount,
    carrotSeedTracking.currentCount,
    carrotSeedTracking.currentCount - carrotSeedTracking.initialCount,
    table.concat(seedData.items, ", "),
    buttonsInfo.totalButtons,
    buttonsInfo.totalCarrotButtons,
    carrotSeedTracking.buyAttempts,
    carrotSeedTracking.successfulBuys,
    carrotSeedTracking.buttonClicks)
    
    -- Tambahkan info detail setiap carrot button
    for i, button in ipairs(buttonsInfo.carrotButtons) do
        trackingText = trackingText .. string.format("\n%d. %s", i, button.name)
        trackingText = trackingText .. string.format("\n   Text: %s", button.text)
        trackingText = trackingText .. string.format("\n   Path: %s", button.path)
        trackingText = trackingText .. string.format("\n   Match: %s", button.matchType)
        trackingText = trackingText .. string.format("\n   Visible: %s, Enabled: %s", 
            tostring(button.visible), tostring(button.enabled))
    end
    
    updateDebugInfo("CARROT SEED TRACKING", "Comprehensive Data Report", trackingText)
end)

-- Fungsi-fungsi lainnya (scanRemoteEvents, scanButtons, dll) tetap sama seperti sebelumnya
-- [Kode untuk scanRemoteEvents, scanButtons, clearLogs, dll...]

-- Initialize system dengan focus pada carrot seed
local function initializeSystem()
    startMonitoring()
    
    -- Initial carrot seed count
    local initialSeedData = getCarrotSeedCount()
    
    updateDebugInfo("SYSTEM", "Carrot Seed Debugger Ready", 
        string.format("Initial carrot seed count: %d\nUse the carrot seed buttons to track and test purchases!", 
        initialSeedData.count))
    
    print("=== CARROT SEED DEBUG SYSTEM READY ===")
    print("F1 - Show RemoteEvent Logs")
    print("F5 - Toggle Monitoring")
    print("Click carrot seed buttons to track and test!")
    print("======================================")
end

-- Tunggu sebentar sebelum initialize
wait(2)
initializeSystem()
