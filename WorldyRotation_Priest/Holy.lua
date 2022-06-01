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
local Mouseover  = Unit.Mouseover
local Party      = Unit.Party
local Raid       = Unit.Raid
local Pet        = Unit.Pet
local Spell      = HL.Spell
local Item       = HL.Item
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
local Enemies30y, EnemiesCount30y
local EnemiesCount8ySplash
local CurrentFocusUnit

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
    return "Target"
  end
  if Everyone.IsSoloMode() then
    return "Player"
  end
  if Settings.Holy.General.Enabled.Dispel and S.Purify:IsReady() then
    local DispellableFriendlyUnits = Everyone.DispellableFriendlyUnits()
    local DispellableFriendlyUnitsCount = #DispellableFriendlyUnits
    if DispellableFriendlyUnitsCount > 0 then
      for i = 1, DispellableFriendlyUnitsCount do
        local DispellableFriendlyUnit = DispellableFriendlyUnits[i]
        if not Everyone.UnitGroupRole(DispellableFriendlyUnit) == "TANK" then
          return DispellableFriendlyUnit:ID()
        end
      end
      return DispellableFriendlyUnits[1]:ID()
    end
  end
  return Everyone.LowestFriendlyUnit()
end

local function AreUnitsBelowHealthPercentage(SettingTable, SettingName)
  if Everyone.IsSoloMode() then
    return false
  elseif Player:IsInParty() then
    return Everyone.FriendlyUnitsBelowHealthPercentageCount(SettingTable.HP[SettingName]) >= SettingTable.AoEGroup[SettingName]
  elseif Player:IsInRaid() then
    return Everyone.FriendlyUnitsBelowHealthPercentageCount(SettingTable.HP[SettingName]) >= SettingTable.AoERaid[SettingName]
  end
  return false
end

-- Rotation Parts
local function FocusUnit()
  local NewFocusUnit = GetFocusUnit()
  if NewFocusUnit and (CurrentFocusUnit == nil or not NewFocusUnit == CurrentFocusUnit or not Focus:Exists() or not Focus:IsInRange(40)) then
    CurrentFocusUnit = NewFocusUnit
    local FocusUnitKey = "Focus" .. CurrentFocusUnit
    if Cast(M[FocusUnitKey]) then return "focus " .. CurrentFocusUnit .. " focus_unit 1"; end
  end
end

