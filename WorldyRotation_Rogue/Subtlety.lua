--- Localize Vars
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local HL = HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
local MultiSpell = HL.MultiSpell
local Item = HL.Item
local Utils = HL.Utils
local BoolToInt = HL.Utils.BoolToInt
-- WorldyRotation
local WR = WorldyRotation
local AoEON = WR.AoEON
local CDsON = WR.CDsON
local Macro = WR.Macro
-- Num/Bool Helper Functions
local num = WR.Commons.Everyone.num
local bool = WR.Commons.Everyone.bool
-- Lua
local pairs = pairs
local tableinsert = table.insert
local mathmin = math.min
local mathmax = math.max
local mathabs = math.abs

--- APL Local Vars
-- Commons
local Everyone = WR.Commons.Everyone
local Rogue = WR.Commons.Rogue
-- Define S/I for spell and item arrays
local S = Spell.Rogue.Subtlety
local I = Item.Rogue.Subtlety
local M = Macro.Rogue.Subtlety

-- Rotation Var
local MeleeRange, AoERange, TargetInMeleeRange, TargetInAoERange
local Enemies30y, MeleeEnemies10y, MeleeEnemies10yCount, MeleeEnemies5y
local ShouldReturn; -- Used to get the return string
local PoolingAbility, PoolingEnergy, PoolingFinisher; -- Used to store an ability we might want to pool for as a fallback in the current situation
local RuptureThreshold, RuptureDMGThreshold
local EffectiveComboPoints, ComboPoints, ComboPointsDeficit, StealthEnergyRequired
local PriorityRotation

S.Eviscerate:RegisterDamageFormula(
  -- Eviscerate DMG Formula (Pre-Mitigation):
  --- Player Modifier
    -- AP * CP * EviscR1_APCoef * Aura_M * NS_M * DS_M * DSh_M * SoD_M * Finality_M * Mastery_M * Versa_M
  --- Target Modifier
    -- EviscR2_M * Sinful_M
  function ()
    return
      --- Player Modifier
        -- Attack Power
        Player:AttackPowerDamageMod() *
        -- Combo Points
        EffectiveComboPoints *
        -- Eviscerate R1 AP Coef
        0.176 *
        -- Aura Multiplier (SpellID: 137035)
        1.21 *
        -- Nightstalker Multiplier
        (S.Nightstalker:IsAvailable() and Player:StealthUp(true, false) and 1.08 or 1) *
        -- Deeper Stratagem Multiplier
        (S.DeeperStratagem:IsAvailable() and 1.05 or 1) *
        -- Shadow Dance Multiplier
        (S.DarkShadow:IsAvailable() and Player:BuffUp(S.ShadowDanceBuff) and 1.3 or 1) *
        -- Symbols of Death Multiplier
        (Player:BuffUp(S.SymbolsofDeath) and 1.1 or 1) *
        -- Finality Multiplier
        (Player:BuffUp(S.FinalityEviscerateBuff) and 1.3 or 1) *
        -- Mastery Finisher Multiplier
        (1 + Player:MasteryPct() / 100) *
        -- Versatility Damage Multiplier
        (1 + Player:VersatilityDmgPct() / 100) *
      --- Target Modifier
        -- Eviscerate R2 Multiplier
        (Target:DebuffUp(S.FindWeaknessDebuff) and 1.5 or 1)
  end
)

S.Rupture:RegisterPMultiplier(
  function ()
    return Player:BuffUp(S.FinalityRuptureBuff) and 1.3 or 1
  end
)

-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Rogue.Commons,
  Commons2 = WR.GUISettings.APL.Rogue.Commons2,
  Subtlety = WR.GUISettings.APL.Rogue.Subtlety
}

-- Interrupt
local InterruptWhitelistIDs = { 209413,225100,210261,207980,208165, 211470, 384365, 386024, 387127, 387411, 387614, 387606, 384808, 373395, 376725, 388635, 396640, 396812, 388392, 378850, 383823, 378850, 382077, 387440, 387135 };

local function ShouldInterrupt(Unit)
  if not Unit then
    Unit = Target;
  end
  if Unit:IsInterruptible() and (Unit:IsCasting() or Unit:IsChanneling()) then
    if (Utils.ValueIsInArray(InterruptWhitelistIDs, Unit:CastSpellID()) or Utils.ValueIsInArray(InterruptWhitelistIDs, Unit:ChannelSpellID())) then
      return true
    end
  end
  return false
end

local function ShouldStun(Unit)
  if not Unit then
    Unit = Target;
  end
  if Unit:CanBeStunned() and (Unit:CastPercentage() >= Settings.General.Threshold.Interrupt or Unit:IsChanneling()) then
    if Utils.ValueIsInArray(StunWhitelistIDs, Unit:CastSpellID()) or Utils.ValueIsInArray(StunWhitelistIDs, Unit:ChannelSpellID()) then
      return true
    end
  end
  return false
end

local function SetPoolingFinisher(PoolingSpell)
  if not PoolingFinisher then
    PoolingFinisher = PoolingSpell
  end
end

local function MayBurnShadowDance()
  if Settings.Subtlety.BurnShadowDance == "On Bosses not in Dungeons" and Player:IsInDungeonArea() then
    return false
  elseif Settings.Subtlety.BurnShadowDance ~= "Always" and not Target:IsInBossList() then
    return false
  else
    return true
  end
end

local function UsePriorityRotation()
  if MeleeEnemies10yCount < 2 then
    return false
  elseif Settings.Commons.UsePriorityRotation == "Always" then
    return true
  elseif Settings.Commons.UsePriorityRotation == "On Bosses" and Target:IsInBossList() then
    return true
  elseif Settings.Commons.UsePriorityRotation == "Auto" then
    -- Zul Mythic
    if Player:InstanceDifficulty() == 16 and Target:NPCID() == 138967 then
      return true
    -- Council of Blood
    elseif Target:NPCID() == 166969 or Target:NPCID() == 166971 or Target:NPCID() == 166970 then
      return true
    -- Anduin (Remnant of a Fallen King/Monstrous Soul)
    elseif Target:NPCID() == 183463 or Target:NPCID() == 183671 then
      return true
    end
  end

  return false
end

-- Handle CastLeftNameplate Suggestions for DoT Spells
local function SuggestCycleDoT(DoTSpell, DoTEvaluation, DoTMinTTD, Enemies)
  -- Prefer melee cycle units
  local BestUnit, BestUnitTTD = nil, DoTMinTTD
  local TargetGUID = Target:GUID()
  for _, CycleUnit in pairs(Enemies) do
    if CycleUnit:GUID() ~= TargetGUID and Everyone.UnitIsCycleValid(CycleUnit, BestUnitTTD, -CycleUnit:DebuffRemains(DoTSpell))
    and DoTEvaluation(CycleUnit) then
      BestUnit, BestUnitTTD = CycleUnit, CycleUnit:TimeToDie()
    end
  end
  if BestUnit then
    WR.CastLeftNameplate(BestUnit, DoTSpell)
  -- Check ranged units next, if the RangedMultiDoT option is enabled
  elseif Settings.Commons.RangedMultiDoT then
    BestUnit, BestUnitTTD = nil, DoTMinTTD
    for _, CycleUnit in pairs(MeleeEnemies10y) do
      if CycleUnit:GUID() ~= TargetGUID and Everyone.UnitIsCycleValid(CycleUnit, BestUnitTTD, -CycleUnit:DebuffRemains(DoTSpell))
      and DoTEvaluation(CycleUnit) then
        BestUnit, BestUnitTTD = CycleUnit, CycleUnit:TimeToDie()
      end
    end
    if BestUnit then
      WR.CastLeftNameplate(BestUnit, DoTSpell)
    end
  end
end

-- APL Action Lists (and Variables)
local function Stealth_Threshold ()
  -- actions+=/variable,name=stealth_threshold,value=25+talent.vigor.enabled*20+talent.master_of_shadows.enabled*20+talent.shadow_focus.enabled*25+talent.alacrity.enabled*20+25*(spell_targets.shuriken_storm>=4)
  return 25 + num(S.Vigor:IsAvailable()) * 20 + num(S.MasterofShadows:IsAvailable()) * 20 + num(S.ShadowFocus:IsAvailable()) * 25 + num(S.Alacrity:IsAvailable()) * 20 + num(MeleeEnemies10yCount >= 4) * 25
end
local function ShD_Threshold ()
  -- actions.stealth_cds=variable,name=shd_threshold,value=cooldown.shadow_dance.charges_fractional>=0.75+talent.shadow_dance
  return S.ShadowDance:ChargesFractional() >= 0.75 + BoolToInt(S.ShadowDanceTalent:IsAvailable())
end
local function ShD_Combo_Points ()
  -- actions.stealth_cds+=/variable,name=shd_combo_points,value=combo_points<=1
  -- actions.stealth_cds+=/variable,name=shd_combo_points,value=combo_points.deficit<=1,if=spell_targets.shuriken_storm>(4-2*talent.shuriken_tornado.enabled)|variable.priority_rotation&spell_targets.shuriken_storm>=4
  -- actions.stealth_cds+=/variable,name=shd_combo_points,value=1,if=spell_targets.shuriken_storm=4
  if MeleeEnemies10yCount == (4 - num(S.SealFate:IsAvailable())) then
    return true
  elseif MeleeEnemies10yCount > (4 - 2 * BoolToInt(S.ShurikenTornado:IsAvailable())) or PriorityRotation and MeleeEnemies10yCount >= 4 then
    return ComboPointsDeficit <= 1
  else
    return ComboPoints <= 1
  end
end
local function SnD_Condition ()
  -- actions+=/variable,name=snd_condition,value=buff.slice_and_dice.up|spell_targets.shuriken_storm>=cp_max_spend
  return Player:BuffUp(S.SliceandDice) or MeleeEnemies10yCount >= Rogue.CPMaxSpend()
