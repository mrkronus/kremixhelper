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
StatsTracker.STAT_MAP = {
    [1]  = "Primary Stats",   -- Str/Agi/Int
    [2]  = "Stamina",
    [3]  = "Attack Speed",
    [4]  = "Critical Strike",
    [5]  = "Versatility",
    [6]  = "Mastery",
    [7]  = "Speed Rating",
    [8]  = "Leech",
    [9]  = "Avoidance",
    [10] = "Experience Gain", -- from kills
    [11] = "Experience Gain", -- from quests
    [12] = "Stamina (flat)",
    [13] = "Unknown Stat",
    [14] = "Armor %",
    [15] = "Mastery Rating",
    [16] = "Stamina (flat)",
}



--------------------------------------------------------------------------------
-- Display Toggles
--------------------------------------------------------------------------------

-- Toggle table: determines which stats are shown
StatsTracker.showStats = {
    [1]  = true,
    [2]  = true,
    [3]  = true,
    [4]  = true,
    [5]  = true,
    [6]  = true,
    [7]  = true,
    [8]  = true,
    [9]  = true,
    [10] = true,
    [11] = false,
    [12] = false,
    [13] = false,
    [14] = true,
    [15] = true,
    [16] = false,
}



--------------------------------------------------------------------------------
-- Public: Stat Line Builder
--------------------------------------------------------------------------------

---Build normalized stat lines from an aura.
---@param aura table Aura data
---@return string[] lines List of formatted stat lines
function StatsTracker:GetStatLines(aura)
    local lines = {}
    if not aura then
        return lines
    end

    for i = 1, 16 do
        if self.showStats[i] and aura.points[i] then
            local raw   = aura.points[i]
            local label = self.STAT_MAP[i] or ("Stat" .. i)

            if i == 1 then
                -- Primary stat % (Str/Agi/Int)
                local statName
                if UnitStat("player", 1) > UnitStat("player", 2) and UnitStat("player", 1) > UnitStat("player", 4) then
                    statName = "Strength"
                elseif UnitStat("player", 2) > UnitStat("player", 1) and UnitStat("player", 2) > UnitStat("player", 4) then
                    statName = "Agility"
                else
                    statName = "Intellect"
                end

                if raw > 0 then
                    table.insert(lines, "+" .. FormatWithCommas(raw) .. "% " .. statName)
                end

            elseif i == 2 or i == 3 or i == 4 or i == 5 or i == 6
                or i == 8 or i == 10 or i == 11 or i == 14 then
                -- Stats expressed as percentages
                if raw > 0 then
                    table.insert(lines, "+" .. FormatWithCommas(raw) .. "% " .. label)
                end

            else
                -- Flat stats
                if raw > 0 then
                    table.insert(lines, "+" .. FormatWithCommas(raw) .. " " .. label)
                end
            end
        end
    end

    return lines
end
