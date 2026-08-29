--[[
=====================================================================
               WOLF CONTROL V39 - SANITY 120 HARD LOCK + MANUAL SAFE STAMP + FULL AUTO STAMP + FAST SAFE AUTO SURGERY + AUTO COLOR MEMORY / REGISTER-SAFE / COMPACT MOBILE UI / SMALL ALERTS / RELIABLE KEY CHARACTER ALERTS / SINGLE INSTANCE
                    English / Русский
=====================================================================

ESP
     ├─ PATIENT
     ├─ MASS OF EYES
     ├─ GHOST
     ├─ STALKER
     ├─ MIMIC
     ├─ HIDERS
     ├─ RITUAL
     ├─ HEAD BANGER
     ├─ CAMERA MONSTER
     ├─ BED MONSTER
     ├─ TENTACLES
     └─ SLIMEBERT

PLAYER
 ├─ NOCLIP
 ├─ FLY
 ├─ SANITY GOD
 ├─ RUN
 ├─ WALK SPEED
 └─ RUN SPEED

MISC
 ├─ KEY CHARACTER NOTIFICATIONS
 ├─ 100% SAFE ASSIST
 └─ INSTANT INTERACT

SETTINGS
 ├─ LANGUAGE: ENGLISH / РУССКИЙ
 ├─ SAVE SETTINGS
 ├─ LOAD SETTINGS
 └─ RESET DEFAULTS

Mobile optimization:
- responsive touch layout
- bottom navigation
- large touch targets
- mobile fly UP/DOWN controls
- reduced background polling/effects
- leak-safe page input handlers

The configuration is stored as:
WOLF_CONTROL_SETTINGS.json
=====================================================================
]]

--==============================================================
-- HARD SINGLE-INSTANCE BOOTSTRAP
-- Immediately shuts down any older WOLF CONTROL before this
-- version waits for game objects or creates a new GUI.
--==============================================================

local ENV = _G
pcall(function()
    if type(getgenv) == "function" then
        ENV = getgenv()
    end
end)

local seenOld = {}
local function hardStopOld(old)
    if type(old) ~= "table" or seenOld[old] then
        return
    end
    seenOld[old] = true

    -- Kill background loops first, even if the old Stop() errors.
    pcall(function() old.Active = false end)
    pcall(function() old.SafeStampManual = false end)
    pcall(function() old.AutoStamp = false end)
    pcall(function() old.AutoColorMemory = false end)
    pcall(function() old.Fly = false end)
    pcall(function() old.Noclip = false end)
    pcall(function() old.SanityGod = false end)

    if type(old.Stop) == "function" then
        pcall(function()
            old:Stop()
        end)
    end
end

hardStopOld(ENV.WOLF_CONTROL)
hardStopOld(_G.WOLF_CONTROL)

ENV.WOLF_CONTROL = nil
_G.WOLF_CONTROL = nil

ENV.WOLF_CONTROL_BOOT_ID = (tonumber(ENV.WOLF_CONTROL_BOOT_ID) or 0) + 1
local WOLF_BOOT_ID = ENV.WOLF_CONTROL_BOOT_ID

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PPS = game:GetService("ProximityPromptService")
local CS = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local NPCFolder = workspace:WaitForChild("NPCs")

--==============================================================
-- MOBILE / TOUCH PROFILE
--==============================================================

local IS_TOUCH = UIS.TouchEnabled
local BASE_DESKTOP = Vector2.new(840, 540)
local BASE_MOBILE = Vector2.new(760, 550)

-- V38 mobile performance profile.
-- Keep automation accurate while reducing unnecessary frame/poll work.
local PERF = {
    ESP_REFRESH = IS_TOUCH and 3.0 or 1.25,
    SAFE_AUTO_TICK = IS_TOUCH and 0.040 or 0.025,
    COLOR_MEMORY_TICK = IS_TOUCH and 0.040 or 0.025,
    NOCLIP_TICK = IS_TOUCH and 0.030 or 0,
    SANITY_UI_TICK = IS_TOUCH and 0.050 or 0,
    KEY_SCAN_TICK = IS_TOUCH and 1.00 or 0.65,
}

local function getViewport()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function isPortraitViewport()
    local viewport = getViewport()
    return viewport.Y > viewport.X
end

--==============================================================
-- CLEAN OLD
--==============================================================

-- Fallback cleanup for a legacy instance that appeared during bootstrap.
hardStopOld(ENV.WOLF_CONTROL)
hardStopOld(_G.WOLF_CONTROL)
ENV.WOLF_CONTROL = nil
_G.WOLF_CONTROL = nil

for _, name in ipairs({
    "WolfControlGUI",
    "WolfGraphicPanel",
    "WolfUtilityPanel",
    "WolfWowMenu",
}) do
    local old = PlayerGui:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

--==============================================================
-- TRANSLATIONS
--==============================================================

local L = {
    EN = {
        SUBTITLE = "ANOMALY INTELLIGENCE SYSTEM",
        NAVIGATION = "NAVIGATION",
        ONLINE = "ONLINE",
        ACTIVE = "ACTIVE",
        OFF = "OFF",

        NAV_ESP = "ESP",
        NAV_PLAYER = "PLAYER",
        NAV_MISC = "MISC",
        NAV_SETTINGS = "SETTINGS",

        PAGE_ESP = "ESP",
        PAGE_ESP_INFO = "Anomaly detection and visual intelligence",
        PAGE_PLAYER = "PLAYER",
        PAGE_PLAYER_INFO = "Movement and character controls",
        PAGE_MISC = "MISC",
        PAGE_MISC_INFO = "Notifications, interaction and utilities",
        PAGE_SETTINGS = "SETTINGS",
        PAGE_SETTINGS_INFO = "Language and saved configuration",

        SEC_TYPES = "ANOMALY TYPES",
        SEC_MOVEMENT = "MOVEMENT",
        SEC_PLAYER = "PLAYER",
        SEC_SPEED = "SPEED",
        SEC_NOTIFICATIONS = "NOTIFICATIONS",
        SEC_INTERACTION = "INTERACTION",
        SEC_LANGUAGE = "LANGUAGE",
        SEC_STORAGE = "SAVED CONFIGURATION",

        ANOMALY_TYPE_DESC = "Detect and highlight: {name}",

        NOCLIP = "NOCLIP",
        NOCLIP_DESC = "Move through physical obstacles",
        FLY = "FLY",
        FLY_DESC = "Free aerial movement",
        SANITY_GOD = "SANITY GOD",
        SANITY_GOD_DESC = "Hard-lock local sanity at 120% and prevent visible drops",
        RUN = "RUN",
        RUN_DESC = "PC: hold Shift • Mobile: always run",
        WALK_SPEED = "WALK SPEED",
        WALK_SPEED_DESC = "Normal movement speed",
        RUN_SPEED = "RUN SPEED",
        RUN_SPEED_DESC = "Running movement speed",

        KEY_NOTIFICATIONS = "KEY CHARACTER NOTIFICATIONS",
        KEY_NOTIFICATIONS_DESC = "Alert when Barney, Ratthew, Ron, Liz or Sam arrives",
        SAFE_STAMP_MANUAL = "100% SUCCESS STAMP MANUAL",
        SAFE_STAMP_MANUAL_DESC = "Press Begin manually; skull targets are removed and safe targets are stacked for manual clicking",
        AUTO_STAMP = "AUTO STAMP",
        AUTO_STAMP_DESC = "Fully automatic: activates Begin when available and clicks only verified safe targets; skull targets are never clicked",
        AUTO_SURGERY = "AUTO SURGERY",
        AUTO_SURGERY_DESC = "Reads the real operating-room surgery board, takes each exact required item and applies it to the patient",
        AUTO_COLOR_MEMORY = "AUTO COLOR MEMORY",
        AUTO_COLOR_MEMORY_DESC = "Automatically records each live Room 6 color sequence and repeats it in the exact same order",
        INSTANT_INTERACT = "INSTANT INTERACT",
        INSTANT_INTERACT_DESC = "Remove visible ProximityPrompt hold time",

        ENGLISH = "ENGLISH",
        ENGLISH_DESC = "Use the complete English interface",
        RUSSIAN = "РУССКИЙ",
        RUSSIAN_DESC = "Use the complete Russian interface",
        SELECTED = "SELECTED",
        SELECT = "SELECT",

        SAVE = "SAVE SETTINGS",
        SAVE_DESC = "Save toggles, speeds, language and UI positions",
        LOAD = "LOAD SETTINGS",
        LOAD_DESC = "Load the last saved WOLF CONTROL configuration",
        RESET = "RESET DEFAULTS",
        RESET_DESC = "Restore the default configuration",
        SAVE_BUTTON = "SAVE",
        LOAD_BUTTON = "LOAD",
        RESET_BUTTON = "RESET",

        CONFIG_AVAILABLE = "FILE STORAGE: AVAILABLE",
        CONFIG_UNAVAILABLE = "FILE STORAGE: NOT SUPPORTED",

        N_ENABLED = "{name} enabled",
        N_DISABLED = "{name} disabled",
        N_CONFIG_SAVED = "Settings saved",
        N_CONFIG_LOADED = "Settings loaded",
        N_CONFIG_RESET = "Defaults restored",
        N_CONFIG_SAVE_FAIL = "Could not save settings",
        N_CONFIG_LOAD_FAIL = "No saved settings found",
        N_LANGUAGE_EN = "Language changed to English",
        N_LANGUAGE_RU = "Language changed to Russian",
        N_KEY_ARRIVED = "KEY CHARACTER ARRIVED • {name} is now at the hospital",
        READY = "WOLF CONTROL READY",

        ESP_ANOMALY = "ANOMALY",
        FILE_STATUS = "Storage",
    },

    RU = {
        SUBTITLE = "СИСТЕМА ОБНАРУЖЕНИЯ АНОМАЛИЙ",
        NAVIGATION = "НАВИГАЦИЯ",
        ONLINE = "В СЕТИ",
        ACTIVE = "АКТИВНО",
        OFF = "ВЫКЛ",

        NAV_ESP = "ВИЗУАЛ",
        NAV_PLAYER = "ИГРОК",
        NAV_MISC = "РАЗНОЕ",
        NAV_SETTINGS = "НАСТРОЙКИ",

        PAGE_ESP = "ВИЗУАЛ",
        PAGE_ESP_INFO = "Обнаружение и визуальная подсветка аномалий",
        PAGE_PLAYER = "ИГРОК",
        PAGE_PLAYER_INFO = "Передвижение и управление персонажем",
        PAGE_MISC = "РАЗНОЕ",
        PAGE_MISC_INFO = "Уведомления, взаимодействие и утилиты",
        PAGE_SETTINGS = "НАСТРОЙКИ",
        PAGE_SETTINGS_INFO = "Язык и сохранённая конфигурация",

        SEC_TYPES = "ТИПЫ АНОМАЛИЙ",
        SEC_MOVEMENT = "ПЕРЕДВИЖЕНИЕ",
        SEC_PLAYER = "ИГРОК",
        SEC_SPEED = "СКОРОСТЬ",
        SEC_NOTIFICATIONS = "УВЕДОМЛЕНИЯ",
        SEC_INTERACTION = "ВЗАИМОДЕЙСТВИЕ",
        SEC_LANGUAGE = "ЯЗЫК",
        SEC_STORAGE = "СОХРАНЁННАЯ КОНФИГУРАЦИЯ",

        ANOMALY_TYPE_DESC = "Обнаружение и подсветка: {name}",

        NOCLIP = "ПРОХОД СКВОЗЬ СТЕНЫ",
        NOCLIP_DESC = "Позволяет проходить сквозь физические препятствия",
        FLY = "ПОЛЁТ",
        FLY_DESC = "Свободное перемещение по воздуху",
        SANITY_GOD = "БЕСКОНЕЧНЫЙ РАССУДОК",
        SANITY_GOD_DESC = "Жёстко удерживает рассудок на 120% без видимого падения",
        RUN = "БЕГ",
        RUN_DESC = "ПК: удерживайте Shift • Телефон: постоянный бег",
        WALK_SPEED = "СКОРОСТЬ ХОДЬБЫ",
        WALK_SPEED_DESC = "Обычная скорость передвижения",
        RUN_SPEED = "СКОРОСТЬ БЕГА",
        RUN_SPEED_DESC = "Скорость во время бега",

        KEY_NOTIFICATIONS = "УВЕДОМЛЕНИЯ О КЛЮЧЕВЫХ ПЕРСОНАЖАХ",
        KEY_NOTIFICATIONS_DESC = "Сообщает о прибытии Barney, Ratthew, Ron, Liz или Sam",
        SAFE_STAMP_MANUAL = "100% БЕЗОПАСНЫЙ ШТАМП — ВРУЧНУЮ",
        SAFE_STAMP_MANUAL_DESC = "Нажмите Begin вручную; цели с черепом блокируются, безопасные цели собираются в одной точке для ручного нажатия",
        AUTO_STAMP = "АВТО ШТАМП",
        AUTO_STAMP_DESC = "Полный автомат: запускает Begin, когда он доступен, и нажимает только проверенные безопасные цели; череп не нажимается",
        AUTO_SURGERY = "АВТО ОПЕРАЦИОННАЯ",
        AUTO_SURGERY_DESC = "Читает реальный экран операции, берёт каждый точно указанный предмет и применяет его к пациенту",
        AUTO_COLOR_MEMORY = "АВТО ПАМЯТЬ ЦВЕТОВ",
        AUTO_COLOR_MEMORY_DESC = "Для каждого нового пациента заново записывает живую последовательность цветов и автоматически повторяет её",
        INSTANT_INTERACT = "МГНОВЕННОЕ ВЗАИМОДЕЙСТВИЕ",
        INSTANT_INTERACT_DESC = "Убирает время удержания видимых ProximityPrompt",

        ENGLISH = "ENGLISH",
        ENGLISH_DESC = "Полностью переключить интерфейс на английский язык",
        RUSSIAN = "РУССКИЙ",
        RUSSIAN_DESC = "Полностью переключить интерфейс на русский язык",
        SELECTED = "ВЫБРАНО",
        SELECT = "ВЫБРАТЬ",

        SAVE = "СОХРАНИТЬ НАСТРОЙКИ",
        SAVE_DESC = "Сохраняет переключатели, скорости, язык и позиции интерфейса",
        LOAD = "ЗАГРУЗИТЬ НАСТРОЙКИ",
        LOAD_DESC = "Загружает последнюю сохранённую конфигурацию WOLF CONTROL",
        RESET = "СБРОСИТЬ НАСТРОЙКИ",
        RESET_DESC = "Восстанавливает настройки по умолчанию",
        SAVE_BUTTON = "СОХРАНИТЬ",
        LOAD_BUTTON = "ЗАГРУЗИТЬ",
        RESET_BUTTON = "СБРОСИТЬ",

        CONFIG_AVAILABLE = "ХРАНЕНИЕ ФАЙЛОВ: ДОСТУПНО",
        CONFIG_UNAVAILABLE = "ХРАНЕНИЕ ФАЙЛОВ: НЕ ПОДДЕРЖИВАЕТСЯ",

        N_ENABLED = "{name}: включено",
        N_DISABLED = "{name}: выключено",
        N_CONFIG_SAVED = "Настройки сохранены",
        N_CONFIG_LOADED = "Настройки загружены",
        N_CONFIG_RESET = "Настройки по умолчанию восстановлены",
        N_CONFIG_SAVE_FAIL = "Не удалось сохранить настройки",
        N_CONFIG_LOAD_FAIL = "Сохранённые настройки не найдены",
        N_LANGUAGE_EN = "Язык переключён на английский",
        N_LANGUAGE_RU = "Язык переключён на русский",
        N_KEY_ARRIVED = "КЛЮЧЕВОЙ ПЕРСОНАЖ ПРИБЫЛ • {name} уже в больнице",
        READY = "WOLF CONTROL ГОТОВ",

        ESP_ANOMALY = "АНОМАЛИЯ",
        FILE_STATUS = "Хранилище",
    },
}

local ANOMALY_NAMES = {
    PATIENT = {EN = "PATIENT", RU = "ПАЦИЕНТ"},
    MASS_OF_EYES = {EN = "MASS OF EYES", RU = "ГЛАЗАСТИК"},
    GHOST = {EN = "GHOST", RU = "ПРИЗРАК"},
    STALKER = {EN = "STALKER", RU = "СТАЛКЕР"},
    MIMIC = {EN = "MIMIC", RU = "МИМИК"},
    HIDERS = {EN = "HIDERS", RU = "ТИХОНЯ"},
    RITUAL = {EN = "RITUAL", RU = "РИТУАЛЬЩИК"},
    HEAD_BANGER = {EN = "HEAD BANGER", RU = "ЛОБОТРЯС"},
    CAMERA_MONSTER = {EN = "CAMERA MONSTER", RU = "НАБЛЮДАТЕЛЬ"},
    BED_MONSTER = {EN = "BED MONSTER", RU = "МОНСТР ПОД КРОВАТЬЮ"},
    TENTACLES = {EN = "TENTACLES", RU = "ОСЬМИНОИД"},
    SLIMEBERT = {EN = "SLIMEBERT", RU = "СЛАЙМБЕРТ"},
}

--==============================================================
-- DEFAULTS / STATE
--==============================================================

local DEFAULTS = {
    Language = "EN",
    CurrentPage = "ESP",
    AnomalyEnabled = {
        PATIENT = false,
        MASS_OF_EYES = false,
        GHOST = false,
        STALKER = false,
        MIMIC = false,
        HIDERS = false,
        RITUAL = false,
        HEAD_BANGER = false,
        CAMERA_MONSTER = false,
        BED_MONSTER = false,
        TENTACLES = false,
        SLIMEBERT = false,
    },
    Noclip = false,
    Fly = false,
    SanityGod = false,
    RunMode = false,
    WalkSpeed = 16,
    RunSpeed = 32,
    InstantInteract = false,
    SafeStampManual = false,
    AutoStamp = false,
    AutoSurgery = false,
    AutoColorMemory = false,
    KeyCharacterNotifications = false,
}

local function copyTable(t)
    local out = {}
    for k, v in pairs(t) do
        out[k] = type(v) == "table" and copyTable(v) or v
    end
    return out
end

local App = copyTable(DEFAULTS)
App.Active = true
App.MenuOpen = false
App.ShiftHeld = false
App.Connections = {}
App.CollisionCache = {}
App.FlyVelocity = nil
App.FlyGyro = nil
App.VisiblePrompts = {}
App.PromptOriginals = setmetatable({}, {__mode = "k"})
App.AnomalyMarked = {}
App.KeyCharacterLastAlert = {}
App.KeyCharacterWatchers = setmetatable({}, {__mode = "k"})
App.KeyCharacterStates = setmetatable({}, {__mode = "k"})
App.UIReady = false
App.PageConnections = {}
App.CharacterParts = {}
App.MobileFlyUp = false
App.MobileFlyDown = false

App.BootId = WOLF_BOOT_ID
ENV.WOLF_CONTROL = App
_G.WOLF_CONTROL = App

local function T(key)
    local lang = L[App.Language] or L.EN
    return lang[key] or L.EN[key] or key
end

local function F(key, vars)
    local text = T(key)
    if vars then
        for k, v in pairs(vars) do
            text = text:gsub("{" .. tostring(k) .. "}", function() return tostring(v) end)
        end
    end
    return text
end

local function anomalyName(key)
    local data = ANOMALY_NAMES[key]
    if not data then
        return key
    end
    return data[App.Language] or data.EN or key
end

--==============================================================
-- CONFIG IO
--==============================================================

local CONFIG_FILE = "WOLF_CONTROL_SETTINGS.json"
local CAN_WRITE = type(writefile) == "function"
local CAN_READ = type(readfile) == "function"

local function encodeUDim2(p)
    return {p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset}
end

local function decodeUDim2(v, fallback)
    if type(v) == "table" and #v >= 4 then
        return UDim2.new(
            tonumber(v[1]) or 0,
            tonumber(v[2]) or 0,
            tonumber(v[3]) or 0,
            tonumber(v[4]) or 0
        )
    end
    return fallback
end

local function readConfigRaw()
    if not CAN_READ then
        return nil
    end

    local ok, raw = pcall(readfile, CONFIG_FILE)
    if not ok or type(raw) ~= "string" or raw == "" then
        return nil
    end

    local ok2, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if ok2 and type(data) == "table" then
        return data
    end

    return nil
end

