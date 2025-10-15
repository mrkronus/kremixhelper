--[[============================================================================
  AceAddon.lua
  Purpose:
    - Core addon initialization using Ace3
    - Registers options, defaults, and minimap toggle
    - Wires into KDebug if available
============================================================================]]--

local _, Addon = ...

local kprint          = Addon.kprint
local Colors          = Addon.Colors
local KDebug_Register = Addon.KDebug_Register

local addonName              = Addon.Settings.AddonName
local addonVersion           = Addon.Settings.Version
local addonNameWithSpaces    = Addon.Settings.AddonNameWithSpaces
local addonNameWithIcon      = Addon.Settings.AddonNameWithIcon
local addonDBName            = Addon.Settings.AddonDBName
local addonOptionsSlashCommand = Addon.Settings.AddonOptionsSlashCommand

---@class LibAceAddon : AceAddon
local LibAceAddon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
Addon.LibAceAddon = LibAceAddon



--------------------------------------------------------------------------------
-- AceOptions Initialization
--------------------------------------------------------------------------------

Addon.AceOptions = {
    name    = addonNameWithIcon,
    handler = LibAceAddon,
    type    = "group",
    args    = {
        description = {
            type     = "description",
            name     = colorize("Version " .. addonVersion, Colors.Grey),
            fontSize = "small",
            order    = 0.1,
        },
        enableMinimapButton = {
            type  = "toggle",
            width = "full",
            order = 1,
            name  = "Hide minimap button",
            desc  = "Toggles the visibility of the minimap icon for this addon.",
            get   = "ShouldHideMinimapButton",
            set   = "ToggleMinimapButton",
        },
    },
}

Addon.AceOptionsDefaults = {
    profile = {
        -- Do not remove! Registered with KDebug
        -- NOTE: Not used directly by this addon
        showDebugOutput = false,
    },
    global = {
        minimap = {
            hide       = false,
            lock       = false,
            radius     = 90,
            minimapPos = 200,
        },
    },
}



--------------------------------------------------------------------------------
-- Database Accessors
--------------------------------------------------------------------------------

---Return the AceDB database object.
function LibAceAddon:GetDB()
    return self.db
end

---Return the stored data version or a fallback.
function LibAceAddon:GetDBDataVersion()
    if self.db.profile.dataVersion == nil then
        return "0.0.0"
    end
    return self.db.profile.dataVersion
end



--------------------------------------------------------------------------------
-- Minimap Button Toggles
--------------------------------------------------------------------------------

---Check if the minimap button should be hidden.
function LibAceAddon:ShouldHideMinimapButton(_)
    return self.db.global.minimap.hide
end

---Toggle the minimap button visibility.
function LibAceAddon:ToggleMinimapButton(_, value)
    self.db.global.minimap.hide = value
    local libIconModule = LibAceAddon:GetModule("MinimapIcon")
    if value then
        libIconModule.libdbicon:Hide(addonName)
    else
        libIconModule.libdbicon:Show(addonName)
    end
end

---Check if debug output should be shown (handled by KDebug).
function LibAceAddon:ShouldShowDebugOutput(_)
    return self.db.profile.showDebugOutput
end



--------------------------------------------------------------------------------
-- Addon Lifecycle
--------------------------------------------------------------------------------

---Called when the addon is enabled.
function LibAceAddon:OnEnable()
    if Addon.Initialize then
        Addon:Initialize()
    end
end

---Called when the addon is initialized.
function LibAceAddon:OnInitialize()
    -- Initialize AceDB
    self.db = LibStub("AceDB-3.0"):New(addonDBName, Addon.AceOptionsDefaults, true)

    -- Register options with AceConfig
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, Addon.AceOptions, addonOptionsSlashCommand)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonNameWithSpaces)

    -- Register with KDebug if available
    if KDebug_Register then
        KDebug_Register(self.db.profile, "FFF2BF4D")
        kprint(addonNameWithSpaces .. " registered with K Debug!")
    end

    -- Store nominal version in profile
    self.db.profile.dataVersion = Addon.Settings.NominalVersion
end
