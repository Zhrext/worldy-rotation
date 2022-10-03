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

--- ============================ CONTENT ============================

-- Spell
if not Spell.Monk then Spell.Monk = {}; end
Spell.Monk.Commons = {
  -- Racials
  AncestralCall                         = Spell(274738),
  ArcaneTorrent                         = Spell(25046),
  BagOfTricks                           = Spell(312411),
  Berserking                            = Spell(26297),
  BloodFury                             = Spell(20572),
  GiftoftheNaaru                        = Spell(59547),
  Fireblood                             = Spell(265221),
  LightsJudgment                        = Spell(255647),
  QuakingPalm                           = Spell(107079),
  Shadowmeld                            = Spell(58984),
  -- Abilities
  CracklingJadeLightning                = Spell(117952),
  ExpelHarm                             = Spell(322101),
  RisingSunKick                         = Spell(107428),
  TigerPalm                             = Spell(100780),
  TouchOfDeath                          = Spell(322109),
  -- Talents
  Celerity                              = Spell(115173),
  ChiBurst                              = Spell(123986),
  ChiWave                               = Spell(115098),
  EyeOfTheTiger                         = Spell(196607),
  GoodKarma                             = Spell(280195),
  InnerStrengthBuff                     = Spell(261769),
  RushingJadeWind                       = Spell(116847),
  RushingJadeWindBuff                   = Spell(116847),
  -- Talents
  ChiTorpedo                            = Spell(115008),
  DampenHarm                            = Spell(122278),
  DampenHarmBuff                        = Spell(122278),
  DiffuseMagic                          = Spell(122783),
  EnergizingElixir                      = Spell(115288),
  HealingElixir                         = Spell(122281),
  LegSweep                              = Spell(119381),
  RingOfPeace                           = Spell(116844),
  TigersLust                            = Spell(116841),
  TigerTailSweep                        = Spell(264348),
  -- Utility
  Detox                                 = Spell(218164),
  Disable                               = Spell(116095),
  Paralysis                             = Spell(115078),
  Provoke                               = Spell(115546),
  Resuscitate                           = Spell(115178),
  Roll                                  = Spell(109132),
  SpearHandStrike                       = Spell(116705),
  Transcendence                         = Spell(101643),
  TranscendenceTransfer                 = Spell(119996),
  Vivify                                = Spell(116670),
  -- Covenant Abilities (Shadowlands)
  BonedustBrew                          = Spell(325216),
  FaelineStomp                          = Spell(327104),
  FaelineStompBuff                      = Spell(347480),
  FaelineStompDebuff                    = Spell(327257),
  FallenOrder                           = Spell(326860),
  Fleshcraft                            = Spell(324631),
  WeaponsOfOrder                        = Spell(310454),
  WeaponsOfOrderChiBuff                 = Spell(311054),
  WeaponsOfOrderDebuff                  = Spell(312106),
  -- Soulbinds (Shadowlands)
  CarversEye                            = Spell(350899),
  CarversEyeBuff                        = Spell(351414),
  FirstStrike                           = Spell(325069),
  FirstStrikeBuff                       = Spell(325381),
  GroveInvigoration                     = Spell(322721),
  LeadByExample                         = Spell(342156),
  PustuleEruption                       = Spell(351094),
  VolatileSolvent                       = Spell(323074),
  -- Conduits (Shadowlands)
  FortifyingIngrediencesBuff            = Spell(336874),
  -- Legendary Effects (Shadowlands)
  ChiEnergyBuff                         = Spell(337571),
  InvokersDelight                       = Spell(338321),
  RecentlyRushingTigerPalm              = Spell(337341),
  SkyreachExhaustion                    = Spell(337341),
  TheEmperorsCapacitor                  = Spell(337291),
  -- Trinket Effects
  AcquiredAxeBuff                       = Spell(368656),
  AcquiredWandBuff                      = Spell(368654),
  ScarsofFraternalStrifeBuff4           = Spell(368638),
  TemptationBuff                        = Spell(234143),
  -- Misc
  PoolEnergy                            = Spell(999910),
  StopFoF                               = Spell(363653)
}

Spell.Monk.Brewmaster = MergeTableByKey(Spell.Monk.Commons, {
  -- Abilities
  BlackoutKick                          = Spell(205523),
  BreathOfFire                          = Spell(115181),
  Clash                                 = Spell(324312),
  InvokeNiuzaoTheBlackOx                = Spell(132578),
  KegSmash                              = Spell(121253),
  SpinningCraneKick                     = Spell(322729),
  -- Debuffs
  BreathOfFireDotDebuff                 = Spell(123725),
  -- Talents
  BlackoutCombo                         = Spell(196736),
  BlackoutComboBuff                     = Spell(228563),
  BlackOxBrew                           = Spell(115399),
  BobAndWeave                           = Spell(280515),
  CelestialFlames                       = Spell(325177),
  ExplodingKeg                          = Spell(325153),
  HighTolerance                         = Spell(196737),
  LightBrewing                          = Spell(325093),
  SpecialDelivery                       = Spell(196730),
  Spitfire                              = Spell(242580),
  SummonBlackOxStatue                   = Spell(115315),
  -- Defensive
  CelestialBrew                         = Spell(322507),
  ElusiveBrawlerBuff                    = Spell(195630),
  FortifyingBrew                        = Spell(115203),
  FortifyingBrewBuff                    = Spell(115203),
  PurifyingBrew                         = Spell(119582),
  PurifiedChiBuff                       = Spell(325092),
  Shuffle                               = Spell(215479),
  -- Legendary Effects (Shadowlands)
  CharredPassions                       = Spell(338140),
  MightyPour                            = Spell(337994),
  -- Stagger Levels
  HeavyStagger                          = Spell(124273),
  ModerateStagger                       = Spell(124274),
  LightStagger                          = Spell(124275),
})

-- Items
if not Item.Monk then Item.Monk = {}; end
Item.Monk.Commons = {
}

Item.Monk.Windwalker = MergeTableByKey(Item.Monk.Commons, {
})

Item.Monk.Brewmaster = MergeTableByKey(Item.Monk.Commons, {
})

Item.Monk.Mistweaver = MergeTableByKey(Item.Monk.Commons, {
})