local function mergeConfig(data)
    if type(data) ~= "table" then
        return
    end

    if data.Language == "EN" or data.Language == "RU" then
        App.Language = data.Language
    end

    if data.CurrentPage == "ESP" or data.CurrentPage == "PLAYER" or data.CurrentPage == "MISC" or data.CurrentPage == "SETTINGS" then
        App.CurrentPage = data.CurrentPage
    end

    for _, key in ipairs({
        "Noclip",
        "Fly",
        "SanityGod",
        "RunMode",
        "InstantInteract",
        "SafeStampManual",
        "AutoStamp",
        "AutoSurgery",
        "AutoColorMemory",
        "KeyCharacterNotifications",
    }) do
        if type(data[key]) == "boolean" then
            App[key] = data[key]
        end
    end

    if tonumber(data.WalkSpeed) then
        App.WalkSpeed = math.clamp(math.floor(tonumber(data.WalkSpeed) + 0.5), 5, 100)
    end

    if tonumber(data.RunSpeed) then
        App.RunSpeed = math.clamp(math.floor(tonumber(data.RunSpeed) + 0.5), 10, 200)
    end

    -- V4 migration:
    -- V2 incorrectly shipped individual anomaly toggles as ON by default.
    -- V3 corrected that. Load individual anomaly choices only from V3+ configs.
    local configVersion = tonumber(data.Version) or 0

    -- V20 stamp-mode migration:
    -- V18 and older used AutoStamp for the MANUAL safe-assist mode.
    -- V19 used AutoStamp for FULL AUTO clicking after Begin.
    -- V20 stores the two modes independently.
    if configVersion < 20 then
        App.SafeStampManual = false
        App.AutoStamp = false
        if type(data.AutoStamp) == "boolean" then
            if configVersion >= 19 then
                App.AutoStamp = data.AutoStamp
            else
                App.SafeStampManual = data.AutoStamp
            end
        end
    end

    if configVersion >= 3 and type(data.AnomalyEnabled) == "table" then
        for key in pairs(App.AnomalyEnabled) do
            if type(data.AnomalyEnabled[key]) == "boolean" then
                App.AnomalyEnabled[key] = data.AnomalyEnabled[key]
            end
        end
    end

    App._SavedIconPosition = data.IconPosition
    App._SavedMainPosition = data.MainPosition
end

local initialConfig = readConfigRaw()
if initialConfig then
    mergeConfig(initialConfig)
end

--==============================================================
-- COLORS / GENERIC UI HELPERS
--==============================================================

local C = {
    BG = Color3.fromRGB(7, 9, 16),
    TOP = Color3.fromRGB(18, 23, 38),
    SIDEBAR = Color3.fromRGB(13, 18, 29),
    CARD = Color3.fromRGB(20, 27, 42),
    CARD_HOVER = Color3.fromRGB(27, 37, 56),
    TEXT = Color3.fromRGB(243, 247, 255),
    MUTED = Color3.fromRGB(135, 150, 177),
    BLUE = Color3.fromRGB(72, 116, 255),
    CYAN = Color3.fromRGB(46, 211, 255),
    PURPLE = Color3.fromRGB(164, 72, 255),
    GREEN = Color3.fromRGB(51, 207, 126),
    RED = Color3.fromRGB(224, 59, 86),
    ORANGE = Color3.fromRGB(255, 154, 61),
    OUTLINE = Color3.fromRGB(67, 87, 130),
    ANOMALY = Color3.fromRGB(245, 55, 91),
}

local function track(connection)
    App.Connections[#App.Connections + 1] = connection
    return connection
end

local function pageTrack(connection)
    App.PageConnections[#App.PageConnections + 1] = connection
    return connection
end

local function clearPageConnections()
    for _, connection in ipairs(App.PageConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(App.PageConnections)
end

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = object
    return c
end

local function stroke(object, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or C.OUTLINE
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = object
    return s
end

local function gradient(object, a, b, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, a),
        ColorSequenceKeypoint.new(1, b),
    })
    g.Rotation = rotation or 0
    g.Parent = object
    return g
end

local function tween(object, time, properties, style, direction)
    local tw = TweenService:Create(
        object,
        TweenInfo.new(
            time or 0.18,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )
    tw:Play()
    return tw
end

local function normalize(value)
    return string.lower(tostring(value or "")):gsub("[%s_%-%p]", "")
end

local function same(a, b)
    return normalize(a) == normalize(b)
end

local function activeValue(value)
    if value == true then
        return true
    end
    if type(value) == "number" then
        return value ~= 0
    end
    if type(value) == "string" then
        local v = string.lower(value)
        return v ~= "" and v ~= "false" and v ~= "none" and v ~= "normal" and v ~= "nil"
    end
    return false
end

local function hasTag(object, tag)
    local ok, result = pcall(function()
        return CS:HasTag(object, tag)
    end)
    return ok and result == true
end

local function getCharacter()
    local character = LP.Character
    if not character then
        return
    end
    return character,
        character:FindFirstChildOfClass("Humanoid"),
        character:FindFirstChild("HumanoidRootPart")
end

local function getESPPart(model)
    return model:FindFirstChild("Head")
        or model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("RootPart")
        or model.PrimaryPart
end

-- Forward declarations used by Settings / localization.
local renderPage
local updateStaticUI
local refreshAllESP
local applyLoadedState
local clampMainToScreen
local clampIconToScreen

--==============================================================
-- GUI ROOT / TOAST
--==============================================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "WolfControlGUI"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder = 80
GUI.Parent = PlayerGui

local Toast = Instance.new("Frame")
Toast.AnchorPoint = Vector2.new(0.5, 0)
Toast.Size = IS_TOUCH and UDim2.new(0.70, 0, 0, 50) or UDim2.fromOffset(410, 58)
Toast.Position = UDim2.new(0.5, 0, 0, -90)
Toast.BackgroundColor3 = C.CARD
Toast.ZIndex = 500
Toast.Visible = false
Toast.ClipsDescendants = false
Toast.Parent = GUI
corner(Toast, IS_TOUCH and 12 or 13)
local ToastStroke = stroke(Toast, C.CYAN, 1.35, 0.14)

local ToastSizeConstraint = Instance.new("UISizeConstraint")
ToastSizeConstraint.MinSize = Vector2.new(IS_TOUCH and 220 or 360, IS_TOUCH and 46 or 54)
ToastSizeConstraint.MaxSize = Vector2.new(IS_TOUCH and 430 or 460, IS_TOUCH and 58 or 68)
ToastSizeConstraint.Parent = Toast

local ToastIcon = Instance.new("TextLabel")
ToastIcon.Size = UDim2.fromOffset(IS_TOUCH and 40 or 46, IS_TOUCH and 50 or 58)
ToastIcon.BackgroundTransparency = 1
ToastIcon.Text = "🐺"
ToastIcon.TextSize = IS_TOUCH and 22 or 24
ToastIcon.ZIndex = 502
ToastIcon.Parent = Toast

local ToastText = Instance.new("TextLabel")
ToastText.Position = UDim2.fromOffset(IS_TOUCH and 39 or 45, 4)
ToastText.Size = UDim2.new(1, IS_TOUCH and -47 or -54, 1, -8)
ToastText.BackgroundTransparency = 1
ToastText.TextColor3 = C.TEXT
ToastText.TextXAlignment = Enum.TextXAlignment.Left
ToastText.TextYAlignment = Enum.TextYAlignment.Center
ToastText.Font = Enum.Font.GothamBold
ToastText.TextSize = IS_TOUCH and 12 or 13
ToastText.TextWrapped = true
ToastText.TextTruncate = Enum.TextTruncate.None
ToastText.ZIndex = 502
ToastText.Parent = Toast

local ToastToken = 0

local function toastVisibleY()
    local viewport = getViewport()

    -- V39: compact alerts are intentionally placed BELOW the game's
    -- top HUD so no part of the message is hidden.
    if IS_TOUCH then
        if viewport.Y > viewport.X then
            return math.floor(math.clamp(viewport.Y * 0.105, 96, 128))
        end
        return math.floor(math.clamp(viewport.Y * 0.125, 96, 118))
    end

    return math.floor(math.clamp(viewport.Y * 0.105, 88, 118))
end

local function notify(text, duration, important)
    ToastToken += 1
    local token = ToastToken

    ToastText.Text = tostring(text)
    ToastStroke.Color = important and C.ORANGE or C.CYAN
    Toast.BackgroundColor3 = important
        and Color3.fromRGB(39, 31, 24)
        or C.CARD

    Toast.Visible = true
    Toast.Position = UDim2.new(0.5, 0, 0, -90)

    tween(Toast, IS_TOUCH and 0.13 or 0.17, {
        Position = UDim2.new(0.5, 0, 0, toastVisibleY()),
    }, Enum.EasingStyle.Quart)

    task.delay(tonumber(duration) or 2.2, function()
        if token ~= ToastToken then
            return
        end

        tween(Toast, 0.16, {
            Position = UDim2.new(0.5, 0, 0, -90),
        })

        -- Explicitly hide it after the exit tween.
        -- This prevents the READY/loading message from remaining on-screen.
        task.delay(0.18, function()
            if token == ToastToken then
                Toast.Visible = false
            end
        end)
    end)
end

local function notifyState(name, state, silent)
    if silent then
        return
    end
    notify(F(state and "N_ENABLED" or "N_DISABLED", {name = name}), IS_TOUCH and 1.8 or 2.1, false)
end

--==============================================================
-- MOBILE FLY CONTROLS
--==============================================================

local MobileFlyControls = Instance.new("Frame")
MobileFlyControls.Name = "MobileFlyControls"
MobileFlyControls.AnchorPoint = Vector2.new(1, 0.5)
MobileFlyControls.Position = UDim2.new(1, -14, 0.54, 0)
MobileFlyControls.Size = UDim2.fromOffset(IS_TOUCH and 70 or 82, IS_TOUCH and 150 or 176)
MobileFlyControls.BackgroundTransparency = 1
MobileFlyControls.Visible = false
MobileFlyControls.Parent = GUI

local function makeFlyTouchButton(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(IS_TOUCH and 64 or 76, IS_TOUCH and 64 or 76)
    button.Position = UDim2.fromOffset(3, IS_TOUCH and math.floor(y * 0.82) or y)
    button.BackgroundColor3 = C.CARD
    button.BackgroundTransparency = 0.08
    button.Text = text
    button.TextColor3 = C.TEXT
    button.TextSize = 34
    button.Font = Enum.Font.GothamBlack
    button.AutoButtonColor = false
    button.Parent = MobileFlyControls
    corner(button, 22)
    stroke(button, C.CYAN, 1.6, 0.15)
    gradient(button, Color3.fromRGB(35, 66, 130), Color3.fromRGB(72, 35, 110), 45)
    return button
end

local FlyUpButton = makeFlyTouchButton("↑", 4)
local FlyDownButton = makeFlyTouchButton("↓", IS_TOUCH and 88 or 96)

local function bindHold(button, field)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            App[field] = true
            tween(button, 0.08, {BackgroundTransparency = 0})
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            App[field] = false
            tween(button, 0.08, {BackgroundTransparency = 0.08})
        end
    end)
end

bindHold(FlyUpButton, "MobileFlyUp")
bindHold(FlyDownButton, "MobileFlyDown")

local function updateMobileFlyControls()
    MobileFlyControls.Visible = IS_TOUCH and App.Fly and App.Active and not App.MenuOpen
    if not MobileFlyControls.Visible then
        App.MobileFlyUp = false
        App.MobileFlyDown = false
    end
end

--==============================================================
-- PLAYER FEATURES
--==============================================================

local function applySpeed()
    local _, humanoid = getCharacter()
    if not humanoid then
        return
    end

    local running = false
    if App.RunMode then
        running = UIS.TouchEnabled or App.ShiftHeld
    end

    humanoid.WalkSpeed = running and App.RunSpeed or App.WalkSpeed
end

local function cacheCharacterParts(character)
    table.clear(App.CharacterParts)
    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            App.CharacterParts[object] = true
        end
    end

    track(character.DescendantAdded:Connect(function(object)
        if object:IsA("BasePart") then
            App.CharacterParts[object] = true
        end
    end))

    track(character.DescendantRemoving:Connect(function(object)
        if object:IsA("BasePart") then
            App.CharacterParts[object] = nil
            App.CollisionCache[object] = nil
        end
    end))
end

if LP.Character then
    cacheCharacterParts(LP.Character)
end

local function setNoclip(state, silent)
    App.Noclip = state == true

    if not App.Noclip then
        for part, original in pairs(App.CollisionCache) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = original
                end)
            end
        end
        table.clear(App.CollisionCache)
    end

    notifyState(T("NOCLIP"), App.Noclip, silent)
end

local LastNoclipStep = 0
track(RunService.Stepped:Connect(function()
    if not App.Noclip then
        return
    end

    if PERF.NOCLIP_TICK > 0 then
        local now = os.clock()
        if now - LastNoclipStep < PERF.NOCLIP_TICK then
            return
        end
        LastNoclipStep = now
    end

    for object in pairs(App.CharacterParts) do
        if object and object.Parent then
            if App.CollisionCache[object] == nil then
                App.CollisionCache[object] = object.CanCollide
            end
            object.CanCollide = false
        else
            App.CharacterParts[object] = nil
            App.CollisionCache[object] = nil
        end
    end
end))

local function setRun(state, silent)
    App.RunMode = state == true
    applySpeed()
    notifyState(T("RUN"), App.RunMode, silent)
end

track(UIS.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        App.ShiftHeld = true
        applySpeed()
    end
end))

track(UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        App.ShiftHeld = false
        applySpeed()
    end
end))

--==============================================================
-- SANITY GOD V29 - 120% HARD LOCK
-- Two layers:
--   1) Attribute correction immediately on every Sanity change.
--   2) UI correction every rendered frame so the displayed value stays 120%.
--==============================================================

App.SanityTarget = 120
App.SanityWriteGuard = false

App.ForceSanity120 = function()
    if not App.Active or not App.SanityGod then
        return
    end

    -- Keep the local attribute at exactly 120. Guard prevents recursive
    -- AttributeChanged calls caused by our own correction.
    if not App.SanityWriteGuard then
        local current = nil
        pcall(function()
            current = LP:GetAttribute("Sanity")
        end)

        if current ~= App.SanityTarget then
            App.SanityWriteGuard = true
            pcall(function()
                LP:SetAttribute("Sanity", App.SanityTarget)
            end)
            App.SanityWriteGuard = false
        end
    end

    -- Lock the visible percentage independently from the game attribute.
    -- This prevents a server/client update from visibly flashing a lower value.
    pcall(function()
        local sanityGui = PlayerGui:FindFirstChild("Sanity")
        local frame1 = sanityGui and sanityGui:FindFirstChild("Frame")
        local frame2 = frame1 and frame1:FindFirstChild("Frame")
        local textbox = frame2 and frame2:FindFirstChild("textbox")
        local amount = textbox and textbox:FindFirstChild("amount")
        if amount and amount:IsA("TextLabel") and amount.Text ~= "120%" then
            amount.Text = "120%"
        end
    end)
end

local function setSanityGod(state, silent)
    App.SanityGod = state == true

    if App.SanityGod then
        App.ForceSanity120()
    end

    notifyState(T("SANITY_GOD"), App.SanityGod, silent)
end

-- Immediate correction whenever Roblox/game logic changes the Sanity attribute.
track(LP:GetAttributeChangedSignal("Sanity"):Connect(function()
    if App.SanityGod and not App.SanityWriteGuard then
        App.ForceSanity120()
    end
end))

-- Frame-level visual/attribute guard. This is much faster than the old
-- 0.10-0.20 second polling loop.
local LastSanityVisualStep = 0
track(RunService.RenderStepped:Connect(function()
    if not App.SanityGod then
        return
    end

    if PERF.SANITY_UI_TICK > 0 then
        local now = os.clock()
        if now - LastSanityVisualStep < PERF.SANITY_UI_TICK then
            return
        end
        LastSanityVisualStep = now
    end

    App.ForceSanity120()
end))

local function stopFly()
    App.Fly = false

    if App.FlyVelocity then
        pcall(function()
            App.FlyVelocity:Destroy()
        end)
        App.FlyVelocity = nil
    end

    if App.FlyGyro then
        pcall(function()
            App.FlyGyro:Destroy()
        end)
        App.FlyGyro = nil
    end

    local _, humanoid = getCharacter()
    if humanoid then
        humanoid.PlatformStand = false
    end

    updateMobileFlyControls()
end

local function startFly()
    stopFly()

    local _, humanoid, root = getCharacter()
    if not humanoid or not root then
        return false
    end

    App.Fly = true
    humanoid.PlatformStand = true
    updateMobileFlyControls()

    local velocity = Instance.new("BodyVelocity")
    velocity.Name = "WolfFlyVelocity"
    velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    velocity.Velocity = Vector3.zero
    velocity.Parent = root

    local gyro = Instance.new("BodyGyro")
    gyro.Name = "WolfFlyGyro"
    gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    gyro.P = 90000
    gyro.CFrame = root.CFrame
    gyro.Parent = root

    App.FlyVelocity = velocity
    App.FlyGyro = gyro

    task.spawn(function()
        while App.Active and App.Fly and root.Parent and humanoid.Parent do
            local camera = workspace.CurrentCamera
            local vertical = 0

            if IS_TOUCH then
                if App.MobileFlyUp then
                    vertical += 1
                end
                if App.MobileFlyDown then
                    vertical -= 1
                end
            else
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    vertical += 1
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    vertical -= 1
                end
            end

            local speed = App.RunMode and App.RunSpeed or App.WalkSpeed
            velocity.Velocity = humanoid.MoveDirection * speed + Vector3.new(0, vertical * speed, 0)

            if camera then
                local look = camera.CFrame.LookVector
                local flat = Vector3.new(look.X, 0, look.Z)
                if flat.Magnitude > 0.001 then
                    gyro.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
                end
            end

            RunService.RenderStepped:Wait()
        end
    end)

    return true
end

local function setFly(state, silent)
    if state then
        startFly()
    else
        stopFly()
    end
    notifyState(T("FLY"), App.Fly, silent)
end

--==============================================================
-- INSTANT INTERACT
--==============================================================

local function applyPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return
    end

    if App.PromptOriginals[prompt] == nil then
        App.PromptOriginals[prompt] = prompt.HoldDuration
    end

    if App.InstantInteract then
        prompt.HoldDuration = 0
    end
end

--==============================================================
-- AUTO STAMP START POLICY
-- BEGIN IS ALWAYS MANUAL.
-- AUTO STAMP takes over only AFTER the minigame is already active.
--==============================================================

local function stampMinigameIsActive()
    local minigame = PlayerGui:FindFirstChild("Minigame")
    if not minigame or not minigame:IsA("ScreenGui") or not minigame.Enabled then
        return false
    end

    local textLabel = minigame:FindFirstChild("text")
    return textLabel
        and textLabel:IsA("TextLabel")
        and textLabel.Visible
        and tostring(textLabel.Text):match("^%d+%%$") ~= nil
end

track(PPS.PromptShown:Connect(function(prompt)
    App.VisiblePrompts[prompt] = true

    if App.InstantInteract then
        applyPrompt(prompt)
    end

end))

track(PPS.PromptHidden:Connect(function(prompt)
    App.VisiblePrompts[prompt] = nil
    if not App.InstantInteract then
        local original = App.PromptOriginals[prompt]
        if original ~= nil and prompt.Parent then
            pcall(function()
                prompt.HoldDuration = original
            end)
        end
    end
end))

local function setInstant(state, silent)
    App.InstantInteract = state == true

    if App.InstantInteract then
        for prompt in pairs(App.VisiblePrompts) do
            if prompt.Parent then
                applyPrompt(prompt)
            end
        end
    else
        -- Restore every prompt we changed, including prompts that are no longer visible.
        for prompt, original in pairs(App.PromptOriginals) do
            if prompt and prompt.Parent and original ~= nil then
                pcall(function()
                    prompt.HoldDuration = original
                end)
            end
        end
    end

    notifyState(T("INSTANT_INTERACT"), App.InstantInteract, silent)
end

--==============================================================
-- ANOMALY DEFINITIONS / DETECTION
--==============================================================

local AnomalyList = {
    {
        Key = "PATIENT",
        Icon = "✚",
        Aliases = {"Skinwalker", "PatientAnomaly"},
    },
    {
        Key = "MASS_OF_EYES",
        Icon = "👁",
        Aliases = {"MassOfEyes", "Mass of Eyes", "MassEyes", "EyeMass"},
    },
    {
        Key = "GHOST",
        Icon = "👻",
        Aliases = {"Ghost", "GhostAnomaly", "GhostVisible"},
    },
    {
        Key = "STALKER",
        Icon = "☠",
        Aliases = {"Stalker", "StalkerMonster", "StalkerJumpscare", "TallMonster", "TallMonsterSpawn"},
    },
    {
        Key = "MIMIC",
        Icon = "◉",
        Aliases = {"Mimic"},
    },
    {
        Key = "HIDERS",
        Icon = "◌",
        Aliases = {"Hider", "Hiders", "QuietOne", "Tikhonya"},
    },
    {
        Key = "RITUAL",
        Icon = "✦",
        Aliases = {"Ritual", "Ritualist"},
    },
    {
        Key = "HEAD_BANGER",
        Icon = "◆",
        Aliases = {"HeadBanger", "Head Banger", "Lobotryas"},
    },
    {
        Key = "CAMERA_MONSTER",
        Icon = "◎",
        Aliases = {"CameraMonster", "Camera Monster", "Watcher", "Observer"},
    },
    {
        Key = "BED_MONSTER",
        Icon = "▣",
        Aliases = {"BedMonster", "Bed Monster"},
    },
    {
        Key = "TENTACLES",
        Icon = "✹",
        Aliases = {"Tentacles", "Octopoid", "OctopoidAnomaly", "Osminoid"},
    },
    {
        Key = "SLIMEBERT",
        Icon = "●",
        Aliases = {"Slimebert", "IsSlimebert"},
    },
}

local AnomalyByKey = {}
for _, data in ipairs(AnomalyList) do
    AnomalyByKey[data.Key] = data
end

