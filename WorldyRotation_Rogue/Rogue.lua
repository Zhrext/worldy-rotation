--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local HL         = HeroLib
local Cache      = HeroCache
local Unit       = HL.Unit
local Player     = Unit.Player
local Target     = Unit.Target
local MouseOver  = Unit.MouseOver
local Spell      = HL.Spell
local MultiSpell = HL.MultiSpell
local Item       = HL.Item
local MergeTableByKey = HL.Utils.MergeTableByKey
-- WorldyRotation
local WR = WorldyRotation
local Everyone = WR.Commons.Everyone
-- Lua
local mathmin = math.min
local pairs = pairs
-- File Locals
local Commons = {}

--- ======= GLOBALIZE =======
WR.Commons.Rogue = Commons

--- ============================ CONTENT ============================
-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Rogue.Commons,
  Commons2 = WR.GUISettings.APL.Rogue.Commons2,
  Outlaw = WR.GUISettings.APL.Rogue.Outlaw,
}

-- Spells
if not Spell.Rogue then Spell.Rogue = {} end

Spell.Rogue.Commons = {
  -- Racials
  AncestralCall           = Spell(274738),
  ArcanePulse             = Spell(260364),
  ArcaneTorrent           = Spell(25046),
  BagofTricks             = Spell(312411),
  Berserking              = Spell(26297),
  BloodFury               = Spell(20572),
  Fireblood               = Spell(265221),
  LightsJudgment          = Spell(255647),
  Shadowmeld              = Spell(58984),
  -- Defensive
  CloakofShadows          = Spell(31224),
  CrimsonVial             = Spell(185311),
  Evasion                 = Spell(5277),
  Feint                   = Spell(1966),
  -- Utility
  Blind                   = Spell(2094),
  CheapShot               = Spell(1833),
  Kick                    = Spell(1766),
  KidneyShot              = Spell(408),
  Sap                     = Spell(6770),
  Shadowstep              = Spell(36554),
  Sprint                  = Spell(2983),
  TricksoftheTrade        = Spell(57934),
  -- Legendaries (Shadowlands)
  MasterAssassinsMark     = Spell(340094),
  -- Covenants (Shadowlands)
  EchoingReprimand        = Spell(323547),
  EchoingReprimand2       = Spell(323558),
  EchoingReprimand3       = Spell(323559),
  EchoingReprimand4       = Spell(323560),
  EchoingReprimand5       = Spell(354838),
  Flagellation            = Spell(323654),
  FlagellationBuff        = Spell(345569),
  Fleshcraft              = Spell(324631),
  Sepsis                  = Spell(328305),
  SepsisBuff              = Spell(347037),
  SerratedBoneSpike       = Spell(328547),
  SerratedBoneSpikeDebuff = Spell(324073),
  -- Soulbinds/Conduits (Shadowlands)
  EffusiveAnimaAccelerator= Spell(352188),
  KevinsOozeling          = Spell(352110),
  KevinsWrathDebuff       = Spell(352528),
  LeadbyExample           = Spell(342156),
  LeadbyExampleBuff       = Spell(342181),
  MarrowedGemstoneBuff    = Spell(327069),
  PustuleEruption         = Spell(351094),
  VolatileSolvent         = Spell(323074),
  -- Domination Shards
  ChaosBaneBuff           = Spell(355829),
  -- Trinkets
  AcquiredSword           = Spell(368657),
  AcquiredAxe             = Spell(368656),
  AcquiredWand            = Spell(368654),
  -- Misc
  PoolEnergy              = Spell(999910),
  SinfulRevelationDebuff  = Spell(324260),
}

