--[[============================================================================
  PlayerIdentity.lua
============================================================================]]--

local _, Addon = ...

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

local PlayerIdentity = {}

-- Returns a snapshot of the player's current identity and stats
function PlayerIdentity:Get()
    local unit = "player"
    local name, realm   = UnitName(unit)
    local localizedClass, classToken = UnitClass(unit)
    local raceLocalized, raceToken   = UnitRace(unit)
    local level         = UnitLevel(unit)
    local faction       = UnitFactionGroup(unit)
    local guid          = UnitGUID(unit)
    local avgIlvl       = select(1, GetAverageItemLevel())
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
        level          = level,
        ilvl           = math.floor((avgIlvl or 0) + 0.5),
        faction        = faction,
    }
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.PlayerIdentity = PlayerIdentity
