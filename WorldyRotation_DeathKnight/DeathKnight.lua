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
if not Spell.DeathKnight then Spell.DeathKnight = {} end
Spell.DeathKnight.Commons = {
  -- Abilities
  DeathAndDecay                         = Spell(43265),
  DeathStrike                           = Spell(49998),
  RaiseDead                             = Spell(46585), -- Blood and Frost, but not Unholy
  SacrificialPact                       = Spell(327574),
  -- Talents
  Asphyxiate                            = Spell(108194), -- Frost and Unholy, but not Blood
  -- Covenant Abilities
  AbominationLimb                       = Spell(315443),
  AbominationLimbBuff                   = Spell(315443),
  DeathsDue                             = Spell(324128),
  Fleshcraft                            = Spell(324631),
  ShackleTheUnworthy                    = Spell(312202),
  SwarmingMist                          = Spell(311648),
  SwarmingMistBuff                      = Spell(311648),
  -- Conduit Effects
  BitingCold                            = Spell(337988),
  ConvocationOfTheDead                  = Spell(338553),
  EradicatingBlow                       = Spell(337934),
  Everfrost                             = Spell(337988),
  FrenziedMonstrosity                   = Spell(334896),
  KevinsOozeling                        = Spell(352110),
  LeadByExample                         = Spell(342156),
  MarrowedGemstoneEnhancement           = Spell(327069),
  PustuleEruption                       = Spell(351094),
  ThrillSeeker                          = Spell(331939),
  UnleashedFrenzy                       = Spell(338492),
  VolatileSolvent                       = Spell(323074),
  VolatileSolventHumanBuff              = Spell(323491),
  WitheringGround                       = Spell(341344),
  -- Domination Shards
  ChaosBaneBuff                         = Spell(355829),
  -- Buffs
  DeathAndDecayBuff                     = Spell(188290),
  DeathStrikeBuff                       = Spell(101568), -- Frost and Unholy, but not Blood
  DeathsDueBuff                         = Spell(324165),
  EndlessRuneWaltzBuff                  = Spell(366008), -- Tier 28 2pc bonus
  UnholyStrengthBuff                    = Spell(53365),
  -- Debuffs
  BloodPlagueDebuff                     = Spell(55078),
  FrostFeverDebuff                      = Spell(55095),
  -- Racials
  AncestralCall                         = Spell(274738),
  ArcanePulse                           = Spell(260364),
  ArcaneTorrent                         = Spell(50613),
  BagofTricks                           = Spell(312411),
  Berserking                            = Spell(26297),
  BloodFury                             = Spell(20572),
  Fireblood                             = Spell(265221),
  LightsJudgment                        = Spell(255647),
  -- Interrupts
  MindFreeze                            = Spell(47528),
  -- Custom
  Pool                                  = Spell(999910)
}

Spell.DeathKnight.Blood = MergeTableByKey(Spell.DeathKnight.Commons, {
  -- Abilities
  Asphyxiate                            = Spell(221562),
  BloodBoil                             = Spell(50842),
  DancingRuneWeapon                     = Spell(49028),
  DeathsCaress                          = Spell(195292),
  HeartStrike                           = Spell(206930),
  IceboundFortitude                     = Spell(48792),
  Marrowrend                            = Spell(195182),
  RuneTap                               = Spell(194679),
  VampiricBlood                         = Spell(55233),
  -- Talents
  Blooddrinker                          = Spell(206931),
  BloodTap                              = Spell(221699),
  Bonestorm                             = Spell(194844),
  Consumption                           = Spell(274156),
  Heartbreaker                          = Spell(221536),
  RapidDecomposition                    = Spell(194662),
  RelishinBlood                         = Spell(317610),
  Tombstone                             = Spell(219809),
  -- Buffs
  BoneShieldBuff                        = Spell(195181),
  CrimsonScourgeBuff                    = Spell(81141),
  DancingRuneWeaponBuff                 = Spell(81256),
  HemostasisBuff                        = Spell(273947),
  IceboundFortitudeBuff                 = Spell(48792),
  RuneTapBuff                           = Spell(194679),
  VampiricBloodBuff                     = Spell(55233)
})

-- Items
if not Item.DeathKnight then Item.DeathKnight = {} end
Item.DeathKnight.Commons = {
  -- Potions
  Healthstone                           = Item(5512),
  PotionofSpectralStrength              = Item(171275),
  -- Covenant
  PhialofSerenity                       = Item(177278),
  -- Trinkets
  InscrutableQuantumDevice              = Item(179350, {13, 14}),
  OverwhelmingPowerCrystal              = Item(179342, {13, 14}),
  ScarsofFraternalStrife                = Item(188253, {13, 14}),
  TheFirstSigil                         = Item(188271, {13, 14}),
  -- Other On-Use Items
  GaveloftheFirstArbiter                = Item(189862),
}

Item.DeathKnight.Blood = MergeTableByKey(Item.DeathKnight.Commons, {
})

-- Macros
if not Macro.DeathKnight then Macro.DeathKnight = {} end
Macro.DeathKnight.Commons = {
  -- Base Spells
  DeathAndDecayPlayer              = Macro("DeathAndDecayPlayer", "/cast [@player] " .. Spell.DeathKnight.Commons.DeathAndDecay:Name()),
}

Macro.DeathKnight.Blood = MergeTableByKey(Macro.DeathKnight.Commons, {
  -- Items
  Trinket1                         = Macro("Trinket1", "/use 13"),
  Trinket2                         = Macro("Trinket2", "/use 14"),
  Healthstone                      = Macro("Healthstone", "/use " .. Item.DeathKnight.Commons.Healthstone:Name()),
  PhialofSerenity                  = Macro("PhialofSerenity", "/use " .. Item.DeathKnight.Commons.PhialofSerenity:Name()),
  PotionofSpectralStrength         = Macro("PotionofSpectralStrength", "/use " .. Item.DeathKnight.Commons.PotionofSpectralStrength:Name()),
})
