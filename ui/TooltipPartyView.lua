--[[-----------------------------------------------------------------------------
  TooltipPartyView.lua
  Purpose:
    - Provide tooltip content for the current group using GroupMonitor data
    - Columns: Role | Level | Name | Realm | Threads | Limits
    - Click headers to sort by that column (toggle ascending/descending)
    - Hover a row to highlight it
    - Left-click a row to whisper that player
    - Right-click a row to open the standard player context menu
    - Section header shows role counts (tank/healer/dps)
-------------------------------------------------------------------------------]]--

local _, Addon = ...

local Fonts         = Addon.Fonts
local Colors        = Addon.Colors
local colorize      = Addon.Colorize

local GroupMonitor  = Addon.GroupMonitor

--------------------------------------------------------------------------------
-- Sort State
--------------------------------------------------------------------------------

local sortKey   = "totalThreads"
local ascending = false

local SORT_FUNCS = {
    role          = function(a,b) return (a.role or "") < (b.role or "") end,
    level         = function(a,b) return (a.level or 0) < (b.level or 0) end,
    name          = function(a,b) return (a.name or "") < (b.name or "") end,
    realm         = function(a,b) return (a.realm or "") < (b.realm or "") end,
    totalThreads  = function(a,b) return (a.totalThreads or 0) < (b.totalThreads or 0) end,
    limitsUnbound = function(a,b) return (a.limitsUnboundRank or 0) < (b.limitsUnboundRank or 0) end,
}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function CountRoles()
    local counts = { TANK = 0, HEALER = 0, DAMAGER = 0 }
    for _, m in ipairs(GroupMonitor:GetGroupData()) do
        if m.role and counts[m.role] ~= nil then
            counts[m.role] = counts[m.role] + 1
        end
    end
    return counts
end

local function BuildRoleSummary(counts)
    return string.format(
        "|cffaaaaaa%s %d  %s %d  %s %d|r",
        INLINE_TANK_ICON, counts.TANK,
        INLINE_HEALER_ICON, counts.HEALER,
        INLINE_DAMAGER_ICON, counts.DAMAGER
    )
end

local function AddPartyViewHeading(tooltip)
    tooltip:SetFont(Fonts.Heading)
    local line = tooltip:AddLine()

    local counts = CountRoles()
    local summary = BuildRoleSummary(counts)

    tooltip:SetCell(line, 1, colorize("Group Info", Colors.Header), Fonts.Heading, "LEFT", tooltip:GetColumnCount()-2)
    tooltip:SetCell(line, tooltip:GetColumnCount()-1, summary, Fonts.MainText, "RIGHT", 2)

    tooltip:AddSeparator()
    tooltip:AddSeparator(3, 0, 0, 0, 0)
    tooltip:SetFont(Fonts.MainText)
end

local function ColorizeClassText(text, classFile)
    local color = RAID_CLASS_COLORS[classFile] or NORMAL_FONT_COLOR
    return string.format("|c%s%s|r", color.colorStr, text or "?")
end

local function FormatThreads(total)
    return colorize(Addon.FormatWithCommasToThousands(total or 0), Colors.WowToken)
end

local function FormatLimitsUnbound(rank)
    local icon = ("|T%d:0|t"):format(GroupMonitor:GetSpellIcon(GroupMonitor.SPELL_ID_LIMITS_UNBOUND))
    return colorize(tostring(rank or 0), Colors.Artifact) .. " " .. icon
end

local function RequestSort(tooltip, key)
    if sortKey == key then
        ascending = not ascending
    else
        sortKey   = key
        ascending = true
    end
    Addon.UI.TooltipProvider:PopulateTooltip(tooltip)
    tooltip:Show()
end

--------------------------------------------------------------------------------
-- Sortable Header
--------------------------------------------------------------------------------

local function AddSortableHeader(tooltip)
    local line = tooltip:AddHeader()

    local headers = {
        { key = "role",          label = "Role"    },
        { key = "level",         label = "Lvl"     },
        { key = "name",          label = "Name"    },
        { key = "realm",         label = "Realm"   },
        { key = "totalThreads",  label = "Threads" },
        { key = "limitsUnbound", label = "Limits"  },
    }

    for col, h in ipairs(headers) do
        tooltip:SetCell(line, col, h.label, Fonts.MainText, "CENTER")
        tooltip:SetCellScript(line, col, "OnMouseDown", function()
            RequestSort(tooltip, h.key)
        end)
    end
end

--------------------------------------------------------------------------------
-- Party Rows
--------------------------------------------------------------------------------

local function AddPartyRows(tooltip)
    tooltip:SetColumnLayout(6, "LEFT", "CENTER", "LEFT", "LEFT", "RIGHT", "RIGHT")
    AddSortableHeader(tooltip)

    local data = GroupMonitor:GetGroupData()

    table.sort(data, function(a,b)
        local cmp = SORT_FUNCS[sortKey]
        if not cmp then return false end
        if ascending then
            return cmp(a,b)
        else
            return cmp(b,a)
        end
    end)

    for _, m in ipairs(data) do
        local line = tooltip:AddLine()
        tooltip:SetCell(line, 1, GroupMonitor:GetRoleIcon(m.role))
        tooltip:SetCell(line, 2, tostring(m.level or "?"))
        tooltip:SetCell(line, 3, ColorizeClassText(m.name, m.class))
        tooltip:SetCell(line, 4, ColorizeClassText(m.realm, m.class))
        tooltip:SetCell(line, 5, FormatThreads(m.totalThreads))
        tooltip:SetCell(line, 6, FormatLimitsUnbound(m.limitsUnboundRank))

        tooltip:SetLineScript(line, "OnEnter", function()
            tooltip:SetLineColor(line, 0.2, 0.4, 0.8, 0.3)
        end)
        tooltip:SetLineScript(line, "OnLeave", function()
            tooltip:SetLineColor(line, 0, 0, 0, 0)
        end)
        tooltip:SetLineScript(line, "OnMouseDown", function(_, button)
            if not m.name or m.name == "" then return end
            local target = m.name
            if m.realm and m.realm ~= GetRealmName() then
                target = target .. "-" .. m.realm
            end

            if button == "LeftButton" then
                ChatFrame_OpenChat("/w " .. target .. " ")
            elseif button == "RightButton" then
                FriendsDropDown.name        = target
                FriendsDropDown.id          = 0
                FriendsDropDown.unit        = nil
                FriendsDropDown.initialize  = nil
                FriendsDropDown.displayMode = "MENU"
                ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor", 0, 0)
            end
        end)
    end
end

--------------------------------------------------------------------------------
-- PartyView
--------------------------------------------------------------------------------

---@class PartyView
local PartyView = {}

---Populate the party/group tooltip.
---@param tooltip table
function PartyView:Populate(tooltip)
    tooltip:EnableMouse(true)
    tooltip:SetColumnLayout(6, "LEFT", "CENTER", "LEFT", "LEFT", "RIGHT", "RIGHT")

    if Addon.IsInLegionTimerunnerMode() then
        AddPartyViewHeading(tooltip)
        AddPartyRows(tooltip)
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

Addon.PartyView = PartyView
