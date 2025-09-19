getgenv().AutoFarm = true
getgenv().SelectedFruits = {"Tomato"} -- Default hanya tomat

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local lplr = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("SummerHarvestRemoteEvent")

-- Variabel untuk mengontrol eksekusi
local isRunning = false

-- Daftar buah yang mungkin ada di game
local ALL_FRUITS = {
    "Tomato",
    "Apple",
    "Orange",
    "Lemon",
    "Watermelon",
    "Strawberry",
    "Blueberry",
    "Pineapple",
    "Mango",
    "Banana",
    "Peach",
    "Pear",
    "Grapes",
    "Cherry"
}

-- Fungsi untuk mendapatkan HumanoidRootPart
local function getHumanoidRootPart()
    if not lplr or not lplr.Character then
        return nil
    end
    
    return lplr.Character:FindFirstChild("HumanoidRootPart")
end

-- Fungsi teleport dengan pengecekan keamanan
local function teleportTo(position)
    local hrp = getHumanoidRootPart()
    if hrp then
        local success = pcall(function()
            hrp.CFrame = CFrame.new(position)
        end)
        return success
    end
    return false
end

-- Fungsi untuk menekan tombol E
local function pressEKey()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- Fungsi untuk memanen buah hingga habis
local function harvestFruitUntilGone(fruit)
    if not fruit or not fruit.PrimaryPart then return end
    
    local fruitExists = true
    local conn = fruit.AncestryChanged:Connect(function(_, parent)
        if not parent then fruitExists = false end
    end)
    
    while fruitExists and getgenv().AutoFarm do
        pressEKey()
        task.wait(0.2)
    end
    
    if conn then conn:Disconnect() end
end

-- Fungsi untuk mendapatkan farm yang dimiliki player
local function getOwnedFarms()
    local farms = {}
    local success, farmObjects = pcall(function()
        return workspace:WaitForChild("Farm"):GetChildren()
    end)
    
    if success and farmObjects then
        for _, farm in ipairs(farmObjects) do
            local isOwned = pcall(function()
                return farm.Important.Data.Owner.Value == lplr.Name
            end)
            if isOwned then
                table.insert(farms, farm)
            end
        end
    end
    return farms
end

-- Fungsi untuk mendapatkan tanaman dari farm
local function getPlantsFromFarm(farm)
    local plants = {}
    if farm and farm.Important then
        local plantsFolder = farm.Important:FindFirstChild("Plants_Physical")
        if plantsFolder then
            for _, plant in ipairs(plantsFolder:GetChildren()) do
                if plant:IsA("Model") then
                    table.insert(plants, plant)
                end
            end
        end
    end
    return plants
end

-- Fungsi untuk mendapatkan buah dari tanaman
local function getFruitsFromPlant(plant)
    local fruits = {}
    if plant then
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                if fruit:IsA("Model") and fruit.PrimaryPart then
                    table.insert(fruits, fruit)
                end
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
        pcall(function()
            hrp.CFrame = CFrame.new(-116.40152, 4.40001249, -12.4976292, 0.871914983, 0, 0.489657342, 0, 1, 0, -0.489657342, 0, 0.871914983)
            remote:FireServer("SubmitAllPlants")
        end)
    end
end

-- Fungsi utama untuk AutoFarm
local function startAutoFarm()
    if isRunning then return end
    isRunning = true
    
    while getgenv().AutoFarm do
        if not isWithinFirstTenMinutes() then
            task.wait(5)
            continue
        end
        
        local hrp = getHumanoidRootPart()
        if not hrp then
            task.wait(3)
            continue
        end
        
        local farms = getOwnedFarms()
        if #farms == 0 then
            task.wait(5)
            continue
        end
        
        for _, farm in ipairs(farms) do
            if not getgenv().AutoFarm then break end
            
            local plants = getPlantsFromFarm(farm)
            for _, plant in ipairs(plants) do
                if not getgenv().AutoFarm then break end
                
                local fruits = getFruitsFromPlant(plant)
                for _, fruit in ipairs(fruits) do
                    if not getgenv().AutoFarm then break end
                    
                    -- Cek apakah buah termasuk yang dipilih
                    if fruit and fruit.PrimaryPart and table.find(getgenv().SelectedFruits, fruit.Name) then
                        if teleportTo(fruit.PrimaryPart.Position) then
                            task.wait(0.5)
                            harvestFruitUntilGone(fruit)
                        end
                    end
                end
            end
        end
        
        if getgenv().AutoFarm then
            for i = 1, 3 do
                if not getgenv().AutoFarm then break end
                pauseAndSubmit()
                task.wait(1)
            end
        end
        
        task.wait(15)
    end
    
    isRunning = false
