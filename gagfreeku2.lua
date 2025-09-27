-- Full Flexible Debug GUI Script

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

-- Wait for player to be ready
player:WaitForChild("PlayerGui")

-- =============================================
-- CONFIGURATION SYSTEM
-- =============================================
local Config = {
    Theme = {
        Primary = Color3.fromRGB(25, 25, 35),
        Secondary = Color3.fromRGB(40, 40, 55),
        Accent = Color3.fromRGB(0, 170, 255),
        Success = Color3.fromRGB(0, 200, 83),
        Warning = Color3.fromRGB(255, 145, 0),
        Error = Color3.fromRGB(255, 50, 50),
        Text = Color3.fromRGB(240, 240, 240),
        TextSecondary = Color3.fromRGB(180, 180, 180)
    },
    
    Layout = {
        DefaultSize = UDim2.new(0, 450, 0, 350),
        MinSize = UDim2.new(0, 300, 0, 200),
        MaxSize = UDim2.new(0, 800, 0, 600),
        HeaderHeight = 0.12,
        ControlHeight = 0.1,
        TabHeight = 0.08
    },
    
    Features = {
        Resizable = true,
        Draggable = true,
        Minimizable = true,
        ThemeSwitcher = true,
        PresetLayouts = true,
        AutoSave = true,
        AutoScan = true
    }
}

-- =============================================
-- STATE MANAGEMENT
-- =============================================
local GUIState = {
    IsVisible = true,
    IsMinimized = false,
    CurrentTheme = "Dark",
    CurrentLayout = "Default",
    WindowPosition = UDim2.new(0, 10, 0, 10),
    WindowSize = Config.Layout.DefaultSize,
    Tabs = {},
    ActiveTab = "",
    DebugLogs = {},
    TrackedEvents = {},
    PerformanceStats = {
        FPS = 0,
        Memory = 0,
        Ping = 0
    }
}

-- =============================================
-- DATA STORAGE SYSTEM
-- =============================================
local function savePreferences()
    local preferences = {
        position = GUIState.WindowPosition,
        size = GUIState.WindowSize,
        theme = GUIState.CurrentTheme,
        layout = GUIState.CurrentLayout,
        minimized = GUIState.IsMinimized,
        visible = GUIState.IsVisible
    }
    
    pcall(function()
        player:SetAttribute("DebugGUI_Preferences", preferences)
    end)
end

local function loadPreferences()
    local success, preferences = pcall(function()
        return player:GetAttribute("DebugGUI_Preferences")
    end)
    
    if success and preferences then
        GUIState.WindowPosition = preferences.position or GUIState.WindowPosition
        GUIState.WindowSize = preferences.size or GUIState.WindowSize
        GUIState.CurrentTheme = preferences.theme or GUIState.CurrentTheme
        GUIState.CurrentLayout = preferences.layout or GUIState.CurrentLayout
        GUIState.IsMinimized = preferences.minimized or false
        GUIState.IsVisible = preferences.visible ~= false
    end
end

-- =============================================
-- THEME SYSTEM
-- =============================================
local Themes = {
    Dark = {
        Primary = Color3.fromRGB(25, 25, 35),
        Secondary = Color3.fromRGB(40, 40, 55),
        Accent = Color3.fromRGB(0, 170, 255),
        Success = Color3.fromRGB(0, 200, 83),
        Warning = Color3.fromRGB(255, 145, 0),
        Error = Color3.fromRGB(255, 50, 50),
        Text = Color3.fromRGB(240, 240, 240),
        TextSecondary = Color3.fromRGB(180, 180, 180)
    },
    
    Light = {
        Primary = Color3.fromRGB(245, 245, 245),
        Secondary = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(0, 120, 215),
        Success = Color3.fromRGB(46, 125, 50),
        Warning = Color3.fromRGB(237, 108, 2),
        Error = Color3.fromRGB(211, 47, 47),
        Text = Color3.fromRGB(30, 30, 30),
        TextSecondary = Color3.fromRGB(80, 80, 80)
    },
    
    Green = {
        Primary = Color3.fromRGB(15, 35, 25),
        Secondary = Color3.fromRGB(30, 60, 45),
        Accent = Color3.fromRGB(76, 175, 80),
        Success = Color3.fromRGB(102, 187, 106),
        Warning = Color3.fromRGB(255, 193, 7),
        Error = Color3.fromRGB(244, 67, 54),
        Text = Color3.fromRGB(220, 255, 220),
        TextSecondary = Color3.fromRGB(180, 220, 180)
    },
    
    Purple = {
        Primary = Color3.fromRGB(35, 25, 45),
        Secondary = Color3.fromRGB(55, 40, 70),
        Accent = Color3.fromRGB(156, 39, 176),
        Success = Color3.fromRGB(102, 187, 106),
        Warning = Color3.fromRGB(255, 193, 7),
        Error = Color3.fromRGB(244, 67, 54),
        Text = Color3.fromRGB(240, 220, 255),
        TextSecondary = Color3.fromRGB(200, 180, 220)
    }
}

