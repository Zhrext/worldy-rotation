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
local MultiSpell = HL.MultiSpell
local Item       = HL.Item
-- WorldyRotation
local WR         = WorldyRotation
local Cast       = WR.Cast
local CDsON      = WR.CDsON
local AoEON      = WR.AoEON
local Press      = WR.Press
local Macro      = WR.Macro
local Bind       = WR.Bind
local Mage       = WR.Commons.Mage
-- Num/Bool Helper Functions
local num        = WR.Commons.Everyone.num
local bool       = WR.Commons.Everyone.bool
-- lua
local max        = math.max

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.Mage.Frost
local I = Item.Mage.Frost
local M = Macro.Mage.Frost

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
}

-- Rotation Var
local EnemiesCount8ySplash, EnemiesCount16ySplash --Enemies arround target
local EnemiesCount15yMelee  --Enemies arround player
local Enemies16ySplash
local var_snowstorm_max_stack = 30
local BossFightRemains = 11111
local FightRemains = 11111

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Mage.Commons,
  Frost = WR.GUISettings.APL.Mage.Frost
}

S.FrozenOrb:RegisterInFlightEffect(84721)
S.FrozenOrb:RegisterInFlight()
HL:RegisterForEvent(function() S.FrozenOrb:RegisterInFlight() end, "LEARNED_SPELL_IN_TAB")
S.Frostbolt:RegisterInFlightEffect(228597)--also register hitting spell to track in flight (spell book id ~= hitting id)
S.Frostbolt:RegisterInFlight()
S.Flurry:RegisterInFlightEffect(228354)
S.Flurry:RegisterInFlight()
S.IceLance:RegisterInFlightEffect(228598)
S.IceLance:RegisterInFlight()