local function aliasMatch(data, value)
    for _, alias in ipairs(data.Aliases) do
        if same(value, alias) then
            return true
        end
    end
    return false
end

local function checkAnomalyType(model, data)
    local key = data.Key

    -- Verified patient / Skinwalker marker.
    if key == "PATIENT" then
        if model:GetAttribute("Skinwalker") == true or hasTag(model, "Skinwalker") then
            return true
        end
    end

    -- Verified Ghost marker from the client-visible game state.
    if key == "GHOST" then
        if hasTag(model, "GhostAnomaly") or model:GetAttribute("GhostAnomaly") == true then
            return true
        end
    end

    -- Stalker runtime markers found in the game state.
    if key == "STALKER" then
        if hasTag(model, "StalkerJumpscare")
            or model:GetAttribute("StalkerJumpscare") == true
            or hasTag(model, "TallMonsterSpawn")
            or model:GetAttribute("TallMonsterSpawn") == true
            or hasTag(model, "StalkerMonster")
            or same(model.Name, "TallMonster") then
            return true
        end
    end

    -- Verified Slimebert attribute seen in the client-visible game state.
    if key == "SLIMEBERT" and model:GetAttribute("IsSlimebert") == true then
        return true
    end

    if aliasMatch(data, model.Name) then
        return true
    end

    local attrs = model:GetAttributes()
    for name, value in pairs(attrs) do
        if aliasMatch(data, name) and activeValue(value) then
            return true
        end

        local n = normalize(name)
        if n == "anomaly"
            or n == "anomalytype"
            or n == "anomalyname"
            or n == "mutation"
            or n == "mutationtype" then
            if aliasMatch(data, value) then
                return true
            end
        end
    end

    local ok, tags = pcall(function()
        return CS:GetTags(model)
    end)
    if ok then
        for _, tag in ipairs(tags) do
            if aliasMatch(data, tag) then
                return true
            end
        end
    end

    -- Exact anomaly-specific child/descendant name only.
    for _, alias in ipairs(data.Aliases) do
        if model:FindFirstChild(alias, true) then
            return true
        end
    end

    return false
end

local function getAnomalyType(model)
    if not model or not model:IsA("Model") then
        return nil
    end

    for _, data in ipairs(AnomalyList) do
        if checkAnomalyType(model, data) then
            return data.Key
        end
    end

    return nil
end

local function removeAnomalyESP(model)
    local data = App.AnomalyMarked[model]
    if not data then
        return
    end

    pcall(function()
        data.Highlight:Destroy()
    end)
    pcall(function()
        data.GUI:Destroy()
    end)

    App.AnomalyMarked[model] = nil
end

local function updateMarkedLanguage(model)
    local data = App.AnomalyMarked[model]
    if not data then
        return
    end

    local typeName = anomalyName(data.Type)
    if data.Label then
        data.Label.Text = T("ESP_ANOMALY") .. "  •  " .. typeName
    end
end

local function markAnomaly(model, anomalyKey)
    local definition = AnomalyByKey[anomalyKey]
    if not definition then
        return
    end

    local existing = App.AnomalyMarked[model]
    if existing then
        existing.Type = anomalyKey
        updateMarkedLanguage(model)
        return
    end

    local head = getESPPart(model)
    if not head then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "WolfAnomalyHighlight"
    highlight.Adornee = model
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.73
    highlight.OutlineTransparency = 0
    highlight.FillColor = C.ANOMALY
    highlight.OutlineColor = Color3.fromRGB(255, 134, 154)
    highlight.Parent = model

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WolfAnomalyESP"
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(330, 60)
    billboard.StudsOffset = Vector3.new(0, 4.15, 0)
    billboard.Parent = head

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -20, 0, 39)
    bg.Position = UDim2.fromOffset(10, 8)
    bg.BackgroundColor3 = Color3.fromRGB(66, 13, 28)
    bg.BackgroundTransparency = 0.08
    bg.Parent = billboard
    corner(bg, 11)
    stroke(bg, C.ANOMALY, 1.6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 232, 237)
    label.TextStrokeTransparency = 0.42
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 14
    label.Parent = bg

    App.AnomalyMarked[model] = {
        Highlight = highlight,
        GUI = billboard,
        Label = label,
        Type = anomalyKey,
    }

    updateMarkedLanguage(model)
end

local function updateAnomaly(model)
    if not model or not model:IsA("Model") then
        return
    end

    -- No master ESP switch. Every anomaly type is fully independent.
    -- We only mark a model when a matching type is individually enabled.
    local anomalyType = nil

    for _, definition in ipairs(AnomalyList) do
        local key = definition.Key

        if App.AnomalyEnabled[key] == true
            and checkAnomalyType(model, definition) then
            anomalyType = key
            break
        end
    end

    if not anomalyType then
        removeAnomalyESP(model)
        return
    end

    markAnomaly(model, anomalyType)
end

refreshAllESP = function()
    for _, model in ipairs(NPCFolder:GetChildren()) do
        if model:IsA("Model") then
            updateAnomaly(model)
        end
    end

    for model in pairs(App.AnomalyMarked) do
        if not model:IsDescendantOf(workspace) then
            removeAnomalyESP(model)
        else
            updateMarkedLanguage(model)
        end
    end
end

local function setAnomalyType(key, state, silent)
    if App.AnomalyEnabled[key] == nil then
        return
    end
    App.AnomalyEnabled[key] = state == true
    refreshAllESP()
    notifyState(anomalyName(key), App.AnomalyEnabled[key], silent)
end

local function watchNPC(model)
    if not model:IsA("Model") then
        return
    end

    track(model.AttributeChanged:Connect(function()
        if App.Active then
            updateAnomaly(model)
        end
    end))

    track(model.ChildAdded:Connect(function()
        if App.Active then
            task.defer(updateAnomaly, model)
        end
    end))

    track(model.ChildRemoved:Connect(function()
        if App.Active then
            task.defer(updateAnomaly, model)
        end
    end))

    updateAnomaly(model)
end

for _, model in ipairs(NPCFolder:GetChildren()) do
    watchNPC(model)
end

track(NPCFolder.ChildAdded:Connect(function(model)
    task.wait(0.2)
    if App.Active then
        watchNPC(model)
    end
end))

track(NPCFolder.ChildRemoved:Connect(function(model)
    removeAnomalyESP(model)
end))

-- Targeted tag listeners. These are lightweight and also catch tagged anomaly models.
local WatchedTags = {
    "Skinwalker",
    "GhostAnomaly",
    "StalkerJumpscare",
    "StalkerMonster",
    "TallMonsterSpawn",
    "MassOfEyes",
    "Mimic",
    "Hiders",
    "Ritual",
    "HeadBanger",
    "CameraMonster",
    "BedMonster",
    "Tentacles",
    "Slimebert",
}

local function resolveTaggedModel(object)
    if not object then
        return nil
    end
    if object:IsA("Model") then
        return object
    end
    return object:FindFirstAncestorOfClass("Model")
end

for _, tag in ipairs(WatchedTags) do
    track(CS:GetInstanceAddedSignal(tag):Connect(function(object)
        local model = resolveTaggedModel(object)
        if model and model:IsDescendantOf(workspace) then
            updateAnomaly(model)
        end
    end))

    track(CS:GetInstanceRemovedSignal(tag):Connect(function(object)
        local model = resolveTaggedModel(object)
        if model then
            task.defer(updateAnomaly, model)
        end
    end))
end

task.spawn(function()
    while App.Active do
        refreshAllESP()
        task.wait(PERF.ESP_REFRESH)
    end
end)

--==============================================================
-- KEY CHARACTER NOTIFICATIONS V38
-- Reliable arrival detection:
--   * new NPC model
--   * key-character name/display-name becoming available later
--   * hospital/patient attributes changing on an existing NPC
--   * low-frequency fallback scan (important on mobile/executors)
--==============================================================

local KEY_CHARACTERS = {
    Barney = {"Barney"},
    Ratthew = {"Ratthew"},
    Ron = {"Ron", "Ron from Accounting"},
    Liz = {"Liz"},
    Sam = {"Sam"},
}

local KEY_ARRIVAL_ATTRIBUTES = {
    "IsPatient",
    "CheckedIn",
    "CompletedCheckIn",
    "InBed",
    "Treated",
    "SkippedCheckIn",
    "DesignatedRoom",
    "AsignedCheckIn",
    "AssignedCheckIn",
    "Room",
}

local function matchKeyCharacterText(text)
    local value = string.lower(tostring(text or ""))
    value = value:gsub("^%s+", ""):gsub("%s+$", "")

    if value == "" then
        return nil
    end

    for display, aliases in pairs(KEY_CHARACTERS) do
        for _, alias in ipairs(aliases) do
            local a = string.lower(alias)

            if value == a then
                return display
            end

            if value:sub(1, #a) == a then
                local nextChar = value:sub(#a + 1, #a + 1)
                if nextChar == ""
                    or nextChar == " "
                    or nextChar == "_"
                    or nextChar == "-"
                    or nextChar == "("
                    or nextChar == "[" then

                    return display
                end
            end
        end
    end

    return nil
end

local function getKeyCharacterName(model)
    if not model or not model:IsA("Model") then
        return nil
    end

    local result = matchKeyCharacterText(model.Name)
    if result then
        return result
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        result = matchKeyCharacterText(humanoid.DisplayName)
        if result then
            return result
        end
    end

    -- Known name-like attributes first.
    for _, attrName in ipairs({
        "NPCName",
        "CharacterName",
        "DisplayName",
        "PatientName",
        "Name",
        "DialogueName",
    }) do
        local value = model:GetAttribute(attrName)
        if value ~= nil then
            result = matchKeyCharacterText(value)
            if result then
                return result
            end
        end
    end

    -- Fallback: some NPC systems store the visible identity under a
    -- game-specific string attribute. Scan strings only; this is tiny.
    local ok, attrs = pcall(function()
        return model:GetAttributes()
    end)

    if ok and type(attrs) == "table" then
        for _, value in pairs(attrs) do
            if type(value) == "string" then
                result = matchKeyCharacterText(value)
                if result then
                    return result
                end
            end
        end
    end

    return nil
end

local function keyCharacterHospitalState(model)
    if not model
        or not model:IsA("Model")
        or model.Parent ~= NPCFolder then

        return false, false
    end

    local sawArrivalAttribute = false

    for _, attrName in ipairs(KEY_ARRIVAL_ATTRIBUTES) do
        local value = model:GetAttribute(attrName)

        if value ~= nil then
            sawArrivalAttribute = true

            if attrName == "DesignatedRoom"
                or attrName == "AsignedCheckIn"
                or attrName == "AssignedCheckIn"
                or attrName == "Room" then

                if tostring(value) ~= ""
                    and string.lower(tostring(value)) ~= "none"
                    and string.lower(tostring(value)) ~= "nil" then

                    return true, true
                end
            elseif activeValue(value) then
                return true, true
            end
        end
    end

    return false, sawArrivalAttribute
end

local function keyCharacterArrived(model, reason)
    if not App.KeyCharacterNotifications
        or not model
        or model.Parent ~= NPCFolder then

        return false
    end

    local characterName = getKeyCharacterName(model)
    if not characterName then
        return false
    end

    local now = os.clock()
    local previous = App.KeyCharacterLastAlert[characterName]

    -- Stronger duplicate protection because one arrival can produce
    -- ChildAdded + several attribute changes in the same second.
    if previous and now - previous < 10 then
        return false
    end

    App.KeyCharacterLastAlert[characterName] = now

    notify(
        F("N_KEY_ARRIVED", {name = characterName}),
        IS_TOUCH and 3.6 or 3.8,
        true
    )

    return true
end

local function reevaluateKeyCharacter(model, allowSpawnAlert)
    if not model
        or not model:IsA("Model")
        or model.Parent ~= NPCFolder then

        return
    end

    local state = App.KeyCharacterStates[model]
    if not state then
        state = {
            Name = nil,
            Hospital = false,
            SawArrivalAttribute = false,
            Initialized = false,
        }
        App.KeyCharacterStates[model] = state
    end

    local characterName = getKeyCharacterName(model)
    local hospital, sawArrivalAttribute = keyCharacterHospitalState(model)

    local wasName = state.Name
    local wasHospital = state.Hospital

    state.Name = characterName
    state.Hospital = hospital
    state.SawArrivalAttribute = sawArrivalAttribute

    if not state.Initialized then
        state.Initialized = true

        -- Models that are created while notifications are ON count as arrival
        -- even before patient attributes finish replicating.
        if allowSpawnAlert and characterName then
            keyCharacterArrived(model, "spawn")
        end
        return
    end

    if not App.KeyCharacterNotifications or not characterName then
        return
    end

    -- Existing NPC became a hospital patient / checked in / got a room.
    if hospital and not wasHospital then
        keyCharacterArrived(model, "hospital-state")
        return
    end

    -- Identity sometimes replicates after the model itself. If a newly
    -- identified key character is already in an active hospital state,
    -- alert at that moment.
    if not wasName and characterName and hospital then
        keyCharacterArrived(model, "identity-replicated")
    end
end

local function watchKeyCharacterModel(model, allowSpawnAlert)
    if not model or not model:IsA("Model") then
        return
    end

    local watcher = App.KeyCharacterWatchers[model]

    if not watcher then
        watcher = {Connected = true}
        App.KeyCharacterWatchers[model] = watcher

        track(model:GetPropertyChangedSignal("Name"):Connect(function()
            if App.Active then
                reevaluateKeyCharacter(model, false)
            end
        end))

        track(model.AttributeChanged:Connect(function()
            if App.Active then
                reevaluateKeyCharacter(model, false)
            end
        end))

        local function bindHumanoid(humanoid)
            if not humanoid
                or not humanoid:IsA("Humanoid")
                or watcher.Humanoid == humanoid then

                return
            end

            watcher.Humanoid = humanoid

            track(humanoid:GetPropertyChangedSignal("DisplayName"):Connect(function()
                if App.Active then
                    reevaluateKeyCharacter(model, false)
                end
            end))
        end

        bindHumanoid(model:FindFirstChildOfClass("Humanoid"))

        track(model.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") then
                bindHumanoid(child)
                task.defer(function()
                    if App.Active then
                        reevaluateKeyCharacter(model, false)
                    end
                end)
            end
        end))
    end

    reevaluateKeyCharacter(model, allowSpawnAlert == true)
end

-- Baseline existing NPCs without generating false "arrival" messages.
for _, model in ipairs(NPCFolder:GetChildren()) do
    if model:IsA("Model") then
        watchKeyCharacterModel(model, false)
    end
end

track(NPCFolder.ChildAdded:Connect(function(model)
    if not model:IsA("Model") then
        return
    end

    task.delay(IS_TOUCH and 0.20 or 0.12, function()
        if App.Active and model.Parent == NPCFolder then
            watchKeyCharacterModel(
                model,
                App.KeyCharacterNotifications
            )
        end
    end)
end))

-- Fallback scan catches executor replication races and models whose
-- identifying attributes/display name arrive after ChildAdded.
task.spawn(function()
    while App.Active do
        if App.KeyCharacterNotifications then
            for _, model in ipairs(NPCFolder:GetChildren()) do
                if model:IsA("Model") then
                    watchKeyCharacterModel(model, false)
                    reevaluateKeyCharacter(model, false)
                end
            end
        end

        task.wait(PERF.KEY_SCAN_TICK)
    end
end)

local function setKeyCharacterNotifications(state, silent)
    App.KeyCharacterNotifications = state == true

    table.clear(App.KeyCharacterLastAlert)

    -- Re-baseline all currently present NPCs whenever the toggle changes.
    -- This means turning notifications ON does not falsely announce NPCs
    -- that were already in the hospital before the toggle was enabled.
    for _, model in ipairs(NPCFolder:GetChildren()) do
        if model:IsA("Model") then
            watchKeyCharacterModel(model, false)

            local item = App.KeyCharacterStates[model]
            if item then
                item.Name = getKeyCharacterName(model)
                item.Hospital = select(1, keyCharacterHospitalState(model))
                item.Initialized = true
            end
        end
    end

    notifyState(T("KEY_NOTIFICATIONS"), App.KeyCharacterNotifications, silent)
end

--==============================================================
-- FLOATING ICON
--==============================================================

local Icon = Instance.new("TextButton")
Icon.Name = "WolfIcon"
Icon.Size = UDim2.fromOffset(IS_TOUCH and 45 or 72, IS_TOUCH and 45 or 72)
Icon.Position = IS_TOUCH and UDim2.fromOffset(12, 138) or UDim2.new(0, 20, 0.36, 0)
Icon.BackgroundColor3 = C.CARD
Icon.Text = "🐺"
Icon.TextSize = IS_TOUCH and 23 or 36
Icon.TextColor3 = C.TEXT
Icon.AutoButtonColor = false
Icon.Parent = GUI
corner(Icon, IS_TOUCH and 14 or 23)
stroke(Icon, C.CYAN, 2)
gradient(Icon, Color3.fromRGB(36, 72, 155), Color3.fromRGB(93, 35, 143), 45)

local Glow = Instance.new("Frame")
Glow.AnchorPoint = Vector2.new(0.5, 0.5)
Glow.Position = UDim2.fromScale(0.5, 0.5)
Glow.Size = UDim2.new(1, IS_TOUCH and 8 or 14, 1, IS_TOUCH and 8 or 14)
Glow.BackgroundTransparency = 1
Glow.ZIndex = 0
Glow.Parent = Icon
corner(Glow, IS_TOUCH and 18 or 27)
local GlowStroke = stroke(Glow, C.PURPLE, IS_TOUCH and 2.5 or 4, 0.48)

if IS_TOUCH then
    GlowStroke.Transparency = 0.42
else
    task.spawn(function()
        while App.Active and Glow.Parent do
            tween(GlowStroke, 0.85, {Transparency = 0.08})
            task.wait(0.85)
            tween(GlowStroke, 0.85, {Transparency = 0.66})
            task.wait(0.85)
        end
    end)
end

--==============================================================
-- MAIN WINDOW
--==============================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.Size = UDim2.fromOffset(IS_TOUCH and BASE_MOBILE.X or BASE_DESKTOP.X, IS_TOUCH and BASE_MOBILE.Y or BASE_DESKTOP.Y)
Main.BackgroundColor3 = C.BG
Main.Visible = false
Main.Parent = GUI
corner(Main, 21)
stroke(Main, C.BLUE, 1.6, 0.15)
gradient(Main, Color3.fromRGB(11, 15, 27), Color3.fromRGB(6, 8, 14), 90)

local MainScale = Instance.new("UIScale")
MainScale.Parent = Main

local ViewportConnection
local function updateScale()
    local viewport = getViewport()
    local base = IS_TOUCH and BASE_MOBILE or BASE_DESKTOP

    if IS_TOUCH then
        -- V38: responsive phone/tablet scale.
        -- Avoid oversized menus on high-resolution phones and leave room
        -- for Roblox's top/bottom touch UI.
        local widthMargin = isPortraitViewport() and 0.84 or 0.82
        local heightMargin = isPortraitViewport() and 0.80 or 0.78

        MainScale.Scale = math.clamp(
            math.min(
                (viewport.X * widthMargin) / base.X,
                (viewport.Y * heightMargin) / base.Y
            ),
            0.42,
            1.08
        )
    else
        MainScale.Scale = math.min(1, (viewport.X - 30) / 870, (viewport.Y - 30) / 570)
    end
end

local function bindViewport()
    if ViewportConnection then
        ViewportConnection:Disconnect()
        ViewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        ViewportConnection = track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
    end
    updateScale()
end

bindViewport()
track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport))

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, IS_TOUCH and 64 or 76)
Top.BackgroundColor3 = C.TOP
Top.Parent = Main
corner(Top, 21)
gradient(Top, Color3.fromRGB(29, 44, 87), Color3.fromRGB(63, 25, 80), 0)

local TopMask = Instance.new("Frame")
TopMask.Position = UDim2.new(0, 0, 1, -18)
TopMask.Size = UDim2.new(1, 0, 0, 18)
TopMask.BorderSizePixel = 0
TopMask.BackgroundColor3 = C.TOP
TopMask.Parent = Top

local Logo = Instance.new("TextLabel")
Logo.Position = UDim2.fromOffset(IS_TOUCH and 14 or 20, IS_TOUCH and 6 or 10)
Logo.Size = UDim2.fromOffset(IS_TOUCH and 41 or 47, IS_TOUCH and 47 or 53)
Logo.BackgroundTransparency = 1
Logo.Text = "🐺"
Logo.TextSize = IS_TOUCH and 28 or 32
Logo.Parent = Top

local Title = Instance.new("TextLabel")
Title.Position = UDim2.fromOffset(IS_TOUCH and 58 or 71, IS_TOUCH and 6 or 10)
Title.Size = UDim2.fromOffset(380, 31)
Title.BackgroundTransparency = 1
Title.Text = "WOLF CONTROL"
Title.TextColor3 = C.TEXT
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBlack
Title.TextSize = IS_TOUCH and 23 or 25
Title.Parent = Top

local Version = Instance.new("TextLabel")
Version.Position = UDim2.fromOffset(IS_TOUCH and 60 or 73, IS_TOUCH and 34 or 42)
Version.Size = UDim2.new(1, IS_TOUCH and -150 or -410, 0, 18)
Version.BackgroundTransparency = 1
Version.TextColor3 = C.MUTED
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.Font = Enum.Font.GothamMedium
Version.TextSize = IS_TOUCH and 10 or 11
Version.Parent = Top

