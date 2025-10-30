--[[-----------------------------------------------------------------------------
  GroupMonitor.lua
  Purpose:
    - Maintain a live database of current group members (1–40)
    - Provide a single public API: GroupMonitor:GetGroupData()
    - Stable schema with explicit fields for tooltip rendering
  Notes:
    - Distinct from ThreadsTracker (aura scanning + persistence)
    - This module focuses on group roster snapshots
-------------------------------------------------------------------------------]]
--

local _, Addon = ...
local ThreadsTracker = Addon.ThreadsTracker

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

---@class GroupMonitor
local GroupMonitor = {}
Addon.GroupMonitor = GroupMonitor

-- Internal database
GroupMonitor.db = {
	group = {}, -- unified list of members
}

local CONFIG = {
	SPELL_ID_LIMITS_UNBOUND = 1245947,
	THREADS_PER_RANK = 50000,
}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local ROLE_ICONS = {
	TANK = "|TInterface\\GroupFrame\\UI-Group-LeaderIcon:16:16:0:0:64:64:0:32:0:32|t",
	HEALER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t",
	DAMAGER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t",
}

---Return icon texture string for a role.
---@param role string
---@return string
function GroupMonitor:GetRoleIcon(role)
	return ROLE_ICONS[role] or ""
end

---Return icon texture ID for a spell.
---@param spellID number
---@return number
function GroupMonitor:GetSpellIcon(spellID)
	return (spellID and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)) or 134400
end

---Return class color string (hex) for a unit.
---@param unit string
---@return string
function GroupMonitor:GetClassColor(unit)
	local _, classFile = UnitClass(unit)
	local color = RAID_CLASS_COLORS[classFile] or NORMAL_FONT_COLOR
	return color.colorStr
end

--------------------------------------------------------------------------------
-- Member Builder
--------------------------------------------------------------------------------

---Build a member record for the given unit.
---@param unit string
---@return table member
local function BuildMember(unit)
	if not UnitExists(unit) then
		return {
			unit = unit,
			name = nil,
			realm = nil,
			class = nil,
			level = nil,
			role = nil,
			totalThreads = 0,
			limitsUnboundRank = 0,
		}
	end

	local total = ThreadsTracker:GetUnitTotal(unit) or 0
	local rank = math.floor(total / CONFIG.THREADS_PER_RANK)
	local name, realm = UnitName(unit)
	local _, classFile = UnitClass(unit)

	return {
		unit = unit,
		name = name,
		realm = realm or GetRealmName(),
		class = classFile,
		level = UnitLevel(unit) or "?",
		role = UnitGroupRolesAssigned(unit),
		totalThreads = total,
		limitsUnboundRank = rank,
	}
end

--------------------------------------------------------------------------------
-- Core Update
--------------------------------------------------------------------------------

---Update the internal group database.
function GroupMonitor:UpdateGroup()
	wipe(self.db.group)

	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			table.insert(self.db.group, BuildMember("raid" .. i))
		end
	elseif IsInGroup() then
		table.insert(self.db.group, BuildMember("player"))
		for i = 1, GetNumSubgroupMembers() do
			table.insert(self.db.group, BuildMember("party" .. i))
		end
	else
		table.insert(self.db.group, BuildMember("player"))
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---Return a fresh snapshot of the current group (1–40 members).
---@return table[] members
function GroupMonitor:GetGroupData()
	self:UpdateGroup()
	return self.db.group
end

--------------------------------------------------------------------------------
-- Event Hook: keep DB fresh
--------------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("UNIT_CONNECTION")
f:RegisterEvent("UNIT_LEVEL")
f:RegisterEvent("UNIT_NAME_UPDATE")

f:SetScript("OnEvent", function()
	GroupMonitor:UpdateGroup()
end)
