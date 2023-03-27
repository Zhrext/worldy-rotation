--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC           = HeroDBC.DBC
-- HeroLib
local HL            = HeroLib
local Cache         = HeroCache
local Unit          = HL.Unit
local Player        = Unit.Player
local Focus         = Unit.Focus
local Mouseover     = Unit.MouseOver
local Pet           = Unit.Pet
local Target        = Unit.Target
local Spell         = HL.Spell
local Item          = HL.Item
-- WorldyRotation
local WR            = WorldyRotation
local Bind          = WR.Bind
local Macro         = WR.Macro
local AoEON         = WR.AoEON
local CDsON         = WR.CDsON
local Cast          = WR.Cast
local Press         = WR.Press
-- Num/Bool Helper Functions
local num           = WR.Commons.Everyone.num
local bool          = WR.Commons.Everyone.bool
-- Lua

--- ============================ CONTENT ============================
--- ======= APL LOCALS =======
-- Commons
local Everyone = WR.Commons.Everyone

-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Warlock.Commons,
  Affliction = WR.GUISettings.APL.Warlock.Affliction
}

-- Spells
local S = Spell.Warlock.Affliction

-- Items
local I = Item.Warlock.Affliction
local TrinketsOnUseExcludes = {
  I.ConjuredChillglobe:ID(),
  I.DesperateInvokersCodex:ID(),
}

-- Macros
local M = Macro.Warlock.Affliction;

-- Enemies
local Enemies40y, Enemies10ySplash, EnemiesCount10ySplash
local VarPSUp, VarVTUp, VarSRUp, VarCDDoTsUp, VarHasCDs, VarCDsActive
local BossFightRemains = 11111
local FightRemains = 11111

-- Register
HL:RegisterForEvent(function()
  S.SeedofCorruption:RegisterInFlight()
  S.ShadowBolt:RegisterInFlight()
  S.Haunt:RegisterInFlight()
end, "LEARNED_SPELL_IN_TAB")
S.SeedofCorruption:RegisterInFlight()
S.ShadowBolt:RegisterInFlight()
S.Haunt:RegisterInFlight()

