--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local HL         = HeroLib
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
-- lua
local mathfloor  = math.floor

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Spells
local S = Spell.Warrior.Protection
local I = Item.Warrior.Protection
local M = Macro.Warrior.Protection

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
}

-- Variables
local TargetInMeleeRange

-- Enemies Variables
local Enemies8y
local EnemiesCount8

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Warrior.Commons,
  Protection = WR.GUISettings.APL.Warrior.Protection
}

local function IsCurrentlyTanking()
  return Player:IsTankingAoE(16) or Player:IsTanking(Target) or Target:IsDummy()
end

local function IgnorePainWillNotCap()
  if Player:BuffUp(S.IgnorePain) then
    local absorb = Player:AttackPowerDamageMod() * 3.5 * (1 + Player:VersatilityDmgPct() / 100)
    local spellTable = Player:AuraInfo(S.IgnorePain, nil, true)
    local IPAmount = spellTable.points[1]
    --return IPAmount < (0.5 * mathfloor(absorb * 1.3))
    -- Ignore Pain appears to cap at 2 times its absorb value now
    return IPAmount < absorb
  else
    return true
  end
end

local function IgnorePainValue()
  if Player:BuffUp(S.IgnorePain) then
    local IPBuffInfo = Player:BuffInfo(S.IgnorePain, nil, true)
    return IPBuffInfo.points[1]
  else
    return 0
  end
end

local function ShouldPressShieldBlock()
  -- shield_block,if=buff.shield_block.duration<=18&talent.enduring_defenses.enabled|buff.shield_block.duration<=12
  return IsCurrentlyTanking() and S.ShieldBlock:IsReady() and (Player:BuffRemains(S.ShieldBlockBuff) <= 18 and S.EnduringDefenses:IsAvailable() or Player:BuffRemains(S.ShieldBlockBuff) <= 12)
end

-- A bit of logic to decide whether to pre-cast-rage-dump on ignore pain.
local function SuggestRageDump(RageFromSpell)
  -- Get RageMax from setting (default 80)
  local RageMax = 80
  -- If the setting value is lower than 35, it's not possible to cast Ignore Pain, so just return false
  if (RageMax < 35 or Player:Rage() < 35) then return false end
  local shouldPreRageDump = false
  -- Make sure we have enough Rage to cast IP, that it's not on CD, and that we shouldn't use Shield Block
  local AbleToCastIP = (Player:Rage() >= 35 and not ShouldPressShieldBlock())
  if AbleToCastIP and (Player:Rage() + RageFromSpell >= RageMax or S.DemoralizingShout:IsReady()) then
    -- should pre-dump rage into IP if rage + RageFromSpell >= RageMax or Demo Shout is ready
      shouldPreRageDump = true
  end
  if shouldPreRageDump then
    if IsCurrentlyTanking() and IgnorePainWillNotCap() then
      if Press(S.IgnorePain) then return "ignore_pain rage capped"; end
    else
      if Press(S.Revenge, not TargetInMeleeRange) then return "revenge rage capped"; end
    end
  end
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  -- Manually added opener
  if Target:IsInMeleeRange(12) then
    if S.ThunderClap:IsCastable() then
      if Press(S.ThunderClap) then return "thunder_clap precombat"; end
    end
  else
    if Settings.Commons.Enabled.Charge and S.Charge:IsCastable() and not Target:IsInRange(8) then
      if Press(S.Charge, not Target:IsSpellInRange(S.Charge)) then return "charge precombat"; end
    end
  end
end

