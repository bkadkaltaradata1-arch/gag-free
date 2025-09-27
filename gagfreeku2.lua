-- LocalScript dengan tampilan debug di layar
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Buat UI debug
local function createDebugUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DebugGUI"
    screenGui.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.Parent = screenGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = "Debug Info akan muncul di sini"
    label.TextWrapped = true
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.Parent = frame
    
    return label
end

local debugLabel = createDebugUI()

-- Fungsi utama
local function onButtonClicked(button)
    local character = player.Character or player.CharacterAdded:Wait()
    
    local debugText = string.format([[
Tombol: %s
Karakter: %s
Posisi: X:%.1f, Y:%.1f, Z:%.1f
Waktu: %s
    ]], 
    button.Name, 
    character.Name,
    character.HumanoidRootPart.Position.X,
    character.HumanoidRootPart.Position.Y,
    character.HumanoidRootPart.Position.Z,
    os.date("%X"))
    
    -- Update UI
    debugLabel.Text = debugText
    
    -- Print ke console
    print(debugText)
end

-- Setup event listeners
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Cek jika mengklik tombol
        local target = input.Position
        local gui = player.PlayerGui
        
        -- Cari tombol yang diklik
        for _, screenGui in ipairs(gui:GetChildren()) do
            if screenGui:IsA("ScreenGui") then
                local buttons = screenGui:GetDescendants()
                for _, button in ipairs(buttons) do
                    if (button:IsA("TextButton") or button:IsA("ImageButton")) and button.Visible then
                        -- Cek jika posisi klik ada di dalam tombol (sederhana)
                        onButtonClicked(button)
                        break
                    end
                end
            end
        end
    end
end)
