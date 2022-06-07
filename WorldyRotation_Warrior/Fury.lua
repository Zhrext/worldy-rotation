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
local Mouseover  = Unit.MouseOver
local Spell      = HL.Spell
local Item       = HL.Item
local Utils      = HL.Utils
-- WorldyRotation
local WR         = WorldyRotation
local Cast       = WR.Cast
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Macro      = WR.Macro


--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I/M for spell, item and macro arrays
local S = Spell.Warrior.Fury
local I = Item.Warrior.Fury
local M = Macro.Warrior.Fury

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  I.FlameofBattle:ID(),
  I.InscrutableQuantumDevice:ID(),
  I.InstructorsDivineBell:ID(),
  I.MacabreSheetMusic:ID(),
  I.OverwhelmingPowerCrystal:ID(),
  I.WakenersFrond:ID(),
  I.SinfulGladiatorsBadge:ID(),
  I.UnchainedGladiatorsBadge:ID(),
}

-- Variables
local EnrageUp
local VarExecutePhase
local VarUniqueLegendaries

-- Enemies Variables
local Enemies8y, EnemiesCount8
local TargetInMeleeRange

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Warrior.Commons,
  Fury = WR.GUISettings.APL.Warrior.Fury
}

-- Interrupts List
local StunInterrupts = {
  {S.StormBolt, "Cast Storm Bolt (Interrupt)", function () return true; end},
}

-- Legendaries
local SignetofTormentedKingsEquipped = Player:HasLegendaryEquipped(181)
local WilloftheBerserkerEquipped = Player:HasLegendaryEquipped(189)
local ElysianMightEquipped = Player:HasLegendaryEquipped(263)
local SinfulSurgeEquipped = Player:HasLegendaryEquipped(215)

-- Event Registrations
HL:RegisterForEvent(function()
  SignetofTormentedKingsEquipped = Player:HasLegendaryEquipped(181)
  WilloftheBerserkerEquipped = Player:HasLegendaryEquipped(189)
  ElysianMightEquipped = Player:HasLegendaryEquipped(263)
  SinfulSurgeEquipped = Player:HasLegendaryEquipped(215)
end, "PLAYER_EQUIPMENT_CHANGED")

-- Player Covenant
-- 0: none, 1: Kyrian, 2: Venthyr, 3: Night Fae, 4: Necrolord
local CovenantID = Player:CovenantID()

-- Update CovenantID if we change Covenants
HL:RegisterForEvent(function()
  CovenantID = Player:CovenantID()
end, "COVENANT_CHOSEN")

