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
local Spell      = HL.Spell
local Item       = HL.Item
-- WorldyRotation
local WR         = WorldyRotation
local Bind       = WR.Bind
local Cast       = WR.Cast
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Macro      = WR.Macro
local Press      = WR.Press
-- Num/Bool Helper Functions
local num        = WR.Commons.Everyone.num
local bool       = WR.Commons.Everyone.bool

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.Warrior.Arms
local I = Item.Warrior.Arms
local M = Macro.Warrior.Arms

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  I.ManicGrieftorch:ID(),
}

-- Variables
local TargetInMeleeRange

-- Enemies Variables
local Enemies8y
local EnemiesCount8y

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Warrior.Commons,
  Arms = WR.GUISettings.APL.Warrior.Arms
}

local function EvaluateCycleColossusSmash(TargetUnit)
  -- if=(target.health.pct<20|talent.massacre&target.health.pct<35)
  return (TargetUnit:HealthPercentage() > 20 or S.Massacre:IsAvailable() and TargetUnit:HealthPercentage() < 35)
end

local function EvaluateCycleMortalStrike(TargetUnit)
  -- if=debuff.executioners_precision.stack=2|dot.deep_wounds.remains<=gcd|talent.dreadnaught&talent.battlelord&active_enemies<=2
  return (TargetUnit:DebuffStack(S.ExecutionersPrecisionDebuff) == 2 or TargetUnit:DebuffRemains(S.DeepWoundsDebuff) <= Player:GCD() or S.Dreadnaught:IsAvailable() and S.Battlelord:IsAvailable() and EnemiesCount8y <= 2)
end

local function EvaluateCycleExecute(TargetUnit)
  --if=buff.sudden_death.react|active_enemies<=2&(target.health.pct<20|talent.massacre&target.health.pct<35)|buff.sweeping_strikes.up
  return (Player:BuffUp(S.SuddenDeathBuff) or EnemiesCount8y <= 2 and (TargetUnit:HealthPercentage() < 20 or S.Massacre:IsAvailable() and TargetUnit:HealthPercentage() < 35) or Player:BuffUp(S.SweepingStrikes) )
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  --battle_stance,toggle=on
  if S.BattleStance:IsCastable() and Player:BuffDown(S.BattleStance, true) then
    if Press(S.BattleStance) then return "battle_stance"; end
  end
  -- Manually added: pre-pull
  if TargetInMeleeRange then
    if S.Skullsplitter:IsCastable() then
      if Press(S.Skullsplitter) then return "skullsplitter precombat"; end
    end
    if S.ColossusSmash:IsCastable() then
      if Press(S.ColossusSmash) then return "colossus_smash precombat"; end
    end
    if S.Warbreaker:IsCastable() then
      if Press(S.Warbreaker) then return "warbreaker precombat"; end
    end
    if S.Overpower:IsCastable() then
      if Press(S.Overpower) then return "overpower precombat"; end
    end
  end
  if Settings.Commons.Enabled.Charge and S.Charge:IsCastable() then
    if Press(S.Charge) then return "charge precombat"; end
  end
end

