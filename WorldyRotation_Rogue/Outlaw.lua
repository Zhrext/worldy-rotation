-- Bind Focus Macros Need to add Mouseover
--WR.Bind(M.FocusTarget)
--WR.Bind(M.FocusPlayer)
--for i = 1, 4 do
--  local FocusUnitKey = stringformat("FocusParty%d", i)
--  WR.Bind(M[FocusUnitKey])
--end
---------- Set MO as focus if we should CC, Interrupt or stun
--Mouseover:IsAPlayer()
-- Check MO for CC, Stuns and Interrupts
--  if Mouseover and Mouseover:NPCID() == ExplosiveNPCID and S.ShadowWordPain:IsReady() then
--    if Cast(M.ShadowWordPainMouseover, not Mouseover:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain damage 2"; end
--  end


--local ExplosiveNPCID = 120651
--if Target:NPCID() == ExplosiveNPCID and S.ShadowWordPain:IsReady() then
--    if Cast(S.ShadowWordPain, not Target:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain damage 1"; end
--  end
--  if Mouseover and Mouseover:NPCID() == ExplosiveNPCID and S.ShadowWordPain:IsReady() then
--    if Cast(M.ShadowWordPainMouseover, not Mouseover:IsSpellInRange(S.ShadowWordPain)) then return "shadow_word_pain damage 2"; end
--  end

-- use_trinket
--if (Settings.General.Enabled.Trinkets) then
--  local TrinketToUse = Player:GetUseableTrinkets(OnUseExcludes)
--  if TrinketToUse then
--    if Utils.ValueIsInArray(TrinketToUse:SlotIDs(), 13) then
--      if Cast(M.Trinket1) then return "use_trinket " .. TrinketToUse:Name() .. " damage 1"; end
--    elseif Utils.ValueIsInArray(TrinketToUse:SlotIDs(), 14) then
--      if Cast(M.Trinket2) then return "use_trinket " .. TrinketToUse:Name() .. " damage 2"; end
--    end
--  end
--end

--local TTD = ThisUnit:TimeToDie()




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
local mathmin = math.min
local mathabs = math.abs


--- ============================ CONTENT ============================
--- ======= APL LOCALS =======
-- Commons
local Everyone = WR.Commons.Everyone
local Rogue = WR.Commons.Rogue

-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Rogue.Commons,
  Commons2 = WR.GUISettings.APL.Rogue.Commons2,
  Outlaw = WR.GUISettings.APL.Rogue.Outlaw,
}

-- Define S/I for spell and item arrays
local S = Spell.Rogue.Outlaw
local I = Item.Rogue.Outlaw
--local M = Macro.Rogue.Outlaw


-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  I.ComputationDevice:ID(),
  I.VigorTrinket:ID(),
  I.FontOfPower:ID(),
  I.RazorCoral:ID()
}

S.Dispatch:RegisterDamageFormula(
  -- Dispatch DMG Formula (Pre-Mitigation):
  --- Player Modifier
    -- AP * CP * EviscR1_APCoef * Aura_M * NS_M * DS_M * DSh_M * SoD_M * Finality_M * Mastery_M * Versa_M
  --- Target Modifier
    -- Ghostly_M * Sinful_M
  function ()
    return
      --- Player Modifier
        -- Attack Power
        Player:AttackPowerDamageMod() *
        -- Combo Points
        Rogue.CPSpend() *
        -- Eviscerate R1 AP Coef
        0.35 *
        -- Aura Multiplier (SpellID: 137036)
        1.13 *
        -- Versatility Damage Multiplier
        (1 + Player:VersatilityDmgPct() / 100) *
      --- Target Modifier
        -- Ghostly Strike Multiplier
        (Target:DebuffUp(S.GhostlyStrike) and 1.1 or 1) *
        -- Sinful Revelation Enchant
        (Target:DebuffUp(S.SinfulRevelationDebuff) and 1.06 or 1)
  end
)

-- Rotation Var
local Enemies30y, EnemiesBF, EnemiesBFCount
local ShouldReturn; -- Used to get the return string
local BladeFlurryRange = 6
local BetweenTheEyesDMGThreshold
local EffectiveComboPoints, ComboPoints, ComboPointsDeficit


