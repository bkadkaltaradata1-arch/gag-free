local plr = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local sellPos = CFrame.new(90.08035, 0.98381, 3.02662, 6e-05, 1e-06, 1, -0.0349, 0.999, 1e-06, -0.999, -0.0349, 6e-05)

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

local f = Instance.new("Frame", gui)
f.Size = UDim2.fromOffset(160, 110)
f.Position = UDim2.new(0.5, -80, 0.6, -55)
f.BackgroundColor3 = Color3.fromRGB(235, 64, 52)
f.Active, f.Draggable = true, true
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

local lbl = Instance.new("TextLabel", f)
lbl.Size = UDim2.new(1, 0, 0.25, 0)
lbl.BackgroundTransparency = 1
lbl.Text = "SheScripts Gag"
lbl.TextColor3 = Color3.new(1, 1, 1)
lbl.Font = Enum.Font.GothamBold
lbl.TextScaled = true

local function makeButton(text, y)
  local b = Instance.new("TextButton", f)
  b.Size = UDim2.new(0.85, 0, 0.3, 0)
  b.Position = UDim2.new(0.075, 0, y, 0)
  b.BackgroundColor3 = Color3.fromRGB(255, 214, 10)
  b.Text = text
  b.TextColor3 = Color3.new(0, 0, 0)
  b.Font = Enum.Font.GothamSemibold
  b.TextScaled = true
  Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
  return b
end

local btnAll = makeButton("Sell Inventory", 0.35)
local btnHand = makeButton("Sell item in hand", 0.68)

btnAll.MouseButton1Click:Connect(function()
  local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  if hrp then
    local orig = hrp.CFrame
    hrp.CFrame = sellPos
    task.wait(0.1)
    rs.GameEvents.Sell_Inventory:FireServer()
    task.wait(0.1)
    hrp.CFrame = orig
  end
end)

btnHand.MouseButton1Click:Connect(function()
  local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  if hrp then
    local orig = hrp.CFrame
    hrp.CFrame = sellPos
    task.wait(0.1)
    rs.GameEvents.Sell_Item:FireServer()
    task.wait(0.1)
    hrp.CFrame = orig
  end
end)
