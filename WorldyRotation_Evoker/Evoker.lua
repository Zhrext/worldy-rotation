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
if not Spell.Evoker then Spell.Evoker = {} end
Spell.Evoker.Commons = {
  -- Racials
  TailSwipe                             = Spell(368970),
  WingBuffet                            = Spell(357214),
  -- Abilities
  AzureStrike                           = Spell(362969),
  BlessingoftheBronze                   = Spell(364342),
  CauterizingFlame                      = Spell(374251),
  DeepBreath                            = Spell(357210),
  Disintegrate                          = Spell(356995),
  EmeraldBlossom                        = Spell(355913),
  FireBreath                            = MultiSpell(357208,382266), -- with and without Font of Magic
  LivingFlame                           = Spell(361469),
  Naturalize                            = Spell(360823),
  Return                                = Spell(361227),
  VerdantEmbrace                        = Spell(360995),
  -- Talents
  BlastFurnace                          = Spell(375510),
  EssenceAttunement                     = Spell(375722),
  ObsidianScales                        = Spell(363916),
  TipTheScales                          = Spell(370553),
  -- Buffs/Debuffs
  BlessingoftheBronzeBuff               = Spell(381748),
  FireBreathDebuff                      = Spell(357209),
  HoverBuff                             = Spell(358267),
  LeapingFlamesBuff                     = Spell(370901),
  -- Trinket Effects
  SpoilsofNeltharusCrit                 = Spell(381954),
  SpoilsofNeltharusHaste                = Spell(381955),
  SpoilsofNeltharusMastery              = Spell(381956),
  SpoilsofNeltharusVers                 = Spell(381957),
  -- Utility
  Quell                                 = Spell(351338),
  -- Other
  Pool                                  = Spell(999910)
}

Spell.Evoker.Devastation = MergeTableByKey(Spell.Evoker.Commons, {
  -- Talents
  Animosity                             = Spell(375797),
  ArcaneVigor                           = Spell(386342),
  Burnout                               = Spell(375801),
  Catalyze                              = Spell(386283),
  Causality                             = Spell(375777),
  ChargedBlast                          = Spell(370455),
  Dragonrage                            = Spell(375087),
  EngulfingBlaze                        = Spell(370837),
  EternitySurge                         = MultiSpell(359073,382411), -- with and without Font of Magic
  EternitysSpan                         = Spell(375757),
  EverburningFlame                      = Spell(370819),
  EyeofInfinity                         = Spell(369375),
  FeedtheFlames                         = Spell(369846),
  Firestorm                             = Spell(368847),
  FontofMagic                           = Spell(375783),
  ImminentDestruction                   = Spell(370781),
  Pyre                                  = Spell(357211),
  RagingInferno                         = Spell(405659),
  RubyEmbers                            = Spell(365937),
  Scintillation                         = Spell(370821),
  ShatteringStar                        = Spell(370452),
  Snapfire                              = Spell(370783),
  Tyranny                               = Spell(376888),
  Unravel                               = Spell(368432),
  Volatility                            = Spell(369089),
  -- Buffs
  BurnoutBuff                           = Spell(375802),
  ChargedBlastBuff                      = Spell(370454),
  EssenceBurstBuff                      = Spell(359618),
  SnapfireBuff                          = Spell(370818),
  -- Debuffs
  LivingFlameDebuff                     = Spell(361500),
})

Spell.Evoker.Preservation = MergeTableByKey(Spell.Evoker.Commons, {
  -- Spells
  DreamBreath                           = MultiSpell(355936, 382614),
  DreamFlight                           = Spell(359816),
  Echo                                  = Spell(364343),
  MassReturn                            = Spell(361178),
  Spiritbloom                           = MultiSpell(367226, 382731),
  Stasis                                = Spell(370537),
  StasisReactivate                      = Spell(370564),
  TemporalAnomaly                       = Spell(373861),
  TimeDilation                          = Spell(357170),
  Reversion                             = MultiSpell(366155, 367364),
  Rewind                                = Spell(363534),
  -- Buff
  EssenceBurstBuff                      = Spell(369299),
  StasisBuff                            = Spell(370562),
})

