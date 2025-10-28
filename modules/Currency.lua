--[[-----------------------------------------------------------------------------
  Currency.lua
  Purpose:
    - Provide a unified API for accessing Legion Remix currency values
    - Expose constants for known currency IDs
  Notes:
    - All constants and methods are namespaced under Addon.Currency
    - Defensive checks ensure safe fallback values
-------------------------------------------------------------------------------]]--

local _, Addon = ...

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class Currency
local Currency = {}

--------------------------------------------------------------------------------
-- Currency Constants
--------------------------------------------------------------------------------

Currency.INFINITE_KNOWLEDGE = 3292
Currency.INFINITE_POWER     = 3268
Currency.BRONZE             = 3252

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

---Get information about a currency.
---@param currencyID number Currency type ID (e.g. 1166 for Timewarped Badge)
---@return string|nil name
---@return number|nil quantity
---@return number|nil iconFileID
function Currency:Get(currencyID)
    if not currencyID then
        return nil, 0, nil
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if info then
        return info.name, info.quantity, info.iconFileID
    end

    return nil, 0, nil
end

---Get the icon texture ID of a given currency.
---@param currencyID number Currency type ID
---@return number|nil iconFileID
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
