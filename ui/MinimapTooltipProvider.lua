--[[============================================================================
  TooltipProvider.lua
  Purpose:
    - Provide tooltip content for the minimap icon
    - Display Threads totals, currency, stat breakdown, and artifact powers
============================================================================]] --

local _, KRemixHelper = ...

local Fonts           = KRemixHelper.Fonts
local Colors          = KRemixHelper.Colors


---@class ParentAceAddon : AceAddon
local ParentAceAddon                  = LibStub("AceAddon-3.0"):GetAddon(KRemixHelper.Settings.AddonName)
local MinimapTooltip                  = ParentAceAddon:GetModule("MinimapTooltip")
local MinimapIcon                     = ParentAceAddon:GetModule("MinimapIcon")

local MinimapTooltipProvider          = {}
MinimapTooltipProvider.activeTicker   = nil
MinimapTooltipProvider.currentTooltip = nil
MinimapTooltipProvider.coordLine      = nil

MinimapIcon:SetClickCallback(function(...) MinimapTooltipProvider:OnIconClick(...) end)
MinimapTooltip:SetProvider(MinimapTooltipProvider)

-- View Helpers
local PlayerView     = KRemixHelper.PlayerView
local PartyView      = KRemixHelper.PartyView
local ObjectivesView = KRemixHelper.ObjectivesView


--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

local function CloseWeaponTraitsUI()
  local closed = false
  local RAF = _G.RemixArtifactFrame
  if RAF and RAF:IsShown() then
    RAF:Hide()
    closed = true
  end
  local AF = _G.ArtifactFrame
  if AF and AF:IsShown() then
    AF:Hide()
    closed = true
  end
  if _G.ItemSocketingFrame and _G.ItemSocketingFrame:IsShown() then
    if CloseSocketInfo then pcall(CloseSocketInfo) end
    if _G.ItemSocketingFrame:IsShown() then
      _G.ItemSocketingFrame:Hide()
    end
    closed = true
  end
  return closed
end

local function ToggleArtifactTree()
  if InCombatLockdown and InCombatLockdown() then
    UIErrorsFrame:AddMessage(L.ERR_COMBAT, 1, 0.1, 0.1)
    return
  end
  if CloseWeaponTraitsUI() then return end
  pcall(SocketInventoryItem, 16)
  C_Timer.After(0.05, function()
    pcall(SocketInventoryItem, 17)
  end)
end

---Handle minimap icon clicks.
---@param clickedFrame Frame
---@param button string
function MinimapTooltipProvider:OnIconClick(clickedFrame, button)
  if button == "LeftButton" then
    ToggleArtifactTree()
  elseif button == "RightButton" then
    Settings.OpenToCategory(KRemixHelper.Settings.AddonNameWithSpaces)
  end
end

--------------------------------------------------------------------------------
-- PopulateTooltip
--------------------------------------------------------------------------------

---Populate the minimap tooltip with Threads, currency, stats, and artifact powers.
---@param tooltip table
function MinimapTooltipProvider:PopulateTooltip(tooltip)
  tooltip:Clear()

  if IsControlKeyDown() then
    PartyView:Populate(tooltip)
  elseif IsAltKeyDown() then
    ObjectivesView:Populate(tooltip)
  else
    PlayerView:Populate(tooltip)
  end

  -- Footer
  tooltip:AddSeparator(3, 0, 0, 0, 0)
  tooltip:AddSeparator()

  tooltip:SetFont(Fonts.FooterText)

  local currentLine = tooltip:AddLine()
  tooltip:SetCell(currentLine, 1, colorize("Click icon to open weapon artifact tree", Colors.Grey), nil, "LEFT",
    tooltip:GetColumnCount())

  currentLine = tooltip:AddLine()
  tooltip:SetCell(currentLine, 1, colorize("Right click icon for options", Colors.Grey), nil, "LEFT",
    tooltip:GetColumnCount())

  currentLine = tooltip:AddLine()
  tooltip:SetCell(currentLine, 1, colorize("Hold alt for objectives | Ctrl for party info", Colors.Grey), nil, "LEFT",
    tooltip:GetColumnCount())
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

KRemixHelper.UI = KRemixHelper.UI or {}
KRemixHelper.UI.TooltipProvider = MinimapTooltipProvider
