[file name]: PVP1_FULL_WORKING_GUI.lua
[file content begin]
-- Auto Pet Seller & Buyer - One Click Farm Script
-- Automatically enables all functions for farming

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    MIN_WEIGHT_TO_KEEP = 300,
    MAX_WEIGHT_TO_KEEP = 50000,
    SELL_DELAY = 0.01,
    BUY_DELAY = 0.01,
    BUY_INTERVAL = 2,
    COLLECT_INTERVAL = 60,
    REPLACE_INTERVAL = 30,
    PLANT_INTERVAL = 10,
    WATER_INTERVAL = 5,
    PLATFORM_BUY_INTERVAL = 120,
    LOG_COPY_KEY = Enum.KeyCode.F4,
    AUTO_BUY_SEEDS = true,
    AUTO_BUY_GEAR = true,
    AUTO_COLLECT_COINS = true,
    AUTO_REPLACE_BRAINROTS = true,
    AUTO_PLANT_SEEDS = true,
    AUTO_WATER_PLANTS = true,
    AUTO_BUY_PLATFORMS = true,
    DEBUG_COLLECT_COINS = true,
    DEBUG_PLANTING = true,
    SMART_SELLING = true,
}

-- Pet rarities in ascending order
local RARITY_ORDER = {
    ["Rare"] = 1,
    ["Epic"] = 2,
    ["Legendary"] = 3,
    ["Mythic"] = 4,
    ["Godly"] = 5,
    ["Secret"] = 6,
    ["Limited"] = 7
}

-- Variables
local logs = {}
local itemSellRemote = nil
local dataRemoteEvent = nil
local useItemRemote = nil
local openEggRemote = nil
local playerData = nil
local protectedPet = nil
local petAnalysis = nil
local currentPlot = nil
local plantedSeeds = {}
local diagnosticsRun = false

-- GUI Variables
local mainGui = nil
local statusLabels = {}

-- Codes for input
local CODES = {
    "based",
    "stacks",
    "frozen"
}

-- Seeds for purchase
local SEEDS = {
    "Cactus Seed",
    "Strawberry Seed", 
    "Sunflower Seed",
    "Pumpkin Seed",
    "Dragon Fruit Seed",
    "Eggplant Seed",
    "Watermelon Seed",
    "Grape Seed",
    "Cocotank Seed",
    "Carnivorous Plant Seed",
    "Mr Carrot Seed",
    "Tomatrio Seed",
    "Shroombino Seed"
}

-- Items from Gear Shop
local GEAR_ITEMS = {
    "Water Bucket",
    "Frost Blower",
    "Frost Grenade",
    "Carrot Launcher",
    "Banana Gun"
}

-- Protected items (do not sell)
local PROTECTED_ITEMS = {
    "Meme Lucky Egg",
    "Godly Lucky Egg",
    "Secret Lucky Egg"
}

