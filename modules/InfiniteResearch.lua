--[[-----------------------------------------------------------------------------
  InfiniteResearch.lua
  Purpose:
    - Provide a class-style API to retrieve all active quests containing
      "Infinite Research" in the title
    - Intended for use with LibQTip tooltips and chat output
  Notes:
    - Returns full quest metadata needed for hoverable links
    - Each quest now includes its objectives (requirements) with completion state
    - Quest links open the quest log on click
    - To keep data fresh, consumers should listen for QUEST_LOG_UPDATE
-------------------------------------------------------------------------------]]

local _, Addon = ...

---@class InfiniteResearch
local InfiniteResearch = {}

--------------------------------------------------------------------------------
-- Telemetry
--------------------------------------------------------------------------------

InfiniteResearch.TelemetryEnabled = true -- set false to silence logs

local function Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff80ff80[IR]|r " .. msg)
	else
		print("[IR] " .. msg)
	end
end

--------------------------------------------------------------------------------
-- Classification
--------------------------------------------------------------------------------

-- Titles containing these phrases are considered non-repeatable
local NON_REPEATABLE_PATTERNS = {
	"infinite research: special assignment",
	"infinite research: self improvement",
	"infinite research promotion",
	"infinite research: special assignment",
	"infinite research: no task too small",
	"infinite research: timeworn keystone dungeon",
}

local function IsRepeatableByTitle(title)
	local lower = title:lower()
	for _, phrase in ipairs(NON_REPEATABLE_PATTERNS) do
		if lower:find(phrase, 1, true) then
			return false
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- Main API
--------------------------------------------------------------------------------

---Get all active Infinite Research quests, grouped and sorted.
---@return table repeatable, table nonRepeatable
function InfiniteResearch:GetInfiniteResearchQuests()
	local repeatable, nonRepeatable = {}, {}
	local searchTerm = "infinite research"

	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(i)
		if info and info.title and info.title:lower():find(searchTerm) then
			local questID = info.questID
			local title = QuestUtils_GetQuestName(questID) or info.title
			local link = format("|cff00ff00|Hquest:%d:%d|h[%s]|h|r", questID, questID, title)
			local isComplete = C_QuestLog.IsComplete(questID)

			-- Objectives
			local objectives = {}
			local objData = C_QuestLog.GetQuestObjectives(questID)
			if objData then
				for _, obj in ipairs(objData) do
					table.insert(objectives, {
						text = obj.text or "",
						finished = obj.finished,
						numFulfilled = obj.numFulfilled,
						numRequired = obj.numRequired,
						type = obj.type,
					})
				end
			end

			local quest = {
				questID = questID,
				title = title,
				link = link,
				isComplete = isComplete,
				objectives = objectives,
			}

			-- Classification by title
			local isRepeatable = IsRepeatableByTitle(title)

			if isRepeatable then
				table.insert(repeatable, quest)
			else
				table.insert(nonRepeatable, quest)
			end
		end
	end

	-- Sort alphabetically
	table.sort(repeatable, function(a, b)
		return a.title < b.title
	end)
	table.sort(nonRepeatable, function(a, b)
		return a.title < b.title
	end)

	return repeatable, nonRepeatable
end

--------------------------------------------------------------------------------
-- Eventing
--------------------------------------------------------------------------------

-- Hook quest links so clicking them opens the quest log
hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
	local questID = link:match("^quest:(%d+):%d+")
	if questID then
		QuestMapFrame_OpenToQuestDetails(tonumber(questID))
	end
end)

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.InfiniteResearch = InfiniteResearch
