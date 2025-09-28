local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Wait for player to load
local player = Players.LocalPlayer
repeat task.wait() until player.Character
local Character = player.Character
local Backpack = player.Backpack
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Remote Events
local BuySeedStock = ReplicatedStorage.GameEvents.BuySeedStock
local Plant = ReplicatedStorage.GameEvents.Plant_RE
local sellAllRemote = ReplicatedStorage.GameEvents.Sell_Inventory
local removeItem = ReplicatedStorage.GameEvents.Remove_Item

-- Game References
local FarmsFolder = Workspace.Farm
local Steven = Workspace.NPCS.Steven
local Sam = Workspace.NPCS.Sam

-- Variables
local CropsListAndStocks = {}
local wantedFruits = {}
local plantToRemove = {"None Selected"}
local plantAura = false
local AutoSellItems = 70
local shouldSell = false
local shouldAutoPlant = false
local isSelling = false
local autoBuyEnabled = false
local isBuying = false
local shopTime = 0

-- Cache System
local cache = {
    playerFarm = nil,
    lastFarmCheck = 0,
    farmCheckCooldown = 5,
    plantCache = {},
    lastPlantUpdate = 0,
    plantUpdateCooldown = 3,
    cropsOptions = {"None Selected"}
}

-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "🌱 Grow A Garden - OPTIMIZED",
    LoadingTitle = "Loading Auto Farm...",
    LoadingSubtitle = "by Sirius",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GrowAGarden",
        FileName = "AutoFarmConfig"
    },
    KeySystem = false,
    Discord = {
        Enabled = false,
        Invite = "noinvite",
        RememberJoins = true
    }
})

-- Utility Functions
local function findPlayerFarm()
    local now = tick()
    if cache.playerFarm and cache.playerFarm.Parent and (now - cache.lastFarmCheck) < cache.farmCheckCooldown then
        return cache.playerFarm
    end
    
    for _, farm in pairs(FarmsFolder:GetChildren()) do
        if farm.Important.Data.Owner.Value == player.Name then
            cache.playerFarm = farm
            cache.lastFarmCheck = now
            return farm
        end
    end
    return nil
end

local function getAllIFromDict(Dict)
    local newList = {}
    for i in pairs(Dict) do
        table.insert(newList, i)
    end
    table.insert(newList, 1, "None Selected")
    return newList
end

local function getPlantedFruitTypes()
    local now = tick()
    if (now - cache.lastPlantUpdate) < cache.plantUpdateCooldown and #cache.plantCache > 0 then
        return cache.plantCache
    end
    
    local list = {"None Selected"}
    local farm = findPlayerFarm()
    if not farm then return list end
    
    local seen = {}
    for _, plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if not seen[plant.Name] then
            seen[plant.Name] = true
            table.insert(list, plant.Name)
        end
    end
    
    cache.plantCache = list
    cache.lastPlantUpdate = now
    return list
end