local function Cooldown()
  -- power_infusion
  if Settings.Holy.Cooldown.Enabled.PowerInfusionSolo and Everyone.IsSoloMode() and S.PowerInfusion:IsReady() then
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
  Enemies12yMelee = Player:GetEnemiesInMeleeRange(12)
  Enemies30y = Player:GetEnemiesInRange(30)
  if AoEON() then
    EnemiesCount12yMelee = #Enemies12yMelee
    EnemiesCount30y = #Enemies30y
    EnemiesCount8ySplash = Target:GetEnemiesInSplashRangeCount(8)
  else
    EnemiesCount12yMelee = 1
    EnemiesCount30y = 1
    EnemiesCount8ySplash = 1
  end
  -- explosive
  local ExplosiveNPCID = 120651
  if Target:NPCID() == ExplosiveNPCID and S.ShadowWordPain:IsReady() then
    if Cast(S.ShadowWordPain, not Target:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain damage 1"; end
  end
  if Mouseover and Mouseover:NPCID() == ExplosiveNPCID and S.ShadowWordPain:IsReady() then
    if Cast(M.ShadowWordPainMouseover, not Mouseover:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain damage 2"; end
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
  if Enemies12yMelee > Settings.Holy.Damage.AoE.HolyNova and S.HolyNova:IsReady() then
    if Cast(S.HolyNova) then return "holy_nova damage 12"; end
  end
  -- shadow_word_pain
  if not Target:BuffUp(S.ShadowWordPainDebuff) and Target:TimeToDie() > 3 and S.ShadowWordPain:IsReady() then
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
  if Player:HealthPercentage() <= Player.Holy.Defensive.HP.DesperatePrayer and S.DesperatePrayer:IsReady() then
    if Cast(S.DesperatePrayer) then return "desperate_prayer defensive 2"; end
  end
end

local function Dispel()
  -- purify
  if Focus and #Everyone.DispellableFriendlyUnits() > 0 and S.Purify:IsReady() then
    if Cast(M.PurifyFocus) then return "purify dispel 1"; end
  end
end

local function Healing()
  local FlashHealIsInstantCast = Player:BuffUp(S.SurgeofLightBuff)
  -- flash_heal
  if FlashConcentrationEquipped and Player:BuffUp(S.FlashConcentrationBuff) and Player:BuffRemains(S.FlashConcentrationBuff) <= 6 and S.FlashHeal:IsReady() then
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
  if AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "HolyWordSanctify") and S.HolyWordSanctify:IsReady() and Mouseover and Mouseover:HealthPercentage() <= Settings.Holy.Healing.HP.HolyWordSanctify then
    if Cast(M.HolyWordSanctifyCursor) then return "holy_word_sanctify healing 4"; end
  end
  -- holy_word_serenity
  if Focus:HealthPercentage() <= Settings.Holy.Healing.HP.HolyWordSerenity and S.HolyWordSerenity:IsReady() then
    if Cast(M.HolyWordSerenityFocus) then return "holy_word_serenity healing 5"; end
  end
  -- TODO(Worldy)
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

local function Combat()
  -- dispels
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
  -- damage
  if Everyone.TargetIsValid() then
    ShouldReturn = Damage(); if ShouldReturn then return ShouldReturn; end
  end
end

local function OutOfCombat()
  -- dispels
  if Settings.Holy.General.Enabled.Dispel then
    local ShouldReturn = Dispel(); if ShouldReturn then return ShouldReturn; end
  end
  -- healing
  if Settings.Holy.General.Enabled.OutOfCombatHealing and Focus and Focus:Exists() and not Focus:IsDeadOrGhost() and Focus:IsInRange(40) then
    local ShouldReturn = Healing(); if ShouldReturn then return ShouldReturn; end
  end
  -- resurrection
  if Target:IsAPlayer() and Target:IsDeadOrGhost() and not Player:CanAttack(Target) then
    local DeadFriendlyUnitsCount = Everyone.DeadFriendlyUnitsCount()
    if DeadFriendlyUnitsCount > 1 then
      if Cast(S.MassResurrection, nil, true) then return "mass_resurrection outofcombat 1"; end
    else
      if Cast(S.Resurrection, not Target:IsInRange(40), true) then return "resurrection outofcombat 2"; end
    end
  end
  -- power_word_fortitude
  if Settings.Commons.Enabled.PowerWordFortitude and S.PowerWordFortitude:IsReady() and not Player:BuffUp(S.PowerWordFortitudeBuff) then
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
  local TrinketToUse = Player:GetUseableTrinkets(OnUseExcludes)
  if TrinketToUse then
    WR.Bind(TrinketToUse)
  end
  if I.PotionofSpectralIntellect then
    WR.Bind(I.PotionofSpectralIntellect)
  end

  -- Bind Macros
  WR.Bind(M.AngelicFeatherPlayer)
  WR.Bind(M.FlashHealFocus)
  WR.Bind(M.GuardianSpiritFocus)
  WR.Bind(M.HolyWordSanctifyCursor)
  WR.Bind(M.HolyWordSerenityFocus)
  WR.Bind(M.PowerInfusionPlayer)
  WR.Bind(M.PowerWordFortitudePlayer)
  WR.Bind(M.PowerWordShieldPlayer)
  WR.Bind(M.PurifyFocus)
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
  C_Timer.After(1, function ()
    AutoBind()
  end)
end


WR.SetAPL(257, APL, Init)
