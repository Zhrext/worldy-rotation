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
    Enabled = {
      HandleExplosives = true,
      UseSteelTrap = true,
      Potions = true,
      Trinkets = true,
    },
    DisplayStyle = {
      Covenant = "Suggested",
      Potions = "Suggested",
      Trinkets = "Suggested",
      Items = "Suggested",
    },
    GCDasOffGCD = {
      AMurderofCrows = false,
      Racials = false,
    },
    OffGCDasOffGCD = {
      Racials = true,
    }
  },
  Commons2 = {
    SummonPetSlot = 1,
    ExhilarationHP = 20,
    MendPetHighHP = 40,
    MendPetLowHP = 80,
    GCDasOffGCD = {
      Exhilaration = true,
      Flare = false,
      RevivePet = false,
      MendPet = false,
      SummonPet = false,
      FreezingTrap = false,
      TarTrap = false,
    },
    OffGCDasOffGCD = {
      CounterShot = true,
    }
  },
  BeastMastery = {
    GCDasOffGCD = {
      BestialWrath = false,
      Bloodshed = false,
      Stampede = false,
      WailingArrow = false,
    },
    OffGCDasOffGCD = {
      AspectOfTheWild = true,
    }
  },
  Marksmanship = {
    HideAimedWhileMoving = false,
    UseVolley = true,
    GCDasOffGCD = {
      DoubleTap = false,
      Volley = false,
      WailingArrow = false,
    },
    OffGCDasOffGCD = {
      Trueshot = true,
    }
  },
  Survival = {
    AspectOfTheEagle = true,
    -- {Display GCD as OffGCD, ForceReturn}
    GCDasOffGCD = {
      -- Abilities
      Butchery = false,
      CoordinatedAssault = true,
      Harpoon = true,
    },
    -- {Display OffGCD as OffGCD, ForceReturn}
    OffGCDasOffGCD = {
      -- Abilities
      AspectOfTheEagle = true,
      Muzzle = true,
      -- Items
      -- Racials
    }
  }
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Hunter = CreateChildPanel(ARPanel, "Hunter")
local CP_Hunter2 = CreateChildPanel(ARPanel, "Hunter 2")
local CP_BeastMastery = CreateChildPanel(ARPanel, "BeastMastery")
local CP_Marksmanship = CreateChildPanel(ARPanel, "Marksmanship")
local CP_Survival = CreateChildPanel(ARPanel, "Survival")

-- Hunter
CreateARPanelOptions(CP_Hunter, "APL.Hunter.Commons")

-- Hunter 2
CreatePanelOption("Slider", CP_Hunter2, "APL.Hunter.Commons2.ExhilarationHP", {0, 100, 1}, "Exhilaration HP", "Set the Exhilaration HP tWReshold. Set to 0 to disable.")
CreatePanelOption("Slider", CP_Hunter2, "APL.Hunter.Commons2.MendPetHighHP", {0, 100, 1}, "Mend Pet High HP", "Set the Mend Pet HP High Priority (ASAP) tWReshold. Set to 0 to disable.")
CreatePanelOption("Slider", CP_Hunter2, "APL.Hunter.Commons2.MendPetLowHP", {0, 100, 1}, "Mend Pet Low HP", "Set the Mend Pet HP Low Priority (Pooling) tWReshold. Set to 0 to disable.")
CreatePanelOption("Slider", CP_Hunter2, "APL.Hunter.Commons2.SummonPetSlot", {1, 5, 1}, "Summon Pet Slot", "Which pet stable slot to suggest when summoning a pet.")
CreateARPanelOptions(CP_Hunter2, "APL.Hunter.Commons2")

-- Beast Mastery
CreateARPanelOptions(CP_BeastMastery, "APL.Hunter.BeastMastery")

-- Marksmanship
CreatePanelOption("CheckButton", CP_Marksmanship, "APL.Hunter.Marksmanship.HideAimedWhileMoving", "Hide Moving Aimed Shot", "Enable this option to hide Aimed Shot while your character is moving.")
CreatePanelOption("CheckButton", CP_Marksmanship, "APL.Hunter.Marksmanship.UseVolley", "Use Volley when Mouseover", "Enable this option to use volley when target is equal to mouseover.")
CreateARPanelOptions(CP_Marksmanship, "APL.Hunter.Marksmanship")

-- Survival
CreatePanelOption("CheckButton", CP_Survival, "APL.Hunter.Survival.AspectoftheEagle", "Show Aspect of the Eagle", "Show Aspect of the Eagle when out of Melee Range.")
CreateARPanelOptions(CP_Survival, "APL.Hunter.Survival")