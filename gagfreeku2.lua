local plr = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local sellPos = CFrame.new(90.08035, 0.98381, 3.02662, 6e-05, 1e-06, 1, -0.0349, 0.999, 1e-06, -0.999, -0.0349, 6e-05)

-- Load Reyframe UI Library
local Reyframe = loadstring(game:HttpGet("https://raw.githubusercontent.com/ReyScript-Hub/Rey-hub/main/Ui%20Lib"))()

-- Create window
local Window = Reyframe:CreateWindow({
   Name = "SheScripts Gag",
   LoadingTitle = "SheScripts Gag",
   LoadingSubtitle = "by SheScripts",
   ConfigurationSaving = {
      Enabled = false
   },
   Discord = {
      Enabled = false
   }
})

-- Create sell tab
local SellTab = Window:CreateTab("Sell Items", nil)

-- Create sell section
local SellSection = SellTab:CreateSection("Sell Options")

-- Sell inventory button
SellSection:CreateButton("Sell Inventory", function()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local orig = hrp.CFrame
        hrp.CFrame = sellPos
        task.wait(0.1)
        rs.GameEvents.Sell_Inventory:FireServer()
        task.wait(0.1)
        hrp.CFrame = orig
        
        -- Show notification
        Reyframe:Notify({
            Title = "Success",
            Content = "Inventory sold successfully!",
            Duration = 3
        })
    end
end)

-- Sell item in hand button
SellSection:CreateButton("Sell Item in Hand", function()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local orig = hrp.CFrame
        hrp.CFrame = sellPos
        task.wait(0.1)
        rs.GameEvents.Sell_Item:FireServer()
        task.wait(0.1)
        hrp.CFrame = orig
        
        -- Show notification
        Reyframe:Notify({
            Title = "Success",
            Content = "Item in hand sold successfully!",
            Duration = 3
        })
    end
end)

-- Create settings tab
local SettingsTab = Window:CreateTab("Settings", nil)

-- Create settings section
local SettingsSection = SettingsTab:CreateSection("Configuration")

-- Toggle UI keybind
SettingsSection:CreateKeybind("Toggle UI", "RightShift", function(Key)
    Window:ChangeToggleKey(Key)
end)

-- UI color picker
SettingsSection:CreateColorpicker("UI Color", Color3.fromRGB(235, 64, 52), function(Color)
    Window:ChangeColor(Color)
end)

-- Create info section
local InfoSection = SettingsTab:CreateSection("Information")

-- Info label
InfoSection:CreateLabel("Script created by SheScripts")
InfoSection:CreateLabel("UI designed with Reyframe Library")

-- Initialize UI
Window:SelectTab(1)
