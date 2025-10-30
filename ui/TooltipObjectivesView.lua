--[[-----------------------------------------------------------------------------
  TooltipObjectivesView.lua
  Purpose:
    - Provide tooltip content for objectives (quests, etc.)
    - Columns: Status Icon | Quest Title | Extra Info (objectives)
    - Section header spans all 3 columns
    - Hover a row to highlight it
    - Click a row to open the quest in the quest log
-------------------------------------------------------------------------------]]

local _, Addon = ...

local Colors = Addon.Colors
local Fonts = Addon.Fonts
local colorize = Addon.Colorize

local InfiniteResearch = Addon.InfiniteResearch

--------------------------------------------------------------------------------
-- Quest Icon Helpers
--------------------------------------------------------------------------------

-- Blue wrapper icons (repeatable)
local ICON_REPEATABLE_ACTIVE = "quest-wrapper-available"
local ICON_REPEATABLE_COMPLETE = "quest-wrapper-turnin"

-- Yellow quest icons (non-repeatable)
local ICON_NORMAL_ACTIVE = "SmallQuestBang"
local ICON_NORMAL_COMPLETE = "QuestTurnin"

---Return texture markup for the quest’s state.
---@param quest table
---@return string
function Addon.GetQuestIconMarkup(quest, isRepeatable)
	if not quest or not quest.questID then
		return ""
	end

	local texture
	if isRepeatable then
		texture = quest.isComplete and ICON_REPEATABLE_COMPLETE or ICON_REPEATABLE_ACTIVE
	else
		texture = quest.isComplete and ICON_NORMAL_COMPLETE or ICON_NORMAL_ACTIVE
	end

	return ("|A:%s:16:16|a"):format(texture)
end

--------------------------------------------------------------------------------
-- Section Helpers
--------------------------------------------------------------------------------

---Render a list of quests into the tooltip with a section heading.
---@param tooltip table
---@param heading string
---@param quests table[]
---@param isRepeatable boolean
local function RenderQuestGroup(tooltip, heading, quests, color, isRepeatable)
	if not quests or #quests == 0 then
		return
	end

	Addon.TooltipHelpers.AddSectionHeading(tooltip, heading, false, color)

	for _, quest in ipairs(quests) do
		local icon = Addon.GetQuestIconMarkup(quest, isRepeatable)

		-- Main quest row (icon + title)
		tooltip:SetFont(Fonts.Subsubheading)
		local line = tooltip:AddLine()
		tooltip:SetCell(line, 1, icon)
		tooltip:SetCell(line, 2, colorize(quest.title, color), nil, "LEFT", tooltip:GetColumnCount() - 1)
		tooltip:SetFont(Fonts.MainText)

		-- Hover/click handlers on the quest title cell (column 2)
		Addon.TooltipHelpers.AddHyperlinkTooltip(tooltip, line, 2, ("quest:%d"):format(quest.questID))

		tooltip:SetCellScript(line, 2, "OnMouseDown", function()
			if quest.questID then
				QuestMapFrame_OpenToQuestDetails(quest.questID)
			end
		end)

		-- Sub-rows for each objective
		if quest.objectives and #quest.objectives > 0 then
			for _, obj in ipairs(quest.objectives) do
				local check = obj.finished and "|A:UI-QuestTracker-Tracker-Check-Glow:14:14|a " or ""
				local text = obj.text or ""
				local objLine = tooltip:AddLine()
				-- indent objectives under the quest title
				tooltip:SetCell(objLine, 2, check .. text, nil, "LEFT", tooltip:GetColumnCount() - 1)
			end
		else
			local objLine = tooltip:AddLine()
			tooltip:SetCell(
				objLine,
				2,
				colorize("No objectives", Colors.Grey),
				nil,
				"LEFT",
				tooltip:GetColumnCount() - 1
			)
		end
		tooltip:AddSeparator(3, 0, 0, 0, 0)
	end
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
		local repeatable, nonRepeatable = InfiniteResearch:GetInfiniteResearchQuests()
		RenderQuestGroup(tooltip, "Repeatable Quests", repeatable, Colors.WowToken, true)
		RenderQuestGroup(tooltip, "Non-Repeatable Quests", nonRepeatable, Colors.Header, false)
	else
		local line = tooltip:AddLine()
		tooltip:SetCell(
			line,
			1,
			colorize("The current character is not a Legion Remix character", Colors.Grey),
			nil,
			"LEFT",
			tooltip:GetColumnCount()
		)
	end
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

Addon.ObjectivesView = ObjectivesView
