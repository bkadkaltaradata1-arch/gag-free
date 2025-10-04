[file name]: PVP1.txt
[file content begin]
-- Auto Pet Seller & Buyer - One Click Farm Script
-- Automatically enables all functions for farming

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    MIN_WEIGHT_TO_KEEP = 300, -- Minimum weight to keep a pet
    MAX_WEIGHT_TO_KEEP = 50000, -- Maximum weight to keep a pet
    SELL_DELAY = 0.01, -- Delay between sales
    BUY_DELAY = 0.01, -- Delay between purchases
    BUY_INTERVAL = 2, -- Interval between buy cycles (seconds)
    COLLECT_INTERVAL = 60, -- Coin collection interval (seconds)
    REPLACE_INTERVAL = 30, -- Brainrot replacement interval (seconds)
    PLANT_INTERVAL = 10, -- Plant planting interval (seconds)
    WATER_INTERVAL = 5, -- Plant watering interval (seconds)
    PLATFORM_BUY_INTERVAL = 120, -- Platform purchase interval (seconds)
    LOG_COPY_KEY = Enum.KeyCode.F4, -- Key for copying logs
    AUTO_BUY_SEEDS = true, -- Auto-buy seeds
    AUTO_BUY_GEAR = true, -- Auto-buy items
    AUTO_COLLECT_COINS = true, -- Auto-collect coins
    AUTO_REPLACE_BRAINROTS = true, -- Auto-replace brainrots
    AUTO_PLANT_SEEDS = true, -- Auto-plant seeds
    AUTO_WATER_PLANTS = true, -- Auto-water plants
    AUTO_BUY_PLATFORMS = true, -- Auto-buy platforms
    DEBUG_COLLECT_COINS = true, -- Debug messages for coin collection
    DEBUG_PLANTING = true, -- Debug messages for planting
    SMART_SELLING = true, -- Smart selling system (adaptive)
}

-- Pet rarities in ascending order
local RARITY_ORDER = {
    ["Rare"] = 1,
    ["Epic"] = 2,
    ["Legendary"] = 3,
    ["Mythic"] = 4,
    ["Godly"] = 5,
    ["Secret"] = 6,
    ["Limited"] = 7
}

-- Variables
local logs = {}
local itemSellRemote = nil
local dataRemoteEvent = nil
local useItemRemote = nil
local openEggRemote = nil
local playerData = nil
local protectedPet = nil -- Protected pet from selling (in hand for replacement)
local petAnalysis = nil -- Analysis of current pet state
local currentPlot = nil -- Current player plot
local plantedSeeds = {} -- Tracking planted seeds
local diagnosticsRun = false -- Flag for running diagnostics

-- Codes for input
local CODES = {
    "based",
    "stacks",
    "frozen"
}

-- Seeds for purchase
local SEEDS = {
    "Cactus Seed",
    "Strawberry Seed", 
    "Sunflower Seed",
    "Pumpkin Seed",
    "Dragon Fruit Seed",
    "Eggplant Seed",
    "Watermelon Seed",
    "Grape Seed",
    "Cocotank Seed",
    "Carnivorous Plant Seed",
    "Mr Carrot Seed",
    "Tomatrio Seed",
    "Shroombino Seed"
}

-- Items from Gear Shop
local GEAR_ITEMS = {
    "Water Bucket",
    "Frost Blower",
    "Frost Grenade",
    "Carrot Launcher",
    "Banana Gun"
}

-- Protected items (do not sell)
local PROTECTED_ITEMS = {
    "Meme Lucky Egg",
    "Godly Lucky Egg",
    "Secret Lucky Egg"
}


-- Initialization
local function initialize()
    print("Initializing Auto Pet Seller & Buyer...")
    
    -- Wait for necessary services
    itemSellRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ItemSell")
    dataRemoteEvent = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")
    useItemRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem")
    openEggRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("OpenEgg")
    
    -- Initialize PlayerData
    local success, result = pcall(function()
        playerData = require(ReplicatedStorage:WaitForChild("PlayerData"))
    end)
    
    if success then
        print("✅ PlayerData initialized successfully")
    else
        print("❌ PlayerData initialization error: " .. tostring(result))
        playerData = nil
    end
    
    -- Get current plot
    local plotNumber = LocalPlayer:GetAttribute("Plot")
    if plotNumber then
        currentPlot = workspace.Plots:FindFirstChild(tostring(plotNumber))
        if currentPlot then
            print("Found plot: " .. plotNumber)
        else
            print("Plot " .. plotNumber .. " not found in workspace.Plots")
        end
    else
        print("Plot attribute not found on player")
    end
    
    print("Initialization completed!")
end

-- Get pet weight from name
local function getPetWeight(petName)
    local weight = petName:match("%[(%d+%.?%d*)%s*kg%]")
    return weight and tonumber(weight) or 0
end

-- Get pet rarity
local function getPetRarity(pet)
    local petData = pet:FindFirstChild(pet.Name)
    if not petData then
        -- Try to find by name without weight and mutations
        local cleanName = pet.Name:gsub("%[.*%]%s*", "")
        petData = pet:FindFirstChild(cleanName)
    end
    
    if not petData then
        -- Look for any child object with Rarity attribute
        for _, child in pairs(pet:GetChildren()) do
            if child:GetAttribute("Rarity") then
                petData = child
                break
            end
        end
    end
    
    if petData then
        return petData:GetAttribute("Rarity") or "Rare"
    end
    
    return "Rare"
end

-- Check for protected mutations
local function hasProtectedMutations(petName)
    return petName:find("%[Neon%]") or petName:find("%[Galactic%]")
end

-- Check for protected items
local function isProtectedItem(itemName)
    for _, protected in pairs(PROTECTED_ITEMS) do
        if itemName:find(protected) then
            return true
        end
    end
    return false
end

