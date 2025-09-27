local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Remote Events
local BuySeedStock = ReplicatedStorage.GameEvents.BuySeedStock
local Plant = ReplicatedStorage.GameEvents.Plant_RE
local sellAllRemote = ReplicatedStorage.GameEvents.Sell_Inventory
local removeItem = ReplicatedStorage.GameEvents.Remove_Item

-- References
local FarmsFolder = Workspace.Farm
local Backpack = Players.LocalPlayer.Backpack
local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local Steven = Workspace.NPCS.Steven
local Sam = Workspace.NPCS.Sam
local SeedShopGUI = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Seed_Shop").Frame.ScrollingFrame
local shopTimer = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame.Frame.Timer

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

-- Cache untuk optimasi
local cache = {
    playerFarm = nil,
    lastFarmCheck = 0,
    farmCheckCooldown = 3,
    plantCache = {},
    lastPlantUpdate = 0,
    plantUpdateCooldown = 2
}

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Grow A Garden - OPTIMIZED",
   LoadingTitle = "Loading Interface...",
   LoadingSubtitle = "by Sirius",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "GAGScript",
      FileName = "Config"
   },
   KeySystem = false,
})

-- Fungsi dasar
local function findPlayerFarm()
    local now = tick()
    if cache.playerFarm and cache.playerFarm.Parent and (now - cache.lastFarmCheck) < cache.farmCheckCooldown then
        return cache.playerFarm
    end
    
    for _, farm in pairs(FarmsFolder:GetChildren()) do
        if farm.Important.Data.Owner.Value == Players.LocalPlayer.Name then
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
    return newList
end