end
local function Skip_Rupture (ShadowDanceBuff)
  -- actions.finish+=/variable,name=skip_rupture,value=master_assassin_remains>0|!talent.nightstalker.enabled&talent.dark_shadow.enabled&buff.shadow_dance.up|spell_targets.shuriken_storm>=(4-stealthed.all*talent.shadow_focus.enabled)
  -- actions.finish+=/variable,name=skip_rupture,value=buff.thistle_tea.up&spell_targets.shuriken_storm=1|buff.shadow_dance.up&(spell_targets.shuriken_storm=1|dot.rupture.ticking&spell_targets.shuriken_storm>=2)
  return Player:BuffUp(S.ThistleTea) and MeleeEnemies10yCount == 1 or ShadowDanceBuff and (MeleeEnemies10yCount == 1 or Target:DebuffUp(S.Rupture) and MeleeEnemies10yCount >= 2)
end

-- # Finishers
-- ReturnSpellOnly and StealthSpell parameters are to Predict Finisher in case of Stealth Macros
local function Finish(ReturnSpellOnly, StealthSpell)
  local ShadowDanceBuff = Player:BuffUp(S.ShadowDanceBuff) or (StealthSpell and StealthSpell:ID() == S.ShadowDance:ID())
  local ShadowDanceBuffRemains = Player:BuffRemains(S.ShadowDanceBuff)
  if StealthSpell and StealthSpell:ID() == S.ShadowDance:ID() then
    ShadowDanceBuffRemains = 8
  end

  if S.SliceandDice:IsCastable() and HL.FilteredFightRemains(MeleeEnemies10y, ">", Player:BuffRemains(S.SliceandDice)) then
    -- actions.finish=variable,name=premed_snd_condition,value=talent.premeditation.enabled&spell_targets.shuriken_storm<5    
    if S.Premeditation:IsAvailable() and MeleeEnemies10yCount < 5 then
      -- actions.finish+=/slice_and_dice,if=variable.premed_snd_condition&cooldown.shadow_dance.charges_fractional<1.75&buff.slice_and_dice.remains<cooldown.symbols_of_death.remains&(cooldown.shadow_dance.ready&buff.symbols_of_death.remains-buff.shadow_dance.remains<1.2)
      if S.ShadowDance:ChargesFractional() < 1.75 and Player:BuffRemains(S.SliceandDice) < S.SymbolsofDeath:CooldownRemains()
        and (S.ShadowDance:Charges() >= 1 and Player:BuffRemains(S.SymbolsofDeath) - Player:BuffRemains(S.ShadowDanceBuff) < 1.2) then
        if ReturnSpellOnly then
          return S.SliceandDice
        else
          if S.SliceandDice:IsReady() and WR.Cast(S.SliceandDice) then return "Cast Slice and Dice (Premed)" end
        end
      end
    else
      -- actions.finish+=/slice_and_dice,if=!variable.premed_snd_condition&spell_targets.shuriken_storm<6&!buff.shadow_dance.up&buff.slice_and_dice.remains<fight_remains&refreshable
      if MeleeEnemies10yCount < 6 and not ShadowDanceBuff
        and Player:BuffRemains(S.SliceandDice) < (1 + ComboPoints * 1.8) then
        if ReturnSpellOnly then
          return S.SliceandDice
        else
          if S.SliceandDice:IsReady() and WR.Cast(S.SliceandDice) then return "Cast Slice and Dice" end
        end
      end
    end
  end

  local SkipRupture = Skip_Rupture(ShadowDanceBuff)
  -- actions.finish+=/rupture,if=(!variable.skip_rupture|variable.priority_rotation)&target.time_to_die-remains>6&refreshable
  if (not SkipRupture or PriorityRotation) and S.Rupture:IsCastable() and Target:DebuffRefreshable(S.Rupture, RuptureThreshold) and ComboPoints > 0 then
    if TargetInMeleeRange and (Target:FilteredTimeToDie(">", 6, -Target:DebuffRemains(S.Rupture)) or Target:TimeToDieIsNotValid()) and Rogue.CanDoTUnit(Target, RuptureDMGThreshold) and Target:DebuffRefreshable(S.Rupture, RuptureThreshold) then
      if ReturnSpellOnly then
        return S.Rupture
      else
        if S.Rupture:IsReady() and WR.Cast(S.Rupture) then return "Cast Rupture 1" end
      end
    end
  end
  -- actions.finish+=/rupture,if=!variable.skip_rupture&buff.finality_rupture.up&cooldown.shadow_dance.remains<12&cooldown.shadow_dance.charges_fractional<=1&spell_targets.shuriken_storm=1&(talent.dark_brew|talent.danse_macabre)
  if not SkipRupture and S.Rupture:IsCastable() and ComboPoints > 0 then
    if MeleeEnemies10yCount == 1 and Player:BuffUp(S.FinalityRuptureBuff) and (S.DarkBrew:IsAvailable() or S.DanseMacabre:IsAvailable()) and S.ShadowDance:CooldownRemains() < 12 and S.ShadowDance:ChargesFractional() <= 1 then
      if S.Rupture:IsReady() and WR.Cast(S.Rupture) then return "Cast Rupture (Finality)" end
    end
  end
  -- actions.finish+=/cold_blood,if=buff.shadow_dance.up&(buff.danse_macabre.stack>=3|!talent.danse_macabre)&cooldown.secret_technique.ready
  -- actions.finish+=/secret_technique,if=buff.shadow_dance.up&(buff.danse_macabre.stack>=3|!talent.danse_macabre)&(!talent.cold_blood|cooldown.cold_blood.remains>buff.shadow_dance.remains-2)
  if S.SecretTechnique:IsCastable() and ShadowDanceBuff and (Player:BuffStack(S.DanseMacabreBuff) >= 3 or not S.DanseMacabre:IsAvailable()) then
    if (S.ColdBlood:IsReady() and Player:BuffDown(S.ColdBlood)) then
      return M.SecretTechnique
    end
    if Player:BuffUp(S.ColdBlood) or S.ColdBlood:CooldownRemains() > (ShadowDanceBuffRemains - 2) then
      if ReturnSpellOnly then
        return M.SecretTechnique
      end 
    end
  end
  if not SkipRupture and S.Rupture:IsCastable() then
    -- actions.finish+=/rupture,cycle_targets=1,if=!variable.skip_rupture&!variable.priority_rotation&spell_targets.shuriken_storm>=2&target.time_to_die>=(2*combo_points)&refreshable
    if not ReturnSpellOnly and WR.AoEON() and not PriorityRotation and MeleeEnemies10yCount >= 2 then
      local function Evaluate_Rupture_Target(TargetUnit)
        return Everyone.CanDoTUnit(TargetUnit, RuptureDMGThreshold)
          and TargetUnit:DebuffRefreshable(S.Rupture, RuptureThreshold)
      end
      --SuggestCycleDoT(S.Rupture, Evaluate_Rupture_Target, (2 * ComboPoints), MeleeEnemies5y)
    end
    -- actions.finish+=/rupture,if=!variable.skip_rupture&remains<cooldown.symbols_of_death.remains+10&cooldown.symbols_of_death.remains<=5&target.time_to_die-remains>cooldown.symbols_of_death.remains+5
    if TargetInMeleeRange and Target:DebuffRemains(S.Rupture) < S.SymbolsofDeath:CooldownRemains() + 10 and ComboPoints > 0
      and S.SymbolsofDeath:CooldownRemains() <= 5
      and Rogue.CanDoTUnit(Target, RuptureDMGThreshold)
      and Target:FilteredTimeToDie(">", 5 + S.SymbolsofDeath:CooldownRemains(), -Target:DebuffRemains(S.Rupture)) then
      if ReturnSpellOnly then
        return S.Rupture
      else
        if S.Rupture:IsReady() and WR.Cast(S.Rupture) then return "Cast Rupture 2" end
      end
    end
  end
  -- actions.finish+=/black_powder,if=!variable.priority_rotation&spell_targets>=3
  if S.BlackPowder:IsCastable() and not PriorityRotation and MeleeEnemies10yCount >= 3 and ComboPoints > 1 then
    if ReturnSpellOnly then
      return S.BlackPowder
    else
      if S.BlackPowder:IsReady() and WR.Cast(S.BlackPowder) then return "Cast Black Powder" end
    end
  end
  -- actions.finish+=/eviscerate
  if S.Eviscerate:IsCastable() and TargetInMeleeRange and ComboPoints > 1 then
    if ReturnSpellOnly then
      return S.Eviscerate
    else
      if S.Eviscerate:IsReady() and WR.Cast(S.Eviscerate) then return "Cast Eviscerate" end
    end
  end
  return false
end

