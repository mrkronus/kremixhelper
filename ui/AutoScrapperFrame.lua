--[[-----------------------------------------------------------------------------
  AutoScrapperFrame.lua (patched)
  Purpose:
    - Side panel UI for scrapping, now cleanly delegates to ScrappingUtils
    Provides:
      - Quality dropdown
      - Scroll grid of scrappable items
      - Fill All button
      - Auto Fill on Open checkbox
      - Auto Scrap All checkbox
  Notes:
    - Uses GetCurrentPendingScrapItemLocationByIndex for pending slots
    - Defers slot filling to next frame to avoid race/taint
    - Adds InCombatLockdown guards
    - Ready to read/write persisted settings via AceDB when wired
-------------------------------------------------------------------------------]]

local _, Addon = ...

local AutoScrapper   = Addon.AutoScrapper
local ScrappingUtils = Addon.ScrappingUtils

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SCRAPPER_FRAME_WIDTH = 325
local GRID_STRIDE          = 7
local ICON_FALLBACK        = 134400

-- Pending slots constant (kept local to avoid global pollution)
local MAX_PENDING_SLOTS = 9

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

---Get the addon AceDB profile (if available), else fallback to legacy settings.
---@return table profile
local function GetProfile()
    local ace = Addon.LibAceAddon
    if ace and ace.db and ace.db.profile then
        return ace.db.profile
    end
    -- Fallback to legacy in-memory settings for now
    return AutoScrapper and AutoScrapper.settings or {}
end

---Convenience getters/setters for settings (reads AceDB profile if present).
local function GetAutoFill()
    local p = GetProfile()
    return (p.autoFill ~= nil) and p.autoFill or (AutoScrapper.settings.autoFill or false)
end
local function SetAutoFill(val)
    local ace = Addon.LibAceAddon
    if ace and ace.db and ace.db.profile then
        ace.db.profile.autoFill = val
    else
        AutoScrapper.settings.autoFill = val
    end
end

local function GetAutoScrapAll()
    local p = GetProfile()
    return (p.autoScrapAll ~= nil) and p.autoScrapAll or (AutoScrapper.settings.autoScrapAll or false)
end
local function SetAutoScrapAll(val)
    local ace = Addon.LibAceAddon
    if ace and ace.db and ace.db.profile then
        ace.db.profile.autoScrapAll = val
    else
        AutoScrapper.settings.autoScrapAll = val
    end
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

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

local function OnClick(btn)
    if InCombatLockdown() then return end
    if ScrappingUtils then
        ScrappingUtils:ScrapItemFromBag(btn.bag, btn.slot)
    end
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

---Initialize the AutoScrapper side panel and wire up UI elements.
function AutoScrapperFrame:Initialize()
    if self.frame then return end
    local blizzardScrappingFrame = ScrappingMachineFrame
    if not blizzardScrappingFrame then return end

    if InCombatLockdown() then return end

    --------------------------------------------------------------------------------
    -- Frame container
    --------------------------------------------------------------------------------
    local frame = CreateFrame("Frame", nil, blizzardScrappingFrame, "InsetFrameTemplate")
    frame:SetSize(SCRAPPER_FRAME_WIDTH, blizzardScrappingFrame:GetHeight())
    frame:SetPoint("TOPLEFT", blizzardScrappingFrame, "TOPRIGHT", 5, 0)
    frame:Hide()
    self.frame = frame

    --------------------------------------------------------------------------------
    -- Quality dropdown
    --------------------------------------------------------------------------------
    local qualityLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    qualityLabel:SetPoint("TOPLEFT", 15, -30)
    qualityLabel:SetText("Maximum quality items to scrap")

    local dropdown = CreateFrame("Frame", "AutoScrapperQualityDropdown", frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", qualityLabel, "BOTTOMLEFT", -20, -5)
    UIDropDownMenu_SetWidth(dropdown, 150)
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
                self:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dropdown, GetMaxQuality())

    --------------------------------------------------------------------------------
    -- Checkboxes
    --------------------------------------------------------------------------------
    local autoFillCheck = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
    autoFillCheck:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 15, -35)
    autoFillCheck.Text:SetText("Auto Fill on Open")
    autoFillCheck:SetChecked(GetAutoFill())
    autoFillCheck:SetScript("OnClick", function(btn)
        SetAutoFill(btn:GetChecked())
    end)

    local autoScrapCheck = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
    autoScrapCheck:SetPoint("BOTTOMLEFT", autoFillCheck, "TOPLEFT", 0, 5)
    autoScrapCheck.Text:SetText("Auto Scrap All")
    autoScrapCheck:SetChecked(GetAutoScrapAll())
    autoScrapCheck:SetScript("OnClick", function(btn)
        SetAutoScrapAll(btn:GetChecked())
    end)

    --------------------------------------------------------------------------------
    -- Scroll frame grid
    --------------------------------------------------------------------------------
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -150)
    scroll:SetPoint("BOTTOMRIGHT", -35, 40)
    self.scrollFrame = scroll

    self.content = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollFrame:SetScrollChild(self.content)

    --------------------------------------------------------------------------------
    -- Fill All button
    --------------------------------------------------------------------------------
    local fillAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    fillAllBtn:SetSize(120, 22)
    fillAllBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    fillAllBtn:SetText("Fill All")
    fillAllBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end

        self:Refresh()

        C_ScrappingMachineUI.RemoveAllScrapItems()

        -- Defer filling to next frame to avoid racing the secure handler
        C_Timer.After(0, function()
            if not ScrappingMachineFrame or not ScrappingMachineFrame:IsShown() then return end
            for _, item in ipairs(AutoScrapper:GetScrappableItems()) do
                ScrappingUtils:ScrapItemFromBag(item.bag, item.slot)
            end
        end)
    end)

    --------------------------------------------------------------------------------
    -- Hooks
    --------------------------------------------------------------------------------
    blizzardScrappingFrame:HookScript("OnShow", function()
        if InCombatLockdown() then return end
        self.frame:Show()
        self:Refresh()
        if GetAutoFill() then
            C_ScrappingMachineUI.RemoveAllScrapItems()
            C_Timer.After(0, function()
                if not ScrappingMachineFrame or not ScrappingMachineFrame:IsShown() then return end
                for _, item in ipairs(AutoScrapper:GetScrappableItems()) do
                    ScrappingUtils:ScrapItemFromBag(item.bag, item.slot)
                end
            end)
        end
    end)

    blizzardScrappingFrame:HookScript("OnHide", function()
        self.frame:Hide()
    end)

    -- Hook Scrap button for Auto Scrap All (top-up after Blizzard triggers)
    ScrappingMachineFrame.ScrapButton:HookScript("OnClick", function()
        if not GetAutoScrapAll() then return end
        if InCombatLockdown() then return end

        -- After the click, keep topping up as long as panel is open
        C_Timer.After(0, function()
            if not ScrappingMachineFrame or not ScrappingMachineFrame:IsShown() then return end
            ScrappingUtils:AutoScrap()
        end)
    end)

    -- Refresh on bag updates
    local f = CreateFrame("Frame")
    f:RegisterEvent("BAG_UPDATE_DELAYED")
    f:SetScript("OnEvent", function()
        if blizzardScrappingFrame:IsShown() then
            self:Refresh()
        end
    end)