local function AOE()
  -- cancel_buff,name=bladestorm,if=spell_targets.whirlwind>1&gcd.remains=0&soulbind.first_strike&buff.first_strike.remains&buff.enrage.remains<gcd
  -- ancient_aftershock,if=buff.enrage.up&cooldown.recklessness.remains>5&spell_targets.whirlwind>1
  if CDsON() and S.AncientAftershock:IsCastable() and (EnrageUp and S.Recklessness:CooldownRemains() > 5 and EnemiesCount8 > 1) then
    if Cast(S.AncientAftershock, not Target:IsInMeleeRange(12)) then return "ancient_aftershock aoe 2"; end
  end
  -- spear_of_bastion,if=buff.enrage.up&rage<40&spell_targets.whirlwind>1
  if CDsON() and S.SpearofBastion:IsCastable() and (EnrageUp and Player:Rage() < 40 and EnemiesCount8 > 1) then
    if Cast(M.SpearofBastionPlayer, not Target:IsInRange(25)) then return "spear_of_bastion aoe 4"; end
  end
  -- bladestorm,if=buff.enrage.up&spell_targets.whirlwind>2
  if CDsON() and S.Bladestorm:IsCastable() and (EnrageUp and EnemiesCount8 > 2) then
    if Cast(S.Bladestorm, not Target:IsInRange(8)) then return "bladestorm aoe 6"; end
  end
  -- condemn,if=spell_targets.whirlwind>1&(buff.enrage.up|buff.recklessness.up&runeforge.sinful_surge)&variable.execute_phase
  if S.Condemn:IsCastable() and (EnemiesCount8 > 1 and (EnrageUp or Player:BuffUp(S.RecklessnessBuff) and SinfulSurgeEquipped) and VarExecutePhase) then
    if Cast(S.Condemn, not TargetInMeleeRange) then return "condemn aoe 8"; end
  end
  -- siegebreaker,if=spell_targets.whirlwind>1
  if S.Siegebreaker:IsCastable() and (EnemiesCount8 > 1) then
    if Cast(S.Siegebreaker, not TargetInMeleeRange) then return "siegebreaker aoe 10"; end
  end
  -- rampage,if=spell_targets.whirlwind>1
  if S.Rampage:IsReady() and (EnemiesCount8 > 1) then
    if Cast(S.Rampage, not TargetInMeleeRange) then return "rampage aoe 12"; end
  end
  -- spear_of_bastion,if=buff.enrage.up&cooldown.recklessness.remains>5&spell_targets.whirlwind>1
  if CDsON() and S.SpearofBastion:IsCastable() and (EnrageUp and S.Recklessness:CooldownRemains() > 5 and EnemiesCount8 > 1) then
    if Cast(M.SpearofBastionPlayer, not Target:IsInRange(25)) then return "spear_of_bastion aoe 14"; end
  end
  -- bladestorm,if=buff.enrage.remains>gcd*2.5&spell_targets.whirlwind>1
  if CDsON() and S.Bladestorm:IsCastable() and (Player:BuffRemains(S.EnrageBuff) > Player:GCD() * 2.5 and EnemiesCount8 > 1) then
    if Cast(S.Bladestorm, not Target:IsInRange(8)) then return "bladestorm aoe 16"; end
  end
end

