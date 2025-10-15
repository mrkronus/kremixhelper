--[[-----------------------------------------------------------------------------
  AutoScrapperFrame.lua
  Purpose:
    Side panel UI for scrapping, consumes AutoScrapper logic.
    Provides:
      - Quality dropdown
      - Scroll grid of scrappable items
      - Fill All button
      - Auto Fill on Open checkbox
      - Auto Scrap All checkbox
-------------------------------------------------------------------------------]]

local _, Addon = ...
local AutoScrapper = Addon.AutoScrapper


--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SCRAPPER_FRAME_WIDTH = 325
local GRID_STRIDE          = 7
local ICON_FALLBACK        = 134400


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
-- Event Handlers
--------------------------------------------------------------------------------

local function OnClick(btn)
    AutoScrapper:ScrapItem(btn.bag, btn.slot)
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
                AutoScrapper.settings.maxQuality = q
                UIDropDownMenu_SetSelectedValue(dropdown, q)
                self:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    AutoScrapper.settings.maxQuality = AutoScrapper.settings.maxQuality or Enum.ItemQuality.Rare
    UIDropDownMenu_SetSelectedValue(dropdown, AutoScrapper.settings.maxQuality)

    --------------------------------------------------------------------------------
    -- Checkboxes
    --------------------------------------------------------------------------------
    local autoFillCheck = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
    autoFillCheck:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 15, -35)
    autoFillCheck.Text:SetText("Auto Fill on Open")
    autoFillCheck:SetChecked(AutoScrapper.settings.autoFill or false)
    autoFillCheck:SetScript("OnClick", function(btn)
        AutoScrapper.settings.autoFill = btn:GetChecked()
    end)

    local autoScrapCheck = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
    autoScrapCheck:SetPoint("BOTTOMLEFT", autoFillCheck, "TOPLEFT", 0, 5)
    autoScrapCheck.Text:SetText("Auto Scrap All")
    autoScrapCheck:SetChecked(AutoScrapper.settings.autoScrapAll or false)
    autoScrapCheck:SetScript("OnClick", function(btn)
        AutoScrapper.settings.autoScrapAll = btn:GetChecked()
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
        self:Refresh()
        C_ScrappingMachineUI.RemoveAllScrapItems()
        for _, item in ipairs(AutoScrapper:GetScrappableItems()) do
            AutoScrapper:ScrapItem(item.bag, item.slot)
        end
    end)

    --------------------------------------------------------------------------------
    -- Hooks
    --------------------------------------------------------------------------------
    blizzardScrappingFrame:HookScript("OnShow", function()
        self.frame:Show()
        self:Refresh()
        if AutoScrapper.settings.autoFill then
            C_ScrappingMachineUI.RemoveAllScrapItems()
            for _, item in ipairs(AutoScrapper:GetScrappableItems()) do
                AutoScrapper:ScrapItem(item.bag, item.slot)
            end
        end
    end)

    blizzardScrappingFrame:HookScript("OnHide", function()
        self.frame:Hide()
    end)

    -- Hook Scrap button for Auto Scrap All
    ScrappingMachineFrame.ScrapButton:HookScript("OnClick", function()
        if AutoScrapper.settings.autoScrapAll then
            C_ScrappingMachineUI.RemoveAllScrapItems()
            for _, item in ipairs(AutoScrapper:GetScrappableItems()) do
                AutoScrapper:ScrapItem(item.bag, item.slot)
            end
            -- Blizzard’s secure handler then calls ScrapItems() safely
        end
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

        -- Icon texture
        if btn._Icon then
            btn._Icon:SetTexture(item.icon or ICON_FALLBACK)
            btn._Icon:SetTexCoord(0, 1, 0, 1)
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
        self.buttons[i]:Hide()
    end
end


--------------------------------------------------------------------------------
-- Eventing
--------------------------------------------------------------------------------

local pendingCount = 0

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("SCRAPPING_MACHINE_PENDING_ITEM_CHANGED")

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_ScrappingMachineUI" then
        AutoScrapperFrame:Initialize()
        return
    end

    if event == "SCRAPPING_MACHINE_PENDING_ITEM_CHANGED" then
        if AutoScrapper.settings.autoScrapAll and ScrappingMachineFrame:IsShown() then
            C_Timer.After(0, function()
                -- Recalculate pending count by scanning slots
                pendingCount = 0
                for slot = 1, 9 do
                    local itemLocation = C_ScrappingMachineUI.GetScrapItemLocation
                        and C_ScrappingMachineUI.GetScrapItemLocation(slot)
                    if itemLocation then
                        pendingCount = pendingCount + 1
                    end
                end

                -- Top up until slots are full
                if pendingCount < 9 then
                    local items = AutoScrapper:GetScrappableItems()
                    for _, item in ipairs(items) do
                        AutoScrapper:ScrapItem(item.bag, item.slot)
                        pendingCount = pendingCount + 1
                        if pendingCount >= 9 then break end
                    end
                end
            end)
        end
    end
end)
