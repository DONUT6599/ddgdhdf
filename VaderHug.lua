--[[
    VaderHug UI
    Real Starlight (Nebula Softworks, docs.nebulasoftworks.xyz/starlight) with Vader's logo. Same API, same look.

    local VaderHug = loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/main/VaderHug.lua"))()
    local Window = VaderHug:CreateWindow({ Name = "VaderHug", Subtitle = "v1.0", FileSettings = { ConfigFolder = "AOTR" } })

    Optional extras:
      CreateWindow({ Icon = <asset id | image url> })   -- a different logo
      CreateWindow({ Mascot = true | <asset id | image url>, MascotTransparency = 0.5 }), VaderHug:SetMascotTransparency(0..1)
      Themes "Vader", "Vader Amethyst", "Vader Light" sit in BuildThemeGroupbox's list next to Starlight's
]]

local Env = (getgenv and getgenv()) or _G

if type(Env.VaderHug_Instance) == "table" and Env.VaderHug_Instance.Destroy then
    pcall(Env.VaderHug_Instance.Destroy, Env.VaderHug_Instance)
end

Env.InterfaceName = Env.InterfaceName or "VaderHug" -- Starlight names its ScreenGui from this when it loads
local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
Starlight.FileSystem.Folder = "VaderHug" -- configs and themes go in VaderHug/ instead of Starlight's folder

local DefaultLogo = "https://github.com/DONUT6599/ddgdhdf/blob/main/Asset_1.png?raw=true"
local DefaultMascot = "https://github.com/DONUT6599/ddgdhdf/blob/main/%E0%B9%84%E0%B8%A1%E0%B9%88%E0%B8%A1%E0%B8%B5%E0%B8%8A%E0%B8%B7%E0%B9%88%E0%B8%AD%20114_20260915013214.png?raw=true"

--------------------------- [[ Themes ]] ---------------------------

local RGB = Color3.fromRGB

local function Gradient(A, B, C)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, A),
        ColorSequenceKeypoint.new(0.5, B),
        ColorSequenceKeypoint.new(1, C),
    })
end

-- VaderUI's palettes as extra Starlight themes; Starlight's own stays the default
Starlight.Themes.Vader = {
    Backgrounds = {
        Dark = RGB(14, 12, 20),
        Medium = RGB(22, 19, 31),
        Light = RGB(26, 22, 37),
        Groupbox = RGB(31, 27, 44),
        Highlight = RGB(17, 14, 25),
    },
    Foregrounds = {
        Active = RGB(255, 255, 255),
        Light = RGB(240, 236, 250),
        Medium = RGB(160, 152, 184),
        Dark = RGB(62, 55, 84),
        MediumHover = RGB(185, 178, 208),
        DarkHover = RGB(82, 74, 108),
    },
    Miscellaneous = {
        Divider = RGB(120, 104, 168),
        Shadow = RGB(10, 8, 15),
        LighterShadow = RGB(18, 15, 26),
    },
    Accents = {
        Main = Gradient(RGB(168, 128, 255), RGB(132, 88, 240), RGB(104, 64, 214)),
        Brighter = Gradient(RGB(196, 166, 255), RGB(164, 128, 248), RGB(138, 102, 232)),
    },
}

Starlight.Themes["Vader Amethyst"] = {
    Backgrounds = {
        Dark = RGB(30, 18, 56),
        Medium = RGB(40, 25, 72),
        Light = RGB(46, 30, 82),
        Groupbox = RGB(54, 36, 94),
        Highlight = RGB(28, 17, 52),
    },
    Foregrounds = {
        Active = RGB(255, 255, 255),
        Light = RGB(244, 240, 255),
        Medium = RGB(190, 176, 224),
        Dark = RGB(82, 62, 128),
        MediumHover = RGB(210, 198, 240),
        DarkHover = RGB(102, 80, 150),
    },
    Miscellaneous = {
        Divider = RGB(150, 120, 210),
        Shadow = RGB(20, 12, 38),
        LighterShadow = RGB(26, 16, 48),
    },
    Accents = {
        Main = Gradient(RGB(200, 166, 255), RGB(168, 128, 255), RGB(136, 96, 236)),
        Brighter = Gradient(RGB(222, 200, 255), RGB(196, 166, 255), RGB(168, 134, 248)),
    },
}

Starlight.Themes["Vader Light"] = {
    Backgrounds = {
        Dark = RGB(236, 232, 245),
        Medium = RGB(250, 248, 254),
        Light = RGB(255, 255, 255),
        Groupbox = RGB(245, 242, 251),
        Highlight = RGB(220, 213, 238),
    },
    Foregrounds = {
        Active = RGB(255, 255, 255),
        Light = RGB(24, 18, 38),
        Medium = RGB(105, 96, 128),
        Dark = RGB(205, 198, 222),
        MediumHover = RGB(85, 76, 108),
        DarkHover = RGB(185, 178, 205),
    },
    Miscellaneous = {
        Divider = RGB(60, 50, 90),
        Shadow = RGB(190, 182, 210),
        LighterShadow = RGB(30, 30, 30),
    },
    Accents = {
        Main = Gradient(RGB(150, 104, 240), RGB(112, 68, 224), RGB(88, 52, 190)),
        Brighter = Gradient(RGB(190, 160, 250), RGB(150, 116, 236), RGB(124, 92, 214)),
    },
}