end

-- =============================================
-- MOBILE-FRIENDLY GUI DENGAN POSISI BAIK
-- =============================================

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileAutoFarmGUI"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

-- Main Frame (Posisi lebih bawah untuk mobile)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 450) -- Lebih pendek agar muat di mobile
mainFrame.Position = UDim2.new(0.5, -160, 0.7, -225) -- POSISI LEBIH BAWAH (70% dari atas)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Corner Radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Title Bar dengan touch area yang lebih besar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🌱 AUTO FARM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Close Button (besar untuk touch)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -45, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeButton.BorderSizePixel = 0
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 24
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 20)
closeCorner.Parent = closeButton

-- Minimize Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 40, 0, 40)
minimizeButton.Position = UDim2.new(1, -90, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
minimizeButton.BorderSizePixel = 0
minimizeButton.Text = "─"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 20
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Parent = titleBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 20)
minimizeCorner.Parent = minimizeButton

-- Content Frame dengan Scrolling
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, -10, 1, -60)
scrollFrame.Position = UDim2.new(0, 5, 0, 55)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 650) -- Diperbesar untuk konten
scrollFrame.Parent = mainFrame

-- Status Panel
local statusPanel = Instance.new("Frame")
statusPanel.Name = "StatusPanel"
statusPanel.Size = UDim2.new(1, 0, 0, 90)
statusPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
statusPanel.BorderSizePixel = 0
statusPanel.Parent = scrollFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusPanel

local statusTitle = Instance.new("TextLabel")
statusTitle.Name = "StatusTitle"
statusTitle.Size = UDim2.new(1, -20, 0, 25)
statusTitle.Position = UDim2.new(0, 10, 0, 5)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "STATUS:"
statusTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
statusTitle.TextSize = 14
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusPanel

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -20, 0, 30)
statusText.Position = UDim2.new(0, 10, 0, 30)
statusText.BackgroundTransparency = 1
statusText.Text = "STOPPED"
statusText.TextColor3 = Color3.fromRGB(255, 80, 80)
statusText.TextSize = 20
statusText.Font = Enum.Font.GothamBold
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusPanel

local timeStatus = Instance.new("TextLabel")
timeStatus.Name = "TimeStatus"
timeStatus.Size = UDim2.new(1, -20, 0, 25)
timeStatus.Position = UDim2.new(0, 10, 0, 60)
timeStatus.BackgroundTransparency = 1
timeStatus.Text = "10-min Window: Checking..."
timeStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
timeStatus.TextSize = 14
timeStatus.Font = Enum.Font.Gotham
timeStatus.TextXAlignment = Enum.TextXAlignment.Left
timeStatus.Parent = statusPanel

-- Control Buttons (Besar untuk touch mobile)
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(1, 0, 0, 60)
controlPanel.Position = UDim2.new(0, 0, 0, 100)
controlPanel.BackgroundTransparency = 1
controlPanel.Parent = scrollFrame

local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(0.45, 0, 1, 0)
startButton.Position = UDim2.new(0, 0, 0, 0)
startButton.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
startButton.BorderSizePixel = 0
startButton.Text = "▶ START"
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 16
startButton.Font = Enum.Font.GothamBold
startButton.Parent = controlPanel

local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0.45, 0, 1, 0)
stopButton.Position = UDim2.new(0.55, 0, 0, 0)
stopButton.BackgroundColor3 = Color3.fromRGB(200, 60, 80)
stopButton.BorderSizePixel = 0
stopButton.Text = "■ STOP"
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextSize = 16
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = controlPanel

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = startButton
buttonCorner:Clone().Parent = stopButton

-- Fruit Selection Panel
local fruitPanel = Instance.new("Frame")
fruitPanel.Name = "FruitPanel"
fruitPanel.Size = UDim2.new(1, 0, 0, 200)
fruitPanel.Position = UDim2.new(0, 0, 0, 170)
fruitPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
fruitPanel.BorderSizePixel = 0
fruitPanel.Parent = scrollFrame

local fruitCorner = Instance.new("UICorner")
fruitCorner.CornerRadius = UDim.new(0, 8)
fruitCorner.Parent = fruitPanel

local fruitTitle = Instance.new("TextLabel")
fruitTitle.Name = "FruitTitle"
fruitTitle.Size = UDim2.new(1, -20, 0, 25)
fruitTitle.Position = UDim2.new(0, 10, 0, 5)
fruitTitle.BackgroundTransparency = 1
fruitTitle.Text = "PILIH BUAH:"
fruitTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
fruitTitle.TextSize = 14
fruitTitle.Font = Enum.Font.GothamBold
fruitTitle.TextXAlignment = Enum.TextXAlignment.Left
fruitTitle.Parent = fruitPanel