-- Items
if not Item.Evoker then Item.Evoker = {} end
Item.Evoker.Commons = {
  -- Potions
  Healthstone                           = Item(5512),
  -- Trinkets
  CrimsonAspirantsBadgeofFerocity       = Item(201449, {13, 14}),
  -- Items
  KharnalexTheFirstLight                = Item(195519),
  -- Trinkets
  SpoilsofNeltharus                     = Item(193773, {13, 14}),
  -- Trinkets (SL)
  ShadowedOrbofTorment                  = Item(186428, {13, 14}),
}

Item.Evoker.Devastation = MergeTableByKey(Item.Evoker.Commons, {
})

Item.Evoker.Preservation = MergeTableByKey(Item.Evoker.Commons, {
})

-- Macros
if not Macro.Evoker then Macro.Evoker = {}; end
Macro.Evoker.Commons = {
  -- Items
  Trinket1                         = Macro("Trinket1", "/use 13"),
  Trinket2                         = Macro("Trinket2", "/use 14"),
  Healthstone                      = Macro("Healthstone", "/use item:5512"),
  
  -- Spells
  AzureStrikeMouseover             = Macro("AzureStrikeMouseover", "/cast [@mouseover] " .. Spell.Evoker.Commons.AzureStrike:Name()),
  DeepBreathCursor                 = Macro("DeepBreathCursor", "/cast [@cursor] " .. Spell.Evoker.Commons.DeepBreath:Name()),
  CauterizingFlameFocus            = Macro("CauterizingFlameFocus", "/cast [@focus] " .. Spell.Evoker.Commons.CauterizingFlame:Name()),
  EmeraldBlossomFocus              = Macro("EmeraldBlossomFocus", "/cast [@focus] " .. Spell.Evoker.Commons.EmeraldBlossom:Name()),
  FireBreathMacro                  = Macro("FireBreath", "/cast " .. Spell.Evoker.Commons.FireBreath:Name()),
  LivingFlameFocus                 = Macro("LivingFlameFocus", "/cast [@focus] " .. Spell.Evoker.Commons.LivingFlame:Name()),
  NaturalizeFocus                  = Macro("NaturalizeFocus", "/cast [@focus] " .. Spell.Evoker.Commons.Naturalize:Name()),
  QuellMouseover                   = Macro("QuellMouseover", "/cast [@mouseover] " .. Spell.Evoker.Commons.Quell:Name()),
  VerdantEmbraceFocus              = Macro("VerdantEmbraceFocus", "/cast [@focus] " .. Spell.Evoker.Commons.VerdantEmbrace:Name()),
}

Macro.Evoker.Devastation = MergeTableByKey(Macro.Evoker.Commons, {
  -- Spells
  EternitySurgeMacro               = Macro("EternitySurge", "/cast " .. Spell.Evoker.Devastation.EternitySurge:Name()),
})

Macro.Evoker.Preservation = MergeTableByKey(Macro.Evoker.Commons, {
  -- Spells
  DreamBreathMacro                 = Macro("DreamBreath", "/cast " .. Spell.Evoker.Preservation.DreamBreath:Name()),
  DreamFlightCursor                = Macro("DreamFlightCursor", "/cast [@cursor] " .. Spell.Evoker.Preservation.DreamFlight:Name()),
  EchoFocus                        = Macro("EchoFocus", "/cast [@focus] " .. Spell.Evoker.Preservation.Echo:Name()),
  SpiritbloomFocus                 = Macro("SpiritbloomFocus", "/cast [@focus] " .. Spell.Evoker.Preservation.Spiritbloom:Name()),
  TimeDilationFocus                = Macro("TimeDilationFocus", "/cast [@focus] " .. Spell.Evoker.Preservation.TimeDilation:Name()),
  TipTheScalesDreamBreath          = Macro("TipTheScalesDreamBreath", "/cast " .. Spell.Evoker.Commons.TipTheScales:Name() .. "\n/cast " .. Spell.Evoker.Preservation.DreamBreath:Name()),
  TipTheScalesSpiritbloom          = Macro("TipTheScalesSpiritbloom", "/cast " .. Spell.Evoker.Commons.TipTheScales:Name() .. "\n/cast [@focus] " .. Spell.Evoker.Preservation.Spiritbloom:Name()),
  ReversionFocus                   = Macro("ReversionFocus", "/cast [@focus] " .. Spell.Evoker.Preservation.Reversion:Name()),
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