-- =============================================
-- LAYOUT PRESETS
-- =============================================
local LayoutPresets = {
    Default = {
        size = UDim2.new(0, 450, 0, 350),
        position = UDim2.new(0, 10, 0, 10)
    },
    
    Wide = {
        size = UDim2.new(0, 600, 0, 350),
        position = UDim2.new(0, 10, 0, 10)
    },
    
    Tall = {
        size = UDim2.new(0, 450, 0, 500),
        position = UDim2.new(0, 10, 0, 10)
    },
    
    Full = {
        size = UDim2.new(0, 700, 0, 500),
        position = UDim2.new(0, 10, 0, 10)
    },
    
    Compact = {
        size = UDim2.new(0, 350, 0, 250),
        position = UDim2.new(0, 10, 0, 10)
    }
}

-- =============================================
-- UI FACTORY SYSTEM
-- =============================================
local UI = {}

function UI.createFrame(parent, props)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = props.BackgroundColor3 or Config.Theme.Primary
    frame.BackgroundTransparency = props.BackgroundTransparency or 0
    frame.BorderSizePixel = props.BorderSizePixel or 0
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.Visible = props.Visible ~= false
    frame.ZIndex = props.ZIndex or 1
    
    if props.CornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, props.CornerRadius)
        corner.Parent = frame
    end
    
    if props.Stroke then
        local stroke = Instance.new("UIStroke")
        stroke.Color = props.StrokeColor or Config.Theme.Secondary
        stroke.Thickness = props.StrokeThickness or 1
        stroke.Parent = frame
    end
    
    if parent then
        frame.Parent = parent
    end
    
    return frame
end

function UI.createTextLabel(parent, props)
    local label = Instance.new("TextLabel")
    label.Text = props.Text or ""
    label.TextColor3 = props.TextColor3 or Config.Theme.Text
    label.TextSize = props.TextSize or 14
    label.Font = props.Font or Enum.Font.Code
    label.BackgroundTransparency = props.BackgroundTransparency or 1
    label.Size = props.Size or UDim2.new(1, 0, 1, 0)
    label.Position = props.Position or UDim2.new(0, 0, 0, 0)
    label.TextWrapped = props.TextWrapped or false
    label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    label.ZIndex = props.ZIndex or 2
    label.RichText = props.RichText or false
    
    if parent then
        label.Parent = parent
    end
    
    return label
end

function UI.createButton(parent, props)
    local button = Instance.new("TextButton")
    button.Text = props.Text or "Button"
    button.TextColor3 = props.TextColor3 or Config.Theme.Text
    button.TextSize = props.TextSize or 14
    button.Font = props.Font or Enum.Font.Code
    button.BackgroundColor3 = props.BackgroundColor3 or Config.Theme.Accent
    button.Size = props.Size or UDim2.new(0, 100, 0, 30)
    button.Position = props.Position or UDim2.new(0, 0, 0, 0)
    button.AutoButtonColor = props.AutoButtonColor ~= false
    button.ZIndex = props.ZIndex or 2
    
    if props.CornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, props.CornerRadius)
        corner.Parent = button
    end
    
    if parent then
        button.Parent = parent
    end
    
    return button