-- Select All Button
local selectAllButton = Instance.new("TextButton")
selectAllButton.Name = "SelectAllButton"
selectAllButton.Size = UDim2.new(0.45, 0, 0, 30)
selectAllButton.Position = UDim2.new(0, 10, 0, 35)
selectAllButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
selectAllButton.BorderSizePixel = 0
selectAllButton.Text = "PILIH SEMUA"
selectAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
selectAllButton.TextSize = 12
selectAllButton.Font = Enum.Font.GothamBold
selectAllButton.Parent = fruitPanel

local selectAllCorner = Instance.new("UICorner")
selectAllCorner.CornerRadius = UDim.new(0, 6)
selectAllCorner.Parent = selectAllButton

-- Deselect All Button
local deselectAllButton = Instance.new("TextButton")
deselectAllButton.Name = "DeselectAllButton"
deselectAllButton.Size = UDim2.new(0.45, 0, 0, 30)
deselectAllButton.Position = UDim2.new(0.55, 0, 0, 35)
deselectAllButton.BackgroundColor3 = Color3.fromRGB(200, 120, 60)
deselectAllButton.BorderSizePixel = 0
deselectAllButton.Text = "BATAL SEMUA"
deselectAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
deselectAllButton.TextSize = 12
deselectAllButton.Font = Enum.Font.GothamBold
deselectAllButton.Parent = fruitPanel

local deselectAllCorner = Instance.new("UICorner")
deselectAllCorner.CornerRadius = UDim.new(0, 6)
deselectAllCorner.Parent = deselectAllButton

-- Fruit List Container
local fruitList = Instance.new("ScrollingFrame")
fruitList.Name = "FruitList"
fruitList.Size = UDim2.new(1, -20, 0, 120)
fruitList.Position = UDim2.new(0, 10, 0, 70)
fruitList.BackgroundTransparency = 1
fruitList.ScrollBarThickness = 4
fruitList.ScrollingDirection = Enum.ScrollingDirection.Y
fruitList.CanvasSize = UDim2.new(0, 0, 0, 0)
fruitList.Parent = fruitPanel

local fruitListLayout = Instance.new("UIListLayout")
fruitListLayout.Padding = UDim.new(0, 5)
fruitListLayout.Parent = fruitList

-- Stats Panel
local statsPanel = Instance.new("Frame")
statsPanel.Name = "StatsPanel"
statsPanel.Size = UDim2.new(1, 0, 0, 120)
statsPanel.Position = UDim2.new(0, 0, 0, 380)
statsPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
statsPanel.BorderSizePixel = 0
statsPanel.Parent = scrollFrame

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 8)
statsCorner.Parent = statsPanel

local statsTitle = Instance.new("TextLabel")
statsTitle.Name = "StatsTitle"
statsTitle.Size = UDim2.new(1, -20, 0, 25)
statsTitle.Position = UDim2.new(0, 10, 0, 5)
statsTitle.BackgroundTransparency = 1
statsTitle.Text = "STATISTIK:"
statsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
statsTitle.TextSize = 14
statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextXAlignment = Enum.TextXAlignment.Left
statsTitle.Parent = statsPanel

local farmsText = Instance.new("TextLabel")
farmsText.Name = "FarmsText"
farmsText.Size = UDim2.new(1, -20, 0, 20)
farmsText.Position = UDim2.new(0, 10, 0, 35)
farmsText.BackgroundTransparency = 1
farmsText.Text = "Farm: 0"
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
plantsText.Text = "Tanaman: 0"
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
fruitsText.Text = "Buah: 0"
fruitsText.TextColor3 = Color3.fromRGB(255, 255, 255)
fruitsText.TextSize = 14
fruitsText.Font = Enum.Font.Gotham
fruitsText.TextXAlignment = Enum.TextXAlignment.Left
fruitsText.Parent = statsPanel

-- Toggle Button untuk mobile (besar dan mudah diakses)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 60, 0, 60)
toggleButton.Position = UDim2.new(0, 20, 0, 20) -- POSISI DI BAWAH KIRI
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "🌱"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 24
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 30)
toggleCorner.Parent = toggleButton

-- =============================================
-- GUI FUNCTIONALITY
-- =============================================

local isGuiVisible = true
local statsUpdateConnection

-- Fungsi untuk update status
local function updateStatus(text, color)
    statusText.Text = text
    statusText.TextColor3 = color
