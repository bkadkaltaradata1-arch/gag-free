--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local fruitNames = {"apple", "cactus", "candy blossom", "coconut", "dragon fruit", "easter egg", "grape", "mango", "peach", "pineapple", "blue berry"}
local activeTweens = {}
local function createRainbowTween(label)
    local colors = {
        Color3.new(1, 0, 0),
        Color3.new(1, 0.5, 0),
        Color3.new(1, 1, 0),
        Color3.new(0, 1, 0),
        Color3.new(0, 0, 1),
        Color3.new(0.5, 0, 1),
        Color3.new(1, 0, 1)
    }
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
    if activeTweens[label] then
        activeTweens[label]:Cancel()
        activeTweens[label] = nil
    end
    spawn(function()
        while true do
            for _, color in ipairs(colors) do
                local tween = TweenService:Create(label, tweenInfo, {TextColor3 = color})
                activeTweens[label] = tween
                tween:Play()
                tween.Completed:Wait()
            end
        end
    end)
end
local function updateFruits()
    for _, fruit in pairs(workspace:GetDescendants()) do
        if table.find(fruitNames, fruit.Name:lower()) then
            local weight = fruit:FindFirstChild("Weight")
            local variant = fruit:FindFirstChild("Variant")
            if weight and weight:IsA("NumberValue") then
                local weightValue = math.floor(weight.Value)
                local variantValue = variant and variant:IsA("StringValue") and variant.Value or "Normal"
                local shouldDisplay = (fruit.Name:lower() == "blue berry") or (variantValue == "Gold") or (variantValue == "Rainbow") or (weight.Value > 20)
                local textColor = (variantValue == "Gold" and Color3.new(1, 1, 0)) or Color3.new(0, 0, 1)
                if shouldDisplay then
                    local billboard = fruit:FindFirstChild("WeightDisplay")
                    local maxDistance = 50 + (weightValue * 2)
                    if not billboard then
                        billboard = Instance.new("BillboardGui")
                        billboard.Name = "WeightDisplay"
                        billboard.Parent = fruit
                        billboard.Adornee = fruit
                        billboard.Size = UDim2.new(0, 100, 0, 50)
                        billboard.MaxDistance = maxDistance
                        billboard.StudsOffset = Vector3.new(0, 2, 0)
                        billboard.AlwaysOnTop = true
                        local frame = Instance.new("Frame")
                        frame.Parent = billboard
                        frame.Size = UDim2.new(1, 0, 1, 0)
                        frame.BackgroundTransparency = 1
                        local shadowLabel = Instance.new("TextLabel")
                        shadowLabel.Name = "ShadowLabel"
                        shadowLabel.Parent = frame
                        shadowLabel.Position = UDim2.new(0, 2, 0, 2)
                        shadowLabel.Size = UDim2.new(1, -2, 0.7, -2)
                        shadowLabel.BackgroundTransparency = 1
                        shadowLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
                        shadowLabel.TextScaled = true
                        shadowLabel.Text = tostring(weightValue)
                        local mainLabel = Instance.new("TextLabel")
                        mainLabel.Name = "MainLabel"
                        mainLabel.Parent = frame
                        mainLabel.Position = UDim2.new(0, 0, 0, 0)
                        mainLabel.Size = UDim2.new(1, 0, 0.7, 0)
                        mainLabel.BackgroundTransparency = 1
                        mainLabel.TextColor3 = textColor
                        mainLabel.TextScaled = true
                        mainLabel.Text = tostring(weightValue)
                        local variantLabel = Instance.new("TextLabel")
                        variantLabel.Name = "VariantLabel"
                        variantLabel.Parent = frame
                        variantLabel.Position = UDim2.new(0, 0, 0.7, 0)
                        variantLabel.Size = UDim2.new(1, 0, 0.3, 0)
                        variantLabel.BackgroundTransparency = 1
                        variantLabel.TextColor3 = textColor
                        variantLabel.TextScaled = true
                        variantLabel.Text = variantValue ~= "Normal" and variantValue or ""
                        billboard.Destroying:Connect(function()
                            if activeTweens[mainLabel] then
                                activeTweens[mainLabel]:Cancel()
                                activeTweens[mainLabel] = nil
                            end
                            if activeTweens[variantLabel] then
                                activeTweens[variantLabel]:Cancel()
                                activeTweens[variantLabel] = nil
                            end
                        end)
                        if variantValue == "Rainbow" then
                            createRainbowTween(mainLabel)
                            createRainbowTween(variantLabel)
                        end
                    else
                        billboard.MaxDistance = maxDistance
                        local frame = billboard:FindFirstChild("Frame")
                        if frame then
                            local shadowLabel = frame:FindFirstChild("ShadowLabel")
                            local mainLabel = frame:FindFirstChild("MainLabel")
                            local variantLabel = frame:FindFirstChild("VariantLabel")
                            if shadowLabel and mainLabel and variantLabel then
                                shadowLabel.Text = tostring(weightValue)
                                mainLabel.Text = tostring(weightValue)
                                mainLabel.TextColor3 = textColor
                                variantLabel.Text = variantValue ~= "Normal" and variantValue or ""
                                variantLabel.TextColor3 = textColor
                                if variantValue == "Rainbow" then
                                    createRainbowTween(mainLabel)
                                    createRainbowTween(variantLabel)
                                end
                            end
                        end
                    end
                else
                    local billboard = fruit:FindFirstChild("WeightDisplay")
                    if billboard then
                        billboard:Destroy()
                    end
                end
                if not fruit:FindFirstChild("ClickDetector") then
                    local clickDetector = Instance.new("ClickDetector")
                    clickDetector.Parent = fruit
                    clickDetector.MouseClick:Connect(function()
                        spawn(function()
                            local tempBillboard = Instance.new("BillboardGui")
                            tempBillboard.Name = "TempWeightDisplay"
                            tempBillboard.Parent = fruit
                            tempBillboard.Adornee = fruit
                            tempBillboard.Size = UDim2.new(0, 100, 0, 50)
                            tempBillboard.MaxDistance = 50 + (weightValue * 2)
                            tempBillboard.StudsOffset = Vector3.new(0, 3, 0)
                            tempBillboard.AlwaysOnTop = true
                            local frame = Instance.new("Frame")
                            frame.Parent = tempBillboard
                            frame.Size = UDim2.new(1, 0, 1, 0)
                            frame.BackgroundTransparency = 1
                            local shadowLabel = Instance.new("TextLabel")
                            shadowLabel.Name = "ShadowLabel"
                            shadowLabel.Parent = frame
                            shadowLabel.Position = UDim2.new(0, 2, 0, 2)
                            shadowLabel.Size = UDim2.new(1, -2, 0.7, -2)
                            shadowLabel.BackgroundTransparency = 1
                            shadowLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
                            shadowLabel.TextScaled = true
                            shadowLabel.Text = string.format("%.1f", weight.Value)
                            local mainLabel = Instance.new("TextLabel")
                            mainLabel.Name = "MainLabel"
                            mainLabel.Parent = frame
                            mainLabel.Position = UDim2.new(0, 0, 0, 0)
                            mainLabel.Size = UDim2.new(1, 0, 0.7, 0)
                            mainLabel.BackgroundTransparency = 1
                            mainLabel.TextColor3 = textColor
                            mainLabel.TextScaled = true
                            mainLabel.Text = string.format("%.1f", weight.Value)
                            local variantLabel = Instance.new("TextLabel")
                            variantLabel.Name = "VariantLabel"
                            variantLabel.Parent = frame
                            variantLabel.Position = UDim2.new(0, 0, 0.7, 0)
                            variantLabel.Size = UDim2.new(1, 0, 0.3, 0)
                            variantLabel.BackgroundTransparency = 1
                            variantLabel.TextColor3 = textColor
                            variantLabel.TextScaled = true
                            variantLabel.Text = variantValue
                            if variantValue == "Rainbow" then
                                createRainbowTween(mainLabel)
                                createRainbowTween(variantLabel)
                            end
                            wait(3)
                            local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
                            for _, label in pairs({shadowLabel, mainLabel, variantLabel}) do
                                local tween = TweenService:Create(label, tweenInfo, {TextTransparency = 1})
                                tween:Play()
                                activeTweens[label] = tween
                            end
                            tween.Completed:Wait()
                            for _, label in pairs({shadowLabel, mainLabel, variantLabel}) do
                                if activeTweens[label] then
                                    activeTweens[label]:Cancel()
                                    activeTweens[label] = nil
                                end
                            end
                            tempBillboard:Destroy()
                        end)
                    end)
                end
            end
        end
    end
end
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer.PlayerGui
local updateButton = Instance.new("TextButton")
updateButton.Size = UDim2.new(0, 50, 0, 50)
updateButton.Position = UDim2.new(0, 10, 0, 10)
updateButton.BackgroundColor3 = Color3.new(0, 0, 1)
updateButton.Text = "🔄"
updateButton.Parent = screenGui
local dragging = false
local dragStart = nil
local startPos = nil
updateButton.MouseButton1Click:Connect(updateFruits)
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local buttonPos = updateButton.AbsolutePosition
        local buttonSize = updateButton.AbsoluteSize
        if mousePos.X >= buttonPos.X and mousePos.X <= buttonPos.X + buttonSize.X and
           mousePos.Y >= buttonPos.Y and mousePos.Y <= buttonPos.Y + buttonSize.Y then
            dragging = true
            dragStart = input.Position
            startPos = updateButton.Position
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        updateButton.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
updateFruits()
