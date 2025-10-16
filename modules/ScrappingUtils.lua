--[[-------------------------------------------------------------------------------
    ScrappingUtils.lua
    Purpose:
      - Core driver logic for scrapping automation
      - Handles bag scanning, slot filling, and scrap actions
    Notes:
      - Keeps UI and logic separate
      - Guards against combat lockdown
-------------------------------------------------------------------------------]]--

local _, Addon = ...
local const = {
    SCRAPPING_MACHINE = {
        MAX_SLOTS = 9,
    }
}

---@class ScrappingUtils
local ScrappingUtils = {}

--------------------------------------------------------------------------------
-- Bag Scanning
--------------------------------------------------------------------------------

---Iterate all bags and slots, yielding scrappable items.
---@return table items { bag, slot, link, quality, icon }
function ScrappingUtils:GetScrappableItems()
    local items = {}
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink then
                -- TODO: apply quality/level filters from settings
                table.insert(items, {
                    bag     = bag,
                    slot    = slot,
                    link    = info.hyperlink,
                    quality = info.quality,
                    icon    = info.iconFileID,
                })
            end
        end
    end
    return items
end

--------------------------------------------------------------------------------
-- Scrap Actions
--------------------------------------------------------------------------------

---Attempt to place an item into the scrapper.
---@param bag number
---@param slot number
---@return boolean success
function ScrappingUtils:ScrapItemFromBag(bag, slot)
    if InCombatLockdown() then return false end
    if CursorHasItem() then return false end  -- never start if cursor is busy

    -- Find a free scrap slot
    local freeIndex
    for i = 0, const.SCRAPPING_MACHINE.MAX_SLOTS - 1 do
        if not C_ScrappingMachineUI.GetCurrentPendingScrapItemLocationByIndex(i) then
            freeIndex = i
            break
        end
    end
    if not freeIndex then return false end

    local slots = { ScrappingMachineFrame.ItemSlots:GetChildren() }
    local targetSlot = slots[freeIndex + 1]
    if not targetSlot or not targetSlot:IsVisible() or not targetSlot:IsEnabled() then
        return false -- slot not usable yet
    end

    -- Now safely pick up and place
    C_Container.PickupContainerItem(bag, slot)
    targetSlot:Click()

    -- Defensive: if we’re still holding something, abort and clear
    if CursorHasItem() then
        ClearCursor()
        return false
    end

    return true
end


---Top up the scrapper until full or no items remain.
function ScrappingUtils:AutoScrap()
    if InCombatLockdown() then return end

    local items = self:GetScrappableItems()
    if not items or #items == 0 then return end

    -- Count how many slots are already filled
    local filled = 0
    for i = 0, Addon.ScrappingConst.SCRAPPING_MACHINE.MAX_SLOTS - 1 do
        if C_ScrappingMachineUI.GetCurrentPendingScrapItemLocationByIndex(i) then
            filled = filled + 1
        end
    end

    -- Fill until slots are full or items run out
    for _, item in ipairs(items) do
        if filled >= Addon.ScrappingConst.SCRAPPING_MACHINE.MAX_SLOTS then break end
        if self:ScrapItemFromBag(item.bag, item.slot) then
            filled = filled + 1
        end
    end
end


--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.ScrappingUtils = ScrappingUtils
Addon.ScrappingConst = const