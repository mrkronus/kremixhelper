--[[-----------------------------------------------------------------------------
  AutoScrapperFrame.lua
  Purpose:
    - Side panel UI for scrapping, delegates to AutoScrapper core
    Provides:
      - Quality dropdown
      - Scroll grid of scrappable items
      - Fill All button
      - Auto Fill on Open checkbox
      - Protect Higher ilvl Items checkbox
  Notes:
    - Calls AutoScrapper:FillNextBatch() only on open, Fill button, or empty
    - Uses AceDB profile values if available
    - All functions are namespaced under Addon.AutoScrapperFrame
-------------------------------------------------------------------------------]]

local _, Addon = ...

local kprint = Addon.Settings.kprint
local AutoScrapper = Addon.AutoScrapper
local TooltipHelpers = Addon.TooltipHelpers

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SCRAPPER_FRAME_WIDTH = 335
local GRID_STRIDE = 7
local GRID_GAP = 4
local GRID_ICON_SIZE = 36
local SCRAPPING_MACHINE_SLOTS = 9
local MIN_NUM_ROWS = 3

--------------------------------------------------------------------------------
-- AutoScrapperFrame
--------------------------------------------------------------------------------

---@class AutoScrapperFrame
local AutoScrapperFrame = {
	frame = nil,
	scrollFrame = nil,
	content = nil,
	buttons = {},
}
Addon.AutoScrapperFrame = AutoScrapperFrame

--------------------------------------------------------------------------------
-- Helpers (settings & persistence)
--------------------------------------------------------------------------------

local function GetProfile()
	local ace = Addon.LibAceAddon
	if ace and ace.db and ace.db.profile then
		return ace.db.profile
	end
	return AutoScrapper.settings
end

local function GetAutoFill()
	local p = GetProfile()
	return (p.autoFillScrapper ~= nil) and p.autoFillScrapper or AutoScrapper.settings.autoFillScrapper
end

local function SetAutoFill(val)
	local ace = Addon.LibAceAddon
	if ace and ace.db and ace.db.profile then
		ace.db.profile.autoFillScrapper = val
	end
	AutoScrapper.settings.autoFillScrapper = val
end

local function GetMaxQuality()
	local p = GetProfile()
	return p.maxQuality or AutoScrapper.settings.maxQuality or Enum.ItemQuality.Rare
end

local function SetMaxQuality(q)
	local ace = Addon.LibAceAddon
	if ace and ace.db and ace.db.profile then
		ace.db.profile.maxQuality = q
	end
	AutoScrapper.settings.maxQuality = q
end

local function GetProtectHigherIlvl()
	local p = GetProfile()
	return (p.protectHigherIlvl ~= nil) and p.protectHigherIlvl or AutoScrapper.settings.protectHigherIlvl
end

local function SetProtectHigherIlvl(val)
	local ace = Addon.LibAceAddon
	if ace and ace.db and ace.db.profile then
		ace.db.profile.protectHigherIlvl = val
	end
	AutoScrapper.settings.protectHigherIlvl = val
end

--------------------------------------------------------------------------------
-- Event Handlers for item buttons
--------------------------------------------------------------------------------

local function OnClick(btn)
	if InCombatLockdown() then
		return
	end
	if not btn.bag or not btn.slot then
		return
	end
	AutoScrapper:ScrapItemFromBag(btn.bag, btn.slot)
end

local function OnEnter(btn)
	if btn.link then
		TooltipHelpers.PositionTooltip(GameTooltip, btn)
		GameTooltip:SetHyperlink(btn.link)
		GameTooltip:Show()
	end
end

local function OnLeave(btn)
	if GameTooltip:GetOwner() == btn then
		GameTooltip:Hide()
	end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

