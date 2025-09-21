-- Grow a Garden Auto Buyer untuk NPC Sam
-- Script untuk Delta Executormm,,

local gui = {}
local running = false

-- Fungsi utama untuk auto buy
function autoBuyFromSam()
    while running do
        -- Cari NPC Sam berdasarkan warna atau template
        local samFound = findNPC()
        
        if samFound then
            -- Klik NPC Sam
            touchDown(0, samFound.x, samFound.y)
            usleep(16000)
            touchUp(0)
            usleep(1000000)  -- Tunggu dialog terbuka
            
            -- Pilih opsi beli
            selectBuyOption()
            
            -- Proses pembelian
            processPurchase()
            
            -- Tutup dialog
            closeDialog()
        else
            -- Jika NPC Sam tidak ditemukan, tunggu sebentar
            usleep(500000)
        end
        
        -- Delay antara pembelian
        usleep(gui.delayValue * 1000)
    end
end

function findNPC()
    -- Implementasi pencarian NPC Sam berdasarkan warna atau template matching
    -- Ini perlu disesuaikan dengan game sebenarnya
    local colors = {
        {r=255, g=200, b=100},  -- Contoh warna karakter NPC Sam
        {r=250, g=190, b=90}
    }
    
    -- Simple search untuk warna tertentu di area tertentu
    for y = 300, 800, 5 do
        for x = 200, 800, 5 do
            local currentColor = getColor(x, y)
            for _, color in ipairs(colors) do
                if colorMatch(currentColor, color, 20) then
                    return {x = x, y = y}
                end
            end
        end
    end
    
    return nil
end

function colorMatch(c1, c2, threshold)
    local dr = math.abs(c1.r - c2.r)
    local dg = math.abs(c1.g - c2.g)
    local db = math.abs(c1.b - c2.b)
    return dr < threshold and dg < threshold and db < threshold
end

function selectBuyOption()
    -- Klik opsi beli di dialog NPC
    -- Koordinat perlu disesuaikan dengan perangkat dan game
    touchDown(0, 500, 600)
    usleep(16000)
    touchUp(0)
    usleep(500000)  -- Tunggu menu pembelian terbuka
end

function processPurchase()
    -- Klik item yang ingin dibeli (contoh: biji bunga)
    touchDown(0, 400, 500)
    usleep(16000)
    touchUp(0)
    usleep(300000)
    
    -- Klik tombol beli
    touchDown(0, 600, 800)
    usleep(16000)
    touchUp(0)
    usleep(300000)
    
    -- Konfirmasi pembelian jika diperlukan
    if gui.confirmPurchase then
        touchDown(0, 550, 700)
        usleep(16000)
        touchUp(0)
        usleep(300000)
    end
end

function closeDialog()
    -- Klik tombol close atau area kosong untuk menutup dialog
    touchDown(0, 700, 200)
    usleep(16000)
    touchUp(0)
    usleep(300000)
end

-- GUI Creation
function createGUI()
    -- Window utama
    gui.mainWindow = createWindow("Grow a Garden Auto Buyer", 300, 400)
    
    -- Label judul
    gui.titleLabel = createLabel(gui.mainWindow, "Auto Buyer NPC Sam", 20, 20, 260, 30)
    setTextColor(gui.titleLabel, 0, 100, 0)
    setTextSize(gui.titleLabel, 16)
    
    -- Toggle untuk menjalankan/menghentikan script
    gui.toggleButton = createButton(gui.mainWindow, "Mulai", 50, 60, 200, 40)
    setOnClick(gui.toggleButton, function()
        running = not running
        if running then
            setText(gui.toggleButton, "Berhenti")
            setTextColor(gui.toggleButton, 255, 0, 0)
            startThread(autoBuyFromSam)
        else
            setText(gui.toggleButton, "Mulai")
            setTextColor(gui.toggleButton, 0, 150, 0)
        end
    end)
    
    -- Slider untuk delay
    gui.delayLabel = createLabel(gui.mainWindow, "Delay: 3000 ms", 50, 120, 200, 30)
    gui.delaySlider = createSlider(gui.mainWindow, 50, 150, 200, 30, 1000, 10000, 3000)
    setOnChange(gui.delaySlider, function(value)
        gui.delayValue = value
        setText(gui.delayLabel, "Delay: " .. value .. " ms")
    end)
    
    -- Checkbox untuk konfirmasi pembelian
    gui.confirmCheckbox = createCheckbox(gui.mainWindow, "Konfirmasi Pembelian", 50, 200, 200, 30)
    setChecked(gui.confirmCheckbox, true)
    setOnChange(gui.confirmCheckbox, function(checked)
        gui.confirmPurchase = checked
    end)
    
    -- Status label
    gui.statusLabel = createLabel(gui.mainWindow, "Status: Tidak aktif", 50, 250, 200, 30)
    
    -- Log area
    gui.logLabel = createLabel(gui.mainWindow, "Log:", 50, 290, 200, 20)
    gui.logArea = createTextArea(gui.mainWindow, 50, 310, 200, 60, "")
    
    -- Inisialisasi nilai default
    gui.delayValue = 3000
    gui.confirmPurchase = true
end

-- Fungsi untuk menambahkan log
function addLog(message)
    local currentText = getText(gui.logArea)
    local newText = os.date("[%H:%M:%S] ") .. message .. "\n" .. currentText
    setText(gui.logArea, newText)
end

-- Main execution
createGUI()
