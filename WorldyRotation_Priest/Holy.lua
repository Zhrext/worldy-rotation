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
local Focus      = Unit.Focus
local Mouseover  = Unit.MouseOver
local Pet        = Unit.Pet
local Spell      = HL.Spell
local Item       = HL.Item
local Utils      = HL.Utils
-- WorldyRotation
local WR         = WorldyRotation
local Macro      = WR.Macro
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Cast       = WR.Cast
-- Lua
local stringformat = string.format

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I/M for spell, item and macro arrays
local S = Spell.Priest.Holy
local I = Item.Priest.Holy
local M = Macro.Priest.Holy

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {}

-- Rotation Var
local Enemies12yMelee, EnemiesCount12yMelee
local EnemiesCount8ySplash
local DispellableDebuffs

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Priest.Commons,
  Holy = WR.GUISettings.APL.Priest.Holy
}

-- Player Covenant
-- 0: none, 1: Kyrian, 2: Venthyr, 3: Night Fae, 4: Necrolord
local CovenantID = Player:CovenantID()

-- Update CovenantID if we change Covenants
HL:RegisterForEvent(function()
  CovenantID = Player:CovenantID()
end, "COVENANT_CHOSEN")

-- Player Legendaries
local FlashConcentrationEquipped = Player:HasLegendaryEquipped(156)

-- Update Legendaries if we change equipment
HL:RegisterForEvent(function()
  FlashConcentrationEquipped = Player:HasLegendaryEquipped(156)
end, "PLAYER_EQUIPMENT_CHANGED")

-- Rotation Utils
local function GetFocusUnit()
  if Everyone.TargetIsValidHealableNpc() then
    return Target
  end
  if Everyone.IsSoloMode() then
    return Player
  end
  if Settings.Holy.General.Enabled.Dispel and S.Purify:IsReady() then
    local DispellableFriendlyUnit = Everyone.DispellableFriendlyUnit(DispellableDebuffs)
    if DispellableFriendlyUnit then
      return DispellableFriendlyUnit
    end
  end
  local LowestFriendlyUnit = Everyone.LowestFriendlyUnit()
  if LowestFriendlyUnit then
    return LowestFriendlyUnit
  end
end

local function AreUnitsBelowHealthPercentage(SettingTable, SettingName)
  if Player:IsInParty() and not Player:IsInRaid() then
    return Everyone.FriendlyUnitsBelowHealthPercentageCount(SettingTable.HP[SettingName]) >= SettingTable.AoEGroup[SettingName]
  elseif Player:IsInRaid() then
    return Everyone.FriendlyUnitsBelowHealthPercentageCount(SettingTable.HP[SettingName]) >= SettingTable.AoERaid[SettingName]
  end
end

-- Rotation Parts
local function FocusUnit()
  local NewFocusUnit = GetFocusUnit()
  if NewFocusUnit ~= nil and (Focus == nil or not Focus:Exists() or NewFocusUnit:GUID() ~= Focus:GUID() or not Focus:IsInRange(40)) then
    local FocusUnitKey = "Focus" .. Utils.UpperCaseFirst(NewFocusUnit:ID())
    if Cast(M[FocusUnitKey]) then return "focus " .. NewFocusUnit:ID() .. " focus_unit 1"; end
  end
end

local function Cooldown()
  -- power_infusion
  if CDsON() and Settings.Holy.Cooldown.Enabled.PowerInfusionSolo and Everyone.IsSoloMode() and S.PowerInfusion:IsReady() then
    if Cast(M.PowerInfusionPlayer) then return "power_infusion cooldown 1"; end
  end
  if Focus then
    -- guardian_spirit
    if Focus:HealthPercentage() <= Settings.Holy.Cooldown.HP.GuardianSpirit and S.GuardianSpirit:IsReady() then
      if Cast(M.GuardianSpiritFocus, not Focus:IsSpellInRange(S.GuardianSpirit)) then return "guardian_spirit cooldown 2"; end
    end
    -- holy_word_salvation
    if S.HolyWordSalvation:IsAvailable() and S.HolyWordSalvation:IsReady() and AreUnitsBelowHealthPercentage(Settings.Holy.Cooldown, "HolyWordSalvation") then
      if Cast(S.HolyWordSalvation) then return "holy_word_salvation cooldown 3"; end
    end
    -- divine_hymn
    if S.DivineHymn:IsReady() and AreUnitsBelowHealthPercentage(Settings.Holy.Cooldown, "DivineHymn") then
      if Cast(S.DivineHymn) then return "divine_hymn cooldown 4"; end
    end
    -- apotheosis
    if S.Apotheosis:IsAvailable() and S.Apotheosis:IsReady() and AreUnitsBelowHealthPercentage(Settings.Holy.Cooldown, "Apotheosis") then
      if Cast(S.Apotheosis) then return "apotheosis cooldown 5"; end
    end
  end
