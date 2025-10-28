--[[============================================================================
  MinimapTooltip.lua
  Purpose:
    - Provides a LibQTip-based tooltip for the minimap icon
    - Delegates content population to a provider module
  Notes:
    - Uses LibQTip for flexible multi-column tooltips
    - Provider can be swapped dynamically
============================================================================]]--

local _, Addon = ...

local addonName        = Addon.Settings.AddonName
local addonTooltipName = Addon.Settings.AddonTooltipName

local LibQTip = LibStub("LibQTip-1.0")
Addon.LibQTip = LibQTip

local tooltip, provider

---@class ParentAceAddon : AceAddon
local ParentAceAddon = LibStub("AceAddon-3.0"):GetAddon(addonName)


--------------------------------------------------------------------------------
-- MinimapTooltip Module
--------------------------------------------------------------------------------

---@class MinimapTooltip : AceModule
local MinimapTooltip = ParentAceAddon:NewModule("MinimapTooltip")

---Initialize the module (reserved for future state/events).
function MinimapTooltip:OnInitialize()
    -- Reserved for future state, events, etc.
end

---Set the provider responsible for populating the tooltip.
---@param newProvider table
function MinimapTooltip:SetProvider(newProvider)
    provider = newProvider
end

---Show the minimap tooltip anchored to a frame.
---@param anchor Frame
---@return table tooltip
function MinimapTooltip:ShowTooltip(anchor)
    if tooltip then
        tooltip:Release()
    end

    tooltip = LibQTip:Acquire(addonTooltipName, 2, "LEFT", "RIGHT")
    tooltip:SmartAnchorTo(anchor)
    tooltip:SetAutoHideDelay(0.1, anchor, function()
        tooltip:Release()
        tooltip = nil
    end)

    self:PopulateTooltip(tooltip)

    tooltip:UpdateScrolling()
    tooltip:Show()
    return tooltip
end

---Populate the tooltip with content from the provider.
---@param tooltip table
function MinimapTooltip:PopulateTooltip(tooltip)
    tooltip:Clear()
    if provider and provider.PopulateTooltip then
        provider:PopulateTooltip(tooltip)
    else
        tooltip:AddHeader(addonTooltipName)
    end
end

---Refresh the tooltip if it is currently visible.
function MinimapTooltip:Refresh()
    if tooltip then
        self:PopulateTooltip(tooltip)
        tooltip:Show()
    end
end

---Check if the tooltip is currently visible.
---@return boolean
function MinimapTooltip:IsVisible()
    return tooltip and tooltip:IsShown()
end
