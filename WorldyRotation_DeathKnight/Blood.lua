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
local Pet        = Unit.Pet
local Spell      = HL.Spell
local Item       = HL.Item
-- WorldyRotation
local WR         = WorldyRotation
local Cast       = WR.Cast
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Macro      = WR.Macro
-- lua
local mathmin    = math.min

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I/M for spell, item and macro arrays
local S = Spell.DeathKnight.Blood
local I = Item.DeathKnight.Blood
local M = Macro.DeathKnight.Blood

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  --  I.TrinketName:ID(),
}

-- Rotation Var
local VarDeathStrikeDumpAmt
local VarDeathStrikeCost
local VarDeathsDueBuffCheck
local VarHeartStrikeRP
local VarHeartStrikeRPDRW
local VarTomestoneBoneCount
local IsTanking
local EnemiesMelee
local EnemiesMeleeCount
local Enemies10y
local EnemiesCount10y
local HeartStrikeCount
local UnitsWithoutBloodPlague
local UnitsWithoutShackleDebuff
local ghoul = HL.GhoulTable
local LastSpellCast

--Opener
local StartOfCombat

-- Player Covenant
-- 0: none, 1: Kyrian, 2: Venthyr, 3: Night Fae, 4: Necrolord
local CovenantID = Player:CovenantID()

-- Update CovenantID if we change Covenants
HL:RegisterForEvent(function()
  CovenantID = Player:CovenantID()
end, "COVENANT_CHOSEN")

-- Legendary
local CrimsonRuneWeaponEquipped = Player:HasLegendaryEquipped(35)

HL:RegisterForEvent(function()
  CrimsonRuneWeaponEquipped = Player:HasLegendaryEquipped(35)
end, "PLAYER_EQUIPMENT_CHANGED")

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.DeathKnight.Commons,
  Blood = WR.GUISettings.APL.DeathKnight.Blood
}

-- Stun Interrupts List
local StunInterrupts = {
  {S.Asphyxiate, "Cast Asphyxiate (Interrupt)", function () return true; end},
}

--Functions
local EnemyRanges = {5, 8, 10, 30}
local TargetIsInRange = {}
local function ComputeTargetRange()
  for _, i in ipairs(EnemyRanges) do
    if i == 8 or 5 then TargetIsInRange[i] = Target:IsInMeleeRange(i) end
    TargetIsInRange[i] = Target:IsInRange(i)
  end
end

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

local function UnitsWithoutBP(enemies)
  local WithoutBPCount = 0
  for _, CycleUnit in pairs(enemies) do
    if not CycleUnit:DebuffUp(S.BloodPlagueDebuff) then
      WithoutBPCount = WithoutBPCount + 1
    end
  end
  return WithoutBPCount
end

local function UnitsWithoutShackle(enemies)
  local WithoutShackleCount = 0
  for _, CycleUnit in pairs(enemies) do
    if not CycleUnit:DebuffUp(S.ShackleTheUnworthy) then
      WithoutShackleCount = WithoutShackleCount + 1
    end
  end
  return WithoutShackleCount
end

local function OutOfCombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  -- fleshcraftS
end

local function RemoveCC()
end
local function AntiMagicShellHandler()
end
local function Mitigation()
end
local function Interrupts()
end
local function Stun()
end
local function Healing()
  -- Active healing
  if Player:HealthPercentage() < 50 then
    if S.DeathStrike:IsReady() and Player:RunicPower() >= 45 and S.DeathStrike:TimeSinceLastCast() > 2.5 then
      if Cast(S.DeathStrike, nil, nil, not Target:IsSpellInRange(S.DeathStrike)) then 
        return "death_strike defensives 4"
      end
    end
  end
  if Player:HealthPercentage() < 20 then
    if S.DeathStrike:IsReady() and Player:RunicPower() >= 45 then
      if Cast(S.DeathStrike, nil, nil, not Target:IsSpellInRange(S.DeathStrike)) then 
        return "death_strike defensives 10"
      end
    end
  end  
