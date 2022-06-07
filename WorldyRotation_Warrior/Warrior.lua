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
if not Spell.Warrior then Spell.Warrior = {} end
Spell.Warrior.Commons = {
  -- Racials
  AncestralCall                         = Spell(274738),
  ArcaneTorrent                         = Spell(50613),
  BagofTricks                           = Spell(312411),
  Berserking                            = Spell(26297),
  BloodFury                             = Spell(20572),
  Fireblood                             = Spell(265221),
  LightsJudgment                        = Spell(255647),
  -- Abilities
  BattleShout                           = Spell(6673),
  BattleShoutBuff                       = Spell(6673),
  Charge                                = Spell(100),
  IntimidatingShout                     = Spell(5246),
  HeroicLeap                            = Spell(6544),
  Pummel                                = Spell(6552),
  VictoryRush                           = Spell(34428),
  -- Talents
  AngerManagement                       = Spell(152278),
  Avatar                                = Spell(107574),
  AvatarBuff                            = Spell(107574),
  DragonRoar                            = Spell(118000),
  ImpendingVictory                      = Spell(202168),
  StormBolt                             = Spell(107570),
  -- Covenant Abilities (Shadowlands)
  AncientAftershock                     = Spell(325886),
  Condemn                               = Spell(330325),
  CondemnDebuff                         = Spell(317491),
  ConquerorsBanner                      = Spell(324143),
  ConquerorsFrenzyBuff                  = Spell(343672),
  Fleshcraft                            = Spell(324631),
  SpearofBastion                        = Spell(307865),
  SpearofBastionBuff                    = Spell(307871),
  -- Conduits (Shadowlands)
  MercilessBonegrinder                  = Spell(335260),
  MercilessBonegrinderBuff              = Spell(346574),
  -- Pool
  Pool                                  = Spell(999910),
}

Spell.Warrior.Fury = MergeTableByKey(Spell.Warrior.Commons, {
  -- Abilities
  Bloodbath                             = Spell(335096),
  Bloodthirst                           = Spell(23881),
  CrushingBlow                          = Spell(335097),
  EnrageBuff                            = Spell(184362),
  Execute                               = Spell(5308),
  MeatCleaverBuff                       = Spell(85739),
  RagingBlow                            = Spell(85288),
  Rampage                               = Spell(184367),
  Recklessness                          = Spell(1719),
  RecklessnessBuff                      = Spell(1719),
  Whirlwind                             = Spell(190411),
  -- Talents
  Bladestorm                            = Spell(46924),
  Cruelty                               = Spell(335070),
  Frenzy                                = Spell(335077),
  FrenzyBuff                            = Spell(335077),
  FrothingBerserker                     = Spell(215571),
  Massacre                              = Spell(206315),
  Onslaught                             = Spell(315720),
  RecklessAbandon                       = Spell(202751),
  Siegebreaker                          = Spell(280772),
  SiegebreakerDebuff                    = Spell(280773),
  SuddenDeath                           = Spell(280721),
  SuddenDeathBuff                       = Spell(280776),
  -- Conduits (Shadowlands)
  ViciousContempt                       = Spell(337302),
  -- Legendary Effects (Shadowlands)
  WilloftheBerserkerBuff                = Spell(335594),
})

Spell.Warrior.Arms = MergeTableByKey(Spell.Warrior.Commons, {
  -- Abilities
  Bladestorm                            = Spell(227847),
  ColossusSmash                         = Spell(167105),
  ColossusSmashDebuff                   = Spell(208086),
  DeepWoundsDebuff                      = Spell(262115),
  Execute                               = Spell(163201),
  MortalStrike                          = Spell(12294),
  Overpower                             = Spell(7384),
  OverpowerBuff                         = Spell(7384),
  Slam                                  = Spell(1464),
  SweepingStrikes                       = Spell(260708),
  SweepingStrikesBuff                   = Spell(260708),
  Whirlwind                             = Spell(1680),
  -- Talents
  Cleave                                = Spell(845),
  CollateralDamage                      = Spell(334779),
  DeadlyCalm                            = Spell(262228),
  DeadlyCalmBuff                        = Spell(262228),
  Doubletime                            = Spell(103827),
  Dreadnaught                           = Spell(262150),
  FervorofBattle                        = Spell(202316),
  InfortheKill                          = Spell(248621),
  Massacre                              = Spell(281001),
  Ravager                               = Spell(152277),
  Rend                                  = Spell(772),
  RendDebuff                            = Spell(772),
  Skullsplitter                         = Spell(260643),
  SuddenDeathBuff                       = Spell(52437),
  Warbreaker                            = Spell(262161),
  WarMachineBuff                        = Spell(262231),
  -- Conduits (Shadowlands)
  AshenJuggernaut                       = Spell(335232),
  AshenJuggernautBuff                   = Spell(335234),
  BattlelordBuff                        = Spell(346369),
  ExploiterDebuff                       = Spell(335452),
})

