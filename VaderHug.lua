--[[
    VaderHug UI
    VaderUI's look, Starlight's API (docs.nebulasoftworks.xyz/starlight).

    local VaderHug = loadstring(game:HttpGet("<raw url of this file>"))()
    local Window   = VaderHug:CreateWindow({ Name = "VaderHug", Subtitle = "v1.0", FileSettings = { ConfigFolder = "AOTR" } })
    local Section  = Window:CreateTabSection("Main")
    local Tab      = Section:CreateTab({ Name = "Farm", Columns = 2 }, "Farm")
    local Box      = Tab:CreateGroupbox({ Name = "Auto", Column = 1 }, "Auto")
    Box:CreateToggle({ Name = "Auto Farm", CurrentValue = false, Callback = function(On) end }, "AutoFarm")
    Tab:BuildConfigGroupbox(2)
    VaderHug:LoadAutoloadConfig()
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Env = (getgenv and getgenv()) or _G

if type(Env.VaderHug_Instance) == "table" and Env.VaderHug_Instance.Destroy then
    pcall(Env.VaderHug_Instance.Destroy, Env.VaderHug_Instance)
end

local DefaultLogo = "https://github.com/DONUT6599/ddgdhdf/blob/main/Asset_1.png?raw=true"
local DefaultMascot = "https://github.com/DONUT6599/ddgdhdf/blob/main/%E0%B9%84%E0%B8%A1%E0%B9%88%E0%B8%A1%E0%B8%B5%E0%B8%8A%E0%B8%B7%E0%B9%88%E0%B8%AD%20114_20260915013214.png?raw=true"

local Themes = {
    Dark = {
        Window = Color3.fromRGB(14, 12, 20),
        Work = Color3.fromRGB(22, 19, 31),
        Card = Color3.fromRGB(31, 27, 44),
        CardHover = Color3.fromRGB(40, 35, 58),
        Stroke = Color3.fromRGB(54, 46, 78),
        Field = Color3.fromRGB(17, 14, 25),
        Text = Color3.fromRGB(240, 236, 250),
        SubText = Color3.fromRGB(160, 152, 184),
        Accent = Color3.fromRGB(132, 88, 240),
        AccentText = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(62, 55, 84),
    },
    Amethyst = {
        Window = Color3.fromRGB(30, 18, 56),
        Work = Color3.fromRGB(40, 25, 72),
        Card = Color3.fromRGB(54, 36, 94),
        CardHover = Color3.fromRGB(66, 45, 112),
        Stroke = Color3.fromRGB(88, 64, 142),
        Field = Color3.fromRGB(28, 17, 52),
        Text = Color3.fromRGB(244, 240, 255),
        SubText = Color3.fromRGB(190, 176, 224),
        Accent = Color3.fromRGB(168, 128, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(82, 62, 128),
    },
    Light = {
        Window = Color3.fromRGB(236, 232, 245),
        Work = Color3.fromRGB(255, 255, 255),
        Card = Color3.fromRGB(245, 242, 251),
        CardHover = Color3.fromRGB(236, 231, 247),
        Stroke = Color3.fromRGB(220, 213, 238),
        Field = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(24, 18, 38),
        SubText = Color3.fromRGB(105, 96, 128),
        Accent = Color3.fromRGB(112, 68, 224),
        AccentText = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(205, 198, 222),
    },
}

local Library = {
    InterfaceBuild = "VaderHug 1.0.0",
    Folder = "VaderHug",
    Themes = Themes,
    ThemeNames = { "Dark", "Amethyst", "Light" },
    ThemeName = "Dark",
    CurrentTheme = Themes.Dark,
    BlurEnabled = false,
    WindowKeybind = "RightControl",
    Minimized = false,
    Maximized = false,
    NotificationsOpen = false,
    NotifyOnCallbackError = true,
    MascotTransparency = 0.5,
    Unloaded = false,
    Connections = {},
    ConfigSystem = {},
}

local Theme = Themes.Dark
local Registry = {}   -- { instance, { Property = "ThemeKey" } }
local Refreshers = {} -- repaint functions for state-dependent colours
local CardAlpha = 0   -- groupboxes go part see-through when the mascot is behind them
local Popups          -- the shared dropdown list and colour picker, built with the window
local Tooltip

--------------------------- [[ Helpers ]] ---------------------------

local function Bind(Inst, Map)
    table.insert(Registry, { Inst, Map })
    for Property, Key in pairs(Map) do
        Inst[Property] = Theme[Key]
    end
end

local function New(Class, Props, Children)
    local Inst = Instance.new(Class)
    if Inst:IsA("GuiObject") then
        Inst.BorderSizePixel = 0
    end
    if Inst:IsA("GuiButton") then
        Inst.AutoButtonColor = false
    end
    if Props then
        for Key, Value in pairs(Props) do
            if Key ~= "Parent" and Key ~= "Theme" then
                Inst[Key] = Value
            end
        end
        if Props.Theme then
            Bind(Inst, Props.Theme)
        end
    end
    for _, Child in ipairs(Children or {}) do
        Child.Parent = Inst
    end
    if Props and Props.Parent then
        Inst.Parent = Props.Parent
    end
    return Inst
end

local function Corner(Radius)
    return New("UICorner", { CornerRadius = UDim.new(0, Radius) })
end

local function Stroke()
    return New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Theme = { Color = "Stroke" } })
end

local function Pad(Top, Bottom, Left, Right)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, Top), PaddingBottom = UDim.new(0, Bottom),
        PaddingLeft = UDim.new(0, Left), PaddingRight = UDim.new(0, Right),
    })
end

local function List(Padding, Horizontal)
    return New("UIListLayout", {
        Padding = UDim.new(0, Padding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        VerticalAlignment = Horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,
    })
end

local function Tween(Inst, Time, Props, Style)
    local Created = TweenService:Create(Inst, TweenInfo.new(Time, Style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), Props)
    Created:Play()
    return Created
end

local function Track(Connection)
    table.insert(Library.Connections, Connection)
    return Connection
end

local function IsPress(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
    return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

-- Starlight icons are bare asset ids; rbxassetid:// and rbxthumb:// strings pass through
local function IconId(Icon)
    if type(Icon) == "number" then
        return Icon ~= 0 and ("rbxassetid://" .. Icon) or nil
    end
    if type(Icon) == "string" then
        if Icon:match("^rbx") then
            return Icon
        end
        if tonumber(Icon) then
            return "rbxassetid://" .. Icon
        end
    end
    return nil
end

local function ReadFile(Path)
    if not (isfile and readfile) then
        return nil
    end
    local ok, Data = pcall(function()
        return isfile(Path) and readfile(Path) or nil
    end)
    return ok and Data or nil
end

local function WriteFile(Path, Data)
    if not writefile then
        return false, "this executor has no writefile"
    end
    return pcall(writefile, Path, Data)
end

-- image data by its first bytes: a whole PNG (signature, and its closing IEND chunk), a JPEG, a GIF or a WebP
local function IsImageData(Data)
    if type(Data) ~= "string" or #Data < 100 then
        return false
    end
    if Data:sub(1, 8) == "\137PNG\r\n\26\n" then
        return Data:sub(-8, -5) == "IEND"
    end
    return Data:sub(1, 3) == "\255\216\255" or Data:sub(1, 4) == "GIF8" or (Data:sub(1, 4) == "RIFF" and Data:sub(9, 12) == "WEBP")
end

-- getcustomasset can close Roblox outright on some PCs, with no error to catch. A flag file says "running" while a
-- call is in there: a launch that finds it still saying so knows the last call never came back, and goes without
-- pictures on this PC from then on (delete VaderHug_asset_check.txt to try again)
local function SafeAsset(Path)
    local Get = getcustomasset or getsynasset
    if not (Get and isfile and readfile and writefile) then
        return nil
    end
    if ReadFile("VaderHug_asset_check.txt") == "running" then
        return nil
    end
    WriteFile("VaderHug_asset_check.txt", "running")
    local ok, Id = pcall(Get, Path)
    WriteFile("VaderHug_asset_check.txt", "done")
    return ok and Id or nil
end

local function ResolveImage(Source, CacheName)
    local Id = IconId(Source)
    if Id then
        return Id
    end
    if type(Source) ~= "string" or Source == "" or not (getcustomasset or getsynasset) or not isfile then
        return nil
    end

    -- only a real image file may reach getcustomasset: a cut-off download, or an error page saved as the picture,
    -- crashes the client on every launch (the file is cached)
    local Path = Source
    if Source:match("^https?://") then
        Path = CacheName
        if not IsImageData(ReadFile(Path)) then
            local ok, Data = pcall(game.HttpGet, game, Source)
            if not ok or not IsImageData(Data) or not WriteFile(Path, Data) then
                if delfile and isfile(Path) then
                    pcall(delfile, Path)
                end
                return nil
            end
        end
    elseif not IsImageData(ReadFile(Path)) then
        return nil
    end
    return SafeAsset(Path)
end

local function GetGuiParent()
    if gethui then
        local ok, Hui = pcall(gethui)
        if ok and Hui then
            return Hui
        end
    end
    local ok, CoreGui = pcall(function()
        local Service = game:GetService("CoreGui")
        local _ = Service.Name
        return Service
    end)
    if ok and CoreGui then
        return CoreGui
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function EnsureGui()
    if Library.Instance then
        return Library.Instance
    end
    local Gui = New("ScreenGui", {
        Name = tostring(Env.InterfaceName or "VaderHug"),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    Gui.Parent = GetGuiParent()
    Library.Instance = Gui

    Library.Notifications = New("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 300, 1, -32),
        ZIndex = 100,
        Parent = Gui,
    }, { List(8) })

    Library.Layer = New("Frame", {
        Name = "Layer",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 150,
        Parent = Gui,
    })

    Tooltip = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = false,
        Theme = { BackgroundColor3 = "Card", TextColor3 = "Text" },
        Parent = Library.Layer,
    }, {
        Corner(6),
        Stroke(),
        Pad(6, 6, 8, 8),
        New("UISizeConstraint", { MaxSize = Vector2.new(260, 200) }),
    })
    return Gui
end

-- the window's logo, or a drawn "V" badge when no image could be resolved
local function MakeLogo(Parent, Size, Props)
    local Inst
    if Library.LogoImage then
        Inst = New("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(Size, Size),
            Image = Library.LogoImage,
            ScaleType = Enum.ScaleType.Fit,
        })
    else
        Inst = New("TextLabel", {
            Size = UDim2.fromOffset(Size, Size),
            Font = Enum.Font.GothamBold,
            Text = "V",
            TextSize = math.floor(Size * 0.6),
            Theme = { BackgroundColor3 = "Accent", TextColor3 = "AccentText" },
        }, { Corner(math.floor(Size / 4)) })
    end
    for Key, Value in pairs(Props or {}) do
        Inst[Key] = Value
    end
    Inst.Parent = Parent
    return Inst
