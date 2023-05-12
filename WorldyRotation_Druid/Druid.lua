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

-- Spell
if not Spell.Druid then Spell.Druid = {} end
Spell.Druid.Commons = {
  -- Racials
  Berserking                            = Spell(26297),
  Shadowmeld                            = Spell(58984),
  -- Abilities
  Barkskin                              = Spell(22812),
  BearForm                              = Spell(5487),
  CatForm                               = Spell(768),
  FerociousBite                         = Spell(22568),
  MarkOfTheWild                         = Spell(1126),
  Moonfire                              = Spell(8921),
  Prowl                                 = Spell(5215),
  Rebirth                               = Spell(20484),
  Regrowth                              = Spell(8936),
  Rejuvenation                          = Spell(774),
  Revive                                = Spell(50769),
  Shred                                 = Spell(5221),
  Soothe                                = Spell(2908),
  -- Talents
  AstralCommunion                       = Spell(202359),
  ConvokeTheSpirits                     = Spell(391528),
  FrenziedRegeneration                  = Spell(22842),
  HeartOfTheWild                        = Spell(319454),
  Innervate                             = Spell(29166),
  IncapacitatingRoar                    = Spell(99),
  ImprovedNaturesCure                   = Spell(392378),
  Ironfur                               = Spell(192081),
  NaturesVigil                          = Spell(124974),
  Maim                                  = Spell(22570),
  MightyBash                            = Spell(5211),
  MoonkinForm                           = MultiSpell(24858,197625),
  Rake                                  = Spell(1822),
  Renewal                               = Spell(108238),
  Rip                                   = Spell(1079),
  SkullBash                             = Spell(106839),
  StampedingRoar                        = Spell(77764),
  Starfire                              = Spell(194153),
  Starsurge                             = MultiSpell(78674,197626),
  Sunfire                               = Spell(93402),
  SurvivalInstincts                     = Spell(61336),
  Swiftmend                             = Spell(18562),
  Swipe                                 = MultiSpell(106785,213771,213764),
  Typhoon                               = Spell(132469),
  Thrash                                = MultiSpell(77758,106830),
  WildCharge                            = MultiSpell(16979,49376,102417),
  Wildgrowth                            = Spell(48438),
  UrsolsVortex                          = Spell(102793),
  MassEntanglement                      = Spell(102359),
  -- Buffs
  FrenziedRegenerationBuff              = Spell(22842),
  IronfurBuff                           = Spell(192081),
  SuddenAmbushBuff                      = Spell(340698),
  -- Debuffs
  MoonfireDebuff                        = Spell(164812),
  RakeDebuff                            = Spell(155722),
  SunfireDebuff                         = Spell(164815),
  ThrashDebuff                          = MultiSpell(106830,192090),
  -- Other
  Pool                                  = Spell(999910)
}

Spell.Druid.Balance = MergeTableByKey(Spell.Druid.Commons, {
  -- Abilities
  EclipseLunar                          = Spell(48518),
  EclipseSolar                          = Spell(48517),
  Wrath                                 = Spell(190984),
  -- Talents
  AetherialKindling                     = Spell(327541),
  AstralSmolder                         = Spell(394058),
  BalanceofAllThings                    = Spell(394048),
  CelestialAlignment                    = MultiSpell(194223,383410), -- 194223 without Orbital Strike, 383410 with Orbital Strike
  ElunesGuidance                        = Spell(393991),
  ForceOfNature                         = Spell(205636),
  FungalGrowth                          = Spell(392999),
  FuryOfElune                           = Spell(202770),
  Incarnation                           = MultiSpell(102560,390414), -- 102560 without Orbital Strike, 390414 with Orbital Strike
  IncarnationTalent                     = Spell(394013),
  NaturesBalance                        = Spell(202430),
  OrbitBreaker                          = Spell(383197),
  OrbitalStrike                         = Spell(390378),
  PowerOfGoldrinn                       = Spell(394046),
  PrimordialArcanicPulsar               = Spell(393960),
  RattleTheStars                        = Spell(393954),
  Solstice                              = Spell(343647),
  SoulOfTheForest                       = Spell(114107),
  Starfall                              = Spell(191034),
  Starlord                              = Spell(202345),
  Starweaver                            = Spell(393940),
  StellarFlare                          = Spell(202347),
  TwinMoons                             = Spell(279620),
  UmbralEmbrace                         = Spell(393760),
  UmbralIntensity                       = Spell(383195),
  WaningTwilight                        = Spell(393956),
  WarriorOfElune                        = Spell(202425),
  WildMushroom                          = Spell(88747),
  -- New Moon Phases
  FullMoon                              = Spell(274283),
  HalfMoon                              = Spell(274282),
  NewMoon                               = Spell(274281),
  -- Buffs
  BOATArcaneBuff                        = Spell(394050),
  BOATNatureBuff                        = Spell(394049),
  CABuff                                = Spell(383410),
  IncarnationBuff                       = MultiSpell(102560,390414),
  PAPBuff                               = Spell(393961),
  RattledStarsBuff                      = Spell(393955),
  SolsticeBuff                          = Spell(343648),
  StarfallBuff                          = Spell(191034),
  StarlordBuff                          = Spell(279709),
  StarweaversWarp                       = Spell(393942),
  StarweaversWeft                       = Spell(393944),
  UmbralEmbraceBuff                     = Spell(393763),
  WarriorOfEluneBuff                    = Spell(202425),
  -- Debuffs
  FungalGrowthDebuff                    = Spell(81281),
  StellarFlareDebuff                    = Spell(202347),
  -- Tier 29 Effects
  GatheringStarstuff                    = Spell(394412),
  TouchTheCosmos                        = Spell(394414),
  -- Legendary Effects
  BOATArcaneLegBuff                     = Spell(339946),
  BOATNatureLegBuff                     = Spell(339943),
  OnethsClearVisionBuff                 = Spell(339797),
  OnethsPerceptionBuff                  = Spell(339800),
  TimewornDreambinderBuff               = Spell(340049)
})