Spell.Rogue.Outlaw = MergeTableByKey(Spell.Rogue.Commons, {
  -- Abilities
  AdrenalineRush          = Spell(13750),
  Ambush                  = Spell(8676),
  BetweentheEyes          = Spell(315341),
  BladeFlurry             = Spell(13877),
  Dispatch                = Spell(2098),
  Elusiveness             = Spell(79008),
  Opportunity             = Spell(195627),
  PistolShot              = Spell(185763),
  RolltheBones            = Spell(315508),
  Shiv                    = Spell(5938),
  SinisterStrike          = Spell(193315),
  SliceandDice            = Spell(315496),
  Stealth                 = Spell(1784),
  Vanish                  = Spell(1856),
  VanishBuff              = Spell(11327),
  -- Talents
  AcrobaticStrikes        = Spell(196924),
  BladeRush               = Spell(271877),
  DeeperStratagem         = Spell(193531),
  Dreadblades             = Spell(343142),
  GhostlyStrike           = Spell(196937),
  KillingSpree            = Spell(51690),
  LoadedDiceBuff          = Spell(256171),
  MarkedforDeath          = Spell(137619),
  PreyontheWeak           = Spell(131511),
  PreyontheWeakDebuff     = Spell(255909),
  QuickDraw               = Spell(196938),
  -- Utility
  Gouge                   = Spell(1776),
  -- PvP
  DeathfromAbove          = Spell(269513),
  Dismantle               = Spell(207777),
  Maneuverability         = Spell(197000),
  PlunderArmor            = Spell(198529),
  SmokeBomb               = Spell(212182),
  ThickasThieves          = Spell(221622),
  -- Roll the Bones
  Broadside               = Spell(193356),
  BuriedTreasure          = Spell(199600),
  GrandMelee              = Spell(193358),
  RuthlessPrecision       = Spell(193357),
  SkullandCrossbones      = Spell(199603),
  TrueBearing             = Spell(193359),
  -- Soulbinds/Conduits (Shadowlands)
  Ambidexterity           = Spell(341542),
  CountTheOdds            = Spell(341546),
  -- Legendaries (Shadowlands)
  ConcealedBlunderbuss    = Spell(340587),
  DeathlyShadowsBuff      = Spell(341202),
  GreenskinsWickers       = Spell(340573),
  -- Set Bonuses (Shadowlands)
  TornadoTriggerBuff      = Spell(364556),
})

-- Items
if not Item.Rogue then Item.Rogue = {} end
Item.Rogue.Outlaw = {
  -- Trinkets
  ComputationDevice     = Item(167555, {13, 14}),
  VigorTrinket          = Item(165572, {13, 14}),
  FontOfPower           = Item(169314, {13, 14}),
  RazorCoral            = Item(169311, {13, 14}),
}

-- Stealth
function Commons.Stealth(Stealth)
  if Settings.Commons2.Enabled.StealthOOC and Stealth:IsCastable() and Player:StealthDown() then
    if WR.Cast(Stealth) then return "Cast Stealth (OOC)" end
  end

  return false
end

-- Crimson Vial
do
  local CrimsonVial = Spell(185311)

  function Commons.CrimsonVial()
    if CrimsonVial:IsCastable() and Player:HealthPercentage() <= Settings.Commons2.HP.CrimsonVialHP then
      if WR.Cast(CrimsonVial) then return "Cast Crimson Vial (Defensives)" end
    end

    return false
  end
end

-- Feint
do
  local Feint = Spell(1966)

  function Commons.Feint()
    if Feint:IsCastable() and Player:BuffDown(Feint) and Player:HealthPercentage() <= Settings.Commons2.HP.FeintHP then
      if WR.Cast(Feint) then return "Cast Feint (Defensives)" end
    end
  end
end

-- Poisons
do
  local CripplingPoison     = Spell(3408)
  local DeadlyPoison        = Spell(2823)
  local InstantPoison       = Spell(315584)
  local NumbingPoison       = Spell(5761)
  local WoundPoison         = Spell(8679)

  function Commons.Poisons()
    local PoisonRefreshTime = Player:AffectingCombat() and Settings.Commons.PoisonRefreshCombat * 60 or Settings.Commons.PoisonRefresh * 60
    local PoisonRemains
    -- Lethal Poison
    PoisonRemains = Player:BuffRemains(WoundPoison)
    if PoisonRemains > 0 then
      if PoisonRemains < PoisonRefreshTime then
        WR.Cast(WoundPoison)
      end
    else
      if DeadlyPoison:IsAvailable() then
        PoisonRemains = Player:BuffRemains(DeadlyPoison)
        if PoisonRemains < PoisonRefreshTime then
          WR.Cast(DeadlyPoison)
        end
      else
        PoisonRemains = Player:BuffRemains(InstantPoison)
        if PoisonRemains < PoisonRefreshTime then
          WR.Cast(InstantPoison)
        end
      end
    end
    -- Non-Lethal Poisons
    PoisonRemains = Player:BuffRemains(CripplingPoison)
    if PoisonRemains > 0 then
      if PoisonRemains < PoisonRefreshTime then
        WR.Cast(CripplingPoison)
      end
    else
      PoisonRemains = Player:BuffRemains(NumbingPoison)
      if PoisonRemains < PoisonRefreshTime then
        WR.Cast(NumbingPoison)
      end
    end
  end
