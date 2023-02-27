--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC         = HeroDBC.DBC
-- HeroLib
local HL          = HeroLib
local Cache       = HeroCache
local Unit        = HL.Unit
local Player      = Unit.Player
local Mouseover   = Unit.MouseOver
local Pet         = Unit.Pet
local Target      = Unit.Target
local Spell       = HL.Spell
local MultiSpell  = HL.MultiSpell
local Item        = HL.Item
-- WorldyRotation
local WR          = WorldyRotation
local AoEON       = WR.AoEON
local CDsON       = WR.CDsON
local Cast        = WR.Cast
local CastPooling = WR.CastPooling
local Macro       = WR.Macro
local Bind        = WR.Bind
local Press       = WR.Press
-- Num/Bool Helper Functions
local num         = WR.Commons.Everyone.num
local bool        = WR.Commons.Everyone.bool

--- ============================ CONTENT ============================
--- ======= APL LOCALS =======
-- Commons
local Everyone = WR.Commons.Everyone

-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Druid.Commons,
  Feral = WR.GUISettings.APL.Druid.Feral
}

-- Spells
local S = Spell.Druid.Feral

-- Items
local I = Item.Druid.Feral
local OnUseExcludes = {
}

-- Macros
local M = Macro.Druid.Feral

-- Rotation Variables
local VarNeedBT
local ComboPoints, ComboPointsDeficit
local BossFightRemains = 11111
local FightRemains = 11111

-- Enemy Variables
local EnemiesMelee, EnemiesCountMelee
local Enemies11y, EnemiesCount11y

-- Berserk/Incarnation Variables
local BsInc = S.Incarnation:IsAvailable() and S.Incarnation or S.Berserk

-- Trinket Item Objects
local equip = Player:GetEquipment()
local trinket1 = equip[13] and Item(equip[13]) or Item(0)
local trinket2 = equip[14] and Item(equip[14]) or Item(0)

-- Event Registration
HL:RegisterForEvent(function()
  equip = Player:GetEquipment()
  trinket1 = equip[13] and Item(equip[13]) or Item(0)
  trinket2 = equip[14] and Item(equip[14]) or Item(0)
end, "PLAYER_EQUIPMENT_CHANGED")

HL:RegisterForEvent(function()
  BsInc = S.Incarnation:IsAvailable() and S.Incarnation or S.Berserk
end, "PLAYER_TALENT_UPDATE")

