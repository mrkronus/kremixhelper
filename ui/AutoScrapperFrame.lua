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

local _, Addon = ...

local kprint = Addon.Settings.kprint
local AutoScrapper = Addon.AutoScrapper

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SCRAPPER_FRAME_WIDTH      = 325
local GRID_STRIDE               = 7
local SCRAPPING_MACHINE_SLOTS   = 9

--------------------------------------------------------------------------------
-- AutoScrapperFrame
--------------------------------------------------------------------------------

---@class AutoScrapperFrame
local AutoScrapperFrame = {
    frame       = nil,
    scrollFrame = nil,
    content     = nil,
    buttons     = {},
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
    if InCombatLockdown() then return end
    AutoScrapper:ScrapItemFromBag(btn.bag, btn.slot)
end

local function OnEnter(btn)
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(btn.link)
    GameTooltip:Show()
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

    -- Scroll frame grid
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -180)
    scroll:SetPoint("BOTTOMRIGHT", -35, 40)
    self.scrollFrame = scroll
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
    local perRow, size, pad = GRID_STRIDE, 35, 5
    local rows = math.ceil(#items / perRow)
    self.content:SetSize((size + pad) * perRow, (size + pad) * rows)

    -- Ensure enough buttons exist
    for i = #self.buttons + 1, #items do
        local btn = CreateFrame("Button", nil, self.content, "ContainerFrameItemButtonTemplate")
        btn:SetScript("OnClick", OnClick)
        btn:SetScript("OnEnter", OnEnter)
        btn:SetScript("OnLeave", OnLeave)

        btn._Background = btn:CreateTexture(nil, "BACKGROUND")
        btn._Background:SetAllPoints()
        btn._Background:SetAtlas("bags-item-slot")
        btn._Background:SetAlpha(0.8)

        btn._Icon = btn.Icon or btn.icon
        if not btn._Icon then
            btn._Icon = btn:CreateTexture(nil, "ARTWORK")
            btn._Icon:SetAllPoints()
        end

        local normal    = btn:GetNormalTexture()
        local pushed    = btn:GetPushedTexture()
        local highlight = btn:GetHighlightTexture()
        if normal then normal:SetTexture(nil) end
        if pushed then pushed:SetTexture(nil) end
        if highlight then
            highlight:SetTexture(nil)
            highlight:SetAlpha(0)
        end

        btn:HookScript("OnShow",       function(b) local h=b:GetHighlightTexture(); if h then h:SetAlpha(0) end end)
        btn:HookScript("OnEnable",     function(b) local h=b:GetHighlightTexture(); if h then h:SetAlpha(0) end end)
        btn:HookScript("OnSizeChanged",function(b) local h=b:GetHighlightTexture(); if h then h:SetAlpha(0) end end)

        btn:Hide()
        self.buttons[i] = btn
    end

    -- Update buttons
    for i, item in ipairs(items) do
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        local btn = self.buttons[i]

        btn:SetSize(size, size)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", col * (size + pad), -(row * (size + pad)))

        if btn._Background then btn._Background:Show() end

        if btn._Icon then
            if item.icon then
                btn._Icon:SetTexture(item.icon)
                btn._Icon:SetTexCoord(0, 1, 0, 1)
                btn._Icon:SetDesaturated(false)
                kprint("Refresh: set icon for", item.link or "?", "icon", item.icon)
            else
                btn._Icon:SetTexture(nil)
                kprint("Refresh: cleared icon for", item.link or "?", "(no icon)")
            end
        end

        btn.bag, btn.slot, btn.link = item.bag, item.slot, item.link

        local color = ITEM_QUALITY_COLORS[item.quality]
        if btn.IconBorder and color then
            btn.IconBorder:SetVertexColor(color.r, color.g, color.b)
            btn.IconBorder:Show()
        elseif btn.IconBorder then
            btn.IconBorder:Hide()
        end

        btn:Show()
    end

    -- Hide unused buttons
    for i = #items + 1, #self.buttons do
        local btn = self.buttons[i]
        btn:Hide()
        if btn._Background then btn._Background:Show() end
        if btn._Icon then btn._Icon:SetTexture(nil) end
    end

    kprint("Refresh complete:", #items, "items shown,", #self.buttons - #items, "buttons hidden")
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
            C_Timer.After(0.1, function() AutoScrapper:FillNextBatch() end)
        end
    end
end)
