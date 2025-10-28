--[[-----------------------------------------------------------------------------
  ThreadsTracker.lua
  Purpose:
    - Track Threads totals from Infinite Power aura (Legion Remix)
    - Track daily gain for the player, rolling over at daily reset
    - Maintain last 7 days of history per character
    - Persist all characters in AceDB global scope for cross-alt comparisons
    - Store class info for UI colorization
-------------------------------------------------------------------------------]]--

local _, Addon = ...

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class ThreadsTracker
local ThreadsTracker = {}
Addon.ThreadsTracker = ThreadsTracker

-- Spell ID for Infinite Power aura
ThreadsTracker.THREADS_SPELL_ID = 1232454

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
        if not aura then return nil end
        if aura.spellId == ThreadsTracker.THREADS_SPELL_ID then
            return aura
        end
        index = index + 1
    end
end

--------------------------------------------------------------------------------
-- Totals
--------------------------------------------------------------------------------

---Get total Threads for a unit (skips XP at index 11).
---@param unit string
---@return number total
function ThreadsTracker:GetUnitTotal(unit)
    local aura = ScanAura(unit)
    if not aura or not aura.points then return 0 end

    local total = 0
    for i, v in ipairs(aura.points) do
        if i ~= 11 then
            total = total + (v or 0)
        end
    end
    return total
end

---Get Versatility bonus (index 5).
---@param unit string
---@return number|nil
function ThreadsTracker:GetUnitVersatilityBonus(unit)
    local aura = ScanAura(unit)
    if not aura or not aura.points then return nil end
    return aura.points[5] or 0
end

--------------------------------------------------------------------------------
-- SavedVariables Helpers (AceDB global scope)
--------------------------------------------------------------------------------

---Get unique character key (Name-Realm).
---@return string
local function GetCharKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

---Get the global threads DB, ensuring structure exists.
---@return table
local function GetGlobalDB()
    if not Addon.LibAceAddon or not Addon.LibAceAddon.db or not Addon.LibAceAddon.db.global then
        return { chars = {} } -- safe fallback
    end

    local db = Addon.LibAceAddon.db.global
    db.threads = db.threads or { chars = {} }
    db.threads.chars = db.threads.chars or {}
    return db.threads
end

---Ensure a character entry exists in the global DB.
---@return table entry
local function EnsureCharEntry()
    local g = GetGlobalDB()
    local key = GetCharKey()
    if not g.chars[key] then
        g.chars[key] = { history = {}, baselineTotal = nil, class = nil }
    end
    return g.chars[key]
end

---Get a string key for the current daily reset (YYYYMMDD).
---@return string
local function GetResetKey()
    local now = time()
    local resetIn = C_DateAndTime.GetSecondsUntilDailyReset()
    local resetEpoch = now + resetIn
    return date("%Y%m%d", resetEpoch - 86400)
end

---Check if the stored day has rolled over and reset if needed.
---@param entry table
local function CheckDayRollover(entry)
    local todayKey = GetResetKey()
    if not entry.history[1] or entry.history[1].day ~= todayKey then
        table.insert(entry.history, 1, { day = todayKey, gain = 0 })
        if #entry.history > 7 then
            table.remove(entry.history)
        end
        -- Clear baseline so it will be re-initialized on first valid read today
        entry.baselineTotal = nil
    end
end

--------------------------------------------------------------------------------
-- Public: Player Data
--------------------------------------------------------------------------------

---Get the player's total Threads, today's gain, and history.
---@return number total, number today, table history
function ThreadsTracker:GetPlayerData()
    local entry = EnsureCharEntry()

    -- capture and persist class
    local _, classFile = UnitClass("player")
    entry.class = classFile

    -- Read current total
    local total = self:GetUnitTotal("player") or 0

    -- Handle day rollover
    CheckDayRollover(entry)

    -- Initialize baseline only when we have a valid positive total and no baseline yet
    if (entry.baselineTotal == nil or entry.baselineTotal < 0) and total > 0 then
        entry.baselineTotal = total
    end

    -- Compute today's gain relative to baseline
    local todayGain
    if entry.baselineTotal ~= nil and total >= entry.baselineTotal then
        todayGain = total - entry.baselineTotal
    else
        -- If baseline missing or total < baseline (e.g., invalid read), preserve existing gain
        todayGain = entry.history[1] and entry.history[1].gain or 0
    end

    -- Persist today's gain without moving baseline
    if entry.history[1] then
        entry.history[1].gain = todayGain
    else
        table.insert(entry.history, 1, { day = GetResetKey(), gain = todayGain })
    end

    return total, todayGain, entry.history
end

--------------------------------------------------------------------------------
-- Public: Alt Rankings
--------------------------------------------------------------------------------

---Get top N alts by today’s gain.
---@param n number Number of alts to return
---@return table list { {char="Name-Realm", gain=number, class="MAGE"}, ... }
function ThreadsTracker:GetTopAlts(n)
    local g = GetGlobalDB()
    local todayKey = GetResetKey()
    local list = {}

    for charKey, data in pairs(g.chars) do
        if data.history and data.history[1] and data.history[1].day == todayKey then
            table.insert(list, {
                char  = charKey,
                gain  = data.history[1].gain or 0,
                class = data.class or "PRIEST", -- fallback
            })
        end
    end

    table.sort(list, function(a, b) return a.gain > b.gain end)

    if n and #list > n then
        local trimmed = {}
        for i = 1, n do trimmed[i] = list[i] end
        return trimmed
    end
    return list
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

ThreadsTracker.ScanAura = ScanAura
