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
if not Spell.Hunter then Spell.Hunter = {}; end
Spell.Hunter.Commons = {
  -- Racials
  AncestralCall                         = Spell(274738),
  ArcanePulse                           = Spell(260364),
  ArcaneTorrent                         = Spell(50613),
  BagofTricks                           = Spell(312411),
  Berserking                            = Spell(26297),
  BloodFury                             = Spell(20572),
  Fireblood                             = Spell(265221),
  LightsJudgment                        = Spell(255647),
  -- Abilities
  ArcaneShot                            = Spell(185358),
  Exhilaration                          = Spell(109304),
  Flare                                 = Spell(1543),
  FreezingTrap                          = Spell(187650),
  HuntersMark                           = Spell(257284),
  -- Pet Utility Abilities
  MendPet                               = Spell(136),
  RevivePet                             = Spell(982),
  SummonPet                             = Spell(883),
  SummonPet2                            = Spell(83242),
  SummonPet3                            = Spell(83243),
  SummonPet4                            = Spell(83244),
  SummonPet5                            = Spell(83245),
  -- Talents
  AlphaPredator                         = Spell(269737),
  Barrage                               = Spell(120360),
  BeastMaster                           = Spell(378007),
  BindingShot                           = Spell(109248),
  CounterShot                           = Spell(147362),
  DeathChakram                          = Spell(375891),
  ExplosiveShot                         = Spell(212431),
  HydrasBite                            = Spell(260241),
  Intimidation                          = Spell(19577),
  KillCommand                           = MultiSpell(34026,259489),
  KillShot                              = MultiSpell(53351,320976),
  KillerInstinct                        = Spell(273887),
  Misdirection                          = Spell(34477),
  Muzzle                                = Spell(187707),
  PoisonInjection                       = Spell(378014),
  ScareBeast                            = Spell(1513),
  SerpentSting                          = Spell(271788),
  Stampede                              = Spell(201430),
  SteelTrap                             = Spell(162488),
  TarTrap                               = Spell(187698),
  TranquilizingShot                     = Spell(19801),
  WailingArrow                          = Spell(392060),
  -- Buffs
  BerserkingBuff                        = Spell(26297),
  BloodFuryBuff                         = Spell(20572),
  -- Debuffs
  HuntersMarkDebuff                     = Spell(257284),
  LatentPoisonDebuff                    = Spell(336903),
  SerpentStingDebuff                    = Spell(271788),
  TarTrapDebuff                         = Spell(135299),
  -- Misc
  PoolFocus                             = Spell(999910),
}

Spell.Hunter.BeastMastery = MergeTableByKey(Spell.Hunter.Commons, {
  -- Abilities
  -- Pet Abilities
  Bite                                 = Spell(17253, "Pet"),
  BloodBolt                            = Spell(288962, "Pet"),
  Claw                                 = Spell(16827, "Pet"),
  Growl                                = Spell(2649, "Pet"),
  Smack                                = Spell(49966, "Pet"),
  -- Talents
  AMurderofCrows                        = Spell(131894),
  AnimalCompanion                       = Spell(267116),
  AspectoftheWild                       = Spell(193530),
  BarbedShot                            = Spell(217200),
  BeastCleave                           = Spell(115939),
  BestialWrath                          = Spell(19574),
  Bloodshed                             = Spell(321530),
  CalloftheWild                         = Spell(359844),
  CobraShot                             = Spell(193455),
  DireBeast                             = Spell(120679),
  KillCleave                            = Spell(378207),
  MultiShot                             = Spell(2643),
  OneWithThePack                        = Spell(199528),
  ScentofBlood                          = Spell(193532),
  Stomp                                 = Spell(199530),
  WildCall                              = Spell(185789),
  WildInstincts                         = Spell(378442),
  -- Buffs
  AspectoftheWildBuff                   = Spell(193530),
  BeastCleavePetBuff                    = Spell(118455, "Pet"),
  BeastCleaveBuff                       = Spell(268877),
  BestialWrathBuff                      = Spell(19574),
  BestialWrathPetBuff                   = Spell(186254, "Pet"),
  CalloftheWildBuff                     = Spell(359844),
  FrenzyPetBuff                         = Spell(272790, "Pet"),
  -- Debuffs
  BarbedShotDebuff                      = Spell(217200),
})

