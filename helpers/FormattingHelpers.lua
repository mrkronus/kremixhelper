--[[============================================================================
  NumberFormatting.lua
  Purpose:
    - Format numbers with commas
    - Format numbers with K/M suffixes and commas
    - Wrap text in WoW color codes
============================================================================]]--

local _, Addon = ...


--------------------------------------------------------------------------------
-- Time Running
--------------------------------------------------------------------------------

local TIMERUNNING_MOP = 1
local TIMERUNNING_LEGION = 2

function IsInTimerunnerMode()
	return PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID() ~= 0
end

function IsInLegionTimerunnerMode()
	return PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID() == TIMERUNNING_LEGION
end

--------------------------------------------------------------------------------
-- Comma Formatting
--------------------------------------------------------------------------------

---Format a number with commas as thousands separators.
---@param num number
---@return string
function FormatWithCommas(num)
    local s = tostring(math.floor(num or 0))

    -- Repeatedly insert commas every three digits from the right
    while true do
        local new, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        s = new
        if k == 0 then break end
    end

    return s
end


--------------------------------------------------------------------------------
-- Thousands / Millions Formatting
--------------------------------------------------------------------------------

---Format a number with K/M rounding and commas.
---@param num number
---@return string
function FormatWithCommasToThousands(num)
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
        local millions  = num / 1000000
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

