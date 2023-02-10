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
local Focus      = Unit.Focus
local Player     = Unit.Player
local Mouseover  = Unit.MouseOver
local Target     = Unit.Target
local Pet        = Unit.Pet
local Spell      = HL.Spell
local Item       = HL.Item
-- WorldyRotation
local WR         = WorldyRotation
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Cast       = WR.Cast
local Bind       = WR.Bind
local Macro      = WR.Macro
local Press      = WR.Press
-- Num/Bool Helper Functions
local num        = WR.Commons.Everyone.num
local bool       = WR.Commons.Everyone.bool
-- Lua
local stringformat = string.format

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.Paladin.Protection
local I = Item.Paladin.Protection
local M = Macro.Paladin.Protection

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
}

-- Rotation Var
local ActiveMitigationNeeded
local IsTanking
local Enemies8y, Enemies30y
local EnemiesCount8y, EnemiesCount30y

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Paladin.Commons,
  Protection = WR.GUISettings.APL.Paladin.Protection
}

local function EvaluateTargetIfFilterJudgment(TargetUnit)
  return TargetUnit:DebuffRemains(S.JudgmentDebuff)
end

local function MissingAura()
  return (Player:BuffDown(S.RetributionAura) and Player:BuffDown(S.DevotionAura) and Player:BuffDown(S.ConcentrationAura) and Player:BuffDown(S.CrusaderAura))
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  -- lights_judgment
  if CDsON() and S.LightsJudgment:IsCastable() then
    if Press(S.LightsJudgment, not Target:IsSpellInRange(S.LightsJudgment)) then return "lights_judgment precombat 4"; end
  end
  -- arcane_torrent
  if CDsON() and S.ArcaneTorrent:IsCastable() then
    if Press(S.ArcaneTorrent, not Target:IsInRange(8)) then return "arcane_torrent precombat 6"; end
  end
  -- consecration
  if S.Consecration:IsCastable() then
    if Press(S.Consecration, not Target:IsInMeleeRange(8)) then return "consecration"; end
  end
  -- variable,name=trinket_1_sync,op=setif,value=1,value_else=0.5,condition=trinket.1.has_use_buff&((talent.moment_of_glory.enabled&trinket.1.cooldown.duration%%cooldown.moment_of_glory.duration=0)|(!talent.moment_of_glory.enabled&trinket.1.cooldown.duration%%cooldown.avenging_wrath.duration=0))
  -- variable,name=trinket_2_sync,op=setif,value=1,value_else=0.5,condition=trinket.2.has_use_buff&((talent.moment_of_glory.enabled&trinket.2.cooldown.duration%%cooldown.moment_of_glory.duration=0)|(!talent.moment_of_glory.enabled&trinket.2.cooldown.duration%%cooldown.avenging_wrath.duration=0))
  -- variable,name=trinket_priority,op=setif,value=2,value_else=1,condition=!trinket.1.has_use_buff&trinket.2.has_use_buff|trinket.2.has_use_buff&((trinket.2.cooldown.duration%trinket.2.proc.any_dps.duration)*(1.5+trinket.2.has_buff.strength)*(variable.trinket_2_sync))>((trinket.1.cooldown.duration%trinket.1.proc.any_dps.duration)*(1.5+trinket.1.has_buff.strength)*(variable.trinket_1_sync))
  -- variable,name=trinket_1_buffs,value=trinket.1.has_buff.strength|trinket.1.has_buff.mastery|trinket.1.has_buff.versatility|trinket.1.has_buff.haste|trinket.1.has_buff.crit
  -- variable,name=trinket_2_buffs,value=trinket.2.has_buff.strength|trinket.2.has_buff.mastery|trinket.2.has_buff.versatility|trinket.2.has_buff.haste|trinket.2.has_buff.crit
  -- Note: Unable to handle some trinket conditionals, such as cooldown.duration.
  -- Manually added: avengers_shield
  if S.AvengersShield:IsCastable() then
    if Press(S.AvengersShield, not Target:IsSpellInRange(S.AvengersShield)) then return "avengers_shield precombat 10"; end
  end
  -- Manually added: judgment
  if S.Judgment:IsReady() then
    if Press(S.Judgment, not Target:IsSpellInRange(S.Judgment)) then return "judgment precombat 12"; end
  end
end