local function Hac()
  -- execute,if=buff.juggernaut.up&buff.juggernaut.remains<gcd
  if S.Execute:IsReady() and Player:BuffUp(S.JuggernautBuff) and Player:BuffRemains(S.JuggernautBuff) < Player:GCD() then
    if Press(S.Execute, not TargetInMeleeRange) then return "execute hac 67"; end
  end
  -- thunder_clap,if=active_enemies>2&talent.thunder_clap&talent.blood_and_thunder&talent.rend&dot.rend.remains<=dot.rend.duration*0.3
  if S.ThunderClap:IsReady() and EnemiesCount8y > 2 and S.BloodandThunder:IsAvailable() and S.Rend:IsAvailable() and Target:DebuffRefreshable(S.RendDebuff) then
    if Press(S.ThunderClap, not TargetInMeleeRange) then return "thunder_clap hac 68"; end
  end
  -- sweeping_strikes,if=active_enemies>=2&(cooldown.bladestorm.remains>15|!talent.bladestorm)
  if S.SweepingStrikes:IsCastable() and (EnemiesCount8y >= 2) and (S.Bladestorm:CooldownRemains() > 15 or not S.Bladestorm:IsAvailable()) then
    if Press(S.SweepingStrikes, not Target:IsInMeleeRange(8)) then return "sweeping_strikes hac 68"; end
  end
  -- rend,if=active_enemies=1&remains<=gcd&(target.health.pct>20|talent.massacre&target.health.pct>35)|talent.tide_of_blood&cooldown.skullsplitter.remains<=gcd&(cooldown.colossus_smash.remains<=gcd|debuff.colossus_smash.up)&dot.rend.remains<dot.rend.duration*0.85
  if S.Rend:IsReady() and EnemiesCount8y == 1 and (Target:HealthPercentage() > 20 or S.Massacre:IsAvailable() and Target:HealthPercentage() < 35) or S.TideofBlood:IsAvailable() and S.Skullsplitter:CooldownRemains() <= Player:GCD() and (S.ColossusSmash:CooldownRemains() < Player:GCD() or Target:DebuffUp(S.ColossusSmashDebuff)) and Target:DebuffRemains(S.RendDebuff) < 21 * 0.85 then
    if Press(S.Rend, not TargetInMeleeRange) then return "rend hac 70"; end
  end
  -- avatar,if=raid_event.adds.in>15|talent.blademasters_torment&active_enemies>1|target.time_to_die<20
  if CDsON() and S.Avatar:IsCastable() and ((S.BlademastersTorment:IsAvailable() and EnemiesCount8y > 1) or HL.FightRemains() < 20) then
    if Press(S.Avatar) then return "avatar hac 71"; end
  end
  -- warbreaker,if=raid_event.adds.in>22|active_enemies>1
  if S.Warbreaker:IsCastable() and EnemiesCount8y > 1 then
    if Press(S.Warbreaker, not TargetInMeleeRange) then return "warbreaker hac 72"; end
  end
  -- colossus_smash,cycle_targets=1,if=(target.health.pct<20|talent.massacre&target.health.pct<35)
  if CDsON() and S.ColossusSmash:IsCastable() then
    if Everyone.CastCycle(S.ColossusSmash, Enemies8y, EvaluateCycleColossusSmash, not TargetInMeleeRange) then return "colossus_smash hac 73"; end
  end
  -- colossus_smash
  if CDsON() and S.ColossusSmash:IsCastable() then
    if Press(S.ColossusSmash, not TargetInMeleeRange) then return "colossus_smash hac 74"; end
  end
  -- thunderous_roar,if=(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)&raid_event.adds.in>15|active_enemies>1&dot.deep_wounds.remains
  if CDsON() and S.ThunderousRoar:IsCastable() and ((Player:BuffUp(S.TestofMightBuff) or (not S.TestofMight:IsAvailable()) and Target:DebuffUp(S.ColossusSmashDebuff)) or EnemiesCount8y > 1 and Target:DebuffRemains(S.DeepWoundsDebuff) > 0) then
    if Press(S.ThunderousRoar, not Target:IsInMeleeRange(12)) then return "thunderous_roar hac 75"; end
  end
  -- spear_of_bastion,if=(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)&raid_event.adds.in>15
  if CDsON() and S.SpearofBastion:IsCastable() and (Player:BuffUp(S.TestofMightBuff) or not S.TestofMight:IsAvailable() and Target:DebuffUp(S.ColossusSmashDebuff)) then
    if Press(S.SpearofBastion, not Target:IsSpellInRange(S.SpearofBastion)) then return "spear_of_bastion hac 76"; end
  end
  -- bladestorm,if=talent.unhinged&(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)
  if CDsON() and S.Bladestorm:IsCastable() and S.Unhinged:IsAvailable() and (Player:BuffUp(S.TestofMightBuff) or not S.TestofMight:IsAvailable() and Target:DebuffUp(S.ColossusSmashDebuff)) then
    if Press(S.Bladestorm, not TargetInMeleeRange) then return "bladestorm hac 77"; end
  end
  -- bladestorm,if=active_enemies>1&(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)&raid_event.adds.in>30|active_enemies>1&dot.deep_wounds.remains
  if CDsON() and S.Bladestorm:IsCastable() and (EnemiesCount8y > 1 and (Player:BuffUp(S.TestofMightBuff) or not S.TestofMight:IsAvailable() and Target:DebuffUp(S.ColossusSmashDebuff)) or EnemiesCount8y > 1 and Target:DebuffRemains(S.DeepWoundsDebuff) > 0) then
    if Press(S.Bladestorm, not TargetInMeleeRange) then return "bladestorm hac 78"; end
  end
  -- cleave,if=active_enemies>2|!talent.battlelord&buff.merciless_bonegrinder.up&cooldown.mortal_strike.remains>gcd
  if S.Cleave:IsReady() and (EnemiesCount8y > 2 or not S.Battlelord:IsAvailable() and Player:BuffUp(S.MercilessBonegrinderBuff) and S.MortalStrike:CooldownRemains() > Player:GCD()) then
    if Press(S.Cleave, not TargetInMeleeRange) then return "cleave hac 79"; end
  end
  -- whirlwind,if=active_enemies>2|talent.storm_of_swords&(buff.merciless_bonegrinder.up|buff.hurricane.up)
  if S.Whirlwind:IsReady() and (EnemiesCount8y > 2 or S.StormofSwords:IsAvailable() and (Player:BuffUp(S.MercilessBonegrinderBuff) or Player:BuffUp(S.HurricaneBuff))) then
    if Press(S.Whirlwind, not Target:IsInMeleeRange(8)) then return "whirlwind hac 80"; end
  end
  -- skullsplitter,if=rage<40|talent.tide_of_blood&dot.rend.remains&(buff.sweeping_strikes.up&active_enemies>=2|debuff.colossus_smash.up|buff.test_of_might.up)
  if S.Skullsplitter:IsCastable() and (Player:Rage() < 40 or S.TideofBlood:IsAvailable() and Target:DebuffRemains(S.RendDebuff) > 0 and (Player:BuffUp(S.SweepingStrikes) and EnemiesCount8y > 2 or Target:DebuffUp(S.ColossusSmashDebuff) or Player:BuffUp(S.TestofMightBuff))) then
    if Press(S.Skullsplitter, not Target:IsInMeleeRange(8)) then return "sweeping_strikes execute 81"; end
  end
  -- overpower,if=buff.sweeping_strikes.up&talent.dreadnaught
  if S.Overpower:IsCastable() and Player:BuffUp(S.SweepingStrikes) and S.Dreadnaught:IsAvailable() then
    if Press(S.Overpower, not TargetInMeleeRange) then return "overpower hac 82"; end
  end
  -- mortal_strike,cycle_targets=1,if=debuff.executioners_precision.stack=2|dot.deep_wounds.remains<=gcd|talent.dreadnaught&talent.battlelord&active_enemies<=2
  if S.MortalStrike:IsReady() then
    if Everyone.CastCycle(S.MortalStrike, Enemies8y, EvaluateCycleMortalStrike, not TargetInMeleeRange) then return "mortal_strike hac 83"; end
  end
  -- execute,cycle_targets=1,if=buff.sudden_death.react|active_enemies<=2&(target.health.pct<20|talent.massacre&target.health.pct<35)|buff.sweeping_strikes.up
  if S.Execute:IsReady() and (Player:BuffUp(S.SuddenDeathBuff) or EnemiesCount8y <= 2 and (Target:HealthPercentage() < 20 or S.Massacre:IsAvailable() and Target:HealthPercentage() < 35) or Player:BuffUp(S.SweepingStrikes) ) then
    if Everyone.CastCycle(S.Execute, Enemies8y, EvaluateCycleExecute, not TargetInMeleeRange) then return "execute hac 84"; end
  end
  -- thunderous_roar,if=raid_event.adds.in>15
  if CDsON() and S.ThunderousRoar:IsCastable() then
    if Press(S.ThunderousRoar, not Target:IsInMeleeRange(12)) then return "thunderous_roar hac 85"; end
  end
  -- shockwave,if=active_enemies>2&talent.sonic_boom
  if S.Shockwave:IsCastable() and EnemiesCount8y > 2 and (S.SonicBoom:IsAvailable()) then
    if Press(S.Shockwave, not Target:IsInMeleeRange(10)) then return "shockwave hac 86"; end
  end
  -- overpower,if=active_enemies=1&(charges=2&!talent.battlelord&(debuff.colossus_smash.down|rage.pct<25)|talent.battlelord)
  if S.Overpower:IsCastable() and EnemiesCount8y == 1 and (S.Overpower:Charges() == 2 and not S.Battlelord:IsAvailable() and (Target:Debuffdown(S.ColossusSmashDebuff) or Player:RagePercentage() < 25) or S.Battlelord:IsAvailable()) then
    if Press(S.Overpower, not TargetInMeleeRange) then return "overpower hac 87"; end
  end
  -- slam,if=active_enemies=1&!talent.battlelord&rage.pct>70
  if S.Slam:IsReady() and EnemiesCount8y == 1 and not S.Battlelord:IsAvailable() and Player:RagePercentage() > 70 then
    if Press(S.Slam, not TargetInMeleeRange) then return "slam hac 88"; end
  end
  -- overpower,if=charges=2&(!talent.test_of_might|talent.test_of_might&debuff.colossus_smash.down|talent.battlelord)|rage<70
  if S.Overpower:IsCastable() and (S.Overpower:Charges() == 2 and (not S.TestofMight:IsAvailable() or S.TestofMight:IsAvailable() and Target:DebuffUp(S.ColossusSmashDebuff) or S.Battlelord:IsAvailable()) or Player:Rage() < 70) then
    if Press(S.Overpower, not TargetInMeleeRange) then return "overpower hac 89"; end
  end
  -- thunder_clap,if=active_enemies>2
  if S.ThunderClap:IsReady() and EnemiesCount8y > 2 then
    if Press(S.ThunderClap, not TargetInMeleeRange) then return "thunder_clap hac 90"; end
  end
  -- mortal_strike
  if S.MortalStrike:IsReady() then
    if Press(S.MortalStrike, not TargetInMeleeRange) then return "mortal_strike hac 91"; end
  end
  -- rend,if=active_enemies=1&dot.rend.remains<duration*0.3
  if S.Rend:IsReady() and EnemiesCount8y == 1 and Target:DebuffRefreshable(S.RendDebuff) then
    if Press(S.Rend, not TargetInMeleeRange) then return "rend hac 92"; end
  end
  -- whirlwind,if=talent.storm_of_swords|talent.fervor_of_battle&active_enemies>1
  if S.Whirlwind:IsReady() and (S.StormofSwords:IsAvailable() or (S.FervorofBattle:IsAvailable() and EnemiesCount8y > 1)) then
    if Press(S.Whirlwind, not Target:IsInMeleeRange(8)) then return "whirlwind hac 93"; end
  end
  -- cleave,if=!talent.crushing_force
  if S.Cleave:IsReady() and not S.CrushingForce:IsAvailable() then
    if Press(S.Cleave, not TargetInMeleeRange) then return "cleave hac 94"; end
  end
  -- ignore_pain,if=talent.battlelord&talent.anger_management&rage>30&(target.health.pct>20|talent.massacre&target.health.pct>35)
  if S.IgnorePain:IsReady() and (S.Battlelord:IsAvailable() and S.AngerManagement:IsAvailable() and Player:Rage() > 30 and (Target:HealthPercentage() < 20 or S.Massacre:IsAvailable() and Target:HealthPercentage() < 35)) then
    if Press(S.IgnorePain, not TargetInMeleeRange) then return "ignore_pain hac 95"; end
  end
  -- slam,if=talent.crushing_force&rage>30&(talent.fervor_of_battle&active_enemies=1|!talent.fervor_of_battle)
  if S.Slam:IsReady() and S.CrushingForce:IsAvailable() and Player:Rage() > 30 and (S.FervorofBattle:IsAvailable() and EnemiesCount8y == 1 or not S.FervorofBattle:IsAvailable()) then
    if Press(S.Slam, not TargetInMeleeRange) then return "slam hac 96"; end
  end
  -- shockwave,if=talent.sonic_boom
  if S.Shockwave:IsCastable() and (S.SonicBoom:IsAvailable()) then
    if Press(S.Shockwave, not Target:IsInMeleeRange(10)) then return "shockwave hac 97"; end
  end
  -- bladestorm,if=raid_event.adds.in>30
  if CDsON() and S.Bladestorm:IsCastable() then
    if Press(S.Bladestorm, not TargetInMeleeRange) then return "bladestorm hac 98"; end
  end
  -- wrecking_throw
  if S.WreckingThrow:IsCastable() and Target:AffectingCombat() then
    if Press(S.WreckingThrow, not Target:IsInRange(30)) then return "wrecking_throw hac 99"; end
  end