end

local function HookTooltip(Target, Values)
    local Token = 0
    Target.MouseEnter:Connect(function()
        Token = Token + 1
        local Mine = Token
        task.delay(0.6, function()
            local Text = Values.Tooltip
            if Mine ~= Token or type(Text) ~= "string" or Text == "" or not Target.Parent then
                return
            end
            local Origin = Library.Layer.AbsolutePosition
            Tooltip.Text = Text
            Tooltip.Position = UDim2.fromOffset(
                Target.AbsolutePosition.X - Origin.X,
                Target.AbsolutePosition.Y - Origin.Y + Target.AbsoluteSize.Y + 4
            )
            Tooltip.Visible = true
        end)
    end)
    Target.MouseLeave:Connect(function()
        Token = Token + 1
        Tooltip.Visible = false
    end)
end

--------------------------- [[ Library ]] ---------------------------

function Library:SafeCallback(Callback, ...)
    if type(Callback) ~= "function" then
        return
    end
    local ok, Problem = pcall(Callback, ...)
    if not ok then
        warn("[VaderHug] callback error: " .. tostring(Problem))
        if self.NotifyOnCallbackError and not self.Unloaded then
            self:Notification({ Title = "Callback Error", Content = tostring(Problem), Duration = 6 })
        end
    end
end

-- a theme name, or a palette table (keys it leaves out come from Dark)
function Library:SetTheme(NewTheme)
    local Palette = Themes[NewTheme]
    if type(NewTheme) == "table" then
        Palette = table.clone(Themes.Dark)
        for Key, Value in pairs(NewTheme) do
            Palette[Key] = Value
        end
    end
    Palette = Palette or Themes.Dark
    self.ThemeName = Themes[NewTheme] and NewTheme or (type(NewTheme) == "table" and "Custom" or "Dark")
    self.CurrentTheme = Palette
    Theme = Palette
    for _, Entry in ipairs(Registry) do
        for Property, Key in pairs(Entry[2]) do
            pcall(function()
                Entry[1][Property] = Theme[Key]
            end)
        end
    end
    for _, Refresh in ipairs(Refreshers) do
        pcall(Refresh)
    end
end

-- 0 is solid, 1 hides her; remembered in VaderHug_mascot_alpha.txt
function Library:SetMascotTransparency(Value)
    Value = math.clamp(tonumber(Value) or 0.5, 0, 1)
    self.MascotTransparency = Value
    if self.Window and self.Window.Mascot then
        self.Window.Mascot.ImageTransparency = Value
    end
    WriteFile("VaderHug_mascot_alpha.txt", tostring(Value))
end

function Library:Notification(Config, Index)
    Config = Config or {}
    EnsureGui()

    self.NotifyCount = (self.NotifyCount or 0) + 1
    local Card = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        GroupTransparency = 1,
        LayoutOrder = self.NotifyCount,
        Parent = self.Notifications,
    }, {
        Corner(12),
        New("UIStroke", { Color = Theme.Stroke }),
        Pad(10, 10, 10, 10),
    })

    local Icon = IconId(Config.Icon)
    if Icon then
        New("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(30, 30),
            Image = Icon,
            ImageColor3 = Theme.Accent,
            ScaleType = Enum.ScaleType.Fit,
            Parent = Card,
        })
    else
        MakeLogo(Card, 30)
    end

    local Texts = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -40, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Card,
    }, { List(2) })

    for Order, Line in ipairs({
        { Config.Title, Enum.Font.GothamBold, 13, Theme.Text },
        { Config.Content, Enum.Font.Gotham, 12, Theme.SubText },
    }) do
        if Line[1] ~= nil and tostring(Line[1]) ~= "" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Line[2],
                Text = tostring(Line[1]),
                TextSize = Line[3],
                TextColor3 = Line[4],
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = Order,
                Parent = Texts,
            })
        end
    end

    Tween(Card, 0.25, { GroupTransparency = 0 })

    local Notification = { Closed = false, Instance = Card, Values = Config }
    function Notification:Close()
        if self.Closed then
            return
        end
        self.Closed = true
        Tween(Card, 0.25, { GroupTransparency = 1 })
        task.delay(0.3, function()
            Card:Destroy()
        end)
    end

    -- no duration given: long enough to read it (about 18 characters a second)
    local Words = tostring(Config.Title or "") .. tostring(Config.Content or "")
    task.delay(tonumber(Config.Duration) or math.clamp(2 + #Words / 18, 3, 10), function()
        Notification:Close()
    end)
    return Notification
end
Library.Notify = Library.Notification -- VaderUI scripts call Notify

function Library:OnDestroy(Callback)
    self.DestroyFunction = Callback
end

function Library:Destroy()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    if type(self.DestroyFunction) == "function" then
        local ok, Problem = pcall(self.DestroyFunction)
        if not ok then
            warn("[VaderHug] OnDestroy error: " .. tostring(Problem))
        end
    end
    for _, Connection in ipairs(self.Connections) do
        pcall(Connection.Disconnect, Connection)
    end
    if self.Instance then
        self.Instance:Destroy()
    end
    if Env.VaderHug_Instance == self then
        Env.VaderHug_Instance = nil
    end
end

--------------------------- [[ Configs ]] ---------------------------

local ConfigSystem = Library.ConfigSystem

-- what each element class writes to a config
local SaveKeys = {
    Toggle = { "CurrentValue" },
    Slider = { "CurrentValue" },
    Input = { "CurrentValue" },
    Bind = { "CurrentValue" },
    ColorPicker = { "CurrentValue", "Transparency" },
    Dropdown = { "CurrentOption" },
}

local function Encode(Value)
    if typeof(Value) == "Color3" then
        return { Color = Value:ToHex() }
    end
    return Value
end

local function Decode(Value)
    if type(Value) == "table" and type(Value.Color) == "string" then
        return Color3.fromHex(Value.Color)
    end
    return Value
end

local function CleanName(Name)
    return (tostring(Name or ""):gsub("[/\\:%*%?\"<>|]", ""):match("^%s*(.-)%s*$"))
end

-- every element, keyed by the same path Starlight uses: section, tab, groupbox, element[, nested]
local function EachElement(Fn)
    if not Library.Window then
        return
    end
    for SectionKey, Section in pairs(Library.Window.TabSections) do
        for TabKey, Tab in pairs(Section.Tabs) do
            for BoxKey, Groupbox in pairs(Tab.Groupboxes) do
                for ElementKey, Element in pairs(Groupbox.Elements) do
                    Fn({ SectionKey, TabKey, BoxKey, ElementKey }, Element)
                    for NestedKey, Nested in pairs(Element.NestedElements or {}) do
                        Fn({ SectionKey, TabKey, BoxKey, ElementKey, NestedKey }, Nested)
                    end
                end
            end
        end
    end
end

local function Resolve(Path)
    local Section = Library.Window and Library.Window.TabSections[Path[1]]
    local Tab = Section and Section.Tabs[Path[2]]
    local Groupbox = Tab and Tab.Groupboxes[Path[3]]
    local Element = Groupbox and Groupbox.Elements[Path[4]]
    if Element and Path[5] ~= nil then
        return Element.NestedElements and Element.NestedElements[Path[5]]
    end
    return Element
end

local function ConfigFile(Name)
    return Library.ConfigPath .. "/" .. Name .. ".json"
end

function ConfigSystem:SaveConfig(Name)
    Name = CleanName(Name)
    if not Library.ConfigPath or Name == "" then
        return false, "pick a config name first"
    end
    local Objects = {}
    EachElement(function(Path, Element)
        local Keys = SaveKeys[Element.Class]
        if Keys and not Element.Values.IgnoreConfig then
            local Data = {}
            for _, Key in ipairs(Keys) do
                Data[Key] = Encode(Element.Values[Key])
            end
            table.insert(Objects, { Path = Path, Data = Data })
        end
    end)
    local ok, Json = pcall(HttpService.JSONEncode, HttpService, { Objects = Objects })
    if not ok then
        return false, "couldn't encode the config"
    end
    return WriteFile(ConfigFile(Name), Json)
end

function ConfigSystem:LoadConfig(Name)
    Name = CleanName(Name)
    local Text = Library.ConfigPath and Name ~= "" and ReadFile(ConfigFile(Name))
    if not Text then
        return false, "config not found"
    end
    local ok, Data = pcall(HttpService.JSONDecode, HttpService, Text)
    if not ok or type(Data) ~= "table" then
        return false, "config file is damaged"
    end
    for _, Object in ipairs(Data.Objects or {}) do
        local Element = type(Object.Path) == "table" and Resolve(Object.Path)
        if Element and type(Object.Data) == "table" then
            local Values = {}
            for Key, Value in pairs(Object.Data) do
                Values[Key] = Decode(Value)
            end
            Element:Set(Values)
        end
    end
    return true
end

function ConfigSystem:DeleteConfig(Name)
    Name = CleanName(Name)
    if not (delfile and Library.ConfigPath) or Name == "" then
        return false, "can't delete files here"
    end
    return pcall(delfile, ConfigFile(Name))
end

function ConfigSystem:RefreshConfigList()
    local Names = {}
    local ok, Files = pcall(function()
        return listfiles(Library.ConfigPath)
    end)
    for _, File in ipairs(ok and Files or {}) do
        local Name = tostring(File):match("([^/\\]+)%.json$")
        if Name then
            table.insert(Names, Name)
        end
    end
    table.sort(Names)
    return Names
end

function ConfigSystem:GetAutoload()
    local Name = Library.ConfigPath and ReadFile(Library.ConfigPath .. "/autoload.txt")
    return Name ~= "" and Name or nil
end

function ConfigSystem:SetAutoload(Name)
    if not Library.ConfigPath then
        return false, "no window yet"
    end
    if Name == nil then
        if delfile then
            pcall(delfile, Library.ConfigPath .. "/autoload.txt")
        end
        return true
    end
    return WriteFile(Library.ConfigPath .. "/autoload.txt", CleanName(Name))
end

function Library:LoadAutoloadConfig()
    local Name = ConfigSystem:GetAutoload()
    if not Name then
        return
    end
    local ok, Problem = ConfigSystem:LoadConfig(Name)
    self:Notification({
        Title = ok and "Autoloaded Configuration" or "Autoloading Error",
        Content = ok and ("Loaded config %q"):format(Name) or ("Couldn't load %q: %s"):format(Name, tostring(Problem)),
    })
end

function Library:LoadAutoloadTheme()
    local Name = self.ThemePath and ReadFile(self.ThemePath .. "/autoload.txt")
    if Name and Themes[Name] then
        self:SetTheme(Name)
    end
end

--------------------------- [[ Elements ]] ---------------------------

-- Set merges new values in and repaints; a new value (not just a new label or callback) also fires the callback
local function ApplySet(Object, Store, NewValues, NewIndex)
    for Key, Value in pairs(NewValues or {}) do
        Object.Values[Key] = Value
    end
    if NewIndex ~= nil and NewIndex ~= Object.Index then
        Store[Object.Index] = nil
        Object.Index = NewIndex
        Store[NewIndex] = Object
    end
    if Object.Render then
        Object:Render()
    end
    if NewValues and Object.Fire
        and (NewValues.CurrentValue ~= nil or NewValues.CurrentOption ~= nil or NewValues.Transparency ~= nil) then
        Object:Fire()
    end
end

-- a title line: icon, wrapping title, and a right-hand holder for the control and nested binds / colour pickers;
-- nested dropdowns go in the full-width Below frame
local function MakeLine(Element, Row)
    List(5).Parent = Row

    local Line = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Parent = Row,
    })
    local Icon = New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.fromOffset(16, 16),
        Theme = { ImageColor3 = "SubText" },
        Parent = Line,
    })
    local Title = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Theme = { TextColor3 = "Text" },
        Parent = Line,
    })
    local Right = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = Line,
    }, { List(6, true) })
    local Below = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Visible = false,
        Parent = Row,
    }, { List(4) })

    local Parts = { Line = Line, Title = Title, Right = Right, Below = Below, Count = 0 }

    local function Fit()
        local IconWidth = Icon.Visible and 22 or 0
        Title.Position = UDim2.fromOffset(IconWidth, 0)
        Title.Size = UDim2.new(1, -(IconWidth + Right.AbsoluteSize.X + 8), 0, 22)
    end
    Right:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)

    function Parts.Paint()
        local Image = IconId(Element.Values.Icon)
        Icon.Image = Image or ""
        Icon.Visible = Image ~= nil
        Title.Text = tostring(Element.Values.Name or "")
        Line.Visible = Title.Text ~= "" or Image ~= nil or #Right:GetChildren() > 1
        Fit()
    end
    function Parts.NextOrder()
        Parts.Count = Parts.Count + 1
        return Parts.Count
    end
    return Parts
