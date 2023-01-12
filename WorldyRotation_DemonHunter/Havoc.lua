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
local Bind          = WR.Bind
local CDsON         = WR.CDsON
local Cast          = WR.Cast
local CastSuggested = WR.CastSuggested
local Press         = WR.Press
local Macro         = WR.Macro
-- Commons
local Everyone      = WR.Commons.Everyone
-- Num/Bool Helper Functions
local num           = Everyone.num
local bool          = Everyone.bool
-- lua
local mathmin       = math.min

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.DemonHunter.Havoc
local I = Item.DemonHunter.Havoc
local M = Macro.DemonHunter.Havoc

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  -- I.TrinketName:ID(),
}

-- Trinket Item Objects
local equip = Player:GetEquipment()
local trinket1 = equip[13] and Item(equip[13]) or Item(0)
local trinket2 = equip[14] and Item(equip[14]) or Item(0)

-- Rotation Var
local Enemies8y, Enemies20y
local EnemiesCount8, EnemiesCount20

-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.DemonHunter.Commons,
  Havoc = WR.GUISettings.APL.DemonHunter.Havoc
}

-- Interrupts List
local StunInterrupts = {
  {S.FelEruption},
  {S.ChaosNova},
}

-- Variables
local VarBladeDance = false
local VarPoolingForBladeDance = false
local VarPoolingForEyeBeam = false
local VarWaitingForEssenceBreak = false
local VarWaitingForMomentum = false
local VarTrinketSyncSlot = 0
local VarUseEyeBeamFuryCondition = false
local BossFightRemains = 11111
local FightRemains = 11111