end
local function Opener()
  --if in range for Marrow
  if Target:IsInMeleeRange(8) then
    if S.RaiseDead:IsCastable() then
      if Cast(S.RaiseDead) then
        LastSpellCast =  S.RaiseDead:Name()
        return "raise_dead opener 1"; 
      end
    end
    if S.SacrificialPact:IsReady() and ghoul.active() and Player:BuffRemains(S.DancingRuneWeaponBuff) > 4 and ghoul.remains() < 2 then
      if Cast(S.SacrificialPact) then 
        LastSpellCast =  S.SacrificialPact:Name()
        return "sacrificial_pact opener 1"; end
    end
    if S.DancingRuneWeapon:IsCastable() and Player:BuffDown(S.DancingRuneWeaponBuff) and S.DancingRuneWeapon:CooldownUp() then
      if Cast(S.DancingRuneWeapon) then 
        LastSpellCast =  S.DancingRuneWeapon:Name()
        return "dancing_rune_weapon opener 2"; end
    end
    if S.DancingRuneWeapon:CooldownRemains() > 15 and S.Tombstone:IsReady() and Player:BuffStack(S.BoneShieldBuff) >= 5 then
      if Cast(S.Tombstone) then 
        LastSpellCast =  S.Tombstone:Name()
        return "tombstone opener 3"; end
    end
    if S.Marrowrend:IsReady() and (Player:BuffRemains(S.BoneShieldBuff) <= Player:RuneTimeToX(3) or Player:BuffStack(S.BoneShieldBuff) < 2 ) then
      if Cast(S.Marrowrend, nil, nil, not Target:IsSpellInRange(S.Marrowrend)) then 
        LastSpellCast =  S.Marrowrend:Name()
        return "marrowrend opener 4"; end
    end
  end
end
local function Cooldowns()
end
local function Mitigation()
end


local function DRWUpSingle()
  -- blood_tap,if=(rune<=2&rune.time_to_4>gcd&charges_fractional>=1.8)|rune.time_to_3>gcd
  if S.BloodTap:IsCastable() and S.BloodTap:TimeSinceLastCast() > 2.5 and ((Player:Rune() <= 2 and Player:RuneTimeToX(4) > Player:GCD() and S.BloodTap:ChargesFractional() >= 1.8) or Player:RuneTimeToX(3) > Player:GCD()) then
    if Cast(S.BloodTap) then return "blood_tap main 12"; end
  end
  --Prio if we are running out of Time
  if Player:BuffRemains(S.DancingRuneWeaponBuff) < 4 and (not S.DancingRuneWeapon:IsReady() or S.DancingRuneWeapon:CooldownRemains() > 4) then
    if S.HeartStrike:IsReady() and Player:Rune() >= 1 and Player:BuffRemains(S.BoneShieldBuff) > 3 and Player:BuffStack(S.BoneShieldBuff) >= 2 then
      if Cast(S.HeartStrike, nil, nil, not Target:IsSpellInRange(S.HeartStrike)) then return "heart_strike drw_up 14"; end
    end
  end
  if S.DeathStrike:IsReady() and Player:RunicPower() >= 125 then
    if Cast(S.DeathStrike, nil, nil, not Target:IsSpellInRange(S.DeathStrike)) then return "death_strike drw_up 8"; end
  end
  if S.BloodBoil:IsCastable() and S.BloodTap:TimeSinceLastCast() > 2.5 and ((S.BloodBoil:Charges() >= 2 and Player:Rune() <= 1) or (Target:DebuffRemains(S.BloodPlagueDebuff) <= 2) and S.BloodBoil:Charges() >= 1)  then
    if Cast(S.BloodBoil, nil, nil, not Target:IsInMeleeRange(10)) then return "blood_boil drw_single 1"; end
  end
  if S.HeartStrike:IsReady() and (Player:Rune() >=6 or Player:RuneTimeToX(6) > Player:GCD()) then
    if Cast(S.HeartStrike, nil, nil, not Target:IsSpellInRange(S.HeartStrike)) then return "heart_strike drw_up 14"; end
  end
  VarHeartStrikeRPDRW = 25 + (HeartStrikeCount * 2)
  if S.DeathStrike:IsReady() and Player:Rune() < 3 and (((Player:RunicPowerDeficit() <= VarHeartStrikeRPDRW) or (Player:RunicPowerDeficit() <= VarDeathStrikeDumpAmt and CovenantID == 2))) then
    if Cast(S.DeathStrike, nil, nil, not Target:IsSpellInRange(S.DeathStrike)) then return "death_strike drw_up 8"; end
  end
  if S.HeartStrike:IsReady() and Player:Rune() >=2 and Player:BuffRemains(S.BoneShieldBuff) > 2 and Player:BuffStack(S.BoneShieldBuff) > 1 then
    if Cast(S.HeartStrike, nil, nil, not Target:IsSpellInRange(S.HeartStrike)) then return "heart_strike drw_up 14"; end
  end

  if S.DeathStrike:IsReady() and Player:RunicPower() >= 45 then
    if Cast(S.DeathStrike, nil, nil, not Target:IsSpellInRange(S.DeathStrike)) then return "death_strike drw_up 8"; end
  end
  if S.DeathAndDecay:IsCastable() and Player:BuffUp(S.CrimsonScourgeBuff) then
    if Cast(M.DeathAndDecayPlayer) then return "death_and_decay drw_up 10"; end
  end
