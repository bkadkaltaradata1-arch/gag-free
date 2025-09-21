-- Script Grow a Garden - Pembelian Seed
-- Untuk Delta Executor Android
-- by [Nama Anda]

-- Konfigurasi warna
local white = 0xFFFFFFFF
local green = 0xFF00FF00
local red = 0xFFFF0000
local blue = 0xFF0000FF

-- Fungsi untuk menampilkan log di console
function log(message, color)
    color = color or white
    print(string.format("<font color='#%06X'>%s</font>", color & 0xFFFFFF, message))
end

-- Fungsi untuk delay dengan feedback
function delayMs(milliseconds)
    log("⏳ Delay " .. milliseconds .. "ms...", blue)
    sleep(milliseconds)
end

-- Fungsi untuk mencari dan tap berdasarkan warna
function tapColor(targetColor, tolerance, area)
    tolerance = tolerance or 10
    area = area or {x1=0, y1=0, x2=100, y2=100}
    
    local x, y = findColor(targetColor, tolerance, area)
    if x ~= -1 and y ~= -1 then
        log("🎯 Ditemukan target warna di: " .. x .. "," .. y, green)
        tap(x, y)
        return true
    end
    return false
end

-- Fungsi utama pembelian seed
function buySeed(seedName, quantity)
    log("🌱 MEMULAI PROSES PEMBELIAN: " .. seedName, green)
    log("==================================", blue)
    
    -- Langkah 1: Buka toko
    log("1. Mencari ikon toko...", white)
    if tapColor(0xFF4CAF50, 15, {x1=900, y1=1800, x2=1080, y2=1920}) then -- Warna hijau toko
        delayMs(2000)
        log("✅ Toko berhasil dibuka", green)
    else
        log("❌ Gagal menemukan toko", red)
        return false
    end
    
    -- Langkah 2: Pilih kategori seeds
    log("2. Memilih kategori Seeds...", white)
    delayMs(1500)
    if tapColor(0xFFFFD700, 20, {x1=100, y1=300, x2=500, y2=600}) then -- Warna emas kategori seeds
        delayMs(2000)
        log("✅ Kategori Seeds dipilih", green)
    else
        log("❌ Gagal menemukan kategori Seeds", red)
        return false
    end
    
    -- Langkah 3: Cari seed tertentu berdasarkan nama
    log("3. Mencari seed: " .. seedName, white)
    delayMs(1000)
    
    local seedFound = false
    local scrollAttempts = 0
    local maxScrolls = 5
    
    while not seedFound and scrollAttempts < maxScrolls do
        -- Cari berdasarkan warna karakteristik seed (contoh: merah untuk strawberry)
        local seedColor = getSeedColor(seedName)
        if seedColor then
            if tapColor(seedColor, 25, {x1=200, y1=400, x2=900, y2=1600}) then
                seedFound = true
                log("✅ " .. seedName .. " ditemukan", green)
                delayMs(1500)
                break
            end
        end
        
        -- Jika tidak ditemukan, scroll ke bawah
        log("↕️ Scroll ke bawah...", blue)
        swipe(500, 1200, 500, 800, 500)
        delayMs(2000)
        scrollAttempts = scrollAttempts + 1
    end
    
    if not seedFound then
        log("❌ " .. seedName .. " tidak ditemukan", red)
        return false
    end
    
    -- Langkah 4: Pilih quantity
    log("4. Memilih quantity: " .. quantity, white)
    delayMs(1000)
    
    for i = 1, quantity - 1 do
        if tapColor(0xFF2196F3, 15, {x1=700, y1=1000, x2=800, y2=1100}) then -- Tombol tambah
            log("➕ Quantity ditambah: " .. (i + 1), blue)
            delayMs(500)
        end
    end
    
    -- Langkah 5: Konfirmasi pembelian
    log("5. Konfirmasi pembelian...", white)
    delayMs(1000)
    if tapColor(0xFFFF9800, 15, {x1=400, y1=1700, x2=700, y2=1850}) then -- Tombol beli oranye
        delayMs(2000)
        log("✅ Pembelian dikonfirmasi", green)
    else
        log("❌ Gagal konfirmasi pembelian", red)
        return false
    end
    
    -- Langkah 6: Kembali ke menu utama
    log("6. Kembali ke menu utama...", white)
    delayMs(1500)
    if tapColor(0xFFF44336, 15, {x1=50, y1=50, x2=150, y2=150}) then -- Tombol back merah
        delayMs(2000)
        log("✅ Kembali ke menu utama", green)
    else
        -- Alternatif back button
        keyevent("BACK")
        delayMs(1000)
    end
    
    log("==================================", blue)
    log("🎉 PEMBELIAN " .. seedName .. " BERHASIL!", green)
    log("Total yang dibeli: " .. quantity .. " seeds", green)
    return true
end

-- Fungsi helper untuk mendapatkan warna berdasarkan nama seed
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
    
    return colorMap[seedName] or 0xFFFFFFFF -- Default putih jika tidak ditemukan
end

-- Fungsi untuk test semua seed yang tersedia
function testAllSeeds()
    local seeds = {"Strawberry", "Carrot", "Tomato", "Lettuce", "Sunflower"}
    
    for i, seed in ipairs(seeds) do
        log("🧪 TESTING: " .. seed, blue)
        if buySeed(seed, 1) then
            log("✅ TEST BERHASIL: " .. seed, green)
        else
            log("❌ TEST GAGAL: " .. seed, red)
        end
        delayMs(3000)
    end
end

-- Menu utama
function main()
    log("🌻 GROW A GARDEN - AUTO BUY SEED", green)
    log("==================================", blue)
    log("Pilihan menu:", white)
    log("1. Beli Strawberry (3x)", white)
    log("2. Beli Carrot (2x)", white)
    log("3. Beli Tomato (1x)", white)
    log("4. Test semua seed", white)
    log("5. Custom purchase", white)
    log("==================================", blue)
    
    local choice = input("Masukkan pilihan (1-5): ")
    
    if choice == "1" then
        buySeed("Strawberry", 3)
    elseif choice == "2" then
        buySeed("Carrot", 2)
    elseif choice == "3" then
        buySeed("Tomato", 1)
    elseif choice == "4" then
        testAllSeeds()
    elseif choice == "5" then
        local seed = input("Nama seed: ")
        local qty = tonumber(input("Quantity: "))
        if seed and qty then
            buySeed(seed, qty)
        end
    else
        log("❌ Pilihan tidak valid", red)
    end
end

-- Jalankan program
log("🚀 Script Grow a Garden dimulai...", green)
delayMs(1000)

-- Tunggu game terbuka (opsional)
log("⏳ Menunggu game terbuka...", blue)
delayMs(3000)

-- Jalankan menu utama
main()

log("==================================", blue)
log("📝 Script selesai dijalankan", green)
log("Tekan stop untuk menghentikan", blue)
