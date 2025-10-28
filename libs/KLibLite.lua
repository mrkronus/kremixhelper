--[[-------------------------------------------------------------------------
    Addon Initialization
---------------------------------------------------------------------------]]

local addonName, Addon = ...


--[[-------------------------------------------------------------------------
    Color Definitions
    https://warcraft.wiki.gg/wiki/Color_codes
---------------------------------------------------------------------------]]

Addon.Colors = {
    -- UI Segments
    Header       = "FFFFD700",
    SubHeader    = "FFFFFF00",
    Footer       = "FFF5F5F5",
    FooterDark   = "FFA9A9A9",

    -- Status Indicators
    Acquired     = "FF00FF00",
    Incomplete   = "FFA9A9A9",

    -- Factions
    Alliance     = "FF4A54E8",
    Horde        = "FFE50D12",

    -- Expansions
    CLASSIC      = "FFE6CC80",
    TBC          = "FF1EFF00",
    WOTLK        = "FF66ccff",
    CATA         = "FFff3300",
    MOP          = "FF00FF96",
    WOD          = "FFff8C1A",
    LEGION       = "FFA335EE",
    BFA          = "FFFF7D0A",
    SHADOWLANDS  = "FFE6CC80",
    DRAGONFLIGHT = "FF33937F",

    -- General Use
    Yellow       = "FFFFFF00",
    White        = "FFFFFFFF",
    Grey         = "FFA9A9A9",
    Red          = "FFFF0000",
    Green        = "FF00FF00",

    -- Item Quality
    Common       = "FFFFFFFF",
    Uncommon     = "FF1EFF00",
    Rare         = "FF0070DD",
    Epic         = "FFA335EE",
    Legendary    = "FFFF8000",
    Artifact     = "FFE6CC80",
    WowToken     = "FF00CCFF",

    -- Class Colors
    DEATHKNIGHT  = "FFC41F3B",
    DEMONHUNTER  = "FFA330C9",
    DRUID        = "FFFF7D0A",
    EVOKER       = "FF33937F",
    HUNTER       = "FFABD473",
    MAGE         = "FF69CCF0",
    MONK         = "FF00FF96",
    PALADIN      = "FFF58CBA",
    PRIEST       = "FFFFFFFF",
    ROGUE        = "FFFFF569",
    SHAMAN       = "FF0070DE",
    WARLOCK      = "FF9482C9",
    WARRIOR      = "FFC79C6E",

    -- Custom Tags
    Beledar      = "FFA060FF",
    LegionFelGreenGlow      = "FF00FF00",
    LegionCorruptedFelGreen = "FF32CD32",
    LegionVoidPurple        = "FF6A0DAD",
    LegionShadowViolet      = "FF8A2BE2",
    LegionFelfireOrange     = "FFFF4500",
    LegionAshenGray         = "FF2F4F4F",
    LegionBlackenedIron     = "FF1C1C1C",
    LegionSicklyYellowGreen = "FFADFF2F",
}


--[[-------------------------------------------------------------------------
    Role, Spec, and Class Mappings
    Sources: wowpedia.fandom.com/wiki/Specialization, warcraft.wiki.gg
---------------------------------------------------------------------------]]

Addon.RoleIcons = {
    ["TANK"]     = '\124A:groupfinder-icon-role-large-tank:20:20\124a',
    ["HEALER"]   = '\124A:groupfinder-icon-role-large-heal:20:20\124a',
    ["DAMAGER"]  = '\124A:groupfinder-icon-role-large-dps:20:20\124a',
    ["NONE"]     = ""
}