-- Legendaries
local CovenantId = Player:CovenantID()
local IsKyrian, IsVenthyr, IsNightFae, IsNecrolord = (CovenantId == 1), (CovenantId == 2), (CovenantId == 3), (CovenantId == 4)
local DeathlyShadowsEquipped = Player:HasLegendaryEquipped(129)
local MarkoftheMasterAssassinEquipped = Player:HasLegendaryEquipped(117)
local TinyToxicBladeEquipped = Player:HasLegendaryEquipped(116)
HL:RegisterForEvent(function()
  CovenantId = Player:CovenantID()
  IsKyrian, IsVenthyr, IsNightFae, IsNecrolord = (CovenantId == 1), (CovenantId == 2), (CovenantId == 3), (CovenantId == 4)
  DeathlyShadowsEquipped = Player:HasLegendaryEquipped(129)
  MarkoftheMasterAssassinEquipped = Player:HasLegendaryEquipped(117)
  TinyToxicBladeEquipped = Player:HasLegendaryEquipped(116)
end, "PLAYER_EQUIPMENT_CHANGED", "COVENANT_CHOSEN" )

-- Utils
local function num(val)
  if val then return 1 else return 0 end
end

-- Stable Energy Prediction
local PrevEnergyTimeToMaxPredicted, PrevEnergyPredicted = 0, 0
local function EnergyTimeToMaxStable ()
  local EnergyTimeToMaxPredicted = Player:EnergyTimeToMaxPredicted()
  if mathabs(PrevEnergyTimeToMaxPredicted - EnergyTimeToMaxPredicted) > 1 then
    PrevEnergyTimeToMaxPredicted = EnergyTimeToMaxPredicted
  end
  return PrevEnergyTimeToMaxPredicted
end
local function EnergyPredictedStable ()
  local EnergyPredicted = Player:EnergyPredicted()
  if mathabs(PrevEnergyPredicted - EnergyPredicted) > 9 then
    PrevEnergyPredicted = EnergyPredicted
  end
  return PrevEnergyPredicted
end

-- Marked for Death Cycle Targets
-- actions.cds+=/marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
local function EvaluateMfDTargetIfConditionCondition(TargetUnit)
  return TargetUnit:TimeToDie()
end
local function EvaluateMfDCondition(TargetUnit)
  -- Note: Increased the SimC condition by 50% since we are slower.
  return TargetUnit:FilteredTimeToDie("<", ComboPointsDeficit*1.5) or (not Player:StealthUp(true, false) and ComboPointsDeficit >= Rogue.CPMaxSpend() - 1)
end

--- ======= ACTION LISTS =======
local RtB_BuffsList = {
  S.Broadside,
  S.BuriedTreasure,
  S.GrandMelee,
  S.RuthlessPrecision,
  S.SkullandCrossbones,
  S.TrueBearing
}
local function RtB_List (Type, List)
  if not Cache.APLVar.RtB_List then Cache.APLVar.RtB_List = {} end
  if not Cache.APLVar.RtB_List[Type] then Cache.APLVar.RtB_List[Type] = {} end
  local Sequence = table.concat(List)
  -- All
  if Type == "All" then
    if not Cache.APLVar.RtB_List[Type][Sequence] then
      local Count = 0
      for i = 1, #List do
        if Player:BuffUp(RtB_BuffsList[List[i]]) then
          Count = Count + 1
        end
      end
      Cache.APLVar.RtB_List[Type][Sequence] = Count == #List and true or false
    end
  -- Any
  else
    if not Cache.APLVar.RtB_List[Type][Sequence] then
      Cache.APLVar.RtB_List[Type][Sequence] = false
      for i = 1, #List do
        if Player:BuffUp(RtB_BuffsList[List[i]]) then
          Cache.APLVar.RtB_List[Type][Sequence] = true
          break
        end
      end
    end
  end
  return Cache.APLVar.RtB_List[Type][Sequence]
end
-- Get the number of Roll the Bones buffs currently on
local function RtB_Buffs ()
  if not Cache.APLVar.RtB_Buffs then
    Cache.APLVar.RtB_Buffs = 0
    for i = 1, #RtB_BuffsList do
      if Player:BuffUp(RtB_BuffsList[i]) then
        Cache.APLVar.RtB_Buffs = Cache.APLVar.RtB_Buffs + 1
      end
    end
  end
  return Cache.APLVar.RtB_Buffs