end

local function Execute()
  -- sweeping_strikes,if=spell_targets.whirlwind>1
  if CDsON() and S.SweepingStrikes:IsCastable() and (EnemiesCount8y > 1) then
    if Press(S.SweepingStrikes, not Target:IsInMeleeRange(8)) then return "sweeping_strikes execute 51"; end
  end
  -- rend,if=remains<=gcd&(!talent.warbreaker&cooldown.colossus_smash.remains<4|talent.warbreaker&cooldown.warbreaker.remains<4)&target.time_to_die>12
  if S.Rend:IsReady() and (Target:DebuffRemains(S.RendDebuff) <= Player:GCD() and ((not S.Warbreaker:IsAvailable()) and S.ColossusSmash:CooldownRemains() < 4 or S.Warbreaker:IsAvailable() and S.Warbreaker:CooldownRemains() < 4) and Target:TimeToDie() > 12) then
    if Press(S.Rend, not TargetInMeleeRange) then return "rend execute 52"; end
  end
  -- avatar,if=cooldown.colossus_smash.ready|debuff.colossus_smash.up|target.time_to_die<20
  if CDsON() and S.Avatar:IsCastable() and (S.ColossusSmash:CooldownUp() or Target:DebuffUp(S.ColossusSmashDebuff) or HL.FightRemains() < 20) then
    if Press(S.Avatar) then return "avatar execute 53"; end
  end
  -- warbreaker
  if CDsON() and S.Warbreaker:IsCastable() then
    if Press(S.Warbreaker, not TargetInMeleeRange) then return "warbreaker execute 54"; end
  end
  -- colossus_smash
  if CDsON() and S.ColossusSmash:IsCastable() then
    if Press(S.ColossusSmash, not TargetInMeleeRange) then return "colossus_smash execute 55"; end
  end
  -- thunderous_roar,if=buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up
  if CDsON() and S.ThunderousRoar:IsCastable() and (Player:BuffUp(S.TestofMightBuff) or (not S.TestofMight:IsAvailable()) and Target:DebuffUp(S.ColossusSmashDebuff)) then
    if Press(S.ThunderousRoar, not Target:IsInMeleeRange(12)) then return "thunderous_roar execute 56"; end
  end
  -- spear_of_bastion,if=debuff.colossus_smash.up|buff.test_of_might.up
  if CDsON() and S.SpearofBastion:IsCastable() and (Target:DebuffUp(S.ColossusSmashDebuff) or Player:BuffUp(S.TestofMightBuff) ) then
    if Press(S.SpearofBastion, not Target:IsSpellInRange(S.SpearofBastion)) then return "spear_of_bastion execute 57"; end
  end
  -- skullsplitter,if=rage<40
  if S.Skullsplitter:IsCastable() and Player:Rage() < 40 then
    if Press(S.Skullsplitter, not Target:IsInMeleeRange(8)) then return "sweeping_strikes execute 58"; end
  end
  -- cleave,if=spell_targets.whirlwind>2&dot.deep_wounds.remains<gcd
  if S.Cleave:IsReady() and (EnemiesCount8y > 2 and Target:DebuffRemains(S.DeepWoundsDebuff) < Player:GCD()) then
    if Press(S.Cleave, not TargetInMeleeRange) then return "cleave execute 59"; end
  end
  -- overpower,if=rage<40&buff.martial_prowess.stack<2
  if S.Overpower:IsCastable() and Player:Rage() < 40 and Player:BuffStack(S.MartialProwessBuff) < 2 then
    if Press(S.Overpower, not TargetInMeleeRange) then return "overpower execute 60"; end
  end
  -- mortal_strike,if=debuff.executioners_precision.stack=2|dot.deep_wounds.remains<=gcd
  if S.MortalStrike:IsReady() and (Target:DebuffStack(S.ExecutionersPrecisionDebuff) == 2 or Target:DebuffRemains(S.DeepWoundsDebuff) <= Player:GCD()) then
    if Press(S.MortalStrike, not TargetInMeleeRange) then return "mortal_strike execute 61"; end
  end
  -- execute
  if S.Execute:IsReady() then
    if Press(S.Execute, not TargetInMeleeRange) then return "execute execute 62"; end
  end
  -- shockwave,if=talent.sonic_boom
  if S.Shockwave:IsCastable() and (S.SonicBoom:IsAvailable()) then
    if Press(S.Shockwave, not Target:IsInMeleeRange(10)) then return "shockwave execute 63"; end
  end
  -- overpower
  if S.Overpower:IsCastable() then
    if Press(S.Overpower, not TargetInMeleeRange) then return "overpower execute 64"; end
  end
  -- bladestorm
  if CDsON() and S.Bladestorm:IsCastable() then
    if Press(S.Bladestorm, not TargetInMeleeRange) then return "bladestorm execute 65"; end
  end
