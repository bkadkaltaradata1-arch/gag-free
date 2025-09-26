-- =============================================
-- ROBLOX CHARACTER DEBUG MONITOR - ALL IN ONE
-- Script untuk memantau semua aspek karakter
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ================= CONFIGURASI =================
local CONFIG = {
    -- Level logging: 1=ERROR, 2=WARN, 3=INFO, 4=DEBUG
    LOG_LEVEL = 3,
    
    -- Fitur yang diaktifkan
    FEATURES = {
        MOVEMENT_MONITOR = true,
        HEALTH_MONITOR = true,
        STATE_MONITOR = true,
        TOOL_MONITOR = true,
        ANIMATION_MONITOR = false, -- Hati-hati bisa spam
        PERFORMANCE_MONITOR = true,
        POSITION_LOGGING = true,
        ERROR_HANDLING = true
    },
    
    -- Interval update (detik)
    UPDATE_INTERVAL = 2,
    PERFORMANCE_UPDATE = 5
}

-- ================= VARIABEL GLOBAL =================
local lastPosition = Vector3.new(0, 0, 0)
local lastLogTime = 0
local performanceUpdateTime = 0
local frameCount = 0
local startTime = tick()
local monitors = {}

-- ================= FUNGSI UTILITY =================
function getLogLevelName(level)
    local levels = {[1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "DEBUG"}
    return levels[level] or "UNKNOWN"
end

function debugLog(level, message)
    if level <= CONFIG.LOG_LEVEL then
        local timestamp = os.date("%H:%M:%S")
        local levelName = getLogLevelName(level)
        local output = string.format("[%s][%s] %s", timestamp, levelName, message)
        
        if level <= 2 then
            warn(output)  -- ERROR dan WARN pakai warn()
        else
            print(output) -- INFO dan DEBUG pakai print()
        end
    end
end

function safeConnect(signal, callback, description)
    local success, connection = pcall(function()
        return signal:Connect(function(...)
            local success2, result = pcall(callback, ...)
            if not success2 and CONFIG.FEATURES.ERROR_HANDLING then
                debugLog(1, string.format("Error in %s: %s", description, tostring(result)))
            end
        end)
    end)
    
    if success and connection then
        table.insert(monitors, connection)
        return connection
    else
        debugLog(1, string.format("Failed to connect to %s", description))
        return nil
    end
end

-- ================= MONITORING FUNCTIONS =================
function setupHealthMonitor(humanoid)
    if not CONFIG.FEATURES.HEALTH_MONITOR then return end
    
    safeConnect(humanoid.HealthChanged, function(health)
        debugLog(3, string.format("Health: %.1f/%.1f (%.1f%%)", 
            health, humanoid.MaxHealth, (health/humanoid.MaxHealth)*100))
    end, "Health Monitor")
    
    safeConnect(humanoid.Died, function()
        debugLog(2, "💀 CHARACTER DIED!")
    end, "Death Monitor")
end

function setupStateMonitor(humanoid)
    if not CONFIG.FEATURES.STATE_MONITOR then return end
    
    safeConnect(humanoid.StateChanged, function(oldState, newState)
        if oldState ~= newState then
            debugLog(3, string.format("State: %s → %s", 
                tostring(oldState), tostring(newState)))
        end
    end, "State Monitor")
end

function setupMovementMonitor()
    if not CONFIG.FEATURES.MOVEMENT_MONITOR then return end
    
    local movementConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Monitor posisi
        if CONFIG.FEATURES.POSITION_LOGGING and currentTime - lastLogTime >= CONFIG.UPDATE_INTERVAL then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local currentPosition = rootPart.Position
                local distance = (currentPosition - lastPosition).Magnitude
                
                if distance > 0.5 then -- Hanya log jika bergerak signifikan
                    debugLog(4, string.format("Movement: %.2f studs | Position: (%.1f, %.1f, %.1f)", 
                        distance, currentPosition.X, currentPosition.Y, currentPosition.Z))
                    lastPosition = currentPosition
                end
                
                lastLogTime = currentTime
            end
        end
        
        -- Monitor performance
        if CONFIG.FEATURES.PERFORMANCE_MONITOR and currentTime - performanceUpdateTime >= CONFIG.PERFORMANCE_UPDATE then
            frameCount = frameCount + 1
            local fps = frameCount / (currentTime - performanceUpdateTime)
            local memoryUsage = game:GetService("Stats").MemoryUsageMb
            
            debugLog(4, string.format("Performance: FPS: %.1f | Memory: %.1f MB", fps, memoryUsage))
            
            performanceUpdateTime = currentTime
            frameCount = 0
        end
    end)
    
    table.insert(monitors, movementConnection)
