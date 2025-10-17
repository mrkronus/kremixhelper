--[[============================================================================
  TooltipProvider.lua
  Purpose:
    - Provide tooltip content for the minimap icon
    - Display Threads totals, currency, stat breakdown, and artifact powers
============================================================================]]--

local _, KRemixHelper = ...

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



--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

---Handle minimap icon clicks.
---@param clickedFrame Frame
---@param button string
function MinimapTooltipProvider:OnIconClick(clickedFrame, button)
    if button == "LeftButton" then
        -- TODO: define left-click behavior
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
    local fonts   = KRemixHelper.Fonts
    local colors  = KRemixHelper.Colors
    local powers  = KRemixHelper.ArtifactPowers
    local Threads = KRemixHelper.ThreadsTracker
    local Stats   = KRemixHelper.StatsTracker

    ---Add a section heading with separators and font changes.
    ---@param sectionName string
    local function AddSectionHeading(sectionName)
        tooltip:AddSeparator(10, 0, 0, 0, 0)
        tooltip:SetFont(fonts.Heading)
        tooltip:AddLine(colorize(sectionName, colors.SubHeader))
        tooltip:AddSeparator()
        tooltip:AddSeparator(3, 0, 0, 0, 0)
        tooltip:SetFont(fonts.MainText)
    end

    tooltip:Clear()
    tooltip:SetFont(fonts.MainHeader)
    tooltip:AddHeader(colorize(KRemixHelper.Settings.AddonNameWithIcon, colors.Header))
    tooltip:SetFont(fonts.MainText)

    -- Infinite Power section
    AddSectionHeading("Your Infinite Power")
    local aura = Threads.ScanAura("player")
    if aura then
        local lines = Stats:GetStatLines(aura)
        for _, line in ipairs(lines) do
            currentLine = tooltip:AddLine()
            tooltip:SetCell(currentLine, 1, colorize(line, colors.White), "LEFT", 2)
        end
    end

    -- Threads section
    AddSectionHeading("Your 'Threads'")
    local total, today = Threads:GetPlayerData()
    local currentLine = tooltip:AddLine()
    tooltip:SetCell(currentLine, 1, "Total Threads")
    tooltip:SetCell(currentLine, 2, colorize(FormatWithCommasToThousands(total) .. " ", colors.White))
    currentLine = tooltip:AddLine()
    tooltip:SetCell(currentLine, 1, "Gained Today")
    tooltip:SetCell(currentLine, 2, colorize("+" .. FormatWithCommasToThousands(today) .. " ", colors.White))

    -- Currency section
    AddSectionHeading("Legion Remix Currency")
    AddCurrencyLine(tooltip, 3292)
    AddCurrencyLine(tooltip, 3268)
    AddCurrencyLine(tooltip, 3252)

    ---Add a section of clickable spell links.
    ---@param headerText string
    ---@param headerColor table
    ---@param entries table
    local function addLinkLine(headerText, headerColor, entries)
        if #entries == 0 then return end
        AddSectionHeading(colorize(headerText, headerColor))
        for _, entry in ipairs(entries) do
            currentLine = tooltip:AddLine()
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

    -- TODO: Artifact powers sections
    --addLinkLine("Disallowed Traits:", colors.Red, powers.disallow)
    --addLinkLine("Required Traits:", colors.Green, powers.required)
    -- addLinkLine("Allowed Traits:", colors.White, powers.allow)

    -- Footer
    tooltip:AddSeparator(3, 0, 0, 0, 0)
    tooltip:AddSeparator()
    tooltip:AddSeparator(3, 0, 0, 0, 0)

    tooltip:SetFont(fonts.FooterText)
    tooltip:AddLine(colorize("Right click icon for options", colors.FooterDark))
end


--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

KRemixHelper.UI = KRemixHelper.UI or {}
KRemixHelper.UI.TooltipProvider = MinimapTooltipProvider