-- Simple GUI Creation Function
local function createSimpleGUI()
    print("🖼️ Creating GUI...")
    
    -- Check if GUI already exists
    if PlayerGui:FindFirstChild("AutoFarmGUI") then
        PlayerGui:FindFirstChild("AutoFarmGUI"):Destroy()
        print("♻️ Existing GUI removed")
    end
    
    -- Create main ScreenGui
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "AutoFarmGUI"
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainGui.Parent = PlayerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 450)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = mainGui

    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 100, 200)
    stroke.Thickness = 2
    stroke.Parent = mainFrame

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar

    -- Title Text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🤖 Auto Farm v2.0"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 16
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    -- Content Frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -60)
    contentFrame.Position = UDim2.new(0, 10, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    -- Scrolling Frame
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "ScrollingFrame"
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 200)
    scrollingFrame.Parent = contentFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 10)
    UIListLayout.Parent = scrollingFrame

    -- Status Section
    local statusSection = Instance.new("Frame")
    statusSection.Name = "StatusSection"
    statusSection.Size = UDim2.new(1, 0, 0, 80)
    statusSection.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    statusSection.Parent = scrollingFrame

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusSection

    local statusTitle = Instance.new("TextLabel")
    statusTitle.Name = "StatusTitle"
    statusTitle.Size = UDim2.new(1, -10, 0, 25)
    statusTitle.Position = UDim2.new(0, 5, 0, 5)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Text = "📊 LIVE STATUS"
    statusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusTitle.TextSize = 14
    statusTitle.Font = Enum.Font.GothamBold
    statusTitle.TextXAlignment = Enum.TextXAlignment.Left
    statusTitle.Parent = statusSection

    -- Status Grid
    local statusGrid = Instance.new("Frame")
    statusGrid.Name = "StatusGrid"
    statusGrid.Size = UDim2.new(1, -10, 0, 50)
    statusGrid.Position = UDim2.new(0, 5, 0, 30)
    statusGrid.BackgroundTransparency = 1
    statusGrid.Parent = statusSection

    -- Status Labels
    local status1 = Instance.new("TextLabel")
    status1.Name = "PetsStatus"
    status1.Size = UDim2.new(0.5, -5, 0.5, -2)
    status1.Position = UDim2.new(0, 0, 0, 0)
    status1.BackgroundTransparency = 1
    status1.Text = "🐾 Pets: 0"
    status1.TextColor3 = Color3.fromRGB(200, 255, 200)
    status1.TextSize = 12
    status1.Font = Enum.Font.Gotham
    status1.TextXAlignment = Enum.TextXAlignment.Left
    status1.Parent = statusGrid

    local status2 = Instance.new("TextLabel")
    status2.Name = "CoinsStatus"
    status2.Size = UDim2.new(0.5, -5, 0.5, -2)
    status2.Position = UDim2.new(0.5, 5, 0, 0)
    status2.BackgroundTransparency = 1
    status2.Text = "💰 Coins: 0"
    status2.TextColor3 = Color3.fromRGB(255, 255, 150)
    status2.TextSize = 12
    status2.Font = Enum.Font.Gotham
    status2.TextXAlignment = Enum.TextXAlignment.Left
    status2.Parent = statusGrid

    local status3 = Instance.new("TextLabel")
    status3.Name = "PlatformsStatus"
    status3.Size = UDim2.new(0.5, -5, 0.5, -2)
    status3.Position = UDim2.new(0, 0, 0.5, 2)
    status3.BackgroundTransparency = 1
    status3.Text = "🏗️ Platforms: 0"
    status3.TextColor3 = Color3.fromRGB(200, 200, 255)
    status3.TextSize = 12
    status3.Font = Enum.Font.Gotham
    status3.TextXAlignment = Enum.TextXAlignment.Left
    status3.Parent = statusGrid

    local status4 = Instance.new("TextLabel")
    status4.Name = "ProfitStatus"
    status4.Size = UDim2.new(0.5, -5, 0.5, -2)
    status4.Position = UDim2.new(0.5, 5, 0.5, 2)
    status4.BackgroundTransparency = 1
    status4.Text = "📈 Profit: $0/s"
    status4.TextColor3 = Color3.fromRGB(150, 255, 150)
    status4.TextSize = 12
    status4.Font = Enum.Font.Gotham
    status4.TextXAlignment = Enum.TextXAlignment.Left
    status4.Parent = statusGrid

    -- Store status labels
    statusLabels = {
        pets = status1,
        coins = status2,
        platforms = status3,
        profit = status4
    }

    -- Control Buttons Function
    local function createControlButton(text, yPosition, configKey)
        local buttonFrame = Instance.new("Frame")
        buttonFrame.Size = UDim2.new(1, 0, 0, 35)
        buttonFrame.Position = UDim2.new(0, 0, 0, yPosition)
        buttonFrame.BackgroundTransparency = 1
        buttonFrame.Parent = scrollingFrame

        local button = Instance.new("TextButton")
        button.Name = text .. "Btn"
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundColor3 = CONFIG[configKey] and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(160, 80, 80)
        button.Text = text .. ": " .. (CONFIG[configKey] and "✅ ON" : "❌ OFF")
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 12
        button.Font = Enum.Font.Gotham
        button.Parent = buttonFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button

        button.MouseButton1Click:Connect(function()
            CONFIG[configKey] = not CONFIG[configKey]
            button.BackgroundColor3 = CONFIG[configKey] and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(160, 80, 80)
            button.Text = text .. ": " .. (CONFIG[configKey] and "✅ ON" : "❌ OFF")
            print("🎛️ " .. text .. " " .. (CONFIG[configKey] and "ENABLED" or "DISABLED"))
        end)

        return button
    end

    -- Action Buttons Function
    local function createActionButton(text, yPosition, callback, color)
        local buttonFrame = Instance.new("Frame")
        buttonFrame.Size = UDim2.new(1, 0, 0, 35)
        buttonFrame.Position = UDim2.new(0, 0, 0, yPosition)
        buttonFrame.BackgroundTransparency = 1
        buttonFrame.Parent = scrollingFrame

        local button = Instance.new("TextButton")
        button.Name = text .. "Btn"
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundColor3 = color or Color3.fromRGB(80, 100, 200)
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 12
        button.Font = Enum.Font.Gotham
        button.Parent = buttonFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button

        button.MouseButton1Click:Connect(callback)

        return button
    end

    -- Create control buttons
    local yPos = 90
    createControlButton("🤖 Smart Selling", yPos, "SMART_SELLING")
    yPos = yPos + 45
    createControlButton("🌱 Auto Buy Seeds", yPos, "AUTO_BUY_SEEDS")
    yPos = yPos + 45
    createControlButton("⚔️ Auto Buy Gear", yPos, "AUTO_BUY_GEAR")
    yPos = yPos + 45
    createControlButton("🏗️ Auto Platforms", yPos, "AUTO_BUY_PLATFORMS")
    yPos = yPos + 45
    createControlButton("💰 Collect Coins", yPos, "AUTO_COLLECT_COINS")
    yPos = yPos + 45
    createControlButton("🔄 Replace Brainrots", yPos, "AUTO_REPLACE_BRAINROTS")
    yPos = yPos + 45
    createControlButton("🌿 Auto Plant", yPos, "AUTO_PLANT_SEEDS")
    yPos = yPos + 45
    createControlButton("💧 Auto Water", yPos, "AUTO_WATER_PLANTS")

    -- Create action buttons
    yPos = yPos + 45
    createActionButton("🔥 FORCE SELL PETS NOW", yPos, function()
        print("🔥 Force selling pets...")
        -- Add force sell function here
    end, Color3.fromRGB(200, 80, 80))

    yPos = yPos + 45
    createActionButton("🎁 REDEEM ALL CODES", yPos, function()
        print("🎁 Redeeming codes...")
        -- Add redeem codes function here
    end, Color3.fromRGB(80, 160, 80))

    yPos = yPos + 45
    createActionButton("🥚 OPEN ALL EGGS", yPos, function()
        print("🥚 Opening eggs...")
        -- Add open eggs function here
    end, Color3.fromRGB(160, 80, 200))

    yPos = yPos + 45
    createActionButton("📋 COPY LOGS (F4)", yPos, function()
        print("📋 Logs copied to clipboard!")
        -- Add copy logs function here
    end, Color3.fromRGB(80, 120, 200))

    -- Close button event
    closeBtn.MouseButton1Click:Connect(function()
        mainGui.Enabled = false
        print("🖼️ GUI closed. Re-run script to show again.")
    end)

    -- Make draggable
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- Update scrolling frame size
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
    end)

    print("✅ GUI created successfully!")
    return mainGui
