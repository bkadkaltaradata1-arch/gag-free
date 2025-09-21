-- Script Grow a Garden - Pembelian Seed
-- Untuk Delta Executor Android
-- GUI Version

-- Konfigurasi warna
local white = 0xFFFFFFFF
local green = 0xFF00FF00
local red = 0xFFFF0000
local blue = 0xFF0000FF
local orange = 0xFFFF9800

-- Inisialisasi GUI
function initGUI()
    -- Hapus GUI lama jika ada
    clearGUI()
    
    -- Buat window utama
    w = createWindow("🌻 Grow a Garden - Auto Buy Seed", 300, 400)
    
    -- Judul
    addLabel(w, "PILIH SEED UNTUK DIBELI", 10, 10, 280, 30)
    setLabelTextColor(w, 0, green)
    setLabelTextSize(w, 0, 16)
    
    -- Dropdown pilihan seed
    addSpinner(w, {"Strawberry", "Carrot", "Tomato", "Lettuce", "Sunflower", "Rose", "Blueberry", "Corn"}, 10, 50, 280, 40)
    
    -- Input quantity
    addLabel(w, "Quantity:", 10, 100, 100, 30)
    addEditText(w, "1", 120, 100, 150, 40)
    setEditTextInputType(w, 2, 2) -- Input type number
    
    -- Checkbox untuk auto scroll
    addCheckBox(w, "Auto Scroll", 10, 150, 200, 30)
    setCheckBoxState(w, 4, true)
    
    -- Checkbox untuk verbose logging
    addCheckBox(w, "Detail Log", 10, 190, 200, 30)
    setCheckBoxState(w, 5, true)
    
    -- Tombol start
    addButton(w, "🚀 START BUYING", 10, 240, 280, 50)
    setButtonTextColor(w, 6, white)
    setButtonBackgroundColor(w, 6, 0xFF4CAF50)
    
    -- Tombol test
    addButton(w, "🧪 TEST COLORS", 10, 300, 135, 40)
    setButtonTextColor(w, 7, white)
    setButtonBackgroundColor(w, 7, 0xFF2196F3)
    
    -- Tombol stop
    addButton(w, "⏹️ STOP", 155, 300, 135, 40)
    setButtonTextColor(w, 8, white)
    setButtonBackgroundColor(w, 8, 0xFFF44336)
    
    -- Status label
    addLabel(w, "Status: Ready", 10, 350, 280, 30)
    setLabelTextColor(w, 9, orange)
end

-- Variabel global
local running = false
local selectedSeed = "Strawberry"
local quantity = 1
local autoScroll = true
local verboseLog = true

-- Fungsi untuk menampilkan log di console
function log(message, color)
    color = color or white
    if verboseLog then
        print(string.format("<font color='#%06X'>%s</font>", color & 0xFFFFFF, message))
    end
end

-- Fungsi untuk update status GUI
function updateStatus(message, color)
    setLabelText(w, 9, "Status: " .. message)
    setLabelTextColor(w, 9, color or orange)
    refreshGUI()
end

-- Fungsi untuk delay dengan feedback
function delayMs(milliseconds)
    if verboseLog then
        log("⏳ Delay " .. milliseconds .. "ms...", blue)
    end
    sleep(milliseconds)
end

-- Fungsi untuk mencari dan tap berdasarkan warna
function tapColor(targetColor, tolerance, area, description)
    tolerance = tolerance or 10
    area = area or {x1=0, y1=0, x2=100, y2=100}
    description = description or "object"
    
    local x, y = findColor(targetColor, tolerance, area)
    if x ~= -1 and y ~= -1 then
        log("🎯 Ditemukan " .. description .. " di: " .. x .. "," .. y, green)
        tap(x, y)
        return true
    else
        log("❌ Gagal menemukan " .. description, red)
        return false
    end
end

-- Fungsi untuk mendapatkan warna berdasarkan nama seed
function getSeedColor(seedName)
    local colorMap = {
        ["Strawberry"] = 0xFFFF0000,    -- Merah
        ["Carrot"] = 0xFFFF5722,        -- Oranye
        ["Tomato"] = 0xFFFF5252,        -- Merah muda
        ["Lettuce"] = 0xFF4CAF50,       -- Hijau
        ["Sunflower"] = 0xFFFFEB3B,     -- Kuning
        ["Rose"] = 0xFFE91E63,          -- Pink
        ["Blueberry"] = 0xFF3F51B5,     -- Biru
        ["Corn"] = 0xFFFFC107,          -- Kuning tua
    }
    
    return colorMap[seedName]
