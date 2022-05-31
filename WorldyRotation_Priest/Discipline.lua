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
-- WorldyRotation
local WR         = WorldyRotation
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Cast       = WR.Cast

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.Priest.Discipline
local I = Item.Priest.Discipline

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
}

-- Rotation Var
local EnemiesCount10ySplash
local Enemies12yMelee, EnemiesCount12yMelee
local Enemies8yMelee, EnemiesCount8yMelee

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Priest.Commons,
  Discipline = WR.GUISettings.APL.Priest.Discipline
}

-- Macros
local M = {
  PowerWordFortitudePlayer = {MacroID = "PowerWordFortitudePlayer", MacroText = "/cast [@player] " .. S.PowerWordFortitude:Name()}
}

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  -- power_word_fortitude
  if S.PowerWordFortitude:IsCastable() and not Player:BuffUp(S.PowerWordFortitude) then
    if Cast(M.PowerWordFortitudePlayer) then return "power_word_fortitude precombat 0"; end
  end
  -- smite
  if S.Smite:IsCastable() then
    if Cast(S.Smite, not Target:IsSpellInRange(S.Smite), true) then return "smite precombat 2"; end
  end
end

local function Racials()
  -- arcane_torrent,if=mana.pct<=95
  if S.ArcaneTorrent:IsCastable() and (Player:ManaPercentage() <= 95) then
    if Cast(S.ArcaneTorrent) then return "arcane_torrent racials 2"; end
  end
  -- blood_fury
  if S.BloodFury:IsCastable() then
    if Cast(S.Fireblood) then return "blood_fury racials 4"; end
  end
  -- berserking
  if S.Berserking:IsCastable()  then
    if Cast(S.Berserking) then return "berserking racials 6"; end
  end
  -- arcane_torrent
  if S.ArcaneTorrent:IsCastable() then
    if Cast(S.ArcaneTorrent) then return "arcane_torrent racials 8"; end
  end
  -- lights_judgment
  if S.LightsJudgment:IsCastable() then
    if Cast(S.LightsJudgment, not Target:IsSpellInRange(S.LightsJudgment)) then return "lights_judgment racials 10"; end
  end
  -- fireblood
  if S.Fireblood:IsCastable() then
    if Cast(S.Fireblood) then return "fireblood racials 12"; end
  end
  -- ancestral_call
  if S.AncestralCall:IsCastable() then
    if Cast(S.AncestralCall) then return "ancestral_call racials 14"; end
  end
  -- bag_of_tricks
  if S.BagofTricks:IsCastable() then
    if Cast(S.BagofTricks, not Target:IsSpellInRange(S.BagofTricks)) then return "bag_of_tricks racials 16"; end
  end
end

local function Boon()
  -- ascended_blast
  -- Manually added: ,if=spell_targets.ascended_nova<3
  if S.AscendedBlast:IsReady() and (EnemiesCount8yMelee < 3) then
    if Cast(S.AscendedBlast, not Target:IsSpellInRange(S.AscendedBlast)) then return "ascended_blast boon 2"; end
  end
  -- ascended_nova
  -- Manually added: ,if=spell_targets.ascended_nova>=3
  if S.AscendedNova:IsReady() and (EnemiesCount8yMelee >= 3) then
    if Cast(S.AscendedNova, not Target:IsInRange(8)) then return "ascended_nova boon 4"; end
  end
end

