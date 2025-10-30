--[[-----------------------------------------------------------------------------
  TooltipHelpers.lua
  Purpose:
    - Provide helper functions for building LibQTip-based tooltips
    - Add section headings, sub-tooltips, and currency lines
    - Provide formatting helpers for Infinite Power and Limits Unbound
  Notes:
    - All functions are namespaced under Addon.TooltipHelpers
-------------------------------------------------------------------------------]]

local _, Addon = ...

local Fonts = Addon.Fonts
local Colors = Addon.Colors
local colorize = Addon.Colorize
local LibQTip = Addon.LibQTip

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class TooltipHelpers
local TooltipHelpers = {}
Addon.TooltipHelpers = TooltipHelpers

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local INFINITE_POWER_CURRENCY_ID = 3268
local COST_TO_UNLOCK_TREE = 114125
local COST_PER_RANK = 50000
local INV_MISC_QUESTIONMARK = 134400

--------------------------------------------------------------------------------
-- Tooltip Positioning Helpers
--------------------------------------------------------------------------------

---Position a tooltip relative to a region with smart left/right anchoring.
---@param tooltip Frame GameTooltip or LibQTip tooltip
---@param region Frame The cell/frame to anchor to
function TooltipHelpers.PositionTooltip(tooltip, region)
	if not (tooltip and region and region:IsShown()) then
		return
	end

	local x, y = region:GetCenter()
	if not x or not y then
		return
	end

	local screenWidth = UIParent:GetWidth()
	tooltip:ClearAllPoints()

	-- GameTooltip needs an owner
	if tooltip:IsObjectType("GameTooltip") then
		tooltip:SetOwner(region, "ANCHOR_NONE")
	end

	-- Decide left/right side
	if x < screenWidth / 2 then
		tooltip:SetPoint("LEFT", region, "RIGHT", 0, 0)
		tooltip:SetPoint("CENTER", region, "CENTER", 0, 0)
	else
		tooltip:SetPoint("RIGHT", region, "LEFT", 0, 0)
		tooltip:SetPoint("CENTER", region, "CENTER", 0, 0)
	end
end

---Attach a GameTooltip that shows a hyperlink when hovering a line or cell.
---@param tooltip table    LibQTip tooltip
---@param lineIndex number Line index to attach
---@param colIndex? number Optional column index; if nil, attaches to the line
---@param hyperlink string Blizzard hyperlink ("quest:12345", "spell:67890", item link, etc.)
function TooltipHelpers.AddHyperlinkTooltip(tooltip, lineIndex, colIndex, hyperlink)
	local function showTooltip(region)
		if not region or not hyperlink then
			return
		end
		TooltipHelpers.PositionTooltip(GameTooltip, region)
		GameTooltip:SetHyperlink(hyperlink)
		GameTooltip:Show()
	end

	local function hideTooltip()
		GameTooltip:Hide()
	end

	if colIndex then
		tooltip:SetCellScript(lineIndex, colIndex, "OnEnter", showTooltip)
		tooltip:SetCellScript(lineIndex, colIndex, "OnLeave", hideTooltip)
	else
		tooltip:SetLineScript(lineIndex, "OnEnter", showTooltip)
		tooltip:SetLineScript(lineIndex, "OnLeave", hideTooltip)
	end
end

---Attach a GameTooltip showing a currency by ID.
---@param tooltip table
---@param lineIndex number
---@param colIndex? number
---@param currencyID number
function TooltipHelpers.AddCurrencyTooltip(tooltip, lineIndex, colIndex, currencyID)
	local function show(cellFrame)
		TooltipHelpers.PositionTooltip(GameTooltip, cellFrame)
		GameTooltip:SetCurrencyByID(currencyID)
		GameTooltip:Show()
	end

	local function hide()
		GameTooltip:Hide()
	end

	if colIndex then
		tooltip:SetCellScript(lineIndex, colIndex, "OnEnter", show)
		tooltip:SetCellScript(lineIndex, colIndex, "OnLeave", hide)
	else
		tooltip:SetLineScript(lineIndex, "OnEnter", show)
		tooltip:SetLineScript(lineIndex, "OnLeave", hide)
	end
