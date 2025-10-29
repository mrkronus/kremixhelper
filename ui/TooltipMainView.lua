--[[-----------------------------------------------------------------------------
  TooltipMainView.lua
  Purpose:
    - Provide tooltip content for the current player (identity, artifact, stats)
  Notes:
    - Sections: Player identity, Artifact weapon, Infinite Power, Currency, Submenus
    - Falls back gracefully if not in Legion Remix
-------------------------------------------------------------------------------]]--

local _, Addon = ...

local Fonts        = Addon.Fonts
local Colors       = Addon.Colors
local colorize     = Addon.Colorize
local classToColor = Addon.ClassToColor

local PartyView      = Addon.PartyView
local ObjectivesView = Addon.ObjectivesView

local INV_MISC_QUESTIONMARK     = 134400
local LIMITS_UNBOUND_SPELL_ID   = 1245947

--------------------------------------------------------------------------------
-- Section Helpers
--------------------------------------------------------------------------------

---Add player identity section (name, class, level, ilvl, Threads).
---@param tooltip table
local function AddPlayerIdentitySection(tooltip)
    local Threads    = Addon.ThreadsTracker
    local player     = Addon.PlayerIdentity:Get()
    local faction    = player.faction
    local classToken = player.classToken

    tooltip:SetFont(Fonts.MainHeader)
    local headerLine = tooltip:AddLine()
    tooltip:SetCell(headerLine, 1,
        getClassIcon(classToken) .. " " ..
        colorize(player.name .. " - " .. player.realm, classToColor(classToken)))
    tooltip:SetCell(headerLine, 2, Addon.FactionIcons[faction])

    tooltip:SetFont(Fonts.MainText)
    local classLoc   = ((player.specLocalized .. " ") or "") .. (player.classLocalized or "")
    local raceString = player.raceLocalized or ""
    local classStr   = classLoc or ""
    local level      = player.level or 0
    local ilvl       = player.ilvl or 0
    local avgWeapon  = Addon.ArtifactWeapon:GetAverageItemLevel()
    local totalThreads = Threads:GetPlayerData()

    tooltip:AddSeparator(3, 0, 0, 0, 0)
    tooltip:AddLine(raceString .. " | " .. colorize(classStr, classToColor(classToken)))
    tooltip:AddLine("Level: " .. level .. " | iLvl: " .. ilvl .. " | Weapon: " .. avgWeapon)

    if Addon.IsInLegionTimerunnerMode() then
        tooltip:AddSeparator(3, 0, 0, 0, 0)
        local threads = colorize(Addon.FormatWithCommasToThousands(totalThreads) .. " Threads", Colors.WowToken)
        local unbound = colorize(Addon.TooltipHelpers.GetLimitsUnboundRankString() .. " Limits Unbound", Colors.Artifact)
        local currentLine = tooltip:AddLine(threads .. " | " .. unbound)
        Addon.TooltipHelpers.AddTooltipToLine(tooltip, currentLine, function(cell)
            GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(LIMITS_UNBOUND_SPELL_ID)
            GameTooltip:Show()
        end)
    end
end

---Add artifact weapon section (equipped weapons + traits).
---@param tooltip table
local function AddArtifactWeaponSection(tooltip)
    local Artifact = Addon.ArtifactWeapon

    Addon.TooltipHelpers.AddSectionHeading(tooltip, "Artifact Weapon")
    tooltip:SetFont(Fonts.Subheading)

    local weapons = Artifact:GetEquippedArtifactWeapons()
    if #weapons > 0 then
        for _, w in ipairs(weapons) do
            local iconMarkup = "|T" .. w.icon .. ":16|t"
            local label = iconMarkup .. " " .. w.text
            local currentLine = tooltip:AddLine(label)
            Addon.TooltipHelpers.AddTooltipToLine(tooltip, currentLine, function(cell)
                GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(w.link)
                GameTooltip:Show()
            end)
        end

        tooltip:AddSeparator(3, 0, 0, 0, 0)
        tooltip:SetFont(Fonts.MainText)
        local traits = Artifact:GetIncreasedTraitSpellsAndRanks()
        for _, value in ipairs(traits or {}) do
            local spellID        = value[1]
            local totalIncreased = value[2]
            local spellIcon      = C_Spell.GetSpellTexture(spellID) or INV_MISC_QUESTIONMARK
            local spellName      = C_Spell.GetSpellName(spellID)

            local traitFormat    = "+%d |T%s:16:16:0:-2:64:64:4:60:4:60|t |cffffd100%s|r"
            local lineText       = string.format(traitFormat, totalIncreased, spellIcon, spellName)
            local line           = tooltip:AddLine(lineText)

            Addon.TooltipHelpers.AddTooltipToLine(tooltip, line, function(cell)
                GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(("spell:%d"):format(spellID))
                GameTooltip:Show()
            end)
        end
    else
        tooltip:SetFont(Fonts.MainText)
        tooltip:AddLine(colorize("No artifact weapon is equipped", Colors.Grey))
    end
