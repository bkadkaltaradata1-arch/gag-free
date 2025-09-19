getgenv().AutoFarm = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local lplr = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("SummerHarvestRemoteEvent")

-- Variabel untuk mengontrol eksekusi
local isRunning = false
local currentTask = nil

-- Fungsi untuk mendapatkan HumanoidRootPart dengan penanganan error yang lebih baik
local function getHumanoidRootPart()
    if not lplr.Character then
        return nil
    end
    
    local success, result = pcall(function()
        return lplr.Character:FindFirstChild("HumanoidRootPart")
    end)
    
    return success and result or nil
end

-- Fungsi teleport dengan pengecekan keamanan
local function teleportTo(position)
    local hrp = getHumanoidRootPart()
    if hrp then
        local success, err = pcall(function()
            hrp.CFrame = CFrame.new(position)
        end)
        
        if not success then
            warn("Teleport error: " .. tostring(err))
            return false
        end
        return true
    end
    return false
end

-- Fungsi untuk menekan tombol E dengan penanganan error
local function pressEKey()
    local success, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    
    if not success then
        warn("Error pressing E key: " .. tostring(err))
        return false
    end
    return true
end

-- Fungsi untuk memanen buah hingga habis
local function harvestFruitUntilGone(fruit)
    if not fruit or not fruit.PrimaryPart then 
        return false 
    end
    
    local fruitExists = true
    local conn
    
    -- Menghubungkan event untuk mendeteksi ketika buah dihapus
    conn = fruit.AncestryChanged:Connect(function(_, parent)
        if not parent then
            fruitExists = false
            conn:Disconnect()
        end
    end)
    
    -- Loop panen selama buah masih ada dan AutoFarm aktif
    while fruitExists and getgenv().AutoFarm do
        if not pressEKey() then
            break
        end
        task.wait(0.2)
    end
    
    if conn then
        conn:Disconnect()
    end
    
    return true
end

-- Fungsi untuk mendapatkan farm yang dimiliki player
local function getOwnedFarms()
    local farms = {}
    
    local success, farmObjects = pcall(function()
        return workspace:WaitForChild("Farm"):GetChildren()
    end)
    
    if not success or not farmObjects then
        return farms
    end
    
    for _, farm in ipairs(farmObjects) do
        local isOwned = pcall(function()
            return farm.Important.Data.Owner.Value == lplr.Name
        end)
        
        if isOwned then
            table.insert(farms, farm)
        end
    end
    
    return farms
end

-- Fungsi untuk mendapatkan tanaman dari farm
local function getPlantsFromFarm(farm)
    local plants = {}
    
    if not farm or not farm.Important then
        return plants
    end
    
    local success, plantsFolder = pcall(function()
        return farm.Important:FindFirstChild("Plants_Physical")
    end)
    
    if success and plantsFolder then
        for _, plant in ipairs(plantsFolder:GetChildren()) do
            if plant:IsA("Model") then
                table.insert(plants, plant)
            end
        end
    end
    
    return plants
end

-- Fungsi untuk mendapatkan buah dari tanaman
local function getFruitsFromPlant(plant)
    local fruits = {}
    
    if not plant then
        return fruits
    end
    
    local success, fruitsFolder = pcall(function()
        return plant:FindFirstChild("Fruits")
    end)
    
    if success and fruitsFolder then
        for _, fruit in ipairs(fruitsFolder:GetChildren()) do
            if fruit:IsA("Model") and fruit.PrimaryPart then
                table.insert(fruits, fruit)
            end
        end
    end
    
    return fruits
end

-- Fungsi untuk memeriksa apakah dalam 10 menit pertama
local function isWithinFirstTenMinutes()
    local time = os.date("*t")
    return time.min >= 0 and time.min < 10
end

-- Fungsi untuk pause dan submit tanaman
local function pauseAndSubmit()
    local hrp = getHumanoidRootPart()
    if hrp then
        local success = pcall(function()
            hrp.CFrame = CFrame.new(-116.40152, 4.40001249, -12.4976292, 0.871914983, 0, 0.489657342, 0, 1, 0, -0.489657342, 0, 0.871914983)
        end)
        
        if success then
            pcall(function()
                remote:FireServer("SubmitAllPlants")
            end)
        end
    end
end