local function Aoe()
  --thunder_clap,if=dot.rend.remains<=1
  if S.ThunderClap:IsCastable() and Target:DebuffRemains(S.RendDebuff) <= 1 then
    SuggestRageDump(5)
    if Press(S.ThunderClap, not Target:IsInMeleeRange(8)) then return "thunder_clap aoe 2"; end
  end
  --thunder_clap,if=buff.violent_outburst.up&spell_targets.thunderclap>5&buff.avatar.up&talent.unstoppable_force.enabled
  if S.ThunderClap:IsCastable() and Player:BuffUp(S.ViolentOutburstBuff) and EnemiesCount8 > 5 and Player:BuffUp(S.AvatarBuff) and S.UnstoppableForce:IsAvailable() then
    SuggestRageDump(5)
    if Press(S.ThunderClap, not Target:IsInMeleeRange(8)) then return "thunder_clap aoe 4"; end
  end
  --revenge,if=rage>=70&talent.seismic_reverberation.enabled&spell_targets.revenge>=3
  if S.Revenge:IsReady() and Player:Rage() >= 70 and S.SeismicReverberation:IsAvailable() and EnemiesCount8 >= 3 then
    if Press(S.Revenge, not TargetInMeleeRange) then return "revenge aoe 6"; end
  end
  --shield_slam,if=rage<=60|buff.violent_outburst.up&spell_targets.thunderclap<=4
  if S.ShieldSlam:IsCastable() and (Player:Rage() <= 60 or Player:BuffUp(S.ViolentOutburstBuff) and EnemiesCount8 <= 4) then
    SuggestRageDump(20)
    if Press(S.ShieldSlam, not TargetInMeleeRange) then return "shield_slam aoe 8"; end
  end
  --thunder_clap
  if S.ThunderClap:IsCastable() then
    SuggestRageDump(5)
    if Press(S.ThunderClap, not Target:IsInMeleeRange(8)) then return "thunder_clap aoe 10"; end
  end
  --revenge,if=rage>=30|rage>=40&talent.barbaric_training.enabled
  if S.Revenge:IsReady() and (Player:Rage() >= 30 or Player:Rage() >= 40 and S.BarbaricTraining:IsAvailable()) then
    if Press(S.Revenge, not TargetInMeleeRange) then return "revenge aoe 12"; end
  end
end