end

function setupToolMonitor()
    if not CONFIG.FEATURES.TOOL_MONITOR then return end
    
    safeConnect(character.ChildAdded, function(child)
        if child:IsA("Tool") then
            debugLog(3, "🔧 Tool equipped: " .. child.Name)
            
            -- Monitor tool activation
            local activateEvent = child:FindFirstChild("Activate")
            if activateEvent then
                safeConnect(activateEvent, function()
                    debugLog(4, "Tool activated: " .. child.Name)
                end, "Tool Activation: " .. child.Name)
            end
        end
    end, "Tool Added Monitor")
    
    safeConnect(character.ChildRemoved, function(child)
        if child:IsA("Tool") then
            debugLog(3, "🔧 Tool unequipped: " .. child.Name)
        end
    end, "Tool Removed Monitor")
end

function setupAnimationMonitor(humanoid)
    if not CONFIG.FEATURES.ANIMATION_MONITOR then return end
    
    local animateScript = character:FindFirstChild("Animate")
    if animateScript then
        debugLog(3, "Animation system found: Animate script")
        -- Bisa ditambahkan monitor animasi spesifik di sini
    end
end

function setupInputMonitor()
    -- Monitor input keyboard/mouse (optional)
    safeConnect(UserInputService.InputBegan, function(input, gameProcessed)
        if not gameProcessed then
            debugLog(4, string.format("Input: %s (Type: %s)", input.KeyCode.Name, input.UserInputType.Name))
        end
    end, "Input Monitor")
end

-- ================= CHARACTER STATUS FUNCTIONS =================
function getDetailedCharacterStatus()
    local status = {
        basic = {},
        humanoid = {},
        parts = {},
        tools = {}
    }
    
    -- Basic info
    status.basic.name = character.Name
    status.basic.childrenCount = #character:GetChildren()
    
    -- Humanoid info
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        status.humanoid.health = humanoid.Health
        status.humanoid.maxHealth = humanoid.MaxHealth
        status.humanoid.state = humanoid:GetState()
        status.humanoid.walkSpeed = humanoid.WalkSpeed
        status.humanoid.jumpPower = humanoid.JumpPower
        status.humanoid.hipHeight = humanoid.HipHeight
    end
    
    -- Part info
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        status.parts.position = rootPart.Position
        status.parts.velocity = rootPart.Velocity
    end
    
    -- Tools info
    status.tools.list = {}
    status.tools.count = 0
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            table.insert(status.tools.list, child.Name)
            status.tools.count = status.tools.count + 1
        end
    end
    
    return status
end

