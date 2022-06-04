--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
  -- HeroLib
local HL = HeroLib
-- WorldyRotation
local WR = WorldyRotation
-- File Locals
local GUI = HL.GUI
local CreateChildPanel = GUI.CreateChildPanel
local CreatePanelOption = GUI.CreatePanelOption
local CreateARPanelOption = WR.GUI.CreateARPanelOption
local CreateARPanelOptions = WR.GUI.CreateARPanelOptions


--- ============================ CONTENT ============================
-- Default settings
WR.GUISettings.APL.Rogue = {
  Commons = {
    Enabled = {
      RangedMultiDoT = true, -- Suggest Multi-DoT at 10y Range
      UseTrinkets = true,
      ShowPooling = true,
      STMfDAsDPSCD = false, -- Single Target MfD as DPS CD
    },
    PoisonRefresh = 15,
    PoisonRefreshCombat = 3,
    UsePriorityRotation = "Never", -- Only for Assassination / Subtlety
  },
  Commons2 = {
    HP = {
      CrimsonVialHP = 20,
      FeintHP = 10,
    },
    Enabled = {
      StealthOOC = true,
    },
  },
  Outlaw = {
    Enabled = {
      UseDPSVanish = false, -- Use Vanish in the rotation for DPS
      DumpSpikes = false, -- don't dump bone spikes at end of boss, useful in M+
    },
    HP = {
      RolltheBonesLeechKeepHP = 60, -- % HP threshold to keep Grand Melee while solo.
      RolltheBonesLeechRerollHP = 40, -- % HP threshold to reroll for Grand Melee while solo.
    },
    -- Roll the Bones Logic, accepts "SimC", "1+ Buff" and every "RtBName".
    -- "SimC", "1+ Buff", "Broadside", "Buried Treasure", "Grand Melee", "Skull and Crossbones", "Ruthless Precision", "True Bearing"
    RolltheBonesLogic = "SimC",
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Rogue = CreateChildPanel(ARPanel, "Rogue")
local CP_Rogue2 = CreateChildPanel(ARPanel, "Rogue 2")
local CP_Outlaw = CreateChildPanel(ARPanel, "Outlaw")
-- Controls
-- Rogue
CreatePanelOption("Slider", CP_Rogue, "APL.Rogue.Commons.PoisonRefresh", {5, 55, 1}, "OOC Poison Refresh", "Set the timer for the Poison Refresh (OOC)")
CreatePanelOption("Slider", CP_Rogue, "APL.Rogue.Commons.PoisonRefreshCombat", {0, 55, 1}, "Combat Poison Refresh", "Set the timer for the Poison Refresh (In Combat)")
CreatePanelOption("Dropdown", CP_Rogue, "APL.Rogue.Commons.UsePriorityRotation", {"Never", "On Bosses", "Always", "Auto"}, "Use Priority Rotation", "Select when to show rotation for maximum priority damage (at the cost of overall AoE damage.)\nAuto will function as Never except on specific encounters where AoE is not recommended.")
CreateARPanelOptions(CP_Rogue, "APL.Rogue.Commons")
-- Rogue 2
CreateARPanelOptions(CP_Rogue2, "APL.Rogue.Commons2")
-- Outlaw
CreatePanelOption("Dropdown", CP_Outlaw, "APL.Rogue.Outlaw.RolltheBonesLogic", {"SimC", "1+ Buff", "Broadside", "Buried Treasure", "Grand Melee", "Skull and Crossbones", "Ruthless Precision", "True Bearing"}, "Roll the Bones Logic", "Define the Roll the Bones logic to follow.\n(SimC highly recommended!)")
CreateARPanelOptions(CP_Outlaw, "APL.Rogue.Outlaw")
