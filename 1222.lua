-- Test script untuk cek library
local success, lib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()
end)

if success then
    print("✅ Library loaded successfully!")
    local Window = lib:NewWindow("Test", "Test")
    -- Lanjutkan dengan GUI
else
    print("❌ Library failed to load")
    warn("Error: " .. tostring(lib))
end