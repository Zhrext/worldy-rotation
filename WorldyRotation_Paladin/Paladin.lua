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
  Intercession                          = Spell(391054),
  FlashofLight                          = Spell(19750),
  HammerofJustice                       = Spell(853),
  HandofReckoning                       = Spell(62124),
  Judgment                              = Spell(20271),
  Rebuke                                = Spell(96231),
  Redemption                            = Spell(7328),
  ShieldoftheRighteous                  = Spell(53600),
  WordofGlory                           = Spell(85673),
  -- Talents
  AvengingWrath                         = Spell(31884),
  BlindingLight                         = Spell(115750),
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
  AuraMastery                           = Spell(31821),
  Absolution                            = Spell(212056),
  BlessingofSummer                      = Spell(388007),
  BlessingofAutumn                      = Spell(388010),
  BlessingofWinter                      = Spell(388011),
  BlessingofSpring                      = Spell(388013),
  BlessingofSacrifice                   = Spell(6940),
  BeaconofVirtue                        = Spell(200025),
  Cleanse                               = Spell(4987),
  DivineFavor                           = Spell(210294),
  DivineProtection                      = Spell(498),
  DivineToll                            = Spell(375576),
  HolyLight                             = Spell(82326),
  HolyShock                             = Spell(20473),
  InfusionofLightBuff                   = Spell(54149),
  LightofDawn                           = Spell(85222),
  LightoftheMartyr                      = Spell(183998),
  Judgment                              = Spell(275773),
  -- Talents
  AvengingCrusader                      = Spell(216331),
  Awakening                             = Spell(248033),
  BestowFaith                           = Spell(223306),
  CrusadersMight                        = Spell(196926),
  EmpyreanLegacyBuff                    = Spell(387178),
  GlimmerofLight                        = Spell(325966),
  GlimmerofLightBuff                    = Spell(287280),
  GoldenPath                            = Spell(377128),
  HolyPrism                             = Spell(114165),
  LightsHammer                          = Spell(114158),
  JudgmentofLight                       = Spell(183778),
  JudgmentofLightDebuff                 = Spell(196941),
  UnendingLightBuff                     = Spell(394709),
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
  CrusaderStrikeMouseover          = Macro("CrusaderStrikeMouseover", "/cast [@mouseover] " .. Spell.Paladin.Commons.CrusaderStrike:Name()),
  FlashofLightFocus                = Macro("FlashofLightFocus", "/cast [@focus] " .. Spell.Paladin.Commons.FlashofLight:Name()),
  LayonHandsFocus                  = Macro("LayonHandsFocus", "/cast [@focus] " .. Spell.Paladin.Commons.LayonHands:Name()),
  LayonHandsPlayer                 = Macro("LayonHandsPlayer", "/cast [@player] " .. Spell.Paladin.Commons.LayonHands:Name()),
  LayonHandsMouseover              = Macro("LayonHandsMouseover", "/cast [@mouseover] " .. Spell.Paladin.Commons.LayonHands:Name()),
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
  FinalReckoningPlayer             = Macro("FinalReckoningPlayer", "/cast [@player] " .. Spell.Paladin.Retribution.FinalReckoning:Name()),
})

