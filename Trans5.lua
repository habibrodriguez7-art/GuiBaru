-- LynxGUI v3.0 - Zero Memory Leak Edition
-- Complete rewrite with optimized architecture
-- FREE NOT FOR SALE

repeat task.wait() until game:IsLoaded()

-- ============================================
-- ANTI-DUPLICATE SYSTEM
-- ============================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer
repeat task.wait() until localPlayer:FindFirstChild("PlayerGui")

local existingGUI = CoreGui:FindFirstChild("LynxGUI_Galaxy")
if existingGUI then
    existingGUI:Destroy()
    task.wait(0.1)
end

-- ============================================
-- SERVICES (Cached once)
-- ============================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- CONNECTION MANAGER - Anti Memory Leak
-- ============================================
local ConnectionManager = {
    _connections = {},
    _spawns = {}
}

function ConnectionManager:Add(name, connection)
    if self._connections[name] then
        pcall(function() self._connections[name]:Disconnect() end)
    end
    self._connections[name] = connection
    return connection
end

function ConnectionManager:AddSpawn(name, thread)
    if self._spawns[name] then
        pcall(function() task.cancel(self._spawns[name]) end)
    end
    self._spawns[name] = thread
    return thread
end

function ConnectionManager:Remove(name)
    if self._connections[name] then
        pcall(function() self._connections[name]:Disconnect() end)
        self._connections[name] = nil
    end
end

function ConnectionManager:Cleanup()
    for name, conn in pairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    for name, thread in pairs(self._spawns) do
        pcall(function() task.cancel(thread) end)
    end
    table.clear(self._connections)
    table.clear(self._spawns)
end

-- ============================================
-- OPTIMIZED INSTANCE CREATOR
-- ============================================
local function new(class, props)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    return inst
end

-- ============================================
-- COLOR PALETTE
-- ============================================
local colors = {
    primary = Color3.fromRGB(255, 140, 0),
    secondary = Color3.fromRGB(147, 112, 219),
    accent = Color3.fromRGB(186, 85, 211),
    success = Color3.fromRGB(34, 197, 94),
    bg1 = Color3.fromRGB(10, 10, 10),
    bg2 = Color3.fromRGB(18, 18, 18),
    bg3 = Color3.fromRGB(25, 25, 25),
    bg4 = Color3.fromRGB(35, 35, 35),
    text = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(180, 180, 180),
    textDimmer = Color3.fromRGB(120, 120, 120),
    border = Color3.fromRGB(50, 50, 50),
}

-- ============================================
-- WINDOW CONFIGURATION
-- ============================================
local windowSize = UDim2.new(0, 400, 0, 260)
local minWindowSize = Vector2.new(360, 230)
local maxWindowSize = Vector2.new(520, 360)
local sidebarWidth = 130

-- ============================================
-- CONFIG SYSTEM
-- ============================================
local CONFIG_FOLDER = "LynxGUI_Configs"
local CONFIG_FILE = CONFIG_FOLDER .. "/lynx_config.json"

local DefaultConfig = {
    InstantFishing = { Mode = "Fast", Enabled = false, FishingDelay = 1.30, CancelDelay = 0.19 },
    BlatantTester = { Enabled = false, CompleteDelay = 0.5, CancelDelay = 0.1 },
    BlatantV1 = { Enabled = false, CompleteDelay = 0.05, CancelDelay = 0.1 },
    UltraBlatant = { Enabled = false, CompleteDelay = 0.05, CancelDelay = 0.1 },
    FastAutoPerfect = { Enabled = false, FishingDelay = 0.05, CancelDelay = 0.01, TimeoutDelay = 0.8 },
    Support = {
        NoFishingAnimation = false, PingFPSMonitor = false, LockPosition = false,
        AutoEquipRod = false, DisableCutscenes = false, DisableObtainedNotif = false,
        DisableSkinEffect = false, WalkOnWater = false, GoodPerfectionStable = false,
        SkinAnimation = { Enabled = false, Current = "Eclipse" }
    },
    AutoFavorite = { EnabledTiers = {}, EnabledVariants = {} },
    Teleport = { SavedLocation = nil, LastEventSelected = nil, AutoTeleportEvent = false },
    Shop = { AutoSellTimer = { Enabled = false, Interval = 5 }, AutoBuyWeather = { Enabled = false, SelectedWeathers = {} } },
    Webhook = { Enabled = false, URL = "", DiscordID = "", EnabledRarities = {} },
    CameraView = { UnlimitedZoom = false, Freecam = { Enabled = false, Speed = 50, Sensitivity = 0.3 } },
    Settings = { AntiAFK = false, Sprint = false, InfiniteJump = false, FPSBooster = false, DisableRendering = false, FPSLimit = 60, HideStats = { Enabled = false, FakeName = "Guest", FakeLevel = "1" } }
}

local CurrentConfig = {}
local isDirty = false
local saveScheduled = false

local function DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = type(v) == "table" and DeepCopy(v) or v
    end
    return copy
end

