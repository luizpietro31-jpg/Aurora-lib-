--[[
    ╔══════════════════════════════════════════════════════════╗
    ║              AuroraLib  v1.0  by Aurora                 ║
    ║  Uma lib de UI reutilizável no estilo AuroraHub          ║
    ║  Uso:                                                    ║
    ║    local Lib = loadstring(game:HttpGet("URL"))()         ║
    ║    local Win = Lib:CreateWindow("Meu Hub")              ║
    ║    local Tab = Win:Tab("Player")                         ║
    ║    Tab:Toggle("Speed", false, function(v) end)           ║
    ║    Tab:Button("Teleport", function() end)                ║
    ║    Tab:Slider("WalkSpeed", 16, 100, 50, function(v) end) ║
    ║    Tab:Input("Placeholder", function(txt) end)           ║
    ║    Tab:Label("Texto qualquer")                           ║
    ╚══════════════════════════════════════════════════════════╝
]]

local AuroraLib = {}
AuroraLib.__index = AuroraLib

-- ═══════════════════════════════════════════════════
-- SERVIÇOS
-- ═══════════════════════════════════════════════════
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local Stats        = game:GetService("Stats")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════
-- TEMA (cores Aurora)
-- ═══════════════════════════════════════════════════
local T = {
    BG        = Color3.fromRGB(24, 25, 30),
    Panel     = Color3.fromRGB(31, 33, 38),
    Element   = Color3.fromRGB(40, 42, 49),
    ElementHi = Color3.fromRGB(50, 53, 61),
    Text      = Color3.fromRGB(236, 237, 242),
    Dim       = Color3.fromRGB(143, 146, 158),
    Accent    = Color3.fromRGB(120, 110, 255),
    Accent2   = Color3.fromRGB(77, 208, 225),
    Red       = Color3.fromRGB(200, 55, 55),
    Green     = Color3.fromRGB(0, 200, 0),
}

local FR = Enum.Font.SourceSans
local FM = Enum.Font.SourceSansSemibold
local FB = Enum.Font.SourceSansBold

-- ═══════════════════════════════════════════════════
-- PERSISTÊNCIA
-- ═══════════════════════════════════════════════════
local function safeRead(path)
    local ok, d = pcall(function() return readfile(path) end)
    if ok and type(d) == "string" and d ~= "" then return d end
    return nil
end
local function safeWrite(path, data)
    pcall(function() writefile(path, data) end)
end
local function loadJSON(path)
    local d = safeRead(path)
    if not d then return {} end
    local ok, t = pcall(function() return HttpService:JSONDecode(d) end)
    return (ok and type(t) == "table") and t or {}
end
local function saveJSON(path, tbl)
    local ok, s = pcall(function() return HttpService:JSONEncode(tbl) end)
    if ok then safeWrite(path, s) end
end

-- ═══════════════════════════════════════════════════
-- UTILITÁRIOS DE INSTÂNCIA
-- ═══════════════════════════════════════════════════
local function new(class, props, parent)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do pcall(function() o[k] = v end) end
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, p)
end

local function gradStroke(p, t)
    local s = new("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = t or 1,
    }, p)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.Accent),
            ColorSequenceKeypoint.new(1, T.Accent2),
        }),
        Rotation = 215,
    }, s)
    return s
end

local function gradFill(p, r)
    return new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.Accent),
            ColorSequenceKeypoint.new(1, T.Accent2),
        }),
        Rotation = r or 0,
    }, p)
end

-- ═══════════════════════════════════════════════════
-- DRAGGABLE + RESIZE
-- ═══════════════════════════════════════════════════
local function makeDraggable(frame, handle)
    handle = handle or frame
    handle.Active = true
    local dragging, startP, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startP   = i.Position
            startPos = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = i.Position - startP
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function addResizeGrip(frame, minW, minH)
    minW = minW or 200; minH = minH or 150
    local grip = new("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -2, 1, -2),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0, Text = "",
        AutoButtonColor = false, ZIndex = 950,
    }, frame)
    corner(grip, 4)
    grip.MouseEnter:Connect(function() grip.BackgroundTransparency = 0.15 end)
    grip.MouseLeave:Connect(function() grip.BackgroundTransparency = 0.55 end)
    local rz, s, sSize = false, nil, nil
    grip.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            rz = true; s = i.Position
            sSize = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not rz then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = i.Position - s
        frame.Size = UDim2.new(
            0, math.max(minW, sSize.X + d.X),
            0, math.max(minH, sSize.Y + d.Y)
        )
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            rz = false
        end
    end)