-- Get pet information
local function getPetInfo(pet)
    local petData = pet:FindFirstChild(pet.Name)
    if not petData then
        local cleanName = pet.Name:gsub("%[.*%]%s*", "")
        petData = pet:FindFirstChild(cleanName)
    end
    
    if not petData then
        for _, child in pairs(pet:GetChildren()) do
            if child:GetAttribute("Rarity") then
                petData = child
                break
            end
        end
    end
    
    -- Get MoneyPerSecond from UI
    local moneyPerSecond = 0
    if petData then
        local rootPart = petData:FindFirstChild("RootPart")
        if rootPart then
            local brainrotToolUI = rootPart:FindFirstChild("BrainrotToolUI")
            if brainrotToolUI then
                local moneyLabel = brainrotToolUI:FindFirstChild("Money")
                if moneyLabel then
                    -- Parse MoneyPerSecond from text like "$1,234/s"
                    local moneyText = moneyLabel.Text
                    local moneyValue = moneyText:match("%$(%d+,?%d*)/s")
                    if moneyValue then
                        -- Remove commas and convert to number
                        local cleanValue = moneyValue:gsub(",", "")
                        moneyPerSecond = tonumber(cleanValue) or 0
                    end
                end
            end
        end
    end
    
    if petData then
        return {
            name = pet.Name,
            weight = getPetWeight(pet.Name),
            rarity = petData:GetAttribute("Rarity") or "Rare",
            worth = petData:GetAttribute("Worth") or 0,
            size = petData:GetAttribute("Size") or 1,
            offset = petData:GetAttribute("Offset") or 0,
            moneyPerSecond = moneyPerSecond
        }
    end
    
    return {
        name = pet.Name,
        weight = getPetWeight(pet.Name),
        rarity = "Rare",
        worth = 0,
        size = 1,
        offset = 0,
        moneyPerSecond = moneyPerSecond
    }
end

-- Get best brainrot from inventory (for checking)
local function getBestBrainrotForReplacement()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local bestBrainrot = nil
    local bestMoneyPerSecond = 0
    
    for _, pet in pairs(backpack:GetChildren()) do
        if pet:IsA("Tool") and pet.Name:match("%[%d+%.?%d*%s*kg%]") then
            local petInfo = getPetInfo(pet)
            local moneyPerSecond = petInfo.moneyPerSecond
            
            if moneyPerSecond > bestMoneyPerSecond then
                bestMoneyPerSecond = moneyPerSecond
                bestBrainrot = pet
            end
        end
    end
    
    return bestBrainrot, bestMoneyPerSecond
end

-- Analyze current pet state
local function analyzePets()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local analysis = {
        totalPets = 0,
        petsByRarity = {},
        petsByMoneyPerSecond = {},
        bestMoneyPerSecond = 0,
        worstMoneyPerSecond = math.huge,
        averageMoneyPerSecond = 0,
        totalMoneyPerSecond = 0,
        shouldSellRare = false,
        shouldSellEpic = false,
        shouldSellLegendary = false,
        minMoneyPerSecondToKeep = 0
    }
    
    -- Collect data on all pets
    for _, pet in pairs(backpack:GetChildren()) do
        if pet:IsA("Tool") and pet.Name:match("%[%d+%.?%d*%s*kg%]") then
            local petInfo = getPetInfo(pet)
            local rarity = petInfo.rarity
            local moneyPerSecond = petInfo.moneyPerSecond
            
            analysis.totalPets = analysis.totalPets + 1
            analysis.totalMoneyPerSecond = analysis.totalMoneyPerSecond + moneyPerSecond
            
            -- Group by rarity
            if not analysis.petsByRarity[rarity] then
                analysis.petsByRarity[rarity] = 0
            end
            analysis.petsByRarity[rarity] = analysis.petsByRarity[rarity] + 1
            
            -- Track best and worst MoneyPerSecond
            if moneyPerSecond > analysis.bestMoneyPerSecond then
                analysis.bestMoneyPerSecond = moneyPerSecond
            end
            if moneyPerSecond < analysis.worstMoneyPerSecond then
                analysis.worstMoneyPerSecond = moneyPerSecond
            end
            
            -- Group by MoneyPerSecond
            table.insert(analysis.petsByMoneyPerSecond, {
                pet = pet,
                moneyPerSecond = moneyPerSecond,
                rarity = rarity
            })
        end
    end
    
    -- Sort by MoneyPerSecond
    table.sort(analysis.petsByMoneyPerSecond, function(a, b)
        return a.moneyPerSecond > b.moneyPerSecond
    end)
    
    -- Calculate average MoneyPerSecond
    if analysis.totalPets > 0 then
        analysis.averageMoneyPerSecond = analysis.totalMoneyPerSecond / analysis.totalPets
    end
    
    -- Smart logic to determine what to sell
    if analysis.totalPets > 0 then
        -- If we have few pets (less than 10), sell only the worst ones
        if analysis.totalPets < 10 then
            analysis.minMoneyPerSecondToKeep = analysis.averageMoneyPerSecond * 0.5 -- Keep only top 50%
            analysis.shouldSellRare = false
            analysis.shouldSellEpic = false
            analysis.shouldSellLegendary = false
        -- If we have medium number of pets (10-20), start selling Rare
        elseif analysis.totalPets < 20 then
            analysis.minMoneyPerSecondToKeep = analysis.averageMoneyPerSecond * 0.7
            analysis.shouldSellRare = true
            analysis.shouldSellEpic = false
            analysis.shouldSellLegendary = false
        -- If we have many pets (20+), sell Rare and Epic
        else
            analysis.minMoneyPerSecondToKeep = analysis.averageMoneyPerSecond * 0.8
            analysis.shouldSellRare = true
            analysis.shouldSellEpic = true
            analysis.shouldSellLegendary = false
        end
        
        -- Additional check: if we have very good pets, we can sell Legendary too
        if analysis.bestMoneyPerSecond > analysis.averageMoneyPerSecond * 2 then
            analysis.shouldSellLegendary = true
        end
        
        -- Special logic for mutations: if we have many pets with mutations, we can sell the bad ones
        local mutationPets = 0
        for _, petData in pairs(analysis.petsByMoneyPerSecond) do
            if hasProtectedMutations(petData.pet.Name) then
                mutationPets = mutationPets + 1
            end
        end
        
        -- If we have many pets with mutations (more than 5), we can sell bad ones with mutations
        if mutationPets > 5 then
            analysis.shouldSellEpic = true -- Allow selling Epic with mutations
            if analysis.totalPets > 25 then
                analysis.shouldSellLegendary = true -- And Legendary too
            end
        end
    end
    
    return analysis