local function MergeTables(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            MergeTables(target[k], v)
        else
            target[k] = v
        end
    end
end

local function EnsureFolderExists()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end

local ConfigSystem = {}

function ConfigSystem.Save()
    local success = pcall(function()
        EnsureFolderExists()
        writefile(CONFIG_FILE, HttpService:JSONEncode(CurrentConfig))
    end)
    return success
end

function ConfigSystem.Load()
    EnsureFolderExists()
    CurrentConfig = DeepCopy(DefaultConfig)
    if isfile(CONFIG_FILE) then
        pcall(function()
            local loaded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            MergeTables(CurrentConfig, loaded)
        end)
    end
    return CurrentConfig
end

function ConfigSystem.Get(path, default)
    if not path then return default end
    local value = CurrentConfig
    for key in string.gmatch(path, "[^.]+") do
        if type(value) ~= "table" then return default end
        value = value[key]
    end
    return value ~= nil and value or default
end

function ConfigSystem.Set(path, value)
    if not path then return end
    local keys = {}
    for key in string.gmatch(path, "[^.]+") do table.insert(keys, key) end
    local target = CurrentConfig
    for i = 1, #keys - 1 do
        if type(target[keys[i]]) ~= "table" then target[keys[i]] = {} end
        target = target[keys[i]]
    end
    target[keys[#keys]] = value
end

local function MarkDirty()
    isDirty = true
    if saveScheduled then return end
    saveScheduled = true
    task.delay(5, function()
        if isDirty then ConfigSystem.Save() isDirty = false end
        saveScheduled = false
    end)
end

CurrentConfig = ConfigSystem.Load()

-- ============================================
-- SECURITY LOADER & MODULES
-- ============================================
local SecurityLoader = loadstring(game:HttpGet("https://raw.githubusercontent.com/habibrodriguez7-art/GuiBaru/refs/heads/main/SecurityLoader.lua"))()
local CombinedModules = SecurityLoader.LoadModule("CombinedModules")

local instant = CombinedModules.instant
local instant2 = CombinedModules.instant2
local blatantv1 = CombinedModules.blatantv1
local UltraBlatant = CombinedModules.UltraBlatant
local blatantv2fix = CombinedModules.BlatantFixedV1
local blatantv2 = CombinedModules.blatantv2
local NoFishingAnimation = CombinedModules.NoFishingAnimation
local LockPosition = CombinedModules.LockPosition
local DisableCutscenes = CombinedModules.DisableCutscenes
local DisableExtras = CombinedModules.DisableExtras
local AutoTotem3X = CombinedModules.AutoTotem3X
local SkinAnimation = CombinedModules.SkinSwapAnimation
local WalkOnWater = CombinedModules.WalkOnWater
local TeleportModule = CombinedModules.TeleportModule
local TeleportToPlayer = CombinedModules.TeleportToPlayer
local SavedLocation = CombinedModules.SavedLocation
local AutoSellSystem = CombinedModules.AutoSellSystem
local MerchantSystem = CombinedModules.MerchantSystem
local RemoteBuyer = CombinedModules.RemoteBuyer
local FreecamModule = CombinedModules.FreecamModule
local UnlimitedZoomModule = CombinedModules.UnlimitedZoom
local AntiAFK = CombinedModules.AntiAFK
local UnlockFPS = CombinedModules.UnlockFPS
local FPSBooster = CombinedModules.FPSBooster
local AutoBuyWeather = CombinedModules.AutoBuyWeather
local Notify = CombinedModules.NotificationModule
local GoodPerfectionStable = CombinedModules.GoodPerfectionStable
local PingFPSMonitor = CombinedModules.PingPanel
local DisableRendering = CombinedModules.DisableRendering
local MovementModule = CombinedModules.MovementModule
local AutoFavorite = CombinedModules.AutoFavorite
local WebhookModule = CombinedModules.Webhook
local HideStats = CombinedModules.HideStats
local EventTeleport = CombinedModules.EventTeleportDynamic or {
    GetEventNames = function() return {"- Module Not Loaded -"} end,
    HasCoords = function() return false end,
    Start = function() return false end,
    Stop = function() return true end,
    TeleportNow = function() return false end
}

-- ============================================
-- MAIN GUI CONTAINER
-- ============================================
local gui = new("ScreenGui", {
    Name = "LynxGUI_Galaxy",
    Parent = CoreGui,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 2147483647
})

local function bringToFront()
    gui.DisplayOrder = 2147483647
end

-- Main Window
local win = new("Frame", {
    Parent = gui,
    Size = windowSize,
    Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
    BackgroundColor3 = colors.bg1,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    ZIndex = 3
})
new("UICorner", {Parent = win, CornerRadius = UDim.new(0, 8)})

-- Sidebar
local sidebar = new("Frame", {
    Parent = win,
    Size = UDim2.new(0, sidebarWidth, 1, -45),
    Position = UDim2.new(0, 0, 0, 45),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.7,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 4
})
new("UICorner", {Parent = sidebar, CornerRadius = UDim.new(0, 8)})

-- Header
local scriptHeader = new("Frame", {
    Parent = win,
    Size = UDim2.new(1, 0, 0, 45),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.7,
    BorderSizePixel = 0,
    ZIndex = 5
})
new("UICorner", {Parent = scriptHeader, CornerRadius = UDim.new(0, 8)})

-- Drag Handle
local headerDragHandle = new("Frame", {
    Parent = scriptHeader,
    Size = UDim2.new(0, 40, 0, 3),
    Position = UDim2.new(0.5, -20, 0, 8),
    BackgroundColor3 = colors.primary,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    ZIndex = 6
})
new("UICorner", {Parent = headerDragHandle, CornerRadius = UDim.new(1, 0)})

-- Title
new("TextLabel", {
    Parent = scriptHeader,
    Text = "LynX",
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(0, 15, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = colors.primary,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6
})

new("ImageLabel", {
    Parent = scriptHeader,
    Image = "rbxassetid://104332967321169",
    Size = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(0, 66, 0.5, -10),
    BackgroundTransparency = 1,
    ImageColor3 = colors.primary,
    ZIndex = 6
})

local separator = new("Frame", {
    Parent = scriptHeader,
    Size = UDim2.new(0, 2, 0, 24),
    Position = UDim2.new(0, 115, 0.5, -12),
    BackgroundColor3 = colors.primary,
    BackgroundTransparency = 0.7,
    BorderSizePixel = 0,
    ZIndex = 6
})
new("UICorner", {Parent = separator, CornerRadius = UDim.new(1, 0)})

new("TextLabel", {
    Parent = scriptHeader,
    Text = "Free Not For Sale",
    Size = UDim2.new(0, 160, 1, 0),
    Position = UDim2.new(0, 145, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = colors.textDim,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTransparency = 0.3,
    ZIndex = 6
})

-- Minimize Button
local btnMinHeader = new("TextButton", {
    Parent = scriptHeader,
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -38, 0.5, -15),
    BackgroundColor3 = colors.bg4,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    Text = "─",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = colors.textDim,
    TextTransparency = 0.3,
    AutoButtonColor = false,
    ZIndex = 7
})
new("UICorner", {Parent = btnMinHeader, CornerRadius = UDim.new(0, 8)})

-- Navigation Container
local navContainer = new("ScrollingFrame", {
    Parent = sidebar,
    Size = UDim2.new(1, -8, 1, -12),
    Position = UDim2.new(0, 4, 0, 6),
    BackgroundTransparency = 1,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = colors.primary,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 5
})
new("UIListLayout", {Parent = navContainer, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})

-- Content Area
local contentBg = new("Frame", {
    Parent = win,
    Size = UDim2.new(1, -(sidebarWidth + 10), 1, -52),
    Position = UDim2.new(0, sidebarWidth + 5, 0, 47),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 4
})
new("UICorner", {Parent = contentBg, CornerRadius = UDim.new(0, 8)})

-- Top Bar
local topBar = new("Frame", {
    Parent = contentBg,
    Size = UDim2.new(1, -8, 0, 32),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    ZIndex = 5
})
new("UICorner", {Parent = topBar, CornerRadius = UDim.new(0, 10)})

local pageTitle = new("TextLabel", {
    Parent = topBar,
    Text = "Main Dashboard",
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BackgroundTransparency = 1,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6
})

-- Resize Handle
local resizeHandle = new("TextButton", {
    Parent = win,
    Size = UDim2.new(0, 18, 0, 18),
    Position = UDim2.new(1, -18, 1, -18),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.7,
    BorderSizePixel = 0,
    Text = "⋰",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.textDim,
    TextTransparency = 0.4,
    AutoButtonColor = false,
    ZIndex = 100
})
new("UICorner", {Parent = resizeHandle, CornerRadius = UDim.new(0, 6)})

-- ============================================
-- PAGES SYSTEM
-- ============================================
local pages = {}
local currentPage = "Main"
local navButtons = {}

local function createPage(name)
    local page = new("ScrollingFrame", {
        Parent = contentBg,
        Size = UDim2.new(1, -16, 1, -44),
        Position = UDim2.new(0, 8, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = colors.primary,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 5
    })
    new("UIListLayout", {Parent = page, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
    new("UIPadding", {Parent = page, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)})
    pages[name] = page
    return page
end

local mainPage = createPage("Main")
local teleportPage = createPage("Teleport")
local shopPage = createPage("Shop")
local webhookPage = createPage("Webhook")
local cameraViewPage = createPage("CameraView")
local settingsPage = createPage("Settings")
local infoPage = createPage("Info")
mainPage.Visible = true

-- ============================================
-- CALLBACK REGISTRY
-- ============================================
local CallbackRegistry = {}

local function RegisterCallback(configPath, callback, componentType, defaultValue)
    if configPath then
        table.insert(CallbackRegistry, {path = configPath, callback = callback, type = componentType, default = defaultValue})
    end
end

local function ExecuteConfigCallbacks()
    for _, entry in ipairs(CallbackRegistry) do
        local value = ConfigSystem.Get(entry.path, entry.default)
        if entry.callback then entry.callback(value) end
    end
end

-- ============================================
-- NAVIGATION BUTTON
-- ============================================
local function createNavButton(text, imageId, page, order)
    local btn = new("TextButton", {
        Parent = navContainer,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = page == currentPage and colors.bg3 or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = page == currentPage and 0.75 or 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 6
    })
    new("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
    
    local indicator = new("Frame", {
        Parent = btn,
        Size = UDim2.new(0, 3, 0, 20),
        Position = UDim2.new(0, 0, 0.5, -10),
        BackgroundColor3 = colors.primary,
        BorderSizePixel = 0,
        Visible = page == currentPage,
        ZIndex = 7
    })
    new("UICorner", {Parent = indicator, CornerRadius = UDim.new(1, 0)})
    
    new("ImageLabel", {
        Parent = btn,
        Image = imageId,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 10, 0.5, -8),
        BackgroundTransparency = 1,
        ImageColor3 = page == currentPage and colors.primary or colors.textDim,
        ImageTransparency = page == currentPage and 0 or 0.3,
        ZIndex = 7,
        Name = "Icon"
    })
    
    new("TextLabel", {
        Parent = btn,
        Text = text,
        Size = UDim2.new(1, -45, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = page == currentPage and colors.text or colors.textDim,
        TextTransparency = page == currentPage and 0.1 or 0.4,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
        Name = "Label"
    })
    
    navButtons[page] = {btn = btn, indicator = indicator}
    return btn
end

-- ============================================
-- PAGE SWITCHING
-- ============================================
local function switchPage(pageName, titleText)
    if currentPage == pageName then return end
    for _, page in pairs(pages) do page.Visible = false end
    
    for name, data in pairs(navButtons) do
        local isActive = name == pageName
        data.btn.BackgroundColor3 = isActive and colors.bg3 or Color3.fromRGB(0, 0, 0)
        data.btn.BackgroundTransparency = isActive and 0.75 or 1
        local icon = data.btn:FindFirstChild("Icon")
        if icon then
            icon.ImageColor3 = isActive and colors.primary or colors.textDim
            icon.ImageTransparency = isActive and 0 or 0.3
        end
        local label = data.btn:FindFirstChild("Label")
        if label then
            label.TextColor3 = isActive and colors.text or colors.textDim
            label.TextTransparency = isActive and 0.1 or 0.4
        end
        data.indicator.Visible = isActive
    end
    
    pages[pageName].Visible = true
    pageTitle.Text = titleText
    currentPage = pageName
end

-- Create nav buttons
local btnMain = createNavButton("Dashboard", "rbxassetid://86450224791749", "Main", 1)
local btnTeleport = createNavButton("Teleport", "rbxassetid://78381660144034", "Teleport", 2)
local btnShop = createNavButton("Shop", "rbxassetid://103366101391777", "Shop", 3)
local btnWebhook = createNavButton("Webhook", "rbxassetid://122775063389583", "Webhook", 4)
local btnCameraView = createNavButton("Camera View", "rbxassetid://76857749595149", "CameraView", 5)
local btnSettings = createNavButton("Settings", "rbxassetid://99707154377618", "Settings", 6)
local btnInfo = createNavButton("About", "rbxassetid://79942787163167", "Info", 7)

ConnectionManager:Add("navMain", btnMain.MouseButton1Click:Connect(function() switchPage("Main", "Main Dashboard") end))
ConnectionManager:Add("navTeleport", btnTeleport.MouseButton1Click:Connect(function() switchPage("Teleport", "Teleport System") end))
ConnectionManager:Add("navShop", btnShop.MouseButton1Click:Connect(function() switchPage("Shop", "Shop Features") end))
ConnectionManager:Add("navWebhook", btnWebhook.MouseButton1Click:Connect(function() switchPage("Webhook", "Webhook Page") end))
ConnectionManager:Add("navCameraView", btnCameraView.MouseButton1Click:Connect(function() switchPage("CameraView", "Camera View Settings") end))
ConnectionManager:Add("navSettings", btnSettings.MouseButton1Click:Connect(function() switchPage("Settings", "Settings") end))
ConnectionManager:Add("navInfo", btnInfo.MouseButton1Click:Connect(function() switchPage("Info", "About Lynx") end))

-- ============================================
-- UI COMPONENTS
-- ============================================

-- CATEGORY
local function makeCategory(parent, title)
    local categoryFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 6
    })
    new("UICorner", {Parent = categoryFrame, CornerRadius = UDim.new(0, 6)})
    
    local header = new("TextButton", {
        Parent = categoryFrame,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 7
    })
    
    new("TextLabel", {
        Parent = header,
        Text = title,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local arrow = new("TextLabel", {
        Parent = header,
        Text = "▼",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -24, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = colors.primary,
        ZIndex = 8
    })
    
    local contentContainer = new("Frame", {
        Parent = categoryFrame,
        Size = UDim2.new(1, -16, 0, 0),
        Position = UDim2.new(0, 8, 0, 38),
        BackgroundTransparency = 1,
        Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 7
    })
    new("UIListLayout", {Parent = contentContainer, Padding = UDim.new(0, 6)})
    new("UIPadding", {Parent = contentContainer, PaddingBottom = UDim.new(0, 8)})
    
    local isOpen = false
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        contentContainer.Visible = isOpen
        arrow.Rotation = isOpen and 180 or 0
        categoryFrame.BackgroundTransparency = isOpen and 0.5 or 0.7
    end)
    
    return contentContainer
end

-- TOGGLE
local function makeToggle(parent, label, configPath, callback)
    local frame = new("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, ZIndex = 7})
    
    new("TextLabel", {
        Parent = frame,
        Text = label,
        Size = UDim2.new(0.68, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextColor3 = colors.text,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextWrapped = true,
        ZIndex = 8
    })
    
    local toggleBg = new("Frame", {
        Parent = frame,
        Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, -38, 0.5, -10),
        BackgroundColor3 = colors.bg4,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = toggleBg, CornerRadius = UDim.new(1, 0)})
    
    local toggleCircle = new("Frame", {
        Parent = toggleBg,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = colors.textDim,
        BorderSizePixel = 0,
        ZIndex = 9
    })
    new("UICorner", {Parent = toggleCircle, CornerRadius = UDim.new(1, 0)})
    
    local btn = new("TextButton", {Parent = toggleBg, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 10})
    
    local on = ConfigSystem.Get(configPath, false)
    toggleBg.BackgroundColor3 = on and colors.primary or colors.bg4
    toggleCircle.Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    toggleCircle.BackgroundColor3 = on and colors.text or colors.textDim
    
    btn.MouseButton1Click:Connect(function()
        on = not on
        toggleBg.BackgroundColor3 = on and colors.primary or colors.bg4
        toggleCircle.Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        toggleCircle.BackgroundColor3 = on and colors.text or colors.textDim
        ConfigSystem.Set(configPath, on)
        MarkDirty()
        if callback then callback(on) end
    end)
    
    RegisterCallback(configPath, callback, "toggle", false)
end

-- INPUT
local function makeInput(parent, label, configPath, defaultValue, callback)
    local frame = new("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, ZIndex = 7})
    
    new("TextLabel", {
        Parent = frame,
        Text = label,
        Size = UDim2.new(0.55, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        ZIndex = 8
    })
    
    local inputBg = new("Frame", {
        Parent = frame,
        Size = UDim2.new(0.42, 0, 0, 28),
        Position = UDim2.new(0.58, 0, 0.5, -14),
        BackgroundColor3 = colors.bg4,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = inputBg, CornerRadius = UDim.new(0, 6)})
    
    local initialValue = ConfigSystem.Get(configPath, defaultValue)
    local inputBox = new("TextBox", {
        Parent = inputBg,
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(initialValue),
        PlaceholderText = "0.00",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        PlaceholderColor3 = colors.textDimmer,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        ZIndex = 9
    })
    
    inputBox.FocusLost:Connect(function()
        local value = tonumber(inputBox.Text)
        if value then
            ConfigSystem.Set(configPath, value)
            MarkDirty()
            if callback then callback(value) end
        else
            inputBox.Text = tostring(initialValue)
        end
    end)
    
    RegisterCallback(configPath, callback, "input", defaultValue)
end

-- DROPDOWN
local function makeDropdown(parent, title, imageId, items, configPath, onSelect, uniqueId)
    local dropdownFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = colors.bg4,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 7,
        Name = uniqueId or "Dropdown"
    })
    new("UICorner", {Parent = dropdownFrame, CornerRadius = UDim.new(0, 6)})
    
    local header = new("TextButton", {
        Parent = dropdownFrame,
        Size = UDim2.new(1, -12, 0, 36),
        Position = UDim2.new(0, 6, 0, 2),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 8
    })
    
    new("ImageLabel", {
        Parent = header,
        Image = imageId,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundTransparency = 1,
        ImageColor3 = colors.primary,
        ZIndex = 9
    })
    
    new("TextLabel", {
        Parent = header,
        Text = title,
        Size = UDim2.new(1, -70, 0, 14),
        Position = UDim2.new(0, 20, 0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    
    local initialSelected = configPath and ConfigSystem.Get(configPath, nil) or nil
    local selectedItem = initialSelected
    
    local statusLabel = new("TextLabel", {
        Parent = header,
        Text = selectedItem or "None Selected",
        Size = UDim2.new(1, -70, 0, 12),
        Position = UDim2.new(0, 26, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = colors.textDimmer,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    
    local arrow = new("TextLabel", {
        Parent = header,
        Text = "▼",
        Size = UDim2.new(0, 24, 1, 0),
        Position = UDim2.new(1, -24, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = colors.primary,
        ZIndex = 9
    })
    
    local listContainer = new("ScrollingFrame", {
        Parent = dropdownFrame,
        Size = UDim2.new(1, -12, 0, 0),
        Position = UDim2.new(0, 6, 0, 42),
        BackgroundTransparency = 1,
        Visible = false,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = colors.primary,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10
    })
    new("UIListLayout", {Parent = listContainer, Padding = UDim.new(0, 4)})
    new("UIPadding", {Parent = listContainer, PaddingBottom = UDim.new(0, 8)})
    
    local isOpen = false
    
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        listContainer.Visible = isOpen
        arrow.Rotation = isOpen and 180 or 0
        dropdownFrame.BackgroundTransparency = isOpen and 0.45 or 0.6
        if isOpen then listContainer.Size = UDim2.new(1, -12, 0, math.min(#items * 28, 140)) end
    end)
    
    for _, itemName in ipairs(items) do
        local itemBtn = new("TextButton", {
            Parent = listContainer,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = colors.bg4,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 11
        })
        new("UICorner", {Parent = itemBtn, CornerRadius = UDim.new(0, 5)})
        
        new("TextLabel", {
            Parent = itemBtn,
            Text = itemName,
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 8,
            TextColor3 = colors.textDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 12
        })
        
        itemBtn.MouseButton1Click:Connect(function()
            selectedItem = itemName
            statusLabel.Text = "✓ " .. itemName
            statusLabel.TextColor3 = colors.success
            if configPath then ConfigSystem.Set(configPath, itemName) MarkDirty() end
            if onSelect then onSelect(itemName) end
            task.wait(0.1)
            isOpen = false
            listContainer.Visible = false
            arrow.Rotation = 0
            dropdownFrame.BackgroundTransparency = 0.6
        end)
    end
    
    if configPath then RegisterCallback(configPath, onSelect, "dropdown", nil) end
    return dropdownFrame
end

-- BUTTON
local function makeButton(parent, label, callback)
    local btnFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = colors.primary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = btnFrame, CornerRadius = UDim.new(0, 6)})
    
    local button = new("TextButton", {
        Parent = btnFrame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        ZIndex = 9
    })
    
    button.MouseButton1Click:Connect(function() pcall(callback) end)
    return btnFrame
end

-- MULTI-SELECT DROPDOWN
local function makeMultiSelectDropdown(parent, label, options, callback, configPath)
    local dropdownFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = colors.bg4,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 7
    })
    new("UICorner", {Parent = dropdownFrame, CornerRadius = UDim.new(0, 6)})
    
    new("TextLabel", {
        Parent = dropdownFrame,
        Text = label,
        Size = UDim2.new(0.5, -10, 0, 36),
        Position = UDim2.new(0, 8, 0, 2),
        BackgroundTransparency = 1,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        ZIndex = 8
    })
    
    local dropdownButton = new("TextButton", {
        Parent = dropdownFrame,
        Size = UDim2.new(0.48, 0, 0, 28),
        Position = UDim2.new(0.52, 0, 0, 6),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Text = "Select... (0)",
        TextColor3 = colors.textDim,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ZIndex = 8
    })
    new("UICorner", {Parent = dropdownButton, CornerRadius = UDim.new(0, 6)})
    
    local arrow = new("TextLabel", {
        Parent = dropdownButton,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -22, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = colors.primary,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        ZIndex = 9
    })
    
    local optionsContainer = new("ScrollingFrame", {
        Parent = dropdownFrame,
        Size = UDim2.new(1, -16, 0, 0),
        Position = UDim2.new(0, 8, 0, 44),
        BackgroundColor3 = colors.bg2,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Visible = false,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = colors.primary,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        ZIndex = 10
    })
    new("UICorner", {Parent = optionsContainer, CornerRadius = UDim.new(0, 6)})
    new("UIListLayout", {Parent = optionsContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
    new("UIPadding", {Parent = optionsContainer, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
    
    local selectedItems = {}
    if configPath then
        local saved = ConfigSystem.Get(configPath, {})
        if type(saved) == "table" then
            for _, item in ipairs(saved) do selectedItems[item] = true end
        end
    end
    
    local function updateButtonText()
        local count = 0
        for _ in pairs(selectedItems) do count = count + 1 end
        if count == 0 then
            dropdownButton.Text = "Select... (0)"
            dropdownButton.TextColor3 = colors.textDim
        elseif count == 1 then
            for item in pairs(selectedItems) do dropdownButton.Text = item break end
            dropdownButton.TextColor3 = colors.text
        else
            dropdownButton.Text = string.format("Selected (%d)", count)
            dropdownButton.TextColor3 = colors.text
        end
    end
    
    for _, option in ipairs(options) do
        local optionButton = new("TextButton", {
            Parent = optionsContainer,
            Size = UDim2.new(1, -10, 0, 28),
            BackgroundColor3 = colors.bg3,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 11
        })
        new("UICorner", {Parent = optionButton, CornerRadius = UDim.new(0, 5)})
        
        local checkbox = new("Frame", {
            Parent = optionButton,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -23, 0.5, -9),
            BackgroundColor3 = selectedItems[option] and colors.primary or colors.bg1,
            BackgroundTransparency = selectedItems[option] and 0.3 or 0.5,
            BorderSizePixel = 0,
            ZIndex = 12
        })
        new("UICorner", {Parent = checkbox, CornerRadius = UDim.new(0, 4)})
        
        local checkmark = new("TextLabel", {
            Parent = checkbox,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "✓",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = colors.text,
            Visible = selectedItems[option] or false,
            ZIndex = 13
        })
        
        new("TextLabel", {
            Parent = optionButton,
            Text = "  " .. option,
            Size = UDim2.new(1, -30, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextColor3 = colors.textDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 12
        })
        
        optionButton.MouseButton1Click:Connect(function()
            if selectedItems[option] then
                selectedItems[option] = nil
                checkmark.Visible = false
                checkbox.BackgroundColor3 = colors.bg1
                checkbox.BackgroundTransparency = 0.5
            else
                selectedItems[option] = true
                checkmark.Visible = true
                checkbox.BackgroundColor3 = colors.primary
                checkbox.BackgroundTransparency = 0.3
            end
            updateButtonText()
            local selected = {}
            for item in pairs(selectedItems) do table.insert(selected, item) end
            if configPath then ConfigSystem.Set(configPath, selected) MarkDirty() end
            callback(selected)
        end)
    end
    
    updateButtonText()
    task.spawn(function()
        task.wait(0.1)
        local selected = {}
        for item in pairs(selectedItems) do table.insert(selected, item) end
        if #selected > 0 then callback(selected) end
    end)
    
    local isOpen = false
    dropdownButton.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optionsContainer.Visible = isOpen
        arrow.Rotation = isOpen and 180 or 0
        dropdownFrame.BackgroundTransparency = isOpen and 0.45 or 0.6
        if isOpen then optionsContainer.Size = UDim2.new(1, -16, 0, math.min(150, #options * 30 + 10)) end
    end)
    
    return {Frame = dropdownFrame, GetSelected = function() local s = {} for i in pairs(selectedItems) do table.insert(s, i) end return s end}
end

-- TEXTBOX
local function makeTextBox(parent, label, placeholder, defaultValue, callback)
    local container = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = colors.bg2,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    new("UICorner", {Parent = container, CornerRadius = UDim.new(0, 8)})
    
    new("TextLabel", {
        Parent = container,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 8),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local textBox = new("TextBox", {
        Parent = container,
        Size = UDim2.new(1, -20, 0, 32),
        Position = UDim2.new(0, 10, 0, 32),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Text = defaultValue or "",
        PlaceholderText = placeholder or "",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = colors.text,
        PlaceholderColor3 = colors.textDimmer,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 8
    })
    new("UICorner", {Parent = textBox, CornerRadius = UDim.new(0, 6)})
    new("UIPadding", {Parent = textBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    
    local lastSavedValue = defaultValue or ""
    textBox.FocusLost:Connect(function()
        local value = textBox.Text
        if value and value ~= "" and value ~= lastSavedValue then
            lastSavedValue = value
            callback(value)
        end
    end)
    
    return {Container = container, TextBox = textBox, SetValue = function(v) textBox.Text = tostring(v) lastSavedValue = tostring(v) end}
end

-- ============================================
-- MAIN PAGE
-- ============================================
local catAutoFishing = makeCategory(mainPage, "Auto Fishing")
local currentInstantMode = "None"
local fishingDelayValue = 1.30
local cancelDelayValue = 0.19
local isInstantFishingEnabled = false

makeDropdown(catAutoFishing, "Instant Fishing Mode", "rbxassetid://104332967321169", {"Fast", "Perfect"}, "InstantFishing.Mode", function(mode)
    currentInstantMode = mode
    if instant then instant.Stop() end
    if instant2 then instant2.Stop() end
    if isInstantFishingEnabled then
        if mode == "Fast" and instant then
            instant.Settings.MaxWaitTime = fishingDelayValue
            instant.Settings.CancelDelay = cancelDelayValue
            instant.Start()
        elseif mode == "Perfect" and instant2 then
            instant2.Settings.MaxWaitTime = fishingDelayValue
            instant2.Settings.CancelDelay = cancelDelayValue
            instant2.Start()
        end
    end
end, "InstantFishingMode")

makeToggle(catAutoFishing, "Enable Instant Fishing", "InstantFishing.Enabled", function(on)
    isInstantFishingEnabled = on
    if on then
        if currentInstantMode == "Fast" and instant then instant.Start()
        elseif currentInstantMode == "Perfect" and instant2 then instant2.Start() end
    else
        if instant then instant.Stop() end
        if instant2 then instant2.Stop() end
    end
end)

makeInput(catAutoFishing, "Fishing Delay", "InstantFishing.FishingDelay", 1.30, function(v)
    fishingDelayValue = v
    if instant then instant.Settings.MaxWaitTime = v end
    if instant2 then instant2.Settings.MaxWaitTime = v end
end)

makeInput(catAutoFishing, "Cancel Delay", "InstantFishing.CancelDelay", 0.19, function(v)
    cancelDelayValue = v
    if instant then instant.Settings.CancelDelay = v end
    if instant2 then instant2.Settings.CancelDelay = v end
end)

-- Blatant Tester
local catBlatantV2 = makeCategory(mainPage, "Blatant Tester")
makeToggle(catBlatantV2, "Blatant Tester", "BlatantTester.Enabled", function(on) 
    if blatantv2fix then if on then blatantv2fix.Start() else blatantv2fix.Stop() end end
end)
makeInput(catBlatantV2, "Complete Delay", "BlatantTester.CompleteDelay", 0.5, function(v)
    if blatantv2fix then blatantv2fix.Settings.CompleteDelay = v end
end)
makeInput(catBlatantV2, "Cancel Delay", "BlatantTester.CancelDelay", 0.1, function(v)
    if blatantv2fix then blatantv2fix.Settings.CancelDelay = v end
end)

-- Blatant V1
local catBlatantV1 = makeCategory(mainPage, "Blatant V1")
makeToggle(catBlatantV1, "Blatant Mode", "BlatantV1.Enabled", function(on) 
    if blatantv1 then if on then blatantv1.Start() else blatantv1.Stop() end end
end)
makeInput(catBlatantV1, "Complete Delay", "BlatantV1.CompleteDelay", 0.05, function(v)
    if blatantv1 then blatantv1.Settings.CompleteDelay = v end
end)
makeInput(catBlatantV1, "Cancel Delay", "BlatantV1.CancelDelay", 0.1, function(v)
    if blatantv1 then blatantv1.Settings.CancelDelay = v end
end)

-- Ultra Blatant V2
local catUltraBlatant = makeCategory(mainPage, "Blatant V2")
makeToggle(catUltraBlatant, "Ultra Blatant Mode", "UltraBlatant.Enabled", function(on) 
    if UltraBlatant then if on then UltraBlatant.Start() else UltraBlatant.Stop() end end
end)
makeInput(catUltraBlatant, "Complete Delay", "UltraBlatant.CompleteDelay", 0.05, function(v)
    if UltraBlatant and UltraBlatant.UpdateSettings then UltraBlatant.UpdateSettings(v, nil, nil) end
end)
makeInput(catUltraBlatant, "Cancel Delay", "UltraBlatant.CancelDelay", 0.1, function(v)
    if UltraBlatant and UltraBlatant.UpdateSettings then UltraBlatant.UpdateSettings(nil, v, nil) end
end)

-- Support Features
local catSupport = makeCategory(mainPage, "Support Features")

makeToggle(catSupport, "No Fishing Animation", "Support.NoFishingAnimation", function(on)
    if NoFishingAnimation then if on then NoFishingAnimation.StartWithDelay() else NoFishingAnimation.Stop() end end
end)

makeToggle(catSupport, "Show Real Ping Panel", "Support.PingFPSMonitor", function(on)
    if PingFPSMonitor then if on then PingFPSMonitor:Show() else PingFPSMonitor:Hide() end end
end)

makeToggle(catSupport, "Lock Position", "Support.LockPosition", function(on)
    if LockPosition then if on then LockPosition.Start() else LockPosition.Stop() end end
end)

makeToggle(catSupport, "Disable Cutscenes", "Support.DisableCutscenes", function(on)
    if DisableCutscenes then if on then DisableCutscenes.Start() else DisableCutscenes.Stop() end end
end)

makeToggle(catSupport, "Disable Obtained Fish Notification", "Support.DisableObtainedNotif", function(on)
    if DisableExtras then if on then DisableExtras.StartSmallNotification() else DisableExtras.StopSmallNotification() end end
end)

makeToggle(catSupport, "Disable Skin Effect", "Support.DisableSkinEffect", function(on)
    if DisableExtras then if on then DisableExtras.StartSkinEffect() else DisableExtras.StopSkinEffect() end end
end)

makeToggle(catSupport, "Walk On Water", "Support.WalkOnWater", function(on)
    if WalkOnWater then if on then WalkOnWater.Start() else WalkOnWater.Stop() end end
end)

makeToggle(catSupport, "Good/Perfection Stable Mode", "Support.GoodPerfectionStable", function(on)
    if GoodPerfectionStable then if on then GoodPerfectionStable.Start() else GoodPerfectionStable.Stop() end end
end)

-- Auto Favorite
local catAutoFav = makeCategory(mainPage, "Auto Favorite")
local autoFavEnabled = false
local selectedTiers = {}
local selectedVariants = {}

if AutoFavorite then
    makeMultiSelectDropdown(catAutoFav, "Auto Favorite Tiers", AutoFavorite.GetAllTiers(), function(selected) selectedTiers = selected end, "AutoFavorite.EnabledTiers")
    makeMultiSelectDropdown(catAutoFav, "Auto Favorite Variants", AutoFavorite.GetAllVariants(), function(selected) selectedVariants = selected end, "AutoFavorite.EnabledVariants")
    
    makeToggle(catAutoFav, "Enable Auto Favorite", "AutoFavorite.Enabled", function(on)
        autoFavEnabled = on
        
        if on then
            AutoFavorite.ClearTiers()
            AutoFavorite.ClearVariants()
            
            -- Use selectedTiers/Variants, or fallback to config if empty
            local tiersToUse = #selectedTiers > 0 and selectedTiers or ConfigSystem.Get("AutoFavorite.EnabledTiers", {})
            local variantsToUse = #selectedVariants > 0 and selectedVariants or ConfigSystem.Get("AutoFavorite.EnabledVariants", {})
            
            if type(tiersToUse) == "table" and #tiersToUse > 0 then 
                AutoFavorite.EnableTiers(tiersToUse) 
            end
            if type(variantsToUse) == "table" and #variantsToUse > 0 then 
                AutoFavorite.EnableVariants(variantsToUse) 
            end
            
            AutoFavorite.Start()
        else
            AutoFavorite.Stop()
            AutoFavorite.ClearTiers()
            AutoFavorite.ClearVariants()
        end
    end)
end

-- Auto Totem 3X
local catAutoTotem = makeCategory(mainPage, "Auto Spawn 3X Totem")
makeButton(catAutoTotem, "Auto Totem 3X", function()
    if AutoTotem3X then
        if AutoTotem3X.IsRunning() then AutoTotem3X.Stop() else AutoTotem3X.Start() end
    end
end)

-- Skin Animation
local catSkin = makeCategory(mainPage, "Skin Animation")
local skinAnimEnabled = false
local selectedSkin = nil

local skinInfo = {
    ["Eclipse Katana"] = {id = "Eclipse", description = "RodThrow: 1.4x"},
    ["Holy Trident"] = {id = "HolyTrident", description = "RodThrow: 1.3x"},
    ["Soul Scythe"] = {id = "SoulScythe", description = "StartRodCharge: 1.4x"},
    ["Oceanic Harpoon"] = {id = "OceanicHarpoon", description = "Ocean-themed"},
    ["Binary Edge"] = {id = "BinaryEdge", description = "Digital glitch"},
    ["The Vanquisher"] = {id = "Vanquisher", description = "Powerful strike"},
    ["Frozen Krampus Scythe"] = {id = "KrampusScythe", description = "Icy winter"},
    ["1x1x1x1 Ban Hammer"] = {id = "BanHammer", description = "Ban hammer swing"},
    ["Corruption Edge"] = {id = "CorruptionEdge", description = "Dark corruption"},
    ["Princess Parasol"] = {id = "PrincessParasol", description = "Parasol spin"}
}

local skinNames = {"Eclipse Katana", "Holy Trident", "Soul Scythe", "Oceanic Harpoon", "Binary Edge", "The Vanquisher", "Frozen Krampus Scythe", "1x1x1x1 Ban Hammer", "Corruption Edge", "Princess Parasol"}

makeDropdown(catSkin, "Select Skin", "rbxassetid://104332967321169", skinNames, "Support.SkinAnimation.Current", function(selected)
    selectedSkin = selected
    if skinAnimEnabled and SkinAnimation and skinInfo[selectedSkin] then
        SkinAnimation.SwitchSkin(skinInfo[selectedSkin].id)
    end
end, "SkinAnimationDropdown")

makeToggle(catSkin, "Enable Skin Animation", "Support.SkinAnimation.Enabled", function(on)
    skinAnimEnabled = on
    if SkinAnimation then
        if on and selectedSkin and skinInfo[selectedSkin] then
            SkinAnimation.SwitchSkin(skinInfo[selectedSkin].id)
            SkinAnimation.Enable()
        else
            SkinAnimation.Disable()
        end
    end
end)

-- ============================================
-- TELEPORT PAGE
-- ============================================
local locationItems = {}
if TeleportModule then
    for name, _ in pairs(TeleportModule.Locations or {}) do table.insert(locationItems, name) end
    table.sort(locationItems)
end

makeDropdown(teleportPage, "Teleport to Location", "rbxassetid://84279757789414", locationItems, nil, function(selectedLocation)
    if TeleportModule then TeleportModule.TeleportTo(selectedLocation) end
end, "LocationTeleport")

-- Player Teleport (Manual Refresh)
local catPlayerTeleport = makeCategory(teleportPage, "Teleport to Player")
local playerDropdown = nil
local playerItems = {}

local function updatePlayerList()
    table.clear(playerItems)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then table.insert(playerItems, player.Name) end
    end
    table.sort(playerItems)
    if playerDropdown and playerDropdown.Parent then playerDropdown:Destroy() end
    playerDropdown = makeDropdown(catPlayerTeleport, "Select Player", "rbxassetid://86355568065894", playerItems, nil, function(selectedPlayer)
        if TeleportToPlayer then TeleportToPlayer.TeleportTo(selectedPlayer) end
    end, "PlayerTeleport")
end
updatePlayerList()

makeButton(catPlayerTeleport, "Refresh Player List", function()
    updatePlayerList()
    if Notify then Notify.Send("Player List", "Daftar player diperbarui!", 2) end
end)

-- Saved Location
local catSaved = makeCategory(teleportPage, "Saved Location")
makeButton(catSaved, "Save Current Location", function()
    if SavedLocation then SavedLocation.Save() end
end)
makeButton(catSaved, "Teleport Saved Location", function()
    if SavedLocation then SavedLocation.Teleport() end
end)
makeButton(catSaved, "Reset Saved Location", function()
    if SavedLocation then SavedLocation.Reset() end
end)

-- Event Teleport
local selectedEventName = nil
local eventNames = EventTeleport.GetEventNames()
local catTeleport = makeCategory(teleportPage, "Event Teleport")

makeDropdown(catTeleport, "Pilih Event", "rbxassetid://84279757789414", eventNames, nil, function(selected)
    selectedEventName = selected
end, "EventTeleport")

makeToggle(catTeleport, "Enable Auto Teleport", "Teleport.AutoTeleportEvent", function(on)
    if on then
        if selectedEventName and EventTeleport.HasCoords(selectedEventName) then EventTeleport.Start(selectedEventName) end
    else
        EventTeleport.Stop()
    end
end)

-- ============================================
-- SHOP PAGE
-- ============================================
local catSell = makeCategory(shopPage, "Sell All")
makeButton(catSell, "Sell All Now", function()
    if AutoSellSystem then AutoSellSystem.SellOnce() end
end)

local catTimer = makeCategory(shopPage, "Auto Sell Timer")
makeInput(catTimer, "Sell Interval (seconds)", "Shop.AutoSellTimer.Interval", 5, function(value)
    if AutoSellSystem and AutoSellSystem.Timer then AutoSellSystem.Timer.SetInterval(value) end
end)
makeToggle(catTimer, "Enable Auto Sell Timer", "Shop.AutoSellTimer.Enabled", function(on)
    if AutoSellSystem and AutoSellSystem.Timer then if on then AutoSellSystem.Timer.Start() else AutoSellSystem.Timer.Stop() end end
end)

local catCount = makeCategory(shopPage, "Auto Sell By Count")
makeInput(catCount, "Target Fish Count", "Shop.AutoSellByCount.Target", 235, function(value)
    if AutoSellSystem and AutoSellSystem.Count then AutoSellSystem.Count.SetTarget(value) end
end)
makeToggle(catCount, "Enable Auto Sell By Count", "Shop.AutoSellByCount.Enabled", function(on)
    if AutoSellSystem and AutoSellSystem.Count then if on then AutoSellSystem.Count.Start() else AutoSellSystem.Count.Stop() end end
end)

-- Auto Buy Weather
local catWeather = makeCategory(shopPage, "Auto Buy Weather")
local selectedWeathers = {}
local autoWeatherEnabled = false

if AutoBuyWeather then
    makeMultiSelectDropdown(catWeather, "Select Weather Types", AutoBuyWeather.AllWeathers, function(selected)
        selectedWeathers = selected
        AutoBuyWeather.SetSelected(selectedWeathers)
    end, "Shop.AutoBuyWeather.SelectedWeathers")
end

makeToggle(catWeather, "Enable Auto Weather", "Shop.AutoBuyWeather.Enabled", function(on)
    autoWeatherEnabled = on
    if AutoBuyWeather then if on then AutoBuyWeather.Start() else AutoBuyWeather.Stop() end end
end)

-- Remote Merchant
local catMerchant = makeCategory(shopPage, "Remote Merchant")
makeButton(catMerchant, "Open Merchant", function() if MerchantSystem then MerchantSystem.Open() end end)
makeButton(catMerchant, "Close Merchant", function() if MerchantSystem then MerchantSystem.Close() end end)

-- Buy Rod
local catRod = makeCategory(shopPage, "Buy Rod")
local RodData = {
    ["Chrome Rod"] = {id = 7, price = 437000}, ["Lucky Rod"] = {id = 4, price = 15000},
    ["Starter Rod"] = {id = 1, price = 50}, ["Steampunk Rod"] = {id = 6, price = 215000},
    ["Carbon Rod"] = {id = 76, price = 750}, ["Ice Rod"] = {id = 78, price = 5000},
    ["Luck Rod"] = {id = 79, price = 325}, ["Midnight Rod"] = {id = 80, price = 50000},
    ["Grass Rod"] = {id = 85, price = 1500}, ["Demascus Rod"] = {id = 77, price = 3000},
    ["Astral Rod"] = {id = 5, price = 1000000}, ["Ares Rod"] = {id = 126, price = 3000000},
    ["Angler Rod"] = {id = 168, price = 8000000}, ["Fluorescent Rod"] = {id = 255, price = 715000},
    ["Bamboo Rod"] = {id = 258, price = 12000000}
}
local RodList, RodMap = {}, {}
for rodName, info in pairs(RodData) do
    local display = rodName .. " (" .. tostring(info.price) .. ")"
    table.insert(RodList, display)
    RodMap[display] = rodName
end
local SelectedRod = nil
makeDropdown(catRod, "Select Rod", "rbxassetid://104332967321169", RodList, nil, function(displayName)
    SelectedRod = RodMap[displayName]
end, "RodDropdown")
makeButton(catRod, "BUY SELECTED ROD", function()
    if SelectedRod and RemoteBuyer then RemoteBuyer.BuyRod(RodData[SelectedRod].id) end
end)

-- Buy Bait
local catBait = makeCategory(shopPage, "Buy Bait")
local BaitData = {
    ["Chroma Bait"] = {id = 6, price = 290000}, ["Luck Bait"] = {id = 2, price = 1000},
    ["Midnight Bait"] = {id = 3, price = 3000}, ["Topwater Bait"] = {id = 10, price = 100},
    ["Dark Matter Bait"] = {id = 8, price = 630000}, ["Nature Bait"] = {id = 17, price = 83500},
    ["Aether Bait"] = {id = 16, price = 3700000}, ["Corrupt Bait"] = {id = 15, price = 1148484},
    ["Floral Bait"] = {id = 20, price = 4000000}
}
local BaitList, BaitMap = {}, {}
for baitName, info in pairs(BaitData) do
    local display = baitName .. " (" .. tostring(info.price) .. ")"
    table.insert(BaitList, display)
    BaitMap[display] = baitName
end
local SelectedBait = nil
makeDropdown(catBait, "Select Bait", "rbxassetid://104332967321169", BaitList, nil, function(displayName)
    SelectedBait = BaitMap[displayName]
end, "BaitDropdown")
makeButton(catBait, "BUY SELECTED BAIT", function()
    if SelectedBait and RemoteBuyer then RemoteBuyer.BuyBait(BaitData[SelectedBait].id) end
end)

-- ============================================
-- WEBHOOK PAGE
-- ============================================
local catWebhook = makeCategory(webhookPage, "Discord Webhook Fish Caught")
local currentWebhookURL = ConfigSystem.Get("Webhook.URL", "")
local currentDiscordID = ConfigSystem.Get("Webhook.DiscordID", "")
local selectedRarities = ConfigSystem.Get("Webhook.EnabledRarities", {})

if WebhookModule then
    if currentWebhookURL ~= "" then WebhookModule:SetWebhookURL(currentWebhookURL) end
    if currentDiscordID ~= "" then WebhookModule:SetDiscordUserID(currentDiscordID) end
    if #selectedRarities > 0 then WebhookModule:SetEnabledRarities(selectedRarities) end
end

makeTextBox(catWebhook, "Discord Webhook URL", "https://discord.com/api/webhooks/...", currentWebhookURL, function(value)
    value = value:gsub("^%s*(.-)%s*$", "%1")
    currentWebhookURL = value
    if WebhookModule then
        WebhookModule:SetWebhookURL(value)
        ConfigSystem.Set("Webhook.URL", value)
        MarkDirty()
    end
end)

makeTextBox(catWebhook, "Discord User ID (Optional)", "123456789012345678", currentDiscordID, function(value)
    value = value:gsub("^%s*(.-)%s*$", "%1")
    currentDiscordID = value
    if WebhookModule then
        WebhookModule:SetDiscordUserID(value)
        ConfigSystem.Set("Webhook.DiscordID", value)
        MarkDirty()
    end
end)

makeMultiSelectDropdown(catWebhook, "Filter Rarity", {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"}, function(selected)
    selectedRarities = selected
    if WebhookModule then WebhookModule:SetEnabledRarities(selectedRarities) end
    ConfigSystem.Set("Webhook.EnabledRarities", selected)
    MarkDirty()
end, "Webhook.EnabledRarities")

makeToggle(catWebhook, "Enable Webhook", "Webhook.Enabled", function(on)
    if WebhookModule then
        if on then
            if currentWebhookURL ~= "" then
                WebhookModule:SetWebhookURL(currentWebhookURL)
                WebhookModule:Start()
            end
        else
            WebhookModule:Stop()
        end
    end
end)

makeButton(catWebhook, "Test Webhook Connection", function()
    if not WebhookModule or currentWebhookURL == "" then return end
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
    if requestFunc then
        pcall(function()
            requestFunc({
                Url = currentWebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    embeds = {{
                        title = "🎣 Webhook Test Successful!",
                        description = "Lynx GUI is ready to send fish notifications.",
                        color = 3447003,
                        footer = {text = "Lynx Webhook Test"},
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                })
            })
        end)
    end
end)

-- ============================================
-- CAMERA VIEW PAGE
-- ============================================
local catZoom = makeCategory(cameraViewPage, "Unlimited Zoom")
makeToggle(catZoom, "Enable Unlimited Zoom", "CameraView.UnlimitedZoom", function(on)
    if UnlimitedZoomModule then
        if on then pcall(function() UnlimitedZoomModule.Enable() end)
        else pcall(function() UnlimitedZoomModule.Disable() end) end
    end
end)

if FreecamModule then FreecamModule.SetMainGuiName("LynxGUI_Galaxy") end
local catFreecam = makeCategory(cameraViewPage, "Freecam Camera")

if not isMobile then
    local noteContainer = new("Frame", {
        Parent = catFreecam,
        Size = UDim2.new(1, 0, 0, 85),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    new("UICorner", {Parent = noteContainer, CornerRadius = UDim.new(0, 8)})
    new("TextLabel", {
        Parent = noteContainer,
        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Text = "📌 FREECAM CONTROLS (PC)\n━━━━━━━━━━━━━━━━━━━━━━\n1. Aktifkan toggle \"Enable Freecam\"\n2. Tekan F3 untuk ON/OFF freecam\n3. WASD - Gerak | Mouse - Rotasi\n4. Space/E - Naik | Shift/Q - Turun",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = colors.text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 8
    })
end

makeToggle(catFreecam, "Enable Freecam", "CameraView.Freecam.Enabled", function(on)
    if FreecamModule then
        if on then
            if not isMobile then FreecamModule.EnableF3Keybind(true) else FreecamModule.Start() end
        else
            FreecamModule.EnableF3Keybind(false)
        end
    end
end)

makeInput(catFreecam, "Movement Speed", "CameraView.Freecam.Speed", 50, function(value)
    if FreecamModule and FreecamModule.SetSpeed then FreecamModule.SetSpeed(tonumber(value) or 50) end
end)

makeInput(catFreecam, "Mouse Sensitivity", "CameraView.Freecam.Sensitivity", 0.3, function(value)
    if FreecamModule and FreecamModule.SetSensitivity then FreecamModule.SetSensitivity(tonumber(value) or 0.3) end
end)

makeButton(catFreecam, "Reset Settings", function()
    if FreecamModule then
        if FreecamModule.SetSpeed then FreecamModule.SetSpeed(50) end
        if FreecamModule.SetSensitivity then FreecamModule.SetSensitivity(0.3) end
    end
end)

-- ============================================
-- SETTINGS PAGE
-- ============================================
local catAFK = makeCategory(settingsPage, "Anti-AFK Protection")
makeToggle(catAFK, "Enable Anti-AFK", "Settings.AntiAFK", function(on)
    if AntiAFK then if on then AntiAFK.Start() else AntiAFK.Stop() end end
end)

local catUtility = makeCategory(settingsPage, "Player Utility")
makeInput(catUtility, "Sprint Speed", "Settings.SprintSpeed", 50, function(value)
    if MovementModule then MovementModule.SetSprintSpeed(tonumber(value) or 50) end
end)
makeToggle(catUtility, "Enable Sprint", "Settings.Sprint", function(on)
    if MovementModule then if on then MovementModule.EnableSprint() else MovementModule.DisableSprint() end end
end)
makeToggle(catUtility, "Enable Infinite Jump", "Settings.InfiniteJump", function(on)
    if MovementModule then if on then MovementModule.EnableInfiniteJump() else MovementModule.DisableInfiniteJump() end end
end)

local catServer = makeCategory(settingsPage, "Server Features")
makeButton(catServer, "Rejoin Server", function()
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer) end)
end)

local catBoost = makeCategory(settingsPage, "FPS Booster")
makeToggle(catBoost, "Enable FPS Booster", "Settings.FPSBooster", function(on)
    if FPSBooster then if on then FPSBooster.Enable() else FPSBooster.Disable() end end
end)
makeToggle(catBoost, "Disable 3D Rendering", "Settings.DisableRendering", function(on)
    if DisableRendering then if on then DisableRendering.Start() else DisableRendering.Stop() end end
end)

local catFPS = makeCategory(settingsPage, "FPS Unlocker")
makeDropdown(catFPS, "Select FPS Limit", "rbxassetid://104332967321169", {"60 FPS", "90 FPS", "120 FPS", "240 FPS"}, nil, function(selected)
    local fpsValue = tonumber(selected:match("%d+"))
    if fpsValue and UnlockFPS and UnlockFPS.SetCap then
        UnlockFPS.SetCap(fpsValue)
        ConfigSystem.Set("Settings.FPSLimit", fpsValue)
        MarkDirty()
    end
end, "FPSDropdown")

local catHideStats = makeCategory(settingsPage, "Hide Stats Identifier")
makeToggle(catHideStats, "Enable Hide Stats", "Settings.HideStats.Enabled", function(on)
    if HideStats then if on then HideStats.Enable() else HideStats.Disable() end end
end)
makeTextBox(catHideStats, "Fake Name", "Enter fake name...", "", function(value)
    if HideStats and HideStats.SetFakeName then
        HideStats.SetFakeName(value)
        ConfigSystem.Set("Settings.HideStats.FakeName", value)
        MarkDirty()
    end
end)
makeTextBox(catHideStats, "Fake Level", "Enter fake level...", "", function(value)
    if HideStats and HideStats.SetFakeLevel then
        HideStats.SetFakeLevel(value)
        ConfigSystem.Set("Settings.HideStats.FakeLevel", value)
        MarkDirty()
    end
end)

-- ============================================
-- INFO PAGE
-- ============================================
local infoContainer = new("Frame", {
    Parent = infoPage,
    Size = UDim2.new(1, 0, 0, 150),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.7,
    BorderSizePixel = 0,
    ZIndex = 6
})
new("UICorner", {Parent = infoContainer, CornerRadius = UDim.new(0, 8)})

new("TextLabel", {
    Parent = infoContainer,
    Size = UDim2.new(1, -24, 0, 80),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text = "# LynX v3.0\nZero Memory Leak Edition\n━━━━━━━━━━━━━━━━━━━━━━\nFree Not For Sale\nCreated with ❤ by Beee\nRefined Edition 2024",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextColor3 = colors.text,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 7
})

local linkButton = new("TextButton", {
    Parent = infoContainer,
    Size = UDim2.new(1, -24, 0, 20),
    Position = UDim2.new(0, 12, 0, 100),
    BackgroundTransparency = 1,
    Text = "🔗 Discord: https://discord.gg/lynxx",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(88, 101, 242),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 7
})

linkButton.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://discord.gg/lynxx") end)
    linkButton.Text = "✅ Link copied to clipboard!"
    task.wait(2)
    linkButton.Text = "🔗 Discord: https://discord.gg/lynxx"
end)

-- ============================================
-- MINIMIZE SYSTEM
-- ============================================
local minimized = false
local icon = nil
local savedIconPos = UDim2.new(0, 20, 0, 100)

local function createMinimizedIcon()
    if icon then return end
    icon = new("ImageLabel", {
        Parent = gui,
        Size = UDim2.new(0, 50, 0, 50),
        Position = savedIconPos,
        BackgroundColor3 = colors.bg2,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Image = "rbxassetid://118176705805619",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 50
    })
    new("UICorner", {Parent = icon, CornerRadius = UDim.new(0, 10)})
    
    local logoText = new("TextLabel", {
        Parent = icon,
        Text = "L",
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 28,
        BackgroundTransparency = 1,
        TextColor3 = colors.primary,
        Visible = icon.Image == "",
        ZIndex = 51
    })
    
    local dragging, dragStart, startPos, dragMoved = false, nil, nil, false
    
    icon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragMoved, dragStart, startPos = true, false, input.Position, icon.Position
        end
    end)
    
    icon.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.sqrt(delta.X^2 + delta.Y^2) > 5 then dragMoved = true end
            icon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    icon.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                savedIconPos = icon.Position
                if not dragMoved then
                    bringToFront()
                    win.Visible = true
                    win.Size = windowSize
                    win.Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
                    icon:Destroy()
                    icon = nil
                    minimized = false
                end
            end
        end
    end)
end

ConnectionManager:Add("minimizeBtn", btnMinHeader.MouseButton1Click:Connect(function()
    if not minimized then
        win.Size = UDim2.new(0, 0, 0, 0)
        win.Position = UDim2.new(0.5, 0, 0.5, 0)
        win.Visible = false
        createMinimizedIcon()
        minimized = true
    end
end))

-- ============================================
-- DRAGGING SYSTEM (Single connection)
-- ============================================
local dragging, dragStart, startPos = false, nil, nil

scriptHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        bringToFront()
        dragging, dragStart, startPos = true, input.Position, win.Position
    end
end)

ConnectionManager:Add("inputChanged", UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
end))

ConnectionManager:Add("inputEnded", UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

-- ============================================
-- RESIZING SYSTEM
-- ============================================
local resizing = false
local resizeStartPos, resizeStartSize = nil, nil

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing, resizeStartPos, resizeStartSize = true, input.Position, win.Size
    end
end)

-- Reuse inputChanged connection for resize
local originalInputChanged = ConnectionManager._connections["inputChanged"]
ConnectionManager:Add("inputChanged", UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging and startPos then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        if resizing and resizeStartPos then
            local delta = input.Position - resizeStartPos
            local newWidth = math.clamp(resizeStartSize.X.Offset + delta.X, minWindowSize.X, maxWindowSize.X)
            local newHeight = math.clamp(resizeStartSize.Y.Offset + delta.Y, minWindowSize.Y, maxWindowSize.Y)
            win.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end
end))

ConnectionManager:Add("inputEnded", UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        resizing = false
    end
end))

-- ============================================
-- INITIALIZE
-- ============================================
win.Size = windowSize
win.BackgroundTransparency = 0.2

local function InitializeModuleSettings()
    local cfg = ConfigSystem.Get
    if instant then instant.Settings.MaxWaitTime = cfg("InstantFishing.FishingDelay", 1.30) instant.Settings.CancelDelay = cfg("InstantFishing.CancelDelay", 0.19) end
    if instant2 then instant2.Settings.MaxWaitTime = cfg("InstantFishing.FishingDelay", 1.30) instant2.Settings.CancelDelay = cfg("InstantFishing.CancelDelay", 0.19) end
    if blatantv2fix then blatantv2fix.Settings.CompleteDelay = cfg("BlatantTester.CompleteDelay", 0.5) blatantv2fix.Settings.CancelDelay = cfg("BlatantTester.CancelDelay", 0.1) end
    if blatantv1 then blatantv1.Settings.CompleteDelay = cfg("BlatantV1.CompleteDelay", 0.05) blatantv1.Settings.CancelDelay = cfg("BlatantV1.CancelDelay", 0.1) end
    if UltraBlatant and UltraBlatant.UpdateSettings then UltraBlatant.UpdateSettings(cfg("UltraBlatant.CompleteDelay", 0.05), cfg("UltraBlatant.CancelDelay", 0.1), nil) end
    if blatantv2 then blatantv2.Settings.FishingDelay = cfg("FastAutoPerfect.FishingDelay", 0.05) blatantv2.Settings.CancelDelay = cfg("FastAutoPerfect.CancelDelay", 0.01) blatantv2.Settings.TimeoutDelay = cfg("FastAutoPerfect.TimeoutDelay", 0.8) end
end

InitializeModuleSettings()
ExecuteConfigCallbacks()

-- Cleanup on GUI destroy
gui.Destroying:Connect(function()
    ConnectionManager:Cleanup()
end)