local function Generic()
  -- shield_slam
  if S.ShieldSlam:IsCastable() then
    SuggestRageDump(20)
    if Press(S.ShieldSlam, not TargetInMeleeRange) then return "shield_slam generic 2"; end
  end
  -- thunder_clap,if=dot.rend.remains<=1&buff.violent_outburst.down
  if S.ThunderClap:IsCastable() and Target:DebuffRemains(S.RendDebuff) <= 1 and Player:BuffDown(S.ViolentOutburstBuff) then
    SuggestRageDump(5)
    if Press(S.ThunderClap, not Target:IsInMeleeRange(8)) then return "thunder_clap generic 4"; end
  end
  -- execute,if=buff.sudden_death.up&talent.sudden_death.enabled
  if S.Execute:IsReady() and Player:BuffUp(S.SuddenDeathBuff) and S.SuddenDeath:IsAvailable() then
    if Press(S.Execute, not TargetInMeleeRange) then return "execute generic 6"; end
  end
  -- execute,if=spell_targets.revenge=1&(talent.massacre.enabled|talent.juggernaut.enabled)&rage>=50
  if S.Execute:IsReady() and EnemiesCount8 == 1 and (S.Massacre:IsAvailable() or S.Juggernaut:IsAvailable()) and Player:Rage() >= 50 then
    if Press(S.Execute, not TargetInMeleeRange) then return "execute generic 6"; end
  end
  -- execute,if=spell_targets.revenge=1&rage>=50
  if S.Execute:IsReady() and EnemiesCount8 == 1 and Player:Rage() >= 50 then
    if Press(S.Execute, not TargetInMeleeRange) then return "execute generic 10"; end
  end
  -- thunder_clap,if=(spell_targets.thunder_clap>1|cooldown.shield_slam.remains&!buff.violent_outburst.up)
  if S.ThunderClap:IsCastable() and (EnemiesCount8 > 1 or S.ShieldSlam:CooldownDown() and not Player:BuffUp(S.ViolentOutburstBuff)) then
    SuggestRageDump(5)
    if Press(S.ThunderClap, not Target:IsInMeleeRange(8)) then return "thunder_clap generic 12"; end
  end
  --revenge,if=
  --(rage>=60&target.health.pct>20|buff.revenge.up&target.health.pct<=20&rage<=18&cooldown.shield_slam.remains|buff.revenge.up&target.health.pct>20)
  --|(rage>=60&target.health.pct>35|buff.revenge.up&target.health.pct<=35&rage<=18&cooldown.shield_slam.remains|buff.revenge.up&target.health.pct>35)
  --&talent.massacre.enabled
  if S.Revenge:IsReady() 
  and ((Player:Rage() >= 60 and Target:HealthPercentage() > 20 or Player:BuffUp(S.RevengeBuff) and Target:HealthPercentage() <= 20 and Player:Rage() <= 18 and S.ShieldSlam:CooldownDown() or Player:BuffUp(S.RevengeBuff) and Target:HealthPercentage() > 20) 
  or (Player:Rage() >= 60 and Target:HealthPercentage() > 35 or Player:BuffUp(S.RevengeBuff) and Target:HealthPercentage() <= 35 and Player:Rage() <= 18 and S.ShieldSlam:CooldownDown() or Player:BuffUp(S.RevengeBuff) and Target:HealthPercentage() > 35) 
  and S.Massacre:IsAvailable()) then
    if Press(S.Revenge, not TargetInMeleeRange) then return "revenge generic 14"; end
  end
  -- execute,if=spell_targets.revenge=1
  if S.Execute:IsReady() and EnemiesCount8 == 1 then
    if Press(S.Execute, not TargetInMeleeRange) then return "execute generic 16"; end
  end
  -- revenge
  if S.Revenge:IsReady() then
    if Press(S.Revenge, not TargetInMeleeRange) then return "revenge generic 18"; end
  end
  -- thunder_clap,if=(spell_targets.thunder_clap>=1|cooldown.shield_slam.remains&buff.violent_outburst.up)
  if S.ThunderClap:IsCastable() and (EnemiesCount8 >= 1 or S.ShieldSlam:CooldownDown() and Player:BuffUp(S.ViolentOutburstBuff)) then
    SuggestRageDump(5)
    if Press(S.ThunderClap, not Target:IsInMeleeRange(8)) then return "thunder_clap generic 20"; end
  end
  -- devastate
  if S.Devastate:IsCastable() then
    if Press(S.Devastate, not TargetInMeleeRange) then return "devastate generic 22"; end
  end
end

