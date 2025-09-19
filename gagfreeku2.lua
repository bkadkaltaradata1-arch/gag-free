getgenv().AutoFarm = true
getgenv().SelectedFruits = {"Tomato"} -- Default tomat

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

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

-- Fungsi teleport
local function teleportTo(position)
    local hrp = getHumanoidRootPart()
    if hrp then
        pcall(function()
            hrp.CFrame = CFrame.new(position)
        end)
    end
end

-- Fungsi untuk menekan tombol E
local function pressEKey()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- Fungsi untuk memanen buah
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

-- Fungsi untuk mendapatkan farm yang dimiliki
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

-- Fungsi untuk submit tanaman
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
                    
                    if fruit and fruit.PrimaryPart and table.find(getgenv().SelectedFruits, fruit.Name) then
                        teleportTo(fruit.PrimaryPart.Position)
                        task.wait(0.5)
                        harvestFruitUntilGone(fruit)
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
-- GUI SEDERHANA UNTUK ANDROID
-- =============================================

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleAutoFarmGUI"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame (Posisi di bawah)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.9, 0, 0, 350) -- Lebar 90%, tinggi 350
mainFrame.Position = UDim2.new(0.5, 0, 1, -360) -- POSISI DI BAWAH
mainFrame.AnchorPoint = Vector2.new(0.5, 1) -- Anchor di bawah
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Corner Radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Title Bar sederhana
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🌱 AUTO FARM"
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
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 14
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

-- Content Frame
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -10, 1, -50)
content.Position = UDim2.new(0, 5, 0, 45)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Status Bar sederhana
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(1, 0, 0, 40)
statusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
statusFrame.BorderSizePixel = 0
statusFrame.Parent = content

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusFrame

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(0.6, 0, 1, 0)
statusText.Position = UDim2.new(0, 10, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "BERHENTI"
statusText.TextColor3 = Color3.fromRGB(255, 80, 80)
statusText.TextSize = 14
statusText.Font = Enum.Font.GothamBold
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusFrame

local timeStatus = Instance.new("TextLabel")
timeStatus.Name = "TimeStatus"
timeStatus.Size = UDim2.new(0.35, 0, 1, 0)
timeStatus.Position = UDim2.new(0.65, 0, 0, 0)
timeStatus.BackgroundTransparency = 1
timeStatus.Text = "10m: ❌"
timeStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
timeStatus.TextSize = 12
timeStatus.Font = Enum.Font.Gotham
timeStatus.TextXAlignment = Enum.TextXAlignment.Right
timeStatus.Parent = statusFrame

-- Control Buttons
local controlFrame = Instance.new("Frame")
controlFrame.Name = "ControlFrame"
controlFrame.Size = UDim2.new(1, 0, 0, 50)
controlFrame.Position = UDim2.new(0, 0, 0, 50)
controlFrame.BackgroundTransparency = 1
controlFrame.Parent = content

local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(0.48, 0, 1, 0)
startButton.Position = UDim2.new(0, 0, 0, 0)
startButton.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
startButton.BorderSizePixel = 0
startButton.Text = "▶ START"
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 14
startButton.Font = Enum.Font.GothamBold
startButton.Parent = controlFrame

local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0.48, 0, 1, 0)
stopButton.Position = UDim2.new(0.52, 0, 0, 0)
stopButton.BackgroundColor3 = Color3.fromRGB(180, 60, 80)
stopButton.BorderSizePixel = 0
stopButton.Text = "■ STOP"
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = controlFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = startButton
buttonCorner:Clone().Parent = stopButton

-- Fruit Selection (Sederhana - Checkbox style)
local fruitFrame = Instance.new("Frame")
fruitFrame.Name = "FruitFrame"
fruitFrame.Size = UDim2.new(1, 0, 0, 150)
fruitFrame.Position = UDim2.new(0, 0, 0, 110)
fruitFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
fruitFrame.BorderSizePixel = 0
fruitFrame.Parent = content

local fruitCorner = Instance.new("UICorner")
fruitCorner.CornerRadius = UDim.new(0, 6)
fruitCorner.Parent = fruitFrame

local fruitTitle = Instance.new("TextLabel")
fruitTitle.Name = "FruitTitle"
fruitTitle.Size = UDim2.new(1, -10, 0, 25)
fruitTitle.Position = UDim2.new(0, 5, 0, 5)
fruitTitle.BackgroundTransparency = 1
fruitTitle.Text = "PILIH BUAH:"
fruitTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
fruitTitle.TextSize = 12
fruitTitle.Font = Enum.Font.GothamBold
fruitTitle.TextXAlignment = Enum.TextXAlignment.Left
fruitTitle.Parent = fruitFrame

-- Fruit Selection Grid
local fruitGrid = Instance.new("UIGridLayout")
fruitGrid.Name = "FruitGrid"
fruitGrid.CellSize = UDim2.new(0.3, 0, 0, 25)
fruitGrid.CellPadding = UDim2.new(0, 5, 0, 5)
fruitGrid.StartCorner = Enum.StartCorner.TopLeft
fruitGrid.SortOrder = Enum.SortOrder.LayoutOrder
fruitGrid.Parent = fruitFrame