end

local function NewNested(Parent, Line, Class, Settings, Index)
    local Nested = {
        Class = Class,
        Values = Settings or {},
        Index = Index ~= nil and Index or Class,
        Parent = Parent,
    }
    function Nested:Set(NewValues, NewIndex)
        ApplySet(self, Parent.NestedElements, NewValues, NewIndex)
    end
    function Nested:Destroy()
        if self.Cleanup then
            self:Cleanup()
        end
        if self.Instance then
            self.Instance:Destroy()
        end
        Parent.NestedElements[self.Index] = nil
        Line.Paint()
    end
    Parent.NestedElements[Nested.Index] = Nested
    return Nested
end

local function AddBind(Parent, Line, Settings, Index)
    local Bind = NewNested(Parent, Line, "Bind", Settings, Index)
    local V = Bind.Values
    local Synced = Parent.Class == "Toggle"
    if V.SyncToggleState == nil then
        V.SyncToggleState = Synced
    end
    Bind.Active = Synced and V.SyncToggleState and Parent.Values.CurrentValue or false
    if V.WindowSetting and V.CurrentValue then
        Library.WindowKeybind = V.CurrentValue
    end

    local Button = New("TextButton", {
        Size = UDim2.fromOffset(0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        LayoutOrder = Line.NextOrder(),
        Theme = { BackgroundColor3 = "Field", TextColor3 = "SubText" },
        Parent = Line.Right,
    }, { Corner(5), Stroke(), Pad(0, 0, 7, 7) })
    Bind.Instance = Button

    function Bind:Render()
        Button.Text = V.CurrentValue and tostring(V.CurrentValue) or "None"
    end
    function Bind:Fire()
        if V.WindowSetting then
            Library.WindowKeybind = V.CurrentValue
        end
        Library:SafeCallback(V.OnChangedCallback, V.CurrentValue)
    end

    local function Matches(Input)
        local Key = V.CurrentValue
        if Key == "MB1" then
            return Input.UserInputType == Enum.UserInputType.MouseButton1
        elseif Key == "MB2" then
            return Input.UserInputType == Enum.UserInputType.MouseButton2
        end
        return Key ~= nil and Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key
    end

    local function SetActive(State)
        Bind.Active = State
        if Synced and V.SyncToggleState and Parent.Values.CurrentValue ~= State then
            Parent:Set({ CurrentValue = State })
        end
        Library:SafeCallback(V.Callback, State)
    end

    Button.MouseButton1Click:Connect(function()
        if Library.Picking then
            return
        end
        Library.Picking = true
        Button.Text = "..."
        local Listener
        Listener = UserInputService.InputBegan:Connect(function(Input)
            local Key
            if Input.UserInputType == Enum.UserInputType.Keyboard then
                Key = Input.KeyCode.Name
            elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Key = "MB1"
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                Key = "MB2"
            else
                return
            end
            Listener:Disconnect()
            if Key == "Escape" then
                Bind:Render()
            elseif Key == "Backspace" then
                V.CurrentValue = nil
                Bind:Render()
                Bind:Fire()
            else
                Bind:Set({ CurrentValue = Key })
            end
            -- after this press has reached the other listeners, so it doesn't also trigger the bind
            task.defer(function()
                Library.Picking = false
            end)
        end)
        Track(Listener)
    end)

    local Began = Track(UserInputService.InputBegan:Connect(function(Input)
        if V.WindowSetting or Library.Picking or UserInputService:GetFocusedTextBox() or not Matches(Input) then
            return
        end
        if V.HoldToInteract then
            SetActive(true)
        elseif Synced and V.SyncToggleState then
            SetActive(not Parent.Values.CurrentValue)
        else
            SetActive(not Bind.Active)
        end
    end))
    local Ended = Track(UserInputService.InputEnded:Connect(function(Input)
        if V.HoldToInteract and Bind.Active and Matches(Input) then
            SetActive(false)
        end
    end))
    function Bind:Cleanup()
        Began:Disconnect()
        Ended:Disconnect()
    end

    Bind:Render()
    Line.Paint()
    return Bind
end

local function AddColorPicker(Parent, Line, Settings, Index)
    local Picker = NewNested(Parent, Line, "ColorPicker", Settings, Index)
    local V = Picker.Values
    V.CurrentValue = V.CurrentValue or Color3.new(1, 1, 1)

    local Swatch = New("TextButton", {
        Text = "",
        Size = UDim2.fromOffset(28, 18),
        LayoutOrder = Line.NextOrder(),
        Parent = Line.Right,
    }, { Corner(5), Stroke() })
    Picker.Instance = Swatch

    function Picker:Render()
        Swatch.BackgroundColor3 = V.CurrentValue
        Swatch.BackgroundTransparency = math.clamp(tonumber(V.Transparency) or 0, 0, 0.8)
        Popups.Refresh(self)
    end
    function Picker:Fire()
        Library:SafeCallback(V.Callback, V.CurrentValue, V.Transparency)
    end
    Swatch.MouseButton1Click:Connect(function()
        if Popups.IsOpen(Picker) then
            Popups.Close()
        else
            Popups.OpenColor(Picker, Swatch)
        end
    end)

    Picker:Render()
    Line.Paint()
    return Picker
end

local function AddDropdown(Parent, Line, Settings, Index)
    local Dropdown = NewNested(Parent, Line, "Dropdown", Settings, Index)
    local V = Dropdown.Values
    V.Options = V.Options or {}
    V.CurrentOption = V.CurrentOption or V.CurrentOptions or {} -- the docs' own snippet says CurrentOptions
    Line.Below.Visible = true

    local Box = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = Line.NextOrder(),
        Theme = { BackgroundColor3 = "Field", TextColor3 = "Text" },
        Parent = Line.Below,
    }, { Corner(7), Stroke(), Pad(0, 0, 9, 24) })
    New("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 18, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Image = "rbxassetid://10709790948",
        Theme = { ImageColor3 = "SubText" },
        Parent = Box,
    })
    Dropdown.Instance = Box

    -- Special 1 lists the server's players, 2 its teams
    function Dropdown:GetOptions()
        local Names = {}
        if V.Special == 1 then
            for _, Player in ipairs(Players:GetPlayers()) do
                table.insert(Names, Player.Name)
            end
        elseif V.Special == 2 then
            for _, Team in ipairs(game:GetService("Teams"):GetTeams()) do
                table.insert(Names, Team.Name)
            end
        else
            return V.Options
        end
        return Names
    end

    function Dropdown:Render()
        local Current = V.CurrentOption
        if type(Current) ~= "table" then
            Current = { Current }
        end
        local Options = self:GetOptions()
        local Special = V.Special == 1 or V.Special == 2
        local Picked = {}
        for _, Name in ipairs(Current) do
            -- a player or team may simply not be here right now: keep it
            if (Special or table.find(Options, Name)) and not table.find(Picked, Name) then
                table.insert(Picked, Name)
            end
        end
        if not V.MultipleOptions and #Picked > 1 then
            Picked = { Picked[1] }
        end
        if V.Required and #Picked == 0 and Options[1] ~= nil then
            Picked = { Options[1] }
        end
        V.CurrentOption = Picked
        Box.Text = #Picked > 0 and table.concat(Picked, ", ") or tostring(V.Placeholder or "--")
        Popups.Refresh(self)
    end
    function Dropdown:Fire()
        Library:SafeCallback(V.Callback, table.clone(V.CurrentOption))
    end

    Box.MouseButton1Click:Connect(function()
        if Popups.IsOpen(Dropdown) then
            Popups.Close()
        else
            Popups.OpenList(Dropdown, Box)
        end
    end)

    Dropdown.Instances = { Box = Box, Popup = Popups.ListPanel }
    Dropdown:Render()
    Line.Paint()
    return Dropdown
end

local function AllowNested(Element, Line)
    function Element:AddBind(Settings, Index)
        return AddBind(self, Line, Settings, Index)
    end
    function Element:AddColorPicker(Settings, Index)
        return AddColorPicker(self, Line, Settings, Index)
    end
    function Element:AddDropdown(Settings, Index)
        return AddDropdown(self, Line, Settings, Index)
    end
end

local GroupboxMethods = {}

