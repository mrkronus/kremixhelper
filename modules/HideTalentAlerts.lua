--[[-----------------------------------------------------------------------------
  HideTalentAlerts.lua
  Purpose:
    - Provide functions to enable/disable suppression of Blizzard’s tutorial popups
    - Suppress talent/spellbook micro button alerts and pulses
    - Preserve and restore the previous tutorial state
    - Actively dismiss any visible popups when enabled
  Notes:
    - Only affects PlayerSpellsMicroButton (talent/spellbook)
    - Uses hooksecurefunc to avoid taint
    - Exposes Addon.HideTalentAlerts:Enable(flag) for external control
    - Restores prior "showTutorials" CVar when suppression is disabled
-------------------------------------------------------------------------------]]

local _, Addon = ...

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class HideTalentAlerts
local HideTalentAlerts = {}

-- Internal state
local suppressionEnabled = false
local previousTutorialState = nil

--------------------------------------------------------------------------------
-- Internal Helpers
--------------------------------------------------------------------------------

---Hide the alert on the PlayerSpellsMicroButton if suppression is enabled.
---@param microButton Button
local function HideAlert(microButton)
	if suppressionEnabled and microButton == PlayerSpellsMicroButton then
		MainMenuMicroButton_HideAlert(microButton)
	end
end

---Stop the pulse animation on the PlayerSpellsMicroButton if suppression is enabled.
---@param microButton Button
local function HidePulse(microButton)
	if suppressionEnabled and microButton == PlayerSpellsMicroButton then
		MicroButtonPulseStop(microButton)
	end
end

--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------

-- Secure hooks (always active, but gated by suppressionEnabled)
hooksecurefunc("MainMenuMicroButton_ShowAlert", HideAlert)
hooksecurefunc("MicroButtonPulse", HidePulse)

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---Enable or disable suppression of Blizzard tutorial popups and talent alerts.
---@param flag boolean True to enable suppression, false to disable
function HideTalentAlerts:Enable(flag)
	if flag and not suppressionEnabled then
		suppressionEnabled = true
		previousTutorialState = GetCVar("showTutorials")
		SetCVar("showTutorials", 0)

		-- Actively dismiss any tutorial UI
		if type(TutorialFrame_HideAll) == "function" then
			TutorialFrame_HideAll()
		elseif TutorialPointerFrame and TutorialPointerFrame.Hide then
			TutorialPointerFrame:Hide()
		end

		-- Clear any active alert/pulse
		if PlayerSpellsMicroButton then
			MainMenuMicroButton_HideAlert(PlayerSpellsMicroButton)
			MicroButtonPulseStop(PlayerSpellsMicroButton)
		end
	elseif not flag and suppressionEnabled then
		suppressionEnabled = false
		if previousTutorialState ~= nil then
			SetCVar("showTutorials", previousTutorialState)
			previousTutorialState = nil
		end
	end
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.HideTalentAlerts = HideTalentAlerts