HL:RegisterForEvent(function()
  VarBladeDance = false
  VarPoolingForBladeDance = false
  VarPoolingForEyeBeam = false
  VarWaitingForEssenceBreak = false
  VarWaitingForMomentum = false
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

HL:RegisterForEvent(function()
  equip = Player:GetEquipment()
  trinket1 = equip[13] and Item(equip[13]) or Item(0)
  trinket2 = equip[14] and Item(equip[14]) or Item(0)
end, "PLAYER_EQUIPMENT_CHANGED")

-- Functions
local function IsInMeleeRange(range)
  if S.Felblade:TimeSinceLastCast() <= Player:GCD() then
    return true
  elseif S.VengefulRetreat:TimeSinceLastCast() < 1.0 then
    return false
  end
  return range and Target:IsInMeleeRange(range) or Target:IsInMeleeRange(5)
end

local function EvalutateTargetIfFilterDemonsBite(TargetUnit)
  -- target_if=min:debuff.burning_wound.remains
  return TargetUnit:DebuffRemains(S.BurningWoundDebuff) or TargetUnit:DebuffRemains(S.BurningWoundLegDebuff)
end

local function EvaluateTargetIfDemonsBite(TargetUnit)
  -- if=talent.burning_wound&debuff.burning_wound.remains<4&active_dot.burning_wound<(spell_targets>?3)
  return S.BurningWound:IsAvailable() and TargetUnit:DebuffRemains(S.BurningWoundDebuff) < 4 and S.BurningWoundDebuff:AuraActiveCount() < mathmin(EnemiesCount8, 3)
end

local function Precombat()
  -- flask
  -- augmentation
  -- food
  -- snapshot_stats
  VarTrinketSyncSlot = 0
  -- variable,name=trinket_sync_slot,value=1,if=trinket.1.has_stat.any_dps&(!trinket.2.has_stat.any_dps|trinket.1.cooldown.duration>=trinket.2.cooldown.duration)
  if (trinket1:TrinketHasStatAnyDps() and ((not trinket2:TrinketHasStatAnyDps()) or trinket1:Cooldown() >= trinket2:Cooldown())) then
    VarTrinketSyncSlot = 1
  end
  -- variable,name=trinket_sync_slot,value=2,if=trinket.2.has_stat.any_dps&(!trinket.1.has_stat.any_dps|trinket.2.cooldown.duration>trinket.1.cooldown.duration)
  if (trinket2:TrinketHasStatAnyDps() and ((not trinket1:TrinketHasStatAnyDps()) or trinket2:Cooldown() >= trinket1:Cooldown())) then
    VarTrinketSyncSlot = 2
  end
  -- arcane_torrent
  if CDsON() and S.ArcaneTorrent:IsCastable() then
    if Press(S.ArcaneTorrent, not Target:IsInRange(8)) then return "arcane_torrent precombat 2"; end
  end
  -- use_item,name=algethar_puzzle_box
  if CDsON() and Settings.General.Enabled.Trinkets and I.AlgetharPuzzleBox:IsEquippedAndReady() then
    if Press(I.AlgetharPuzzleBox) then return "algethar_puzzle_box precombat 4"; end
  end
  -- sigil_of_flame
  if S.SigilOfFlame:IsCastable() then
    if Press(M.SigilOfFlamePlayer, not Target:IsInMeleeRange(8)) then return "sigil_of_flame precombat 6"; end
  end
  -- immolation_aura
  if S.ImmolationAura:IsCastable() then
    if Press(S.ImmolationAura, not Target:IsInMeleeRange(8)) then return "immolation_aura precombat 8"; end
  end
  -- Manually added: Fel Rush if out of range
  if (not Target:IsInMeleeRange(5)) and S.FelRush:IsCastable() and Settings.Havoc.Enabled.FelRush then
    if Press(S.FelRush, not Target:IsInRange(8)) then return "fel_rush precombat 10"; end
  end
  -- Manually added: Demon's Bite/Demon Blades if in melee range
  if Target:IsInMeleeRange(5) and (S.DemonsBite:IsCastable() or S.DemonBlades:IsAvailable()) then
    if Press(S.DemonsBite, not Target:IsInMeleeRange(5)) then return "demons_bite or demon_blades precombat 12"; end
  end
end

local function Cooldown()
  -- metamorphosis,if=!talent.demonic&((!talent.chaotic_transformation|cooldown.eye_beam.remains>20)&active_enemies>desired_targets|raid_event.adds.in>60|fight_remains<25)
  if CDsON() and S.Metamorphosis:IsCastable() and (not S.Demonic:IsAvailable()) then
    if Press(M.MetamorphosisPlayer, not Target:IsInMeleeRange(5)) then return "metamorphosis cooldown 2"; end
  end
  -- metamorphosis,if=talent.demonic&(!talent.chaotic_transformation|cooldown.eye_beam.remains>20&(!variable.blade_dance|cooldown.blade_dance.remains>gcd.max)|fight_remains<25)
  if CDsON() and S.Metamorphosis:IsCastable() and (S.Demonic:IsAvailable() and ((not S.ChaoticTransformation:IsAvailable()) or S.EyeBeam:CooldownRemains() > 20 and ((not VarBladeDance) or S.BladeDance:CooldownRemains() > Player:GCD() + 0.5) or FightRemains < 25)) then
    if Press(M.MetamorphosisPlayer, not Target:IsInMeleeRange(5)) then return "metamorphosis cooldown 4"; end
  end
  if Settings.General.Enabled.Trinkets then
    -- use_items,slots=trinket1,if=variable.trinket_sync_slot=1&(buff.metamorphosis.up|(!talent.demonic.enabled&cooldown.metamorphosis.remains>(fight_remains>?trinket.1.cooldown.duration%2))|fight_remains<=20)|(variable.trinket_sync_slot=2&!trinket.2.cooldown.ready)|!variable.trinket_sync_slot
    local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
    if Trinket1ToUse and (VarTrinketSyncSlot == 1 and (Player:BuffUp(S.MetamorphosisBuff) or ((not S.Demonic:IsAvailable()) and S.Metamorphosis:CooldownRemains() > ((FightRemains > trinket1:Cooldown() / 2) and FightRemains or trinket1:Cooldown() / 2)) or FightRemains <= 20) or (VarTrinketSyncSlot == 2 and not trinket2:IsReady()) or VarTrinketSyncSlot == 0) then
      if Press(M.Trinket1, nil, nil, true) then return "trinket1 cooldown 14"; end
    end
    -- use_items,slots=trinket2,if=variable.trinket_sync_slot=2&(buff.metamorphosis.up|(!talent.demonic.enabled&cooldown.metamorphosis.remains>(fight_remains>?trinket.2.cooldown.duration%2))|fight_remains<=20)|(variable.trinket_sync_slot=1&!trinket.1.cooldown.ready)|!variable.trinket_sync_slot
    local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
    if Trinket2ToUse and (VarTrinketSyncSlot == 2 and (Player:BuffUp(S.MetamorphosisBuff) or ((not S.Demonic:IsAvailable()) and S.Metamorphosis:CooldownRemains() > ((FightRemains > trinket2:Cooldown() / 2) and FightRemains or trinket2:Cooldown() / 2)) or FightRemains <= 20) or (VarTrinketSyncSlot == 1 and not trinket1:IsReady()) or VarTrinketSyncSlot == 0) then
      if Press(M.Trinket2, nil, nil, true) then return "trinket2 cooldown 16"; end
    end
  end
  -- the_hunt,if=(!talent.momentum|!buff.momentum.up)
  if CDsON() and S.TheHunt:IsCastable() and ((not S.Momentum:IsAvailable()) or Player:BuffDown(S.MomentumBuff) or (not Settings.Havoc.Enabled.VengefulRetreat and not Settings.Havoc.Enabled.FelRush)) then
    if Press(S.TheHunt, not Target:IsSpellInRange(S.TheHunt)) then return "the_hunt cooldown 20"; end
  end
  -- elysian_decree,if=(active_enemies>desired_targets|raid_event.adds.in>30)
  if S.ElysianDecree:IsCastable() then
    if Press(S.ElysianDecree, not Target:IsInRange(30)) then return "elysian_decree cooldown 22"; end
  end
end

--- ======= ACTION LISTS =======
local function APL()
  if AoEON() then
    Enemies8y = Player:GetEnemiesInMeleeRange(8) -- Multiple Abilities
    Enemies20y = Player:GetEnemiesInMeleeRange(20) -- Eye Beam
    EnemiesCount8 = #Enemies8y
    EnemiesCount20 = #Enemies20y
  else
    EnemiesCount8 = 1
    EnemiesCount20 = 1
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies8y, false)
    end
  end

  if Everyone.TargetIsValid() then
    -- Precombat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- auto_attack
    -- retarget_auto_attack,line_cd=1,target_if=min:debuff.burning_wound.remains,if=talent.burning_wound&talent.demon_blades&active_dot.burning_wound<(spell_targets>?3)
    -- variable,name=blade_dance,value=talent.first_blood|talent.trail_of_ruin|talent.chaos_theory&buff.chaos_theory.down|spell_targets.blade_dance1>1
    VarBladeDance = (S.FirstBlood:IsAvailable() or S.TrailofRuin:IsAvailable() or S.ChaosTheory:IsAvailable() and Player:BuffDown(S.ChaosTheoryBuff) or EnemiesCount8 > 1)
    -- variable,name=pooling_for_blade_dance,value=variable.blade_dance&fury<(75-talent.demon_blades*20)&cooldown.blade_dance.remains<gcd.max
    VarPoolingForBladeDance = (VarBladeDance and Player:Fury() < (75 - num(S.DemonBlades:IsAvailable()) * 20) and S.BladeDance:CooldownRemains() < Player:GCD() + 0.5)
    -- variable,name=pooling_for_eye_beam,value=talent.demonic&!talent.blind_fury&cooldown.eye_beam.remains<(gcd.max*2)&fury.deficit>20
    VarPoolingForEyeBeam = S.Demonic:IsAvailable() and (not S.BlindFury:IsAvailable()) and S.EyeBeam:CooldownRemains() < (Player:GCD() * 2) and Player:FuryDeficit() > 20
    -- variable,name=waiting_for_momentum,value=talent.momentum&!buff.momentum.up
    VarWaitingForMomentum = S.Momentum:IsAvailable() and Player:BuffDown(S.MomentumBuff) and (Settings.Havoc.Enabled.FelRush or Settings.Havoc.Enabled.VengefulRetreat)
    -- Interrupts
    if not Player:IsCasting() and not Player:IsChanneling() then
      local ShouldReturn = Everyone.Interrupt(S.Disrupt, 10, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.FelEruption); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.ChaosNova); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=cooldown,if=gcd.remains=0
    if CDsON() then
      local ShouldReturn = Cooldown(); if ShouldReturn then return ShouldReturn; end
    end
    -- Manually added: Defensive Blur
    if S.Blur:IsCastable() and Player:HealthPercentage() <= Settings.Havoc.HP.Blur then
      if Press(S.Blur) then return "blur defensive"; end
    end
    -- healthstone
    if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
      if Press(M.Healthstone, nil, nil, true) then return "healthstone defensive"; end
    end
    -- pick_up_fragment,type=demon,if=demon_soul_fragments>0
    -- pick_up_fragment,mode=nearest,if=talent.demonic_appetite&fury.deficit>=35&(!cooldown.eye_beam.ready|fury<30)
    -- TODO: Can't detect when orbs actually spawn, we could possibly show a suggested icon when we DON'T want to pick up souls so people can avoid moving?
    -- vengeful_retreat,use_off_gcd=1,if=talent.initiative&talent.essence_break&time>1&(cooldown.essence_break.remains>15|cooldown.essence_break.remains<gcd.max&(!talent.demonic|buff.metamorphosis.up|cooldown.eye_beam.remains>15+(10*talent.cycle_of_hatred)))
    if Settings.Havoc.Enabled.VengefulRetreat and S.VengefulRetreat:IsCastable() and (S.Initiative:IsAvailable() and S.EssenceBreak:IsAvailable() and HL.CombatTime() > 1 and (S.EssenceBreak:CooldownRemains() > 15 or S.EssenceBreak:CooldownRemains() < Player:GCD() + 0.5 and ((not S.Demonic:IsAvailable()) or Player:BuffUp(S.MetamorphosisBuff) or S.EyeBeam:CooldownRemains() > 15 + (10 * num(S.CycleOfHatred:IsAvailable()))))) then
      if Press(S.VengefulRetreat, not Target:IsInMeleeRange(8)) then return "vengeful_retreat main 4"; end
    end
    -- vengeful_retreat,use_off_gcd=1,if=talent.initiative&!talent.essence_break&time>1&!buff.momentum.up
    if Settings.Havoc.Enabled.VengefulRetreat and S.VengefulRetreat:IsCastable() and (S.Initiative:IsAvailable() and (not S.EssenceBreak:IsAvailable()) and HL.CombatTime() > 1 and Player:BuffDown(S.MomentumBuff)) then
      if Press(S.VengefulRetreat, not Target:IsInMeleeRange(8)) then return "vengeful_retreat main 5"; end
    end
    -- fel_rush,if=(buff.unbound_chaos.up|variable.waiting_for_momentum&(!talent.unbound_chaos|!cooldown.immolation_aura.ready))&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
    if S.FelRush:IsCastable() and ((Player:BuffUp(S.UnboundChaosBuff) or VarWaitingForMomentum and ((not S.UnboundChaos:IsAvailable()) or S.ImmolationAura:CooldownDown())) and Settings.Havoc.Enabled.FelRush) then
      if Press(S.FelRush, not Target:IsInMeleeRange(8)) then return "fel_rush main 6"; end
    end
    -- essence_break,if=(active_enemies>desired_targets|raid_event.adds.in>40)&!variable.waiting_for_momentum&fury>40&(cooldown.eye_beam.remains>8|buff.metamorphosis.up)&(!talent.tactical_retreat|buff.tactical_retreat.up)
    if S.EssenceBreak:IsCastable() and ((not VarWaitingForMomentum) and Player:Fury() > 40 and (S.EyeBeam:CooldownRemains() > 8 or Player:BuffUp(S.MetamorphosisBuff)) and ((not S.TacticalRetreat:IsAvailable()) or Player:BuffUp(S.TacticalRetreatBuff) or not Settings.Havoc.Enabled.VengefulRetreat)) then
      if Press(S.EssenceBreak, not IsInMeleeRange(10)) then return "essence_break main 9"; end
    end
    -- death_sweep,if=variable.blade_dance&(!talent.essence_break|cooldown.essence_break.remains>(cooldown.death_sweep.duration-4))
    if S.DeathSweep:IsReady() and (VarBladeDance and ((not S.EssenceBreak:IsAvailable()) or S.EssenceBreak:CooldownRemains() > ((9 * Player:SpellHaste()) - 4))) then
      if Press(S.DeathSweep, not IsInMeleeRange(8)) then return "death_sweep main 10"; end
    end
    -- fel_barrage,if=active_enemies>desired_targets|raid_event.adds.in>30
    if S.FelBarrage:IsCastable() then
      if Press(S.FelBarrage, not IsInMeleeRange(8)) then return "fel_barrage main 12"; end
    end
    -- glaive_tempest,if=active_enemies>desired_targets|raid_event.adds.in>10
    if S.GlaiveTempest:IsReady() then
      if Press(S.GlaiveTempest) then return "glaive_tempest main 14"; end
    end
    -- eye_beam,if=active_enemies>desired_targets|raid_event.adds.in>(40-talent.cycle_of_hatred*15)&!debuff.essence_break.up
    if S.EyeBeam:IsReady() and (Target:DebuffDown(S.EssenceBreakDebuff)) then
      if Press(S.EyeBeam, not IsInMeleeRange(20)) then return "eye_beam main 18"; end
    end
    -- blade_dance,if=variable.blade_dance&(cooldown.eye_beam.remains>5|!talent.demonic|(raid_event.adds.in>cooldown&raid_event.adds.in<25))
    if S.BladeDance:IsReady() and (VarBladeDance and (S.EyeBeam:CooldownRemains() > 5 or not S.Demonic:IsAvailable())) then
      if Press(S.BladeDance, not IsInMeleeRange(8)) then return "blade_dance main 20"; end
    end
    -- throw_glaive,if=talent.soulrend&(active_enemies>desired_targets|raid_event.adds.in>full_recharge_time+9)&spell_targets>=(2-talent.furious_throws)&!debuff.essence_break.up
    if Target:AffectingCombat() and S.ThrowGlaive:IsCastable() and (S.Soulrend:IsAvailable() and EnemiesCount8 >= (2 - num(S.FuriousThrows)) and Target:DebuffDown(S.EssenceBreakDebuff)) then
      if Press(S.ThrowGlaive, not Target:IsSpellInRange(S.ThrowGlaive)) then return "throw_glaive main 22"; end
    end
    -- annihilation,if=!variable.pooling_for_blade_dance
    if S.Annihilation:IsReady() and (not VarPoolingForBladeDance) then
      if Press(S.Annihilation, not IsInMeleeRange(5)) then return "annihilation main 24"; end
    end
    -- throw_glaive,if=talent.serrated_glaive&cooldown.eye_beam.remains<4&!debuff.serrated_glaive.up&!debuff.essence_break.up
    if Target:AffectingCombat() and S.ThrowGlaive:IsCastable() and (S.SerratedGlaive:IsAvailable() and S.EyeBeam:CooldownRemains() < 4 and Target:DebuffDown(S.SerratedGlaiveDebuff) and Target:DebuffDown(S.EssenceBreakDebuff)) then
      if Press(S.ThrowGlaive, not Target:IsSpellInRange(S.ThrowGlaive)) then return "throw_glaive main 16"; end
    end
    -- immolation_aura,if=!buff.immolation_aura.up&(!talent.ragefire|active_enemies>desired_targets|raid_event.adds.in>15)
    if S.ImmolationAura:IsCastable() and (Player:BuffDown(S.ImmolationAuraBuff)) then
      if Press(S.ImmolationAura, not IsInMeleeRange(8)) then return "immolation_aura main 26"; end
    end
    -- felblade,if=fury.deficit>=40
    if S.Felblade:IsCastable() and (Player:FuryDeficit() >= 40) then
      if Press(S.Felblade, not Target:IsSpellInRange(S.Felblade)) then return "felblade main 28"; end
    end
    -- chaos_strike,if=!variable.pooling_for_blade_dance&!variable.pooling_for_eye_beam
    if S.ChaosStrike:IsReady() and ((not VarPoolingForBladeDance) and not VarPoolingForEyeBeam) then
      if Press(S.ChaosStrike, not Target:IsSpellInRange(S.ChaosStrike)) then return "chaos_strike main 32"; end
    end
    -- fel_rush,if=!talent.momentum&talent.demon_blades&!cooldown.eye_beam.ready&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
    if S.FelRush:IsCastable() and ((not S.Momentum:IsAvailable()) and S.DemonBlades:IsAvailable() and S.EyeBeam:CooldownDown() and Settings.Havoc.Enabled.FelRush) then
      if Press(S.FelRush, not Target:IsInMeleeRange(8)) then return "fel_rush main 34"; end
    end
    -- demons_bite,target_if=min:debuff.burning_wound.remains,if=talent.burning_wound&debuff.burning_wound.remains<4&active_dot.burning_wound<(spell_targets>?3)
    if S.DemonsBite:IsCastable() then
      if Everyone.CastTargetIf(S.DemonsBite, Enemies8y, "min", EvalutateTargetIfFilterDemonsBite, EvaluateTargetIfDemonsBite, not Target:IsSpellInRange(S.DemonsBite)) then return "demons_bite main 36"; end
    end
    -- fel_rush,if=!talent.momentum&!talent.demon_blades&spell_targets>1&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
    if S.FelRush:IsCastable() and ((not S.Momentum:IsAvailable()) and (not S.DemonBlades:IsAvailable()) and EnemiesCount8 > 1 and Settings.Havoc.Enabled.FelRush) then
      if Press(S.FelRush, not Target:IsInMeleeRange(8)) then return "fel_rush main 38"; end
    end
    -- sigil_of_flame,if=raid_event.adds.in>15&fury.deficit>=30
    if S.SigilOfFlame:IsCastable() and (Player:FuryDeficit() >= 30) then
      if Press(M.SigilOfFlamePlayer, not Target:IsInMeleeRange(8)) then return "sigil_of_flame main 40"; end
    end
    -- demons_bite
    if S.DemonsBite:IsCastable() then
      if Press(S.DemonsBite, not Target:IsSpellInRange(S.DemonsBite)) then return "demons_bite main 42"; end
    end
    -- fel_rush,if=movement.distance>15|(buff.out_of_range.up&!talent.momentum)
    if S.FelRush:IsCastable() and ((not IsInMeleeRange()) and (not S.Momentum:IsAvailable()) and Settings.Havoc.Enabled.FelRush) then
      if Press(S.FelRush, not Target:IsInMeleeRange(8)) then return "fel_rush main 46"; end
    end
    -- vengeful_retreat,if=!talent.initiative&movement.distance>15
    if Settings.Havoc.Enabled.VengefulRetreat and S.VengefulRetreat:IsCastable() and ((not S.Initiative:IsAvailable()) and (not IsInMeleeRange())) then
      if Press(S.VengefulRetreat, not Target:IsInMeleeRange(8)) then return "vengeful_retreat main 48"; end
    end
    -- throw_glaive,if=(talent.demon_blades.enabled|buff.out_of_range.up)&!debuff.essence_break.up
    if Target:AffectingCombat() and S.ThrowGlaive:IsCastable() and ((S.DemonBlades:IsAvailable() or not Target:IsInRange(12)) and Target:DebuffDown(S.EssenceBreakDebuff)) then
      if Press(S.ThrowGlaive, not Target:IsSpellInRange(S.ThrowGlaive)) then return "throw_glaive main 50"; end
    end
    -- Show pool icon if nothing else to do (should only happen when Demon Blades is used)
    if (S.DemonBlades:IsAvailable()) then
      if Press(S.Pool) then return "pool demon_blades"; end
    end
  end
end

local function AutoBind()
  -- Spell Binds
  Bind(S.ArcaneTorrent)
  Bind(S.Annihilation)
  Bind(S.BladeDance)
  Bind(S.Blur)
  Bind(S.ChaosStrike)
  Bind(S.DemonsBite)
  Bind(S.DeathSweep)
  Bind(S.Disrupt)
  Bind(S.EssenceBreak)
  Bind(S.EyeBeam)
  Bind(S.FelBarrage)
  Bind(S.Felblade)
  Bind(S.FelEruption)
  Bind(S.FelRush)
  Bind(S.GlaiveTempest)
  Bind(S.ImmolationAura)
  Bind(S.SigilOfFlame)
  Bind(S.ThrowGlaive)
  Bind(S.TheHunt)
  Bind(S.VengefulRetreat)
  
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  
  -- Macros
  Bind(M.MetamorphosisPlayer)
  Bind(M.SigilOfFlamePlayer)
  Bind(M.SigilOfMiseryPlayer)
end

local function Init()
  S.BurningWoundDebuff:RegisterAuraTracking()

  WR.Print("Havoc Demon Hunter by Worldy.")
  AutoBind()
end

WR.SetAPL(577, APL, Init)
