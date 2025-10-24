--[[============================================================================
  StatsTracker.lua
  Purpose:
    - Parse Infinite Power aura stat effects
    - Return normalized stat lines for display
============================================================================]]--

local _, Addon = ...

---@class StatsTracker
local StatsTracker = {}
Addon.StatsTracker = StatsTracker


--------------------------------------------------------------------------------
-- Stat Mapping
--------------------------------------------------------------------------------

-- Canonical mapping of aura.points indices
-- NOTE: this is unused and is just here as documentation of:
-- https://www.wowhead.com/spell=1232454/infinite-power
StatsTracker.STAT_MAP = {
    [1]  = "Primary Stats",   -- Str/Agi/Int
    [2]  = "Stamina",
    [3]  = "Attack Speed",
    [4]  = "Critical Strike",
    [5]  = "Versatility",
    [6]  = "Mastery",
    [7]  = "Speed",
    [8]  = "Leech",
    [9]  = "Avoidance",
    [10] = "Experience Gain", -- from kills
    [11] = "Experience Gain", -- from quests (though should be the same as the other)
    [12] = "Stamina",
    [13] = "Unknown Stat",    -- usually the flat primary stat increase
    [14] = "Armor %",
    [15] = "Mastery Rating",
    [16] = "Stamina",         -- for some reason it's split into two stats
}


--------------------------------------------------------------------------------
-- Display Spec (order + grouping)
--------------------------------------------------------------------------------

StatsTracker.STAT_DISPLAY = {
    { label = "Primary",         type = "percent", indices = { 1 } },
    { label = "Primary",         type = "flat",    indices = { 13 } },
    { label = "Stamina",         type = "percent", indices = { 2 } },
    { label = "Stamina",         type = "flat",    indices = { 12, 16 } },
    { label = "Attack Speed",    type = "percent", indices = { 3 } },
    { label = "Critical Strike", type = "percent", indices = { 4 } },
    { label = "Versatility",     type = "percent", indices = { 5 } },
    { label = "Mastery",         type = "percent", indices = { 6 } },
    { label = "Mastery Rating",  type = "flat",    indices = { 15 } },
    { label = "Speed",           type = "flat",    indices = { 7 } },
    { label = "Leech",           type = "percent", indices = { 8 } },
    { label = "Avoidance",       type = "flat",    indices = { 9 } },
    { label = "Armor",           type = "percent", indices = { 14 } },
    { label = "Experience Gain", type = "percent", indices = { 10 } },
    -- 11 is ignored since it's a duplicate of 10
}


--------------------------------------------------------------------------------
-- Public: Stat Line Builder
--------------------------------------------------------------------------------
-- From: https://warcraft.wiki.gg/wiki/SpecializationID
local SPEC_PRIMARY_STAT = {
  -- Warrior
  [71] = "Strength", -- Arms
  [72] = "Strength", -- Fury
  [73] = "Strength", -- Protection

  -- Paladin
  [65] = "Intellect", -- Holy
  [66] = "Strength",  -- Protection
  [70] = "Strength",  -- Retribution

  -- Hunter
  [253] = "Agility", -- Beast Mastery
  [254] = "Agility", -- Marksmanship
  [255] = "Agility", -- Survival

  -- Rogue
  [259] = "Agility", -- Assassination
  [260] = "Agility", -- Outlaw
  [261] = "Agility", -- Subtlety

  -- Priest
  [256] = "Intellect", -- Discipline
  [257] = "Intellect", -- Holy
  [258] = "Intellect", -- Shadow

  -- DK
  [250] = "Strength", -- Blood
  [251] = "Strength", -- Frost
  [252] = "Strength", -- Unholy

  -- Shaman
  [262] = "Intellect", -- Elemental
  [263] = "Agility",   -- Enhancement
  [264] = "Intellect", -- Restoration

  -- Mage
  [62]  = "Intellect", -- Arcane
  [63]  = "Intellect", -- Fire
  [64]  = "Intellect", -- Frost

  -- Warlock
  [265] = "Intellect", -- Affliction
  [266] = "Intellect", -- Demonology
  [267] = "Intellect", -- Destruction

  -- Monk
  [268] = "Agility",   -- Brewmaster
  [269] = "Agility",   -- Windwalker
  [270] = "Intellect", -- Mistweaver

  -- Druid
  [102] = "Intellect", -- Balance
  [103] = "Agility",   -- Feral
  [104] = "Agility",   -- Guardian
  [105] = "Intellect", -- Restoration

  -- Demon Hunter
  [577] = "Agility", -- Havoc
  [581] = "Agility", -- Vengeance

  -- Evoker
  [1467] = "Intellect", -- Devastation
  [1468] = "Intellect", -- Preservation
  [1473] = "Intellect", -- Augmentation
}

local function GetPrimaryStatName(unit)
  if not UnitIsPlayer(unit) then return nil end

  if UnitIsUnit(unit, "player") then
    local specIndex = GetSpecialization()
    if specIndex then
      local specID = GetSpecializationInfo(specIndex)
      return SPEC_PRIMARY_STAT[specID]
    end
  else
    local specID = GetInspectSpecialization(unit)
    if specID and specID > 0 then
      return SPEC_PRIMARY_STAT[specID]
    end
  end

  return "Primary Stat"
end

---Build normalized stat lines from an aura.
---@param aura table Aura data
---@param unit table Unit the aura was applied to
---@return string[] lines List of formatted stat lines
function StatsTracker:GetStatLines(aura, unit)
    local lines = {}
    if not aura then
        return lines
    end

    local function addLine(value, suffix, isPercent)
        local prefix = "+" .. FormatWithCommas(value)
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