end

local function Damage()
  -- explosive
  local ExplosiveNPCID = 120651
  if Target:NPCID() == ExplosiveNPCID and S.ShadowWordPain:IsReady() then
    if Cast(S.ShadowWordPain, not Target:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain damage 1"; end
  end
  if Mouseover and Mouseover:NPCID() == ExplosiveNPCID and S.ShadowWordPain:IsReady() then
    if Cast(M.ShadowWordPainMouseover, not Mouseover:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain damage 2"; end
  end
  -- use_trinket
  if (Settings.Holy.General.Enabled.Trinkets) then
    local TrinketToUse = Player:GetUseableTrinkets(OnUseExcludes)
    if TrinketToUse then
      if Utils.ValueIsInArray(TrinketToUse:SlotIDs(), 13) then
        if Cast(M.Trinket1) then return "use_trinket " .. TrinketToUse:Name() .. " damage 1"; end
      elseif Utils.ValueIsInArray(TrinketToUse:SlotIDs(), 14) then
        if Cast(M.Trinket2) then return "use_trinket " .. TrinketToUse:Name() .. " damage 2"; end
      end
    end
  end
  -- use_potion_of_spectral_intellect
  if I.PotionofSpectralIntellect:IsReady() and (Player:BloodlustUp() or Target:TimeToDie() <= 30) then
    if Cast(M.PotionofSpectralIntellect) then return "potion damage 1"; end
  end
  if CovenantID == 1 then
    -- ascended_blast
    if Player:BuffUp(S.BoonoftheAscendedBuff) and S.AscendedBlast:IsReady() then
      if Cast(S.AscendedBlast, not Target:IsSpellInRange(S.AscendedBlast)) then return "ascended_blast damage 3"; end
    end
    -- ascended_nova
    if Player:BuffUp(S.BoonoftheAscendedBuff) and S.AscendedNova:IsReady() and EnemiesCount12yMelee > 3 then
      if Cast(S.AscendedNova) then return "ascended_nova damage 4"; end
    end
  end
  -- shadow_word_death
  if Target:HealthPercentage() <= 20 and S.ShadowWordDeath:IsReady() then
    if Cast(S.ShadowWordDeath, not Target:IsSpellInRange(S.ShadowWordDeath)) then return "shadow_word_death damage 5"; end
  end
  if Mouseover and Mouseover:HealthPercentage() <= 20 and S.ShadowWordDeath:IsReady() then
    if Cast(M.ShadowWordDeathMouseover, not Mouseover:IsSpellInRange(S.ShadowWordDeath)) then return "shadow_word_death damage 6"; end
  end
  -- holy_word_chastise
  if S.HolyWordChastise:IsReady() then
    if Cast(S.HolyWordChastise, not Target:IsSpellInRange(S.HolyWordChastise)) then return "holy_word_chastise damage 7"; end
  end
  -- ascended_nova
  if CovenantID == 1 and Player:BuffUp(S.BoonoftheAscendedBuff) and S.AscendedNova:IsReady() then
    if Cast(S.AscendedNova, not Target:IsInRange(12)) then return "ascended_nova damage 8"; end
  end
  -- holy_fire
  if S.HolyFire:IsReady() then
    if Cast(S.HolyFire, not Target:IsSpellInRange(S.HolyFire), true) then return "holy_fire damage 9"; end
  end
  -- divine_star
  if Settings.Holy.Damage.Enabled.DivineStar and EnemiesCount8ySplash >= Settings.Holy.Damage.AoE.DivineStar and S.DivineStar:IsAvailable() and S.DivineStar:IsReady() and not Target:IsFacingBlacklisted() then
    if Cast(S.DivineStar, not Target:IsInRange(24)) then return "divine_star damage 10"; end
  end
  -- boon_of_the_ascended
  if CovenantID == 1 and CDsON() and Settings.Holy.Damage.Enabled.BoonOfTheAscended and S.BoonoftheAscended:IsAvailable() and S.BoonoftheAscended:IsReady() then
    if Cast(S.BoonoftheAscended, nil, true) then return "boon_of_the_ascended damage 11"; end
  end
  -- holy_nova
  if EnemiesCount12yMelee > Settings.Holy.Damage.AoE.HolyNova and S.HolyNova:IsReady() then
    if Cast(S.HolyNova) then return "holy_nova damage 12"; end
  end
  -- shadow_word_pain
  if not Target:DebuffUp(S.ShadowWordPainDebuff) and Target:TimeToDie() > 3 and S.ShadowWordPain:IsReady() then
    if Cast(S.ShadowWordPain, not Target:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain damage 13"; end
  end
  -- smite
  if S.Smite:IsReady() then
    if Cast(S.Smite, not Target:IsSpellInRange(S.Smite), true) then return "smite damage 14"; end
  end
  -- shadow_word_pain
  if S.ShadowWordPain:IsReady() then
    if Cast(S.ShadowWordPain, not Target:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain damage 15"; end
  end
end

local function Defensive()
  -- fade
  if Settings.Holy.Defensive.Enabled.Fade and Player:IsTankingAoE() and S.Fade:IsReady() then
    if Cast(S.Fade) then return "fade defensive 1"; end
  end
  -- desperate_prayer
  if Player:HealthPercentage() <= Settings.Holy.Defensive.HP.DesperatePrayer and S.DesperatePrayer:IsReady() then
    if Cast(S.DesperatePrayer) then return "desperate_prayer defensive 2"; end
  end
  -- healthstone
  if Player:HealthPercentage() <= Settings.Holy.Defensive.HP.Healthstone and I.Healthstone:IsReady() then
    if Cast(M.Healthstone) then return "healthstone defensive 3"; end
  end
  -- phial_of_serenity
  if Player:HealthPercentage() <= Settings.Holy.Defensive.HP.PhialOfSerenity and I.PhialofSerenity:IsReady() then
    if Cast(M.PhialofSerenity) then return "phial_of_serenity defensive 4"; end
  end
end

local function Dispel()
  -- purify
  if Focus and Everyone.DispellableFriendlyUnit(DispellableDebuffs) and S.Purify:IsReady() then
    if Cast(M.PurifyFocus) then return "purify dispel 1"; end
  end
end

local function Healing()
  local FlashHealIsInstantCast = Player:BuffUp(S.SurgeofLightBuff)
  -- flash_heal
  if Settings.Holy.General.Enabled.FlashConcentration and FlashConcentrationEquipped and Player:BuffUp(S.FlashConcentrationBuff) and Player:BuffRemains(S.FlashConcentrationBuff) <= 6 and S.FlashHeal:IsReady() then
    if Cast(M.FlashHealFocus, nil, not FlashHealIsInstantCast) then return "flash_heal healing 1"; end
  end
  if CovenantID == 1 then
    -- ascended_blast
    if Everyone.TargetIsValid() and Player:BuffUp(S.BoonoftheAscendedBuff) and S.AscendedBlast:IsReady() then
      if Cast(S.AscendedBlast, not Target:IsSpellInRange(S.AscendedBlast)) then return "ascended_blast healing 2"; end
    end
    -- ascended_nova
    if Player:BuffUp(S.BoonoftheAscendedBuff) and S.AscendedNova:IsReady() and EnemiesCount12yMelee > 3 then
      if Cast(S.AscendedNova) then return "ascended_nova healing 3"; end
    end
  end
  -- holy_word_sanctify
  if AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "HolyWordSanctify") and S.HolyWordSanctify:IsReady() and Mouseover and Mouseover:IsAPlayer() and not Player:CanAttack(Mouseover) then
    if Cast(M.HolyWordSanctifyCursor) then return "holy_word_sanctify healing 4"; end
  end
  -- holy_word_serenity
  if Focus:HealthPercentage() <= Settings.Holy.Healing.HP.HolyWordSerenity and S.HolyWordSerenity:IsReady() then
    if Cast(M.HolyWordSerenityFocus) then return "holy_word_serenity healing 5"; end
  end
  -- prayer_of_mending
  if Focus:HealthPercentage() <= Settings.Holy.Healing.HP.PrayerOfMending and S.PrayerofMending:IsReady() then
    if Cast(M.PrayerofMendingFocus) then return "prayer_of_mending healing 6"; end
  end
  -- circle_of_healing
  if AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "CircleOfHealing") and S.CircleofHealing:IsReady() then
    if Cast(M.CircleofHealingFocus) then return "circle_of_healing healing 7"; end
  end
  -- divine_star
  if Focus:HealthPercentage() < Settings.Holy.Healing.HP.DivineStar and S.DivineStar:IsAvailable() and S.DivineStar:IsReady() and not Focus:IsFacingBlacklisted() then
    if Cast(S.DivineStar, not Focus:IsInRange(24)) then return "divine_star healing 8"; end
  end
  -- renew
  if Focus:HealthPercentage() <= Settings.Holy.Healing.HP.Renew and S.Renew:IsReady() and not Focus:BuffUp(S.RenewBuff) then
    if Cast(M.RenewFocus) then return "renew healing 9"; end
  end
  -- halo
  if AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "Halo") and S.Halo:IsAvailable() and S.Halo:IsReady() then
    if Cast(S.Halo, nil, true) then return "halo healing 10"; end
  end
  -- prayer_of_healing
  if AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "PrayerOfHealing") and S.PrayerofHealing:IsReady() then
    if Cast(M.PrayerofHealingFocus, nil, true) then return "prayer_of_healing healing 11"; end
  end
  -- fae_guardians
  if CovenantID == 3 and AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "FaeGuardians") and S.FaeGuardians:IsReady() then
    if Cast(S.FaeGuardians) then return "fae_guardians healing 12"; end
  end
  -- flash_heal
  if S.FlashHeal:IsReady() and (not Player:BuffUp(S.FlashConcentrationBuff) or Player:BuffStack(S.FlashConcentrationBuff) < 5) then
    if Focus:HealthPercentage() <= Settings.Holy.Healing.HP.FlashHeal or  Focus:HealthPercentage() <= Settings.Holy.Healing.HP.Heal then
      if Cast(M.FlashHealFocus, nil, not FlashHealIsInstantCast) then return "flash_heal healing 13"; end
    end
  end
  -- heal
  if Focus:HealthPercentage() <= Settings.Holy.Healing.HP.Heal and S.Heal:IsReady() then
    if Cast(M.HealFocus, nil, true) then return "heal healing 14"; end
  end
