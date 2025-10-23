--[[============================================================================
  ThreadsMonitor.lua
  Purpose:
    - Show compact group summary (non-raid) with Threads + Limits Unbound
============================================================================]]--

local _, Addon = ...

local colors  = Addon.Settings.Colors
local ThreadsTracker = Addon.ThreadsTracker

local HEADER_COLOR = "ffaaff00"

---@class ThreadsMonitor
local ThreadsMonitor = {}
Addon.ThreadsMonitor = ThreadsMonitor

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function NotifyBlock(lines)
    for _, line in ipairs(lines) do
        DEFAULT_CHAT_FRAME:AddMessage(line)
    end
end

local function ColoredPlayerLink(unit)
    local name, realm = UnitName(unit)
    if not name then return "Unknown" end
    realm = realm or GetRealmName()
    local _, classFile = UnitClass(unit)
    local color = RAID_CLASS_COLORS[classFile] or NORMAL_FONT_COLOR
    -- clickable player link
    local link = string.format("|Hplayer:%s-%s|h%s-%s|h", name, realm, name, realm)
    return string.format("|c%s%s|r", color.colorStr, link)
end

local function FormatThreads(total)
    return colorize(FormatWithCommasToThousands(total) .. " Threads", colors.WowToken)
end

-- Helper function to get spell icon
local function GetSpellIcon(spellID)
  if not spellID or not C_Spell.GetSpellTexture then return 134400 end
  return C_Spell.GetSpellTexture(spellID) or 134400
end

local LIMITS_UNBOUND_SPELL_ID = 1245947
local function FormatLimitsUnbound(rank)
    local icon = ("|T%d:0|t"):format(GetSpellIcon(LIMITS_UNBOUND_SPELL_ID)) or ""
    return colorize(tostring(rank), colors.Artifact) .. " " .. icon
end


--------------------------------------------------------------------------------
-- Reporting
--------------------------------------------------------------------------------

local function ReportGroup()
    if IsInRaid() then return end
    if not Addon.LibAceAddon:IsGroupReportingEnabled() then return end

    local num = GetNumGroupMembers()
    if num == 0 then return end

    local lines = {}
    table.insert(lines, " ")
    table.insert(lines, colorize("=== Group Threads & Limits Unbound ===", HEADER_COLOR))

    local prefix = IsInRaid() and "raid" or "party"

    local function AddUnit(unit)
        if not UnitExists(unit) then return end
        local total = ThreadsTracker:GetUnitTotal(unit)
        if not total then return end
        local rank = math.floor(total / 50000)
        table.insert(lines, string.format("%s (%s) | %s | %s",
            ColoredPlayerLink(unit),
            UnitLevel(unit) or "?",
            FormatLimitsUnbound(rank),
            FormatThreads(total)
        ))
    end

    AddUnit("player")
    for i = 1, num do AddUnit(prefix .. i) end
    table.insert(lines, " ")

    NotifyBlock(lines)
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_JOINED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(_, event)
    if event == "GROUP_JOINED" then
        if not IsInRaid() then
            ReportGroup()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInstance, instanceType = IsInInstance()
        if isInstance and instanceType ~= "raid" then
            ReportGroup()
        end
    end
end)


