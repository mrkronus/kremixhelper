--[[-------------------------------------------------------------------------
TooltipMainView.lua
Purpose:
  Provides tooltip content for the current player (identity, artifact, stats).
---------------------------------------------------------------------------]]

local _, KRemixHelper            = ...

local Fonts                      = KRemixHelper.Fonts
local Colors                     = KRemixHelper.Colors
local colorize                   = KRemixHelper.Colorize
local classToColor               = KRemixHelper.ClassToColor
local PartyView                  = KRemixHelper.PartyView
local ObjectivesView             = KRemixHelper.ObjectivesView


--------------------------------------------------------------------------------
-- Section Helpers
--------------------------------------------------------------------------------

local function AddPlayerIdentitySection(tooltip)
    local Threads    = KRemixHelper.ThreadsTracker
    local player     = KRemixHelper.PlayerIdentity.Get()
    local faction    = player.faction
    local classToken = player.classToken

    tooltip:SetFont(Fonts.MainHeader)
    local headerLine = tooltip:AddLine()
    tooltip:SetCell(headerLine, 1, getClassIcon(classToken) .. " " .. colorize(player.name .. " - " .. player.realm, classToColor(classToken)))
    tooltip:SetCell(headerLine, 2, KRemixHelper.FactionIcons[faction])

    tooltip:SetFont(Fonts.MainText)
    local classLoc        = ((player.specLocalized .. " ") or "") .. (player.classLocalized or "")
    local raceString      = player.raceLocalized or ""
    local classString     = classLoc or ""
    local level           = player.level or 0
    local ilvl            = player.ilvl or 0
    local avgArtifactILvl = KRemixHelper.ArtifactWeapon:GetAverageItemLevel()
    local totalThreads, _ = Threads:GetPlayerData()

    tooltip:AddSeparator(3, 0, 0, 0, 0)
    tooltip:AddLine(raceString .. " | " .. colorize(classString, classToColor(classToken)))
    tooltip:AddLine("Level: " .. level .. " | iLvl: " .. ilvl .. " | Weapon: " .. avgArtifactILvl)

    if IsInLegionTimerunnerMode() then
        tooltip:AddSeparator(3, 0, 0, 0, 0)
        local threads = colorize(FormatWithCommasToThousands(totalThreads) .. " Threads", Colors.WowToken)
        local unbound = colorize(GetLimitsUnboundRankString() .. " Limits Unbound", Colors.Artifact)
        local currentLine = tooltip:AddLine(threads .. " | " .. unbound)
        AddTooltipToLine(tooltip, currentLine, function(cell)
            GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(1245947)
            GameTooltip:Show()
        end)
    end
end

local function AddArtifactWeaponSection(tooltip)
    local Artifact = KRemixHelper.ArtifactWeapon

    -- Artifact weapon
    AddSectionHeading(tooltip, "Artifact Weapon")
    tooltip:SetFont(Fonts.Subheading)
    local weapons = Artifact:GetEquippedArtifactWeapons()
    if #weapons > 0 then
        for _, w in ipairs(weapons) do
            local iconMarkup = "|T" .. w.icon .. ":16|t"
            local label = iconMarkup .. " " .. w.text
            local currentLine = tooltip:AddLine(label)
            AddTooltipToLine(tooltip, currentLine, function(cell)
                GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(w.link)
                GameTooltip:Show()
            end)
        end

        -- Artifact traits
        tooltip:AddSeparator(3, 0, 0, 0, 0)
        tooltip:SetFont(Fonts.MainText)
        local traits = Artifact:GetIncreasedTraitSpellsAndRanks()
        for _, value in ipairs(traits) do
            local spellID        = value[1]
            local totalIncreased = value[2]
            local spellIcon      = C_Spell.GetSpellTexture(spellID) or INV_MISC_QUESTIONMARK
            local spellName      = C_Spell.GetSpellName(spellID)

            local traitFormat    = "+%d |T%s:16:16:0:-2:64:64:4:60:4:60|t |cffffd100%s|r"
            local lineText       = string.format(traitFormat, totalIncreased, spellIcon, spellName)
            local line           = tooltip:AddLine(lineText)

            AddTooltipToLine(tooltip, line, function(cell)
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

local function AddInfinitePowerSection(tooltip)
    local Threads  = KRemixHelper.ThreadsTracker
    local Stats    = KRemixHelper.StatsTracker
    local Artifact = KRemixHelper.ArtifactWeapon

    AddSectionHeading(tooltip, "Infinite Power")

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

local function AddCurrencySection(tooltip)
    AddSectionHeading(tooltip, "Remix Currency")
    AddCurrencyLine(tooltip, CURRENCY_INFINITE_KNOWLEDGE)
    AddCurrencyLine(tooltip, CURRENCY_INFINITE_POWER)
    AddCurrencyLine(tooltip, CURRENCY_BRONZE)
end

local function AddSubMenusSection(tooltip)
    tooltip:AddSeparator(10, 0, 0, 0, 0)
    tooltip:AddSeparator()
    tooltip:AddSeparator(3, 0, 0, 0, 0)
    AddSubTooltipLine(tooltip, "Group Info", function(subTip)
        PartyView:Populate(subTip)
    end)

    AddSubTooltipLine(tooltip, "Objectives", function(subTip)
        ObjectivesView:Populate(subTip)
    end)

end

local function AddNotInRemixSection(tooltip)
    tooltip:SetFont(Fonts.MainText)
    tooltip:AddSeparator(3, 0, 0, 0, 0)
    local currentLine = tooltip:AddLine()
    tooltip:SetCell(currentLine, 1, colorize("The current character is not a Legion Remix character", Colors.Grey), 2)
end


--------------------------------------------------------------------------------
-- PlayerView
--------------------------------------------------------------------------------

local PlayerView = {}

function PlayerView:Populate(tooltip)
    if IsInLegionTimerunnerMode() then
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

KRemixHelper.PlayerView = PlayerView