end

function UI.createScrollingFrame(parent, props)
    local frame = Instance.new("ScrollingFrame")
    frame.BackgroundTransparency = props.BackgroundTransparency or 1
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.ScrollBarThickness = props.ScrollBarThickness or 8
    frame.CanvasSize = props.CanvasSize or UDim2.new(0, 0, 0, 0)
    frame.ScrollBarImageColor3 = props.ScrollBarColor or Config.Theme.Accent
    frame.ZIndex = props.ZIndex or 1
    
    if parent then
        frame.Parent = parent
    end
    
    return frame
end

function UI.createTextBox(parent, props)
    local textBox = Instance.new("TextBox")
    textBox.Text = props.Text or ""
    textBox.PlaceholderText = props.PlaceholderText or ""
    textBox.TextColor3 = props.TextColor3 or Config.Theme.Text
    textBox.BackgroundColor3 = props.BackgroundColor3 or Config.Theme.Secondary
    textBox.Size = props.Size or UDim2.new(1, 0, 0, 30)
    textBox.Position = props.Position or UDim2.new(0, 0, 0, 0)
    textBox.Font = props.Font or Enum.Font.Code
    textBox.TextSize = props.TextSize or 14
    textBox.ZIndex = props.ZIndex or 2
    
    if props.CornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, props.CornerRadius)
        corner.Parent = textBox
    end
    
    if parent then
        textBox.Parent = parent
    end
    
    return textBox
end

-- =============================================
-- DEBUG LOGGING SYSTEM
-- =============================================
local DebugLogger = {
    MaxLogs = 100,
    LogTypes = {
        INFO = {Color = Color3.fromRGB(100, 200, 255), Icon = "ℹ️"},
        SUCCESS = {Color = Color3.fromRGB(100, 255, 100), Icon = "✅"},
        WARNING = {Color = Color3.fromRGB(255, 200, 100), Icon = "⚠️"},
        ERROR = {Color = Color3.fromRGB(255, 100, 100), Icon = "❌"},
        EVENT = {Color = Color3.fromRGB(200, 100, 255), Icon = "📡"},
        PERFORMANCE = {Color = Color3.fromRGB(255, 255, 100), Icon = "⚡"}
    }
}

function DebugLogger.addLog(logType, message, data)
    local logInfo = DebugLogger.LogTypes[logType] or DebugLogger.LogTypes.INFO
    local timestamp = os.date("%H:%M:%S")
    
    local logEntry = {
        Type = logType,
        Message = message,
        Data = data,
        Timestamp = timestamp,
        Color = logInfo.Color,
        Icon = logInfo.Icon
    }
    
    table.insert(GUIState.DebugLogs, logEntry)
    
    -- Keep only MaxLogs entries
    if #GUIState.DebugLogs > DebugLogger.MaxLogs then
        table.remove(GUIState.DebugLogs, 1)
    end
    
    return logEntry
end

function DebugLogger.clearLogs()
    GUIState.DebugLogs = {}
end

-- =============================================
-- EVENT TRACKING SYSTEM
-- =============================================
local EventTracker = {
    TrackedEvents = {},
    EventLogs = {}
}