local function isInTable(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function getPlantedFruitTypes()
    local now = tick()
    if (now - cache.lastPlantUpdate) < cache.plantUpdateCooldown and #cache.plantCache > 0 then
        return cache.plantCache
    end
    
    local list = {}
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
            Title = "Error",
            Content = "Please select a plant type to remove",
            Duration = 3
        })
        return 
    end
    
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]") or Backpack:FindFirstChild("Shovel")
    if not Shovel then
        Rayfield:Notify({
            Title = "Error",
            Content = "Shovel not found in backpack",
            Duration = 3
        })
        return
    end
    
    Shovel.Parent = Character
    task.wait(0.2)
    
    local farm = findPlayerFarm()
    if not farm then return end
    
    local removedCount = 0
    for _, plant in pairs(farm.Important.Plants_Physical:GetChildren()) do
        if plant.Name == kind[1] and plant:FindFirstChild("Fruit_Spawn") then
            HRP.CFrame = plant.PrimaryPart.CFrame
            task.wait(0.1)
            pcall(function()
                removeItem:FireServer(plant.Fruit_Spawn)
                removedCount = removedCount + 1
            end)
            task.wait(0.05)
        end
    end 
    
    if Shovel.Parent == Character then
        Shovel.Parent = Backpack
    end
    
    Rayfield:Notify({
        Title = "Success",
        Content = "Removed " .. removedCount .. " " .. kind[1] .. " plants",
        Duration = 3
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
    
    for _, plantGui in pairs(SeedShopGUI:GetChildren()) do
        if plantGui:FindFirstChild("Main_Frame") and plantGui.Main_Frame:FindFirstChild("Stock_Text") then
            local plantName = plantGui.Name
            local plantStock = StripPlantStock(plantGui.Main_Frame.Stock_Text.Text)
            CropsListAndStocks[plantName] = plantStock
        end
    end
    
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
    local PlantingLocations = farm.Important.Plant_Locations:GetChildren()
    
    if #PlantingLocations >= 2 then
        local rect1Center = PlantingLocations[1].Position
        local rect2Center = PlantingLocations[2].Position
        edges["1TopLeft"] = rect1Center + offset
        edges["1BottomRight"] = rect1Center - offset
        edges["2TopLeft"] = rect2Center + offset
        edges["2BottomRight"] = rect2Center - offset
    end
    
    return edges
end

local function collectPlant(plant)
    if not plant or not plant.Parent then return end
    
    -- Cari ProximityPrompt di plant atau children-nya
    local prompt = plant:FindFirstChild("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
        return
    end
    
    for _, child in pairs(plant:GetChildren()) do
        local childPrompt = child:FindFirstChild("ProximityPrompt")
        if childPrompt then
            fireproximityprompt(childPrompt)
            break
        end
    end
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
            Title = "Info",
            Content = "No plants found to collect",
            Duration = 3
        })
        return
    end
    
    Rayfield:Notify({
        Title = "Harvesting",
        Content = "Collecting " .. #plants .. " plants...",
        Duration = 3
    })
    
    -- Shuffle plants untuk menghindari pattern yang sama
    for i = #plants, 2, -1 do
        local j = math.random(i)
        plants[i], plants[j] = plants[j], plants[i]
    end
    
    -- Process plants in batches untuk kecepatan
    local batchSize = 5
    for i = 1, #plants, batchSize do
        for j = i, math.min(i + batchSize - 1, #plants) do
            if plants[j] and plants[j].Parent then
                collectPlant(plants[j])
            end
        end
        task.wait(0.02) -- Small delay between batches
    end
    
    Rayfield:Notify({
        Title = "Success",
        Content = "Finished collecting plants!",
        Duration = 3
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
        
        Rayfield:Notify({
            Title = "Plant Aura",
            Content = "Plant Aura activated!",
            Duration = 3
        })
    else
        Rayfield:Notify({
            Title = "Plant Aura",
            Content = "Plant Aura deactivated!",
            Duration = 3
        })
    end
end

-- Planting System
local function getRandomPlantingLocation(edges)
    if not edges or not edges["1TopLeft"] then 
        return CFrame.new(0, 0, 0)
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
            Title = "Error",
            Content = "Farm not found!",
            Duration = 3
        })
        return
    end
    
    if not areThereSeeds() then
        Rayfield:Notify({
            Title = "Info",
            Content = "No seeds found in backpack",
            Duration = 3
        })
        return
    end
    
    Rayfield:Notify({
        Title = "Planting",
        Content = "Planting all seeds...",
        Duration = 3
    })
    
    local edges = getPlantingBoundaries(farm)
    local plantedCount = 0
    
    while areThereSeeds() do
        local plantedThisRound = false
        
        for _, item in pairs(Backpack:GetChildren()) do
            if item:FindFirstChild("Seed Local Script") then
                item.Parent = Character
                task.wait(0.1)
                
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
                
                if item and item.Parent == Character then
                    item.Parent = Backpack
                end
            end
        end
        
        if not plantedThisRound then break end
        task.wait(0.2)
    end
    
    Rayfield:Notify({
        Title = "Success",
        Content = "Planted " .. plantedCount .. " seeds!",
        Duration = 3
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
            Title = "Error",
            Content = "No fruits selected to buy",
            Duration = 3
        })
        return false
    end
    
    if isBuying then
        Rayfield:Notify({
            Title = "Info",
            Content = "Already buying seeds, please wait...",
            Duration = 3
        })
        return false
    end
    
    isBuying = true
    
    local beforePos = HRP.CFrame
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    -- Go to Sam
    HRP.CFrame = Sam.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    task.wait(1.5)
    
    HRP.CFrame = CFrame.new(HRP.Position, Sam.HumanoidRootPart.Position)
    task.wait(0.5)
    
    local totalBought = 0
    
    for _, fruitName in ipairs(wantedFruits) do
        local stock = tonumber(CropsListAndStocks[fruitName] or 0)
        
        if stock > 0 then
            Rayfield:Notify({
                Title = "Buying",
                Content = "Buying " .. stock .. " " .. fruitName .. " seeds...",
                Duration = 2
            })
            
            for i = 1, stock do
                if buyCropSeeds(fruitName) then
                    totalBought = totalBought + 1
                end
                task.wait(0.15)
            end
        end
    end
    
    -- Return to original position
    task.wait(0.5)
    HRP.CFrame = beforePos
    isBuying = false
    
    Rayfield:Notify({
        Title = "Success",
        Content = "Bought " .. totalBought .. " seeds total!",
        Duration = 3
    })
    
    return totalBought > 0
end

-- Selling System
local function sellAll()
    if isSelling then return end
    
    isSelling = true
    local beforePos = HRP.CFrame
    
    Rayfield:Notify({
        Title = "Selling",
        Content = "Selling all items...",
        Duration = 3
    })
    
    -- Go to Steven
    HRP.CFrame = Steven.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
    task.wait(1.5)
    
    local startTime = tick()
    local itemsSold = 0
    
    -- Sell until backpack is empty or timeout
    while #Backpack:GetChildren() > 0 and tick() - startTime < 10 do
        sellAllRemote:FireServer()
        itemsSold = itemsSold + 1
        task.wait(0.3)
    end
    
    -- Return to original position
    HRP.CFrame = beforePos
    isSelling = false
    
    Rayfield:Notify({
        Title = "Success",
        Content = "Sold all items! (" .. itemsSold .. " transactions)",
        Duration = 3
    })
end

-- Auto Sell System
local autoSellConnection
local function toggleAutoSell(value)
    shouldSell = value
    
    if autoSellConnection then
        autoSellConnection:Disconnect()
        autoSellConnection = nil
    end
    
    if value then
        autoSellConnection = RunService.Heartbeat:Connect(function()
            if not isSelling and #Backpack:GetChildren() >= AutoSellItems then
                sellAll()
            end
        end)
        
        Rayfield:Notify({
            Title = "Auto Sell",
            Content = "Auto Sell activated! Threshold: " .. AutoSellItems .. " items",
            Duration = 3
        })
    else
        Rayfield:Notify({
            Title = "Auto Sell",
            Content = "Auto Sell deactivated!",
            Duration = 3
        })
    end
end

-- Auto Plant System
local autoPlantConnection
local function toggleAutoPlant(value)
    shouldAutoPlant = value
    
    if autoPlantConnection then
        autoPlantConnection:Disconnect()
        autoPlantConnection = nil
    end
    
    if value then
        autoPlantConnection = RunService.Heartbeat:Connect(function()
            if areThereSeeds() then
                plantAllSeeds()
            end
        end)
        
        Rayfield:Notify({
            Title = "Auto Plant",
            Content = "Auto Plant activated!",
            Duration = 3
        })
    else
        Rayfield:Notify({
            Title = "Auto Plant",
            Content = "Auto Plant deactivated!",
            Duration = 3
        })
    end
end

-- Shop Monitoring System
local function getTimeInSeconds(input)
    if not input then return 0 end
    local minutes = tonumber(input:match("(%d+)m")) or 0
    local seconds = tonumber(input:match("(%d+)s")) or 0
    return minutes * 60 + seconds
end

local shopMonitorConnection
local function monitorShop()
    if shopMonitorConnection then
        shopMonitorConnection:Disconnect()
    end
    
    shopMonitorConnection = RunService.Heartbeat:Connect(function()
        if shopTimer and shopTimer.Text then
            shopTime = getTimeInSeconds(shopTimer.Text)
        end
        
        -- Check for shop refresh and auto-buy
        local isRefreshed = getCropsListAndStock()
        if isRefreshed and autoBuyEnabled and #wantedFruits > 0 and not isBuying then
            task.wait(2) -- Wait for UI to update
            buyWantedCropSeeds()
        end
    end)
end

-- UI Creation
local Tab = Window:CreateTab("Plants", "rbxassetid://4483345998")

Tab:CreateSection("Remove Plants")

local PlantToRemoveDropdown = Tab:CreateDropdown({
   Name = "Choose A Plant To Remove",
   Options = getPlantedFruitTypes(),
   CurrentOption = {"None Selected"},
   MultipleOptions = false,
   Callback = function(Options)
        plantToRemove = Options
   end,
})

Tab:CreateButton({
    Name = "Refresh Selection",
    Callback = function()
        cache.lastPlantUpdate = 0
        PlantToRemoveDropdown:Refresh(getPlantedFruitTypes())
    end,
})

Tab:CreateButton({
    Name = "Remove Selected Plant",
    Callback = function()
        removePlantsOfKind(plantToRemove)
    end,
})

Tab:CreateSection("Harvesting Plants")

Tab:CreateButton({
    Name = "Collect All Plants (FAST)",
    Callback = CollectAllPlants
})

Tab:CreateToggle({
   Name = "Harvest Plants Aura (OPTIMIZED)",
   CurrentValue = false,
   Callback = togglePlantAura,
})

Tab:CreateSection("Planting")

Tab:CreateButton({
    Name = "Plant All Seeds (FAST)",
    Callback = plantAllSeeds
})

Tab:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = false,
    Callback = toggleAutoPlant,
})