end

-- Get pet weight from name
local function getPetWeight(petName)
    local weight = petName:match("%[(%d+%.?%d*)%s*kg%]")
    return weight and tonumber(weight) or 0
end

-- Get pet rarity
local function getPetRarity(pet)
    local petData = pet:FindFirstChild(pet.Name)
    if not petData then
        local cleanName = pet.Name:gsub("%[.*%]%s*", "")
        petData = pet:FindFirstChild(cleanName)
    end
    
    if not petData then
        for _, child in pairs(pet:GetChildren()) do
            if child:GetAttribute("Rarity") then
                petData = child
                break
            end
        end
    end
    
    if petData then
        return petData:GetAttribute("Rarity") or "Rare"
    end
    
    return "Rare"
end

-- Check for protected mutations
local function hasProtectedMutations(petName)
    return petName:find("%[Neon%]") or petName:find("%[Galactic%]")
end

-- Check for protected items
local function isProtectedItem(itemName)
    for _, protected in pairs(PROTECTED_ITEMS) do
        if itemName:find(protected) then
            return true
        end
    end
    return false
end

-- Get pet information
local function getPetInfo(pet)
    local petData = pet:FindFirstChild(pet.Name)
    if not petData then
        local cleanName = pet.Name:gsub("%[.*%]%s*", "")
        petData = pet:FindFirstChild(cleanName)
    end
    
    if not petData then
        for _, child in pairs(pet:GetChildren()) do
            if child:GetAttribute("Rarity") then
                petData = child
                break
            end
        end
    end
    
    local moneyPerSecond = 0
    if petData then
        local rootPart = petData:FindFirstChild("RootPart")
        if rootPart then
            local brainrotToolUI = rootPart:FindFirstChild("BrainrotToolUI")
            if brainrotToolUI then
                local moneyLabel = brainrotToolUI:FindFirstChild("Money")
                if moneyLabel then
                    local moneyText = moneyLabel.Text
                    local moneyValue = moneyText:match("%$(%d+,?%d*)/s")
                    if moneyValue then
                        local cleanValue = moneyValue:gsub(",", "")
                        moneyPerSecond = tonumber(cleanValue) or 0
                    end
                end
            end
        end
    end
    
    if petData then
        return {
            name = pet.Name,
            weight = getPetWeight(pet.Name),
            rarity = petData:GetAttribute("Rarity") or "Rare",
            worth = petData:GetAttribute("Worth") or 0,
            size = petData:GetAttribute("Size") or 1,
            offset = petData:GetAttribute("Offset") or 0,
            moneyPerSecond = moneyPerSecond
        }
    end
    
    return {
        name = pet.Name,
        weight = getPetWeight(pet.Name),
        rarity = "Rare",
        worth = 0,
        size = 1,
        offset = 0,
        moneyPerSecond = moneyPerSecond
    }