-- # Stealthed Rotation
-- ReturnSpellOnly and StealthSpell parameters are to Predict Finisher in case of Stealth Macros
local function Stealthed(ReturnSpellOnly, StealthSpell)
  local StealthBuff = Player:BuffUp(Rogue.StealthSpell()) or (StealthSpell and StealthSpell:ID() == Rogue.StealthSpell():ID())
  local VanishBuffCheck = Player:BuffUp(Rogue.VanishBuffSpell()) or (StealthSpell and StealthSpell:ID() == Rogue.VanishBuffSpell():ID())
  local ShadowDanceBuff = Player:BuffUp(S.ShadowDanceBuff) or (StealthSpell and StealthSpell:ID() == S.ShadowDance:ID())
  local ShadowDanceBuffRemains = Player:BuffRemains(S.ShadowDanceBuff)
  local PremeditationBuff = StealthSpell or Player:BuffUp(S.PremeditationBuff)
  if StealthSpell and StealthSpell:ID() == S.ShadowDance:ID() then 
    ShadowDanceBuffRemains = 8
  end
  local ShadowstrikeIsCastable = S.Shadowstrike:IsCastable() or StealthBuff or VanishBuffCheck or ShadowDanceBuff
  if StealthBuff or VanishBuffCheck then
    ShadowstrikeIsCastable = ShadowstrikeIsCastable and Target:IsInRange(25)
  else
    ShadowstrikeIsCastable = ShadowstrikeIsCastable and TargetInMeleeRange
  end

  -- actions.stealthed=shadowstrike,if=(buff.stealth.up|buff.vanish.up)&(spell_targets.shuriken_storm<4|variable.priority_rotation)
  if ShadowstrikeIsCastable and (StealthBuff or VanishBuffCheck) and (MeleeEnemies10yCount < 4 or PriorityRotation) then
    if ReturnSpellOnly then return S.Shadowstrike end
  end

  -- #Variable to Gloomblade / Backstab when on 4 or 5 combo points with premediation and when the combo point is not anima charged
  -- actions.stealthed+=/variable,name=gloomblade_condition,value=buff.danse_macabre.stack<5&(combo_points.deficit=2|combo_points.deficit=3)&(buff.premeditation.up|effective_combo_points<7)&(spell_targets.shuriken_storm<=8|talent.lingering_shadow)
  if Player:BuffStack(S.DanseMacabreBuff) < 5 and (ComboPointsDeficit == 2 or ComboPointsDeficit == 3) and (PremeditationBuff or EffectiveComboPoints < 7) and (MeleeEnemies10yCount <= 8 or S.LingeringShadow:IsAvailable()) then
    -- actions.stealthed+=/shuriken_storm,if=variable.gloomblade_condition&buff.silent_storm.up&!debuff.find_weakness.remains&talent.improved_shuriken_storm.enabled
    if S.ImprovedShurikenStorm:IsAvailable() and (Player:BuffUp(S.SilentStormBuff) or StealthSpell and S.SilentStorm:IsAvailable()) and Target:DebuffDown(S.FindWeaknessDebuff) then
      if ReturnSpellOnly then return S.ShurikenStorm end
    end
    -- actions.stealthed+=/gloomblade,if=variable.gloomblade_condition
    -- actions.stealthed+=/backstab,if=variable.gloomblade_condition&talent.danse_macabre&buff.danse_macabre.stack<=2&spell_targets.shuriken_storm<=2
    if S.Gloomblade:IsCastable() then
      if ReturnSpellOnly then
        if StealthSpell then return S.Gloomblade
        else
          return { S.Gloomblade, S.Stealth }
        end
      end
    elseif S.Backstab:IsCastable() and S.DanseMacabre:IsAvailable() and Player:BuffStack(S.DanseMacabreBuff) <= 2 and MeleeEnemies10yCount <= 2 then
      if ReturnSpellOnly then
        -- If calling from a Stealth macro, we don't need the PV suggestion since it's already a macro cast
        if StealthSpell then
          return S.Backstab
        else
          return { S.Backstab, S.Stealth }
        end
      end
    end
  end

  -- actions.stealthed+=/call_action_list,name=finish,if=effective_combo_points>=cp_max_spend
  
  if EffectiveComboPoints >= Rogue.CPMaxSpend() then
    return Finish(ReturnSpellOnly, StealthSpell)
  end
  -- actions.stealthed+=/call_action_list,name=finish,if=buff.shuriken_tornado.up&combo_points.deficit<=2
  if Player:BuffUp(S.ShurikenTornado) and ComboPointsDeficit <= 2 then
    return Finish(ReturnSpellOnly, StealthSpell)
  end
  -- actions.stealthed+=/call_action_list,name=finish,if=spell_targets.shuriken_storm>=4-talent.seal_fate&variable.effective_combo_points>=4
  if MeleeEnemies10yCount >= (4 - BoolToInt(S.SealFate:IsAvailable())) and EffectiveComboPoints >= 4  then
    return Finish(ReturnSpellOnly, StealthSpell)
  end
  -- actions.stealthed+=/call_action_list,name=finish,if=combo_points.deficit<=1+(talent.seal_fate|talent.deeper_stratagem|talent.secret_stratagem)
  if ComboPointsDeficit <= 1 + num(S.SealFate:IsAvailable() or S.DeeperStratagem:IsAvailable() or S.SecretStratagem:IsAvailable()) then
    return Finish(ReturnSpellOnly, StealthSpell)
  end

  -- As we're in stealth, show a special macro combo with the PV icon to make it clear we are casting Backstab specifically within Shadow Dance
  -- actions.stealthed+=/gloomblade,if=buff.perforated_veins.stack>=5&spell_targets.shuriken_storm<3
  -- actions.stealthed+=/backstab,if=buff.perforated_veins.stack>=5&spell_targets.shuriken_storm<3
  if Player:BuffStack(S.PerforatedVeinsBuff) >= 5 and MeleeEnemies10yCount < 3 then
    if S.Gloomblade:IsCastable() then
      if ReturnSpellOnly then
        -- If calling from a Stealth macro, we don't need the PV suggestion since it's already a macro cast
        if StealthSpell then
          return S.Gloomblade
        else
          return { S.Gloomblade, S.PerforatedVeins }
        end
      end
    elseif S.Backstab:IsCastable() then
      if ReturnSpellOnly then
        -- If calling from a Stealth macro, we don't need the PV suggestion since it's already a macro cast
        if StealthSpell then
          return S.Backstab
        else
          return { S.Backstab, S.PerforatedVeins }
        end
      end
    end
  end
  -- actions.stealthed+=/shadowstrike,if=stealthed.sepsis&spell_targets.shuriken_storm<4
  if ShadowstrikeIsCastable and not Player:StealthUp(true, false) and not StealthSpell and Player:BuffUp(S.SepsisBuff) and MeleeEnemies10yCount < 4 then
    if ReturnSpellOnly then
      return S.Shadowstrike
    end
  end
  -- actions.stealthed+=/shuriken_storm,if=spell_targets>=3+buff.the_rotten.up&(!buff.premeditation.up|spell_targets>=7)
  if WR.AoEON() and S.ShurikenStorm:IsCastable()
    and MeleeEnemies10yCount >= (3 + BoolToInt(Player:BuffUp(S.TheRottenBuff))) and (not PremeditationBuff or MeleeEnemies10yCount >= 7) then
    if ReturnSpellOnly then
      return S.ShurikenStorm
    end
  end
  -- actions.stealthed+=/shadowstrike,if=debuff.find_weakness.remains<=1|cooldown.symbols_of_death.remains<18&debuff.find_weakness.remains<cooldown.symbols_of_death.remains
  if ShadowstrikeIsCastable and (Target:DebuffRemains(S.FindWeaknessDebuff) < 1 or S.SymbolsofDeath:CooldownRemains() < 18
    and Target:DebuffRemains(S.FindWeaknessDebuff) < S.SymbolsofDeath:CooldownRemains()) then
    if ReturnSpellOnly then
      return S.Shadowstrike
    end
  end
  -- actions.stealthed+=/shadowstrike
  if ShadowstrikeIsCastable then
    if ReturnSpellOnly then
      return S.Shadowstrike
    end
  end
  return false
end

-- # Stealth Macros
-- This returns a table with the original Stealth spell and the result of the Stealthed action list as if the applicable buff was present
local function StealthMacro(StealthSpell, EnergyThreshold)
  -- Fetch the predicted ability to use after the stealth spell
  local MacroAbility = Stealthed(true, StealthSpell)
  
  if not EnergyThreshold then EnergyThreshold = 1 end
  if Player:Power() < EnergyThreshold then return "Pooling" end

  -- Handle StealthMacro GUI options
  -- If false, just suggest them as off-GCD and bail out of the macro functionality
  if StealthSpell == S.Vanish and (not Settings.Subtlety.StealthMacro.Vanish or not MacroAbility) then
    if WR.Cast(S.Vanish, true) then return "Cast Vanish" end
    return false
  elseif StealthSpell == S.Shadowmeld and (not Settings.Subtlety.StealthMacro.Shadowmeld or not MacroAbility) then
    if WR.Cast(S.Shadowmeld, true) then return "Cast Shadowmeld" end
    return false
  elseif StealthSpell == S.ShadowDance and (not Settings.Subtlety.StealthMacro.ShadowDance or not MacroAbility) then
    if WR.Cast(M.ShadowDance, true) then return "Cast Shadow Dance" end
    return false
  end

  local MacroTable = {StealthSpell, MacroAbility}

  -- We need to Pool Energy for
    
  --Need to create macros or handle this seperatly
  -- For now only cast the stealthspell
  if MacroTable[1] == S.ShadowDance then   
    ShouldReturn = WR.Cast(M.ShadowDance, true)
    if ShouldReturn then return "|" end
  elseif  MacroTable[1] == S.Vanish then
    --Todo Issue here is we want to cast vanish when we have the power for shadowstrike
    ShouldReturn = WR.Cast(S.Vanish)
    if ShouldReturn then return "| " end
  end
  return false
end