Addon.Specializations =
{
    -- Mage
    [62] = "Arcane",
    [63] = "Fire",
    [64] = "Frost",

    -- Paladin
    [65] = "Holy",
    [66] = "Protection",
    [70] = "Retribution",

    -- Warrior
    [71] = "Arms",
    [72] = "Fury",
    [73] = "Protection",

    -- Druid
    [102] = "Balance",
    [103] = "Feral",
    [104] = "Guardian",
    [105] = "Restoration",

    -- Death Knight
    [250] = "Blood",
    [251] = "Frost",
    [252] = "Unholy",

    -- Hunter
    [253] = "Beast Mastery",
    [254] = "Marksmanship",
    [255] = "Survival",

    -- Priest
    [256] = "Discipline",
    [257] = "Holy",
    [258] = "Shadow",

    -- Rogue
    [259] = "Assassination",
    [260] = "Outlaw",
    [261] = "Subtlety",

    -- Shaman
    [262] = "Elemental",
    [263] = "Enhancement",
    [264] = "Restoration",

    -- Warlock
    [265] = "Affliction",
    [266] = "Demonology",
    [267] = "Destruction",

    -- Monk
    [268] = "Brewmaster",
    [269] = "Windwalker",
    [270] = "Mistweaver",

    -- Demon Hunter
    [577] = "Havoc",
    [581] = "Vengeance",

    -- Evoker
    [1467] = "Devastation",
    [1468] = "Preservation",
    [1473] = "Augmentation"
}

Addon.SpecializationToRoleText = {
--[[ 
    Source: https://wowpedia.fandom.com/wiki/Specialization
]]--

    -- Mage
    [62] = "DAMAGER", -- Arcane
    [63] = "DAMAGER", -- Fire
    [64] = "DAMAGER", -- Frost

    -- Paladin
    [65] = "HEALER", -- Holy
    [66] = "TANK", -- Protection
    [70] = "DAMAGER", -- Retribution

    -- Warrior
    [71] = "DAMAGER", -- Arms
    [72] = "DAMAGER", -- Fury
    [73] = "TANK", -- Protection

    -- Hunter
    [253] = "DAMAGER", -- Beast Mastery
    [254] = "DAMAGER", -- Marksmanship
    [255] = "DAMAGER", -- Survival

    -- Priest
    [256] = "HEALER", -- Discipline
    [257] = "HEALER", -- Holy
    [258] = "DAMAGER", -- Shadow

    -- Rogue
    [259] = "DAMAGER", -- Assassination
    [260] = "DAMAGER", -- Outlaw
    [261] = "DAMAGER", -- Subtlety

    -- Shaman
    [262] = "DAMAGER", -- Elemental
    [263] = "DAMAGER", -- Enhancement
    [264] = "HEALER", -- Restoration

    -- Warlock
    [265] = "DAMAGER", -- Affliction
    [266] = "DAMAGER", -- Demonology
    [267] = "DAMAGER", -- Destruction

    -- Monk
    [268] = "TANK", -- Brewmaster
    [269] = "DAMAGER", -- Windwalker
    [270] = "HEALER", -- Mistweaver

    -- Druid
    [102] = "DAMAGER", -- Balance
    [103] = "DAMAGER", -- Feral
    [104] = "TANK", -- Guardian
    [105] = "HEALER", -- Restoration

    -- Death Knight
    [250] = "TANK", -- Blood
    [251] = "DAMAGER", -- Frost
    [252] = "DAMAGER", -- Unholy

    -- Demon Hunter
    [577] = "DAMAGER", -- Havoc
    [581] = "TANK", -- Vengeance

    -- Evoker
    [1467] = "DAMAGER", -- Devastation
    [1468] = "HEALER", -- Preservation
    [1473] = "DAMAGER", -- Augmentation
}


--[[-------------------------------------------------------------------------
    Text & Texture Icons
---------------------------------------------------------------------------]]

Addon.TextIcons = {
    RedX         = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t",
    GreenCheck   = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t",
    YellowCheck  = "|TInterface\\Icons\\Achievement_General:0|t",
    OrangeStar   = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    Mythic       = "|TInterface\\RaidFrame\\Raid-Icon-RaidLeader:0|t",
    Heroic       = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    Normal       = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    Unknown      = "|TInterface\\Icons\\INV_Misc_QuestionMark:0|t",
    QuestExclamation = '\124A:QuestNormal:20:20\124a',
    QuestQuestion     = '\124A:QuestTurnin:20:20\124a',
    RoleIconPending   = '\124A:ui-lfg-roleicon-pending:20:20\124a',
}