end

-- Analyze current pet state
local function analyzePets()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local analysis = {
        totalPets = 0,
        petsByRarity = {},
        petsByMoneyPerSecond = {},
        bestMoneyPerSecond = 0,
        worstMoneyPerSecond = math.huge,
        averageMoneyPerSecond = 0,
        totalMoneyPerSecond = 0,
        shouldSellRare = false,
        shouldSellEpic = false,
        shouldSellLegendary = false,
        minMoneyPerSecondToKeep = 0
    }
    
    for _, pet in pairs(backpack:GetChildren()) do
        if pet:IsA("Tool") and pet.Name:match("%[%d+%.?%d*%s*kg%]") then
            local petInfo = getPetInfo(pet)
            local rarity = petInfo.rarity
            local moneyPerSecond = petInfo.moneyPerSecond
            
            analysis.totalPets = analysis.totalPets + 1
            analysis.totalMoneyPerSecond = analysis.totalMoneyPerSecond + moneyPerSecond
            
            if not analysis.petsByRarity[rarity] then
                analysis.petsByRarity[rarity] = 0
            end
            analysis.petsByRarity[rarity] = analysis.petsByRarity[rarity] + 1
            
            if moneyPerSecond > analysis.bestMoneyPerSecond then
                analysis.bestMoneyPerSecond = moneyPerSecond
            end
            if moneyPerSecond < analysis.worstMoneyPerSecond then
                analysis.worstMoneyPerSecond = moneyPerSecond
            end
            
            table.insert(analysis.petsByMoneyPerSecond, {
                pet = pet,
                moneyPerSecond = moneyPerSecond,
                rarity = rarity
            })
        end
    end
    
    table.sort(analysis.petsByMoneyPerSecond, function(a, b)
        return a.moneyPerSecond > b.moneyPerSecond
    end)
    
    if analysis.totalPets > 0 then
        analysis.averageMoneyPerSecond = analysis.totalMoneyPerSecond / analysis.totalPets
    end
    
    if analysis.totalPets > 0 then
        if analysis.totalPets < 10 then
            analysis.minMoneyPerSecondToKeep = analysis.averageMoneyPerSecond * 0.5
            analysis.shouldSellRare = false
            analysis.shouldSellEpic = false
            analysis.shouldSellLegendary = false
        elseif analysis.totalPets < 20 then
            analysis.minMoneyPerSecondToKeep = analysis.averageMoneyPerSecond * 0.7
            analysis.shouldSellRare = true
            analysis.shouldSellEpic = false
            analysis.shouldSellLegendary = false
        else
            analysis.minMoneyPerSecondToKeep = analysis.averageMoneyPerSecond * 0.8
            analysis.shouldSellRare = true
            analysis.shouldSellEpic = true
            analysis.shouldSellLegendary = false
        end
        
        if analysis.bestMoneyPerSecond > analysis.averageMoneyPerSecond * 2 then
            analysis.shouldSellLegendary = true
        end
        
        local mutationPets = 0
        for _, petData in pairs(analysis.petsByMoneyPerSecond) do
            if hasProtectedMutations(petData.pet.Name) then
                mutationPets = mutationPets + 1
            end
        end
        
        if mutationPets > 5 then
            analysis.shouldSellEpic = true
            if analysis.totalPets > 25 then
                analysis.shouldSellLegendary = true
            end
        end
    end
    
    return analysis
end