Macro.Paladin.Holy = MergeTableByKey(Macro.Paladin.Commons, {
  BeaconofVirtueFocus              = Macro("BeaconofVirtueFocus", "/cast [@focus] " .. Spell.Paladin.Holy.BeaconofVirtue:Name()),
  BlessingofSummerPlayer           = Macro("BlessingofSummerPlayer", "/cast [@player] " .. Spell.Paladin.Holy.BlessingofSummer:Name()),
  BlessingofSummerFocus            = Macro("BlessingofSummerFocus", "/cast [@focus] " .. Spell.Paladin.Holy.BlessingofSummer:Name()),
  BlessingofSacrificeFocus         = Macro("BlessingofSacrificeFocus", "/cast [@focus] " .. Spell.Paladin.Holy.BlessingofSacrifice:Name()),
  BlessingofSacrificeMouseover     = Macro("BlessingofSacrificeMouseover", "/cast [@mouseover] " .. Spell.Paladin.Holy.BlessingofSacrifice:Name()),
  CleanseFocus                     = Macro("CleanseFocus", "/cast [@focus] " .. Spell.Paladin.Holy.Cleanse:Name()),
  CleanseMouseover                 = Macro("CleanseMouseover", "/cast [@mouseover] " .. Spell.Paladin.Holy.Cleanse:Name()),
  DivineTollFocus                  = Macro("DivineTollFocus", "/cast [@focus] " .. Spell.Paladin.Holy.DivineToll:Name()),
  HolyLightFocus                   = Macro("HolyLightFocus", "/cast [@focus] " .. Spell.Paladin.Holy.HolyLight:Name()),
  HolyShockFocus                   = Macro("HolyShockFocus", "/cast [@focus] " .. Spell.Paladin.Holy.HolyShock:Name()),
  HolyShockMouseover               = Macro("HolyShockMouseover", "/cast [@mouseover] " .. Spell.Paladin.Holy.HolyShock:Name()),
  HolyPrismPlayer                  = Macro("HolyPrismPlayer", "/cast [@focus] " .. Spell.Paladin.Holy.HolyPrism:Name()),
  LightoftheMartyrFocus            = Macro("LightoftheMartyrFocus", "/cast [@focus] " .. Spell.Paladin.Holy.LightoftheMartyr:Name()),
  LightsHammerPlayer               = Macro("LightsHammerPlayer", "/cast [@player] " .. Spell.Paladin.Holy.LightsHammer:Name()),
  -- Focus
  FocusTarget                      = Macro("FocusTarget", "/focus target"),
  FocusPlayer                      = Macro("FocusPlayer", "/focus player"),
  FocusParty1                      = Macro("FocusParty1", "/focus party1"),
  FocusParty2                      = Macro("FocusParty2", "/focus party2"),
  FocusParty3                      = Macro("FocusParty3", "/focus party3"),
  FocusParty4                      = Macro("FocusParty4", "/focus party4"),
  FocusRaid1                       = Macro("FocusRaid1", "/focus raid1"),
  FocusRaid2                       = Macro("FocusRaid2", "/focus raid2"),
  FocusRaid3                       = Macro("FocusRaid3", "/focus raid3"),
  FocusRaid4                       = Macro("FocusRaid4", "/focus raid4"),
  FocusRaid5                       = Macro("FocusRaid5", "/focus raid5"),
  FocusRaid6                       = Macro("FocusRaid6", "/focus raid6"),
  FocusRaid7                       = Macro("FocusRaid7", "/focus raid7"),
  FocusRaid8                       = Macro("FocusRaid8", "/focus raid8"),
  FocusRaid9                       = Macro("FocusRaid9", "/focus raid9"),
  FocusRaid10                      = Macro("FocusRaid10", "/focus raid10"),
  FocusRaid11                      = Macro("FocusRaid11", "/focus raid11"),
  FocusRaid12                      = Macro("FocusRaid12", "/focus raid12"),
  FocusRaid13                      = Macro("FocusRaid13", "/focus raid13"),
  FocusRaid14                      = Macro("FocusRaid14", "/focus raid14"),
  FocusRaid15                      = Macro("FocusRaid15", "/focus raid15"),
  FocusRaid16                      = Macro("FocusRaid16", "/focus raid16"),
  FocusRaid17                      = Macro("FocusRaid17", "/focus raid17"),
  FocusRaid18                      = Macro("FocusRaid18", "/focus raid18"),
  FocusRaid19                      = Macro("FocusRaid19", "/focus raid19"),
  FocusRaid20                      = Macro("FocusRaid20", "/focus raid20"),
  FocusRaid21                      = Macro("FocusRaid21", "/focus raid21"),
  FocusRaid22                      = Macro("FocusRaid22", "/focus raid22"),
  FocusRaid23                      = Macro("FocusRaid23", "/focus raid23"),
  FocusRaid24                      = Macro("FocusRaid24", "/focus raid24"),
  FocusRaid25                      = Macro("FocusRaid25", "/focus raid25"),
  FocusRaid26                      = Macro("FocusRaid26", "/focus raid26"),
  FocusRaid27                      = Macro("FocusRaid27", "/focus raid27"),
  FocusRaid28                      = Macro("FocusRaid28", "/focus raid28"),
  FocusRaid29                      = Macro("FocusRaid29", "/focus raid29"),
  FocusRaid30                      = Macro("FocusRaid30", "/focus raid30"),
  FocusRaid31                      = Macro("FocusRaid31", "/focus raid31"),
  FocusRaid32                      = Macro("FocusRaid32", "/focus raid32"),
  FocusRaid33                      = Macro("FocusRaid33", "/focus raid33"),
  FocusRaid34                      = Macro("FocusRaid34", "/focus raid34"),
  FocusRaid35                      = Macro("FocusRaid35", "/focus raid35"),
  FocusRaid36                      = Macro("FocusRaid36", "/focus raid36"),
  FocusRaid37                      = Macro("FocusRaid37", "/focus raid37"),
  FocusRaid38                      = Macro("FocusRaid38", "/focus raid38"),
  FocusRaid39                      = Macro("FocusRaid39", "/focus raid39"),
  FocusRaid40                      = Macro("FocusRaid40", "/focus raid40"),
})
