-- Grow A Garden Auto Farm Script - Fixed UI Versiona
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Wait for player to load
if not Player then
    Player = Players.PlayerAdded:Wait()
end

-- Wait for character to load
local Character = Player.Character or Player.CharacterAdded:Wait()
local Backpack = Player:WaitForChild("Backpack")
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Initialize variables
local FarmsFolder = Workspace:WaitForChild("Farm")
local BuySeedStock = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock")
local Plant = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Plant_RE")
local sellAllRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory")
local removeItem = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Remove_Item")
local Sheckles_Buy = ReplicatedStorage.GameEvents:FindFirstChild("Sheckles_Buy")

-- Find NPCs
local Steven = Workspace:FindFirstChild("NPCS") and Workspace.NPCS:FindFirstChild("Steven")
local Sam = Workspace:FindFirstChild("NPCS") and Workspace.NPCS:FindFirstChild("Sam")

-- Game Variables
local CropsListAndStocks = {}
local wantedFruits = {}
local plantAura = false
local AutoSellItems = 70
local shouldSell = false
local plantToRemove = {"None Selected"}
local shouldAutoPlant = false
local isSelling = false
local autoBuyEnabled = false
local isBuying = false
local autoShecklesBuyEnabled = false
local shecklesBuyCooldown = 5
local lastShecklesBuyTime = 0