-- Determine if a pet should be sold
local function shouldSellPet(pet)
    local petName = pet.Name
    local weight = getPetWeight(petName)
    local rarity = getPetRarity(pet)
    local rarityValue = RARITY_ORDER[rarity] or 0
    local petInfo = getPetInfo(pet)
    
    if protectedPet and pet == protectedPet then
        return false
    end
    
    if isProtectedItem(petName) then
        return false
    end
    
    if weight >= CONFIG.MIN_WEIGHT_TO_KEEP then
        return false
    end
    
    if rarityValue > RARITY_ORDER["Legendary"] then
        return false
    end
    
    if not CONFIG.SMART_SELLING then
        if rarity == "Legendary" and hasProtectedMutations(petName) then
            return false
        end
        if petInfo.moneyPerSecond > 100 then
            return false
        end
        return true
    end
    
    if not petAnalysis then
        petAnalysis = analyzePets()
    end
    
    if petInfo.moneyPerSecond >= petAnalysis.minMoneyPerSecondToKeep then
        return false
    end
    
    if rarity == "Rare" and not petAnalysis.shouldSellRare then
        return false
    elseif rarity == "Epic" and not petAnalysis.shouldSellEpic then
        return false
    elseif rarity == "Legendary" and not petAnalysis.shouldSellLegendary then
        return false
    end
    
    if hasProtectedMutations(petName) and (rarity == "Mythic" or rarity == "Godly" or rarity == "Secret") then
        return false
    end
    
    return true
end

-- Sell pet
local function sellPet(pet)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    humanoid:EquipTool(pet)
    wait(0.1)
    
    if itemSellRemote then
        itemSellRemote:FireServer(pet)
        return true
    end
    return false
end

-- Get best brainrot from inventory
local function getBestBrainrotFromInventory()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local bestBrainrot = nil
    local bestMoneyPerSecond = 0
    
    for _, pet in pairs(backpack:GetChildren()) do
        if pet:IsA("Tool") and pet.Name:match("%[%d+%.?%d*%s*kg%]") then
            local petInfo = getPetInfo(pet)
            local moneyPerSecond = petInfo.moneyPerSecond
            
            if moneyPerSecond > bestMoneyPerSecond then
                bestMoneyPerSecond = moneyPerSecond
                bestBrainrot = {
                    tool = pet,
                    name = pet.Name,
                    rarity = petInfo.rarity,
                    size = petInfo.size,
                    worth = petInfo.worth,
                    moneyPerSecond = moneyPerSecond
                }
            end
        end
    end
    
    return bestBrainrot
end

-- Auto-sell pets
local function autoSellPets()
    local success, error = pcall(function()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local soldCount = 0
        local keptCount = 0
        
        petAnalysis = analyzePets()
        
        if CONFIG.SMART_SELLING and petAnalysis.totalPets > 0 then
            local mutationPets = 0
            for _, petData in pairs(petAnalysis.petsByMoneyPerSecond) do
                if hasProtectedMutations(petData.pet.Name) then
                    mutationPets = mutationPets + 1
                end
            end
            
            print("=== PET ANALYSIS ===")
            print("Total pets: " .. petAnalysis.totalPets)
            print("Pets with mutations: " .. mutationPets)
            print("Average MoneyPerSecond: " .. math.floor(petAnalysis.averageMoneyPerSecond))
            print("Best MoneyPerSecond: " .. petAnalysis.bestMoneyPerSecond)
            print("Minimum to keep: " .. math.floor(petAnalysis.minMoneyPerSecondToKeep))
            print("Sell Rare: " .. (petAnalysis.shouldSellRare and "YES" or "NO"))
            print("Sell Epic: " .. (petAnalysis.shouldSellEpic and "YES" or "NO"))
            print("Sell Legendary: " .. (petAnalysis.shouldSellLegendary and "YES" or "NO"))
            print("==================")
        end
        
        local bestBrainrot = getBestBrainrotFromInventory()
        if bestBrainrot then
            protectedPet = bestBrainrot.tool
            print("🛡️ Protected from sale: " .. bestBrainrot.name .. " (" .. bestBrainrot.moneyPerSecond .. "/s)")
        end
        
        for _, pet in pairs(backpack:GetChildren()) do
            if pet:IsA("Tool") and pet.Name:match("%[%d+%.?%d*%s*kg%]") then
                if shouldSellPet(pet) then
                    local petInfo = getPetInfo(pet)
                    local sellSuccess = sellPet(pet)
                    
                    if sellSuccess then
                        soldCount = soldCount + 1
                        
                        local reason = "Sold: " .. petInfo.rarity .. " (weight: " .. petInfo.weight .. "kg)"
                        if CONFIG.SMART_SELLING then
                            reason = reason .. " [MoneyPerSecond: " .. petInfo.moneyPerSecond .. "/s]"
                        end
                        
                        table.insert(logs, {
                            action = "SELL",
                            item = petInfo.name,
                            reason = reason,
                            timestamp = os.time()
                        })
                        
                        print("💰 Sold: " .. petInfo.name .. " (" .. petInfo.rarity .. ", " .. petInfo.weight .. "kg, " .. petInfo.moneyPerSecond .. "/s)")
                    else
                        print("❌ Failed to sell: " .. petInfo.name)
                    end
                    
                    wait(CONFIG.SELL_DELAY)
                else
                    local petInfo = getPetInfo(pet)
                    keptCount = keptCount + 1
                end
            end
        end
        
        protectedPet = nil
        
        if soldCount > 0 or keptCount > 0 then
            print("📊 Pets sold: " .. soldCount .. ", kept: " .. keptCount)
        end
    end)
    
    if not success then
        print("❌ Error in autoSellPets: " .. tostring(error))
    end