end

local function Movement()
  -- angelic_feather
  if Settings.Holy.General.Enabled.AngelicFeather and S.AngelicFeather:IsAvailable() and S.AngelicFeather:IsReady() and not Player:BuffUp(S.AngelicFeatherBuff) then
    if Cast(M.AngelicFeatherPlayer) then return "angelic_feather_player movement 1"; end
  end
  -- body_and_soul
  if Settings.Holy.General.Enabled.BodyAndSoul and S.BodyandSoul:IsAvailable() and S.PowerWordShield:IsReady() and not Player:DebuffUp(S.PowerWordShieldDebuff) then
    if Cast(M.PowerWordShieldPlayer) then return "power_word_shield_player movement 2"; end
  end
end

local function Racial()
  -- arcane_torrent,if=mana.pct<=95
  if Settings.Holy.General.Enabled.Racials and S.ArcaneTorrent:IsReady() and Player:ManaPercentage() <= 95 then
    if Cast(S.ArcaneTorrent) then return "arcane_torrent racials 1"; end
  end
end

local function Combat()
  -- dispel
  if Settings.Holy.General.Enabled.Dispel then
    local ShouldReturn = Dispel(); if ShouldReturn then return ShouldReturn; end
  end
  -- defensive
  local ShouldReturn = Defensive(); if ShouldReturn then return ShouldReturn; end
  -- cooldown
  ShouldReturn = Cooldown(); if ShouldReturn then return ShouldReturn; end
  -- healing
  if Focus and Focus:Exists() and not Focus:IsDeadOrGhost() and Focus:IsInRange(40) then
    ShouldReturn = Healing(); if ShouldReturn then return ShouldReturn; end
  end
  -- racial
  ShouldReturn = Racial(); if ShouldReturn then return ShouldReturn; end
  -- damage
  if Everyone.TargetIsValid() then
    ShouldReturn = Damage(); if ShouldReturn then return ShouldReturn; end
  end