Spell.Druid.Feral = MergeTableByKey(Spell.Druid.Commons, {
  -- Abilties
  -- Talents
  AdaptiveSwarm                         = Spell(391888),
  ApexPredatorsCraving                  = Spell(391881),
  AshamanesGuidance                     = Spell(391548),
  Berserk                               = Spell(106951),
  BerserkHeartoftheLion                 = Spell(391174),
  Bloodtalons                           = Spell(319439),
  BrutalSlash                           = Spell(202028),
  CircleofLifeandDeath                  = Spell(400320),
  DoubleClawedRake                      = Spell(391700),
  FeralFrenzy                           = Spell(274837),
  Incarnation                           = Spell(102543),
  LionsStrength                         = Spell(391972),
  LunarInspiration                      = Spell(155580),
  LIMoonfire                            = Spell(155625), -- Lunar Inspiration Moonfire
  MomentofClarity                       = Spell(236068),
  Predator                              = Spell(202021),
  PrimalWrath                           = Spell(285381),
  RipandTear                            = Spell(391347),
  Sabertooth                            = Spell(202031),
  SouloftheForest                       = Spell(158476),
  Swipe                                 = Spell(106785),
  TearOpenWounds                        = Spell(391785),
  ThrashingClaws                        = Spell(405300),
  TigersFury                            = Spell(5217),
  WildSlashes                           = Spell(390864),
  -- Buffs
  ApexPredatorsCravingBuff              = Spell(391882),
  BloodtalonsBuff                       = Spell(145152),
  Clearcasting                          = Spell(135700),
  SabertoothBuff                        = Spell(391722),
  -- Debuffs
  AdaptiveSwarmDebuff                   = Spell(391889),
  AdaptiveSwarmHeal                     = Spell(391891),
  LIMoonfireDebuff                      = Spell(155625),
})

Spell.Druid.Restoration = MergeTableByKey(Spell.Druid.Commons, {
  -- Abilities
  EclipseLunar                          = Spell(48518),
  EclipseSolar                          = Spell(48517),
  Efflorescence                         = Spell(145205),
  Lifebloom                             = MultiSpell(33763,188550),
  NaturesCure                           = Spell(88423),
  Revitalize                            = Spell(212040),
  Starfire                              = Spell(197628),
  Starsurge                             = Spell(197626),
  Wrath                                 = Spell(5176),
  -- Talents
  Abundance                             = Spell(207383),
  AdaptiveSwarm                         = Spell(391888),
  BalanceAffinity                       = Spell(197632),
  CenarionWard                          = Spell(102351),
  FeralAffinity                         = Spell(197490),
  Flourish                              = Spell(197721),
  IronBark                              = Spell(102342),
  NaturesSwiftness                      = Spell(132158),
  Reforestation                         = Spell(392356),
  SoulOfTheForest                       = Spell(158478),
  Tranquility                           = Spell(740),
  UnbridledSwarm                        = Spell(391951),
  Undergrowth                           = Spell(392301),
  -- Buffs
  AdaptiveSwarmHeal                     = Spell(391891),
  IncarnationBuff                       = Spell(117679),
  SoulOfTheForestBuff                   = Spell(114108),
  -- Debuffs
  AdaptiveSwarmDebuff                   = Spell(391889),
})

-- Items
if not Item.Druid then Item.Druid = {} end
Item.Druid.Commons = {
  -- Potion
  Healthstone                      = Item(5512),
}

Item.Druid.Balance = MergeTableByKey(Item.Druid.Commons, {
})