function EventTracker.trackRemoteEvent(remoteEvent)
    if EventTracker.TrackedEvents[remoteEvent] then return end
    
    EventTracker.TrackedEvents[remoteEvent] = true
    
    local connection = remoteEvent.OnClientEvent:Connect(function(...)
        local args = {...}
        local logEntry = DebugLogger.addLog("EVENT", 
            "RemoteEvent Fired: " .. remoteEvent.Name,
            string.format("Args Count: %d\nPath: %s", #args, remoteEvent:GetFullName()))
        
        table.insert(EventTracker.EventLogs, {
            Event = remoteEvent,
            Args = args,
            Timestamp = os.date("%H:%M:%S"),
            LogEntry = logEntry
        })
    end)
    
    return connection
end

function EventTracker.scanAndTrackEvents()
    -- Scan ReplicatedStorage
    for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
        if descendant:IsA("RemoteEvent") then
            EventTracker.trackRemoteEvent(descendant)
        end
    end
    
    -- Scan workspace
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("RemoteEvent") then
            EventTracker.trackRemoteEvent(descendant)
        end
    end
end

-- =============================================
-- PERFORMANCE MONITORING SYSTEM
-- =============================================
local PerformanceMonitor = {
    SampleCount = 60,
    FrameTimes = {},
    LastUpdate = 0
}

function PerformanceMonitor.update()
    local currentTime = tick()
    
    -- Calculate FPS
    table.insert(PerformanceMonitor.FrameTimes, currentTime)
    if #PerformanceMonitor.FrameTimes > PerformanceMonitor.SampleCount then
        table.remove(PerformanceMonitor.FrameTimes, 1)
    end
    
    local fps = 0
    if #PerformanceMonitor.FrameTimes > 1 then
        local timeSpan = PerformanceMonitor.FrameTimes[#PerformanceMonitor.FrameTimes] - PerformanceMonitor.FrameTimes[1]
        fps = math.floor((#PerformanceMonitor.FrameTimes - 1) / timeSpan)
    end
    
    GUIState.PerformanceStats.FPS = fps
    
    -- Update every second
    if currentTime - PerformanceMonitor.LastUpdate >= 1 then
        PerformanceMonitor.LastUpdate = currentTime
        
        -- Memory usage (approximate)
        local memory = math.floor(collectgarbage("count") / 1024) -- Convert to MB
        GUIState.PerformanceStats.Memory = memory
        
        DebugLogger.addLog("PERFORMANCE", 
            string.format("FPS: %d | Memory: %.1fMB", fps, memory))
    end
end

-- =============================================
-- MAIN GUI CREATION
-- =============================================
local function createFlexibleGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlexibleDebugGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = GUIState.IsVisible
    screenGui.Parent = player.PlayerGui

    -- Main Container
    local mainContainer = UI.createFrame(screenGui, {
        Size = GUIState.WindowSize,
        Position = GUIState.WindowPosition,
        BackgroundColor3 = Config.Theme.Primary,
        CornerRadius = 12,
        Stroke = true,
        StrokeColor = Config.Theme.Secondary,
        StrokeThickness = 2
    })
    mainContainer.ZIndex = 10

    -- Header Bar
    local header = UI.createFrame(mainContainer, {
        Size = UDim2.new(1, 0, Config.Layout.HeaderHeight, 0),
        BackgroundColor3 = Config.Theme.Secondary,
        CornerRadius = 12
    })
    header.ZIndex = 11

    -- Title
    local title = UI.createTextLabel(header, {
        Text = "🔧 Flexible Debug GUI v2.0",
        TextSize = 16,
        TextColor3 = Config.Theme.Accent,
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0.02, 0, 0, 0),
        Font = Enum.Font.GothamBold
    })
    title.ZIndex = 12

    -- Control Buttons
    local controlButtons = UI.createFrame(header, {
        Size = UDim2.new(0.35, 0, 1, 0),
        Position = UDim2.new(0.65, 0, 0, 0),
        BackgroundTransparency = 1
    })
    controlButtons.ZIndex = 12

    local minimizeBtn = UI.createButton(controlButtons, {
        Text = GUIState.IsMinimized and "🗖" or "🗕",
        Size = UDim2.new(0.25, 0, 0.6, 0),
        Position = UDim2.new(0, 0, 0.2, 0),
        BackgroundColor3 = Config.Theme.Warning,
        CornerRadius = 6,
        TextSize = 12
    })
    minimizeBtn.ZIndex = 13

    local settingsBtn = UI.createButton(controlButtons, {
        Text = "⚙️",
        Size = UDim2.new(0.25, 0, 0.6, 0),
        Position = UDim2.new(0.26, 0, 0.2, 0),
        BackgroundColor3 = Config.Theme.Secondary,
        CornerRadius = 6,
        TextSize = 12
    })
    settingsBtn.ZIndex = 13

    local themeBtn = UI.createButton(controlButtons, {
        Text = "🎨",
        Size = UDim2.new(0.25, 0, 0.6, 0),
        Position = UDim2.new(0.52, 0, 0.2, 0),
        BackgroundColor3 = Config.Theme.Secondary,
        CornerRadius = 6,
        TextSize = 12
    })
    themeBtn.ZIndex = 13

    local closeBtn = UI.createButton(controlButtons, {
        Text = "✕",
        Size = UDim2.new(0.25, 0, 0.6, 0),
        Position = UDim2.new(0.78, 0, 0.2, 0),
        BackgroundColor3 = Config.Theme.Error,
        CornerRadius = 6,
        TextSize = 12
    })
    closeBtn.ZIndex = 13

    -- Content Area (will be hidden when minimized)
    local contentArea = UI.createFrame(mainContainer, {
        Size = UDim2.new(1, 0, 1 - Config.Layout.HeaderHeight, 0),
        Position = UDim2.new(0, 0, Config.Layout.HeaderHeight, 0),
        BackgroundTransparency = 1,
        Visible = not GUIState.IsMinimized
    })
    contentArea.ZIndex = 11

    -- Tab Bar
    local tabBar = UI.createFrame(contentArea, {
        Size = UDim2.new(1, 0, Config.Layout.TabHeight, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Config.Theme.Secondary
    })
    tabBar.ZIndex = 12

    -- Tab Content Area
    local tabContentArea = UI.createFrame(contentArea, {
        Size = UDim2.new(1, -10, 1 - Config.Layout.TabHeight - 0.05, 0),
        Position = UDim2.new(0, 5, Config.Layout.TabHeight, 0),
        BackgroundTransparency = 1
    })
    tabContentArea.ZIndex = 11

    -- Status Bar
    local statusBar = UI.createFrame(contentArea, {
        Size = UDim2.new(1, 0, 0.05, 0),
        Position = UDim2.new(0, 0, 0.95, 0),
        BackgroundColor3 = Config.Theme.Secondary
    })
    statusBar.ZIndex = 12

    local statusText = UI.createTextLabel(statusBar, {
        Text = "Ready | FPS: 0 | Memory: 0MB",
        TextSize = 11,
        TextColor3 = Config.Theme.TextSecondary,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0)
    })
    statusText.ZIndex = 13

    -- Resize Handle
    local resizeHandle = UI.createFrame(mainContainer, {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 1, -20),
        BackgroundColor3 = Config.Theme.Accent,
        CornerRadius = 4,
        Visible = Config.Features.Resizable
    })
    resizeHandle.ZIndex = 15

    local resizeIcon = UI.createTextLabel(resizeHandle, {
        Text = "⤢",
        TextSize = 12,
        TextColor3 = Config.Theme.Text,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0)
    })
    resizeIcon.ZIndex = 16

    -- Settings Panel (initially hidden)
    local settingsPanel = UI.createFrame(mainContainer, {
        Size = UDim2.new(0.8, 0, 0.7, 0),
        Position = UDim2.new(0.1, 0, 0.15, 0),
        BackgroundColor3 = Config.Theme.Primary,
        CornerRadius = 8,
        Stroke = true,
        StrokeColor = Config.Theme.Accent,
        StrokeThickness = 2,
        Visible = false
    })
    settingsPanel.ZIndex = 20

    local settingsTitle = UI.createTextLabel(settingsPanel, {
        Text = "⚙️ Debug GUI Settings",
        TextSize = 16,
        TextColor3 = Config.Theme.Accent,
        Size = UDim2.new(1, 0, 0.1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.GothamBold
    })
    settingsTitle.ZIndex = 21

    return {
        ScreenGui = screenGui,
        MainContainer = mainContainer,
        Header = header,
        Title = title,
        ContentArea = contentArea,
        TabBar = tabBar,
        TabContentArea = tabContentArea,
        StatusBar = statusBar,
        StatusText = statusText,
        ResizeHandle = resizeHandle,
        SettingsPanel = settingsPanel,
        
        -- Control Buttons
        MinimizeBtn = minimizeBtn,
        SettingsBtn = settingsBtn,
        ThemeBtn = themeBtn,
        CloseBtn = closeBtn,
        
        -- Tabs collection
        Tabs = {}
    }
end

-- =============================================
-- TAB MANAGEMENT SYSTEM
-- =============================================
local TabSystem = {}

function TabSystem.createTab(gui, name, icon, tooltip)
    local tabCount = #gui.Tabs
    local tabWidth = 1 / math.max(4, tabCount + 1) -- Max 4 tabs visible
    
    local tabButton = UI.createButton(gui.TabBar, {
        Text = icon and (icon .. " " .. name) or name,
        Size = UDim2.new(tabWidth - 0.02, 0, 0.8, 0),
        Position = UDim2.new(tabWidth * tabCount + 0.01, 0, 0.1, 0),
        BackgroundColor3 = tabCount == 0 and Config.Theme.Accent or Config.Theme.Secondary,
        CornerRadius = 6,
        TextSize = 11
    })
    tabButton.ZIndex = 13

    local tabContent = UI.createFrame(gui.TabContentArea, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = tabCount == 0 -- First tab visible by default
    })
    tabContent.ZIndex = 11

    local tab = {
        Name = name,
        Icon = icon,
        Button = tabButton,
        Content = tabContent,
        IsActive = tabCount == 0
    }

    table.insert(gui.Tabs, tab)
    
    if tabCount == 0 then
        GUIState.ActiveTab = name
    end

    -- Tab click handler
    tabButton.MouseButton1Click:Connect(function()
        TabSystem.switchToTab(gui, name)
    end)

    return tab
end

function TabSystem.switchToTab(gui, tabName)
    for _, tab in ipairs(gui.Tabs) do
        local isActive = tab.Name == tabName
        tab.Content.Visible = isActive
        tab.Button.BackgroundColor3 = isActive and Config.Theme.Accent or Config.Theme.Secondary
        tab.IsActive = isActive
    end
    GUIState.ActiveTab = tabName
end

-- =============================================
-- INTERACTION SYSTEM
-- =============================================
local InteractionSystem = {}

function InteractionSystem.makeDraggable(gui)
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        
        -- Keep within screen bounds
        local screenSize = gui.ScreenGui.AbsoluteSize
        local containerSize = gui.MainContainer.AbsoluteSize
        newPos = UDim2.new(
            newPos.X.Scale, math.clamp(newPos.X.Offset, 0, screenSize.X - containerSize.X),
            newPos.Y.Scale, math.clamp(newPos.Y.Offset, 0, screenSize.Y - containerSize.Y)
        )
        
        gui.MainContainer.Position = newPos
        GUIState.WindowPosition = newPos
    end

    gui.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = gui.MainContainer.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    savePreferences()
                end
            end)
        end
    end)

    gui.Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput then
            update(input)
        end
    end)
