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
WR.GUISettings.APL.Mage = {
  Commons = {
    Enabled = {
      ArcaneIntellect = true,
      MovingRotation = true,
      StayDistance = true,
    },
    HP = {
      IceBlock = 20,
    },
  },
  Frost = {
    HP = {
      IceBarrier = 60,
    },
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Mage = CreateChildPanel(ARPanel, "Mage")
local CP_Frost = CreateChildPanel(CP_Mage, "Frost")

-- Controls
-- Mage
CreateARPanelOptions(CP_Mage, "APL.Mage.Commons")

-- Frost
CreateARPanelOptions(CP_Frost, "APL.Mage.Frost")
