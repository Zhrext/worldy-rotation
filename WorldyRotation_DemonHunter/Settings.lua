--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
local addonName, addonTable = ...
-- WorldyRotation
local WR = WorldyRotation

local HL = HeroLib
-- File Locals
local GUI = HL.GUI
local CreateChildPanel = GUI.CreateChildPanel
local CreatePanelOption = GUI.CreatePanelOption
local CreateARPanelOption = WR.GUI.CreateARPanelOption
local CreateARPanelOptions = WR.GUI.CreateARPanelOptions

--- ============================ CONTENT ============================
-- All settings here should be moved into the GUI someday.
WR.GUISettings.APL.DemonHunter = {
  Commons = {
  },
  Havoc = {
    Enabled = {
      FelRush = false,
      VengefulRetreat = false,
    },
    HP = {
      Blur = 65,
    },
  },
  Vengeance = {
    Enabled = {
      InfernalStrike = true,
      ConserveInfernalStrike = true,
      FieryBrandOffensively = false,
      MetaOffensively = false,
    },
    HP = {
      Metamorphosis = 50,
      FieryBrand = 40,
      DemonSpikes = 65,
      FelDev = 30,
    },
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)
local ARPanel = WR.GUI.Panel
local CP_DemonHunter = CreateChildPanel(ARPanel, "DemonHunter")
local CP_Havoc = CreateChildPanel(CP_DemonHunter, "Havoc")
local CP_Vengeance = CreateChildPanel(CP_DemonHunter, "Vengeance")

-- Commons
CreateARPanelOptions(CP_DemonHunter, "APL.DemonHunter.Commons")

-- Vengeance
CreateARPanelOptions(CP_Vengeance, "APL.DemonHunter.Vengeance")

-- Havoc
CreateARPanelOptions(CP_Havoc, "APL.DemonHunter.Havoc")