HL:RegisterForEvent(function()
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

HL:RegisterForEvent(function()
  S.AdaptiveSwarm:RegisterInFlight()
end, "LEARNED_SPELL_IN_TAB")
S.AdaptiveSwarm:RegisterInFlight()

-- PMultiplier and Damage Registrations
local function ComputeRakePMultiplier()
  return Player:StealthUp(true, true) and 1.6 or 1
end
S.Rake:RegisterPMultiplier(S.RakeDebuff, ComputeRakePMultiplier)

local function SwipeBleedMult()
  return (Target:DebuffUp(S.Rip) or Target:DebuffUp(S.RakeDebuff) or Target:DebuffUp(S.ThrashDebuff)) and 1.2 or 1;
end

S.Shred:RegisterDamageFormula(
  function()
    return
      -- Attack Power
      Player:AttackPowerDamageMod() *
      -- Shred Modifier
      0.6837 *
      -- Stealth Modifier
      (Player:StealthUp(true) and 1.6 or 1) *
      -- Versatility Modifier
      (1 + Player:VersatilityDmgPct() / 100)
  end
)

S.Thrash:RegisterDamageFormula(
  function()
    return
      -- Immediate Damage
      (Player:AttackPowerDamageMod() * 0.098) +
      -- Bleed Damage
      (Player:AttackPowerDamageMod() * 0.312)
  end
)

-- Functions for Bloodtalons
local BtTriggers = {
  S.Rake,
  S.LIMoonfire,
  S.Thrash,
  S.BrutalSlash,
  S.Swipe,
  S.Shred,
  S.FeralFrenzy,
}

local function BTBuffUp(Trigger)
  if not S.Bloodtalons:IsAvailable() then return false end
  return Trigger:TimeSinceLastCast() < math.min(5, S.BloodtalonsBuff:TimeSinceLastAppliedOnPlayer())
end

local function BTBuffDown(Trigger)
  return not BTBuffUp(Trigger)
end

function CountActiveBtTriggers()
  local ActiveTriggers = 0
  for i = 1, #BtTriggers do
    if BTBuffUp(BtTriggers[i]) then ActiveTriggers = ActiveTriggers + 1 end
  end
  return ActiveTriggers
end

local function TicksGainedOnRefresh(Spell, Tar)
  if not Tar then Tar = Target end
  local AddedDuration = 0
  local MaxDuration = 0
  -- Added TickTime variable, as Rake and Moonfire don't have tick times in DBC
  local TickTime = 0
  if Spell == S.Rip then
    AddedDuration = (4 + ComboPoints * 4)
    MaxDuration = 31.2
    TickTime = Spell:TickTime()
  else
    AddedDuration = Spell:BaseDuration()
    MaxDuration = Spell:MaxDuration()
    TickTime = Spell:TickTime()
  end

  local OldTicks = Tar:DebuffTicksRemain(Spell)
  local OldTime = Tar:DebuffRemains(Spell)
  local NewTime = AddedDuration + OldTime
  if NewTime > MaxDuration then NewTime = MaxDuration end
  local NewTicks = NewTime / TickTime
  if (not OldTicks) then OldTicks = 0 end
  local TicksAdded = NewTicks - OldTicks
  return TicksAdded
end

-- CastCycle/CastTargetIf Functions
local function EvaluateCycleAdaptiveSwarm(TargetUnit)
  -- target_if=((!dot.adaptive_swarm_damage.ticking|dot.adaptive_swarm_damage.remains<2)&(dot.adaptive_swarm_damage.stack<3|!dot.adaptive_swarm_heal.stack>1)&!action.adaptive_swarm_heal.in_flight&!action.adaptive_swarm_damage.in_flight&!action.adaptive_swarm.in_flight)&target.time_to_die>5|active_enemies>2&!dot.adaptive_swarm_damage.ticking&energy<35&target.time_to_die>5
  return (((TargetUnit:DebuffDown(S.AdaptiveSwarmDebuff) or TargetUnit:DebuffRemains(S.AdaptiveSwarmDebuff) < 2) and (TargetUnit:DebuffStack(S.AdaptiveSwarmDebuff) < 3 or Player:BuffStack(S.AdaptiveSwarmHeal) <= 1) and (not S.AdaptiveSwarm:InFlight())) and TargetUnit:TimeToDie() > 5 or EnemiesCount11y > 2 and TargetUnit:DebuffDown(S.AdaptiveSwarmDebuff) and Player:Energy() < 35 and TargetUnit:TimeToDie() > 5)
end

local function EvaluateCycleLIMoonfire(TargetUnit)
  -- target_if=refreshable
  return (TargetUnit:DebuffRefreshable(S.LIMoonfireDebuff))
end

local function EvaluateCycleLIMoonfireAoe(TargetUnit)
  -- target_if=max:((ticks_gained_on_refresh+1)-(spell_targets.swipe_cat*2.492))
  return ((TicksGainedOnRefresh(S.LIMoonfireDebuff, TargetUnit) + 1) - (EnemiesCount11y * 2.492))
end

local function EvaluateCyclePrimalWrath(TargetUnit)
  -- target_if=refreshable
  return (TargetUnit:DebuffRefreshable(S.Rip))
end

local function EvaluateCycleRip(TargetUnit)
  -- target_if=refreshable
  return (TargetUnit:DebuffRefreshable(S.Rip))
end

local function EvaluateCycleThrash(TargetUnit)
  -- target_if=refreshable
  return (TargetUnit:DebuffRefreshable(S.ThrashDebuff))
end

local function EvaluateTargetIfFilterRake(TargetUnit)
  -- target_if=refreshable
  return (TargetUnit:DebuffRefreshable(S.RakeDebuff))
end

local function EvaluateTargetIfFilterRakeAoe(TargetUnit)
  -- target_if=max:dot.rake.ticks_gained_on_refresh.pmult
  return (TicksGainedOnRefresh(S.RakeDebuff, TargetUnit))
end

local function EvaluateTargetIfFilterRakeTicks(TargetUnit)
  -- target_if=max:druid.rake.ticks_gained_on_refresh
  return (TicksGainedOnRefresh(S.RakeDebuff, TargetUnit))
end

local function EvaluateTargetIfRake(TargetUnit)
  -- if=refreshable|(buff.sudden_ambush.up&persistent_multiplier>dot.rake.pmultiplier&dot.rake.duration>6)
  -- Note: Skipped dot.rake.duration>6, as this should always be true (may have intended .remains?)
  return (TargetUnit:DebuffRefreshable(S.RakeDebuff) or (Player:BuffUp(S.SuddenAmbushBuff) and Player:PMultiplier(S.Rake) > TargetUnit:PMultiplier(S.Rake)))
end

local function EvaluateTargetIfRakeAoe(TargetUnit)
  -- if=((dot.rake.ticks_gained_on_refresh.pmult*(1+talent.doubleclawed_rake.enabled))>(spell_targets.swipe_cat*0.216+3.32))
  return ((TicksGainedOnRefresh(S.RakeDebuff, TargetUnit) * (1 + num(S.DoubleClawedRake:IsAvailable()))) > (EnemiesCount11y * 0.216 + 3.32))
end

local function EvaluateTargetIfRakeBloodtalons(TargetUnit)
  -- if=(refreshable|1.4*persistent_multiplier>dot.rake.pmultiplier)&buff.bt_rake.down
  return ((TargetUnit:DebuffRefreshable(S.RakeDebuff) or 1.4 * Player:PMultiplier(S.Rake) > TargetUnit:PMultiplier(S.Rake)) and BTBuffDown(S.Rake))
end

-- APL Functions
local function Precombat()
  -- cat_form
  if S.CatForm:IsCastable() then
    if Press(S.CatForm) then return "cat_form precombat 2"; end
  end
  -- prowl
  if S.Prowl:IsCastable() then
    if Press(S.Prowl) then return "prowl precombat 4"; end
  end
  -- Manually added: wild_charge
  if Settings.Feral.Enabled.WildCharge and S.WildCharge:IsCastable() and (not Target:IsInRange(8)) then
    if Press(S.WildCharge, not Target:IsInRange(28)) then return "wild_charge precombat 6"; end
  end
  -- Manually added: rake
  if S.Rake:IsReady() then
    if Press(S.Rake, not Target:IsInMeleeRange(8)) then return "rake precombat 8"; end
  end
end

local function Clearcasting()
  -- thrash_cat,if=refreshable
  if S.Thrash:IsReady() and (Target:DebuffRefreshable(S.ThrashDebuff)) then
    if Press(S.Thrash, not Target:IsInMeleeRange(11)) then return "thrash clearcasting 2"; end
  end
  -- swipe_cat,if=spell_targets.swipe_cat>1
  if S.Swipe:IsReady() and (EnemiesCount11y > 1) then
    if Press(S.Swipe, not Target:IsInMeleeRange(11)) then return "swipe clearcasting 4"; end
  end
  -- brutal_slash,if=spell_targets.brutal_slash>5&talent.moment_of_clarity.enabled
  if S.BrutalSlash:IsReady() and (EnemiesCount11y > 5 and S.MomentofClarity:IsAvailable()) then
    if Press(S.BrutalSlash, not Target:IsInMeleeRange(8)) then return "brutal_slash clearcasting 6"; end
  end
  -- shred
  if S.Shred:IsReady() then
    if Press(S.Shred, not Target:IsInMeleeRange(8)) then return "shred clearcasting 8"; end
  end
end

local function Builder()
  -- run_action_list,name=clearcasting,if=buff.clearcasting.react
  if (Player:BuffUp(S.Clearcasting)) then
    local ShouldReturn = Clearcasting(); if ShouldReturn then return ShouldReturn; end
    if Press(S.Pool) then return "Pool for Clearcasting"; end
  end
  -- rake,target_if=max:ticks_gained_on_refresh,if=refreshable|(buff.sudden_ambush.up&persistent_multiplier>dot.rake.pmultiplier&dot.rake.duration>6)
  if S.Rake:IsReady() then
    if Everyone.CastTargetIf(S.Rake, EnemiesMelee, "max", EvaluateTargetIfFilterRakeTicks, EvaluateTargetIfRake, not Target:IsInMeleeRange(8), nil, nil, M.RakeMouseover) then return "rake builder 2"; end
  end
  -- moonfire_cat,target_if=refreshable
  if S.LIMoonfire:IsReady() then
    if Everyone.CastCycle(S.LIMoonfire, Enemies11y, EvaluateCycleLIMoonfire, not Target:IsSpellInRange(S.LIMoonfire), nil, nil, M.MoonfireMouseover) then return "moonfire_cat builder 4"; end
  end
  -- pool_resource,for_next=1
  -- thrash_cat,target_if=refreshable
  if S.Thrash:IsCastable() and (Target:DebuffRefreshable(S.ThrashDebuff)) then
    if CastPooling(S.Thrash, Player:EnergyTimeToX(40), not Target:IsInMeleeRange(11)) then return "thrash builder 6"; end
  end
  -- brutal_slash
  if S.BrutalSlash:IsReady() then
    if Press(S.BrutalSlash, not Target:IsInMeleeRange(11)) then return "brutal_slash builder 8"; end
  end
  -- swipe_cat,if=spell_targets.swipe_cat>1
  if S.Swipe:IsReady() and (EnemiesCount11y > 1) then
    if Press(S.Swipe, not Target:IsInMeleeRange(11)) then return "swipe builder 10"; end
  end
  -- shred
  if S.Shred:IsReady() then
    if Press(S.Shred, not Target:IsInMeleeRange(8)) then return "shred builder 12"; end
  end
end

local function BerserkBuilders()
  -- rake,target_if=refreshable
  if S.Rake:IsReady() then
    if Everyone.CastCycle(S.Rake, EnemiesMelee, EvaluateTargetIfFilterRake, not Target:IsInMeleeRange(8), nil, nil, M.RakeMouseover) then return "rake berserk_builders 2"; end
  end
  -- swipe_cat,if=spell_targets.swipe_cat>1
  if S.Swipe:IsReady() and (EnemiesCount11y > 1) then
    if Press(S.Swipe, not Target:IsInMeleeRange(11)) then return "swipe berserk_builders 4"; end
  end
  -- brutal_slash,if=active_bt_triggers=2&buff.bt_brutal_slash.down
  if S.BrutalSlash:IsReady() and (CountActiveBtTriggers() == 2 and BTBuffDown(S.BrutalSlash)) then
    if Press(S.BrutalSlash, not Target:IsInMeleeRange(11)) then return "brutal_slash berserk_builders 6"; end
  end
  -- moonfire_cat,target_if=refreshable
  if S.LIMoonfire:IsReady() then
    if Everyone.CastCycle(S.LIMoonfire, Enemies11y, EvaluateCycleLIMoonfire, not Target:IsSpellInRange(S.LIMoonfire), nil, nil, M.MoonfireMouseover) then return "moonfire_cat berserk_builder 8"; end
  end
  -- shred
  if S.Shred:IsReady() then
    if Press(S.Shred, not Target:IsInMeleeRange(8)) then return "shred berserk_builders 10"; end
  end
end

local function Finisher()
  -- primal_wrath,if=spell_targets.primal_wrath>2
  if S.PrimalWrath:IsReady() and (EnemiesCount11y > 2) then
    if Press(S.PrimalWrath, not Target:IsInMeleeRange(11)) then return "primal_wrath finisher 2"; end
  end
  -- primal_wrath,target_if=refreshable,if=spell_targets.primal_wrath>1
  if S.PrimalWrath:IsReady() and (EnemiesCount11y > 1) then
    if Everyone.CastCycle(S.PrimalWrath, Enemies11y, EvaluateCyclePrimalWrath, not Target:IsInMeleeRange(11), nil, nil, M.PrimalWrathMouseover) then return "primal_wrath finisher 4"; end
  end
  -- rip,target_if=refreshable
  if S.Rip:IsReady() then
    if Everyone.CastCycle(S.Rip, EnemiesMelee, EvaluateCycleRip, not Target:IsInRange(8), nil, nil, M.RipMouseover) then return "rip finisher 6"; end
  end
  -- pool_resource,for_next=1
  -- ferocious_bite,max_energy=1,if=!buff.bs_inc.up|(buff.bs_inc.up&!talent.soul_of_the_forest.enabled)
  if S.FerociousBite:IsReady() and (Player:BuffDown(BsInc) or (Player:BuffUp(BsInc) and not S.SouloftheForest:IsAvailable())) then
    if CastPooling(S.FerociousBite, Player:EnergyTimeToX(50)) then return "ferocious_bite finisher 14"; end
  end
  -- ferocious_bite,if=(buff.bs_inc.up&talent.soul_of_the_forest.enabled)
  if S.FerociousBite:IsReady() and (Player:BuffUp(BsInc) and S.SouloftheForest:IsAvailable()) then
    if Press(S.FerociousBite, not Target:IsInMeleeRange(8)) then return "ferocious_bite finisher 10"; end
  end
end

local function Cooldown()
  -- berserk
  if S.Berserk:IsReady() then
    if Press(S.Berserk, not Target:IsInMeleeRange(8)) then return "berserk cooldown 2"; end
  end
  -- incarnation
  if S.Incarnation:IsReady() then
    if Press(S.Incarnation, not Target:IsInMeleeRange(8)) then return "incarnation cooldown 4"; end
  end
  -- convoke_the_spirits,if=buff.tigers_fury.up&combo_points<3|fight_remains<5
  if S.ConvokeTheSpirits:IsReady() and (Player:BuffUp(S.TigersFury) and ComboPoints < 3 or FightRemains < 5) then
    if Press(S.ConvokeTheSpirits, not Target:IsInMeleeRange(8), true) then return "convoke_the_spirits cooldown 6"; end
  end
  -- berserking
  if S.Berserking:IsCastable() then
    if Press(S.Berserking, not Target:IsInMeleeRange(8)) then return "berserking cooldown 8"; end
  end
  -- shadowmeld,if=buff.tigers_fury.up&buff.bs_inc.down&combo_points<4&buff.sudden_ambush.down&dot.rake.pmultiplier<1.6&energy>40&druid.rake.ticks_gained_on_refresh>spell_targets.swipe_cat*2-2&target.time_to_die>5
  if S.Shadowmeld:IsCastable() and (Player:BuffUp(S.TigersFury) and Player:BuffDown(BsInc) and ComboPoints < 4 and Player:BuffDown(S.SuddenAmbushBuff) and Target:PMultiplier(S.Rake) < 1.6 and Player:Energy() > 40 and TicksGainedOnRefresh(S.RakeDebuff) > EnemiesCount11y * 2 - 2 and Target:TimeToDie() > 5) then
    if Press(S.Shadowmeld, not Target:IsInMeleeRange(8)) then return "shadowmeld cooldown 10"; end
  end
  -- potion,if=buff.bs_inc.up|fight_remains<cooldown.bs_inc.remains|fight_remains<35
  -- use_items
  if CDsON() and Settings.General.Enabled.Trinkets and Target:IsInMeleeRange(8) then
    local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
    if Trinket1ToUse then
      if Press(M.Trinket1, nil, nil, true) then return "trinket1 cooldown 14"; end
    end
    local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
    if Trinket2ToUse then
      if Press(M.Trinket2, nil, nil, true) then return "trinket2 cooldown 16"; end
    end
  end
end

local function Owlweaving()
  if (Player:BuffUp(S.MoonkinForm)) then
    -- sunfire,line_cd=4*gcd
    if S.Sunfire:IsReady() and (S.Sunfire:TimeSinceLastCast() > 4 * Player:GCD()) then
      if Press(S.Sunfire, not Target:IsSpellInRange(S.Sunfire)) then return "sunfire owlweaving 4"; end
    end
  end
  -- Manually added: moonkin_form,if=!buff.moonkin_form.up
  if S.MoonkinForm:IsCastable() and (Player:BuffDown(S.MoonkinForm)) then
    if Press(S.MoonkinForm) then return "moonkin_form owlweave 10"; end
  end
end

local function Bloodtalons()
  -- rake,target_if=max:druid.rake.ticks_gained_on_refresh,if=(refreshable|1.4*persistent_multiplier>dot.rake.pmultiplier)&buff.bt_rake.down
  if S.Rake:IsReady() and (BTBuffDown(S.Rake)) then
    if Everyone.CastTargetIf(S.Rake, EnemiesMelee, "max", EvaluateTargetIfFilterRakeTicks, EvaluateTargetIfRakeBloodtalons, not Target:IsInRange(8), nil, nil, M.RakeMouseover) then return "rake bloodtalons 2"; end
  end
  -- lunar_inspiration,if=refreshable&buff.bt_moonfire.down
  if S.LunarInspiration:IsAvailable() and S.LIMoonfire:IsReady() and (Target:DebuffRefreshable(S.LIMoonfireDebuff) and BTBuffDown(S.LIMoonfire)) then
    if Press(S.LIMoonfire, not Target:IsSpellInRange(S.LIMoonfire)) then return "moonfire bloodtalons 4"; end
  end
  -- brutal_slash,if=buff.bt_brutal_slash.down
  if S.BrutalSlash:IsReady() and (BTBuffDown(S.BrutalSlash)) then
    if Press(S.BrutalSlash, not Target:IsInMeleeRange(8)) then return "brutal_slash bloodtalons 6"; end
  end
  -- thrash_cat,target_if=refreshable&buff.bt_thrash.down
  if S.Thrash:IsReady() and (BTBuffDown(S.Thrash)) then
    if Everyone.CastCycle(S.Thrash, Enemies11y, EvaluateCycleThrash, not Target:IsInMeleeRange(8)) then return "thrash bloodtalons 8"; end
  end
  -- swipe_cat,if=spell_targets.swipe_cat>1&buff.bt_swipe.down
  if S.Swipe:IsReady() and (EnemiesCount11y > 1 and BTBuffDown(S.Swipe)) then
    if Press(S.Swipe, not Target:IsInMeleeRange(8)) then return "swipe bloodtalons 14"; end
  end
  -- shred,if=buff.bt_shred.down
  if S.Shred:IsReady() and (BTBuffDown(S.Shred)) then
    if Press(S.Shred, not Target:IsInMeleeRange(8)) then return "shred bloodtalons 10"; end
  end
  -- swipe_cat,if=buff.bt_swipe.down
  if S.Swipe:IsReady() and (BTBuffDown(S.Swipe)) then
    if Press(S.Swipe, not Target:IsInMeleeRange(8)) then return "swipe bloodtalons 12"; end
  end
  -- thrash_cat,if=buff.bt_thrash.down
  if S.Thrash:IsReady() and (BTBuffDown(S.Thrash)) then
    if Press(S.Thrash, not Target:IsInMeleeRange(8)) then return "thrash bloodtalons 16"; end
  end
  -- rake,if=buff.bt_rake.down&combo_points>4
  if S.Rake:IsReady() and (BTBuffDown(S.Rake) and ComboPoints > 4) then
    if Press(S.Rake, not Target:IsInMeleeRange(8)) then return "rake bloodtalons 18"; end
  end
end

local function Aoe()
  -- pool_resource,for_next=1
  -- primal_wrath,if=combo_points=5
  if S.PrimalWrath:IsCastable() and (ComboPoints == 5) then
    if CastPooling(S.PrimalWrath, Player:EnergyTimeToX(20), not Target:IsInMeleeRange(11)) then return "primal_wrath aoe 2"; end
  end
  -- ferocious_bite,if=buff.apex_predators_craving.up&buff.sabertooth.down
  if S.FerociousBite:IsReady() and (Player:BuffUp(S.ApexPredatorsCravingBuff) and Player:BuffDown(S.SabertoothBuff)) then
    if Press(S.FerociousBite, not Target:IsInMeleeRange(8)) then return "ferocious_bite aoe 4"; end
  end
  -- run_action_list,name=bloodtalons,if=variable.need_bt&active_bt_triggers>=1
  if (VarNeedBT and CountActiveBtTriggers() >= 1) then
    local ShouldReturn = Bloodtalons(); if ShouldReturn then return ShouldReturn; end
    if Press(S.Pool) then return "Pool for Bloodtalons()"; end
  end
  -- pool_resource,for_next=1
  -- thrash_cat,target_if=refreshable
  if S.Thrash:IsCastable() and (Target:DebuffRefreshable(S.ThrashDebuff)) then
    if CastPooling(S.Thrash, Player:EnergyTimeToX(40), not Target:IsInMeleeRange(11)) then return "thrash aoe 6"; end
  end
  -- brutal_slash
  if S.BrutalSlash:IsReady() then
    if Press(S.BrutalSlash, not Target:IsInMeleeRange(11)) then return "brutal_slash aoe 8"; end
  end
  -- pool_resource,for_next=1
  -- rake,target_if=max:dot.rake.ticks_gained_on_refresh.pmult,if=((dot.rake.ticks_gained_on_refresh.pmult*(1+talent.doubleclawed_rake.enabled))>(spell_targets.swipe_cat*0.216+3.32))
  if S.Rake:IsReady() then
    if Everyone.CastTargetIf(S.Rake, EnemiesMelee, "max", EvaluateTargetIfFilterRakeAoe, EvaluateTargetIfRakeAoe, not Target:IsInMeleeRange(8), nil, nil, M.RakeMouseover) then return "rake aoe 10"; end
  end
  -- lunar_inspiration,target_if=max:((ticks_gained_on_refresh+1)-(spell_targets.swipe_cat*2.492))
  if S.LIMoonfire:IsCastable() then
    if Everyone.CastCycle(S.LIMoonfire, Enemies11y, EvaluateCycleLIMoonfireAoe, not Target:IsSpellInRange(S.LIMoonfire), nil, nil, M.MoonfireMouseover) then return "lunar_inspiration aoe 12"; end
  end
  -- swipe_cat
  if S.Swipe:IsReady() then
    if Press(S.Swipe, not Target:IsInMeleeRange(11)) then return "swipe aoe 14"; end
  end
  -- shred,if=action.shred.damage>action.thrash_cat.damage
  if S.Shred:IsReady() and (S.Shred:Damage() > S.Thrash:Damage()) then
    if Press(S.Shred, not Target:IsInMeleeRange(8)) then return "shred aoe 16"; end
  end
  -- thrash_cat
  if S.Thrash:IsReady() then
    if Press(S.Thrash, not Target:IsInMeleeRange(11)) then return "thrash aoe 18"; end
  end
end

local function APL()
  -- Update Enemies
  if AoEON() then
    EnemiesMelee = Player:GetEnemiesInMeleeRange(8)
    Enemies11y = Player:GetEnemiesInMeleeRange(11)
    EnemiesCountMelee = #EnemiesMelee
    EnemiesCount11y = #Enemies11y
  else
    EnemiesMelee = {}
    Enemies11y = {}
    EnemiesCountMelee = 1
    EnemiesCount11y = 1
  end

  -- Combo Points
  ComboPoints = Player:ComboPoints()
  ComboPointsDeficit = Player:ComboPointsDeficit()

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies11y, false)
    end
  end

  -- cat_form OOC, if setting is true
  if S.CatForm:IsCastable() and Settings.Feral.Enabled.CatFormOOC then
    if Press(S.CatForm) then return "cat_form ooc"; end
  end
  
  if not Player:AffectingCombat() then
    -- Manually added: Group buff check
    if S.MarkOfTheWild:IsCastable() and (Player:BuffDown(S.MarkOfTheWild, true) or Everyone.GroupBuffMissing(S.MarkOfTheWild)) then
      if Press(M.MarkOfTheWildPlayer) then return "mark_of_the_wild precombat"; end
    end
  end

  if Everyone.TargetIsValid() and not Player:IsChanneling() then
    -- Precombat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- Explosives
    if Settings.General.Enabled.HandleExplosives then
      local ShouldReturn = Everyone.HandleExplosive(S.Rake, M.RakeMouseover, 8); if ShouldReturn then return ShouldReturn; end
    end
    -- Interrupts
    if not Player:IsCasting() and not Player:IsChanneling() then
      local ShouldReturn = Everyone.Interrupt(S.SkullBash, 10, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.Interrupt(S.SkullBash, 10, true, Mouseover, M.SkullBashMouseover); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.MightyBash, 8); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.IncapacitatingRoar, 8); if ShouldReturn then return ShouldReturn; end
    end
    -- Dispels
    if Settings.General.Enabled.DispelBuffs and S.Soothe:IsReady() and not Player:IsCasting() and not Player:IsChanneling() and Everyone.UnitHasEnrageBuff(Target) then
      if Press(S.Soothe, not Target:IsInMeleeRange(8)) then return "dispel"; end
    end
    -- prowl
    if S.Prowl:IsCastable() then
      if Press(S.Prowl) then return "prowl main 2"; end
    end
    -- Defensive
    if Player:AffectingCombat() then
      -- natures_vigil
      if Player:HealthPercentage() <= Settings.Feral.HP.NaturesVigil and S.NaturesVigil:IsReady() then
        if Press(S.NaturesVigil, nil, nil, true) then return "natures_vigil defensive 2"; end
      end
      -- renewal
      if Player:HealthPercentage() <= Settings.Feral.HP.Renewal and S.Renewal:IsReady() then
        if Press(S.Renewal, nil, nil, true) then return "renewal defensive 2"; end
      end
      -- barkskin
      if Player:HealthPercentage() <= Settings.Feral.HP.Barkskin and S.Barkskin:IsReady() then
        if Press(S.Barkskin, nil, nil, true) then return "barkskin defensive 2"; end
      end
      -- healthstone
      if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
        if Press(M.Healthstone, nil, nil, true) then return "healthstone defensive 4"; end
      end
      if Player:BuffUp(S.BearForm) then return; end
    end
    -- invoke_external_buff,name=power_infusion,if=buff.bs_inc.up|fight_remains<cooldown.bs_inc.remains
    -- Note: We're not handling external buffs
    -- variable,name=need_bt,value=talent.bloodtalons.enabled&buff.bloodtalons.down
    VarNeedBT = (S.Bloodtalons:IsAvailable() and Player:BuffDown(S.BloodtalonsBuff))
    -- tigers_fury
    if S.TigersFury:IsCastable() and CDsON() then
      if Press(S.TigersFury, not Target:IsInMeleeRange(8)) then return "tigers_fury main 4"; end
    end
    -- rake,if=buff.prowl.up|buff.shadowmeld.up
    if S.Rake:IsReady() and (Player:StealthUp(false, true)) then
      if Press(S.Rake, not Target:IsInMeleeRange(8)) then return "rake main 6"; end
    end
    -- cat_form,if=!buff.cat_form.up
    if S.CatForm:IsCastable() then
      if Press(S.CatForm) then return "cat_form main 8"; end
    end
    -- auto_attack,if=!buff.prowl.up&!buff.shadowmeld.up
    -- call_action_list,name=cooldown
    if CDsON() then
      local ShouldReturn = Cooldown(); if ShouldReturn then return ShouldReturn; end
    end
    -- adaptive_swarm,target_if=((!dot.adaptive_swarm_damage.ticking|dot.adaptive_swarm_damage.remains<2)&(dot.adaptive_swarm_damage.stack<3|!dot.adaptive_swarm_heal.stack>1)&!action.adaptive_swarm_heal.in_flight&!action.adaptive_swarm_damage.in_flight&!action.adaptive_swarm.in_flight)&target.time_to_die>5|active_enemies>2&!dot.adaptive_swarm_damage.ticking&energy<35&target.time_to_die>5
    if S.AdaptiveSwarm:IsReady() then
      if Everyone.CastCycle(S.AdaptiveSwarm, Enemies11y, EvaluateCycleAdaptiveSwarm, not Target:IsSpellInRange(S.AdaptiveSwarm), nil, nil, M.AdaptiveSwarmMouseover) then return "adaptive_swarm main 8"; end
    end
    -- feral_frenzy,if=combo_points<2|combo_points=2&buff.bs_inc.up
    if S.FeralFrenzy:IsReady() and (ComboPoints < 2 or ComboPoints == 2 and Player:BuffUp(BsInc)) then
      if Press(S.FeralFrenzy, not Target:IsInMeleeRange(8)) then return "feral_frenzy main 12"; end
    end
    -- run_action_list,name=aoe,if=spell_targets.swipe_cat>1&talent.primal_wrath.enabled
    if (EnemiesCount11y > 1 and S.PrimalWrath:IsAvailable()) then
      local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
      if Press(S.Pool) then return "Pool for Aoe()"; end
    end
    -- ferocious_bite,if=buff.apex_predators_craving.up
    if S.FerociousBite:IsReady() and (Player:BuffUp(S.ApexPredatorsCravingBuff)) then
      if Press(S.FerociousBite, not Target:IsInMeleeRange(8)) then return "ferocious_bite main 10"; end
    end
    -- call_action_list,name=bloodtalons,if=variable.need_bt&!buff.bs_inc.up
    if (VarNeedBT and Player:BuffDown(BsInc)) then
      local ShouldReturn = Bloodtalons(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=finisher,if=combo_points=5
    if (ComboPoints == 5) then
      local ShouldReturn = Finisher(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=berserk_builders,if=combo_points<5&buff.bs_inc.up
    if (ComboPoints < 5 and Player:BuffUp(BsInc)) then
      local ShouldReturn = BerserkBuilders(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=builder,if=combo_points<5
    if (ComboPoints < 5) then
      local ShouldReturn = Builder(); if ShouldReturn then return ShouldReturn; end
    end
    -- Pool if nothing else to do
    if (true) then
      if Press(S.Pool) then return "Pool Energy"; end
    end
  end
end

local function AutoBind()
  -- Bind Spells
  Bind(S.AdaptiveSwarm)
  Bind(S.Barkskin)
  Bind(S.Berserking)
  Bind(S.Berserk)
  Bind(S.BearForm)
  Bind(S.BrutalSlash)
  Bind(S.CatForm)
  Bind(S.ConvokeTheSpirits)
  Bind(S.FerociousBite)
  Bind(S.FeralFrenzy)
  Bind(S.HeartOfTheWild)
  Bind(S.Incarnation)
  Bind(S.IncapacitatingRoar)
  Bind(S.NaturesVigil)
  Bind(S.MightyBash)
  Bind(S.Moonfire)
  Bind(S.MoonkinForm)
  Bind(S.PrimalWrath)
  Bind(S.Prowl)
  Bind(S.Rake)
  Bind(S.Renewal)
  Bind(S.Rip)
  Bind(S.Rebirth)
  Bind(S.Revive)
  Bind(S.Shred)
  Bind(S.Sunfire)
  Bind(S.StampedingRoar)
  Bind(S.SkullBash)
  Bind(S.Soothe)
  Bind(S.TigersFury)
  Bind(S.Thrash)
  Bind(S.Typhoon)
  Bind(S.WildCharge)
  -- Macros
  Bind(M.AdaptiveSwarmMouseover)
  Bind(M.RakeMouseover)
  Bind(M.RipMouseover)
  Bind(M.PrimalWrathMouseover)
  Bind(M.MarkOfTheWildPlayer)
  Bind(M.MoonfireMouseover)
  Bind(M.SkullBashMouseover)
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
end

local function OnInit()
  S.Rip:RegisterAuraTracking()
  WR.Print("Feral Druid by Worldy.")
  AutoBind()
end

WR.SetAPL(103, APL, OnInit)