local function Defensives()
  if Player:HealthPercentage() <= Settings.Protection.HP.LoH and S.LayonHands:IsCastable() then
    if Press(M.LayonHandsPlayer) then return "lay_on_hands defensive 2"; end
  end
  if S.GuardianofAncientKings:IsCastable() and (Player:HealthPercentage() <= Settings.Protection.HP.GoAK and Player:BuffDown(S.ArdentDefenderBuff)) then
    if Press(S.GuardianofAncientKings) then return "guardian_of_ancient_kings defensive 4"; end
  end
  if S.ArdentDefender:IsCastable() and (Player:HealthPercentage() <= Settings.Protection.HP.ArdentDefender and Player:BuffDown(S.GuardianofAncientKingsBuff)) then
    if Press(S.ArdentDefender) then return "ardent_defender defensive 6"; end
  end
  -- word_of_glory,if=buff.shining_light_free.up
  if S.WordofGlory:IsReady() then
    if Player:HealthPercentage() > 90 and Player:IsInParty() and not Player:IsInRaid() then
      local ShouldReturn = Everyone.FocusUnit(false, M); if ShouldReturn then return ShouldReturn; end
      if Focus and Focus:Exists() and Focus:HealthPercentage() < Settings.Protection.HP.WordofGlory then
        if Press(M.WordofGloryFocus) then return "word_of_glory standard party 28"; end
      end
    else
      if S.WordofGlory:IsReady() and (Player:HealthPercentage() <= Settings.Protection.HP.WordofGlory) then
        if Press(M.WordofGloryPlayer) then return "word_of_glory defensive 8"; end
      end
    end
  end
  
  if S.ShieldoftheRighteous:IsReady() and (Player:BuffRefreshable(S.ShieldoftheRighteousBuff) and (ActiveMitigationNeeded or Player:HealthPercentage() <= Settings.Protection.HP.ShieldoftheRighteous)) then
    if Press(S.ShieldoftheRighteous) then return "shield_of_the_righteous defensive 12"; end
  end
  -- healthstone
  if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
    if Press(M.Healthstone, nil, nil, true) then return "healthstone defensive"; end
  end
end

local function Cooldowns()
  -- seraphim
  if S.Seraphim:IsReady() then
    if Press(S.Seraphim, not Target:IsInMeleeRange(8)) then return "seraphim cooldowns 2"; end
  end
  -- avenging_wrath,if=(buff.seraphim.up|!talent.seraphim.enabled)
  if S.AvengingWrath:IsCastable() and (Player:BuffUp(S.SeraphimBuff) or not S.Seraphim:IsAvailable()) then
    if Press(S.AvengingWrath, not Target:IsInMeleeRange(8)) then return "avenging_wrath cooldowns 4"; end
  end
  -- potion,if=buff.avenging_wrath.up
  -- moment_of_glory,if=(buff.avenging_wrath.remains<15|(time>10|(cooldown.avenging_wrath.remains>15))&(cooldown.avengers_shield.remains&cooldown.judgment.remains&cooldown.hammer_of_wrath.remains))
  if S.MomentofGlory:IsCastable() and (Player:BuffRemains(S.AvengingWrathBuff) < 15 or (HL.CombatTime() > 10 or (S.AvengingWrath:CooldownRemains() > 15)) and (S.AvengersShield:CooldownDown() and S.Judgment:CooldownDown() and S.HammerofWrath:CooldownDown())) then
    if Press(S.MomentofGlory, not Target:IsInMeleeRange(8)) then return "moment_of_glory cooldowns 8"; end
  end
  -- holy_avenger,if=buff.avenging_wrath.up|cooldown.avenging_wrath.remains>60
  if S.HolyAvenger:IsCastable() and (Player:BuffUp(S.AvengingWrathBuff) or S.AvengingWrath:CooldownRemains() > 60) then
    if Press(S.HolyAvenger, not Target:IsInMeleeRange(8)) then return "holy_avenger cooldowns 10"; end
  end
  -- bastion_of_light,if=buff.avenging_wrath.up
  if S.BastionofLight:IsCastable() and (Player:BuffUp(S.AvengingWrathBuff)) then
    if Press(S.BastionofLight, not Target:IsInMeleeRange(8)) then return "bastion_of_light cooldowns 12"; end
  end
end

local function Trinkets()
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