end
local function RtB_Reroll ()
  if not Cache.APLVar.RtB_Reroll then
    -- 1+ Buff
    if Settings.Outlaw.RolltheBonesLogic == "1+ Buff" then
      Cache.APLVar.RtB_Reroll = (RtB_Buffs() <= 0) and true or false
    -- Broadside
    elseif Settings.Outlaw.RolltheBonesLogic == "Broadside" then
      Cache.APLVar.RtB_Reroll = (not Player:BuffUp(S.Broadside)) and true or false
    -- Buried Treasure
    elseif Settings.Outlaw.RolltheBonesLogic == "Buried Treasure" then
      Cache.APLVar.RtB_Reroll = (not Player:BuffUp(S.BuriedTreasure)) and true or false
    -- Grand Melee
    elseif Settings.Outlaw.RolltheBonesLogic == "Grand Melee" then
      Cache.APLVar.RtB_Reroll = (not Player:BuffUp(S.GrandMelee)) and true or false
    -- Skull and Crossbones
    elseif Settings.Outlaw.RolltheBonesLogic == "Skull and Crossbones" then
      Cache.APLVar.RtB_Reroll = (not Player:BuffUp(S.SkullandCrossbones)) and true or false
    -- Ruthless Precision
    elseif Settings.Outlaw.RolltheBonesLogic == "Ruthless Precision" then
      Cache.APLVar.RtB_Reroll = (not Player:BuffUp(S.RuthlessPrecision)) and true or false
    -- True Bearing
    elseif Settings.Outlaw.RolltheBonesLogic == "True Bearing" then
      Cache.APLVar.RtB_Reroll = (not Player:BuffUp(S.TrueBearing)) and true or false
    -- SimC Default
    else
      -- # Reroll single buffs early other than True Bearing and Broadside
      -- actions+=/variable,name=rtb_reroll,value=rtb_buffs<2&(!buff.true_bearing.up&!buff.broadside.up)
      --Todo fix for Shadowdust
      --Cache.APLVar.RtB_Reroll = (RtB_Buffs() < 2 and (not Player:BuffUp(S.TrueBearing) and not Player:BuffUp(S.Broadside))) and true or false
      --This is only updated for Blunderbuss where we want to keep single BS and SnC
      Cache.APLVar.RtB_Reroll = (RtB_Buffs() < 2 and not (Player:BuffUp(S.Broadside) or Player:BuffUp(S.SkullandCrossbones))) or (RtB_Buffs() == 2 and Player:BuffUp(S.BuriedTreasure) and Player:BuffUp(S.GrandMelee)) and true or false
    end
  end

  return Cache.APLVar.RtB_Reroll
end