end

-- ═══════════════════════════════════════════════════
-- LAYOUT PERSISTENTE
-- ═══════════════════════════════════════════════════
local function makeLayoutSystem(layoutFile)
    local layout = loadJSON(layoutFile)
    local queue  = {}

    local function queueSave(key)
        if queue[key] then return end
        queue[key] = true
        task.delay(0.4, function()
            queue[key] = nil
            saveJSON(layoutFile, layout)
        end)
    end

    local function register(frame, key)
        local saved = layout[key]
        if type(saved) == "table" then
            if saved.px ~= nil and saved.py ~= nil then
                frame.Position = UDim2.new(saved.sx or 0, saved.px, saved.sy or 0, saved.py)
            end
            if saved.pw ~= nil and saved.ph ~= nil then
                frame.Size = UDim2.new(0, math.min(saved.pw, 600), 0, math.min(saved.ph, 700))
            end
        end
        frame:GetPropertyChangedSignal("Position"):Connect(function()
            local t = layout[key] or {}
            t.px = frame.Position.X.Offset; t.py = frame.Position.Y.Offset
            t.sx = frame.Position.X.Scale;  t.sy = frame.Position.Y.Scale
            layout[key] = t; queueSave(key)
        end)
        frame:GetPropertyChangedSignal("Size"):Connect(function()
            local t = layout[key] or {}
            t.pw = frame.Size.X.Offset; t.ph = frame.Size.Y.Offset
            layout[key] = t; queueSave(key)
        end)
    end

    return { data = layout, register = register, reset = function()
        layout = {}
        saveJSON(layoutFile, layout)
    end }
end

-- ═══════════════════════════════════════════════════
-- FPS + PING
-- ═══════════════════════════════════════════════════
local _fps, _fpsFrames, _fpsElapsed = 0, 0, 0
RunService.RenderStepped:Connect(function(dt)
    _fpsFrames  = _fpsFrames + 1
    _fpsElapsed = _fpsElapsed + dt
    if _fpsElapsed >= 0.5 then
        _fps       = math.floor(_fpsFrames / _fpsElapsed + 0.5)
        _fpsFrames = 0; _fpsElapsed = 0
    end
end)

local function getPing()
    local ping = 0
    pcall(function()
        local net = Stats:FindFirstChild("Network")
        local ssi = net and net:FindFirstChild("ServerStatsItem")
        local dp  = ssi and ssi:FindFirstChild("Data Ping")
        if dp then
            ping = tonumber(string.match(dp:GetValueString(), "%d+%.?%d*")) or 0
        else
            ping = (LP:GetNetworkPing() or 0) * 1000
        end
    end)
    return math.max(0, math.floor(ping + 0.5))
end