end
local function DRWUpAoE()
  -- We are casting Bloodboil and DnD at the end of DRW when we should cast Shackle for keeping the buff going.
  if S.ShackleTheUnworthy:IsCastable() and Player:Rune() < 3 and Player:BuffRemains(S.DancingRuneWeaponBuff) < 4 then
    if Cast(S.ShackleTheUnworthy, not Target:IsSpellInRange(S.ShackleTheUnworthy)) then 
      LastSpellCast =  S.ShackleTheUnworthy:Name()
      return "shackle_the_unworthy opener 5"
    end
  end
  if S.BloodBoil:IsCastable() and (((S.BloodBoil:Charges() >= 2 and Player:Rune() <= 1) or Target:DebuffRemains(S.BloodPlagueDebuff) <= 2) or (EnemiesCount10y > 5 and S.BloodBoil:ChargesFractional() >= 1.1)) then
    if Cast(S.BloodBoil, nil, nil, not Target:IsInMeleeRange(10)) then 
      LastSpellCast =  S.BloodBoil:Name()
      return "blood_boil drw_up 6"
    end
  end
  if S.DeathAndDecay:IsCastable() and ((EnemiesCount10y == 3 and Player:BuffUp(S.CrimsonScourgeBuff)) or EnemiesCount10y >= 4) then
    if Cast(M.DeathAndDecayPlayer) then 
      LastSpellCast =  S.DeathAndDecay:Name()
      return "death_and_decay drw_up 10"
    end
  end
  if S.ShackleTheUnworthy:IsCastable() and UnitsWithoutShackleDebuff >= 2 then 
    if S.Marrowrend:IsReady() and Player:Rune() >= 2 and (Player:BuffRemains(S.BoneShieldBuff) <= 3 or Player:BuffStack(S.BoneShieldBuff) < 2 ) then
      if Cast(S.Marrowrend, nil, nil, not Target:IsSpellInRange(S.Marrowrend)) then 
        LastSpellCast =  S.Marrowrend:Name()
        return "marrowrend opener 4"
      end
    end
    --So lets just spam HS
    if S.HeartStrike:IsReady() and Player:Rune() > 1 and not (Player:BuffRemains(S.BoneShieldBuff) <= Player:RuneTimeToX(3) or Player:BuffStack(S.BoneShieldBuff) < 2) then
      if Cast(S.HeartStrike) then 
        LastSpellCast =  S.HeartStrike:Name()
        return "heart_strike drw_up 14"
      end
    end
  end
  if S.ShackleTheUnworthy:IsCastable() and Player:Rune() < 3 and S.ShackleTheUnworthy:CooldownUp() then 
    if Cast(S.ShackleTheUnworthy, not Target:IsSpellInRange(S.ShackleTheUnworthy)) then 
      LastSpellCast =  S.ShackleTheUnworthy:Name()
      return "shackle_the_unworthy opener 5"
    end
  end
  -- If target is shackledebuffed and unit close that is not Spam HS
  if S.HeartStrike:IsReady() and Target:DebuffUp(S.ShackleTheUnworthy) and UnitsWithoutShackleDebuff >= 1 then
    if Cast(S.HeartStrike) then 
      LastSpellCast =  S.HeartStrike:Name()
      return "heart_strike drw_up 14"
    end
  end
  if Player:BuffRemains(S.DancingRuneWeaponBuff) < 4 then 
    --Keep the buff flowing
    if S.BloodTap:IsCastable() and S.BloodTap:Charges() >= 2 and Player:Rune() < 3 then
      if Cast(S.BloodTap) then 
        LastSpellCast =  S.BloodTap:Name()
        return "blood_boil pre_drw 1"
      end
    end
    if S.HeartStrike:IsReady() and Player:Rune() >= 1 then
      if Cast(S.HeartStrike) then 
        LastSpellCast =  S.HeartStrike:Name()
        return "heart_strike drw_up 14"
      end
    end
    if S.BloodTap:IsCastable() and S.BloodTap:Charges() >= 1 then
      if Cast(S.BloodTap) then 
        LastSpellCast =  S.BloodTap:Name()
        return "blood_boil pre_drw 1"
      end
    end
  end
  if Player:BuffUp(S.DeathAndDecayBuff) and S.HeartStrike:IsReady() and Player:RuneTimeToX(2) < Player:GCD() and not (Player:BuffRemains(S.BoneShieldBuff) <= Player:RuneTimeToX(3) or Player:BuffStack(S.BoneShieldBuff) < 2) then
    if Cast(S.HeartStrike) then 
      LastSpellCast =  S.HeartStrike:Name()
      return "heart_strike drw_up 14"; end
  end
  if S.HeartStrike:IsReady() and not (Player:BuffRemains(S.BoneShieldBuff) <= Player:RuneTimeToX(3) or Player:BuffStack(S.BoneShieldBuff) < 2) then
    if Cast(S.HeartStrike) then 
      LastSpellCast =  S.HeartStrike:Name()
      return "heart_strike drw_up 14"; end
  end
  if S.DeathStrike:IsReady() and Player:RunicPower() >= 45 then
    if Cast(S.DeathStrike, nil, nil, not Target:IsSpellInRange(S.DeathStrike)) then 
      LastSpellCast =  S.DeathStrike:Name()
      return "death_strike drw_up 8"; end
  end
  VarHeartStrikeRPDRW = (25 + HeartStrikeCount * num(S.Heartbreaker:IsAvailable()) * 2)
  if S.HeartStrike:IsReady() and (Player:RuneTimeToX(2) < Player:GCD() or Player:RunicPowerDeficit() >= VarHeartStrikeRPDRW) then
    if Cast(S.HeartStrike, nil, nil, not Target:IsSpellInRange(S.HeartStrike)) then 
      LastSpellCast =  S.HeartStrike:Name()
      return "heart_strike drw_up 14"
    end
  end
  return "dont do anything"