end

-- Marked for Death Sniping
function Commons.MfDSniping(MarkedforDeath)
  if MarkedforDeath:IsCastable() then
    local BestUnit, BestUnitTTD = nil, 60
    local MOTTD = MouseOver:IsInRange(30) and MouseOver:TimeToDie() or 11111
    for _, ThisUnit in pairs(Player:GetEnemiesInRange(30)) do
      local TTD = ThisUnit:TimeToDie()
      -- Note: Increased the SimC condition by 50% since we are slower.
      if not ThisUnit:IsMfDBlacklisted() and TTD < Player:ComboPointsDeficit()*1.5 and TTD < BestUnitTTD then
        if MOTTD - TTD > 1 then
          BestUnit, BestUnitTTD = ThisUnit, TTD
        else
          BestUnit, BestUnitTTD = MouseOver, MOTTD
        end
      end
    end
    if BestUnit and BestUnit:GUID() ~= Target:GUID() then
      --WR.CastLeftNameplate(BestUnit, MarkedforDeath)
      -- TODO use mouseover or focus to cast mfd
    end
  end
end

-- Everyone CanDotUnit override, originally used for Mantle legendary
-- Is it worth to DoT the unit ?
function Commons.CanDoTUnit(ThisUnit, HealthThreshold)
  return Everyone.CanDoTUnit(ThisUnit, HealthThreshold)
end
--- ======= SIMC CUSTOM FUNCTION / EXPRESSION =======
-- cp_max_spend
do
  local DeeperStratagem = Spell(193531)

  function Commons.CPMaxSpend()
    return DeeperStratagem:IsAvailable() and 6 or 5
  end
end

-- "cp_spend"
function Commons.CPSpend()
  return mathmin(Player:ComboPoints(), Commons.CPMaxSpend())
end

-- "animacharged_cp"
do
  function Commons.AnimachargedCP()
    if Player:BuffUp(Spell.Rogue.Commons.EchoingReprimand2) then
      return 2
    elseif Player:BuffUp(Spell.Rogue.Commons.EchoingReprimand3) then
      return 3
    elseif Player:BuffUp(Spell.Rogue.Commons.EchoingReprimand4) then
      return 4
    elseif Player:BuffUp(Spell.Rogue.Commons.EchoingReprimand5) then
      return 5
    end

    return -1
  end

  function Commons.EffectiveComboPoints(ComboPoints)
    if ComboPoints == 2 and Player:BuffUp(Spell.Rogue.Commons.EchoingReprimand2)
    or ComboPoints == 3 and Player:BuffUp(Spell.Rogue.Commons.EchoingReprimand3)
    or ComboPoints == 4 and Player:BuffUp(Spell.Rogue.Commons.EchoingReprimand4)
    or ComboPoints == 5 and Player:BuffUp(Spell.Rogue.Commons.EchoingReprimand5) then
      return 7
    end
    return ComboPoints
  end
end

-- Master Assassin's Mark Remains Check
do
  local MasterAssassinsMark, NominalDuration = Spell(340094), 4

  function Commons.MasterAssassinsMarkRemains ()
    if Player:BuffRemains(MasterAssassinsMark) < 0 then
      return Player:GCDRemains() + NominalDuration
    else
      return Player:BuffRemains(MasterAssassinsMark)
    end
  end
end
