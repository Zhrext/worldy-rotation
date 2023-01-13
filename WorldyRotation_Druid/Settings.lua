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
WR.GUISettings.APL.Druid = {
  Commons = {
    Enabled = {
      OutOfCombatHealing = true,
      MarkOfTheWild = true,
    },
  },
  Balance = {
    Enabled = {
      MoonkinFormOOC = false,
    },
    Defensive = {
      HP = {
        Barkskin = 50,
        NaturesVigil = 75,
      },
    },
  },
  Restoration = {
    Defensive = {
      HP = {
        Barkskin = 40,
      },
    },
    Damage = {
      Enabled = {
        ConvokeTheSpirits = true,
        NaturesVigil = true,
      },
    },
    HealingOne = {
      Enabled = {
        Efflorescence = true,
      },
      HP = {
        CenarionWard = 40,
        ConvokeTheSpirits = 60,
        Efflorescence = 99,
        Flourish = 60,
        IronBark = 30,
        LifebloomTank = 99,
        Lifebloom = 70,
        NaturesSwiftness = 40,
      },
      AoEGroup = {
        ConvokeTheSpirits = 3,
        Flourish = 3,
      },
      AoERaid = {
        ConvokeTheSpirits = 5,
        Flourish = 5,
      },
    },
    HealingTwo = {
      HP = {
        Regrowth = 40,
        RegrowthRefresh = 60,
        Rejuvenation = 80,
        Swiftmend = 88,
        Tranquility = 35,
        TranquilityTree = 40,
        WildgrowthSotF = 95,
        Wildgrowth = 75,
      },
      AoEGroup = {
        Tranquility = 3,
        TranquilityTree = 4,
        WildgrowthSotF = 2,
        Wildgrowth = 2,
      },
      AoERaid = {
        Tranquility = 5,
        TranquilityTree = 6,
        WildgrowthSotF = 3,
        Wildgrowth = 4,
      },
    },
  },
}

WR.GUI.LoadSettingsRecursively(WR.GUISettings)

-- Child Panels
local ARPanel = WR.GUI.Panel
local CP_Druid = CreateChildPanel(ARPanel, "Druid")
local CP_Balance = CreateChildPanel(CP_Druid, "Balance")
local CP_Balance_Defensive = CreateChildPanel(CP_Balance, "Defensive")
local CP_Restoration = CreateChildPanel(CP_Druid, "Restoration")
local CP_Restoration_Defensive = CreateChildPanel(CP_Restoration, "Defensive")
local CP_Restoration_Damage = CreateChildPanel(CP_Restoration, "Damage")
local CP_Restoration_HealingOne = CreateChildPanel(CP_Restoration, "HealingOne")
local CP_Restoration_HealingTwo = CreateChildPanel(CP_Restoration, "HealingTwo")

-- Druid
CreateARPanelOptions(CP_Druid, "APL.Druid.Commons")

-- Balance
CreateARPanelOptions(CP_Balance, "APL.Druid.Balance")
CreateARPanelOptions(CP_Balance_Defensive, "APL.Druid.Balance.Defensive")

-- Restoration
CreateARPanelOptions(CP_Restoration_Defensive, "APL.Druid.Restoration.Defensive")
CreateARPanelOptions(CP_Restoration_Damage, "APL.Druid.Restoration.Damage")
CreateARPanelOptions(CP_Restoration_HealingOne, "APL.Druid.Restoration.HealingOne")
CreateARPanelOptions(CP_Restoration_HealingTwo, "APL.Druid.Restoration.HealingTwo")