end

local function StandardAoE()

  -- NEED TO FIX TOMBSTONE and BONESHIELD, We should cast Marrow if Tombstone is up and less then 5 BS
  --But should be done in opener so its handling all cases.
  if S.BloodBoil:IsCastable() and (((S.BloodBoil:Charges() >= 2 and Player:Rune() <= 1) or Target:DebuffRemains(S.BloodPlagueDebuff) <= 2) or (EnemiesCount10y > 5 and S.BloodBoil:ChargesFractional() >= 1.1)) then
    if Cast(S.BloodBoil, nil, nil, not Target:IsInMeleeRange(10)) then 
      LastSpellCast =  S.BloodBoil:Name()
      return "blood_boil drw_up 6"
    end
  end
  if S.DeathAndDecay:IsCastable() and ((EnemiesCount10y == 3 and Player:BuffUp(S.CrimsonScourgeBuff)) or EnemiesCount10y >= 4) then
    if Cast(M.DeathAndDecayPlayer) then 
      LastSpellCast =  S.DeathAndDecay:Name()
      return "death_and_decay drw_up 10"
    end
  end
  if S.ShackleTheUnworthy:IsCastable() and UnitsWithoutShackleDebuff >= 2 then 
    --So lets just spam HS
    if Player:BuffUp(S.DeathAndDecayBuff) and S.HeartStrike:IsReady() and Player:Rune() > 1 and not (Player:BuffRemains(S.BoneShieldBuff) <= Player:RuneTimeToX(3) or Player:BuffStack(S.BoneShieldBuff) < 2) then
      if Cast(S.HeartStrike) then 
        LastSpellCast =  S.HeartStrike:Name()
        return "heart_strike drw_up 14"; end
    end
  end
  if Player:BuffUp(S.DeathAndDecayBuff) then 
    --Keep the buff flowing
    if S.BloodTap:IsCastable() and S.BloodTap:Charges() >= 2 and Player:Rune() < 2 and not LastSpellCast == S.BloodTap:Name() then
      if Cast(S.BloodTap) then 
        LastSpellCast =  S.BloodTap:Name()
        return "blood_boil pre_drw 1"
      end
    end
    if S.HeartStrike:IsReady() and Player:Rune() >= 1 then
      if Cast(S.HeartStrike) then 
        LastSpellCast =  S.HeartStrike:Name()
        return "heart_strike drw_up 14"
      end
    end
    if S.BloodTap:IsCastable() and S.BloodTap:Charges() >= 1 and not LastSpellCast == S.BloodTap:Name() then
      if Cast(S.BloodTap) then 
        LastSpellCast =  S.BloodTap:Name()
        return "blood_boil pre_drw 1"
      end
    end
  end
  if S.ShackleTheUnworthy:IsCastable() and Player:Rune() <= 1 and S.ShackleTheUnworthy:CooldownUp() then 
    if Cast(S.ShackleTheUnworthy, not Target:IsSpellInRange(S.ShackleTheUnworthy)) then 
      LastSpellCast =  S.ShackleTheUnworthy:Name()
      return "shackle_the_unworthy opener 5"
    end
  end
  if Player:BuffUp(S.DeathAndDecayBuff) and S.HeartStrike:IsReady() and Player:RuneTimeToX(2) < Player:GCD() and not (Player:BuffRemains(S.BoneShieldBuff) <= Player:RuneTimeToX(3) or Player:BuffStack(S.BoneShieldBuff) < 2) then
    if Cast(S.HeartStrike, nil, nil, not Target:IsSpellInRange(S.HeartStrike)) then 
      LastSpellCast =  S.HeartStrike:Name()
      return "heart_strike drw_up 14"
    end
  end
  if S.DeathStrike:IsReady() and Player:RunicPower() >= 45 then
    if Cast(S.DeathStrike, nil, nil, not Target:IsSpellInRange(S.DeathStrike)) then 
      LastSpellCast =  S.DeathStrike:Name()
      return "heart_strike drw_up 14"
    end
  end
  if S.HeartStrike:IsReady() and (Player:Rune() > 1 and (Player:RuneTimeToX(3) < Player:GCD() or Player:BuffStack(S.BoneShieldBuff) > 7)) then
    if Cast(S.HeartStrike, nil, nil, not Target:IsSpellInRange(S.HeartStrike)) then 
      LastSpellCast =  S.HeartStrike:Name()
      return "heart_strike standard 28"
    end
  end
  return "dont do anything"
