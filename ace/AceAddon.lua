--[[============================================================================
  AceAddon.lua
  Purpose:
    - Core addon initialization using Ace3
    - Registers options, defaults, and minimap toggle
    - Wires into KDebug if available
============================================================================]]--

local _, Addon                 = ...

local kprint                   = Addon.kprint
local Colors                   = Addon.Colors
local KDebug_Register          = Addon.KDebug_Register

local addonName                = Addon.Settings.AddonName
local addonVersion             = Addon.Settings.Version
local addonNameWithSpaces      = Addon.Settings.AddonNameWithSpaces
local addonNameWithIcon        = Addon.Settings.AddonNameWithIcon
local addonDBName              = Addon.Settings.AddonDBName
local addonOptionsSlashCommand = Addon.Settings.AddonOptionsSlashCommand

---@class LibAceAddon : AceAddon
local LibAceAddon              = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
Addon.LibAceAddon              = LibAceAddon

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
        scrapping = {
            type    = "group",
            name    = "Scrapping",
            order   = 10,
            inline  = true,
            args  = {
                maxQuality = {
                    type   = "select",
                    name   = "Maximum Item Quality To Scrap",
                    desc   = "Only scrap items up to this quality.",
                    values = function()
                        local t = {}
                        for q = Enum.ItemQuality.Common, Enum.ItemQuality.Epic do
                            local name  = _G["ITEM_QUALITY" .. q .. "_DESC"]
                            local color = ITEM_QUALITY_COLORS[q]
                            t[q]        = color.hex .. name .. "|r"
                        end
                        return t
                    end,
                    get    = function() return LibAceAddon.db.profile.maxQuality end,
                    set    = function(_, val) LibAceAddon.db.profile.maxQuality = val end,
                    order  = 1,
                },
                spacer = {
                    type  = "description",
                    name  = "  ",
                    order = 2,
                },
                autoFillScrapper = {
                    type  = "toggle",
                    name  = "Auto Fill Scrapper",
                    desc  = "Continuously tops up the scrapper when it's empty.",
                    get   = function() return LibAceAddon.db.profile.autoFillScrapper end,
                    set   = function(_, val) LibAceAddon.db.profile.autoFillScrapper = val end,
                    order = 3,
                },
                protectHigherIlvl = {
                    type  = "toggle",
                    name  = "Keep High iLvl Items",
                    desc  = "If enabled, items above your equipped item level for the item's slot will not be scrapped.",
                    get   = function() return LibAceAddon.db.profile.protectHigherIlvl end,
                    set   = function(_, val) LibAceAddon.db.profile.protectHigherIlvl = val end,
                    order = 4,
                },
            },
        },
    },
}

Addon.AceOptionsDefaults = {
    profile = {
        showDebugOutput   = false,

        -- Scrapping defaults
        autoFillScrapper  = true,
        protectHigherIlvl = true,
        maxQuality        = Enum.ItemQuality.Rare,
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

function LibAceAddon:GetDB()
    return self.db
end

function LibAceAddon:GetDBDataVersion()
    if self.db.profile.dataVersion == nil then
        return "0.0.0"
    end
    return self.db.profile.dataVersion
end

--------------------------------------------------------------------------------
-- Minimap Button Toggles
--------------------------------------------------------------------------------

function LibAceAddon:ShouldHideMinimapButton(_)
    return self.db.global.minimap.hide
end

function LibAceAddon:ToggleMinimapButton(_, value)
    self.db.global.minimap.hide = value
    local libIconModule = LibAceAddon:GetModule("MinimapIcon")
    if value then
        libIconModule.libdbicon:Hide(addonName)
    else
        libIconModule.libdbicon:Show(addonName)
    end
end

function LibAceAddon:ShouldShowDebugOutput(_)
    return self.db.profile.showDebugOutput
end

--------------------------------------------------------------------------------
-- Addon Lifecycle
--------------------------------------------------------------------------------

function LibAceAddon:OnEnable()
    if Addon.Initialize then
        Addon:Initialize()
    end
end

function LibAceAddon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(addonDBName, Addon.AceOptionsDefaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, Addon.AceOptions, addonOptionsSlashCommand)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonNameWithSpaces)

    if KDebug_Register then
        KDebug_Register(self.db.profile, "FFF2BF4D")
        kprint(addonNameWithSpaces .. " registered with K Debug!")
    end

    self.db.profile.dataVersion = Addon.Settings.NominalVersion
end