end
--------------------------------------------------------------------------------
-- Refresh
--------------------------------------------------------------------------------

---Refresh the scroll grid of scrappable items.
function AutoScrapperFrame:Refresh()
    if InCombatLockdown() then return end

    local items = AutoScrapper:GetScrappableItems()
    local perRow, size, pad = GRID_STRIDE, 35, 5
    local rows = math.ceil(#items / perRow)
    self.content:SetSize((size + pad) * perRow, (size + pad) * rows)

    -- Ensure enough buttons exist
    for i = #self.buttons + 1, #items do
        local btn = CreateFrame("Button", nil, self.content, "ContainerFrameItemButtonTemplate")
        btn:SetScript("OnClick", OnClick)
        btn:SetScript("OnEnter", OnEnter)
        btn:SetScript("OnLeave", OnLeave)

        -- Add a slot background (like bag slots)
        btn._Background = btn:CreateTexture(nil, "BACKGROUND")
        btn._Background:SetAllPoints()
        btn._Background:SetAtlas("bags-item-slot") -- Blizzard’s standard slot background
        btn._Background:SetAlpha(0.8)

        -- Normalize icon region
        btn._Icon = btn.Icon or btn.icon
        if not btn._Icon then
            btn._Icon = btn:CreateTexture(nil, "ARTWORK")
            btn._Icon:SetAllPoints()
        end

        -- Clear default slot/flash textures defensively
        local normal    = btn:GetNormalTexture()
        local pushed    = btn:GetPushedTexture()
        local highlight = btn:GetHighlightTexture()
        if normal then normal:SetTexture(nil) end
        if pushed then pushed:SetTexture(nil) end
        if highlight then
            highlight:SetTexture(nil)
            highlight:SetAlpha(0)
        end

        -- Kill any future highlight reinstatement by the template
        btn:HookScript("OnShow", function(b)
            local h = b:GetHighlightTexture()
            if h then
                h:SetTexture(nil)
                h:SetAlpha(0)
            end
        end)
        btn:HookScript("OnEnable", function(b)
            local h = b:GetHighlightTexture()
            if h then
                h:SetTexture(nil)
                h:SetAlpha(0)
            end
        end)
        btn:HookScript("OnSizeChanged", function(b)
            local h = b:GetHighlightTexture()
            if h then h:SetAlpha(0) end
        end)

        btn:Hide() -- Prevent first-frame flash
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

        -- Always show the slot background
        if btn._Background then
            btn._Background:Show()
        end

        -- Icon texture
        if btn._Icon then
            if item.icon then
                btn._Icon:SetTexture(item.icon)
                btn._Icon:SetTexCoord(0, 1, 0, 1)
                btn._Icon:SetDesaturated(false)
            else
                btn._Icon:SetTexture(nil) -- leave background visible when empty
            end
        end

        btn.bag, btn.slot, btn.link = item.bag, item.slot, item.link

        -- Border coloring
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
        if btn._Background then
            btn._Background:Show() -- keep slot background visible even when no item
        end
    end
end


--------------------------------------------------------------------------------
-- Eventing
--------------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("SCRAPPING_MACHINE_PENDING_ITEM_CHANGED")

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_ScrappingMachineUI" then
        AutoScrapperFrame:Initialize()
        return
    end

    if event == "SCRAPPING_MACHINE_PENDING_ITEM_CHANGED" then
        if GetAutoScrapAll() and ScrappingMachineFrame:IsShown() then
            C_Timer.After(0, function()
                if InCombatLockdown() then return end
                -- just refill slots, do NOT click ScrapButton here
                ScrappingUtils:AutoScrap()
            end)
        end
    end
end)
