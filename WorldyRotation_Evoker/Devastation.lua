--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local HL            = HeroLib
local Cache         = HeroCache
local Unit          = HL.Unit
local Player        = Unit.Player
local Target        = Unit.Target
local Pet           = Unit.Pet
local Spell         = HL.Spell
local Item          = HL.Item
-- WorldyRotation
local WR            = WorldyRotation
local AoEON         = WR.AoEON
local CDsON         = WR.CDsON
local Cast          = WR.Cast
local CastPooling   = WR.CastPooling
local CastAnnotated = WR.CastAnnotated
local CastSuggested = WR.CastSuggested
local Press         = WR.Press
local Bind          = WR.Bind
local Macro         = WR.Macro
local Evoker        = WR.Commons.Evoker
-- Num/Bool Helper Functions
local num           = WR.Commons.Everyone.num
local bool          = WR.Commons.Everyone.bool
-- lua
local mathmax       = math.max

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.Evoker.Devastation
local I = Item.Evoker.Devastation
local M = Macro.Evoker.Devastation

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  I.ShadowedOrbofTorment:ID(),
  I.SpoilsofNeltharus:ID(),
}

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Evoker.Commons,
  Devastation = WR.GUISettings.APL.Evoker.Devastation
}

-- Trinket Item Objects
local equip = Player:GetEquipment()
local trinket1 = equip[13] and Item(equip[13]) or Item(0)
local trinket2 = equip[14] and Item(equip[14]) or Item(0)

-- Rotation Var
local Enemies25y
local Enemies8ySplash
local EnemiesCount8ySplash
local MaxEssenceBurstStack = (S.EssenceAttunement:IsAvailable()) and 2 or 1
local MaxBurnoutStack = 2
local VarTrinket1Sync, VarTrinket2Sync, TrinketPriority
local VarNextDragonrage
local VarDragonrageUp, VarDragonrageRemains
local VarR1CastTime
local BFRank = S.BlastFurnace:TalentRank()
local PlayerHaste
local BossFightRemains = 11111
local FightRemains = 11111
local GCDMax
local Immovable
local ESEmpower = 0
local FBEmpower = 0

-- Update Equipment
HL:RegisterForEvent(function()
  equip = Player:GetEquipment()
  trinket1 = equip[13] and Item(equip[13]) or Item(0)
  trinket2 = equip[14] and Item(equip[14]) or Item(0)
end, "PLAYER_EQUIPMENT_CHANGED")

-- Talent change registrations
HL:RegisterForEvent(function()
  MaxEssenceBurstStack = (S.EssenceAttunement:IsAvailable()) and 2 or 1
  BFRank = S.BlastFurnace:TalentRank()
end, "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB")

-- Reset variables after fights
HL:RegisterForEvent(function()
  BossFightRemains = 11111
  FightRemains = 11111
  for k in pairs(Evoker.FirestormTracker) do
    Evoker.FirestormTracker[k] = nil
  end
end, "PLAYER_REGEN_ENABLED")

-- Check if target is in Firestorm
local function InFirestorm()
  if S.Firestorm:TimeSinceLastCast() > 12 then return false end
  if Evoker.FirestormTracker[Target:GUID()] then
    if Evoker.FirestormTracker[Target:GUID()] > GetTime() - 2.5 then
      return true
    end
  end
  return false
end

local function Precombat()
  -- flask
  -- augmentation
  -- food
  -- snapshot_stats
  -- variable,name=trinket_1_sync,op=setif,value=1,value_else=0.5,condition=variable.trinket_1_buffs&(trinket.1.cooldown.duration%%cooldown.dragonrage.duration=0|cooldown.dragonrage.duration%%trinket.1.cooldown.duration=0)
  -- variable,name=trinket_2_sync,op=setif,value=1,value_else=0.5,condition=variable.trinket_2_buffs&(trinket.2.cooldown.duration%%cooldown.dragonrage.duration=0|cooldown.dragonrage.duration%%trinket.2.cooldown.duration=0)
  -- variable,name=trinket_priority,op=setif,value=2,value_else=1,condition=!variable.trinket_1_buffs&variable.trinket_2_buffs|variable.trinket_2_buffs&((trinket.2.cooldown.duration%trinket.2.proc.any_dps.duration)*(1.5+trinket.2.has_buff.intellect)*(variable.trinket_2_sync))>((trinket.1.cooldown.duration%trinket.1.proc.any_dps.duration)*(1.5+trinket.1.has_buff.intellect)*(variable.trinket_1_sync))
  -- variable,name=trinket_1_manual,value=trinket.1.is.spoils_of_neltharus
  -- variable,name=trinket_2_manual,value=trinket.2.is.spoils_of_neltharus
  -- variable,name=trinket_1_exclude,value=trinket.1.is.ruby_whelp_shell|trinket.1.is.whispering_incarnate_icon
  -- variable,name=trinket_2_exclude,value=trinket.2.is.ruby_whelp_shell|trinket.2.is.whispering_incarnate_icon
  -- variable,name=trinket_priority,op=setif,value=2,value_else=1,condition=!variable.trinket_1_buffs&variable.trinket_2_buffs|variable.trinket_2_buffs&((trinket.2.cooldown.duration%trinket.2.proc.any_dps.duration)*(1.5+trinket.2.has_buff.intellect)*(variable.trinket_2_sync))>((trinket.1.cooldown.duration%trinket.1.proc.any_dps.duration)*(1.5+trinket.1.has_buff.intellect)*(variable.trinket_1_sync))
  -- TODO: Can't yet handle all of these trinket conditions
  -- use_item,name=shadowed_orb_of_torment
  if Settings.General.Enabled.Trinkets and I.ShadowedOrbofTorment:IsEquippedAndReady() then
    if Press(I.ShadowedOrbofTorment) then return "shadowed_orb_of_torment precombat"; end
  end
  -- firestorm,if=talent.firestorm
  if S.Firestorm:IsCastable() then
    if Press(S.Firestorm, not Target:IsInRange(25), Immovable) then return "firestorm precombat"; end
  end
  -- living_flame,if=!talent.firestorm
  if S.LivingFlame:IsCastable() and (not S.Firestorm:IsAvailable()) then
    if Press(S.LivingFlame, not Target:IsInRange(25), Immovable) then return "living_flame precombat"; end
  end
  -- azure_strike
  if S.AzureStrike:IsCastable() then
    if Press(S.AzureStrike, not Target:IsSpellInRange(S.AzureStrike)) then return "azure_strike precombat"; end
  end
