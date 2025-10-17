--[[============================================================================
  UnitTooltip.lua
  Purpose:
    - Hook into Blizzard unit tooltips
    - Display Threads totals + today (from ThreadsTracker)
    - Display stat breakdown (from StatsTracker)
============================================================================]]--

local _, Addon = ...

local colors  = Addon.Settings.Colors
local Threads = Addon.ThreadsTracker
local Stats   = Addon.StatsTracker


--------------------------------------------------------------------------------
-- Tooltip Hook
--------------------------------------------------------------------------------

---Post-process unit tooltips to inject Threads and Stats information.
---@param tooltip GameTooltip
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
    local _, unit = tooltip:GetUnit()
    if not (unit and UnitIsPlayer(unit)) then
        return
    end

    -- Threads total
    local total = Threads:GetUnitTotal(unit)
    if not total then
        return
    end

    tooltip:AddLine(" ")

    -- Stat breakdown lines
    local aura = Threads.ScanAura(unit)
    if aura then
        local lines = Stats:GetStatLines(aura)
        for _, line in ipairs(lines) do
            tooltip:AddLine(colorize(line, colors.White))
        end
    end

    tooltip:AddLine(" ")

    -- Threads info line
    tooltip:AddLine(colorize(FormatWithCommasToThousands(total) .. " Threads", colors.WowToken))

    -- Player-specific "today" line
    if UnitIsUnit(unit, "player") then
        local _, today = Threads:GetPlayerData()
        tooltip:AddLine(colorize("+ " .. FormatWithCommasToThousands(today) .. " Today", colors.White))
    end

    tooltip:AddLine(" ")
end)