local function Standard()
  -- shield_of_the_righteous,if=(cooldown.seraphim.remains>=5|!talent.seraphim.enabled)&(((holy_power=3&!buff.blessing_of_dusk.up&!buff.holy_avenger.up)|(holy_power=5)|buff.bastion_of_light.up|buff.divine_purpose.up))
  if S.ShieldoftheRighteous:IsReady() and ((S.Seraphim:CooldownRemains() >= 5 or not S.Seraphim:IsAvailable()) and ((Player:HolyPower() == 3 and Player:BuffDown(S.BlessingofDuskBuff) and Player:BuffDown(S.HolyAvengerBuff)) or (Player:HolyPower() == 5) or Player:BuffUp(S.BastionofLightBuff) or Player:BuffUp(S.DivinePurposeBuff))) then
    if Press(S.ShieldoftheRighteous) then return "shield_of_the_righteous standard 2"; end
  end
  -- avengers_shield,if=buff.moment_of_glory.up|!talent.moment_of_glory.enabled
  if S.AvengersShield:IsCastable() and (Player:BuffUp(S.MomentofGloryBuff) or not S.MomentofGlory:IsAvailable()) then
    if Press(S.AvengersShield, not Target:IsSpellInRange(S.AvengersShield)) then return "avengers_shield standard 4"; end
  end
  -- hammer_of_wrath,if=buff.avenging_wrath.up
  if S.HammerofWrath:IsReady() and (Player:BuffUp(S.AvengingWrathBuff)) then
    if Press(S.HammerofWrath, not Target:IsSpellInRange(S.HammerofWrath)) then return "hammer_of_wrath standard 6"; end
  end
  -- judgment,target_if=min:debuff.judgment.remains,if=charges=2|!talent.crusaders_judgment.enabled
  if S.Judgment:IsReady() and (S.Judgment:Charges() == 2 or not S.CrusadersJudgment:IsAvailable()) then
    if Everyone.CastTargetIf(S.Judgment, Enemies30y, "min", EvaluateTargetIfFilterJudgment, nil, not Target:IsSpellInRange(S.Judgment), nil, nil, M.JudgmentMouseover) then return "judgment standard 8"; end
  end
  -- divine_toll,if=time>20|((!talent.seraphim.enabled|buff.seraphim.up)&(buff.avenging_wrath.up|!talent.avenging_wrath.enabled)&(buff.moment_of_glory.up|!talent.moment_of_glory.enabled))
  if CDsON() and S.DivineToll:IsReady() and (HL.CombatTime() > 20 or (((not S.Seraphim:IsAvailable()) or Player:BuffUp(S.SeraphimBuff)) and (Player:BuffUp(S.AvengingWrathBuff) or not S.AvengingWrath:IsAvailable()) and (Player:BuffUp(S.MomentofGloryBuff) or not S.MomentofGlory:IsAvailable()))) then
    if Press(S.DivineToll, not Target:IsInRange(30)) then return "divine_toll standard 10"; end
  end
  -- avengers_shield
  if S.AvengersShield:IsCastable() then
    if Press(S.AvengersShield, not Target:IsSpellInRange(S.AvengersShield)) then return "avengers_shield standard 12"; end
  end
  -- hammer_of_wrath
  if S.HammerofWrath:IsReady() then
    if Press(S.HammerofWrath, not Target:IsSpellInRange(S.HammerofWrath)) then return "hammer_of_wrath standard 14"; end
  end
  -- judgment,target_if=min:debuff.judgment.remains
  if S.Judgment:IsReady() then
    if Everyone.CastTargetIf(S.Judgment, Enemies30y, "min", EvaluateTargetIfFilterJudgment, nil, not Target:IsSpellInRange(S.Judgment), nil, nil, M.JudgmentMouseover) then return "judgment standard 16"; end
  end
  -- consecration,if=!consecration.up
  if S.Consecration:IsCastable() and (Player:BuffDown(S.ConsecrationBuff)) then
    if Press(S.Consecration, not Target:IsInMeleeRange(8)) then return "consecration standard 18"; end
  end
  -- eye_of_tyr
  if CDsON() and S.EyeofTyr:IsCastable() then
    if Press(S.EyeofTyr, not Target:IsInMeleeRange(8)) then return "eye_of_tyr standard 20"; end
  end
  -- blessed_hammer
  if S.BlessedHammer:IsCastable() then
    if Press(S.BlessedHammer, not Target:IsInMeleeRange(5)) then return "blessed_hammer standard 22"; end
  end
  -- hammer_of_the_righteous
  if S.HammeroftheRighteous:IsCastable() then
    if Press(S.HammeroftheRighteous, not Target:IsInMeleeRange(5)) then return "hammer_of_the_righteous standard 24"; end
  end
  -- crusader_strike
  if S.CrusaderStrike:IsCastable() then
    if Press(S.CrusaderStrike, not Target:IsInMeleeRange(5)) then return "crusader_strike standard 26"; end
  end
  -- word_of_glory,if=buff.shining_light_free.up
  if S.WordofGlory:IsReady() and (Player:BuffUp(S.ShiningLightFreeBuff)) then
    if Player:HealthPercentage() > 90 and Player:IsInParty() and not Player:IsInRaid() then
      local ShouldReturn = Everyone.FocusUnit(false, M); if ShouldReturn then return ShouldReturn; end
      if Focus and Focus:Exists() and Focus:HealthPercentage() < 100 then
        if Press(M.WordofGloryFocus) then return "word_of_glory standard party 28"; end
      end
    else
      if Press(M.WordofGloryPlayer) then return "word_of_glory standard self 32"; end
    end
  end
  -- consecration
  if S.Consecration:IsCastable() then
    if Press(S.Consecration, not Target:IsInMeleeRange(8)) then return "consecration standard 34"; end
  end
