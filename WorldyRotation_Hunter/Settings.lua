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
WR.GUISettings.APL.Hunter = {
  Commons = {
    SummonPetSlot = 1,
    Enabled = {
      SteelTrap = true,
      RevivePet = true,
      MendPet = true,
      SummonPet = true,
    },
    HP = {
      Exhilaration = 20,
      MendPetHigh = 40,
      MendPetLow = 80,
    },
  },
  BeastMastery = {
  },
  Marksmanship = {
    Enabled = {
      Volley = true,
    }
  },
  Survival = {
    Enabled = {
      AspectOfTheEagle = true,
    }
  }
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Hunter = CreateChildPanel(ARPanel, "Hunter")
local CP_BeastMastery = CreateChildPanel(ARPanel, "BeastMastery")
local CP_Marksmanship = CreateChildPanel(ARPanel, "Marksmanship")
local CP_Survival = CreateChildPanel(ARPanel, "Survival")

-- Hunter
CreatePanelOption("Slider", CP_Hunter, "APL.Hunter.Commons.SummonPetSlot", {1, 5, 1}, "Summon Pet Slot", "Which pet stable slot to suggest when summoning a pet.")
CreateARPanelOptions(CP_Hunter, "APL.Hunter.Commons")

-- Beast Mastery
CreateARPanelOptions(CP_BeastMastery, "APL.Hunter.BeastMastery")

-- Marksmanship
CreateARPanelOptions(CP_Marksmanship, "APL.Hunter.Marksmanship")

-- Survival
CreateARPanelOptions(CP_Survival, "APL.Hunter.Survival")