end

---Add a sub-tooltip line that spawns another tooltip on hover.
---@param tooltip table
---@param label string
---@param populateFunc fun(subTip: table)
function TooltipHelpers.AddSubTooltipLine(tooltip, label, populateFunc)
	local line = tooltip:AddLine()
	tooltip:SetCell(line, 1, label, nil, "LEFT")
	tooltip:SetCell(line, tooltip:GetColumnCount(), " >", nil, "RIGHT")

	tooltip:SetLineScript(line, "OnEnter", function(cell)
		local subTip = LibQTip:Acquire("AddonSubTooltip", 1, "LEFT")
		subTip:Clear()
		TooltipHelpers.PositionTooltip(subTip, cell)
		populateFunc(subTip)
		subTip:Show()
	end)

	tooltip:SetLineScript(line, "OnLeave", function()
		LibQTip:Release(LibQTip:Acquire("AddonSubTooltip"))
	end)
end

--------------------------------------------------------------------------------
-- Content Helpers
--------------------------------------------------------------------------------

---Add a section heading with separators and font changes.
---@param tooltip table
---@param sectionName string
---@param shouldAddGapAbove? boolean
function TooltipHelpers.AddSectionHeading(tooltip, sectionName, shouldAddGapAbove)
	if shouldAddGapAbove == nil then
		-- default to true
		shouldAddGapAbove = true
	end
	if shouldAddGapAbove then
		tooltip:AddSeparator(10, 0, 0, 0, 0)
	end
	tooltip:SetFont(Fonts.Heading)
	local currentLine = tooltip:AddLine()
	tooltip:SetCell(currentLine, 1, colorize(sectionName, Colors.Header), nil, "LEFT", tooltip:GetColumnCount())
	tooltip:AddSeparator()
	tooltip:AddSeparator(3, 0, 0, 0, 0)
	tooltip:SetFont(Fonts.MainText)
end

---Add a currency line to the tooltip if the player has any of it.
---@param tooltip table
---@param currencyID number
function TooltipHelpers.AddCurrencyLine(tooltip, currencyID)
	local name, quantity, icon = Addon.Currency:Get(currencyID)
	if quantity and quantity > 0 then
		local iconString = icon and ("|T%d:0|t"):format(icon) or ""
		local line = tooltip:AddLine()
		tooltip:SetCell(line, 1, name)
		tooltip:SetCell(line, 2, Addon.FormatWithCommas(quantity) .. " " .. iconString)

		-- Use a dedicated helper for currencies
		TooltipHelpers.AddCurrencyTooltip(tooltip, line, nil, currencyID)
	end
end

--------------------------------------------------------------------------------
-- Formatting Helpers
--------------------------------------------------------------------------------

---Get current Infinite Power quantity.
---@return number
function TooltipHelpers.GetInfinitePowerQty()
	if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then
		return 0
	end
	local ci = C_CurrencyInfo.GetCurrencyInfo(INFINITE_POWER_CURRENCY_ID)
	return (ci and ci.quantity) or 0
end

---Get a spell icon texture ID.
---@param spellID number
---@return number
function TooltipHelpers.GetSpellIcon(spellID)
	if not spellID or not C_Spell.GetSpellTexture then
		return INV_MISC_QUESTIONMARK
	end
	return C_Spell.GetSpellTexture(spellID) or INV_MISC_QUESTIONMARK
end

---Calculate Limits Unbound rank and return as string.
---@return string
function TooltipHelpers.GetLimitsUnboundRankString()
	local ipQty = TooltipHelpers.GetInfinitePowerQty()
	local available = math.max(0, ipQty - COST_TO_UNLOCK_TREE)
	local rank = math.floor(available / COST_PER_RANK)
	return tostring(rank)
end
