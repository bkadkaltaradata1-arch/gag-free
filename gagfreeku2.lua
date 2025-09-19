function autoPlant()
    spawn(function()
        while getgenv().AutoPlant do
            -- Cek apakah ada biji di inventory
            if areThereSeeds() then
                print("There Are Seeds!")
                
                -- Dapatkan backpack dan karakter
                local Backpack = game.Players.LocalPlayer.Backpack
                local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
                
                -- Loop melalui semua item di backpack
                for _, Item in pairs(Backpack:GetChildren()) do
                    if not getgenv().AutoPlant then break end
                    
                    -- Cek apakah item adalah biji yang sesuai dengan yang dipilih
                    if Item:FindFirstChild("Seed Local Script") and isSelectedSeedType(Item) then
                        -- Pindahkan tool ke karakter untuk digunakan
                        Item.Parent = Character
                        wait(0.1)
                        
                        -- Dapatkan lokasi tanam yang sesuai
                        local location = getRandomPlantingLocation()
                        if location then
                            -- Fire the plant event
                            local args = {
                                [1] = location.Position,
                                [2] = Item:GetAttribute("Seed") or getgenv().SelectedSeed
                            }
                            
                            -- Cari remote event untuk menanam
                            local Plant = findPlantRemoteEvent()
                            if Plant then
                                Plant:FireServer(unpack(args))
                            end
                        end
                        
                        wait(0.5)
                        
                        -- Kembalikan tool ke backpack
                        if Item and Item:IsDescendantOf(game) and Item.Parent ~= Backpack then
                            pcall(function()
                                Item.Parent = Backpack
                            end)
                        end
                    end
                end
                
                Rayfield:Notify({
                    Title = "Auto Plant",
                    Content = "Planted available seeds",
                    Duration = 3,
                    Image = 4483362458,
                })
            else
                print("No seeds available")
                Rayfield:Notify({
                    Title = "Auto Plant",
                    Content = "No seeds available in inventory",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            
            wait(2) -- Tunggu sebelum pengecekan berikutnya
        end
    end)
end

-- Fungsi pendukung yang diperlukan
function areThereSeeds()
    local Backpack = game.Players.LocalPlayer.Backpack
    for _, Item in pairs(Backpack:GetChildren()) do
        if Item:FindFirstChild("Seed Local Script") and isSelectedSeedType(Item) then
            return true
        end
    end
    return false
end

function isSelectedSeedType(Item)
    local seedAttribute = Item:GetAttribute("Seed") or Item.Name
    return string.find(seedAttribute, getgenv().SelectedSeed, 1, true) ~= nil
end

function getRandomPlantingLocation()
    local emptyPlots = findEmptyPlots()
    if #emptyPlots > 0 then
        return emptyPlots[math.random(1, #emptyPlots)]
    end
    return nil
end

function findPlantRemoteEvent()
    -- Cari RemoteEvent untuk menanam di berbagai lokasi yang mungkin
    local events = {
        game.ReplicatedStorage:FindFirstChild("Plant"),
        game.ReplicatedStorage:FindFirstChild("PlantEvent"),
        game.ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("Plant"),
        game.ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("Plant")
    }
    
    for _, event in ipairs(events) do
        if event and event:IsA("RemoteEvent") then
            return event
        end
    end
    
    -- Jika tidak ditemukan, coba cari di tempat lain
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (obj.Name:find("Plant") or obj.Name:find("Seed")) then
            return obj
        end
    end
    
    return nil
end
