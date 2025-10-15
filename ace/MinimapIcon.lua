--[[============================================================================
  MinimapIcon.lua
  Purpose:
    - Provides a LibDataBroker launcher for the addon
    - Registers with LibDBIcon for minimap display
    - Delegates tooltip and click handling to callbacks
============================================================================]]--

local _, Addon = ...

local addonName = Addon.Settings.AddonName
local addonIcon = Addon.Settings.IconTexture

---@class ParentAceAddon : AceAddon
local ParentAceAddon = LibStub("AceAddon-3.0"):GetAddon(addonName)



--------------------------------------------------------------------------------
-- Minimap Icon Module
--------------------------------------------------------------------------------

---@class MinimapIcon : AceModule
local MinimapIcon = ParentAceAddon:NewModule("MinimapIcon")

MinimapIcon.libdbicon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1")

---Initialize the minimap icon data object.
function MinimapIcon:OnInitialize()
    self.icon = LDB:NewDataObject(addonName, {
        type  = "launcher",
        text  = Addon.Settings.AddonNameWithSpaces,
        icon  = addonIcon,
        OnClick = function(...) self:OnClick(...) end,
        OnEnter = function(...) self:OnEnter(...) end,
        OnLeave = function(...) self:OnLeave(...) end,
    })
end

---Set the tooltip callback.
---@param cb fun(frame: Frame): table
function MinimapIcon:SetTooltipCallback(cb)
    self.tooltipCallback = cb
end

---Set the click callback.
---@param cb fun(frame: Frame, button: string)
function MinimapIcon:SetClickCallback(cb)
    self.clickCallback = cb
end

---Enable the minimap icon.
function MinimapIcon:OnEnable()
    self.libdbicon:Register(addonName, self.icon, ParentAceAddon.db.global.minimap)
end

---Disable (hide) the minimap icon.
function MinimapIcon:OnDisable()
    self.libdbicon:Hide(addonName)
end

---Update the icon’s text label.
---@param newText string
function MinimapIcon:SetIconText(newText)
    if self.icon then
        self.icon.text = newText or ""
    end
end



--------------------------------------------------------------------------------
-- LibDBIcon Events
--------------------------------------------------------------------------------

---Handle minimap icon clicks.
---@param clickedFrame Frame
---@param button string
function MinimapIcon:OnClick(clickedFrame, button)
    if self.clickCallback then
        self.clickCallback(clickedFrame, button)
    end
end

---Handle mouse entering the icon (show tooltip).
---@param frame Frame
function MinimapIcon:OnEnter(frame)
    if self.tooltip then
        self.tooltip:Release()
        self.tooltip = nil
    end

    if self.tooltipCallback then
        self.tooltip = self.tooltipCallback(frame)
    end
end

---Handle mouse leaving the icon.
function MinimapIcon:OnLeave(_)
    -- Intentionally left blank
end



--------------------------------------------------------------------------------
-- Publish / Wire-up
--------------------------------------------------------------------------------

local MinimapTooltip = ParentAceAddon:GetModule("MinimapTooltip")

-- Wire tooltip callback to the MinimapTooltip module
MinimapIcon:SetTooltipCallback(function(anchor)
    return MinimapTooltip:ShowTooltip(anchor)
end)
