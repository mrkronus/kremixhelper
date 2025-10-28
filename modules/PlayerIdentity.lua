--[[-----------------------------------------------------------------------------
  PlayerIdentity.lua
  Purpose:
    - Provide a snapshot of the player's current identity and stats
    - Expose class, race, spec, ilvl, and faction in a normalized schema
  Notes:
    - All values are returned in a single table
    - Defensive defaults ensure safe fallbacks
-------------------------------------------------------------------------------]]--

local _, Addon = ...

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class PlayerIdentity
local PlayerIdentity = {}

---Get a snapshot of the player's current identity and stats.
---@return table identity {
---   name: string,
---   realm: string,
---   guid: string,
---   classToken: string,
---   classLocalized: string,
---   specLocalized: string,
---   raceToken: string,
---   raceLocalized: string,
---   level: number,
---   ilvl: number,
---   faction: string
---}
function PlayerIdentity:Get()
    local unit = "player"
    local name, realm   = UnitName(unit)
    local localizedClass, classToken = UnitClass(unit)
    local raceLocalized, raceToken   = UnitRace(unit)
    local level         = UnitLevel(unit)
    local faction       = UnitFactionGroup(unit)
    local guid          = UnitGUID(unit)
    local avgIlvl       = select(1, GetAverageItemLevel()) or 0
    local specID        = GetSpecialization()
    local specName      = ""

    if specID and specID > 0 then
        _, specName = GetSpecializationInfo(specID)
    end

    return {
        name           = name,
        realm          = realm or GetRealmName(),
        guid           = guid,
        classToken     = classToken,
        classLocalized = localizedClass,
        specLocalized  = specName,
        raceToken      = raceToken,
        raceLocalized  = raceLocalized,
        level          = level or 0,
        ilvl           = math.floor(avgIlvl + 0.5),
        faction        = faction,
    }
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.PlayerIdentity = PlayerIdentity
