--[[-----------------------------------------------------------------------------
  PlayerIdentity.lua
  Purpose:
    - Provide a snapshot of the player's current identity and stats
    - Expose class, race, spec, ilvl, and faction in a normalized schema
  Notes:
    - All values are returned in a single table
-------------------------------------------------------------------------------]]

local _, Addon = ...

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class PlayerIdentity
local PlayerIdentity = {}

---Represents a snapshot of the player's current identity and stats.
---@class PlayerIdentitySnapshot
---@field name string           Player name
---@field realm string          Realm name
---@field guid string           Player GUID
---@field classToken string     Class token (e.g. "WARRIOR")
---@field classLocalized string Localized class name
---@field specLocalized string  Localized specialization name
---@field raceToken string      Race token (e.g. "Human")
---@field raceLocalized string  Localized race name
---@field level number          Player level
---@field ilvl number           Average item level (rounded)
---@field faction string        Faction ("Alliance"/"Horde")

---Get a snapshot of the player's current identity and stats.
---@return PlayerIdentitySnapshot identity
function PlayerIdentity:Get()
	local unit = "player"
	local name, realm = UnitName(unit)
	local localizedClass, classToken = UnitClass(unit)
	local raceLocalized, raceToken = UnitRace(unit)
	local level = UnitLevel(unit)
	local faction = UnitFactionGroup(unit)
	local guid = UnitGUID(unit)
	local avgIlvl = select(1, GetAverageItemLevel()) or 0
	local specID = GetSpecialization()
	local specName = ""

	if specID and specID > 0 then
		_, specName = GetSpecializationInfo(specID)
	end

	return {
		name = name or "Unknown",
		realm = realm or GetRealmName(),
		guid = guid or "",
		classToken = classToken or "",
		classLocalized = localizedClass or "",
		specLocalized = specName or "",
		raceToken = raceToken or "",
		raceLocalized = raceLocalized or "",
		level = level or 0,
		ilvl = math.floor(avgIlvl + 0.5),
		faction = faction or "",
	}
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.PlayerIdentity = PlayerIdentity