local Status = Instance.new("Frame")
Status.Size = UDim2.fromOffset(120, 35)
Status.Visible = not IS_TOUCH
Status.Position = UDim2.new(1, -180, 0, 20)
Status.BackgroundColor3 = Color3.fromRGB(19, 54, 42)
Status.Parent = Top
corner(Status, 18)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(9, 9)
StatusDot.Position = UDim2.fromOffset(14, 13)
StatusDot.BackgroundColor3 = C.GREEN
StatusDot.Parent = Status
corner(StatusDot, 20)

local StatusText = Instance.new("TextLabel")
StatusText.Position = UDim2.fromOffset(31, 0)
StatusText.Size = UDim2.new(1, -36, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = C.GREEN
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 12
StatusText.Parent = Status

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(IS_TOUCH and 50 or 42, IS_TOUCH and 50 or 42)
Close.Position = UDim2.new(1, IS_TOUCH and -60 or -54, 0, IS_TOUCH and 11 or 17)
Close.BackgroundColor3 = Color3.fromRGB(95, 31, 48)
Close.Text = "×"
Close.TextColor3 = C.TEXT
Close.TextSize = IS_TOUCH and 32 or 29
Close.Font = Enum.Font.GothamBold
Close.AutoButtonColor = false
Close.Parent = Top
corner(Close, IS_TOUCH and 15 or 13)

--==============================================================
-- SIDEBAR
--==============================================================

local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.fromOffset(14, 91)
Sidebar.Size = UDim2.fromOffset(195, 435)
Sidebar.BackgroundColor3 = C.SIDEBAR
Sidebar.Parent = Main
corner(Sidebar, 18)
stroke(Sidebar, C.OUTLINE, 1, 0.35)

local Navigation = Instance.new("TextLabel")
Navigation.Position = UDim2.fromOffset(16, 15)
Navigation.Size = UDim2.new(1, -32, 0, 20)
Navigation.BackgroundTransparency = 1
Navigation.TextColor3 = C.MUTED
Navigation.TextXAlignment = Enum.TextXAlignment.Left
Navigation.Font = Enum.Font.GothamBold
Navigation.TextSize = 11
Navigation.Parent = Sidebar

local NavButtons = {}
local function createNav(key, iconText, y)
    local button = Instance.new("TextButton")
    button.Position = UDim2.fromOffset(10, y)
    button.Size = UDim2.new(1, -20, 0, 54)
    button.BackgroundColor3 = C.SIDEBAR
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = Sidebar
    corner(button, 14)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.fromOffset(4, 30)
    accent.Position = UDim2.new(0, 0, 0.5, -15)
    accent.BackgroundColor3 = C.CYAN
    accent.Visible = false
    accent.Parent = button
    corner(accent, 5)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.fromOffset(44, 54)
    icon.Position = UDim2.fromOffset(7, 0)
    icon.BackgroundTransparency = 1
    icon.Text = iconText
    icon.TextColor3 = C.TEXT
    icon.TextSize = 21
    icon.Parent = button

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(51, 0)
    label.Size = UDim2.new(1, -58, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = C.MUTED
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = button

    NavButtons[key] = {
        Button = button,
        Accent = accent,
        Label = label,
    }

    return button
end

local ESPNav = createNav("ESP", "◉", 50)
local PlayerNav = createNav("PLAYER", "◆", 112)
local MiscNav = createNav("MISC", "⚙", 174)
local SettingsNav = createNav("SETTINGS", "≡", 236)

local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, -20, 0, 72)
Footer.Position = UDim2.new(0, 10, 1, -83)
Footer.BackgroundColor3 = C.CARD
Footer.Parent = Sidebar
corner(Footer, 14)

local FooterIcon = Instance.new("TextLabel")
FooterIcon.Size = UDim2.fromOffset(46, 72)
FooterIcon.BackgroundTransparency = 1
FooterIcon.Text = "🐺"
FooterIcon.TextSize = 24
FooterIcon.Parent = Footer

local FooterTitle = Instance.new("TextLabel")
FooterTitle.Position = UDim2.fromOffset(46, 15)
FooterTitle.Size = UDim2.new(1, -52, 0, 18)
FooterTitle.BackgroundTransparency = 1
FooterTitle.Text = "WOLF ENGINE"
FooterTitle.TextColor3 = C.TEXT
FooterTitle.TextXAlignment = Enum.TextXAlignment.Left
FooterTitle.Font = Enum.Font.GothamBold
FooterTitle.TextSize = 10
FooterTitle.Parent = Footer

local FooterStatus = Instance.new("TextLabel")
FooterStatus.Position = UDim2.fromOffset(46, 35)
FooterStatus.Size = UDim2.new(1, -52, 0, 18)
FooterStatus.BackgroundTransparency = 1
FooterStatus.TextColor3 = C.GREEN
FooterStatus.TextXAlignment = Enum.TextXAlignment.Left
FooterStatus.Font = Enum.Font.GothamBold
FooterStatus.TextSize = 10
FooterStatus.Parent = Footer

--==============================================================
-- CONTENT
--==============================================================

local Content = Instance.new("Frame")
Content.Position = UDim2.fromOffset(224, 91)
Content.Size = UDim2.new(1, -238, 1, -105)
Content.BackgroundColor3 = C.SIDEBAR
Content.Parent = Main

if IS_TOUCH then
    Sidebar.Visible = false
    Content.Position = UDim2.fromOffset(14, 86)
    Content.Size = UDim2.new(1, -28, 1, -174)
end

corner(Content, 18)
stroke(Content, C.OUTLINE, 1, 0.35)

local PageTitle = Instance.new("TextLabel")
PageTitle.Position = UDim2.fromOffset(22, 17)
PageTitle.Size = UDim2.new(1, -44, 0, 30)
PageTitle.BackgroundTransparency = 1
PageTitle.TextColor3 = C.TEXT
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.Font = Enum.Font.GothamBlack
PageTitle.TextSize = IS_TOUCH and 22 or 25
PageTitle.Parent = Content

local PageInfo = Instance.new("TextLabel")
PageInfo.Position = UDim2.fromOffset(23, 49)
PageInfo.Size = UDim2.new(1, -46, 0, 20)
PageInfo.BackgroundTransparency = 1
PageInfo.TextColor3 = C.MUTED
PageInfo.TextXAlignment = Enum.TextXAlignment.Left
PageInfo.Font = Enum.Font.Gotham
PageInfo.TextSize = IS_TOUCH and 13 or 12
PageInfo.Parent = Content

local HeaderLine = Instance.new("Frame")
HeaderLine.Position = UDim2.fromOffset(22, 79)
HeaderLine.Size = UDim2.new(1, -44, 0, 2)
HeaderLine.BackgroundColor3 = C.BLUE
HeaderLine.Parent = Content
gradient(HeaderLine, C.CYAN, C.PURPLE, 0)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Position = UDim2.fromOffset(18, 94)
Scroll.Size = UDim2.new(1, -36, 1, IS_TOUCH and -164 or -109)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = IS_TOUCH and 6 or 4
Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
Scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
Scroll.ScrollBarImageColor3 = C.BLUE
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new()
Scroll.Parent = Content

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, IS_TOUCH and 13 or 11)
Layout.Parent = Scroll

--==============================================================
-- MOBILE BOTTOM NAVIGATION
--==============================================================

local MobileNavButtons = {}
local MobileNav = Instance.new("Frame")
MobileNav.Name = "MobileNav"
MobileNav.Position = UDim2.new(0, 10, 1, -61)
MobileNav.Size = UDim2.new(1, -20, 0, 50)
MobileNav.BackgroundColor3 = C.SIDEBAR
MobileNav.Visible = IS_TOUCH
MobileNav.Parent = Main
corner(MobileNav, 14)
stroke(MobileNav, C.OUTLINE, 1, 0.25)

local MobileNavLayout = Instance.new("UIListLayout")
MobileNavLayout.FillDirection = Enum.FillDirection.Horizontal
MobileNavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
MobileNavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
MobileNavLayout.Padding = UDim.new(0, 6)
MobileNavLayout.Parent = MobileNav

local function createMobileNav(key, iconText)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.25, -9, 1, -10)
    button.BackgroundColor3 = C.CARD
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = MobileNav
    corner(button, 14)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0.62, 0, 0, 3)
    accent.AnchorPoint = Vector2.new(0.5, 1)
    accent.Position = UDim2.new(0.5, 0, 1, -3)
    accent.BackgroundColor3 = C.CYAN
    accent.Visible = false
    accent.Parent = button
    corner(accent, 3)

    local icon = Instance.new("TextLabel")
    icon.Position = UDim2.new(0, 8, 0, 0)
    icon.Size = UDim2.fromOffset(31, 48)
    icon.BackgroundTransparency = 1
    icon.Text = iconText
    icon.TextColor3 = C.TEXT
    icon.TextSize = IS_TOUCH and 18 or 20
    icon.Parent = button

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(36, 0)
    label.Size = UDim2.new(1, -39, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = C.MUTED
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = IS_TOUCH and 11 or 12
    label.TextWrapped = true
    label.Parent = button

    MobileNavButtons[key] = {Button = button, Accent = accent, Label = label}
    return button
end

local MobileESPNav = createMobileNav("ESP", "◉")
local MobilePlayerNav = createMobileNav("PLAYER", "◆")
local MobileMiscNav = createMobileNav("MISC", "⚙")
local MobileSettingsNav = createMobileNav("SETTINGS", "≡")

local function clearPage()
    clearPageConnections()
    for _, child in ipairs(Scroll:GetChildren()) do
        if child ~= Layout then
            child:Destroy()
        end
    end
end

local function createSection(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -5, 0, IS_TOUCH and 30 or 26)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = C.MUTED
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = IS_TOUCH and 13 or 11
    label.Parent = Scroll
    return label
end

local function createCard(height, iconText, titleText, description)
    local actualHeight = IS_TOUCH and (height + 12) or height
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -5, 0, actualHeight)
    card.BackgroundColor3 = C.CARD
    card.Active = IS_TOUCH
    card.Parent = Scroll
    corner(card, IS_TOUCH and 17 or 15)
    local cardStroke = stroke(card, C.OUTLINE, 1, 0.38)

    local iconSize = IS_TOUCH and 56 or 48
    local iconBox = Instance.new("Frame")
    iconBox.Size = UDim2.fromOffset(iconSize, iconSize)
    iconBox.Position = UDim2.fromOffset(IS_TOUCH and 16 or 14, IS_TOUCH and 14 or 12)
    iconBox.BackgroundColor3 = Color3.fromRGB(30, 45, 78)
    iconBox.Parent = card
    corner(iconBox, IS_TOUCH and 15 or 13)
    gradient(iconBox, Color3.fromRGB(39, 79, 160), Color3.fromRGB(85, 38, 130), 45)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.fromScale(1, 1)
    icon.BackgroundTransparency = 1
    icon.Text = iconText
    icon.TextColor3 = C.TEXT
    icon.TextSize = IS_TOUCH and 25 or 22
    icon.Parent = iconBox

    local textX = IS_TOUCH and 86 or 76
    local reserveRight = IS_TOUCH and 190 or 230

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(textX, IS_TOUCH and 15 or 13)
    title.Size = UDim2.new(1, -reserveRight, 0, IS_TOUCH and 25 or 22)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = C.TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = IS_TOUCH and 18 or 15
    title.TextWrapped = true
    title.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Position = UDim2.fromOffset(textX, IS_TOUCH and 43 or 36)
    desc.Size = UDim2.new(1, -reserveRight, 0, IS_TOUCH and 28 or 22)
    desc.BackgroundTransparency = 1
    desc.Text = description or ""
    desc.TextColor3 = C.MUTED
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Font = Enum.Font.Gotham
    desc.TextSize = IS_TOUCH and 12 or 10
    desc.TextWrapped = true
    desc.Parent = card

    if not IS_TOUCH then
        card.MouseEnter:Connect(function()
            tween(card, 0.12, {BackgroundColor3 = C.CARD_HOVER})
            tween(cardStroke, 0.12, {Color = C.BLUE, Transparency = 0.1})
        end)

        card.MouseLeave:Connect(function()
            tween(card, 0.12, {BackgroundColor3 = C.CARD})
            tween(cardStroke, 0.12, {Color = C.OUTLINE, Transparency = 0.38})
        end)
    end

    return card
end

local function createToggle(iconText, titleText, description, getter, setter)
    local card = createCard(72, iconText, titleText, description)

    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(1, 0)
    status.Position = UDim2.new(1, IS_TOUCH and -94 or -92, 0, IS_TOUCH and 31 or 27)
    status.Size = UDim2.fromOffset(IS_TOUCH and 58 or 56, IS_TOUCH and 20 or 18)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamBold
    status.TextSize = IS_TOUCH and 11 or 9
    status.ZIndex = 7
    status.Parent = card

    -- Visual switch only. The whole card gets ONE dedicated hitbox below.
    -- This fixes cases where the knob/frame or executor input routing eats
    -- MouseButton1Click on the small switch itself.
    local switch = Instance.new("Frame")
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Position = UDim2.new(1, IS_TOUCH and -14 or -17, 0.5, 0)
    switch.Size = UDim2.fromOffset(IS_TOUCH and 68 or 64, IS_TOUCH and 38 or 32)
    switch.BackgroundColor3 = C.RED
    switch.ZIndex = 7
    switch.Parent = card
    corner(switch, 22)

    local knobSize = IS_TOUCH and 28 or 24
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(knobSize, knobSize)
    knob.Position = UDim2.fromOffset(4, IS_TOUCH and 5 or 4)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.ZIndex = 8
    knob.Parent = switch
    corner(knob, 20)

    local function refresh()
        local ok, value = pcall(getter)
        local enabled = ok and value == true
        status.Text = enabled and T("ACTIVE") or T("OFF")
        status.TextColor3 = enabled and C.GREEN or C.MUTED
        tween(switch, 0.12, {
            BackgroundColor3 = enabled and C.GREEN or C.RED,
        })
        tween(knob, 0.12, {
            Position = enabled
                and UDim2.fromOffset(IS_TOUCH and 36 or 36, IS_TOUCH and 5 or 4)
                or UDim2.fromOffset(4, IS_TOUCH and 5 or 4),
        })
    end

    local busy = false
    local function toggle()
        if busy then
            return
        end
        busy = true

        local okGet, current = pcall(getter)
        current = okGet and current == true
        local wanted = not current

        local okSet, err = pcall(setter, wanted)
        if not okSet then
            warn("[WOLF] TOGGLE ERROR |", tostring(titleText), "|", tostring(err))
        end

        -- Refresh even if the setter had an internal error. This keeps the
        -- switch visually synced with the real state instead of getting stuck.
        refresh()
        task.delay(0.12, function()
            busy = false
        end)
    end

    -- One full-card input surface for BOTH mouse and touch.
    -- Activated is more reliable than MouseButton1Click across desktop/mobile.
    local hitbox = Instance.new("TextButton")
    hitbox.Name = "ToggleHitbox"
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.AutoButtonColor = false
    hitbox.Active = true
    hitbox.Selectable = false
    hitbox.Size = UDim2.fromScale(1, 1)
    hitbox.Position = UDim2.fromOffset(0, 0)
    hitbox.ZIndex = 20
    hitbox.Parent = card
    hitbox.Activated:Connect(toggle)

    refresh()
    return refresh
end

local function createSlider(iconText, titleText, description, minimum, maximum, getter, setter)
    local card = createCard(98, iconText, titleText, description)

    local value = Instance.new("TextLabel")
    value.AnchorPoint = Vector2.new(1, 0)
    value.Position = UDim2.new(1, -17, 0, IS_TOUCH and 20 or 17)
    value.Size = UDim2.fromOffset(IS_TOUCH and 70 or 60, IS_TOUCH and 34 or 28)
    value.BackgroundColor3 = Color3.fromRGB(29, 39, 58)
    value.TextColor3 = C.CYAN
    value.Font = Enum.Font.GothamBold
    value.TextSize = IS_TOUCH and 17 or 14
    value.Parent = card
    corner(value, 10)

    local bar = Instance.new("Frame")
    bar.Position = UDim2.new(0, IS_TOUCH and 20 or 18, 1, IS_TOUCH and -29 or -24)
    bar.Size = UDim2.new(1, IS_TOUCH and -40 or -36, 0, IS_TOUCH and 12 or 8)
    bar.BackgroundColor3 = Color3.fromRGB(38, 46, 63)
    bar.Parent = card
    corner(bar, 10)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = C.BLUE
    fill.Size = UDim2.fromScale(0, 1)
    fill.Parent = bar
    corner(fill, 10)
    gradient(fill, C.CYAN, C.PURPLE, 0)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(IS_TOUCH and 28 or 18, IS_TOUCH and 28 or 18)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = C.TEXT
    knob.Parent = bar
    corner(knob, 20)
    stroke(knob, C.CYAN, 2)

    -- Larger transparent hit zone so the slider is easy to grab with a thumb.
    local hit = Instance.new("Frame")
    hit.BackgroundTransparency = 1
    hit.Active = true
    hit.Position = UDim2.new(0, 0, 0.5, IS_TOUCH and -24 or -14)
    hit.Size = UDim2.new(1, 0, 0, IS_TOUCH and 48 or 28)
    hit.Parent = bar

    local dragging = false
    local dragInput = nil

    local function setValue(v)
        v = math.clamp(math.floor(v + 0.5), minimum, maximum)
        setter(v)
        value.Text = tostring(v)
        local alpha = (v - minimum) / (maximum - minimum)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
    end

    local function update(input)
        if bar.AbsoluteSize.X <= 0 then
            return
        end
        local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        setValue(minimum + (maximum - minimum) * alpha)
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            update(input)
        end
    end)

    pageTrack(UIS.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragInput == nil or input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end
    end))

    pageTrack(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragInput == nil or input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                dragInput = nil
            end
        end
    end))

    setValue(getter())
end

local function createAction(iconText, titleText, description, buttonText, callback, accentColor)
    local card = createCard(72, iconText, titleText, description)

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -17, 0.5, 0)
    button.Size = UDim2.fromOffset(IS_TOUCH and 138 or 118, IS_TOUCH and 44 or 36)
    button.BackgroundColor3 = accentColor or Color3.fromRGB(48, 83, 160)
    button.Text = buttonText
    button.TextColor3 = C.TEXT
    button.Font = Enum.Font.GothamBold
    button.TextSize = IS_TOUCH and 13 or 11
    button.AutoButtonColor = false
    button.Parent = card
    corner(button, 11)
    stroke(button, Color3.fromRGB(125, 170, 255), 1, 0.35)

    if not IS_TOUCH then
        button.MouseEnter:Connect(function()
            tween(button, 0.12, {BackgroundColor3 = C.BLUE})
        end)
        button.MouseLeave:Connect(function()
            tween(button, 0.12, {BackgroundColor3 = accentColor or Color3.fromRGB(48, 83, 160)})
        end)
    end
    button.MouseButton1Click:Connect(callback)

    return button
end

local function createInfoCard(text, good)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -5, 0, 44)
    card.BackgroundColor3 = good and Color3.fromRGB(17, 55, 42) or Color3.fromRGB(70, 30, 37)
    card.Parent = Scroll
    corner(card, 12)
    stroke(card, good and C.GREEN or C.RED, 1, 0.3)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = good and C.GREEN or Color3.fromRGB(255, 150, 165)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card
end

--==============================================================
-- NAV / STATIC LOCALIZATION
--==============================================================

local NAV_TRANSLATION_KEYS = {
    ESP = "NAV_ESP",
    PLAYER = "NAV_PLAYER",
    MISC = "NAV_MISC",
    SETTINGS = "NAV_SETTINGS",
}

local function selectNav(key)
    for navKey, data in pairs(NavButtons) do
        local selected = navKey == key
        data.Accent.Visible = selected
        data.Label.TextColor3 = selected and C.TEXT or C.MUTED
        tween(data.Button, 0.15, {
            BackgroundColor3 = selected and Color3.fromRGB(30, 42, 68) or C.SIDEBAR,
        })
    end

    for navKey, data in pairs(MobileNavButtons) do
        local selected = navKey == key
        data.Accent.Visible = selected
        data.Label.TextColor3 = selected and C.TEXT or C.MUTED
        tween(data.Button, 0.15, {
            BackgroundColor3 = selected and Color3.fromRGB(34, 48, 76) or C.CARD,
        })
    end
end

updateStaticUI = function()
    Version.Text = T("SUBTITLE")
    StatusText.Text = T("ONLINE")
    Navigation.Text = T("NAVIGATION")
    FooterStatus.Text = T("ACTIVE")

    for key, data in pairs(NavButtons) do
        data.Label.Text = T(NAV_TRANSLATION_KEYS[key])
    end

    for key, data in pairs(MobileNavButtons) do
        data.Label.Text = T(NAV_TRANSLATION_KEYS[key])
    end

    refreshAllESP()
end


