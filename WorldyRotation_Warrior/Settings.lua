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
      Potions = true,
      Trinkets = true,
    },
    HP = {
      VictoryRushHP = 80,
      Healthstone = 40,
      PhialOfSerenity = 40,
    },
  },
  Arms = {
  },
  Fury = {
    Enabled = {
      HideCastQueue = false,
    },
  },
  Protection = {
    Enabled = {
      DisableHeroicCharge = false,
      DisableIntervene = false,
    },
    RageCapValue = 80,
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
CreatePanelOption("Slider", CP_Protection, "APL.Warrior.Protection.RageCapValue", {30, 100, 5}, "Rage Cap Value", "Set the highest amount of Rage we should allow to pool before dumping Rage with Ignore Pain. Setting this value to 30 will allow you to over-cap Rage.")