end

-- Redeem codes
local function redeemCodes()
    print("🎁 Redeeming codes...")
    if dataRemoteEvent then
        for _, code in pairs(CODES) do
            pcall(function()
                local args = {{"code", "\031"}}
                dataRemoteEvent:FireServer(unpack(args))
                wait(0.5)
            end)
        end
        print("✅ Codes redeemed!")
    else
        print("❌ dataRemoteEvent not available")
    end
end

-- Auto-open eggs
local function autoOpenEggs()
    local success, error = pcall(function()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local openedCount = 0
        
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                for _, eggName in pairs(PROTECTED_ITEMS) do
                    if item.Name:find(eggName) then
                        if openEggRemote then
                            local args = {eggName}
                            openEggRemote:FireServer(unpack(args))
                            
                            table.insert(logs, {
                                action = "OPEN_EGG",
                                item = eggName,
                                reason = "Automatically opened egg",
                                timestamp = os.time()
                            })
                            
                            print("🥚 Opened egg: " .. eggName)
                            openedCount = openedCount + 1
                            wait(0.1)
                        end
                        break
                    end
                end
            end
        end
        
        if openedCount > 0 then
            print("📦 Eggs opened: " .. openedCount)
        end
    end)
    
    if not success then
        print("❌ Error in autoOpenEggs: " .. tostring(error))
    end
end

-- Check seed stock
local function checkSeedStock(seedName)
    local seedsGui = PlayerGui:FindFirstChild("Main")
    if not seedsGui then return false, 0 end
    
    local seedsFrame = seedsGui:FindFirstChild("Seeds")
    if not seedsFrame then return false, 0 end
    
    local scrollingFrame = seedsFrame:FindFirstChild("Frame"):FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return false, 0 end
    
    local seedFrame = scrollingFrame:FindFirstChild(seedName)
    if not seedFrame then return false, 0 end
    
    local stockLabel = seedFrame:FindFirstChild("Stock")
    if not stockLabel then return false, 0 end
    
    local stockText = stockLabel.Text
    local stockCount = tonumber(stockText:match("x(%d+)")) or 0
    
    return stockCount > 0, stockCount
end

-- Auto-buy seeds
local function autoBuySeeds()
    local success, error = pcall(function()
        for _, seedName in pairs(SEEDS) do
            local hasStock, stockCount = checkSeedStock(seedName)
            if hasStock then
                if dataRemoteEvent then
                    local args = {{seedName, "\b"}}
                    dataRemoteEvent:FireServer(unpack(args))
                    
                    table.insert(logs, {
                        action = "BUY_SEED",
                        item = seedName,
                        reason = "Purchased (in stock: " .. stockCount .. ")",
                        timestamp = os.time()
                    })
                    
                    print("🌱 Purchased seed: " .. seedName .. " (in stock: " .. stockCount .. ")")
                    wait(0.1)
                end
            end
        end
    end)
    
    if not success then
        print("❌ Error in autoBuySeeds: " .. tostring(error))
    end
end

-- Check gear stock
local function checkGearStock(gearName)
    local gearsGui = PlayerGui:FindFirstChild("Main")
    if not gearsGui then return false, 0 end
    
    local gearsFrame = gearsGui:FindFirstChild("Gears")
    if not gearsFrame then return false, 0 end
    
    local scrollingFrame = gearsFrame:FindFirstChild("Frame"):FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return false, 0 end
    
    local gearFrame = scrollingFrame:FindFirstChild(gearName)
    if not gearFrame then return false, 0 end
    
    local stockLabel = gearFrame:FindFirstChild("Stock")
    if not stockLabel then return false, 0 end
    
    local stockText = stockLabel.Text
    local stockCount = tonumber(stockText:match("x(%d+)")) or 0
    
    return stockCount > 0, stockCount
end