-- Fungsi utama untuk AutoFarm
local function startAutoFarm()
    if isRunning then return end
    isRunning = true
    
    while getgenv().AutoFarm and task.wait(1) do
        -- Periksa apakah dalam 10 menit pertama
        getgenv().sh = isWithinFirstTenMinutes()
        
        if not getgenv().sh then
            task.wait(5)
            continue
        end
        
        local hrp = getHumanoidRootPart()
        if not hrp then
            task.wait(3)
            continue
        end
        
        -- Dapatkan farm yang dimiliki
        local farms = getOwnedFarms()
        if #farms == 0 then
            task.wait(5)
            continue
        end
        
        -- Iterasi melalui setiap farm, tanaman, dan buah
        for _, farm in ipairs(farms) do
            if not getgenv().AutoFarm or not getgenv().sh then break end
            
            local plants = getPlantsFromFarm(farm)
            for _, plant in ipairs(plants) do
                if not getgenv().AutoFarm or not getgenv().sh then break end
                
                local fruits = getFruitsFromPlant(plant)
                for _, fruit in ipairs(fruits) do
                    if not getgenv().AutoFarm or not getgenv().sh then break end
                    
                    -- Hanya panen tomat
                    if fruit and fruit.Name == "Tomato" and fruit.PrimaryPart then
                        if teleportTo(fruit.PrimaryPart.Position) then
                            task.wait(0.1)
                            harvestFruitUntilGone(fruit)
                        end
                    end
                end
            end
        end
        
        -- Submit tanaman setelah selesai
        if getgenv().AutoFarm and getgenv().sh then
            for i = 1, 5 do
                if not getgenv().AutoFarm then break end
                pauseAndSubmit()
                task.wait(1)
            end
        end
        
        task.wait(25)
    end
    
    isRunning = false
end

-- Fungsi untuk menghentikan AutoFarm
local function stopAutoFarm()
    getgenv().AutoFarm = false
    isRunning = false
end

-- =============================================
-- GUI CREATION
-- =============================================

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmGUI"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 400)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Corner Radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Drop Shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.8
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = -1
shadow.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🌱 Auto Farm GUI"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeButton.BorderSizePixel = 0
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 15)
closeCorner.Parent = closeButton

-- Content Frame
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -20, 1, -60)
content.Position = UDim2.new(0, 10, 0, 50)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Status Panel
local statusPanel = Instance.new("Frame")
statusPanel.Name = "StatusPanel"
statusPanel.Size = UDim2.new(1, 0, 0, 80)
statusPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
statusPanel.BorderSizePixel = 0
statusPanel.Parent = content

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusPanel

local statusTitle = Instance.new("TextLabel")
statusTitle.Name = "StatusTitle"
statusTitle.Size = UDim2.new(1, -20, 0, 20)
statusTitle.Position = UDim2.new(0, 10, 0, 10)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "STATUS:"
statusTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
statusTitle.TextSize = 12
statusTitle.Font = Enum.Font.Gotham
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusPanel

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -20, 0, 30)
statusText.Position = UDim2.new(0, 10, 0, 30)
statusText.BackgroundTransparency = 1
statusText.Text = "STOPPED"
statusText.TextColor3 = Color3.fromRGB(255, 80, 80)
statusText.TextSize = 18
statusText.Font = Enum.Font.GothamBold
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusPanel

local timeStatus = Instance.new("TextLabel")
timeStatus.Name = "TimeStatus"
timeStatus.Size = UDim2.new(1, -20, 0, 20)
timeStatus.Position = UDim2.new(0, 10, 0, 60)
timeStatus.BackgroundTransparency = 1
timeStatus.Text = "10-min Window: Checking..."
timeStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
timeStatus.TextSize = 12
timeStatus.Font = Enum.Font.Gotham
timeStatus.TextXAlignment = Enum.TextXAlignment.Left
timeStatus.Parent = statusPanel

-- Control Buttons
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, 0, 0, 50)
buttonContainer.Position = UDim2.new(0, 0, 0, 100)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = content

local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(0, 120, 1, 0)
startButton.Position = UDim2.new(0, 0, 0, 0)
startButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
startButton.BorderSizePixel = 0
startButton.Text = "▶ START"
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 14
startButton.Font = Enum.Font.GothamBold
startButton.Parent = buttonContainer

local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0, 120, 1, 0)
stopButton.Position = UDim2.new(1, -120, 0, 0)
stopButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
stopButton.BorderSizePixel = 0
stopButton.Text = "■ STOP"
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = buttonContainer

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = startButton
buttonCorner:Clone().Parent = stopButton

-- Stats Panel
local statsPanel = Instance.new("Frame")
statsPanel.Name = "StatsPanel"
statsPanel.Size = UDim2.new(1, 0, 0, 120)
statsPanel.Position = UDim2.new(0, 0, 0, 170)
statsPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
statsPanel.BorderSizePixel = 0
statsPanel.Parent = content

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 6)
statsCorner.Parent = statsPanel

local statsTitle = Instance.new("TextLabel")
statsTitle.Name = "StatsTitle"
statsTitle.Size = UDim2.new(1, -20, 0, 20)
statsTitle.Position = UDim2.new(0, 10, 0, 10)
statsTitle.BackgroundTransparency = 1
statsTitle.Text = "FARM STATS:"
statsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
statsTitle.TextSize = 12
statsTitle.Font = Enum.Font.Gotham
statsTitle.TextXAlignment = Enum.TextXAlignment.Left
statsTitle.Parent = statsPanel

