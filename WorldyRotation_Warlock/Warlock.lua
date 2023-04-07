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
if not Spell.Warlock then Spell.Warlock = {} end
Spell.Warlock.Commons = {
  -- Racials
  Berserking                            = Spell(26297),
  BloodFury                             = Spell(33702),
  Fireblood                             = Spell(265221),
  -- Abilities
  Corruption                            = Spell(172),
  DarkPact                              = Spell(108416),
  ShadowBolt                            = Spell(686),
  SummonDarkglare                       = Spell(205180),
  UnendingResolve                       = Spell(104773),
  -- Talents
  GrimoireofSacrifice                   = Spell(108503),
  GrimoireofSacrificeBuff               = Spell(196099),
  SoulConduit                           = Spell(215941),
  SummonSoulkeeper                      = Spell(386256),
  InquisitorsGaze                       = Spell(386344),
  InquisitorsGazeBuff                   = Spell(388068),
  Soulburn                              = Spell(385899),
  -- Buffs
  PowerInfusionBuff                     = Spell(10060),
  -- Debuffs
  -- Command Demon Abilities
  AxeToss                               = Spell(119914),
  Seduction                             = Spell(119909),
  ShadowBulwark                         = Spell(119907),
  SingeMagic                            = Spell(119905),
  SpellLock                             = Spell(119910),
}

Spell.Warlock.Demonology = MergeTableByKey(Spell.Warlock.Commons, {
  -- Base Abilities
  Felstorm                              = Spell(89751),
  HandofGuldan                          = Spell(105174), -- Splash, 8
  SummonPet                             = Spell(30146),
  -- Talents
  BilescourgeBombers                    = Spell(267211), -- Splash, 8
  CallDreadstalkers                     = Spell(104316),
  Demonbolt                             = Spell(264178),
  DemonicCalling                        = Spell(205145),
  DemonicStrength                       = Spell(267171),
  Doom                                  = Spell(603),
  FelDomination                         = Spell(333889),
  FelCovenant                           = Spell(387432),
  FromtheShadows                        = Spell(267170),
  GrimoireFelguard                      = Spell(111898),
  Guillotine                            = Spell(386833),
  ImpGangBoss                           = Spell(387445),
  Implosion                             = Spell(196277), -- Splash, 8
  InnerDemons                           = Spell(267216),
  NetherPortal                          = Spell(267217),
  PowerSiphon                           = Spell(264130),
  SacrificedSouls                       = Spell(267214),
  SoulboundTyrant                       = Spell(334585),
  SoulStrike                            = Spell(264057),
  SummonDemonicTyrant                   = Spell(265187),
  SummonVilefiend                       = Spell(264119),
  TheExpendables                        = Spell(387600),
  -- Buffs
  DemonicCallingBuff                    = Spell(205146),
  DemonicCoreBuff                       = Spell(264173),
  DemonicPowerBuff                      = Spell(265273),
  FelCovenantBuff                       = Spell(387437),
  NetherPortalBuff                      = Spell(267218),
  -- Debuffs
  DoomDebuff                            = Spell(603),
  FromtheShadowsDebuff                  = Spell(270569),
})

Spell.Warlock.Affliction = MergeTableByKey(Spell.Warlock.Commons, {
  -- Base Abilities
  Agony                                 = Spell(980),
  DrainLife                             = Spell(234153),
  SummonPet                             = Spell(688),
  -- Talents
  AbsoluteCorruption                    = Spell(196103),
  DrainSoul                             = Spell(198590),
  DreadTouch                            = Spell(389775),
  Haunt                                 = Spell(48181),
  InevitableDemise                      = Spell(334319),
  MaleficAffliction                     = Spell(389761),
  MaleficRapture                        = Spell(324536),
  Nightfall                             = Spell(108558),
  PhantomSingularity                    = Spell(205179),
  SowTheSeeds                           = Spell(196226),
  SeedofCorruption                      = Spell(27243),
  ShadowEmbrace                         = Spell(27243),
  SiphonLife                            = Spell(63106),
  SoulRot                               = Spell(386997),
  SoulSwap                              = Spell(386951),
  SoulTap                               = Spell(387073),
  SouleatersGluttony                    = Spell(389630),
  SowtheSeeds                           = Spell(196226),
  TormentedCrescendo                    = Spell(387075),
  UnstableAffliction                    = Spell(316099),
  VileTaint                             = Spell(278350),
  -- Buffs
  InevitableDemiseBuff                  = Spell(334320),
  NightfallBuff                         = Spell(264571),
  MaleficAfflictionBuff                 = Spell(389845),
  TormentedCrescendoBuff                = Spell(387079),
  -- Debuffs
  AgonyDebuff                           = Spell(980),
  CorruptionDebuff                      = Spell(146739),
  HauntDebuff                           = Spell(48181),
  PhantomSingularityDebuff              = Spell(205179),
  SeedofCorruptionDebuff                = Spell(27243),
  SiphonLifeDebuff                      = Spell(63106),
  UnstableAfflictionDebuff              = Spell(316099),
  VileTaintDebuff                       = Spell(278350),
  SoulRotDebuff                         = Spell(386997),
  DreadTouchDebuff                      = Spell(389868),
  ShadowEmbraceDebuff                   = Spell(32390),
})