end

local function OutOfCombat()
  -- dispel
  if Settings.Holy.General.Enabled.Dispel then
    local ShouldReturn = Dispel(); if ShouldReturn then return ShouldReturn; end
  end
  -- healing
  if Settings.Holy.General.Enabled.OutOfCombatHealing and Focus and Focus:Exists() and not Focus:IsDeadOrGhost() and Focus:IsInRange(40) then
    local ShouldReturn = Healing(); if ShouldReturn then return ShouldReturn; end
  end
  -- resurrection
  if Target and Target:Exists() and Target:IsAPlayer() and Target:IsDeadOrGhost() and not Player:CanAttack(Target) then
    local DeadFriendlyUnitsCount = Everyone.DeadFriendlyUnitsCount()
    if DeadFriendlyUnitsCount > 1 then
      if Cast(S.MassResurrection, nil, true) then return "mass_resurrection outofcombat 1"; end
    else
      if Cast(S.Resurrection, not Target:IsInRange(40), true) then return "resurrection outofcombat 2"; end
    end
  end
  -- power_word_fortitude
  if Settings.Holy.General.Enabled.PowerWordFortitude and S.PowerWordFortitude:IsReady() and not Player:BuffUp(S.PowerWordFortitudeBuff) then
    if Cast(M.PowerWordFortitudePlayer) then return "power_word_fortitude_player outofcombat 3"; end
  end
