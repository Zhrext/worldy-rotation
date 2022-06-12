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
WR.GUISettings.APL.Priest = {
  Commons = {
    Enabled = {
    },
  },
  Holy = {
    General = {
      Enabled = {
        AngelicFeather = true,
        BodyAndSoul = true,
        Dispel = true,
        FlashConcentration = true,
        OutOfCombatHealing = true,
        PowerWordFortitude = true,
      },
    },
    Cooldown = {
      Enabled = {
        PowerInfusionSolo = true,
      },
      HP = {
        Apotheosis = 60,
        DivineHymn = 50,
        GuardianSpirit = 20,
        HolyWordSalvation = 50,
      },
      AoEGroup = {
        Apotheosis = 3,
        DivineHymn = 3,
        HolyWordSalvation = 4,
      },
      AoERaid = {
        Apotheosis = 6,
        DivineHymn = 6,
        HolyWordSalvation = 8,
      },
    },
    Defensive = {
      Enabled = {
        Fade = true,
      },
      HP = {
        DesperatePrayer = 40,
      },
    },
    Damage = {
      Enabled = {
        BoonOfTheAscended = true,
        DivineStar = true,
      },
      AoE = {
        DivineStar = 1,
        HolyNova = 3,
      },
    },
    Healing = {
      HP = {
        CircleOfHealing = 85,
        DivineStar = 85,
        FlashHeal = 65,
        Halo = 85,
        Heal = 80,
        HolyWordSanctify = 85,
        HolyWordSerenity = 70,
        PrayerOfHealing = 0,
        PrayerOfMending = 99,
        Renew = 0,
      },
      AoEGroup = {
        CircleOfHealing = 3,
        Halo = 3,
        HolyWordSanctify = 3,
        PrayerOfHealing = 3,
      },
      AoERaid = {
        CircleOfHealing = 4,
        Halo = 5,
        HolyWordSanctify = 4,
        PrayerOfHealing = 4,
      },
    },
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Priest = CreateChildPanel(ARPanel, "Priest")
local CP_Holy = CreateChildPanel(CP_Priest, "Holy")
local CP_Holy_General = CreateChildPanel(CP_Holy, "General")
local CP_Holy_Cooldown = CreateChildPanel(CP_Holy, "Cooldown")
local CP_Holy_Defensive = CreateChildPanel(CP_Holy, "Defensive")
local CP_Holy_Damage = CreateChildPanel(CP_Holy, "Damage")
local CP_Holy_Healing = CreateChildPanel(CP_Holy, "Healing")

CreateARPanelOptions(CP_Priest, "APL.Priest.Commons")

--Holy
CreateARPanelOptions(CP_Holy_General, "APL.Priest.Holy.General")
CreateARPanelOptions(CP_Holy_Cooldown, "APL.Priest.Holy.Cooldown")
CreateARPanelOptions(CP_Holy_Defensive, "APL.Priest.Holy.Defensive")
CreateARPanelOptions(CP_Holy_Damage, "APL.Priest.Holy.Damage")
CreateARPanelOptions(CP_Holy_Healing, "APL.Priest.Holy.Healing")