local function NewElement(Groupbox, Class, Settings, Index, Clickable)
    Groupbox.Order = Groupbox.Order + 1
    local Element = {
        Class = Class,
        Values = Settings or {},
        Index = Index ~= nil and Index or (Class .. Groupbox.Order),
        NestedElements = {},
    }
    local Row = New(Clickable and "TextButton" or "Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = Groupbox.Order,
        Parent = Groupbox.Instance,
    })
    if Clickable then
        Row.Text = ""
    end
    Element.Instance = Row
    Element.IgnoreConfig = Element.Values.IgnoreConfig

    function Element:Set(NewValues, NewIndex)
        ApplySet(self, Groupbox.Elements, NewValues, NewIndex)
    end

    function Element:Lock(Reason)
        if self.LockFrame then
            self.LockFrame:Destroy()
        end
        self.LockFrame = New("TextButton", {
            BackgroundTransparency = 0.2,
            Size = UDim2.fromScale(1, 1),
            Font = Enum.Font.GothamMedium,
            Text = "🔒 " .. tostring(Reason or "Locked"),
            TextSize = 12,
            TextWrapped = true,
            ZIndex = 10,
            Theme = { BackgroundColor3 = "Card", TextColor3 = "SubText" },
            Parent = Row,
        }, { Corner(6) })
    end

    function Element:Unlock()
        if self.LockFrame then
            self.LockFrame:Destroy()
            self.LockFrame = nil
        end
    end

    function Element:Destroy()
        for _, Nested in pairs(self.NestedElements) do
            Nested:Destroy()
        end
        Row:Destroy()
        Groupbox.Elements[self.Index] = nil
    end

    Groupbox.Elements[Element.Index] = Element
    HookTooltip(Row, Element.Values)
    return Element, Row
end

function GroupboxMethods:CreateToggle(Settings, Index)
    local Element, Row = NewElement(self, "Toggle", Settings, Index, true)
    local V = Element.Values
    V.Style = V.Style or 2 -- switch, VaderUI's look; Style 1 is Starlight's checkbox
    local Line = MakeLine(Element, Row)

    local Box, Mark
    if V.Style == 1 then
        Box = New("Frame", { Size = UDim2.fromOffset(18, 18), LayoutOrder = 100, Parent = Line.Right }, { Corner(5), Stroke() })
        local Check = IconId(V.CheckboxIcon)
        Mark = Check and New("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Check,
            Theme = { ImageColor3 = "AccentText" },
            Parent = Box,
        }) or New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = Enum.Font.GothamBold,
            Text = "✓",
            TextSize = 13,
            Theme = { TextColor3 = "AccentText" },
            Parent = Box,
        })
    else
        Box = New("Frame", { Size = UDim2.fromOffset(34, 18), LayoutOrder = 100, Parent = Line.Right }, { Corner(9) })
        Mark = New("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.fromOffset(14, 14),
            Parent = Box,
        }, { Corner(7) })
    end

    function Element:Render()
        V.CurrentValue = V.CurrentValue == true
        Line.Paint()
        local On = V.CurrentValue
        if V.Style == 1 then
            Tween(Box, 0.15, { BackgroundColor3 = On and Theme.Accent or Theme.Field })
            Mark.Visible = On
        else
            Tween(Box, 0.15, { BackgroundColor3 = On and Theme.Accent or Theme.ToggleOff })
            Tween(Mark, 0.15, { Position = UDim2.fromOffset(On and 18 or 2, 2) })
        end
    end

    function Element:Fire()
        for _, Nested in pairs(self.NestedElements) do
            if Nested.Class == "Bind" and Nested.Values.SyncToggleState then
                Nested.Active = V.CurrentValue
            end
        end
        Library:SafeCallback(V.Callback, V.CurrentValue)
    end

    Row.MouseButton1Click:Connect(function()
        Element:Set({ CurrentValue = not V.CurrentValue })
    end)

    AllowNested(Element, Line)
    table.insert(Refreshers, function()
        Element:Render()
    end)
    Element:Render()
    return Element
end

function GroupboxMethods:CreateSlider(Settings, Index)
    local Element, Row = NewElement(self, "Slider", Settings, Index)
    local V = Element.Values
    V.Range = V.Range or { 0, 100 }
    V.Increment = V.Increment or 1
    V.CurrentValue = V.CurrentValue or V.Range[1]
    local Line = MakeLine(Element, Row)

    local ValueBox = New("TextBox", {
        Size = UDim2.fromOffset(0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        LayoutOrder = 100,
        Theme = { BackgroundColor3 = "Field", TextColor3 = "SubText" },
        Parent = Line.Right,
    }, { Corner(5), Pad(0, 0, 6, 6) })

    local Hit = New("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        LayoutOrder = 3,
        Parent = Row,
    })
    local Bar = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 4),
        Theme = { BackgroundColor3 = "ToggleOff" },
        Parent = Hit,
    }, { Corner(2) })
    local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), Theme = { BackgroundColor3 = "Accent" }, Parent = Bar }, { Corner(2) })
    local Knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12),
        Parent = Bar,
    }, { Corner(6) })

    local function Snap(Value)
        local Min, Max, Step = V.Range[1], V.Range[2], V.Increment
        Value = math.clamp(tonumber(Value) or Min, Min, Max)
        if Step > 0 then
            Value = math.clamp(Min + math.floor((Value - Min) / Step + 0.5) * Step, Min, Max)
        end
        return tonumber(string.format("%.4f", Value)) -- drop float noise like 0.30000000000000004
    end

    function Element:Render()
        Line.Paint()
        V.CurrentValue = Snap(V.CurrentValue)
        local Min, Max = V.Range[1], V.Range[2]
        local Alpha = Max > Min and (V.CurrentValue - Min) / (Max - Min) or 0
        Fill.Size = UDim2.fromScale(Alpha, 1)
        Knob.Position = UDim2.fromScale(Alpha, 0.5)
        if not ValueBox:IsFocused() then
            ValueBox.Text = tostring(V.CurrentValue) .. (V.HideMax and "" or ("/" .. tostring(Max))) .. tostring(V.Suffix or "")
        end
    end

    function Element:Fire()
        Library:SafeCallback(V.Callback, V.CurrentValue)
    end

    local Sliding = false
    local function SlideTo(Input)
        local Alpha = math.clamp((Input.Position.X - Bar.AbsolutePosition.X) / math.max(Bar.AbsoluteSize.X, 1), 0, 1)
        local Value = Snap(V.Range[1] + (V.Range[2] - V.Range[1]) * Alpha)
        if Value ~= V.CurrentValue then
            Element:Set({ CurrentValue = Value })
        end
    end
    Hit.InputBegan:Connect(function(Input)
        if IsPress(Input) then
            Sliding = true
            SlideTo(Input)
        end
    end)
    Track(UserInputService.InputChanged:Connect(function(Input)
        if Sliding and IsMove(Input) then
            SlideTo(Input)
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(Input)
        if IsPress(Input) then
            Sliding = false
        end
    end))

    ValueBox.Focused:Connect(function()
        ValueBox.Text = tostring(V.CurrentValue)
    end)
    ValueBox.FocusLost:Connect(function()
        Element:Set({ CurrentValue = tonumber(ValueBox.Text) or V.CurrentValue })
    end)

    Element:Render()
    return Element
end

function GroupboxMethods:CreateInput(Settings, Index)
    local Element, Row = NewElement(self, "Input", Settings, Index)
    local V = Element.Values
    V.CurrentValue = tostring(V.CurrentValue or "")
    local Line = MakeLine(Element, Row)
    Line.Below.Visible = true

    local Box = New("TextBox", {
        Size = UDim2.new(1, 0, 0, 28),
        ClearTextOnFocus = V.RemoveTextOnFocus == true,
        ClipsDescendants = true,
        Font = Enum.Font.Gotham,
        Text = V.CurrentValue,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Theme = { BackgroundColor3 = "Field", TextColor3 = "Text", PlaceholderColor3 = "SubText" },
        Parent = Line.Below,
    }, { Corner(7), Stroke(), Pad(0, 0, 9, 9) })

    -- nil when the text isn't allowed at all
    local function Clean(Text)
        local Max = tonumber(V.MaxCharacters)
        if Max and Max > 0 and #Text > Max then
            Text = Text:sub(1, Max)
        end
        if V.Numeric and Text ~= "" and Text ~= "-" and Text ~= "." and tonumber(Text) == nil then
            return nil
        end
        return Text
    end

    function Element:Render()
        Line.Paint()
        V.CurrentValue = tostring(V.CurrentValue or "")
        Box.PlaceholderText = tostring(V.PlaceholderText or "")
        if Box.Text ~= V.CurrentValue then
            Box.Text = V.CurrentValue
        end
    end

    function Element:Fire()
        Library:SafeCallback(V.Callback, V.CurrentValue)
    end

    Box:GetPropertyChangedSignal("Text"):Connect(function()
        local Text = Clean(Box.Text)
        if Text == nil then
            Box.Text = V.CurrentValue
            return
        end
        if Text ~= Box.Text then
            Box.Text = Text
            return
        end
        if Text == V.CurrentValue then
            return
        end
        V.CurrentValue = Text
        if not V.Enter then
            Element:Fire()
        end
    end)

    Box.FocusLost:Connect(function(EnterPressed)
        if V.Enter and EnterPressed then
            Element:Fire()
        end
        if V.RemoveTextAfterFocusLost then
            V.CurrentValue = ""
            Box.Text = ""
        end
    end)

    Element:Render()
    return Element
end

function GroupboxMethods:CreateButton(Settings, Index)
    local Element, Row = NewElement(self, "Button", Settings, Index, true)
    local V = Element.Values
    V.Style = V.Style or 2

    local Face = New("Frame", { Size = UDim2.new(1, 0, 0, 30), Parent = Row }, { Corner(8), Stroke() })
    local Icon = New("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        Parent = Face,
    })
    local Padding = Pad(0, 0, 10, 10)
    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = Face,
    }, { Padding })
    local Indicator = New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = Face,
    })

    local Hovering = false
    function Element:Render()
        local Primary = V.Style == 1
        local Image = IconId(V.Icon)
        local Mark = ({ "›", "⋯" })[V.IndicatorStyle or 0]
        Face.BackgroundColor3 = Primary and Theme.Accent or (Hovering and Theme.CardHover or Theme.Field)
        Face.BackgroundTransparency = (Primary and Hovering) and 0.15 or 0
        Label.TextColor3 = Primary and Theme.AccentText or Theme.Text
        Icon.ImageColor3 = Label.TextColor3
        Indicator.TextColor3 = Label.TextColor3
        Icon.Image = Image or ""
        Icon.Visible = Image ~= nil
        Indicator.Text = Mark or ""
        Label.Text = tostring(V.Name or "")
        Label.TextXAlignment = V.CenterContent and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        Padding.PaddingLeft = UDim.new(0, Image and 32 or 10)
        Padding.PaddingRight = UDim.new(0, Mark and 28 or 10)
    end

    Row.MouseEnter:Connect(function()
        Hovering = true
        Element:Render()
    end)
    Row.MouseLeave:Connect(function()
        Hovering = false
        Element:Render()
    end)
    Row.MouseButton1Click:Connect(function()
        Face.BackgroundTransparency = 0.4
        Tween(Face, 0.3, { BackgroundTransparency = 0 })
        Library:SafeCallback(V.Callback)
    end)

    table.insert(Refreshers, function()
        Element:Render()
    end)
    Element:Render()
    return Element
