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
local Pet        = Unit.Pet
local Spell      = HL.Spell
local MultiSpell = HL.MultiSpell
local Item       = HL.Item
local MergeTableByKey = HL.Utils.MergeTableByKey
-- WorldyRotation
local WR         = WorldyRotation
local Macro      = WR.Macro

--- ============================ CONTENT ============================
-- Spells
if not Spell.Paladin then Spell.Paladin = {} end
Spell.Paladin.Commons = {
  -- Racials
  AncestralCall                         = Spell(274738),
  ArcanePulse                           = Spell(260364),
  ArcaneTorrent                         = Spell(50613),
  BagofTricks                           = Spell(312411),
  Berserking                            = Spell(26297),
  BloodFury                             = Spell(20572),
  Fireblood                             = Spell(265221),
  GiftoftheNaaru                        = Spell(59542),
  LightsJudgment                        = Spell(255647),
  -- Abilities
  BlessingofFreedom                     = Spell(1044),
  BlessingofProtection                  = Spell(1022),
  Consecration                          = Spell(26573),
  CrusaderStrike                        = Spell(35395),
  CleanseToxins                         = Spell(213644),
  DivineShield                          = Spell(642),
  DivineSteed                           = Spell(190784),
  FlashofLight                          = Spell(19750),
  HammerofJustice                       = Spell(853),
  HandofReckoning                       = Spell(62124),
  Judgment                              = Spell(20271),
  Rebuke                                = Spell(96231),
  ShieldoftheRighteous                  = Spell(53600),
  WordofGlory                           = Spell(85673),
  -- Talents
  AvengingWrath                         = Spell(31884),
  HammerofWrath                         = Spell(24275),
  HolyAvenger                           = Spell(105809),
  LayonHands                            = Spell(633),
  Seraphim                              = Spell(152262),
  ZealotsParagon                        = Spell(391142),
  -- Auras
  ConcentrationAura                     = Spell(317920),
  CrusaderAura                          = Spell(32223),
  DevotionAura                          = Spell(465),
  RetributionAura                       = Spell(183435),
  -- Buffs
  AvengingWrathBuff                     = Spell(31884),
  BlessingofDuskBuff                    = Spell(385126),
  ConsecrationBuff                      = Spell(188370),
  DivinePurposeBuff                     = Spell(223819),
  HolyAvengerBuff                       = Spell(105809),
  SeraphimBuff                          = Spell(152262),
  ShieldoftheRighteousBuff              = Spell(132403),
  -- Debuffs
  ConsecrationDebuff                    = Spell(204242),
  JudgmentDebuff                        = Spell(197277),
  -- Pool
  Pool                                  = Spell(999910),
}

Spell.Paladin.Protection = MergeTableByKey(Spell.Paladin.Commons, {
  -- Abilities
  Judgment                              = Spell(275779),
  -- Talents
  ArdentDefender                        = Spell(31850),
  AvengersShield                        = Spell(31935),
  BastionofLight                        = Spell(378974),
  BlessedHammer                         = Spell(204019),
  CrusadersJudgment                     = Spell(204023),
  DivineToll                            = Spell(375576),
  EyeofTyr                              = Spell(387174),
  GuardianofAncientKings                = Spell(86659),
  HammeroftheRighteous                  = Spell(53595),
  MomentofGlory                         = Spell(327193),
  -- Buffs
  ArdentDefenderBuff                    = Spell(31850),
  BastionofLightBuff                    = Spell(378974),
  GuardianofAncientKingsBuff            = Spell(86659),
  MomentofGloryBuff                     = Spell(327193),
  ShiningLightFreeBuff                  = Spell(327510),
  -- Debuffs
})

Spell.Paladin.Retribution = MergeTableByKey(Spell.Paladin.Commons, {
  -- Abilities
  TemplarsVerdict                       = Spell(85256),
  -- Talents
  AshestoDust                           = Spell(383300),
  BladeofJustice                        = Spell(184575),
  BladeofWrath                          = Spell(231832),
  Crusade                               = Spell(231895),
  DivineResonance                       = Spell(384027),
  DivineStorm                           = Spell(53385),
  DivineToll                            = Spell(375576),
  EmpyreanLegacy                        = Spell(387170),
  EmpyreanPower                         = Spell(326732),
  ExecutionSentence                     = Spell(343527),
  ExecutionersWrath                     = Spell(387196),
  Exorcism                              = Spell(383185),
  Expurgation                           = Spell(383344),
  FinalReckoning                        = Spell(343721),
  FinalVerdict                          = Spell(383328),
  FiresofJustice                        = Spell(203316),
  JusticarsVengeance                    = Spell(215661),
  RadiantDecree                         = Spell(383469),
  RadiantDecreeTalent                   = Spell(384052),
  RighteousVerdict                      = Spell(267610),
  ShieldofVengeance                     = Spell(184662),
  VanguardsMomentum                     = Spell(383314),
  WakeofAshes                           = Spell(255937),
  Zeal                                  = Spell(269569),
  -- Buffs
  CrusadeBuff                           = Spell(231895),
  DivineResonanceBuff                   = Spell(384029),
  EmpyreanLegacyBuff                    = Spell(387178),
  EmpyreanPowerBuff                     = Spell(326733),
  -- Debuffs
})