Spell.Warlock.Destruction = MergeTableByKey(Spell.Warlock.Commons, {
  -- Base Abilities
  Immolate                              = Spell(348),
  Incinerate                            = Spell(29722),
  SummonPet                             = Spell(688),
  -- Talents
  AshenRemains                          = Spell(387252),
  AvatarofDestruction                   = Spell(387159),
  Backdraft                             = Spell(196406),
  BurntoAshes                           = Spell(387153),
  Cataclysm                             = Spell(152108),
  ChannelDemonfire                      = Spell(196447),
  ChaosBolt                             = Spell(116858),
  Conflagrate                           = Spell(17962),
  CryHavoc                              = Spell(387522),
  DiabolicEmbers                        = Spell(387173),
  DimensionalRift                       = Spell(387976),
  Eradication                           = Spell(196412),
  FireandBrimstone                      = Spell(196408),
  Havoc                                 = Spell(80240),
  Inferno                               = Spell(270545),
  InternalCombustion                    = Spell(266134),
  MadnessoftheAzjAqir                   = Spell(387400),
  Mayhem                                = Spell(387506),
  RagingDemonfire                       = Spell(387166),
  RainofChaos                           = Spell(266086),
  RainofFire                            = Spell(5740),
  RoaringBlaze                          = Spell(205184),
  Ruin                                  = Spell(387103),
  SoulFire                              = Spell(6353),
  SummonInfernal                        = Spell(1122),
  -- Buffs
  BackdraftBuff                         = Spell(117828),
  MadnessCBBuff                         = Spell(387409),
  RainofChaosBuff                       = Spell(266087),
  RitualofRuinBuff                      = Spell(387157),
  BurntoAshesBuff                       = Spell(387154),
  -- Debuffs
  EradicationDebuff                     = Spell(196414),
  HavocDebuff                           = Spell(80240),
  ImmolateDebuff                        = Spell(157736),
  RoaringBlazeDebuff                    = Spell(265931),
})

-- Items
if not Item.Warlock then Item.Warlock = {} end
Item.Warlock.Commons = {
  -- Potions
  Healthstone                           = Item(5512),
  -- Trinkets
  ConjuredChillglobe                    = Item(194300, {13, 14}),
  DesperateInvokersCodex                = Item(194310, {13, 14}),
  TimebreachingTalon                    = Item(193791, {13, 14}),
}

Item.Warlock.Affliction = MergeTableByKey(Item.Warlock.Commons, {
})

Item.Warlock.Demonology = MergeTableByKey(Item.Warlock.Commons, {
})

Item.Warlock.Destruction = MergeTableByKey(Item.Warlock.Commons, {
})

-- Macros
if not Macro.Warlock then Macro.Warlock = {}; end
Macro.Warlock.Commons = {
  -- Items
  Trinket1                              = Macro("Trinket1", "/use 13"),
  Trinket2                              = Macro("Trinket2", "/use 14"),
  Healthstone                           = Macro("Healthstone", "/use item:5512"),
  ConjuredChillglobe                    = Macro("ConjuredChillglobe", "/use item:194300"),
  DesperateInvokersCodex                = Macro("DesperateInvokersCodex", "/use item:194310"),
  TimebreachingTalon                    = Macro("TimebreachingTalon", "/use item:193791"),
  -- Spells
  AxeTossMouseover                      = Macro("AxeTossMouseover", "/cast [@mouseover] " .. Spell.Warlock.Commons.AxeToss:Name()),
  CorruptionMouseover                   = Macro("CorruptionMouseover", "/cast [@mouseover] " .. Spell.Warlock.Commons.Corruption:Name()),
  SpellLockMouseover                    = Macro("SpellLockMouseover", "/cast [@mouseover] " .. Spell.Warlock.Commons.SpellLock:Name()),
  ShadowBoltPetAttack                   = Macro("ShadowBoltPetAttack", "/cast " .. Spell.Warlock.Commons.ShadowBolt:Name() .. "\n/petattack"),
}

Macro.Warlock.Affliction = MergeTableByKey(Macro.Warlock.Commons, {
  AgonyMouseover                        = Macro("AgonyMouseover", "/cast [@mouseover] " .. Spell.Warlock.Affliction.Agony:Name()),
  VileTaintCursor                       = Macro("VileTaintCursor", "/cast [@cursor] " .. Spell.Warlock.Affliction.VileTaint:Name()),
})

Macro.Warlock.Demonology = MergeTableByKey(Macro.Warlock.Commons, {
  DemonboltPetAttack                    = Macro("DemonboltPetAttack", "/cast " .. Spell.Warlock.Demonology.Demonbolt:Name() .. "\n/petattack"),
  DoomMouseover                         = Macro("DoomMouseover", "/cast [@mouseover] " .. Spell.Warlock.Demonology.Doom:Name()),
  GuillotineCursor                      = Macro("GuillotineCursor", "/cast [@cursor] " .. Spell.Warlock.Demonology.Guillotine:Name()),
})

Macro.Warlock.Destruction = MergeTableByKey(Macro.Warlock.Commons, {
  HavocMouseover                        = Macro("HavocMouseover", "/cast [@mouseover] " .. Spell.Warlock.Destruction.Havoc:Name()),
  ImmolateMouseover                     = Macro("ImmolateMouseover", "/cast [@mouseover] " .. Spell.Warlock.Destruction.Immolate:Name()),
  ImmolatePetAttack                     = Macro("ImmolatePetAttack", "/cast " .. Spell.Warlock.Destruction.Immolate:Name() .. "\n/petattack"),
  RainofFireCursor                      = Macro("RainofFireCursor", "/cast [@cursor] " .. Spell.Warlock.Destruction.RainofFire:Name()),
  SummonInfernalCursor                  = Macro("SummonInfernalCursor", "/cast [@cursor] " .. Spell.Warlock.Destruction.SummonInfernal:Name()),
})