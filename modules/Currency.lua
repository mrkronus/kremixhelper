--[[============================================================================
  Currency.lua
============================================================================]]--

local _, Addon = ...

CURRENCY_INFINITE_KNOWLEDGE = 3292
CURRENCY_INFINITE_POWER = 3268
CURRENCY_BRONZE = 3252

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

local Currency = {}

-- Returns the current quantity of a given currency ID
-- @param currencyID (number) The currency type ID (e.g. 1166 for Timewarped Badge)
-- @return number Current amount owned, or 0 if not found
function Currency:Get(currencyID)
    if not currencyID then
        return 0
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if info then
        return info.name, info.quantity, info.iconFileID
    end
end

-- Returns the icon texture ID of a given currency ID
-- @param currencyID (number) The currency type ID
-- @return number|nil Icon file ID, or nil if not found
function Currency:GetIcon(currencyID)
    if not currencyID then
        return nil
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if info and info.iconFileID then
        return info.iconFileID
    end

    return nil
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.Currency = Currency