Spell.Warrior.Protection = MergeTableByKey(Spell.Warrior.Commons, {
  -- Abilities
  DemoralizingShout                     = Spell(1160),
  Devastate                             = Spell(20243),
  Execute                               = Spell(163201),
  IgnorePain                            = Spell(190456),
  Intervene                             = Spell(3411),
  LastStand                             = Spell(12975),
  LastStandBuff                         = Spell(12975),
  Revenge                               = Spell(6572),
  RevengeBuff                           = Spell(5302),
  ShieldBlock                           = Spell(2565),
  ShieldBlockBuff                       = Spell(132404),
  ShieldSlam                            = Spell(23922),
  ThunderClap                           = Spell(6343),
  -- Talents
  BoomingVoice                          = Spell(202743),
  Ravager                               = Spell(228920),
  UnstoppableForce                      = Spell(275336),
  -- Tier Effects
  OutburstBuff                          = Spell(364010),
  SeeingRedBuff                         = Spell(364006),
})

-- Items
if not Item.Warrior then Item.Warrior = {} end
Item.Warrior.Commons = {
  -- Potions
  Healthstone                           = Item(5512),
  PotionofPhantomFire                   = Item(171349),
  PotionofSpectralStrength              = Item(171275),
  -- Covenant
  PhialofSerenity                       = Item(177278),
  -- Trinkets
  DDVoracity                            = Item(173087, {13, 14}),
  FlameofBattle                         = Item(181501, {13, 14}),
  GrimCodex                             = Item(178811, {13, 14}),
  InscrutableQuantumDevice              = Item(179350, {13, 14}),
  InstructorsDivineBell                 = Item(184842, {13, 14}),
  MacabreSheetMusic                     = Item(184024, {13, 14}),
  OverwhelmingPowerCrystal              = Item(179342, {13, 14}),
  WakenersFrond                         = Item(181457, {13, 14}),
  -- Gladiator's Badges
  SinfulGladiatorsBadge                 = Item(175921, {13, 14}),
  UnchainedGladiatorsBadge              = Item(185197, {13, 14}),
}

Item.Warrior.Fury = MergeTableByKey(Item.Warrior.Commons, {
})

Item.Warrior.Arms = MergeTableByKey(Item.Warrior.Commons, {
})

Item.Warrior.Protection = MergeTableByKey(Item.Warrior.Commons, {
})

-- Macros
if not Macro.Warrior then Macro.Warrior = {} end
Macro.Warrior.Commons = {
  -- Basic Spells
  HeroicLeapCursor                 = Macro("HeroicLeapCursor", "/cast [@cursor] " .. Spell.Warrior.Commons.HeroicLeap:Name()),
  -- Covenant
  SpearofBastionPlayer             = Macro("SpearofBastionPlayer", "/cast [@player] " .. Spell.Warrior.Commons.SpearofBastion:Name()),
  -- Items
  Trinket1                         = Macro("Trinket1", "/use 13"),
  Trinket2                         = Macro("Trinket2", "/use 14"),
  Healthstone                      = Macro("Healthstone", "/use " .. Item.Warrior.Commons.Healthstone:Name()),
  PotionofSpectralStrength         = Macro("PotionofSpectralStrength", "/use " .. Item.Warrior.Commons.PotionofSpectralStrength:Name()),
  PhialofSerenity                  = Macro("PhialofSerenity", "/use " .. Item.Warrior.Commons.PhialofSerenity:Name()),
}

Macro.Warrior.Fury = MergeTableByKey(Macro.Warrior.Commons, {
})

Macro.Warrior.Arms = MergeTableByKey(Macro.Warrior.Commons, {
})

Macro.Warrior.Protection = MergeTableByKey(Macro.Warrior.Commons, {
  RavagerPlayer                    = Macro("RavagerPlayer", "/cast [@player] " .. Spell.Warrior.Protection.Ravager:Name()),
})
