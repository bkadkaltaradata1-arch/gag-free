-- FlexibleDebugGUI.lua
-- LocalScript di StarterPlayerScripts
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

player:WaitForChild("PlayerGui")

-- Configuration System
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
        DefaultSize = UDim2.new(0, 400, 0, 300),
        MinSize = UDim2.new(0, 300, 0, 200),
        MaxSize = UDim2.new(0, 800, 0, 600),
        HeaderHeight = 0.12,
        ControlHeight = 0.1
    },
    
    Features = {
        Resizable = true,
        Draggable = true,
        Minimizable = true,
        ThemeSwitcher = true,
        PresetLayouts = true,
        AutoSave = true
    }
}

-- State Management
local GUIState = {
    IsVisible = true,
    IsMinimized = false,
    CurrentTheme = "Dark",
    CurrentLayout = "Default",
    WindowPosition = UDim2.new(0, 10, 0, 10),
    WindowSize = Config.Layout.DefaultSize,
    Tabs = {},
    ActiveTab = ""
}

-- Storage untuk save/load preferences
local function savePreferences()
    local preferences = {
        position = GUIState.WindowPosition,
        size = GUIState.WindowSize,
        theme = GUIState.CurrentTheme,
        layout = GUIState.CurrentLayout,
        minimized = GUIState.IsMinimized
    }
    
    -- Simpan ke player's data atau cache
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
    end
end

-- Theme System
local Themes = {
    Dark = {
        Primary = Color3.fromRGB(25, 25, 35),
        Secondary = Color3.fromRGB(40, 40, 55),
        Accent = Color3.fromRGB(0, 170, 255),
        Text = Color3.fromRGB(240, 240, 240)
    },
    
    Light = {
        Primary = Color3.fromRGB(245, 245, 245),
        Secondary = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(0, 120, 215),
        Text = Color3.fromRGB(30, 30, 30)
    },
    
    Green = {
        Primary = Color3.fromRGB(15, 35, 25),
        Secondary = Color3.fromRGB(30, 60, 45),
        Accent = Color3.fromRGB(76, 175, 80),
        Text = Color3.fromRGB(220, 255, 220)
    },
    
    Purple = {
        Primary = Color3.fromRGB(35, 25, 45),
        Secondary = Color3.fromRGB(55, 40, 70),
        Accent = Color3.fromRGB(156, 39, 176),
        Text = Color3.fromRGB(240, 220, 255)
    }
}

local function applyTheme(themeName)
    local theme = Themes[themeName] or Themes.Dark
    GUIState.CurrentTheme = themeName
    
    -- Apply theme ke semua UI elements
    -- (Implementation details akan diisi nanti)
    
    savePreferences()
end

-- Layout Presets
local LayoutPresets = {
    Default = {
        size = UDim2.new(0, 400, 0, 300),
        position = UDim2.new(0, 10, 0, 10)
    },
    
    Wide = {
        size = UDim2.new(0, 600, 0, 300),
        position = UDim2.new(0, 10, 0, 10)
    },
    
    Tall = {
        size = UDim2.new(0, 400, 0, 500),
        position = UDim2.new(0, 10, 0, 10)
    },
    
    Full = {
        size = UDim2.new(0, 700, 0, 500),
        position = UDim2.new(0, 10, 0, 10)
    }
}

local function applyLayout(layoutName)
    local layout = LayoutPresets[layoutName] or LayoutPresets.Default
    GUIState.CurrentLayout = layoutName
    GUIState.WindowSize = layout.size
    GUIState.WindowPosition = layout.position
    
    -- Apply layout ke UI
    -- (Implementation details akan diisi nanti)
    
    savePreferences()
end

-- UI Factory Functions
local UI = {}

function UI.createFrame(parent, props)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = props.BackgroundColor3 or Config.Theme.Primary
    frame.BackgroundTransparency = props.BackgroundTransparency or 0
    frame.BorderSizePixel = props.BorderSizePixel or 0
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.Visible = props.Visible ~= false
    
    if props.CornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, props.CornerRadius)
        corner.Parent = frame
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
    label.BackgroundTransparency = 1
    label.Size = props.Size or UDim2.new(1, 0, 1, 0)
    label.Position = props.Position or UDim2.new(0, 0, 0, 0)
    label.TextWrapped = props.TextWrapped or false
    label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    
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
    frame.BackgroundTransparency = 1
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.ScrollBarThickness = props.ScrollBarThickness or 8
    frame.CanvasSize = props.CanvasSize or UDim2.new(0, 0, 0, 0)
    
    if parent then
        frame.Parent = parent
    end
    
    return frame