end

local function Defensives()
  -- obsidian_scales
  if S.ObsidianScales:IsCastable() and Player:BuffDown(S.ObsidianScales) and (Player:HealthPercentage() < Settings.Commons.HP.ObsidianScales) then
    if Press(S.ObsidianScales) then return "obsidian_scales defensives"; end
  end
  -- healthstone
  if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
    if Press(M.Healthstone, nil, nil, true) then return "healthstone"; end
  end
end

local function Trinkets()
  -- use_item,name=spoils_of_neltharus,if=buff.dragonrage.up&(buff.spoils_of_neltharus_mastery.up|buff.spoils_of_neltharus_haste.up|buff.dragonrage.remains+6*(cooldown.eternity_surge.remains<=gcd.max*2+cooldown.fire_breath.remains<=gcd.max*2)<=18)|fight_remains<=20
  if I.SpoilsofNeltharus:IsEquippedAndReady() and (VarDragonrageUp and (Player:BuffUp(S.SpoilsofNeltharusMastery) or Player:BuffUp(S.SpoilsofNeltharusHaste) or VarDragonrageRemains + 6 * num(num(S.EternitySurge:CooldownRemains() <= GCDMax * 2) + num(S.FireBreath:CooldownRemains() <= GCDMax * 2)) <= 18) or FightRemains <= 20) then
    if Press(I.SpoilsofNeltharus) then return "spoils_of_neltharus trinkets 2"; end
  end
  -- use_item,slot=trinket1,if=buff.dragonrage.up&(!trinket.2.has_cooldown|trinket.2.cooldown.remains|variable.trinket_priority=1|variable.trinket_2_exclude)&!variable.trinket_1_manual|trinket.1.proc.any_dps.duration>=fight_remains|trinket.1.cooldown.duration<=60&(variable.next_dragonrage>20|!talent.dragonrage)&(!buff.dragonrage.up|variable.trinket_priority=1)
  -- use_item,slot=trinket2,if=buff.dragonrage.up&(!trinket.1.has_cooldown|trinket.1.cooldown.remains|variable.trinket_priority=2|variable.trinket_1_exclude)&!variable.trinket_2_manual|trinket.2.proc.any_dps.duration>=fight_remains|trinket.2.cooldown.duration<=60&(variable.next_dragonrage>20|!talent.dragonrage)&(!buff.dragonrage.up|variable.trinket_priority=2)
  -- use_item,slot=trinket1,if=!variable.trinket_1_buffs&(trinket.2.cooldown.remains|!variable.trinket_2_buffs)&(variable.next_dragonrage>20|!talent.dragonrage)&!variable.trinket_1_manual
  -- use_item,slot=trinket2,if=!variable.trinket_2_buffs&(trinket.1.cooldown.remains|!variable.trinket_1_buffs)&(variable.next_dragonrage>20|!talent.dragonrage)&!variable.trinket_2_manual
  -- Note: Can't handle above trinket tracking, so let's use a generic fallback. When we can do above tracking, the below can be removed.
  -- use_items,if=buff.dragonrage.up|variable.next_dragonrage>20|!talent.dragonrage
  if (VarDragonrageUp or VarNextDragonrage > 20 or not S.Dragonrage:IsAvailable()) then
    local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
    if Trinket1ToUse then
      if Press(M.Trinket1, nil, nil, true) then return "trinket1"; end
    end
    local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
    if Trinket2ToUse then
      if Press(M.Trinket2, nil, nil, true) then return "trinket2"; end
    end
  end
