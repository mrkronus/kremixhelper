--[[============================================================================
  ArtifactPowers.lua
  Purpose:
    - Defines the full list of artifact-like powers available via jewelry in Legion Remix
  Notes:
    - Each entry includes the power name and the slots/items it can appear on
    - Flat lists (allow, disallow, required) are provided for quick scanning
    - This static list can later be extended with SavedVariables or a config UI
============================================================================]]--

local _, Addon = ...



--------------------------------------------------------------------------------
-- Artifact Powers
--------------------------------------------------------------------------------

---@class ArtifactPowers
Addon.ArtifactPowers = {
    ---------------------------------------------------------------------------
    -- Master List (grouped by slot for clarity)
    ---------------------------------------------------------------------------
    masterList = {
        necks = {
            { id = 1258587, name = "Brewing Storm" },
            { id = 1234683, name = "Highmountain Fortitude" },
            { id = 1251666, name = "Light's Vengeance" },
            { id = 1235159, name = "Souls of the Caw" },
            { id = 1241854, name = "Storm Surger" },
            { id = 1232262, name = "Temporal Retaliation" },
            { id = 1242992, name = "Touch of Malice" },
            { id = 1234774, name = "Volatile Magics" },
        },
        rings = {
            { id = 1232720, name = "Arcane Aegis" },
            { id = 1242202, name = "Arcane Ward" },
            { id = 1258587, name = "Brewing Storm" },
            { id = 1234683, name = "Highmountain Fortitude" },
            { id = 1242022, name = "I Am My Scars!" },
            { id = 1232262, name = "Temporal Retaliation" },
            { id = 1233595, name = "Terror From Below" },
            { id = 1234774, name = "Volatile Magics" },
        },
        trinkets = {
            { id = 1232720, name = "Arcane Aegis" },
            { id = 1242202, name = "Arcane Ward" },
            { id = 1242022, name = "I Am My Scars!" },
            { id = 1251666, name = "Light's Vengeance" },
            { id = 1235159, name = "Souls of the Caw" },
            { id = 1241854, name = "Storm Surger" },
            { id = 1233595, name = "Terror From Below" },
            { id = 1242992, name = "Touch of Malice" },
        },
    },

    ---------------------------------------------------------------------------
    -- Flat Lists (for quick scanning)
    ---------------------------------------------------------------------------
    allow = {
        { id = 1258587, name = "Brewing Storm" },
        { id = 1234683, name = "Highmountain Fortitude" },
        { id = 1251666, name = "Light's Vengeance" },
        { id = 1235159, name = "Souls of the Caw" },
        { id = 1241854, name = "Storm Surger" },
        { id = 1232262, name = "Temporal Retaliation" },
        { id = 1242992, name = "Touch of Malice" },
        { id = 1234774, name = "Volatile Magics" },
        { id = 1242202, name = "Arcane Ward" },
        { id = 1242022, name = "I Am My Scars!" },
        { id = 1233595, name = "Terror From Below" },
    },

    disallow = {
        { id = 1232720, name = "Arcane Aegis" },
    },

    required = {
        { id = 1242992, name = "Touch of Malice" },
        { id = 1233595, name = "Terror From Below" },
        { id = 1234774, name = "Volatile Magics" },
    },
}
