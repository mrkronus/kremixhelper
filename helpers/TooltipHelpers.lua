--[[-------------------------------------------------------------------------
TooltipHelpers.lua
---------------------------------------------------------------------------]]

local _, KRemixHelper            = ...

local Fonts                      = KRemixHelper.Fonts
local Colors                     = KRemixHelper.Colors

local LibQTip                    = KRemixHelper.LibQTip

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
---@param sectionName string
function AddSectionHeading(tooltip, sectionName)
    tooltip:AddSeparator(10, 0, 0, 0, 0)
    tooltip:SetFont(Fonts.Heading)
    local currentLine = tooltip:AddLine()
    tooltip:SetCell(currentLine, 1, colorize(sectionName, Colors.Header), nil, "LEFT", tooltip:GetColumnCount())
    tooltip:AddSeparator()
    tooltip:AddSeparator(3, 0, 0, 0, 0)
    tooltip:SetFont(Fonts.MainText)
end

---@param tooltip table
---@param onEnter fun(cell: Frame)
function AddTooltipToLine(tooltip, lineIndex, onEnter)
    tooltip:SetLineScript(lineIndex, "OnEnter", onEnter)
    tooltip:SetLineScript(lineIndex, "OnLeave", function() GameTooltip:Hide() end)
end

function AddSubTooltipLine(tooltip, label, populateFunc)
    local line = tooltip:AddLine()
    tooltip:SetCell(line, 1, label, nil, "LEFT")
    tooltip:SetCell(line, tooltip:GetColumnCount(), " >", nil, "RIGHT")

    tooltip:SetLineScript(line, "OnEnter", function(cell)
        -- Acquire a new tooltip
        local subTip = LibQTip:Acquire("KRemixHelperSubTooltip", 1, "LEFT")
        subTip:Clear()

        -- Decide which side of the screen we’re on
        local x = cell:GetCenter()
        local screenWidth = UIParent:GetWidth()

        if x < screenWidth / 2 then
            -- Anchor to the right of the cell
            subTip:SetPoint("LEFT", cell, "TOPRIGHT", 0, 0)
        else
            -- Anchor to the left of the cell
            subTip:SetPoint("RIGHT", cell, "TOPLEFT", 0, 0)
        end

        subTip:SetAutoHideDelay(1, UIParent)

        -- Populate with the requested view
        populateFunc(subTip)

        subTip:Show()
    end)

    tooltip:SetLineScript(line, "OnLeave", function()
        -- LibQTip handles auto‑hide, but you can force release if needed:
        LibQTip:Release(LibQTip:Acquire("KRemixHelperSubTooltip"))
    end)
end

---Add a currency line to the tooltip if the player has any of it.
---@param tooltip table
---@param currencyID number
function AddCurrencyLine(tooltip, currencyID)
    local name, quantity, icon = KRemixHelper.Currency:Get(currencyID)
    if quantity and quantity > 0 then
        local iconString = icon and ("|T%d:0|t"):format(icon) or ""
        local line = tooltip:AddLine()
        tooltip:SetCell(line, 1, name)
        tooltip:SetCell(line, 2, FormatWithCommas(quantity) .. " " .. iconString)
        AddTooltipToLine(tooltip, line, function(cell)
            GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
            GameTooltip:SetCurrencyByID(currencyID)
            GameTooltip:Show()
        end)
    end
end


--------------------------------------------------------------------------------
-- Formatting Helpers
--------------------------------------------------------------------------------

-- Function to get current Infinite Power
function GetInfinitePowerQty()
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return 0 end
    local ci = C_CurrencyInfo.GetCurrencyInfo(INFINITE_POWER_CURRENCY_ID)
    return (ci and ci.quantity) or 0
end

-- Function to get a spell icon
function GetSpellIcon(spellID)
    if not spellID or not C_Spell.GetSpellTexture then return INV_MISC_QUESTIONMARK end
    return C_Spell.GetSpellTexture(spellID) or INV_MISC_QUESTIONMARK
end

-- Function to calculate Limits Unbound rank and format string
function GetLimitsUnboundRankString()
    local ipQty = GetInfinitePowerQty()
    local available = math.max(0, ipQty - COST_TO_UNLOCK_TREE)
    local rank = math.floor(available / COST_PER_RANK)
    local icon = ("|T%d:0|t"):format(GetSpellIcon(LIMITS_UNBOUND_SPELL_ID)) or ""
    return tostring(rank)
end