--- ======= ACTION LISTS =======
local function APL()
  Enemies12yMelee = Player:GetEnemiesInMeleeRange(12) -- Holy Nova
  Enemies8yMelee = Player:GetEnemiesInMeleeRange(8) -- Ascended Nova
  if AoEON() then
    EnemiesCount10ySplash = Target:GetEnemiesInSplashRangeCount(10)
    EnemiesCount12yMelee = #Enemies12yMelee
    EnemiesCount8yMelee = #Enemies8yMelee
  else
    EnemiesCount10ySplash = 1
    EnemiesCount12yMelee = 1
    EnemiesCount8yMelee = 1
  end

  if Everyone.TargetIsValid() then
    -- call precombat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- use_items
    if Settings.Commons.Enabled.Trinkets then
      local TrinketToUse = Player:GetUseableTrinkets(OnUseExcludes)
      if TrinketToUse then
        if Cast(TrinketToUse) then return "Generic use_items for " .. TrinketToUse:Name(); end
      end
    end
    -- potion,if=buff.bloodlust.react|buff.power_infusion.up|target.time_to_die<=40
    if Settings.Commons.Enabled.Potions and I.PotionofSpectralIntellect:IsReady() and (Player:BloodlustUp() or Player:BuffUp(S.PowerInfusion) or Target:TimeToDie() <= 40) then
      if Cast(I.PotionofSpectralIntellect) then return "potion main 2"; end
    end
    -- call_action_list,name=racials
    local ShouldReturn = Racials(); if ShouldReturn then return ShouldReturn; end
    -- power_infusion
    if S.PowerInfusion:IsCastable() then
      if Cast(S.PowerInfusion) then return "power_infusion main 42"; end
    end
    -- divine_star
    if S.DivineStar:IsCastable() then
      if Cast(S.DivineStar, not Target:IsSpellInRange(S.DivineStar)) then return "divine_star main 44"; end
    end
    -- halo
    if S.Halo:IsCastable() then
      if Cast(S.Halo) then return "divine_star main 11"; end
    end
    --penance
    if S.Penance:IsCastable() then
      if Cast(S.Penance, not Target:IsSpellInRange(S.Penance)) then return "penance main 46"; end
    end
    --power_word_solace
    if S.PowerWordSolace:IsCastable() then
      if Cast(S.PowerWordSolace, not Target:IsSpellInRange(S.PowerWordSolace)) then return "power_word_solace main 48"; end
    end
    -- shadow_covenant,if=!covenant.kyrian|(!cooldown.boon_of_the_ascended.up&!buff.boon_of_the_ascended.up)
    if S.ShadowCovenant:IsCastable() and (Player:Covenant() ~= "Kyrian" or (not S.BoonoftheAscended:CooldownUp() and Player:BuffDown(S.BoonoftheAscendedBuff))) then
      if Cast(S.ShadowCovenant) then return "shadow_covenant main 50"; end
    end
    --schism
    if S.Schism:IsCastable() then
      if Cast(S.Schism, not Target:IsSpellInRange(S.Schism), true) then return "schism main 52"; end
    end
    -- mindgames
    if S.Mindgames:IsReady() then
      if Cast(S.Mindgames, not Target:IsSpellInRange(S.Mindgames), true) then return "mindgames 57"; end
    end
    -- fae_guardians
    if S.FaeGuardians:IsCastable() then
      if Cast(S.FaeGuardians) then return "fae_guardians main "; end
    end
    -- unholy_nova
    if S.UnholyNova:IsCastable() then
      if Cast(S.UnholyNova) then return "unholy_nova main "; end
    end
    -- boon_of_the_ascended
    if S.BoonoftheAscended:IsCastable() then
      if Cast(S.BoonoftheAscended, nil, true) then return "boon_of_the_ascended main 54"; end
    end
    -- call_action_list,name=boon,if=buff.boon_of_the_ascended.up
    if (Player:BuffUp(S.BoonoftheAscendedBuff)) then
      local ShouldReturn = Boon(); if ShouldReturn then return ShouldReturn; end
    end
    -- mindbender
    --if S.Mindbender:IsCastable() then
    --  if Cast(S.Mindbender) then return "mindbender main 56"; end
    --end
    -- spirit_shell
    if S.SpiritShell:IsReady() then
      if Cast(S.SpiritShell) then return "spirit_shell main "; end
    end
    -- purge_the_wicked,if=!ticking
    if S.PurgeTheWicked:IsCastable() and (Target:DebuffDown(S.PurgeTheWickedDebuff)) then
      if Cast(S.PurgeTheWicked, not Target:IsSpellInRange(S.PurgeTheWicked)) then return "purge_the_wicked main 58"; end
    end
    -- shadow_word_pain,if=!ticking&!talent.purge_the_wicked.enabled
    if S.ShadowWordPain:IsCastable() and (Target:DebuffDown(S.ShadowWordPainDebuff) and not S.PurgeTheWicked:IsAvailable()) then
      if Cast(S.ShadowWordPain, not Target:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain main 60"; end
    end
    --smite,if=spell_targets.holy_nova<3
    if S.Smite:IsCastable() and (EnemiesCount12yMelee < 3) then
      if Cast(S.Smite, not Target:IsSpellInRange(S.Smite), true) then return "smite main 70"; end
    end
    -- holy_nova,if=spell_targets.holy_nova>=3
    if S.HolyNova:IsCastable() and (EnemiesCount12yMelee >= 3) then
      if Cast(S.HolyNova) then return "holy_nova main 72"; end
    end
    --shadow_word_pain
    if S.ShadowWordPain:IsCastable() then
      if Cast(S.ShadowWordPain, not Target:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain main 74"; end
    end
    -- If Shadow Covenant buff is up and nothing to cast, give a Pool icon annotated with HEAL
    if Player:BuffUp(S.ShadowCovenantBuff) then
      if Cast(S.Pool) then return "Shadow Covenant UP - No Holy Spells"; end
    end
    -- If nothing else to do, show the Pool icon
    if Cast(S.Pool) then return "Wait/Pool Resources"; end
  end
end

local function Init()
  WR.Print("Discipline Priest Rotation by Worldy");
  WR.Bind(S.Smite);
  WR.Bind(M.PowerWordFortitudePlayer);
end

WR.SetAPL(256, APL, Init)