-- Remove Plants System
local function removePlantsOfKind(kind)
    if not kind or kind[1] == "None Selected" then 
        Rayfield:Notify({
            Title = "❌ Error",
            Content = "Please select a plant type to remove",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        return 
    end
    
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]") or Backpack:FindFirstChild("Shovel")
    if not Shovel then
        Rayfield:Notify({
            Title = "❌ Error",
            Content = "Shovel not found in backpack!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        return
    end
    
    local farm = findPlayerFarm()
    if not farm then
        Rayfield:Notify({
            Title = "❌ Error",
            Content = "Farm not found!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        return
    end
    
    -- Equip shovel
    Shovel.Parent = Character
    task.wait(0.3)
    
    local removedCount = 0
    local plants = farm.Important.Plants_Physical:GetChildren()
    
    Rayfield:Notify({
        Title = "🔄 Removing Plants",
        Content = "Removing " .. kind[1] .. " plants...",
        Duration = 3,
        Image = "rbxassetid://4483345998"
    })
    
    for _, plant in pairs(plants) do
        if plant.Name == kind[1] and plant:FindFirstChild("Fruit_Spawn") then
            HRP.CFrame = plant.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)
            
            local success = pcall(function()
                removeItem:FireServer(plant.Fruit_Spawn)
                removedCount = removedCount + 1
            end)
            
            task.wait(0.1)
        end
    end
    
    -- Unequip shovel
    if Shovel.Parent == Character then
        Shovel.Parent = Backpack
    end
    
    Rayfield:Notify({
        Title = "✅ Success",
        Content = "Removed " .. removedCount .. " " .. kind[1] .. " plants!",
        Duration = 5,
        Image = "rbxassetid://4483345998"
    })
end

-- Shop System
local function StripPlantStock(UnstrippedStock)
    local num = string.match(UnstrippedStock, "%d+")
    return tonumber(num) or 0
end

local function getCropsListAndStock()
    local oldStock = CropsListAndStocks
    CropsListAndStocks = {}
    
    local seedShopGui = player.PlayerGui:FindFirstChild("Seed_Shop")
    if not seedShopGui then return false end
    
    local scrollingFrame = seedShopGui.Frame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return false end
    
    for _, plantGui in pairs(scrollingFrame:GetChildren()) do
        if plantGui:FindFirstChild("Main_Frame") then
            local mainFrame = plantGui.Main_Frame
            local stockText = mainFrame:FindFirstChild("Stock_Text")
            if stockText then
                local plantName = plantGui.Name
                local plantStock = StripPlantStock(stockText.Text)
                CropsListAndStocks[plantName] = plantStock
            end
        end
    end
    
    -- Update crops options
    cache.cropsOptions = getAllIFromDict(CropsListAndStocks)
    
    local isRefreshed = false
    for cropName, stock in pairs(CropsListAndStocks) do
        if oldStock[cropName] ~= stock then
            isRefreshed = true
            break
        end
    end
    
    return isRefreshed
end

-- Harvesting System
local function getPlantingBoundaries(farm)
    local offset = Vector3.new(15.2844, 0, 28.356)
    local edges = {}
    local plantingLocations = farm.Important.Plant_Locations:GetChildren()
    
    if #plantingLocations >= 2 then
        local rect1Center = plantingLocations[1].Position
        local rect2Center = plantingLocations[2].Position
        edges["1TopLeft"] = rect1Center + offset
        edges["1BottomRight"] = rect1Center - offset
        edges["2TopLeft"] = rect2Center + offset
        edges["2BottomRight"] = rect2Center - offset
    end
    
    return edges
end

local function collectPlant(plant)
    if not plant or not plant.Parent then return false end
    
    -- Try to find ProximityPrompt
    local prompt = plant:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
        return true
    end
    
    -- Check children for prompts
    for _, child in pairs(plant:GetChildren()) do
        local childPrompt = child:FindFirstChildOfClass("ProximityPrompt")
        if childPrompt then
            fireproximityprompt(childPrompt)
            return true
        end
    end
    
    return false
end

local function GetAllPlants()
    local plantsTable = {}
    local farm = findPlayerFarm()
    if not farm then return plantsTable end
    
    for _, plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if plant:FindFirstChild("Fruits") then
            for _, fruit in pairs(plant.Fruits:GetChildren()) do
                table.insert(plantsTable, fruit)
            end
        else
            table.insert(plantsTable, plant)
        end
    end
    
    return plantsTable
end

local function CollectAllPlants()
    local plants = GetAllPlants()
    if #plants == 0 then
        Rayfield:Notify({
            Title = "ℹ️ Info",
            Content = "No plants found to collect!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        return
    end
    
    Rayfield:Notify({
        Title = "🌾 Harvesting",
        Content = "Collecting " .. #plants .. " plants...",
        Duration = 3,
        Image = "rbxassetid://4483345998"
    })
    
    -- Shuffle plants for better distribution
    for i = #plants, 2, -1 do
        local j = math.random(i)
        plants[i], plants[j] = plants[j], plants[i]
    end
    
    local collected = 0
    local batchSize = 4
    
    for i = 1, #plants, batchSize do
        for j = i, math.min(i + batchSize - 1, #plants) do
            if plants[j] and plants[j].Parent then
                if collectPlant(plants[j]) then
                    collected = collected + 1
                end
            end
        end
        task.wait(0.02) -- Small delay between batches
    end
    
    Rayfield:Notify({
        Title = "✅ Harvest Complete",
        Content = "Collected " .. collected .. " plants!",
        Duration = 5,
        Image = "rbxassetid://4483345998"
    })
end

-- Auto Harvest Aura
local auraConnection
local function togglePlantAura(value)
    plantAura = value
    
    if auraConnection then
        auraConnection:Disconnect()
        auraConnection = nil
    end
    
    if value then
        Rayfield:Notify({
            Title = "🌀 Plant Aura Activated",
            Content = "Auto harvesting all plants!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        
        auraConnection = RunService.Heartbeat:Connect(function()
            local plants = GetAllPlants()
            if #plants > 0 then
                for _, plant in pairs(plants) do
                    if plant and plant.Parent then
                        collectPlant(plant)
                    end
                end
            end
        end)
    else
        Rayfield:Notify({
            Title = "🌀 Plant Aura Deactivated",
            Content = "Auto harvesting stopped!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
    end
end

-- Planting System
local function getRandomPlantingLocation(edges)
    if not edges or not edges["1TopLeft"] then 
        local farm = findPlayerFarm()
        if farm then
            return farm.Important.Plant_Locations[1].CFrame
        end
        return CFrame.new(0, 5, 0)
    end
    
    local rectangles = {
        {edges["1TopLeft"], edges["1BottomRight"]},
        {edges["2TopLeft"], edges["2BottomRight"]}
    }

    local chosen = rectangles[math.random(1, #rectangles)]
    local a, b = chosen[1], chosen[2]

    local minX, maxX = math.min(a.X, b.X), math.max(a.X, b.X)
    local minZ, maxZ = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
    local Y = 0.13552704453468323

    local randX = math.random() * (maxX - minX) + minX
    local randZ = math.random() * (maxZ - minZ) + minZ

    return CFrame.new(randX, Y, randZ)
end

local function areThereSeeds()
    for _, item in pairs(Backpack:GetChildren()) do
        if item:FindFirstChild("Seed Local Script") then
            return true
        end
    end
    return false
end

local function plantAllSeeds()
    local farm = findPlayerFarm()
    if not farm then
        Rayfield:Notify({
            Title = "❌ Error",
            Content = "Farm not found!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        return
    end
    
    if not areThereSeeds() then
        Rayfield:Notify({
            Title = "ℹ️ Info",
            Content = "No seeds found in backpack!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        return
    end
    
    Rayfield:Notify({
        Title = "🌱 Planting",
        Content = "Planting all seeds...",
        Duration = 3,
        Image = "rbxassetid://4483345998"
    })
    
    local edges = getPlantingBoundaries(farm)
    local plantedCount = 0
    local attempts = 0
    local maxAttempts = 100
    
    while areThereSeeds() and attempts < maxAttempts do
        attempts = attempts + 1
        local plantedThisRound = false
        
        for _, item in pairs(Backpack:GetChildren()) do
            if item:FindFirstChild("Seed Local Script") then
                -- Equip seed
                item.Parent = Character
                task.wait(0.1)
                
                -- Get planting location
                local location = getRandomPlantingLocation(edges)
                local seedType = item:GetAttribute("Seed")
                
                if seedType then
                    local success = pcall(function()
                        Plant:FireServer(location.Position, seedType)
                        plantedCount = plantedCount + 1
                        plantedThisRound = true
                    end)
                    
                    if not success then
                        warn("Failed to plant seed: " .. tostring(seedType))
                    end
                end
                
                task.wait(0.1)
                
                -- Unequip seed
                if item and item.Parent == Character then
                    item.Parent = Backpack
                end
            end
        end
        
        if not plantedThisRound then break end
        task.wait(0.2)
    end
    
    Rayfield:Notify({
        Title = "✅ Planting Complete",
        Content = "Planted " .. plantedCount .. " seeds!",
        Duration = 5,
        Image = "rbxassetid://4483345998"
    })
end

-- Auto Buy System
local function buyCropSeeds(cropName)
    local success, result = pcall(function()
        BuySeedStock:FireServer(cropName)
    end)
    return success
end

local function buyWantedCropSeeds()
    if #wantedFruits == 0 then
        Rayfield:Notify({
            Title = "❌ Error",
            Content = "No fruits selected to buy!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        return false
    end
    
    if isBuying then
        Rayfield:Notify({
            Title = "ℹ️ Info",
            Content = "Already buying seeds, please wait...",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        return false
    end
    
    isBuying = true
    
    local beforePos = HRP.CFrame
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    Rayfield:Notify({
        Title = "🛒 Buying Seeds",
        Content = "Going to Sam...",
        Duration = 3,
        Image = "rbxassetid://4483345998"
    })
    
    -- Go to Sam
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    task.wait(1.5)
    
    -- Face Sam
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    task.wait(0.5)
    
    local totalBought = 0
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        
        if stock > 0 then
            Rayfield:Notify({
                Title = "🛒 Buying",
                Content = "Buying " .. stock .. " " .. fruitName .. " seeds...",
                Duration = 2,
                Image = "rbxassetid://4483345998"
            })
            
            for i = 1, stock do
                if buyCropSeeds(fruitName) then
                    totalBought = totalBought + 1
                end
                task.wait(0.1) -- Small delay between purchases
            end
        else
            Rayfield:Notify({
                Title = "ℹ️ Info",
                Content = "No stock for " .. fruitName,
                Duration = 2,
                Image = "rbxassetid://4483345998"
            })
        end
    end
    
    -- Return to original position
    task.wait(0.5)
    HRP.CFrame = beforePos
    isBuying = false
    
    Rayfield:Notify({
        Title = "✅ Buying Complete",
        Content = "Bought " .. totalBought .. " seeds total!",
        Duration = 5,
        Image = "rbxassetid://4483345998"
    })
    
    return totalBought > 0
end

-- Selling System
local function sellAll()
    if isSelling then return end
    
    isSelling = true
    local beforePos = HRP.CFrame
    local itemsBefore = #Backpack:GetChildren()
    
    if itemsBefore == 0 then
        Rayfield:Notify({
            Title = "ℹ️ Info",
            Content = "No items to sell!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        isSelling = false
        return
    end
    
    Rayfield:Notify({
        Title = "💰 Selling",
        Content = "Selling " .. itemsBefore .. " items...",
        Duration = 3,
        Image = "rbxassetid://4483345998"
    })
    
    -- Go to Steven
    HRP.CFrame = Steven.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    task.wait(1.5)
    
    local startTime = tick()
    local transactions = 0
    
    -- Sell until backpack is empty or timeout
    while #Backpack:GetChildren() > 0 and tick() - startTime < 15 do
        local success = pcall(function()
            sellAllRemote:FireServer()
        end)
        
        if success then
            transactions = transactions + 1
        end
        
        task.wait(0.3) -- Delay between sell attempts
    end
    
    local itemsAfter = #Backpack:GetChildren()
    local itemsSold = itemsBefore - itemsAfter
    
    -- Return to original position
    HRP.CFrame = beforePos
    isSelling = false
    
    Rayfield:Notify({
        Title = "✅ Selling Complete",
        Content = "Sold " .. itemsSold .. " items! (" .. transactions .. " transactions)",
        Duration = 5,
        Image = "rbxassetid://4483345998"
    })
end

-- Auto Systems
local autoSellConnection
local function toggleAutoSell(value)
    shouldSell = value
    
    if autoSellConnection then
        autoSellConnection:Disconnect()
        autoSellConnection = nil
    end
    
    if value then
        Rayfield:Notify({
            Title = "💰 Auto Sell Activated",
            Content = "Will auto sell at " .. AutoSellItems .. " items",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        
        autoSellConnection = RunService.Heartbeat:Connect(function()
            if not isSelling and #Backpack:GetChildren() >= AutoSellItems then
                sellAll()
            end
        end)
    else
        Rayfield:Notify({
            Title = "💰 Auto Sell Deactivated",
            Content = "Auto selling stopped!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
    end
end

local autoPlantConnection
local function toggleAutoPlant(value)
    shouldAutoPlant = value
    
    if autoPlantConnection then
        autoPlantConnection:Disconnect()
        autoPlantConnection = nil
    end
    
    if value then
        Rayfield:Notify({
            Title = "🌱 Auto Plant Activated",
            Content = "Auto planting enabled!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
        
        autoPlantConnection = RunService.Heartbeat:Connect(function()
            if areThereSeeds() then
                plantAllSeeds()
                task.wait(2) -- Wait before checking again
            end
        end)
    else
        Rayfield:Notify({
            Title = "🌱 Auto Plant Deactivated",
            Content = "Auto planting stopped!",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
    end
end

-- Shop Monitoring
local function getTimeInSeconds(input)
    if not input then return 0 end
    local minutes = tonumber(input:match("(%d+)m")) or 0
    local seconds = tonumber(input:match("(%d+)s")) or 0
    return minutes * 60 + seconds
end

-- Create UI Tabs
local PlantsTab = Window:CreateTab("🌱 Plants", "rbxassetid://4483345998")
local SeedsTab = Window:CreateTab("🛒 Seeds", "rbxassetid://4483345998")
local SellTab = Window:CreateTab("💰 Sell", "rbxassetid://4483345998")
local PlayerTab = Window:CreateTab("👤 Player", "rbxassetid://4483345998")

-- Plants Tab
PlantsTab:CreateSection("Remove Plants")

local PlantToRemoveDropdown = PlantsTab:CreateDropdown({
    Name = "Choose Plant Type To Remove",
    Options = getPlantedFruitTypes(),
    CurrentOption = {"None Selected"},
    MultipleOptions = false,
    Callback = function(Options)
        plantToRemove = Options
    end,
})

PlantsTab:CreateButton({
    Name = "🔄 Refresh Plant List",
    Callback = function()
        cache.lastPlantUpdate = 0
        local newOptions = getPlantedFruitTypes()
        PlantToRemoveDropdown:Refresh(newOptions)
        Rayfield:Notify({
            Title = "🔄 Refreshed",
            Content = "Plant list updated!",
            Duration = 2,
            Image = "rbxassetid://4483345998"
        })
    end,
})

PlantsTab:CreateButton({
    Name = "🗑️ Remove Selected Plants",
    Callback = function()
        removePlantsOfKind(plantToRemove)
    end,
})

PlantsTab:CreateSection("Harvesting")

PlantsTab:CreateButton({
    Name = "🌾 Harvest All Plants (FAST)",
    Callback = CollectAllPlants
})

PlantsTab:CreateToggle({
    Name = "🌀 Plant Harvest Aura",
    CurrentValue = false,
    Callback = togglePlantAura,
})

PlantsTab:CreateSection("Planting")

PlantsTab:CreateButton({
    Name = "🌱 Plant All Seeds",
    Callback = plantAllSeeds
})

PlantsTab:CreateToggle({
    Name = "🌱 Auto Plant Seeds",
    CurrentValue = false,
    Callback = toggleAutoPlant,
})

-- Seeds Tab
SeedsTab:CreateSection("Seed Selection")

-- Initial crop options
getCropsListAndStock()

local FruitsDropdown = SeedsTab:CreateDropdown({
    Name = "Select Fruits To Buy",
    Options = cache.cropsOptions,
    CurrentOption = {},
    MultipleOptions = true,
    Callback = function(Options)
        wantedFruits = {}
        for _, option in ipairs(Options) do
            if option ~= "None Selected" then
                table.insert(wantedFruits, option)
            end
        end
    end,
})

SeedsTab:CreateButton({
    Name = "🔄 Refresh Seed Shop",
    Callback = function()
        getCropsListAndStock()
        FruitsDropdown:Refresh(cache.cropsOptions)
        Rayfield:Notify({
            Title = "🔄 Shop Refreshed",
            Content = "Seed list updated!",
            Duration = 2,
            Image = "rbxassetid://4483345998"
        })
    end,
})

SeedsTab:CreateSection("Auto Buy")

SeedsTab:CreateToggle({
    Name = "🛒 Enable Auto-Buy",
    CurrentValue = false,
    Callback = function(Value)
        autoBuyEnabled = Value
        Rayfield:Notify({
            Title = "🛒 Auto-Buy " .. (Value and "Enabled" or "Disabled"),
            Content = Value and "Will auto-buy selected seeds!" or "Auto-buy disabled",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
    end,
})

SeedsTab:CreateButton({
    Name = "🛒 Buy Selected Seeds Now",
    Callback = buyWantedCropSeeds,
})

-- Sell Tab
SellTab:CreateSection("Auto Selling")

SellTab:CreateToggle({
    Name = "💰 Enable Auto Sell",
    CurrentValue = false,
    Callback = toggleAutoSell,
})

SellTab:CreateSlider({
    Name = "Items Threshold For Auto Sell",
    Range = {10, 200},
    Increment = 5,
    Suffix = "Items",
    CurrentValue = 70,
    Callback = function(Value)
        AutoSellItems = Value
    end,
})

SellTab:CreateButton({
    Name = "💰 Sell All Items Now",
    Callback = sellAll,
})

SellTab:CreateSection("Inventory Info")

SellTab:CreateButton({
    Name = "📊 Check Backpack",
    Callback = function()
        local itemCount = #Backpack:GetChildren()
        Rayfield:Notify({
            Title = "📊 Backpack Info",
            Content = itemCount .. " items in backpack",
            Duration = 5,
            Image = "rbxassetid://4483345998"
        })
    end,
})

-- Player Tab
PlayerTab:CreateSection("Movement")

local WalkSpeedSlider = PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 4,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(Value)
        Humanoid.WalkSpeed = Value
    end,
})

local JumpPowerSlider = PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 10,
    Suffix = "Power",
    CurrentValue = 50,
    Callback = function(Value)
        Humanoid.JumpPower = Value
    end,
})

PlayerTab:CreateButton({
    Name = "🔄 Reset Movement",
    Callback = function()
        WalkSpeedSlider:Set(16)
        JumpPowerSlider:Set(50)
        Rayfield:Notify({
            Title = "🔄 Movement Reset",
            Content = "Speed and jump power reset to default",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
    end,
})

PlayerTab:CreateSection("Teleport")

PlayerTab:CreateButton({
    Name = "🧙‍♂️ Create TP Wand",
    Callback = function()
        local mouse = player:GetMouse()
        
        -- Remove existing TP Wand
        if Backpack:FindFirstChild("TP Wand") then
            Backpack:FindFirstChild("TP Wand"):Destroy()
        end
        if Character:FindFirstChild("TP Wand") then
            Character:FindFirstChild("TP Wand"):Destroy()
        end
        
        local TPWand = Instance.new("Tool")
        TPWand.Name = "TP Wand"
        TPWand.RequiresHandle = false
        TPWand.Parent = Backpack
        
        TPWand.Activated:Connect(function()
            HRP.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
        end)
        
        Rayfield:Notify({
            Title = "🧙‍♂️ TP Wand Created",
            Content = "Equip the wand and click to teleport!",
            Duration = 5,
            Image = "rbxassetid://4483345998"
        })
    end,
})

PlayerTab:CreateButton({
    Name = "🗑️ Remove TP Wand",
    Callback = function()
        if Backpack:FindFirstChild("TP Wand") then
            Backpack:FindFirstChild("TP Wand"):Destroy()
        end
        if Character:FindFirstChild("TP Wand") then
            Character:FindFirstChild("TP Wand"):Destroy()
        end
        Rayfield:Notify({
            Title = "🗑️ TP Wand Removed",
            Content = "Teleport wand removed from inventory",
            Duration = 3,
            Image = "rbxassetid://4483345998"
        })
    end,
})

-- Auto Shop Monitoring
task.spawn(function()
    while true do
        local refreshed = getCropsListAndStock()
        if refreshed and autoBuyEnabled and #wantedFruits > 0 and not isBuying then
            Rayfield:Notify({
                Title = "🛒 Shop Refreshed!",
                Content = "Auto-buying selected seeds...",
                Duration = 3,
                Image = "rbxassetid://4483345998"
            })
            task.wait(2)
            buyWantedCropSeeds()
        end
        task.wait(5) -- Check every 5 seconds
    end
end)

-- Character respawn handling
player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HRP = newCharacter:WaitForChild("HumanoidRootPart")
    Humanoid = newCharacter:WaitForChild("Humanoid")
    Backpack = player.Backpack
    
    -- Reset movement speeds
    WalkSpeedSlider:Set(16)
    JumpPowerSlider:Set(50)
    
    Rayfield:Notify({
        Title = "🔄 Character Respawned",
        Content = "Movement speeds reset to default",
        Duration = 3,
        Image = "rbxassetid://4483345998"
    })
end)

-- Initialization Complete
Rayfield:Notify({
    Title = "✅ Script Loaded Successfully!",
    Content = "Grow A Garden Optimized v2.0 is ready!\nPress K to toggle GUI",
    Duration = 6,
    Image = "rbxassetid://4483345998"
})

print("🎯 Grow A Garden OPTIMIZED script loaded successfully!")
print("🌱 Features: Auto Harvest, Auto Plant, Auto Buy, Auto Sell")
print("🎮 Press K to toggle the GUI")
print("⚡ Optimized for maximum performance")

-- Load completed
getCropsListAndStock()
