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
local Item       = HL.Item
local MergeTableByKey = HL.Utils.MergeTableByKey
-- WorldyRotation
local WR         = WorldyRotation
local Macro      = WR.Macro

--- ============================ CONTENT ============================

-- Spells
if not Spell.Priest then Spell.Priest = {} end
Spell.Priest.Commons = {
  -- Racials
  AncestralCall                         = Spell(274738),
  ArcanePulse                           = Spell(260364),
  ArcaneTorrent                         = Spell(50613),
  BagofTricks                           = Spell(312411),
  Berserking                            = Spell(26297),
  BerserkingBuff                        = Spell(26297),
  BloodFury                             = Spell(20572),
  BloodFuryBuff                         = Spell(20572),
  Fireblood                             = Spell(265221),
  LightsJudgment                        = Spell(255647),
  -- Abilities
  DesperatePrayer                       = Spell(19236),
  DispelMagic                           = Spell(528),
  Fade                                  = Spell(586),
  PowerInfusion                         = Spell(10060),
  PowerInfusionBuff                     = Spell(10060),
  PowerWordFortitude                    = Spell(21562),
  PowerWordFortitudeBuff                = Spell(21562),
  PowerWordShield                       = Spell(17),
  PowerWordShieldBuff                   = Spell(17),
  PowerWordShieldDebuff                 = Spell(6788),
  ShadowWordDeath                       = Spell(32379),
  ShadowWordPain                        = Spell(589),
  ShadowWordPainDebuff                  = Spell(589),
  Smite                                 = Spell(585),
  -- Covenant Abilities
  AscendedBlast                         = Spell(325283),
  AscendedNova                          = Spell(325020), -- Melee, 8
  BoonoftheAscended                     = Spell(325013),
  BoonoftheAscendedBuff                 = Spell(325013),
  FaeGuardians                          = Spell(327661),
  FaeGuardiansBuff                      = Spell(327661),
  Fleshcraft                            = Spell(324631),
  Mindgames                             = Spell(323673),
  UnholyNova                            = Spell(324724), -- Melee, 15
  WrathfulFaerieDebuff                  = Spell(342132),
  -- Other
  Pool                                  = Spell(999910)
}

Spell.Priest.Holy = MergeTableByKey(Spell.Priest.Commons, {
  -- Base Spells
  BodyandSoul                           = Spell(64129),
  CircleofHealing                       = Spell(204883),
  DivineHymn                            = Spell(64843),
  FlashHeal                             = Spell(2061),
  GuardianSpirit                        = Spell(47788),
  Heal                                  = Spell(2060),
  HolyFire                              = Spell(14914),
  HolyFireDebuff                        = Spell(14914),
  HolyNova                              = Spell(132157), -- Melee, 12
  HolyWordChastise                      = Spell(88625),
  HolyWordSanctify                      = Spell(34861),
  HolyWordSerenity                      = Spell(2050),
  MassResurrection                      = Spell(212036),
  PrayerofHealing                       = Spell(596),
  PrayerofMending                       = Spell(33076),
  PrayerofMendingBuff                   = Spell(41635),
  Purify                                = Spell(527),
  Renew                                 = Spell(139),
  RenewBuff                             = Spell(139),
  Resurrection                          = Spell(2006),
  SurgeofLightBuff                      = Spell(114255),
  -- Talents
  AngelicFeather                        = Spell(121536),
  AngelicFeatherBuff                    = Spell(121557),
  Apotheosis                            = Spell(200183),
  DivineStar                            = Spell(110744),
  Halo                                  = Spell(120517),
  HolyWordSalvation                     = Spell(265202),
  -- Legendary
  FlashConcentrationBuff                = Spell(336267),
})