local farmsText = Instance.new("TextLabel")
farmsText.Name = "FarmsText"
farmsText.Size = UDim2.new(1, -20, 0, 20)
farmsText.Position = UDim2.new(0, 10, 0, 35)
farmsText.BackgroundTransparency = 1
farmsText.Text = "Owned Farms: 0"
farmsText.TextColor3 = Color3.fromRGB(255, 255, 255)
farmsText.TextSize = 14
farmsText.Font = Enum.Font.Gotham
farmsText.TextXAlignment = Enum.TextXAlignment.Left
farmsText.Parent = statsPanel

local plantsText = Instance.new("TextLabel")
plantsText.Name = "PlantsText"
plantsText.Size = UDim2.new(1, -20, 0, 20)
plantsText.Position = UDim2.new(0, 10, 0, 60)
plantsText.BackgroundTransparency = 1
plantsText.Text = "Total Plants: 0"
plantsText.TextColor3 = Color3.fromRGB(255, 255, 255)
plantsText.TextSize = 14
plantsText.Font = Enum.Font.Gotham
plantsText.TextXAlignment = Enum.TextXAlignment.Left
plantsText.Parent = statsPanel

local fruitsText = Instance.new("TextLabel")
fruitsText.Name = "FruitsText"
fruitsText.Size = UDim2.new(1, -20, 0, 20)
fruitsText.Position = UDim2.new(0, 10, 0, 85)
fruitsText.BackgroundTransparency = 1
fruitsText.Text = "Tomatoes Found: 0"
fruitsText.TextColor3 = Color3.fromRGB(255, 255, 255)
fruitsText.TextSize = 14
fruitsText.Font = Enum.Font.Gotham
fruitsText.TextXAlignment = Enum.TextXAlignment.Left
fruitsText.Parent = statsPanel

-- Toggle Visibility Button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(1, -50, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "⬅"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 16
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 20)
toggleCorner.Parent = toggleButton

-- =============================================
-- GUI FUNCTIONALITY
-- =============================================

-- Variables for GUI
local isGuiVisible = true
local statsUpdateConnection

-- Function to update status
local function updateStatus(text, color)
    statusText.Text = text
    statusText.TextColor3 = color
end

-- Function to update time status
local function updateTimeStatus()
    local inTimeWindow = isWithinFirstTenMinutes()
    timeStatus.Text = "10-min Window: " .. (inTimeWindow and "OPEN ✅" or "CLOSED ❌")
    timeStatus.TextColor3 = inTimeWindow and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
    return inTimeWindow
end

-- Function to update stats
local function updateStats()
    local farms = getOwnedFarms()
    local totalPlants = 0
    local totalTomatoes = 0
    
    for _, farm in ipairs(farms) do
        local plants = getPlantsFromFarm(farm)
        totalPlants += #plants
        
        for _, plant in ipairs(plants) do
            local fruits = getFruitsFromPlant(plant)
            for _, fruit in ipairs(fruits) do
                if fruit.Name == "Tomato" then
                    totalTomatoes += 1
                end
            end
        end
    end
    
    farmsText.Text = "Owned Farms: " .. #farms
    plantsText.Text = "Total Plants: " .. totalPlants
    fruitsText.Text = "Tomatoes Found: " .. totalTomatoes
end

-- Function to toggle GUI visibility
local function toggleGUI()
    isGuiVisible = not isGuiVisible
    mainFrame.Visible = isGuiVisible
    toggleButton.Text = isGuiVisible and "⬅" or "➡"
end

-- Function to start farming
local function guiStartFarming()
    getgenv().AutoFarm = true
    updateStatus("RUNNING", Color3.fromRGB(80, 255, 80))
    startAutoFarm()
end

-- Function to stop farming
local function guiStopFarming()
    getgenv().AutoFarm = false
    updateStatus("STOPPED", Color3.fromRGB(255, 80, 80))
end

-- Connect events
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    if statsUpdateConnection then
        statsUpdateConnection:Disconnect()
    end
end)

startButton.MouseButton1Click:Connect(guiStartFarming)
stopButton.MouseButton1Click:Connect(guiStopFarming)
toggleButton.MouseButton1Click:Connect(toggleGUI)

-- Make GUI draggable
local dragging = false
local dragInput, dragStart, startPos

local function updateInput(input)
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
        updateInput(input)
    end
end)

-- Start stats update loop
statsUpdateConnection = RunService.Heartbeat:Connect(function()
    updateTimeStatus()
    updateStats()
end)

-- Initial update
updateStatus("STOPPED", Color3.fromRGB(255, 80, 80))
updateTimeStatus()
updateStats()

print("AutoFarm GUI Loaded! Press the arrow button to toggle visibility.")
