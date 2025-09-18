-- Test simple GUI dulu
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()
local Window = library:NewWindow("Test GUI", "Test")

local Tab = Window:NewTab("Test Tab")
local Section = Tab:NewSection("Test Section")
Section:NewButton("Test Button", "Click me", function()
    print("Button works!")
end)

print("Simple GUI loaded - press Insert")