end

-- Determine if a pet should be sold (smart system)
local function shouldSellPet(pet)
    local petName = pet.Name
    local weight = getPetWeight(petName)
    local rarity = getPetRarity(pet)
    local rarityValue = RARITY_ORDER[rarity] or 0
    local petInfo = getPetInfo(pet)
    
    -- Don't sell protected pet (the one in hand for replacement)
    if protectedPet and pet == protectedPet then
        return false
    end
    
    -- Don't sell protected items
    if isProtectedItem(petName) then
        return false
    end
    
    -- Don't sell heavy pets
    if weight >= CONFIG.MIN_WEIGHT_TO_KEEP then
        return false
    end
    
    -- Don't sell high rarities (Mythic and above)
    if rarityValue > RARITY_ORDER["Legendary"] then
        return false
    end
    
    -- If smart system is disabled, use old logic
    if not CONFIG.SMART_SELLING then
        -- Old logic: don't sell Legendary with mutations and brainrots with high MoneyPerSecond
        if rarity == "Legendary" and hasProtectedMutations(petName) then
            return false
        end
        if petInfo.moneyPerSecond > 100 then
            return false
        end
        return true
    end
    
    -- Smart system: use pet analysis
    if not petAnalysis then
        petAnalysis = analyzePets()
    end
    
    -- Check by MoneyPerSecond
    if petInfo.moneyPerSecond >= petAnalysis.minMoneyPerSecondToKeep then
        return false
    end
    
    -- Check by rarity (only if analysis says we can sell this rarity)
    if rarity == "Rare" and not petAnalysis.shouldSellRare then
        return false
    elseif rarity == "Epic" and not petAnalysis.shouldSellEpic then
        return false
    elseif rarity == "Legendary" and not petAnalysis.shouldSellLegendary then
        return false
    end
    
    -- In smart system, do NOT automatically protect mutations - let analysis decide
    -- Only if they are very rare mutations (Neon/Galactic), then protect
    if hasProtectedMutations(petName) and (rarity == "Mythic" or rarity == "Godly" or rarity == "Secret") then
        return false
    end
    
    return true
end

-- Sell pet
local function sellPet(pet)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    -- Equip pet before selling
    humanoid:EquipTool(pet)
    wait(0.1) -- Wait for pet to be equipped
    
    -- Sell pet
    itemSellRemote:FireServer(pet)
    
    return true
end

-- Get best brainrot from inventory
local function getBestBrainrotFromInventory()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local bestBrainrot = nil
    local bestMoneyPerSecond = 0
    
    for _, pet in pairs(backpack:GetChildren()) do
        if pet:IsA("Tool") and pet.Name:match("%[%d+%.?%d*%s*kg%]") then
            local petInfo = getPetInfo(pet)
            local moneyPerSecond = petInfo.moneyPerSecond
            
            -- Compare by MoneyPerSecond
            if moneyPerSecond > bestMoneyPerSecond then
                bestMoneyPerSecond = moneyPerSecond
                bestBrainrot = {
                    tool = pet,
                    name = pet.Name,
                    rarity = petInfo.rarity,
                    size = petInfo.size,
                    worth = petInfo.worth,
                    moneyPerSecond = moneyPerSecond
                }
            end
        end
    end
    
    return bestBrainrot
end

-- Auto-sell pets
local function autoSellPets()
    local success, error = pcall(function()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local soldCount = 0
        local keptCount = 0
        
        -- Update pet analysis before selling
        petAnalysis = analyzePets()
        
        -- Show analysis information
        if CONFIG.SMART_SELLING and petAnalysis.totalPets > 0 then
            -- Count pets with mutations
            local mutationPets = 0
            for _, petData in pairs(petAnalysis.petsByMoneyPerSecond) do
                if hasProtectedMutations(petData.pet.Name) then
                    mutationPets = mutationPets + 1
                end
            end
            
            print("=== PET ANALYSIS ===")
            print("Total pets: " .. petAnalysis.totalPets)
            print("Pets with mutations: " .. mutationPets)
            print("Average MoneyPerSecond: " .. math.floor(petAnalysis.averageMoneyPerSecond))
            print("Best MoneyPerSecond: " .. petAnalysis.bestMoneyPerSecond)
            print("Minimum to keep: " .. math.floor(petAnalysis.minMoneyPerSecondToKeep))
            print("Sell Rare: " .. (petAnalysis.shouldSellRare and "YES" or "NO"))
            print("Sell Epic: " .. (petAnalysis.shouldSellEpic and "YES" or "NO"))
            print("Sell Legendary: " .. (petAnalysis.shouldSellLegendary and "YES" or "NO"))
            print("==================")
        end
        
        -- First find best brainrot for replacement and protect it
        local bestBrainrot = getBestBrainrotFromInventory()
        if bestBrainrot then
            protectedPet = bestBrainrot.tool
            print("Protected from sale: " .. bestBrainrot.name .. " (" .. bestBrainrot.moneyPerSecond .. "/s)")
        end
        
        for _, pet in pairs(backpack:GetChildren()) do
            if pet:IsA("Tool") and pet.Name:match("%[%d+%.?%d*%s*kg%]") then
                if shouldSellPet(pet) then
                    local petInfo = getPetInfo(pet)
                    local sellSuccess = sellPet(pet)
                    
                    if sellSuccess then
                        soldCount = soldCount + 1
                        
                        local reason = "Sold: " .. petInfo.rarity .. " (weight: " .. petInfo.weight .. "kg)"
                        if CONFIG.SMART_SELLING then
                            reason = reason .. " [MoneyPerSecond: " .. petInfo.moneyPerSecond .. "/s]"
                        end
                        
                        table.insert(logs, {
                            action = "SELL",
                            item = petInfo.name,
                            reason = reason,
                            timestamp = os.time()
                        })
                        
                        print("Sold: " .. petInfo.name .. " (" .. petInfo.rarity .. ", " .. petInfo.weight .. "kg, " .. petInfo.moneyPerSecond .. "/s)")
                    else
                        print("Failed to sell: " .. petInfo.name)
                    end
                    
                    wait(CONFIG.SELL_DELAY)
                else
                    local petInfo = getPetInfo(pet)
                    local reason = "Kept: "
                    
                    -- Check if this is a useful brainrot
                    if petInfo.moneyPerSecond >= petAnalysis.minMoneyPerSecondToKeep then
                        reason = reason .. "high MoneyPerSecond (" .. petInfo.moneyPerSecond .. "/s)"
                    elseif petInfo.weight >= CONFIG.MIN_WEIGHT_TO_KEEP then
                        reason = reason .. "heavy (" .. petInfo.weight .. "kg)"
                    elseif RARITY_ORDER[petInfo.rarity] > RARITY_ORDER["Legendary"] then
                        reason = reason .. "high rarity (" .. petInfo.rarity .. ")"
                    elseif petInfo.rarity == "Legendary" and hasProtectedMutations(pet.Name) then
                        reason = reason .. "protected mutations"
                    else
                        reason = reason .. "protected item"
                    end
                    
                    table.insert(logs, {
                        action = "KEEP",
                        item = petInfo.name,
                        reason = reason,
                        timestamp = os.time()
                    })
                    
                    keptCount = keptCount + 1
                end
            end
        end
        
        -- Remove protection after selling
        protectedPet = nil
        
        if soldCount > 0 or keptCount > 0 then
            print("Pets sold: " .. soldCount .. ", kept: " .. keptCount)
        end
    end)
    
    if not success then
        print("Error in autoSellPets: " .. tostring(error))
    end