end

function InteractionSystem.makeResizable(gui)
    local resizeInput
    local dragStart
    local startSize

    local function update(input)
        local delta = input.Position - dragStart
        local newSize = UDim2.new(
            startSize.X.Scale, math.max(Config.Layout.MinSize.X.Offset, startSize.X.Offset + delta.X),
            startSize.Y.Scale, math.max(Config.Layout.MinSize.Y.Offset, startSize.Y.Offset + delta.Y)
        )
        
        -- Limit maximum size
        newSize = UDim2.new(
            newSize.X.Scale, math.min(Config.Layout.MaxSize.X.Offset, newSize.X.Offset),
            newSize.Y.Scale, math.min(Config.Layout.MaxSize.Y.Offset, newSize.Y.Offset)
        )
        
        gui.MainContainer.Size = newSize
        GUIState.WindowSize = newSize
    end

    gui.ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startSize = gui.MainContainer.Size
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    savePreferences()
                end
            end)
        end
    end)

    gui.ResizeHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            resizeInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == resizeInput then
            update(input)
        end
    end)
end

-- =============================================
-- CONSOLE SYSTEM
-- =============================================
local ConsoleSystem = {}

function ConsoleSystem.createConsoleTab(gui)
    local consoleTab = TabSystem.createTab(gui, "Console", "📟", "Debug Console")
    
    -- Console controls
    local controlsFrame = UI.createFrame(consoleTab.Content, {
        Size = UDim2.new(1, 0, 0.1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Config.Theme.Secondary,
        CornerRadius = 6
    })
    
    local clearBtn = UI.createButton(controlsFrame, {
        Text = "🧹 Clear",
        Size = UDim2.new(0.15, 0, 0.7, 0),
        Position = UDim2.new(0.02, 0, 0.15, 0),
        BackgroundColor3 = Config.Theme.Warning,
        CornerRadius = 4,
        TextSize = 11
    })
    
    local autoScrollBtn = UI.createButton(controlsFrame, {
        Text = "📜 Auto-Scroll: ON",
        Size = UDim2.new(0.2, 0, 0.7, 0),
        Position = UDim2.new(0.18, 0, 0.15, 0),
        BackgroundColor3 = Config.Theme.Success,
        CornerRadius = 4,
        TextSize = 11
    })
    
    -- Console output
    local consoleScroll = UI.createScrollingFrame(consoleTab.Content, {
        Size = UDim2.new(1, 0, 0.9, 0),
        Position = UDim2.new(0, 0, 0.1, 0),
        CanvasSize = UDim2.new(0, 0, 2, 0),
        ScrollBarThickness = 8
    })
    
    local consoleOutput = UI.createTextLabel(consoleScroll, {
        Text = "🔧 Debug Console Ready!\n" .. os.date("🕒 %H:%M:%S") .. "\n\n",
        TextSize = 12,
        TextColor3 = Config.Theme.Text,
        Size = UDim2.new(1, -10, 2, 0),
        Position = UDim2.new(0, 5, 0, 5),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true
    })
    
    -- Clear button handler
    clearBtn.MouseButton1Click:Connect(function()
        DebugLogger.clearLogs()
        consoleOutput.Text = "🧹 Console Cleared!\n" .. os.date("🕒 %H:%M:%S") .. "\n\n"
        consoleScroll.CanvasSize = UDim2.new(0, 0, 0, consoleOutput.TextBounds.Y + 20)
    end)
    
    -- Auto-scroll toggle
    local autoScroll = true
    autoScrollBtn.MouseButton1Click:Connect(function()
        autoScroll = not autoScroll
        autoScrollBtn.Text = "📜 Auto-Scroll: " .. (autoScroll and "ON" or "OFF")
        autoScrollBtn.BackgroundColor3 = autoScroll and Config.Theme.Success or Config.Theme.Secondary
    end)
    
    -- Function to update console
    local function updateConsole()
        local logText = "🔧 Debug Console\n" .. os.date("🕒 %H:%M:%S") .. "\n\n"
        
        for i, log in ipairs(GUIState.DebugLogs) do
            local logLine = string.format("[%s] %s %s", log.Timestamp, log.Icon, log.Message)
            if log.Data then
                logLine = logLine .. "\n   " .. log.Data
            end
            logText = logText .. logLine .. "\n\n"
        end
        
        consoleOutput.Text = logText
        consoleScroll.CanvasSize = UDim2.new(0, 0, 0, consoleOutput.TextBounds.Y + 20)
        
        if autoScroll then
            consoleScroll.CanvasPosition = Vector2.new(0, consoleScroll.CanvasSize.Y.Offset)
        end
    end
    
    -- Update console periodically
    spawn(function()
        while true do
            wait(0.5)
            if GUIState.ActiveTab == "Console" then
                updateConsole()
            end
        end
    end)
    
    return consoleTab
end

-- =============================================
-- INITIALIZATION
-- =============================================
local function initializeFlexibleGUI()
    -- Load saved preferences
    loadPreferences()
    
    -- Create GUI
    local gui = createFlexibleGUI()
    
    -- Setup interactions
    if Config.Features.Draggable then
        InteractionSystem.makeDraggable(gui)
    end
    
    if Config.Features.Resizable then
        InteractionSystem.makeResizable(gui)
    end

    -- Button handlers
    gui.CloseBtn.MouseButton1Click:Connect(function()
        GUIState.IsVisible = false
        gui.ScreenGui.Enabled = false
        savePreferences()
    end)

    gui.MinimizeBtn.MouseButton1Click:Connect(function()
        GUIState.IsMinimized = not GUIState.IsMinimized
        gui.ContentArea.Visible = not GUIState.IsMinimized
        gui.MinimizeBtn.Text = GUIState.IsMinimized and "🗖" or "🗕"
        savePreferences()
    end)

    gui.SettingsBtn.MouseButton1Click:Connect(function()
        gui.SettingsPanel.Visible = not gui.SettingsPanel.Visible
    end)

    gui.ThemeBtn.MouseButton1Click:Connect(function()
        -- Cycle through themes
        local themes = {"Dark", "Light", "Green", "Purple"}
        local currentIndex = table.find(themes, GUIState.CurrentTheme) or 1
        local nextIndex = (currentIndex % #themes) + 1
        GUIState.CurrentTheme = themes[nextIndex]
        
        -- In a full implementation, this would update all colors
        DebugLogger.addLog("INFO", "Theme changed to: " .. GUIState.CurrentTheme)
        savePreferences()
    end)

    -- Create default tabs
    ConsoleSystem.createConsoleTab(gui)
    TabSystem.createTab(gui, "Events", "📡", "Event Monitor")
    TabSystem.createTab(gui, "Performance", "⚡", "Performance Stats")
    TabSystem.createTab(gui, "Settings", "⚙️", "GUI Settings")

    -- Start performance monitoring
    spawn(function()
        while true do
            PerformanceMonitor.update()
            
            -- Update status bar
            gui.StatusText.Text = string.format("FPS: %d | Memory: %.1fMB | Logs: %d", 
                GUIState.PerformanceStats.FPS, 
                GUIState.PerformanceStats.Memory,
                #GUIState.DebugLogs)
            
            wait(0.1)
        end
    end)

    -- Auto-scan events if enabled
    if Config.Features.AutoScan then
        wait(3)
        EventTracker.scanAndTrackEvents()
        DebugLogger.addLog("SUCCESS", "Auto-scanned and tracked RemoteEvents")
    end

    -- Hotkey system
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F9 then
            GUIState.IsVisible = not GUIState.IsVisible
            gui.ScreenGui.Enabled = GUIState.IsVisible
            savePreferences()
            
        elseif input.KeyCode == Enum.KeyCode.F10 then
            GUIState.IsMinimized = not GUIState.IsMinimized
            gui.ContentArea.Visible = not GUIState.IsMinimized
            gui.MinimizeBtn.Text = GUIState.IsMinimized and "🗖" or "🗕"
            savePreferences()
            
        elseif input.KeyCode == Enum.KeyCode.F11 then
            -- Quick log test
            DebugLogger.addLog("INFO", "Hotkey test log", "F11 pressed at " .. os.date("%H:%M:%S"))
        end
    end)

    -- Initial log
    DebugLogger.addLog("SUCCESS", "Flexible Debug GUI Initialized!", 
        string.format("Version 2.0 | Theme: %s | Tabs: %d", 
        GUIState.CurrentTheme, #gui.Tabs))

    print("🎯 Flexible Debug GUI v2.0 Loaded!")
    print("F9 - Toggle GUI")
    print("F10 - Toggle Minimize") 
    print("F11 - Test Log")

    return gui
end

-- =============================================
-- AUTO-START
-- =============================================
spawn(function()
    wait(2) -- Wait for game to fully load
    
    local success, errorMsg = pcall(function()
        local gui = initializeFlexibleGUI()
        
        -- Public API
        _G.DebugGUI = {
            log = function(type, message, data)
                DebugLogger.addLog(type, message, data)
            end,
            
            clear = function()
                DebugLogger.clearLogs()
            end,
            
            trackEvent = function(remoteEvent)
                return EventTracker.trackRemoteEvent(remoteEvent)
            end
        }
    end)
    
    if not success then
        warn("❌ Failed to initialize Debug GUI: " .. tostring(errorMsg))
    end
end)

-- Return the API for external use
return {
    Config = Config,
    Themes = Themes,
    LayoutPresets = LayoutPresets
}
