--[[-------------------------------------------------------------------------
  AutoScrapper.lua
  Purpose:
    - Core scrapping logic
    - Filtering (maxQuality, protectHigherIlvl via equipped comparison)
    - Auto-fill via FillNextBatch(), called by UI/events
  Notes:
    - Never calls ScrapItems() (protected). Piggybacks on player Scrap clicks.
---------------------------------------------------------------------------]]

local _, Addon = ...

local kprint = Addon.Settings.kprint

---@class AutoScrapper
local AutoScrapper = {}
Addon.AutoScrapper = AutoScrapper


--------------------------------------------------------------------------------
-- Settings (fallback defaults)
--------------------------------------------------------------------------------

AutoScrapper.settings = {
    autoFillScrapper  = true,
    protectHigherIlvl = true,
    maxQuality        = Enum.ItemQuality.Rare,
}


--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SCRAPPING_MACHINE_SLOTS = 9


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function GetProfile()
    local ace = Addon.LibAceAddon
    if ace and ace.db and ace.db.profile then
        return ace.db.profile
    end
    return AutoScrapper.settings
end

local INVTYPE_TO_SLOTS = {
    [Enum.InventoryType.IndexHeadType]            = { INVSLOT_HEAD },
    [Enum.InventoryType.IndexNeckType]            = { INVSLOT_NECK },
    [Enum.InventoryType.IndexShoulderType]        = { INVSLOT_SHOULDER },
    [Enum.InventoryType.IndexBodyType]            = { INVSLOT_BODY },
    [Enum.InventoryType.IndexChestType]           = { INVSLOT_CHEST },
    [Enum.InventoryType.IndexWaistType]           = { INVSLOT_WAIST },
    [Enum.InventoryType.IndexLegsType]            = { INVSLOT_LEGS },
    [Enum.InventoryType.IndexFeetType]            = { INVSLOT_FEET },
    [Enum.InventoryType.IndexWristType]           = { INVSLOT_WRIST },
    [Enum.InventoryType.IndexHandType]            = { INVSLOT_HAND },
    [Enum.InventoryType.IndexFingerType]          = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
    [Enum.InventoryType.IndexTrinketType]         = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
    [Enum.InventoryType.IndexCloakType]           = { INVSLOT_BACK },
    [Enum.InventoryType.IndexTabardType]          = { INVSLOT_TABARD },
    [Enum.InventoryType.IndexRobeType]            = { INVSLOT_CHEST },
    [Enum.InventoryType.IndexWeaponType]          = { INVSLOT_MAINHAND },
    [Enum.InventoryType.Index2HweaponType]        = { INVSLOT_MAINHAND },
    [Enum.InventoryType.IndexWeaponmainhandType]  = { INVSLOT_MAINHAND },
    [Enum.InventoryType.IndexWeaponoffhandType]   = { INVSLOT_OFFHAND },
    [Enum.InventoryType.IndexShieldType]          = { INVSLOT_OFFHAND },
    [Enum.InventoryType.IndexHoldableType]        = { INVSLOT_OFFHAND },
    [Enum.InventoryType.IndexRangedType]          = { INVSLOT_MAINHAND },
    [Enum.InventoryType.IndexRangedrightType]     = { INVSLOT_MAINHAND },
    [Enum.InventoryType.IndexThrownType]          = { INVSLOT_MAINHAND },
    [Enum.InventoryType.IndexRelicType]           = { INVSLOT_MAINHAND },
}

local function GetLinkItemLevel(link)
    if not link then return 0 end
    local ilvl = C_Item.GetDetailedItemLevelInfo(link)
    return ilvl or 0
end

local function IsHigherThanEquipped(invType, candidateIlvl)
    if not invType or candidateIlvl <= 0 then
        return false
    end
    local slots = INVTYPE_TO_SLOTS[invType]
    if not slots then
        return false
    end
    for _, slotId in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slotId)
        local equippedIlvl = GetLinkItemLevel(equippedLink)
        if candidateIlvl > equippedIlvl then
            return true
        end
    end
    return false
end


--------------------------------------------------------------------------------
-- Filtering
--------------------------------------------------------------------------------