Spell.Paladin.Holy = MergeTableByKey(Spell.Paladin.Commons, {
  -- Abilities
  DivineProtection                      = Spell(498),
  HolyShock                             = Spell(20473),
  Judgment                              = Spell(275773),
  LightofDawn                           = Spell(85222),
  InfusionofLightBuff                   = Spell(54149),
  -- Talents
  AvengingCrusader                      = Spell(216331),
  Awakening                             = Spell(248033),
  BestowFaith                           = Spell(223306),
  CrusadersMight                        = Spell(196926),
  GlimmerofLight                        = Spell(325966),
  GlimmerofLightDebuff                  = Spell(325966),
  HolyPrism                             = Spell(114165),
  LightsHammer                          = Spell(114158),
})

-- Items
if not Item.Paladin then Item.Paladin = {} end
Item.Paladin.Commons = {
  -- Potion
  Healthstone                           = Item(5512),
  -- Trinkets
  AlgetharPuzzleBox                     = Item(193701, {13, 14}),
}

Item.Paladin.Protection = MergeTableByKey(Item.Paladin.Commons, {
})

Item.Paladin.Retribution = MergeTableByKey(Item.Paladin.Commons, {
})

Item.Paladin.Holy = MergeTableByKey(Item.Paladin.Commons, {
})

-- Macros
if not Macro.Paladin then Macro.Paladin = {} end
Macro.Paladin.Commons = {
  -- Spells
  BlessingofProtectionMouseover    = Macro("BlessingofProtectionMouseover", "/cast [@mouseover] " .. Spell.Paladin.Commons.BlessingofProtection:Name()),
  BlessingofFreedomMouseover       = Macro("BlessingofFreedomMouseover", "/cast [@mouseover] " .. Spell.Paladin.Commons.BlessingofFreedom:Name()),
  CleanseToxinsMouseover           = Macro("CleanseToxinsMouseover", "/cast [@mouseover] " .. Spell.Paladin.Commons.CleanseToxins:Name()),
  LayonHandsFocus                  = Macro("LayonHandsFocus", "/cast [@focus] " .. Spell.Paladin.Commons.LayonHands:Name()),
  LayonHandsPlayer                 = Macro("LayonHandsPlayer", "/cast [@player] " .. Spell.Paladin.Commons.LayonHands:Name()),
  JudgmentMouseover                = Macro("JudgmentMouseover", "/cast [@mouseover] " .. Spell.Paladin.Commons.Judgment:Name()),
  WordofGloryFocus                 = Macro("WordofGloryFocus", "/cast [@focus] " .. Spell.Paladin.Commons.WordofGlory:Name()),
  WordofGloryPlayer                = Macro("WordofGloryPlayer", "/cast [@player] " .. Spell.Paladin.Commons.WordofGlory:Name()),
  -- Items
  Trinket1                         = Macro("Trinket1", "/use 13"),
  Trinket2                         = Macro("Trinket2", "/use 14"),
  Healthstone                      = Macro("Healthstone", "/use item:5512"),
  -- Focus
  FocusPlayer                      = Macro("FocusPlayer", "/focus player"),
  FocusParty1                      = Macro("FocusParty1", "/focus party1"),
  FocusParty2                      = Macro("FocusParty2", "/focus party2"),
  FocusParty3                      = Macro("FocusParty3", "/focus party3"),
  FocusParty4                      = Macro("FocusParty4", "/focus party4"),
}

Macro.Paladin.Protection = MergeTableByKey(Macro.Paladin.Commons, {
})

Macro.Paladin.Retribution = MergeTableByKey(Macro.Paladin.Commons, {
})

Macro.Paladin.Holy = MergeTableByKey(Macro.Paladin.Commons, {
})