end

local function SingleTarget()
  -- sweeping_strikes,if=spell_targets.whirlwind>1
  if CDsON() and S.SweepingStrikes:IsCastable() and (EnemiesCount8y > 1) then
    if Press(S.SweepingStrikes, not Target:IsInMeleeRange(8)) then return "sweeping_strikes single_target 98"; end
  end
  -- mortal_strike
  if S.MortalStrike:IsReady() then
    if Press(S.MortalStrike, not TargetInMeleeRange) then return "mortal_strike single_target 99"; end
  end
  -- rend,if=remains<=gcd|talent.tide_of_blood&cooldown.skullsplitter.remains<=gcd&(cooldown.colossus_smash.remains<=gcd|debuff.colossus_smash.up)&dot.rend.remains<dot.rend.duration*0.85
  if S.Rend:IsReady() and (Target:DebuffRemains(S.RendDebuff) <= Player:GCD() or S.TideofBlood:IsAvailable() and S.Skullsplitter:CooldownRemains() <= Player:GCD() and (S.ColossusSmash:CooldownRemains() <= Player:GCD() or Target:DebuffUp(S.ColossusSmashDebuff)) and Target:DebuffRemains(S.RendDebuff) < S.RendDebuff:BaseDuration() * 0.85) then
    if Press(S.Rend, not TargetInMeleeRange) then return "rend single_target 100"; end
  end
  -- avatar,if=talent.warlords_torment&rage.pct<33&(cooldown.colossus_smash.ready|debuff.colossus_smash.up|buff.test_of_might.up)|!talent.warlords_torment&(cooldown.colossus_smash.ready|debuff.colossus_smash.up)
  if CDsON() and S.Avatar:IsCastable() and ((S.WarlordsTorment:IsAvailable() and Player:RagePercentage() < 33 and (S.ColossusSmash:CooldownUp() or Target:DebuffUp(S.ColossusSmashDebuff) or Player:BuffUp(S.TestofMightBuff))) or (not S.WarlordsTorment:IsAvailable() and (S.ColossusSmash:CooldownUp() or Target:DebuffUp(S.ColossusSmashDebuff)))) then
    if Press(S.Avatar) then return "avatar single_target 101"; end
  end
  -- spear_of_bastion,if=cooldown.colossus_smash.remains<=gcd|cooldown.warbreaker.remains<=gcd
  if CDsON() and S.SpearofBastion:IsCastable() and (S.ColossusSmash:CooldownRemains() <= Player:GCD() or S.Warbreaker:CooldownRemains() <= Player:GCD() ) then
    if Press(S.SpearofBastion, not Target:IsSpellInRange(S.SpearofBastion)) then return "spear_of_bastion single_target 102"; end
  end
  -- warbreaker
  if CDsON() and S.Warbreaker:IsCastable() then
    if Press(S.Warbreaker, not Target:IsInRange(8)) then return "warbreaker single_target 103"; end
  end
  -- colossus_smash
  if CDsON() and S.ColossusSmash:IsCastable() then
    if Press(S.ColossusSmash,not TargetInMeleeRange) then return "colossus_smash single_target 104"; end
  end
  -- thunderous_roar,if=buff.test_of_might.up|talent.test_of_might&debuff.colossus_smash.up&rage.pct<33|!talent.test_of_might&debuff.colossus_smash.up
  if CDsON() and S.ThunderousRoar:IsCastable() and (Player:BuffUp(S.TestofMightBuff) or (S.TestofMight:IsAvailable() and Target:DebuffUp(S.ColossusSmashDebuff) and Player:RagePercentage() < 33) or (not S.TestofMight:IsAvailable() and Target:DebuffUp(S.ColossusSmashDebuff))) then
    if Press(S.ThunderousRoar, not Target:IsInMeleeRange(12)) then return "thunderous_roar single_target 105"; end
  end
  -- bladestorm,if=talent.hurricane&(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)|talent.unhinged&(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)
  if CDsON() and S.Bladestorm:IsCastable() and (S.Hurricane:IsAvailable() and (Player:BuffUp(S.TestofMightBuff) or (not S.TestofMight:IsAvailable() and Target:DebuffUp(S.ColossusSmashDebuff))) or S.Unhinged:IsAvailable() and (Player:BuffUp(S.TestofMightBuff) or (not S.TestofMight:IsAvailable() and Target:DebuffUp(S.ColossusSmashDebuff)))) then
    if Press(S.Bladestorm, not TargetInMeleeRange) then return "bladestorm single_target 106"; end
  end
  -- skullsplitter,if=talent.tide_of_blood&dot.rend.remains&(debuff.colossus_smash.up|cooldown.colossus_smash.remains>gcd*4&buff.test_of_might.up|!talent.test_of_might&cooldown.colossus_smash.remains>gcd*4)|rage<30
  if S.Skullsplitter:IsCastable() and (S.TideofBlood:IsAvailable() and Target:DebuffUp(S.RendDebuff) and (Target:DebuffUp(S.ColossusSmashDebuff) or (S.ColossusSmash:CooldownRemains() > Player:GCD() * 4 and Player:BuffUp(S.TestofMightBuff)) or (not S.TestofMight:IsAvailable() and S.ColossusSmash:CooldownRemains() > Player:GCD() * 4)) or Player:Rage() < 30) then
    if Press(S.Skullsplitter, not TargetInMeleeRange) then return "skullsplitter single_target 107"; end
  end
  -- execute,if=buff.sudden_death.react
  if S.Execute:IsReady() and (Player:BuffUp(S.SuddenDeathBuff)) then
    if Press(S.Execute, not TargetInMeleeRange) then return "execute single_target 108"; end
  end
  -- shockwave,if=talent.sonic_boom.enabled
  if S.Shockwave:IsCastable() and (S.SonicBoom:IsAvailable()) then
    if Press(S.Shockwave, not Target:IsInMeleeRange(10)) then return "shockwave single_target 109"; end
  end
  -- ignore_pain,if=talent.anger_management|talent.test_of_might&debuff.colossus_smash.up
  if S.IgnorePain:IsReady() and (S.AngerManagement:IsAvailable() or S.TestofMight:IsAvailable() and Target:DebuffUp(S.ColossusSmashDebuff)) then
    if Press(S.IgnorePain, not TargetInMeleeRange) then return "ignore_pain single_target 110"; end
  end
  -- whirlwind,if=talent.storm_of_swords&talent.battlelord&rage.pct>80&debuff.colossus_smash.up
  if S.Whirlwind:IsReady() and (S.StormofSwords:IsAvailable() and S.Battlelord:IsAvailable() and Player:RagePercentage() > 80 and Target:DebuffUp(S.ColossusSmashDebuff)) then
    if Press(S.Whirlwind, not Target:IsInMeleeRange(8)) then return "whirlwind single_target 113"; end
  end
  -- overpower,if=charges=2&!talent.battlelord&(debuff.colossus_smash.down|rage.pct<25)|talent.battlelord
  if S.Overpower:IsCastable() and (S.Overpower:Charges() == 2 and not S.Battlelord:IsAvailable() and (Target:DebuffUp(S.ColossusSmashDebuff) or Player:RagePercentage() < 25) or S.Battlelord:IsAvailable()) then
    if Press(S.Overpower, not TargetInMeleeRange) then return "overpower single_target 114"; end
  end
  -- whirlwind,if=talent.storm_of_swords|talent.fervor_of_battle&active_enemies>1
  if S.Whirlwind:IsReady() and (S.StormofSwords:IsAvailable() or (S.FervorofBattle:IsAvailable() and EnemiesCount8y > 1)) then
    if Press(S.Whirlwind, not Target:IsInMeleeRange(8)) then return "whirlwind single_target 113"; end
  end
  -- thunder_clap,if=talent.battlelord&talent.blood_and_thunder
  if S.ThunderClap:IsReady() and S.Battlelord:IsAvailable() and S.BloodandThunder:IsAvailable() then
    if Press(S.ThunderClap, not TargetInMeleeRange) then return "thunder_clap single_target 90"; end
  end
  -- overpower,if=debuff.colossus_smash.down&rage.pct<50&!talent.battlelord|rage.pct<25
  if S.Overpower:IsCastable() and (Target:DebuffDown(S.ColossusSmashDebuff) and Player:RagePercentage() < 50 and not S.Battlelord:IsAvailable() or Player:RagePercentage() < 25) then
    if Press(S.Overpower, not TargetInMeleeRange) then return "overpower single_target 114"; end
  end
  -- whirlwind,if=buff.merciless_bonegrinder.up
  if S.Whirlwind:IsReady() and Player:BuffUp(S.MercilessBonegrinderBuff) then
    if Press(S.Whirlwind, not Target:IsInRange(8)) then return "whirlwind single_target 115"; end
  end
  -- cleave,if=set_bonus.tier29_2pc&!talent.crushing_force
  if S.Cleave:IsReady() and Player:HasTier(29, 2) and not S.CrushingForce:IsAvailable() then
    if Press(S.Cleave, not TargetInMeleeRange) then return "cleave single_target 116"; end
  end
  -- slam,if=rage>30&(!talent.fervor_of_battle|talent.fervor_of_battle&active_enemies=1)
  if S.Slam:IsReady() and Player:Rage() > 30 and (not S.FervorofBattle:IsAvailable() or S.FervorofBattle:IsAvailable() and EnemiesCount8y == 1) then
    if Press(S.Slam, not TargetInMeleeRange) then return "slam single_target 117"; end
  end
  -- bladestorm
  if CDsON() and S.Bladestorm:IsCastable() then
    if Press(S.Bladestorm, not TargetInMeleeRange) then return "bladestorm single_target 106"; end
  end
  -- cleave
  if S.Cleave:IsReady() then
    if Press(S.Cleave, not TargetInMeleeRange) then return "cleave single_target 116"; end
  end
  -- wrecking_throw
  if S.WreckingThrow:IsCastable() and Target:AffectingCombat() then
    if Press(S.WreckingThrow, not Target:IsInRange(30)) then return "wrecking_throw single_target 118"; end
  end
  -- rend,if=remains<duration*0.3
  if S.Rend:IsReady() and Target:DebuffRefreshable(S.RendDebuff) then
    if Press(S.Rend, not TargetInMeleeRange) then return "rend single_target 100"; end
  end
