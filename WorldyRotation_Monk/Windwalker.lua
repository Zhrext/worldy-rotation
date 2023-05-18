-- TODOs --
-- ChiWave for healing
-- Dampen Harm list of spells to mitigate
-- Diffuse Damage list of spells to mitigate and spellreflect
-- Expel Harm, heal and dps
-- Forifying Brew, list of things to mitigate
-- Leg Sweep, list of things to stun and AoE interrupts
-- Paralysis, list of things to interrupt/stun
-- Provoke, take some debuffs of MT if necessary
-- Mouseover unit, interrupt, stun, debuff, etc
-- Healing, Soothing mist, Vivify
-- List of spells to interrupt/stun
-- White Tiger macro at player and cursor and target?
-- Attacking different targets for buffing Spinning Crane, its only Blackout kick that can be used since the other is longer CD?
-- Touch of Death optimisation, ie aoe.
-- Zen Flight, is there any scenarios where we can use it?
-- Flying Serpent kick, press twice for AoE?
-- Mighty Ox Kick, pvp push back talent
-- Cooldowns, Strike of the windlord for example, 40 sec CD means once per pull, should have TTD
-- Cooldowns, SEF, 2 charges 1.5 min rechargeonce per pull, 15 secs uptime on adds
-- PvP logic, for example use Para if fighting more then 1 enemy
-- Touch of Karma, absorbs 50% of hp for 10 seconds and reflect 70% as nature damage.
-- Potion usage, get an error so add it in later
-- Interrupt and Stuns

-- ----- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC        = HeroDBC.DBC
-- HeroLib
local HL         = HeroLib
local Cache      = HeroCache
local Unit       = HL.Unit
local Player     = Unit.Player
local Target     = Unit.Target
local Pet        = Unit.Pet
local Spell      = HL.Spell
local MultiSpell = HL.MultiSpell
local Item       = HL.Item
-- WorldyRotation
local WR         = WorldyRotation
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Cast       = WR.Cast
local Macro      = WR.Macro
-- Lua
local pairs      = pairs


--- ============================ CONTENT ============================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.Monk.Windwalker
local I = Item.Monk.Windwalker
local M = Macro.Monk.Windwalker

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  -- I.TrinketName:ID(),
}

-- Rotation Var
local Enemies5y
local Enemies8y
local EnemiesCount8y
local BossFightRemains = 11111
local FightRemains = 11111
local XuenActive
local VarXuenOnUse = false
local VarHoldXuen = false
local VarHoldSEF = false
local VarSerenityBurst = false
local VarBoKNeeded = false

local VarHoldTod = false
local VarFoPPreChan = 0

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Monk = WR.Commons.Monk
local Settings = {
  General    = WR.GUISettings.General,
  Commons    = WR.GUISettings.APL.Monk.Commons,
  Windwalker = WR.GUISettings.APL.Monk.Windwalker
}