local function SingleTarget()
  -- raging_blow,if=runeforge.will_of_the_berserker.equipped&buff.will_of_the_berserker.remains<gcd
  if S.RagingBlow:IsCastable() and (WilloftheBerserkerEquipped and Player:BuffRemains(S.WilloftheBerserkerBuff) < Player:GCD()) then
    if Cast(S.RagingBlow, not TargetInMeleeRange) then return "raging_blow single_target 2"; end
  end
  -- crushing_blow,if=runeforge.will_of_the_berserker.equipped&buff.will_of_the_berserker.remains<gcd
  if S.CrushingBlow:IsCastable() and (WilloftheBerserkerEquipped and Player:BuffRemains(S.WilloftheBerserkerBuff) < Player:GCD()) then
    if Cast(S.CrushingBlow, not TargetInMeleeRange) then return "crushing_blow single_target 4"; end
  end
  -- cancel_buff,name=bladestorm,if=spell_targets.whirlwind=1&gcd.remains=0&(talent.massacre.enabled|covenant.venthyr.enabled)&variable.execute_phase&(rage>90|!cooldown.condemn.remains)
  -- condemn,if=(buff.enrage.up|buff.recklessness.up&runeforge.sinful_surge)&variable.execute_phase
  if S.Condemn:IsCastable() and ((EnrageUp or Player:BuffUp(S.RecklessnessBuff) and SinfulSurgeEquipped) and VarExecutePhase) then
    if Cast(S.Condemn, not TargetInMeleeRange) then return "condemn single_target 8"; end
  end
  -- siegebreaker,if=spell_targets.whirlwind>1|raid_event.adds.in>15
  if S.Siegebreaker:IsCastable() then
    if Cast(S.Siegebreaker, not TargetInMeleeRange) then return "siegebreaker single_target 10"; end
  end
  -- rampage,if=buff.recklessness.up|(buff.enrage.remains<gcd|rage>80)|buff.frenzy.remains<1.5
  if S.Rampage:IsReady() and (Player:BuffUp(S.RecklessnessBuff) or (Player:BuffRemains(S.EnrageBuff) < Player:GCD() or Player:Rage() > 80) or Player:BuffRemains(S.FrenzyBuff) < 1.5) then
    if Cast(S.Rampage, not TargetInMeleeRange) then return "rampage single_target 12"; end
  end
  -- condemn
  if S.Condemn:IsReady() then
    if Cast(S.Condemn, not TargetInMeleeRange) then return "condemn single_target 14"; end
  end
  -- ancient_aftershock,if=buff.enrage.up&cooldown.recklessness.remains>5&(target.time_to_die>95|buff.recklessness.up|target.time_to_die<20)&raid_event.adds.in>75
  if CDsON() and S.AncientAftershock:IsCastable() and (EnrageUp and S.Recklessness:CooldownRemains() > 5 and (Target:TimeToDie() > 95 or Player:BuffUp(S.RecklessnessBuff) or Target:TimeToDie() < 20)) then
    if Cast(S.AncientAftershock, not Target:IsInRange(12)) then return "ancient_aftershock single_target 16"; end
  end
  -- crushing_blow,if=set_bonus.tier28_2pc|charges=2|(buff.recklessness.up&variable.execute_phase&talent.massacre.enabled)
  if S.CrushingBlow:IsCastable() and (Player:HasTier(28, 2) or S.CrushingBlow:Charges() == 2 or (Player:BuffUp(S.RecklessnessBuff) and VarExecutePhase and S.Massacre:IsAvailable())) then
    if Cast(S.CrushingBlow, not TargetInMeleeRange) then return "crushing_blow single_target 18"; end
  end
  -- execute
  if S.Execute:IsReady() then
    if Cast(S.Execute, not TargetInMeleeRange) then return "execute single_target 20"; end
  end
  if CDsON() then
    -- spear_of_bastion,if=runeforge.elysian_might&buff.enrage.up&cooldown.recklessness.remains>5&(buff.recklessness.up|target.time_to_die<20|debuff.siegebreaker.up|!talent.siegebreaker&target.time_to_die>68)&raid_event.adds.in>55
    if S.SpearofBastion:IsCastable() and (ElysianMightEquipped and EnrageUp and S.Recklessness:CooldownRemains() > 5 and (Player:BuffUp(S.RecklessnessBuff) or Target:TimeToDie() < 20 or Target:DebuffUp(S.SiegebreakerDebuff) or not S.Siegebreaker:IsAvailable() and Target:TimeToDie() > 68)) then
      if Cast(M.SpearofBastionPlayer, not Target:IsInRange(25)) then return "spear_of_bastion single_target 22"; end
    end
    -- bladestorm,if=buff.enrage.up&(!buff.recklessness.remains|rage<50)&(spell_targets.whirlwind=1&raid_event.adds.in>45|spell_targets.whirlwind=2)
    if S.Bladestorm:IsCastable() and (EnrageUp and (Player:BuffDown(S.RecklessnessBuff) or Player:Rage() < 50) and (EnemiesCount8 == 1 or EnemiesCount8 == 2)) then
      if Cast(S.Bladestorm, not Target:IsInRange(8)) then return "bladestorm single_target 24"; end
    end
    -- spear_of_bastion,if=buff.enrage.up&cooldown.recklessness.remains>5&(buff.recklessness.up|target.time_to_die<20|debuff.siegebreaker.up|!talent.siegebreaker&target.time_to_die>68)&raid_event.adds.in>55
    if S.SpearofBastion:IsCastable() and (EnrageUp and S.Recklessness:CooldownRemains() > 5 and (Player:BuffUp(S.RecklessnessBuff) or Target:TimeToDie() < 20 or Target:DebuffUp(S.SiegebreakerDebuff) or not S.Siegebreaker:IsAvailable() and Target:TimeToDie() > 68)) then
      if Cast(M.SpearofBastionPlayer, not Target:IsInRange(25)) then return "spear_of_bastion single_target 26"; end
    end
  end
  -- raging_blow,if=set_bonus.tier28_2pc|charges=2|buff.recklessness.up&variable.execute_phase&talent.massacre.enabled
  if S.RagingBlow:IsCastable() and (Player:HasTier(28, 2) or S.RagingBlow:Charges() == 2 or Player:BuffUp(S.RecklessnessBuff) and VarExecutePhase and S.Massacre:IsAvailable()) then
    if Cast(S.RagingBlow, not TargetInMeleeRange) then return "raging_blow single_target 28"; end
  end
  -- bloodthirst,if=buff.enrage.down|conduit.vicious_contempt.rank>5&target.health.pct<35
  if S.Bloodthirst:IsCastable() and ((not EnrageUp) or S.ViciousContempt:ConduitRank() > 5 and Target:HealthPercentage() < 35) then
    if Cast(S.Bloodthirst, not TargetInMeleeRange) then return "bloodthirst single_target 30"; end
  end
  -- bloodbath,if=buff.enrage.down|conduit.vicious_contempt.rank>5&target.health.pct<35&!talent.cruelty.enabled
  if S.Bloodbath:IsCastable() and ((not EnrageUp) or S.ViciousContempt:ConduitRank() > 5 and Target:HealthPercentage() < 35 and not S.Cruelty:IsAvailable()) then
    if Cast(S.Bloodbath, not TargetInMeleeRange) then return "bloodbath single_target 32"; end
  end
  -- dragon_roar,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>15)
  if S.DragonRoar:IsCastable() and (EnrageUp) then
    if Cast(S.DragonRoar, not Target:IsInRange(12)) then return "dragon_roar single_target 34"; end
  end
  -- whirlwind,if=buff.merciless_bonegrinder.up&spell_targets.whirlwind>3
  if S.Whirlwind:IsCastable() and (Player:BuffUp(S.MercilessBonegrinderBuff) and EnemiesCount8 > 3) then
    if Cast(S.Whirlwind, not Target:IsInRange(8)) then return "whirlwind single_target 36"; end
  end
  -- onslaught,if=buff.enrage.up
  if S.Onslaught:IsReady() and (EnrageUp) then
    if Cast(S.Onslaught, not TargetInMeleeRange) then return "onslaught single_target 38"; end
  end
  -- bloodthirst
  if S.Bloodthirst:IsCastable() then
    if Cast(S.Bloodthirst, not TargetInMeleeRange) then return "bloodthirst single_target 40"; end
  end
  -- bloodbath
  if S.Bloodbath:IsCastable() then
    if Cast(S.Bloodbath, not TargetInMeleeRange) then return "bloodbath single_target 42"; end
  end
  -- raging_blow
  if S.RagingBlow:IsCastable() then
    if Cast(S.RagingBlow, not TargetInMeleeRange) then return "raging_blow single_target 44"; end
  end
  -- crushing_blow
  if S.CrushingBlow:IsCastable() then
    if Cast(S.CrushingBlow, not TargetInMeleeRange) then return "crushing_blow single_target 46"; end
  end
  -- whirlwind
  if S.Whirlwind:IsCastable() then
    if Cast(S.Whirlwind, not Target:IsInRange(8)) then return "whirlwind single_target 48"; end
  end