--------------------------- [[ Images ]] ---------------------------

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
        return false
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
    if not (Get and isfile and readfile and writefile) or ReadFile("VaderHug_asset_check.txt") == "running" then
        return nil
    end
    WriteFile("VaderHug_asset_check.txt", "running")
    local ok, Id = pcall(Get, Path)
    WriteFile("VaderHug_asset_check.txt", "done")
    return ok and Id or nil
end

-- an asset id, an rbx... string, or an image url (downloaded once, cached in CacheName)
local function ResolveImage(Source, CacheName)
    if type(Source) == "number" or (type(Source) == "string" and tonumber(Source)) then
        return "rbxassetid://" .. Source
    end
    if type(Source) ~= "string" or Source == "" then
        return nil
    end
    if Source:match("^rbx") then
        return Source
    end
    if not (getcustomasset or getsynasset) or not isfile then
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

--------------------------- [[ Window ]] ---------------------------

Starlight.MascotTransparency = 0.5

-- 0 is solid, 1 hides her; remembered in VaderHug_mascot_alpha.txt
function Starlight:SetMascotTransparency(Value)
    Value = math.clamp(tonumber(Value) or 0.5, 0, 1)
    self.MascotTransparency = Value
    if self.Mascot then
        self.Mascot.ImageTransparency = Value
    end
    WriteFile("VaderHug_mascot_alpha.txt", tostring(Value))
end

local CreateWindow = Starlight.CreateWindow

function Starlight:CreateWindow(Settings)
    Settings = Settings or {}

    -- Starlight only takes asset ids ("rbxassetid://" .. Icon); a downloaded logo is put in by hand after
    local Logo
    if type(Settings.Icon) == "number" then
        Logo = "rbxassetid://" .. Settings.Icon
    else
        Logo = ResolveImage(Settings.Icon or Env.VaderHug_Logo or DefaultLogo, "VaderHug_logo.png")
        Settings.Icon = nil
    end
    local Loading = Settings.LoadingSettings
    local CustomLoadingLogo = Logo and Loading and Loading.Logo == nil
    if CustomLoadingLogo then
        Loading.Logo = 0 -- tells Starlight a logo replaces its spinner; the real image goes in below
    end

    local Window = CreateWindow(self, Settings)
    local Main = Window.Instance

    if Logo then
        -- white = the logo's own colours (Starlight tints its icons to the theme)
        local function Put(Image)
            Image.Image = Logo
            Image.ImageColor3 = Color3.new(1, 1, 1)
        end
        Put(Main.Sidebar.Icon)
        Put(self.Instance.MobileToggle)
        local Screen = Main:FindFirstChild("New Loading Screen")
        if CustomLoadingLogo and Screen then
            Put(Screen.Frame.ImageLabel.Image)
        end

        -- notifications without an icon get the logo; Starlight fills the card in, then yields
        local Holder = self.Instance:FindFirstChild("Notifications")
        if Holder then
            Holder.ChildAdded:Connect(function(Card)
                task.defer(function()
                    local Icon = Card:FindFirstChild("Icon")
                    if Icon and Icon:IsA("ImageLabel") and (Icon.Image == "" or Icon.Image == "rbxassetid://") then
                        Put(Icon)
                    end
                end)
            end)
        end
    end

    -- opt-in: the mascot sits in the content area, under the tabs, showing wherever there's no groupbox
    local Mascot = Settings.Mascot and ResolveImage(Settings.Mascot == true and DefaultMascot or Settings.Mascot, "VaderHug_mascot.png")
    local Content = Main:FindFirstChild("Content")
    local ContentMain = Content and Content:FindFirstChild("ContentMain")
    if Mascot and ContentMain then
        local Saved = tonumber(ReadFile("VaderHug_mascot_alpha.txt") or "")
        self.MascotTransparency = math.clamp(Settings.MascotTransparency or Saved or self.MascotTransparency, 0, 1)

        local Image = Instance.new("ImageLabel")
        Image.Name = "VaderMascot"
        Image.BackgroundTransparency = 1
        Image.AnchorPoint = Vector2.new(1, 1)
        Image.Position = UDim2.new(1, -4, 1, 0)
        Image.Size = UDim2.new(1, -8, 1, -8)
        Image.Image = Mascot
        Image.ImageTransparency = self.MascotTransparency
        Image.ScaleType = Enum.ScaleType.Fit
        -- under its siblings with Sibling z-ordering; with Global, level with the content's own background
        Image.ZIndex = self.Instance.ZIndexBehavior == Enum.ZIndexBehavior.Sibling and 0 or ContentMain.ZIndex

        local Ratio = Instance.new("UIAspectRatioConstraint")
        Ratio.AspectRatio = 1462 / 2000
        Ratio.DominantAxis = Enum.DominantAxis.Height
        Ratio.Parent = Image

        Image.Parent = ContentMain
        self.Mascot = Image
    end

    return Window
end

Env.VaderHug_Instance = Starlight
return Starlight
