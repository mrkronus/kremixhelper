--[[-----------------------------------------------------------------------------
  AutoScrapperFrame.lua
  Purpose:
    - Side panel UI for scrapping, delegates to AutoScrapper core
    Provides:
      - Quality dropdown
      - Scroll grid of scrappable items
      - Fill All button
      - Auto Fill on Open checkbox
      - Auto Scrap All checkbox
      - Protect Higher iLvl Items checkbox
  Notes:
    - Calls AutoScrapper:FillNextBatch() only on open, Fill button, or empty
    - Uses AceDB profile values if available
-----------------------------------------------------------------------------]]

local _, Addon                = ...

local kprint                  = Addon.Settings.kprint
local AutoScrapper            = Addon.AutoScrapper

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SCRAPPER_FRAME_WIDTH    = 325
local GRID_STRIDE             = 7
local SCRAPPING_MACHINE_SLOTS = 9

--------------------------------------------------------------------------------
-- AutoScrapperFrame
--------------------------------------------------------------------------------

---@class AutoScrapperFrame
local AutoScrapperFrame       = {
    frame       = nil,
    scrollFrame = nil,
    content     = nil,
    buttons     = {},
}
Addon.AutoScrapperFrame       = AutoScrapperFrame

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
    if InCombatLockdown() then return end
    AutoScrapper:ScrapItemFromBag(btn.bag, btn.slot)
end

local function OnEnter(btn)
    if btn.link then
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(btn.link)
        GameTooltip:Show()
    end
end

local function OnLeave()
    GameTooltip:Hide()
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

