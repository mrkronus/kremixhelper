--[[============================================================================
  TooltipProvider.lua
  Purpose:
    - Provide tooltip content for the minimap icon
    - Display Threads totals, currency, stat breakdown, and artifact powers
============================================================================]]--

local _, KRemixHelper = ...

local Fonts   = KRemixHelper.Fonts
local Colors  = KRemixHelper.Colors

---@class ParentAceAddon : AceAddon
local ParentAceAddon = LibStub("AceAddon-3.0"):GetAddon(KRemixHelper.Settings.AddonName)
local MinimapTooltip = ParentAceAddon:GetModule("MinimapTooltip")
local MinimapIcon    = ParentAceAddon:GetModule("MinimapIcon")

local MinimapTooltipProvider          = {}
MinimapTooltipProvider.activeTicker   = nil
MinimapTooltipProvider.currentTooltip = nil
MinimapTooltipProvider.coordLine      = nil

MinimapIcon:SetClickCallback(function(...) MinimapTooltipProvider:OnIconClick(...) end)
MinimapTooltip:SetProvider(MinimapTooltipProvider)


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

---Build a clickable spell link from id and name.
---@param id number
---@param name string
---@return string
local function SpellLink(id, name)
    return ("|cff71d5ff|Hspell:%d|h[%s]|h|r"):format(id, name)
end

---Add a section heading with separators and font changes.
---@param sectionName string
local function AddSectionHeading(tooltip, sectionName)
    tooltip:AddSeparator(10, 0, 0, 0, 0)
    tooltip:SetFont(Fonts.Heading)
    tooltip:AddLine(colorize(sectionName, Colors.SubHeader))
    tooltip:AddSeparator()
    tooltip:AddSeparator(3, 0, 0, 0, 0)
    tooltip:SetFont(Fonts.MainText)
end

---Add a currency line to the tooltip if the player has any of it.
---@param tooltip table
---@param currencyID number
local function AddCurrencyLine(tooltip, currencyID)
    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if info and info.quantity and info.quantity > 0 then
        local icon = info.iconFileID and ("|T%d:0|t"):format(info.iconFileID) or ""
        local line = tooltip:AddLine()
        tooltip:SetCell(line, 1, info.name)
        tooltip:SetCell(line, 2, FormatWithCommas(info.quantity) .. " " .. icon)
    end
end

