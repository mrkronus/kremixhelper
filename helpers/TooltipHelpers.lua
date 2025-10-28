--[[-----------------------------------------------------------------------------
  TooltipHelpers.lua
  Purpose:
    - Provide helper functions for building LibQTip-based tooltips
    - Add section headings, sub-tooltips, and currency lines
    - Provide formatting helpers for Infinite Power and Limits Unbound
  Notes:
    - All functions are namespaced under Addon.TooltipHelpers
    - Defensive coding ensures safe fallbacks
-------------------------------------------------------------------------------]]--

local _, Addon = ...

local Fonts    = Addon.Fonts
local Colors   = Addon.Colors
local colorize = Addon.Colorize
local LibQTip  = Addon.LibQTip

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class TooltipHelpers
local TooltipHelpers = {}
Addon.TooltipHelpers = TooltipHelpers

-- Constants
local LIMITS_UNBOUND_SPELL_ID    = 1245947
local INFINITE_POWER_CURRENCY_ID = 3268
local COST_TO_UNLOCK_TREE        = 114125
local COST_PER_RANK              = 50000
local INV_MISC_QUESTIONMARK      = 134400

--------------------------------------------------------------------------------
-- Content Helpers
--------------------------------------------------------------------------------

---Add a section heading with separators and font changes.
---@param tooltip table
---@param sectionName string
function TooltipHelpers.AddSectionHeading(tooltip, sectionName)
    tooltip:AddSeparator(10, 0, 0, 0, 0)
    tooltip:SetFont(Fonts.Heading)
    local currentLine = tooltip:AddLine()
    tooltip:SetCell(currentLine, 1, colorize(sectionName, Colors.Header), nil, "LEFT", tooltip:GetColumnCount())
    tooltip:AddSeparator()
    tooltip:AddSeparator(3, 0, 0, 0, 0)
    tooltip:SetFont(Fonts.MainText)
end

---Attach a tooltip script to a line.
---@param tooltip table
---@param lineIndex number
---@param onEnter fun(cell: Frame)
function TooltipHelpers.AddTooltipToLine(tooltip, lineIndex, onEnter)
    tooltip:SetLineScript(lineIndex, "OnEnter", onEnter)
    tooltip:SetLineScript(lineIndex, "OnLeave", function() GameTooltip:Hide() end)
end

---Add a sub-tooltip line that spawns another tooltip on hover.
---@param tooltip table
---@param label string
---@param populateFunc fun(subTip: table)
function TooltipHelpers.AddSubTooltipLine(tooltip, label, populateFunc)
    local line = tooltip:AddLine()
    tooltip:SetCell(line, 1, label, nil, "LEFT")
    tooltip:SetCell(line, tooltip:GetColumnCount(), " >", nil, "RIGHT")

    tooltip:SetLineScript(line, "OnEnter", function(cell)
        local subTip = LibQTip:Acquire("AddonSubTooltip", 1, "LEFT")
        subTip:Clear()

        local x = cell:GetCenter()
        local screenWidth = UIParent:GetWidth()

        if x < screenWidth / 2 then
            subTip:SetPoint("LEFT", cell, "TOPRIGHT", 0, 0)
        else
            subTip:SetPoint("RIGHT", cell, "TOPLEFT", 0, 0)
        end

        subTip:SetAutoHideDelay(1, UIParent)
        populateFunc(subTip)
        subTip:Show()
    end)

    tooltip:SetLineScript(line, "OnLeave", function()
        LibQTip:Release(LibQTip:Acquire("AddonSubTooltip"))
    end)
end

---Add a currency line to the tooltip if the player has any of it.
---@param tooltip table
---@param currencyID number
function TooltipHelpers.AddCurrencyLine(tooltip, currencyID)
    local name, quantity, icon = Addon.Currency:Get(currencyID)
    if quantity and quantity > 0 then
        local iconString = icon and ("|T%d:0|t"):format(icon) or ""
        local line = tooltip:AddLine()
        tooltip:SetCell(line, 1, name)
        tooltip:SetCell(line, 2, Addon.FormatWithCommas(quantity) .. " " .. iconString)
        TooltipHelpers.AddTooltipToLine(tooltip, line, function(cell)
            GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
            GameTooltip:SetCurrencyByID(currencyID)
            GameTooltip:Show()
        end)
    end
end

--------------------------------------------------------------------------------
-- Formatting Helpers
--------------------------------------------------------------------------------

---Get current Infinite Power quantity.
---@return number
function TooltipHelpers.GetInfinitePowerQty()
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return 0 end
    local ci = C_CurrencyInfo.GetCurrencyInfo(INFINITE_POWER_CURRENCY_ID)
    return (ci and ci.quantity) or 0
end

---Get a spell icon texture ID.
---@param spellID number
---@return number
function TooltipHelpers.GetSpellIcon(spellID)
    if not spellID or not C_Spell.GetSpellTexture then return INV_MISC_QUESTIONMARK end
    return C_Spell.GetSpellTexture(spellID) or INV_MISC_QUESTIONMARK
end

---Calculate Limits Unbound rank and return as string.
---@return string
function TooltipHelpers.GetLimitsUnboundRankString()
    local ipQty = TooltipHelpers.GetInfinitePowerQty()
    local available = math.max(0, ipQty - COST_TO_UNLOCK_TREE)
    local rank = math.floor(available / COST_PER_RANK)
    return tostring(rank)
end