end

-- Redeem codes
local function redeemCodes()
    print("Redeeming codes...")
    for _, code in pairs(CODES) do
        local args = {{"code", "\031"}}
        dataRemoteEvent:FireServer(unpack(args))
        wait(0.1)
    end
    print("Codes redeemed!")
end

-- Auto-open eggs
local function autoOpenEggs()
    local success, error = pcall(function()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local openedCount = 0
        
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                for _, eggName in pairs(PROTECTED_ITEMS) do
                    if item.Name:find(eggName) then
                        local args = {eggName}
                        openEggRemote:FireServer(unpack(args))
                        
                        table.insert(logs, {
                            action = "OPEN_EGG",
                            item = eggName,
                            reason = "Automatically opened egg",
                            timestamp = os.time()
                        })
                        
                        print("Opened egg: " .. eggName)
                        openedCount = openedCount + 1
                        wait(0.1)
                        break
                    end
                end
            end
        end
        
        if openedCount > 0 then
            print("Eggs opened: " .. openedCount)
        end
    end)
    
    if not success then
        print("Error in autoOpenEggs: " .. tostring(error))
    end
end

-- Check seed stock
local function checkSeedStock(seedName)
    local seedsGui = PlayerGui:FindFirstChild("Main")
    if not seedsGui then return false, 0 end
    
    local seedsFrame = seedsGui:FindFirstChild("Seeds")
    if not seedsFrame then return false, 0 end
    
    local scrollingFrame = seedsFrame:FindFirstChild("Frame"):FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return false, 0 end
    
    local seedFrame = scrollingFrame:FindFirstChild(seedName)
    if not seedFrame then return false, 0 end
    
    local stockLabel = seedFrame:FindFirstChild("Stock")
    if not stockLabel then return false, 0 end
    
    local stockText = stockLabel.Text
    local stockCount = tonumber(stockText:match("x(%d+)")) or 0
    
    return stockCount > 0, stockCount
end

-- Auto-buy seeds
local function autoBuySeeds()
    local success, error = pcall(function()
        for _, seedName in pairs(SEEDS) do
            local hasStock, stockCount = checkSeedStock(seedName)
            if hasStock then
                local args = {{seedName, "\b"}}
                dataRemoteEvent:FireServer(unpack(args))
                
                table.insert(logs, {
                    action = "BUY_SEED",
                    item = seedName,
                    reason = "Purchased (in stock: " .. stockCount .. ")",
                    timestamp = os.time()
                })
                
                print("Purchased seed: " .. seedName .. " (in stock: " .. stockCount .. ")")
                wait(0.1)
            end
        end
    end)
    
    if not success then
        print("Error in autoBuySeeds: " .. tostring(error))
    end
end

-- Check gear stock
local function checkGearStock(gearName)
    local gearsGui = PlayerGui:FindFirstChild("Main")
    if not gearsGui then return false, 0 end
    
    local gearsFrame = gearsGui:FindFirstChild("Gears")
    if not gearsFrame then return false, 0 end
    
    local scrollingFrame = gearsFrame:FindFirstChild("Frame"):FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return false, 0 end
    
    local gearFrame = scrollingFrame:FindFirstChild(gearName)
    if not gearFrame then return false, 0 end
    
    local stockLabel = gearFrame:FindFirstChild("Stock")
    if not stockLabel then return false, 0 end
    
    local stockText = stockLabel.Text
    local stockCount = tonumber(stockText:match("x(%d+)")) or 0
    
    return stockCount > 0, stockCount
end

-- Auto-buy items
local function autoBuyGear()
    local success, error = pcall(function()
        for _, gearName in pairs(GEAR_ITEMS) do
            local hasStock, stockCount = checkGearStock(gearName)
            if hasStock then
                local args = {{gearName, "\026"}}
                dataRemoteEvent:FireServer(unpack(args))
                
                table.insert(logs, {
                    action = "BUY_GEAR",
                    item = gearName,
                    reason = "Purchased (in stock: " .. stockCount .. ")",
                    timestamp = os.time()
                })
                
                print("Purchased item: " .. gearName .. " (in stock: " .. stockCount .. ")")
                wait(0.1)
            end
        end
    end)
    
    if not success then
        print("Error in autoBuyGear: " .. tostring(error))
    end
