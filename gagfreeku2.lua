-- Deteksi Event Teleport
local TeleportEvents = {"Teleport", "TravelTo", "GoToShop", "GearShop", "ShopTeleport"}
local TeleportEvent = FindEvent(TeleportEvents)

print("🚀 Teleport Event: " .. (TeleportEvent and TeleportEvent.Name or "Not Found"))

-- Variabel untuk teleport
_G.TeleportToShop = false

-- Fungsi untuk teleport ke gear shop
function TeleportToGearShop()
    if not TeleportEvent then
        print("❌ No teleport event found")
        return false
    end
    
    print("🚀 Teleporting to Gear Shop...")
    
    -- Coba dengan berbagai parameter yang mungkin
    local success = pcall(function()
        TeleportEvent:FireServer("GearShop")
        print("✅ Teleported to Gear Shop")
    end)
    
    if not success then
        pcall(function()
            TeleportEvent:FireServer("Shop")
            print("✅ Teleported to Shop")
        end)
    end
    
    if not success then
        pcall(function()
            TeleportEvent:FireServer()
            print("✅ Teleported (no parameter)")
        end)
    end
    
    return success
end

-- Tambahkan ke GUI (di bagian CreateSection dan CreateTouchToggle)
CreateSection("TELEPORT", 235)

CreateTouchToggle("Auto Teleport to Shop", 280, function(state)
    _G.TeleportToShop = state
    print("Auto Teleport: " .. tostring(state))
    if state and TeleportEvent then
        spawn(function()
            while _G.TeleportToShop do
                TeleportToGearShop()
                wait(30) -- Teleport setiap 30 detik
            end
        end)
    elseif state then
        print("❌ Cannot start Auto Teleport - Event not found")
    end
end)

-- Tambahkan status teleport event
table.insert(eventStatuses, {name = "Teleport Event", event = TeleportEvent, yPos = 430})

-- Perbarui posisi section berikutnya
CreateSection("MANUAL CONTROL", 470)

-- Perbarui posisi tombol manual
CreateManualButton("🔧 Manual Harvest", 515, HarvestPlants)
CreateManualButton("🔧 Manual Plant", 560, PlantSeeds)
CreateManualButton("🔧 Manual Water", 605, WaterPlants)
CreateManualButton("🔧 Manual Sell", 650, SellCrops)
CreateManualButton("🚀 Teleport to Shop", 695, TeleportToGearShop)  -- Tombol manual teleport

-- Perbarui ukuran canvas scroll
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 740)  -- Tambah tinggi untuk fitur baru

-- Perbarui output deteksi event
print("🔍 Auto-detected " .. 
      (PlantEvent and "Plant " or "") ..
      (WaterEvent and "Water " or "") ..
      (HarvestEvent and "Harvest " or "") ..
      (SellEvent and "Sell " or "") ..
      (TeleportEvent and "Teleport" or ""))
