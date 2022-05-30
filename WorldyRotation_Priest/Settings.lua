--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- WorldyRotation
local WR = WorldyRotation
-- HeroLib
local HL = HeroLib
-- File Locals
local GUI = HL.GUI
local CreateChildPanel = GUI.CreateChildPanel
local CreatePanelOption = GUI.CreatePanelOption
local CreateARPanelOption = WR.GUI.CreateARPanelOption
local CreateARPanelOptions = WR.GUI.CreateARPanelOptions

--- ============================ CONTENT ============================
-- All settings here should be moved into the GUI someday.
WR.GUISettings.APL.Priest = {
  Commons = {
    Enabled = {
      Potions = true,
      Racials = true,
      Trinkets = true,
    },
  },
  Discipline = {
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Priest = CreateChildPanel(ARPanel, "Priest")
local CP_Discipline = CreateChildPanel(CP_Priest, "Discipline")

CreateARPanelOptions(CP_Priest, "APL.Priest.Commons")

--Discipline
CreateARPanelOptions(CP_Discipline, "APL.Priest.Discipline")
