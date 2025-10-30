--[[-----------------------------------------------------------------------------
  MinimapTooltipProvider.lua
  Purpose:
    - Provide tooltip content for the minimap icon
    - Display Threads totals, currency, stat breakdown, and artifact powers
  Notes:
    - Integrates with AceAddon modules MinimapTooltip and MinimapIcon
    - Delegates content population to PlayerView, PartyView, and ObjectivesView
-------------------------------------------------------------------------------]]

local _, Addon = ...

local Fonts = Addon.Fonts
local Colors = Addon.Colors
local colorize = Addon.Colorize

---@class ParentAceAddon : AceAddon
local ParentAceAddon = LibStub("AceAddon-3.0"):GetAddon(Addon.Settings.AddonName)
local MinimapTooltip = ParentAceAddon:GetModule("MinimapTooltip")
local MinimapIcon = ParentAceAddon:GetModule("MinimapIcon")

---@class MinimapTooltipProvider
local MinimapTooltipProvider = {
	activeTicker = nil,
	currentTooltip = nil,
	coordLine = nil,
}

-- Register provider and click callback
MinimapIcon:SetClickCallback(function(...)
	MinimapTooltipProvider:OnIconClick(...)
end)
MinimapTooltip:SetProvider(MinimapTooltipProvider)

-- View Helpers
local PlayerView = Addon.PlayerView
local PartyView = Addon.PartyView
local ObjectivesView = Addon.ObjectivesView

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

---Toggle the Artifact Tree UI.
--- - If in combat, aborts.
--- - If an artifact/weapon traits UI is already open, closes it.
--- - Otherwise, attempts to socket the main/offhand weapon to open the tree.
local function ToggleArtifactTree()
	if InCombatLockdown and InCombatLockdown() then
		return
	end

	local function CloseWeaponTraitFrames()
		local closed = false

		local remixFrame = _G.RemixArtifactFrame
		if remixFrame and remixFrame:IsShown() then
			remixFrame:Hide()
			closed = true
		end

		local artifactFrame = _G.ArtifactFrame
		if artifactFrame and artifactFrame:IsShown() then
			artifactFrame:Hide()
			closed = true
		end

		local socketFrame = _G.ItemSocketingFrame
		if socketFrame and socketFrame:IsShown() then
			if CloseSocketInfo then
				pcall(CloseSocketInfo)
			end
			if socketFrame:IsShown() then
				socketFrame:Hide()
			end
			closed = true
		end

		return closed
	end

	if CloseWeaponTraitFrames() then
		return
	end

	if not InCombatLockdown() then
		pcall(SocketInventoryItem, 16) -- main hand
		C_Timer.After(0.05, function()
			if not InCombatLockdown() then
				pcall(SocketInventoryItem, 17) -- off hand
			end
		end)
	end
end

---Handle minimap icon clicks.
---@param clickedFrame Frame
---@param button string Mouse button identifier
function MinimapTooltipProvider:OnIconClick(clickedFrame, button)
	if button == "LeftButton" then
		ToggleArtifactTree()
	elseif button == "RightButton" then
		if Settings and Settings.OpenToCategory then
			Settings.OpenToCategory(Addon.Settings.AddonNameWithSpaces)
		end
	end
end

--------------------------------------------------------------------------------
-- PopulateTooltip
--------------------------------------------------------------------------------

---Populate the minimap tooltip with Threads, currency, stats, and artifact powers.
---@param tooltip table LibQTip tooltip
function MinimapTooltipProvider:PopulateTooltip(tooltip)
	tooltip:Clear()

	if IsControlKeyDown() then
		PartyView:Populate(tooltip)
	elseif IsAltKeyDown() then
		ObjectivesView:Populate(tooltip)
	else
		PlayerView:Populate(tooltip)
	end

	-- Footer separators
	tooltip:AddSeparator(3, 0, 0, 0, 0)
	tooltip:AddSeparator()
	tooltip:AddSeparator(3, 0, 0, 0, 0)

	tooltip:SetFont(Fonts.FooterText)

	local currentLine = tooltip:AddLine()
	tooltip:SetCell(
		currentLine,
		1,
		colorize("Click icon to open weapon artifact tree", Colors.Grey),
		nil,
		"LEFT",
		tooltip:GetColumnCount()
	)

	currentLine = tooltip:AddLine()
	tooltip:SetCell(
		currentLine,
		1,
		colorize("Right click icon for options", Colors.Grey),
		nil,
		"LEFT",
		tooltip:GetColumnCount()
	)

	currentLine = tooltip:AddLine()
	tooltip:SetCell(
		currentLine,
		1,
		colorize("Hold Alt for objectives | Ctrl for group info", Colors.Grey),
		nil,
		"LEFT",
		tooltip:GetColumnCount()
	)
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.UI = Addon.UI or {}
Addon.UI.TooltipProvider = MinimapTooltipProvider