end

local function APL()
  -- Movement
  if Player:IsMoving() then
    local ShouldReturn = Movement(); if ShouldReturn then return ShouldReturn; end
  end
  -- FocusUnit
  if Player:AffectingCombat() or Settings.Holy.General.Enabled.Dispel then
    local ShouldReturn = FocusUnit(); if ShouldReturn then return ShouldReturn; end
  end
  Enemies12yMelee = Player:GetEnemiesInMeleeRange(12)
  if AoEON() then
    EnemiesCount12yMelee = #Enemies12yMelee
    EnemiesCount8ySplash = Target:GetEnemiesInSplashRangeCount(8)
  else
    EnemiesCount12yMelee = 1
    EnemiesCount8ySplash = 1
  end
  if Player:AffectingCombat() then
    -- Combat
    local ShouldReturn = Combat(); if ShouldReturn then return ShouldReturn; end
  else
    -- OutOfCombat
    local ShouldReturn = OutOfCombat(); if ShouldReturn then return ShouldReturn; end
  end
end

local function AutoBind()
  -- Bind Spells
  WR.Bind(S.ArcaneTorrent)
  WR.Bind(S.Apotheosis)
  WR.Bind(S.AscendedBlast)
  WR.Bind(S.AscendedNova)
  WR.Bind(S.BoonoftheAscended)
  WR.Bind(S.DesperatePrayer)
  WR.Bind(S.DivineHymn)
  WR.Bind(S.DivineStar)
  WR.Bind(S.Fade)
  WR.Bind(S.HolyFire)
  WR.Bind(S.HolyNova)
  WR.Bind(S.HolyWordChastise)
  WR.Bind(S.HolyWordSalvation)
  WR.Bind(S.ShadowWordDeath)
  WR.Bind(S.ShadowWordPain)
  WR.Bind(S.Smite)

  -- Bind Items
  WR.Bind(M.Trinket1)
  WR.Bind(M.Trinket2)
  WR.Bind(M.Healthstone)
  WR.Bind(M.PotionofSpectralIntellect)
  WR.Bind(M.PhialofSerenity)

  -- Bind Macros
  WR.Bind(M.AngelicFeatherPlayer)
  WR.Bind(M.CircleofHealingFocus)
  WR.Bind(M.FlashHealFocus)
  WR.Bind(M.GuardianSpiritFocus)
  WR.Bind(M.HealFocus)
  WR.Bind(M.HolyWordSanctifyCursor)
  WR.Bind(M.HolyWordSerenityFocus)
  WR.Bind(M.PowerInfusionPlayer)
  WR.Bind(M.PowerWordFortitudePlayer)
  WR.Bind(M.PowerWordShieldPlayer)
  WR.Bind(M.PrayerofHealingFocus)
  WR.Bind(M.PrayerofMendingFocus)
  WR.Bind(M.PurifyFocus)
  WR.Bind(M.RenewFocus)
  WR.Bind(M.ShadowWordDeathMouseover)
  WR.Bind(M.ShadowWordPainMouseover)

  -- Bind Focus Macros
  WR.Bind(M.FocusTarget)
  WR.Bind(M.FocusPlayer)
  for i = 1, 4 do
    local FocusUnitKey = stringformat("FocusParty%d", i)
    WR.Bind(M[FocusUnitKey])
  end
  for i = 1, 40 do
    local FocusUnitKey = stringformat("FocusRaid%d", i)
    WR.Bind(M[FocusUnitKey])
  end