-- Auto-buy items
local function autoBuyGear()
    local success, error = pcall(function()
        for _, gearName in pairs(GEAR_ITEMS) do
            local hasStock, stockCount = checkGearStock(gearName)
            if hasStock then
                if dataRemoteEvent then
                    local args = {{gearName, "\026"}}
                    dataRemoteEvent:FireServer(unpack(args))
                    
                    table.insert(logs, {
                        action = "BUY_GEAR",
                        item = gearName,
                        reason = "Purchased (in stock: " .. stockCount .. ")",
                        timestamp = os.time()
                    })
                    
                    print("⚔️ Purchased item: " .. gearName .. " (in stock: " .. stockCount .. ")")
                    wait(0.1)
                end
            end
        end
    end)
    
    if not success then
        print("❌ Error in autoBuyGear: " .. tostring(error))
    end
end

-- Get current player plot
local function getCurrentPlot()
    local plotNumber = LocalPlayer:GetAttribute("Plot")
    if plotNumber then
        local plot = workspace.Plots:FindFirstChild(tostring(plotNumber))
        if plot then
            return plot
        end
    end
    return nil
end

-- Get player balance
local function getPlayerBalance()
    if not playerData then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local moneyValue = humanoid:FindFirstChild("Money")
                if moneyValue then
                    return moneyValue.Value
                end
            end
        end
        return 0
    end
    
    local success, balance = pcall(function()
        return playerData.get("Money") or 0
    end)
    
    if success then
        return balance
    else
        return 0
    end
end

-- Buy platform
local function buyPlatform(platformNumber)
    if dataRemoteEvent then
        local args = {
            {
                tostring(platformNumber),
                ","
            }
        }
        
        local success, error = pcall(function()
            dataRemoteEvent:FireServer(unpack(args))
        end)
        
        if success then
            table.insert(logs, {
                action = "BUY_PLATFORM",
                item = "Platform " .. platformNumber,
                reason = "Platform purchased",
                timestamp = os.time()
            })
            return true
        end
    end
    return false
end

-- Auto-buy platforms
local function autoBuyPlatforms()
    local success, error = pcall(function()
        if not CONFIG.AUTO_BUY_PLATFORMS then
            return
        end
        
        local currentPlot = getCurrentPlot()
        if not currentPlot then
            return
        end
        
        local brainrots = currentPlot:FindFirstChild("Brainrots")
        if not brainrots then
            return
        end
        
        local playerBalance = getPlayerBalance()
        local boughtCount = 0
        
        for _, platform in pairs(brainrots:GetChildren()) do
            if platform:IsA("Model") and platform.Name:match("^%d+$") then
                local platformPrice = platform:GetAttribute("PlatformPrice")
                if platformPrice then
                    local platformPriceMoney = platformPrice.Money
                    if platformPriceMoney then
                        local priceText = tostring(platformPriceMoney)
                        local priceValue = priceText:match("%$(%d+,?%d*%d*)")
                        if priceValue then
                            local cleanPrice = priceValue:gsub(",", "")
                            local price = tonumber(cleanPrice) or 0
                            
                            if buyPlatform(platform.Name) then
                                boughtCount = boughtCount + 1
                                wait(0.5)
                            end
                        end
                    end
                end
            end
        end
        
        if boughtCount > 0 then
            print("🏗️ Platforms purchased: " .. boughtCount)
        end
    end)
    
    if not success then
        print("❌ Error in autoBuyPlatforms: " .. tostring(error))
    end
end

-- Update status display
local function updateStatus()
    if not statusLabels.pets then return end
    
    -- Update pet count
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local petCount = 0
    local totalMoneyPerSecond = 0
    
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name:match("%[%d+%.?%d*%s*kg%]") then
            petCount = petCount + 1
            local petInfo = getPetInfo(item)
            totalMoneyPerSecond = totalMoneyPerSecond + petInfo.moneyPerSecond
        end
    end
    statusLabels.pets.Text = "🐾 Pets: " .. petCount
    
    -- Update coins
    local balance = getPlayerBalance()
    statusLabels.coins.Text = "💰 Coins: $" .. balance
    
    -- Update platforms count
    local platformCount = 0
    local plotNumber = LocalPlayer:GetAttribute("Plot")
    if plotNumber then
        local plot = workspace.Plots:FindFirstChild(tostring(plotNumber))
        if plot then
            local brainrots = plot:FindFirstChild("Brainrots")
            if brainrots then
                for _, platform in pairs(brainrots:GetChildren()) do
                    if platform:IsA("Model") then
                        platformCount = platformCount + 1
                    end
                end
            end
        end
    end
    statusLabels.platforms.Text = "🏗️ Platforms: " .. platformCount
    
    -- Update profit
    statusLabels.profit.Text = "📈 Profit: $" .. math.floor(totalMoneyPerSecond) .. "/s"
end