end

function GroupboxMethods:CreateLabel(Settings, Index)
    local Element, Row = NewElement(self, "Label", Settings, Index)
    local Line = MakeLine(Element, Row)
    Line.Title.Font = Enum.Font.Gotham
    function Element:Render()
        Line.Paint()
    end
    AllowNested(Element, Line)
    Element:Render()
    return Element
end

function GroupboxMethods:CreateParagraph(Settings, Index)
    local Element, Row = NewElement(self, "Paragraph", Settings, Index)
    local Line = MakeLine(Element, Row)
    Line.Title.Font = Enum.Font.GothamBold
    local Body = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 3,
        Theme = { TextColor3 = "SubText" },
        Parent = Row,
    })
    function Element:Render()
        Line.Paint()
        Body.Text = tostring(self.Values.Content or "")
        Body.Visible = Body.Text ~= ""
    end
    Element:Render()
    return Element
end

function GroupboxMethods:CreateDivider(Settings, Index)
    local Element, Row = NewElement(self, "Divider", Settings, Index)
    New("Frame", { Size = UDim2.new(1, 0, 0, 1), Theme = { BackgroundColor3 = "Stroke" }, Parent = Row })
    return Element
end

local function NewGroupbox(Tab, Settings, Index)
    Settings = Settings or {}
    Tab.Order = Tab.Order + 1
    local Column = math.clamp(math.floor(tonumber(Settings.Column) or 1), 1, #Tab.Columns)

    local Card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = Settings.Style == 2 and 1 or CardAlpha,
        LayoutOrder = Tab.Order,
        Theme = { BackgroundColor3 = "Card" },
        Parent = Tab.Columns[Column],
    }, {
        Corner(10),
        New("UIStroke", { Transparency = 0.3, Theme = { Color = "Stroke" } }),
        Pad(10, 10, 10, 10),
        List(7),
    })
    local Head = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = Card })
    local HeadIcon = New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 2),
        Size = UDim2.fromOffset(16, 16),
        Theme = { ImageColor3 = "Accent" },
        Parent = Head,
    })
    local HeadTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Theme = { TextColor3 = "Text" },
        Parent = Head,
    })

    local Groupbox = setmetatable({
        ClassName = "Groupbox",
        Values = Settings,
        Index = Index ~= nil and Index or ("Groupbox" .. Tab.Order),
        Instance = Card,
        Elements = {},
        Order = 0,
        Tab = Tab,
    }, { __index = GroupboxMethods })

    function Groupbox:Render()
        local Image = IconId(self.Values.Icon)
        HeadIcon.Image = Image or ""
        HeadIcon.Visible = Image ~= nil
        HeadTitle.Position = UDim2.fromOffset(Image and 22 or 0, 0)
        HeadTitle.Size = UDim2.new(1, Image and -22 or 0, 1, 0)
        HeadTitle.Text = tostring(self.Values.Name or "")
        Head.Visible = HeadTitle.Text ~= "" or Image ~= nil
    end
    function Groupbox:Set(NewValues, NewIndex)
        ApplySet(self, Tab.Groupboxes, NewValues, NewIndex)
    end
    function Groupbox:Destroy()
        Card:Destroy()
        Tab.Groupboxes[self.Index] = nil
    end

    Groupbox:Render()
    Tab.Groupboxes[Groupbox.Index] = Groupbox
    return Groupbox
end

--------------------------- [[ Prebuilt Groupboxes ]] ---------------------------

local function BuildConfigGroupbox(Tab, Column, Style, Centered)
    local Box = NewGroupbox(Tab, { Name = "Configurations", Column = Column, Style = Style }, "__prebuiltConfigGroupbox")
    if not (writefile and readfile and isfile and listfiles) then
        Box:CreateParagraph({ Name = "Config System Unavailable", Content = "Your executor has no file functions." }, "__Unavailable")
        return Box
    end

    local function Report(ok, Problem, Done)
        Library:Notification({ Title = "Configurations", Content = ok and Done or ("Failed: " .. tostring(Problem)) })
    end

    local NameInput = Box:CreateInput({ Name = "Config Name", PlaceholderText = "My config", IgnoreConfig = true }, "__ConfigName")
    local List = Box:CreateLabel({ Name = "Config List" }, "__ConfigList"):AddDropdown({
        Options = ConfigSystem:RefreshConfigList(),
        Placeholder = "No config selected",
        IgnoreConfig = true,
    }, "Dropdown")
    local AutoloadLabel = Box:CreateLabel({ Name = "" }, "__Autoload")

    local function Refresh()
        List:Set({ Options = ConfigSystem:RefreshConfigList() })
        AutoloadLabel:Set({ Name = "Autoload: " .. (ConfigSystem:GetAutoload() or "None") })
    end
    local function Selected()
        return List.Values.CurrentOption[1]
    end
    local function Button(Name, Callback)
        Box:CreateButton({ Name = Name, CenterContent = Centered, Callback = Callback }, "__" .. Name)
    end

    Button("Create Config", function()
        local Name = CleanName(NameInput.Values.CurrentValue)
        if Name == "" then
            return Report(false, "type a config name first")
        end
        if table.find(ConfigSystem:RefreshConfigList(), Name) then
            return Report(false, ("%q already exists, use Overwrite"):format(Name))
        end
        local ok, Problem = ConfigSystem:SaveConfig(Name)
        Report(ok, Problem, ("Created %q"):format(Name))
        Refresh()
    end)
    Button("Load Config", function()
        local ok, Problem = ConfigSystem:LoadConfig(Selected())
        Report(ok, Problem, ("Loaded %q"):format(tostring(Selected())))
    end)
    Button("Overwrite Config", function()
        local ok, Problem = ConfigSystem:SaveConfig(Selected())
        Report(ok, Problem, ("Overwrote %q"):format(tostring(Selected())))
    end)
    Button("Delete Config", function()
        local ok, Problem = ConfigSystem:DeleteConfig(Selected())
        Report(ok, Problem, ("Deleted %q"):format(tostring(Selected())))
        Refresh()
    end)
    Button("Refresh List", Refresh)
    Button("Set As Autoload", function()
        if not Selected() then
            return Report(false, "select a config first")
        end
        local ok, Problem = ConfigSystem:SetAutoload(Selected())
        Report(ok, Problem, ("%q loads on start"):format(Selected()))
        Refresh()
    end)
    Button("Reset Autoload", function()
        ConfigSystem:SetAutoload(nil)
        Refresh()
    end)

    Refresh()
    return Box
end

local function BuildThemeGroupbox(Tab, Column, Style, Centered)
    local Box = NewGroupbox(Tab, { Name = "Interface", Column = Column, Style = Style }, "__prebuiltThemeGroupbox")

    Library.ThemeDropdown = Box:CreateLabel({ Name = "Theme" }, "__Theme"):AddDropdown({
        Options = Library.ThemeNames,
        CurrentOption = { Library.ThemeName },
        Required = true,
        IgnoreConfig = true,
        Callback = function(Picked)
            Library:SetTheme(Picked[1])
        end,
    }, "Dropdown")

    Box:CreateButton({
        Name = "Set As Autoload Theme",
        CenterContent = Centered,
        Callback = function()
            local ok = Library.ThemePath and WriteFile(Library.ThemePath .. "/autoload.txt", Library.ThemeName)
            Library:Notification({ Title = "Interface", Content = ok and ("%s loads on start"):format(Library.ThemeName) or "Couldn't save the theme" })
        end,
    }, "__AutoloadTheme")

    Box:CreateLabel({ Name = "Toggle Interface" }, "__WindowKeybind"):AddBind({
        CurrentValue = Library.WindowKeybind,
        WindowSetting = true,
    }, "Bind")

    if Library.Window and Library.Window.Mascot then
        Box:CreateSlider({
            Name = "Mascot Transparency",
            Range = { 0, 1 },
            Increment = 0.05,
            HideMax = true,
            CurrentValue = Library.MascotTransparency,
            IgnoreConfig = true,
            Callback = function(Value)
                Library:SetMascotTransparency(Value)
            end,
        }, "__Mascot")
    end
    return Box
end

-- keep the theme dropdown in step when a theme comes from elsewhere (autoload, a script)
table.insert(Refreshers, function()
    local Dropdown = Library.ThemeDropdown
    if Dropdown and Dropdown.Values.CurrentOption[1] ~= Library.ThemeName and Themes[Library.ThemeName] then
        Dropdown.Values.CurrentOption = { Library.ThemeName }
        Dropdown:Render()
    end
end)

--------------------------- [[ Popups ]] ---------------------------