end

local function ES()
  -- eternity_surge,empower_to=1,if=spell_targets.pyre<=1+talent.eternitys_span|buff.dragonrage.remains<1.75*spell_haste&buff.dragonrage.remains>=1*spell_haste
  if (EnemiesCount8ySplash <= 1 + num(S.EternitysSpan:IsAvailable()) or VarDragonrageRemains < 1.75 * PlayerHaste and VarDragonrageRemains >= 1 * PlayerHaste) then
    ESEmpower = 1
  -- eternity_surge,empower_to=2,if=spell_targets.pyre<=2+2*talent.eternitys_span|buff.dragonrage.remains<2.5*spell_haste&buff.dragonrage.remains>=1.75*spell_haste
  elseif (EnemiesCount8ySplash <= 2 + 2 * num(S.EternitysSpan:IsAvailable()) or VarDragonrageRemains < 2.5 * PlayerHaste and VarDragonrageRemains >= 1.75 * PlayerHaste) then
    ESEmpower = 2
  -- eternity_surge,empower_to=3,if=spell_targets.pyre<=3+3*talent.eternitys_span|!talent.font_of_magic|buff.dragonrage.remains<=3.25*spell_haste&buff.dragonrage.remains>=2.5*spell_haste
  elseif (EnemiesCount8ySplash <= 3 + 3 * num(S.EternitysSpan:IsAvailable()) or (not S.FontofMagic:IsAvailable()) or VarDragonrageRemains <= 3.25 * PlayerHaste and VarDragonrageRemains >= 2.5 * PlayerHaste) then
    ESEmpower = 3
  -- eternity_surge,empower_to=4
  else
    ESEmpower = 4
  end
  if Press(M.EternitySurgeMacro, not Target:IsInRange(30), true) then return "eternity_surge empower " .. ESEmpower; end
end

local function FB()
  local FBRemains = Target:DebuffRemains(S.FireBreath)
  -- fire_breath,empower_to=1,if=(20+2*talent.blast_furnace.rank)+dot.fire_breath_damage.remains<(20+2*talent.blast_furnace.rank)*1.3|buff.dragonrage.remains<1.75*spell_haste&buff.dragonrage.remains>=1*spell_haste|active_enemies<=2
  if ((20 + 2 * BFRank) + FBRemains < (20 + 2 * BFRank) * 1.3 or VarDragonrageRemains < 1.75 * PlayerHaste and VarDragonrageRemains >= 1 * PlayerHaste or EnemiesCount8ySplash <= 2) then
    FBEmpower = 1
  -- fire_breath,empower_to=2,if=(14+2*talent.blast_furnace.rank)+dot.fire_breath_damage.remains<(20+2*talent.blast_furnace.rank)*1.3|buff.dragonrage.remains<2.5*spell_haste&buff.dragonrage.remains>=1.75*spell_haste
  elseif ((14 + 2 * BFRank) + FBRemains < (20 + 2 * BFRank) * 1.3 or VarDragonrageRemains < 2.5 * PlayerHaste and VarDragonrageRemains >= 1.75 * PlayerHaste) then
    FBEmpower = 2
  -- fire_breath,empower_to=3,if=(8+2*talent.blast_furnace.rank)+dot.fire_breath_damage.remains<(20+2*talent.blast_furnace.rank)*1.3|!talent.font_of_magic|buff.dragonrage.remains<=3.25*spell_haste&buff.dragonrage.remains>=2.5*spell_haste
  elseif ((8 + 2 * BFRank) + FBRemains < (20 + 2 * BFRank) * 1.3 or (not S.FontofMagic:IsAvailable()) or VarDragonrageRemains <= 3.25 * PlayerHaste and VarDragonrageRemains >= 2.5 * PlayerHaste) then
    FBEmpower = 3
  -- fire_breath,empower_to=4
  else
    FBEmpower = 4
  end
  if Press(M.FireBreathMacro, not Target:IsInRange(30), true) then return "fire_breath empower " .. FBEmpower; end
end

