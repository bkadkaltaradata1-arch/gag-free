local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmsFolder = Workspace.Farm
local Players = game:GetService("Players")
local BuySeedStock = ReplicatedStorage.GameEvents.BuySeedStock
local Plant = ReplicatedStorage.GameEvents.Plant_RE
local Backpack = Players.LocalPlayer.Backpack
local Character = Players.LocalPlayer.Character
local sellAllRemote = ReplicatedStorage.GameEvents.Sell_Inventory
local Steven = Workspace.NPCS.Steven
local Sam = Workspace.NPCS.Sam
local HRP = Players.LocalPlayer.Character.HumanoidRootPart
local CropsListAndStocks = {}
local shopTime = 0
local Humanoid = Character:WaitForChild("Humanoid")
wantedFruits = {}
local plantAura = false
local AutoSellItems = 70
local shouldSell = false
local removeItem = ReplicatedStorage.GameEvents.Remove_Item
local plantToRemove
local shouldAutoPlant = false
local isSelling = false
local byteNetReliable = ReplicatedStorage:FindFirstChild("ByteNetReliable")
local autoBuyEnabled = false
local lastShopStock = {}
local isBuying = false

-- Load Rayfield safely
local Rayfield = nil
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Failed to load Rayfield: " .. tostring(err))
    return
end

local Window = Rayfield:CreateWindow({
   Name = "Grow A Garden",
   Icon = 0,
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by Sirius",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "GAGscript"
   },
})

local function findPlayerFarm()
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important.Data.Owner.Value == Players.LocalPlayer.Name then
            return v
        end
    end
    return nil
end

-- ... (kode lainnya tetap sama sampai bagian bawah) ...

-- Function to find and click on Blueberry seed in the shop
local function selectBlueberrySeed()
    wait(2) -- Wait longer for shop to fully load
    
    local seedShopGui = Players.LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop")
    if not seedShopGui then
        print("Seed_Shop GUI not found")
        return false
    end
    
    local scrollingFrame = seedShopGui.Frame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then
        print("ScrollingFrame not found")
        return false
    end
    
    -- Debug: Print all children in scrolling frame
    print("Items in shop:")
    for _, item in pairs(scrollingFrame:GetChildren()) do
        if item:IsA("Frame") then
            print(" - " .. item.Name)
        end
    end
    
    -- Look for Blueberry in the shop items
    local blueberryFrame = scrollingFrame:FindFirstChild("Blueberry")
    if not blueberryFrame then
        print("Blueberry frame not found, trying alternative names...")
        -- Try alternative names
        blueberryFrame = scrollingFrame:FindFirstChild("Blueberries") or scrollingFrame:FindFirstChild("BlueberrySeed")
        if not blueberryFrame then
            print("Blueberry not found with any name")
            return false
        end
    end
    
    print("Found Blueberry frame:", blueberryFrame.Name)
    
    -- Find the buy button - try different possible names
    local buyButton = blueberryFrame:FindFirstChild("Buy_Button") or 
                     blueberryFrame:FindFirstChild("BuyButton") or
                     blueberryFrame:FindFirstChild("PurchaseButton") or
                     blueberryFrame:FindFirstChild("Button")
    
    if not buyButton then
        print("Buy button not found, searching in children...")
        -- Search for any button-like object
        for _, child in pairs(blueberryFrame:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("ImageButton") then
                buyButton = child
                break
            end
        end
    end
    
    if not buyButton then
        print("No buy button found in Blueberry frame")
        return false
    end
    
    print("Found buy button:", buyButton.Name)
    
    -- Try different methods to click the button
    local clickMethods = {
        function() 
            -- Method 1: Fire mouse click event
            if buyButton:IsA("TextButton") or buyButton:IsA("ImageButton") then
                buyButton:FireEvent("MouseButton1Click")
                return true
            end
            return false
        end,
        function()
            -- Method 2: Use remote event if available
            local remote = buyButton:FindFirstChildWhichIsA("RemoteEvent")
            if remote then
                remote:FireServer()
                return true
            end
            return false
        end,
        function()
            -- Method 3: Directly call the click function
            if buyButton:FindFirstChild("Click") then
                buyButton.Click:Fire()
                return true
            end
            return false
        end,
        function()
            -- Method 4: Use mouse simulation
            local mouse = game:GetService("Players").LocalPlayer:GetMouse()
            local originalPos = mouse.Hit
            mouse.TargetFilter = buyButton
            wait(0.1)
            mouse.TargetFilter = nil
            return true
        end
    }
    
    for i, method in ipairs(clickMethods) do
        local success, result = pcall(method)
        if success and result then
            print("Successfully selected Blueberry seed using method " .. i)
            return true
        end
        wait(0.2)
    end
    
    print("All click methods failed")
    return false
end

-- Function to teleport to Sam and open the shop
local function teleportToSamAndOpenShop()
    local originalPosition = HRP.CFrame
    
    -- Teleport to Sam
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    wait(1.5)
    
    -- Make sure we're facing Sam
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    wait(0.5)
    
    -- Activate the shop by firing proximity prompt
    local foundPrompt = false
    for _, part in pairs(Sam:GetChildren()) do
        if part:IsA("BasePart") and part:FindFirstChild("ProximityPrompt") then
            fireproximityprompt(part.ProximityPrompt)
            foundPrompt = true
            print("Opened Sam's shop")
            break
        end
    end
    
    if foundPrompt then
        -- Wait for the shop to open
        wait(3) -- Wait longer for shop to fully load
        
        -- Select Blueberry seed
        selectBlueberrySeed()
    else
        print("Could not find ProximityPrompt on Sam")
        
        -- Alternative method: try to open shop via remote event
        local shopRemote = ReplicatedStorage:FindFirstChild("OpenShop") or 
                          ReplicatedStorage:FindFirstChild("OpenSeedShop")
        if shopRemote then
            pcall(function() shopRemote:FireServer() end)
            wait(3)
            selectBlueberrySeed()
        end
    end
    
    -- Return to original position after a delay
    wait(2)
    HRP.CFrame = originalPosition
end

-- Function to directly buy blueberry seeds without opening GUI
local function buyBlueberrySeedsDirectly()
    local args = {[1] = "Blueberry"}
    local success, errorMsg = pcall(function()
        BuySeedStock:FireServer(unpack(args))
    end)
    
    if success then
        print("Successfully bought Blueberry seeds directly")
        return true
    else
        print("Error buying Blueberry seeds directly:", errorMsg)
        return false
    end
end

-- Add button untuk langsung beli blueberry tanpa buka GUI
seedsTab:CreateButton({
    Name = "Buy Blueberry Seeds Directly",
    Callback = function()
        buyBlueberrySeedsDirectly()
    end,
})

-- Add teleport to Sam and open shop button
seedsTab:CreateButton({
    Name = "Teleport to Sam & Open Shop (Select Blueberry)",
    Callback = function()
        teleportToSamAndOpenShop()
    end,
})

-- ... (kode lainnya tetap sama) ...
