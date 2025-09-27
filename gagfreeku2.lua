-- LocalScript di StarterPlayerScripts1
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
    buttonClicks = 0,
    remoteEventsAttempted = 0,
    lastBuyMethod = "None"
}

-- Buat UI debug
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CarrotSeedDebugger"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 550, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- [Kode UI sebelumnya tetap sama...]
-- Header dengan kontrol
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.12, 0)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6, 0, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 0)
title.Text = "🥕 ADVANCED CARROT BUY DEBUGGER 🥕"
title.Font = Enum.Font.Code
title.TextSize = 16
title.Parent = header

-- Tombol Start/Stop
local startStopButton = Instance.new("TextButton")
startStopButton.Size = UDim2.new(0.3, 0, 0.6, 0)
startStopButton.Position = UDim2.new(0.65, 0, 0.2, 0)
startStopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
startStopButton.Text = "STOP"
startStopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startStopButton.Font = Enum.Font.Code
startStopButton.TextSize = 14
startStopButton.Parent = header

-- Panel kontrol carrot seed yang diperluas
local carrotControlFrame = Instance.new("Frame")
carrotControlFrame.Size = UDim2.new(1, 0, 0.25, 0)
carrotControlFrame.Position = UDim2.new(0, 0, 0.12, 0)
carrotControlFrame.BackgroundColor3 = Color3.fromRGB(40, 20, 0)
carrotControlFrame.BackgroundTransparency = 0.2
carrotControlFrame.Parent = mainFrame

local carrotTitle = Instance.new("TextLabel")
carrotTitle.Size = UDim2.new(1, 0, 0.3, 0)
carrotTitle.BackgroundTransparency = 1
carrotTitle.TextColor3 = Color3.fromRGB(255, 165, 0)
carrotTitle.Text = "🛒 AUTO BUY CARROT SEEDS SYSTEM"
carrotTitle.Font = Enum.Font.Code
carrotTitle.TextSize = 14
carrotTitle.Parent = carrotControlFrame

-- Tombol-tombol kontrol carrot seed
local checkCarrotBtn = Instance.new("TextButton")
checkCarrotBtn.Size = UDim2.new(0.23, 0, 0.6, 0)
checkCarrotBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
checkCarrotBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
checkCarrotBtn.Text = "🔍 Check Seeds"
checkCarrotBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
checkCarrotBtn.Font = Enum.Font.Code
checkCarrotBtn.TextSize = 11
checkCarrotBtn.Parent = carrotControlFrame

local autoBuyBasicBtn = Instance.new("TextButton")
autoBuyBasicBtn.Size = UDim2.new(0.23, 0, 0.6, 0)
autoBuyBasicBtn.Position = UDim2.new(0.27, 0, 0.4, 0)
autoBuyBasicBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
autoBuyBasicBtn.Text = "🔄 Basic Auto Buy"
autoBuyBasicBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBuyBasicBtn.Font = Enum.Font.Code
autoBuyBasicBtn.TextSize = 11
autoBuyBasicBtn.Parent = carrotControlFrame

local autoBuyAdvancedBtn = Instance.new("TextButton")
autoBuyAdvancedBtn.Size = UDim2.new(0.23, 0, 0.6, 0)
autoBuyAdvancedBtn.Position = UDim2.new(0.52, 0, 0.4, 0)
autoBuyAdvancedBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
autoBuyAdvancedBtn.Text = "⚡ Advanced Buy"
autoBuyAdvancedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBuyAdvancedBtn.Font = Enum.Font.Code
autoBuyAdvancedBtn.TextSize = 11
autoBuyAdvancedBtn.Parent = carrotControlFrame

local trackCarrotBtn = Instance.new("TextButton")
trackCarrotBtn.Size = UDim2.new(0.23, 0, 0.6, 0)
trackCarrotBtn.Position = UDim2.new(0.77, 0, 0.4, 0)
trackCarrotBtn.BackgroundColor3 = Color3.fromRGB(150, 75, 0)
trackCarrotBtn.Text = "📊 Tracking Data"
trackCarrotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
trackCarrotBtn.Font = Enum.Font.Code
trackCarrotBtn.TextSize = 11
trackCarrotBtn.Parent = carrotControlFrame