local function Aoe()
  -- deep_breath,if=talent.imminent_destruction&cooldown.fire_breath.remains<=gcd.max*7&cooldown.eternity_surge.remains<gcd.max*7
  if S.DeepBreath:IsCastable() and CDsON() and Settings.Devastation.Enabled.DeepBreath and (S.ImminentDestruction:IsAvailable() and S.FireBreath:CooldownRemains() <= GCDMax * 7 and S.EternitySurge:CooldownRemains() < GCDMax * 7) and Mouseover and Mouseover:Exists() and Mouseover:GUID() == Target:GUID() then
    if Press(M.DeepBreathCursor, not Target:IsInRange(50)) then return "deep_breath aoe 2"; end
  end
  -- dragonrage,if=cooldown.fire_breath.remains<=gcd.max&cooldown.eternity_surge.remains<3*gcd.max
  if S.Dragonrage:IsCastable() and CDsON() and (S.FireBreath:CooldownRemains() <= GCDMax and S.EternitySurge:CooldownRemains() < 3 * GCDMax) then
    if Press(S.Dragonrage) then return "dragonrage aoe 2"; end
  end
  -- tip_the_scales,if=buff.dragonrage.up&(spell_targets.pyre<=6|!cooldown.fire_breath.up)
  if S.TipTheScales:IsCastable() and CDsON() and (VarDragonrageUp and (EnemiesCount8ySplash <= 6 or S.FireBreath:CooldownDown())) then
    if Press(S.TipTheScales, not Target:IsInRange(30), nil, true) then return "tip_the_scales aoe 4"; end
  end
  -- Handle FireBreath
  if S.FireBreath:IsCastable() then
    FBEmpower = 0
    local SpellHaste = Player:SpellHaste()
    -- fire_breath,empower_to=1,if=buff.dragonrage.remains<1.75*spell_haste&buff.dragonrage.remains>=1*spell_haste|cooldown.dragonrage.remains>10&(spell_targets.pyre>=8|spell_targets.pyre<=3)&buff.dragonrage.up&buff.dragonrage.remains>=10|buff.dragonrage.up&spell_targets.pyre<=3&!talent.raging_inferno&talent.catalyze
    if (VarDragonrageRemains < 1.75 * SpellHaste and VarDragonrageRemains >= 1 * SpellHaste or S.Dragonrage:CooldownRemains() > 10 and (EnemiesCount8ySplash >= 8 or EnemiesCount8ySplash <= 3) and VarDragonrageUp and VarDragonrageRemains >= 10 or VarDragonrageUp and EnemiesCount8ySplash <= 3 and (not S.RagingInferno:IsAvailable()) and S.Catalyze:IsAvailable()) then
      FBEmpower = 1
    -- fire_breath,empower_to=2,if=buff.dragonrage.remains<2.5*spell_haste&buff.dragonrage.remains>=1.75*spell_haste
    elseif (VarDragonrageRemains < 2.5 * SpellHaste and VarDragonrageRemains >= 1.75 * SpellHaste) then
      FBEmpower = 2
    -- fire_breath,empower_to=3,if=(!talent.font_of_magic|(spell_targets.pyre==5&!talent.volatility&!talent.charged_blast&talent.catalyze&!talent.raging_inferno))&cooldown.dragonrage.remains>10|buff.dragonrage.remains<=3.25*spell_haste&buff.dragonrage.remains>=2.5*spell_haste
    elseif (((not S.FontofMagic:IsAvailable()) or (EnemiesCount8ySplash == 5 and (not S.Volatility:IsAvailable()) and (not S.ChargedBlast:IsAvailable()) and S.Catalyze:IsAvailable() and not S.RagingInferno:IsAvailable())) and S.Dragonrage:CooldownRemains() > 10 or VarDragonrageRemains <= 3.25 * SpellHaste and VarDragonrageRemains >= 2.5 * SpellHaste) then
      FBEmpower = 3
    -- fire_breath,empower_to=4,if=cooldown.dragonrage.remains>10
    elseif (S.Dragonrage:CooldownRemains() > 10) then
      FBEmpower = 4
    end
    if FBEmpower > 0 then
      if Press(M.FireBreathMacro, not Target:IsInRange(30), true) then return "fire_breath empower " .. FBEmpower .. " aoe 8"; end
    end
  end
  -- call_action_list,name=es,if=buff.dragonrage.up|!talent.dragonrage|cooldown.dragonrage.remains>15
  if S.EternitySurge:IsCastable() and (VarDragonrageUp or (not S.Dragonrage:IsAvailable()) or (not CDsON()) or S.Dragonrage:CooldownRemains() > 15) then
    local ShouldReturn = ES(); if ShouldReturn then return ShouldReturn; end
  end
  -- azure_strike,if=buff.dragonrage.up&buff.dragonrage.remains<(buff.essence_burst.max_stack-buff.essence_burst.stack)*gcd.max
  if S.AzureStrike:IsCastable() and (VarDragonrageUp and VarDragonrageRemains < (MaxEssenceBurstStack - Player:BuffStack(S.EssenceBurstBuff)) * GCDMax) then
    if Press(S.AzureStrike, not Target:IsSpellInRange(S.AzureStrike)) then return "azure_strike aoe 8"; end
  end
  -- deep_breath,if=!buff.dragonrage.up
  if S.DeepBreath:IsCastable() and CDsON() and Settings.Devastation.Enabled.DeepBreath and (not VarDragonrageUp) and Mouseover and Mouseover:Exists() and Mouseover:GUID() == Target:GUID() then
   if Press(M.DeepBreathCursor, not Target:IsInRange(50)) then return "deep_breath aoe 10"; end
  end
  -- shattering_star
  if S.ShatteringStar:IsCastable() then
    if Press(S.ShatteringStar, not Target:IsSpellInRange(S.ShatteringStar)) then return "shattering_star aoe 14"; end
  end
  -- azure_strike,if=cooldown.dragonrage.remains<gcd.max*6&cooldown.fire_breath.remains<6*gcd.max&cooldown.eternity_surge.remains<6*gcd.max
  if S.AzureStrike:IsCastable() and (S.Dragonrage:CooldownRemains() < GCDMax * 6 and CDsON() and S.FireBreath:CooldownRemains() < 6 * GCDMax and S.EternitySurge:CooldownRemains() < 6 * GCDMax) then
    if Press(S.AzureStrike, not Target:IsSpellInRange(S.AzureStrike)) then return "azure_strike aoe 16"; end
  end
  -- firestorm
  if S.Firestorm:IsCastable() then
    if Press(S.Firestorm, not Target:IsInRange(25), Immovable) then return "firestorm aoe 12"; end
  end
  -- pyre,if=talent.volatility
  if S.Pyre:IsReady() and (S.Volatility:IsAvailable() and Player:BuffStack(S.ChargedBlastBuff) >= 10) and not Player:IsChanneling() then
    if Press(S.Pyre, not Target:IsSpellInRange(S.Pyre)) then return "pyre aoe 18"; end
  end
  -- pyre,if=talent.volatility&spell_targets.pyre>=4
  if S.Pyre:IsReady() and (S.Volatility:IsAvailable() and EnemiesCount8ySplash >= 4) and not Player:IsChanneling() then
    if Press(S.Pyre, not Target:IsSpellInRange(S.Pyre)) then return "pyre aoe 20"; end
  end
  -- living_flame,if=buff.burnout.up&buff.leaping_flames.up&!buff.essence_burst.up
  if S.LivingFlame:IsCastable() and (Player:BuffUp(S.BurnoutBuff) and Player:BuffUp(S.LeapingFlamesBuff) and Player:BuffDown(S.EssenceBurstBuff)) then
    if Press(S.LivingFlame, not Target:IsSpellInRange(S.LivingFlame), Immovable) then return "living_flame aoe 22"; end
  end
  -- Handle Pyre
  if S.Pyre:IsReady() and (S.Dragonrage:CooldownRemains() >= 10 or (not CDsON())) then
    -- pyre,if=cooldown.dragonrage.remains>=10&spell_targets.pyre>=6
    if EnemiesCount8ySplash >= 6 then
      if Press(S.Pyre, not Target:IsSpellInRange(S.Pyre)) then return "pyre aoe 26"; end
    end
    -- pyre,if=cooldown.dragonrage.remains>=10&spell_targets.pyre>=5&((buff.charged_blast.stack>=3)|(talent.raging_inferno&debuff.in_firestorm.up))
    if EnemiesCount8ySplash >= 5 and (Player:BuffStack(S.ChargedBlastBuff) >= 3 or (S.RagingInferno:IsAvailable() and InFirestorm())) then
      if Press(S.Pyre, not Target:IsSpellInRange(S.Pyre)) then return "pyre aoe 28"; end
    end
    -- pyre,if=cooldown.dragonrage.remains>=10&spell_targets.pyre>=4&((buff.charged_blast.stack>=12)|(talent.raging_inferno&debuff.in_firestorm.up))
    if EnemiesCount8ySplash >= 4 and (Player:BuffStack(S.ChargedBlastBuff) >= 12 or (S.RagingInferno:IsAvailable() and InFirestorm())) then
      if Press(S.Pyre, not Target:IsSpellInRange(S.Pyre)) then return "pyre aoe 30"; end
    end
    -- pyre,if=cooldown.dragonrage.remains>=10&spell_targets.pyre=3&buff.charged_blast.stack>=16
    if EnemiesCount8ySplash == 3 and Player:BuffStack(S.ChargedBlastBuff) >= 16 then
      if Press(S.Pyre, not Target:IsSpellInRange(S.Pyre)) then return "pyre aoe 32"; end
    end
  end
  -- disintegrate,chain=1,if=!talent.shattering_star|cooldown.shattering_star.remains>5|essence>essence.max-1|buff.essence_burst.stack==buff.essence_burst.max_stack
  if S.Disintegrate:IsReady() and (VarDragonrageUp or ((not S.ShatteringStar:IsAvailable()) or S.ShatteringStar:CooldownRemains() > 6 or Player:Essence() > Player:EssenceMax() - 1 or Player:BuffStack(S.EssenceBurstBuff) == MaxEssenceBurstStack)) then
    if Press(S.Disintegrate, not Target:IsSpellInRange(S.Disintegrate), Immovable) then return "disintegrate aoe 26"; end
  end
  -- living_flame,if=talent.snapfire&buff.burnout.up
  if S.LivingFlame:IsCastable() and (S.Snapfire:IsAvailable() and Player:BuffUp(S.BurnoutBuff)) then
    if Press(S.LivingFlame, not Target:IsSpellInRange(S.LivingFlame), Immovable) then return "living_flame aoe 28"; end
  end
  -- azure_strike
  if S.AzureStrike:IsCastable() then
    if Press(S.AzureStrike, not Target:IsSpellInRange(S.AzureStrike)) then return "azure_strike aoe 30"; end
  end