Addon.RaidIcons = {
    Star     = "\124A:GM-raidMarker8:20:20\124a",
    Circle   = "\124A:GM-raidMarker7:20:20\124a",
    Diamond  = "\124A:GM-raidMarker6:20:20\124a",
    Triangle = "\124A:GM-raidMarker5:20:20\124a",
    Moon     = "\124A:GM-raidMarker4:20:20\124a",
    Square   = "\124A:GM-raidMarker3:20:20\124a",
    Cross    = "\124A:GM-raidMarker2:20:20\124a",
    Skull    = "\124A:GM-raidMarker1:20:20\124a",
}


--[[-------------------------------------------------------------------------
    Class & Faction Utilities
---------------------------------------------------------------------------]]

function getClassIcon(class)
    return ("\124TInterface/Icons/classicon_%s:20\124t"):format(strlower(class))
end

Addon.FactionIcons = {
    ["Alliance"] = "\124A:poi-alliance:18:18\124a",
    ["Horde"]    = "\124A:poi-horde:18:18\124a"
}

Addon.FactionIconsBig = {
    ["Alliance"] = "\124A:poi-alliance:20:20\124a",
    ["Horde"]    = "\124A:poi-horde:20:20\124a"
}

Addon.FactionColors = {
    ["Alliance"] = Addon.Colors.Alliance,
    ["Horde"]    = Addon.Colors.Horde
}


--[[-------------------------------------------------------------------------
    Fonts
---------------------------------------------------------------------------]]

Addon.Fonts = {
    MainHeader = CreateFont("KLib_MainHeaderFont"),
    FooterText = CreateFont("KLib_FooterTextFont"),
    Heading    = CreateFont("KLib_HeadingFont"),
    Subheading = CreateFont("KLib_SubheadingFont"),
    MainText   = CreateFont("KLib_MainTextFont")
}

Addon.Fonts.MainHeader:SetFont("Fonts\\FRIZQT__.TTF", 22, "")
Addon.Fonts.FooterText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
Addon.Fonts.Heading:SetFont("Fonts\\FRIZQT__.TTF", 18, "")
Addon.Fonts.Subheading:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
Addon.Fonts.MainText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")


--[[-------------------------------------------------------------------------
    Utilities
---------------------------------------------------------------------------]]

---@param text string
---@param color string
---@return string
function Addon.Colorize(text, color)
    if type(text) ~= "string" then return "" end
    if type(color) ~= "string" then return text end
    return string.format("|c%s%s|r", color:upper(), text)
end

---Wrap text in WoW color codes using RGB values or a RAID_CLASS_COLORS table.
---@param text string
---@param r number|table Either red (0–1) or a table with .r/.g/.b
---@param g number? Green (0–1) if r is a number
---@param b number? Blue (0–1) if r is a number
---@return string
---@diagnostic disable-next-line: lowercase-global
function Addon.ColorizeRGB(text, r, g, b)
    local red, green, blue

    if type(r) == "table" then
        -- Assume it's a RAID_CLASS_COLORS entry
        red, green, blue = r.r, r.g, r.b
    else
        red, green, blue = r, g, b
    end

    if not (red and green and blue) then
        return text -- fallback: no color
    end

    return ("|cff%02x%02x%02x%s|r"):format(red * 255, green * 255, blue * 255, text)
end

---@param class string
---@return string
function Addon.ClassToColor(class)
    return Addon.Colors[class] or Addon.Colors.Grey
end

---@param i number
function Addon.CommaFormatInt(i)
    return tostring(i):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end


--[[-------------------------------------------------------------------------
    KDebug Integration
---------------------------------------------------------------------------]]

local KDebug = _G.KDebug
if KDebug then
    Addon.kprint = KDebug.kprint
    Addon.HasKDebug = true
else
    Addon.kprint = function(...) end
    Addon.HasKDebug = false
end