-- Area display
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.96, 0, 0.6, 0)
scrollFrame.Position = UDim2.new(0.02, 0, 0.38, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = mainFrame

local scrollLabel = Instance.new("TextLabel")
scrollLabel.Size = UDim2.new(1, 0, 2, 0)
scrollLabel.BackgroundTransparency = 1
scrollLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scrollLabel.Text = "Carrot Seed Debugger Ready..."
scrollLabel.TextWrapped = true
scrollLabel.Font = Enum.Font.Code
scrollLabel.TextSize = 12
scrollLabel.TextXAlignment = Enum.TextXAlignment.Left
scrollLabel.TextYAlignment = Enum.TextYAlignment.Top
scrollLabel.Parent = scrollFrame

print("Advanced Carrot Seed Auto Buy Debugger Loaded!")

-- Fungsi untuk mendapatkan full path dari instance
local function getFullPath(instance)
    local path = instance.Name
    local current = instance.Parent
    local depth = 0
    
    while current and current ~= game and depth < 10 do
        path = current.Name .. " > " .. path
        current = current.Parent
        depth = depth + 1
    end
    
    return path
end

-- Fungsi untuk mencari backpack player dan menghitung seed carrot
local function getCarrotSeedCount()
    local success, result = pcall(function()
        -- Cari backpack player
        local backpack = player:FindFirstChild("Backpack")
        if not backpack then
            return {count = 0, items = {}, error = "Backpack not found"}
        end
        
        local carrotSeeds = 0
        local seedItems = {}
        
        -- Cari tools/items di backpack dengan berbagai pattern
        for _, item in ipairs(backpack:GetChildren()) do
            local itemName = string.lower(item.Name)
            
            -- Pattern matching untuk carrot seed
            local patterns = {
                "carrot.seed", "seed.carrot", "carrotseed", "seedcarrot",
                "carrot", "seed"
            }
            
            for _, pattern in ipairs(patterns) do
                if string.find(itemName, pattern) then
                    carrotSeeds = carrotSeeds + 1
                    table.insert(seedItems, {
                        name = item.Name,
                        className = item.ClassName,
                        fullPath = getFullPath(item)
                    })
                    break
                end
            end
        end
        
        -- Update tracking data
        local oldCount = carrotSeedTracking.currentCount
        carrotSeedTracking.currentCount = carrotSeeds
        
        if carrotSeedTracking.initialCount == 0 then
            carrotSeedTracking.initialCount = carrotSeeds
        end
        
        return {
            count = carrotSeeds,
            items = seedItems,
            initialCount = carrotSeedTracking.initialCount,
            difference = carrotSeeds - carrotSeedTracking.initialCount,
            oldCount = oldCount,
            newCount = carrotSeeds
        }
    end)
    
    if not success then
        return {count = 0, items = {}, error = result}
    end
    
    return result
end

-- Fungsi untuk mencari RemoteEvents yang terkait dengan pembelian
local function findBuyRemoteEvents()
    local buyEvents = {}
    local allEvents = {}
    
    -- Scan ReplicatedStorage untuk RemoteEvents
    for _, event in ipairs(ReplicatedStorage:GetDescendants()) do
        if event:IsA("RemoteEvent") then
            local eventName = string.lower(event.Name)
            
            -- Pattern matching untuk event pembelian
            local buyPatterns = {
                "buy", "purchase", "shop", "store", "seed", "carrot",
                "sheckles", "currency", "item", "add", "get"
            }
            
            local score = 0
            for _, pattern in ipairs(buyPatterns) do
                if string.find(eventName, pattern) then
                    score = score + 1
                end
            end
            
            if score > 0 then
                table.insert(buyEvents, {
                    event = event,
                    name = event.Name,
                    path = getFullPath(event),
                    score = score,
                    type = "RemoteEvent"
                })
            end
            
            table.insert(allEvents, {
                event = event,
                name = event.Name,
                path = getFullPath(event),
                type = "RemoteEvent"
            })
        end
    end
    
    -- Scan RemoteFunctions juga
    for _, func in ipairs(ReplicatedStorage:GetDescendants()) do
        if func:IsA("RemoteFunction") then
            local funcName = string.lower(func.Name)
            
            local buyPatterns = {
                "buy", "purchase", "shop", "store", "seed", "carrot"
            }
            
            local score = 0
            for _, pattern in ipairs(buyPatterns) do
                if string.find(funcName, pattern) then
                    score = score + 1
                end
            end
            
            if score > 0 then
                table.insert(buyEvents, {
                    event = func,
                    name = func.Name,
                    path = getFullPath(func),
                    score = score,
                    type = "RemoteFunction"
                })
            end
        end
    end
    
    -- Urutkan berdasarkan score (kecocokan tertinggi)
    table.sort(buyEvents, function(a, b)
        return a.score > b.score
    end)
    
    return {
        buyEvents = buyEvents,
        allEvents = allEvents,
        totalBuyEvents = #buyEvents,
        totalEvents = #allEvents
    }
end

-- Fungsi untuk mencari button pembelian di GUI
local function findBuyButtons()
    local buyButtons = {}
    local carrotButtons = {}
    local shecklesButtons = {}
    local allButtons = {}
    
    local guis = player.PlayerGui:GetDescendants()
    
    for _, guiElement in ipairs(guis) do
        if guiElement:IsA("TextButton") or guiElement:IsA("ImageButton") then
            local buttonName = string.lower(guiElement.Name)
            local buttonText = guiElement:IsA("TextButton") and string.lower(guiElement.Text or "") or ""
            
            -- Kategorikan button berdasarkan pattern
            local patterns = {
                {pattern = "sheckles", category = "sheckles"},
                {pattern = "carrot", category = "carrot"},
                {pattern = "seed", category = "carrot"},
                {pattern = "buy", category = "buy"},
                {pattern = "purchase", category = "buy"}
            }
            
            local categories = {}
            for _, patternData in ipairs(patterns) do
                if string.find(buttonName, patternData.pattern) or string.find(buttonText, patternData.pattern) then
                    table.insert(categories, patternData.category)
                end
            end
            
            local buttonInfo = {
                button = guiElement,
                name = guiElement.Name,
                text = guiElement:IsA("TextButton") and guiElement.Text or "N/A",
                path = getFullPath(guiElement),
                categories = categories,
                visible = guiElement.Visible,
                enabled = guiElement.Enabled
            }
            
            table.insert(allButtons, buttonInfo)
            
            -- Kategorikan button
            if #categories > 0 then
                table.insert(buyButtons, buttonInfo)
                
                if table.find(categories, "carrot") then
                    table.insert(carrotButtons, buttonInfo)
                end
                
                if table.find(categories, "sheckles") then
                    table.insert(shecklesButtons, buttonInfo)
                end
            end
        end
    end
    
    return {
        allButtons = allButtons,
        buyButtons = buyButtons,
        carrotButtons = carrotButtons,
        shecklesButtons = shecklesButtons,
        totalAllButtons = #allButtons,
        totalBuyButtons = #buyButtons,
        totalCarrotButtons = #carrotButtons,
        totalShecklesButtons = #shecklesButtons
    }
end

-- Fungsi untuk mencoba FireServer pada RemoteEvents
local function tryRemoteEventBuy()
    local eventsInfo = findBuyRemoteEvents()
    local buyEvents = eventsInfo.buyEvents
    
    if #buyEvents == 0 then
        return {
            success = false,
            message = "No buy-related RemoteEvents found",
            attempted = 0,
            successful = 0
        }
    end
    
    local attempted = 0
    local successful = 0
    local results = {}
    
    -- Ambil seed count sebelum mencoba
    local beforeSeedData = getCarrotSeedCount()
    local initialCount = beforeSeedData.count
    
    for i, eventInfo in ipairs(buyEvents) do
        if attempted >= 5 then break end -- Batasi attempt
        
        local event = eventInfo.event
        attempted = attempted + 1
        
        local result = {
            eventName = eventInfo.name,
            eventType = eventInfo.type,
            path = eventInfo.path,
            success = false,
            error = nil
        }
        
        -- Coba FireServer dengan berbagai parameter
        local parametersList = {
            {"carrot", "seed"},
            {"CarrotSeed", 1},
            {"carrot_seed", 1},
            {1, "carrot"},
            {"seed", "carrot"},
            {"buy", "carrot", "seed"},
            {player, "carrot", "seed"}
        }
        
        for _, params in ipairs(parametersList) do
            local success, errorMsg = pcall(function()
                if eventInfo.type == "RemoteEvent" then
                    event:FireServer(unpack(params))
                else
                    event:InvokeServer(unpack(params))
                end
            end)
            
            if success then
                result.success = true
                successful = successful + 1
                carrotSeedTracking.remoteEventsAttempted = carrotSeedTracking.remoteEventsAttempted + 1
                break
            else
                result.error = errorMsg
            end
            
            wait(0.1) -- Delay antara attempts
        end
        
        table.insert(results, result)
        wait(0.2) -- Delay antara events
    end
    
    -- Tunggu dan cek hasil
    wait(1)
    local afterSeedData = getCarrotSeedCount()
    local finalCount = afterSeedData.count
    
    local seedIncreased = finalCount > initialCount
    if seedIncreased then
        carrotSeedTracking.successfulBuys = carrotSeedTracking.successfulBuys + 1
        carrotSeedTracking.lastBuyMethod = "RemoteEvent"
    end
    
    return {
        success = seedIncreased,
        attemptedEvents = attempted,
        successfulEvents = successful,
        seedIncreased = seedIncreased,
        beforeCount = initialCount,
        afterCount = finalCount,
        difference = finalCount - initialCount,
        results = results,
        totalBuyEvents = #buyEvents
    }
end

-- Fungsi untuk mencoba click button pembelian
local function tryButtonBuy()
    local buttonsInfo = findBuyButtons()
    local relevantButtons = {}
    
    -- Prioritaskan button yang mengandung "sheckles" dan "buy"
    for _, button in ipairs(buttonsInfo.buyButtons) do
        if table.find(button.categories, "sheckles") or table.find(button.categories, "carrot") then
            table.insert(relevantButtons, button)
        end
    end
    
    if #relevantButtons == 0 then
        relevantButtons = buttonsInfo.buyButtons
    end
    
    if #relevantButtons == 0 then
        return {
            success = false,
            message = "No buy buttons found",
            attempted = 0,
            successful = 0
        }
    end
    
    local attempted = 0
    local successfulClicks = 0
    local results = {}
    
    local beforeSeedData = getCarrotSeedCount()
    local initialCount = beforeSeedData.count
    
    for i, buttonInfo in ipairs(relevantButtons) do
        if attempted >= 8 then break end -- Batasi attempt
        
        if buttonInfo.visible and buttonInfo.enabled then
            attempted = attempted + 1
            
            local result = {
                buttonName = buttonInfo.name,
                buttonText = buttonInfo.text,
                path = buttonInfo.path,
                categories = table.concat(buttonInfo.categories, ", "),
                success = false,
                error = nil
            }
            
            -- Coba berbagai metode click
            local clickMethods = {
                {"MouseButton1Click", "Standard Click"},
                {"Activate", "Activate Method"},
                {"MouseButton1Down", "Mouse Down"}
            }
            
            for _, method in ipairs(clickMethods) do
                local success, errorMsg = pcall(function()
                    -- Simpan original color
                    local originalColor = buttonInfo.button.BackgroundColor3
                    
                    -- Visual feedback
                    buttonInfo.button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    
                    -- Coba trigger event
                    if buttonInfo.button:FindFirstChild(method[1]) then
                        buttonInfo.button[method[1]]:Fire()
                    else
                        -- Fallback: gunakan MouseButton1Click
                        buttonInfo.button:FireEvent("MouseButton1Click")
                    end
                    
                    wait(0.1)
                    buttonInfo.button.BackgroundColor3 = originalColor
                end)
                
                if success then
                    result.success = true
                    successfulClicks = successfulClicks + 1
                    carrotSeedTracking.buttonClicks = carrotSeedTracking.buttonClicks + 1
                    break
                else
                    result.error = errorMsg
                end
            end
            
            table.insert(results, result)
            wait(0.3) -- Delay antara button attempts
        end
    end
    
    -- Tunggu dan cek hasil
    wait(1.5)
    local afterSeedData = getCarrotSeedCount()
    local finalCount = afterSeedData.count
    
    local seedIncreased = finalCount > initialCount
    if seedIncreased then
        carrotSeedTracking.successfulBuys = carrotSeedTracking.successfulBuys + 1
        carrotSeedTracking.lastBuyMethod = "Button Click"
    end
    
    return {
        success = seedIncreased,
        attemptedButtons = attempted,
        successfulClicks = successfulClicks,
        seedIncreased = seedIncreased,
        beforeCount = initialCount,
        afterCount = finalCount,
        difference = finalCount - initialCount,
        results = results,
        totalRelevantButtons = #relevantButtons
    }
end

-- Fungsi auto buy advanced (mencoba semua metode)
local function advancedAutoBuy()
    updateDebugInfo("ADVANCED AUTO BUY", "Starting comprehensive buy attempt", "Trying all available methods...")
    
    local results = {}
    local totalAttempted = 0
    local totalSuccessful = 0
    
    -- Method 1: Coba RemoteEvents pertama
    updateDebugInfo("REMOTE EVENT BUY", "Attempting RemoteEvent purchase", "Scanning for buy events...")
    local eventResult = tryRemoteEventBuy()
    table.insert(results, {method = "RemoteEvent", result = eventResult})
    totalAttempted = totalAttempted + eventResult.attemptedEvents
    totalSuccessful = totalSuccessful + (eventResult.success and 1 or 0)
    
    wait(1)
    
    -- Method 2: Coba Button clicks
    updateDebugInfo("BUTTON BUY", "Attempting Button purchase", "Scanning for buy buttons...")
    local buttonResult = tryButtonBuy()
    table.insert(results, {method = "Button", result = buttonResult})
    totalAttempted = totalAttempted + buttonResult.attemptedButtons
    totalSuccessful = totalSuccessful + (buttonResult.success and 1 or 0)
    
    -- Method 3: Coba kombinasi
    if not eventResult.success and not buttonResult.success then
        updateDebugInfo("COMBINATION BUY", "Attempting combination approach", "Trying sequential methods...")
        wait(0.5)
        
        -- Coba event lalu button secara berurutan
        local comboResults = {}
        
        for i = 1, 2 do
            local tempEventResult = tryRemoteEventBuy()
            wait(0.5)
            local tempButtonResult = tryButtonBuy()
            
            table.insert(comboResults, {
                attempt = i,
                eventSuccess = tempEventResult.success,
                buttonSuccess = tempButtonResult.success
            })
            
            if tempEventResult.success or tempButtonResult.success then
                break
            end
        end
        
        table.insert(results, {method = "Combination", result = comboResults})
    end
    
    -- Final evaluation
    local finalSeedData = getCarrotSeedCount()
    local overallSuccess = eventResult.success or buttonResult.success
    
    if overallSuccess then
        carrotSeedTracking.successfulBuys = carrotSeedTracking.successfulBuys + 1
    end
    
    -- Generate comprehensive report
    local report = "🎯 ADVANCED AUTO BUY COMPLETE REPORT:\n\n"
    report = report .. string.format("OVERALL RESULT: %s\n", overallSuccess and "SUCCESS 🎉" or "FAILED ❌")
    report = report .. string.format("Final Seed Count: %d (Started: %d)\n", finalSeedData.count, finalSeedData.oldCount)
    report = report .. string.format("Total Methods Attempted: %d\n", #results)
    report = report .. string.format("Total Operations: %d\n\n", totalAttempted)
    
    for i, methodResult in ipairs(results) do
        report = report .. string.format("METHOD %d: %s\n", i, methodResult.method)
        report = report .. string.format("  Success: %s\n", methodResult.result.success and "YES" or "NO")
        
        if methodResult.method == "RemoteEvent" then
            report = report .. string.format("  Events Attempted: %d/%d\n", 
                methodResult.result.attemptedEvents, methodResult.result.totalBuyEvents)
            report = report .. string.format("  Seed Change: %d → %d (%+d)\n\n",
                methodResult.result.beforeCount, methodResult.result.afterCount, methodResult.result.difference)
        elseif methodResult.method == "Button" then
            report = report .. string.format("  Buttons Attempted: %d/%d\n", 
                methodResult.result.attemptedButtons, methodResult.result.totalRelevantButtons)
            report = report .. string.format("  Successful Clicks: %d\n", methodResult.result.successfulClicks)
            report = report .. string.format("  Seed Change: %d → %d (%+d)\n\n",
                methodResult.result.beforeCount, methodResult.result.afterCount, methodResult.result.difference)
        end
    end
    
    report = report .. "📊 TRACKING SUMMARY:\n"
    report = report .. string.format("Total Buy Attempts: %d\n", carrotSeedTracking.buyAttempts)
    report = report .. string.format("Successful Buys: %d\n", carrotSeedTracking.successfulBuys)
    report = report .. string.format("Button Clicks: %d\n", carrotSeedTracking.buttonClicks)
    report = report .. string.format("Remote Events: %d\n", carrotSeedTracking.remoteEventsAttempted)
    report = report .. string.format("Last Method: %s\n", carrotSeedTracking.lastBuyMethod)
    
    updateDebugInfo("ADVANCED AUTO BUY", "Comprehensive buy attempt completed", report)
    
    return {
        success = overallSuccess,
        results = results,
        finalCount = finalSeedData.count,
        totalAttempted = totalAttempted
    }
end

-- Fungsi update debug info
local function updateDebugInfo(debugType, details, data)
    if not isMonitoring then return end
    
    local debugText = string.format([[
🔍 DEBUG TYPE: %s
📋 DETAILS: %s

🥕 CARROT SEED STATUS:
- Initial: %d | Current: %d | Difference: %+d
- Buy Attempts: %d | Successful: %d
- Last Method: %s

📊 DATA:
%s
    ]], 
    debugType, 
    details,
    carrotSeedTracking.initialCount,
    carrotSeedTracking.currentCount,
    carrotSeedTracking.currentCount - carrotSeedTracking.initialCount,
    carrotSeedTracking.buyAttempts,
    carrotSeedTracking.successfulBuys,
    carrotSeedTracking.lastBuyMethod,
    data or "No additional data")
    
    scrollLabel.Text = debugText
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLabel.TextBounds.Y + 20)
    
    print("=== CARROT DEBUG: " .. debugType .. " ===")
    print(details)
end

-- Handler untuk tombol-tombol
checkCarrotBtn.MouseButton1Click:Connect(function()
    local seedData = getCarrotSeedCount()
    
    local dataText = string.format([[
SEED COUNT RESULTS:
- Current Count: %d
- Items Found: %d
- Initial Count: %d
- Difference: %+d

ITEMS IN BACKPACK:
%s

%s
    ]],
    seedData.count,
    #seedData.items,
    seedData.initialCount,
    seedData.difference,
    #seedData.items > 0 and table.concat(seedData.items, "\n") or "No carrot seed items found",
    seedData.error and "ERROR: " .. seedData.error or "Scan successful")
    
    updateDebugInfo("SEED CHECK", "Backpack scan completed", dataText)
end)

autoBuyBasicBtn.MouseButton1Click:Connect(function()
    updateDebugInfo("BASIC AUTO BUY", "Starting basic buy attempt", "Trying button clicks only...")
    
    local result = tryButtonBuy()
    
    local resultText = string.format([[
BASIC AUTO BUY RESULTS:
- Success: %s
- Buttons Attempted: %d/%d
- Successful Clicks: %d
- Seed Change: %d → %d (%+d)

%s
    ]],
    result.success and "YES 🎉" or "NO ❌",
    result.attemptedButtons,
    result.totalRelevantButtons,
    result.successfulClicks,
    result.beforeCount,
    result.afterCount,
    result.difference,
    result.message or "Basic buy attempt completed")
    
    updateDebugInfo("BASIC AUTO BUY", "Basic buy attempt completed", resultText)
end)

autoBuyAdvancedBtn.MouseButton1Click:Connect(function()
    carrotSeedTracking.buyAttempts = carrotSeedTracking.buyAttempts + 1
    advancedAutoBuy()
end)

trackCarrotBtn.MouseButton1Click:Connect(function()
    local eventsInfo = findBuyRemoteEvents()
    local buttonsInfo = findBuyButtons()
    local seedData = getCarrotSeedCount()
    
    local trackingText = string.format([[
COMPREHENSIVE TRACKING DATA:

REMOTE EVENTS:
- Total Events: %d
- Buy-Related Events: %d

BUTTONS:
- Total Buttons: %d
- Buy Buttons: %d
- Carrot Buttons: %d
- Sheckles Buttons: %d

TOP BUY EVENTS:
    ]],
    eventsInfo.totalEvents,
    eventsInfo.totalBuyEvents,
    buttonsInfo.totalAllButtons,
    buttonsInfo.totalBuyButtons,
    buttonsInfo.totalCarrotButtons,
    buttonsInfo.totalShecklesButtons)
    
    for i = 1, math.min(5, #eventsInfo.buyEvents) do
        trackingText = trackingText .. string.format("\n%d. %s (Score: %d)", i, 
            eventsInfo.buyEvents[i].name, eventsInfo.buyEvents[i].score)
    end
    
    trackingText = trackingText .. "\n\nTOP BUY BUTTONS:"
    for i = 1, math.min(5, #buttonsInfo.buyButtons) do
        trackingText = trackingText .. string.format("\n%d. %s (%s)", i, 
            buttonsInfo.buyButtons[i].name, table.concat(buttonsInfo.buyButtons[i].categories, ", "))
    end
    
    updateDebugInfo("TRACKING DATA", "Comprehensive system scan", trackingText)
end)

-- Initialize system
local function initializeSystem()
    isMonitoring = true
    startStopButton.Text = "STOP"
    startStopButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    
    -- Initial scan
    local seedData = getCarrotSeedCount()
    
    updateDebugInfo("SYSTEM READY", "Carrot Seed Auto Buy Debugger Initialized",
        string.format("Initial seed count: %d\nUse the buttons above to test buy methods!\n\nF1 - Quick Buy\nF2 - Advanced Buy\nF3 - Check Seeds", 
        seedData.count))
end

startStopButton.MouseButton1Click:Connect(function()
    isMonitoring = not isMonitoring
    if isMonitoring then
        startStopButton.Text = "STOP"
        startStopButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        updateDebugInfo("SYSTEM", "Monitoring RESUMED", "All systems active")
    else
        startStopButton.Text = "START"
        startStopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        updateDebugInfo("SYSTEM", "Monitoring PAUSED", "All systems paused")
    end
end)

-- Hotkey system
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        autoBuyBasicBtn:FireEvent("MouseButton1Click")
    elseif input.KeyCode == Enum.KeyCode.F2 then
        autoBuyAdvancedBtn:FireEvent("MouseButton1Click")
    elseif input.KeyCode == Enum.KeyCode.F3 then
        checkCarrotBtn:FireEvent("MouseButton1Click")
    elseif input.KeyCode == Enum.KeyCode.F5 then
        isMonitoring = not isMonitoring
    end
end)

-- Initialize
wait(2)
initializeSystem()
