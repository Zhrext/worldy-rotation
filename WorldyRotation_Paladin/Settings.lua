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
WR.GUISettings.APL.Paladin = {
  Commons = {
    Enabled = {
        OutOfCombatHealing = true,
    },
  },
  Protection = {
    HP = {
      DS = 25,
      LoH = 15,
      GoAK = 40,
      WordofGlory = 50,
      ArdentDefender = 60,
      ShieldoftheRighteous = 70,
    },
  },
  Retribution = {
    HP = {
      DS = 35,
    },
  },
  Holy = {
    Enabled = {
      AvengingWrathOffensively = false,
      DivineTollOffensively = true,
      HolyShockOffensively = true,
      HolyShockCycle = true,
      HolyShockRefreshOnly = true,
    },
    HP = {
      LoH = 15,
      DP = 50,
      DS = 35,
      WoG = 60,
    },
    Healing = {
      HP = {
        AvengingWrath = 65,
        AuraMastery = 50,
        BlessingofSacrifice = 60,
        BeaconofVirtue = 85,
        DivineToll = 65,
        FlashofLight = 40,
        HolyLight = 75,
        HolyShock = 90,
        LayonHands = 15,
        LightofDawn = 90,
        WordofGlory = 75,
      },
      AoEGroup = {
        AvengingWrath = 2,
        AuraMastery = 2,
        BeaconofVirtue = 2,
        DivineToll = 2,
        LightofDawn = 2,
      },
      AoERaid = {
        AvengingWrath = 4,
        AuraMastery = 4,
        BeaconofVirtue = 4,
        DivineToll = 4,
        LightofDawn = 4,
      },
    },
  },
}
-- GUI
WR.GUI.LoadSettingsRecursively(WR.GUISettings)
-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Paladin = CreateChildPanel(ARPanel, "Paladin")
local CP_Protection = CreateChildPanel(CP_Paladin, "Protection")
local CP_Retribution = CreateChildPanel(CP_Paladin, "Retribution")
local CP_Holy = CreateChildPanel(CP_Paladin, "Holy")
local CP_Holy_Healing = CreateChildPanel(CP_Holy, "Healing")

-- Shared Paladin settings
CreateARPanelOptions(CP_Paladin, "APL.Paladin.Commons")

-- Protection
CreateARPanelOptions(CP_Protection, "APL.Paladin.Protection")

-- Retribution
CreateARPanelOptions(CP_Retribution, "APL.Paladin.Retribution")

-- Holy
CreateARPanelOptions(CP_Holy, "APL.Paladin.Holy")
CreateARPanelOptions(CP_Holy_Healing, "APL.Paladin.Holy.Healing")
