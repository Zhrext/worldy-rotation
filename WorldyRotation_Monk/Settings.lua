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
WR.GUISettings.APL.Monk = {
  Commons = {
    Enabled = {
      Trinkets = true,
      Potions = true,
    },
    DisplayStyle = {
      Potions = "Suggested",
      Covenant = "Suggested",
      Trinkets = "Suggested",
      Items = "Suggested"
    },
    -- {Display GCD as OffGCD, ForceReturn}
    GCDasOffGCD = {
      -- Abilities
      LegSweep = true,
      RingOfPeace = true,
      Paralysis = true,
    },
    -- {Display OffGCD as OffGCD, ForceReturn}
    OffGCDasOffGCD = {
      -- Racials
      Racials = true,
      -- Abilities
      Interrupts = true,
    }
  },
  Brewmaster = {
    -- DisplayStyle for Brewmaster-only stuff
    DisplayStyle = {
      CelestialBrew = "Suggested",
      DampenHarm = "Suggested",
      FortifyingBrew = "Suggested",
      Purify = "SuggestedRight"
    },
    -- {Display GCD as OffGCD, ForceReturn}
    GCDasOffGCD = {
      -- Abilities
      InvokeNiuzaoTheBlackOx = true,
      TouchOfDeath           = true,
    },
    -- {Display OffGCD as OffGCD, ForceReturn}
    OffGCDasOffGCD = {
      -- Racials
      -- Abilities
      BlackOxBrew            = true,
      PurifyingBrew          = true,
    }
  }
};
WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Monk = CreateChildPanel(ARPanel, "Monk")
local CP_Brewmaster = CreateChildPanel(CP_Monk, "Brewmaster")
-- Monk
CreateARPanelOptions(CP_Monk, "APL.Monk.Commons")

-- Brewmaster
CreateARPanelOptions(CP_Brewmaster, "APL.Monk.Brewmaster")