end

-- APL Main
local function APL()
  Enemies8y = Player:GetEnemiesInMeleeRange(8)
  Enemies30y = Player:GetEnemiesInRange(30)
  if (AoEON()) then
    EnemiesCount8y = #Enemies8y
    EnemiesCount30y = #Enemies30y
  else
    EnemiesCount8y = 1
    EnemiesCount30y = 1
  end

  ActiveMitigationNeeded = Player:ActiveMitigationNeeded()
  IsTanking = Player:IsTankingAoE(8) or Player:IsTanking(Target)

  if not Player:AffectingCombat() then
    -- Manually added: devotion_aura
    if S.DevotionAura:IsCastable() and (MissingAura()) then
      if Press(S.DevotionAura) then return "devotion_aura"; end
    end
  end

  if Everyone.TargetIsValid() then
    -- Precombat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- auto_attack
    -- Explosives
    if Settings.General.Enabled.HandleExplosives then
      local ShouldReturn = Everyone.HandleExplosive(S.Judgment, M.JudgmentMouseover, 30); if ShouldReturn then return ShouldReturn; end
    end
    -- Interrupts
    if not Player:IsCasting() and not Player:IsChanneling() then
      local ShouldReturn = Everyone.Interrupt(S.Rebuke, 5, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.HammerofJustice, 8); if ShouldReturn then return ShouldReturn; end
    end
    -- Manually added: Defensives!
    if IsTanking then
      local ShouldReturn = Defensives(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=cooldowns
    if CDsON() then
      local ShouldReturn = Cooldowns(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=trinkets
    local ShouldReturn = Trinkets(); if ShouldReturn then return ShouldReturn; end
    -- call_action_list,name=standard
    local ShouldReturn = Standard(); if ShouldReturn then return ShouldReturn; end
    -- Manually added: Pool, if nothing else to do
    if Press(S.Pool) then return "Wait/Pool Resources"; end
  end
end

local function AutoBind()
  -- Spells
  Bind(S.ArdentDefender)
  Bind(S.AvengersShield)
  Bind(S.AvengingWrath)
  Bind(S.BastionofLight)
  Bind(S.BlessedHammer)
  Bind(S.BlessingofFreedom)
  Bind(S.BlessingofProtection)
  Bind(S.BlindingLight)
  Bind(S.Consecration)
  Bind(S.CrusaderStrike)
  Bind(S.CrusadersJudgment)
  Bind(S.DevotionAura)
  Bind(S.DivineToll)
  Bind(S.DivineShield)
  Bind(S.EyeofTyr)
  Bind(S.FlashofLight)
  Bind(S.GuardianofAncientKings)
  Bind(S.HammerofJustice)
  Bind(S.HandofReckoning)
  Bind(S.HammeroftheRighteous)
  Bind(S.HammerofWrath)
  Bind(S.LayonHands)
  Bind(S.MomentofGlory)
  Bind(S.Judgment)
  Bind(S.Rebuke)
  Bind(S.ShieldoftheRighteous)
  Bind(S.WordofGlory)
  Bind(S.HolyAvenger)
  Bind(S.Seraphim)
  Bind(S.ZealotsParagon)
  -- Macros
  Bind(M.BlessingofFreedomMouseover)
  Bind(M.BlessingofProtectionMouseover)
  Bind(M.CleanseToxinsMouseover)
  Bind(M.LayonHandsPlayer)
  Bind(M.JudgmentMouseover)
  Bind(M.WordofGloryFocus)
  Bind(M.WordofGloryPlayer)
  -- Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  -- Focus
  Bind(M.FocusPlayer)
  for i = 1, 4 do
    local FocusUnitKey = stringformat("FocusParty%d", i)
    Bind(M[FocusUnitKey])
  end
end

local function Init()
  WR.Print("Protection Paladin by Worldy.")
  AutoBind()
end

WR.SetAPL(66, APL, Init)