end

local function Movement()
  -- heroic_leap
  if Settings.Commons.Enabled.HeroicLeap and S.HeroicLeap:IsCastable() and not Target:IsInMeleeRange(8) and Mouseover and Mouseover:GUID() == Target:GUID() then
    if Cast(M.HeroicLeapCursor) then return "heroic_leap movement 2"; end
  end
end

local function OutOfCombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  -- Manually added: battle_shout,if=buff.battle_shout.remains<60
  if S.BattleShout:IsCastable() and (Player:BuffRemains(S.BattleShoutBuff, true) < 5) then
    if Cast(S.BattleShout) then return "battle_shout precombat 2"; end
  end
end

local function Combat()
  if AoEON() then
    Enemies8y = Player:GetEnemiesInMeleeRange(8)
    EnemiesCount8 = #Enemies8y
  else
    EnemiesCount8 = 1
  end
  
  -- Enrage check
  EnrageUp = Player:BuffUp(S.EnrageBuff)

  -- Range check
  TargetInMeleeRange = Target:IsInMeleeRange(5)

  -- Interrupts
  local ShouldReturn = Everyone.Interrupt(5, S.Pummel, StunInterrupts); if ShouldReturn then return ShouldReturn; end
  -- auto_attack
  -- charge
  if Settings.Commons.Enabled.Charge and S.Charge:IsCastable() then
    if Cast(S.Charge, not Target:IsSpellInRange(S.Charge)) then return "charge main 2"; end
  end
  -- Manually added: VR/IV
  if Player:HealthPercentage() < Settings.Commons.HP.VictoryRushHP then
    if S.VictoryRush:IsReady() then
      if Cast(S.VictoryRush, not TargetInMeleeRange) then return "victory_rush heal"; end
    end
    if S.ImpendingVictory:IsReady() then
      if Cast(S.ImpendingVictory, not TargetInMeleeRange) then return "impending_victory heal"; end
    end
  end
  -- healthstone
  if Player:HealthPercentage() <= Settings.Commons.HP.Healthstone and I.Healthstone:IsReady() then
    if Cast(M.Healthstone) then return "healthstone defensive 3"; end
  end
  -- phial_of_serenity
  if Player:HealthPercentage() <= Settings.Commons.HP.PhialOfSerenity and I.PhialofSerenity:IsReady() then
    if Cast(M.PhialofSerenity) then return "phial_of_serenity defensive 4"; end
  end
  -- variable,name=execute_phase,value=talent.massacre&target.health.pct<35|target.health.pct<20|target.health.pct>80&covenant.venthyr
  VarExecutePhase = (S.Massacre:IsAvailable() and Target:HealthPercentage() < 35 or Target:HealthPercentage() < 20 or Target:HealthPercentage() > 80 and CovenantID == 2)
  -- variable,name=unique_legendaries,value=runeforge.signet_of_tormented_kings|runeforge.sinful_surge|runeforge.elysian_might
  VarUniqueLegendaries = (SignetofTormentedKingsEquipped or SinfulSurgeEquipped or ElysianMightEquipped)
  -- run_action_list,name=movement,if=movement.distance>5
  if (not TargetInMeleeRange) then
    local ShouldReturn = Movement(); if ShouldReturn then return ShouldReturn; end
  end
  -- heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)
  if S.HeroicLeap:IsCastable() and (not Target:IsInRange(25)) and Mouseover and Mouseover:GUID() == Target:GUID() then
    if Cast(M.HeroicLeapCursor) then return "heroic_leap main 4"; end
  end
  -- potion
  if Settings.Commons.Enabled.Potions and I.PotionofSpectralStrength:IsReady() and (Player:BloodlustUp() or Target:TimeToDie() <= 30) then
    if Cast(M.PotionofSpectralStrength) then return "potion main 6"; end
  end
  -- conquerors_banner,if=rage>70
  if S.ConquerorsBanner:IsCastable() and CDsON() and (Player:Rage() > 70) then
    if Cast(S.ConquerorsBanner) then return "conquerors_banner main 8"; end
  end
  -- spear_of_bastion,if=buff.enrage.up&rage<70
  if CDsON() and S.SpearofBastion:IsCastable() and (EnrageUp and Player:Rage() < 70) then
    if Cast(M.SpearofBastionPlayer, not Target:IsInRange(25)) then return "spear_of_bastion main 9"; end
  end
  -- rampage,if=cooldown.recklessness.remains<3&talent.reckless_abandon.enabled
  if S.Rampage:IsReady() and (S.Recklessness:CooldownRemains() < 3 and S.RecklessAbandon:IsAvailable()) then
    if Cast(S.Rampage, not TargetInMeleeRange) then return "rampage main 10"; end
  end
  if CDsON() then
    -- recklessness,if=runeforge.sinful_surge&gcd.remains=0&(variable.execute_phase|(target.time_to_pct_35>40&talent.anger_management|target.time_to_pct_35>70&!talent.anger_management))&(spell_targets.whirlwind=1|buff.meat_cleaver.up)
    if S.Recklessness:IsCastable() and (SinfulSurgeEquipped and (VarExecutePhase or (Target:TimeToX(35) > 40 and S.AngerManagement:IsAvailable() or Target:TimeToX(35) > 70 and not S.AngerManagement:IsAvailable())) and (EnemiesCount8 == 1 or Player:BuffUp(S.MeatCleaverBuff))) then
      if Cast(S.Recklessness) then return "recklessness main 11"; end
    end
    -- recklessness,if=runeforge.elysian_might&gcd.remains=0&(cooldown.spear_of_bastion.remains<5|cooldown.spear_of_bastion.remains>20)&((buff.bloodlust.up|talent.anger_management.enabled|raid_event.adds.in>10)|target.time_to_die>100|variable.execute_phase|target.time_to_die<15&raid_event.adds.in>10)&(spell_targets.whirlwind=1|buff.meat_cleaver.up)
    if S.Recklessness:IsCastable() and (ElysianMightEquipped and (S.SpearofBastion:CooldownRemains() < 5 or S.SpearofBastion:CooldownRemains() > 20) and ((Player:BloodlustUp() or S.AngerManagement:IsAvailable() or EnemiesCount8 == 1) or Target:TimeToDie() > 100 or VarExecutePhase or Target:TimeToDie() < 15) and (EnemiesCount8 == 1 or Player:BuffUp(S.MeatCleaverBuff))) then
      if Cast(S.Recklessness) then return "recklessness main 12"; end
    end
    -- recklessness,if=!variable.unique_legendaries&gcd.remains=0&((buff.bloodlust.up|talent.anger_management.enabled|raid_event.adds.in>10)|target.time_to_die>100|variable.execute_phase|target.time_to_die<15&raid_event.adds.in>10)&(spell_targets.whirlwind=1|buff.meat_cleaver.up)&(!covenant.necrolord|cooldown.conquerors_banner.remains>20)
    if S.Recklessness:IsCastable() and (not VarUniqueLegendaries and ((Player:BloodlustUp() or S.AngerManagement:IsAvailable() or EnemiesCount8 == 1) or Target:TimeToDie() > 100 or VarExecutePhase or Target:TimeToDie() < 15) and (EnemiesCount8 == 1 or Player:BuffUp(S.MeatCleaverBuff)) and (CovenantID ~= 4 or S.ConquerorsBanner:CooldownRemains() > 20)) then
      if Cast(S.Recklessness) then return "recklessness main 13"; end
    end
    -- recklessness,use_off_gcd=1,if=runeforge.signet_of_tormented_kings.equipped&gcd.remains&prev_gcd.1.rampage&((buff.bloodlust.up|talent.anger_management.enabled|raid_event.adds.in>10)|target.time_to_die>100|variable.execute_phase|target.time_to_die<15&raid_event.adds.in>10)&(spell_targets.whirlwind=1|buff.meat_cleaver.up)
    if S.Recklessness:IsCastable() and (SignetofTormentedKingsEquipped and Player:PrevGCDP(1, S.Rampage) and ((Player:BloodlustUp() or S.AngerManagement:IsAvailable()) or Target:TimeToDie() > 100 or VarExecutePhase) and (EnemiesCount8 == 1 or Player:BuffUp(S.MeatCleaverBuff))) then
      if Cast(S.Recklessness) then return "recklessness main 14"; end
    end
  end
  -- whirlwind,if=spell_targets.whirlwind>1&!buff.meat_cleaver.up|raid_event.adds.in<gcd&!buff.meat_cleaver.up
  if S.Whirlwind:IsCastable() and (EnemiesCount8 > 1 and Player:BuffDown(S.MeatCleaverBuff)) then
    if Cast(S.Whirlwind, not Target:IsInMeleeRange(8)) then return "whirlwind main 16"; end
  end
  -- trinkets
  if Settings.Commons.Enabled.Trinkets then
    local TrinketToUse = Player:GetUseableTrinkets(OnUseExcludes)
    if TrinketToUse then
      if Utils.ValueIsInArray(TrinketToUse:SlotIDs(), 13) then
        if Cast(M.Trinket1) then return "use_trinket " .. TrinketToUse:Name() .. " damage 1"; end
      elseif Utils.ValueIsInArray(TrinketToUse:SlotIDs(), 14) then
        if Cast(M.Trinket2) then return "use_trinket " .. TrinketToUse:Name() .. " damage 2"; end
      end
    end
  end
  if CDsON() then
    -- arcane_torrent,if=rage<40&!buff.recklessness.up
    if S.ArcaneTorrent:IsCastable() and (Player:Rage() < 40 and Player:BuffDown(S.RecklessnessBuff)) then
      if Cast(S.ArcaneTorrent, not Target:IsInRange(8)) then return "arcane_torrent"; end
    end
    -- lights_judgment,if=buff.recklessness.down&debuff.siegebreaker.down
    if S.LightsJudgment:IsCastable() and (Player:BuffDown(S.RecklessnessBuff) and Target:DebuffDown(S.SiegebreakerDebuff)) then
      if Cast(S.LightsJudgment, not Target:IsSpellInRange(S.LightsJudgment)) then return "lights_judgment"; end
    end
    -- bag_of_tricks,if=buff.recklessness.down&debuff.siegebreaker.down&buff.enrage.up
    if S.BagofTricks:IsCastable() and (Player:BuffDown(S.RecklessnessBuff) and Target:DebuffDown(S.SiegebreakerDebuff) and EnrageUp) then
      if Cast(S.BagofTricks, not Target:IsSpellInRange(S.BagofTricks)) then return "bag_of_tricks"; end
    end
    -- berserking,if=buff.recklessness.up
    if S.Berserking:IsCastable() and (Player:BuffUp(S.RecklessnessBuff)) then
      if Cast(S.Berserking) then return "berserking"; end
    end
    -- blood_fury
    if S.BloodFury:IsCastable() then
      if Cast(S.BloodFury) then return "blood_fury"; end
    end
    -- fireblood
    if S.Fireblood:IsCastable() then
      if Cast(S.Fireblood) then return "fireblood"; end
    end
    -- ancestral_call
    if S.AncestralCall:IsCastable() then
      if Cast(S.AncestralCall) then return "ancestral_call"; end
    end
  end
  -- call_action_list,name=aoe
  local ShouldReturn = AOE(); if ShouldReturn then return ShouldReturn; end
  -- call_action_list,name=single_target
  local ShouldReturn = SingleTarget(); if ShouldReturn then return ShouldReturn; end
