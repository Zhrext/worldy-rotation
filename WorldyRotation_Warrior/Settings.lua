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
WR.GUISettings.APL.Warrior = {
  Commons = {
    Enabled = {
      Charge = false,
    },
    HP = {
      VictoryRush = 80,
      RallyingCry = 40,
    },
  },
  Arms = {
  },
  Fury = {
  },
  Protection = {
    Enabled = {
      Intervene = false,
    },
    HP = {
      ShieldWall = 35,
      LastStand = 40,
    },
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)
local ARPanel = WR.GUI.Panel
local CP_Warrior = CreateChildPanel(ARPanel, "Warrior")
local CP_Arms = CreateChildPanel(CP_Warrior, "Arms")
local CP_Fury = CreateChildPanel(CP_Warrior, "Fury")
local CP_Protection = CreateChildPanel(CP_Warrior, "Protection")

CreateARPanelOptions(CP_Warrior, "APL.Warrior.Commons")

-- Arms Settings
CreateARPanelOptions(CP_Arms, "APL.Warrior.Arms")

-- Fury Settings
CreateARPanelOptions(CP_Fury, "APL.Warrior.Fury")

-- Protection Settings
CreateARPanelOptions(CP_Protection, "APL.Warrior.Protection")