end
local function StandardSingle()
  if S.BloodBoil:IsCastable() and S.BloodTap:TimeSinceLastCast() > 2.5 and ((S.BloodBoil:Charges() >= 2 and Player:Rune() <= 1) or (Target:DebuffRemains(S.BloodPlagueDebuff) <= 2) and S.BloodBoil:Charges() >= 1)  then
    if Cast(S.BloodBoil, nil, nil, not Target:IsInMeleeRange(10)) then return "blood_boil drw_single 1"; end
  end
  -------------------
  -- Old Placeholder stuff
  --------------------
  -- heart_strike,if=covenant.night_fae&death_and_decay.ticking&(buff.deaths_due.up&buff.deaths_due.remains<6)
  if S.HeartStrike:IsReady() and (CovenantID == 3 and Player:BuffUp(S.DeathAndDecayBuff) and (Player:BuffUp(S.DeathsDueBuff) and Player:BuffRemains(S.DeathsDueBuff) < 6)) then
    if Cast(S.HeartStrike, not Target:IsSpellInRange(S.HeartStrike)) then return "heart_strike standard 2"; end
  end
  -- tombstone,if=buff.bone_shield.stack>5&rune>=2&runic_power.deficit>=30&!(covenant.venthyr&cooldown.swarming_mist.remains<3)
  if S.Tombstone:IsCastable() and (Player:BuffStack(S.BoneShieldBuff) > 5 and Player:Rune() >= 2 and Player:RunicPowerDeficit() >= 30 and not (CovenantID == 2 and S.SwarmingMist:CooldownRemains() < 3)) then
    if Cast(S.Tombstone) then return "tombstone standard 4"; end
  end
  -- marrowrend,if=(buff.bone_shield.remains<=rune.time_to_3|buff.bone_shield.remains<=(gcd+cooldown.blooddrinker.ready*talent.blooddrinker.enabled*4)|buff.bone_shield.stack<6|((!covenant.night_fae|buff.deaths_due.remains>5)&buff.bone_shield.remains<7))&runic_power.deficit>20&!(runeforge.crimson_rune_weapon&cooldown.dancing_rune_weapon.remains<buff.bone_shield.remains)
  if S.Marrowrend:IsReady() and ((Player:BuffRemains(S.BoneShieldBuff) <= Player:RuneTimeToX(3) or Player:BuffRemains(S.BoneShieldBuff) <= (Player:GCD() + num(S.Blooddrinker:CooldownUp()) * num(S.Blooddrinker:IsAvailable()) * 4) or Player:BuffStack(S.BoneShieldBuff) < 6 or ((CovenantID ~= 3 or Player:BuffRemains(S.DeathsDueBuff) > 5) and Player:BuffRemains(S.BoneShieldBuff) < 7)) and Player:RunicPowerDeficit() > 20 and not (CrimsonRuneWeaponEquipped and S.DancingRuneWeapon:CooldownRemains() < Player:BuffRemains(S.BoneShieldBuff))) then
    if Cast(S.Marrowrend, not Target:IsSpellInRange(S.Marrowrend)) then return "marrowrend standard 6"; end
  end
  -- death_strike,if=runic_power.deficit<=variable.death_strike_dump_amount&!(talent.bonestorm.enabled&cooldown.bonestorm.remains<2)&!(covenant.venthyr&cooldown.swarming_mist.remains<3)
  if S.DeathStrike:IsReady() and (Player:RunicPowerDeficit() <= VarDeathStrikeDumpAmt and (not (S.Bonestorm:IsAvailable() and S.Bonestorm:CooldownRemains() < 2)) and not (CovenantID == 2 and S.SwarmingMist:CooldownRemains() < 3)) then
    if Cast(S.DeathStrike, not Target:IsSpellInRange(S.DeathStrike)) then return "death_strike standard 8"; end
  end
  -- blood_boil,if=charges_fractional>=1.8&(buff.hemostasis.stack<=(5-spell_targets.blood_boil)|spell_targets.blood_boil>2)
  if S.BloodBoil:IsCastable() and (S.BloodBoil:ChargesFractional() >= 1.8 and Player:BuffStack(S.HemostasisBuff) <= 4) then
    if Cast(S.BloodBoil, not Target:IsInMeleeRange(10)) then return "blood_boil standard 10"; end
  end
  -- death_and_decay,if=buff.crimson_scourge.up&talent.relish_in_blood.enabled&runic_power.deficit>10
  if S.DeathAndDecay:IsReady() and ((Player:BuffUp(S.CrimsonScourgeBuff) and S.RelishinBlood:IsAvailable()) and Player:RunicPowerDeficit() > 10) then
    if Cast(M.DeathAndDecayPlayer, not Target:IsInRange(30)) then return "death_and_decay standard 12"; end
  end
  -- bonestorm,if=runic_power>=100&!(covenant.venthyr&cooldown.swarming_mist.remains<3)
  if S.Bonestorm:IsReady() and (Player:RunicPower() >= 100 and not (CovenantID == 2 and S.SwarmingMist:CooldownRemains() < 3)) then
    if Cast(S.Bonestorm, not Target:IsInRange(8)) then return "bonestorm standard 14"; end
  end
  -- variable,name=heart_strike_rp,value=(15+spell_targets.heart_strike*talent.heartbreaker.enabled*2),op=setif,condition=covenant.night_fae&death_and_decay.ticking,value_else=(15+spell_targets.heart_strike*talent.heartbreaker.enabled*2)*1.2
  if (CovenantID == 3 and Player:BuffUp(S.DeathAndDecayBuff)) then
    VarHeartStrikeRP = (15 + EnemiesMeleeCount * num(S.Heartbreaker:IsAvailable()) * 2)
  else
    VarHeartStrikeRP = (15 + EnemiesMeleeCount * num(S.Heartbreaker:IsAvailable()) * 2) * 1.2
  end
  -- death_strike,if=(runic_power.deficit<=variable.heart_strike_rp)|target.time_to_die<10
  if S.DeathStrike:IsReady() and ((Player:RunicPowerDeficit() <= VarHeartStrikeRP) or Target:TimeToDie() < 10) then
    if Cast(S.DeathStrike, not Target:IsSpellInRange(S.DeathStrike)) then return "death_strike standard 16"; end
  end
  -- heart_strike,if=rune.time_to_4<gcd
  if S.HeartStrike:IsReady() and (Player:RuneTimeToX(4) < Player:GCD()) then
    if Cast(S.HeartStrike, not Target:IsSpellInRange(S.HeartStrike)) then return "heart_strike standard 20"; end
  end
  -- death_and_decay,if=buff.crimson_scourge.up|talent.rapid_decomposition.enabled
  if S.DeathAndDecay:IsReady() and (Player:BuffUp(S.CrimsonScourgeBuff) or S.RapidDecomposition:IsAvailable()) then
    if Cast(M.DeathAndDecayPlayer, not Target:IsInRange(30)) then return "death_and_decay standard 22"; end
  end
  -- consumption
  if S.Consumption:IsCastable() then
    if Cast(S.Consumption, not Target:IsSpellInRange(S.Consumption)) then return "consumption standard 24"; end
  end
  -- blood_boil,if=charges_fractional>=1.1
  if S.BloodBoil:IsCastable() and (S.BloodBoil:ChargesFractional() >= 1.1) then
    if Cast(S.BloodBoil, not Target:IsInMeleeRange(10)) then return "blood_boil standard 26"; end
  end
  -- heart_strike,if=(rune>1&(rune.time_to_3<gcd|buff.bone_shield.stack>7))
  if S.HeartStrike:IsReady() and (Player:Rune() > 1 and (Player:RuneTimeToX(3) < Player:GCD() or Player:BuffStack(S.BoneShieldBuff) > 7)) then
    if Cast(S.HeartStrike, not Target:IsSpellInRange(S.HeartStrike)) then return "heart_strike standard 28"; end
  end