function AutoScrapperFrame:Initialize()
    if self.frame then return end
    local blizzardScrappingFrame = ScrappingMachineFrame
    if not blizzardScrappingFrame then return end
    if InCombatLockdown() then return end

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
    dropdown:SetPoint("TOPLEFT", qualityLabel, "BOTTOMLEFT", -20, -5)
    UIDropDownMenu_SetWidth(dropdown, 120)
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for q = Enum.ItemQuality.Common, Enum.ItemQuality.Epic do
            local name  = _G["ITEM_QUALITY" .. q .. "_DESC"]
            local color = ITEM_QUALITY_COLORS[q]
            local info  = UIDropDownMenu_CreateInfo()
            info.value  = q
            info.text   = color.hex .. name .. "|r"
            info.func   = function()
                SetMaxQuality(q)
                UIDropDownMenu_SetSelectedValue(dropdown, q)
                owner:ReevaluateScrapper()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dropdown, GetMaxQuality())

    local autoScrapCheck = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
    autoScrapCheck:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 15, 0)
    autoScrapCheck.Text:SetText("Auto Fill When Empty")
    autoScrapCheck:SetChecked(GetAutoFill())
    autoScrapCheck:SetScript("OnClick", function(btn)
        local isChecked = btn:GetChecked()
        SetAutoFill(isChecked)
        if isChecked then
            self:ReevaluateScrapper()
        end
    end)

    local protectCheck = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
    protectCheck:SetPoint("TOPLEFT", autoScrapCheck, "BOTTOMLEFT", 0, 0)
    protectCheck.Text:SetText("Keep Higher iLvl Items")
    protectCheck:SetChecked(GetProtectHigherIlvl())
    protectCheck:SetScript("OnClick", function(btn)
        SetProtectHigherIlvl(btn:GetChecked())
        self:ReevaluateScrapper()
    end)

    -- Scroll frame grid container
    local gridContainer = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    gridContainer:SetPoint("TOPLEFT", 10, -140)
    gridContainer:SetPoint("BOTTOMRIGHT", -10, 40)

    -- Scroll frame inside the container
    local scroll = CreateFrame("ScrollFrame", nil, gridContainer, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 5, -5)
    scroll:SetPoint("BOTTOMRIGHT", -28, 5)
    self.scrollFrame = scroll

    -- Content frame that holds the item buttons
    self.content = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollFrame:SetScrollChild(self.content)

    -- Fill All button
    local fillAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    fillAllBtn:SetSize(120, 22)
    fillAllBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    fillAllBtn:SetText("Fill All")
    fillAllBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end
        AutoScrapper:FillNextBatch()
    end)
    self.fillAllBtn = fillAllBtn

    -- Hooks to Blizzard scrapper
    blizzardScrappingFrame:HookScript("OnShow", function()
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

function AutoScrapperFrame:Refresh()
    if InCombatLockdown() then return end

    local items = AutoScrapper:GetScrappableItems(GetMaxQuality(), AutoScrapper.settings.minLevelDiff or 0)
    local perRow, size, pad = GRID_STRIDE, 36, 3

    -- How many rows of items we actually need
    local itemRows = math.ceil(#items / perRow)
    local rows

    if itemRows < 4 then
        rows = 4
    else
        -- pad the last row to a full stride
        rows = itemRows
    end

    local totalSlots = rows * perRow
    self.content:SetSize((size + pad) * perRow, (size + pad) * rows)

    -- Ensure enough buttons exist
    for i = #self.buttons + 1, totalSlots do
        local btn = CreateFrame("Button", nil, self.content, "ContainerFrameItemButtonTemplate")
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

        -- Empty slot texture (shows when no item is present)
        btn._EmptyIcon = btn:CreateTexture(nil, "ARTWORK")
        btn._EmptyIcon:SetAllPoints()
        btn._EmptyIcon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
        btn._EmptyIcon:SetAlpha(0.4) -- faint look
        btn._EmptyIcon:Hide()

        self.buttons[i] = btn
    end

    -- Update all slots (items + empties)
    for i = 1, totalSlots do
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        local btn = self.buttons[i]

        btn:SetSize(size, size)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", col * (size + pad), -(row * (size + pad)))

        local item = items[i]
        if item then
            -- Show item
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

            if btn._EmptyIcon then btn._EmptyIcon:Hide() end
        else
            -- Empty slot
            btn._Icon:SetTexture(nil)
            btn.bag, btn.slot, btn.link = nil, nil, nil
            btn._QualityBorder:Hide()
            if btn._EmptyIcon then btn._EmptyIcon:Show() end
        end

        btn:Show()
    end

    kprint("Refresh complete:", #items, "items,", totalSlots - #items, "empty slots,", totalSlots, "total")
end

function AutoScrapperFrame:ReevaluateScrapper()
    if InCombatLockdown() then return end
    if self._reevaluating then return end
    self._reevaluating = true

    -- Always redraw the grid first
    self:Refresh()

    if ScrappingMachineFrame and ScrappingMachineFrame:IsShown() and GetAutoFill() then
        -- Clear current pending items
        C_ScrappingMachineUI.RemoveAllScrapItems()

        -- Delay one frame so the UI state settles before re‑adding
        C_Timer.After(0, function()
            local items = AutoScrapper:GetScrappableItems(
                GetMaxQuality(),
                AutoScrapper.settings.minLevelDiff or 0
            )
            if #items == 0 then
                kprint("ReevaluateScrapper: no eligible items found")
            else
                local filled = 0
                for _, item in ipairs(items) do
                    if AutoScrapper:ScrapItemFromBag(item.bag, item.slot) then
                        filled = filled + 1
                    end
                end
                kprint("ReevaluateScrapper: placed", filled, "items after refresh")
            end
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

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_ScrappingMachineUI" then
        AutoScrapperFrame:Initialize()
    elseif event == "SCRAPPING_MACHINE_PENDING_ITEM_CHANGED" then
        if GetAutoFill() and IsScrapperEmpty() then
            C_Timer.After(0.05, function() AutoScrapper:FillNextBatch() end)
        end
    elseif event == "SCRAPPING_MACHINE_SCRAPPING_FINISHED" then
        if GetAutoFill() then
            C_Timer.After(0.1, function()
                AutoScrapper:FillNextBatch()
                AutoScrapperFrame:ReevaluateScrapper()
            end)
        end
    end
end)