end

--- ======= ACTION LISTS =======
local function APL()
  if AoEON() then
    Enemies8y = Player:GetEnemiesInMeleeRange(8) -- Multiple Abilities
    EnemiesCount8y = #Enemies8y
  else
    EnemiesCount8y = 1
  end

  -- Range check
  TargetInMeleeRange = Target:IsInMeleeRange(5)
  
  -- Manually added: Group buff check
  if not Player:AffectingCombat() and S.BattleShout:IsCastable() and (Player:BuffDown(S.BattleShoutBuff, true) or Everyone.GroupBuffMissing(S.BattleShoutBuff)) then
    if Press(S.BattleShout) then return "battle_shout"; end
  end

  if Everyone.TargetIsValid() then
    -- call Precombat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- Interrupts
    local ShouldReturn = Everyone.Interrupt(S.Pummel, 5, true); if ShouldReturn then return ShouldReturn; end
    ShouldReturn = Everyone.InterruptWithStun(S.StormBolt, 8); if ShouldReturn then return ShouldReturn; end
    -- charge
    if Settings.Commons.Enabled.Charge and S.Charge:IsCastable() and (not TargetInMeleeRange) then
      if Press(S.Charge, not Target:IsSpellInRange(S.Charge)) then return "charge main 34"; end
    end
    -- Manually added: VR/IV
    if Player:HealthPercentage() < Settings.Commons.HP.VictoryRush then
      if S.VictoryRush:IsReady() then
        if Press(S.VictoryRush, not TargetInMeleeRange) then return "victory_rush heal"; end
      end
      if S.ImpendingVictory:IsReady() then
        if Press(S.ImpendingVictory, not TargetInMeleeRange) then return "impending_victory heal"; end
      end
    end
    -- healthstone
    if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
      if Press(M.Healthstone, nil, nil, true) then return "healthstone"; end
    end
    -- auto_attack
    -- potion,if=gcd.remains=0&debuff.colossus_smash.remains>8|target.time_to_die<25
    -- use_item,name=manic_grieftorch,if=!buff.avatar.up&!debuff.colossus_smash.up
    if Settings.General.Enabled.Trinkets and CDsON() then
      if I.ManicGrieftorch:IsEquippedAndReady() and not Player:BuffUp(S.Avatar) and not Target:DebuffRemains(S.ColossusSmashDebuff) then
        if Press(I.ManicGrieftorch) then return "manic_grieftorch main 38"; end
      end
    end
    if CDsON() then
      -- blood_fury,if=debuff.colossus_smash.up
      if S.BloodFury:IsCastable() and Target:DebuffUp(S.ColossusSmashDebuff) then
        if Press(S.BloodFury) then return "blood_fury main 39"; end
      end
      -- berserking,if=debuff.colossus_smash.remains>6
      if S.Berserking:IsCastable() and Target:DebuffRemains(S.ColossusSmashDebuff) > 6 then
        if Press(S.Berserking) then return "berserking main 40"; end
      end
      -- arcane_torrent,if=cooldown.mortal_strike.remains>1.5&rage<50
      if S.ArcaneTorrent:IsCastable() and S.MortalStrike:CooldownRemains() > 1.5 and Player:Rage() < 50 then
        if Press(S.ArcaneTorrent, not Target:IsInRange(8)) then return "arcane_torrent main 41"; end
      end
      -- lights_judgment,if=debuff.colossus_smash.down&cooldown.mortal_strike.remains
      if S.LightsJudgment:IsCastable() and Target:DebuffDown(S.ColossusSmashDebuff) and not S.MortalStrike:CooldownUp() then
        if Press(S.LightsJudgment, not Target:IsSpellInRange(S.LightsJudgment)) then return "lights_judgment main 42"; end
      end
      -- fireblood,if=debuff.colossus_smash.up
      if S.Fireblood:IsCastable() and (Target:DebuffUp(S.ColossusSmashDebuff)) then
        if Press(S.Fireblood) then return "fireblood main 43"; end
      end
      -- ancestral_call,if=debuff.colossus_smash.up
      if S.AncestralCall:IsCastable() and (Target:DebuffUp(S.ColossusSmashDebuff)) then
        if Press(S.AncestralCall) then return "ancestral_call main 44"; end
      end
      -- bag_of_tricks,if=debuff.colossus_smash.down&cooldown.mortal_strike.remains
      if S.BagofTricks:IsCastable() and (Target:DebuffDown(S.ColossusSmashDebuff) and not S.MortalStrike:CooldownUp()) then
        if Press(S.BagofTricks, not Target:IsSpellInRange(S.BagofTricks)) then return "bag_of_tricks main 10"; end
      end
      -- use_item,name=manic_grieftorch
      if Settings.General.Enabled.Trinkets and CDsON() then
        if I.ManicGrieftorch:IsEquippedAndReady() then
          if Press(I.ManicGrieftorch) then return "manic_grieftorch main 46"; end
        end
      end
    end
    if CDsON() and (Settings.General.Enabled.Trinkets) and Target:IsInMeleeRange(8) then
      -- use_item,slot=trinket1
      local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
      if Trinket1ToUse then
        if Press(M.Trinket1, nil, nil, true) then return "trinket1 main"; end
      end
      -- use_item,slot=trinket2
      local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
      if Trinket2ToUse then
        if Press(M.Trinket2, nil, nil, true) then return "trinket2 main"; end
      end
    end
    -- run_action_list,name=hac,if=raid_event.adds.exists|active_enemies>2
    if AoEON() and EnemiesCount8y > 2 then
      local ShouldReturn = Hac(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=execute,target_if=min:target.health.pct,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
    if (S.Massacre:IsAvailable() and Target:HealthPercentage() < 35) or Target:HealthPercentage() < 20 then
      local ShouldReturn = Execute(); if ShouldReturn then return ShouldReturn; end
    end
    -- run_action_list,name=single_target,if=!raid_event.adds.exists
    local ShouldReturn = SingleTarget(); if ShouldReturn then return ShouldReturn; end
    -- Pool if nothing else to suggest
    if WR.CastAnnotated(S.Pool, false, "WAIT") then return "Wait/Pool Resources"; end
  end
end

local function AutoBind()
  -- Spell Binds
  Bind(S.Avatar)
  Bind(S.AncestralCall)
  Bind(S.ArcaneTorrent)
  Bind(S.BagofTricks)
  Bind(S.BattleShout)
  Bind(S.Berserking)
  Bind(S.Bladestorm)
  Bind(S.Charge)
  Bind(S.Cleave)
  Bind(S.Execute)
  Bind(S.Fireblood)
  Bind(S.LightsJudgment)
  Bind(S.MortalStrike)
  Bind(S.Rend)
  Bind(S.Slam)
  Bind(S.Shockwave)
  Bind(S.Skullsplitter)
  Bind(S.SpearofBastion)
  Bind(S.ThunderClap)
  Bind(S.ThunderousRoar)
  
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  Bind(I.ManicGrieftorch)
  
  -- Macros
  Bind(M.SpearofBastionPlayer)
end

local function Init()
  WR.Print("Arms Warrior by Worldy.")
  AutoBind()
end

WR.SetAPL(71, APL, Init)