HL:RegisterForEvent(function()
  VarFoPPreChan = 0
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

local function EnergyTimeToMaxRounded()
  -- Round to the nearesth 10th to reduce prediction instability on very high regen rates
  return math.floor(Player:EnergyTimeToMaxPredicted() * 10 + 0.5) / 10
end

local function EnergyPredictedRounded()
  -- Round to the nearesth int to reduce prediction instability on very high regen rates
  return math.floor(Player:EnergyPredicted() + 0.5)
end

local function ComboStrike(SpellObject)
  return (not Player:PrevGCD(1, SpellObject))
end

local function MotCCounter()
  if not S.MarkoftheCrane:IsAvailable() then return 0; end
  local Count = 0
  for _, CycleUnit in pairs(Enemies8y) do
    if CycleUnit:DebuffUp(S.MarkoftheCraneDebuff) then
      Count = Count + 1
    end
  end
  return Count
end

local function SCKModifier()
  if not S.MarkoftheCrane:IsAvailable() then return 0; end
  local Count = MotCCounter()
  local Mod = 1
  if Count > 0 then
    Mod = Mod * (1 + (Count * 0.18))
  end
  Mod = Mod * (1 + (0.1 * S.CraneVortex:TalentRank()))
  Mod = Mod * (1 + (0.3 * num(Player:BuffUp(S.KicksofFlowingMomentumBuff))))
  Mod = Mod * (1 + (0.05 * S.FastFeet:TalentRank()))
  return Mod
end

local function SCKMax()
  if not S.MarkoftheCrane:IsAvailable() then return true; end
  local Count = MotCCounter()
  if (EnemiesCount8y == Count or Count >= 3) then return true; end
  return false
end

local function EvaluateTargetIfFilterMarkoftheCrane100(TargetUnit)
  return TargetUnit:DebuffRemains(S.MarkoftheCraneDebuff)
end

local function EvaluateTargetIfFilterMarkoftheCrane101(TargetUnit)
  return TargetUnit:DebuffRemains(S.MarkoftheCraneDebuff) + (num(TargetUnit:DebuffUp(S.SkyreachExhaustionDebuff)) * 20)
end

local function UseItems()
  -- use_items
  local Trinket1ToUse = Player:GetUseableItems(OnUseExcludes, 13)
  if Trinket1ToUse then
    if Press(M.Trinket1, nil, nil, true) then return "trinket1 trinket 2"; end
  end
  local Trinket2ToUse = Player:GetUseableItems(OnUseExcludes, 14)
  if Trinket2ToUse then
    if Press(M.Trinket2, nil, nil, true) then return "trinket2 trinket 4"; end
  end
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  -- variable,name=xuen_on_use_trinket,op=set,value=equipped.inscrutable_quantum_device|equipped.gladiators_badge|equipped.wrathstone|equipped.overcharged_anima_battery|equipped.shadowgrasp_totem|equipped.the_first_sigil|equipped.cache_of_acquired_treasures
  -- Note: All referenced trinkets are from SL, so ignoring this for simplicity.
  -- summon_white_tiger_statue
  if S.SummonWhiteTigerStatue:IsCastable() and CDsON() then
    if Cast(M.SummonWhiteTigerStatueM, Settings.Commons.GCDasOffGCD.SummonWhiteTigerStatue, nil, not Target:IsInRange(40)) then return "summon_white_tiger_statue precombat 2"; end
  end
  -- expel_harm,if=chi<chi.max
  if S.ExpelHarm:IsReady() and (Player:Chi() < Player:ChiMax()) then
    if Cast(S.ExpelHarm, nil, nil, not Target:IsInMeleeRange(8)) then return "expel_harm precombat 4"; end
  end
  -- chi_burst,if=!talent.faeline_stomp
  if S.ChiBurst:IsReady() and (not S.FaelineStomp:IsAvailable()) then
    if Cast(S.ChiBurst, nil, nil, not Target:IsInRange(40)) then return "chi_burst precombat 6"; end
  end
  -- chi_wave
  if S.ChiWave:IsReady() then
    if Cast(S.ChiWave, nil, nil, not Target:IsInRange(40)) then return "chi_wave precombat 8"; end
  end
end

local function Opener()
  -- expel_harm,if=talent.chi_burst.enabled&chi.max-chi>=3
  if S.ExpelHarm:IsReady() and (S.ChiBurst:IsAvailable() and Player:ChiDeficit() >= 3) then
    if Cast(S.ExpelHarm, nil, nil, not Target:IsInMeleeRange(8)) then return "expel_harm opener 2"; end
  end
  -- target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=combo_strike&chi.max-chi>=(2+buff.power_strikes.up)
  if S.TigerPalm:IsReady() and (ComboStrike(S.TigerPalm) and Player:ChiDeficit() >= (2 + num(Player:BuffUp(S.PowerStrikesBuff)))) then
    if Everyone.CastTargetIf(S.TigerPalm, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane101, nil, not Target:IsInMeleeRange(5)) then return "tiger_palm opener 4"; end
  end
  -- chi_wave,if=chi.max-chi=2
  if S.ChiWave:IsReady() and (Player:ChiDeficit() >= 2) then
    if Cast(S.ChiWave, nil, nil, not Target:IsInRange(40)) then return "chi_wave opener 6"; end
  end
  -- expel_harm
  if S.ExpelHarm:IsReady() then
    if Cast(S.ExpelHarm, nil, nil, not Target:IsInMeleeRange(8)) then return "expel_harm opener 10"; end
  end
  -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=chi.max-chi>=(2+buff.power_strikes.up)
  if S.TigerPalm:IsReady() and (Player:ChiDeficit() >= (2 + num(Player:BuffUp(S.PowerStrikesBuff)))) then
    if Everyone.CastTargetIf(S.TigerPalm, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane101, nil, not Target:IsInMeleeRange(5)) then return "tiger_palm opener 12"; end
  end
end

local function BDBSetup()
  -- bonedust_brew,if=spinning_crane_kick.max&chi>=4
  if S.BonedustBrew:IsCastable() and (SCKMax() and Player:Chi() >= 4) then
    if Cast(M.BonedustBrewM, nil, Settings.Commons.DisplayStyle.Signature, not Target:IsInRange(40)) then return "bonedust_brew bdb_setup 2"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&!talent.whirling_dragon_punch
  if S.BlackoutKick:IsReady() and (ComboStrike(S.BlackoutKick) and not S.WhirlingDragonPunch:IsAvailable()) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick bdb_setup 4"; end
  end
  -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&chi>=5
  if S.RisingSunKick:IsReady() and (ComboStrike(S.RisingSunKick) and Player:Chi() >= 5) then
    if Everyone.CastTargetIf(S.RisingSunKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "rising_sun_kick bdb_setup 6"; end
  end
  -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=combo_strike&chi.max-chi>=2
  if S.TigerPalm:IsReady() and (ComboStrike(S.TigerPalm) and Player:ChiDeficit() >= 2) then
    if Everyone.CastTargetIf(S.TigerPalm, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane101, nil, not Target:IsInMeleeRange(5)) then return "tiger_palm bdb_setup 8"; end
  end
  -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&active_enemies>=2
  if S.RisingSunKick:IsReady() and (ComboStrike(S.RisingSunKick) and EnemiesCount8y >= 2) then
    if Everyone.CastTargetIf(S.RisingSunKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "rising_sun_kick bdb_setup 10"; end
  end
end

local function CDSerenity()
  -- summon_white_tiger_statue,if=pet.xuen_the_white_tiger.active
  if S.SummonWhiteTigerStatue:IsCastable() and (XuenActive) then
    if Cast(M.SummonWhiteTigerStatueM, Settings.Commons.GCDasOffGCD.SummonWhiteTigerStatue, nil, not Target:IsInRange(40)) then return "summon_white_tiger_statue cd_serenity 2"; end
  end
  -- invoke_xuen_the_white_tiger,if=!variable.hold_xuen&talent.bonedust_brew&cooldown.bonedust_brew.remains<=5|fight_remains<25
  if S.InvokeXuenTheWhiteTiger:IsCastable() and ((not VarHoldXuen) and S.BonedustBrew:IsAvailable() and S.BonedustBrew:CooldownRemains() <= 5 or FightRemains < 25) then
    if Cast(S.InvokeXuenTheWhiteTiger, Settings.Windwalker.GCDasOffGCD.InvokeXuenTheWhiteTiger, nil, not Target:IsInRange(40)) then return "invoke_xuen_the_white_tiger cd_serenity 4"; end
  end
  -- invoke_xuen_the_white_tiger,if=!variable.hold_xuen&!talent.bonedust_brew&(cooldown.rising_sun_kick.remains<2)|fight_remains<25
  if S.InvokeXuenTheWhiteTiger:IsCastable() and ((not VarHoldXuen) and (not S.BonedustBrew:IsAvailable()) and S.RisingSunKick:CooldownRemains() < 2 or FightRemains < 25) then
    if Cast(S.InvokeXuenTheWhiteTiger, Settings.Windwalker.GCDasOffGCD.InvokeXuenTheWhiteTiger, nil, not Target:IsInRange(40)) then return "invoke_xuen_the_white_tiger cd_serenity 6"; end
  end
  -- bonedust_brew,if=!buff.bonedust_brew.up&(cooldown.serenity.up|cooldown.serenity.remains>15|fight_remains<30&fight_remains>10)|fight_remains<10
  if S.BonedustBrew:IsCastable() and (Player:BuffDown(S.BonedustBrewBuff) and (S.Serenity:CooldownUp() or S.Serenity:CooldownRemains() > 15 or FightRemains < 30 and FightRemains > 10) or FightRemains < 10) then
    if Cast(M.BonedustBrewM, nil, Settings.Commons.DisplayStyle.Signature, not Target:IsInRange(40)) then return "bonedust_brew cd_serenity 8"; end
  end
  -- serenity,if=pet.xuen_the_white_tiger.active|cooldown.invoke_xuen_the_white_tiger.remains>10|!talent.invoke_xuen_the_white_tiger|fight_remains<15
  if S.Serenity:IsCastable() and (XuenActive or S.InvokeXuenTheWhiteTiger:CooldownRemains() > 10 or (not S.InvokeXuenTheWhiteTiger:IsAvailable()) or FightRemains < 15) then
    if Cast(S.Serenity, Settings.Windwalker.OffGCDasOffGCD.Serenity) then return "serenity cd_serenity 10"; end
  end
  -- With Xuen: touch_of_death,if=combo_strike&(fight_remains>60|pet.xuen_the_white_tiger.active&buff.bonedust_brew.up|(cooldown.invoke_xuen_the_white_tiger.remains>fight_remains)&buff.bonedust_brew.up|fight_remains<10)
  -- Without Xuen: touch_of_death,if=combo_strike&target.health=0&(fight_remains>60|buff.bonedust_brew.up|fight_remains<10)
  -- Skipping last line, as target.health=0 would end the fight...
  if S.TouchofDeath:IsReady() and (S.InvokeXuenTheWhiteTiger:IsAvailable() and (ComboStrike(S.TouchofDeath) and (FightRemains > 60 or XuenActive and Player:BuffUp(S.BonedustBrewBuff) or (S.InvokeXuenTheWhiteTiger:CooldownRemains() > FightRemains) and Player:BuffUp(S.BonedustBrewBuff) or FightRemains < 10))) then
    if Cast(S.TouchofDeath, Settings.Windwalker.GCDasOffGCD.TouchOfDeath, nil, not Target:IsInMeleeRange(5)) then return "touch_of_death cd_serenity 12"; end
  end
  -- touch_of_karma,if=fight_remains>90|fight_remains<10
  if (not Settings.Windwalker.IgnoreToK) and S.TouchofKarma:IsCastable() and (FightRemains > 90 or FightRemains < 10) then
    if Cast(S.TouchofKarma, Settings.Windwalker.GCDasOffGCD.TouchOfKarma) then return "touch_of_karma cd_serenity 14"; end
  end
  if (Player:BuffUp(S.SerenityBuff) or FightRemains < 20) then
    -- ancestral_call,if=buff.serenity.up|fight_remains<20
    if S.AncestralCall:IsCastable() then
      if Cast(S.AncestralCall, Settings.Commons.GCDasOffGCD.Racials) then return "ancestral_call cd_serenity 16"; end
    end
    -- blood_fury,if=buff.serenity.up|fight_remains<20
    if S.BloodFury:IsCastable() then
      if Cast(S.BloodFury, Settings.Commons.GCDasOffGCD.Racials) then return "blood_fury cd_serenity 18"; end
    end
    -- fireblood,if=buff.serenity.up|fight_remains<20
    if S.Fireblood:IsCastable() then
      if Cast(S.Fireblood, Settings.Commons.GCDasOffGCD.Racials) then return "fireblood cd_serenity 20"; end
    end
    -- berserking,if=buff.serenity.up|fight_remains<20
    if S.Berserking:IsCastable() then
      if Cast(S.Berserking, Settings.Commons.GCDasOffGCD.Racials) then return "berserking cd_serenity 22"; end
    end
    -- bag_of_tricks,if=buff.serenity.up|fight_remains<20
    if S.BagofTricks:IsCastable() then
      if Cast(S.BagofTricks, Settings.Commons.GCDasOffGCD.Racials) then return "bag_of_tricks cd_serenity 24"; end
    end
  end
  -- lights_judgment
  if S.LightsJudgment:IsCastable() then
    if Cast(S.LightsJudgment, Settings.Commons.GCDasOffGCD.Racials) then return "lights_judgment cd_serenity 26"; end
  end
  -- use_items
  if Settings.Commons.Enabled.Trinkets then
    local ShouldReturn = UseItems(); if ShouldReturn then return ShouldReturn; end
  end
end

local function CDSEF()
  -- summon_white_tiger_statue,if=pet.xuen_the_white_tiger.active
  if S.SummonWhiteTigerStatue:IsCastable() and (XuenActive) then
    if Cast(M.SummonWhiteTigerStatueM, nil, nil, not Target:IsInRange(40)) then return "summon_white_tiger_statue cd_sef 2"; end
  end
  -- invoke_xuen_the_white_tiger,if=!variable.hold_xuen&talent.bonedust_brew&cooldown.bonedust_brew.remains<=5&(active_enemies<3&chi>=3|active_enemies>=3&chi>=2)|fight_remains<25
  if S.InvokeXuenTheWhiteTiger:IsCastable() and ((not VarHoldXuen) and S.BonedustBrew:IsAvailable() and S.BonedustBrew:CooldownRemains() <= 5 and (EnemiesCount8y < 3 and Player:Chi() >= 3 or EnemiesCount8y >= 3 and Player:Chi() >= 2) or FightRemains < 25) then
    if Cast(S.InvokeXuenTheWhiteTiger, Settings.Windwalker.GCDasOffGCD.InvokeXuenTheWhiteTiger, nil, not Target:IsInRange(40)) then return "invoke_xuen_the_white_tiger cd_sef 4"; end
  end
  -- invoke_xuen_the_white_tiger,if=!variable.hold_xuen&!talent.bonedust_brew&(cooldown.rising_sun_kick.remains<2)&chi>=3
  if S.InvokeXuenTheWhiteTiger:IsCastable() and ((not VarHoldXuen) and (not S.BonedustBrew:IsAvailable()) and S.RisingSunKick:CooldownRemains() < 2 and Player:Chi() >= 3) then
    if Cast(S.InvokeXuenTheWhiteTiger, Settings.Windwalker.GCDasOffGCD.InvokeXuenTheWhiteTiger, nil, not Target:IsInRange(40)) then return "invoke_xuen_the_white_tiger cd_sef 6"; end
  end
  -- storm_earth_and_fire,if=talent.bonedust_brew&(fight_remains<30&cooldown.bonedust_brew.remains<4&chi>=4|buff.bonedust_brew.up&!variable.hold_sef|!spinning_crane_kick.max&active_enemies>=3&cooldown.bonedust_brew.remains<=2&chi>=2)&(pet.xuen_the_white_tiger.active|cooldown.invoke_xuen_the_white_tiger.remains>cooldown.storm_earth_and_fire.full_recharge_time)
  if S.StormEarthAndFire:IsCastable() and (S.BonedustBrew:IsAvailable() and (FightRemains < 30 and S.BonedustBrew:CooldownRemains() < 4 and Player:Chi() >= 4 or Player:BuffUp(S.BonedustBrewBuff) and (not VarHoldSEF) or (not SCKMax()) and EnemiesCount8y >= 3 and S.BonedustBrew:CooldownRemains() <= 2 and Player:Chi() >= 2) and (XuenActive or S.InvokeXuenTheWhiteTiger:CooldownRemains() > S.StormEarthAndFire:FullRechargeTime())) then
    if Cast(S.StormEarthAndFire, Settings.Windwalker.OffGCDasOffGCD.StormEarthAndFire) then return "storm_earth_and_fire cd_sef 8"; end
  end
  -- bonedust_brew,if=(!buff.bonedust_brew.up&buff.storm_earth_and_fire.up&buff.storm_earth_and_fire.remains<11&spinning_crane_kick.max)|(!buff.bonedust_brew.up&fight_remains<30&fight_remains>10&spinning_crane_kick.max&chi>=4)|fight_remains<10
  if S.BonedustBrew:IsCastable() and ((Player:BuffDown(S.BonedustBrewBuff) and Player:BuffUp(S.StormEarthAndFireBuff) and Player:BuffRemains(S.StormEarthAndFireBuff) < 11 and SCKMax()) or (Player:BuffDown(S.BonedustBrewBuff) and FightRemains < 30 and FightRemains > 10 and SCKMax() and Player:Chi() >= 4) or FightRemains < 10) then
    if Cast(M.BonedustBrewM, nil, Settings.Commons.DisplayStyle.Signature, not Target:IsInRange(40)) then return "bonedust_brew cd_sef 10"; end
  end
  -- call_action_list,name=bdb_setup,if=!buff.bonedust_brew.up&talent.bonedust_brew&cooldown.bonedust_brew.remains<=2&(fight_remains>60&(cooldown.storm_earth_and_fire.charges>0|cooldown.storm_earth_and_fire.remains>10)&(pet.xuen_the_white_tiger.active|cooldown.invoke_xuen_the_white_tiger.remains>10|variable.hold_xuen)|((pet.xuen_the_white_tiger.active|cooldown.invoke_xuen_the_white_tiger.remains>13)&(cooldown.storm_earth_and_fire.charges>0|cooldown.storm_earth_and_fire.remains>13|buff.storm_earth_and_fire.up)))
  if (Player:BuffDown(S.BonedustBrewBuff) and S.BonedustBrew:IsAvailable() and S.BonedustBrew:CooldownRemains() <= 2 and (FightRemains > 60 and (S.StormEarthAndFire:Charges() > 0 or S.StormEarthAndFire:CooldownRemains() > 10) and (XuenActive or S.InvokeXuenTheWhiteTiger:CooldownRemains() > 10 or VarHoldXuen) or ((XuenActive or S.InvokeXuenTheWhiteTiger:CooldownRemains() > 13) and (S.StormEarthAndFire:Charges() > 0 or S.StormEarthAndFire:CooldownRemains() > 13 or Player:BuffUp(S.StormEarthAndFireBuff))))) then
    local ShouldReturn = BDBSetup(); if ShouldReturn then return ShouldReturn; end
  end
  -- storm_earth_and_fire,if=fight_remains<20|(cooldown.storm_earth_and_fire.charges=2&cooldown.invoke_xuen_the_white_tiger.remains>cooldown.storm_earth_and_fire.full_recharge_time)&cooldown.fists_of_fury.remains<=9&chi>=2&cooldown.whirling_dragon_punch.remains<=12
  if S.StormEarthAndFire:IsCastable() and (FightRemains < 20 or (S.StormEarthAndFire:Charges() == 2 and S.InvokeXuenTheWhiteTiger:CooldownRemains() > S.StormEarthAndFire:FullRechargeTime()) and S.FistsofFury:CooldownRemains() <= 9 and Player:Chi() >= 2 and S.WhirlingDragonPunch:CooldownRemains() <= 12) then
    if Cast(S.StormEarthAndFire, Settings.Windwalker.OffGCDasOffGCD.StormEarthAndFire) then return "storm_earth_and_fire cd_sef 12"; end
  end
  -- With Xuen: touch_of_death,if=combo_strike&(fight_remains>60|buff.storm_earth_and_fire.down&pet.xuen_the_white_tiger.active&buff.bonedust_brew.up|(cooldown.invoke_xuen_the_white_tiger.remains>fight_remains)&buff.bonedust_brew.up|fight_remains<10)
  -- Without Xuen: touch_of_death,if=combo_strike&(fight_remains>60|buff.storm_earth_and_fire.down&buff.bonedust_brew.up|fight_remains<10)
  if S.TouchofDeath:IsReady() and ((S.InvokeXuenTheWhiteTiger:IsAvailable() and (ComboStrike(S.TouchofDeath) and (FightRemains > 60 or Player:BuffDown(S.StormEarthAndFireBuff) and XuenActive and Player:BuffUp(S.BonedustBrewBuff) or (S.InvokeXuenTheWhiteTiger:CooldownRemains() > FightRemains) and Player:BuffUp(S.BonedustBrewBuff) or FightRemains < 10))) or ((not S.InvokeXuenTheWhiteTiger:IsAvailable()) and (ComboStrike(S.TouchofDeath) and (FightRemains > 60 or Player:BuffDown(S.StormEarthAndFireBuff) and Player:BuffUp(S.BonedustBrewBuff) or FightRemains < 10)))) then
    if Cast(S.TouchofDeath, Settings.Windwalker.GCDasOffGCD.TouchOfDeath, nil, not Target:IsInMeleeRange(5)) then return "touch_of_death cd_sef 14"; end
  end
  -- use_items,if=!variable.xuen_on_use_trinket|cooldown.invoke_xuen_the_white_tiger.remains>20&pet.xuen_the_white_tiger.remains<20|variable.hold_xuen
  -- Note: variable.xuen_on_use_trinket referred to SL trinkets, so was removed, making this always true.
  if Settings.Commons.Enabled.Trinkets then
    local ShouldReturn = UseItems(); if ShouldReturn then return ShouldReturn; end
  end
  -- With Xuen: touch_of_karma,target_if=max:target.time_to_die,if=fight_remains>90|pet.xuen_the_white_tiger.active|variable.hold_xuen|fight_remains<16
  -- Without Xuen: touch_of_karma,if=fight_remains>159|variable.hold_xuen
  if S.TouchofKarma:IsCastable() and (not Settings.Windwalker.IgnoreToK) and ((S.InvokeXuenTheWhiteTiger:IsAvailable() and (FightRemains > 90 or XuenActive or VarHoldXuen or FightRemains < 16)) or ((not S.InvokeXuenTheWhiteTiger:IsAvailable()) and (FightRemains > 159 or VarHoldXuen))) then
    if Cast(S.TouchofKarma, Settings.Windwalker.GCDasOffGCD.TouchOfKarma, nil, not Target:IsInRange(20)) then return "touch_of_karma cd_sef 16"; end
  end
  -- ancestral_call,if=cooldown.invoke_xuen_the_white_tiger.remains>30|variable.hold_xuen|fight_remains<20
  if S.AncestralCall:IsCastable() and (S.InvokeXuenTheWhiteTiger:CooldownRemains() > 30 or VarHoldXuen or FightRemains < 20) then
    if Cast(S.AncestralCall, Settings.Commons.GCDasOffGCD.Racials) then return "ancestral_call cd_sef 18"; end
  end
  -- blood_fury,if=cooldown.invoke_xuen_the_white_tiger.remains>30|variable.hold_xuen|fight_remains<20
  if S.BloodFury:IsCastable() and (S.InvokeXuenTheWhiteTiger:CooldownRemains() > 30 or VarHoldXuen or FightRemains < 20) then
    if Cast(S.BloodFury, Settings.Commons.GCDasOffGCD.Racials) then return "blood_fury cd_sef 20"; end
  end
  -- fireblood,if=cooldown.invoke_xuen_the_white_tiger.remains>30|variable.hold_xuen|fight_remains<10
  if S.Fireblood:IsCastable() and (S.InvokeXuenTheWhiteTiger:CooldownRemains() > 30 or VarHoldXuen or FightRemains < 10) then
    if Cast(S.Fireblood, Settings.Commons.GCDasOffGCD.Racials) then return "fireblood cd_sef 22"; end
  end
  -- berserking,if=cooldown.invoke_xuen_the_white_tiger.remains>30|variable.hold_xuen|fight_remains<15
  if S.Berserking:IsCastable() and (S.InvokeXuenTheWhiteTiger:CooldownRemains() > 30 or VarHoldXuen or FightRemains < 15) then
    if Cast(S.Berserking, Settings.Commons.GCDasOffGCD.Racials) then return "berserking cd_sef 24"; end
  end
  -- bag_of_tricks,if=buff.storm_earth_and_fire.down
  if S.BagofTricks:IsCastable() and (Player:BuffDown(S.StormEarthAndFireBuff)) then
    if Cast(S.BagofTricks, Settings.Commons.GCDasOffGCD.Racials) then return "bag_of_tricks cd_sef 26"; end
  end
  -- lights_judgment
  if S.LightsJudgment:IsCastable() then
    if Cast(S.LightsJudgment, Settings.Commons.GCDasOffGCD.Racials) then return "lights_judgment cd_sef 28"; end
  end
end

local function Serenity()
  -- strike_of_the_windlord,if=active_enemies<3
  if S.StrikeoftheWindlord:IsReady() and (EnemiesCount8y < 3) then
    if Cast(S.StrikeoftheWindlord, nil, nil, not Target:IsInMeleeRange(9)) then return "strike_of_the_windlord serenity 2"; end
  end
  -- faeline_stomp,if=combo_strike&(!talent.faeline_harmony|debuff.fae_exposure_damage.remains<1)
  if S.FaelineStomp:IsCastable() and (ComboStrike(S.FaelineStomp) and ((not S.FaelineHarmony:IsAvailable()) or Target:DebuffRemains(S.FaeExposureDebuff) < 1)) then
    if Cast(S.FaelineStomp, nil, Settings.Commons.DisplayStyle.Signature, not Target:IsInRange(30)) then return "faeline_stomp serenity 4"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&buff.teachings_of_the_monastery.stack=3
  if S.BlackoutKick:IsReady() and (ComboStrike(S.BlackoutKick) and Player:BuffStack(S.TeachingsoftheMonasteryBuff) == 3) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick serenity 6"; end
  end
  -- fists_of_fury,if=buff.serenity.remains<1
  -- fists_of_fury_cancel
  if S.FistsofFury:IsReady() and (not Player:IsChanneling(S.FistsofFury)) and (Player:BuffRemains(S.SerenityBuff) < 1) then
    if WR.CastQueue(S.FistsofFury, S.StopFoF) then return "one_gcd fists_of_fury serenity 8"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&active_enemies=3&buff.teachings_of_the_monastery.stack=2
  if S.BlackoutKick:IsReady() and (ComboStrike(S.BlackoutKick) and EnemiesCount8y == 3 and Player:BuffStack(S.TeachingsoftheMonasteryBuff) == 2) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick serenity 10"; end
  end
  -- spinning_crane_kick,if=combo_strike&(active_enemies>3|active_enemies>2&spinning_crane_kick.modifier>=2.3)
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and (EnemiesCount8y > 3 or EnemiesCount8y > 2 and SCKModifier() >= 2.3)) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick serenity 12"; end
  end
  -- strike_of_the_windlord,if=active_enemies>=3
  if S.StrikeoftheWindlord:IsReady() and (EnemiesCount8y >= 3) then
    if Cast(S.StrikeoftheWindlord, nil, nil, not Target:IsInMeleeRange(9)) then return "strike_of_the_windlord serenity 14"; end
  end
  -- spinning_crane_kick,if=combo_strike&active_enemies>1
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and EnemiesCount8y > 1) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick serenity 16"; end
  end
  -- whirling_dragon_punch,if=active_enemies>1
  if S.WhirlingDragonPunch:IsReady() and (EnemiesCount8y > 1) then
    if Cast(S.WhirlingDragonPunch, nil, nil, not Target:IsInMeleeRange(5)) then return "whirling_dragon_punch serenity 18"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies>=3&cooldown.fists_of_fury.remains&talent.shadowboxing_treads
  if S.BlackoutKick:IsReady() and (EnemiesCount8y >= 3 and S.FistsofFury:CooldownDown() and S.ShadowboxingTreads:IsAvailable()) then
    if Cast(S.BlackoutKick, nil, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick serenity 20"; end
  end
  -- rushing_jade_wind,if=!buff.rushing_jade_wind.up&active_enemies>=3
  if S.RushingJadeWind:IsReady() and (Player:BuffDown(S.RushingJadeWindBuff) and EnemiesCount8y >= 3) then
    if Cast(S.RushingJadeWind, nil, nil, not Target:IsInMeleeRange(8)) then return "rushing_jade_wind serenity 22"; end
  end
  -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
  if S.RisingSunKick:IsReady() then
    if Everyone.CastTargetIf(S.RisingSunKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "rising_sun_kick serenity 24"; end
  end
  -- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and Player:BuffUp(S.DanceofChijiBuff)) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick serenity 24"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike
  if S.BlackoutKick:IsReady() and (ComboStrike(S.BlackoutKick)) then
    if Cast(S.BlackoutKick, nil, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick serenity 26"; end
  end
  -- whirling_dragon_punch
  if S.WhirlingDragonPunch:IsReady() then
    if Cast(S.WhirlingDragonPunch, nil, nil, not Target:IsInMeleeRange(5)) then return "whirling_dragon_punch serenity 28"; end
  end
  -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=talent.teachings_of_the_monastery&buff.teachings_of_the_monastery.stack<3
  if S.TigerPalm:IsReady() and (S.TeachingsoftheMonastery:IsAvailable() and Player:BuffStack(S.TeachingsoftheMonasteryBuff) < 3) then
    if Cast(S.TigerPalm, nil, nil, not Target:IsInMeleeRange(5)) then return "tiger_palm serenity 30"; end
  end
end

local function Aoe()
  -- faeline_stomp,if=combo_strike
  if S.FaelineStomp:IsCastable() and (ComboStrike(S.FaelineStomp)) then
    if Cast(S.FaelineStomp, nil, Settings.Commons.DisplayStyle.Signature, not Target:IsInRange(30)) then return "faeline_stomp aoe 2"; end
  end
  -- strike_of_the_windlord,if=talent.thunderfist&active_enemies>3
  if S.StrikeoftheWindlord:IsReady() and (S.Thunderfist:IsAvailable() and EnemiesCount8y > 3) then
    if Cast(S.StrikeoftheWindlord, nil, nil, not Target:IsInMeleeRange(5)) then return "strike_of_the_windlord aoe 6"; end
  end
  -- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up&active_enemies>3
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and Player:BuffUp(S.DanceofChijiBuff) and EnemiesCount8y > 3) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick aoe 4"; end
  end
  -- fists_of_fury,if=active_enemies>3
  if S.FistsofFury:IsReady() and (EnemiesCount8y > 3) then
    if Cast(S.FistsofFury, nil, nil, not Target:IsInMeleeRange(8)) then return "fists_of_fury aoe 26"; end
  end
  -- Here we should cast Rising Sun kick in order to get Dragon ready
  -- whirling_dragon_punch,if=active_enemies>8
  if S.WhirlingDragonPunch:IsReady() and (EnemiesCount8y > 8) then
    if Cast(S.WhirlingDragonPunch, nil, nil, not Target:IsInMeleeRange(5)) then return "whirling_dragon_punch aoe 8"; end
  end
  -- spinning_crane_kick,if=buff.bonedust_brew.up&combo_strike&active_enemies>5&spinning_crane_kick.modifier>=3.2
  if S.SpinningCraneKick:IsReady() and (Player:BuffUp(S.BonedustBrewBuff) and ComboStrike(S.SpinningCraneKick) and EnemiesCount8y > 5 and SCKModifier() >= 3.2) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick aoe 10"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3&talent.shadowboxing_treads
  if S.BlackoutKick:IsReady() and (Player:BuffStack(S.TeachingsoftheMonasteryBuff) == 3 and S.ShadowboxingTreads:IsAvailable()) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick aoe 12"; end
  end
  -- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and Player:BuffUp(S.DanceofChijiBuff)) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick aoe 14"; end
  end
  -- strike_of_the_windlord,if=talent.thunderfist
  if S.StrikeoftheWindlord:IsReady() and (S.Thunderfist:IsAvailable()) then
    if Cast(S.StrikeoftheWindlord, nil, nil, not Target:IsInMeleeRange(5)) then return "strike_of_the_windlord aoe 16"; end
  end
  -- whirling_dragon_punch,if=active_enemies>5
  if S.WhirlingDragonPunch:IsReady() and (EnemiesCount8y > 5) then
    if Cast(S.WhirlingDragonPunch, nil, nil, not Target:IsInMeleeRange(5)) then return "whirling_dragon_punch aoe 18"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.up&(buff.teachings_of_the_monastery.stack=2|active_enemies<5)&talent.shadowboxing_treads
  if S.BlackoutKick:IsReady() and (Player:BuffUp(S.TeachingsoftheMonasteryBuff) and (Player:BuffStack(S.TeachingsoftheMonasteryBuff) == 2 or EnemiesCount8y < 5) and S.ShadowboxingTreads:IsAvailable()) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick aoe 20"; end
  end
  -- whirling_dragon_punch
  if S.WhirlingDragonPunch:IsReady() then
    if Cast(S.WhirlingDragonPunch, nil, nil, not Target:IsInMeleeRange(5)) then return "whirling_dragon_punch aoe 22"; end
  end
  -- spinning_crane_kick,if=buff.bonedust_brew.up&combo_strike
  if S.SpinningCraneKick:IsReady() and (Player:BuffUp(S.BonedustBrewBuff) and ComboStrike(S.SpinningCraneKick)) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick aoe 24"; end
  end
  -- fists_of_fury,if=active_enemies>3
  if S.FistsofFury:IsReady() and (EnemiesCount8y > 3) then
    if Cast(S.FistsofFury, nil, nil, not Target:IsInMeleeRange(8)) then return "fists_of_fury aoe 26"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3
  if S.BlackoutKick:IsReady() and (Player:BuffStack(S.TeachingsoftheMonasteryBuff) == 3) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick aoe 28"; end
  end
  -- rushing_jade_wind,if=!buff.rushing_jade_wind.up&active_enemies>3
  if S.RushingJadeWind:IsReady() and (Player:BuffDown(S.RushingJadeWindBuff) and EnemiesCount8y > 3) then
    if Cast(S.RushingJadeWind, nil, nil, not Target:IsInMeleeRange(8)) then return "rushing_jade_wind aoe 30"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.up&active_enemies>=5&talent.shadowboxing_treads
  if S.BlackoutKick:IsReady() and (Player:BuffUp(S.TeachingsoftheMonasteryBuff) and EnemiesCount8y >= 5 and S.ShadowboxingTreads:IsAvailable()) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick aoe 32"; end
  end
  -- spinning_crane_kick,if=combo_strike&(active_enemies>=7|active_enemies=6&spinning_crane_kick.modifier>=2.7|active_enemies=5&spinning_crane_kick.modifier>=2.9)
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and (EnemiesCount8y >= 7 or EnemiesCount8y == 6 and SCKModifier() >= 2.7 or EnemiesCount8y == 5 and SCKModifier() >= 2.9)) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick aoe 34"; end
  end
  -- strike_of_the_windlord
  if S.StrikeoftheWindlord:IsReady() then
    if Cast(S.StrikeoftheWindlord, nil, nil, not Target:IsInMeleeRange(5)) then return "strike_of_the_windlord aoe 36"; end
  end
  -- spinning_crane_kick,if=combo_strike&active_enemies>=5
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and EnemiesCount8y >= 5) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick aoe 38"; end
  end
  -- fists_of_fury
  if S.FistsofFury:IsReady() then
    if Cast(S.FistsofFury, nil, nil, not Target:IsInMeleeRange(8)) then return "fists_of_fury aoe 40"; end
  end
  -- spinning_crane_kick,if=combo_strike&(active_enemies>=4&spinning_crane_kick.modifier>=2.5|!talent.shadowboxing_treads)
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and (EnemiesCount8y >= 4 and SCKModifier() >= 2.5 or not S.ShadowboxingTreads:IsAvailable())) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick aoe 42"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike
  if S.BlackoutKick:IsReady() and (ComboStrike(S.BlackoutKick)) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick aoe 44"; end
  end
  -- rushing_jade_wind,if=!buff.rushing_jade_wind.up
  if S.RushingJadeWind:IsReady() and (Player:BuffDown(S.RushingJadeWindBuff)) then
    if Cast(S.RushingJadeWind, nil, nil, not Target:IsInMeleeRange(8)) then return "rushing_jade_wind aoe 46"; end
  end
  -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
  if S.RisingSunKick:IsReady() then
    if Everyone.CastTargetIf(S.RisingSunKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "rising_sun_kick aoe 48"; end
  end
  -- whirling_dragon_punch
  if S.WhirlingDragonPunch:IsReady() then
    if Cast(S.WhirlingDragonPunch, nil, nil, not Target:IsInMeleeRange(5)) then return "whirling_dragon_punch aoe 50"; end
  end
end

local function STCleave()
  -- faeline_stomp,if=combo_strike&(!talent.faeline_harmony|debuff.fae_exposure_damage.remains<1)
  if S.FaelineStomp:IsCastable() and (ComboStrike(S.FaelineStomp) and ((not S.FaelineHarmony:IsAvailable()) or Target:DebuffRemains(S.FaeExposureDebuff) < 1)) then
    if Cast(S.FaelineStomp, nil, Settings.Commons.DisplayStyle.Signature, not Target:IsInRange(30)) then return "faeline_stomp st_cleave 2"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3&talent.shadowboxing_treads
  if S.BlackoutKick:IsReady() and (Player:BuffStack(S.TeachingsoftheMonasteryBuff) == 3 and S.ShadowboxingTreads:IsAvailable()) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick st_cleave 4"; end
  end
  -- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and Player:BuffUp(S.DanceofChijiBuff)) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick st_cleave 6"; end
  end
  -- strike_of_the_windlord,if=talent.thunderfist
  if S.StrikeoftheWindlord:IsReady() and (S.Thunderfist:IsAvailable()) then
    if Cast(S.StrikeoftheWindlord, nil, nil, not Target:IsInMeleeRange(5)) then return "strike_of_the_windlord st_cleave 8"; end
  end
  -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies=1&buff.kicks_of_flowing_momentum.up
  if S.RisingSunKick:IsReady() and (EnemiesCount8y == 1 and Player:BuffUp(S.KicksofFlowingMomentumBuff)) then
    if Everyone.CastTargetIf(S.RisingSunKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "rising_sun_kick st_cleave 10"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=2&talent.shadowboxing_treads
  if S.BlackoutKick:IsReady() and (Player:BuffStack(S.TeachingsoftheMonasteryBuff) == 2 and S.ShadowboxingTreads:IsAvailable()) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick st_cleave 12"; end
  end
  -- fists_of_fury
  if S.FistsofFury:IsReady() then
    if Cast(S.FistsofFury, nil, nil, not Target:IsInMeleeRange(8)) then return "fists_of_fury st_cleave 14"; end
  end
  -- strike_of_the_windlord
  if S.StrikeoftheWindlord:IsReady() then
    if Cast(S.StrikeoftheWindlord, nil, nil, not Target:IsInMeleeRange(5)) then return "strike_of_the_windlord st_cleave 16"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.up&(talent.shadowboxing_treads&active_enemies>1|cooldown.rising_sun_kick.remains>1)
  if S.BlackoutKick:IsReady() and (Player:BuffUp(S.TeachingsoftheMonasteryBuff) and (S.ShadowboxingTreads:IsAvailable() and EnemiesCount8y > 1 or S.RisingSunKick:CooldownRemains() > 1)) then
    if Cast(S.BlackoutKick, nil, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick st_cleave 18"; end
  end
  -- whirling_dragon_punch,if=active_enemies=2
  if S.WhirlingDragonPunch:IsReady() and (EnemiesCount8y == 2) then
    if Cast(S.WhirlingDragonPunch, nil, nil, not Target:IsInMeleeRange(5)) then return "whirling_dragon_punch st_cleave 20"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3
  if S.BlackoutKick:IsReady() and (Player:BuffStack(S.TeachingsoftheMonasteryBuff) == 3) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick st_cleave 22"; end
  end
  -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(active_enemies=1|!talent.shadowboxing_treads)&cooldown.fists_of_fury.remains>4&talent.xuens_battlegear
  if S.RisingSunKick:IsReady() and ((EnemiesCount8y == 1 or not S.ShadowboxingTreads:IsAvailable()) and S.FistsofFury:CooldownRemains() > 4 and S.XuensBattlegear:IsAvailable()) then
    if Everyone.CastTargetIf(S.RisingSunKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "rising_sun_kick st_cleave 24"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&active_enemies=2&cooldown.rising_sun_kick.remains&cooldown.fists_of_fury.remains
  if S.BlackoutKick:IsReady() and (ComboStrike(S.BlackoutKick) and EnemiesCount8y == 2 and S.RisingSunKick:CooldownDown() and S.FistsofFury:CooldownDown()) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick st_cleave 26"; end
  end
  -- rushing_jade_wind,if=!buff.rushing_jade_wind.up&active_enemies=2
  if S.RushingJadeWind:IsReady() and (Player:BuffDown(S.RushingJadeWindBuff) and EnemiesCount8y == 2) then
    if Cast(S.RushingJadeWind, nil, nil, not Target:IsInMeleeRange(8)) then return "rushing_jade_wind st_cleave 28"; end
  end
  -- spinning_crane_kick,if=buff.bonedust_brew.up&combo_strike&(active_enemies>1|spinning_crane_kick.modifier>=2.7)
  if S.SpinningCraneKick:IsReady() and (Player:BuffUp(S.BonedustBrewBuff) and ComboStrike(S.SpinningCraneKick) and (EnemiesCount8y > 1 or SCKModifier() >= 2.7)) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick st_cleave 30"; end
  end
  -- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains
  if S.RisingSunKick:IsReady() then
    if Everyone.CastTargetIf(S.RisingSunKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "rising_sun_kick st_cleave 32"; end
  end
  -- whirling_dragon_punch
  if S.WhirlingDragonPunch:IsReady() then
    if Cast(S.WhirlingDragonPunch, nil, nil, not Target:IsInMeleeRange(5)) then return "whirling_dragon_punch st_cleave 34"; end
  end
  -- rushing_jade_wind,if=!buff.rushing_jade_wind.up
  if S.RushingJadeWind:IsReady() and (Player:BuffDown(S.RushingJadeWindBuff)) then
    if Cast(S.RushingJadeWind, nil, nil, not Target:IsInMeleeRange(8)) then return "rushing_jade_wind st_cleave 36"; end
  end
  -- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike
  if S.BlackoutKick:IsReady() and (ComboStrike(S.BlackoutKick)) then
    if Everyone.CastTargetIf(S.BlackoutKick, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane100, nil, not Target:IsInMeleeRange(5)) then return "blackout_kick st_cleave 38"; end
  end
end

local function Fallthru()
  -- crackling_jade_lightning,if=buff.the_emperors_capacitor.stack>19&energy.time_to_max>execute_time-1&cooldown.rising_sun_kick.remains>execute_time|buff.the_emperors_capacitor.stack>14&(cooldown.serenity.remains<5&talent.serenity|fight_remains<5)
  if S.CracklingJadeLightning:IsReady() and (Player:BuffStack(S.TheEmperorsCapacitorBuff) > 19 and EnergyTimeToMaxRounded() > S.CracklingJadeLightning:ExecuteTime() - 1 and S.RisingSunKick:CooldownRemains() > S.CracklingJadeLightning:ExecuteTime() or Player:BuffStack(S.TheEmperorsCapacitorBuff) > 14 and (S.Serenity:CooldownRemains() < 5 and S.Serenity:IsAvailable() or FightRemains < 5)) then
    if Cast(S.CracklingJadeLightning, nil, nil, not Target:IsSpellInRange(S.CracklingJadeLightning)) then return "crackling_jade_lightning fallthru 2"; end
  end
  -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=combo_strike&buff.bonedust_brew.up&chi.max-chi>=(2+buff.power_strikes.up)
  if S.TigerPalm:IsReady() and (ComboStrike(S.TigerPalm) and Player:BuffUp(S.BonedustBrewBuff) and Player:ChiDeficit() >= (2 + num(Player:BuffUp(S.PowerStrikesBuff)))) then
    if Everyone.CastTargetIf(S.TigerPalm, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane101, nil, not Target:IsInMeleeRange(5)) then return "tiger_palm fallthru 4"; end
  end
  -- expel_harm,if=chi.max-chi>=1
  if S.ExpelHarm:IsReady() and (Player:ChiDeficit() >= 1) then
    if Cast(S.ExpelHarm, nil, nil, not Target:IsInMeleeRange(8)) then return "expel_harm fallthru 6"; end
  end
  -- chi_burst,if=chi.max-chi>=1&active_enemies=1&raid_event.adds.in>20|chi.max-chi>=2&active_enemies>=2
  if S.ChiBurst:IsCastable() and (Player:ChiDeficit() >= 1 and EnemiesCount8y == 1 or Player:ChiDeficit() >= 2 and EnemiesCount8y >= 2) then
    if Cast(S.ChiBurst, nil, nil, not Target:IsInRange(40)) then return "chi_burst fallthru 8"; end
  end
  -- chi_wave
  if S.ChiWave:IsCastable() then
    if Cast(S.ChiWave, nil, nil, not Target:IsInRange(40)) then return "chi_wave fallthru 10"; end
  end
  -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=combo_strike&chi.max-chi>=(2+buff.power_strikes.up)&buff.storm_earth_and_fire.down
  if S.TigerPalm:IsReady() and (ComboStrike(S.TigerPalm) and Player:ChiDeficit() >= (2 + num(Player:BuffUp(S.PowerStrikesBuff))) and Player:BuffDown(S.StormEarthAndFireBuff)) then
    if Everyone.CastTargetIf(S.TigerPalm, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane101, nil, not Target:IsInMeleeRange(5)) then return "tiger_palm fallthru 12"; end
  end
  -- spinning_crane_kick,if=combo_strike&buff.chi_energy.stack>30-5*active_enemies&buff.storm_earth_and_fire.down&(cooldown.rising_sun_kick.remains>2&cooldown.fists_of_fury.remains>2|cooldown.rising_sun_kick.remains<3&cooldown.fists_of_fury.remains>3&chi>3|cooldown.rising_sun_kick.remains>3&cooldown.fists_of_fury.remains<3&chi>4|chi.max-chi<=1&energy.time_to_max<2)|buff.chi_energy.stack>10&fight_remains<7
  if S.SpinningCraneKick:IsReady() and (ComboStrike(S.SpinningCraneKick) and Player:BuffStack(S.ChiEnergyBuff) > 30 - 5 * EnemiesCount8y and Player:BuffDown(S.StormEarthAndFireBuff) and (S.RisingSunKick:CooldownRemains() > 2 and S.FistsofFury:CooldownRemains() > 2 or S.RisingSunKick:CooldownRemains() < 3 and S.FistsofFury:CooldownRemains() > 3 and Player:Chi() > 3 or S.RisingSunKick:CooldownRemains() > 3 and S.FistsofFury:CooldownRemains() < 3 and Player:Chi() > 4 or Player:ChiDeficit() <= 1 and EnergyTimeToMaxRounded() < 2) or Player:BuffStack(S.ChiEnergyBuff) > 10 and FightRemains < 7) then
    if Cast(S.SpinningCraneKick, nil, nil, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick fallthru 14"; end
  end
  -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=combo_strike&chi.max-chi>=(2+buff.power_strikes.up)
  if S.TigerPalm:IsReady() and (ComboStrike(S.TigerPalm) and Player:ChiDeficit() >= (2 + num(Player:BuffUp(S.PowerStrikesBuff)))) then
    if Everyone.CastTargetIf(S.TigerPalm, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane101, nil, not Target:IsInMeleeRange(5)) then return "tiger_palm fallthru 16"; end
  end
  -- arcane_torrent,if=chi.max-chi>=1
  if S.ArcaneTorrent:IsCastable() and (Player:ChiDeficit() >= 1) then
    if Cast(S.ArcaneTorrent, Settings.Commons.GCDasOffGCD.Racials) then return "arcane_torrent fallthru 18"; end
  end
  -- flying_serpent_kick,interrupt=1
  if S.FlyingSerpentKick:IsCastable() and not Settings.Windwalker.IgnoreFSK then
    if Cast(S.FlyingSerpentKick, nil, nil, not Target:IsInRange(30)) then return "flying_serpent_kick fallthru 20"; end
  end
end

local function SpendEnergy()
  -- expel_harm,if=chi.max-chi>=1&(energy.time_to_max<1|cooldown.serenity.remains<2|energy.time_to_max<4&cooldown.fists_of_fury.remains<1.5)&(!buff.bonedust_brew.up|buff.bloodlust.up|buff.invokers_delight.up)
  if S.ExpelHarm:IsReady() and (Player:ChiDeficit() >= 1 and (EnergyTimeToMaxRounded() < 1 or S.Serenity:CooldownRemains() < 2 or EnergyTimeToMaxRounded() < 4 and S.FistsofFury:CooldownRemains() < 1.5) and (Player:BuffDown(S.BonedustBrewBuff) or Player:BloodlustUp() or Player:BuffUp(S.InvokersDelightBuff))) then
    if Cast(S.ExpelHarm, nil, nil, not Target:IsInMeleeRange(8)) then return "expel_harm spend_energy 2"; end
  end
  -- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=buff.teachings_of_the_monastery.stack<3&combo_strike&chi.max-chi>=(2+buff.power_strikes.up)&(energy.time_to_max<1|cooldown.serenity.remains<2|energy.time_to_max<4&cooldown.fists_of_fury.remains<1.5)
  if S.TigerPalm:IsReady() and (Player:BuffStack(S.TeachingsoftheMonasteryBuff) < 3 and ComboStrike(S.TigerPalm) and Player:ChiDeficit() >= (2 + num(Player:BuffUp(S.PowerStrikesBuff))) and (EnergyTimeToMaxRounded() < 1 or S.Serenity:CooldownRemains() < 2 or EnergyTimeToMaxRounded() < 4 and S.FistsofFury:CooldownRemains() < 1.5)) then
    if Everyone.CastTargetIf(S.TigerPalm, Enemies5y, "min", EvaluateTargetIfFilterMarkoftheCrane101, nil, not Target:IsInMeleeRange(5)) then return "tiger_palm spend_energy 4"; end
  end
end

-- APL Main
local function APL()
  Enemies5y = Player:GetEnemiesInMeleeRange(5) -- Multiple Abilities
  Enemies8y = Player:GetEnemiesInMeleeRange(8) -- Multiple Abilities
  if AoEON() then
    EnemiesCount8y = #Enemies8y -- AOE Toogle
  else
    EnemiesCount8y = 1
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies8y, false)
    end
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    XuenActive = S.InvokeXuenTheWhiteTiger:TimeSinceLastCast() <= 24
  end

  if Everyone.TargetIsValid() then
    -- Out of Combat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- auto_attack
    -- Manually added: Force landing from FSK
    if (not Settings.Windwalker.IgnoreFSK) and Player:PrevGCD(1, S.FlyingSerpentKick) then
      if Cast(S.FlyingSerpentKickLand) then return "flying_serpent_kick land"; end
    end
    
    -- Fortifying Brew
    if S.FortifyingBrew:IsReady() and Settings.Windwalker.ShowFortifyingBrewCD and Player:HealthPercentage() <= Settings.Windwalker.FortifyingBrewHP then
      if Cast(S.FortifyingBrew, Settings.Windwalker.GCDasOffGCD.FortifyingBrew, nil, not Target:IsSpellInRange(S.FortifyingBrew)) then return "fortifying_brew main 2"; end
    end
    -- variable,name=hold_xuen,op=set,value=!talent.invoke_xuen_the_white_tiger|cooldown.invoke_xuen_the_white_tiger.remains>fight_remains|fight_remains-cooldown.invoke_xuen_the_white_tiger.remains<120&((talent.serenity&fight_remains>cooldown.serenity.remains&cooldown.serenity.remains>10)|(cooldown.storm_earth_and_fire.full_recharge_time<fight_remains&cooldown.storm_earth_and_fire.full_recharge_time>15)|(cooldown.storm_earth_and_fire.charges=0&cooldown.storm_earth_and_fire.remains<fight_remains))
    VarHoldXuen = ((not S.InvokeXuenTheWhiteTiger:IsAvailable()) or S.InvokeXuenTheWhiteTiger:CooldownRemains() > FightRemains or FightRemains - S.InvokeXuenTheWhiteTiger:CooldownRemains() < 120 and ((S.Serenity:IsAvailable() and FightRemains > S.Serenity:CooldownRemains() and S.Serenity:CooldownRemains() > 10) or (S.StormEarthAndFire:FullRechargeTime() < FightRemains and S.StormEarthAndFire:FullRechargeTime() > 15) or (S.StormEarthAndFire:Charges() == 0 and S.StormEarthAndFire:CooldownRemains() < FightRemains)))
    -- variable,name=hold_sef,op=set,value=cooldown.bonedust_brew.up&cooldown.storm_earth_and_fire.charges<2&chi<3|buff.bonedust_brew.remains<8
    VarHoldSEF = (S.BonedustBrew:CooldownUp() and S.StormEarthAndFire:Charges() < 2 and Player:Chi() < 3 or Player:BuffRemains(S.BonedustBrew) < 8)
    
    -- With Xuen: call_action_list,name=opener,if=time<4&chi<5&!pet.xuen_the_white_tiger.active&!talent.serenity
    -- Without Xuen: call_action_list,name=opener,if=time<4&chi<5&!talent.serenity
    if (HL.CombatTime() < 4 and Player:Chi() < 5 and (not S.Serenity:IsAvailable()) and ((not XuenActive) or not S.InvokeXuenTheWhiteTiger:IsAvailable())) then
      local ShouldReturn = Opener(); if ShouldReturn then return ShouldReturn; end
    end
    -- faeline_stomp,if=combo_strike&talent.faeline_harmony&(!debuff.fae_exposure_damage.up|active_enemies>1)
    -- call_action_list,name=spend_energy,if=!buff.bonedust_brew.up&!buff.first_strike.up&!buff.serenity.up
    -- chi_burst,if=talent.faeline_stomp&cooldown.faeline_stomp.remains&(chi.max-chi>=1&active_enemies=1|chi.max-chi>=2&active_enemies>=2)&!buff.first_strike.up
    -- call_action_list,name=cd_sef,if=!talent.serenity
    
    local ShouldReturn = SpendEnergy(); if ShouldReturn then return ShouldReturn; end
    
    if (CDsON() and not S.Serenity:IsAvailable()) then
      local ShouldReturn = CDSEF(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=cd_serenity,if=talent.serenity
    if (CDsON() and S.Serenity:IsAvailable()) then
      local ShouldReturn = CDSerenity(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=serenity,if=buff.serenity.up
    if Player:BuffUp(S.SerenityBuff) then
      local ShouldReturn = Serenity(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=aoe,if=active_enemies>=3
    if (AoEON() and EnemiesCount8y >= 3) then
      local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=st_cleave,if=active_enemies<3
    if (EnemiesCount8y < 3) then
      local ShouldReturn = STCleave(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=fallthru
    if (true) then
      local ShouldReturn = Fallthru(); if ShouldReturn then return ShouldReturn; end
    end
    -- Manually added Pool filler
    if Cast(S.PoolEnergy) then return "Pool Energy"; end
  end
end

local function AutoBind()
  -- Spell Binds
  WR.Bind(S.BlackoutKick)
  WR.Bind(M.SummonWhiteTigerStatueM)
  WR.Bind(S.TouchofKarma)
  WR.Bind(S.ChiWave)
  WR.Bind(S.ExpelHarm)
  WR.Bind(S.InvokeXuenTheWhiteTiger)
  WR.Bind(S.StrikeoftheWindlord)
  WR.Bind(S.StormEarthAndFire)
  WR.Bind(S.FistsofFury)
  WR.Bind(S.SpinningCraneKick)
  WR.Bind(S.TigerPalm)
  WR.Bind(S.ChiBurst)
  WR.Bind(S.RisingSunKick)
  WR.Bind(M.BonedustBrewM)
  WR.Bind(S.TouchofDeath)
  
end

local function Init ()
  WR.Print("Windwalker Monk by Gabbz")
  AutoBind()
end

WR.SetAPL(269, APL, Init)