end

-- Main GUI Creation
local function createFlexibleGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlexibleDebugGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player.PlayerGui

    -- Main Container
    local mainContainer = UI.createFrame(screenGui, {
        Size = GUIState.WindowSize,
        Position = GUIState.WindowPosition,
        BackgroundColor3 = Config.Theme.Primary,
        CornerRadius = 8
    })
    
    -- Drop Shadow Effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://2610133241"
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ZIndex = -1
    shadow.Parent = mainContainer

    -- Header Bar
    local header = UI.createFrame(mainContainer, {
        Size = UDim2.new(1, 0, Config.Layout.HeaderHeight, 0),
        BackgroundColor3 = Config.Theme.Secondary,
        CornerRadius = 8
    })

    -- Title
    local title = UI.createTextLabel(header, {
        Text = "🎯 Flexible Debug GUI",
        TextSize = 16,
        TextColor3 = Config.Theme.Accent,
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0.02, 0, 0, 0)
    })

    -- Control Buttons (Minimize, Close, Settings)
    local controlButtons = UI.createFrame(header, {
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(0.7, 0, 0, 0),
        BackgroundTransparency = 1
    })

    local minimizeBtn = UI.createButton(controlButtons, {
        Text = "─",
        Size = UDim2.new(0.3, 0, 0.6, 0),
        Position = UDim2.new(0, 0, 0.2, 0),
        BackgroundColor3 = Config.Theme.Warning,
        CornerRadius = 4
    })

    local settingsBtn = UI.createButton(controlButtons, {
        Text = "⚙️",
        Size = UDim2.new(0.3, 0, 0.6, 0),
        Position = UDim2.new(0.35, 0, 0.2, 0),
        BackgroundColor3 = Config.Theme.Secondary,
        CornerRadius = 4
    })

    local closeBtn = UI.createButton(controlButtons, {
        Text = "✕",
        Size = UDim2.new(0.3, 0, 0.6, 0),
        Position = UDim2.new(0.7, 0, 0.2, 0),
        BackgroundColor3 = Config.Theme.Error,
        CornerRadius = 4
    })

    -- Tab Bar
    local tabBar = UI.createFrame(mainContainer, {
        Size = UDim2.new(1, 0, 0.08, 0),
        Position = UDim2.new(0, 0, Config.Layout.HeaderHeight, 0),
        BackgroundColor3 = Config.Theme.Secondary
    })

    -- Content Area
    local contentArea = UI.createFrame(mainContainer, {
        Size = UDim2.new(1, -10, 1 - Config.Layout.HeaderHeight - 0.08 - 0.1, 0),
        Position = UDim2.new(0, 5, Config.Layout.HeaderHeight + 0.08, 0),
        BackgroundTransparency = 1
    })

    -- Control Panel
    local controlPanel = UI.createFrame(mainContainer, {
        Size = UDim2.new(1, 0, Config.Layout.ControlHeight, 0),
        Position = UDim2.new(0, 0, 1 - Config.Layout.ControlHeight, 0),
        BackgroundColor3 = Config.Theme.Secondary
    })

    -- Resize Handle
    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.new(0, 15, 0, 15)
    resizeHandle.Position = UDim2.new(1, -15, 1, -15)
    resizeHandle.BackgroundColor3 = Config.Theme.Accent
    resizeHandle.BorderSizePixel = 0
    resizeHandle.ZIndex = 10
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = resizeHandle
    
    resizeHandle.Parent = mainContainer

    -- Settings Panel (Hidden by default)
    local settingsPanel = UI.createFrame(mainContainer, {
        Size = UDim2.new(0.8, 0, 0.7, 0),
        Position = UDim2.new(0.1, 0, 0.15, 0),
        BackgroundColor3 = Config.Theme.Primary,
        CornerRadius = 8,
        Visible = false
    })

    -- Apply loaded preferences
    loadPreferences()
    applyTheme(GUIState.CurrentTheme)
    applyLayout(GUIState.CurrentLayout)

    return {
        ScreenGui = screenGui,
        MainContainer = mainContainer,
        Header = header,
        Title = title,
        ContentArea = contentArea,
        TabBar = tabBar,
        ControlPanel = controlPanel,
        ResizeHandle = resizeHandle,
        SettingsPanel = settingsPanel,
        
        -- Control Buttons
        MinimizeBtn = minimizeBtn,
        SettingsBtn = settingsBtn,
        CloseBtn = closeBtn
    }