function printCharacterStatus()
    local status = getDetailedCharacterStatus()
    
    debugLog(3, "=== 🎮 CHARACTER STATUS REPORT ===")
    debugLog(3, string.format("Basic: %s (%d children)", status.basic.name, status.basic.childrenCount))
    
    if next(status.humanoid) ~= nil then
        debugLog(3, string.format("Health: %.1f/%.1f | State: %s", 
            status.humanoid.health, status.humanoid.maxHealth, tostring(status.humanoid.state)))
        debugLog(3, string.format("Speed: %.1f | Jump: %.1f | HipHeight: %.1f", 
            status.humanoid.walkSpeed, status.humanoid.jumpPower, status.humanoid.hipHeight))
    end
    
    if status.parts.position then
        debugLog(3, string.format("Position: (%.1f, %.1f, %.1f)", 
            status.parts.position.X, status.parts.position.Y, status.parts.position.Z))
        debugLog(3, string.format("Velocity: (%.1f, %.1f, %.1f) | Speed: %.1f", 
            status.parts.velocity.X, status.parts.velocity.Y, status.parts.velocity.Z, status.parts.velocity.Magnitude))
    end
    
    debugLog(3, string.format("Tools: %d tools - %s", 
        status.tools.count, table.concat(status.tools.list, ", ")))
    debugLog(3, "===================================")
end

-- ================= INITIAL SETUP =================
function initializeMonitors()
    debugLog(3, "🔄 Initializing character monitors...")
    
    -- Setup initial position
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        lastPosition = rootPart.Position
    end
    
    -- Setup semua monitors
    local humanoid = character:WaitForChild("Humanoid")
    
    setupHealthMonitor(humanoid)
    setupStateMonitor(humanoid)
    setupMovementMonitor()
    setupToolMonitor()
    setupAnimationMonitor(humanoid)
    setupInputMonitor()
    
    debugLog(3, "✅ All monitors initialized successfully!")
    printCharacterStatus()
end

function cleanupMonitors()
    debugLog(3, "🧹 Cleaning up monitors...")
    for _, connection in ipairs(monitors) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    monitors = {}
end

-- ================= RESPAWN HANDLING =================
safeConnect(player.CharacterAdded, function(newCharacter)
    debugLog(3, "🔄 Character respawn detected...")
    
    -- Cleanup monitors lama
    cleanupMonitors()
    
    -- Tunggu karakter fully loaded
    wait(1)
    
    -- Update reference karakter
    character = newCharacter
    
    -- Initialize monitors baru
    initializeMonitors()
end, "Respawn Monitor")

-- ================= COMMAND HANDLER =================
function handleCommand(command)
    command = string.lower(command)
    
    if command == "status" then
        printCharacterStatus()
    elseif command == "config" then
        debugLog(3, "=== CONFIGURATION ===")
        for key, value in pairs(CONFIG) do
            if type(value) ~= "table" then
                debugLog(3, string.format("%s: %s", key, tostring(value)))
            end
        end
    elseif command == "help" then
        debugLog(3, "=== COMMANDS ===")
        debugLog(3, "status - Show character status")
        debugLog(3, "config - Show current configuration")
        debugLog(3, "help - Show this help message")
    else
        debugLog(2, "Unknown command: " .. command)
        debugLog(3, "Type 'help' for available commands")
    end
end

-- ================= MAIN EXECUTION =================
debugLog(3, "🚀 Starting Roblox Character Debug Monitor...")
debugLog(3, "Script loaded successfully!")

-- Initialize pertama kali
initializeMonitors()

-- Setup command handler (untuk executor yang support)
if typeof(syn) == "table" or typeof(fluxus) == "table" or getexecutorname then
    debugLog(3, "💬 Command system available! Type 'help' for commands.")
    
    -- Simulate command system (adapt sesuai executor Anda)
    local function setupCommandListener()
        -- Ini contoh, sesuaikan dengan executor yang digunakan
        debugLog(3, "Use: handleCommand('status') to check character")
    end
    setupCommandListener()
end

-- Final message
debugLog(3, "🎯 Debug monitor is running! Check console for updates.")
debugLog(3, "Character changes will be logged automatically.")

return {
    getStatus = printCharacterStatus,
    getConfig = function() return CONFIG end,
    updateConfig = function(newConfig)
        for key, value in pairs(newConfig) do
            if CONFIG[key] ~= nil then
                CONFIG[key] = value
            end
        end
        debugLog(3, "Configuration updated!")
    end,
    handleCommand = handleCommand
}