---Add a section of clickable spell links.
---@param headerText string
---@param headerColor table
---@param entries table
local function addLinkLine(tooltip, headerText, headerColor, entries)
    if #entries == 0 then return end
    AddSectionHeading(colorize(headerText, headerColor))
    for _, entry in ipairs(entries) do
        local currentLine = tooltip:AddLine()
        local linkText = SpellLink(entry.id, entry.name)
        tooltip:SetCell(currentLine, 1, linkText, "LEFT", 1)
        tooltip:SetLineScript(currentLine, "OnEnter", function()
            GameTooltip:SetOwner(tooltip, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(entry.id)
            GameTooltip:Show()
        end)
        tooltip:SetLineScript(currentLine, "OnLeave", function()
            GameTooltip:Hide()
        end)
        tooltip:SetLineScript(currentLine, "OnMouseUp", function()
            ChatFrame_OpenChat(C_Spell.GetSpellLink(entry.id))
        end)
    end
end

local function CloseWeaponTraitsUI()
  local closed = false
  local RAF = _G.RemixArtifactFrame
  if RAF and RAF:IsShown() then
    RAF:Hide()
    closed = true
  end
  local AF = _G.ArtifactFrame
  if AF and AF:IsShown() then
    AF:Hide()
    closed = true
  end
  if _G.ItemSocketingFrame and _G.ItemSocketingFrame:IsShown() then
    if CloseSocketInfo then pcall(CloseSocketInfo) end
    if _G.ItemSocketingFrame:IsShown() then
      _G.ItemSocketingFrame:Hide()
    end
    closed = true
  end
  return closed
end


local function ToggleArtifactTree()
  if InCombatLockdown and InCombatLockdown() then
    UIErrorsFrame:AddMessage(L.ERR_COMBAT, 1, 0.1, 0.1)
    return
  end
  if CloseWeaponTraitsUI() then return end
  pcall(SocketInventoryItem, 16)
  C_Timer.After(0.05, function()
    pcall(SocketInventoryItem, 17)
  end)
end

-- Constants
local LIMITS_UNBOUND_SPELL_ID = 1245947
local INFINITE_POWER_CURRENCY_ID = 3268
local COST_TO_UNLOCK_TREE = 114125
local COST_PER_RANK = 50000

-- Function to get current Infinite Power
local function GetInfinitePowerQty()
  if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return 0 end
  local ci = C_CurrencyInfo.GetCurrencyInfo(INFINITE_POWER_CURRENCY_ID)
  return (ci and ci.quantity) or 0
end

-- Function to get spell icon
local function GetSpellIcon(spellID)
  if not spellID or not C_Spell.GetSpellTexture then return 134400 end
  return C_Spell.GetSpellTexture(spellID) or 134400
end

-- Function to calculate Limits Unbound rank and format string
local function GetLimitsUnboundRankString()
  local ipQty = GetInfinitePowerQty()
  local available = math.max(0, ipQty - COST_TO_UNLOCK_TREE)
  local rank = math.floor(available / COST_PER_RANK)
  local icon = ("|T%d:0|t"):format(GetSpellIcon(LIMITS_UNBOUND_SPELL_ID)) or ""
  return colorize(tostring(rank), Colors.White) .. " " .. icon
end

local function GetPlayerIdentity()
    local unit = "player"
    local name, realm   = UnitName(unit)
    local localizedClass, classToken = UnitClass(unit)
    local raceLocalized, raceToken   = UnitRace(unit)
    local level         = UnitLevel(unit)
    local faction       = UnitFactionGroup(unit)
    local guid          = UnitGUID(unit)
    local avgIlvl, eq   = GetAverageItemLevel()
    local specID        = GetSpecialization()
    local specName      = ""
    if specID and specID > 0 then
        _, specName = GetSpecializationInfo(specID)
    end

    return {
        name           = name,
        realm          = realm or GetRealmName(),
        guid           = guid,
        classToken     = classToken,
        classLocalized = localizedClass,
        specLocalized  = specName,
        raceToken      = raceToken,
        raceLocalized  = raceLocalized,
        level          = level,
        ilvl           = math.floor((avgIlvl or 0) + 0.5),
        faction        = faction,
    }
end
--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

---Handle minimap icon clicks.
---@param clickedFrame Frame
---@param button string
function MinimapTooltipProvider:OnIconClick(clickedFrame, button)
    if button == "LeftButton" then
        ToggleArtifactTree()
    elseif button == "RightButton" then
        Settings.OpenToCategory(KRemixHelper.Settings.AddonNameWithSpaces)
    end
end


--------------------------------------------------------------------------------
-- PopulateTooltip
--------------------------------------------------------------------------------

---Populate the minimap tooltip with Threads, currency, stats, and artifact powers.
---@param tooltip table
function MinimapTooltipProvider:PopulateTooltip(tooltip)
    tooltip:Clear()
    tooltip:SetFont(Fonts.MainHeader)

    if IsInLegionTimerunnerMode() then
        local Threads = KRemixHelper.ThreadsTracker
        local Stats   = KRemixHelper.StatsTracker

        local player  = GetPlayerIdentity()
        local faction    = player.faction
        local classToken    = player.classToken

        local headerLine = tooltip:AddLine()
        tooltip:SetCell(headerLine, 1, getClassIcon(classToken) .." " .. colorize(player.name .. " - " .. player.realm, classToColor(classToken)))
        tooltip:SetCell(headerLine, 2, KRemixHelper.FactionIcons[faction])

        tooltip:SetFont(Fonts.MainText)

        local factionString = faction or ""
        local classLoc      = ((player.specLocalized .. " ") or "" ) .. (player.classLocalized or "")
        local raceString    = player.raceLocalized or ""
        local classString   = classLoc or ""
        local level         = player.level or 0
        local ilvl          = player.ilvl or 0
        local totalThreads, threadsGainedToday = Threads:GetPlayerData()

        tooltip:AddLine(raceString .. " | " .. colorize(factionString, KRemixHelper.FactionColors[faction]) .. " | " .. colorize(classString, classToColor(classToken)))
        tooltip:AddLine("Level: " .. level .. " | iLvl: " .. ilvl .. " | Threads: " .. FormatWithCommasToThousands(totalThreads))

        -- Limits Unbound section
        AddSectionHeading(tooltip, "Limits Unbound")
        local limitsUnboundString = GetLimitsUnboundRankString()
        local currentLine = tooltip:AddLine()
        tooltip:SetCell(currentLine, 1, "Limits Unbound Rank")
        tooltip:SetCell(currentLine, 2, limitsUnboundString)

        -- Infinite Power section
        AddSectionHeading(tooltip, "Your Infinite Power")
        local aura = Threads.ScanAura("player")
        if aura then
            local lines = Stats:GetStatLines(aura)
            for _, line in ipairs(lines) do
                local currentLine = tooltip:AddLine()
                tooltip:SetCell(currentLine, 1, colorize(line, Colors.White), "LEFT", 2)
            end
        end

        -- Threads section
        AddSectionHeading(tooltip, "Your Threads")
        local currentLine = tooltip:AddLine()
        tooltip:SetCell(currentLine, 1, "Total Threads")
        tooltip:SetCell(currentLine, 2, colorize(FormatWithCommasToThousands(totalThreads) .. " ", Colors.White))
        currentLine = tooltip:AddLine()
        tooltip:SetCell(currentLine, 1, "Gained")
        tooltip:SetCell(currentLine, 2, colorize("+ " .. FormatWithCommasToThousands(threadsGainedToday) .. " ", Colors.White))

        -- Currency section
        AddSectionHeading(tooltip, "Legion Remix Currency")
        AddCurrencyLine(tooltip, 3292)
        AddCurrencyLine(tooltip, 3268)
        AddCurrencyLine(tooltip, 3252)

        -- TODO: Artifact powers sections
        --addLinkLine(tooltip, "Disallowed Traits:", colors.Red, powers.disallow)
        --addLinkLine(tooltip, "Required Traits:", colors.Green, powers.required)
        --addLinkLine(tooltip, "Allowed Traits:", colors.White, powers.allow)
    else
        tooltip:AddHeader(colorize(KRemixHelper.Settings.AddonNameWithIcon, Colors.Header))
        tooltip:SetFont(Fonts.MainText)

        local currentLine = tooltip:AddLine()
        tooltip:SetCell(currentLine, 1, colorize("The current character is not a Legion Remix character", Colors.Grey), 2)
    end

    -- Footer
    tooltip:AddSeparator(3, 0, 0, 0, 0)
    tooltip:AddSeparator()
    tooltip:AddSeparator(3, 0, 0, 0, 0)

    tooltip:SetFont(Fonts.FooterText)
    tooltip:AddLine(colorize("Click icon to open weapon artifact tree", Colors.FooterDark))
    tooltip:AddLine(colorize("Right click icon for options", Colors.FooterDark))
end


--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

KRemixHelper.UI = KRemixHelper.UI or {}
KRemixHelper.UI.TooltipProvider = MinimapTooltipProvider