end

-- Tab Management System
local TabSystem = {}

function TabSystem.createTab(gui, name, icon)
    local tabButton = UI.createButton(gui.TabBar, {
        Text = icon and (icon .. " " .. name) or name,
        Size = UDim2.new(0.2, 0, 0.8, 0),
        Position = UDim2.new(#gui.Tabs * 0.2, 0, 0.1, 0),
        BackgroundColor3 = Config.Theme.Secondary,
        CornerRadius = 4
    })

    local tabContent = UI.createFrame(gui.ContentArea, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = #gui.Tabs == 0 -- First tab visible by default
    })

    local tab = {
        Name = name,
        Button = tabButton,
        Content = tabContent,
        IsActive = #gui.Tabs == 0
    }

    table.insert(gui.Tabs, tab)
    
    if #gui.Tabs == 1 then
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
        tab.Content.Visible = tab.Name == tabName
        tab.Button.BackgroundColor3 = tab.Name == tabName and Config.Theme.Accent or Config.Theme.Secondary
        tab.IsActive = tab.Name == tabName
    end
    GUIState.ActiveTab = tabName
end

function TabSystem.addContentToTab(tab, content)
    content.Parent = tab.Content
    return content
end

-- Interaction System
local InteractionSystem = {}

function InteractionSystem.makeDraggable(gui)
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        gui.MainContainer.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        GUIState.WindowPosition = gui.MainContainer.Position
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

-- Initialize GUI System
local function initializeFlexibleGUI()
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
        gui.ScreenGui.Enabled = false
        GUIState.IsVisible = false
    end)

    gui.MinimizeBtn.MouseButton1Click:Connect(function()
        GUIState.IsMinimized = not GUIState.IsMinimized
        local content = gui.ContentArea.Parent
        content.Visible = not GUIState.IsMinimized
        gui.MinimizeBtn.Text = GUIState.IsMinimized and "□" or "─"
        savePreferences()
    end)

    gui.SettingsBtn.MouseButton1Click:Connect(function()
        gui.SettingsPanel.Visible = not gui.SettingsPanel.Visible
    end)

    -- Create default tabs
    local consoleTab = TabSystem.createTab(gui, "Console", "📟")
    local eventsTab = TabSystem.createTab(gui, "Events", "📡")
    local performanceTab = TabSystem.createTab(gui, "Performance", "⚡")
    local settingsTab = TabSystem.createTab(gui, "Settings", "⚙️")

    -- Add content to tabs
    -- Console Tab
    local consoleScroll = UI.createScrollingFrame(consoleTab.Content, {
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 2, 0)
    })
    
    local consoleText = UI.createTextLabel(consoleScroll, {
        Text = "Debug Console Ready...\n",
        TextWrapped = true,
        Size = UDim2.new(1, -10, 2, 0),
        Position = UDim2.new(0, 5, 0, 5),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })

    -- Hotkey to toggle GUI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F9 then
            GUIState.IsVisible = not GUIState.IsVisible
            gui.ScreenGui.Enabled = GUIState.IsVisible
        elseif input.KeyCode == Enum.KeyCode.F10 then
            GUIState.IsMinimized = not GUIState.IsMinimized
            local content = gui.ContentArea.Parent
            content.Visible = not GUIState.IsMinimized
            gui.MinimizeBtn.Text = GUIState.IsMinimized and "□" or "─"
        end
    end)

    print("🎯 Flexible Debug GUI Initialized!")
    print("F9 - Toggle GUI Visibility")
    print("F10 - Toggle Minimize")

    return gui
end

-- Export public API
local FlexibleDebugGUI = {
    Config = Config,
    GUIState = GUIState,
    Themes = Themes,
    LayoutPresets = LayoutPresets,
    
    initialize = initializeFlexibleGUI,
    createTab = TabSystem.createTab,
    switchTab = TabSystem.switchToTab,
    addToTab = TabSystem.addContentToTab,
    applyTheme = applyTheme,
    applyLayout = applyLayout
}

-- Auto-initialize
spawn(function()
    wait(2)
    local gui = FlexibleDebugGUI.initialize()
    
    -- Example usage:
    local consoleTab = FlexibleDebugGUI.createTab(gui, "Custom", "🌟")
    local customLabel = UI.createTextLabel(consoleTab.Content, {
        Text = "This is a custom tab!",
        TextSize = 16,
        Size = UDim2.new(1, 0, 0.1, 0)
    })
end)

return FlexibleDebugGUI
