-- Player Section
local PlayerSection = PlayerTab:CreateSection("Player Modifications")

-- Tambahkan tampilan koordinat posisi player
local player = game.Players.LocalPlayer

-- Buat label untuk menampilkan koordinat
local coordinatesLabel = PlayerTab:CreateLabel("Position: Menunggu karakter...")

-- Fungsi untuk memperbarui koordinat
local function updateCoordinates()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = character.HumanoidRootPart
        local position = humanoidRootPart.Position
        coordinatesLabel:SetText(string.format("Position: X: %.2f, Y: %.2f, Z: %.2f", 
            position.X, position.Y, position.Z))
    else
        coordinatesLabel:SetText("Position: Karakter tidak tersedia")
    end
end

-- Jalankan pembaruan koordinat setiap 0.1 detik
spawn(function()
    while true do
        pcall(updateCoordinates) -- Gunakan pcall untuk menangani error
        wait(0.1)
    end
end)

-- Pastikan untuk memperbarui referensi ketika karakter berubah
player.CharacterAdded:Connect(function(newCharacter)
    -- Tunggu sampai HumanoidRootPart tersedia
    newCharacter:WaitForChild("HumanoidRootPart")
    coordinatesLabel:SetText("Position: Karakter ditemukan, memuat koordinat...")
end)

local WalkSpeedSlider = PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        getgenv().WalkSpeed = Value
        setWalkSpeed(Value)
        Rayfield:Notify({
            Title = "Walk Speed",
            Content = "Walk speed set to: " .. Value,
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

local JumpPowerSlider = PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 100},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        getgenv().JumpPower = Value
        setJumpPower(Value)
        Rayfield:Notify({
            Title = "Jump Power",
            Content = "Jump power set to: " .. Value,
            Duration = 3,
            Image = 4483362458,
        })
    end,
})