Spell.Hunter.Marksmanship = MergeTableByKey(Spell.Hunter.Commons, {
  -- Abilities
  SteadyShot                            = Spell(56641),
  -- Talents
  AimedShot                             = Spell(19434),
  BurstingShot                          = Spell(186387),
  CarefulAim                            = Spell(260228),
  ChimaeraShot                          = Spell(342049),
  DoubleTap                             = Spell(260402),
  InTheRhythm                           = Spell(407404),
  LegacyoftheWindrunners                = Spell(406425),
  LoneWolf                              = Spell(155228),
  MultiShot                             = Spell(257620),
  RapidFire                             = Spell(257044),
  Salvo                                 = Spell(400456),
  SerpentstalkersTrickery               = Spell(378888),
  SteadyFocus                           = Spell(193533),
  Streamline                            = Spell(260367),
  SurgingShots                          = Spell(391559),
  TrickShots                            = Spell(257621),
  Trueshot                              = Spell(288613),
  Volley                                = Spell(260243),
  WindrunnersGuidance                   = Spell(378905),
  -- Buffs
  BombardmentBuff                       = Spell(386875),
  BulletstormBuff                       = Spell(389020),
  DoubleTapBuff                         = Spell(260402),
  InTheRhythmBuff                       = Spell(407405),
  LockandLoadBuff                       = Spell(194594),
  PreciseShotsBuff                      = Spell(260242),
  RazorFragmentsBuff                    = Spell(388998),
  SalvoBuff                             = Spell(400456),
  SteadyFocusBuff                       = Spell(193534),
  TrickShotsBuff                        = Spell(257622),
  TrueshotBuff                          = Spell(288613),
  VolleyBuff                            = Spell(260243),
  -- Debuffs
  SalvoDebuff                           = Spell(388909),
  -- Legendaries
  EagletalonsTrueFocusBuff              = Spell(336851),
})

Spell.Hunter.Survival = MergeTableByKey(Spell.Hunter.Commons, {
  -- Abilities
  -- Bombs
  PheromoneBomb                         = Spell(270323),
  ShrapnelBomb                          = Spell(270335),
  VolatileBomb                          = Spell(271045),
  WildfireBomb                          = Spell(259495),
  -- Talents
  AspectoftheEagle                      = Spell(186289),
  Bombardier                            = Spell(389880),
  Butchery                              = Spell(212436),
  Carve                                 = Spell(187708),
  CoordinatedAssault                    = Spell(360952),
  CoordinatedKill                       = Spell(385739),
  FlankingStrike                        = Spell(269751),
  FuryoftheEagle                        = Spell(203415),
  Harpoon                               = Spell(190925),
  Lunge                                 = Spell(378934),
  MongooseBite                          = Spell(259387),
  Ranger                                = Spell(385695),
  RaptorStrike                          = Spell(186270),
  Spearhead                             = Spell(360966),
  TermsofEngagement                     = Spell(265895),
  TipoftheSpear                         = Spell(260285),
  VipersVenom                           = Spell(268501),
  WildfireInfusion                      = Spell(271014),
  -- Buffs
  BloodseekerBuff                       = Spell(260249),
  CoordinatedAssaultBuff                = Spell(361738),
  DeadlyDuoBuff                         = Spell(397568),
  MongooseFuryBuff                      = Spell(259388),
  SpearheadBuff                         = Spell(360966),
  SteelTrapDebuff                       = Spell(162487),
  TipoftheSpearBuff                     = Spell(260286),
  -- Debuffs
  BloodseekerDebuff                     = Spell(259277),
  InternalBleedingDebuff                = Spell(270343),
  PheromoneBombDebuff                   = Spell(270332),
  ShrapnelBombDebuff                    = Spell(270339),
  ShreddedArmorDebuff                   = Spell(410167),
  VolatileBombDebuff                    = Spell(271049),
  WildfireBombDebuff                    = Spell(269747),
})

-- Items
if not Item.Hunter then Item.Hunter = {}; end
Item.Hunter.Commons = {
  -- Potions
  Healthstone                           = Item(5512),
  --Trinkets
  AlgetharPuzzleBox                     = Item(193701, {13, 14}),
  DMDDance                              = Item(198088, {13, 14}),
  DMDDanceBox                           = Item(198478, {13, 14}),
  DMDInferno                            = Item(198086, {13, 14}),
  DMDInfernoBox                         = Item(194872, {13, 14}),
  DMDRime                               = Item(198087, {13, 14}),
  DMDRimeBox                            = Item(198477, {13, 14}),
  DMDWatcher                            = Item(198089, {13, 14}),
  DMDWatcherBox                         = Item(198481, {13, 14}),
  DecorationofFlame                     = Item(194299, {13, 14}),
  GlobeofJaggedIce                      = Item(193732, {13, 14}),
  ManicGrieftorch                       = Item(194308, {13, 14}),
  StormeatersBoon                       = Item(194302, {13, 14}),
  WindscarWhetstone                     = Item(137486, {13, 14}),
}

