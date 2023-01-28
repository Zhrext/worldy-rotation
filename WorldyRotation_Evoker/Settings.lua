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
WR.GUISettings.APL.Evoker = {
  Commons = {
  },
  Devastation = {
    HP = {
      ObsidianScales = 60,
    },
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Evoker = CreateChildPanel(ARPanel, "Evoker")
local CP_Devastation = CreateChildPanel(CP_Evoker, "Devastation")

-- Evoker
CreateARPanelOptions(CP_Evoker, "APL.Evoker.Commons")
CreateARPanelOptions(CP_Devastation, "APL.Evoker.Devastation")