end

--- ======= ACTION LISTS =======
local function APL()
  if not Player:AffectingCombat() then
    -- call Precombat
    local ShouldReturn = OutOfCombat(); if ShouldReturn then return ShouldReturn; end
  else
    if Everyone.TargetIsValid() then
      -- In Combat
      local ShouldReturn = Combat(); if ShouldReturn then return ShouldReturn; end
    end
  end
end

local function AutoBind()
  -- Racials
  WR.Bind(S.AncestralCall)
  WR.Bind(S.ArcaneTorrent)
  WR.Bind(S.BagofTricks)
  WR.Bind(S.Berserking)
  WR.Bind(S.BloodFury)
  WR.Bind(S.Fireblood)
  WR.Bind(S.LightsJudgment)
  -- Bind Spells
  WR.Bind(S.BattleShout)
  WR.Bind(S.Bladestorm)
  WR.Bind(S.Bloodbath)
  WR.Bind(S.Bloodthirst)
  WR.Bind(S.Charge)
  WR.Bind(S.CrushingBlow)
  WR.Bind(S.Execute)
  WR.Bind(S.HeroicLeap)
  WR.Bind(S.IntimidatingShout)
  WR.Bind(S.Pummel)
  WR.Bind(S.RagingBlow)
  WR.Bind(S.Rampage)
  WR.Bind(S.Recklessness)
  WR.Bind(S.StormBolt)
  WR.Bind(S.VictoryRush)
  WR.Bind(S.Whirlwind)
  -- Bind Items
  WR.Bind(M.Trinket1)
  WR.Bind(M.Trinket2)
  WR.Bind(M.Healthstone)
  WR.Bind(M.PotionofSpectralStrength)
  WR.Bind(M.PhialofSerenity)
  -- Bind Macros
  WR.Bind(M.HeroicLeapCursor)
  WR.Bind(M.SpearofBastionPlayer)
end

local function Init()
  WR.Print("Fury Warrior by Worldy")
  AutoBind()
end

WR.SetAPL(72, APL, Init)
