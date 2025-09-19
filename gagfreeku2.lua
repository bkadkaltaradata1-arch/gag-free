function harvestPlant()
    -- Implementasi untuk memanen tanaman yang kompatibel dengan mobile
    local tool = findTool("Harvest Tool") or findTool("Sickle") or findTool("Axe")
    if tool then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.5)
        
        -- Coba beberapa metode yang mungkin bekerja di mobile
        -- Metode 1: Aktifkan tool secara langsung
        if tool:FindFirstChild("Activate") then
            tool.Activate:Invoke()
        end
        
        -- Metode 2: Gunakan event remote jika ada
        local events = getHarvestEvents()
        if #events > 0 then
            for _, event in ipairs(events) do
                event:FireServer()
            end
        end
        
        -- Metode 3: Gunukan touch events untuk mobile
        local touchEvent = getTouchEvent()
        if touchEvent then
            touchEvent:FireServer(tool)
        end
        
        wait(0.5)
    end
end

-- Fungsi baru untuk mendapatkan event panen yang tersedia
function getHarvestEvents()
    local events = {}
    
    -- Cari event panen di berbagai lokasi yang mungkin
    local possibleLocations = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Workspace"),
        game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts")
    }
    
    for _, location in ipairs(possibleLocations) do
        if location then
            for _, item in ipairs(location:GetDescendants()) do
                if item:IsA("RemoteEvent") and 
                  (item.Name:find("Harvest") or item.Name:find("Collect") or 
                   item.Name:find("Pick") or item.Name:find("Gather")) then
                    table.insert(events, item)
                end
            end
        end
    end
    
    return events
end

-- Fungsi khusus untuk mendapatkan event touch yang digunakan di mobile
function getTouchEvent()
    -- Cari event touch/interaction yang biasa digunakan di game mobile
    local touchEvent
    
    -- Cek di ReplicatedStorage terlebih dahulu
    if game:GetService("ReplicatedStorage"):FindFirstChild("TouchEvent") then
        touchEvent = game:GetService("ReplicatedStorage").TouchEvent
    elseif game:GetService("ReplicatedStorage"):FindFirstChild("MobileEvent") then
        touchEvent = game:GetService("ReplicatedStorage").MobileEvent
    elseif game:GetService("ReplicatedStorage"):FindFirstChild("InteractEvent") then
        touchEvent = game:GetService("ReplicatedStorage").InteractEvent
    end
    
    return touchEvent
end

-- Fungsi untuk mencari tanaman yang siap panen (diperbarui)
function findMaturePlants()
    local maturePlants = {}
    
    -- Cari tanaman di berbagai lokasi yang mungkin
    local possibleParents = {
        workspace:FindFirstChild("Plants"),
        workspace:FindFirstChild("Crops"),
        workspace:FindFirstChild("Garden"),
        workspace:FindFirstChild("Farm"),
        workspace
    }
    
    for _, parent in ipairs(possibleParents) do
        if parent then
            for _, plant in ipairs(parent:GetChildren()) do
                if plant:IsA("Model") then
                    -- Beberapa cara untuk mendeteksi tanaman siap panen
                    local isMature = false
                    
                    -- 1. Cek attribute
                    if plant:GetAttribute("IsMature") or plant:GetAttribute("ReadyToHarvest") then
                        isMature = true
                    end
                    
                    -- 2. Cek part color atau transparency (jika ada perubahan visual)
                    for _, part in ipairs(plant:GetDescendants()) do
                        if part:IsA("Part") then
                            if part.BrickColor == BrickColor.new("Bright yellow") or 
                               part.Transparency < 0.5 then
                                isMature = true
                                break
                            end
                        end
                    end
                    
                    -- 3. Cek jika ada part khusus untuk tanaman matang
                    if plant:FindFirstChild("Harvestable") or plant:FindFirstChild("Mature") then
                        isMature = true
                    end
                    
                    if isMature then
                        table.insert(maturePlants, plant)
                    end
                end
            end
        end
    end
    
    return maturePlants
end
