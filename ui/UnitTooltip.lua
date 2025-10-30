--[[-----------------------------------------------------------------------------
  UnitTooltip.lua
  Purpose:
    - Hook into Blizzard unit tooltips
    - Display Threads totals + today (from ThreadsTracker)
    - Display stat breakdown (from StatsTracker)
  Notes:
    - Only applies in Legion Timerunner mode
    - Adds stat lines, Threads total, and Limits Unbound bonus
    - All functions are namespaced under Addon
-------------------------------------------------------------------------------]]

local _, Addon = ...

local colors = Addon.Settings.Colors
local colorize = Addon.Colorize
local Threads = Addon.ThreadsTracker
local Stats = Addon.StatsTracker

--------------------------------------------------------------------------------
-- Tooltip Hook
--------------------------------------------------------------------------------

---Post-process unit tooltips to inject Threads and Stats information.
---@param tooltip GameTooltip
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
	if not Addon.IsInLegionTimerunningMode() then
		return
	end

	local _, unit = tooltip:GetUnit()
	if not (unit and UnitIsPlayer(unit)) then
		return
	end

	-- Threads total
	local total = Threads:GetUnitTotal(unit)
	if not total or total <= 0 then
		return
	end

	tooltip:AddLine(" ")

	-- Stat breakdown lines
	local aura = Threads.ScanAura(unit)
	if aura then
		local lines = Stats:GetStatLines(aura, unit)
		for _, line in ipairs(lines) do
			tooltip:AddLine(colorize(line, colors.White))
		end
	end

	tooltip:AddLine(" ")

	-- Threads info line
	tooltip:AddLine(colorize(Addon.FormatWithCommasToThousands(total) .. " Threads", colors.WowToken))

	-- Limits Unbound bonus (i.e. Versatility bonus)
	local verseBonus = Threads:GetUnitVersatilityBonus(unit)
	if verseBonus and verseBonus > 0 then
		tooltip:AddLine(colorize(verseBonus .. " Limits Unbound", colors.Artifact))
	end

	tooltip:AddLine(" ")
end)
