--[[============================================================================
  ThreadsTracker.lua
  Purpose:
    - Track Threads totals from Infinite Power aura
    - Track daily gain for the player
============================================================================]]--

local _, Addon = ...

---@class ThreadsTracker
local ThreadsTracker = {}
Addon.ThreadsTracker = ThreadsTracker

-- SavedVariables table
if not ThreadsDB then ThreadsDB = {} end

-- Spell ID for Infinite Power aura
local THREADS_SPELL_ID = 1232454



--------------------------------------------------------------------------------
-- Internal: Aura Scanning
--------------------------------------------------------------------------------

---Scan a unit's auras for the Threads aura.
---@param unit string Unit token
---@return table|nil aura Aura data if found
local function ScanAura(unit)
    local index = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, index)
        if not aura then
            return nil
        end
        if aura.spellId == THREADS_SPELL_ID then
            return aura
        end
        index = index + 1
    end
end



--------------------------------------------------------------------------------
-- Public: Totals
--------------------------------------------------------------------------------

---Get total Threads for a unit (skips XP at index 11).
---@param unit string Unit token
---@return number|nil total Threads total or nil if aura not found
function ThreadsTracker:GetUnitTotal(unit)
    local aura = ScanAura(unit)
    if not aura then
        return nil
    end

    local total = 0
    for i = 1, 16 do
        if i ~= 11 then
            total = total + (aura.points[i] or 0)
        end
    end
    return total
end



--------------------------------------------------------------------------------
-- SavedVariables Helpers
--------------------------------------------------------------------------------

---Ensure a character entry exists in ThreadsDB.
---@return table char Character data entry
local function EnsureChar()
    local name = UnitName("player") .. "-" .. GetRealmName()
    if not ThreadsDB[name] then
        ThreadsDB[name] = { day = date("%m%d%y"), base = 0, today = 0 }
    end
    return ThreadsDB[name]
end

---Check if the stored day has rolled over and reset if needed.
---@param char table Character data entry
local function CheckDayRollover(char)
    local today = date("%m%d%y")
    if char.day ~= today then
        char.day  = today
        char.base = ThreadsTracker:GetUnitTotal("player") or 0
        char.today = 0
    end
end



--------------------------------------------------------------------------------
-- Public: Player Data
--------------------------------------------------------------------------------

---Get the player's total Threads and today's gain.
---@return number total Total Threads
---@return number today Threads gained today
function ThreadsTracker:GetPlayerData()
    local char = EnsureChar()
    CheckDayRollover(char)

    local total = self:GetUnitTotal("player") or 0
    if char.base == 0 then
        char.base = total
    end
    char.today = total - char.base

    return total, char.today
end



--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

ThreadsTracker.ScanAura = ScanAura