-- Items
if not Item.Priest then Item.Priest = {} end
Item.Priest.Commons = {
  -- Potion
  PotionofSpectralIntellect        = Item(171352),
  -- Trinkets
  ArchitectsIngenuityCore          = Item(188268, {13, 14}),
  DarkmoonDeckPutrescence          = Item(173069, {13, 14}),
  DreadfireVessel                  = Item(184030, {13, 14}),
  EmpyrealOrdinance                = Item(180117, {13, 14}),
  GlyphofAssimilation              = Item(184021, {13, 14}),
  InscrutableQuantumDevice         = Item(179350, {13, 14}),
  MacabreSheetMusic                = Item(184024, {13, 14}),
  ScarsofFraternalStrife           = Item(188253, {13, 14}),
  ShadowedOrbofTorment             = Item(186428, {13, 14}),
  SinfulGladiatorsBadgeofFerocity  = Item(175921, {13, 14}),
  SoullettingRuby                  = Item(178809, {13, 14}),
  SunbloodAmethyst                 = Item(178826, {13, 14}),
  TheFirstSigil                    = Item(188271, {13, 14}),
}

Item.Priest.Holy = MergeTableByKey(Item.Priest.Commons, {
})

-- Macros
if not Macro.Priest then Macro.Priest = {} end
Macro.Priest.Commons = {
  -- Base Spells
  PowerInfusionPlayer              = Macro("PowerInfusionPlayer", "/cast [@player] " .. Spell.Priest.Commons.PowerInfusion:Name()),
  PowerWordFortitudePlayer         = Macro("PowerWordFortitudePlayer", "/cast [@player] " .. Spell.Priest.Commons.PowerWordFortitude:Name()),
  PowerWordShieldPlayer            = Macro("PowerWordShieldPlayer", "/cast [@player] " .. Spell.Priest.Commons.PowerWordShield:Name()),
  ShadowWordDeathMouseover         = Macro("ShadowWordDeathMouseover", "/cast [@mouseover] " .. Spell.Priest.Commons.ShadowWordDeath:Name()),
  ShadowWordPainMouseover          = Macro("ShadowWordPainMouseover", "/cast [@mouseover] " .. Spell.Priest.Commons.ShadowWordPain:Name()),
}

Macro.Priest.Holy = MergeTableByKey(Macro.Priest.Commons, {
  -- Base Spells
  CircleofHealingFocus             = Macro("CircleofHealingFocus", "/cast [@focus] " .. Spell.Priest.Holy.CircleofHealing:Name()),
  GuardianSpiritFocus              = Macro("GuardianSpiritFocus", "/cast [@focus] " .. Spell.Priest.Holy.GuardianSpirit:Name()),
  FlashHealFocus                   = Macro("FlashHealFocus", "/cast [@focus] " .. Spell.Priest.Holy.FlashHeal:Name()),
  HealFocus                        = Macro("HealFocus", "/cast [@focus] " .. Spell.Priest.Holy.Heal:Name()),
  HolyWordSanctifyCursor           = Macro("HolyWordSanctifyCursor", "/cast [@cursor] " .. Spell.Priest.Holy.HolyWordSanctify:Name()),
  HolyWordSerenityFocus            = Macro("HolyWordSerenityFocus", "/cast [@focus] " .. Spell.Priest.Holy.HolyWordSerenity:Name()),
  PrayerofHealingFocus             = Macro("PrayerofHealingFocus", "/cast [@focus] " .. Spell.Priest.Holy.PrayerofHealing:Name()),
  PrayerofMendingFocus             = Macro("PrayerofMendingFocus", "/cast [@focus] " .. Spell.Priest.Holy.PrayerofMending:Name()),
  PurifyFocus                      = Macro("PurifyFocus", "/cast [@focus] " .. Spell.Priest.Holy.Purify:Name()),
  RenewFocus                       = Macro("RenewFocus", "/cast [@focus] " .. Spell.Priest.Holy.Renew:Name()),
  -- Talents
  AngelicFeatherPlayer             = Macro("AngelicFeatherPlayer", "/cast [@player] " .. Spell.Priest.Holy.AngelicFeather:Name()),
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
