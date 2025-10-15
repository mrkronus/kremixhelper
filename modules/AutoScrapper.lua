--[[-------------------------------------------------------------------------------
    AutoScrapper.lua
    Purpose:
      Core logic for scanning bags and scrapping items.
    Notes:
      - Provides filtering logic for scrappable items
      - Handles both manual and automated scrapping flows
-------------------------------------------------------------------------------]]--

local _, Addon = ...


--------------------------------------------------------------------------------
-- Shared Globals
--------------------------------------------------------------------------------

---@class AutoScrapper
local AutoScrapper = {
    settings = {
        maxQuality   = Enum.ItemQuality.Rare, -- Maximum item quality to scrap
        minLevelDiff = 0,                     -- Minimum ilvl difference vs equipped
        autoScrap    = false,                 -- Legacy toggle for auto-scrap batch
        autoFill     = true,                  -- Auto-fill scrapper on open
        autoScrapAll = false,                 -- Continuous auto-scrap loop
    }
}
Addon.AutoScrapper = AutoScrapper


--------------------------------------------------------------------------------
-- Item Scanning
--------------------------------------------------------------------------------

---Scan all bags for scrappable items that meet quality and ilvl thresholds.
---@return table items List of candidate items with bag/slot/link/icon/quality
function AutoScrapper:GetScrappableItems()
    local items = {}

    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)

            if loc:IsValid() and C_Item.CanScrapItem(loc) then
                local quality   = C_Item.GetItemQuality(loc)
                local ilvl      = C_Item.GetCurrentItemLevel(loc)
                local invType   = C_Item.GetItemInventoryType(loc)
                local equipped  = self:GetEquippedLevel(invType)

                -- Intent: only scrap items below configured quality and ilvl threshold
                if quality
                    and quality <= self.settings.maxQuality
                    and equipped
                    and (equipped - ilvl) >= self.settings.minLevelDiff
                then
                    table.insert(items, {
                        bag     = bag,
                        slot    = slot,
                        link    = C_Item.GetItemLink(loc),
                        icon    = C_Item.GetItemIcon(loc),
                        quality = quality,
                    })
                end
            end
        end
    end

    return items
end


--------------------------------------------------------------------------------
-- Equipped Level Baseline
--------------------------------------------------------------------------------

---Get the currently equipped item level baseline.
---@param invType number Inventory type (unused, reserved for future logic)
---@return number equipped Equipped item level
function AutoScrapper:GetEquippedLevel(invType)
    local avg, equipped = GetAverageItemLevel()
    return equipped
end


--------------------------------------------------------------------------------
-- Scrapping Operations
--------------------------------------------------------------------------------

---Queue a single item into the scrapper.
---@param bag number Bag ID
---@param slot number Slot ID
function AutoScrapper:ScrapItem(bag, slot)
    C_Container.PickupContainerItem(bag, slot)

    -- Intent: find the first empty scrapper slot and click it
    for i = 1, 9 do
        if not C_ScrappingMachineUI.GetCurrentPendingScrapItemLocationByIndex(i - 1) then
            local slots = { ScrappingMachineFrame.ItemSlots:GetChildren() }
            slots[i]:Click()
            return
        end
    end

    -- Defensive: clear cursor if no slot was available
    ClearCursor()
end


--------------------------------------------------------------------------------
-- Automation Helpers
--------------------------------------------------------------------------------

---Trigger auto-scrap batch if enabled.
function AutoScrapper:AutoScrap()
    if not self.settings.autoScrap then
        return
    end
    self:ScrapAllNow()
end

---Scrap all items immediately:
--- - Clears existing slots
--- - Fills with eligible items
--- - Clicks Blizzard's Scrap button
function AutoScrapper:ScrapAllNow()
    if not ScrappingMachineFrame or not ScrappingMachineFrame:IsShown() then
        return
    end

    -- Clear any existing items
    C_ScrappingMachineUI.RemoveAllScrapItems()

    -- Fill slots with filtered items
    for _, item in ipairs(self:GetScrappableItems()) do
        self:ScrapItem(item.bag, item.slot)
    end

    -- Trigger Blizzard’s Scrap button if enabled
    if ScrappingMachineFrame.ScrapButton and ScrappingMachineFrame.ScrapButton:IsEnabled() then
        ScrappingMachineFrame.ScrapButton:Click()
    end
end