HL:RegisterForEvent(function()
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

local function FrozenRemains()
  return max(Target:DebuffRemains(S.Frostbite), Target:DebuffRemains(S.Freeze), Target:DebuffRemains(S.FrostNova))
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- summon_water_elemental
  if S.SummonWaterElemental:IsCastable() then
    if Press(S.SummonWaterElemental, nil, true) then return "summon_water_elemental"; end
  end
  -- snapshot_stats
  if Everyone.TargetIsValid() then
    -- blizzard,if=active_enemies>=2
    -- TODO precombat active_enemies
    -- frostbolt,if=active_enemies=1
    if S.Frostbolt:IsCastable() and not Player:IsCasting(S.Frostbolt) then
      if Press(S.Frostbolt, not Target:IsSpellInRange(S.Frostbolt), true) then return "frostbolt"; end
    end
  end
end

local function Trinkets()
  local Trinket1ToUse = Player:GetUseableItems(OnUseExcludes, 13)
  if Trinket1ToUse then
    if Press(M.Trinket1, nil, nil, true) then return "trinket1 trinkets 2"; end
  end
  local Trinket2ToUse = Player:GetUseableItems(OnUseExcludes, 14)
  if Trinket2ToUse then
    if Press(M.Trinket2, nil, nil, true) then return "trinket2 trinkets 4"; end
  end
end

local function Cooldowns()
  -- time_warp,if=buff.exhaustion.up&buff.bloodlust.down
  -- potion,if=prev_off_gcd.icy_veins|fight_remains<60
  -- icy_veins,if=buff.rune_of_power.down&(buff.icy_veins.down|talent.rune_of_power)
  if S.IcyVeins:IsCastable() and (Player:BuffDown(S.RuneofPowerBuff) and (Player:BuffDown(S.IcyVeinsBuff) or S.RuneofPower:IsAvailable())) then
    if Press(S.IcyVeins) then return "icy_veins cd 6"; end
  end
  -- rune_of_power,if=buff.rune_of_power.down&cooldown.icy_veins.remains>10
  if S.RuneofPower:IsCastable() and (S.IcyVeins:CooldownRemains() > 10 and Player:BuffDown(S.RuneofPowerBuff)) then
    if Press(S.RuneofPower, nil, true) then return "rune_of_power cd 8"; end
  end
  -- use_items
  if Settings.General.Enabled.Trinkets then
    local ShouldReturn = Trinkets(); if ShouldReturn then return ShouldReturn; end
  end
  -- invoke_external_buff,name=power_infusion,if=buff.power_infusion.down
  -- invoke_external_buff,name=blessing_of_summer,if=buff.blessing_of_summer.down
  -- Note: Not handling external buffs.
  -- blood_fury
  if S.BloodFury:IsCastable() then
    if Press(S.BloodFury, nil, nil, true) then return "blood_fury cd 10"; end
  end
  -- berserking
  if S.Berserking:IsCastable() then
    if Press(S.Berserking, nil, nil, true) then return "berserking cd 12"; end
  end
  -- lights_judgment
  if S.LightsJudgment:IsCastable() then
    if Press(S.LightsJudgment, not Target:IsSpellInRange(S.LightsJudgment)) then return "lights_judgment cd 14"; end
  end
  -- fireblood
  if S.Fireblood:IsCastable() then
    if Press(S.Fireblood, nil, nil, true) then return "fireblood cd 16"; end
  end
  -- ancestral_call
  if S.AncestralCall:IsCastable() then
    if Press(S.AncestralCall) then return "ancestral_call cd 18"; end
  end
end

local function Aoe()
  -- cone_of_cold,if=buff.snowstorm.stack=buff.snowstorm.max_stack&debuff.frozen.up&(prev_gcd.1.frost_nova|prev_gcd.1.ice_nova|prev_off_gcd.freeze)
  if S.ConeofCold:IsCastable() and (Player:BuffStackP(S.SnowstormBuff) == var_snowstorm_max_stack and FrozenRemains() > 0 and (Player:PrevGCDP(1, S.FrostNova) or Player:PrevGCDP(1, S.IceNova) or Player:PrevGCDP(1, S.Freeze))) then
    if Press(S.ConeofCold, not Target:IsInRange(12)) then return "cone_of_cold aoe 2"; end
  end
  -- frozen_orb
  if S.FrozenOrb:IsCastable() then
    if Press(S.FrozenOrb, not Target:IsInRange(18)) then return "frozen_orb aoe 4"; end
  end
  -- blizzard
  if S.Blizzard:IsCastable() and Target:GUID() == Mouseover:GUID() then
    if Press(M.BlizzardCursor, not Target:IsInRange(40), true) then return "blizzard aoe 6"; end
  end
  -- comet_storm
  if S.CometStorm:IsCastable() then
    if Press(S.CometStorm, not Target:IsSpellInRange(S.CometStorm)) then return "comet_storm aoe 8"; end
  end
  -- freeze,if=(target.level<level+3|target.is_add)&(!talent.snowstorm&debuff.frozen.down|cooldown.cone_of_cold.ready&buff.snowstorm.stack=buff.snowstorm.max_stack)
  if Pet:IsActive() and S.Freeze:IsReady() and (Target:Level() < Player:Level() + 3 and ((not S.Snowstorm:IsAvailable()) and FrozenRemains() == 0 or S.ConeofCold:CooldownUp() and Player:BuffStackP(S.SnowstormBuff) == var_snowstorm_max_stack)) then
    if Press(S.Freeze, not Target:IsSpellInRange(S.Freeze)) then return "freeze aoe 10"; end
  end
  -- ice_nova,if=(target.level<level+3|target.is_add)&(prev_gcd.1.comet_storm|cooldown.cone_of_cold.ready&buff.snowstorm.stack=buff.snowstorm.max_stack&gcd.max<1)
  if S.IceNova:IsCastable() and (Target:Level() < Player:Level() + 3 and (Player:PrevGCDP(1, S.CometStorm) or S.ConeofCold:CooldownUp() and Player:BuffStackP(S.SnowstormBuff) == var_snowstorm_max_stack and Player:GCD() < 1)) then
    if Press(S.IceNova, not Target:IsSpellInRange(S.IceNova)) then return "ice_nova aoe 11"; end
  end
  -- frost_nova,if=(target.level<level+3|target.is_add)&active_enemies>=5&cooldown.cone_of_cold.ready&buff.snowstorm.stack=buff.snowstorm.max_stack&gcd.max<1
  if S.FrostNova:IsCastable() and (Target:Level() < Player:Level() + 3 and (EnemiesCount16ySplash >= 5 and S.ConeofCold:CooldownUp() and Player:BuffStackP(S.SnowstormBuff) == var_snowstorm_max_stack and Player:GCD() < 1)) then
    if Press(S.FrostNova, not Target:IsInRange(12)) then return "frost_nova aoe 12"; end
  end
  -- cone_of_cold,if=buff.snowstorm.stack=buff.snowstorm.max_stack
  if S.ConeofCold:IsCastable() and (Player:BuffStackP(S.SnowstormBuff) == var_snowstorm_max_stack) then
    if Press(S.ConeofCold, not Target:IsInRange(12)) then return "cone_of_cold aoe 14"; end
  end
  -- flurry,if=cooldown_react&remaining_winters_chill=0&debuff.winters_chill.down&(prev_gcd.1.frostbolt|(active_enemies>=7|charges=max_charges)&buff.fingers_of_frost.react=0)
  if S.Flurry:IsCastable() and (Target:DebuffDown(S.WintersChillDebuff) and (Player:PrevGCDP(1, S.Frostbolt) or (EnemiesCount16ySplash >= 7 or S.Flurry:Charges() == S.Flurry:MaxCharges()) and Player:BuffDown(S.FingersofFrostBuff))) then
    if Press(S.Flurry, not Target:IsSpellInRange(S.Flurry)) then return "flurry aoe 16"; end
  end
  -- ice_lance,if=buff.fingers_of_frost.react|debuff.frozen.remains>travel_time|remaining_winters_chill
  if S.IceLance:IsCastable() and (Player:BuffUp(S.FingersofFrostBuff) or FrozenRemains() > S.IceLance:TravelTime() or Target:DebuffStack(S.WintersChillDebuff) > 0) then
    if Press(S.IceLance, not Target:IsSpellInRange(S.IceLance)) then return "ice_lance aoe 18"; end
  end
  -- shifting_power
  if S.ShiftingPower:IsCastable() and CDsON() then
    if Press(S.ShiftingPower, not Target:IsInRange(18), true) then return "shifting_power aoe 20"; end
  end
  -- ice_nova
  if S.IceNova:IsCastable() then
    if Press(S.IceNova, not Target:IsSpellInRange(S.IceNova)) then return "ice_nova aoe 22"; end
  end
  -- meteor
  if S.Meteor:IsCastable() then
    if Press(S.Meteor, not Target:IsInRange(40), true) then return "meteor aoe 24"; end
  end
  -- dragons_breath,if=active_enemies>=7
  if S.DragonsBreath:IsCastable() and (EnemiesCount16ySplash >= 7) then
    if Press(S.DragonsBreath, not Target:IsInRange(12)) then return "dragons_breath aoe 26"; end
  end
  -- arcane_explosion,if=mana.pct>30&active_enemies>=7
  if S.ArcaneExplosion:IsCastable() and (Player:ManaPercentage() > 30 and EnemiesCount16ySplash >= 7) then
    if Press(S.ArcaneExplosion, not Target:IsInRange(10)) then return "arcane_explosion aoe 28"; end
  end
  -- ebonbolt
  if S.Ebonbolt:IsCastable() and (EnemiesCount8ySplash >= 2) then
    if Press(S.Ebonbolt, not Target:IsSpellInRange(S.Ebonbolt), true) then return "ebonbolt aoe 30"; end
  end
  -- frostbolt
  if S.Frostbolt:IsCastable() then
    if Press(S.Frostbolt, not Target:IsSpellInRange(S.Frostbolt), true) then return "frostbolt aoe 32"; end
  end
  -- Manually added: ice_lance as a fallthrough when MovingRotation is true
  if S.IceLance:IsCastable() then
    if Press(S.IceLance, not Target:IsSpellInRange(S.IceLance)) then return "ice_lance aoe 34"; end
  end
end

local function Single()
  -- meteor,if=prev_gcd.1.flurry
  if S.Meteor:IsCastable() and Player:PrevGCDP(1, S.Flurry) then
    if Press(S.Meteor, not Target:IsSpellInRange(S.Meteor)) then return "meteor single 2"; end
  end
  -- comet_storm,if=prev_gcd.1.flurry
  if S.CometStorm:IsCastable() and Player:PrevGCDP(1, S.Flurry) then
    if Press(S.CometStorm, not Target:IsSpellInRange(S.CometStorm)) then return "comet_storm single 4"; end
  end
  -- flurry,if=cooldown_react&remaining_winters_chill=0&debuff.winters_chill.down&(prev_gcd.1.frostbolt|prev_gcd.1.glacial_spike)
  if S.Flurry:IsCastable() and (Target:DebuffDown(S.WintersChillDebuff) and (Player:IsCasting(S.Ebonbolt) or Player:IsCasting(S.Frostbolt))) then
    if Press(S.Flurry, not Target:IsSpellInRange(S.Flurry)) then return "flurry single 6"; end
  end
  -- ray_of_frost,if=remaining_winters_chill=1&buff.freezing_winds.down
  if S.RayofFrost:IsCastable() and (Target:DebuffStack(S.WintersChillDebuff) == 1 and Player:BuffDown(S.FreezingWindsBuff)) then
    if Press(S.RayofFrost, not Target:IsSpellInRange(S.RayofFrost)) then return "ray_of_frost single 8"; end
  end
  -- glacial_spike,if=remaining_winters_chill
  if S.GlacialSpike:IsReady() and (Target:DebuffUp(S.WintersChillDebuff)) then
    if Press(S.GlacialSpike, not Target:IsSpellInRange(S.GlacialSpike), true) then return "glacial_spike single 10"; end
  end
  -- cone_of_cold,if=buff.snowstorm.stack=buff.snowstorm.max_stack&remaining_winters_chill
  if S.ConeofCold:IsCastable() and (Player:BuffStackP(S.SnowstormBuff) == var_snowstorm_max_stack and Target:DebuffUp(S.WintersChillDebuff)) then
    if Press(S.ConeofCold, not Target:IsInRange(12)) then return "cone_of_cold single 12"; end
  end
  -- frozen_orb
  if S.FrozenOrb:IsCastable() then
    if Press(S.FrozenOrb, not Target:IsInRange(18)) then return "frozen_orb single 14"; end
  end
  -- blizzard,if=active_enemies>=2&talent.ice_caller&talent.freezing_rain
  if S.Blizzard:IsCastable() and EnemiesCount16ySplash >= 2 and S.IceCaller:IsAvailable() and S.FreezingRain:IsAvailable() and Target:GUID() == Mouseover:GUID() then
    if Press(M.BlizzardCursor, not Target:IsInRange(40), true) then return "blizzard single 16"; end
  end
  -- shifting_power,if=buff.rune_of_power.down
  if S.ShiftingPower:IsCastable() and Player:BuffDown(S.RuneofPowerBuff) then
    if Press(S.ShiftingPower, not Target:IsInRange(18), true) then return "shifting_power single 18"; end
  end
  -- ice_lance,if=buff.fingers_of_frost.react&!prev_gcd.1.glacial_spike|remaining_winters_chill
  if S.IceLance:IsCastable() and (Player:BuffUpP(S.FingersofFrostBuff) and not Player:IsCasting(S.GlacialSpike) or Target:DebuffUp(S.WintersChillDebuff)) then
    if Press(S.IceLance, not Target:IsSpellInRange(S.IceLance)) then return "ice_lance single 20"; end
  end
  -- ice_nova,if=active_enemies>=4
  if S.IceNova:IsCastable() and (EnemiesCount16ySplash >= 4) then
    if Press(S.IceNova, not Target:IsSpellInRange(S.IceNova)) then return "ice_nova single 22"; end
  end
  -- glacial_spike,if=buff.brain_freeze.react
  if S.GlacialSpike:IsCastable() and Player:BuffUp(S.BrainFreezeBuff) then
    if Press(S.GlacialSpike, not Target:IsSpellInRange(S.GlacialSpike)) then return "glacial_spike single 34"; end
  end
  -- ebonbolt,if=cooldown.flurry.charges_fractional<1
  if S.Ebonbolt:IsCastable() and S.Flurry:Charges() < 1 then
    if Press(S.Ebonbolt, not Target:IsSpellInRange(S.Ebonbolt)) then return "ebonbolt single 36"; end
  end
  if CDsON() then
    -- bag_of_tricks
    if S.BagofTricks:IsCastable() then
      if Press(S.BagofTricks, not Target:IsSpellInRange(S.BagofTricks)) then return "bag_of_tricks cd 40"; end
    end
  end
  -- frostbolt
  if S.Frostbolt:IsCastable() then
    if Press(S.Frostbolt, not Target:IsSpellInRange(S.Frostbolt), true) then return "frostbolt single 42"; end
  end
  -- Manually added: ice_lance as a fallthrough when MovingRotation is true
end

local function Movement()
  -- ice_floes,if=buff.ice_floes.down
  if S.IceFloes:IsCastable() and Player:BuffDown(S.IceFloes) then
    if Press(S.IceFloes) then return "ice_floes movement"; end
  end
  -- ice_nova
  if S.IceNova:IsCastable() then
    if Press(S.IceNova, not Target:IsSpellInRange(S.IceNova)) then return "ice_nova movement"; end
  end
  -- arcane_explosion,if=mana.pct>30&active_enemies>=2
  if S.ArcaneExplosion:IsCastable() and (Player:ManaPercentage() > 30 and EnemiesCount16ySplash >= 2) then
    if Press(S.ArcaneExplosion, not Target:IsInRange(10)) then return "arcane_explosion movement"; end
  end
  -- fire_blast
  if S.FireBlast:IsCastable() then
    if Press(S.FireBlast, not Target:IsSpellInRange(S.FireBlast)) then return "fire_blast movement"; end
  end
  -- ice_lance
  if S.IceLance:IsCastable() then
    if Press(S.IceLance, not Target:IsSpellInRange(S.IceLance)) then return "ice_lance movement"; end
  end
end

--- ======= ACTION LISTS =======
local function APL()
  -- Enemies Update
  Enemies16ySplash = Target:GetEnemiesInSplashRange(16)
  if AoEON() then
    EnemiesCount8ySplash = Target:GetEnemiesInSplashRangeCount(8)
    EnemiesCount16ySplash = Target:GetEnemiesInSplashRangeCount(16)
  else
    EnemiesCount15yMelee = 1
    EnemiesCount8ySplash = 1
    EnemiesCount16ySplash = 1
  end

  if not Player:AffectingCombat() then
    -- arcane_intellect
    if S.ArcaneIntellect:IsCastable() and (Player:BuffDown(S.ArcaneIntellect, true) or Everyone.GroupBuffMissing(S.ArcaneIntellect)) then
      if Press(M.ArcaneIntellectPlayer) then return "arcane_intellect"; end
    end
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies16ySplash, false)
    end
  end

  -- call precombat
  if not Player:AffectingCombat() then
    local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
  end
  if Everyone.TargetIsValid() then
    -- Interrupts
    if not Player:IsCasting() and not Player:IsChanneling() then
      local ShouldReturn = Everyone.Interrupt(S.Counterspell, 40, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.Interrupt(S.Counterspell, 40, true, Mouseover, M.CounterspellMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- Defensives
    -- ice_block
    if S.IceBlock:IsCastable() and Player:HealthPercentage() <= Settings.Commons.HP.IceBlock then
      if Press(S.IceBlock) then return "IceBlock"; end
    end
    -- ice_barrier
    if S.IceBarrier:IsCastable() and Player:BuffDown(S.IceBarrier) and Player:HealthPercentage() <= Settings.Frost.HP.IceBarrier then
      if Press(S.IceBarrier) then return "IceBarrier"; end
    end
    -- healthstone
    if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
      if Press(M.Healthstone, nil, nil, true) then return "healthstone"; end
    end
    -- water_jet,if=cooldown.flurry.charges_fractional<1
    if Pet:IsActive() and S.WaterJet:IsReady() and (S.Flurry:ChargesFractional() < 1) then
      if Press(S.WaterJet, not Target:IsSpellInRange(S.WaterJet)) then return "water_jet main 2"; end
    end
    -- call_action_list,name=cds
    if CDsON() then
      local ShouldReturn = Cooldowns(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=aoe,if=active_enemies>=7|active_enemies>=3&talent.ice_caller
    if AoEON() and (EnemiesCount16ySplash >= 7 or EnemiesCount16ySplash >= 3 and S.IceCaller:IsAvailable()) then
      local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=single,if=active_enemies<7&(active_enemies<3|!talent.ice_caller)
    if (not AoEON()) or (EnemiesCount16ySplash < 7 and (EnemiesCount16ySplash < 3 or not S.IceCaller:IsAvailable())) then
      local ShouldReturn = Single(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=movement
    local ShouldReturn = Movement(); if ShouldReturn then return ShouldReturn; end
  end
end

local function AutoBind()
  -- Spells
  Bind(S.ArcaneExplosion)
  Bind(S.ArcaneIntellect)
  Bind(S.BagofTricks)
  Bind(S.BloodFury)
  Bind(S.Counterspell)
  Bind(S.CometStorm)
  Bind(S.ConeofCold)
  Bind(S.DragonsBreath)
  Bind(S.Ebonbolt)
  Bind(S.Fireblood)
  Bind(S.FireBlast)
  Bind(S.Freeze)
  Bind(S.Frostbolt)
  Bind(S.FrozenOrb)
  Bind(S.Flurry)
  Bind(S.GlacialSpike)
  Bind(S.IceBarrier)
  Bind(S.IceBlock)
  Bind(S.IceLance)
  Bind(S.IceFloes)
  Bind(S.IceNova)
  Bind(S.IcyVeins)
  Bind(S.Meteor)
  Bind(S.ShiftingPower)
  Bind(S.SummonWaterElemental)
  Bind(S.RayofFrost)
  Bind(S.RuneofPower)
  Bind(M.ArcaneIntellectPlayer)
  Bind(M.BlizzardCursor)
  Bind(M.CounterspellMouseover)
  Bind(M.IceLanceMouseover)
  -- Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
end

local function Init()
  WR.Print("Frost Mage rotation by Worldy.")
  AutoBind()
end

WR.SetAPL(64, APL, Init)