end


--- ======= ACTION LISTS =======
local function APL()
  -- Get Enemies Count
  Enemies10y          = Player:GetEnemiesInRange(10)
  if AoEON() then
    EnemiesMelee      = Player:GetEnemiesInMeleeRange(8)
    EnemiesMeleeCount = #EnemiesMelee
    EnemiesCount10y   = #Enemies10y
  else
    EnemiesMeleeCount = 1
    EnemiesCount10y   = 1
  end

  -- HeartStrike is limited to 5 targets maximum
  HeartStrikeCount = mathmin(EnemiesMeleeCount, Player:BuffUp(S.DeathAndDecayBuff) and 5 or 2)

  -- Check Units without Blood Plague
  UnitsWithoutBloodPlague = UnitsWithoutBP(Enemies10y)

  UnitsWithoutShackleDebuff =  UnitsWithoutShackle(Enemies10y)

  -- Are we actively tanking?
  IsTanking = Player:IsTankingAoE(8) or Player:IsTanking(Target)

  VarDeathStrikeDumpAmt = (CovenantID == 3) and 55 or 70
  --VarDeathStrikeCost    = (Player:BuffUp(Ossuary)) and 40 or 45

  if Player:AffectingCombat() then
    local ShouldReturn = RemoveCC(); if ShouldReturn then return ShouldReturn; end
    local ShouldReturn = AntiMagicShellHandler(); if ShouldReturn then return ShouldReturn; end
    local ShouldReturn = Mitigation(); if ShouldReturn then return ShouldReturn; end
    local ShouldReturn = Interrupts(); if ShouldReturn then return ShouldReturn; end
    local ShouldReturn = Stun(); if ShouldReturn then return ShouldReturn; end
    local ShouldReturn = Healing(); if ShouldReturn then return ShouldReturn; end
    local ShouldReturn = Opener(); if ShouldReturn then return ShouldReturn; end
    local ShouldReturn = Cooldowns(); if ShouldReturn then return ShouldReturn; end    
    if Player:BuffUp(S.DancingRuneWeaponBuff) and EnemiesCount10y <= 2 then
      local ShouldReturn = DRWUpSingle(); if ShouldReturn then return ShouldReturn; end
    end
    if Player:BuffUp(S.DancingRuneWeaponBuff) and EnemiesCount10y >= 3 then
        local ShouldReturn = DRWUpAoE(); if ShouldReturn then return ShouldReturn; end    
    end
    if EnemiesCount10y <= 2 then
      --local ShouldReturn = StandardSingle(); if ShouldReturn then return ShouldReturn; end
    end
    if EnemiesCount10y >= 3 then  
      local ShouldReturn = StandardAoE(); if ShouldReturn then return ShouldReturn; end
    end
  end
  -- OutOfCombat
  if not Player:AffectingCombat() then
    local ShouldReturn = OutOfCombat(); if ShouldReturn then return ShouldReturn; end
  end