end

-- Fungsi utama pembelian seed
function buySeed(seedName, qty)
    updateStatus("Memulai pembelian " .. seedName, blue)
    log("🌱 MEMULAI PROSES PEMBELIAN: " .. seedName, green)
    log("==================================", blue)
    
    -- Langkah 1: Buka toko
    updateStatus("Mencari toko...", blue)
    log("1. Mencari ikon toko...", white)
    
    -- Coba beberapa kemungkinan warna toko
    local shopFound = false
    local shopColors = {0xFF4CAF50, 0xFF388E3C, 0xFF66BB6A} -- Variasi hijau
    
    for _, color in ipairs(shopColors) do
        if tapColor(color, 20, {x1=900, y1=1800, x2=1080, y2=1920}, "toko") then
            shopFound = true
            break
        end
    end
    
    if not shopFound then
        updateStatus("Gagal menemukan toko", red)
        log("❌ Gagal menemukan toko", red)
        return false
    end
    
    log("✅ Toko berhasil dibuka", green)
    delayMs(2500)
    
    -- Langkah 2: Pilih kategori seeds
    updateStatus("Memilih kategori seeds...", blue)
    log("2. Memilih kategori Seeds...", white)
    
    local seedsCategoryFound = false
    local categoryColors = {0xFFFFD700, 0xFFFFC107, 0xFFFFA000} -- Variasi emas/kuning
    
    for _, color in ipairs(categoryColors) do
        if tapColor(color, 25, {x1=100, y1=300, x2=500, y2=600}, "kategori seeds") then
            seedsCategoryFound = true
            break
        end
    end
    
    if not seedsCategoryFound then
        updateStatus("Gagal menemukan kategori", red)
        log("❌ Gagal menemukan kategori Seeds", red)
        return false
    end
    
    log("✅ Kategori Seeds dipilih", green)
    delayMs(2000)
    
    -- Langkah 3: Cari seed tertentu
    updateStatus("Mencari " .. seedName .. "...", blue)
    log("3. Mencari seed: " .. seedName, white)
    
    local seedFound = false
    local scrollAttempts = 0
    local maxScrolls = 3
    
    while not seedFound and scrollAttempts < maxScrolls and running do
        local seedColor = getSeedColor(seedName)
        if seedColor then
            if tapColor(seedColor, 30, {x1=200, y1=400, x2=900, y2=1600}, seedName) then
                seedFound = true
                log("✅ " .. seedName .. " ditemukan", green)
                delayMs(1500)
                break
            end
        end
        
        -- Auto scroll jika enabled
        if autoScroll and scrollAttempts < maxScrolls - 1 then
            updateStatus("Scroll mencari " .. seedName, blue)
            log("↕️ Scroll ke bawah...", blue)
            swipe(500, 1200, 500, 600, 800)
            delayMs(2500)
        end
        
        scrollAttempts = scrollAttempts + 1
    end
    
    if not seedFound then
        updateStatus(seedName .. " tidak ditemukan", red)
        log("❌ " .. seedName .. " tidak ditemukan", red)
        return false
    end
    
    -- Langkah 4: Pilih quantity
    updateStatus("Memilih quantity...", blue)
    log("4. Memilih quantity: " .. qty, white)
    
    -- Tap tombol plus (qty-1) kali
    for i = 1, qty - 1 do
        if tapColor(0xFF2196F3, 20, {x1=700, y1=1000, x2=800, y2=1100}, "tombol tambah") then
            log("➕ Quantity: " .. (i + 1), blue)
            delayMs(300)
        end
    end
    
    -- Langkah 5: Konfirmasi pembelian
    updateStatus("Mengkonfirmasi pembelian...", blue)
    log("5. Konfirmasi pembelian...", white)
    
    local buyFound = false
    local buyColors = {0xFFFF9800, 0xFFF57C00, 0xFFE65100} -- Variasi oranye
    
    for _, color in ipairs(buyColors) do
        if tapColor(color, 20, {x1=400, y1=1700, x2=700, y2=1850}, "tombol beli") then
            buyFound = true
            break
        end
    end
    
    if not buyFound then
        updateStatus("Gagal konfirmasi", red)
        log("❌ Gagal konfirmasi pembelian", red)
        return false
    end
    
    log("✅ Pembelian dikonfirmasi", green)
    delayMs(2000)
    
    -- Langkah 6: Kembali ke menu utama
    updateStatus("Kembali ke menu...", blue)
    log("6. Kembali ke menu utama...", white)
    
    -- Coba beberapa cara untuk back
    local backFound = tapColor(0xFFF44336, 20, {x1=50, y1=50, x2=150, y2=150}, "tombol back")
    if not backFound then
        keyevent("BACK")
        log("🔙 Back dengan keyevent", blue)
    end
    
    delayMs(1500)
    
    log("==================================", blue)
    log("🎉 PEMBELIAN " .. seedName .. " BERHASIL!", green)
    log("Total yang dibeli: " .. qty .. " seeds", green)
    
    updateStatus("Pembelian berhasil!", green)
    return true
