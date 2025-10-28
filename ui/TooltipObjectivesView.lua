--[[-----------------------------------------------------------------------------
  TooltipObjectivesView.lua
  Purpose:
    - Provide tooltip content for objectives (quests, etc.)
    - Columns: Status Icon | Quest Title | Extra Info
    - Section header spans all 3 columns
    - Hover a row to highlight it
    - Click a row to open the quest in the quest log
-------------------------------------------------------------------------------]]--

local _, Addon = ...

local Colors   = Addon.Colors
local colorize = Addon.Colorize

local InfiniteResearch = Addon.InfiniteResearch

--------------------------------------------------------------------------------
-- Quest Helpers
--------------------------------------------------------------------------------

---@enum Addon.QuestTags
Addon.QuestTags = {
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

---@enum Addon.QuestFrequency
Addon.QuestFrequency = {
  Default          = 0,
  Daily            = 1,
  Weekly           = 2,
  ResetByScheduler = 3,
}

-- Atlas mappings
local ATLAS_BY_FREQUENCY = {
  [Addon.QuestFrequency.Daily]  = "QuestType-Daily",
  [Addon.QuestFrequency.Weekly] = "QuestType-Weekly",
}

local ATLAS_BY_TAG = {
  [Addon.QuestTags.Group]      = "QuestType-Group",
  [Addon.QuestTags.PvP]        = "QuestType-PvP",
  [Addon.QuestTags.Dungeon]    = "QuestType-Dungeon",
  [Addon.QuestTags.Raid]       = "QuestType-Raid",
  [Addon.QuestTags.Legendary]  = "QuestType-Legendary",
  [Addon.QuestTags.Scenario]   = "QuestType-Scenario",
  [Addon.QuestTags.Account]    = "QuestType-Account",
  [Addon.QuestTags.CombatAlly] = "QuestType-CombatAlly",
  [Addon.QuestTags.Delve]      = "QuestType-Delve",
}

local DEFAULT_ATLAS = "QuestNormal" -- generic yellow "!" fallback

---Return atlas markup string if atlas exists.
---@param name string|nil
---@return string
local function AtlasMarkup(name)
  if name and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
    return ("|A:%s:16:16:0:0|a"):format(name)
  end
  return ""
end

---Return an icon markup string for a quest.
---@param questID number
---@return string
function Addon.GetQuestIconMarkup(questID)
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

---@class ObjectivesView
local ObjectivesView = {}

---Populate the objectives tooltip.
---@param tooltip table
function ObjectivesView:Populate(tooltip)
  tooltip:EnableMouse(true)
  tooltip:SetColumnLayout(3, "CENTER", "LEFT", "RIGHT")

  if Addon.IsInLegionTimerunnerMode() then
    Addon.TooltipHelpers.AddSectionHeading(tooltip, "Infinite Research")

    local quests = InfiniteResearch:GetInfiniteResearchQuests()
    if not quests or #quests == 0 then
      local line = tooltip:AddLine()
      tooltip:SetCell(line, 1, "No Infinite Research quests found", nil, "LEFT", tooltip:GetColumnCount())
      return
    end

    for _, quest in ipairs(quests) do
      local icon = Addon.GetQuestIconMarkup(quest.questID)
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
          if not QuestMapFrame or not QuestMapFrame:IsShown() then
            ToggleQuestLog()
          end

          if C_QuestLog.IsOnQuest(quest.questID) then
            if QuestMapFrame_OpenToQuestDetails then
              QuestMapFrame_OpenToQuestDetails(quest.questID)
            else
              C_QuestLog.SetSelectedQuest(quest.questID)
              C_QuestLog.QuestLog_Update()
            end
          else
            C_QuestLog.SetSelectedQuest(quest.questID)
          end
        end
      end)
    end
  else
    local line = tooltip:AddLine()
    tooltip:SetCell(line, 1,
      colorize("The current character is not a Legion Remix character", Colors.Grey),
      nil, "LEFT", tooltip:GetColumnCount())
  end
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.ObjectivesView = ObjectivesView