-- # Finish at max possible CP without overflowing bonus combo points, unless for BtE which always should be 5+ CP
-- # Always attempt to use BtE at 5+ CP, regardless of CP gen waste
local function Finish_Condition ()
   -- actions+=/variable,name=finish_condition,op=reset,if=cooldown.between_the_eyes.ready&effective_combo_points<5
  if S.BetweentheEyes:CooldownUp() and EffectiveComboPoints < 5 and (Player:BuffUp(S.RuthlessPrecision) or (Target:DebuffRemains(S.BetweentheEyes) < 4 or Target:DebuffRemains(S.BetweentheEyes) == 0)) then --Rogue.CPMaxSpend(
    return false
  end
  -- actions+=/variable,name=finish_condition,value=combo_points>=cp_max_spend-buff.broadside.up-(buff.opportunity.up*talent.quick_draw.enabled)|effective_combo_points>=cp_max_spend
  return ComboPoints >= (Rogue.CPMaxSpend() - num(Player:BuffUp(S.Broadside)) - (num(Player:BuffUp(S.Opportunity)) * num(S.QuickDraw:IsAvailable())))
    or EffectiveComboPoints >= Rogue.CPMaxSpend()
end

-- # Ensure we get full Ambush CP gains and aren't rerolling Count the Odds buffs away
local function Ambush_Condition ()
  -- actions+=/variable,name=ambush_condition,value=combo_points.deficit>=2+buff.broadside.up&energy>=50&(!conduit.count_the_odds|buff.roll_the_bones.remains>=10)
  return ComboPointsDeficit >= 2 + num(Player:BuffUp(S.Broadside)) and EffectiveComboPoints < Rogue.CPMaxSpend()
    and EnergyPredictedStable() > 50 and (not S.CountTheOdds:ConduitEnabled() or Rogue.RtBRemains() > 10)
end
-- # With multiple targets, this variable is checked to decide whether some CDs should be synced with Blade Flurry
-- actions+=/variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.remains>1+talent.killing_spree.enabled
local function Blade_Flurry_Sync ()
  return not AoEON() or EnemiesBFCount < 2 or (Player:BuffRemains(S.BladeFlurry) > 1 + num(S.KillingSpree:IsAvailable()))
end

-- Determine if we are allowed to use Vanish offensively in the current situation
local function Vanish_DPS_Condition ()
  return Settings.Outlaw.Enabled.UseDPSVanish and CDsON() and not (Everyone.IsSoloMode() and Player:IsTanking(Target))
end

local function CDs ()
  if S.BladeFlurry:IsReady() and AoEON() and EnemiesBFCount >= 2 and (not Player:BuffUp(S.BladeFlurry) or Player:BuffRemains(S.BladeFlurry) < 1 or (Player:BuffRemains(S.BladeFlurry) < 3 and Player:EnergyMax())) then
    if WR.Cast(S.BladeFlurry) then return "Cast Blade Flurry" end
  end
  
  if Target:IsSpellInRange(S.SinisterStrike) then

    -- # Using Ambush is a 2% increase, so Vanish can be sometimes be used as a utility spell unless using Master Assassin or Deathly Shadows
    if S.Vanish:IsCastable() and Vanish_DPS_Condition() and not Player:StealthUp(true, true) then
      if not MarkoftheMasterAssassinEquipped then
        -- actions.cds+=/vanish,if=!runeforge.mark_of_the_master_assassin&!stealthed.all&variable.ambush_condition&(!runeforge.deathly_shadows|buff.deathly_shadows.down&combo_points<=2)
        if Ambush_Condition() and (not DeathlyShadowsEquipped or not Player:BuffUp(S.DeathlyShadowsBuff) and ComboPoints <= 2) then
          if WR.Cast(S.Vanish) then return "Cast Vanish" end
        end
      else
        -- actions.cds+=/variable,name=vanish_ma_condition,if=runeforge.mark_of_the_master_assassin&!talent.marked_for_death.enabled,value=(!cooldown.between_the_eyes.ready&variable.finish_condition)|(cooldown.between_the_eyes.ready&variable.ambush_condition)
        -- actions.cds+=/variable,name=vanish_ma_condition,if=runeforge.mark_of_the_master_assassin&talent.marked_for_death.enabled,value=variable.finish_condition
        -- actions.cds+=/vanish,if=variable.vanish_ma_condition&master_assassin_remains=0&variable.blade_flurry_sync
        if Rogue.MasterAssassinsMarkRemains() <= 0 and Blade_Flurry_Sync() then
          if S.MarkedforDeath:IsAvailable() then
            if Finish_Condition() then
              if WR.Cast(S.Vanish) then return "Cast Vanish (MA+MfD)" end
            end
          else
            if (not S.BetweentheEyes:CooldownUp() and Finish_Condition() or S.BetweentheEyes:CooldownUp() and Ambush_Condition()) then
              if WR.Cast(S.Vanish) then return "Cast Vanish (MA)" end
            end
          end
        end
      end
    end
    -- actions.cds+=/adrenaline_rush,if=!buff.adrenaline_rush.up
    if CDsON() and S.AdrenalineRush:IsCastable() and not Player:BuffUp(S.AdrenalineRush) then
      if WR.Cast(S.AdrenalineRush, nil, nil, true) then return "Cast Adrenaline Rush" end
    end
    --Todo:Should add time to die here as well
    if S.Flagellation:IsReady() and not Player:StealthUp(true, true) and (Finish_Condition() or HL.BossFilteredFightRemains("<", 13)) then
      if WR.Cast(S.Flagellation) then return "Cast Flagellation" end
    end
    -- actions.cds+=/roll_the_bones,if=master_assassin_remains=0&buff.dreadblades.down&(buff.roll_the_bones.remains<=3|variable.rtb_reroll)
    if S.RolltheBones:IsReady() and (Rogue.RtBRemains() <= 2 or RtB_Reroll()) then
      if WR.Cast(S.RolltheBones) then return "Cast Roll the Bones" end
    end
  end
  if Blade_Flurry_Sync() then
    -- # Attempt to sync Killing Spree with Vanish for Master Assassin
    -- actions.cds+=/variable,name=killing_spree_vanish_sync,value=!runeforge.mark_of_the_master_assassin|cooldown.vanish.remains>10|master_assassin_remains>2
    -- # Use in 1-2T if BtE is up and won't cap Energy, or at 3T+ (2T+ with Deathly Shadows) or when Master Assassin is up.
    -- actions.cds+=/killing_spree,if=variable.blade_flurry_sync&variable.killing_spree_vanish_sync&!stealthed.rogue&(debuff.between_the_eyes.up&buff.dreadblades.down&energy.deficit>(energy.regen*2+15)|spell_targets.blade_flurry>(2-buff.deathly_shadows.up)|master_assassin_remains>0)
    if CDsON() and S.KillingSpree:IsCastable() and Target:IsSpellInRange(S.KillingSpree) and not Player:StealthUp(true, false)
        and (not MarkoftheMasterAssassinEquipped or S.Vanish:CooldownRemains() > 10 or Rogue.MasterAssassinsMarkRemains() > 2 or not Vanish_DPS_Condition())
        and (Target:DebuffUp(S.BetweentheEyes) and not Player:BuffUp(S.Dreadblades) and Player:EnergyDeficitPredicted() > (Player:EnergyRegen() * 2 + 10)
          or EnemiesBFCount > (2 - num(Player:BuffUp(S.DeathlyShadowsBuff))) or Rogue.MasterAssassinsMarkRemains() > 0) then
      if WR.Cast(S.KillingSpree) then return "Cast Killing Spree" end
    end
    -- blade_rush,if=variable.blade_flurry_sync&(energy.time_to_max>2|spell_targets>2)
    -- actions.cds+=/blade_rush,if=variable.blade_flurry_sync&(energy.time_to_max>2&buff.dreadblades.down|energy<=30|spell_targets>2)
    --if S.BladeRush:IsCastable() and Target:IsSpellInRange(S.BladeRush) and EnemiesBFCount > 4 then
    --  if WR.Cast(S.BladeRush) then return "Cast Blade Rush" end
    --end
    if S.BladeRush:IsCastable() and Target:IsSpellInRange(S.BladeRush) and (EnergyTimeToMaxStable() > 2 and not Player:BuffUp(S.Dreadblades)
      or EnergyPredictedStable() <= 30 or EnemiesBFCount > 4) then
      if WR.Cast(S.BladeRush) then return "Cast Blade Rush" end
    end
  end
  --Racials
  if Target:IsSpellInRange(S.SinisterStrike) then
    if CDsON() then
      -- actions.cds+=/shadowmeld,if=!stealthed.all&variable.ambush_condition
      if Settings.Outlaw.Enabled.UseDPSVanish and S.Shadowmeld:IsCastable() and Ambush_Condition() then
        if WR.Cast(S.Shadowmeld) then return "Cast Shadowmeld" end
      end

      -- actions.cds=potion,if=buff.bloodlust.react|target.time_to_die<=60|buff.adrenaline_rush.up

      -- Racials
      -- actions.cds+=/blood_fury
      if S.BloodFury:IsCastable() then
        if WR.Cast(S.BloodFury, nil, nil, true) then return "Cast Blood Fury" end
      end
      -- actions.cds+=/berserking
      if S.Berserking:IsCastable() then
        if WR.Cast(S.Berserking) then return "Cast Berserking" end
      end
      -- actions.cds+=/fireblood
      if S.Fireblood:IsCastable() then
        if WR.Cast(S.Fireblood) then return "Cast Fireblood" end
      end
      -- actions.cds+=/ancestral_call
      if S.AncestralCall:IsCastable() then
        if WR.Cast(S.AncestralCall) then return "Cast Ancestral Call" end
      end

      -- Trinkets
      -- TODO
    end
  end
end

local function Stealth ()
  -- ER FW Bug
  if Settings.Outlaw.Enabled.VanishEchoingReprimand and CDsON() and S.EchoingReprimand:IsReady() and Target:IsSpellInRange(S.EchoingReprimand) then
    if WR.Cast(S.EchoingReprimand) then return "Cast Echoing Reprimand" end
  end
  -- actions.stealth=dispatch,if=variable.finish_condition
  if S.Dispatch:IsCastable() and Target:IsSpellInRange(S.Dispatch) and Finish_Condition() then
    if WR.Cast(S.Dispatch) then return "Cast Dispatch" end
  end
    -- actions.stealth=ambush
  if S.Ambush:IsCastable() and Target:IsSpellInRange(S.Ambush) then
    if WR.Cast(S.Ambush) then return "Cast Ambush" end
  end
end

local function Finish ()
  --if S.BetweentheEyes:IsCastable() and Target:IsSpellInRange(S.BetweentheEyes) and (Target:FilteredTimeToDie(">", 3) or Target:TimeToDieIsNotValid()) and (Target:DebuffRemains(S.BetweentheEyes) < 4 or Target:DebuffRemains(S.BetweentheEyes) == 0) and Rogue.CanDoTUnit(Target, BetweenTheEyesDMGThreshold) then
  if S.BetweentheEyes:IsCastable() and Target:IsSpellInRange(S.BetweentheEyes) and (Player:BuffUp(S.RuthlessPrecision) or Target:DebuffRemains(S.BetweentheEyes) < 4 or not Target:DebuffUp(S.BetweentheEyes)) then
    if WR.Cast(S.BetweentheEyes) then return "Cast Between the Eyes" end
  end
  if S.SliceandDice:IsCastable() and (HL.FilteredFightRemains(EnemiesBF, ">", Player:BuffRemains(S.SliceandDice), true) or Player:BuffRemains(S.SliceandDice) == 0)
    and Player:BuffRemains(S.SliceandDice) < 9 then --(1 + ComboPoints) * 1.8
    if WR.Cast(S.SliceandDice) then return "Cast Slice and Dice" end
  end
  -- actions.finish+=/dispatch
  if S.Dispatch:IsCastable() and Target:IsSpellInRange(S.Dispatch) then
    if WR.Cast(S.Dispatch) then return "Cast Dispatch" end
  end
end

local function Build ()
  if S.PistolShot:IsCastable() and Target:IsSpellInRange(S.PistolShot) and Player:BuffUp(S.Opportunity) then
    if Player:BuffUp(S.GreenskinsWickers) or Player:BuffUp(S.ConcealedBlunderbuss) or Player:BuffUp(S.TornadoTriggerBuff) then
      if WR.Cast(S.PistolShot) then return "Cast Pistol Shot (Buffed)" end
    end
    --if Player:EnergyDeficitPredicted() > (Player:EnergyRegen()*1.5) or ComboPointsDeficit <= 1 + num(Player:BuffUp(S.Broadside)) then
    if Player:Energy() < 45 or ComboPointsDeficit <= 1 + num(Player:BuffUp(S.Broadside)) then
      if WR.Cast(S.PistolShot) then return "Cast Pistol Shot" end
    end
  end
  if S.SinisterStrike:IsCastable() and Target:IsSpellInRange(S.SinisterStrike) then
    if WR.Cast(S.SinisterStrike) then return "Cast Sinister Strike" end
  end
end

--- ======= MAIN =======
local function APL ()
  -- Local Update
  BladeFlurryRange = S.AcrobaticStrikes:IsAvailable() and 9 or 6
  BetweenTheEyesDMGThreshold = S.Dispatch:Damage() * 1.25
  ComboPoints = Player:ComboPoints()
  EffectiveComboPoints = Rogue.EffectiveComboPoints(ComboPoints)
  ComboPointsDeficit = Player:ComboPointsDeficit()

  -- Unit Update
  if AoEON() then
    Enemies30y = Player:GetEnemiesInRange(30) -- Serrated Bone Spike cycle
    EnemiesBF = Player:GetEnemiesInRange(BladeFlurryRange)
    EnemiesBFCount = #EnemiesBF
  else
    EnemiesBFCount = 1
  end

  -- Defensives
  -- Crimson Vial
  ShouldReturn = Rogue.CrimsonVial()
  if ShouldReturn then return ShouldReturn end
  -- Feint
  ShouldReturn = Rogue.Feint()
  if ShouldReturn then return ShouldReturn end

  -- Poisons
  --Rogue.Poisons()

  -- Out of Combat
  if not Player:AffectingCombat() then
    -- Stealth
    if not Player:BuffUp(S.VanishBuff) then
      ShouldReturn = Rogue.Stealth(S.Stealth)
      if ShouldReturn then return ShouldReturn end
    end
    -- Flask
    -- Food
    -- Rune
    -- PrePot w/ Bossmod Countdown
    -- Opener
    if Everyone.TargetIsValid() then
      -- Precombat CDs
      -- actions.precombat+=/marked_for_death,precombat_seconds=10,if=raid_event.adds.in>25
      if CDsON() and S.MarkedforDeath:IsCastable() and ComboPointsDeficit >= Rogue.CPMaxSpend() - 1 then
        if Settings.Commons.STMfDAsDPSCD then
          if WR.Cast(S.MarkedforDeath) then return "Cast Marked for Death (OOC)" end
        else
          if WR.Cast(S.MarkedforDeath) then return "Cast Marked for Death (OOC)" end
        end
      end
      -- TODO actions.precombat+=/fleshcraft,if=soulbind.pustule_eruption|soulbind.volatile_solvent
      -- actions.precombat+=/roll_the_bones,precombat_seconds=2
      if S.RolltheBones:IsReady() and (Rogue.RtBRemains() <= 3 or RtB_Reroll()) then
        if WR.Cast(S.RolltheBones) then return "Cast Roll the Bones (Opener)" end
      end
      -- actions.precombat+=/slice_and_dice,precombat_seconds=1
      if S.SliceandDice:IsReady() and Player:BuffRemains(S.SliceandDice) < (1 + ComboPoints) * 1.8 then
        if WR.Cast(S.SliceandDice) then return "Cast Slice and Dice (Opener)" end
      end
      if Player:StealthUp(true, true) then
        ShouldReturn = Stealth()
        if ShouldReturn then return "Stealth (Opener): " .. ShouldReturn end
      elseif Finish_Condition() then
        ShouldReturn = Finish()
        if ShouldReturn then return "Finish (Opener): " .. ShouldReturn end
      elseif S.SinisterStrike:IsCastable() then
        if WR.Cast(S.SinisterStrike) then return "Cast Sinister Strike (Opener)" end
      end
    end
    return
  end
  -- In Combat
  -- MfD Sniping (Higher Priority than APL)
  -- actions.cds+=/marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit|((raid_event.adds.in>40|buff.true_bearing.remains>15-buff.adrenaline_rush.up*5)&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
  -- actions.cds+=/marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1
  if S.MarkedforDeath:IsCastable() then
    if EnemiesBFCount == 1 and not Player:StealthUp(true, false) and ComboPointsDeficit >= Rogue.CPMaxSpend() - 1 then
      if Settings.Commons.STMfDAsDPSCD then
        if WR.Cast(S.MarkedforDeath) then return "Cast Marked for Death (ST)" end
      else
        WR.Cast(S.MarkedforDeath)
      end
    end
  end

  if Everyone.TargetIsValid() then
    -- Interrupts
    --ShouldReturn = Everyone.Interrupt(S.Kick, 5, true)
    --if ShouldReturn then return ShouldReturn end
    --ShouldReturn = Everyone.InterruptWithStun(S.Blind, 5)
    --if ShouldReturn then return ShouldReturn end
    --if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
    --  if Cast(M.Healthstone, nil, nil, true) then return "healthstone defensive 3"; end
    --end
    --if Player:HealthPercentage() <= Settings.General.HP.PhialOfSerenity and I.PhialofSerenity:IsReady() then
    --  if Cast(M.PhialofSerenity, nil, nil, true) then return "phial_of_serenity defensive 4"; end
    --end
    --if Settings.General.Enabled.Potions and I.PotionofSpectralAgility:IsReady() and (Player:BloodlustUp() and Player:BuffUp(S.AdrenalineRush) > 8 or Target:TimeToDie() <= 30) then
    --  if Cast(M.PotionofSpectralStrength, nil, nil, true) then return "potion main 6"; end
    --end  
  

    -- actions+=/call_action_list,name=stealth,if=stealthed.all
    if Player:StealthUp(true, true) then
      ShouldReturn = Stealth()
      if ShouldReturn then return "Stealth: " .. ShouldReturn end
    end
    -- actions+=/call_action_list,name=cds
    ShouldReturn = CDs()
    if ShouldReturn then return "CDs: " .. ShouldReturn end
    -- actions+=/run_action_list,name=finish,if=variable.finish_condition
    if Finish_Condition() then
      ShouldReturn = Finish()
      if ShouldReturn then return "Finish: " .. ShouldReturn end
      -- run_action_list forces the return
      WR.Cast(S.PoolEnergy)
      return "Finish Pooling"
    end
    -- actions+=/call_action_list,name=build
    ShouldReturn = Build()
    if ShouldReturn then return "Build: " .. ShouldReturn end
    -- actions+=/arcane_torrent,if=energy.deficit>=15+energy.regen
    if S.ArcaneTorrent:IsCastable() and Target:IsSpellInRange(S.SinisterStrike) and Player:EnergyDeficitPredicted() > 15 + Player:EnergyRegen() then
      if WR.Cast(S.ArcaneTorrent) then return "Cast Arcane Torrent" end
    end
    -- actions+=/arcane_pulse
    if S.ArcanePulse:IsCastable() and Target:IsSpellInRange(S.SinisterStrike) then
      if WR.Cast(S.ArcanePulse) then return "Cast Arcane Pulse" end
    end
    -- actions+=/lights_judgment
    if S.LightsJudgment:IsCastable() and Target:IsInMeleeRange(5) then
      if WR.Cast(S.LightsJudgment) then return "Cast Lights Judgment" end
    end
    -- actions+=/bag_of_tricks
    if S.BagofTricks:IsCastable() and Target:IsInMeleeRange(5) then
      if WR.Cast(S.BagofTricks) then return "Cast Bag of Tricks" end
    end
    -- OutofRange Pistol Shot
    if S.PistolShot:IsCastable() and Target:IsSpellInRange(S.PistolShot) and not Target:IsInRange(BladeFlurryRange) and not Player:StealthUp(true, true) and Player:EnergyDeficitPredicted() < 25 and (ComboPointsDeficit >= 1 or EnergyTimeToMaxStable() <= 1.2) then
      if WR.Cast(S.PistolShot) then return "Cast Pistol Shot (OOR)" end
    end
  end
end

local function AutoBind()
  -- Spell Binds
  WR.Bind(S.AdrenalineRush)
  WR.Bind(S.Ambush)
  WR.Bind(S.BetweentheEyes)
  WR.Bind(S.BladeFlurry)
  WR.Bind(S.BladeRush)
  WR.Bind(S.Dispatch)
  WR.Bind(S.Flagellation)
  WR.Bind(S.PistolShot)
  WR.Bind(S.RolltheBones)
  WR.Bind(S.Shiv)
  WR.Bind(S.SinisterStrike)
  WR.Bind(S.Stealth)
  WR.Bind(S.Vanish)
  WR.Bind(S.ArcaneTorrent)
  WR.Bind(S.MarkedforDeath)
  WR.Bind(S.SliceandDice)
  WR.Bind(S.BloodFury)
  --WR.Bind(S.DeadlyPoison)
  WR.Bind(S.NumbingPoison)
  WR.Bind(S.InstantPoison)
  --WR.Bind(S.WoundPoison)
  --WR.Bind(S.CripplingPoison)
  WR.Bind(S.CrimsonVial)
  WR.Bind(S.Feint)
  --WR.Bind(M.Healthstone)
  --WR.Bind(M.PotionofSpectralStrength)
  --WR.Bind(M.PhialofSerenity)
end

local function Init ()
  WR.Print("Outlaw Rogue by Worldy")
  AutoBind()
  S.Flagellation:RegisterAuraTracking()
end

WR.SetAPL(260, APL, Init)