Item.Druid.Feral = MergeTableByKey(Item.Druid.Commons, {
})

Item.Druid.Restoration = MergeTableByKey(Item.Druid.Commons, {
})


-- Macros
if not Macro.Druid then Macro.Druid = {} end
Macro.Druid.Commons = {
  -- Base Spells
  InnervatePlayer                  = Macro("InnervatePlayer", "/cast [@player] " .. Spell.Druid.Commons.Innervate:Name()),
  MarkOfTheWildPlayer              = Macro("MarkOfTheWildPlayer", "/cast [@player] " .. Spell.Druid.Commons.MarkOfTheWild:Name()),
  MoonfireMouseover                = Macro("MoonfireMouseover", "/cast [@mouseover] " .. Spell.Druid.Commons.Moonfire:Name()),
  RakeMouseover                    = Macro("RakeMouseover", "/cast [@mouseover] " .. Spell.Druid.Commons.Rake:Name()),
  RipMouseover                     = Macro("RipMouseover", "/cast [@mouseover] " .. Spell.Druid.Commons.Rip:Name()),
  RebirthMouseover                 = Macro("RebirthMouseover", "/cast [@mouseover] " .. Spell.Druid.Commons.Rebirth:Name()),
  RegrowthFocus                    = Macro("RegrowthFocus", "/cast [@focus] " .. Spell.Druid.Commons.Regrowth:Name()),
  RejuvenationFocus                = Macro("RejuvenationFocus", "/cast [@focus] " .. Spell.Druid.Commons.Rejuvenation:Name()),
  RejuvenationMouseover            = Macro("RejuvenationMouseover", "/cast [@mouseover] " .. Spell.Druid.Commons.Rejuvenation:Name()),
  SunfireMouseover                 = Macro("SunfireMouseover", "/cast [@mouseover] " .. Spell.Druid.Commons.Sunfire:Name()),
  SwiftmendFocus                   = Macro("SwiftmendFocus", "/cast [@focus] " .. Spell.Druid.Commons.Swiftmend:Name()),
  SkullBashMouseover               = Macro("SkullBashMouseover", "/cast [@mouseover] " .. Spell.Druid.Commons.SkullBash:Name()),
  WildgrowthFocus                  = Macro("WildgrowthFocus", "/cast [@focus] " .. Spell.Druid.Commons.Wildgrowth:Name()),
  UrsolsVortexCursor               = Macro("UrsolsVortexCursor", "/cast [@cursor] " .. Spell.Druid.Commons.UrsolsVortex:Name()),
  -- Items
  Trinket1                         = Macro("Trinket1", "/use 13"),
  Trinket2                         = Macro("Trinket2", "/use 14"),
  Healthstone                      = Macro("Healthstone", "/use item:5512"),
}

Macro.Druid.Balance = MergeTableByKey(Macro.Druid.Commons, {
  StellarFlareMouseover            = Macro("StellarFlareMouseover", "/cast [@mouseover] " .. Spell.Druid.Balance.StellarFlare:Name()),
})

Macro.Druid.Feral = MergeTableByKey(Macro.Druid.Commons, {
  AdaptiveSwarmMouseover           = Macro("AdaptiveSwarmMouseover", "/cast [@mouseover] " .. Spell.Druid.Feral.AdaptiveSwarm:Name()),
  PrimalWrathMouseover             = Macro("PrimalWrathMouseover", "/cast [@mouseover] " .. Spell.Druid.Feral.PrimalWrath:Name()),
})

Macro.Druid.Restoration = MergeTableByKey(Macro.Druid.Commons, {
  -- Base Spells
  AdaptiveSwarmFocus               = Macro("AdaptiveSwarmFocus", "/cast [@focus] " .. Spell.Druid.Restoration.AdaptiveSwarm:Name()),
  CenarionWardFocus                = Macro("CenarionWardFocus", "/cast [@focus] " .. Spell.Druid.Restoration.CenarionWard:Name()),
  EfflorescenceCursor              = Macro("EfflorescenceCursor", "/cast [@cursor] " .. Spell.Druid.Restoration.Efflorescence:Name()),
  IronBarkFocus                    = Macro("IronBarkFocus", "/cast [@focus] " .. Spell.Druid.Restoration.IronBark:Name()),
  LifebloomFocus                   = Macro("LifebloomFocus", "/cast [@focus] " .. Spell.Druid.Restoration.Lifebloom:Name()),
  NaturesCureFocus                 = Macro("NaturesCureFocus", "/cast [@focus] " .. Spell.Druid.Restoration.NaturesCure:Name()),
  NaturesCureMouseover             = Macro("NaturesCureMouseover", "/cast [@mouseover] " .. Spell.Druid.Restoration.NaturesCure:Name()),
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