end

-- Fungsi test warna
function testColors()
    updateStatus("Testing warna...", blue)
    log("🧪 MULAI TEST WARNA", blue)
    
    local testAreas = {
        {name = "Toko", area = {x1=900, y1=1800, x2=1080, y2=1920}, colors = {0xFF4CAF50, 0xFF388E3C}},
        {name = "Kategori", area = {x1=100, y1=300, x2=500, y2=600}, colors = {0xFFFFD700, 0xFFFFC107}},
        {name = "Beli", area = {x1=400, y1=1700, x2=700, y2=1850}, colors = {0xFFFF9800, 0xFFF57C00}}
    }
    
    for _, test in ipairs(testAreas) do
        log("🔍 Testing: " .. test.name, white)
        for _, color in ipairs(test.colors) do
            local x, y = findColor(color, 30, test.area)
            if x ~= -1 then
                log("✅ " .. string.format("Warna %X ditemukan di %d,%d", color, x, y), green)
            else
                log("❌ " .. string.format("Warna %X tidak ditemukan", color), red)
            end
            delayMs(500)
        end
    end
    
    updateStatus("Test warna selesai", green)
end

-- Main loop
function mainLoop()
    while running do
        -- Baca input dari GUI
        selectedSeed = getSpinnerValue(w, 1)
        quantity = tonumber(getEditText(w, 2)) or 1
        autoScroll = getCheckBoxState(w, 4)
        verboseLog = getCheckBoxState(w, 5)
        
        -- Batasi quantity
        quantity = math.max(1, math.min(quantity, 10))
        
        -- Jalankan pembelian
        buySeed(selectedSeed, quantity)
        
        -- Tunggu sebelum pembelian berikutnya
        if running then
            updateStatus("Menunggu 5 detik...", blue)
            for i = 5, 1, -1 do
                if not running then break end
                updateStatus("Menunggu " .. i .. "s...", blue)
                delayMs(1000)
            end
        end
    end
end

-- Event handler untuk GUI
function onGuiEvent(id, event)
    if event == 0 then -- Click event
        if id == 6 then -- Start button
            running = true
            setButtonText(w, 6, "⏸️ PAUSE")
            setButtonBackgroundColor(w, 6, 0xFFFF9800)
            updateStatus("Memulai...", blue)
            mainLoop()
            
        elseif id == 7 then -- Test button
            testColors()
            
        elseif id == 8 then -- Stop button
            running = false
            setButtonText(w, 6, "🚀 START BUYING")
            setButtonBackgroundColor(w, 6, 0xFF4CAF50)
            updateStatus("Dihentikan", orange)
            log("⏹️ Script dihentikan oleh user", orange)
        end
    end
end

-- Inisialisasi program
log("🌻 GROW A GARDEN - AUTO BUY SEED", green)
log("GUI Version - Delta Executor", blue)
log("==================================", blue)

-- Buat GUI
initGUI()
setGuiEventListener("onGuiEvent")
updateStatus("GUI Ready - Pilih seed", green)

log("GUI berhasil diinisialisasi", green)
log("Pilih seed dan klik START untuk mulai", white)
