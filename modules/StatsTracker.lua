--[[-----------------------------------------------------------------------------
  StatsTracker.lua
  Purpose:
    - Parse Infinite Power aura stat effects
    - Return normalized stat lines for display
  Notes:
    - Uses defensive checks for aura data
    - Provides canonical mapping and display spec for tooltip rendering
-------------------------------------------------------------------------------]]

local _, Addon = ...

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class StatsTracker
local StatsTracker = {}
Addon.StatsTracker = StatsTracker

--------------------------------------------------------------------------------
-- Stat Mapping
--------------------------------------------------------------------------------

-- Canonical mapping of aura.points indices
-- NOTE: This is unused directly, but documents the mapping from:
-- https://www.wowhead.com/spell=1232454/infinite-power
StatsTracker.STAT_MAP = {
	[1] = "Primary Stats", -- Str/Agi/Int
	[2] = "Stamina",
	[3] = "Attack Speed",
	[4] = "Critical Strike",
	[5] = "Versatility",
	[6] = "Mastery",
	[7] = "Speed",
	[8] = "Leech",
	[9] = "Avoidance",
	[10] = "Experience Gain", -- from kills
	[11] = "Experience Gain", -- from quests (duplicate of 10)
	[12] = "Stamina",
	[13] = "Unknown Stat", -- usually the flat primary stat increase
	[14] = "Armor %",
	[15] = "Mastery Rating",
	[16] = "Stamina", -- split into multiple indices
}

--------------------------------------------------------------------------------
-- Display Spec (order + grouping)
--------------------------------------------------------------------------------

StatsTracker.STAT_DISPLAY = {
	{ label = "Primary", type = "percent", indices = { 1 } },
	{ label = "Primary", type = "flat", indices = { 13 } },
	{ label = "Stamina", type = "percent", indices = { 2 } },
	{ label = "Stamina", type = "flat", indices = { 12, 16 } },
	{ label = "Attack Speed", type = "percent", indices = { 3 } },
	{ label = "Critical Strike", type = "percent", indices = { 4 } },
	{ label = "Versatility", type = "percent", indices = { 5 } },
	{ label = "Mastery", type = "percent", indices = { 6 } },
	{ label = "Mastery Rating", type = "flat", indices = { 15 } },
	{ label = "Speed", type = "flat", indices = { 7 } },
	{ label = "Leech", type = "percent", indices = { 8 } },
	{ label = "Avoidance", type = "flat", indices = { 9 } },
	{ label = "Armor", type = "percent", indices = { 14 } },
	{ label = "Experience Gain", type = "percent", indices = { 10 } },
	-- index 11 ignored (duplicate of 10)
}

--------------------------------------------------------------------------------
-- Primary Stat Mapping
--------------------------------------------------------------------------------

-- From: https://warcraft.wiki.gg/wiki/SpecializationID
local SPEC_PRIMARY_STAT = {
	-- Warrior
	[71] = "Strength",
	[72] = "Strength",
	[73] = "Strength",
	-- Paladin
	[65] = "Intellect",
	[66] = "Strength",
	[70] = "Strength",
	-- Hunter
	[253] = "Agility",
	[254] = "Agility",
	[255] = "Agility",
	-- Rogue
	[259] = "Agility",
	[260] = "Agility",
	[261] = "Agility",
	-- Priest
	[256] = "Intellect",
	[257] = "Intellect",
	[258] = "Intellect",
	-- Death Knight
	[250] = "Strength",
	[251] = "Strength",
	[252] = "Strength",
	-- Shaman
	[262] = "Intellect",
	[263] = "Agility",
	[264] = "Intellect",
	-- Mage
	[62] = "Intellect",
	[63] = "Intellect",
	[64] = "Intellect",
	-- Warlock
	[265] = "Intellect",
	[266] = "Intellect",
	[267] = "Intellect",
	-- Monk
	[268] = "Agility",
	[269] = "Agility",
	[270] = "Intellect",
	-- Druid
	[102] = "Intellect",
	[103] = "Agility",
	[104] = "Agility",
	[105] = "Intellect",
	-- Demon Hunter
	[577] = "Agility",
	[581] = "Agility",
	-- Evoker
	[1467] = "Intellect",
	[1468] = "Intellect",
	[1473] = "Intellect",
}

---Get the localized primary stat name for a unit.
---@param unit string Unit token
---@return string statName Localized primary stat name
local function GetPrimaryStatName(unit)
	if not UnitIsPlayer(unit) then
		return "Primary Stat"
	end

	if UnitIsUnit(unit, "player") then
		local specIndex = GetSpecialization()
		if specIndex then
			local specID = GetSpecializationInfo(specIndex)
			return SPEC_PRIMARY_STAT[specID] or "Primary Stat"
		end
	else
		local specID = GetInspectSpecialization(unit)
		if specID and specID > 0 then
			return SPEC_PRIMARY_STAT[specID] or "Primary Stat"
		end
	end

	return "Primary Stat"
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---Build normalized stat lines from an aura.
---@param aura table Aura data (from C_UnitAuras)
---@param unit string Unit token the aura was applied to
---@return string[] lines List of formatted stat lines
function StatsTracker:GetStatLines(aura, unit)
	local lines = {}
	if not aura or not aura.points then
		return lines
	end

	local function addLine(value, suffix, isPercent)
		local prefix = "+" .. Addon.FormatWithCommas(value)
		if isPercent then
			table.insert(lines, prefix .. "% " .. suffix)
		else
			table.insert(lines, prefix .. " " .. suffix)
		end
	end

	for _, entry in ipairs(self.STAT_DISPLAY) do
		local total = 0
		for _, idx in ipairs(entry.indices) do
			if aura.points[idx] then
				total = total + aura.points[idx]
			end
		end

		if total > 0 then
			if entry.label == "Primary" then
				addLine(total, GetPrimaryStatName(unit), entry.type == "percent")
			else
				addLine(total, entry.label, entry.type == "percent")
			end
		end
	end

	return lines
end