---Initialize the AutoScrapper side panel UI.
function AutoScrapperFrame:Initialize()
	if self.frame then
		return
	end
	local blizzardScrappingFrame = ScrappingMachineFrame
	if not blizzardScrappingFrame or InCombatLockdown() then
		return
	end

	-- Frame container
	local frame = CreateFrame("Frame", nil, blizzardScrappingFrame, "InsetFrameTemplate")
	frame:SetSize(SCRAPPER_FRAME_WIDTH, blizzardScrappingFrame:GetHeight())
	frame:SetPoint("TOPLEFT", blizzardScrappingFrame, "TOPRIGHT", 5, 0)
	frame:Hide()
	self.frame = frame

	-- Quality dropdown
	local qualityLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	qualityLabel:SetPoint("TOPLEFT", 15, -30)
	qualityLabel:SetText("Maximum quality items to scrap")

	local owner = self
	local dropdown = CreateFrame("Frame", "AutoScrapperQualityDropdown", frame, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", qualityLabel, "BOTTOMLEFT", -17, -5)
	UIDropDownMenu_SetWidth(dropdown, 120)
	UIDropDownMenu_Initialize(dropdown, function(_, level)
		for q = Enum.ItemQuality.Common, Enum.ItemQuality.Epic do
			local name = _G["ITEM_QUALITY" .. q .. "_DESC"]
			local color = ITEM_QUALITY_COLORS[q]
			local info = UIDropDownMenu_CreateInfo()
			info.value = q
			info.text = color.hex .. name .. "|r"
			info.func = function()
				SetMaxQuality(q)
				UIDropDownMenu_SetSelectedValue(dropdown, q)
				owner:ReevaluateScrapper()
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end)
	UIDropDownMenu_SetSelectedValue(dropdown, GetMaxQuality())

	-- Auto Fill checkbox
	local autoScrapCheck = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
	autoScrapCheck:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 17, 0)
	autoScrapCheck.Text:SetText("Auto Fill When Empty")
	autoScrapCheck:SetChecked(GetAutoFill())
	autoScrapCheck:SetScript("OnClick", function(btn)
		local isChecked = btn:GetChecked()
		SetAutoFill(isChecked)
		if isChecked then
			self:ReevaluateScrapper()
		end
	end)

	-- Protect Higher ilvl checkbox
	local protectCheck = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
	protectCheck:SetPoint("TOPLEFT", autoScrapCheck, "BOTTOMLEFT", 0, 0)
	protectCheck.Text:SetText("Keep Higher ilvl Items")
	protectCheck:SetChecked(GetProtectHigherIlvl())
	protectCheck:SetScript("OnClick", function(btn)
		SetProtectHigherIlvl(btn:GetChecked())
		self:ReevaluateScrapper()
	end)

	-- Scroll frame grid container
	local gridContainer = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
	gridContainer:SetPoint("TOPLEFT", 12, -130)
	gridContainer:SetPoint("BOTTOMRIGHT", -12, 30)

	-- Scroll frame inside the container
	local scroll = CreateFrame("ScrollFrame", nil, gridContainer, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 5, -5)
	scroll:SetPoint("BOTTOMRIGHT", -28, 4)
	self.scrollFrame = scroll

	-- Content frame that holds the item buttons
	self.content = CreateFrame("Frame", nil, self.scrollFrame)
	self.scrollFrame:SetScrollChild(self.content)

	-- Fill All button
	local fillAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	fillAllBtn:SetSize(120, 22)
	fillAllBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
	fillAllBtn:SetText("Fill All")
	fillAllBtn:SetScript("OnClick", function()
		if InCombatLockdown() then
			return
		end
		AutoScrapper:FillNextBatch()
	end)
	self.fillAllBtn = fillAllBtn

	-- Hooks to Blizzard scrapper
	blizzardScrappingFrame:HookScript("OnShow", function()
		if not IsInLegionTimerunnerMode() then
			return
		end
		self.frame:Show()
		self:ReevaluateScrapper()
		if GetAutoFill() then
			AutoScrapper:FillNextBatch()
		end
	end)

	blizzardScrappingFrame:HookScript("OnHide", function()
		self.frame:Hide()
	end)
end

--------------------------------------------------------------------------------
-- Refresh grid of scrappable items
--------------------------------------------------------------------------------