-- one dropdown list and one colour picker, shared by every element; whichever element opened it "owns" it
local function BuildPopups(Gui)
    local P = {}
    local Owner, Anchor
    local Busy = false -- the popup is the one changing its owner: don't rebuild under the click

    local Overlay = New("TextButton", {
        Name = "Popups",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 50,
        Parent = Gui,
    })

    local function Panel()
        return New("Frame", {
            Active = true,
            Visible = false,
            ZIndex = 51,
            Theme = { BackgroundColor3 = "Card" },
            Parent = Overlay,
        }, { Corner(9), New("UIStroke", { Theme = { Color = "Stroke" } }) })
    end

    local function Place(Frame, Width, Height)
        local Origin = Anchor.AbsolutePosition - Overlay.AbsolutePosition
        local X = Origin.X + Anchor.AbsoluteSize.X - Width
        local Y = Origin.Y + Anchor.AbsoluteSize.Y + 4
        if Y + Height > Overlay.AbsoluteSize.Y - 8 then
            Y = math.max(Origin.Y - Height - 4, 8)
        end
        Frame.Size = UDim2.fromOffset(Width, Height)
        Frame.Position = UDim2.fromOffset(math.max(X, 8), Y)
    end

    ---------------- list ----------------

    local ListPanel = Panel()
    P.ListPanel = ListPanel
    local Search = New("TextBox", {
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 0, 26),
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
        Theme = { BackgroundColor3 = "Field", TextColor3 = "Text", PlaceholderColor3 = "SubText" },
        Parent = ListPanel,
    }, { Corner(6), Pad(0, 0, 8, 8) })
    local Scroll = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 38),
        Size = UDim2.new(1, -12, 1, -44),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 52,
        Theme = { ScrollBarImageColor3 = "Stroke" },
        Parent = ListPanel,
    }, { List(2) })

    local function FillList()
        for _, Child in ipairs(Scroll:GetChildren()) do
            if Child:IsA("TextButton") then
                Child:Destroy()
            end
        end
        local Dropdown = Owner
        if not (Dropdown and Dropdown.Class == "Dropdown" and Anchor) then
            return
        end
        local V = Dropdown.Values
        local Query = Search.Text:lower()
        local Count = 0

        for Order, Value in ipairs(Dropdown:GetOptions()) do
            local Text = tostring(Value)
            if Query == "" or Text:lower():find(Query, 1, true) then
                Count = Count + 1
                local Option = New("TextButton", {
                    BackgroundColor3 = Theme.CardHover,
                    Size = UDim2.new(1, -5, 0, 26),
                    Font = Enum.Font.Gotham,
                    Text = Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    LayoutOrder = Order,
                    ZIndex = 53,
                    Parent = Scroll,
                }, { Corner(6), Pad(0, 0, 8, 22) })
                local Dot = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 14, 0.5, 0),
                    Size = UDim2.fromOffset(8, 8),
                    BackgroundColor3 = Theme.Accent,
                    ZIndex = 54,
                    Parent = Option,
                }, { Corner(4) })

                local function Paint()
                    local Selected = table.find(V.CurrentOption, Value) ~= nil
                    Dot.Visible = Selected
                    Option.BackgroundTransparency = Selected and 0 or 1
                    Option.TextColor3 = Selected and Theme.Accent or Theme.Text
                    Option.Font = Selected and Enum.Font.GothamMedium or Enum.Font.Gotham
                end
                Paint()
                Option.MouseEnter:Connect(function()
                    Option.BackgroundTransparency = 0
                end)
                Option.MouseLeave:Connect(Paint)

                Option.MouseButton1Click:Connect(function()
                    local Picked = table.clone(V.CurrentOption)
                    local At = table.find(Picked, Value)
                    if V.MultipleOptions then
                        if not At then
                            table.insert(Picked, Value)
                        elseif #Picked > 1 or not V.Required then
                            table.remove(Picked, At)
                        end
                    elseif At then
                        Picked = V.Required and Picked or {}
                    else
                        Picked = { Value }
                    end
                    Busy = true
                    Dropdown:Set({ CurrentOption = Picked })
                    Busy = false
                    if V.MultipleOptions then
                        Paint()
                    else
                        P.Close()
                    end
                end)
            end
        end

        Scroll.CanvasSize = UDim2.fromOffset(0, math.max(Count * 28 - 2, 0))
        Place(ListPanel, math.max(Anchor.AbsoluteSize.X, 210), math.clamp(Count * 28 - 2, 26, 196) + 44)
    end
    Search:GetPropertyChangedSignal("Text"):Connect(FillList)

    ---------------- colour ----------------

    local ColorPanel = Panel()
    local H, S, Vv, A = 0, 0, 1, nil

    local SV = New("Frame", {
        Active = true,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 0, 130),
        ZIndex = 52,
        Parent = ColorPanel,
    }, { Corner(6) })
    New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 53,
        Parent = SV,
    }, { Corner(6), New("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
    New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        ZIndex = 54,
        Parent = SV,
    }, { Corner(6), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
    local SVCursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.fromOffset(10, 10),
        ZIndex = 55,
        Parent = SV,
    }, { Corner(5), New("UIStroke", { Color = Color3.new(0, 0, 0) }) })

    local Rainbow = {}
    for Step = 0, 6 do
        table.insert(Rainbow, ColorSequenceKeypoint.new(Step / 6, Color3.fromHSV(Step / 6, 1, 1)))
    end

    local function Bar(Y, Gradient)
        local Frame = New("Frame", {
            Active = true,
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.fromOffset(8, Y),
            Size = UDim2.new(1, -16, 0, 12),
            ZIndex = 52,
            Parent = ColorPanel,
        }, { Corner(6), Gradient })
        local Cursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(4, 16),
            ZIndex = 53,
            Parent = Frame,
        }, { Corner(2), New("UIStroke", { Color = Color3.new(0, 0, 0) }) })
        return Frame, Cursor
    end
    local HueBar, HueCursor = Bar(146, New("UIGradient", { Color = ColorSequence.new(Rainbow) }))
    local AlphaBar, AlphaCursor = Bar(166, New("UIGradient", { Transparency = NumberSequence.new(0, 1) }))

    local Hex = New("TextBox", {
        Size = UDim2.new(1, -16, 0, 26),
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ZIndex = 52,
        Theme = { BackgroundColor3 = "Field", TextColor3 = "Text" },
        Parent = ColorPanel,
    }, { Corner(6) })

    local function PaintColor()
        local Color = Color3.fromHSV(H, S, Vv)
        SV.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
        SVCursor.Position = UDim2.fromScale(S, 1 - Vv)
        HueCursor.Position = UDim2.fromScale(H, 0.5)
        AlphaBar.BackgroundColor3 = Color
        AlphaCursor.Position = UDim2.fromScale(A or 0, 0.5)
        if not Hex:IsFocused() then
            Hex.Text = "#" .. Color:ToHex():upper()
        end
    end

    local function LoadColor()
        H, S, Vv = Owner.Values.CurrentValue:ToHSV()
        A = Owner.Values.Transparency
        PaintColor()
    end

    local function PushColor()
        Busy = true
        Owner:Set({ CurrentValue = Color3.fromHSV(H, S, Vv), Transparency = A })
        Busy = false
        PaintColor()
    end

    local Dragging
    local function DragTo(Input)
        local Position, Corner0, Size = Input.Position, Dragging.AbsolutePosition, Dragging.AbsoluteSize
        local X = math.clamp((Position.X - Corner0.X) / math.max(Size.X, 1), 0, 1)
        local Y = math.clamp((Position.Y - Corner0.Y) / math.max(Size.Y, 1), 0, 1)
        if Dragging == SV then
            S, Vv = X, 1 - Y
        elseif Dragging == HueBar then
            H = X
        else
            A = X
        end
        PushColor()
    end
    for _, Area in ipairs({ SV, HueBar, AlphaBar }) do
        Area.InputBegan:Connect(function(Input)
            if IsPress(Input) and Owner then
                Dragging = Area
                DragTo(Input)
            end
        end)
    end
    Track(UserInputService.InputChanged:Connect(function(Input)
        if Dragging and Owner and IsMove(Input) then
            DragTo(Input)
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(Input)
        if IsPress(Input) then
            Dragging = nil
        end
    end))
    Hex.FocusLost:Connect(function()
        local ok, Color = pcall(Color3.fromHex, (Hex.Text:gsub("[^%x]", "")))
        if ok and Owner then
            H, S, Vv = Color:ToHSV()
            PushColor()
        else
            PaintColor()
        end
    end)

    ---------------- shared ----------------

    function P.Close()
        Overlay.Visible = false
        ListPanel.Visible = false
        ColorPanel.Visible = false
        Owner, Anchor, Dragging = nil, nil, nil
    end

    function P.IsOpen(Object)
        return Owner == Object
    end

    function P.OpenList(Dropdown, Box)
        P.Close()
        Owner, Anchor = Dropdown, Box
        Search.Text = ""
        Scroll.CanvasPosition = Vector2.zero
        ListPanel.Visible = true
        Overlay.Visible = true
        FillList()
    end

    function P.OpenColor(Picker, Swatch)
        P.Close()
        Owner, Anchor = Picker, Swatch
        local HasAlpha = Picker.Values.Transparency ~= nil
        AlphaBar.Visible = HasAlpha
        Hex.Position = UDim2.fromOffset(8, HasAlpha and 186 or 166)
        LoadColor()
        ColorPanel.Visible = true
        Overlay.Visible = true
        Place(ColorPanel, 220, HasAlpha and 220 or 200)
    end

    -- the owner changed from outside (a script, a config): show it
    function P.Refresh(Object)
        if Busy or Owner ~= Object then
            return
        end
        if ListPanel.Visible then
            FillList()
        else
            LoadColor()
        end
    end

    Overlay.MouseButton1Click:Connect(P.Close)
    return P
end

--------------------------- [[ Window ]] ---------------------------

