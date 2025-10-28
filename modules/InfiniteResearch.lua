--[[-------------------------------------------------------------------------
InfiniteResearch.lua
Purpose:
  Provides a class-style API to retrieve all active quests containing
  "Infinite Research" in the title. Intended for use with LibQTip tooltips
  and chat output.

Notes:
  - Returns full quest metadata needed for hoverable links
  - Uses defensive checks and scoped blocks
  - Includes a slash command to print matching quests
  - Quest links open the quest log on click
  - To keep data fresh, consumers should listen for QUEST_LOG_UPDATE
---------------------------------------------------------------------------]]

local _, KRemixHelper = ...


--------------------------------------------------------------------------------
-- InfiniteResearch
--------------------------------------------------------------------------------

InfiniteResearch = {}

function InfiniteResearch:GetInfiniteResearchQuests()
  local results = {}
  local searchTerm = "infinite research"

  for i = 1, C_QuestLog.GetNumQuestLogEntries() do
    local info = C_QuestLog.GetInfo(i)
    if info and info.title and info.title:lower():find(searchTerm) then
      local questID = info.questID
      local title = QuestUtils_GetQuestName(questID) or info.title
      local link = format("|cff00ff00|Hquest:%d:%d|h[%s]|h|r", questID, questID, title)

      table.insert(results, {
        questID = questID,
        title = title,
        link = link,
        isHeader = info.isHeader,
        isTask = info.isTask,
        isBounty = info.isBounty,
        campaignID = info.campaignID,
        frequency = info.frequency,
        level = info.level,
        suggestedGroup = info.suggestedGroup,
        isOnMap = info.isOnMap,
        isHidden = info.isHidden,
        isAutoComplete = info.isAutoComplete,
      })
    end
  end

  return results
end


--------------------------------------------------------------------------------
-- Eventing
--------------------------------------------------------------------------------

SLASH_SPEAKINFINITERESEARCH1 = "/speakresearch"
SlashCmdList.SPEAKINFINITERESEARCH = function()
  local quests = InfiniteResearch:GetInfiniteResearchQuests()

  if #quests == 0 then
    print("No quests found with title containing: infinite research")
    return
  end

  for _, quest in ipairs(quests) do
    print("Found quest:", quest.link)
  end
end

hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
  local questID = link:match("^quest:(%d+):%d+")
  if questID then
    QuestMapFrame_OpenToQuestDetails(tonumber(questID))
  end
end)


--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

KRemixHelper.InfiniteResearch = InfiniteResearch