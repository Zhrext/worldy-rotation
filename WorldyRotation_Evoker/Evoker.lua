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
  DeepBreath                            = Spell(357210),
  Disintegrate                          = Spell(356995),
  FireBreath                            = MultiSpell(357208,382266), -- with and without Font of Magic
  LivingFlame                           = Spell(361469),
  -- Talents
  BlastFurnace                          = Spell(375510),
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
  Causality                             = Spell(375777),
  ChargedBlast                          = Spell(370455),
  Dragonrage                            = Spell(375087),
  EngulfingBlaze                        = Spell(370837),
  EssenceAttunement                     = Spell(375722),
  EternitySurge                         = MultiSpell(359073,382411), -- with and without Font of Magic
  EternitysSpan                         = Spell(375757),
  EverburningFlame                      = Spell(370819),
  EyeofInfinity                         = Spell(369375),
  FeedtheFlames                         = Spell(369846),
  Firestorm                             = Spell(368847),
  FontofMagic                           = Spell(375783),
  Pyre                                  = Spell(357211),
  RubyEmbers                            = Spell(365937),
  Scintillation                         = Spell(370821),
  ShatteringStar                        = Spell(370452),
  Snapfire                              = Spell(370783),
  Tyranny                               = Spell(376888),
  Volatility                            = Spell(369089),
  -- Buffs
  BurnoutBuff                           = Spell(375802),
  ChargedBlastBuff                      = Spell(370454),
  EssenceBurstBuff                      = Spell(359618),
  SnapfireBuff                          = Spell(370818),
  -- Debuffs
  LivingFlameDebuff                     = Spell(361500),
})

-- Items
if not Item.Evoker then Item.Evoker = {} end
Item.Evoker.Commons = {
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

-- Macros
if not Macro.Evoker then Macro.Evoker = {}; end
Macro.Evoker.Commons = {
  -- Items
  Trinket1                         = Macro("Trinket1", "/use 13"),
  Trinket2                         = Macro("Trinket2", "/use 14"),
  Healthstone                      = Macro("Healthstone", "/use item:5512"),
  
  -- Spells
  DeepBreathCursor                 = Macro("DeepBreathCursor", "/cast [@cursor] " .. Spell.Evoker.Commons.DeepBreath:Name()),
  FireBreathMacro                  = Macro("FireBreathMacro", "/cast " .. Spell.Evoker.Commons.FireBreath:Name()),
  QuellMouseover                   = Macro("QuellMouseover", "/cast [@mouseover] " .. Spell.Evoker.Commons.Quell:Name()),
}

Macro.Evoker.Devastation = MergeTableByKey(Macro.Evoker.Commons, {
  -- Spells
  EternitySurgeMacro                  = Macro("EternitySurgeMacro", "/cast " .. Spell.Evoker.Devastation.EternitySurge:Name()),
})