end

local function AutoBind()
  -- Bind Spells
  WR.Bind(S.Asphyxiate)
  WR.Bind(S.BloodBoil)
  WR.Bind(S.DancingRuneWeapon)
  WR.Bind(S.DeathsCaress)
  WR.Bind(S.HeartStrike)
  WR.Bind(S.IceboundFortitude)
  WR.Bind(S.Marrowrend)
  WR.Bind(S.RuneTap)
  WR.Bind(S.VampiricBlood)
  WR.Bind(S.DeathAndDecay)
  WR.Bind(S.DeathStrike)
  WR.Bind(S.RaiseDead)
  WR.Bind(S.SacrificialPact)
  -- Covenant Abilities
  WR.Bind(S.AbominationLimb)
  WR.Bind(S.DeathsDue)
  WR.Bind(S.Fleshcraft)
  WR.Bind(S.ShackleTheUnworthy)
  WR.Bind(S.SwarmingMist)
  
  -- Talents
  WR.Bind(S.Blooddrinker)
  WR.Bind(S.BloodTap)
  WR.Bind(S.Bonestorm)
  WR.Bind(S.Consumption)
  WR.Bind(S.Tombstone)
  
  
  
  -- Bind Items
  WR.Bind(M.Trinket1)
  WR.Bind(M.Trinket2)
  WR.Bind(M.Healthstone)
  WR.Bind(M.PhialofSerenity)
  WR.Bind(M.PotionofSpectralStrength)
  
  -- Bind Macros
  WR.Bind(M.DeathAndDecayPlayer)
end

local function Init()
  WR.Print("Blood DeathKnight by Gabbz")
  AutoBind()
end

WR.SetAPL(250, APL, Init)