local SeedsTab = Window:CreateTab("Seeds", "rbxassetid://4483345998")

SeedsTab:CreateDropdown({
   Name = "Fruits To Buy",
   Options = getAllIFromDict(CropsListAndStocks),
   CurrentOption = {},
   MultipleOptions = true,
   Callback = function(Options)
        wantedFruits = Options
   end,
})

SeedsTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Callback = function(Value)
        autoBuyEnabled = Value
        Rayfield:Notify({
            Title = "Auto-Buy",
            Content = "Auto-Buy " .. (Value and "enabled" or "disabled"),
            Duration = 3
        })
    end,
})

SeedsTab:CreateButton({
    Name = "Buy Selected Fruits Now",
    Callback = buyWantedCropSeeds,
})

local SellTab = Window:CreateTab("Sell", "rbxassetid://4483345998")

SellTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Callback = toggleAutoSell,
})

SellTab:CreateSlider({
   Name = "Minimum Items to Auto Sell",
   Range = {1, 200},
   Increment = 1,
   Suffix = "Items",
   CurrentValue = 70,
   Callback = function(Value)
        AutoSellItems = Value
   end,
})

SellTab:CreateButton({
    Name = "Sell All Now",
    Callback = sellAll,
})

local PlayerTab = Window:CreateTab("Player", "rbxassetid://4483345998")