--==============================================================
-- STAMP SAFETY V20 - MANUAL ASSIST + FULL AUTO / FAIL-CLOSED
--
-- MANUAL mode: Begin stays manual; safe targets are stacked, skulls are blocked.
-- AUTO mode: Begin is activated automatically when visible; safe targets are clicked automatically.
-- In BOTH modes:
--   * EVERY ImageButton named "Template" is a SAFE target.
--   * ALL safe Templates are forced to ONE fixed large position.
--   * EVERY ImageButton named "Danger" is hidden/disabled.
--   * Empty is NEVER touched.
--
-- IMPORTANT:
-- This section is intentionally stored in ONE table instead of dozens
-- of top-level locals. Older V15/V16/V17 builds exceeded Luau's local
-- register limit and therefore never loaded at all.
--==============================================================

local Safe = {
    Originals = setmetatable({}, {__mode = "k"}),
    BindName = "WOLF_SAFE_V20_" .. tostring(LP.UserId),
    DangerImage = "rbxassetid://2766332187",
    Position = UDim2.fromScale(0.18, 0.50),
    Size = UDim2.fromOffset(IS_TOUCH and 260 or 230, IS_TOUCH and 260 or 230),
    Bound = false,
    LastSafe = -1,
    LastDanger = -1,
    ClickBusy = false,
    ClickGeneration = 0,
    ClickDelay = IS_TOUCH and 0.070 or 0.050,
    BeginGeneration = 0,
    BeginBusy = false,
    LastBeginAttempt = 0,
}

function Safe.enabled()
    return App.Active and (App.SafeStampManual or App.AutoStamp)
end

function Safe.isFrame(frame)
    if not frame or not frame:IsA("Frame") then
        return false
    end

    local minigame = frame.Parent
    return minigame
        and minigame:IsA("ScreenGui")
        and minigame.Name == "Minigame"
        and minigame.Parent == PlayerGui
        and frame.Name == "Frame"
end

function Safe.getFrame()
    local minigame = PlayerGui:FindFirstChild("Minigame")
    local frame = minigame and minigame:FindFirstChild("Frame")
    return Safe.isFrame(frame) and frame or nil
end

function Safe.image(button)
    if not button or not button:IsA("ImageButton") then
        return ""
    end

    -- Some builds store the icon directly on the ImageButton, others in an ImageLabel.
    local ownImage = tostring(button.Image or "")
    if ownImage ~= "" then
        return ownImage
    end

    local image = button:FindFirstChildWhichIsA("ImageLabel", true)
    return image and tostring(image.Image) or ""
end

function Safe.isSafe(button)
    -- DANGER CHECK IS INTENTIONALLY PART OF THE SAFE TEST.
    -- Even if a future game update accidentally names a skull "Template",
    -- the known skull image is still rejected before any click can happen.
    return button
        and button:IsA("ImageButton")
        and Safe.isFrame(button.Parent)
        and button.Name == "Template"
        and Safe.image(button) ~= Safe.DangerImage
end

function Safe.isDanger(button)
    return button
        and button:IsA("ImageButton")
        and Safe.isFrame(button.Parent)
        and (button.Name == "Danger" or Safe.image(button) == Safe.DangerImage)
end

function Safe.remember(gui)
    if not gui or Safe.Originals[gui] then
        return
    end

    Safe.Originals[gui] = {
        Visible = gui.Visible,
        Active = gui.Active,
        Selectable = gui.Selectable,
        ZIndex = gui.ZIndex,
        Position = gui.Position,
        Size = gui.Size,
        AnchorPoint = gui.AnchorPoint,
        Rotation = gui.Rotation,
    }
end

function Safe.force(button, index)
    if not Safe.enabled() or not Safe.isSafe(button) then
        return
    end

    Safe.remember(button)

    -- Move the REAL game button, not a clone. This keeps its native input
    -- connection while making every random spawn appear at one location.
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = Safe.Position
    button.Size = Safe.Size
    button.Visible = true
    button.Active = true
    button.ZIndex = 900 + (index or 1)
    button.Rotation = 0
end

function Safe.killDanger(button)
    if not Safe.enabled() or not Safe.isDanger(button) then
        return
    end

    Safe.remember(button)
    button.Visible = false
    button.Active = false
    button.Selectable = false
    button.ZIndex = -100
end

function Safe.inputClick(button)
    if not button or not button.Parent or not button.Visible then
        return false
    end

    -- Final fail-closed validation immediately before input injection.
    if Safe.isDanger(button) or not Safe.isSafe(button) then
        return false
    end

    local center = button.AbsolutePosition + (button.AbsoluteSize * 0.5)
    local x = math.floor(center.X + 0.5)
    local y = math.floor(center.Y + 0.5)

    if VirtualInputManager then
        local ok = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.012)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
        if ok then
            return true
        end
    end

    -- Fallback for environments where VirtualInputManager is unavailable.
    local camera = workspace.CurrentCamera
    local ok = pcall(function()
        VirtualUser:Button1Down(Vector2.new(x, y), camera and camera.CFrame or CFrame.new())
        task.wait(0.012)
        VirtualUser:Button1Up(Vector2.new(x, y), camera and camera.CFrame or CFrame.new())
    end)
    return ok
end

function Safe.isBeginPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then
        return false
    end

    local action = normalize(prompt.ActionText)

    -- Fail closed: only a prompt whose visible action is explicitly "Begin" is eligible.
    return action == "begin"
end

function Safe.triggerBegin(prompt)
    if Safe.BeginBusy
        or not App.Active
        or not App.AutoStamp
        or stampMinigameIsActive()
        or not Safe.isBeginPrompt(prompt) then
        return false
    end

    local now = os.clock()
    if now - Safe.LastBeginAttempt < 0.45 then
        return false
    end

    Safe.LastBeginAttempt = now
    Safe.BeginBusy = true
    local ok = false

    -- Preferred executor path: trigger the exact visible ProximityPrompt.
    if type(fireproximityprompt) == "function" then
        ok = pcall(function()
            fireproximityprompt(prompt)
        end)
    end

    -- Native prompt input fallback. This keeps the action scoped to THIS prompt.
    if not ok then
        ok = pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.max(0.03, tonumber(prompt.HoldDuration) or 0))
            prompt:InputHoldEnd()
        end)
    end

    -- Last fallback for environments where prompt methods are blocked.
    if not ok and VirtualInputManager then
        local key = prompt.KeyboardKeyCode
        if key and key ~= Enum.KeyCode.Unknown then
            ok = pcall(function()
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(math.max(0.04, tonumber(prompt.HoldDuration) or 0))
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end)
        end
    end

    task.delay(0.12, function()
        Safe.BeginBusy = false
    end)

    return ok
end

function Safe.tryVisibleBegin()
    if not App.Active or not App.AutoStamp or stampMinigameIsActive() then
        return false
    end

    for prompt in pairs(App.VisiblePrompts) do
        if prompt and prompt.Parent and Safe.isBeginPrompt(prompt) then
            return Safe.triggerBegin(prompt)
        end
    end

    return false
end

function Safe.startAutoBeginLoop()
    Safe.BeginGeneration += 1
    local generation = Safe.BeginGeneration

    task.spawn(function()
        while App.Active and App.AutoStamp and generation == Safe.BeginGeneration do
            if not stampMinigameIsActive() then
                pcall(Safe.tryVisibleBegin)
            end
            task.wait(0.12)
        end
    end)
end

function Safe.pickSafeTarget()
    local frame = Safe.getFrame()
    if not frame then
        return nil
    end

    local best = nil
    local bestZ = -math.huge

    -- Dangers are never candidates. Choose only a verified Template.
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("ImageButton")
            and child.Visible
            and not Safe.isDanger(child)
            and Safe.isSafe(child) then
            local z = tonumber(child.ZIndex) or 0
            if not best or z > bestZ then
                best = child
                bestZ = z
            end
        end
    end

    return best
end

function Safe.clickOne()
    if Safe.ClickBusy
        or not App.Active
        or not App.AutoStamp
        or not stampMinigameIsActive() then
        return false
    end

    local target = Safe.pickSafeTarget()
    if not target then
        return false
    end

    Safe.ClickBusy = true
    local ok = false

    -- Re-verify after selection because the game can replace buttons at any frame.
    if target.Parent and target.Visible and not Safe.isDanger(target) and Safe.isSafe(target) then
        ok = Safe.inputClick(target)
    end

    task.delay(Safe.ClickDelay, function()
        Safe.ClickBusy = false
    end)

    return ok
end

function Safe.startAutoClickLoop()
    Safe.ClickGeneration += 1
    local generation = Safe.ClickGeneration

    task.spawn(function()
        while App.Active and App.AutoStamp and generation == Safe.ClickGeneration do
            if stampMinigameIsActive() then
                pcall(Safe.enforce)
                pcall(Safe.clickOne)
            else
                Safe.ClickBusy = false
            end
            task.wait(PERF.SAFE_AUTO_TICK)
        end
    end)
end

function Safe.enforce()
    if not Safe.enabled() or not stampMinigameIsActive() then
        return
    end

    local frame = Safe.getFrame()
    if not frame then
        return
    end

    local safeCount = 0
    local dangerCount = 0

    -- First remove every skull, then stack every safe target.
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("ImageButton") and Safe.isDanger(child) then
            dangerCount += 1
            pcall(Safe.killDanger, child)
        end
    end

    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("ImageButton") and Safe.isSafe(child) then
            safeCount += 1
            pcall(Safe.force, child, safeCount)
        end
    end

    if safeCount ~= Safe.LastSafe or dangerCount ~= Safe.LastDanger then
        Safe.LastSafe = safeCount
        Safe.LastDanger = dangerCount
    end
end

function Safe.bind()
    if not Safe.Bound then
        Safe.Bound = true

        pcall(function()
            RunService:UnbindFromRenderStep(Safe.BindName)
        end)

        -- Always enforce the safety geometry while either stamp mode is enabled.
        RunService:BindToRenderStep(
            Safe.BindName,
            Enum.RenderPriority.Last.Value,
            function()
                if Safe.enabled() then
                    pcall(Safe.enforce)
                end
            end
        )
    end

    if App.AutoStamp then
        Safe.startAutoClickLoop()
        Safe.startAutoBeginLoop()
        pcall(Safe.tryVisibleBegin)
    end
end

function Safe.restore()
    Safe.ClickGeneration += 1
    Safe.BeginGeneration += 1
    Safe.ClickBusy = false
    Safe.BeginBusy = false

    if Safe.Bound then
        pcall(function()
            RunService:UnbindFromRenderStep(Safe.BindName)
        end)
        Safe.Bound = false
    end

    for gui, original in pairs(Safe.Originals) do
        if gui and gui.Parent then
            pcall(function()
                gui.Visible = original.Visible
                gui.Active = original.Active
                gui.Selectable = original.Selectable
                gui.ZIndex = original.ZIndex
                gui.Position = original.Position
                gui.Size = original.Size
                gui.AnchorPoint = original.AnchorPoint
                gui.Rotation = original.Rotation
            end)
        end
    end

    Safe.Originals = setmetatable({}, {__mode = "k"})
    Safe.LastSafe = -1
    Safe.LastDanger = -1
end

function Safe.setManual(state, silent)
    App.SafeStampManual = state == true

    if App.SafeStampManual then
        Safe.bind()
        pcall(Safe.enforce)
    elseif not App.AutoStamp then
        Safe.restore()
    end

    if not silent then
        notifyState(T("SAFE_STAMP_MANUAL"), App.SafeStampManual)
    end
end

local function setAutoStamp(state, silent)
    App.AutoStamp = state == true

    if App.AutoStamp then
        Safe.bind()
        pcall(Safe.enforce)
        pcall(Safe.tryVisibleBegin)
    else
        -- Stop only the automatic workers. Keep manual protection alive if enabled.
        Safe.ClickGeneration += 1
        Safe.BeginGeneration += 1
        Safe.ClickBusy = false
        Safe.BeginBusy = false
        if not App.SafeStampManual then
            Safe.restore()
        end
    end

    if not silent then
        notifyState(T("AUTO_STAMP"), App.AutoStamp)
    end
end

-- Catch newly created random buttons immediately. RenderStep remains the
-- authoritative enforcement, so this only reduces visual delay.
track(PlayerGui.DescendantAdded:Connect(function(obj)
    if not Safe.enabled() or not obj:IsA("ImageButton") then
        return
    end

    task.defer(function()
        if Safe.enabled() and obj.Parent then
            if Safe.isDanger(obj) then
                pcall(Safe.killDanger, obj)
            elseif Safe.isSafe(obj) then
                pcall(Safe.force, obj, 999)
            end
        end
    end)
end))

-- If AUTO STAMP is enabled while a Begin prompt appears, trigger it immediately.
track(PPS.PromptShown:Connect(function(prompt)
    if App.Active and App.AutoStamp and Safe.isBeginPrompt(prompt) then
        task.defer(function()
            if App.Active and App.AutoStamp and prompt and prompt.Parent then
                pcall(Safe.triggerBegin, prompt)
            end
        end)
    end
end))

--==============================================================
-- AUTO SURGERY V28 - FAST + 1.5S SAFE ADVANCE / REGISTER-SAFE
--
-- Learned from WOLF_SURGERY_SCAN_20260829_125447:
--   1) The normal PlayerGui Objective is NOT the authoritative surgery task.
--   2) The operating-room TV exposes exact required treatments here:
--        Room.Minigame.TV.Screen.UI.Report.inv
--   3) Each required entry contains:
--        .name  -> exact treatment name
--        .check -> Visible=true once that treatment was accepted
--   4) The matching pickup prompt is:
--        Room.Minigame.Medicine.Model.<Treatment>.PP
--   5) The patient treatment prompt is:
--        Room.Minigame.Bed.InBed.PP  ("Apply Treatment")
--
-- The engine therefore does NOT guess from screen text, images, remotes, or
-- unrelated objectives anymore. It follows the exact active surgery board.
--==============================================================