function Library:CreateWindow(Config)
    Config = Config or {}
    local Gui = EnsureGui()
    self.NotifyOnCallbackError = Config.NotifyOnCallbackError ~= false

    -- VaderHug/[RootFolder/]ConfigFolder/{configs,themes}
    local FileSettings = Config.FileSettings or {}
    local Root = FileSettings.RootFolder and (self.Folder .. "/" .. CleanName(FileSettings.RootFolder)) or self.Folder
    local Home = Root .. "/" .. CleanName(FileSettings.ConfigFolder or "Default")
    self.ConfigPath = Home .. "/configs"
    self.ThemePath = (FileSettings.ThemesInRoot and FileSettings.RootFolder) and (Root .. "/themes") or (Home .. "/themes")
    if isfolder and makefolder then
        for _, Path in ipairs({ self.Folder, Root, Home, self.ConfigPath, self.ThemePath }) do
            pcall(function()
                if not isfolder(Path) then
                    makefolder(Path)
                end
            end)
        end
    end

    self.LogoImage = ResolveImage(Config.Icon or Config.Logo or Env.VaderHug_Logo or DefaultLogo, "VaderHug_logo.png")
    local MascotImage
    if Config.Mascot ~= false then
        MascotImage = ResolveImage(Config.Mascot or DefaultMascot, "VaderHug_mascot.png")
    end
    if Config.Theme then
        self:SetTheme(Config.Theme)
    end

    local Requested = Config.DefaultSize or UDim2.fromOffset(720, 480)
    local Viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local Width = math.clamp(Requested.X.Offset, 560, math.max(560, Viewport.X - 20))
    local Height = math.clamp(Requested.Y.Offset, 380, math.max(380, Viewport.Y - 20))
    local SideWidth = 190

    local Window = { TabSections = {}, Tabs = {}, CurrentTab = nil, Values = Config }
    self.Window = Window
    Popups = BuildPopups(Gui)

    local Holder = New("Frame", {
        Name = "Window",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1.5, Height),
        Size = UDim2.fromOffset(Width, Height),
        Parent = Gui,
    })
    Window.Instance = Holder

    New("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1.2, 1.2),
        Image = "rbxassetid://313486536",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.35,
        Parent = Holder,
    })

    local Main = New("Frame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
        Theme = { BackgroundColor3 = "Window" },
        Parent = Holder,
    }, { Corner(14), New("UIStroke", { Theme = { Color = "Stroke" } }) })
    Window.Main = Main

    --------------------------- [[ Dragging ]] ---------------------------

    local ShownPosition = UDim2.fromScale(0.5, 0.5)
    local Drag = { Active = false }

    local function HookDrag(Handle)
        Handle.InputBegan:Connect(function(Input)
            if IsPress(Input) and not Library.Minimized then
                Drag.Active, Drag.Start, Drag.Origin = true, Input.Position, Holder.Position
            end
        end)
    end

    -- ends here rather than on the input object: mouse input objects are reused, so a listener left on one
    -- would later save the minimized, off-screen spot as "shown"
    Track(UserInputService.InputEnded:Connect(function(Input)
        if Drag.Active and IsPress(Input) then
            Drag.Active = false
            if not Library.Minimized then
                ShownPosition = Holder.Position
            end
        end
    end))
    Track(UserInputService.InputChanged:Connect(function(Input)
        if Drag.Active and IsMove(Input) then
            local Delta = Input.Position - Drag.Start
            Holder.Position = UDim2.new(
                Drag.Origin.X.Scale, Drag.Origin.X.Offset + Delta.X,
                Drag.Origin.Y.Scale, Drag.Origin.Y.Offset + Delta.Y
            )
        end
    end))

    --------------------------- [[ Work Area ]] ---------------------------

    local Work = New("Frame", {
        Name = "Work",
        Position = UDim2.fromOffset(SideWidth, 0),
        Size = UDim2.new(1, -SideWidth, 1, 0),
        Theme = { BackgroundColor3 = "Work" },
        Parent = Main,
    }, { Corner(14) })
    -- squares off the work area's left corners where it meets the sidebar
    New("Frame", { Size = UDim2.new(0, 14, 1, 0), Theme = { BackgroundColor3 = "Work" }, Parent = Work })

    if MascotImage then
        CardAlpha = 0.3
        -- explicit config wins, then the remembered setting, then the default
        local Saved = tonumber(ReadFile("VaderHug_mascot_alpha.txt") or "")
        self.MascotTransparency = math.clamp(Config.MascotTransparency or Saved or self.MascotTransparency, 0, 1)
        Window.Mascot = New("ImageLabel", {
            Name = "Mascot",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -4, 1, 0),
            Size = UDim2.new(1, -8, 1, -8),
            Image = MascotImage,
            ImageTransparency = self.MascotTransparency,
            ScaleType = Enum.ScaleType.Fit,
            Parent = Work,
        }, { New("UIAspectRatioConstraint", { AspectRatio = 1462 / 2000, DominantAxis = Enum.DominantAxis.Height }) })
    else
        CardAlpha = 0
    end

    local Header = New("TextLabel", {
        Name = "Header",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 12),
        Size = UDim2.new(1, -36, 0, 26),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
        Theme = { TextColor3 = "Text" },
        Parent = Work,
    })

    local Pages = New("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 48),
        Size = UDim2.new(1, -20, 1, -56),
        ZIndex = 2,
        Parent = Work,
    })

    HookDrag(New("Frame", {
        Name = "DragBar",
        Active = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 3,
        Parent = Main,
    }))

    --------------------------- [[ Sidebar ]] ---------------------------

    local Lights = New("Frame", {
        Name = "Lights",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(60, 12),
        ZIndex = 4,
        Parent = Main,
    }, { List(8, true) })

    local function MakeLight(Order, Color)
        return New("TextButton", {
            Text = "",
            BackgroundColor3 = Color,
            Size = UDim2.fromOffset(12, 12),
            LayoutOrder = Order,
            ZIndex = 4,
            Parent = Lights,
        }, { Corner(6) })
    end
    local CloseLight = MakeLight(1, Color3.fromRGB(254, 94, 86))
    local MinimizeLight = MakeLight(2, Color3.fromRGB(255, 189, 46))
    local ZoomLight = MakeLight(3, Color3.fromRGB(39, 200, 63))

    local Brand = New("Frame", {
        Name = "Brand",
        Active = true,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 38),
        Size = UDim2.new(0, SideWidth - 24, 0, 36),
        ZIndex = 3,
        Parent = Main,
    })
    HookDrag(Brand)
    MakeLogo(Brand, 36)
    for _, Spec in ipairs({
        { Config.Name or "VaderHug", Enum.Font.GothamBold, 12, 2, "Text" },
        { Config.Subtitle or "", Enum.Font.Gotham, 11, 19, "SubText" },
    }) do
        New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(44, Spec[4]),
            Size = UDim2.new(1, -44, 0, 15),
            Font = Spec[2],
            Text = tostring(Spec[1]),
            TextSize = Spec[3],
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Theme = { TextColor3 = Spec[5] },
            Parent = Brand,
        })
    end

    local SearchFrame = New("Frame", {
        Name = "Search",
        Position = UDim2.fromOffset(12, 84),
        Size = UDim2.new(0, SideWidth - 24, 0, 28),
        Theme = { BackgroundColor3 = "Card" },
        Parent = Main,
    }, { Corner(8) })
    New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 7),
        Size = UDim2.fromOffset(14, 14),
        Image = "rbxassetid://2804603863",
        ScaleType = Enum.ScaleType.Fit,
        Theme = { ImageColor3 = "SubText" },
        Parent = SearchFrame,
    })
    local SearchBox = New("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.new(1, -34, 1, 0),
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Theme = { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
        Parent = SearchFrame,
    })

    local TabList = New("ScrollingFrame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 122),
        Size = UDim2.new(0, SideWidth - 24, 1, -134),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Theme = { ScrollBarImageColor3 = "Stroke" },
        Parent = Main,
    }, { List(6) })

    --------------------------- [[ Dialog ]] ---------------------------

    local Dim = New("TextButton", {
        Name = "Dialog",
        Text = "",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 20,
        Parent = Main,
    }, { Corner(14) })

    local DialogCard = New("Frame", {
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(300, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 21,
        Theme = { BackgroundColor3 = "Card" },
        Parent = Dim,
    }, {
        Corner(14),
        New("UIStroke", { Theme = { Color = "Stroke" } }),
        Pad(18, 14, 16, 16),
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }),
    })
    local DialogIcon = New("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(48, 48),
        ScaleType = Enum.ScaleType.Fit,
        LayoutOrder = 1,
        ZIndex = 22,
        Parent = DialogCard,
    })
    local function DialogText(Order, Font, Size, Key)
        return New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Font,
            TextSize = Size,
            TextWrapped = true,
            LayoutOrder = Order,
            ZIndex = 22,
            Theme = { TextColor3 = Key },
            Parent = DialogCard,
        })
    end
    local DialogTitle = DialogText(2, Enum.Font.GothamBold, 16, "Text")
    local DialogContent = DialogText(3, Enum.Font.Gotham, 12, "SubText")
    local DialogActions = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 4,
        ZIndex = 22,
        Parent = DialogCard,
    }, { List(6), Pad(6, 0, 0, 0) })

    -- Type 1: Actions.Primary plus grey buttons. Type 2: text inputs that fire on Enter, and a Close button
    function Window:PromptDialog(Options)
        Options = Options or {}
        local Actions = Options.Actions or {}
        local Image = IconId(Options.Icon) or Library.LogoImage
        DialogIcon.Image = Image or ""
        DialogIcon.Visible = Image ~= nil
        DialogTitle.Text = tostring(Options.Name or Options.Title or "Notice")
        DialogContent.Text = tostring(Options.Content or "")
        for _, Child in ipairs(DialogActions:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end

        local Dialog = { Instance = Dim, Values = Options }
        function Dialog:Close()
            Dim.Visible = false
        end

        local Order = 0
        local function AddButton(Spec, Primary)
            Order = Order + 1
            local Button = New("TextButton", {
                BackgroundColor3 = Primary and Theme.Accent or Theme.CardHover,
                Size = UDim2.new(1, 0, 0, 32),
                Font = Enum.Font.GothamMedium,
                Text = tostring(Spec.Name or Spec.Title or "OK"),
                TextColor3 = Primary and Theme.AccentText or Theme.Text,
                TextSize = 13,
                LayoutOrder = Order,
                ZIndex = 23,
                Parent = DialogActions,
            }, { Corner(8) })
            Button.MouseButton1Click:Connect(function()
                Dim.Visible = false
                Library:SafeCallback(Spec.Callback)
            end)
        end

        if Options.Type == 2 then
            for _, Spec in ipairs(Actions) do
                Order = Order + 1
                local Box = New("TextBox", {
                    Size = UDim2.new(1, 0, 0, 30),
                    ClearTextOnFocus = Spec.RemoveTextOnFocus == true,
                    Font = Enum.Font.Gotham,
                    PlaceholderText = tostring(Spec.PlaceholderText or ""),
                    Text = tostring(Spec.CurrentValue or ""),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = Order,
                    ZIndex = 23,
                    Theme = { BackgroundColor3 = "Field", TextColor3 = "Text", PlaceholderColor3 = "SubText" },
                    Parent = DialogActions,
                }, { Corner(7), Stroke(), Pad(0, 0, 9, 9) })
                Box.FocusLost:Connect(function(EnterPressed)
                    local Text = Box.Text
                    local Max = tonumber(Spec.MaxCharacters)
                    if Max and Max > 0 then
                        Text = Text:sub(1, Max)
                    end
                    if EnterPressed and not (Spec.Numeric and tonumber(Text) == nil) then
                        Library:SafeCallback(Spec.Callback, Text)
                    end
                end)
            end
            AddButton({ Name = "Close" }, false)
        else
            if Actions.Primary then
                AddButton(Actions.Primary, true)
            end
            for _, Spec in ipairs(Actions) do
                AddButton(Spec, false)
            end
            if Order == 0 then
                AddButton({ Name = "OK" }, true)
            end
        end

        Dim.Visible = true
        return Dialog
    end

    --------------------------- [[ Minimize ]] ---------------------------

    local Reopen = New("TextButton", {
        Name = "Reopen",
        Text = "",
        Position = UDim2.new(0, 16, 0.5, -24),
        Size = UDim2.fromOffset(48, 48),
        Visible = false,
        ZIndex = 10,
        Theme = { BackgroundColor3 = "Window" },
        Parent = Gui,
    }, { Corner(24), New("UIStroke", { Thickness = 2, Theme = { Color = "Accent" } }) })
    MakeLogo(Reopen, 36, { Position = UDim2.fromOffset(6, 6), ZIndex = 11 })

    local Motion = 0
    function Window:Minimize()
        Library.Minimized = not Library.Minimized
        Motion = Motion + 1
        local Token = Motion
        Popups.Close()

        if Library.Minimized then
            Reopen.Visible = true
            Tween(Holder, 0.4, { Position = UDim2.new(ShownPosition.X.Scale, ShownPosition.X.Offset, 1.5, Holder.AbsoluteSize.Y) })
            task.delay(0.4, function()
                if Motion == Token then
                    Holder.Visible = false
                end
            end)
            if not self.MinimizeHintShown then
                self.MinimizeHintShown = true
                Library:Notification({
                    Title = "Interface",
                    Content = ("Press %s or the logo button to bring it back."):format(tostring(Library.WindowKeybind or "the logo")),
                    Duration = 6,
                })
            end
        else
            Reopen.Visible = false
            Holder.Visible = true
            Tween(Holder, 0.4, { Position = ShownPosition })
        end
    end

    Reopen.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)
    MinimizeLight.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)
    ZoomLight.MouseButton1Click:Connect(function()
        Library.Maximized = not Library.Maximized
        Popups.Close()
        Tween(Holder, 0.3, {
            Size = Library.Maximized
                and UDim2.fromOffset(math.min(Width + 160, Viewport.X - 20), math.min(Height + 140, Viewport.Y - 20))
                or UDim2.fromOffset(Width, Height),
        })
    end)
    CloseLight.MouseButton1Click:Connect(function()
        Window:PromptDialog({
            Name = "Close",
            Content = "Unload the interface? Anything it is running stops.",
            Actions = {
                Primary = { Name = "Unload", Callback = function() Library:Destroy() end },
                { Name = "Cancel" },
            },
        })
    end)

    Track(UserInputService.InputBegan:Connect(function(Input)
        if Library.Picking or UserInputService:GetFocusedTextBox() or Input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if Library.WindowKeybind and Input.KeyCode.Name == Library.WindowKeybind then
            Window:Minimize()
        end
    end))

    --------------------------- [[ Search ]] ---------------------------

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local Query = SearchBox.Text:lower()
        local function Hit(Text)
            return Query == "" or (Text ~= nil and tostring(Text):lower():find(Query, 1, true) ~= nil)
        end
        for _, Tab in ipairs(Window.Tabs) do
            local TabHit, AnyHit = Hit(Tab.Values.Name), false
            for _, Groupbox in pairs(Tab.Groupboxes) do
                local BoxHit = TabHit or Hit(Groupbox.Values.Name)
                local BoxAny = false
                for _, Element in pairs(Groupbox.Elements) do
                    local Show = BoxHit or Hit(Element.Values.Name) or Hit(Element.Values.Content)
                    Element.Instance.Visible = Show
                    BoxAny = BoxAny or Show
                end
                Groupbox.Instance.Visible = BoxAny or BoxHit
                AnyHit = AnyHit or BoxAny
            end
            Tab.Button.Visible = TabHit or AnyHit
        end
    end)

    --------------------------- [[ Tabs ]] ---------------------------

    local function PaintTabs()
        for _, Tab in ipairs(Window.Tabs) do
            local Selected = Tab == Window.CurrentTab
            Tab.Button.BackgroundTransparency = Selected and 0 or 1
            Tab.Button.BackgroundColor3 = Theme.Accent
            Tab.Button.TextColor3 = Selected and Theme.AccentText or Theme.Text
            Tab.Icon.ImageColor3 = Tab.Button.TextColor3
            Tab.Page.Visible = Selected
        end
        Header.Text = Window.CurrentTab and tostring(Window.CurrentTab.Values.Name or "") or ""
    end
    table.insert(Refreshers, PaintTabs)

    function Window:SelectTab(Tab)
        if type(Tab) == "number" then
            Tab = self.Tabs[Tab]
        end
        Popups.Close()
        self.CurrentTab = Tab
        PaintTabs()
    end

    local function NewTab(Section, Settings, Index, Custom)
        Settings = Settings or {}
        Section.Count = Section.Count + 1
        local Tab = {
            Values = Settings,
            Index = Index ~= nil and Index or ("Tab" .. Section.Count),
            Section = Section,
            Groupboxes = {},
            Columns = {},
            Order = 0,
        }

        local Padding = Pad(0, 0, 10, 8)
        Tab.Button = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = Section.Count,
            Parent = Section.Instance,
        }, { Corner(8), Padding })
        Tab.Icon = New("ImageLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -24, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            Parent = Tab.Button,
        })

        if Custom then
            Tab.Page = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 2, Parent = Pages })
            if typeof(Settings.Page) == "Instance" then
                Settings.Page.Parent = Tab.Page
            end
        else
            Tab.Page = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Visible = false,
                ZIndex = 2,
                Theme = { ScrollBarImageColor3 = "Stroke" },
                Parent = Pages,
            }, { List(8, true), Pad(0, 8, 0, 8) })
            local Count = math.clamp(math.floor(tonumber(Settings.Columns) or 2), 1, 4)
            for Column = 1, Count do
                Tab.Columns[Column] = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1 / Count, -math.ceil(8 * (Count - 1) / Count), 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = Column,
                    Parent = Tab.Page,
                }, { List(8) })
            end

            function Tab:CreateGroupbox(GroupboxSettings, GroupIndex)
                return NewGroupbox(self, GroupboxSettings, GroupIndex)
            end
            function Tab:BuildConfigGroupbox(Column, Style, Centered)
                return BuildConfigGroupbox(self, Column, Style, Centered)
            end
            function Tab:BuildThemeGroupbox(Column, Style, Centered)
                return BuildThemeGroupbox(self, Column, Style, Centered)
            end
        end
        Tab.Instance = Tab.Page

        function Tab:Render()
            local Image = IconId(self.Values.Icon)
            self.Button.Text = tostring(self.Values.Name or "")
            self.Icon.Image = Image or ""
            self.Icon.Visible = Image ~= nil
            Padding.PaddingLeft = UDim.new(0, Image and 32 or 10)
            PaintTabs()
        end
        function Tab:Set(NewValues, NewIndex)
            ApplySet(self, Section.Tabs, NewValues, NewIndex)
        end
        function Tab:Destroy()
            self.Button:Destroy()
            self.Page:Destroy()
            Section.Tabs[self.Index] = nil
            local At = table.find(Window.Tabs, self)
            if At then
                table.remove(Window.Tabs, At)
            end
            if Window.CurrentTab == self then
                Window:SelectTab(Window.Tabs[1])
            end
        end

        Tab.Button.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)

        Section.Tabs[Tab.Index] = Tab
        table.insert(Window.Tabs, Tab)
        Window.CurrentTab = Window.CurrentTab or Tab
        Tab:Render()
        return Tab
    end

    -- Visible = false hides the heading: for a dashboard above the other sections
    function Window:CreateTabSection(Name, Visible)
        local Section = { Name = Name, Tabs = {}, Count = 0 }
        Section.Key = Name ~= nil and Name or ("Section" .. #TabList:GetChildren())
        Section.Instance = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = #TabList:GetChildren(),
            Parent = TabList,
        }, { List(3) })
        local Heading = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = tostring(Name or ""):upper(),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            LayoutOrder = 0,
            Visible = Visible ~= false and Name ~= nil,
            Theme = { TextColor3 = "SubText" },
            Parent = Section.Instance,
        }, { Pad(0, 3, 6, 0) })

        function Section:CreateTab(TabSettings, TabIndex)
            return NewTab(self, TabSettings, TabIndex)
        end
        function Section:CreateCustomTab(TabSettings, TabIndex)
            return NewTab(self, TabSettings, TabIndex, true)
        end
        function Section:Set(NewName)
            Window.TabSections[self.Key] = nil
            self.Name, self.Key = NewName, NewName
            Window.TabSections[NewName] = self
            Heading.Text = tostring(NewName):upper()
        end
        function Section:Destroy()
            for _, Tab in pairs(self.Tabs) do
                Tab:Destroy()
            end
            self.Instance:Destroy()
            Window.TabSections[self.Key] = nil
        end

        Window.TabSections[Section.Key] = Section
        return Section
    end

    -- Starlight's preset dashboard, in VaderHug's own elements
    function Window:CreateHomeTab(Settings)
        Settings = Settings or {}
        local Section = self:CreateTabSection("__Home", false)
        Section.Instance.LayoutOrder = -1
        local Tab = Section:CreateTab({ Name = "Home", Icon = Settings.Icon, Columns = 2 }, "Home")
        local LocalPlayer = Players.LocalPlayer

        local Welcome = Tab:CreateGroupbox({ Name = "Welcome", Column = 1 }, "Welcome")
        Welcome:CreateParagraph({ Name = LocalPlayer.DisplayName, Content = "@" .. LocalPlayer.Name }, "Player")

        local ok, Executor = pcall(function()
            return identifyexecutor()
        end)
        Executor = ok and tostring(Executor) or "Unknown"
        local Verdict = "Untested here; it may work."
        if table.find(Settings.SupportedExecutors or {}, Executor) then
            Verdict = "Supported."
        elseif table.find(Settings.UnsupportedExecutors or {}, Executor) then
            Verdict = "Not supported; expect problems."
        end
        Welcome:CreateParagraph({ Name = "Executor: " .. Executor, Content = Verdict }, "Executor")

        if Settings.DiscordInvite then
            Welcome:CreateButton({
                Name = "Copy Discord Invite",
                IndicatorStyle = 1,
                Callback = function()
                    local Link = "https://discord.gg/" .. tostring(Settings.DiscordInvite)
                    if setclipboard then
                        setclipboard(Link)
                    end
                    Library:Notification({ Title = "Discord", Content = setclipboard and "Invite copied." or Link })
                end,
            }, "Discord")
        end

        if Settings.Changelog and #Settings.Changelog > 0 then
            local Changes = Tab:CreateGroupbox({ Name = "Changelog", Column = 2 }, "Changelog")
            for Order, Entry in ipairs(Settings.Changelog) do
                Changes:CreateParagraph({
                    Name = Entry.Title,
                    Content = tostring(Entry.Date or "") .. "\n" .. tostring(Entry.Description or ""),
                }, "Update" .. Order)
            end
        end

        self:SelectTab(Tab)
        return Tab
    end

    --------------------------- [[ Loading ]] ---------------------------

    local Loading = Config.LoadingSettings
    if Loading and Config.LoadingEnabled ~= false then
        local Cover = New("CanvasGroup", {
            Active = true,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 40,
            Theme = { BackgroundColor3 = "Window" },
            Parent = Main,
        }, { Corner(14) })
        local LogoImage = IconId(Loading.Logo)
        if LogoImage then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 0.5, -10),
                Size = UDim2.fromOffset(64, 64),
                Image = LogoImage,
                Parent = Cover,
            })
        else
            MakeLogo(Cover, 64, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.5, -10) })
        end
        local Big = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 26),
            Font = Enum.Font.GothamBold,
            Text = tostring(Loading.Title or Config.Name or "VaderHug"),
            TextSize = 20,
            Theme = { TextColor3 = "Text" },
            Parent = Cover,
        })
        local Small = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.5, 28),
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.Gotham,
            Text = "Loading...",
            TextSize = 13,
            Theme = { TextColor3 = "SubText" },
            Parent = Cover,
        })
        task.delay(1.2, function()
            Big.Text = "Welcome, " .. Players.LocalPlayer.DisplayName
            Small.Text = tostring(Loading.Subtitle or Loading.Title or "")
        end)
        task.delay(2.6, function()
            Tween(Cover, 0.4, { GroupTransparency = 1 })
            task.delay(0.45, function()
                Cover:Destroy()
            end)
        end)
    end

    Tween(Holder, 0.6, { Position = ShownPosition })
    return Window
end

Env.VaderHug_Instance = Library
return Library
