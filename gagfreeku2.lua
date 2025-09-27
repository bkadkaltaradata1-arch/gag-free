-- LocalScript di StarterPlayerScripts - BUY SEED DEBUGGER
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Tunggu sampai player ready
player:WaitForChild("PlayerGui")

-- Variabel sistem khusus buy seed
local trackedRemoteEvents = {}
local remoteEventLogs = {}
local isMonitoring = true
local buttonConnections = {}
local remoteEventConnections = {}
local lastBuyAttempt = nil
local seedPurchaseHistory = {}

-- Buat UI debug yang lebih fokus pada buy seed
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BuySeedDebugger"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 350)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 20, 0)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Header khusus buy seed
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.15, 0)
header.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
header.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 0)
title.Text = "🌱 BUY SEED DEBUGGER 🌱"
title.Font = Enum.Font.Code
title.TextSize = 18
title.Parent = header

-- Status monitoring
local statusIndicator = Instance.new("Frame")
statusIndicator.Size = UDim2.new(0.02, 0, 0.4, 0)
statusIndicator.Position = UDim2.new(0.72, 0, 0.3, 0)
statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
statusIndicator.Parent = header

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.1, 0, 0.4, 0)
statusLabel.Position = UDim2.new(0.75, 0, 0.3, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "ACTIVE"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 12
statusLabel.Parent = header

-- Kontrol panel
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, 0, 0.12, 0)
controlFrame.Position = UDim2.new(0, 0, 0.15, 0)
controlFrame.BackgroundColor3 = Color3.fromRGB(0, 30, 0)
controlFrame.Parent = mainFrame

-- Tombol kontrol khusus buy seed
local buttons = {
    {name = "🔍 Scan Shop", pos = 0.02, color = Color3.fromRGB(0, 100, 200)},
    {name = "📡 Track Events", pos = 0.27, color = Color3.fromRGB(200, 100, 0)},
    {name = "💰 Test Buy", pos = 0.52, color = Color3.fromRGB(0, 200, 0)},
    {name = "📊 History", pos = 0.77, color = Color3.fromRGB(200, 200, 0)}
}

for _, btnInfo in ipairs(buttons) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.23, 0, 0.7, 0)
    button.Position = UDim2.new(btnInfo.pos, 0, 0.15, 0)
    button.BackgroundColor3 = btnInfo.color
    button.Text = btnInfo.name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Code
    button.TextSize = 11
    button.Parent = controlFrame
end

-- Area informasi buy seed
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, 0, 0.73, 0)
infoFrame.Position = UDim2.new(0, 0, 0.27, 0)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.96, 0, 0.95, 0)
scrollFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
scrollFrame.Parent = infoFrame

local debugLabel = Instance.new("TextLabel")
debugLabel.Size = UDim2.new(1, 0, 2, 0)
debugLabel.BackgroundTransparency = 1
debugLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
debugLabel.Text = "🌱 Buy Seed Debugger Ready...\nClick 'Scan Shop' to find seed buttons\n"
debugLabel.TextWrapped = true
debugLabel.Font = Enum.Font.Code
debugLabel.TextSize = 13
debugLabel.TextXAlignment = Enum.TextXAlignment.Left
debugLabel.TextYAlignment = Enum.TextYAlignment.Top
debugLabel.Parent = scrollFrame

-- Fungsi update debug info khusus buy seed
local function updateBuySeedDebugInfo(debugType, details, data)
    if not isMonitoring then return end
    
    local timestamp = os.date("%H:%M:%S")
    local debugText = string.format([[
🕒 [%s] %s: %s
📋 %s

%s
────────────────────────────
]], timestamp, debugType, details, data or "No additional data", debugLabel.Text)
    
    debugLabel.Text = debugText
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, debugLabel.TextBounds.Y + 20)
    
    -- Auto scroll ke atas
    wait(0.1)
    scrollFrame.CanvasPosition = Vector2.new(0, 0)
    
    print("🌱 BUY SEED DEBUG: " .. debugType .. " - " .. details)
end

