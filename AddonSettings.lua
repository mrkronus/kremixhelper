--[[============================================================================
  Addon Initialization
  Purpose:
    - Initialize addon settings and metadata
    - Register debug helpers if available
    - Provide global constants for addon name, version, and UI references
============================================================================]]--

local tocName = ...
local Addon   = select(2, ...)

local KLib   = _G.KLib or nil
local KDebug = _G.KDebug or nil


--------------------------------------------------------------------------------
-- Settings Table
--------------------------------------------------------------------------------

Addon.Settings = {}
Addon.Settings.HasKDebug = (KLib and KLib.HasKDebug and KDebug) or false
Addon.Settings.kprint    = (KLib and KLib.kprint) or function() end
Addon.Settings.Colors    = (KLib and KLib.Colors) or nil

-- Defensive: register debug only if KDebug is present
Addon.KDebug_Register = (Addon.Settings.HasKDebug and KDebug and KDebug.Register) or function() end


--------------------------------------------------------------------------------
-- Metadata
--------------------------------------------------------------------------------

Addon.Settings.AddonName           = C_AddOns.GetAddOnMetadata(tocName, "Title")
Addon.Settings.AddonNameWithSpaces = C_AddOns.GetAddOnMetadata(tocName, "X-Title-With-Spaces")

Addon.Settings.Version        = C_AddOns.GetAddOnMetadata(tocName, "Version")
local version                 = Addon.Settings.Version or "0.0.0"
Addon.Settings.NominalVersion = tonumber(version:match("(%d+)$")) or 1


--------------------------------------------------------------------------------
-- Derived Identifiers
--------------------------------------------------------------------------------

Addon.Settings.AddonTooltipName         = Addon.Settings.AddonName .. "Tooltip"                -- e.g. "AddonTooltip"
Addon.Settings.AddonDBName              = Addon.Settings.AddonName .. "DB"                     -- e.g. "AddonDB"
Addon.Settings.AddonOptionsSlashCommand = "/" .. string.lower(Addon.Settings.AddonName)        -- e.g. "/addon"


--------------------------------------------------------------------------------
-- Icon and Display Name
--------------------------------------------------------------------------------

local iconPath = C_AddOns.GetAddOnMetadata(tocName, "IconTexture") or "Interface\\Icons\\INV_Misc_QuestionMark"
Addon.Settings.IconTexture     = iconPath
Addon.Settings.AddonNameWithIcon = "|T" .. iconPath .. ":0|t " .. Addon.Settings.AddonNameWithSpaces

-- Defensive: ensure proper escape sequence for icon embedding
Addon.Settings.AddonNameWithIcon = "\124T" ..
    Addon.Settings.IconTexture .. ":0\124t " .. Addon.Settings.AddonNameWithSpaces


--------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------

Addon.Settings.Dependencies = C_AddOns.GetAddOnMetadata(tocName, "Dependencies")
Addon.Settings.OptionalDeps = C_AddOns.GetAddOnMetadata(tocName, "OptionalDeps")