---Refresh the grid of scrappable items.
function AutoScrapperFrame:Refresh()
	if InCombatLockdown() then
		return
	end
	if not IsInLegionTimerunnerMode() then
		return
	end

	local items = AutoScrapper:GetScrappableItems(GetMaxQuality(), AutoScrapper.settings.minLevelDiff or 0)
	local perRow, size, pad = GRID_STRIDE, GRID_ICON_SIZE, GRID_GAP

	local itemRows = math.ceil(#items / perRow)
	local rows = (itemRows < MIN_NUM_ROWS) and MIN_NUM_ROWS or itemRows
	local totalSlots = rows * perRow
	self.content:SetSize((size + pad) * perRow, (size + pad) * rows)

	-- Ensure enough buttons exist
	for i = #self.buttons + 1, totalSlots do
		local btn = CreateFrame("Button", nil, self.content)
		btn:SetSize(size, size)

		btn:SetScript("OnClick", OnClick)
		btn:SetScript("OnEnter", OnEnter)
		btn:SetScript("OnLeave", OnLeave)

		-- Background slot texture
		btn._Background = btn:CreateTexture(nil, "BACKGROUND")
		btn._Background:SetAllPoints()
		btn._Background:SetAtlas("bags-item-slot")
		btn._Background:SetAlpha(0.8)

		-- Icon
		btn._Icon = btn.Icon or btn.icon
		if not btn._Icon then
			btn._Icon = btn:CreateTexture(nil, "ARTWORK")
			btn._Icon:SetAllPoints()
		end

		-- Disable Blizzard's "new item" glow
		if btn.NewItemTexture then
			btn.NewItemTexture:Hide()
			btn.NewItemTexture.Show = function() end
		end
		if btn.BattlepayItemTexture then
			btn.BattlepayItemTexture:Hide()
			btn.BattlepayItemTexture.Show = function() end
		end

		-- Custom quality border
		btn._QualityBorder = btn:CreateTexture(nil, "OVERLAY")
		btn._QualityBorder:SetAllPoints()
		btn._QualityBorder:SetAtlas("UI-Frame-IconBorder")
		btn._QualityBorder:Hide()

		-- Empty slot texture
		btn._EmptyIcon = btn:CreateTexture(nil, "ARTWORK")
		btn._EmptyIcon:SetAllPoints()
		btn._EmptyIcon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
		btn._EmptyIcon:SetAlpha(0.4)
		btn._EmptyIcon:Hide()

		self.buttons[i] = btn
	end

	-- Update all slots
	for i = 1, totalSlots do
		local row = math.floor((i - 1) / perRow)
		local col = (i - 1) % perRow
		local btn = self.buttons[i]

		btn:SetSize(size, size)
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", col * (size + pad), -(row * (size + pad)))

		local item = items[i]
		if item then
			btn._Icon:SetTexture(item.icon)
			btn._Icon:SetTexCoord(0, 1, 0, 1)
			btn._Icon:SetDesaturated(false)
			btn.bag, btn.slot, btn.link = item.bag, item.slot, item.link

			local color = ITEM_QUALITY_COLORS[item.quality]
			if color then
				btn._QualityBorder:SetVertexColor(color.r, color.g, color.b)
				btn._QualityBorder:Show()
			else
				btn._QualityBorder:Hide()
			end

			if btn._EmptyIcon then
				btn._EmptyIcon:Hide()
			end
		else
			btn._Icon:SetTexture(nil)
			btn.bag, btn.slot, btn.link = nil, nil, nil
			btn._QualityBorder:Hide()
			if btn._EmptyIcon then
				btn._EmptyIcon:Show()
			end
		end

		btn:Show()
	end

	kprint("Refresh complete:", #items, "items,", totalSlots - #items, "empty slots,", totalSlots, "total")
end

---Reevaluate the scrapper contents and auto-fill if enabled.
function AutoScrapperFrame:ReevaluateScrapper()
	if InCombatLockdown() then
		return
	end
	if not IsInLegionTimerunnerMode() then
		return
	end
	if self._reevaluating then
		return
	end

	self._reevaluating = true
	self:Refresh()

	if ScrappingMachineFrame and ScrappingMachineFrame:IsShown() and GetAutoFill() then
		C_ScrappingMachineUI.RemoveAllScrapItems()

		C_Timer.After(0, function()
			local items = AutoScrapper:GetScrappableItems(GetMaxQuality(), AutoScrapper.settings.minLevelDiff or 0)
			local filled = 0
			for _, item in ipairs(items) do
				if AutoScrapper:ScrapItemFromBag(item.bag, item.slot) then
					filled = filled + 1
				end
			end

			local pendingCount = 0
			for i = 0, SCRAPPING_MACHINE_SLOTS - 1 do
				if C_ScrappingMachineUI.GetCurrentPendingScrapItemLocationByIndex(i) then
					pendingCount = pendingCount + 1
				end
			end

			kprint("ReevaluateScrapper: placed", filled, "items; scrapper now has", pendingCount, "queued")
			self._reevaluating = false
		end)
	else
		self._reevaluating = false
	end
end

--------------------------------------------------------------------------------
-- Eventing: auto-fill when empty
--------------------------------------------------------------------------------

local function IsScrapperEmpty()
	for i = 0, SCRAPPING_MACHINE_SLOTS - 1 do
		if C_ScrappingMachineUI.GetCurrentPendingScrapItemLocationByIndex(i) then
			return false
		end
	end
	return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("SCRAPPING_MACHINE_PENDING_ITEM_CHANGED")
f:RegisterEvent("SCRAPPING_MACHINE_SCRAPPING_FINISHED")
f:RegisterEvent("BAG_UPDATE_DELAYED")

f:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "Blizzard_ScrappingMachineUI" then
		AutoScrapperFrame:Initialize()
	elseif event == "SCRAPPING_MACHINE_PENDING_ITEM_CHANGED" then
		if GetAutoFill() then
			AutoScrapperFrame:Refresh()
		end
	elseif event == "SCRAPPING_MACHINE_SCRAPPING_FINISHED" then
		if GetAutoFill() then
			C_Timer.After(0.2, function()
				AutoScrapper:FillNextBatch()
			end)
		end
	elseif event == "BAG_UPDATE_DELAYED" then
		if ScrappingMachineFrame and ScrappingMachineFrame:IsShown() then
			if IsScrapperEmpty() then
				AutoScrapperFrame:ReevaluateScrapper()
			end
		end
	end
end)