end

-- Get current player plot
local function getCurrentPlot()
    local plotNumber = LocalPlayer:GetAttribute("Plot")
    if plotNumber then
        local plot = workspace.Plots:FindFirstChild(tostring(plotNumber))
        if plot then
            print("Found plot: " .. plotNumber)
            return plot
        else
            print("Plot " .. plotNumber .. " not found in workspace.Plots")
        end
    else
        print("Plot attribute not found on player")
    end
    return nil
end

-- Get player balance
local function getPlayerBalance()
    if not playerData then
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "❌ playerData not initialized, trying alternative method",
            timestamp = os.time()
        })
        
        -- Alternative method to get balance
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local moneyValue = humanoid:FindFirstChild("Money")
                if moneyValue then
                    local balance = moneyValue.Value
                    table.insert(logs, {
                        action = "PLATFORM_DEBUG",
                        message = "💰 Balance obtained via alternative method: $" .. balance,
                        timestamp = os.time()
                    })
                    return balance
                end
            end
        end
        return 0
    end
    
    local success, balance = pcall(function()
        return playerData.get("Money") or 0
    end)
    
    if success then
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "💰 Balance obtained: $" .. balance,
            timestamp = os.time()
        })
        return balance
    else
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "❌ Error getting balance, trying alternative method",
            timestamp = os.time()
        })
        
        -- Alternative method to get balance
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local moneyValue = humanoid:FindFirstChild("Money")
                if moneyValue then
                    local balance = moneyValue.Value
                    table.insert(logs, {
                        action = "PLATFORM_DEBUG",
                        message = "💰 Balance obtained via alternative method: $" .. balance,
                        timestamp = os.time()
                    })
                    return balance
                end
            end
        end
        return 0
    end
end

-- Buy platform
local function buyPlatform(platformNumber)
    table.insert(logs, {
        action = "PLATFORM_DEBUG",
        message = "=== ATTEMPTING TO BUY PLATFORM " .. platformNumber .. " ===",
        timestamp = os.time()
    })
    
    local args = {
        {
            tostring(platformNumber),
            ","
        }
    }
    
    table.insert(logs, {
        action = "PLATFORM_DEBUG",
        message = "Sending platform purchase request " .. platformNumber,
        timestamp = os.time()
    })
    
    table.insert(logs, {
        action = "PLATFORM_DEBUG",
        message = "Request arguments: " .. tostring(args[1][1]) .. ", " .. tostring(args[1][2]),
        timestamp = os.time()
    })
    
    local success, error = pcall(function()
        dataRemoteEvent:FireServer(unpack(args))
    end)
    
    if success then
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "✅ Platform purchase request " .. platformNumber .. " sent successfully",
            timestamp = os.time()
        })
        
        table.insert(logs, {
            action = "BUY_PLATFORM",
            item = "Platform " .. platformNumber,
            reason = "Platform purchased",
            timestamp = os.time()
        })
    else
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "❌ ERROR when buying platform " .. platformNumber .. ": " .. tostring(error),
            timestamp = os.time()
        })
    end
    
    table.insert(logs, {
        action = "PLATFORM_DEBUG",
        message = "=== COMPLETING PLATFORM PURCHASE ATTEMPT " .. platformNumber .. " ===",
        timestamp = os.time()
    })
end

-- Test function for platform buying diagnostics
local function testPlatformBuying()
    -- Simple platform availability check
    local plotNumber = LocalPlayer:GetAttribute("Plot")
    if plotNumber then
        local plot = workspace.Plots[tostring(plotNumber)]
        if plot and plot:FindFirstChild("Brainrots") then
            table.insert(logs, {
                action = "PLATFORM_DEBUG",
                message = "✅ Platforms available for purchase",
                timestamp = os.time()
            })
        end
    end
end

-- Auto-buy platforms
local function autoBuyPlatforms()
    table.insert(logs, {
        action = "PLATFORM_DEBUG",
        message = "=== autoBuyPlatforms() FUNCTION CALLED ===",
        timestamp = os.time()
    })
    
    
    local success, error = pcall(function()
        if not CONFIG.AUTO_BUY_PLATFORMS then
            table.insert(logs, {
                action = "PLATFORM_DEBUG",
                message = "Auto platform purchase disabled in configuration",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "Auto platform purchase enabled, starting check...",
            timestamp = os.time()
        })
        
        local currentPlot = getCurrentPlot()
        if not currentPlot then
            table.insert(logs, {
                action = "PLATFORM_DEBUG",
                message = "Current plot not found for platform purchase",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "Found plot: " .. tostring(currentPlot),
            timestamp = os.time()
        })
        
        local brainrots = currentPlot:FindFirstChild("Brainrots")
        if not brainrots then
            table.insert(logs, {
                action = "PLATFORM_DEBUG",
                message = "Brainrots not found on plot for platform purchase",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "Brainrots found, checking platforms...",
            timestamp = os.time()
        })
        
        
        local playerBalance = getPlayerBalance()
        local boughtCount = 0
        local platformsChecked = 0
        
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "Checking platforms for purchase. Balance: $" .. playerBalance,
            timestamp = os.time()
        })
        
        -- Check dataRemoteEvent
        if dataRemoteEvent then
            table.insert(logs, {
                action = "PLATFORM_DEBUG",
                message = "dataRemoteEvent found: " .. tostring(dataRemoteEvent),
                timestamp = os.time()
            })
        else
            table.insert(logs, {
                action = "PLATFORM_DEBUG",
                message = "ERROR: dataRemoteEvent not found!",
                timestamp = os.time()
            })
        end
        
        for _, platform in pairs(brainrots:GetChildren()) do
            if platform:IsA("Model") and platform.Name:match("^%d+$") then
                platformsChecked = platformsChecked + 1
                
                -- Check PlatformPrice.Money instead of just PlatformPrice
                local platformPrice = platform:GetAttribute("PlatformPrice")
                if platformPrice then
                    -- Check if PlatformPrice has Money attribute
                    local platformPriceMoney = platformPrice.Money
                    if platformPriceMoney then
                        -- Parse price from PlatformPrice.Money
                        local priceText = tostring(platformPriceMoney)
                        local priceValue = priceText:match("%$(%d+,?%d*%d*)")
                        if priceValue then
                            -- Remove commas and convert to number
                            local cleanPrice = priceValue:gsub(",", "")
                            local price = tonumber(cleanPrice) or 0
                        
                            -- Always try to buy platform, regardless of balance
                            table.insert(logs, {
                                action = "PLATFORM_DEBUG",
                                message = "Buying platform " .. platform.Name .. " for $" .. price .. " (balance: $" .. playerBalance .. ")",
                                timestamp = os.time()
                            })
                            buyPlatform(platform.Name)
                            boughtCount = boughtCount + 1
                            wait(0.5) -- Small pause between purchases
                        end
                    end
                end
            end
        end
        
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "Platforms checked: " .. platformsChecked .. ", purchased: " .. boughtCount,
            timestamp = os.time()
        })
        
        if boughtCount > 0 then
            print("Platforms purchased: " .. boughtCount)
        end
    end)
    
    if not success then
        table.insert(logs, {
            action = "PLATFORM_DEBUG",
            message = "❌ ERROR in autoBuyPlatforms: " .. tostring(error),
            timestamp = os.time()
        })
        print("Error in autoBuyPlatforms: " .. tostring(error))
    end
    
    table.insert(logs, {
        action = "PLATFORM_DEBUG",
        message = "=== autoBuyPlatforms() FUNCTION COMPLETED ===",
        timestamp = os.time()
    })