end

local function ST()
  -- dragonrage,if=cooldown.fire_breath.remains<gcd.max&cooldown.eternity_surge.remains<2*gcd.max|fight_remains<30
  if S.Dragonrage:IsCastable() and CDsON() and (S.FireBreath:CooldownRemains() < GCDMax and S.EternitySurge:CooldownRemains() < 2 * GCDMax or FightRemains < 30) then
    if Press(S.Dragonrage) then return "dragonrage st 2"; end
  end
  -- tip_the_scales,if=buff.dragonrage.up&(buff.dragonrage.remains<variable.r1_cast_time&(buff.dragonrage.remains>cooldown.fire_breath.remains|buff.dragonrage.remains>cooldown.eternity_surge.remains)|talent.feed_the_flames&!cooldown.fire_breath.up)
  if S.TipTheScales:IsCastable() and CDsON() and (VarDragonrageUp and (VarDragonrageRemains < VarR1CastTime and (VarDragonrageRemains > S.FireBreath:CooldownRemains() or VarDragonrageRemains > S.EternitySurge:CooldownRemains()) or S.FeedtheFlames:IsAvailable() and S.FireBreath:CooldownDown())) then
    if Press(S.TipTheScales, not Target:IsInRange(30), nil, true) then return "tip_the_scales st 4"; end
  end
  -- call_action_list,name=fb,if=!talent.dragonrage|variable.next_dragonrage>15|!talent.animosity
  -- call_action_list,name=es,if=!talent.dragonrage|variable.next_dragonrage>15|!talent.animosity
  if ((not S.Dragonrage:IsAvailable()) or (not CDsON()) or VarNextDragonrage > 15 or not S.Animosity:IsAvailable()) then
    if S.FireBreath:IsReady() then
      local ShouldReturn = FB(); if ShouldReturn then return ShouldReturn; end
    end
    if S.EternitySurge:IsReady() then
      local ShouldReturn = ES(); if ShouldReturn then return ShouldReturn; end
    end
  end
  -- wait,sec=cooldown.fire_breath.remains,if=talent.animosity&buff.dragonrage.up&buff.dragonrage.remains<gcd.max+variable.r1_cast_time*buff.tip_the_scales.down&buff.dragonrage.remains-cooldown.fire_breath.remains>=variable.r1_cast_time*buff.tip_the_scales.down
  if (S.Animosity:IsAvailable() and VarDragonrageUp and VarDragonrageRemains < GCDMax + VarR1CastTime * num(Player:BuffDown(S.TipTheScales)) and VarDragonrageRemains - S.FireBreath:CooldownRemains() >= VarR1CastTime * num(Player:BuffDown(S.TipTheScales))) then
    if Press(S.Pool) then return "Wait for Fire Breath st 6"; end
  end
  -- wait,sec=cooldown.eternity_surge.remains,if=talent.animosity&buff.dragonrage.up&buff.dragonrage.remains<gcd.max+variable.r1_cast_time&buff.dragonrage.remains-cooldown.eternity_surge.remains>=variable.r1_cast_time*buff.tip_the_scales.down
  if (S.Animosity:IsAvailable() and VarDragonrageUp and VarDragonrageRemains < GCDMax + VarR1CastTime and VarDragonrageRemains - S.EternitySurge:CooldownRemains() >= VarR1CastTime * num(Player:BuffDown(S.TipTheScales))) then
    if Press(S.Pool) then return "Wait for Eternity Surge st 8"; end
  end
  -- shattering_star,if=!buff.dragonrage.up|buff.essence_burst.stack==buff.essence_burst.max_stack|talent.eye_of_infinity
  if S.ShatteringStar:IsCastable() and ((not VarDragonrageUp) or Player:BuffStack(S.EssenceBurstBuff) == MaxEssenceBurstStack or S.EyeofInfinity:IsAvailable()) then
    if Press(S.ShatteringStar, not Target:IsSpellInRange(S.ShatteringStar)) then return "shattering_star st 10"; end
  end
  -- living_flame,if=buff.dragonrage.up&buff.dragonrage.remains<(buff.essence_burst.max_stack-buff.essence_burst.stack)*gcd.max&buff.burnout.up
  if S.LivingFlame:IsCastable() and (VarDragonrageUp and VarDragonrageRemains < (MaxEssenceBurstStack - Player:BuffStack(S.EssenceBurstBuff)) * GCDMax and Player:BuffUp(S.BurnoutBuff)) then
    if Press(S.LivingFlame, not Target:IsSpellInRange(S.LivingFlame), Immovable) then return "living_flame st 12"; end
  end
  -- azure_strike,if=buff.dragonrage.up&buff.dragonrage.remains<(buff.essence_burst.max_stack-buff.essence_burst.stack)*gcd.max
  if S.AzureStrike:IsCastable() and (VarDragonrageUp and VarDragonrageRemains < (MaxEssenceBurstStack - Player:BuffStack(S.EssenceBurstBuff)) * GCDMax) then
    if Press(S.AzureStrike, not Target:IsSpellInRange(S.AzureStrike)) then return "azure_strike st 14"; end
  end
  -- firestorm,if=!buff.dragonrage.up&debuff.shattering_star_debuff.down|buff.snapfire.up
  if S.Firestorm:IsCastable() and ((not VarDragonrageUp) and Target:DebuffDown(S.ShatteringStar) or Player:BuffUp(S.SnapfireBuff)) then
    if Press(S.Firestorm, not Target:IsInRange(25), Immovable) then return "firestorm st 18"; end
  end
  -- living_flame,if=buff.burnout.up&buff.essence_burst.stack<buff.essence_burst.max_stack&essence<essence.max-1
  if S.LivingFlame:IsCastable() and (Player:BuffUp(S.BurnoutBuff) and Player:BuffStack(S.EssenceBurstBuff) < MaxEssenceBurstStack and Player:Essence() < Player:EssenceMax() - 1) then
    if Press(S.LivingFlame, not Target:IsSpellInRange(S.LivingFlame), Immovable) then return "living_flame st 20"; end
  end
  -- azure_strike,if=buff.dragonrage.up&(essence<3&!buff.essence_burst.up|(talent.shattering_star&cooldown.shattering_star.remains<=(buff.essence_burst.max_stack-buff.essence_burst.stack)*gcd.max))
  if S.AzureStrike:IsCastable() and (VarDragonrageUp and (Player:Essence() < 3 and Player:BuffDown(S.EssenceBurstBuff) or (S.ShatteringStar:IsAvailable() and S.ShatteringStar:CooldownRemains() <= (MaxEssenceBurstStack - Player:BuffStack(S.EssenceBurstBuff)) * GCDMax))) then
    if Press(S.AzureStrike, not Target:IsSpellInRange(S.AzureStrike)) then return "azure_strike st 24"; end
  end
  -- disintegrate,chain=1,early_chain_if=evoker.use_early_chaining&buff.dragonrage.up&ticks>=2,interrupt_if=buff.dragonrage.up&ticks>=2&(evoker.use_clipping|cooldown.fire_breath.up|cooldown.eternity_surge.up),if=buff.dragonrage.up|(!talent.shattering_star|cooldown.shattering_star.remains>6|essence>essence.max-1|buff.essence_burst.stack==buff.essence_burst.max_stack)
  -- Note: Chaining is up to the user. We will display this for the next action, but the user must decide when to press the button.
  if S.Disintegrate:IsCastable() and (VarDragonrageUp or ((not S.ShatteringStar:IsAvailable()) or S.ShatteringStar:CooldownRemains() > 6 or Player:Essence() > Player:EssenceMax() - 1 or Player:BuffStack(S.EssenceBurstBuff) == MaxEssenceBurstStack)) then
    if Press(S.Disintegrate, not Target:IsSpellInRange(S.Disintegrate), Immovable) then return "disintegrate st 26"; end
  end
  -- deep_breath,if=!buff.dragonrage.up&spell_targets.deep_breath>1
  if S.DeepBreath:IsCastable() and CDsON() and Settings.Devastation.Enabled.DeepBreath and ((not VarDragonrageUp) and EnemiesCount8ySplash > 1) and Mouseover and Mouseover:Exists() and Mouseover:GUID() == Target:GUID() then
   if Press(M.DeepBreathCursor, not Target:IsInRange(50)) then return "deep_breath st 32"; end
  end
  -- living_flame
  if S.LivingFlame:IsCastable() then
    if Press(S.LivingFlame, not Target:IsSpellInRange(S.LivingFlame), Immovable) then return "living_flame st 36"; end
  end
  -- azure_strike
  if S.AzureStrike:IsCastable() then
    if Press(S.AzureStrike, not Target:IsSpellInRange(S.AzureStrike)) then return "azure_strike st 38"; end
  end
