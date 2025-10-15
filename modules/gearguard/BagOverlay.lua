--[[============================================================================
  BagOverlay.lua
  Purpose:
    - Adds visual cues to bag items based on artifact-like powers
  Notes:
    - Colors borders green for must-have, red for disallowed
    - Uses BAG_UPDATE_DELAYED event to rescan bags, since old update functions
      are no longer global in Dragonflight/Remix
============================================================================]]--

local _, Addon     = ...
local addonName    = Addon.Settings.AddonName
local ParentAceAddon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class BagOverlay : AceModule
local BagOverlay = ParentAceAddon:NewModule("BagOverlay", "AceEvent-3.0")

local lists = Addon.ArtifactPowers



--------------------------------------------------------------------------------
-- Tooltip Scanner
--------------------------------------------------------------------------------

-- Tooltip scanner for keyword detection
local scanner = CreateFrame("GameTooltip", "KRemixHelperBagScanner", nil, "GameTooltipTemplate")
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
        local line = _G["KRemixHelperBagScannerTextLeft" .. i]
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
-- Bag Scanning
--------------------------------------------------------------------------------

---Scan all bags and recolor borders based on artifact power keywords.
local function RescanBags()
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local button = _G["ContainerFrame" .. (bag + 1) .. "Item" .. slot]
            if button and button.IconBorder then
                local link = C_Container.GetContainerItemLink(bag, slot)
                if link then
                    local isGood = ItemHasKeyword(link, lists.allow)
                    local isBad  = ItemHasKeyword(link, lists.disallow)

                    if isGood then
                        button.IconBorder:SetVertexColor(0, 1, 0) -- green
                    elseif isBad then
                        button.IconBorder:SetVertexColor(1, 0, 0) -- red
                    else
                        button.IconBorder:SetVertexColor(1, 1, 1) -- default white
                    end
                else
                    button.IconBorder:SetVertexColor(1, 1, 1)
                end
            end
        end
    end
end



--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

---Enable the BagOverlay module.
function BagOverlay:OnEnable()
    -- Rescan bags whenever contents change
    self:RegisterEvent("BAG_UPDATE_DELAYED", function()
        RescanBags()
    end)

    -- Initial scan when addon loads
    RescanBags()
end