end

-- Collect coins from plot
local function collectCoinsFromPlot()
    table.insert(logs, {
        action = "COLLECT_DEBUG",
        message = "=== collectCoinsFromPlot() FUNCTION CALLED ===",
        timestamp = os.time()
    })
    
    local success, error = pcall(function()
        if not CONFIG.AUTO_COLLECT_COINS then
            table.insert(logs, {
                action = "COLLECT_DEBUG",
                message = "Auto coin collection disabled in configuration",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "COLLECT_DEBUG",
            message = "Auto coin collection enabled, starting...",
            timestamp = os.time()
        })
        
        local currentPlot = getCurrentPlot()
        if not currentPlot then
            table.insert(logs, {
                action = "COLLECT_DEBUG",
                message = "Current plot not found for coin collection",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "COLLECT_DEBUG",
            message = "Found plot: " .. tostring(currentPlot),
            timestamp = os.time()
        })
        
        local coins = currentPlot:FindFirstChild("Coins")
        if not coins then
            table.insert(logs, {
                action = "COLLECT_DEBUG",
                message = "Coins not found on plot",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "COLLECT_DEBUG",
            message = "Coins found, collecting...",
            timestamp = os.time()
        })
        
        local collectedCount = 0
        for _, coin in pairs(coins:GetChildren()) do
            if coin:IsA("Part") and coin.Name == "Coin" then
                -- Fire remote event to collect coin
                local args = {coin}
                useItemRemote:FireServer(unpack(args))
                collectedCount = collectedCount + 1
                wait(0.01) -- Small pause between collections
            end
        end
        
        table.insert(logs, {
            action = "COLLECT_DEBUG",
            message = "Coins collected: " .. collectedCount,
            timestamp = os.time()
        })
        
        if collectedCount > 0 and CONFIG.DEBUG_COLLECT_COINS then
            print("Coins collected: " .. collectedCount)
        end
    end)
    
    if not success then
        table.insert(logs, {
            action = "COLLECT_DEBUG",
            message = "❌ ERROR in collectCoinsFromPlot: " .. tostring(error),
            timestamp = os.time()
        })
        print("Error in collectCoinsFromPlot: " .. tostring(error))
    end
    
    table.insert(logs, {
        action = "COLLECT_DEBUG",
        message = "=== collectCoinsFromPlot() FUNCTION COMPLETED ===",
        timestamp = os.time()
    })
end

-- Get best brainrot for replacement
local function getBestBrainrotForReplacement()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local bestBrainrot = nil
    local bestMoneyPerSecond = 0
    
    for _, pet in pairs(backpack:GetChildren()) do
        if pet:IsA("Tool") and pet.Name:match("%[%d+%.?%d*%s*kg%]") then
            local petInfo = getPetInfo(pet)
            local moneyPerSecond = petInfo.moneyPerSecond
            
            if moneyPerSecond > bestMoneyPerSecond then
                bestMoneyPerSecond = moneyPerSecond
                bestBrainrot = pet
            end
        end
    end
    
    return bestBrainrot, bestMoneyPerSecond
end

