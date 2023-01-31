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
    Enabled = {
      OutOfCombatHealing = true,
      BlessingoftheBronze = true,
    },
    HP = {
      ObsidianScales = 60,
    },
  },
  Devastation = {
  },
  Preservation = {
    Healing = {
      HP = {
        DreamBreath = 75,
        Echo = 65,
        EmeraldBlossom = 85,
        LivingFlame = 90,
        Spiritbloom = 75,
        Rewind = 50,
        Reversion = 65,
        ReversionTank = 99,
        TemporalAnomaly = 90,
        TimeDilation = 60,
        VerdantEmbrace = 70,
      },
      AoEGroup = {
        DreamBreath = 2,
        EmeraldBlossom = 2,
        Spiritbloom = 2,
        TemporalAnomaly = 2,
        Rewind = 3,
      },
      AoERaid = {
        DreamBreath = 4,
        EmeraldBlossom = 4,
        Spiritbloom = 4,
        TemporalAnomaly = 4,
        Rewind = 5,
      },
    },
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Evoker = CreateChildPanel(ARPanel, "Evoker")
local CP_Devastation = CreateChildPanel(CP_Evoker, "Devastation")
local CP_Preservation = CreateChildPanel(CP_Evoker, "Preservation")
local CP_Preservation_Healing = CreateChildPanel(CP_Preservation, "Healing")

-- Evoker
CreateARPanelOptions(CP_Evoker, "APL.Evoker.Commons")
CreateARPanelOptions(CP_Devastation, "APL.Evoker.Devastation")
CreateARPanelOptions(CP_Preservation, "APL.Evoker.Preservation")

-- Preservation
CreateARPanelOptions(CP_Preservation_Healing, "APL.Evoker.Preservation.Healing")