local speedSlider = PlayerTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 200},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = 16,
   Callback = function(Value)
        Humanoid.WalkSpeed = Value
   end,
})

local jumpSlider = PlayerTab:CreateSlider({
   Name = "Jump Power",
   Range = {50, 200},
   Increment = 5,
   Suffix = "Jump Power",
   CurrentValue = 50,
   Callback = function(Value)
        Humanoid.JumpPower = Value
   end,
})

PlayerTab:CreateButton({
    Name = "Reset Speed",
    Callback = function()
        speedSlider:Set(16)
        jumpSlider:Set(50)
    end,
})

PlayerTab:CreateButton({
    Name = "TP Wand (Equip to Teleport)",
    Callback = function()
        local mouse = Players.LocalPlayer:GetMouse()
        local TPWand = Instance.new("Tool")
        TPWand.Name = "TP Wand"
        TPWand.RequiresHandle = false
        TPWand.Parent = Backpack
        
        TPWand.Activated:Connect(function()
            HRP.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
        end)
    end,
})

-- Initialize
getCropsListAndStock()
monitorShop()

Rayfield:Notify({
    Title = "Script Loaded",
    Content = "Grow A Garden Optimized v2.0 loaded successfully!",
    Duration = 5
})

print("Grow A Garden OPTIMIZED script loaded successfully!")