function AutoScrapper:IsEligible(itemInfo)
    local profile = GetProfile()
    local maxQ = profile.maxQuality or Enum.ItemQuality.Rare

    if itemInfo.quality and itemInfo.quality > maxQ then
        kprint("Reject", itemInfo.link or "?", "quality", itemInfo.quality, "> max", maxQ)
        return false
    end

    if profile.protectHigherIlvl and itemInfo.invType then
        if IsHigherThanEquipped(itemInfo.invType, itemInfo.itemLevel or 0) then
            kprint("Reject", itemInfo.link or "?", "ilvl", itemInfo.itemLevel or 0, "higher than equipped")
            return false
        end
    end

    kprint("Accept", itemInfo.link or "?", "ilvl", itemInfo.itemLevel or 0, "quality", itemInfo.quality or -1)
    return true
end


--------------------------------------------------------------------------------
-- Scrappable items
--------------------------------------------------------------------------------

function AutoScrapper:GetScrappableItems()
    local items = {}
    local profile = GetProfile()
    kprint("=== Scrapper Scan Start ===")
    kprint("Settings:", "autoFillScrapper", profile.autoFillScrapper,
           "protectHigherIlvl", profile.protectHigherIlvl, "maxQuality", profile.maxQuality)

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info then
                local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                if itemLoc:IsValid() and C_Item.CanScrapItem(itemLoc) then
                    local invType   = C_Item.GetItemInventoryType(itemLoc)
                    local itemLevel = C_Item.GetCurrentItemLevel(itemLoc)
                    local itemInfo  = {
                        bag       = bag,
                        slot      = slot,
                        link      = info.hyperlink,
                        icon      = info.iconFileID,
                        quality   = info.quality,
                        itemLevel = itemLevel,
                        invType   = invType,
                    }

                    kprint("Checking", itemInfo.link or "?", "bag", bag, "slot", slot,
                           "ilvl", itemLevel or -1, "quality", info.quality or -1, "invType", invType or -1)

                    if self:IsEligible(itemInfo) then
                        kprint(" -> Accepted")
                        table.insert(items, itemInfo)
                    else
                        kprint(" -> Rejected by filters")
                    end
                end
            end
        end
    end

    kprint("=== Scrapper Scan Complete:", #items, "items eligible ===")
    return items
end


--------------------------------------------------------------------------------
-- Scrapping actions
--------------------------------------------------------------------------------

function AutoScrapper:ScrapItemFromBag(bag, slot)
    kprint("Attempting to scrap bag", bag, "slot", slot)

    local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not (itemLoc and itemLoc:IsValid()) then
        return false
    end
    if not C_Item.CanScrapItem(itemLoc) then
        return false
    end

    C_Container.PickupContainerItem(bag, slot)
    if not CursorHasItem() then
        return false
    end

    -- Iterate the 9 slot buttons in order
    local children = { ScrappingMachineFrame.ItemSlots:GetChildren() }
    for idx, slotFrame in ipairs(children) do
        local pending = C_ScrappingMachineUI.GetCurrentPendingScrapItemLocationByIndex(idx - 1)
        if not pending then
            slotFrame:Click()
            local link = C_Container.GetContainerItemLink(bag, slot)
            kprint("Placed", link or "?", "into scrapper slot", idx)
            return true
        end
    end

    ClearCursor()
    kprint("No free scrapper slot for bag", bag, "slot", slot)
    return false
end

local function GetFreeScrapperSlot()
    for i = 1, 9 do
        if not C_ScrappingMachineUI.GetCurrentPendingScrapItemLocationByIndex(i - 1) then
            return i
        end
    end
    return nil
end

function AutoScrapper:FillNextBatch()
    if self._filling then return end
    self._filling = true

    kprint("Filling next batch...")
    if InCombatLockdown() or not (ScrappingMachineFrame and ScrappingMachineFrame:IsShown()) then
        self._filling = false
        return
    end

    local items = self:GetScrappableItems()
    local filled = 0

    for _, item in ipairs(items) do
        local freeSlot = GetFreeScrapperSlot()
        if not freeSlot then
            kprint("Scrapper full, stopping fill")
            break
        end
        if self:ScrapItemFromBag(item.bag, item.slot) then
            filled = filled + 1
        end
    end

    kprint("Batch fill complete", filled, "items placed")
    self._filling = false
end


--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.AutoScrapper = AutoScrapper