HL:RegisterForEvent(function()
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

local function EvaluateAgony(TargetUnit)
  -- target_if=remains<5,if=active_dot.agony<5
  return (TargetUnit:DebuffRemains(S.AgonyDebuff) < 5)
end

local function EvaluateAgonyRefreshable(TargetUnit)
  -- target_if=refreshable
  return (TargetUnit:DebuffRefreshable(S.AgonyDebuff))
end

local function EvaluateSiphonLife(TargetUnit)
  -- target_if=remains<5,if=active_dot.siphon_life<3
  return (TargetUnit:DebuffRemains(S.SiphonLifeDebuff) < 3)
end

local function EvaluateCorruption(TargetUnit)
  -- target_if=remains<5
  return (TargetUnit:DebuffRemains(S.CorruptionDebuff) < 5)
end

local function EvaluateCorruptionRefreshable(TargetUnit)
  -- target_if=refreshable
  return (TargetUnit:DebuffRefreshable(S.CorruptionDebuff))
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- summon_pet - Moved to APL()
  -- variable,name=cleave_apl,default=0,op=reset
  -- grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
  if S.GrimoireofSacrifice:IsCastable() then
    if Press(S.GrimoireofSacrifice) then return "grimoire_of_sacrifice precombat 2"; end
  end
  -- snapshot_stats
  -- seed_of_corruption,if=spell_targets.seed_of_corruption_aoe>3
  -- NYI precombat multi target
  -- haunt
  if S.Haunt:IsReady() then
    if Press(S.Haunt, not Target:IsSpellInRange(S.Haunt), true) then return "haunt precombat 6"; end
  end
  -- unstable_affliction,if=!talent.soul_swap
  if S.UnstableAffliction:IsReady() and (not S.SoulSwap:IsAvailable()) then
    if Press(S.UnstableAffliction, not Target:IsSpellInRange(S.UnstableAffliction), true) then return "unstable_affliction precombat 8"; end
  end
  -- shadow_bolt
  if S.ShadowBolt:IsReady() then
    if Press(S.ShadowBolt, not Target:IsSpellInRange(S.ShadowBolt), true) then return "shadow_bolt precombat 10"; end
  end
end

local function Variables()
  -- variable,name=ps_up,op=set,value=dot.phantom_singularity.ticking|!talent.phantom_singularity
  VarPSUp = (Target:DebuffUp(S.PhantomSingularityDebuff) or not S.PhantomSingularity:IsAvailable())
  -- variable,name=vt_up,op=set,value=dot.vile_taint_dot.ticking|!talent.vile_taint
  VarVTUp = (Target:DebuffUp(S.VileTaintDebuff) or not S.VileTaint:IsAvailable())
  -- variable,name=sr_up,op=set,value=dot.soul_rot.ticking|!talent.soul_rot
  VarSRUp = (Target:DebuffUp(S.SoulRotDebuff) or not S.SoulRot:IsAvailable())
  -- variable,name=cd_dots_up,op=set,value=variable.ps_up&variable.vt_up&variable.sr_up
  VarCDDoTsUp = (VarPSUp and VarVTUp and VarSRUp)
  -- variable,name=has_cds,op=set,value=talent.phantom_singularity|talent.vile_taint|talent.soul_rot|talent.summon_darkglare
  VarHasCDs = (S.PhantomSingularity:IsAvailable() or S.VileTaint:IsAvailable() or S.SoulRot:IsAvailable() or S.SummonDarkglare:IsAvailable())
  -- variable,name=cds_active,op=set,value=!variable.has_cds|(pet.darkglare.active|variable.cd_dots_up|buff.power_infusion.react)
  VarCDsActive = ((not VarHasCDs) or (HL.GuardiansTable.DarkglareDuration > 0 or VarCDDoTsUp or Player:BuffUp(S.PowerInfusionBuff)))
end

local function Items()
  -- use_items,if=variable.cds_active
  if (VarCDsActive) then
    local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
    if Trinket1ToUse then
      if Press(M.Trinket1, nil, nil, true) then return "trinket1 trinket 2"; end
    end
    local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
    if Trinket2ToUse then
      if Press(M.Trinket2, nil, nil, true) then return "trinket2 trinket 4"; end
    end
  end
  -- use_item,name=desperate_invokers_codex
  if I.DesperateInvokersCodex:IsEquippedAndReady() then
    if Press(I.DesperateInvokersCodex, not Target:IsInRange(45)) then return "desperate_invokers_codex items 2"; end
  end
  -- use_item,name=conjured_chillglobe
  if I.ConjuredChillglobe:IsEquippedAndReady() then
    if Press(I.ConjuredChillglobe) then return "conjured_chillglobe items 4"; end
  end
end

local function oGCD()
  if VarCDsActive then
    -- potion,if=variable.cds_active
    -- TODO
    -- berserking,if=variable.cds_active
    if S.Berserking:IsCastable() then
      if Press(S.Berserking) then return "berserking ogcd 4"; end
    end
    -- blood_fury,if=variable.cds_active
    if S.BloodFury:IsCastable() then
      if Press(S.BloodFury) then return "blood_fury ogcd 6"; end
    end
    -- invoke_external_buff,name=power_infusion,if=variable.cds_active
    -- Note: Not handling external buffs
    -- fireblood,if=variable.cds_active
    if S.Fireblood:IsCastable() then
      if Press(S.Fireblood) then return "fireblood ogcd 8"; end
    end
  end
end

local function AoE()
  -- call_action_list,name=ogcd
  if CDsON() then
    local ShouldReturn = oGCD(); if ShouldReturn then return ShouldReturn; end
  end
  -- call_action_list,name=items
  if CDsON() and Settings.Commons.Enabled.Trinkets then
    local ShouldReturn = Items(); if ShouldReturn then return ShouldReturn; end
  end
  -- haunt
  if S.Haunt:IsReady() then
    if Press(S.Haunt, not Target:IsSpellInRange(S.Haunt), true) then return "haunt aoe 2"; end
  end
  -- vile_taint
  if CDsON() and S.VileTaint:IsReady() then
    if Press(S.VileTaint, not Target:IsInRange(40)) then return "vile_taint aoe 4"; end
  end
  -- phantom_singularity
  if CDsON() and S.PhantomSingularity:IsCastable() then
    if Press(S.PhantomSingularity, not Target:IsSpellInRange(S.PhantomSingularity)) then return "phantom_singularity aoe 6"; end
  end
  -- soul_rot
  if CDsON() and S.SoulRot:IsReady() then
    if Press(S.SoulRot, not Target:IsSpellInRange(S.SoulRot)) then return "soul_rot aoe 8"; end
  end
  -- seed_of_corruption,if=dot.corruption.remains<5
  if S.SeedofCorruption:IsReady() and Target:DebuffRemains(S.SeedofCorruptionDebuff) < 5 then
    if Press(S.SeedofCorruption, not Target:IsSpellInRange(S.SeedofCorruption), true) then return "soul_rot aoe 10"; end
  end
  -- agony,target_if=remains<5,if=active_dot.agony<5
  if S.Agony:IsReady() then
    if Everyone.CastCycle(S.Agony, Enemies40y, EvaluateAgony, not Target:IsSpellInRange(S.Agony)) then return "agony aoe 12"; end
  end
  -- summon_darkglare
  if CDsON() and S.SummonDarkglare:IsCastable() then
    if Press(S.SummonDarkglare) then return "summon_darkglare aoe 14"; end
  end
  -- seed_of_corruption,if=talent.sow_the_seeds
  if S.SeedofCorruption:IsReady() and S.SowTheSeeds:IsAvailable() then
    if Press(S.SeedofCorruption, not Target:IsSpellInRange(S.SeedofCorruption), true) then return "soul_rot aoe 16"; end
  end
  -- malefic_rapture
  if S.MaleficRapture:IsReady() then
    if Press(S.MaleficRapture, not Target:IsInRange(100)) then return "malefic_rapture aoe 18"; end
  end
  -- drain_life,if=(buff.soul_rot.up|!talent.soul_rot)&buff.inevitable_demise.stack>10
  if S.DrainLife:IsReady() and (Target:DebuffUp(S.SoulRotDebuff) or not S.SoulRot:IsAvailable()) and Player:BuffStack(S.InevitableDemiseBuff) > 10 then
    if Press(S.DrainLife, not Target:IsSpellInRange(S.DrainLife)) then return "drain_life aoe 20"; end
  end
  -- summon_soulkeeper,if=buff.tormented_soul.stack=10|buff.tormented_soul.stack>3&time_to_die<10
  if S.SummonSoulkeeper:IsReady() and (S.SummonSoulkeeper:Count() == 10 or S.SummonSoulkeeper:Count() > 3 and FightRemains < 10) then
    if Press(S.SummonSoulkeeper) then return "soul_strike aoe 22"; end
  end
  -- siphon_life,target_if=remains<5,if=active_dot.siphon_life<3
  if S.SiphonLife:IsReady() and EvaluateSiphonLife(Target) then
    if Press(S.SiphonLife, not Target:IsSpellInRange(S.SiphonLife), true) then return "siphon_life aoe 24"; end
  end
  -- drain_soul,interrupt_global=1
  if S.DrainSoul:IsReady() then
    if Press(S.DrainSoul, not Target:IsSpellInRange(S.DrainSoul), true) then return "drain_soul aoe 26"; end
  end
  -- shadow_bolt
  if S.ShadowBolt:IsReady() then
    if Press(S.ShadowBolt, not Target:IsSpellInRange(S.ShadowBolt), true) then return "shadow_bolt aoe 28"; end
  end
end

local function Cleave()
  -- call_action_list,name=ogcd
  if CDsON() then
    local ShouldReturn = oGCD(); if ShouldReturn then return ShouldReturn; end
  end
  -- call_action_list,name=items
  if CDsON() and Settings.Commons.Enabled.Trinkets then
    local ShouldReturn = Items(); if ShouldReturn then return ShouldReturn; end
  end
  -- haunt
  if S.Haunt:IsReady() then
    if Press(S.Haunt, not Target:IsSpellInRange(S.Haunt), true) then return "haunt cleave 2"; end
  end
  -- unstable_affliction,if=remains<5
  if S.UnstableAffliction:IsReady() and (Target:DebuffRemains(S.UnstableAfflictionDebuff) < 5) then
    if Press(S.UnstableAffliction, not Target:IsSpellInRange(S.UnstableAffliction), true) then return "unstable_affliction cleave 6"; end
  end
  -- agony,if=remains<5
  if S.Agony:IsReady() and Target:DebuffRemains(S.AgonyDebuff) < 5 then
    if Press(S.Agony, not Target:IsSpellInRange(S.Agony)) then return "agony cleave 8"; end
  end
  -- agony,target_if=!(target=self.target)&remains<5
  if S.Agony:IsReady() then
    if Everyone.CastCycle(S.Agony, Enemies40y, EvaluateAgony, not Target:IsSpellInRange(S.Agony)) then return "agony cleave 10"; end
  end
  -- siphon_life,if=remains<5
  if S.SiphonLife:IsCastable() and (Target:DebuffRemains(S.SiphonLifeDebuff) < 5) then
    if Press(S.SiphonLife, not Target:IsSpellInRange(S.SiphonLife), true) then return "siphon_life cleave 12"; end
  end
  -- siphon_life,target_if=!(target=self.target)&remains<3
  if S.SiphonLife:IsReady() and EvaluateSiphonLife(Target) then
    if Press(S.SiphonLife, not Target:IsSpellInRange(S.SiphonLife), true) then return "siphon_life cleave 14"; end
  end
  -- seed_of_corruption,if=!talent.absolute_corruption&dot.corruption.remains<5
  if S.SeedofCorruption:IsReady() and not S.AbsoluteCorruption:IsAvailable() and Target:DebuffRemains(S.CorruptionDebuff) < 5 then
    if Press(S.SeedofCorruption, not Target:IsSpellInRange(S.SeedofCorruption), true) then return "seed_of_corruption cleave 16"; end
  end
  -- corruption,target_if=remains<5&(talent.absolute_corruption|!talent.seed_of_corruption)
  if S.Corruption:IsCastable() and (S.AbsoluteCorruption:IsAvailable() or not S.SeedofCorruption:IsAvailable()) then
    if Everyone.CastCycle(S.Corruption, Enemies40y, EvaluateCorruption, not Target:IsSpellInRange(S.Corruption)) then return "corruption cleave 18"; end
  end
  -- phantom_singularity
  if CDsON() and S.PhantomSingularity:IsCastable() then
    if Press(S.PhantomSingularity, not Target:IsSpellInRange(S.PhantomSingularity)) then return "phantom_singularity cleave 20"; end
  end
  -- vile_taint
  if CDsON() and S.VileTaint:IsReady() then
    if Press(S.VileTaint, not Target:IsInRange(40)) then return "vile_taint cleave 22"; end
  end
  -- soul_rot
  if CDsON() and S.SoulRot:IsReady() then
    if Press(S.SoulRot, not Target:IsSpellInRange(S.SoulRot)) then return "soul_rot cleave 24"; end
  end
  -- summon_darkglare
  if CDsON() and S.SummonDarkglare:IsCastable() then
    if Press(S.SummonDarkglare) then return "summon_darkglare cleave 26"; end
  end
  -- malefic_rapture,if=talent.malefic_affliction&buff.malefic_affliction.stack<3
  if S.MaleficRapture:IsReady() and S.MaleficAffliction:IsAvailable() and Player:BuffStack(S.MaleficAfflictionBuff) < 3 then
    if Press(S.MaleficRapture, not Target:IsInRange(100)) then return "malefic_rapture cleave 28"; end
  end
  -- malefic_rapture,if=talent.dread_touch&debuff.dread_touch.remains<gcd
  if S.MaleficRapture:IsReady() and S.DreadTouch:IsAvailable() and Target:DebuffRemains(S.DreadTouchDebuff) < Player:GCD() then
    if Press(S.MaleficRapture, not Target:IsInRange(100)) then return "malefic_rapture cleave 30"; end
  end
  -- malefic_rapture,if=!talent.dread_touch&buff.tormented_crescendo.up
  if S.MaleficRapture:IsReady() and not S.DreadTouch:IsAvailable() and Player:BuffUp(S.TormentedCrescendoBuff) then
    if Press(S.MaleficRapture, not Target:IsInRange(100)) then return "malefic_rapture cleave 32"; end
  end
  -- malefic_rapture,if=!talent.dread_touch&(dot.soul_rot.remains>cast_time|dot.phantom_singularity.remains>cast_time|dot.vile_taint_dot.remains>cast_time|pet.darkglare.active)
  if S.MaleficRapture:IsReady() and not S.DreadTouch:IsAvailable() and (Target:DebuffRemains(S.SoulRotDebuff) > S.MaleficRapture:CastTime() or Target:DebuffRemains(S.PhantomSingularityDebuff) > S.MaleficRapture:CastTime() or Target:DebuffRemains(S.VileTaintDebuff) > S.MaleficRapture:CastTime() or HL.GuardiansTable.DarkglareDuration > 0) then
    if Press(S.MaleficRapture, not Target:IsInRange(100)) then return "malefic_rapture cleave 34"; end
  end
  -- drain_soul,if=buff.nightfall.react
  if S.DrainSoul:IsReady() and Player:BuffUp(S.NightfallBuff) then
    if Press(S.DrainSoul, not Target:IsSpellInRange(S.DrainSoul), true) then return "drain_soul cleave 36"; end
  end
  -- shadow_bolt,if=buff.nightfall.react
  if S.ShadowBolt:IsReady() and Player:BuffUp(S.NightfallBuff) then
    if Press(S.ShadowBolt, not Target:IsSpellInRange(S.ShadowBolt), true) then return "shadow_bolt cleave 38"; end
  end
  -- drain_life,if=buff.inevitable_demise.stack>48|buff.inevitable_demise.stack>20&time_to_die<4
  if S.DrainLife:IsReady() and (Player:BuffStack(S.InevitableDemiseBuff) > 48 or Player:BuffStack(S.InevitableDemiseBuff) > 20 and FightRemains < 4) then
    if Press(S.DrainLife, not Target:IsSpellInRange(S.DrainLife), true) then return "drain_life cleave 40"; end
  end
  -- drain_life,if=buff.soul_rot.up&buff.inevitable_demise.stack>10
  if S.DrainLife:IsReady() and Target:DebuffUp(S.SoulRotDebuff) and Player:BuffStack(S.InevitableDemiseBuff) > 10 then
    if Press(S.DrainLife, not Target:IsSpellInRange(S.DrainLife), true) then return "drain_life cleave 42"; end
  end
  -- agony,target_if=refreshable
  if S.Agony:IsReady() then
    if Everyone.CastCycle(S.Agony, Enemies40y, EvaluateAgonyRefreshable, not Target:IsSpellInRange(S.Agony)) then return "agony cleave 44"; end
  end
  -- corruption,target_if=refreshable
  if S.Corruption:IsCastable() then
    if Everyone.CastCycle(S.Corruption, Enemies40y, EvaluateCorruptionRefreshable, not Target:IsSpellInRange(S.Corruption)) then return "corruption cleave 46"; end
  end
  -- drain_soul,interrupt_global=1
  if S.DrainSoul:IsReady() then
    if Press(S.DrainSoul, not Target:IsSpellInRange(S.DrainSoul), true) then return "drain_soul cleave 48"; end
  end
  -- shadow_bolt
  if S.ShadowBolt:IsReady() then
    if Press(S.ShadowBolt, not Target:IsSpellInRange(S.ShadowBolt), true) then return "shadow_bolt cleave 50"; end
  end
end

--- ======= MAIN =======
local function APL()
  -- Unit Update
  Enemies40y = Player:GetEnemiesInRange(40)
  Enemies10ySplash = Target:GetEnemiesInSplashRange(10)
  if AoEON() then
    EnemiesCount10ySplash = Target:GetEnemiesInSplashRangeCount(10)
  else
    EnemiesCount10ySplash = 1
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies10ySplash, false)
    end
  end

  -- summon_pet 
  if S.SummonPet:IsCastable() and Settings.Commons.Enabled.SummonPet then
    if Press(S.SummonPet) then return "summon_pet ooc"; end
  end

  if Everyone.TargetIsValid() then
    -- Precombat
    if (not Player:AffectingCombat()) then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=variables
    Variables()
    -- call_action_list,name=cleave,if=active_enemies!=1&active_enemies<4|variable.cleave_apl
    if (EnemiesCount10ySplash > 1 and EnemiesCount10ySplash < 4) then
      local ShouldReturn = Cleave(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=aoe,if=active_enemies>3
    if (EnemiesCount10ySplash > 3) then
      local ShouldReturn = AoE(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=ogcd
    if CDsON() then
      local ShouldReturn = oGCD(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=items
    if CDsON() and Settings.Commons.Enabled.Trinkets then
      local ShouldReturn = Items(); if ShouldReturn then return ShouldReturn; end
    end
    -- unstable_affliction,if=remains<5
    if S.UnstableAffliction:IsReady() and (Target:DebuffRemains(S.UnstableAfflictionDebuff) < 5) then
      if Press(S.UnstableAffliction, not Target:IsSpellInRange(S.UnstableAffliction), true) then return "unstable_affliction main 4"; end
    end
    -- agony,if=remains<5
    if S.Agony:IsCastable() and (Target:DebuffRemains(S.AgonyDebuff) < 5) then
      if Press(S.Agony, not Target:IsSpellInRange(S.Agony)) then return "agony main 6"; end
    end
    -- corruption,if=remains<5
    if S.Corruption:IsCastable() and (Target:DebuffRemains(S.CorruptionDebuff) < 5) then
      if Press(S.Corruption, not Target:IsSpellInRange(S.Corruption)) then return "corruption main 8"; end
    end
    -- siphon_life,if=remains<5
    if S.SiphonLife:IsCastable() and (Target:DebuffRemains(S.SiphonLifeDebuff) < 5) then
      if Press(S.SiphonLife, not Target:IsSpellInRange(S.SiphonLife), true) then return "siphon_life main 10"; end
    end
    -- haunt
    if S.Haunt:IsReady() then
      if Press(S.Haunt, not Target:IsSpellInRange(S.Haunt), true) then return "haunt main 12"; end
    end
    -- drain_soul,if=talent.shadow_embrace&(debuff.shadow_embrace.stack<3|debuff.shadow_embrace.remains<3)
    if S.DrainSoul:IsReady() and (S.ShadowEmbrace:IsAvailable() and (Target:DebuffStack(S.ShadowEmbraceDebuff) < 3 or Target:DebuffRemains(S.ShadowEmbraceDebuff) < 3)) then
      if Press(S.DrainSoul, not Target:IsSpellInRange(S.DrainSoul), true) then return "drain_soul main 14"; end
    end
    -- shadow_bolt,if=talent.shadow_embrace&(debuff.shadow_embrace.stack<3|debuff.shadow_embrace.remains<3)
    if S.ShadowBolt:IsReady() and (S.ShadowEmbrace:IsAvailable() and (Target:DebuffStack(S.ShadowEmbraceDebuff) < 3 or Target:DebuffRemains(S.ShadowEmbraceDebuff) < 3)) then
      if Press(S.ShadowBolt, not Target:IsSpellInRange(S.ShadowBolt), true) then return "shadow_bolt main 16"; end
    end
    -- phantom_singularity,if=!talent.soul_rot|cooldown.soul_rot.remains<=execute_time|!talent.summon_darkglare
    if CDsON() and S.PhantomSingularity:IsCastable() and ((not S.SoulRot:IsAvailable()) or S.SoulRot:CooldownRemains() <= S.PhantomSingularity:ExecuteTime() or not S.SummonDarkglare:IsAvailable()) then
      if Press(S.PhantomSingularity, not Target:IsSpellInRange(S.PhantomSingularity)) then return "phantom_singularity main 18"; end
    end
    -- vile_taint,if=!talent.soul_rot|cooldown.soul_rot.remains<=execute_time|talent.souleaters_gluttony.rank<2&cooldown.soul_rot.remains>=12
    if CDsON() and S.VileTaint:IsReady() and ((not S.SoulRot:IsAvailable()) or S.SoulRot:CooldownRemains() <= S.VileTaint:ExecuteTime() or S.SouleatersGluttony:TalentRank() < 2 and S.SoulRot:CooldownRemains() >= 12) then
      if Press(S.VileTaint, not Target:IsInRange(40)) then return "vile_taint main 20"; end
    end
    -- soul_rot,if=variable.ps_up&variable.vt_up|!talent.summon_darkglare
    if CDsON() and S.SoulRot:IsReady() and (VarPSUp and VarVTUp or not S.SummonDarkglare:IsAvailable()) then
      if Press(S.SoulRot, not Target:IsSpellInRange(S.SoulRot)) then return "soul_rot main 22"; end
    end
    -- summon_darkglare,if=variable.ps_up&variable.vt_up&variable.sr_up|cooldown.invoke_power_infusion_0.duration>0&cooldown.invoke_power_infusion_0.up&!talent.soul_rot
    -- Note: Not handling Power Infusion
    if CDsON() and S.SummonDarkglare:IsCastable() and (VarPSUp and VarVTUp and VarSRUp) then
      if Press(S.SummonDarkglare) then return "summon_darkglare main 24"; end
    end
    if S.MaleficRapture:IsReady() and (
      -- malefic_rapture,if=soul_shard>4|(talent.tormented_crescendo&buff.tormented_crescendo.stack=1&soul_shard>3)
      (Player:SoulShardsP() > 4 or (S.TormentedCrescendo:IsAvailable() and Player:BuffStack(S.TormentedCrescendoBuff) == 1 and Player:SoulShardsP() > 3)) or
      -- malefic_rapture,if=talent.dread_touch&talent.malefic_affliction&debuff.dread_touch.remains<2&buff.malefic_affliction.stack=3
      (S.DreadTouch:IsAvailable() and S.MaleficAffliction:IsAvailable() and Target:DebuffRemains(S.DreadTouchDebuff) < 2 and Player:BuffStack(S.MaleficAfflictionBuff) == 3) or
      -- malefic_rapture,if=talent.malefic_affliction&buff.malefic_affliction.stack<3
      (S.MaleficAffliction:IsAvailable() and Player:BuffStack(S.MaleficAfflictionBuff) < 3) or
      -- malefic_rapture,if=talent.tormented_crescendo&buff.tormented_crescendo.react&!debuff.dread_touch.react
      (S.TormentedCrescendo:IsAvailable() and Player:BuffUp(S.TormentedCrescendoBuff) and Target:DebuffDown(S.DreadTouchDebuff)) or
      -- malefic_rapture,if=talent.tormented_crescendo&buff.tormented_crescendo.stack=2
      (S.TormentedCrescendo:IsAvailable() and Player:BuffStack(S.TormentedCrescendoBuff) == 2) or
      -- malefic_rapture,if=variable.cd_dots_up|dot.vile_taint_dot.ticking&soul_shard>1
      (VarCDDoTsUp or Target:DebuffUp(S.VileTaintDebuff) and Player:SoulShardsP() > 1) or
      -- malefic_rapture,if=talent.tormented_crescendo&talent.nightfall&buff.tormented_crescendo.react&buff.nightfall.react
      (S.TormentedCrescendo:IsAvailable() and S.Nightfall:IsAvailable() and Player:BuffUp(S.TormentedCrescendoBuff) and Player:BuffUp(S.NightfallBuff))
    ) then
        if Press(S.MaleficRapture, not Target:IsInRange(100)) then return "malefic_rapture main 26"; end
    end
    -- drain_life,if=buff.inevitable_demise.stack>48|buff.inevitable_demise.stack>20&time_to_die<4
    if S.DrainLife:IsReady() and (Player:BuffStack(S.InevitableDemiseBuff) > 48 or Player:BuffStack(S.InevitableDemiseBuff) > 20 and FightRemains < 4) then
      if Press(S.DrainLife, not Target:IsSpellInRange(S.DrainLife), true) then return "drain_life main 28"; end
    end
    -- drain_soul,if=buff.nightfall.react
    if S.DrainSoul:IsReady() and (Player:BuffUp(S.NightfallBuff)) then
      if Press(S.DrainSoul, not Target:IsSpellInRange(S.DrainSoul), true) then return "drain_soul main 30"; end
    end
    -- shadow_bolt,if=buff.nightfall.react
    if S.ShadowBolt:IsReady() and (Player:BuffUp(S.NightfallBuff)) then
      if Press(S.ShadowBolt, not Target:IsSpellInRange(S.ShadowBolt), true) then return "shadow_bolt main 32"; end
    end
    -- agony,if=refreshable
    if S.Agony:IsCastable() and (Target:DebuffRefreshable(S.AgonyDebuff)) then
      if Press(S.Agony, not Target:IsSpellInRange(S.Agony)) then return "agony main 34"; end
    end
    -- corruption,if=refreshable
    if S.Corruption:IsCastable() and (Target:DebuffRefreshable(S.CorruptionDebuff)) then
      if Press(S.Corruption, not Target:IsSpellInRange(S.Corruption)) then return "corruption main 36"; end
    end
    -- drain_soul,interrupt=1
    if S.DrainSoul:IsReady() then
      if Press(S.DrainSoul, not Target:IsSpellInRange(S.DrainSoul), true) then return "drain_soul main 40"; end
    end
    -- shadow_bolt
    if S.ShadowBolt:IsReady() then
      if Press(S.ShadowBolt, not Target:IsSpellInRange(S.ShadowBolt), true) then return "shadow_bolt main 42"; end
    end
  end
end

local function AutoBind()
end

local function OnInit()
  WR.Print("Affliction Warlock rotation by Worldy.")
  AutoBind()
end

WR.SetAPL(265, APL, OnInit)