-- Fungsi scan toko dan button seed
local function scanSeedShop()
    updateBuySeedDebugInfo("SCAN", "Memulai scan toko seed...")
    
    local seedButtonsFound = 0
    local shopFramesFound = 0
    
    -- Scan PlayerGui untuk elemen toko
    local guiElements = player.PlayerGui:GetDescendants()
    
    for _, element in ipairs(guiElements) do
        -- Cari frame yang berhubungan dengan shop/toko
        if element:IsA("Frame") then
            local frameName = string.lower(element.Name)
            if string.find(frameName, "shop") or string.find(frameName, "store") or 
               string.find(frameName, "seed") or string.find(frameName, "buy") then
                shopFramesFound += 1
                
                updateBuySeedDebugInfo("SHOP FRAME", "Found: " .. element.Name, 
                    "Parent: " .. (element.Parent and element.Parent.Name or "N/A"))
            end
        end
        
        -- Cari button yang berhubungan dengan seed
        if element:IsA("TextButton") or element:IsA("ImageButton") then
            local buttonName = string.lower(element.Name)
            local buttonText = element:IsA("TextButton") and string.lower(element.Text) or ""
            
            if string.find(buttonName, "seed") or string.find(buttonName, "buy") or 
               string.find(buttonName, "purchase") or string.find(buttonText, "seed") or
               string.find(buttonText, "buy") or string.find(buttonText, "purchase") then
                
                seedButtonsFound += 1
                
                -- Pasang event listener untuk button ini
                local connection = element.MouseButton1Click:Connect(function()
                    if not isMonitoring then return end
                    
                    -- Record buy attempt
                    lastBuyAttempt = {
                        timestamp = os.date("%H:%M:%S"),
                        buttonName = element.Name,
                        buttonText = element:IsA("TextButton") and element.Text or "N/A",
                        position = element.AbsolutePosition,
                        size = element.AbsoluteSize
                    }
                    
                    updateBuySeedDebugInfo("BUY ATTEMPT", "Button Clicked: " .. element.Name,
                        string.format([[
Button Details:
- Text: %s
- Position: %s
- Size: %s
- Visible: %s
- Parent: %s

💡 Mencoba membeli seed...
                        ]], 
                        element:IsA("TextButton") and element.Text or "N/A",
                        tostring(element.AbsolutePosition),
                        tostring(element.AbsoluteSize),
                        tostring(element.Visible),
                        element.Parent and element.Parent.Name or "N/A"))
                    
                    -- Highlight effect
                    local originalColor = element.BackgroundColor3
                    element.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    delay(0.2, function()
                        element.BackgroundColor3 = originalColor
                    end)
                end)
                
                buttonConnections[element] = connection
                
                updateBuySeedDebugInfo("SEED BUTTON", "Tracked: " .. element.Name,
                    "Parent: " .. (element.Parent and element.Parent.Name or "N/A"))
            end
        end
    end
    
    updateBuySeedDebugInfo("SCAN COMPLETE", "Scan selesai",
        string.format("Shop Frames: %d\nSeed Buttons: %d", shopFramesFound, seedButtonsFound))
end

-- Fungsi track remote events khusus buy seed
local function trackBuySeedEvents()
    updateBuySeedDebugInfo("EVENT TRACK", "Memulai pelacakan RemoteEvents...")
    
    local eventsTracked = 0
    
    -- Track events di ReplicatedStorage
    for _, event in ipairs(ReplicatedStorage:GetDescendants()) do
        if event:IsA("RemoteEvent") then
            local eventName = string.lower(event.Name)
            
            if string.find(eventName, "seed") or string.find(eventName, "buy") or 
               string.find(eventName, "purchase") or string.find(eventName, "shop") then
                
                eventsTracked += 1
                
                local connection = event.OnClientEvent:Connect(function(...)
                    if not isMonitoring then return end
                    
                    local args = {...}
                    local argsInfo = ""
                    
                    for i, arg in ipairs(args) do
                        argsInfo = argsInfo .. string.format("Arg[%d]: %s (%s)\n", i, tostring(arg), typeof(arg))
                    end
                    
                    -- Record ke history
                    table.insert(seedPurchaseHistory, {
                        event = event.Name,
                        timestamp = os.date("%H:%M:%S"),
                        args = args,
                        success = #args > 0 and tostring(args[1]):lower() == "success" or false
                    })
                    
                    updateBuySeedDebugInfo("REMOTEEVENT", "Received: " .. event.Name,
                        string.format([[
Arguments (%d):
%s
Last Buy Attempt: %s
                        ]], #args, argsInfo, 
                        lastBuyAttempt and lastBuyAttempt.timestamp or "None"))
                end)
                
                remoteEventConnections[event] = connection
                trackedRemoteEvents[event] = true
                
                updateBuySeedDebugInfo("EVENT TRACKED", "Now tracking: " .. event.Name)
            end
        end
    end
    
    -- Track juga RemoteFunctions untuk proses buy
    for _, func in ipairs(ReplicatedStorage:GetDescendants()) do
        if func:IsA("RemoteFunction") then
            local funcName = string.lower(func.Name)
            
            if string.find(funcName, "seed") or string.find(funcName, "buy") then
                eventsTracked += 1
                
                updateBuySeedDebugInfo("REMOTEFUNCTION", "Found: " .. func.Name,
                    "⚠️ RemoteFunction detected - mungkin digunakan untuk buy seed")
            end
        end
    end
    
    updateBuySeedDebugInfo("EVENT TRACK COMPLETE", "Pelacakan selesai",
        string.format("Events/Functions tracked: %d", eventsTracked))
end

