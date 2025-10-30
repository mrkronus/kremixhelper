--[[-----------------------------------------------------------------------------
  FormattingHelpers.lua
  Purpose:
    - Format numbers with commas
    - Format numbers with K/M suffixes and commas
    - Provide helpers for Timerunning season checks
  Notes:
    - All functions and constants are namespaced under Addon
-------------------------------------------------------------------------------]]

local _, Addon = ...

--------------------------------------------------------------------------------
-- Timerunning Constants
--------------------------------------------------------------------------------

---Timerunning season IDs (Blizzard API values).
Addon.TIMERUNNING_MOP = 1
Addon.TIMERUNNING_LEGION = 2

--------------------------------------------------------------------------------
-- Timerunning Checks
--------------------------------------------------------------------------------

---Check if the player is in any Timerunning mode.
---@return boolean inMode True if the player is in a Timerunning season
function Addon.IsInTimerunningMode()
	return PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID() ~= 0
end

---Check if the player is in Legion Timerunning mode.
---@return boolean inLegion True if the player is in Legion Timerunning
function Addon.IsInLegionTimerunningMode()
	return PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID() == Addon.TIMERUNNING_LEGION
end

--------------------------------------------------------------------------------
-- Comma Formatting
--------------------------------------------------------------------------------

---Format a number with commas as thousands separators.
---@param num number|nil Number to format
---@return string formatted Comma-formatted string
function Addon.FormatWithCommas(num)
	local s = tostring(math.floor(num or 0))

	-- Repeatedly insert commas every three digits from the right
	while true do
		local new, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		s = new
		if k == 0 then
			break
		end
	end

	return s
end

--------------------------------------------------------------------------------
-- Thousands / Millions Formatting
--------------------------------------------------------------------------------

---Format a number with K/M rounding and commas.
---@param num number|nil Number to format
---@return string formatted Formatted string with K/M suffix
function Addon.FormatWithCommasToThousands(num)
	if not num then
		return "0"
	end

	if num < 1000 then
		-- Just the raw number
		return tostring(num)
	elseif num < 1000000 then
		-- Thousands: always round to K with 2 decimals
		return string.format("%.2fK", num / 1000)
	else
		-- Millions: round to M with 2 decimals, add commas
		local millions = num / 1000000
		local formatted = string.format("%.2fM", millions)

		-- Insert commas into the integer part before the decimal
		local int, frac = formatted:match("^(%d+)(%.%d+M)$")
		if int then
			repeat
				int, k = int:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
			until k == 0
			return int .. frac
		end

		return formatted
	end
end
