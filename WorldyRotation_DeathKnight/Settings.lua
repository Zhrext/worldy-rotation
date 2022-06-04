--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- WorldyRotation
local WR = WorldyRotation
-- HeroLib
local HL = HeroLib
--File Locals
local GUI = HL.GUI
local CreateChildPanel = GUI.CreateChildPanel
local CreatePanelOption = GUI.CreatePanelOption
local CreateARPanelOption = WR.GUI.CreateARPanelOption
local CreateARPanelOptions = WR.GUI.CreateARPanelOptions

--- ============================ CONTENT ============================
-- All settings here should be moved into the GUI someday.
WR.GUISettings.APL.DeathKnight = {
  Commons = {
    Enabled = {
      Potions = true,
      Trinkets = true,
    },
    HP = {
      UseDeathStrikeHP = 60, -- % HP threshold to try to heal with Death Strike
      UseDarkSuccorHP = 80, -- % HP threshold to use Dark Succor's free Death Strike
    },
  },
  Blood = {
    Enabled = {
      PoolDuringBlooddrinker = false,
    },
    HP = {
      RuneTapThreshold = 40,
      IceboundFortitudeThreshold = 50,
      VampiricBloodThreshold = 65,
    },
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)
-- Panels
local ARPanel = WR.GUI.Panel
local CP_Deathknight = CreateChildPanel(ARPanel, "DeathKnight")
local CP_Blood = CreateChildPanel(CP_Deathknight, "Blood")

--DeathKnight Panels
CreateARPanelOptions(CP_Deathknight, "APL.DeathKnight.Commons")

--Blood Panels
CreateARPanelOptions(CP_Blood, "APL.DeathKnight.Blood")