-- Simple UI Library as fallback
local function createSimpleUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GrowAGardenUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Grow A Garden Auto Farm"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = mainFrame
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 14
    closeButton.Parent = mainFrame
    closeButton.MouseButton1Click:Connect(function()
        screenGui.Enabled = not screenGui.Enabled
    end)
    
    local tabButtons = {}
    local tabFrames = {}
    local tabs = {"Plants", "Seeds", "Sell", "Player"}
    
    for i, tabName in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(0.25, -5, 0, 30)
        tabButton.Position = UDim2.new((i-1) * 0.25, 5, 0, 40)
        tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.Text = tabName
        tabButton.Font = Enum.Font.Gotham
        tabButton.TextSize = 12
        tabButton.Parent = mainFrame
        
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, -10, 1, -80)
        tabFrame.Position = UDim2.new(0, 5, 0, 75)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = mainFrame
        
        local layout = Instance.new("UIListLayout")
        layout.Parent = tabFrame
        layout.Padding = UDim.new(0, 5)
        
        tabButtons[tabName] = tabButton
        tabFrames[tabName] = tabFrame
        
        tabButton.MouseButton1Click:Connect(function()
            for _, frame in pairs(tabFrames) do
                frame.Visible = false
            end
            tabFrame.Visible = true
        end)
    end
    
    -- Plants Tab
    local plantsFrame = tabFrames["Plants"]
    
    -- Harvest Aura
    local auraToggle = Instance.new("TextButton")
    auraToggle.Size = UDim2.new(1, 0, 0, 30)
    auraToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    auraToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    auraToggle.Text = "Harvest Aura: OFF"
    auraToggle.Font = Enum.Font.Gotham
    auraToggle.TextSize = 12
    auraToggle.Parent = plantsFrame
    auraToggle.MouseButton1Click:Connect(function()
        plantAura = not plantAura
        auraToggle.Text = "Harvest Aura: " .. (plantAura and "ON" or "OFF")
        auraToggle.BackgroundColor3 = plantAura and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(80, 80, 80)
    end)
    
    -- Collect All Plants
    local collectButton = Instance.new("TextButton")
    collectButton.Size = UDim2.new(1, 0, 0, 30)
    collectButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    collectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    collectButton.Text = "Collect All Plants"
    collectButton.Font = Enum.Font.Gotham
    collectButton.TextSize = 12
    collectButton.Parent = plantsFrame
    collectButton.MouseButton1Click:Connect(function()
        -- Collect plants function will be added
        print("Collecting all plants...")
    end)
    
    -- Plant All Seeds
    local plantButton = Instance.new("TextButton")
    plantButton.Size = UDim2.new(1, 0, 0, 30)
    plantButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    plantButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    plantButton.Text = "Plant All Seeds"
    plantButton.Font = Enum.Font.Gotham
    plantButton.TextSize = 12
    plantButton.Parent = plantsFrame
    plantButton.MouseButton1Click:Connect(function()
        -- Plant seeds function will be added
        print("Planting all seeds...")
    end)
    
    -- Auto Plant Toggle
    local autoPlantToggle = Instance.new("TextButton")
    autoPlantToggle.Size = UDim2.new(1, 0, 0, 30)
    autoPlantToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    autoPlantToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoPlantToggle.Text = "Auto Plant: OFF"
    autoPlantToggle.Font = Enum.Font.Gotham
    autoPlantToggle.TextSize = 12
    autoPlantToggle.Parent = plantsFrame
    autoPlantToggle.MouseButton1Click:Connect(function()
        shouldAutoPlant = not shouldAutoPlant
        autoPlantToggle.Text = "Auto Plant: " .. (shouldAutoPlant and "ON" or "OFF")
        autoPlantToggle.BackgroundColor3 = shouldAutoPlant and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(80, 80, 80)
    end)
    
    -- Seeds Tab
    local seedsFrame = tabFrames["Seeds"]
    
    -- Auto Buy Toggle
    local autoBuyToggle = Instance.new("TextButton")
    autoBuyToggle.Size = UDim2.new(1, 0, 0, 30)
    autoBuyToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    autoBuyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBuyToggle.Text = "Auto Buy Seeds: OFF"
    autoBuyToggle.Font = Enum.Font.Gotham
    autoBuyToggle.TextSize = 12
    autoBuyToggle.Parent = seedsFrame
    autoBuyToggle.MouseButton1Click:Connect(function()
        autoBuyEnabled = not autoBuyEnabled
        autoBuyToggle.Text = "Auto Buy Seeds: " .. (autoBuyEnabled and "ON" or "OFF")
        autoBuyToggle.BackgroundColor3 = autoBuyEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(80, 80, 80)
    end)
    
    -- Sheckles Buy Section
    if Sheckles_Buy then
        local shecklesToggle = Instance.new("TextButton")
        shecklesToggle.Size = UDim2.new(1, 0, 0, 30)
        shecklesToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        shecklesToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        shecklesToggle.Text = "Auto Sheckles Buy: OFF"
        shecklesToggle.Font = Enum.Font.Gotham
        shecklesToggle.TextSize = 12
        shecklesToggle.Parent = seedsFrame
        shecklesToggle.MouseButton1Click:Connect(function()
            autoShecklesBuyEnabled = not autoShecklesBuyEnabled
            shecklesToggle.Text = "Auto Sheckles Buy: " .. (autoShecklesBuyEnabled and "ON" or "OFF")
            shecklesToggle.BackgroundColor3 = autoShecklesBuyEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(80, 80, 80)
        end)
        
        local shecklesButton = Instance.new("TextButton")
        shecklesButton.Size = UDim2.new(1, 0, 0, 30)
        shecklesButton.BackgroundColor3 = Color3.fromRGB(200, 120, 60)
        shecklesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        shecklesButton.Text = "Sheckles Buy Now"
        shecklesButton.Font = Enum.Font.Gotham
        shecklesButton.TextSize = 12
        shecklesButton.Parent = seedsFrame
        shecklesButton.MouseButton1Click:Connect(function()
            -- Sheckles buy function will be added
            print("Sheckles buy...")
        end)
    end
    
    -- Sell Tab
    local sellFrame = tabFrames["Sell"]
    
    -- Auto Sell Toggle
    local autoSellToggle = Instance.new("TextButton")
    autoSellToggle.Size = UDim2.new(1, 0, 0, 30)
    autoSellToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    autoSellToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoSellToggle.Text = "Auto Sell: OFF"
    autoSellToggle.Font = Enum.Font.Gotham
    autoSellToggle.TextSize = 12
    autoSellToggle.Parent = sellFrame
    autoSellToggle.MouseButton1Click:Connect(function()
        shouldSell = not shouldSell
        autoSellToggle.Text = "Auto Sell: " .. (shouldSell and "ON" or "OFF")
        autoSellToggle.BackgroundColor3 = shouldSell and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(80, 80, 80)
    end)
    
    -- Sell Now Button
    local sellButton = Instance.new("TextButton")
    sellButton.Size = UDim2.new(1, 0, 0, 30)
    sellButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    sellButton.Text = "Sell All Now"
    sellButton.Font = Enum.Font.Gotham
    sellButton.TextSize = 12
    sellButton.Parent = sellFrame
    sellButton.MouseButton1Click:Connect(function()
        -- Sell function will be added
        print("Selling all...")
    end)
    
    -- Player Tab
    local playerFrame = tabFrames["Player"]
    
    -- Speed Slider
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, 0, 0, 20)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedLabel.Text = "Walk Speed: 16"
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 12
    speedLabel.Parent = playerFrame
    
    local speedSlider = Instance.new("TextButton")
    speedSlider.Size = UDim2.new(1, 0, 0, 30)
    speedSlider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    speedSlider.Text = "Adjust Speed (16-500)"
    speedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedSlider.Font = Enum.Font.Gotham
    speedSlider.TextSize = 12
    speedSlider.Parent = playerFrame
    
    -- Jump Power Slider
    local jumpLabel = Instance.new("TextLabel")
    jumpLabel.Size = UDim2.new(1, 0, 0, 20)
    jumpLabel.BackgroundTransparency = 1
    jumpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpLabel.Text = "Jump Power: 50"
    jumpLabel.Font = Enum.Font.Gotham
    jumpLabel.TextSize = 12
    jumpLabel.Parent = playerFrame
    
    local jumpSlider = Instance.new("TextButton")
    jumpSlider.Size = UDim2.new(1, 0, 0, 30)
    jumpSlider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    jumpSlider.Text = "Adjust Jump Power (50-500)"
    jumpSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpSlider.Font = Enum.Font.Gotham
    jumpSlider.TextSize = 12
    jumpSlider.Parent = playerFrame
    
    -- TP Wand
    local tpWandButton = Instance.new("TextButton")
    tpWandButton.Size = UDim2.new(1, 0, 0, 30)
    tpWandButton.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    tpWandButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpWandButton.Text = "Create TP Wand"
    tpWandButton.Font = Enum.Font.Gotham
    tpWandButton.TextSize = 12
    tpWandButton.Parent = playerFrame
    tpWandButton.MouseButton1Click:Connect(function()
        local mouse = Player:GetMouse()
        local TPWand = Instance.new("Tool", Backpack)
        TPWand.Name = "TP Wand"
        TPWand.RequiresHandle = false
        mouse.Button1Down:Connect(function()
            if Character:FindFirstChild("TP Wand") then
                HRP.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
            end
        end)
    end)
    
    return screenGui