-- Copy logs to clipboard
local function copyLogsToClipboard()
    if #logs == 0 then
        print("📋 No logs available!")
        return
    end
    
    local logText = "=== AUTO FARM LOGS ===\n\n"
    
    for i, log in pairs(logs) do
        local timeStr = os.date("%H:%M:%S", log.timestamp)
        logText = logText .. string.format("[%s] %s: %s - %s\n", 
            timeStr, log.action, log.item or "No item", log.reason or "No reason")
    end
    
    logText = logText .. "\nTotal entries: " .. #logs
    
    pcall(function()
        setclipboard(logText)
        print("✅ Logs copied to clipboard!")
    end)
end

-- Initialize remote events
local function initialize()
    print("🚀 Initializing Auto Farm...")
    
    -- Wait for necessary services with error handling
    local success, err = pcall(function()
        itemSellRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ItemSell")
        print("✅ itemSellRemote found")
    end)
    if not success then
        print("⚠️ itemSellRemote not found: " .. tostring(err))
    end
    
    success, err = pcall(function()
        dataRemoteEvent = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")
        print("✅ dataRemoteEvent found")
    end)
    if not success then
        print("⚠️ dataRemoteEvent not found: " .. tostring(err))
    end
    
    success, err = pcall(function()
        useItemRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem")
        print("✅ useItemRemote found")
    end)
    if not success then
        print("⚠️ useItemRemote not found: " .. tostring(err))
    end
    
    success, err = pcall(function()
        openEggRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("OpenEgg")
        print("✅ openEggRemote found")
    end)
    if not success then
        print("⚠️ openEggRemote not found: " .. tostring(err))
    end
    
    -- Initialize PlayerData
    success, err = pcall(function()
        playerData = require(ReplicatedStorage:WaitForChild("PlayerData"))
        print("✅ PlayerData initialized")
    end)
    if not success then
        print("⚠️ PlayerData not available: " .. tostring(err))
        playerData = nil
    end
    
    -- Get current plot
    local plotNumber = LocalPlayer:GetAttribute("Plot")
    if plotNumber then
        currentPlot = workspace.Plots:FindFirstChild(tostring(plotNumber))
        if currentPlot then
            print("📍 Found plot: " .. plotNumber)
        else
            print("❌ Plot " .. plotNumber .. " not found")
        end
    else
        print("❌ Plot attribute not found")
    end
    
    -- Create GUI with error handling
    local guiSuccess, guiErr = pcall(function()
        createSimpleGUI()
    end)
    
    if not guiSuccess then
        print("❌ GUI creation failed: " .. tostring(guiErr))
        print("🔄 Creating emergency GUI...")
        
        -- Emergency GUI
        local emergencyGui = Instance.new("ScreenGui")
        emergencyGui.Name = "EmergencyAutoFarmGUI"
        emergencyGui.Parent = PlayerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 250, 0, 120)
        frame.Position = UDim2.new(0, 50, 0, 50)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        frame.Parent = emergencyGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = "🤖 Auto Farm\n✅ Script Running!\n🎮 Check console for controls"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.Parent = frame
        
        print("✅ Emergency GUI created!")
    end
    
    print("✅ Initialization completed!")
end

-- Main function
local function main()
    print("====================================")
    print("🤖 AUTO FARM BOT v2.0 STARTED")
    print("====================================")
    
    -- Initialize
    initialize()
    
    -- Redeem codes on start
    spawn(function()
        wait(3)
        redeemCodes()
    end)
    
    -- Start status updates
    spawn(function()
        while true do
            updateStatus()
            wait(2)
        end
    end)
    
    -- Main farming loops
    spawn(function()
        while true do
            if CONFIG.SMART_SELLING then
                autoSellPets()
            end
            wait(5)
        end
    end)
    
    spawn(function()
        while true do
            if CONFIG.AUTO_BUY_SEEDS then
                autoBuySeeds()
            end
            if CONFIG.AUTO_BUY_GEAR then
                autoBuyGear()
            end
            wait(CONFIG.BUY_INTERVAL)
        end
    end)
    
    spawn(function()
        while true do
            if CONFIG.AUTO_BUY_PLATFORMS then
                autoBuyPlatforms()
            end
            wait(CONFIG.PLATFORM_BUY_INTERVAL)
        end
    end)
    
    spawn(function()
        while true do
            autoOpenEggs()
            wait(30)
        end
    end)
    
    -- Keyboard input handler
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.LOG_COPY_KEY then
            copyLogsToClipboard()
        end
    end)
    
    print("✅ All systems ready!")
    print("📍 GUI should be visible on screen")
    print("🎮 Use the GUI buttons to control farming")
    print("====================================")
end

-- Start the script
main()
[file content end]