end

local function Init()
  WR.Print("Holy Priest by Worldy")
  AutoBind()
  DispellableDebuffs = {
    Spell(325885), -- Anguished Cries
    Spell(325224), -- Anima Injection
    Spell(321968), -- Bewildering Pollen
    Spell(327882), -- Blightbeak
    Spell(324859), -- Bramblethorn Entanglement
    Spell(317963), -- Burden of Knowledge
    Spell(322358), -- Burning Strain
    Spell(243237), -- Burst
    Spell(360148), -- Bursting Dread
    Spell(338729), -- Charged Anima
    Spell(328664), -- Chilled
    Spell(323347), -- Clinging Darkness
    Spell(320512), -- Corroded Claws
    Spell(319070), -- Corrosive Gunk
    Spell(325725), -- Cosmic Artifice
    Spell(365297), -- Crushing Prism
    Spell(327481), -- Dark Lance
    Spell(324652), -- Debilitating Plague
    Spell(330700), -- Decaying Blight
    Spell(364522), -- Devouring Blood
    Spell(356324), -- Empowered Glyph of Restraint
    Spell(328331), -- Forced Confession
    -- NOTE(Worldy): Manually.
    -- 320788, -- Frozen Binds
    Spell(320248), -- Genetic Alteration
    Spell(355915), -- Glyph of Restraint
    Spell(364031), -- Gloom
    Spell(338353), -- Goresplatter
    Spell(328180), -- Gripping Infection
    Spell(346286), -- Hazardous Liquids
    Spell(320596), -- Heaving Retch
    Spell(332605), -- Hex
    Spell(328002), -- Hurl Spores
    Spell(357029), -- Hyperlight Bomb
    Spell(317661), -- Insidious Venom
    Spell(327648), -- Internal Strife
    Spell(322818), -- Lost Confidence
    Spell(319626), -- Phantasmal Parasite
    Spell(349954), -- Purification Protocol
    Spell(324293), -- Rasping Scream
    Spell(328756), -- Repulsive Visage
    -- NOTE(Worldy): Manually.
    -- 360687, -- Runecarver's Deathtouch
    Spell(355641), -- Scintillate
    Spell(332707), -- Shadow Word: Pain
    Spell(334505), -- Shimmerdust Sleep
    Spell(339237), -- Sinlight Visions
    Spell(325701), -- Siphon Life
    Spell(329110), -- Slime Injection
    Spell(333708), -- Soul Corruption
    Spell(322557), -- Soul Split
    Spell(356031), -- Stasis Beam
    Spell(326632), -- Stony Veins
    Spell(353835), -- Suppression
    Spell(326607), -- Turn to Stone
    Spell(360241), -- Unsettling Dreams
    Spell(340026), -- Wailing Grief
    Spell(320529), -- Wasting Blight
    Spell(341949), -- Withering Blight
    Spell(321038), -- Wrack Soul
  }
end


WR.SetAPL(257, APL, Init)
