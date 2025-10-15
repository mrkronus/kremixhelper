--[[============================================================================
  GearGuard.lua
  Purpose:
    - Monitors equipment changes and warns when must-have powers are removed
      or disallowed powers are equipped
  Notes:
    - Uses tooltip scanning to detect keywords
    - Keeps a cache of last equipped items for comparison
============================================================================]]--

local _, Addon     = ...
local addonName    = Addon.Settings.AddonName
local ParentAceAddon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class GearGuard : AceModule
local GearGuard = ParentAceAddon:NewModule("GearGuard", "AceEvent-3.0")

local lists = Addon.ArtifactPowers



--------------------------------------------------------------------------------
-- Tooltip Scanner
--------------------------------------------------------------------------------

-- Tooltip scanner reused for keyword detection
local scanner = CreateFrame("GameTooltip", "KRemixHelperScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(UIParent, "ANCHOR_NONE")

---Check if an item contains any keyword from a list.
---@param itemLink string
---@param keywords string[]
---@return boolean, string|nil
local function ItemHasKeyword(itemLink, keywords)
    if not itemLink then
        return false
    end

    scanner:ClearLines()
    scanner:SetHyperlink(itemLink)

    for i = 1, scanner:NumLines() do
        local line = _G["KRemixHelperScannerTextLeft" .. i]
        if line then
            local text = line:GetText() or ""
            for _, keyword in ipairs(keywords) do
                if text:find(keyword) then
                    return true, keyword
                end
            end
        end
    end

    return false
end



--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

---Enable the GearGuard module.
function GearGuard:OnEnable()
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end



--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

---Event: Fires when equipment changes.
---@param _ any Event frame (unused)
---@param slot number Equipment slot ID
---@param hasItem boolean Whether the slot now has an item
function GearGuard:PLAYER_EQUIPMENT_CHANGED(_, slot, hasItem)
    if not hasItem then
        -- Item removed: check if it was a must-have
        local oldLink = self.lastEquipped and self.lastEquipped[slot]
        if oldLink then
            local isGood, key = ItemHasKeyword(oldLink, lists.allow)
            if isGood then
                UIErrorsFrame:AddMessage("Removed MUST-HAVE bonus: " .. key, 1, 1, 0)
            end
        end
    else
        -- Item equipped: check if it is disallowed
        local link = GetInventoryItemLink("player", slot)
        if link then
            local isBad, key = ItemHasKeyword(link, lists.disallow)
            if isBad then
                UIErrorsFrame:AddMessage("Equipped DISALLOWED bonus: " .. key, 1, 0, 0)
            end

            -- Cache last equipped item for this slot
            self.lastEquipped = self.lastEquipped or {}
            self.lastEquipped[slot] = link
        end
    end
end