end

-- APL Main
local function APL()
  if Player:IsChanneling(S.EternitySurge) then
    local ESCastTime = (ESEmpower > 0 and GetUnitEmpowerStageDuration("player", 0) or 0)
                        + (ESEmpower > 1 and GetUnitEmpowerStageDuration("player", 1) or 0)
                        + (ESEmpower > 2 and GetUnitEmpowerStageDuration("player", 2) or 0)
                        + (ESEmpower > 3 and GetUnitEmpowerStageDuration("player", 3) or 0)
    if (GetTime() - Player:ChannelStart()) * 1000 > ESCastTime then
      if Press(M.EternitySurgeMacro, nil, nil, true) then return "ES " .. ESCastTime; end
    end
    if Press(S.Pool) then return "Pool for ES " .. ESCastTime; end
  end
  if Player:IsChanneling(S.FireBreath) then
    local FBCastTime = (FBEmpower > 0 and GetUnitEmpowerStageDuration("player", 0) or 0)
                        + (FBEmpower > 1 and GetUnitEmpowerStageDuration("player", 1) or 0)
                        + (FBEmpower > 2 and GetUnitEmpowerStageDuration("player", 2) or 0)
                        + (FBEmpower > 3 and GetUnitEmpowerStageDuration("player", 3) or 0)
    if (GetTime() - Player:ChannelStart()) * 1000 > FBCastTime then
      if Press(M.FireBreathMacro, nil, nil, true) then return "FB " .. FBCastTime; end
    end
    if Press(S.Pool) then return "Pool for FB " .. FBCastTime; end
  end
  
  Immovable = Player:BuffRemains(S.HoverBuff) < 2
  Enemies25y = Player:GetEnemiesInRange(25)
  Enemies8ySplash = Target:GetEnemiesInSplashRange(8)
  if (AoEON()) then
    EnemiesCount8ySplash = #Enemies8ySplash
  else
    EnemiesCount8ySplash = 1
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies25y, false)
    end
  end

  -- Set GCDMax (add 0.25 seconds for latency/player reaction)
  GCDMax = Player:GCD() + 0.25

  -- Player haste value is used in multiple places
  PlayerHaste = Player:SpellHaste()

  -- Set Dragonrage Variables
  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    VarDragonrageUp = Player:BuffUp(S.Dragonrage)
    VarDragonrageRemains = VarDragonrageUp and Player:BuffRemains(S.Dragonrage) or 0
  end
  
  if not Player:AffectingCombat() then
    -- Manually added: Group buff check
    if Settings.Commons.Enabled.BlessingoftheBronze and S.BlessingoftheBronze:IsCastable() and (Player:BuffDown(S.BlessingoftheBronzeBuff) or Everyone.GroupBuffMissing(S.BlessingoftheBronzeBuff)) then
      if Press(S.BlessingoftheBronze) then return "blessing_of_the_bronze precombat"; end
    end
  end
  
  -- Explosives
  if (Settings.General.Enabled.HandleExplosives) then
    local ShouldReturn = Everyone.HandleExplosive(S.AzureStrike, M.AzureStrikeMouseover); if ShouldReturn then return ShouldReturn; end
  end

  if Everyone.TargetIsValid() then
    -- Precombat
    if not Player:AffectingCombat() and not Player:IsCasting() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- Defensives
    if Player:AffectingCombat() then
      local ShouldReturn = Defensives(); if ShouldReturn then return ShouldReturn; end
    end
    -- Manually added: Interrupts
    if not Player:IsCasting() and not Player:IsChanneling() then
      local ShouldReturn = Everyone.Interrupt(S.Quell, 10, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.TailSwipe, 8); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.Interrupt(S.Quell, 10, true, Mouseover, M.QuellMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- variable,name=next_dragonrage,value=cooldown.dragonrage.remains<?(cooldown.eternity_surge.remains-2*gcd.max)<?(cooldown.fire_breath.remains-gcd.max)
    VarNextDragonrage = mathmax(S.Dragonrage:CooldownRemains(), (S.EternitySurge:CooldownRemains() - 2 * GCDMax), (S.FireBreath:CooldownRemains() - GCDMax))
    -- variable,name=r1_cast_time,value=1.3*spell_haste
    VarR1CastTime = 1.3 * PlayerHaste
    -- invoke_external_buff,name=power_infusion,if=buff.dragonrage.up&!buff.power_infusion.up
    -- Note: Not handling external buffs.
    -- call_action_list,name=trinkets
    if Settings.General.Enabled.Trinkets and CDsON() then
      local ShouldReturn = Trinkets(); if ShouldReturn then return ShouldReturn; end
    end
    -- run_action_list,name=aoe,if=spell_targets.pyre>=3
    if EnemiesCount8ySplash >= 3 then
      local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
      if Press(S.Pool) then return "Pool for Aoe()"; end
    end
    -- run_action_list,name=st
    local ShouldReturn = ST(); if ShouldReturn then return ShouldReturn; end
    if Press(S.Pool) then return "Pool for ST()"; end
  end
end

local function AutoBind()
  -- Spell Binds
  Bind(S.AzureStrike)
  Bind(S.BlessingoftheBronze)
  Bind(S.Disintegrate)
  Bind(S.Dragonrage)
  Bind(S.EternitySurge)
  Bind(S.FireBreath)
  Bind(S.Firestorm)
  Bind(S.LivingFlame)
  Bind(S.ObsidianScales)
  Bind(S.Pyre)
  Bind(S.ShatteringStar)
  Bind(S.TailSwipe)
  Bind(S.TipTheScales)
  Bind(S.WingBuffet)
  Bind(S.Quell)
  
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  
  -- Macros
  Bind(M.AzureStrikeMouseover)
  Bind(M.DeepBreathCursor)
  Bind(M.EternitySurgeMacro)
  Bind(M.FireBreathMacro)
  Bind(M.QuellMouseover)
end

local function Init()
  WR.Print("Devastation Evoker by Worldy.")
  AutoBind()
end

WR.SetAPL(1467, APL, Init);
