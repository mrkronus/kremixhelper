--[[============================================================================
  TooltipProvider.lua
  Purpose:
    - Provide tooltip content for the minimap icon
    - Display Threads totals, currency, stat breakdown, and artifact powers
============================================================================]] --

local _, KRemixHelper = ...

local Fonts    = KRemixHelper.Fonts
local Colors   = KRemixHelper.Colors
local colorize = KRemixHelper.Colorize


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

---Toggle the Artifact Tree UI.
--- - If in combat, shows an error and aborts.
--- - If an artifact/weapon traits UI is already open, closes it.
--- - Otherwise, attempts to socket the main/offhand weapon to open the tree.
local function ToggleArtifactTree()
    -- Block in combat
    if InCombatLockdown and InCombatLockdown() then return end

    -- Local helper: close any existing weapon trait/artifact UIs
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
            if CloseSocketInfo then pcall(CloseSocketInfo) end
            if socketFrame:IsShown() then
                socketFrame:Hide()
            end
            closed = true
        end

        return closed
    end

    -- If we just closed something, stop here
    if CloseWeaponTraitFrames() then return end

    -- Otherwise, try to open the artifact tree by socketing weapons
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
  tooltip:AddSeparator(3, 0, 0, 0, 0)

  tooltip:SetFont(Fonts.FooterText)

  local currentLine = tooltip:AddLine()
  tooltip:SetCell(currentLine, 1, colorize("Click icon to open weapon artifact tree", Colors.Grey), nil, "LEFT",
    tooltip:GetColumnCount())

  currentLine = tooltip:AddLine()
  tooltip:SetCell(currentLine, 1, colorize("Right click icon for options", Colors.Grey), nil, "LEFT",
    tooltip:GetColumnCount())

  currentLine = tooltip:AddLine()
  tooltip:SetCell(currentLine, 1, colorize("Hold alt for objectives | ctrl for group info", Colors.Grey), nil, "LEFT",
    tooltip:GetColumnCount())
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

KRemixHelper.UI = KRemixHelper.UI or {}
KRemixHelper.UI.TooltipProvider = MinimapTooltipProvider
