--[[-----------------------------------------------------------------------------
  ArtifactWeapon.lua
  Purpose:
    - Provide accessors for artifact weapon metrics
    - Support querying average weapon item level
    - Support querying increased trait spells and their ranks
  Notes:
    - Uses C_Item and C_Traits APIs
    - Defensive coding: always checks for nils and empty lists
-------------------------------------------------------------------------------]]--

local _, Addon = ...

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------

-- NodeID, EntryID, DefinitionID triplets for traits that can be modified
local ModifiableArtifactTraits = {
    { 108106, 133489, 138275 }, -- Souls of the Caw
    { 108110, 133493, 138279 }, -- Highmountain Fortitude
    { 108702, 134248, 139024 }, -- Touch of Malice
    { 108105, 133488, 138274 }, -- I Am My Scars!
    { 108132, 133525, 138311 }, -- Call of the Legion
    { 108102, 133485, 138271 }, -- Volatile Magics
    { 108103, 133486, 138272 }, -- Arcane Aegis
    { 108103, 133508, 138294 }, -- Arcane Ward
    { 108107, 133490, 138276 }, -- Temporal Retaliation
    { 108108, 133491, 138277 }, -- Terror From Below
    { 108104, 133487, 138273 }, -- Storm Surger
    { 108104, 135715, 140470 }, -- Brewing Storm
    { 109265, 135326, 140093 }, -- Light's Vengeance
}

--------------------------------------------------------------------------------
-- Helpers (private)
--------------------------------------------------------------------------------

---Get the total increased trait rank for a given node/entry.
---@param nodeID number
---@param entryID number
---@return number totalIncreased
local function GetIncreasedTraitRankForNodeEntry(nodeID, entryID)
    local totalIncreased = 0
    local increasedTraitDataList = C_Traits.GetIncreasedTraitData(nodeID, entryID)
    if increasedTraitDataList and #increasedTraitDataList > 0 then
        for _, increasedTraitData in ipairs(increasedTraitDataList) do
            totalIncreased = totalIncreased + (increasedTraitData.numPointsIncreased or 0)
        end
    end
    return totalIncreased
end

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class ArtifactWeapon
local ArtifactWeapon = {}

---Get the average item level of the equipped artifact weapon.
---If both main-hand and off-hand are present, averages them.
---If only one is present, returns that one’s ilvl.
---Returns 0 if no artifact weapon is equipped.
---@return number avgItemLevel
function ArtifactWeapon:GetAverageItemLevel()
    local mhLoc = ItemLocation:CreateFromEquipmentSlot(INVSLOT_MAINHAND)
    local ohLoc = ItemLocation:CreateFromEquipmentSlot(INVSLOT_OFFHAND)

    local mh = (mhLoc and mhLoc:IsValid()) and C_Item.GetCurrentItemLevel(mhLoc) or 0
    local oh = (ohLoc and ohLoc:IsValid()) and C_Item.GetCurrentItemLevel(ohLoc) or 0

    local count = (mh > 0 and 1 or 0) + (oh > 0 and 1 or 0)
    if count == 0 then
        return 0
    end

    return (mh + oh) / count
end

---Get all increased trait spells and their total ranks.
---Iterates over ModifiableArtifactTraits and returns only those with >0 increase.
---@return table[]|nil list { { spellID:number, totalIncreased:number }, ... }
function ArtifactWeapon:GetIncreasedTraitSpellsAndRanks()
    local results = {}
    for _, value in ipairs(ModifiableArtifactTraits) do
        local nodeID, entryID, definitionID = value[1], value[2], value[3]
        local totalIncreased = GetIncreasedTraitRankForNodeEntry(nodeID, entryID)
        if totalIncreased > 0 then
            local definitionInfo = C_Traits.GetDefinitionInfo(definitionID)
            local spellID = definitionInfo and definitionInfo.spellID
            if spellID then
                table.insert(results, { spellID, totalIncreased })
            end
        end
    end
    if #results > 0 then
        return results
    end
    return nil
end

---Returns a list of currently equipped Artifact weapons with metadata.
---Deduplicates identical weapons across slots.
---@return table[] weapons List of weapon tables with fields:
---  icon: number|nil — Texture ID for the weapon icon
---  text: string — Localized item name
---  itemID: number — Numeric item ID
---  link: string — Full item link string
---  slot: number — Inventory slot used (16, 17, or 18)
function ArtifactWeapon:GetEquippedArtifactWeapons()
    local slots = {16, 17, 18} -- Main hand, Off-hand, Ranged
    local seen = {}
    local weapons = {}

    for _, slot in ipairs(slots) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local icon = GetInventoryItemTexture("player", slot)
            local itemName, _, _, _, _, _, _, _, _, texture, itemID = C_Item.GetItemInfo(link)
            if itemName and itemID and not seen[itemID] then
                seen[itemID] = true
                table.insert(weapons, {
                    icon   = icon or texture or 134400, -- fallback question mark
                    text   = itemName or "Unknown",
                    itemID = itemID,
                    link   = link,
                    slot   = slot,
                })
            end
        end
    end

    return weapons
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.ArtifactWeapon = ArtifactWeapon