-- Replace brainrot on plot
local function replaceBrainrotOnPlot()
    table.insert(logs, {
        action = "REPLACE_DEBUG",
        message = "=== replaceBrainrotOnPlot() FUNCTION CALLED ===",
        timestamp = os.time()
    })
    
    local success, error = pcall(function()
        if not CONFIG.AUTO_REPLACE_BRAINROTS then
            table.insert(logs, {
                action = "REPLACE_DEBUG",
                message = "Auto brainrot replacement disabled in configuration",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "REPLACE_DEBUG",
            message = "Auto brainrot replacement enabled, starting...",
            timestamp = os.time()
        })
        
        local currentPlot = getCurrentPlot()
        if not currentPlot then
            table.insert(logs, {
                action = "REPLACE_DEBUG",
                message = "Current plot not found for brainrot replacement",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "REPLACE_DEBUG",
            message = "Found plot: " .. tostring(currentPlot),
            timestamp = os.time()
        })
        
        local brainrots = currentPlot:FindFirstChild("Brainrots")
        if not brainrots then
            table.insert(logs, {
                action = "REPLACE_DEBUG",
                message = "Brainrots not found on plot",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "REPLACE_DEBUG",
            message = "Brainrots found, checking for replacement...",
            timestamp = os.time()
        })
        
        local bestBrainrot, bestMoneyPerSecond = getBestBrainrotForReplacement()
        if not bestBrainrot then
            table.insert(logs, {
                action = "REPLACE_DEBUG",
                message = "No suitable brainrot found in inventory for replacement",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "REPLACE_DEBUG",
            message = "Best brainrot for replacement: " .. bestBrainrot.Name .. " (" .. bestMoneyPerSecond .. "/s)",
            timestamp = os.time()
        })
        
        local replacedCount = 0
        for _, platform in pairs(brainrots:GetChildren()) do
            if platform:IsA("Model") and platform.Name:match("^%d+$") then
                local currentBrainrot = platform:FindFirstChildOfClass("Tool")
                if currentBrainrot then
                    local currentBrainrotInfo = getPetInfo(currentBrainrot)
                    local currentMoneyPerSecond = currentBrainrotInfo.moneyPerSecond
                    
                    -- Replace if the new brainrot is better
                    if bestMoneyPerSecond > currentMoneyPerSecond then
                        -- Equip best brainrot
                        local character = LocalPlayer.Character
                        if character then
                            local humanoid = character:FindFirstChild("Humanoid")
                            if humanoid then
                                humanoid:EquipTool(bestBrainrot)
                                wait(0.1)
                                
                                -- Use brainrot on platform
                                local args = {platform}
                                useItemRemote:FireServer(unpack(args))
                                replacedCount = replacedCount + 1
                                
                                table.insert(logs, {
                                    action = "REPLACE_BRAINROT",
                                    item = bestBrainrot.Name,
                                    reason = "Replaced brainrot on platform " .. platform.Name .. " (old: " .. currentMoneyPerSecond .. "/s, new: " .. bestMoneyPerSecond .. "/s)",
                                    timestamp = os.time()
                                })
                                
                                print("Replaced brainrot on platform " .. platform.Name .. ": " .. currentMoneyPerSecond .. "/s -> " .. bestMoneyPerSecond .. "/s")
                                wait(0.1)
                            end
                        end
                    end
                end
            end
        end
        
        table.insert(logs, {
            action = "REPLACE_DEBUG",
            message = "Brainrots replaced: " .. replacedCount,
            timestamp = os.time()
        })
        
        if replacedCount > 0 then
            print("Brainrots replaced: " .. replacedCount)
        end
    end)
    
    if not success then
        table.insert(logs, {
            action = "REPLACE_DEBUG",
            message = "❌ ERROR in replaceBrainrotOnPlot: " .. tostring(error),
            timestamp = os.time()
        })
        print("Error in replaceBrainrotOnPlot: " .. tostring(error))
    end
    
    table.insert(logs, {
        action = "REPLACE_DEBUG",
        message = "=== replaceBrainrotOnPlot() FUNCTION COMPLETED ===",
        timestamp = os.time()
    })
end

-- Plant seeds on plot
local function plantSeedsOnPlot()
    table.insert(logs, {
        action = "PLANT_DEBUG",
        message = "=== plantSeedsOnPlot() FUNCTION CALLED ===",
        timestamp = os.time()
    })
    
    local success, error = pcall(function()
        if not CONFIG.AUTO_PLANT_SEEDS then
            table.insert(logs, {
                action = "PLANT_DEBUG",
                message = "Auto planting disabled in configuration",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "PLANT_DEBUG",
            message = "Auto planting enabled, starting...",
            timestamp = os.time()
        })
        
        local currentPlot = getCurrentPlot()
        if not currentPlot then
            table.insert(logs, {
                action = "PLANT_DEBUG",
                message = "Current plot not found for planting",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "PLANT_DEBUG",
            message = "Found plot: " .. tostring(currentPlot),
            timestamp = os.time()
        })
        
        local plants = currentPlot:FindFirstChild("Plants")
        if not plants then
            table.insert(logs, {
                action = "PLANT_DEBUG",
                message = "Plants not found on plot",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "PLANT_DEBUG",
            message = "Plants found, checking for planting...",
            timestamp = os.time()
        })
        
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local plantedCount = 0
        
        -- Check for seeds in backpack
        for _, seedName in pairs(SEEDS) do
            local seed = backpack:FindFirstChild(seedName)
            if seed then
                -- Find empty plant spot
                for _, plantSpot in pairs(plants:GetChildren()) do
                    if plantSpot:IsA("Part") and plantSpot.Name == "PlantSpot" then
                        local hasPlant = false
                        for _, child in pairs(plantSpot:GetChildren()) do
                            if child:IsA("Model") and child.Name == "Plant" then
                                hasPlant = true
                                break
                            end
                        end
                        
                        if not hasPlant then
                            -- Equip seed
                            local character = LocalPlayer.Character
                            if character then
                                local humanoid = character:FindFirstChild("Humanoid")
                                if humanoid then
                                    humanoid:EquipTool(seed)
                                    wait(0.1)
                                    
                                    -- Plant seed
                                    local args = {plantSpot}
                                    useItemRemote:FireServer(unpack(args))
                                    plantedCount = plantedCount + 1
                                    
                                    table.insert(logs, {
                                        action = "PLANT_SEED",
                                        item = seedName,
                                        reason = "Planted seed on spot " .. plantSpot.Name,
                                        timestamp = os.time()
                                    })
                                    
                                    if CONFIG.DEBUG_PLANTING then
                                        print("Planted: " .. seedName .. " on spot " .. plantSpot.Name)
                                    end
                                    wait(0.1)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        table.insert(logs, {
            action = "PLANT_DEBUG",
            message = "Seeds planted: " .. plantedCount,
            timestamp = os.time()
        })
        
        if plantedCount > 0 and CONFIG.DEBUG_PLANTING then
            print("Seeds planted: " .. plantedCount)
        end
    end)
    
    if not success then
        table.insert(logs, {
            action = "PLANT_DEBUG",
            message = "❌ ERROR in plantSeedsOnPlot: " .. tostring(error),
            timestamp = os.time()
        })
        print("Error in plantSeedsOnPlot: " .. tostring(error))
    end
    
    table.insert(logs, {
        action = "PLANT_DEBUG",
        message = "=== plantSeedsOnPlot() FUNCTION COMPLETED ===",
        timestamp = os.time()
    })