end

-- Game Functions
local function findPlayerFarm()
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important and v.Important.Data and v.Important.Data.Owner and v.Important.Data.Owner.Value == Player.Name then
            return v
        end
    end
    return nil
end

local function getPlantedFruitTypes()
    local list = {"None Selected"}
    local farm = findPlayerFarm()
    if not farm then return list end
    
    if farm.Important and farm.Important.Plants_Physical then
        for _,plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
            if not table.find(list, plant.Name) then
                table.insert(list, plant.Name)
            end
        end
    end
    return list
end

local function getPlantingBoundaries(farm)
    local offset = Vector3.new(15.2844, 0, 28.356)
    local edges = {}
    
    if farm.Important and farm.Important.Plant_Locations then
        local PlantingLocations = farm.Important.Plant_Locations:GetChildren()
        if #PlantingLocations >= 2 then
            local rect1Center = PlantingLocations[1].Position
            local rect2Center = PlantingLocations[2].Position
            edges["1TopLeft"] = rect1Center + offset
            edges["1BottomRight"] = rect1Center - offset
            edges["2TopLeft"] = rect2Center + offset
            edges["2BottomRight"] = rect2Center - offset
        end
    end
    return edges
end

local function getRandomPlantingLocation(edges)
    if not edges["1TopLeft"] then
        return CFrame.new(0, 0, 0)
    end
    
    local rectangles = {
        {edges["1TopLeft"], edges["1BottomRight"]},
        {edges["2TopLeft"], edges["2BottomRight"]}
    }

    local chosen = rectangles[math.random(1, #rectangles)]
    local a = chosen[1]
    local b = chosen[2]

    local minX, maxX = math.min(a.X, b.X), math.max(a.X, b.X)
    local minZ, maxZ = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
    local Y = 0.13552704453468323

    local randX = math.random() * (maxX - minX) + minX
    local randZ = math.random() * (maxZ - minZ) + minZ

    return CFrame.new(randX, Y, randZ)
end

local function areThereSeeds()
    for _,Item in pairs(Backpack:GetChildren()) do
        if Item:FindFirstChild("Seed Local Script") then
            return true
        end
    end
    return false
end

local function plantAllSeeds()
    local farm = findPlayerFarm()
    if not farm then return end
    
    local edges = getPlantingBoundaries(farm)
    
    while areThereSeeds() do
        for _,Item in pairs(Backpack:GetChildren()) do
            if Item:FindFirstChild("Seed Local Script") then
                Item.Parent = Character
                wait(0.1)
                local location = getRandomPlantingLocation(edges)
                local args = {
                    [1] = location.Position,
                    [2] = Item:GetAttribute("Seed")
                }
                Plant:FireServer(unpack(args))
                wait(0.1)
                if Item and Item:IsDescendantOf(game) and Item.Parent ~= Backpack then
                    pcall(function()
                        Item.Parent = Backpack
                    end)
                end
            end
        end
        wait(0.5)
    end
end

local function GetAllPlants()
    local plantsTable = {}
    local farm = findPlayerFarm()
    if not farm or not farm.Important or not farm.Important.Plants_Physical then return plantsTable end
    
    for _, Plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if Plant:FindFirstChild("Fruits") then
            for _, miniPlant in pairs(Plant.Fruits:GetChildren()) do
                table.insert(plantsTable, miniPlant)
            end
        else
            table.insert(plantsTable, Plant)
        end
    end
    return plantsTable
end

local function collectPlant(plant)
    if plant:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(plant.ProximityPrompt)
    else
        for _, child in pairs(plant:GetChildren()) do
            if child:FindFirstChild("ProximityPrompt") then
                fireproximityprompt(child.ProximityPrompt)
                break
            end
        end
    end
end

local function CollectAllPlants()
    local plants = GetAllPlants()
    
    for i = #plants, 2, -1 do
        local j = math.random(i)
        plants[i], plants[j] = plants[j], plants[i]
    end
    
    for _,plant in pairs(plants) do
        collectPlant(plant)
        task.wait(0.05)
    end
end

-- Sheckles Buy Function
local function performShecklesBuy()
    if not Sheckles_Buy then return false end
    
    local currentTime = tick()
    if currentTime - lastShecklesBuyTime < shecklesBuyCooldown then return false end
    
    local success, errorMsg = pcall(function()
        Sheckles_Buy:FireServer()
    end)
    
    if success then
        lastShecklesBuyTime = currentTime
        return true
    else
        return false
    end
end

local function sellAll()
    if not Steven or isSelling then return end
    
    local OrgPos = HRP.CFrame
    HRP.CFrame = Steven.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    wait(1.5)
    
    isSelling = true
    sellAllRemote:FireServer()
    
    local startTime = tick()
    while #Backpack:GetChildren() >= AutoSellItems and tick() - startTime < 10 do
        sellAllRemote:FireServer()
        wait(0.5)
    end
    
    HRP.CFrame = OrgPos
    isSelling = false
end

-- Main loops
spawn(function()
    while true do
        if autoShecklesBuyEnabled and Sheckles_Buy then
            performShecklesBuy()
        end
        wait(shecklesBuyCooldown)
    end
end)

spawn(function()
    while true do
        if shouldSell and #Backpack:GetChildren() >= AutoSellItems and not isSelling then
            sellAll()
        end
        
        wait(0.5)
    end
end)

spawn(function()
    while true do
        if plantAura then
            local plants = GetAllPlants()
            for i = #plants, 2, -1 do
                local j = math.random(i)
                plants[i], plants[j] = plants[j], plants[i]
            end
            
            for _, plant in pairs(plants) do
                if plant:FindFirstChild("Fruits") then
                    for _, miniPlant in pairs(plant.Fruits:GetChildren()) do
                        for _, child in pairs(miniPlant:GetChildren()) do
                            if child:FindFirstChild("ProximityPrompt") then
                                fireproximityprompt(child.ProximityPrompt)
                            end
                        end
                        task.wait(0.01)
                    end
                else
                    for _, child in pairs(plant:GetChildren()) do
                        if child:FindFirstChild("ProximityPrompt") then
                            fireproximityprompt(child.ProximityPrompt)
                        end
                        task.wait(0.01)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Auto Plant loop
spawn(function()
    while true do
        if shouldAutoPlant then
            plantAllSeeds()
        end
        wait(5)
    end
end)

-- Create UI
local success, ui = pcall(function()
    return createSimpleUI()
end)

if success then
    print("✅ Grow A Garden UI loaded successfully!")
    print("✅ Features loaded:")
    print("   - Auto Harvest Aura")
    print("   - Auto Plant")
    print("   - Auto Sheckles Buy")
    print("   - Auto Sell")
    print("   - Player Utilities")
else
    warn("❌ Failed to create UI: " .. tostring(ui))
end

-- Update references on character respawn
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HRP = newCharacter:WaitForChild("HumanoidRootPart")
    Humanoid = newCharacter:WaitForChild("Humanoid")
end)

print("🎮 Grow A Garden script loaded successfully!")
