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
if not Spell.Monk then Spell.Monk = {}; end
Spell.Monk.Commons = {
  -- Racials
  AncestralCall                         = Spell(274738),
  ArcaneTorrent                         = Spell(25046),
  BagofTricks                           = Spell(312411),
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
  LegSweep                              = Spell(119381),
  Provoke                               = Spell(115546),
  Resuscitate                           = Spell(115178),
  RisingSunKick                         = Spell(107428),
  Roll                                  = Spell(109132),
  TigerPalm                             = Spell(100780),
  TouchofDeath                          = Spell(322109),
  Transcendence                         = Spell(101643),
  TranscendenceTransfer                 = Spell(119996),
  Vivify                                = Spell(116670),
  -- Talents
  BonedustBrew                          = Spell(386276),
  Celerity                              = Spell(115173),
  ChiBurst                              = Spell(123986),
  ChiTorpedo                            = Spell(115008),
  ChiWave                               = Spell(115098),
  DampenHarm                            = Spell(122278),
  Detox                                 = Spell(218164),
  Disable                               = Spell(116095),
  DiffuseMagic                          = Spell(122783),
  EyeoftheTiger                         = Spell(196607),
  InnerStrengthBuff                     = Spell(261769),
  Paralysis                             = Spell(115078),
  RingOfPeace                           = Spell(116844),
  RushingJadeWind                       = Spell(116847),
  SpearHandStrike                       = Spell(116705),
  SummonWhiteTigerStatue                = Spell(388686),
  TigerTailSweep                        = Spell(264348),
  TigersLust                            = Spell(116841),
  -- Buffs
  BonedustBrewBuff                      = Spell(386276),
  DampenHarmBuff                        = Spell(122278),
  RushingJadeWindBuff                   = Spell(116847),
  -- Debuffs
  -- Item Effects
  TheEmperorsCapacitorBuff              = Spell(235054),
  -- Misc
  PoolEnergy                            = Spell(999910),
  StopFoF                               = Spell(363653)
}

Spell.Monk.Windwalker = MergeTableByKey(Spell.Monk.Commons, {
  -- Abilities
  BlackoutKick                          = Spell(100784),
  FlyingSerpentKick                     = Spell(101545),
  FlyingSerpentKickLand                 = Spell(115057),
  SpinningCraneKick                     = Spell(101546),
  -- Talents
  BonedustBrew                          = Spell(386276),
  CraneVortex                           = Spell(388848),
  FastFeet                              = Spell(388809),
  FaelineHarmony                        = Spell(391412),
  FaelineStomp                          = Spell(388193),
  FistsofFury                           = Spell(113656),
  HitCombo                              = Spell(196740),
  InvokeXuenTheWhiteTiger               = Spell(123904),
  MarkoftheCrane                        = Spell(220357),
  Serenity                              = Spell(152173),
  ShadowboxingTreads                    = Spell(392982),
  StormEarthAndFire                     = Spell(137639),
  StormEarthAndFireFixate               = Spell(221771),
  StrikeoftheWindlord                   = Spell(392983),
  TeachingsoftheMonastery               = Spell(116645),
  Thunderfist                           = Spell(392985),
  WhirlingDragonPunch                   = Spell(152175),
  XuensBattlegear                       = Spell(392993),
  -- Defensive
  FortifyingBrew                        = Spell(243435),
  TouchofKarma                          = Spell(122470),
  -- Buffs
  BlackoutKickBuff                      = Spell(116768),
  ChiEnergyBuff                         = Spell(393057),    
  DanceofChijiBuff                      = Spell(325202),
  HitComboBuff                          = Spell(196741),
  PowerStrikesBuff                      = Spell(129914),
  SerenityBuff                          = Spell(152173),
  StormEarthAndFireBuff                 = Spell(137639),
  TeachingsoftheMonasteryBuff           = Spell(202090),
  WhirlingDragonPunchBuff               = Spell(196742),
  -- Debuffs
  MarkoftheCraneDebuff                  = Spell(228287),
  SkyreachExhaustionDebuff              = Spell(393050),
  -- Tier 29 Effects
  KicksofFlowingMomentumBuff            = Spell(394944),
  FistsofFlowingMomentumBuff            = Spell(394949),
})

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
  WeaponsOfOrder                        = Spell(387184),
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