-- # Cooldowns
local function CDs()
  if Player:BuffUp(S.ShurikenTornado) then
    -- actions.cds+=/shadow_dance,off_gcd=1,if=!buff.shadow_dance.up&buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
    -- actions.cds+=/symbols_of_death,use_off_gcd=1,if=buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
    if S.SymbolsofDeath:IsCastable() and S.ShadowDance:IsCastable() and not Player:BuffUp(S.SymbolsofDeath) and not Player:BuffUp(S.ShadowDance) then
      if WR.Cast(S.SymbolsofDeath, true) then return "Dance + Symbols (during Tornado)" end
    end
  end

  local SnDCondition = SnD_Condition()

  -- actions.cds+=/vanish,if=buff.danse_macabre.stack>3&combo_points<=2
  if S.Vanish:IsCastable() and not Everyone.IsSoloMode() and ComboPoints <= 2 and Player:BuffStack(S.DanseMacabreBuff) > 3 and S.Vanish:TimeSinceLastCast() > 3 then
    ShouldReturn = StealthMacro(S.Vanish)
    if ShouldReturn then return "Vanish Macro (DM) " .. ShouldReturn end
  end
  -- actions.cds+=/cold_blood,if=!talent.secret_technique&combo_points>=5
  if S.ColdBlood:IsReady() and not S.SecretTechnique:IsAvailable() and ComboPoints >= 5 then
    if WR.Cast(S.ColdBlood, true) then return "Cast Cold Blood" end
  end
  if TargetInMeleeRange then
    -- actions.cds+=/flagellation,target_if=max:target.time_to_die,if=variable.snd_condition&combo_points>=5&target.time_to_die>10
    if WR.CDsON() and S.Flagellation:IsReady() and SnDCondition and not Player:StealthUp(false, false) and ComboPoints >= 5 and Target:FilteredTimeToDie(">", 10) then
      if WR.Cast(S.Flagellation, nil, Settings.Commons.CovenantDisplayStyle) then return "Cast Flagellation" end
    end
  end
  -- actions.cds+=/shuriken_tornado,if=spell_targets.shuriken_storm<=1&energy>=60&variable.snd_condition&cooldown.symbols_of_death.up&cooldown.shadow_dance.charges>=1&(!talent.flagellation.enabled&!cooldown.flagellation.up|buff.flagellation_buff.up|spell_targets.shuriken_storm>=5)&combo_points<=2&!buff.premeditation.up
  if S.ShurikenTornado:IsCastable() and MeleeEnemies10yCount <= 1 and SnDCondition and S.SymbolsofDeath:CooldownUp() and S.ShadowDance:Charges() >= 1 and (not S.Flagellation:IsAvailable() or Player:BuffUp(S.Flagellation) or MeleeEnemies10yCount >= 5) and ComboPoints <= 2 and not Player:BuffUp(S.PremeditationBuff) then
    -- actions.cds+=/pool_resource,for_next=1,if=talent.shuriken_tornado.enabled&!talent.shadow_focus.enabled
    if Player:Energy() >= 60 then
      if WR.Cast(S.ShurikenTornado) then return "Cast Shuriken Tornado" end
    elseif not S.ShadowFocus:IsAvailable() then
      if WR.CastPooling(S.ShurikenTornado) then return "Pool for Shuriken Tornado" end
      if Player:Energy() >= 60 then return "1" end
    end
  end
  if TargetInMeleeRange then
    -- actions.cds+=/sepsis,if=variable.snd_condition&combo_points.deficit>=1&target.time_to_die>=16
    if WR.CDsON() and S.Sepsis:IsReady() and SnDCondition and ComboPointsDeficit >= 1 and not Target:FilteredTimeToDie("<", 16) then
      if WR.Cast(S.Sepsis) then return "Cast Sepsis" end
    end
    -- actions.cds+=/symbols_of_death,if=variable.snd_condition&(!talent.flagellation|cooldown.flagellation.remains>10|cooldown.flagellation.up&combo_points>=5)
    if S.SymbolsofDeath:IsCastable() and SnDCondition and (not S.Flagellation:IsAvailable() or S.Flagellation:CooldownRemains() > 10 or S.Flagellation:CooldownUp() and ComboPoints >= 5) then
      --if WR.Cast(S.SymbolsofDeath, true) then return "Cast Symbols of Death" end
    end
    -- actions.cds+=/symbols_of_death,if=variable.snd_condition&(!talent.flagellation|cooldown.flagellation.remains>10|cooldown.flagellation.up&combo_points>=5)
    if S.SymbolsofDeath:IsCastable() and (S.ShadowDance:CooldownRemains() < 5 or Player:BuffRemains(S.ShadowDanceBuff) > 4 or S.ShadowDance:CooldownRemains() > 30) then
      if WR.Cast(S.SymbolsofDeath, true) then return "Cast Symbols of Death" end
    end
  end
  if S.MarkedforDeath:IsCastable() then
    -- actions.cds+=/marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit
    if Target:FilteredTimeToDie("<", ComboPointsDeficit) then
      if WR.Cast(S.MarkedforDeath, Settings.Commons.OffGCDasOffGCD.MarkedforDeath) then return "Cast Marked for Death" end
    end
    -- actions.cds+=/marked_for_death,if=raid_event.adds.in>30&!stealthed.all&combo_points.deficit>=cp_max_spend
    if not Player:StealthUp(true, true) and ComboPointsDeficit >= Rogue.CPMaxSpend() then
      if not Settings.Commons.STMfDAsDPSCD then
        WR.CastSuggested(S.MarkedforDeath)
      elseif WR.CDsON() then
        if WR.Cast(S.MarkedforDeath, Settings.Commons.OffGCDasOffGCD.MarkedforDeath) then return "Cast Marked for Death" end
      end
    end
  end
  if WR.CDsON() then
    -- actions.cds+=/shadow_blades,if=variable.snd_condition&combo_points.deficit>=2&target.time_to_die>=10&(dot.sepsis.ticking|cooldown.sepsis.remains<=8|!talent.sepsis)|fight_remains<=20
    if S.ShadowBlades:IsCastable() and (Player:BuffUp(S.ShadowDanceBuff) or S.ShadowDance:CooldownRemains() < 10) and (SnDCondition and ComboPointsDeficit >= 2 and Target:FilteredTimeToDie(">=", 10) and (not S.Sepsis:IsAvailable() or S.Sepsis:CooldownRemains() <= 8 or Target:DebuffUp(S.Sepsis)) or HL.BossFilteredFightRemains("<=", 20)) then
      if WR.Cast(S.ShadowBlades, true) then return "Cast Shadow Blades" end
    end
    -- actions.cds+=/echoing_reprimand,if=variable.snd_condition&combo_points.deficit>=3&(variable.priority_rotation|spell_targets.shuriken_storm<=4|talent.resounding_clarity)&(buff.shadow_dance.up|!talent.danse_macabre)
    if S.EchoingReprimand:IsReady() and TargetInMeleeRange and ComboPointsDeficit >= 3 and (PriorityRotation or MeleeEnemies10yCount <= 4 or S.ResoundingClarity:IsAvailable()) and (Player:BuffUp(S.ShadowDanceBuff) or not S.DanseMacabre:IsAvailable()) then
      if WR.Cast(S.EchoingReprimand, nil, Settings.Commons.CovenantDisplayStyle) then return "Cast Echoing Reprimand" end
    end
    -- actions.cds+=/shuriken_tornado,if=variable.snd_condition&buff.symbols_of_death.up&combo_points<=2&(!buff.premeditation.up|spell_targets.shuriken_storm>4)
    -- actions.cds+=/shuriken_tornado,if=cooldown.shadow_dance.ready&!stealthed.all&spell_targets.shuriken_storm>=3&!talent.flagellation.enabled
    if S.ShurikenTornado:IsReady() then
      if SnD_Condition and Player:BuffUp(S.SymbolsofDeath) and ComboPoints <= 2 and (not Player:BuffUp(S.PremeditationBuff) or MeleeEnemies10yCount > 4) then
        if WR.Cast(S.ShurikenTornado) then return "Cast Shuriken Tornado (SoD)" end
      end
      if not S.Flagellation:IsAvailable() and MeleeEnemies10yCount >= 3 and S.ShadowDance:Charges() >= 1 and not Player:StealthUp(true, true) then
        if WR.Cast(S.ShurikenTornado) then return "Cast Shuriken Tornado (Dance)" end
      end
    end
    -- actions.cds+=/shadow_dance,if=!buff.shadow_dance.up&fight_remains<=8+talent.subterfuge.enabled
    if S.ShadowDance:IsCastable() and MayBurnShadowDance() and not Player:BuffUp(S.ShadowDanceBuff) and HL.BossFilteredFightRemains("<=", 8) then
      ShouldReturn = StealthMacro(S.ShadowDance)
      if ShouldReturn then return "Shadow Dance Macro (Low TTD) " .. ShouldReturn end
    end
    -- actions.cds+=/thistle_tea,if=cooldown.symbols_of_death.remains>=3&!buff.thistle_tea.up&(energy.deficit>=100|cooldown.thistle_tea.charges_fractional>=2.75&buff.shadow_dance.up)|buff.shadow_dance.remains>=4&!buff.thistle_tea.up&spell_targets.shuriken_storm>=3|!buff.thistle_tea.up&fight_remains<=(6*cooldown.thistle_tea.charges)    
    if S.ThistleTea:TimeSinceLastCast() > 6 and S.ThistleTea:IsCastable() and not Player:BuffUp(S.ThistleTea) and (S.SymbolsofDeath:CooldownRemains() >= 3 and (Player:EnergyDeficit() >= 100 or S.ThistleTea:ChargesFractional() >= 2.75 and Player:BuffUp(S.ShadowDanceBuff)) or Player:BuffRemains(S.ShadowDanceBuff) > 4 and MeleeEnemies10yCount >= 3 or HL.BossFilteredFightRemains("<=", S.ThistleTea:Charges()*6)) then
      --if WR.Cast(S.ThistleTea, true) then return "Cast Thistle Tea" end
    end

    -- TODO: Add Potion Suggestion
    -- actions.cds+=/potion,if=buff.bloodlust.react|fight_remains<30|buff.symbols_of_death.up&(buff.shadow_blades.up|cooldown.shadow_blades.remains<=10)

    -- Racials
    if Player:BuffUp(S.SymbolsofDeath) then
      -- actions.cds+=/blood_fury,if=buff.symbols_of_death.up
      if S.BloodFury:IsCastable() then
        if WR.Cast(S.BloodFury, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Blood Fury" end
      end
      -- actions.cds+=/berserking,if=buff.symbols_of_death.up
      if S.Berserking:IsCastable() then
        if WR.Cast(S.Berserking, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Berserking" end
      end
      -- actions.cds+=/fireblood,if=buff.symbols_of_death.up
      if S.Fireblood:IsCastable() then
        if WR.Cast(S.Fireblood, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Fireblood" end
      end
      -- actions.cds+=/ancestral_call,if=buff.symbols_of_death.up
      if S.AncestralCall:IsCastable() then
        if WR.Cast(S.AncestralCall, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Ancestral Call" end
      end
    end

    -- Trinkets
    if Settings.Commons.UseTrinkets then
      -- Trinkets
    -- Windscar Whetstone has a bugged 26 second lockout despite the tooltip
      if I.WindscarWhetstone:TimeSinceLastCast() > 26 then
        if I.WindscarWhetstone:IsEquippedAndReady() and (MeleeEnemies5yCount >= 5 or not WR.AoEON()) and not Player:StealthUp(true, true) then
          if WR.Cast(M.WindscarWhetstone) then return "Windscar Whetstone"; end
        end
      end
    end
  end

  return false
end

-- # Stealth Cooldowns
local function Stealth_CDs(EnergyThreshold)
  if WR.CDsON() and S.ShadowDance:TimeSinceLastDisplay() > 0.3 and S.Shadowmeld:TimeSinceLastDisplay() > 0.3 and not Player:IsTanking(Target) then
    -- actions.stealth_cds+=/vanish,if=(!talent.danse_macabre|spell_targets.shuriken_storm>=3)&!variable.shd_threshold&combo_points.deficit>1
    if S.Vanish:IsCastable() and not Everyone.IsSoloMode() and (not S.DanseMacabre:IsAvailable() or MeleeEnemies10yCount >= 3) and not ShD_Threshold() and ComboPointsDeficit > 1 then
      ShouldReturn = StealthMacro(S.Vanish, EnergyThreshold)
      if ShouldReturn then return "Vanish Macro " .. ShouldReturn end
    end
  end
  if TargetInMeleeRange and S.ShadowDance:IsCastable() and S.ShadowDance:Charges() >= 1 and S.Vanish:TimeSinceLastDisplay() > 0.3 and S.Shadowmeld:TimeSinceLastDisplay() > 0.3 and (WR.CDsON() or (S.ShadowDance:ChargesFractional() >= Settings.Subtlety.ShDEcoCharge - (not S.ShadowDanceTalent:IsAvailable() and 0.75 or 0))) then
    -- actions.stealth_cds+=/shadow_dance,if=(variable.shd_combo_points&(buff.symbols_of_death.remains>=(2.2-talent.flagellation.enabled)|variable.shd_threshold)|buff.flagellation.up|buff.flagellation_persist.remains>=6|spell_targets.shuriken_storm>=4&cooldown.symbols_of_death.remains>10)&!buff.the_rotten.up
    if (ShD_Combo_Points() and (Player:BuffRemains(S.SymbolsofDeath) >= (2.2 - BoolToInt(S.Flagellation:IsAvailable())) or ShD_Threshold()) or Player:BuffUp(S.Flagellation) or Player:BuffRemains(S.FlagellationPersistBuff) >= 6 or MeleeEnemies10yCount >= 4 and S.SymbolsofDeath:CooldownRemains() > 10) and Player:BuffDown(S.TheRottenBuff) then
      ShouldReturn = StealthMacro(S.ShadowDance, EnergyThreshold)
      if ShouldReturn then return "ShadowDance Macro 1 " .. ShouldReturn end
    end
    -- actions.stealth_cds+=/shadow_dance,if=variable.shd_combo_points&fight_remains<cooldown.symbols_of_death.remains|!talent.shadow_dance&dot.rupture.ticking&spell_targets.shuriken_storm<=4&!buff.the_rotten.up
    if MayBurnShadowDance() and (ShD_Combo_Points() and HL.BossFilteredFightRemains("<", S.SymbolsofDeath:CooldownRemains()) or not S.ShadowDanceTalent:IsAvailable() and Target:DebuffUp(S.Rupture) and MeleeEnemies10yCount <= 4 and Player:BuffDown(S.TheRottenBuff)) then
      ShouldReturn = StealthMacro(S.ShadowDance, EnergyThreshold)
      if ShouldReturn then return "ShadowDance Macro 2 " .. ShouldReturn end
    end
  end
  return false
end

-- # Builders
local function Build (EnergyThreshold)
  local ThresholdMet = not EnergyThreshold or Player:EnergyPredicted() >= EnergyThreshold
  -- actions.build=shuriken_storm,if=spell_targets>=2+(talent.gloomblade&buff.lingering_shadow.remains>=6|buff.perforated_veins.up)
  if WR.AoEON() and S.ShurikenStorm:IsCastable() and MeleeEnemies10yCount >= 2 + BoolToInt(S.Gloomblade:IsAvailable() and Player:BuffRemains(S.LingeringShadowBuff) >= 6 or Player:BuffUp(S.PerforatedVeinsBuff)) then
    if ThresholdMet and WR.Cast(S.ShurikenStorm) then return "Cast Shuriken Storm" end
  end
  if TargetInMeleeRange then
    -- # Build immediately unless the next CP is Animacharged and we won't cap energy waiting for it.
    -- actions.build+=/variable,name=anima_helper,value=!talent.echoing_reprimand.enabled|!(variable.is_next_cp_animacharged&(time_to_sht.3.plus<0.5|time_to_sht.4.plus<1)&energy<60)
    if S.EchoingReprimand:IsAvailable() and Player:Energy() < 60
      and (ComboPoints == 2 and Player:BuffUp(S.EchoingReprimand3)
        or ComboPoints == 3 and Player:BuffUp(S.EchoingReprimand4)
        or ComboPoints == 4 and Player:BuffUp(S.EchoingReprimand5))
      and (Rogue.TimeToSht(3) < 0.5 or Rogue.TimeToSht(4) < 1.0 or Rogue.TimeToSht(5) < 1.0) then
      --WR.Cast(S.PoolEnergy)
      return "ER Generator Pooling"
    end
    -- actions.build+=/gloomblade,if=variable.anima_helper
    if S.Gloomblade:IsCastable() then
      if ThresholdMet and WR.Cast(S.Gloomblade) then return "Cast Gloomblade" end
    -- actions.build+=/backstab,if=variable.anima_helper
    elseif S.Backstab:IsCastable() then
      if ThresholdMet and WR.Cast(S.Backstab) then return "Cast Backstab" end
    end
  end
  return false
end

-- APL Main
local function APL ()
  -- Reset pooling cache
  PoolingAbility = nil
  PoolingFinisher = nil
  PoolingEnergy = 0

  -- Unit Update
  MeleeRange = S.AcrobaticStrikes:IsAvailable() and 8 or 5
  AoERange = S.AcrobaticStrikes:IsAvailable() and 10 or 13
  TargetInMeleeRange = Target:IsInMeleeRange(MeleeRange)
  TargetInAoERange = Target:IsInMeleeRange(AoERange)
  if AoEON() then
    Enemies30y = Player:GetEnemiesInRange(30) -- Serrated Bone Spike
    MeleeEnemies10y = Player:GetEnemiesInMeleeRange(AoERange) -- Shuriken Storm & Black Powder
    MeleeEnemies10yCount = #MeleeEnemies10y
    MeleeEnemies5y = Player:GetEnemiesInMeleeRange(MeleeRange) -- Melee cycle
    MeleeEnemies5yCount = #MeleeEnemies5y
  else
    Enemies30y = {}
    MeleeEnemies10y = {}
    MeleeEnemies10yCount = 1
    MeleeEnemies5y = {}
    MeleeEnemies5yCount = 1
  end
  
  -- Cache updates
  ComboPoints = Player:ComboPoints()
  EffectiveComboPoints = Rogue.EffectiveComboPoints(ComboPoints)
  ComboPointsDeficit = Player:ComboPointsDeficit()
  PriorityRotation = UsePriorityRotation()
  StealthEnergyRequired = Player:EnergyMax() - Stealth_Threshold()

  if EffectiveComboPoints > ComboPoints and ComboPointsDeficit > 2 and Player:AffectingCombat() then
    if ComboPoints == 2 and not Player:BuffUp(S.EchoingReprimand3) or ComboPoints == 3 and not Player:BuffUp(S.EchoingReprimand4) or ComboPoints == 4 and not Player:BuffUp(S.EchoingReprimand5) then
      local TimeToSht = Rogue.TimeToSht(4)
      if TimeToSht == 0 then TimeToSht = Rogue.TimeToSht(5) end
      if TimeToSht < (mathmax(Player:EnergyTimeToX(35), Player:GCDRemains()) + 0.5) then
        EffectiveComboPoints = ComboPoints
      end
    end
  end

  -- Shuriken Tornado Combo Point Prediction
  if Player:BuffUp(S.ShurikenTornado, nil, true) and ComboPoints < Rogue.CPMaxSpend() then
    local TimeToNextTornadoTick = Rogue.TimeToNextTornado()
    if TimeToNextTornadoTick <= Player:GCDRemains() or mathabs(Player:GCDRemains() - TimeToNextTornadoTick) < 0.25 then
      local PredictedComboPointGeneration = MeleeEnemies10yCount + num(Player:BuffUp(S.ShadowBlades))
      ComboPoints = mathmin(ComboPoints + PredictedComboPointGeneration, Rogue.CPMaxSpend())
      ComboPointsDeficit = mathmax(ComboPointsDeficit - PredictedComboPointGeneration, 0)
      if EffectiveComboPoints < Rogue.CPMaxSpend() then
        EffectiveComboPoints = ComboPoints
      end
    end
  end

  -- Damage Cache updates (after EffectiveComboPoints adjustments)
  RuptureThreshold = (4 + EffectiveComboPoints * 4) * 0.3
  RuptureDMGThreshold = S.Eviscerate:Damage()*Settings.Subtlety.EviscerateDMGOffset; -- Used to check if Rupture is worth to be casted since it's a finisher.

   --------------- Healing -------------------------------------------------------------
  if S.CrimsonVial:IsCastable() and Player:HealthPercentage() <= Settings.Commons2.CrimsonVialHP and not (Player:IsChanneling() or Player:IsCasting()) then
    if WR.Cast(S.CrimsonVial) then return "Cast Crimson Vial (Defensives)" end
  end
  -- Use Healthstone if existing
  if I.Healthstone:IsReady() and Player:HealthPercentage() < Settings.General.HP.Healthstone and not (Player:IsChanneling() or Player:IsCasting()) then
    if WR.Cast(M.Healthstone) then return "Healthstone "; end
  end
  -- Use Healing potion
  if I.RefreshingHealingPotion:IsReady() and Player:HealthPercentage() < Settings.General.HP.PhialOfSerenity and not (Player:IsChanneling() or Player:IsCasting()) then
    if WR.Cast(M.RefreshingHealingPotion) then return "RefreshingHealingPotion "; end
  end

  --------------- Interrupts -------------------------------------------------------------
  if (ShouldInterrupt(Target) or true) and Target:CastPercentage() >= 60 and not (Player:IsChanneling() or Player:IsCasting()) then 
    if Target:IsInterruptible() and S.Kick:IsCastable() and Target:IsInMeleeRange(8) then
      if WR.Cast(S.Kick) then return "Interrupt Rebuke"; end
    end
    if Target:CanBeStunned() then
      if Player:StealthUp(false, false) and S.CheapShot:IsCastable() and Target:IsInMeleeRange(8) then
        if WR.Cast(S.CheapShot) then return "Interrupt HoJ"; end
      end

      if S.Blind:IsCastable() and Target:IsInRange(15) then
        if WR.Cast(S.Blind) then return "Interrupt HoJ"; end
      end
    
      if S.KidneyShot:IsCastable() and Target:IsInMeleeRange(8) and Player:ComboPoints() > 0 then
        --if WR.Cast(S.KidneyShot) then return "Interrupt HoJ"; end
      end
    end
  end

  --- Out of Combat
  if not Player:AffectingCombat() and Target:AffectingCombat() and S.Vanish:TimeSinceLastCast() > 1 then
    if Everyone.TargetIsValid() and (Target:IsSpellInRange(S.Shadowstrike) or TargetInMeleeRange) then
      -- Precombat CDs
      if Player:StealthUp(true, true) then
        CastAbility = Stealthed(true)
        if CastAbility then 
          if type(CastAbility) == "table" and #CastAbility > 1 then
            if WR.Cast(unpack(CastAbility)) then return "Stealthed Macro Cast or Pool (OOC): " end
          else
            if WR.Cast(CastAbility) then return "Stealthed Cast or Pool (OOC): " end
          end
        end
      elseif ComboPoints >= 5 then
        ShouldReturn = Finish()
        if ShouldReturn then return ShouldReturn .. " (OOC)" end
      end
    end
    return
  end

  if Everyone.TargetIsValid() then

    --Shortcut this for now.
    if (HL.CombatTime() < 10 and HL.CombatTime() > 0 ) and S.ShadowDance:CooldownUp() and S.Vanish:TimeSinceLastCast() > 11 then
      if Player:StealthUp(true, true) then
        if WR.Cast(S.Shadowstrike) then return "Opener SS" end
      end
      if S.SymbolsofDeath:IsCastable() and Player:BuffDown(S.SymbolsofDeath) then
        if WR.Cast(S.SymbolsofDeath, true) then return "Opener SymbolsofDeath" end
      end
      if S.ShadowBlades:IsCastable() and Player:BuffDown(S.ShadowBlades) then
        if WR.Cast(S.ShadowBlades, true) then return "Opener ShadowBlades" end
      end
      if S.ShurikenStorm:IsCastable() and MeleeEnemies10yCount >= 2 then
        if WR.Cast(S.ShurikenStorm) then return "Opener Shuriken Tornado" end
      end
      if S.Gloomblade:TimeSinceLastCast() > 3 and MeleeEnemies10yCount <= 1 then 
        if WR.Cast(S.Gloomblade) then return "Opener Gloomblade" end
      end
      if Target:DebuffDown(S.Rupture) and MeleeEnemies10yCount <= 1 and ComboPoints > 0 then
        if WR.Cast(S.Rupture) then return "Opener Rupture" end
      end
      if S.ShadowDance:IsCastable() and WR.Cast(M.ShadowDance, true) then return "Opener ShadowDance" end
    end
    -- # Check CDs at first
    -- actions=call_action_list,name=cds
    ShouldReturn = CDs()
    if ShouldReturn then return "CDs: " .. ShouldReturn end

    -- # Apply Slice and Dice at 4+ CP if it expires within the next GCD or is not up
    -- actions+=/slice_and_dice,if=spell_targets.shuriken_storm<cp_max_spend&buff.slice_and_dice.remains<gcd.max&fight_remains>6&combo_points>=4
    if S.SliceandDice:IsCastable() and MeleeEnemies10yCount < Rogue.CPMaxSpend() and HL.FilteredFightRemains(MeleeEnemies10y, ">", 6) and Player:BuffRemains(S.SliceandDice) < Player:GCD() and ComboPoints >= 4 then
      if S.SliceandDice:IsReady() then
        if WR.Cast(S.SliceandDice) then return "Cast Slice and Dice (Low Duration)" end
        if Player:Power() < 20 then return "Pooling" end
      end
    end

    -- # Run fully switches to the Stealthed Rotation (by doing so, it forces pooling if nothing is available).
    -- If we are stealthed then special rotation
    if Player:StealthUp(true, true) then
      CastAbility = Stealthed(true)
      if CastAbility then 
        if type(CastAbility) == "table" and #CastAbility > 1 then
          if WR.Cast(unpack(CastAbility)) then return "Stealthed Macro Cast or Pool (OOC): " end
        else
          if WR.Cast(CastAbility) then return "Stealthed Cast or Pool (OOC): " end
        end
      end
      return "Stealthed Pooling"
    end

    -- Here we want to see if we want to go into Stealth?
    -- So pool energy for burn stealth phase?
    -- Will cast Vanish or ShadowDance if we have enough energy
    -- But should we not pool Energy if we can cast Vanish or ShadowDance?
    if Player:EnergyPredicted() >= StealthEnergyRequired then
      ShouldReturn = Stealth_CDs(StealthEnergyRequired)
      if ShouldReturn then return "Stealth CDs: " .. ShouldReturn end
    end

    if EffectiveComboPoints >= Rogue.CPMaxSpend() or (ComboPointsDeficit <= (1 + num(Player:BuffUp(S.TheRottenBuff))) or (HL.BossFilteredFightRemains("<", 2) and EffectiveComboPoints >= 3)) or (MeleeEnemies10yCount >= (4 - num(S.SealFate:IsAvailable())) and EffectiveComboPoints >= 4) then
      ShouldReturn = Finish()
      if ShouldReturn then return "Finish: " .. ShouldReturn end
    else
      ShouldReturn = Stealth_CDs(StealthEnergyRequired)
      if ShouldReturn then return "Stealth CDs: " .. ShouldReturn end

      ShouldReturn = Build(StealthEnergyRequired)
      if ShouldReturn then return "Build: " .. ShouldReturn end
    end
  end
end

local function AutoBind()
  -- Spell Binds
  WR.Bind(S.Blind)
  WR.Bind(S.BlackPowder)
  WR.Bind(S.CheapShot)
  --WR.Bind(S.CloakofShadows)
  WR.Bind(S.ColdBlood)
  WR.Bind(S.CrimsonVial)
  --WR.Bind(S.DeathfromAbove)
  --WR.Bind(S.Evasion)
  WR.Bind(S.Eviscerate)
  --WR.Bind(S.Feint)
  WR.Bind(S.Gloomblade)
  WR.Bind(S.Rupture)
  --WR.Bind(S.SecretTechnique)
  WR.Bind(S.ShadowBlades)
  WR.Bind(S.ShadowDance)
  WR.Bind(S.Shadowstrike)
  WR.Bind(S.Shiv)
  WR.Bind(S.ShurikenStorm)
  WR.Bind(S.ShurikenTornado)
  WR.Bind(S.ShurikenToss)
  WR.Bind(S.SliceandDice)
  WR.Bind(S.Stealth)
  WR.Bind(S.Stealth2)
  WR.Bind(S.SymbolsofDeath)
  WR.Bind(S.ThistleTea)
  WR.Bind(S.Vanish)
    
  WR.Bind(M.ElementalPotionOfPower)
  WR.Bind(M.Healthstone)
  WR.Bind(M.RefreshingHealingPotion)
  WR.Bind(M.WindscarWhetstone)

  WR.Bind(S.Kick)
  WR.Bind(S.CheapShot)
  WR.Bind(S.KidneyShot)
  WR.Bind(S.Blind)

  WR.Bind(M.SecretTechnique)
  WR.Bind(M.ShadowDance)
  --WR.Bind(M.ShadowDanceSymbol)
  
end

local function Init ()
  WR.Print("Outlaw Rogue by Worldy")
  AutoBind()
end

WR.SetAPL(261, APL, Init)

-- Last Update: 2022-11-28

-- # Executed before combat begins. Accepts non-harmful actions only.
-- actions.precombat=apply_poison
-- actions.precombat+=/flask
-- actions.precombat+=/augmentation
-- actions.precombat+=/food
-- # Snapshot raid buffed stats before combat begins and pre-potting is done.
-- actions.precombat+=/snapshot_stats
-- actions.precombat+=/stealth
-- actions.precombat+=/marked_for_death,precombat_seconds=15
-- actions.precombat+=/slice_and_dice,precombat_seconds=1

-- # Executed every time the actor is available.
-- # Restealth if possible (no vulnerable enemies in combat)
-- actions=stealth
-- # Interrupt on cooldown to allow simming interactions with that
-- actions+=/kick
-- # Wait for for the 3rd Secret Technique attack to trigger when syncing with Cold Blood
-- actions+=/wait,sec=0.3,if=talent.cold_blood&talent.secret_technique&buff.cold_blood.up&buff.secret_technique.up
-- # Used to determine whether cooldowns wait for SnD based on targets.
-- actions+=/variable,name=snd_condition,value=buff.slice_and_dice.up|spell_targets.shuriken_storm>=cp_max_spend
-- # Check to see if the next CP (in the event of a ShT proc) is Animacharged
-- actions+=/variable,name=is_next_cp_animacharged,if=talent.echoing_reprimand.enabled,value=combo_points=1&buff.echoing_reprimand_2.up|combo_points=2&buff.echoing_reprimand_3.up|combo_points=3&buff.echoing_reprimand_4.up|combo_points=4&buff.echoing_reprimand_5.up
-- # Account for ShT reaction time by ignoring low-CP animacharged matches in the 0.5s preceeding a potential ShT proc
-- actions+=/variable,name=effective_combo_points,value=effective_combo_points
-- actions+=/variable,name=effective_combo_points,if=talent.echoing_reprimand.enabled&effective_combo_points>combo_points&combo_points.deficit>2&time_to_sht.4.plus<0.5&!variable.is_next_cp_animacharged,value=combo_points
-- # Check CDs at first
-- actions+=/call_action_list,name=cds
-- # Apply Slice and Dice at 4+ CP if it expires within the next GCD or is not up
-- actions+=/slice_and_dice,if=spell_targets.shuriken_storm<cp_max_spend&buff.slice_and_dice.remains<gcd.max&fight_remains>6&combo_points>=4
-- # Run fully switches to the Stealthed Rotation (by doing so, it forces pooling if nothing is available).
-- actions+=/run_action_list,name=stealthed,if=stealthed.all
-- # Only change rotation if we have priority_rotation set.
-- actions+=/variable,name=priority_rotation,value=priority_rotation
-- # Used to define when to use stealth CDs or builders
-- actions+=/variable,name=stealth_threshold,value=25+talent.vigor.enabled*20+talent.master_of_shadows.enabled*20+talent.shadow_focus.enabled*25+talent.alacrity.enabled*20+25*(spell_targets.shuriken_storm>=4)
-- # Consider using a Stealth CD when reaching the energy threshold
-- actions+=/call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold
-- actions+=/call_action_list,name=finish,if=variable.effective_combo_points>=cp_max_spend
-- # Finish at maximum or close to maximum combo point value
-- actions+=/call_action_list,name=finish,if=combo_points.deficit<=1|fight_remains<=1&variable.effective_combo_points>=3
-- # Finish at 4+ against 4 targets (outside stealth)
-- actions+=/call_action_list,name=finish,if=spell_targets.shuriken_storm>=4&variable.effective_combo_points>=4
-- # Use a builder when reaching the energy threshold
-- actions+=/call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
-- # Lowest priority in all of the APL because it causes a GCD
-- actions+=/arcane_torrent,if=energy.deficit>=15+energy.regen
-- actions+=/arcane_pulse
-- actions+=/lights_judgment
-- actions+=/bag_of_tricks

-- # Builders
-- actions.build=shuriken_storm,if=spell_targets>=2+(buff.lingering_shadow.up|buff.perforated_veins.up)
-- # Build immediately unless the next CP is Animacharged and we won't cap energy waiting for it.
-- actions.build+=/variable,name=anima_helper,value=!talent.echoing_reprimand.enabled|!(variable.is_next_cp_animacharged&(time_to_sht.3.plus<0.5|time_to_sht.4.plus<1)&energy<60)
-- actions.build+=/gloomblade,if=variable.anima_helper
-- actions.build+=/backstab,if=variable.anima_helper

-- # Cooldowns
-- # Use Dance off-gcd before the first Shuriken Storm from Tornado comes in.
-- actions.cds=shadow_dance,use_off_gcd=1,if=!buff.shadow_dance.up&buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
-- # (Unless already up because we took Shadow Focus) use Symbols off-gcd before the first Shuriken Storm from Tornado comes in.
-- actions.cds+=/symbols_of_death,use_off_gcd=1,if=buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
-- # Cold Blood on 5 combo points when not playing DM or secret technique
-- actions.cds+=/cold_blood,if=(!talent.danse_macabre|!talent.secret_technique)&combo_points>=5
-- # Cold Blood after secret techniques initial attack
-- actions.cds+=/cold_blood,use_off_gcd=1,if=talent.secret_technique&buff.secret_technique.up
-- actions.cds+=/flagellation,target_if=max:target.time_to_die,if=variable.snd_condition&combo_points>=5&target.time_to_die>10
-- # Pool for Tornado pre-SoD with ShD ready when not running SF.
-- actions.cds+=/pool_resource,for_next=1,if=talent.shuriken_tornado.enabled&!talent.shadow_focus.enabled
-- # Use Tornado pre SoD when we have the energy whether from pooling without SF or just generally.
-- actions.cds+=/shuriken_tornado,if=spell_targets.shuriken_storm<=1&energy>=60&variable.snd_condition&cooldown.symbols_of_death.up&cooldown.shadow_dance.charges>=1&(!talent.flagellation.enabled&!cooldown.flagellation.up|buff.flagellation_buff.up|spell_targets.shuriken_storm>=5)&combo_points<=2&!buff.premeditation.up
-- actions.cds+=/sepsis,if=variable.snd_condition&combo_points.deficit>=1&target.time_to_die>=16
-- # Use Symbols on cooldown (after first SnD) unless we are going to pop Tornado and do not have Shadow Focus.
-- actions.cds+=/symbols_of_death,if=variable.snd_condition&(!talent.flagellation|cooldown.flagellation.remains>10|cooldown.flagellation.up&combo_points>=5)
-- # If adds are up, snipe the one with lowest TTD. Use when dying faster than CP deficit or not stealthed without any CP.
-- actions.cds+=/marked_for_death,line_cd=1.5,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.all&combo_points.deficit>=cp_max_spend)
-- # If no adds will die within the next 30s, use MfD on boss without any CP.
-- actions.cds+=/marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&combo_points.deficit>=cp_max_spend
-- actions.cds+=/shadow_blades,if=variable.snd_condition&combo_points.deficit>=2
-- actions.cds+=/echoing_reprimand,if=variable.snd_condition&combo_points.deficit>=3&(variable.priority_rotation|spell_targets.shuriken_storm<=4|talent.resounding_clarity)&(buff.shadow_dance.up|!talent.danse_macabre)
-- # With SF, if not already done, use Tornado with SoD up.
-- actions.cds+=/shuriken_tornado,if=variable.snd_condition&buff.symbols_of_death.up&combo_points<=2&(!buff.premeditation.up|spell_targets.shuriken_storm>4)
-- actions.cds+=/shadow_dance,if=!buff.shadow_dance.up&fight_remains<=8+talent.subterfuge.enabled
-- actions.cds+=/thistle_tea,if=cooldown.symbols_of_death.remains>=3&!buff.thistle_tea.up&(energy.deficit>=100|cooldown.thistle_tea.charges_fractional>=2.75&energy.deficit>=40)|buff.shadow_dance.up&!buff.thistle_tea.up&spell_targets.shuriken_storm>=2
-- actions.cds+=/potion,if=buff.bloodlust.react|fight_remains<30|buff.symbols_of_death.up&(buff.shadow_blades.up|cooldown.shadow_blades.remains<=10)
-- actions.cds+=/blood_fury,if=buff.symbols_of_death.up
-- actions.cds+=/berserking,if=buff.symbols_of_death.up
-- actions.cds+=/fireblood,if=buff.symbols_of_death.up
-- actions.cds+=/ancestral_call,if=buff.symbols_of_death.up
-- # Default fallback for usable items: Use with Symbols of Death.
-- actions.cds+=/use_items,if=buff.symbols_of_death.up|fight_remains<20

-- # Finishers
-- # While using Premeditation, avoid casting Slice and Dice when Shadow Dance is soon to be used, except for Kyrian
-- actions.finish=variable,name=premed_snd_condition,value=talent.premeditation.enabled&spell_targets.shuriken_storm<5
-- actions.finish+=/slice_and_dice,if=!variable.premed_snd_condition&spell_targets.shuriken_storm<6&!buff.shadow_dance.up&buff.slice_and_dice.remains<fight_remains&refreshable
-- actions.finish+=/slice_and_dice,if=variable.premed_snd_condition&cooldown.shadow_dance.charges_fractional<1.75&buff.slice_and_dice.remains<cooldown.symbols_of_death.remains&(cooldown.shadow_dance.ready&buff.symbols_of_death.remains-buff.shadow_dance.remains<1.2)
-- actions.finish+=/variable,name=skip_rupture,value=buff.thistle_tea.up&spell_targets.shuriken_storm=1|buff.shadow_dance.up&(spell_targets.shuriken_storm=1|dot.rupture.ticking&spell_targets.shuriken_storm>=2)
-- # Keep up Rupture if it is about to run out.
-- actions.finish+=/rupture,if=(!variable.skip_rupture|variable.priority_rotation)&target.time_to_die-remains>6&refreshable
-- actions.finish+=/secret_technique,if=buff.shadow_dance.up&(buff.danse_macabre.stack>=3|!talent.danse_macabre)
-- # Multidotting targets that will live for the duration of Rupture, refresh during pandemic.
-- actions.finish+=/rupture,cycle_targets=1,if=!variable.skip_rupture&!variable.priority_rotation&spell_targets.shuriken_storm>=2&target.time_to_die>=(2*combo_points)&refreshable
-- # Refresh Rupture early if it will expire during Symbols. Do that refresh if SoD gets ready in the next 5s.
-- actions.finish+=/rupture,if=!variable.skip_rupture&remains<cooldown.symbols_of_death.remains+10&cooldown.symbols_of_death.remains<=5&target.time_to_die-remains>cooldown.symbols_of_death.remains+5
-- actions.finish+=/black_powder,if=!variable.priority_rotation&spell_targets>=(3-talent.dark_brew.enabled)
-- actions.finish+=/eviscerate

-- # Stealth Cooldowns
-- # Helper Variable
-- actions.stealth_cds=variable,name=shd_threshold,value=cooldown.shadow_dance.charges_fractional>=0.75+talent.shadow_dance
-- # Vanish if we are capping on Dance charges. Early before first dance if we have no Nightstalker but Dark Shadow in order to get Rupture up (no Master Assassin).
-- actions.stealth_cds+=/vanish,if=!variable.shd_threshold&combo_points.deficit>1
-- # Pool for Shadowmeld + Shadowstrike unless we are about to cap on Dance charges. Only when Find Weakness is about to run out.
-- actions.stealth_cds+=/pool_resource,for_next=1,extra_amount=40,if=race.night_elf
-- actions.stealth_cds+=/shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&combo_points.deficit>4
-- # CP thresholds for entering Shadow Dance Default to start dance with 0 or 1 combo point
-- actions.stealth_cds+=/variable,name=shd_combo_points,value=combo_points<=1
-- # Use stealth cooldowns with at least 2 combo points missing on 3 targets
-- actions.stealth_cds+=/variable,name=shd_combo_points,value=combo_points.deficit>=2,if=spell_targets.shuriken_storm=3
-- # Use stealth cooldowns with high combo points when playing shuriken tornado or with high target counts
-- actions.stealth_cds+=/variable,name=shd_combo_points,value=combo_points.deficit<=1,if=spell_targets.shuriken_storm>(4-2*talent.shuriken_tornado.enabled)|variable.priority_rotation&spell_targets.shuriken_storm>=4
-- # Use stealth cooldowns on any combo point on 4 targets
-- actions.stealth_cds+=/variable,name=shd_combo_points,value=1,if=spell_targets.shuriken_storm=4
-- # Dance during Symbols or above threshold.
-- actions.stealth_cds+=/shadow_dance,if=(variable.shd_combo_points&(buff.symbols_of_death.remains>=(2.2-talent.flagellation.enabled)|variable.shd_threshold)|buff.flagellation.up|buff.flagellation_persist.remains>=6|spell_targets.shuriken_storm>=4&cooldown.symbols_of_death.remains>10)&!buff.the_rotten.up
-- # Burn Dances charges if before the fight ends if SoD won't be ready in time.
-- actions.stealth_cds+=/shadow_dance,if=variable.shd_combo_points&fight_remains<cooldown.symbols_of_death.remains|!talent.shadow_dance&dot.rupture.ticking&spell_targets.shuriken_storm<=4

-- # Stealthed Rotation
-- # If Stealth/vanish are up, use Shadowstrike to benefit from the passive bonus and Find Weakness, even if we are at max CP (unless using Master Assassin)
-- actions.stealthed=shadowstrike,if=(buff.stealth.up|buff.vanish.up)&(spell_targets.shuriken_storm<4|variable.priority_rotation)
-- #Variable to Gloomblade / Backstab when on 4 or 5 combo points with premediation and when the combo point is not anima charged
-- actions.stealthed+=/variable,name=gloomblade_condition,value=(combo_points.deficit=2|combo_points.deficit=3)&(buff.premeditation.up|effective_combo_points<7)&(spell_targets.shuriken_storm<=8|talent.lingering_shadow)
-- actions.stealthed+=/gloomblade,if=variable.gloomblade_condition
-- actions.stealthed+=/backstab,if=variable.gloomblade_condition&talent.danse_macabre&buff.danse_macabre.stack<=2
-- actions.stealthed+=/call_action_list,name=finish,if=variable.effective_combo_points>=cp_max_spend
-- # Finish earlier with Shuriken tornado up.
-- actions.stealthed+=/call_action_list,name=finish,if=buff.shuriken_tornado.up&combo_points.deficit<=2
-- # Also safe to finish at 4+ CP with exactly 4 targets. (Same as outside stealth.)
-- actions.stealthed+=/call_action_list,name=finish,if=spell_targets.shuriken_storm>=4-talent.seal_fate&variable.effective_combo_points>=4
-- # Finish at lower combo points if you are talented in DS, SS or Seal Fate
-- actions.stealthed+=/call_action_list,name=finish,if=combo_points.deficit<=1+(talent.seal_fate|talent.deeper_stratagem|talent.secret_stratagem)
-- # Use Gloomblade or Backstab when close to hitting max PV stacks
-- actions.stealthed+=/gloomblade,if=buff.perforated_veins.stack>=5&spell_targets.shuriken_storm<3
-- actions.stealthed+=/backstab,if=buff.perforated_veins.stack>=5&spell_targets.shuriken_storm<3
-- actions.stealthed+=/shadowstrike,if=stealthed.sepsis&spell_targets.shuriken_storm<4
-- actions.stealthed+=/shuriken_storm,if=spell_targets>=3+buff.the_rotten.up&(!buff.premeditation.up|spell_targets>=7)
-- # Shadowstrike to refresh Find Weakness and to ensure we can carry over a full FW into the next SoD if possible.
-- actions.stealthed+=/shadowstrike,if=debuff.find_weakness.remains<=1|cooldown.symbols_of_death.remains<18&debuff.find_weakness.remains<cooldown.symbols_of_death.remains
-- actions.stealthed+=/shadowstrike

-- actions.stealth_cds=variable,name=shd_threshold,value=cooldown.shadow_dance.charges_fractional>=0.75+talent.shadow_dance
-- # Vanish if we are capping on Dance charges. Early before first dance if we have no Nightstalker but Dark Shadow in order to get Rupture up (no Master Assassin).
-- actions.stealth_cds+=/vanish,if=!variable.shd_threshold&combo_points.deficit>1
-- # Pool for Shadowmeld + Shadowstrike unless we are about to cap on Dance charges. Only when Find Weakness is about to run out.
-- actions.stealth_cds+=/pool_resource,for_next=1,extra_amount=40,if=race.night_elf
-- actions.stealth_cds+=/shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&combo_points.deficit>4
-- # CP thresholds for entering Shadow Dance Default to start dance with 0 or 1 combo point
-- actions.stealth_cds+=/variable,name=shd_combo_points,value=combo_points<=1
-- # Use stealth cooldowns with at least 2 combo points missing on 3 targets
-- actions.stealth_cds+=/variable,name=shd_combo_points,value=combo_points.deficit>=2,if=spell_targets.shuriken_storm=3
-- # Use stealth cooldowns with high combo points when playing shuriken tornado or with high target counts
-- actions.stealth_cds+=/variable,name=shd_combo_points,value=combo_points.deficit<=1,if=spell_targets.shuriken_storm>(4-2*talent.shuriken_tornado.enabled)|variable.priority_rotation&spell_targets.shuriken_storm>=4
-- # Use stealth cooldowns on any combo point on 4 targets
-- actions.stealth_cds+=/variable,name=shd_combo_points,value=1,if=spell_targets.shuriken_storm=4
-- # Dance during Symbols or above threshold.
-- actions.stealth_cds+=/shadow_dance,if=(variable.shd_combo_points&(buff.symbols_of_death.remains>=(2.2-talent.flagellation.enabled)|variable.shd_threshold)|buff.flagellation.up|buff.flagellation_persist.remains>=6|spell_targets.shuriken_storm>=4&cooldown.symbols_of_death.remains>10)&!buff.the_rotten.up
-- # Burn Dances charges if before the fight ends if SoD won't be ready in time.
-- actions.stealth_cds+=/shadow_dance,if=variable.shd_combo_points&fight_remains<cooldown.symbols_of_death.remains|!talent.shadow_dance&dot.rupture.ticking&spell_targets.shuriken_storm<=4

-- # Stealthed Rotation
-- # If Stealth/vanish are up, use Shadowstrike to benefit from the passive bonus and Find Weakness, even if we are at max CP (unless using Master Assassin)
-- actions.stealthed=shadowstrike,if=(buff.stealth.up|buff.vanish.up)&(spell_targets.shuriken_storm<4|variable.priority_rotation)
-- #Variable to Gloomblade / Backstab when on 4 or 5 combo points with premediation and when the combo point is not anima charged
-- actions.stealthed+=/variable,name=gloomblade_condition,value=(combo_points.deficit=2|combo_points.deficit=3)&(buff.premeditation.up|effective_combo_points<7)&(spell_targets.shuriken_storm<=8|talent.lingering_shadow)
-- actions.stealthed+=/gloomblade,if=variable.gloomblade_condition
-- actions.stealthed+=/backstab,if=variable.gloomblade_condition&talent.danse_macabre&buff.danse_macabre.stack<=2
-- actions.stealthed+=/call_action_list,name=finish,if=variable.effective_combo_points>=cp_max_spend
-- # Finish earlier with Shuriken tornado up.
-- actions.stealthed+=/call_action_list,name=finish,if=buff.shuriken_tornado.up&combo_points.deficit<=2
-- # Also safe to finish at 4+ CP with exactly 4 targets. (Same as outside stealth.)
-- actions.stealthed+=/call_action_list,name=finish,if=spell_targets.shuriken_storm>=4-talent.seal_fate&variable.effective_combo_points>=4
-- # Finish at lower combo points if you are talented in DS, SS or Seal Fate
-- actions.stealthed+=/call_action_list,name=finish,if=combo_points.deficit<=1+(talent.seal_fate|talent.deeper_stratagem|talent.secret_stratagem)
-- # Use Gloomblade or Backstab when close to hitting max PV stacks
-- actions.stealthed+=/gloomblade,if=buff.perforated_veins.stack>=5&spell_targets.shuriken_storm<3
-- actions.stealthed+=/backstab,if=buff.perforated_veins.stack>=5&spell_targets.shuriken_storm<3
-- actions.stealthed+=/shadowstrike,if=stealthed.sepsis&spell_targets.shuriken_storm<4
-- actions.stealthed+=/shuriken_storm,if=spell_targets>=3+buff.the_rotten.up&(!buff.premeditation.up|spell_targets>=7)
-- # Shadowstrike to refresh Find Weakness and to ensure we can carry over a full FW into the next SoD if possible.
-- actions.stealthed+=/shadowstrike,if=debuff.find_weakness.remains<=1|cooldown.symbols_of_death.remains<18&debuff.find_weakness.remains<cooldown.symbols_of_death.remains
-- actions.stealthed+=/shadowstrike