do
    local Surgery = {
        Generation = 0,
        Busy = false,
        LastRoom = "",
        LastNeed = "",
        LastLogAt = 0,
        LastErrorAt = 0,
        Tick = IS_TOUCH and 0.085 or 0.045,
        RoomDistance = 130,
        AcquireTimeout = 0.90,
        ApplyEnableTimeout = 1.20,
        ResultTimeout = 1.60,

        -- After a treatment is applied, NEVER pick the same treatment again
        -- until the board advances. Minimum delay requested by user: 1.5 sec.
        AdvanceDelay = 1.50,
        AwaitingAdvanceName = nil,
        AwaitingAdvanceNode = nil,
        AdvanceNotBefore = 0,
    }

    -- Exact item registry confirmed by manual scan + screenshots.
    -- Name = board text = prompt ActionText = tool name.
    Surgery.Items = {
        ["transplant"]  = {Name = "Transplant",  Image = "rbxassetid://137637637347521"},
        ["bandages"]    = {Name = "Bandages",    Image = "rbxassetid://84839702164032"},
        ["antibiotics"] = {Name = "Antibiotics", Image = "rbxassetid://132258407294719"},
        ["scalpel"]     = {Name = "Scalpel",     Image = ""},
        ["ivdrops"]     = {Name = "IV Drops",    Image = "rbxassetid://118311058179090"},
        ["medkit"]      = {Name = "Medkit",      Image = ""},
        ["medicine"]    = {Name = "Medicine",    Image = "rbxassetid://135236061613718"},
        ["organ"]       = {Name = "Organ",       Image = "rbxassetid://102550407034117"},
        ["scissors"]    = {Name = "Scissors",    Image = ""},
    }

    function Surgery.registry(name)
        return Surgery.Items[Surgery.norm(name)]
    end

    function Surgery.norm(value)
        return string.lower(tostring(value or "")):gsub("[^%w]+", "")
    end

    function Surgery.root()
        local character = LP.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    function Surgery.humanoid()
        local character = LP.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end

    function Surgery.partOf(object)
        if not object then
            return nil
        end

        if object:IsA("BasePart") then
            return object
        end

        if object:IsA("Attachment") then
            return object.Parent and object.Parent:IsA("BasePart") and object.Parent or nil
        end

        local part = object:FindFirstAncestorWhichIsA("BasePart")
        if part then
            return part
        end

        local model = object:FindFirstAncestorOfClass("Model")
        if model then
            return model.PrimaryPart
                or model:FindFirstChild("HumanoidRootPart")
                or model:FindFirstChildWhichIsA("BasePart", true)
        end

        return nil
    end

    function Surgery.distanceTo(object)
        local root = Surgery.root()
        local part = Surgery.partOf(object)

        if not root or not part then
            return math.huge
        end

        return (root.Position - part.Position).Magnitude
    end

    function Surgery.guiChainVisible(object)
        local current = object

        while current do
            if current:IsA("GuiObject") and current.Visible == false then
                return false
            end

            if (current:IsA("SurfaceGui") or current:IsA("BillboardGui") or current:IsA("ScreenGui"))
                and current.Enabled == false then
                return false
            end

            current = current.Parent
        end

        return true
    end

    function Surgery.roomData(room)
        if not room or not room.Parent then
            return nil
        end

        local minigame = room:FindFirstChild("Minigame")
        if not minigame then
            return nil
        end

        local tv = minigame:FindFirstChild("TV")
        local screen = tv and tv:FindFirstChild("Screen")
        local ui = screen and screen:FindFirstChild("UI")
        local report = ui and ui:FindFirstChild("Report")
        local inv = report and report:FindFirstChild("inv")

        local bed = minigame:FindFirstChild("Bed")
        local inBed = bed and bed:FindFirstChild("InBed")
        local patientPrompt = inBed and inBed:FindFirstChild("PP")

        local medicine = minigame:FindFirstChild("Medicine")
        local medicineModel = medicine and medicine:FindFirstChild("Model")

        if not report or not inv or not patientPrompt or not medicineModel then
            return nil
        end

        return {
            Room = room,
            Minigame = minigame,
            TV = tv,
            UI = ui,
            Report = report,
            Inv = inv,
            PatientPrompt = patientPrompt,
            MedicineModel = medicineModel,
        }
    end

    function Surgery.requiredEntries(data)
        local result = {}

        if not data or not data.Inv or not data.Inv.Parent then
            return result
        end

        for _, entry in ipairs(data.Inv:GetChildren()) do
            local nameLabel = entry:FindFirstChild("name")
            local check = entry:FindFirstChild("check")

            local entryUsable = true
            if entry:IsA("GuiObject") and entry.Visible == false then
                entryUsable = false
            end

            if entryUsable and nameLabel and nameLabel:IsA("TextLabel") then
                local itemName = tostring(nameLabel.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")

                if itemName ~= "" and Surgery.registry(itemName) then
                    local done = false
                    if check and check:IsA("GuiObject") then
                        done = check.Visible == true
                    end

                    local icon = entry:FindFirstChild("icon")
                    local iconImage = ""
                    if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
                        iconImage = tostring(icon.Image or "")
                    end

                    result[#result + 1] = {
                        Node = entry,
                        Name = itemName,
                        Key = Surgery.norm(itemName),
                        Check = check,
                        Icon = icon,
                        IconImage = iconImage,
                        Done = done,
                        Order = tonumber(entry.LayoutOrder) or 0,
                    }
                end
            end
        end

        table.sort(result, function(a, b)
            if a.Order == b.Order then
                return a.Name < b.Name
            end
            return a.Order < b.Order
        end)

        return result
    end

    function Surgery.unfinishedCount(data)
        local count = 0
        for _, req in ipairs(Surgery.requiredEntries(data)) do
            if not req.Done then
                count += 1
            end
        end
        return count
    end

    function Surgery.activeRoom()
        local rooms = workspace:FindFirstChild("Rooms")
        local emergency = rooms and rooms:FindFirstChild("Emergency")

        if not emergency then
            return nil
        end

        local best = nil
        local bestDistance = math.huge

        for _, room in ipairs(emergency:GetChildren()) do
            local data = Surgery.roomData(room)

            if data then
                local requirements = Surgery.requiredEntries(data)

                if #requirements > 0 then
                    local distance = Surgery.distanceTo(
                        data.PatientPrompt.Parent or data.PatientPrompt
                    )

                    -- Prefer a nearby room that actually has an active report.
                    -- Report visibility is a bonus, but requirements are the
                    -- authoritative signal because some builds keep parent
                    -- frames visible state unusual while surgery is running.
                    local reportVisible = Surgery.guiChainVisible(data.Report)
                    local weightedDistance = distance + (reportVisible and 0 or 25)

                    if distance <= Surgery.RoomDistance and weightedDistance < bestDistance then
                        best = data
                        bestDistance = weightedDistance
                    end
                end
            end
        end

        return best
    end

    function Surgery.findTool(itemName)
        local wanted = Surgery.norm(itemName)
        local character = LP.Character
        local backpack = LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")

        local function scan(container, equipped)
            if not container then
                return nil, false
            end

            -- Direct children first.
            for _, object in ipairs(container:GetChildren()) do
                if object:IsA("Tool") and Surgery.norm(object.Name) == wanted then
                    return object, equipped
                end
            end

            -- Some inventory implementations nest tools in folders.
            for _, object in ipairs(container:GetDescendants()) do
                if object:IsA("Tool") and Surgery.norm(object.Name) == wanted then
                    return object, equipped
                end
            end

            return nil, false
        end

        local tool, equipped = scan(character, true)
        if tool then
            return tool, equipped
        end

        tool, equipped = scan(backpack, false)
        if tool then
            return tool, equipped
        end

        return nil, false
    end

    function Surgery.findExactPrompt(data, itemName)
        if not data or not data.Room then
            return nil
        end

        local reg = Surgery.registry(itemName)
        if not reg then
            return nil
        end

        local wanted = Surgery.norm(reg.Name)

        -- Pass 1: exact ActionText in current room. This is the authoritative
        -- lookup because the screenshots/manual scan show each table item has
        -- its own E prompt carrying the exact treatment name.
        for _, object in ipairs(data.Room:GetDescendants()) do
            if object:IsA("ProximityPrompt")
                and object ~= data.PatientPrompt
                and Surgery.norm(object.ActionText) == wanted then
                return object
            end
        end

        -- Pass 2: exact item-node name with PP below it.
        for _, object in ipairs(data.Room:GetDescendants()) do
            if Surgery.norm(object.Name) == wanted then
                local pp = object:FindFirstChildWhichIsA("ProximityPrompt", true)
                if pp and pp ~= data.PatientPrompt then
                    return pp
                end
            end
        end

        -- Pass 3: known rack path from the scan.
        if data.MedicineModel and data.MedicineModel.Parent then
            for _, object in ipairs(data.MedicineModel:GetChildren()) do
                if Surgery.norm(object.Name) == wanted then
                    local pp = object:FindFirstChild("PP")
                        or object:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if pp then
                        return pp
                    end
                end
            end
        end

        return nil
    end

    function Surgery.waitPickupPrompt(data, req, timeout)
        local deadline = os.clock() + (timeout or 1.25)

        while App.Active and App.AutoSurgery and os.clock() < deadline do
            local pp = Surgery.findExactPrompt(data, req.Name)
            if pp and pp.Parent then
                return pp
            end

            -- Rack references can be reconstructed between stages.
            local fresh = Surgery.roomData(data.Room)
            if fresh then
                data.Minigame = fresh.Minigame
                data.TV = fresh.TV
                data.UI = fresh.UI
                data.Report = fresh.Report
                data.Inv = fresh.Inv
                data.PatientPrompt = fresh.PatientPrompt
                data.MedicineModel = fresh.MedicineModel
            end

            task.wait(0.02)
        end

        return nil
    end

    function Surgery.debugRoomPrompts(data, req)
        if not data or not data.Room or not req then
            return
        end

        local rows = {}
        for _, object in ipairs(data.Room:GetDescendants()) do
            if object:IsA("ProximityPrompt") then
                rows[#rows + 1] =
                    tostring(object.ActionText)
                    .. " @ "
                    .. object:GetFullName()
            end
        end

        warn(
            "[WOLF][SURGERY V28] Exact registry lookup failed for "
            .. tostring(req.Name)
            .. " | icon="
            .. tostring(req.IconImage)
            .. " | room prompts: "
            .. table.concat(rows, " || ")
        )
    end

    function Surgery.trigger(prompt)
        if not prompt or not prompt.Parent or not prompt.Enabled then
            return false
        end

        local ok = false

        if type(fireproximityprompt) == "function" then
            ok = pcall(function()
                fireproximityprompt(prompt)
            end)

        end

        if not ok then
            ok = pcall(function()
                prompt:InputHoldBegin()
                task.wait(math.max(0.03, tonumber(prompt.HoldDuration) or 0))
                prompt:InputHoldEnd()
            end)
        end

        if not ok and VirtualInputManager then
            local key = prompt.KeyboardKeyCode
            if key and key ~= Enum.KeyCode.Unknown then
                ok = pcall(function()
                    VirtualInputManager:SendKeyEvent(true, key, false, game)
                    task.wait(math.max(0.04, tonumber(prompt.HoldDuration) or 0))
                    VirtualInputManager:SendKeyEvent(false, key, false, game)
                end)
            end
        end

        return ok
    end

    function Surgery.equip(tool)
        if not tool or not tool.Parent then
            return false
        end

        local character = LP.Character
        if character and tool.Parent == character then
            return true
        end

        local humanoid = Surgery.humanoid()
        if not humanoid then
            return false
        end

        local ok = pcall(function()
            humanoid:EquipTool(tool)
        end)

        if ok then
            task.wait(0.025)
        end

        return character and tool.Parent == character
    end

    function Surgery.waitForTool(itemName, timeout)
        local deadline = os.clock() + (timeout or Surgery.AcquireTimeout)

        while App.Active and App.AutoSurgery and os.clock() < deadline do
            local tool, equipped = Surgery.findTool(itemName)
            if tool then
                return tool, equipped
            end
            task.wait(0.015)
        end

        return nil, false
    end

    function Surgery.waitPatientEnabled(data, timeout)
        local deadline = os.clock() + (timeout or Surgery.ApplyEnableTimeout)

        while App.Active and App.AutoSurgery and os.clock() < deadline do
            local pp = data and data.PatientPrompt

            if pp and pp.Parent and pp.Enabled then
                return pp
            end

            task.wait(0.015)
        end

        return nil
    end

    function Surgery.requirementResolved(req)
        if not req then
            return true
        end

        if not req.Node or not req.Node.Parent then
            return true
        end

        if req.Check and req.Check.Parent and req.Check.Visible == true then
            return true
        end

        return false
    end

    function Surgery.waitResult(req, oldTool, timeout)
        local deadline = os.clock() + (timeout or Surgery.ResultTimeout)

        while App.Active and App.AutoSurgery and os.clock() < deadline do
            if Surgery.requirementResolved(req) then
                return true
            end

            if oldTool and not oldTool.Parent then
                -- Tool consumption is a strong server-side acknowledgement.
                -- Do not waste surgery time waiting for a slow board animation.
                task.wait(0.025)

                if Surgery.requirementResolved(req) then
                    return true
                end

                return true
            end

            task.wait(0.015)
        end

        return Surgery.requirementResolved(req)
    end

    function Surgery.log(message, force)
        -- Quiet mode: no routine surgery console output.
        Surgery.LastLogAt = os.clock()
    end

    function Surgery.fail(message)
        if os.clock() - Surgery.LastErrorAt > 2.5 then
            Surgery.LastErrorAt = os.clock()
            warn("[WOLF][SURGERY V28]", message)
        end
    end

    function Surgery.boardAdvanced(data)
        if not Surgery.AwaitingAdvanceName then
            return true
        end

        -- Always respect the requested 1.5 second minimum delay.
        if os.clock() < Surgery.AdvanceNotBefore then
            return false
        end

        local waitingName = Surgery.AwaitingAdvanceName
        local waitingNode = Surgery.AwaitingAdvanceNode

        -- If the exact old board node disappeared, the board advanced.
        if waitingNode and (not waitingNode.Parent) then
            Surgery.AwaitingAdvanceName = nil
            Surgery.AwaitingAdvanceNode = nil
            return true
        end

        -- If the old item is now checked, the board advanced.
        if waitingNode and waitingNode.Parent then
            local check = waitingNode:FindFirstChild("check")
            if check and check:IsA("GuiObject") and check.Visible == true then
                Surgery.AwaitingAdvanceName = nil
                Surgery.AwaitingAdvanceNode = nil
                return true
            end
        end

        -- Re-read the real board. If the first unfinished treatment changed,
        -- it is safe to continue immediately.
        local firstPending = nil
        for _, entry in ipairs(Surgery.requiredEntries(data)) do
            if not entry.Done then
                firstPending = entry
                break
            end
        end

        if not firstPending then
            Surgery.AwaitingAdvanceName = nil
            Surgery.AwaitingAdvanceNode = nil
            return true
        end

        if Surgery.norm(firstPending.Name) ~= Surgery.norm(waitingName) then
            Surgery.AwaitingAdvanceName = nil
            Surgery.AwaitingAdvanceNode = nil
            return true
        end

        -- Same treatment is still shown: DO NOT take another copy.
        return false
    end

    function Surgery.processRequirement(data, req)
        if not data or not req or req.Done then
            return
        end

        Surgery.Busy = true
        Surgery.LastRoom = data.Room.Name
        Surgery.LastNeed = req.Name

        local tool, equipped = Surgery.findTool(req.Name)

        if not tool then
            local pickup = Surgery.waitPickupPrompt(data, req, 5.0)

            if not pickup then
                Surgery.debugRoomPrompts(data, req)
                Surgery.fail(
                    "No exact registered prompt for "
                    .. tostring(req.Name)
                    .. " in "
                    .. tostring(data.Room.Name)
                )
                Surgery.Busy = false
                return
            end

            Surgery.log(
                "TAKE "
                .. tostring(req.Name)
                .. " | room="
                .. tostring(data.Room.Name),
                true
            )

            if not pickup.Enabled then
                local enableDeadline = os.clock() + 0.45
                while App.Active and App.AutoSurgery
                    and pickup.Parent
                    and not pickup.Enabled
                    and os.clock() < enableDeadline do
                    task.wait(0.015)
                end
            end

            if not Surgery.trigger(pickup) then
                Surgery.fail(
                    "Could not trigger pickup: "
                    .. tostring(req.Name)
                    .. " | ActionText="
                    .. tostring(pickup.ActionText)
                )
                Surgery.Busy = false
                return
            end

            tool, equipped = Surgery.waitForTool(req.Name, Surgery.AcquireTimeout)

            if not tool then
                Surgery.fail(
                    "Pickup fired but tool was not acquired: "
                    .. tostring(req.Name)
                )
                Surgery.Busy = false
                return
            end
        end

        if not equipped then
            equipped = Surgery.equip(tool)
        end

        if not equipped then
            Surgery.fail("Could not equip treatment: " .. tostring(req.Name))
            Surgery.Busy = false
            return
        end

        -- The real patient action learned from the scan.
        local patientPrompt = data.PatientPrompt

        if not patientPrompt or not patientPrompt.Parent or not patientPrompt.Enabled then
            patientPrompt = Surgery.waitPatientEnabled(data, Surgery.ApplyEnableTimeout)
        end

        if not patientPrompt then
            Surgery.fail(
                "Apply Treatment did not enable for "
                .. tostring(req.Name)
            )
            Surgery.Busy = false
            return
        end

        Surgery.log(
            "APPLY "
            .. tostring(req.Name)
            .. " -> patient | room="
            .. tostring(data.Room.Name),
            true
        )

        if not Surgery.trigger(patientPrompt) then
            Surgery.fail("Could not trigger Apply Treatment")
            Surgery.Busy = false
            return
        end

        local accepted = Surgery.waitResult(req, tool, Surgery.ResultTimeout)

        if accepted then
            Surgery.log(
                "ACCEPTED "
                .. tostring(req.Name)
                .. " | room="
                .. tostring(data.Room.Name)
                .. " | waiting 1.5s for board advance",
                true
            )

            -- Hard anti-duplicate lock:
            -- even if the board still shows the same item for a moment,
            -- never pick another copy of it.
            Surgery.AwaitingAdvanceName = req.Name
            Surgery.AwaitingAdvanceNode = req.Node
            Surgery.AdvanceNotBefore = os.clock() + Surgery.AdvanceDelay
        else
            Surgery.fail(
                "No board confirmation for "
                .. tostring(req.Name)
                .. " after Apply Treatment"
            )
        end

        Surgery.Busy = false
    end

    function Surgery.step()
        if not App.Active or not App.AutoSurgery or Surgery.Busy then
            return
        end

        local data = Surgery.activeRoom()
        if not data then
            Surgery.log("Waiting for an active surgery board...")
            return
        end

        local entries = Surgery.requiredEntries(data)
        if #entries == 0 then
            return
        end

        local pending = nil
        local unfinished = 0

        for _, req in ipairs(entries) do
            if not req.Done then
                unfinished += 1
                if not pending then
                    pending = req
                end
            end
        end

        if not pending then
            Surgery.AwaitingAdvanceName = nil
            Surgery.AwaitingAdvanceNode = nil
            Surgery.log(
                "All board treatments checked; waiting for recovery | room="
                .. tostring(data.Room.Name)
            )
            return
        end

        -- If we just applied this treatment, wait at least 1.5 seconds AND
        -- wait for the real board to advance. Never grab the same item twice.
        if Surgery.AwaitingAdvanceName then
            if not Surgery.boardAdvanced(data) then
                return
            end
        end

        -- One item at a time.
        Surgery.processRequirement(data, pending)
    end

    function Surgery.start()
        Surgery.Generation += 1
        local generation = Surgery.Generation

        task.spawn(function()
            while App.Active and App.AutoSurgery and generation == Surgery.Generation do
                local ok, err = pcall(Surgery.step)
                if not ok then
                    Surgery.fail("Runtime error: " .. tostring(err))
                    Surgery.Busy = false
                end
                task.wait(Surgery.Tick)
            end
        end)
    end

    function Surgery.stop()
        Surgery.Generation += 1
        Surgery.Busy = false
        Surgery.LastRoom = ""
        Surgery.LastNeed = ""
        Surgery.AwaitingAdvanceName = nil
        Surgery.AwaitingAdvanceNode = nil
        Surgery.AdvanceNotBefore = 0
    end

    function App.SetAutoSurgery(state, silent)
        App.AutoSurgery = state == true

        if App.AutoSurgery then
            Surgery.start()
        else
            Surgery.stop()
        end

        if not silent then
            notifyState(T("AUTO_SURGERY"), App.AutoSurgery)
        end
    end

end -- AUTO SURGERY V24 scan-driven register-safe scope

--==============================================================
-- AUTO COLOR MEMORY V37
-- LIVE PER-PATIENT recorder + verified replay.
--
-- The sequence is NEVER cached between patients.
-- Every new X-Ray sequence is learned again in real time.
--==============================================================

do
    local Memory = {
        Generation = 0,
        Connections = {},

        Room = nil,
        Minigame = nil,
        Colors = nil,
        Model = nil,
        Monitor = nil,
        BeginPrompt = nil,
        Notice = nil,

        Buttons = {},
        Sequence = {},

        Recording = false,
        Playing = false,
        Armed = false,

        LastFlashAt = 0,
        LastStartTry = 0,
        ArmedUntil = 0,

        LastBindCheck = 0,
        RebindInterval = 0.20,

        SequenceEndGap = 1.90,
        SameFlashDebounce = 0.18,
        StepTimeout = 1.55,
        BetweenSteps = 0.08,

        Debug = false,
        DebugState = "",
        DebugLastAt = 0,
    }

    -- Exact colors learned from the Room 6 scan.
    Memory.FixedColors = {
        [1] = Color3.fromRGB(196, 40, 28),   -- red
        [2] = Color3.fromRGB(91, 154, 76),   -- green
        [3] = Color3.fromRGB(0, 46, 204),    -- blue
        [4] = Color3.fromRGB(245, 205, 48),  -- yellow
        [5] = Color3.fromRGB(255, 0, 191),   -- pink
        [6] = Color3.fromRGB(4, 175, 236),   -- cyan
    }

    local VirtualUser = nil
    pcall(function()
        VirtualUser = game:GetService("VirtualUser")
    end)

    local GuiService = nil
    pcall(function()
        GuiService = game:GetService("GuiService")
    end)

    function Memory.debug(message)
        -- Quiet mode.
    end

    function Memory.state(message)
        -- Quiet mode.
    end


    function Memory.seqText()
        local out = {}
        for i, info in ipairs(Memory.Sequence) do
            out[i] = tostring(info.Number or "?")
        end
        return table.concat(out, " -> ")
    end

    function Memory.colorName(info)
        if not info then
            return "?"
        end

        local c = info.MainColor
        if typeof(c) ~= "Color3" then
            return tostring(info.Number or "?")
        end

        return string.format(
            "#%s RGB(%d,%d,%d)",
            tostring(info.Number or "?"),
            math.floor(c.R * 255 + 0.5),
            math.floor(c.G * 255 + 0.5),
            math.floor(c.B * 255 + 0.5)
        )
    end

    function Memory.disconnect()
        for _, c in ipairs(Memory.Connections) do
            pcall(function()
                c:Disconnect()
            end)
        end
        table.clear(Memory.Connections)
    end

    function Memory.connect(signal, callback)
        local ok, c = pcall(function()
            return signal:Connect(callback)
        end)

        if ok and c then
            Memory.Connections[#Memory.Connections + 1] = c
            return c
        end

        return nil
    end

    function Memory.root()
        local ch = LP.Character
        return ch and ch:FindFirstChild("HumanoidRootPart")
    end

    function Memory.partOf(obj)
        if not obj then return nil end

        if obj:IsA("BasePart") then
            return obj
        end

        if obj:IsA("Attachment") then
            return obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or nil
        end

        if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            local parent = obj.Parent

            if parent and parent:IsA("Attachment") then
                return parent.Parent and parent.Parent:IsA("BasePart") and parent.Parent or nil
            end

            if parent and parent:IsA("BasePart") then
                return parent
            end

            if parent and parent:IsA("Model") then
                return parent.PrimaryPart
                    or parent:FindFirstChild("Screen")
                    or parent:FindFirstChildWhichIsA("BasePart", true)
            end
        end

        local p = obj:FindFirstAncestorWhichIsA("BasePart")
        if p then
            return p
        end

        local model = obj:FindFirstAncestorWhichIsA("Model")
        if model then
            return model.PrimaryPart
                or model:FindFirstChild("Screen")
                or model:FindFirstChildWhichIsA("BasePart", true)
        end

        return nil
    end

    function Memory.distance(obj)
        local root = Memory.root()
        local part = Memory.partOf(obj)

        if not root or not part then
            return math.huge
        end

        return (root.Position - part.Position).Magnitude
    end

    function Memory.colorExact(a, b)
        if typeof(a) ~= "Color3" or typeof(b) ~= "Color3" then
            return false
        end

        return math.abs(a.R - b.R) <= 0.001
            and math.abs(a.G - b.G) <= 0.001
            and math.abs(a.B - b.B) <= 0.001
    end

    function Memory.colorDistance(a, b)
        if typeof(a) ~= "Color3" or typeof(b) ~= "Color3" then
            return math.huge
        end

        local dr = a.R - b.R
        local dg = a.G - b.G
        local db = a.B - b.B
        return math.sqrt(dr * dr + dg * dg + db * db)
    end

    function Memory.buttonNumber(button)
        if not button then
            return nil
        end

        -- Direct UI first.
        local ui = button:FindFirstChild("ui")
        if ui then
            local label = ui:FindFirstChildWhichIsA("TextLabel", true)
            if label then
                local n = tonumber(label.Text)
                if n and n >= 1 and n <= 6 then
                    return n
                end
            end
        end

        -- Robust descendant lookup.
        for _, obj in ipairs(button:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local n = tonumber(obj.Text)
                if n and n >= 1 and n <= 6 then
                    return n
                end
            end
        end

        return nil
    end

    function Memory.numberFromColor(color)
        if typeof(color) ~= "Color3" then
            return nil
        end

        local bestNumber = nil
        local bestDistance = math.huge

        for number, known in pairs(Memory.FixedColors) do
            local dr = color.R - known.R
            local dg = color.G - known.G
            local db = color.B - known.B
            local d = dr * dr + dg * dg + db * db

            if d < bestDistance then
                bestDistance = d
                bestNumber = number
            end
        end

        -- Exact/near-exact registry color only.
        if bestDistance <= 0.01 then
            return bestNumber
        end

        return nil
    end

    function Memory.collectButtons(model)
        local byNumber = {}

        if not model then
            return {}
        end

        -- The current build may nest buttons or remove ClickDetectors from
        -- inactive buttons. MainColor is enough to identify the physical pad.
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                local mainColor = obj:GetAttribute("MainColor")
                local number = Memory.buttonNumber(obj)

                if not number and typeof(mainColor) == "Color3" then
                    number = Memory.numberFromColor(mainColor)
                end

                if number and number >= 1 and number <= 6 then
                    if typeof(mainColor) ~= "Color3" then
                        mainColor = Memory.FixedColors[number]
                    end

                    local click = obj:FindFirstChildWhichIsA("ClickDetector", true)

                    -- Sometimes the interaction object is on a nearby parent.
                    if not click and obj.Parent then
                        click = obj.Parent:FindFirstChildWhichIsA("ClickDetector", true)
                    end

                    local boop = obj:FindFirstChild("boop", true)
                    if boop and not boop:IsA("Sound") then
                        boop = nil
                    end

                    local candidate = {
                        Button = obj,
                        MainColor = mainColor,
                        Number = number,
                        Click = click,
                        Sound = boop,
                    }

                    local old = byNumber[number]

                    -- Prefer a candidate that actually has a ClickDetector,
                    -- but keep the physical button even without one because
                    -- screen-input fallback can still click it.
                    if not old or (not old.Click and candidate.Click) then
                        byNumber[number] = candidate
                    end
                end
            end
        end

        local result = {}
        for number = 1, 6 do
            if byNumber[number] then
                result[#result + 1] = byNumber[number]
            end
        end

        return result
    end

    function Memory.buttonDiagnostic(model)
        if not model then
            return "model=nil"
        end

        local baseParts = 0
        local namedButtons = 0
        local mainColors = 0
        local clickDetectors = 0
        local numbered = 0

        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                baseParts += 1

                if obj.Name == "Button" then
                    namedButtons += 1
                end

                if typeof(obj:GetAttribute("MainColor")) == "Color3" then
                    mainColors += 1
                end

                if Memory.buttonNumber(obj) then
                    numbered += 1
                end
            elseif obj:IsA("ClickDetector") then
                clickDetectors += 1
            end
        end

        local siblingModels = 0
        for _, child in ipairs(model:GetChildren()) do
            if child:IsA("Model") and child.Name == "Model" then
                siblingModels += 1
            end
        end

        return string.format(
            "SiblingModels=%d BaseParts=%d namedButton=%d MainColor=%d numbered=%d ClickDetectors=%d",
            siblingModels,
            baseParts,
            namedButtons,
            mainColors,
            numbered,
            clickDetectors
        )
    end

    function Memory.readRoom(room)
        local minigame = room and room:FindFirstChild("Minigame")
        local colors = minigame and minigame:FindFirstChild("Colors")

        -- IMPORTANT:
        -- Room 6 has SIX sibling Models under Colors, all literally named
        -- "Model". Each one owns one colored Button. FindFirstChild("Model")
        -- therefore sees only 1/6. Treat Colors itself as the button container
        -- and recursively collect from every sibling Model.
        local model = colors

        local xray = minigame and minigame:FindFirstChild("xrayMonitor")
        local pp = xray and xray:FindFirstChild("PP")

        local screen = xray and xray:FindFirstChild("Screen")
        local ui = screen and screen:FindFirstChild("UI")
        local action = ui and ui:FindFirstChild("Action")
        local notice = action and action:FindFirstChild("notice")

        return minigame, colors, model, xray, pp, notice
    end

    function Memory.validModel(model)
        if not model then
            return false
        end

        return #Memory.collectButtons(model) >= 6
    end

    function Memory.isColorRoom(room)
        local _, _, model, xray, pp = Memory.readRoom(room)
        return Memory.validModel(model) and xray ~= nil and pp ~= nil
    end

    function Memory.findBestRoom()
        local rooms = workspace:FindFirstChild("Rooms")
        local emergency = rooms and rooms:FindFirstChild("Emergency")
        local room = emergency and emergency:FindFirstChild("Room6")

        if not room then
            Memory.state("ROOM6 NOT FOUND")
            return nil
        end

        local minigame, colors, model, xray, pp = Memory.readRoom(room)

        if not minigame then
            Memory.state("ROOM6 FOUND / MINIGAME MISSING")
            return nil
        end

        if not colors then
            Memory.state("ROOM6 FOUND / COLORS MISSING")
            return nil
        end

        if not model then
            Memory.state("ROOM6 FOUND / COLORS.MODEL MISSING")
            return nil
        end

        if not Memory.validModel(model) then
            local found = Memory.collectButtons(model)

            Memory.state(
                "ROOM6 FOUND / WAITING FOR 6 BUTTONS | resolved="
                .. tostring(#found)
                .. " | "
                .. Memory.buttonDiagnostic(model)
            )

            -- Room 6 itself is still valid. Return it so bind/watchdog can
            -- keep observing the model while Roblox finishes building it.
            return room
        end

        if not xray then
            Memory.state("ROOM6 FOUND / XRAY MONITOR MISSING")
            return nil
        end

        if not pp then
            Memory.state("ROOM6 FOUND / BEGIN X-RAY PP MISSING")
            return nil
        end

        Memory.state(
            "ROOM6 DETECTED | Begin X-Ray distance="
            .. string.format("%.2f", Memory.distance(pp))
        )

        return room
    end

    function Memory.capture(info)
        if not App.Active
            or not App.AutoColorMemory
            or Memory.Playing
            or not Memory.Armed then

            return
        end

        local now = os.clock()

        if now > Memory.ArmedUntil then
            Memory.Armed = false
            Memory.Recording = false
            return
        end

        if now - (info.LastCapturedAt or 0) < Memory.SameFlashDebounce then
            return
        end

        info.LastCapturedAt = now
        Memory.Sequence[#Memory.Sequence + 1] = info
        Memory.Recording = true
        Memory.LastFlashAt = now

        Memory.debug(
            "CAPTURE "
            .. Memory.colorName(info)
            .. " | position="
            .. tostring(#Memory.Sequence)
            .. " | sequence="
            .. Memory.seqText()
        )
    end

    function Memory.onButtonVisual(info)
        local button = info.Button
        if not button or not button.Parent then
            return
        end

        info.FeedbackSerial = (info.FeedbackSerial or 0) + 1

        if Memory.Playing then
            return
        end

        local exact = Memory.colorExact(button.Color, info.MainColor)

        if exact and not info.WasExact then
            info.WasExact = true
            Memory.capture(info)
        elseif not exact then
            info.WasExact = false
        end
    end

    function Memory.onButtonSound(info)
        info.FeedbackSerial = (info.FeedbackSerial or 0) + 1

        if Memory.Playing then
            return
        end

        Memory.capture(info)
    end

    function Memory.modelStillCurrent()
        if not Memory.Room or not Memory.Room.Parent then
            return false
        end

        local minigame, colors, model, xray, pp = Memory.readRoom(Memory.Room)

        if minigame ~= Memory.Minigame
            or colors ~= Memory.Colors
            or model ~= Memory.Model
            or xray ~= Memory.Monitor
            or pp ~= Memory.BeginPrompt then

            return false
        end

        if #Memory.Buttons < 6 then
            return false
        end

        for _, info in ipairs(Memory.Buttons) do
            if not info.Button or not info.Button.Parent then
                return false
            end
        end

        return true
    end

    function Memory.bind(room)
        Memory.disconnect()

        Memory.Room = nil
        Memory.Minigame = nil
        Memory.Colors = nil
        Memory.Model = nil
        Memory.Monitor = nil
        Memory.BeginPrompt = nil
        Memory.Notice = nil
        table.clear(Memory.Buttons)
        table.clear(Memory.Sequence)

        Memory.Recording = false
        Memory.Playing = false
        Memory.Armed = false
        Memory.ArmedUntil = 0
        Memory.LastFlashAt = 0

        if not room then
            return false
        end

        local minigame, colors, model, xray, pp, notice = Memory.readRoom(room)

        if not minigame
            or not colors
            or not model
            or not xray
            or not pp then

            Memory.debug("BIND FAILED | missing Room6 structure")
            return false
        end

        Memory.Room = room
        Memory.Minigame = minigame
        Memory.Colors = colors
        Memory.Model = model
        Memory.Monitor = xray
        Memory.BeginPrompt = pp
        Memory.Notice = notice

        local candidates = Memory.collectButtons(model)

        for _, candidate in ipairs(candidates) do
            local obj = candidate.Button

            local info = {
                Button = obj,
                MainColor = candidate.MainColor,
                Number = candidate.Number,
                Click = candidate.Click,
                Sound = candidate.Sound,

                WasExact = false,
                LastCapturedAt = 0,
                FeedbackSerial = 0,
            }

            Memory.Buttons[#Memory.Buttons + 1] = info

            Memory.connect(obj:GetPropertyChangedSignal("Color"), function()
                Memory.onButtonVisual(info)
            end)

            Memory.connect(obj:GetPropertyChangedSignal("BrickColor"), function()
                Memory.onButtonVisual(info)
            end)

            if info.Sound then
                Memory.connect(info.Sound.Played, function()
                    Memory.onButtonSound(info)
                end)

                Memory.connect(info.Sound.Ended, function()
                    info.FeedbackSerial = (info.FeedbackSerial or 0) + 1
                end)
            end
        end

        table.sort(Memory.Buttons, function(a, b)
            return (a.Number or 99) < (b.Number or 99)
        end)

        Memory.connect(colors.DescendantAdded, function()
            Memory.LastBindCheck = 0
        end)

        Memory.connect(colors.DescendantRemoving, function()
            Memory.LastBindCheck = 0
        end)

        if #Memory.Buttons >= 6 then
            Memory.state("ROOM6 READY / ALL 6 BUTTONS RESOLVED")

            local nums = {}
            for i, info in ipairs(Memory.Buttons) do
                nums[i] = Memory.colorName(info)
            end

            Memory.debug(
                "BOUND ROOM6 ALL COLOR MODELS | container="
                .. tostring(Memory.Model and Memory.Model:GetFullName() or "?")
                .. " | buttons="
                .. table.concat(nums, " | ")
            )
        else
            Memory.debug(
                "BIND WAITING room="
                .. tostring(room.Name)
                .. " | resolved="
                .. tostring(#Memory.Buttons)
                .. " | "
                .. Memory.buttonDiagnostic(model)
            )
        end

        return #Memory.Buttons >= 6
    end

    function Memory.triggerPrompt(prompt)
        if not prompt or not prompt.Parent or not prompt.Enabled then
            return false
        end

        local ok = false

        if type(fireproximityprompt) == "function" then
            ok = pcall(function()
                fireproximityprompt(prompt)
            end)
        end

        if not ok then
            ok = pcall(function()
                prompt:InputHoldBegin()
                task.wait(math.max(0.02, tonumber(prompt.HoldDuration) or 0))
                prompt:InputHoldEnd()
            end)

            if ok then
                Memory.debug("BEGIN X-RAY triggered with InputHoldBegin/End")
            end
        end

        if not ok then
            Memory.debug("BEGIN X-RAY trigger FAILED")
        end

        return ok
    end

    function Memory.screenPoint(part)
        local camera = workspace.CurrentCamera
        if not camera or not part then
            return nil
        end

        local point, visible = camera:WorldToViewportPoint(part.Position)

        if not visible or point.Z <= 0 then
            return nil
        end

        local x = point.X
        local y = point.Y

        if GuiService then
            pcall(function()
                local inset = GuiService:GetGuiInset()
                x += inset.X
                y += inset.Y
            end)
        end

        return Vector2.new(x, y)
    end

    function Memory.feedbackChanged(info, serial, timeout)
        local deadline = os.clock() + timeout

        while os.clock() < deadline do
            if (info.FeedbackSerial or 0) ~= serial then
                return true
            end

            task.wait(0.015)
        end

        return false
    end

    function Memory.directClick(info)
        if type(fireclickdetector) ~= "function"
            or not info
            or not info.Click
            or not info.Click.Parent then

            return false
        end

        local serial = info.FeedbackSerial or 0

        local ok = pcall(function()
            fireclickdetector(info.Click)
        end)

        if not ok then
            Memory.debug("fireclickdetector ERROR on " .. Memory.colorName(info))
            return false
        end

        local accepted = Memory.feedbackChanged(info, serial, 0.22)

        Memory.debug(
            "fireclickdetector "
            .. Memory.colorName(info)
            .. " -> "
            .. (accepted and "ACCEPTED" or "NO FEEDBACK")
        )

        return accepted
    end

    function Memory.vimClick(info)
        if not VirtualInputManager then
            return false
        end

        local point = Memory.screenPoint(info.Button)
        if not point then
            return false
        end

        local serial = info.FeedbackSerial or 0

        local ok = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(
                math.floor(point.X + 0.5),
                math.floor(point.Y + 0.5),
                0,
                true,
                game,
                0
            )

            task.wait(0.035)

            VirtualInputManager:SendMouseButtonEvent(
                math.floor(point.X + 0.5),
                math.floor(point.Y + 0.5),
                0,
                false,
                game,
                0
            )
        end)

        if not ok then
            Memory.debug("VIM click ERROR on " .. Memory.colorName(info))
            return false
        end

        local accepted = Memory.feedbackChanged(info, serial, 0.28)

        Memory.debug(
            "VIM click "
            .. Memory.colorName(info)
            .. " -> "
            .. (accepted and "ACCEPTED" or "NO FEEDBACK")
        )

        return accepted
    end

    function Memory.virtualUserClick(info)
        if not VirtualUser then
            return false
        end

        local point = Memory.screenPoint(info.Button)
        if not point then
            return false
        end

        local serial = info.FeedbackSerial or 0

        local ok = pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(point)
        end)

        if not ok then
            Memory.debug("VirtualUser click ERROR on " .. Memory.colorName(info))
            return false
        end

        local accepted = Memory.feedbackChanged(info, serial, 0.30)

        Memory.debug(
            "VirtualUser click "
            .. Memory.colorName(info)
            .. " -> "
            .. (accepted and "ACCEPTED" or "NO FEEDBACK")
        )

        return accepted
    end

    function Memory.fireButtonVerified(info)
        if not info
            or not info.Button
            or not info.Button.Parent then

            return false
        end

        Memory.state("REPLAY CLICK " .. Memory.colorName(info))

        if Memory.directClick(info) then
            Memory.debug("CLICK METHOD=fireclickdetector | " .. Memory.colorName(info))
            return true
        end

        if Memory.vimClick(info) then
            Memory.debug("CLICK METHOD=VirtualInputManager | " .. Memory.colorName(info))
            return true
        end

        if Memory.virtualUserClick(info) then
            Memory.debug("CLICK METHOD=VirtualUser | " .. Memory.colorName(info))
            return true
        end

        Memory.debug("ALL CLICK METHODS FAILED | " .. Memory.colorName(info))
        return false
    end

    function Memory.waitButtonSettled(info)
        local start = os.clock()
        local black = Color3.fromRGB(27, 42, 53)

        while os.clock() - start < Memory.StepTimeout do
            if not App.Active or not App.AutoColorMemory then
                return false
            end

            if not info.Button or not info.Button.Parent then
                return false
            end

            if os.clock() - start > 0.35
                and Memory.colorDistance(info.Button.Color, black) <= 0.035 then

                Memory.debug("BUTTON SETTLED " .. Memory.colorName(info))
                return true
            end

            task.wait(0.025)
        end

        Memory.debug("BUTTON SETTLE TIMEOUT " .. Memory.colorName(info))
        return true
    end

    function Memory.playSequence(generation)
        if Memory.Playing or #Memory.Sequence == 0 then
            return
        end

        Memory.Playing = true
        Memory.Recording = false
        Memory.Armed = false

        Memory.debug(
            "REPLAY START | count="
            .. tostring(#Memory.Sequence)
            .. " | sequence="
            .. Memory.seqText()
        )

        local sequence = {}
        for i, info in ipairs(Memory.Sequence) do
            sequence[i] = info
        end

        for index, info in ipairs(sequence) do
            if not App.Active
                or not App.AutoColorMemory
                or generation ~= Memory.Generation then

                break
            end

            Memory.debug(
                "REPLAY STEP "
                .. tostring(index)
                .. "/"
                .. tostring(#sequence)
                .. " | "
                .. Memory.colorName(info)
            )

            local accepted = Memory.fireButtonVerified(info)

            if accepted then
                Memory.waitButtonSettled(info)
            else
                task.wait(0.12)
                accepted = Memory.fireButtonVerified(info)

                if accepted then
                    Memory.waitButtonSettled(info)
                end
            end

            task.wait(Memory.BetweenSteps)
        end

        table.clear(Memory.Sequence)
        Memory.LastFlashAt = 0
        Memory.Playing = false
        Memory.Recording = false
        Memory.Armed = false
        Memory.ArmedUntil = 0

        for _, info in ipairs(Memory.Buttons) do
            info.LastCapturedAt = 0
            info.WasExact = false
        end

        Memory.debug("REPLAY FINISHED | sequence cleared")
        Memory.state("IDLE / WAITING FOR NEXT PATIENT")
    end

    function Memory.armForNewPatient()
        table.clear(Memory.Sequence)

        Memory.Recording = false
        Memory.Playing = false
        Memory.Armed = true
        Memory.ArmedUntil = os.clock() + 28
        Memory.LastFlashAt = 0

        for _, info in ipairs(Memory.Buttons) do
            info.LastCapturedAt = 0
            info.WasExact = false
        end

        Memory.debug("NEW PATIENT ARMED | old sequence cleared")
        Memory.state("ARMED / WAITING FOR FLASHES")
    end

    function Memory.step(generation)
        if not App.Active
            or not App.AutoColorMemory
            or generation ~= Memory.Generation then

            return
        end

        local now = os.clock()

        if now - Memory.LastBindCheck >= Memory.RebindInterval then
            Memory.LastBindCheck = now

            local room = Memory.findBestRoom()

            if room ~= Memory.Room then
                Memory.bind(room)
            elseif room and not Memory.modelStillCurrent() then
                Memory.bind(room)
            elseif not room and Memory.Room then
                Memory.bind(nil)
            end
        end

        if not Memory.Room then
            Memory.state("ROOM6 NOT BOUND YET")
            return
        end

        if not Memory.modelStillCurrent() then
            Memory.state("COLOR ROOM FOUND / WAITING FOR VALID MODEL")
            return
        end

        local pp = Memory.BeginPrompt

        if not Memory.Armed and not Memory.Playing and not Memory.Recording then
            if pp and pp.Parent and pp.Enabled then
                Memory.state("READY / BEGIN X-RAY AVAILABLE")
            else
                Memory.state("WAITING FOR BEGIN X-RAY")
            end
        end

        if pp
            and pp.Parent
            and pp.Enabled
            and not Memory.Playing
            and not Memory.Recording
            and Memory.distance(pp) <= (tonumber(pp.MaxActivationDistance) or 6) + 1.5 then

            if now - Memory.LastStartTry >= 0.85 then
                Memory.LastStartTry = now

                Memory.armForNewPatient()

                Memory.debug(
                    "TRY BEGIN X-RAY | room="
                    .. tostring(Memory.Room and Memory.Room.Name)
                    .. " | distance="
                    .. string.format("%.2f", Memory.distance(pp))
                )

                local started = Memory.triggerPrompt(pp)

                if started then
                    Memory.state("BEGIN SENT / WAITING FOR FLASHES")
                else
                    Memory.Armed = false
                    table.clear(Memory.Sequence)
                    Memory.state("BEGIN FAILED / RETRYING")
                end
            end
        end

        if not Memory.Armed and not Memory.Playing and Memory.Notice then
            local txt = ""
            pcall(function()
                txt = string.lower(tostring(Memory.Notice.Text or ""))
            end)

            if string.find(txt, "copy", 1, true)
                and string.find(txt, "sequence", 1, true) then

                Memory.debug('MONITOR says "Copy the sequence" -> recorder armed')
                Memory.armForNewPatient()
            end
        end

        if Memory.Armed and not Memory.Recording and not Memory.Playing then
            Memory.state("ARMED / WAITING FOR FIRST FLASH")
        end

        if Memory.Armed and Memory.Recording and not Memory.Playing then
            local remaining = math.max(0, Memory.SequenceEndGap - (now - Memory.LastFlashAt))
            Memory.state(
                "RECORDING | count="
                .. tostring(#Memory.Sequence)
                .. " | sequence="
                .. Memory.seqText()
                .. " | waitingGap="
                .. string.format("%.2f", remaining)
                .. "s"
            )
        end

        if Memory.Armed
            and Memory.Recording
            and not Memory.Playing
            and #Memory.Sequence > 0
            and now - Memory.LastFlashAt >= Memory.SequenceEndGap then

            Memory.debug(
                "SEQUENCE END DETECTED | count="
                .. tostring(#Memory.Sequence)
                .. " | sequence="
                .. Memory.seqText()
            )
            Memory.state("SEQUENCE COMPLETE / STARTING REPLAY")

            task.spawn(function()
                Memory.playSequence(generation)
            end)
        end

        if Memory.Armed and now > Memory.ArmedUntil and not Memory.Playing then
            table.clear(Memory.Sequence)
            Memory.Armed = false
            Memory.Recording = false
            Memory.LastFlashAt = 0
            Memory.debug("ARM TIMEOUT | no valid sequence completed")
            Memory.state("IDLE / ARM TIMEOUT")
        end
    end

    function Memory.start()
        Memory.Generation += 1
        local generation = Memory.Generation

        local initialRoom = Memory.findBestRoom()
        Memory.debug(
            "AUTO COLOR MEMORY DEBUG START | forcedRoom=Room6 | found="
            .. tostring(initialRoom ~= nil)
        )
        Memory.bind(initialRoom)

        task.spawn(function()
            while App.Active
                and App.AutoColorMemory
                and generation == Memory.Generation do

                pcall(function()
                    Memory.step(generation)
                end)

                task.wait(PERF.COLOR_MEMORY_TICK)
            end
        end)
    end

    function Memory.stop()
        Memory.Generation += 1
        Memory.disconnect()

        table.clear(Memory.Sequence)
        table.clear(Memory.Buttons)

        Memory.Room = nil
        Memory.Minigame = nil
        Memory.Colors = nil
        Memory.Model = nil
        Memory.Monitor = nil
        Memory.BeginPrompt = nil
        Memory.Notice = nil

        Memory.Recording = false
        Memory.Playing = false
        Memory.Armed = false
        Memory.ArmedUntil = 0
        Memory.LastFlashAt = 0
        Memory.DebugState = ""
        Memory.debug("AUTO COLOR MEMORY STOPPED")
    end

    function App.SetAutoColorMemory(state, silent)
        App.AutoColorMemory = state == true

        if App.AutoColorMemory then
            Memory.start()
        else
            Memory.stop()
        end

        if not silent then
            notifyState(T("AUTO_COLOR_MEMORY"), App.AutoColorMemory)
        end
    end
end

--==============================================================
-- CONFIG SAVE / LOAD / RESET
--==============================================================

local function buildConfig()
    return {
        Version = 39,
        Language = App.Language,
        CurrentPage = App.CurrentPage,
        AnomalyEnabled = copyTable(App.AnomalyEnabled),
        Noclip = App.Noclip,
        Fly = App.Fly,
        SanityGod = App.SanityGod,
        RunMode = App.RunMode,
        WalkSpeed = App.WalkSpeed,
        RunSpeed = App.RunSpeed,
        InstantInteract = App.InstantInteract,
        SafeStampManual = App.SafeStampManual,
        AutoStamp = App.AutoStamp,
        AutoSurgery = App.AutoSurgery,
        AutoColorMemory = App.AutoColorMemory,
        KeyCharacterNotifications = App.KeyCharacterNotifications,
        IconPosition = encodeUDim2(Icon.Position),
        MainPosition = encodeUDim2(Main.Position),
    }
end

local function saveSettings(silent)
    if not CAN_WRITE then
        if not silent then
            notify(T("N_CONFIG_SAVE_FAIL"))
        end
        return false
    end

    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(buildConfig()))
    end)

    if not silent then
        notify(ok and T("N_CONFIG_SAVED") or T("N_CONFIG_SAVE_FAIL"))
    end

    return ok
end

local function applyLanguage(language, silent)
    if language ~= "EN" and language ~= "RU" then
        return
    end

    App.Language = language
    updateStaticUI()
    if renderPage then
        renderPage(App.CurrentPage)
    end

    if not silent then
        notify(language == "RU" and T("N_LANGUAGE_RU") or T("N_LANGUAGE_EN"))
    end
end

applyLoadedState = function(silent)
    setNoclip(App.Noclip, true)
    setSanityGod(App.SanityGod, true)
    setRun(App.RunMode, true)
    setInstant(App.InstantInteract, true)
    Safe.setManual(App.SafeStampManual, true)
    setAutoStamp(App.AutoStamp, true)
    App.SetAutoSurgery(App.AutoSurgery, true)
    App.SetAutoColorMemory(App.AutoColorMemory, true)
    setKeyCharacterNotifications(App.KeyCharacterNotifications, true)

    if App.Fly then
        setFly(true, true)
    else
        setFly(false, true)
    end

    applySpeed()
    refreshAllESP()

    if not silent and renderPage then
        renderPage(App.CurrentPage)
    end
end

local function loadSettings(silent)
    local data = readConfigRaw()
    if not data then
        if not silent then
            notify(T("N_CONFIG_LOAD_FAIL"))
        end
        return false
    end

    stopFly()
    setNoclip(false, true)
    setInstant(false, true)
    setAutoStamp(false, true)
    App.SetAutoSurgery(false, true)
    App.SetAutoColorMemory(false, true)
    Safe.setManual(false, true)

    mergeConfig(data)

    Icon.Position = decodeUDim2(data.IconPosition, Icon.Position)
    Main.Position = decodeUDim2(data.MainPosition, Main.Position)

    task.defer(function()
        clampIconToScreen()
        if Main.Visible then
            clampMainToScreen()
        end
    end)

    updateStaticUI()
    applyLoadedState(true)

    if renderPage then
        renderPage(App.CurrentPage)
    end

    if not silent then
        notify(T("N_CONFIG_LOADED"))
    end

    return true
end

local function resetSettings()
    stopFly()
    setNoclip(false, true)
    setInstant(false, true)
    setAutoStamp(false, true)
    App.SetAutoSurgery(false, true)
    App.SetAutoColorMemory(false, true)
    Safe.setManual(false, true)

    local fresh = copyTable(DEFAULTS)
    for key, value in pairs(fresh) do
        App[key] = value
    end

    App.ShiftHeld = false
    App.KeyCharacterLastAlert = {}
    Icon.Position = IS_TOUCH and UDim2.fromOffset(12, 138) or UDim2.new(0, 20, 0.36, 0)
    Main.Position = UDim2.fromScale(0.5, 0.5)

    updateStaticUI()
    applyLoadedState(true)
    renderPage(App.CurrentPage)
    notify(T("N_CONFIG_RESET"))
end

--==============================================================
-- PAGES
--==============================================================

local function openESP()
    App.CurrentPage = "ESP"
    clearPage()
    selectNav("ESP")
    PageTitle.Text = T("PAGE_ESP")
    PageInfo.Text = T("PAGE_ESP_INFO")

    createSection(T("SEC_TYPES"))
    for _, definition in ipairs(AnomalyList) do
        local key = definition.Key
        local name = anomalyName(key)
        createToggle(
            definition.Icon,
            name,
            F("ANOMALY_TYPE_DESC", {name = name}),
            function()
                return App.AnomalyEnabled[key]
            end,
            function(state)
                setAnomalyType(key, state)
            end
        )
    end
end

local function openPlayer()
    App.CurrentPage = "PLAYER"
    clearPage()
    selectNav("PLAYER")
    PageTitle.Text = T("PAGE_PLAYER")
    PageInfo.Text = T("PAGE_PLAYER_INFO")

    createSection(T("SEC_MOVEMENT"))
    createToggle("◈", T("NOCLIP"), T("NOCLIP_DESC"), function()
        return App.Noclip
    end, setNoclip)

    createToggle("✦", T("FLY"), T("FLY_DESC"), function()
        return App.Fly
    end, setFly)

    createToggle("➤", T("RUN"), T("RUN_DESC"), function()
        return App.RunMode
    end, setRun)

    createSection(T("SEC_PLAYER"))
    createToggle("✚", T("SANITY_GOD"), T("SANITY_GOD_DESC"), function()
        return App.SanityGod
    end, setSanityGod)

    createSection(T("SEC_SPEED"))
    createSlider("↔", T("WALK_SPEED"), T("WALK_SPEED_DESC"), 5, 100, function()
        return App.WalkSpeed
    end, function(value)
        App.WalkSpeed = value
        applySpeed()
    end)

    createSlider("»", T("RUN_SPEED"), T("RUN_SPEED_DESC"), 10, 200, function()
        return App.RunSpeed
    end, function(value)
        App.RunSpeed = value
        applySpeed()
    end)
end

local function openMisc()
    App.CurrentPage = "MISC"
    clearPage()
    selectNav("MISC")
    PageTitle.Text = T("PAGE_MISC")
    PageInfo.Text = T("PAGE_MISC_INFO")

    createSection(T("SEC_NOTIFICATIONS"))
    createToggle("★", T("KEY_NOTIFICATIONS"), T("KEY_NOTIFICATIONS_DESC"), function()
        return App.KeyCharacterNotifications
    end, setKeyCharacterNotifications)

    createSection(T("SEC_INTERACTION"))

    createToggle("◎", T("SAFE_STAMP_MANUAL"), T("SAFE_STAMP_MANUAL_DESC"), function()
        return App.SafeStampManual
    end, Safe.setManual)

    createToggle("▶", T("AUTO_STAMP"), T("AUTO_STAMP_DESC"), function()
        return App.AutoStamp
    end, setAutoStamp)

    createToggle("✚", T("AUTO_SURGERY"), T("AUTO_SURGERY_DESC"), function()
        return App.AutoSurgery
    end, App.SetAutoSurgery)

    createToggle("◆", T("AUTO_COLOR_MEMORY"), T("AUTO_COLOR_MEMORY_DESC"), function()
        return App.AutoColorMemory
    end, App.SetAutoColorMemory)

    createToggle("⚡", T("INSTANT_INTERACT"), T("INSTANT_INTERACT_DESC"), function()
        return App.InstantInteract
    end, setInstant)
end

local function openSettings()
    App.CurrentPage = "SETTINGS"
    clearPage()
    selectNav("SETTINGS")
    PageTitle.Text = T("PAGE_SETTINGS")
    PageInfo.Text = T("PAGE_SETTINGS_INFO")

    createSection(T("SEC_LANGUAGE"))

    createAction(
        "EN",
        T("ENGLISH"),
        T("ENGLISH_DESC"),
        App.Language == "EN" and T("SELECTED") or T("SELECT"),
        function()
            applyLanguage("EN", false)
        end,
        App.Language == "EN" and C.GREEN or Color3.fromRGB(48, 83, 160)
    )

    createAction(
        "RU",
        T("RUSSIAN"),
        T("RUSSIAN_DESC"),
        App.Language == "RU" and T("SELECTED") or T("SELECT"),
        function()
            applyLanguage("RU", false)
        end,
        App.Language == "RU" and C.GREEN or Color3.fromRGB(48, 83, 160)
    )

    createSection(T("SEC_STORAGE"))
    createInfoCard((CAN_WRITE and CAN_READ) and T("CONFIG_AVAILABLE") or T("CONFIG_UNAVAILABLE"), CAN_WRITE and CAN_READ)

    createAction("↓", T("SAVE"), T("SAVE_DESC"), T("SAVE_BUTTON"), function()
        saveSettings(false)
    end, Color3.fromRGB(38, 125, 84))

    createAction("↑", T("LOAD"), T("LOAD_DESC"), T("LOAD_BUTTON"), function()
        loadSettings(false)
    end, Color3.fromRGB(55, 86, 160))

    createAction("↺", T("RESET"), T("RESET_DESC"), T("RESET_BUTTON"), function()
        resetSettings()
    end, Color3.fromRGB(145, 58, 68))
end

renderPage = function(page)
    if page == "PLAYER" then
        openPlayer()
    elseif page == "MISC" then
        openMisc()
    elseif page == "SETTINGS" then
        openSettings()
    else
        openESP()
    end
end

ESPNav.MouseButton1Click:Connect(openESP)
PlayerNav.MouseButton1Click:Connect(openPlayer)
MiscNav.MouseButton1Click:Connect(openMisc)
SettingsNav.MouseButton1Click:Connect(openSettings)
MobileESPNav.MouseButton1Click:Connect(openESP)
MobilePlayerNav.MouseButton1Click:Connect(openPlayer)
MobileMiscNav.MouseButton1Click:Connect(openMisc)
MobileSettingsNav.MouseButton1Click:Connect(openSettings)

--==============================================================
-- DRAGGING V6 - HARD FIX / DESKTOP + MOBILE
-- Main window: drag from the left/top header area.
-- Wolf icon: drag directly from the icon.
-- Uses RenderStepped for mouse and TouchMoved for mobile.
-- This avoids the InputObject mismatch that prevented V5 dragging.
--==============================================================

local function saveDragPosition()
    if CAN_WRITE then
        pcall(function()
            saveSettings(true)
        end)
    end
end

local function screenViewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end

-- MAIN WINDOW --------------------------------------------------

local MainDragging = false
local MainDragTouch = nil
local MainDragStartPointer = nil
local MainDragStartCenter = nil
local MainMoved = false

local function mainCenterFromAbsolute()
    return Main.AbsolutePosition + Main.AbsoluteSize * 0.5
end

local function clampMainCenter(center)
    local viewport = screenViewport()
    local size = Main.AbsoluteSize
    local halfX = size.X * 0.5
    local halfY = size.Y * 0.5

    local minX = halfX + 6
    local maxX = math.max(minX, viewport.X - halfX - 6)
    local minY = halfY + 6
    local maxY = math.max(minY, viewport.Y - halfY - 6)

    return Vector2.new(
        math.clamp(center.X, minX, maxX),
        math.clamp(center.Y, minY, maxY)
    )
end

clampMainToScreen = function()
    if not Main.Visible then
        return
    end

    local center = clampMainCenter(mainCenterFromAbsolute())
    Main.Position = UDim2.fromOffset(center.X, center.Y)
end

local function moveMainToPointer(pointerPosition)
    if not MainDragging or not MainDragStartPointer or not MainDragStartCenter then
        return
    end

    local delta = pointerPosition - MainDragStartPointer
    if delta.Magnitude > 3 then
        MainMoved = true
    end

    local center = clampMainCenter(MainDragStartCenter + delta)
    Main.Position = UDim2.fromOffset(center.X, center.Y)
end

local function finishMainDrag()
    if not MainDragging then
        return
    end

    MainDragging = false
    MainDragTouch = nil
    MainDragStartPointer = nil
    MainDragStartCenter = nil
    clampMainToScreen()
    saveDragPosition()
end

-- A real TextButton guarantees the header receives pointer/touch input.
local MainDragHandle = Instance.new("TextButton")
MainDragHandle.Name = "DragHandle"
MainDragHandle.BackgroundTransparency = 1
MainDragHandle.Text = ""
MainDragHandle.AutoButtonColor = false
MainDragHandle.Active = true
MainDragHandle.Selectable = false
MainDragHandle.Position = UDim2.fromOffset(0, 0)
MainDragHandle.Size = UDim2.new(1, IS_TOUCH and -78 or -205, 1, 0)
MainDragHandle.ZIndex = 50
MainDragHandle.Parent = Top

-- Small visible grip on mobile so it is obvious where to drag.
local DragGrip = Instance.new("TextLabel")
DragGrip.Name = "DragGrip"
DragGrip.AnchorPoint = Vector2.new(0.5, 0.5)
DragGrip.Position = UDim2.new(0.5, 0, 0, IS_TOUCH and 58 or 61)
DragGrip.Size = UDim2.fromOffset(IS_TOUCH and 90 or 74, IS_TOUCH and 18 or 14)
DragGrip.BackgroundTransparency = 1
DragGrip.Text = IS_TOUCH and "━━ DRAG ━━" or "DRAG"
DragGrip.TextColor3 = C.MUTED
DragGrip.TextTransparency = 0.28
DragGrip.Font = Enum.Font.GothamBold
DragGrip.TextSize = IS_TOUCH and 11 or 9
DragGrip.ZIndex = 51
DragGrip.Parent = MainDragHandle

MainDragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MainDragging = true
        MainMoved = false
        MainDragTouch = nil
        MainDragStartPointer = UIS:GetMouseLocation()
        MainDragStartCenter = mainCenterFromAbsolute()

    elseif input.UserInputType == Enum.UserInputType.Touch then
        MainDragging = true
        MainMoved = false
        MainDragTouch = input
        MainDragStartPointer = Vector2.new(input.Position.X, input.Position.Y)
        MainDragStartCenter = mainCenterFromAbsolute()
    end
end)

-- Mouse dragging: update every rendered frame while LMB is held.
track(RunService.RenderStepped:Connect(function()
    if not MainDragging or MainDragTouch ~= nil then
        return
    end

    if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        finishMainDrag()
        return
    end

    moveMainToPointer(UIS:GetMouseLocation())
end))

-- Touch dragging: track the exact finger that began the drag.
track(UIS.TouchMoved:Connect(function(input)
    if MainDragging and MainDragTouch and input == MainDragTouch then
        moveMainToPointer(Vector2.new(input.Position.X, input.Position.Y))
    end
end))

track(UIS.TouchEnded:Connect(function(input)
    if MainDragging and MainDragTouch and input == MainDragTouch then
        finishMainDrag()
    end
end))

track(UIS.InputEnded:Connect(function(input)
    if MainDragging and MainDragTouch == nil and input.UserInputType == Enum.UserInputType.MouseButton1 then
        finishMainDrag()
    end
end))

-- FLOATING ICON ------------------------------------------------

local IconDragging = false
local IconDragTouch = nil
local IconDragStartPointer = nil
local IconStartAbsolute = nil
local IconMoved = false

local function clampIconTopLeft(position)
    local viewport = screenViewport()
    local size = Icon.AbsoluteSize

    return Vector2.new(
        math.clamp(position.X, 6, math.max(6, viewport.X - size.X - 6)),
        math.clamp(position.Y, 6, math.max(6, viewport.Y - size.Y - 6))
    )
end

clampIconToScreen = function()
    local p = clampIconTopLeft(Icon.AbsolutePosition)
    Icon.Position = UDim2.fromOffset(p.X, p.Y)
end

local function moveIconToPointer(pointerPosition)
    if not IconDragging or not IconDragStartPointer or not IconStartAbsolute then
        return
    end

    local delta = pointerPosition - IconDragStartPointer

    if delta.Magnitude > (IS_TOUCH and 8 or 5) then
        IconMoved = true
    end

    local p = clampIconTopLeft(IconStartAbsolute + delta)
    Icon.Position = UDim2.fromOffset(p.X, p.Y)
end

local function finishIconDrag()
    if not IconDragging then
        return
    end

    IconDragging = false
    IconDragTouch = nil
    IconDragStartPointer = nil
    IconStartAbsolute = nil
    clampIconToScreen()
    saveDragPosition()
end

Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IconDragging = true
        IconMoved = false
        IconDragTouch = nil
        IconDragStartPointer = UIS:GetMouseLocation()
        IconStartAbsolute = Icon.AbsolutePosition

    elseif input.UserInputType == Enum.UserInputType.Touch then
        IconDragging = true
        IconMoved = false
        IconDragTouch = input
        IconDragStartPointer = Vector2.new(input.Position.X, input.Position.Y)
        IconStartAbsolute = Icon.AbsolutePosition
    end
end)

track(RunService.RenderStepped:Connect(function()
    if not IconDragging or IconDragTouch ~= nil then
        return
    end

    if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        finishIconDrag()
        return
    end

    moveIconToPointer(UIS:GetMouseLocation())
end))

track(UIS.TouchMoved:Connect(function(input)
    if IconDragging and IconDragTouch and input == IconDragTouch then
        moveIconToPointer(Vector2.new(input.Position.X, input.Position.Y))
    end
end))

track(UIS.TouchEnded:Connect(function(input)
    if IconDragging and IconDragTouch and input == IconDragTouch then
        finishIconDrag()
    end
end))

track(UIS.InputEnded:Connect(function(input)
    if IconDragging and IconDragTouch == nil and input.UserInputType == Enum.UserInputType.MouseButton1 then
        finishIconDrag()
    end
end))

--==============================================================
-- MENU OPEN / CLOSE
--==============================================================

local function openMenu()
    if App.MenuOpen then
        return
    end

    App.MenuOpen = true
    updateMobileFlyControls()
    Main.Visible = true
    local target = IS_TOUCH and BASE_MOBILE or BASE_DESKTOP
    Main.Size = UDim2.fromOffset(target.X * 0.94, target.Y * 0.94)
    Main.BackgroundTransparency = 0.2

    -- Keep the current/saved dragged position on both desktop and mobile.

    tween(Main, 0.23, {
        Size = UDim2.fromOffset(target.X, target.Y),
        BackgroundTransparency = 0,
    }, Enum.EasingStyle.Back)

    task.defer(function()
        updateScale()
        clampMainToScreen()
    end)
end

local function closeMenu()
    if not App.MenuOpen then
        return
    end

    App.MenuOpen = false
    updateMobileFlyControls()
    local target = IS_TOUCH and BASE_MOBILE or BASE_DESKTOP
    tween(Main, 0.16, {
        Size = UDim2.fromOffset(target.X * 0.94, target.Y * 0.94),
        BackgroundTransparency = 0.15,
    })

    task.delay(0.17, function()
        if not App.MenuOpen then
            Main.Visible = false
        end
    end)
end

Icon.MouseButton1Click:Connect(function()
    if IconMoved then
        IconMoved = false
        return
    end

    if App.MenuOpen then
        closeMenu()
    else
        openMenu()
    end
end)

Close.MouseButton1Click:Connect(closeMenu)
if not IS_TOUCH then
    Close.MouseEnter:Connect(function()
        tween(Close, 0.12, {BackgroundColor3 = C.RED})
    end)
    Close.MouseLeave:Connect(function()
        tween(Close, 0.12, {BackgroundColor3 = Color3.fromRGB(95, 31, 48)})
    end)
end

--==============================================================
-- RESPAWN
--==============================================================

track(LP.CharacterAdded:Connect(function(character)
    cacheCharacterParts(character)
    task.wait(1)
    local shouldFly = App.Fly
    stopFly()
    App.MobileFlyUp = false
    App.MobileFlyDown = false
    App.ShiftHeld = false
    applySpeed()
    if shouldFly then
        setFly(true, true)
    end
end))

--==============================================================
-- STOP / CLEANUP
--==============================================================

function App:Stop()
    if not self.Active then
        return
    end

    self.Active = false
    self.SafeStampManual = false
    self.AutoStamp = false
    self.AutoSurgery = false
    self.AutoColorMemory = false
    pcall(function() App.SetAutoSurgery(false, true) end)
    pcall(function() App.SetAutoColorMemory(false, true) end)
    pcall(Safe.restore)
    clearPageConnections()
    self.MobileFlyUp = false
    self.MobileFlyDown = false
    stopFly()

    self.Noclip = false
    for part, original in pairs(self.CollisionCache) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = original
            end)
        end
    end
    table.clear(self.CollisionCache)

    for prompt, original in pairs(self.PromptOriginals) do
        if prompt and prompt.Parent then
            pcall(function()
                prompt.HoldDuration = original
            end)
        end
    end

    local marked = {}
    for model in pairs(self.AnomalyMarked) do
        marked[#marked + 1] = model
    end
    for _, model in ipairs(marked) do
        removeAnomalyESP(model)
    end

    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if GUI then
        GUI:Destroy()
    end

    -- Release the single-instance slot only if it still belongs to us.
    if ENV.WOLF_CONTROL == self then
        ENV.WOLF_CONTROL = nil
    end
    if _G.WOLF_CONTROL == self then
        _G.WOLF_CONTROL = nil
    end
end

--==============================================================
-- INITIAL STATE / AUTO LOAD
--==============================================================

if App._SavedIconPosition then
    Icon.Position = decodeUDim2(App._SavedIconPosition, Icon.Position)
end
if App._SavedMainPosition then
    Main.Position = decodeUDim2(App._SavedMainPosition, Main.Position)
end

updateStaticUI()
applyLoadedState(true)
renderPage(App.CurrentPage)
updateScale()
task.defer(function()
    clampIconToScreen()
end)
App.UIReady = true

notify(T("READY"), IS_TOUCH and 1.55 or 1.9, false)