Spell.Monk.Mistweaver = MergeTableByKey(Spell.Monk.Commons, {
  -- Abilities
  BlackoutKick                          = Spell(100784),
  EnvelopingMist                        = Spell(124682),
  EssenceFont                           = Spell(191837),
  EssenceFontBuff                       = Spell(191840),
  InvokeYulonTheJadeSerpent             = Spell(123904),
  LifeCocoon                            = Spell(116849),
  RenewingMist                          = Spell(115151),
  Revival                               = Spell(115310),
  SoothingMist                          = Spell(115175),
  SpinningCraneKick                     = Spell(101546),
  TeachingsOfTheMonasteryBuff           = Spell(202090),
  ThunderFocusTea                       = Spell(116680),
  -- Talents
  InvokeChiJiTheRedCrane                = Spell(325197),
  LifecyclesEnvelopingMistBuff          = Spell(197919),
  LifecyclesVivifyBuff                  = Spell(197916),
  ManaTea                               = Spell(197908),
  RefreshingJadeWind                    = Spell(196725),
  SongOfChiJi                           = Spell(198898),
  SummonJadeSerpentStatue               = Spell(115313),
  -- Defensive
  FortifyingBrew                        = Spell(243435),
  -- Utility
  Reawaken                              = Spell(212051),
})

-- Items
if not Item.Monk then Item.Monk = {}; end
Item.Monk.Commons = {
  -- Potions
  Healthstone                           = Item(5512),
  --Trinkets
  AlgetharPuzzleBox                     = Item(193701, {13, 14}),
}

Item.Monk.Windwalker = MergeTableByKey(Item.Monk.Commons, {
})

Item.Monk.Brewmaster = MergeTableByKey(Item.Monk.Commons, {
})

Item.Monk.Mistweaver = MergeTableByKey(Item.Monk.Commons, {
})

-- Macro
if not Macro.Monk then Macro.Monk = {}; end
Macro.Monk.Commons = {
  -- Items
  Trinket1                         = Macro("Trinket1", "/use 13"),
  Trinket2                         = Macro("Trinket2", "/use 14"),
  Healthstone                      = Macro("Healthstone", "/use item:5512"),
  AlgetharPuzzleBox                = Macro("AlgetharPuzzleBox", "/use item:193701"),
  -- Spells
  BoneDustBrewPlayer               = Macro("BoneDustBrewPlayer", "/cast [@player] " .. Spell.Monk.Commons.BonedustBrew:Name()),
  DetoxMouseover                   = Macro("DetoxMouseover", "/cast [@mouseover] " .. Spell.Monk.Commons.Detox:Name()),
  RingOfPeaceCursor                = Macro("RingOfPeaceCursor", "/cast [@cursor] " .. Spell.Monk.Commons.RingOfPeace:Name()),
  SpearHandStrikeMouseover         = Macro("SpearHandStrikeMouseover", "/cast [@mouseover] " .. Spell.Monk.Commons.SpearHandStrike:Name()),
  SummonWhiteTigerStatuePlayer     = Macro("SummonWhiteTigerStatuePlayer", "/cast [@player] " .. Spell.Monk.Commons.SummonWhiteTigerStatue:Name()),
  TigerPalmMouseover               = Macro("TigerPalmMouseover", "/cast [@mouseover] " .. Spell.Monk.Commons.TigerPalm:Name()),
}

Macro.Monk.Windwalker = MergeTableByKey(Macro.Monk.Commons, {
  SummonWhiteTigerStatueM                      = Macro("SummonWhiteTigerStatue", "/cast [@player] Summon White Tiger Statue"),
  BonedustBrewM                                = Macro("BoneDustBrew", "/cast [@player] Bonedust Brew"),
})

Macro.Monk.Brewmaster = MergeTableByKey(Macro.Monk.Commons, {
  ExplodingKegPlayer               = Macro("ExplodingKegPlayer", "/cast [@player] " .. Spell.Monk.Brewmaster.ExplodingKeg:Name()),
})

Macro.Monk.Mistweaver = MergeTableByKey(Macro.Monk.Commons, {
})
