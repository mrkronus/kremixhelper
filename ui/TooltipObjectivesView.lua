--[[-------------------------------------------------------------------------
TooltipObjectivesView.lua
Purpose:
  Provides tooltip content for objectives (quests, etc).
  Columns: Status Icon | Quest Title | Extra Info
  - Section header spans all 3 columns
  - Hover a row to highlight it
  - Click a row to open the quest in the quest log
---------------------------------------------------------------------------]]

local _, KRemixHelper = ...

local Fonts   = KRemixHelper.Fonts
local Colors  = KRemixHelper.Colors

local InfiniteResearch = KRemixHelper.InfiniteResearch


--------------------------------------------------------------------------------
-- Quest Helpers
--------------------------------------------------------------------------------

---@enum QuestTags
QuestTags = {
  Group       = 1,
  PvP         = 41,
  Raid        = 62,
  Dungeon     = 81,
  Legendary   = 83,
  Heroic      = 85,
  Raid10      = 88,
  Raid25      = 89,
  Scenario    = 98,
  Account     = 102,
  CombatAlly  = 266,
  Delve       = 288,
}

---@enum QuestFrequency
QuestFrequency = {
  Default          = 0,
  Daily            = 1,
  Weekly           = 2,
  ResetByScheduler = 3,
}

-- Atlas mappings
local ATLAS_BY_FREQUENCY = {
  [QuestFrequency.Daily]  = "QuestType-Daily",
  [QuestFrequency.Weekly] = "QuestType-Weekly",
}

local ATLAS_BY_TAG = {
  [QuestTags.Group]      = "QuestType-Group",
  [QuestTags.PvP]        = "QuestType-PvP",
  [QuestTags.Dungeon]    = "QuestType-Dungeon",
  [QuestTags.Raid]       = "QuestType-Raid",
  [QuestTags.Legendary]  = "QuestType-Legendary",
  [QuestTags.Scenario]   = "QuestType-Scenario",
  [QuestTags.Account]    = "QuestType-Account",
  [QuestTags.CombatAlly] = "QuestType-CombatAlly",
  [QuestTags.Delve]      = "QuestType-Delve",
}

local DEFAULT_ATLAS = "QuestNormal" -- generic yellow "!" fallback

local function AtlasMarkup(name)
  if name and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
    return ("|A:%s:16:16:0:0|a"):format(name)
  end
  return ""
end

---Return an icon markup string for a quest.
---@param questID number
---@return string
function GetQuestIconMarkup(questID)
  if not questID then return "" end

  -- Frequency first (daily/weekly)
  local index = C_QuestLog.GetLogIndexForQuestID(questID)
  if index then
    local info = C_QuestLog.GetInfo(index)
    if info and info.frequency then
      local atlas = ATLAS_BY_FREQUENCY[info.frequency]
      local markup = AtlasMarkup(atlas)
      if markup ~= "" then
        return markup
      end
    end
  end

  -- Tag fallback
  local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
  if tagInfo and tagInfo.tagID then
    local atlas = ATLAS_BY_TAG[tagInfo.tagID]
    local markup = AtlasMarkup(atlas)
    if markup ~= "" then
      return markup
    end
  end

  -- Default icon
  return AtlasMarkup(DEFAULT_ATLAS)
end

--------------------------------------------------------------------------------
-- ObjectivesView
--------------------------------------------------------------------------------

local ObjectivesView = {}

function ObjectivesView:Populate(tooltip)
    tooltip:EnableMouse(true)
    tooltip:SetColumnLayout(3, "CENTER", "LEFT", "RIGHT")

    if IsInLegionTimerunnerMode() then
        AddSectionHeading(tooltip, "Infinite Research")

        local quests = InfiniteResearch:GetInfiniteResearchQuests()
        if #quests == 0 then
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, "No Infinite Research quests found", nil, "LEFT", tooltip:GetColumnCount())
            return
        end

        for _, quest in ipairs(quests) do
            local icon = GetQuestIconMarkup(quest.questID)
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, icon)
            tooltip:SetCell(line, 2, quest.title)
            tooltip:SetCell(line, 3, colorize(("ID: %d"):format(quest.questID), Colors.Grey))

            -- Highlight row on hover
            tooltip:SetLineScript(line, "OnEnter", function()
                tooltip:SetLineColor(line, 0.2, 0.4, 0.8, 0.3)
                GameTooltip:SetOwner(tooltip, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(("quest:%d"):format(quest.questID))
                GameTooltip:Show()
            end)
            tooltip:SetLineScript(line, "OnLeave", function()
                tooltip:SetLineColor(line, 0, 0, 0, 0)
                GameTooltip:Hide()
            end)

            -- Click row to open quest in log
            tooltip:SetLineScript(line, "OnMouseDown", function(_, button)
                if button == "LeftButton" and quest.questID then
                    -- Always open the Quest Log panel
                    if not QuestMapFrame or not QuestMapFrame:IsShown() then
                        ToggleQuestLog()
                    end

                    -- If the quest is in your log, focus it
                    if C_QuestLog.IsOnQuest(quest.questID) then
                        if QuestMapFrame_OpenToQuestDetails then
                            QuestMapFrame_OpenToQuestDetails(quest.questID)
                        else
                            C_QuestLog.SetSelectedQuest(quest.questID)
                            C_QuestLog.QuestLog_Update()
                        end
                    else
                        -- Fallback: just show the tooltip again
                        C_QuestLog.SetSelectedQuest(quest.questID)
                    end
                end
            end)
        end
    else
        local line = tooltip:AddLine()
        tooltip:SetCell(line, 1, colorize("The current character is not a Legion Remix character", Colors.Grey), nil, "LEFT", tooltip:GetColumnCount())
    end
end


--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

KRemixHelper.ObjectivesView = ObjectivesView
