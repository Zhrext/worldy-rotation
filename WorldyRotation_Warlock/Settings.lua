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
WR.GUISettings.APL.Warlock = {
  Commons = {
    Enabled = {
      SummonPet = true,
    },
  },
  Affliction = {
  },
  Demonology = {
    HP = {
      UnendingResolve = 20,
    },
  },
  Destruction = {
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Warlock = CreateChildPanel(ARPanel, "Warlock")
local CP_Affliction = CreateChildPanel(CP_Warlock, "Affliction")
local CP_Demonology = CreateChildPanel(CP_Warlock, "Demonology")
local CP_Destruction = CreateChildPanel(CP_Warlock, "Destruction")

-- Warlock
CreateARPanelOptions(CP_Warlock, "APL.Warlock.Commons")

-- Affliction
CreateARPanelOptions(CP_Affliction, "APL.Warlock.Affliction")

-- Demonology
CreateARPanelOptions(CP_Demonology, "APL.Warlock.Demonology")

-- Destruction
CreateARPanelOptions(CP_Destruction, "APL.Warlock.Destruction")
