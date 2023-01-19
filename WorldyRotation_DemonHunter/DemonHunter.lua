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
if not Spell.DemonHunter then Spell.DemonHunter = {} end
Spell.DemonHunter.Commons = {
  -- Racials
  ArcaneTorrent                         = Spell(50613),
  -- Abilities
  Glide                                 = Spell(131347),
  ImmolationAura                        = Spell(258920),
  -- Talents
  ChaosNova                             = Spell(179057),
  Demonic                               = Spell(213410),
  ElysianDecree                         = Spell(390163),
  Felblade                              = Spell(232893),
  FodderToTheFlame                      = Spell(391429),
  SigilOfFlame                          = MultiSpell(204596, 204513, 389810), -- 204596: Base ID, 204513: Concentrated, 389810: Precise
  TheHunt                               = Spell(370965),
  -- Utility
  Disrupt                               = Spell(183752),
  -- Buffs
  ImmolationAuraBuff                    = Spell(258920),
  -- Debuffs
  SigilOfFlameDebuff                    = Spell(204598),
  -- Other
  Pool                                  = Spell(999910)
}

Spell.DemonHunter.Havoc = MergeTableByKey(Spell.DemonHunter.Commons, {
  -- Abilities
  Annihilation                          = Spell(201427),
  BladeDance                            = Spell(188499),
  Blur                                  = Spell(198589),
  ChaosStrike                           = Spell(162794),
  DeathSweep                            = Spell(210152),
  DemonsBite                            = Spell(162243),
  FelRush                               = Spell(195072),
  Metamorphosis                         = Spell(191427),
  ThrowGlaive                           = Spell(185123),
  -- Talents
  BlindFury                             = Spell(203550),
  BurningWound                          = Spell(391189),
  ChaosTheory                           = Spell(389687),
  ChaoticTransformation                 = Spell(388112),
  CycleOfHatred                         = Spell(258887),
  DemonBlades                           = Spell(203555),
  EssenceBreak                          = Spell(258860),
  EyeBeam                               = Spell(198013),
  FelBarrage                            = Spell(258925),
  FelEruption                           = Spell(211881),
  FirstBlood                            = Spell(206416),
  FuriousGaze                           = Spell(343311),
  GlaiveTempest                         = Spell(342817),
  Initiative                            = Spell(388108),
  Momentum                              = Spell(206476),
  Ragefire                              = Spell(388107),
  SerratedGlaive                        = Spell(390154),
  SigilOfMisery                         = Spell(389813),
  Soulrend                              = Spell(388106),
  TacticalRetreat                       = Spell(389688),
  TrailofRuin                           = Spell(258881),
  UnboundChaos                          = Spell(347461),
  VengefulRetreat                       = Spell(198793),
  -- Buffs
  ChaosTheoryBuff                       = Spell(390195),
  FuriousGazeBuff                       = Spell(343312),
  MetamorphosisBuff                     = Spell(162264),
  MomentumBuff                          = Spell(208628),
  TacticalRetreatBuff                   = Spell(389890),
  UnboundChaosBuff                      = Spell(347462),
  -- Debuffs
  BurningWoundDebuff                    = Spell(391191),
  EssenceBreakDebuff                    = Spell(320338),
  SerratedGlaiveDebuff                  = Spell(390155),
})

Spell.DemonHunter.Vengeance = MergeTableByKey(Spell.DemonHunter.Commons, {
  -- Abilities
  InfernalStrike                        = Spell(189110),
  Shear                                 = Spell(203782),
  SoulCleave                            = Spell(228477),
  SoulFragments                         = Spell(203981),
  ThrowGlaive                           = Spell(204157),
  -- Defensive
  DemonSpikes                           = Spell(203720),
  Torment                               = Spell(185245),
  -- Talents
  AgonizingFlames                       = Spell(207548),
  BulkExtraction                        = Spell(320341),
  BurningAlive                          = Spell(207739),
  CharredFlesh                          = Spell(336639),
  ConcentratedSigils                    = Spell(207666),
  DarkglareBoon                         = Spell(389708),
  DowninFlames                          = Spell(389732),
  Fallout                               = Spell(227174),
  FelDevastation                        = Spell(212084),
  FieryBrand                            = Spell(204021),
  FieryDemise                           = Spell(389220),
  Frailty                               = Spell(389958),
  Fracture                              = Spell(263642),
  SigilOfSilence                        = Spell(202137),
  SoulBarrier                           = Spell(263648),
  SoulCarver                            = Spell(207407),
  SpiritBomb                            = Spell(247454),
  -- Utility
  Metamorphosis                         = Spell(187827),
  -- Buffs
  DemonSpikesBuff                       = Spell(203819),
  MetamorphosisBuff                     = Spell(187827),
  -- Debuffs
  FieryBrandDebuff                      = Spell(207771),
  FrailtyDebuff                         = Spell(247456),
})

-- Items
if not Item.DemonHunter then Item.DemonHunter = {} end
Item.DemonHunter.Commons = {
  AlgetharPuzzleBox                     = Item(193701, {13, 14}),
  Healthstone                           = Item(5512),
}

Item.DemonHunter.Havoc = MergeTableByKey(Item.DemonHunter.Commons, {
})

Item.DemonHunter.Vengeance = MergeTableByKey(Item.DemonHunter.Commons, {
})

-- Macros
if not Macro.DemonHunter then Macro.DemonHunter = {}; end
Macro.DemonHunter.Commons = {
  -- Items
  Trinket1                         = Macro("Trinket1", "/use 13"),
  Trinket2                         = Macro("Trinket2", "/use 14"),
  Healthstone                      = Macro("Healthstone", "/use item:5512"),
  
  -- Spells
  SigilOfFlamePlayer               = Macro("SigilOfFlamePlayer", "/cast [@player] " .. Spell.DemonHunter.Commons.SigilOfFlame:Name()),
}

Macro.DemonHunter.Havoc = MergeTableByKey(Macro.DemonHunter.Commons, {
  MetamorphosisPlayer              = Macro("MetamorphosisPlayer", "/cast [@player] " .. Spell.DemonHunter.Havoc.Metamorphosis:Name()),
  SigilOfMiseryPlayer              = Macro("SigilOfMiseryPlayer", "/cast [@player] " .. Spell.DemonHunter.Havoc.SigilOfMisery:Name()),
  ThrowGlaiveMouseover             = Macro("ThrowGlaiveMouseover", "/cast [@mouseover] " .. Spell.DemonHunter.Havoc.ThrowGlaive:Name()),
})

Macro.DemonHunter.Vengeance = MergeTableByKey(Macro.DemonHunter.Commons, {
  InfernalStrikePlayer             = Macro("InfernalStrikePlayer", "/cast [@player] " .. Spell.DemonHunter.Vengeance.InfernalStrike:Name()),
  SigilOfSilencePlayer             = Macro("SigilOfSilencePlayer", "/cast [@player] " .. Spell.DemonHunter.Vengeance.SigilOfSilence:Name()),
  ThrowGlaiveMouseover             = Macro("ThrowGlaiveMouseover", "/cast [@mouseover] " .. Spell.DemonHunter.Vengeance.ThrowGlaive:Name()),
})