-- ═══════════════════════════════════════════════════
-- AURORA LIB — CRIAR JANELA PRINCIPAL
-- ═══════════════════════════════════════════════════
function AuroraLib:CreateWindow(config)
    config = type(config) == "table" and config or { Title = tostring(config or "Aurora") }

    local title     = config.Title    or "Aurora"
    local version   = config.Version  or "v1.0"
    local layoutKey = config.SaveKey  or "auroralib_layout"
    local settKey   = config.SaveKey  and (config.SaveKey.."_settings") or "auroralib_settings"

    -- Estado de toggles
    local savedToggles = loadJSON(settKey..".json")
    local state = {}
    if type(savedToggles) == "table" then
        for k, v in pairs(savedToggles) do state[k] = (v == true) end
    end
    local function saveState() saveJSON(settKey..".json", state) end

    -- Layout persistente
    local LS = makeLayoutSystem(layoutKey..".json")

    -- ScreenGui
    local gui = new("ScreenGui", {
        Name = "AuroraLib_"..title:gsub("%s",""),
        ResetOnSpawn = false, DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, PG)

    local root = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 1,
    }, gui)

    -- ───────────────────────────────────
    -- PAINEL PRINCIPAL
    -- ───────────────────────────────────
    local panel = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 360, 0, 420),
        BackgroundColor3 = T.BG, BorderSizePixel = 0, ZIndex = 2,
    }, root)
    corner(panel, 10); gradStroke(panel, 1.4)
    LS.register(panel, "main_panel")
    addResizeGrip(panel, 280, 230)

    -- Barra de título
    local titleBar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 3,
    }, panel)
    corner(titleBar, 10)
    new("Frame", {
        Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 3,
    }, titleBar)

    makeDraggable(panel, titleBar)

    local titleLabel = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.45, 0, 1, 0),
        Font = FB, Text = title,
        TextColor3 = T.Text, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    }, titleBar)
    gradFill(titleLabel)

    local statusLabel = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14 + 90, 0, 0),
        Size = UDim2.new(0.45, 0, 1, 0),
        Font = FM, Text = version.."  •  0 FPS  •  0 ms",
        TextColor3 = T.Dim, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    }, titleBar)

    task.spawn(function()
        while gui and gui.Parent do
            task.wait(0.5)
            pcall(function()
                statusLabel.Text = string.format("%s  •  %d FPS  •  %d ms", version, _fps, getPing())
            end)
        end
    end)

    -- Botões minimizar / fechar
    local titleBtns = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 100, 0, 22),
        BackgroundTransparency = 1, ZIndex = 4,
    }, titleBar)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, titleBtns)

    local function tinyBtn(text, order)
        local b = new("TextButton", {
            Size = UDim2.new(0, 22, 0, 22),
            BackgroundColor3 = T.Element, BorderSizePixel = 0,
            Font = FB, Text = text, TextColor3 = T.Dim,
            TextSize = 14, LayoutOrder = order, ZIndex = 5,
        }, titleBtns)
        corner(b, 5)
        b.MouseEnter:Connect(function() b.TextColor3 = T.Text end)
        b.MouseLeave:Connect(function() b.TextColor3 = T.Dim  end)
        return b
    end

    local minBtn   = tinyBtn("–", 1)
    local closeBtn = tinyBtn("✕", 2)

    -- Chip de "SHOW" para quando minimizado
    local chip = new("TextButton", {
        Position = UDim2.new(0, 16, 0, 16),
        Size = UDim2.new(0, 70, 0, 32),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0,
        Visible = false, Font = FB, Text = "SHOW",
        TextColor3 = T.Text, TextSize = 12, ZIndex = 60,
    }, gui)
    corner(chip, 6); gradStroke(chip, 1.4)
    makeDraggable(chip)

    local function setMinimized(s)
        panel.Visible = not s
        chip.Visible  = s
    end
    minBtn.MouseButton1Click:Connect(function() setMinimized(true)  end)
    chip.MouseButton1Click:Connect(function()   setMinimized(false) end)
    closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

    -- Barra de abas
    local tabBar = new("Frame", {
        Position = UDim2.new(0, 10, 0, 44),
        Size = UDim2.new(1, -20, 0, 28),
        BackgroundTransparency = 1, ZIndex = 3,
    }, panel)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, tabBar)

    -- Área de conteúdo
    local contentHolder = new("Frame", {
        Position = UDim2.new(0, 4, 0, 80),
        Size = UDim2.new(1, -8, 1, -86),
        BackgroundTransparency = 1, ZIndex = 3,
    }, panel)

    local scroll = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarImageColor3 = T.Accent2, ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 4,
    }, contentHolder)
    new("UIPadding", {
        PaddingBottom = UDim.new(0, 10), PaddingLeft  = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10), PaddingTop   = UDim.new(0, 10),
    }, scroll)
    new("UIListLayout", { Padding = UDim.new(0, 8) }, scroll)

    -- ═══════════════════════════════════════════════
    -- SISTEMA DE JANELAS FLUTUANTES
    -- ═══════════════════════════════════════════════
    local windowsHolder = new("Frame", {
        Name = "WindowsLayer", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 900,
    }, root)

    local openedWindows = {}

    local function openWindow(id, winTitle, size, builder)
        local entry = openedWindows[id]
        if entry then
            entry.Frame.Visible = true
            return entry.Content
        end

        local win = new("Frame", {
            Name = "Win_"..id,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 50, 0.5, -30),
            Size = size or UDim2.new(0, 300, 0, 300),
            BackgroundColor3 = T.BG, BorderSizePixel = 0, ZIndex = 900,
        }, windowsHolder)
        corner(win, 8); gradStroke(win, 1.4)

        local bar = new("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 901,
        }, win)
        corner(bar, 8)
        new("Frame", {
            Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 8),
            BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 901,
        }, bar)

        local t2 = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 11, 0, 0),
            Size = UDim2.new(1, -40, 1, 0),
            Font = FB, Text = winTitle,
            TextColor3 = T.Text, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 902,
        }, bar)
        gradFill(t2)

        local closeB = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -4, 0.5, 0),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            Font = FB, Text = "✕", TextColor3 = T.Dim, TextSize = 13, ZIndex = 903,
        }, bar)
        closeB.MouseButton1Click:Connect(function() win.Visible = false end)

        local cont = new("ScrollingFrame", {
            Position = UDim2.new(0, 0, 0, 30),
            Size = UDim2.new(1, 0, 1, -30),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarImageColor3 = T.Accent2, ScrollBarThickness = 3,
            ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 902,
        }, win)
        new("UIPadding", {
            PaddingBottom = UDim.new(0, 10), PaddingLeft  = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 10), PaddingTop   = UDim.new(0, 10),
        }, cont)
        new("UIListLayout", { Padding = UDim.new(0, 7) }, cont)

        makeDraggable(win, bar)
        LS.register(win, "win_"..id)
        addResizeGrip(win, 200, 140)

        openedWindows[id] = { Frame = win, Content = cont }
        if builder then pcall(builder, cont) end
        return cont
    end

    -- ═══════════════════════════════════════════════
    -- HELPERS DE ELEMENTO (internos)
    -- ═══════════════════════════════════════════════
    local function rowShell(parent, h)
        local r = new("Frame", {
            BackgroundColor3 = T.Panel, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, h or 36), ZIndex = 6,
        }, parent)
        corner(r, 6); gradStroke(r)
        new("UIPadding", {
            PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11),
        }, r)
        return r
    end

    -- ═══════════════════════════════════════════════
    -- SISTEMA DE ABAS
    -- ═══════════════════════════════════════════════
    local tabs       = {}
    local tabBtns    = {}
    local tabIdx     = 0
    local currentTab = 0

    local function selectTab(i)
        for k, b in ipairs(tabBtns) do
            local on = (k == i)
            b.TextColor3 = on and T.Text or T.Dim
            if b:FindFirstChild("Bar") then b.Bar.Visible = on end
        end
        for k, tab in ipairs(tabs) do
            if tab._frame then
                tab._frame.Visible = (k == i)
            end
        end
        currentTab = i
    end

    -- ═══════════════════════════════════════════════
    -- API: Tab()
    -- ═══════════════════════════════════════════════
    local windowObj = {}

    function windowObj:Tab(name)
        tabIdx = tabIdx + 1
        local myIdx = tabIdx

        -- Frame de conteúdo desta aba
        local tabFrame = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false, ZIndex = 4,
        }, scroll)
        new("UIListLayout", { Padding = UDim.new(0, 8) }, tabFrame)

        -- Botão na tabBar
        local b = new("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 60, 1, 0),
            Font = FM, Text = name, TextColor3 = T.Dim, TextSize = 12,
            ZIndex = 4, TextTruncate = Enum.TextTruncate.AtEnd,
        }, tabBar)

        local bar = new("Frame", {
            Name = "Bar",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, -6, 0, 2),
            BackgroundColor3 = T.Accent, BorderSizePixel = 0,
            Visible = false, ZIndex = 5,
        }, b)
        corner(bar, 1)

        b.MouseButton1Click:Connect(function() selectTab(myIdx) end)

        local tabEntry = { _frame = tabFrame, _sectionCount = 0 }
        tabs[myIdx]    = tabEntry
        tabBtns[myIdx] = b

        if myIdx == 1 then
            task.defer(function() selectTab(1) end)
        end

        -- ────────────────────────────────────────
        -- SEÇÃO (agrupa elementos com título)
        -- ────────────────────────────────────────
        local tabAPI = {}

        local function makeSection(sectionTitle)
            local sec = new("Frame", {
                BackgroundColor3 = T.Panel, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 5,
            }, tabFrame)
            corner(sec, 7); gradStroke(sec)
            new("UIListLayout", { Padding = UDim.new(0, 7) }, sec)
            new("UIPadding", {
                PaddingBottom = UDim.new(0, 10), PaddingLeft  = UDim.new(0, 9),
                PaddingRight  = UDim.new(0, 9),  PaddingTop   = UDim.new(0, 9),
            }, sec)

            if sectionTitle and sectionTitle ~= "" then
                new("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = FB, Text = string.upper(sectionTitle),
                    TextColor3 = T.Dim, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
                }, sec)
            end
            return sec
        end

        -- seção padrão para elementos sem seção
        local defaultSection = makeSection("")

        local function getParent(sectionName)
            return sectionName and makeSection(sectionName) or defaultSection
        end

        -- ────────────────────────────────────────
        -- TOGGLE
        -- ────────────────────────────────────────
        function tabAPI:Toggle(text, default, callback, sectionName, saveKey)
            local parent = getParent(sectionName)
            local key    = saveKey or (title.."|"..name.."|"..text):gsub("%s", "_")

            local r = rowShell(parent)
            new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -55, 1, 0),
                Font = FM, Text = text, TextColor3 = T.Text, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
            }, r)

            local track = new("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 40, 0, 20),
                BackgroundColor3 = T.Element, BorderSizePixel = 0, ZIndex = 7,
            }, r)
            corner(track, 10)
            local tg = gradFill(track); tg.Enabled = false

            local knob = new("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = T.Text, BorderSizePixel = 0, ZIndex = 8,
            }, track)
            corner(knob, 8)

            local hit = new("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 9,
            }, track)

            local v = (state[key] ~= nil) and (state[key] == true) or (default == true)
            state[key] = v

            local function apply(anim)
                local goal = v and UDim2.new(0, 22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                if anim then
                    TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
                        { Position = goal }):Play()
                else
                    knob.Position = goal
                end
                track.BackgroundColor3 = v and T.Accent or T.Element
                tg.Enabled = v
            end

            hit.MouseButton1Click:Connect(function()
                v = not v
                state[key] = v
                apply(true)
                saveState()
                if callback then pcall(callback, v) end
            end)

            apply(false)

            return {
                SetValue = function(_, val)
                    v = (val == true)
                    state[key] = v
                    apply(true)
                    saveState()
                    if callback then pcall(callback, v) end
                end,
                GetValue = function() return v end,
            }
        end

        -- ────────────────────────────────────────
        -- BUTTON
        -- ────────────────────────────────────────
        function tabAPI:Button(text, callback, sectionName)
            local parent = getParent(sectionName)
            local r = rowShell(parent)
            r.BackgroundColor3 = T.Element

            new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = FM, Text = text, TextColor3 = T.Text, TextSize = 13, ZIndex = 7,
            }, r)

            local c = new("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 9,
            }, r)
            c.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)
            c.MouseEnter:Connect(function() r.BackgroundColor3 = T.ElementHi end)
            c.MouseLeave:Connect(function() r.BackgroundColor3 = T.Element   end)
        end

        -- ────────────────────────────────────────
        -- SLIDER
        -- ────────────────────────────────────────
        function tabAPI:Slider(text, minVal, maxVal, default, callback, sectionName, saveKey)
            local parent = getParent(sectionName)
            local key    = saveKey or (title.."|"..name.."|slider|"..text):gsub("%s", "_")

            local savedVal = state[key]
            local v = (type(savedVal) == "number") and savedVal or (default or minVal)
            state[key] = v

            local r = rowShell(parent, 54)

            new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -56, 0, 16),
                Font = FM, Text = text, TextColor3 = T.Text, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
            }, r)

            local valLbl = new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -52, 0, 0),
                Size = UDim2.new(0, 52, 0, 16),
                Font = FB, Text = tostring(math.floor(v)),
                TextColor3 = T.Dim, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7,
            }, r)

            local track = new("Frame", {
                BackgroundColor3 = T.Element, BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -16),
                Size = UDim2.new(1, 0, 0, 8), ZIndex = 7,
            }, r)
            corner(track, 4)

            local fill = new("Frame", {
                BackgroundColor3 = T.Accent, BorderSizePixel = 0,
                Size = UDim2.new((v - minVal) / (maxVal - minVal), 0, 1, 0), ZIndex = 8,
            }, track)
            corner(fill, 4); gradFill(fill, 90)

            local knob = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((v - minVal) / (maxVal - minVal), 0, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundColor3 = T.Text, BorderSizePixel = 0, ZIndex = 9,
            }, track)
            corner(knob, 7)

            local dragging = false
            local function update(x)
                local abs = track.AbsolutePosition.X
                local wid = track.AbsoluteSize.X
                local pct = math.clamp((x - abs) / wid, 0, 1)
                v = math.floor(minVal + (maxVal - minVal) * pct)
                local p = UDim2.new(pct, 0, 0.5, 0)
                knob.Position = p
                fill.Size = UDim2.new(pct, 0, 1, 0)
                valLbl.Text = tostring(v)
                state[key] = v
                saveState()
                if callback then pcall(callback, v) end
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; update(i.Position.X)
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if not dragging then return end
                if i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch then
                    update(i.Position.X)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            return {
                GetValue = function() return v end,
                SetValue = function(_, val)
                    local pct = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
                    v = math.floor(math.clamp(val, minVal, maxVal))
                    knob.Position = UDim2.new(pct, 0, 0.5, 0)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    valLbl.Text = tostring(v)
                    state[key] = v; saveState()
                    if callback then pcall(callback, v) end
                end,
            }
        end

        -- ────────────────────────────────────────
        -- INPUT (caixa de texto)
        -- ────────────────────────────────────────
        function tabAPI:Input(placeholder, callback, sectionName)
            local parent = getParent(sectionName)
            local r = rowShell(parent)

            local box = new("TextBox", {
                BackgroundColor3 = T.Element, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                Font = FR, Text = "",
                PlaceholderText = placeholder or "",
                PlaceholderColor3 = T.Dim,
                TextColor3 = T.Text, TextSize = 12,
                ClearTextOnFocus = false, ZIndex = 7,
            }, r)
            corner(box, 5)
            new("UIPadding", {
                PaddingLeft  = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
            }, box)

            if callback then
                box.FocusLost:Connect(function() pcall(callback, box.Text) end)
            end

            return {
                GetText  = function() return box.Text end,
                SetText  = function(_, t) box.Text = t end,
                OnChange = function(_, cb)
                    box:GetPropertyChangedSignal("Text"):Connect(function() pcall(cb, box.Text) end)
                end,
            }
        end

        -- ────────────────────────────────────────
        -- LABEL (texto estático)
        -- ────────────────────────────────────────
        function tabAPI:Label(text, sectionName)
            local parent = getParent(sectionName)
            local r = rowShell(parent, 28)
            r.BackgroundTransparency = 1

            local lbl = new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = FR, Text = text,
                TextColor3 = T.Dim, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
            }, r)

            return {
                SetText = function(_, t) lbl.Text = t end,
                GetText = function() return lbl.Text end,
            }
        end

        -- ────────────────────────────────────────
        -- DROPDOWN
        -- ────────────────────────────────────────
        function tabAPI:Dropdown(text, options, default, callback, sectionName)
            local parent = getParent(sectionName)
            local r      = rowShell(parent, 36)
            local open   = false
            local selected = default or options[1] or ""

            new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                Font = FM, Text = text, TextColor3 = T.Text, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
            }, r)

            local dropBtn = new("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.45, 0, 0, 24),
                BackgroundColor3 = T.Element, BorderSizePixel = 0,
                Font = FM, Text = selected.." ▾",
                TextColor3 = T.Text, TextSize = 12, ZIndex = 8,
            }, r)
            corner(dropBtn, 5); gradStroke(dropBtn)

            -- Lista flutuante
            local listFrame = new("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 1, 4),
                Size = UDim2.new(0.45, 0, 0, #options * 28),
                BackgroundColor3 = T.Panel, BorderSizePixel = 0,
                Visible = false, ZIndex = 20,
            }, r)
            corner(listFrame, 6); gradStroke(listFrame)
            new("UIListLayout", { Padding = UDim.new(0, 2) }, listFrame)
            new("UIPadding", {
                PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
            }, listFrame)

            for _, opt in ipairs(options) do
                local ob = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = T.Element, BorderSizePixel = 0,
                    Font = FM, Text = opt, TextColor3 = T.Text, TextSize = 12, ZIndex = 21,
                }, listFrame)
                corner(ob, 4)
                ob.MouseEnter:Connect(function() ob.BackgroundColor3 = T.ElementHi end)
                ob.MouseLeave:Connect(function() ob.BackgroundColor3 = T.Element end)
                ob.MouseButton1Click:Connect(function()
                    selected = opt
                    dropBtn.Text = opt.." ▾"
                    listFrame.Visible = false
                    open = false
                    if callback then pcall(callback, opt) end
                end)
            end

            dropBtn.MouseButton1Click:Connect(function()
                open = not open
                listFrame.Visible = open
            end)

            return {
                GetValue = function() return selected end,
                SetValue = function(_, v)
                    selected = v
                    dropBtn.Text = v.." ▾"
                    if callback then pcall(callback, v) end
                end,
            }
        end

        -- ────────────────────────────────────────
        -- KEYBIND (captura tecla)
        -- ────────────────────────────────────────
        function tabAPI:Keybind(text, default, callback, sectionName, saveKey)
            local parent = getParent(sectionName)
            local key    = saveKey or (title.."|"..name.."|key|"..text):gsub("%s","_")
            local saved  = state[key]
            local bound  = saved or (default and default.Name) or "None"
            local listening = false

            local r = rowShell(parent)
            new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.55, 0, 1, 0),
                Font = FM, Text = text, TextColor3 = T.Text, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
            }, r)

            local kb = new("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 70, 0, 22),
                BackgroundColor3 = T.Element, BorderSizePixel = 0,
                Font = FB, Text = bound,
                TextColor3 = T.Dim, TextSize = 12, ZIndex = 8,
            }, r)
            corner(kb, 5); gradStroke(kb)

            kb.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                kb.Text = "..."
                kb.TextColor3 = T.Accent
            end)

            UIS.InputBegan:Connect(function(i, gpe)
                if not listening then return end
                if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if gpe then return end
                bound = i.KeyCode.Name
                state[key] = bound; saveState()
                kb.Text = bound; kb.TextColor3 = T.Dim
                listening = false
            end)

            UIS.InputBegan:Connect(function(i, gpe)
                if gpe then return end
                if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if i.KeyCode.Name == bound and callback then
                    pcall(callback, i.KeyCode)
                end
            end)

            return {
                GetKey = function() return bound end,
            }
        end

        -- ────────────────────────────────────────
        -- SEPARADOR
        -- ────────────────────────────────────────
        function tabAPI:Separator(sectionName)
            local parent = getParent(sectionName)
            local r = new("Frame", {
                BackgroundColor3 = T.Element, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 1), ZIndex = 6,
            }, parent)
            gradFill(r, 90)
        end

        -- ────────────────────────────────────────
        -- TOGGLE COM JANELA FLUTUANTE (Config)
        -- ────────────────────────────────────────
        function tabAPI:ToggleWithWindow(text, default, winTitle, winSize, winBuilder, callback, sectionName, saveKey)
            local parent = getParent(sectionName)
            local key    = saveKey or (title.."|"..name.."|"..text):gsub("%s", "_")
            local winId  = key.."_win"

            local r = rowShell(parent)

            new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -78, 1, 0),
                Font = FM, Text = text, TextColor3 = T.Text, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
            }, r)

            -- Seta de config
            new("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -46, 0.5, 0),
                Size = UDim2.new(0, 14, 1, 0),
                BackgroundTransparency = 1,
                Text = "›", Font = FB, TextSize = 18,
                TextColor3 = T.Dim, ZIndex = 8,
            }, r)

            -- Toggle
            local track = new("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 40, 0, 20),
                BackgroundColor3 = T.Element, BorderSizePixel = 0, ZIndex = 7,
            }, r)
            corner(track, 10)
            local tg = gradFill(track); tg.Enabled = false

            local knob = new("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = T.Text, BorderSizePixel = 0, ZIndex = 8,
            }, track)
            corner(knob, 8)

            local hit = new("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 9,
            }, track)

            local v = (state[key] ~= nil) and (state[key] == true) or (default == true)
            state[key] = v

            local function apply(anim)
                local goal = v and UDim2.new(0, 22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                if anim then
                    TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
                        { Position = goal }):Play()
                else
                    knob.Position = goal
                end
                track.BackgroundColor3 = v and T.Accent or T.Element
                tg.Enabled = v
            end

            -- Hover na seta abre a janela
            hit.MouseEnter:Connect(function()
                track.BackgroundColor3 = T.Accent2; tg.Enabled = true
            end)
            hit.MouseLeave:Connect(function()
                track.BackgroundColor3 = v and T.Accent or T.Element
                tg.Enabled = v
            end)
            hit.MouseButton1Click:Connect(function()
                openWindow(winId, winTitle or text, winSize, winBuilder)
            end)

            apply(false)

            return {
                GetValue = function() return v end,
                SetValue = function(_, val)
                    v = (val == true); state[key] = v
                    apply(true); saveState()
                    if callback then pcall(callback, v) end
                end,
                OpenWindow = function()
                    openWindow(winId, winTitle or text, winSize, winBuilder)
                end,
            }
        end

        return tabAPI
    end

    -- ═══════════════════════════════════════════════
    -- API GLOBAL DA JANELA
    -- ═══════════════════════════════════════════════
    function windowObj:OpenWindow(id, winTitle, size, builder)
        return openWindow(id, winTitle, size, builder)
    end

    function windowObj:Destroy()
        gui:Destroy()
    end

    function windowObj:Toggle()
        gui.Enabled = not gui.Enabled
    end

    function windowObj:SetVisible(v)
        gui.Enabled = v
    end

    function windowObj:ResetLayout()
        LS.reset()
        panel.Position = UDim2.new(0.5, 0, 0.5, 0)
        panel.Size     = UDim2.new(0, 360, 0, 420)
        for _, entry in pairs(openedWindows) do
            entry.Frame.Position = UDim2.new(0.5, 50, 0.5, -30)
            entry.Frame.Size     = UDim2.new(0, 300, 0, 300)
        end
    end

    function windowObj:GetToggles()
        return state
    end

    windowObj._gui       = gui
    windowObj._panel     = panel
    windowObj._openWin   = openWindow

    return windowObj
end

-- ═══════════════════════════════════════════════════
-- HELPER: Abrir janela flutuante avulsa
-- ═══════════════════════════════════════════════════
function AuroraLib:QuickWindow(config)
    config = type(config) == "table" and config or {}
    warn("[AuroraLib] QuickWindow requer uma Window criada com :CreateWindow(). Use window:OpenWindow() para janelas flutuantes.")
end

-- Tema público para quem quiser customizar
AuroraLib.Theme = T

return AuroraLib