end

-- Water plants on plot
local function waterPlantsOnPlot()
    table.insert(logs, {
        action = "WATER_DEBUG",
        message = "=== waterPlantsOnPlot() FUNCTION CALLED ===",
        timestamp = os.time()
    })
    
    local success, error = pcall(function()
        if not CONFIG.AUTO_WATER_PLANTS then
            table.insert(logs, {
                action = "WATER_DEBUG",
                message = "Auto watering disabled in configuration",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "WATER_DEBUG",
            message = "Auto watering enabled, starting...",
            timestamp = os.time()
        })
        
        local currentPlot = getCurrentPlot()
        if not currentPlot then
            table.insert(logs, {
                action = "WATER_DEBUG",
                message = "Current plot not found for watering",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "WATER_DEBUG",
            message = "Found plot: " .. tostring(currentPlot),
            timestamp = os.time()
        })
        
        local plants = currentPlot:FindFirstChild("Plants")
        if not plants then
            table.insert(logs, {
                action = "WATER_DEBUG",
                message = "Plants not found on plot",
                timestamp = os.time()
            })
            return
        end
        
        table.insert(logs, {
            action = "WATER_DEBUG",
            message = "Plants found, checking for watering...",
            timestamp = os.time()
        })
        
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local wateredCount = 0
        
        -- Check for water bucket in backpack
        local waterBucket = backpack:FindFirstChild("Water Bucket")
        if waterBucket then
            -- Find plants that need watering
            for _, plantSpot in pairs(plants:GetChildren()) do
                if plantSpot:IsA("Part") and plantSpot.Name == "PlantSpot" then
                    for _, child in pairs(plantSpot:GetChildren()) do
                        if child:IsA("Model") and child.Name == "Plant" then
                            -- Check if plant needs watering (you can add additional conditions here)
                            local needsWatering = true -- Placeholder condition
                            
                            if needsWatering then
                                -- Equip water bucket
                                local character = LocalPlayer.Character
                                if character then
                                    local humanoid = character:FindFirstChild("Humanoid")
                                    if humanoid then
                                        humanoid:EquipTool(waterBucket)
                                        wait(0.1)
                                        
                                        -- Water plant
                                        local args = {plantSpot}
                                        useItemRemote:FireServer(unpack(args))
                                        wateredCount = wateredCount + 1
                                        
                                        table.insert(logs, {
                                            action = "WATER_PLANT",
                                            item = "Water Bucket",
                                            reason = "Watered plant on spot " .. plantSpot.Name,
                                            timestamp = os.time()
                                        })
                                        
                                        if CONFIG.DEBUG_PLANTING then
                                            print("Watered plant on spot " .. plantSpot.Name)
                                        end
                                        wait(0.1)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        table.insert(logs, {
            action = "WATER_DEBUG",
            message = "Plants watered: " .. wateredCount,
            timestamp = os.time()
        })
        
        if wateredCount > 0 and CONFIG.DEBUG_PLANTING then
            print("Plants watered: " .. wateredCount)
        end
    end)
    
    if not success then
        table.insert(logs, {
            action = "WATER_DEBUG",
            message = "❌ ERROR in waterPlantsOnPlot: " .. tostring(error),
            timestamp = os.time()
        })
        print("Error in waterPlantsOnPlot: " .. tostring(error))
    end
    
    table.insert(logs, {
        action = "WATER_DEBUG",
        message = "=== waterPlantsOnPlot() FUNCTION COMPLETED ===",
        timestamp = os.time()
    })
end

-- Copy logs to clipboard
local function copyLogsToClipboard()
    local logText = ""
    for _, logEntry in pairs(logs) do
        logText = logText .. "[" .. os.date("%H:%M:%S", logEntry.timestamp) .. "] " .. logEntry.action .. ": " .. tostring(logEntry.item or logEntry.message) .. "\n"
        if logEntry.reason then
            logText = logText .. "   Reason: " .. logEntry.reason .. "\n"
        end
    end
    
    if logText == "" then
        logText = "No logs available"
    end
    
    pcall(function()
        setclipboard(logText)
    end)
    
    print("Logs copied to clipboard!")
end

-- Main loop
local function mainLoop()
    print("Starting main loop...")
    
    -- Initial redeem codes
    redeemCodes()
    
    -- Main loop
    while true do
        -- Auto sell pets
        autoSellPets()
        
        -- Auto open eggs
        autoOpenEggs()
        
        -- Auto buy seeds
        if CONFIG.AUTO_BUY_SEEDS then
            autoBuySeeds()
        end
        
        -- Auto buy gear
        if CONFIG.AUTO_BUY_GEAR then
            autoBuyGear()
        end
        
        -- Auto collect coins
        if CONFIG.AUTO_COLLECT_COINS then
            collectCoinsFromPlot()
        end
        
        -- Auto replace brainrots
        if CONFIG.AUTO_REPLACE_BRAINROTS then
            replaceBrainrotOnPlot()
        end
        
        -- Auto plant seeds
        if CONFIG.AUTO_PLANT_SEEDS then
            plantSeedsOnPlot()
        end
        
        -- Auto water plants
        if CONFIG.AUTO_WATER_PLANTS then
            waterPlantsOnPlot()
        end
        
        -- Auto buy platforms
        if CONFIG.AUTO_BUY_PLATFORMS then
            autoBuyPlatforms()
        end
        
        wait(CONFIG.BUY_INTERVAL)
    end
end

-- Keyboard input handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == CONFIG.LOG_COPY_KEY then
        copyLogsToClipboard()
    end
end)

-- Start diagnostics if not already run
if not diagnosticsRun then
    print("Running diagnostics...")
    testPlatformBuying()
    diagnosticsRun = true
end

-- Start script
initialize()
mainLoop()
[file content end]