-- Buat checkbox untuk setiap buah
for i, fruitName in ipairs(ALL_FRUITS) do
    local fruitCheck = Instance.new("TextButton")
    fruitCheck.Name = fruitName
    fruitCheck.Size = UDim2.new(0, 100, 0, 25)
    fruitCheck.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    fruitCheck.BorderSizePixel = 0
    fruitCheck.Text = fruitName
    fruitCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
    fruitCheck.TextSize = 11
    fruitCheck.Font = Enum.Font.Gotham
    fruitCheck.LayoutOrder = i
    fruitCheck.Parent = fruitFrame
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 4)
    checkCorner.Parent = fruitCheck
    
    -- Set selected state
    if table.find(getgenv().SelectedFruits, fruitName) then
        fruitCheck.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    end
    
    -- Toggle selection
    fruitCheck.MouseButton1Click:Connect(function()
        if table.find(getgenv().SelectedFruits, fruitName) then
            table.remove(getgenv().SelectedFruits, table.find(getgenv().SelectedFruits, fruitName))
            fruitCheck.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        else
            table.insert(getgenv().SelectedFruits, fruitName)
            fruitCheck.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        end
    end)
end

-- Quick Select Buttons
local quickSelectFrame = Instance.new("Frame")
quickSelectFrame.Name = "QuickSelectFrame"
quickSelectFrame.Size = UDim2.new(1, 0, 0, 30)
quickSelectFrame.Position = UDim2.new(0, 0, 0, 270)
quickSelectFrame.BackgroundTransparency = 1
quickSelectFrame.Parent = content

local selectAllBtn = Instance.new("TextButton")
selectAllBtn.Name = "SelectAllBtn"
selectAllBtn.Size = UDim2.new(0.48, 0, 1, 0)
selectAllBtn.Position = UDim2.new(0, 0, 0, 0)
selectAllBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
selectAllBtn.BorderSizePixel = 0
selectAllBtn.Text = "PILIH SEMUA"
selectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
selectAllBtn.TextSize = 12
selectAllBtn.Font = Enum.Font.Gotham
selectAllBtn.Parent = quickSelectFrame

local deselectAllBtn = Instance.new("TextButton")
deselectAllBtn.Name = "DeselectAllBtn"
deselectAllBtn.Size = UDim2.new(0.48, 0, 1, 0)
deselectAllBtn.Position = UDim2.new(0.52, 0, 0, 0)
deselectAllBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 60)
deselectAllBtn.BorderSizePixel = 0
deselectAllBtn.Text = "BATAL SEMUA"
deselectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deselectAllBtn.TextSize = 12
deselectAllBtn.Font = Enum.Font.Gotham
deselectAllBtn.Parent = quickSelectFrame

local quickCorner = Instance.new("UICorner")
quickCorner.CornerRadius = UDim.new(0, 4)
quickCorner.Parent = selectAllBtn
quickCorner:Clone().Parent = deselectAllBtn

-- Toggle Button (Sederhana)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 20, 1, -60) -- Posisi di bawah kiri
toggleButton.AnchorPoint = Vector2.new(0, 1)
toggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "🌱"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 20
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 25)
toggleCorner.Parent = toggleButton

-- =============================================
-- GUI FUNCTIONALITY
-- =============================================

local isGuiVisible = true

-- Fungsi untuk update status
local function updateStatus(text, color)
    statusText.Text = text
    statusText.TextColor3 = color
end

-- Fungsi untuk update time status
local function updateTimeStatus()
    local inTimeWindow = isWithinFirstTenMinutes()
    timeStatus.Text = "10m: " .. (inTimeWindow and "✅" or "❌")
    timeStatus.TextColor3 = inTimeWindow and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
end

-- Fungsi untuk toggle GUI visibility
local function toggleGUI()
    isGuiVisible = not isGuiVisible
    mainFrame.Visible = isGuiVisible
    toggleButton.Text = isGuiVisible and "❌" or "🌱"
end

-- Fungsi untuk select semua buah
local function selectAllFruits()
    getgenv().SelectedFruits = {}
    for _, fruitName in ipairs(ALL_FRUITS) do
        table.insert(getgenv().SelectedFruits, fruitName)
        local button = fruitFrame:FindFirstChild(fruitName)
        if button then
            button.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        end
    end
end

-- Fungsi untuk deselect semua buah
local function deselectAllFruits()
    getgenv().SelectedFruits = {}
    for _, fruitName in ipairs(ALL_FRUITS) do
        local button = fruitFrame:FindFirstChild(fruitName)
        if button then
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        end
    end
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
end)

startButton.MouseButton1Click:Connect(guiStartFarming)
stopButton.MouseButton1Click:Connect(guiStopFarming)
toggleButton.MouseButton1Click:Connect(toggleGUI)
selectAllBtn.MouseButton1Click:Connect(selectAllFruits)
deselectAllBtn.MouseButton1Click:Connect(deselectAllFruits)

-- Update time status setiap 5 detik
task.spawn(function()
    while true do
        updateTimeStatus()
        task.wait(5)
    end
end)

-- Initial state
updateStatus("BERHENTI", Color3.fromRGB(255, 80, 80))
updateTimeStatus()

print("Simple AutoFarm GUI Loaded! Tap the plant icon to toggle.")