Item.Hunter.BeastMastery = MergeTableByKey(Item.Hunter.Commons, {
})

Item.Hunter.Marksmanship = MergeTableByKey(Item.Hunter.Commons, {
})

Item.Hunter.Survival = MergeTableByKey(Item.Hunter.Commons, {
})

-- Macros
if not Macro.Hunter then Macro.Hunter = {}; end
Macro.Hunter.Commons = {
  -- Items
  Trinket1                         = Macro("Trinket1", "/use 13"),
  Trinket2                         = Macro("Trinket2", "/use 14"),
  Healthstone                      = Macro("Healthstone", "/use item:5512"),
  AlgetharPuzzleBox                = Macro("AlgetharPuzzleBox", "/use item:193701"),
  ManicGrieftorch                  = Macro("ManicGrieftorch", "/use item:194308"),
  WindscarWhetstone                = Macro("WindscarWhetstone", "/use item:137486"),
  
  -- Spells
  ArcaneShotMouseover              = Macro("ArcaneShotMouseover", "/cast [@mouseover] " .. Spell.Hunter.Commons.ArcaneShot:Name()),
  BindingShotCursor                = Macro("BindingShotCursor", "/cast [@cursor] " .. Spell.Hunter.Commons.BindingShot:Name()),
  CounterShotMouseover             = Macro("CounterShotMouseover", "/cast [@mouseover] " .. Spell.Hunter.Commons.CounterShot:Name()),
  IntimidationMouseover            = Macro("IntimidationMouseover", "/cast [@mouseover] " .. Spell.Hunter.Commons.Intimidation:Name()),
  KillShotMouseover                = Macro("KillShotMouseover", "/cast [@mouseover] " .. Spell.Hunter.Commons.KillShot:Name()),
  MuzzleMouseover                  = Macro("MuzzleMouseover", "/cast [@mouseover] " .. Spell.Hunter.Commons.Muzzle:Name()),
  SerpentStingMouseover            = Macro("SerpentStingMouseover", "/cast [@mouseover] " .. Spell.Hunter.Commons.SerpentSting:Name()),
  SteelTrapCursor                  = Macro("SteelTrapCursor", "/cast [@cursor] " .. Spell.Hunter.Commons.SteelTrap:Name()),
  MisdirectionFocus                = Macro("MisdirectionFocus", "/cast [@focus] " .. Spell.Hunter.Commons.Misdirection:Name()),
}

Macro.Hunter.BeastMastery = MergeTableByKey(Macro.Hunter.Commons, {
  BarbedShotMouseover              = Macro("BarbedShotMouseover", "/cast [@mouseover] " .. Spell.Hunter.BeastMastery.BarbedShot:Name()),
  BarbedShotPetAttack              = Macro("BarbedShotPetAttack", "/cast " .. Spell.Hunter.BeastMastery.BarbedShot:Name() .. "\n/petattack"),
  CobraShotMouseover               = Macro("CobraShotMouseover", "/cast [@mouseover] " .. Spell.Hunter.BeastMastery.CobraShot:Name()),
  CobraShotPetAttack               = Macro("CobraShotPetAttack", "/cast " .. Spell.Hunter.BeastMastery.CobraShot:Name() .. "\n/petattack"),
  KillCommandPetAttack             = Macro("KillCommandPetAttack", "/cast " .. Spell.Hunter.BeastMastery.KillCommand:Name() .. "\n/petattack"),
})

Macro.Hunter.Marksmanship = MergeTableByKey(Macro.Hunter.Commons, {
  AimedShotMouseover               = Macro("AimedShotMouseover", "/cast [@mouseover] " .. Spell.Hunter.Marksmanship.AimedShot:Name()),
  VolleyCursor                     = Macro("VolleyCursor", "/cast [@cursor] " .. Spell.Hunter.Marksmanship.Volley:Name()),
})

Macro.Hunter.Survival = MergeTableByKey(Macro.Hunter.Commons, {
})