end

-- Fungsi untuk update time status
local function updateTimeStatus()
    local inTimeWindow = isWithinFirstTenMinutes()
    timeStatus.Text = "10-menit: " .. (inTimeWindow and "BUKA ✅" or "TUTUP ❌")
    timeStatus.TextColor3 = inTimeWindow and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
    return inTimeWindow
end

-- Fungsi untuk update stats
local function updateStats()
    local farms = getOwnedFarms()
    local totalPlants = 0
    local totalFruits = 0
    
    for _, farm in ipairs(farms) do
        local plants = getPlantsFromFarm(farm)
        totalPlants += #plants
        
        for _, plant in ipairs(plants) do
            local fruits = getFruitsFromPlant(plant)
            totalFruits += #fruits
        end
    end
    
    farmsText.Text = "Farm: " .. #farms
    plantsText.Text = "Tanaman: " .. totalPlants
    fruitsText.Text = "Buah: " .. totalFruits
end

-- Fungsi untuk toggle GUI visibility
local function toggleGUI()
    isGuiVisible = not isGuiVisible
    mainFrame.Visible = isGuiVisible
    toggleButton.Text = isGuiVisible and "❌" or "🌱"
end

-- Fungsi untuk membuat fruit buttons
local function createFruitButtons()
    fruitList:ClearAllChildren()
    
    for _, fruitName in ipairs(ALL_FRUITS) do
        local fruitButton = Instance.new("TextButton")
        fruitButton.Name = fruitName
        fruitButton.Size = UDim2.new(1, 0, 0, 30)
        fruitButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        fruitButton.BorderSizePixel = 0
        fruitButton.Text = fruitName
        fruitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        fruitButton.TextSize = 14
        fruitButton.Font = Enum.Font.Gotham
        fruitButton.Parent = fruitList
        
        local fruitCorner = Instance.new("UICorner")
        fruitCorner.CornerRadius = UDim.new(0, 6)
        fruitCorner.Parent = fruitButton
        
        -- Update tampilan berdasarkan selection
        if table.find(getgenv().SelectedFruits, fruitName) then
            fruitButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        end
        
        -- Toggle selection on click
        fruitButton.MouseButton1Click:Connect(function()
            if table.find(getgenv().SelectedFruits, fruitName) then
                table.remove(getgenv().SelectedFruits, table.find(getgenv().SelectedFruits, fruitName))
                fruitButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            else
                table.insert(getgenv().SelectedFruits, fruitName)
                fruitButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
            end
        end)
    end
    
    -- Update canvas size
    fruitList.CanvasSize = UDim2.new(0, 0, 0, #ALL_FRUITS * 35)
end

-- Fungsi untuk select semua buah
local function selectAllFruits()
    getgenv().SelectedFruits = {}
    for _, fruitName in ipairs(ALL_FRUITS) do
        table.insert(getgenv().SelectedFruits, fruitName)
    end
    createFruitButtons()
end

-- Fungsi untuk deselect semua buah
local function deselectAllFruits()
    getgenv().SelectedFruits = {}
    createFruitButtons()
end

-- Fungsi untuk start farming
local function guiStartFarming()
    getgenv().AutoFarm = true
    updateStatus("JALAN", Color3.fromRGB(80, 255, 80))
    task.spawn(startAutoFarm)
end

-- Fungsi untuk stop farming
local function guiStopFarming()
    getgenv().AutoFarm = false
    updateStatus("BERHENTI", Color3.fromRGB(255, 80, 80))
end

-- Connect events
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    if statsUpdateConnection then
        statsUpdateConnection:Disconnect()
    end
end)

minimizeButton.MouseButton1Click:Connect(toggleGUI)
startButton.MouseButton1Click:Connect(guiStartFarming)
stopButton.MouseButton1Click:Connect(guiStopFarming)
toggleButton.MouseButton1Click:Connect(toggleGUI)
selectAllButton.MouseButton1Click:Connect(selectAllFruits)
deselectAllButton.MouseButton1Click:Connect(deselectAllFruits)

-- Buat fruit buttons
createFruitButtons()

-- Start stats update loop
statsUpdateConnection = RunService.Heartbeat:Connect(function()
    updateTimeStatus()
    updateStats()
end)

-- Initial update
updateStatus("BERHENTI", Color3.fromRGB(255, 80, 80))
updateTimeStatus()
updateStats()

-- Fitur drag untuk memindahkan GUI
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

print("Mobile AutoFarm GUI Loaded! Tap the plant icon to toggle visibility.")