--- ======= ACTION LISTS =======
local function APL()
  if AoEON() then
    Enemies8y = Player:GetEnemiesInMeleeRange(8) -- Multiple Abilities
    EnemiesCount8 = #Enemies8y
  else
    EnemiesCount8 = 1
  end

  -- Range check
  TargetInMeleeRange = Target:IsInMeleeRange(5)
  
  if not Player:AffectingCombat() then
    -- Manually added: Group buff check
    if S.BattleShout:IsCastable() and (Player:BuffDown(S.BattleShoutBuff, true) or Everyone.GroupBuffMissing(S.BattleShoutBuff)) then
      if Press(S.BattleShout) then return "battle_shout precombat"; end
    end
    if S.DefensiveStance:IsCastable() and not Player:BuffUp(S.DefensiveStance) then
      if Press(S.DefensiveStance) then return "defensive_stance precombat"; end
    end
  end

  if Everyone.TargetIsValid() then
    -- call precombat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- Manually added: VR/IV
    if Player:HealthPercentage() < Settings.Commons.HP.VictoryRush then
      if S.VictoryRush:IsReady() then
        if Press(S.VictoryRush) then return "victory_rush defensive"; end
      end
      if S.ImpendingVictory:IsReady() then
        if Press(S.ImpendingVictory) then return "impending_victory defensive"; end
      end
    end
    -- rallying_cry,if=!buff.last_stand.up&!buff.shield_wall.up
    if Player:HealthPercentage() < Settings.Commons.HP.RallyingCry and S.RallyingCry:IsCastable() and (Player:BuffDown(S.LastStandBuff) and Player:BuffDown(S.ShieldWallBuff)) then
      if Press(S.RallyingCry) then return "rallying_cry defensive"; end
    end
    -- healthstone
    if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
      if Press(M.Healthstone, nil, nil, true) then return "healthstone"; end
    end
    -- Interrupt
    local ShouldReturn = Everyone.Interrupt(S.Pummel, 5, true); if ShouldReturn then return ShouldReturn; end
    ShouldReturn = Everyone.InterruptWithStun(S.StormBolt, 8); if ShouldReturn then return ShouldReturn; end
    ShouldReturn = Everyone.Interrupt(S.Pummel, 5, true, Mouseover, M.PummelMouseover); if ShouldReturn then return ShouldReturn; end
    ShouldReturn = Everyone.InterruptWithStun(S.StormBolt, 8, nil, Mouseover, M.StormBoltMouseover); if ShouldReturn then return ShouldReturn; end
    -- auto_attack
    -- shield_charge,if=time=0
    -- charge,if=time=0
    -- Note: Above 2 lines handled in Precombat
    -- use_items
    if CDsON() and Settings.General.Enabled.Trinkets and TargetInMeleeRange then
      -- use_item,slot=trinket1
      local Trinket1ToUse = Player:GetUseableItems(OnUseExcludes, 13)
      if Trinket1ToUse then
        if Press(M.Trinket1, nil, nil, true) then return "trinket1 main"; end
      end
      -- use_item,slot=trinket2
      local Trinket2ToUse = Player:GetUseableItems(OnUseExcludes, 14)
      if Trinket2ToUse then
        if Press(M.Trinket2, nil, nil, true) then return "trinket2 main"; end
      end
    end
    -- avatar
    if CDsON() and S.Avatar:IsCastable() then
      if Press(S.Avatar) then return "avatar main 2"; end
    end
    -- shield_wall,if=!buff.last_stand.up&!buff.rallying_cry.up
    if IsCurrentlyTanking() and S.ShieldWall:IsCastable() and (S.ImmovableObject:IsAvailable() and Player:BuffDown(S.AvatarBuff)) then
      if Press(S.ShieldWall) then return "shield_wall defensive"; end
    end
    if CDsON() then
      -- blood_fury
      if S.BloodFury:IsCastable() then
        if Press(S.BloodFury) then return "blood_fury main 4"; end
      end
      -- berserking
      if S.Berserking:IsCastable() then
        if Press(S.Berserking) then return "berserking main 6"; end
      end
      -- arcane_torrent
      if S.ArcaneTorrent:IsCastable() then
        if Press(S.ArcaneTorrent) then return "arcane_torrent main 8"; end
      end
      -- lights_judgment
      if S.LightsJudgment:IsCastable() then
        if Press(S.LightsJudgment) then return "lights_judgment main 10"; end
      end
      -- fireblood
      if S.Fireblood:IsCastable() then
        if Press(S.Fireblood) then return "fireblood main 12"; end
      end
      -- ancestral_call
      if S.AncestralCall:IsCastable() then
        if Press(S.AncestralCall) then return "ancestral_call main 14"; end
      end
      -- bag_of_tricks
      if S.BagofTricks:IsCastable() then
        if Press(S.BagofTricks) then return "ancestral_call main 16"; end
      end
    end
    -- potion,if=buff.avatar.up|buff.avatar.up&target.health.pct<=20
    
    -- ignore_pain,if=target.health.pct>=20&
    --(rage.deficit<=15&cooldown.shield_slam.ready
    --|rage.deficit<=40&cooldown.shield_charge.ready&talent.champions_bulwark.enabled
    --|rage.deficit<=20&cooldown.shield_charge.ready
    --|rage.deficit<=30&cooldown.demoralizing_shout.ready&talent.booming_voice.enabled
    --|rage.deficit<=20&cooldown.avatar.ready
    --|rage.deficit<=45&cooldown.demoralizing_shout.ready&talent.booming_voice.enabled&buff.last_stand.up&talent.unnerving_focus.enabled
    --|rage.deficit<=30&cooldown.avatar.ready&buff.last_stand.up&talent.unnerving_focus.enabled
    --|rage.deficit<=20
    --|rage.deficit<=40&cooldown.shield_slam.ready&buff.violent_outburst.up&talent.heavy_repercussions.enabled&talent.impenetrable_wall.enabled
    --|rage.deficit<=55&cooldown.shield_slam.ready&buff.violent_outburst.up&buff.last_stand.up&talent.unnerving_focus.enabled&talent.heavy_repercussions.enabled&talent.impenetrable_wall.enabled
    --|rage.deficit<=17&cooldown.shield_slam.ready&talent.heavy_repercussions.enabled
    --|rage.deficit<=18&cooldown.shield_slam.ready&talent.impenetrable_wall.enabled),use_off_gcd=1
    if S.IgnorePain:IsReady() and IgnorePainWillNotCap() and (Target:HealthPercentage() >= 20 and 
      (Player:RageDeficit() <= 15 and S.ShieldSlam:CooldownUp() 
      or Player:RageDeficit() <= 40 and S.ShieldCharge:CooldownUp() and S.ChampionsBulwark:IsAvailable() 
      or Player:RageDeficit() <= 20 and S.ShieldCharge:CooldownUp() 
      or Player:RageDeficit() <= 30 and S.DemoralizingShout:CooldownUp() and S.BoomingVoice:IsAvailable() 
      or Player:RageDeficit() <= 20 and S.Avatar:CooldownUp() 
      or Player:RageDeficit() <= 45 and S.DemoralizingShout:CooldownUp() and S.BoomingVoice:IsAvailable() and Player:BuffUp(S.LastStandBuff) and S.UnnervingFocus:IsAvailable() 
      or Player:RageDeficit() <= 30 and S.Avatar:CooldownUp() and Player:BuffUp(S.LastStandBuff) and S.UnnervingFocus:IsAvailable()
      or Player:RageDeficit() <= 20
      or Player:RageDeficit() <= 40 and S.ShieldSlam:CooldownUp() and Player:BuffUp(S.ViolentOutburstBuff) and S.HeavyRepercussions:IsAvailable() and S.ImpenetrableWall:IsAvailable() 
      or Player:RageDeficit() <= 55 and S.ShieldSlam:CooldownUp() and Player:BuffUp(S.ViolentOutburstBuff) and Player:BuffUp(S.LastStandBuff) and S.UnnervingFocus:IsAvailable() and S.HeavyRepercussions:IsAvailable() and S.ImpenetrableWall:IsAvailable()
      or Player:RageDeficit() <= 17 and S.ShieldSlam:CooldownUp() and S.HeavyRepercussions:IsAvailable()
      or Player:RageDeficit() <= 18 and S.ShieldSlam:CooldownUp() and S.ImpenetrableWall:IsAvailable())) then
      if Press(S.IgnorePain) then return "ignore_pain main 20"; end
    end
    -- last_stand,if=(target.health.pct>=90&talent.unnerving_focus.enabled|target.health.pct<=20&talent.unnerving_focus.enabled)|talent.bolster.enabled
    if IsCurrentlyTanking() and S.LastStand:IsCastable() and Player:BuffDown(S.ShieldWallBuff) and ((Target:HealthPercentage() >= 90 and S.UnnervingFocus:IsAvailable() or Target:HealthPercentage() <= 20 and S.UnnervingFocus:IsAvailable()) or S.Bolster:IsAvailable() or Player:HasTier(30, 2)) then
      if Press(S.LastStand) then return "last_stand defensive"; end
    end
    -- ravager
    if CDsON() and S.Ravager:IsCastable() then
      SuggestRageDump(10)
      if Press(M.RavagerPlayer, not TargetInMeleeRange) then return "ravager main 24"; end
    end
    -- demoralizing_shout,if=talent.booming_voice.enabled
    if S.DemoralizingShout:IsCastable() and S.BoomingVoice:IsAvailable() then
      SuggestRageDump(30)
      if Press(S.DemoralizingShout, not TargetInMeleeRange) then return "demoralizing_shout main 28"; end
    end
    -- spear_of_bastion
    if CDsON() and S.SpearofBastion:IsCastable() then
      SuggestRageDump(20)
      if Press(M.SpearofBastionPlayer, not TargetInMeleeRange) then return "spear_of_bastion main 28"; end
    end
    -- thunderous_roar
    if CDsON() and S.ThunderousRoar:IsCastable() then
      if Press(S.ThunderousRoar, not Target:IsInMeleeRange(12)) then return "thunderous_roar main 30"; end
    end
    -- shockwave,if=talent.sonic_boom.enabled&buff.avatar.up&talent.unstoppable_force.enabled&!talent.rumbling_earth.enabled
    if S.Shockwave:IsCastable() and S.SonicBoom:IsAvailable() and Player:BuffUp(S.AvatarBuff) and S.UnstoppableForce:IsAvailable() and not S.RumblingEarth:IsAvailable() then
      SuggestRageDump(10)
      if Press(S.Shockwave, not Target:IsInMeleeRange(10)) then return "shockwave main 32"; end
    end
    -- shield_charge
    if S.ShieldCharge:IsCastable() then
      if Press(S.ShieldCharge, not Target:IsSpellInRange(S.ShieldCharge)) then return "shield_charge main 34"; end
    end
    -- shield_block,if=buff.shield_block.duration<=18&talent.enduring_defenses.enabled|buff.shield_block.duration<=12
    if ShouldPressShieldBlock() then
      if Press(S.ShieldBlock) then return "shield_block main 38"; end
    end
    -- run_action_list,name=aoe,if=spell_targets.thunder_clap>3
    if EnemiesCount8 > 3 then
      local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
      if WR.CastAnnotated(S.Pool, false, "WAIT") then return "Pool for Aoe()"; end
    end
    -- call_action_list,name=generic
    local ShouldReturn = Generic(); if ShouldReturn then return ShouldReturn; end
    -- If nothing else to do, show the Pool icon
    if WR.CastAnnotated(S.Pool, false, "WAIT") then return "Wait/Pool Resources"; end
  end
end

local function AutoBind()
  -- Spells
  Bind(S.Avatar)
  Bind(S.BattleShout)
  Bind(S.Charge)
  Bind(S.DefensiveStance)  
  Bind(S.IgnorePain)
  Bind(S.ShieldBlock)
  Bind(S.ShieldSlam)
  Bind(S.ThunderClap)
  Bind(S.Rend)
  Bind(S.Revenge)
  Bind(S.Execute)
  Bind(S.ThunderousRoar)
  Bind(S.ShieldCharge)
  Bind(S.Shockwave)
  Bind(S.ImpendingVictory)
  Bind(S.HeroicThrow)
  Bind(S.StormBolt)
  Bind(S.IntimidatingShout)
  Bind(S.ShieldWall)
  Bind(S.RallyingCry)
  Bind(S.DemoralizingShout)
  Bind(S.Pummel)
  Bind(S.WarStomp)
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  Bind(M.RavagerPlayer)
  Bind(M.SpearofBastionPlayer)
  Bind(M.PummelMouseover)
  Bind(M.StormBoltMouseover)
end

local function Init()
  WR.Print("Protection Warrior by Worldy.")
  AutoBind()
end

WR.SetAPL(73, APL, Init)