end

---Add Infinite Power stat breakdown section.
---@param tooltip table
local function AddInfinitePowerSection(tooltip)
    local Threads  = Addon.ThreadsTracker
    local Stats    = Addon.StatsTracker
    local Artifact = Addon.ArtifactWeapon

    Addon.TooltipHelpers.AddSectionHeading(tooltip, "Infinite Power")

    local weapons = Artifact:GetEquippedArtifactWeapons()
    if #weapons > 0 then
        local aura = Threads.ScanAura("player")
        if aura then
            local lines = Stats:GetStatLines(aura, "player")
            for _, line in ipairs(lines) do
                local currentLine = tooltip:AddLine()
                tooltip:SetCell(currentLine, 1, colorize(line, Colors.White), "LEFT", 2)
            end
        end
    else
        tooltip:SetFont(Fonts.MainText)
        tooltip:AddLine(colorize("No artifact weapon is equipped", Colors.Grey))
    end
end

---Add currency section.
---@param tooltip table
local function AddCurrencySection(tooltip)
    Addon.TooltipHelpers.AddSectionHeading(tooltip, "Remix Currency")
    Addon.TooltipHelpers.AddCurrencyLine(tooltip, Addon.Currency.INFINITE_KNOWLEDGE)
    Addon.TooltipHelpers.AddCurrencyLine(tooltip, Addon.Currency.INFINITE_POWER)
    Addon.TooltipHelpers.AddCurrencyLine(tooltip, Addon.Currency.BRONZE)
end

---Add submenu section (Party/Group info, Objectives).
---@param tooltip table
local function AddSubMenusSection(tooltip)
    tooltip:AddSeparator(10, 0, 0, 0, 0)
    tooltip:AddSeparator()
    tooltip:AddSeparator(3, 0, 0, 0, 0)

    Addon.TooltipHelpers.AddSubTooltipLine(tooltip, "Group Info", function(subTip)
        PartyView:Populate(subTip)
    end)

    Addon.TooltipHelpers.AddSubTooltipLine(tooltip, "Objectives", function(subTip)
        ObjectivesView:Populate(subTip)
    end)
end

---Add fallback section if not in Remix.
---@param tooltip table
local function AddNotInRemixSection(tooltip)
    tooltip:SetFont(Fonts.MainText)
    tooltip:AddSeparator(3, 0, 0, 0, 0)
    local currentLine = tooltip:AddLine()
    tooltip:SetCell(currentLine, 1,
        colorize("The current character is not a Legion Remix character", Colors.Grey), 2)
end

--------------------------------------------------------------------------------
-- PlayerView
--------------------------------------------------------------------------------

---@class PlayerView
local PlayerView = {}

---Populate the tooltip for the current player.
---@param tooltip table
function PlayerView:Populate(tooltip)
    if Addon.IsInLegionTimerunnerMode() then
        AddPlayerIdentitySection(tooltip)
        AddArtifactWeaponSection(tooltip)
        AddInfinitePowerSection(tooltip)
        AddCurrencySection(tooltip)
        AddSubMenusSection(tooltip)
    else
        AddPlayerIdentitySection(tooltip)
        AddNotInRemixSection(tooltip)
    end
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.PlayerView = PlayerView