-- Fungsi test buy seed
local function testBuySeed()
    updateBuySeedDebugInfo("TEST", "Memulai test buy seed...")
    
    -- Cari button seed untuk di-test
    local seedButtons = {}
    local guiElements = player.PlayerGui:GetDescendants()
    
    for _, element in ipairs(guiElements) do
        if (element:IsA("TextButton") or element:IsA("ImageButton")) then
            local buttonName = string.lower(element.Name)
            if string.find(buttonName, "seed") or string.find(buttonName, "buy") then
                table.insert(seedButtons, element)
            end
        end
    end
    
    if #seedButtons == 0 then
        updateBuySeedDebugInfo("TEST FAILED", "Tidak ada seed button ditemukan")
        return
    end
    
    updateBuySeedDebugInfo("TEST", "Found " .. #seedButtons .. " seed buttons",
        "Mencoba simulate click pada button pertama...")
    
    -- Simulate click pada button pertama
    local firstButton = seedButtons[1]
    if firstButton:IsA("TextButton") or firstButton:IsA("ImageButton") then
        -- Fire the click event
        firstButton:Fire("MouseButton1Click")
        
        updateBuySeedDebugInfo("TEST CLICK", "Simulated click on: " .. firstButton.Name)
    end
end

-- Fungsi show purchase history
local function showPurchaseHistory()
    if #seedPurchaseHistory == 0 then
        updateBuySeedDebugInfo("HISTORY", "No purchase history recorded")
        return
    end
    
    local historyText = "📊 SEED PURCHASE HISTORY:\n\n"
    
    for i, purchase in ipairs(seedPurchaseHistory) do
        historyText = historyText .. string.format("[%d] %s - %s\n", i, purchase.timestamp, purchase.event)
        historyText = historyText .. string.format("   Success: %s\n", tostring(purchase.success))
        if #purchase.args > 0 then
            historyText = historyText .. "   Args: " .. #purchase.args .. "\n"
        end
        historyText = historyText .. "\n"
    end
    
    updateBuySeedDebugInfo("HISTORY", "Purchase History", historyText)
end

-- Setup button handlers
local controlButtons = controlFrame:GetChildren()
for _, button in ipairs(controlButtons) do
    if button:IsA("TextButton") then
        if button.Text:find("Scan Shop") then
            button.MouseButton1Click:Connect(scanSeedShop)
        elseif button.Text:find("Track Events") then
            button.MouseButton1Click:Connect(trackBuySeedEvents)
        elseif button.Text:find("Test Buy") then
            button.MouseButton1Click:Connect(testBuySeed)
        elseif button.Text:find("History") then
            button.MouseButton1Click:Connect(showPurchaseHistory)
        end
    end
end

-- Hotkey system untuk buy seed debug
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F2 then
        scanSeedShop()
    elseif input.KeyCode == Enum.KeyCode.F3 then
        trackBuySeedEvents()
    elseif input.KeyCode == Enum.KeyCode.F4 then
        showPurchaseHistory()
    elseif input.KeyCode == Enum.KeyCode.F5 then
        isMonitoring = not isMonitoring
        statusIndicator.BackgroundColor3 = isMonitoring and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        statusLabel.Text = isMonitoring and "ACTIVE" or "PAUSED"
        statusLabel.TextColor3 = isMonitoring and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        
        updateBuySeedDebugInfo("SYSTEM", "Monitoring " .. (isMonitoring and "ACTIVATED" or "PAUSED"))
    end
end)

-- Monitor untuk events baru
ReplicatedStorage.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("RemoteEvent") then
        local eventName = string.lower(descendant.Name)
        if string.find(eventName, "seed") or string.find(eventName, "buy") then
            wait(1)
            trackBuySeedEvents()
        end
    end
end)

-- Player stats monitoring untuk currency
local function monitorPlayerStats()
    while true do
        wait(5)
        
        if not isMonitoring then continue end
        
        -- Coba dapatkan info currency player
        local success, stats = pcall(function()
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local money = leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("Coins")
                local gems = leaderstats:FindFirstChild("Gems") or leaderstats:FindFirstChild("Diamonds")
                
                local statsText = ""
                if money then statsText = statsText .. "💰 Money: " .. tostring(money.Value) .. "\n" end
                if gems then statsText = statsText .. "💎 Gems: " .. tostring(gems.Value) .. "\n" end
                
                if statsText ~= "" then
                    updateBuySeedDebugInfo("STATS", "Player Currency", statsText)
                end
            end
        end)
    end
end

-- Auto-initialize
delay(2, function()
    updateBuySeedDebugInfo("SYSTEM", "Buy Seed Debugger Ready!",
        [[
Hotkeys:
F2 - Scan Seed Shop
F3 - Track Buy Events  
F4 - Show Purchase History
F5 - Toggle Monitoring

Click buttons above to start debugging!
        ]])
    
    -- Mulai monitoring stats
    spawn(monitorPlayerStats)
end)

print("🌱 Buy Seed Debugger successfully loaded!")
