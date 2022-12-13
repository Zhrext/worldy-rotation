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
local Action     = HL.Action
-- WorldyRotation
local WR         = WorldyRotation
local Macro      = WR.Macro
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Cast       = WR.Cast
-- Lua
local mathmax    = math.max


--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- Commons
local Everyone = WR.Commons.Everyone
local Hunter = WR.Commons.Hunter

-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Hunter.Commons,
  Commons2 = WR.GUISettings.APL.Hunter.Commons2,
  BeastMastery = WR.GUISettings.APL.Hunter.BeastMastery
}

-- Spells
local S = Spell.Hunter.BeastMastery;
local SummonPetSpells = { S.SummonPet, S.SummonPet2, S.SummonPet3, S.SummonPet4, S.SummonPet5 }

-- Items
local I = Item.Hunter.BeastMastery;
local OnUseExcludes = {
  --  I.TrinketName:ID(),
}

-- Macros
local M = Macro.Hunter.BeastMastery;

-- Usable Item Objects
local equip = Player:GetEquipment()
local finger1 = (equip[11]) and Item(equip[11]) or Item(0)
local finger2 = (equip[12]) and Item(equip[12]) or Item(0)

-- Check for equipment changes
HL:RegisterForEvent(function()
  equip = Player:GetEquipment()
  finger1 = (equip[11]) and Item(equip[11]) or Item(0)
  finger2 = (equip[12]) and Item(equip[12]) or Item(0)
end, "PLAYER_EQUIPMENT_CHANGED")

-- Rotation Variables
local GCDMax
local BossFightRemains = 11111
local FightRemains = 11111

-- Reset variables after combat
HL:RegisterForEvent(function()
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

-- Enemies
local Enemies40y, PetEnemiesMixedy, PetEnemiesMixedyCount

-- Range
local TargetInRange40y, TargetInRange30y
local TargetInRangePet30y

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

local function EvaluateTargetIfFilterBarbedShot(TargetUnit)
  -- target_if=min:dot.barbed_shot.remains
  return (TargetUnit:DebuffRemains(S.BarbedShotDebuff))
end

local function EvaluateTargetIfFilterLatentPoison(TargetUnit)
  -- target_if=max:debuff.latent_poison.stack
  return (TargetUnit:DebuffStack(S.LatentPoisonDebuff))
end

local function EvaluateTargetIfFilterSerpentSting(TargetUnit)
  -- target_if=min:remains
  return (TargetUnit:DebuffRemains(S.SerpentStingDebuff))
end

local function EvaluateTargetIfBarbedShotCleave(TargetUnit)
  --if=debuff.latent_poison.stack>9&(pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd+0.25|talent.scent_of_blood&cooldown.bestial_wrath.remains<12+gcd|full_recharge_time<gcd&cooldown.bestial_wrath.remains)
  return (TargetUnit:DebuffStack(S.LatentPoisonDebuff) > 9 and (Pet:BuffUp(S.FrenzyPetBuff) and Pet:BuffRemains(S.FrenzyPetBuff) <= GCDMax + 0.25 or S.ScentofBlood:IsAvailable() and S.BestialWrath:CooldownRemains() < 12 + GCDMax or S.BarbedShot:FullRechargeTime() < GCDMax and S.BestialWrath:CooldownDown()))
end

local function EvaluateTargetIfBarbedShotCleave2(TargetUnit)
  -- if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd+0.25|talent.scent_of_blood&cooldown.bestial_wrath.remains<12+gcd|full_recharge_time<gcd&cooldown.bestial_wrath.remains
  return (Pet:BuffUp(S.FrenzyPetBuff) and Pet:BuffRemains(S.FrenzyPetBuff) <= GCDMax + 0.25 or S.ScentofBlood:IsAvailable() and S.BestialWrath:CooldownRemains() < 12 + GCDMax or S.BarbedShot:FullRechargeTime() < GCDMax and S.BestialWrath:CooldownDown())
end

local function EvaluateTargetIfBarbedShotCleave3(TargetUnit)
  -- if=debuff.latent_poison.stack>9&(talent.wild_instincts&buff.call_of_the_wild.up|fight_remains<9|talent.wild_call&charges_fractional>1.2)
  return (TargetUnit:DebuffStack(S.LatentPoisonDebuff) > 9 and (S.WildInstincts:IsAvailable() and Player:BuffUp(S.CalloftheWildBuff) or FightRemains < 9 or S.WildCall:IsAvailable() and S.BarbedShot:ChargesFractional() > 1.2))
end

local function EvaluateTargetIfBarbedShotCleave4(TargetUnit)
  -- if=talent.wild_instincts&buff.call_of_the_wild.up|fight_remains<9|talent.wild_call&charges_fractional>1.2
  return (S.WildInstincts:IsAvailable() and Player:BuffUp(S.CalloftheWildBuff) or FightRemains < 9 or S.WildCall:IsAvailable() and S.BarbedShot:ChargesFractional() > 1.2)
end

local function EvaluateTargetIfSerpentStingCleave(TargetUnit)
  -- if=refreshable&target.time_to_die>duration
  return (TargetUnit:DebuffRefreshable(S.SerpentStingDebuff) and TargetUnit:TimeToDie() > S.SerpentStingDebuff:BaseDuration())
end

local function EvaluateTargetIfBarbedShotST(TargetUnit)
  -- if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd+0.25|talent.scent_of_blood&pet.main.buff.frenzy.stack<3&cooldown.bestial_wrath.ready
  return (Pet:BuffUp(S.FrenzyPetBuff) and Pet:BuffRemains(S.FrenzyPetBuff) <= GCDMax + 0.25 or S.ScentofBlood:IsAvailable() and Pet:BuffStack(S.FrenzyPetBuff) < 3 and S.BestialWrath:CooldownUp())
end

local function EvaluateTargetIfBarbedShotST2(TargetUnit)
  -- if=talent.wild_instincts&buff.call_of_the_wild.up|talent.wild_call&charges_fractional>1.4|full_recharge_time<gcd&cooldown.bestial_wrath.remains|talent.scent_of_blood&(cooldown.bestial_wrath.remains<12+gcd|full_recharge_time+gcd<8&cooldown.bestial_wrath.remains<24+(8-gcd)+full_recharge_time)|fight_remains<9
  return (S.WildInstincts:IsAvailable() and Player:BuffUp(S.CalloftheWildBuff) or S.WildCall:IsAvailable() and S.BarbedShot:ChargesFractional() > 1.4 or S.BarbedShot:FullRechargeTime() < GCDMax and S.BestialWrath:CooldownDown() or S.ScentofBlood:IsAvailable() and (S.BestialWrath:CooldownRemains() < 12 + GCDMax or S.BarbedShot:FullRechargeTime() + GCDMax < 8 and S.BestialWrath:CooldownRemains() < 24 + (8 - GCDMax) + S.BarbedShot:FullRechargeTime()) or FightRemains < 9)
end

local function EvaluateTargetIfSerpentStingST(TargetUnit)
  -- if=refreshable&target.time_to_die>duration
  return (TargetUnit:DebuffRefreshable(S.SerpentStingDebuff) and Target:TimeToDie() > S.SerpentStingDebuff:BaseDuration())
end

--- ======= ACTION LISTS =======
local function Precombat()
  -- flask
  -- augmentation
  -- food
  -- summon_pet
  -- Handled in APL()
  -- snapshot_stats
  -- misdirection
  if Focus:Exists() and S.Misdirection:IsReady() then
    if WR.Press(M.MisdirectionFocus) then return "misdirection precombat 0"; end
  end
  -- steel_trap,precast_time=1.5,if=!talent.wailing_arrow&talent.steel_trap
  if S.SteelTrap:IsCastable() and ((not S.WailingArrow:IsAvailable()) and S.SteelTrap:IsAvailable()) then
    if Cast(S.SteelTrap, Settings.Commons2.GCDasOffGCD.SteelTrap) then return "steel_trap precombat 2"; end
  end
  -- Manually added opener abilities
  -- Barbed Shot
  if S.BarbedShot:IsCastable() and S.BarbedShot:Charges() >= 2 then
    if Cast(S.BarbedShot) then return "barbed_shot precombat 8"; end
  end
  -- Kill Shot
  if S.KillShot:IsReady() then
    if Cast(S.KillShot) then return "kill_shot precombat 10"; end
  end
  -- Kill Command
  if S.KillCommand:IsReady() and TargetInRangePet30y then
    if Cast(S.KillCommand) then return "kill_command precombat 12"; end
  end
  if PetEnemiesMixedyCount > 1 then
    -- Multi Shot
    if S.MultiShot:IsReady()  then
      if Cast(S.MultiShot) then return "multishot precombat 14"; end
    end
  else
    -- Cobra Shot
    if S.CobraShot:IsReady()  then
      if Cast(S.CobraShot) then return "cobra_shot precombat 16"; end
    end
  end
end

local function CDs()
  -- berserking,if=!talent.bestial_wrath|buff.bestial_wrath.up|fight_remains<16
  if S.Berserking:IsCastable() and ((not S.BestialWrath:IsAvailable()) or Player:BuffUp(S.BestialWrathBuff) or FightRemains < 16) then
    if Cast(S.Berserking, Settings.Commons.GCDasOffGCD.Racials) then return "berserking cds 2"; end
  end
  -- use_items,slots=trinket1,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<31
  -- use_items,slots=trinket2,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<31
  -- Moved to Trinkets() so trinkets aren't relying on CDsON
  -- blood_fury,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<16
  if S.BloodFury:IsCastable() and (Player:BuffUp(S.CalloftheWildBuff) or (not S.CalloftheWild:IsAvailable()) and (Player:BuffUp(S.BestialWrathBuff) and (Player:BloodlustUp() or Target:HealthPercentage() < 20)) or FightRemains < 16) then
    if Cast(S.BloodFury, Settings.Commons.GCDasOffGCD.Racials) then return "blood_fury cds 8"; end
  end
  -- ancestral_call,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<16
  if S.AncestralCall:IsCastable() and (Player:BuffUp(S.CalloftheWildBuff) or (not S.CalloftheWild:IsAvailable()) and (Player:BuffUp(S.BestialWrathBuff) and (Player:BloodlustUp() or Target:HealthPercentage() < 20)) or FightRemains < 16) then
    if Cast(S.AncestralCall, Settings.Commons.GCDasOffGCD.Racials) then return "ancestral_call cds 10"; end
  end
  -- fireblood,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<10
  if S.Fireblood:IsCastable() and (Player:BuffUp(S.CalloftheWildBuff) or (not S.CalloftheWild:IsAvailable()) and (Player:BuffUp(S.BestialWrathBuff) and (Player:BloodlustUp() or Target:HealthPercentage() < 20)) or FightRemains < 10) then
    if Cast(S.Fireblood, Settings.Commons.GCDasOffGCD.Racials) then return "fireblood cds 12"; end
  end
  -- potion,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<31
  if Settings.Commons.Enabled.Potions and (Player:BuffUp(S.CalloftheWildBuff) or (not S.CalloftheWild:IsAvailable()) and (Player:BuffUp(S.BestialWrathBuff) and (Player:BloodlustUp() or Target:HealthPercentage() < 20)) or FightRemains < 31) then
    local PotionSelected = Everyone.PotionSelected()
    if PotionSelected and PotionSelected:IsReady() then
      if Cast(PotionSelected, nil, Settings.Commons.DisplayStyle.Potions) then return "potion cds 14"; end
    end
  end
end

local function Trinkets()
  -- use_items,slots=trinket1,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<31
  local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
  if Trinket1ToUse and (Player:BuffUp(S.CalloftheWildBuff) or (not S.CalloftheWild:IsAvailable()) and (Player:BuffUp(S.BestialWrathBuff) and (Player:BloodlustUp() or Target:HealthPercentage() < 20)) or FightRemains < 31) then
    if WR.Press(M.Trinket1, nil, nil, true) then return "trinket1 cds 4"; end
  end
  -- use_items,slots=trinket2,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<31
  local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
  if Trinket2ToUse and (Player:BuffUp(S.CalloftheWildBuff) or (not S.CalloftheWild:IsAvailable()) and (Player:BuffUp(S.BestialWrathBuff) and (Player:BloodlustUp() or Target:HealthPercentage() < 20)) or FightRemains < 31) then
    if WR.Press(M.Trinket2, nil, nil, true) then return "trinket2 cds 6"; end
  end
end

local function Cleave()
  -- barbed_shot,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>9&(pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd+0.25|talent.scent_of_blood&cooldown.bestial_wrath.remains<12+gcd|full_recharge_time<gcd&cooldown.bestial_wrath.remains)
  if S.BarbedShot:IsCastable() then
    if Everyone.CastTargetIf(S.BarbedShot, Enemies40y, "max", EvaluateTargetIfFilterLatentPoison, EvaluateTargetIfBarbedShotCleave, not Target:IsSpellInRange(S.BarbedShot), nil, nil, M.BarbedShotMouseover) then return "barbed_shot cleave 2"; end
  end
  -- barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd+0.25|talent.scent_of_blood&cooldown.bestial_wrath.remains<12+gcd|full_recharge_time<gcd&cooldown.bestial_wrath.remains
  if S.BarbedShot:IsCastable() then
    if Everyone.CastTargetIf(S.BarbedShot, Enemies40y, "min", EvaluateTargetIfFilterBarbedShot, EvaluateTargetIfBarbedShotCleave2, not Target:IsSpellInRange(S.BarbedShot), nil, nil, M.BarbedShotMouseover) then return "barbed_shot cleave 4"; end
  end
  -- multishot,if=gcd-pet.main.buff.beast_cleave.remains>0.25
  if S.MultiShot:IsReady() and (GCDMax - Pet:BuffRemains(S.BeastCleavePetBuff) > 0.25) then
    if Cast(S.MultiShot, nil, nil, not Target:IsSpellInRange(S.MultiShot)) then return "multishot cleave 6"; end
  end
  -- kill_command,if=full_recharge_time<gcd&talent.alpha_predator&talent.kill_cleave
  if S.KillCommand:IsReady() and (S.KillCommand:FullRechargeTime() < GCDMax and S.AlphaPredator:IsAvailable() and S.KillCleave:IsAvailable()) then
    if Cast(S.KillCommand, nil, nil, not Target:IsInRange(50)) then return "kill_command cleave 8"; end
  end
  -- call_of_the_wild
  if S.CalloftheWild:IsCastable() and CDsON() then
    if Cast(S.CalloftheWild, Settings.BeastMastery.GCDasOffGCD.CallOfTheWild) then return "call_of_the_wild cleave 10"; end
  end
  -- explosive_shot
  if S.ExplosiveShot:IsReady() then
    if Cast(S.ExplosiveShot, nil, nil, not Target:IsSpellInRange(S.ExplosiveShot)) then return "explosive_shot cleave 12"; end
  end
  -- stampede,if=buff.bestial_wrath.up|target.time_to_die<15
  if S.Stampede:IsCastable() and CDsON() and (Player:BuffUp(S.BestialWrathBuff) or FightRemains < 15) then
    if Cast(S.Stampede, Settings.Commons2.GCDasOffGCD.Stampede, nil, not Target:IsSpellInRange(S.Stampede)) then return "stampede cleave 14"; end
  end
  -- bloodshed
  if S.Bloodshed:IsCastable() then
    if Cast(S.Bloodshed, nil, nil, not Target:IsSpellInRange(S.Bloodshed)) then return "bloodshed cleave 16"; end
  end
  -- death_chakram
  if S.DeathChakram:IsCastable() then
    if Cast(S.DeathChakram, nil, nil, not Target:IsSpellInRange(S.DeathChakram)) then return "death_chakram cleave 18"; end
  end
  -- bestial_wrath
  if S.BestialWrath:IsCastable() and CDsON() then
    if Cast(S.BestialWrath, Settings.BeastMastery.GCDasOffGCD.BestialWrath) then return "bestial_wrath cleave 20"; end
  end
  -- steel_trap
  if S.SteelTrap:IsCastable() then
    if Cast(S.SteelTrap, Settings.Commons2.GCDasOffGCD.SteelTrap) then return "steel_trap cleave 22"; end
  end
  -- a_murder_of_crows
  if S.AMurderofCrows:IsReady() then
    if Cast(S.AMurderofCrows, Settings.BeastMastery.GCDasOffGCD.AMurderOfCrows, nil, not Target:IsSpellInRange(S.AMurderofCrows)) then return "a_murder_of_crows cleave 24"; end
  end
  -- barbed_shot,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>9&(talent.wild_instincts&buff.call_of_the_wild.up|fight_remains<9|talent.wild_call&charges_fractional>1.2)
  if S.BarbedShot:IsCastable() then
    if Everyone.CastTargetIf(S.BarbedShot, Enemies40y, "max", EvaluateTargetIfFilterLatentPoison, EvaluateTargetIfBarbedShotCleave3, not Target:IsSpellInRange(S.BarbedShot), nil, nil, M.BarbedShotMouseover) then return "barbed_shot cleave 26"; end
  end
  -- barbed_shot,target_if=min:dot.barbed_shot.remains,if=talent.wild_instincts&buff.call_of_the_wild.up|fight_remains<9|talent.wild_call&charges_fractional>1.2
  if S.BarbedShot:IsCastable() then
    if Everyone.CastTargetIf(S.BarbedShot, Enemies40y, "min", EvaluateTargetIfFilterBarbedShot, EvaluateTargetIfBarbedShotCleave4, not Target:IsSpellInRange(S.BarbedShot), nil, nil, M.BarbedShotMouseover) then return "barbed_shot cleave 28"; end
  end
  -- kill_command
  if S.KillCommand:IsReady() then
    if Cast(S.KillCommand, nil, nil, not Target:IsInRange(50)) then return "kill_command cleave 30"; end
  end
  -- dire_beast
  if S.DireBeast:IsCastable() then
    if Cast(S.DireBeast, Settings.BeastMastery.GCDasOffGCD.DireBeast, nil, not Target:IsSpellInRange(S.DireBeast)) then return "dire_beast cleave 32"; end
  end
  -- serpent_sting,target_if=min:remains,if=refreshable&target.time_to_die>duration
  if S.SerpentSting:IsReady() then
    if Everyone.CastTargetIf(S.SerpentSting, Enemies40y, "min", EvaluateTargetIfFilterSerpentSting, EvaluateTargetIfSerpentStingCleave, not Target:IsSpellInRange(S.SerpentSting), nil, nil, M.SerpentStingMouseover) then return "serpent_sting cleave 34"; end
  end
  -- barrage,if=pet.main.buff.frenzy.remains>execute_time
  if S.Barrage:IsReady() and (Pet:BuffRemains(S.FrenzyPetBuff) > S.Barrage:ExecuteTime()) then
    if Cast(S.Barrage, nil, nil, not Target:IsSpellInRange(S.Barrage)) then return "barrage cleave 36"; end
  end
  -- kill_shot
  if S.KillShot:IsReady() then
    if Cast(S.KillShot, nil, nil, not Target:IsSpellInRange(S.KillShot)) then return "kill_shot cleave 38"; end
  end
  -- kill_shot_mouseover
  if Mouseover:Exists() and S.KillShot:IsCastable() and Mouseover:HealthPercentage() <= 20  then
    if WR.Press(M.KillShotMouseover, not Mouseover:IsSpellInRange(S.KillShot)) then return "kill_shot_mouseover cleave 38"; end
  end
  -- aspect_of_the_wild
  if S.AspectoftheWild:IsCastable() and CDsON() then
    if Cast(S.AspectoftheWild, Settings.BeastMastery.OffGCDasOffGCD.AspectOfTheWild) then return "aspect_of_the_wild cleave 40"; end
  end
  -- cobra_shot,if=focus.time_to_max<gcd*2|buff.aspect_of_the_wild.up&focus.time_to_max<gcd*4
  if S.CobraShot:IsReady() and (Player:FocusTimeToMax() < GCDMax * 2 or Player:BuffUp(S.AspectoftheWildBuff) and Player:FocusTimeToMax() < GCDMax * 4) then
    if Cast(S.CobraShot, nil, nil, not Target:IsSpellInRange(S.CobraShot)) then return "cobra_shot cleave 42"; end
  end
  -- wailing_arrow,if=pet.main.buff.frenzy.remains>execute_time|fight_remains<5
  if S.WailingArrow:IsReady() and (Pet:BuffRemains(S.FrenzyPetBuff) > S.WailingArrow:ExecuteTime() or FightRemains < 5) then
    if WR.Press(S.WailingArrow, not Target:IsSpellInRange(S.WailingArrow), true) then return "wailing_arrow cleave 44"; end
  end
  -- bag_of_tricks,if=buff.bestial_wrath.down|target.time_to_die<5
  if S.BagofTricks:IsCastable() and CDsON() and (Player:BuffDown(S.BestialWrathBuff) or FightRemains < 5) then
    if Cast(S.BagofTricks, Settings.Commons.GCDasOffGCD.Racials) then return "bag_of_tricks cleave 46"; end
  end
  -- arcane_torrent,if=(focus+focus.regen+30)<focus.max
  if S.ArcaneTorrent:IsCastable() and CDsON() and ((Player:Focus() + Player:FocusRegen() + 30) < Player:FocusMax()) then
    if Cast(S.ArcaneTorrent, Settings.Commons.GCDasOffGCD.Racials) then return "arcane_torrent cleave 48"; end
  end
end

local function ST()
  -- barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd+0.25|talent.scent_of_blood&pet.main.buff.frenzy.stack<3&cooldown.bestial_wrath.ready
  if S.BarbedShot:IsCastable() then
    if Everyone.CastTargetIf(S.BarbedShot, Enemies40y, "min", EvaluateTargetIfFilterBarbedShot, EvaluateTargetIfBarbedShotST, not Target:IsSpellInRange(S.BarbedShot), nil, nil, M.BarbedShotMouseover) then return "barbed_shot st 2"; end
  end
  -- kill_command,if=full_recharge_time<gcd&talent.alpha_predator
  if S.KillCommand:IsReady() and (S.KillCommand:FullRechargeTime() < GCDMax and S.AlphaPredator:IsAvailable()) then
    if Cast(S.KillCommand, nil, nil, not Target:IsInRange(50)) then return "kill_command st 4"; end
  end
  -- call_of_the_wild
  if S.CalloftheWild:IsCastable() and CDsON() then
    if Cast(S.CalloftheWild, Settings.BeastMastery.GCDasOffGCD.CallOfTheWild) then return "call_of_the_wild st 6"; end
  end
  -- death_chakram
  if S.DeathChakram:IsCastable() then
    if Cast(S.DeathChakram, nil, nil, not Target:IsSpellInRange(S.DeathChakram)) then return "death_chakram st 8"; end
  end
  -- bloodshed
  if S.Bloodshed:IsCastable() then
    if Cast(S.Bloodshed, Settings.Commons.GCDasOffGCD.Bloodshed, nil, not Target:IsSpellInRange(S.Bloodshed)) then return "bloodshed st 10"; end
  end
  -- stampede
  if S.Stampede:IsCastable() and CDsON() then
    if Cast(S.Stampede, Settings.Commons2.GCDasOffGCD.Stampede, nil, not Target:IsSpellInRange(S.Stampede)) then return "stampede st 12"; end
  end
  -- a_murder_of_crows
  if S.AMurderofCrows:IsCastable() then
    if Cast(S.AMurderofCrows, Settings.BeastMastery.GCDasOffGCD.AMurderOfCrows, nil, not Target:IsSpellInRange(S.AMurderofCrows)) then return "a_murder_of_crows st 14"; end
  end
  -- steel_trap
  if S.SteelTrap:IsCastable() then
    if Cast(S.SteelTrap, Settings.Commons2.GCDasOffGCD.SteelTrap) then return "steel_trap st 16"; end
  end
  -- explosive_shot
  if S.ExplosiveShot:IsReady() then
    if Cast(S.ExplosiveShot, nil, nil, not Target:IsSpellInRange(S.ExplosiveShot)) then return "explosive_shot st 18"; end
  end
  -- bestial_wrath
  if S.BestialWrath:IsCastable() and CDsON() then
    if Cast(S.BestialWrath, Settings.BeastMastery.GCDasOffGCD.BestialWrath) then return "bestial_wrath st 20"; end
  end
  -- kill_command
  if S.KillCommand:IsReady() then
    if Cast(S.KillCommand, nil, nil, not Target:IsInRange(50)) then return "kill_command st 22"; end
  end
  -- barbed_shot,target_if=min:dot.barbed_shot.remains,if=talent.wild_instincts&buff.call_of_the_wild.up|talent.wild_call&charges_fractional>1.4|full_recharge_time<gcd&cooldown.bestial_wrath.remains|talent.scent_of_blood&(cooldown.bestial_wrath.remains<12+gcd|full_recharge_time+gcd<8&cooldown.bestial_wrath.remains<24+(8-gcd)+full_recharge_time)|fight_remains<9
  if S.BarbedShot:IsCastable() then
    if Everyone.CastTargetIf(S.BarbedShot, Enemies40y, "min", EvaluateTargetIfFilterBarbedShot, EvaluateTargetIfBarbedShotST2, not Target:IsSpellInRange(S.BarbedShot), nil, nil, M.BarbedShotMouseover) then return "barbed_shot st 24"; end
  end
  -- dire_beast
  if S.DireBeast:IsCastable() then
    if Cast(S.DireBeast, Settings.BeastMastery.GCDasOffGCD.DireBeast, nil, not Target:IsSpellInRange(S.DireBeast)) then return "dire_beast st 26"; end
  end
  -- serpent_sting,target_if=min:remains,if=refreshable&target.time_to_die>duration
  if S.SerpentSting:IsReady() then
    if Everyone.CastTargetIf(S.SerpentSting, Enemies40y, "min", EvaluateTargetIfFilterSerpentSting, EvaluateTargetIfSerpentStingST, not Target:IsSpellInRange(S.SerpentSting), nil, nil, M.SerpentStingMouseover) then return "serpent_sting st 28"; end
  end
  -- kill_shot
  if S.KillShot:IsReady() then
    if Cast(S.KillShot, nil, nil, not Target:IsSpellInRange(S.KillShot)) then return "kill_shot st 30"; end
  end
  -- aspect_of_the_wild
  if S.AspectoftheWild:IsCastable() and CDsON() then
    if Cast(S.AspectoftheWild, Settings.BeastMastery.OffGCDasOffGCD.AspectOfTheWild) then return "aspect_of_the_wild st 32"; end
  end
  -- cobra_shot
  if S.CobraShot:IsReady() then
    if Cast(S.CobraShot, nil, nil, not Target:IsSpellInRange(S.CobraShot)) then return "cobra_shot st 34"; end
  end
  -- wailing_arrow,if=pet.main.buff.frenzy.remains>execute_time|target.time_to_die<5
  if S.WailingArrow:IsReady() and (Pet:BuffRemains(S.FrenzyPetBuff) > S.WailingArrow:ExecuteTime() or FightRemains < 5) then
    if WR.Press(S.WailingArrow, not Target:IsSpellInRange(S.WailingArrow), true) then return "wailing_arrow st 36"; end
  end
  if CDsON() then
    -- bag_of_tricks,if=buff.bestial_wrath.down|target.time_to_die<5
    if S.BagofTricks:IsCastable() and (Player:BuffDown(S.BestialWrathBuff) or FightRemains < 5) then
      if Cast(S.BagofTricks, Settings.Commons.GCDasOffGCD.Racials) then return "bag_of_tricks st 38"; end
    end
    -- arcane_pulse,if=buff.bestial_wrath.down|target.time_to_die<5
    if S.ArcanePulse:IsCastable() and (Player:BuffDown(S.BestialWrathBuff) or FightRemains < 5) then
      if Cast(S.ArcanePulse, Settings.Commons.GCDasOffGCD.Racials) then return "arcane_pulse st 40"; end
    end
    -- arcane_torrent,if=(focus+focus.regen+15)<focus.max
    if S.ArcaneTorrent:IsCastable() and ((Player:Focus() + Player:FocusRegen() + 15) < Player:FocusMax()) then
      if Cast(S.ArcaneTorrent, Settings.Commons.GCDasOffGCD.Racials) then return "arcane_torrent st 42"; end
    end
  end
end

--- ======= MAIN =======
local function APL()
  -- HeroLib SplashData Tracking Update (used as fallback if pet abilities are not in action bars)
  if S.Stomp:IsAvailable() then
    HL.SplashEnemies.ChangeFriendTargetsTracking("Mine Only")
  else
    HL.SplashEnemies.ChangeFriendTargetsTracking("All")
  end

  -- Update GCDMax
  GCDMax = Player:GCD() + 0.150

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies8y, false)
    end
  end

  -- Enemies Update
  local PetCleaveAbility = (S.BloodBolt:IsPetKnown() and S.BloodBolt)
    or (S.Bite:IsPetKnown() and S.Bite)
    or (S.Claw:IsPetKnown() and S.Claw)
    or (S.Smack:IsPetKnown() and S.Smack)
    or nil
  local PetRangeAbility = (S.Growl:IsPetKnown() and Action.FindBySpellID(S.Growl:ID()) and S.Growl) or nil
  if AoEON() then
    Enemies8y = Player:GetEnemiesInRange(8)
    Enemies40y = Player:GetEnemiesInRange(40) -- Barbed Shot Cycle
    PetEnemiesMixedyCount = (PetCleaveAbility and #Player:GetEnemiesInSpellActionRange(PetCleaveAbility)) or Target:GetEnemiesInSplashRangeCount(8) -- Beast Cleave (through Multi-Shot)
  else
    Enemies8y = {}
    Enemies40y = {}
    PetEnemiesMixedyCount = 0
  end
  TargetInRange40y = Target:IsInRange(40) -- Most abilities
  TargetInRange30y = Target:IsInRange(30) -- Stampede
  TargetInRangePet30y = (PetRangeAbility and Target:IsSpellInActionRange(PetRangeAbility)) or Target:IsInRange(30) -- Kill Command

  -- Defensives
  -- Exhilaration
  if S.Exhilaration:IsCastable() and Player:HealthPercentage() <= Settings.Commons2.ExhilarationHP then
    if Cast(S.Exhilaration, Settings.Commons2.GCDasOffGCD.Exhilaration) then return "Exhilaration"; end
  end
  -- healthstone
  if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
    if WR.Press(M.Healthstone, nil, nil, true) then return "healthstone defensive 3"; end
  end

  -- Pet Management
  if S.SummonPet:IsCastable() then
    if Cast(SummonPetSpells[Settings.Commons2.SummonPetSlot], Settings.Commons2.GCDasOffGCD.SummonPet) then return "Summon Pet"; end
  end
  if Pet:IsDeadOrGhost() and S.RevivePet:IsCastable() then
    if Cast(S.RevivePet, Settings.Commons2.GCDasOffGCD.RevivePet) then return "Revive Pet"; end
  end
  if (not Pet:IsDeadOrGhost()) and S.MendPet:IsCastable() and Pet:HealthPercentage() <= Settings.Commons2.MendPetHighHP then
    if Cast(S.MendPet) then return "Mend Pet High Priority"; end
  end

  if Everyone.TargetIsValid() then
    -- Out of Combat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- Interrupts
    if not Player:IsCasting(S.WailingArrow) then
      local ShouldReturn = Everyone.Interrupt(S.CounterShot, 40, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.Intimidation, 40); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.Interrupt(S.CounterShot, 40, true, Mouseover, M.CounterShotMouseover); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.Intimidation, 40, nil, Mouseover, M.IntimidationMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- Explosives
    if (Settings.Commons.Enabled.HandleExplosives) then
      local ShouldReturn = Everyone.HandleExplosive(S.CobraShot, M.CobraShotMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- auto_shot
    -- call_action_list,name=cds
    if (CDsON()) then
      local ShouldReturn = CDs(); if ShouldReturn then return ShouldReturn; end
    end
    -- Manually added: call_action_list,name=trinkets
    -- Note: Shifted Trinket usage from CDs() to its own function so Trinket usage isn't reliant upon CDsON()
    if (Settings.Commons.Enabled.Trinkets) then
      local ShouldReturn = Trinkets(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=st,if=active_enemies<2|!talent.beast_cleave&active_enemies<3
    if (PetEnemiesMixedyCount < 2 or (not S.BeastCleave:IsAvailable()) and PetEnemiesMixedyCount < 3) then
      local ShouldReturn = ST(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=cleave,if=active_enemies>2|talent.beast_cleave&active_enemies>1
    if (PetEnemiesMixedyCount > 2 or S.BeastCleave:IsAvailable() and PetEnemiesMixedyCount > 1) then
      local ShouldReturn = Cleave(); if ShouldReturn then return ShouldReturn; end
    end
    -- Manually added pet healing
    if not Pet:IsDeadOrGhost() and S.MendPet:IsCastable() and Pet:HealthPercentage() <= Settings.Commons2.MendPetLowHP then
      if Cast(S.MendPet) then return "Mend Pet Low Priority (w/ Target)"; end
    end
    -- Pool Focus if nothing else to do
    if Cast(S.PoolFocus) then return "Pooling Focus"; end
  end

  -- Note: We have to put it again in case we don't have a target but our pet is dying.
  if not Pet:IsDeadOrGhost() and S.MendPet:IsCastable() and Pet:HealthPercentage() <= Settings.Commons2.MendPetLowHP then
    if Cast(S.MendPet) then return "Mend Pet Low Priority (w/o Target)"; end
  end
end

local function AutoBind()
  -- Spell Binds
  WR.Bind(S.AMurderofCrows)
  WR.Bind(S.AspectoftheWild)  
  WR.Bind(S.ArcaneTorrent)
  WR.Bind(S.ArcanePulse)
  WR.Bind(S.BagofTricks)
  WR.Bind(S.BarbedShot)
  WR.Bind(S.Barrage)
  WR.Bind(S.BestialWrath)
  WR.Bind(S.BloodFury)
  WR.Bind(S.Bloodshed)
  WR.Bind(S.CobraShot)
  WR.Bind(S.CounterShot)
  WR.Bind(S.DeathChakram)
  WR.Bind(S.DireBeast)
  WR.Bind(S.Exhilaration)
  WR.Bind(S.ExplosiveShot)
  WR.Bind(S.Flare)
  WR.Bind(S.Intimidation)
  WR.Bind(S.KillCommand)
  WR.Bind(S.KillShot)
  WR.Bind(S.MendPet)
  WR.Bind(S.MultiShot)
  WR.Bind(S.RevivePet)
  WR.Bind(S.SerpentSting)
  WR.Bind(S.Stampede)
  WR.Bind(S.SteelTrap)
  WR.Bind(S.TarTrap)
  WR.Bind(S.WailingArrow)
  WR.Bind(S.SummonPet)
  WR.Bind(S.SummonPet2)
  WR.Bind(S.SummonPet3)
  WR.Bind(S.SummonPet4)
  WR.Bind(S.SummonPet5)
  
  -- Pet Spells
  WR.Bind(S.BloodBolt)
  WR.Bind(S.Bite)
  WR.Bind(S.Claw)
  WR.Bind(S.Growl)
  WR.Bind(S.Smack)
  
  -- Bind Items
  WR.Bind(M.Trinket1)
  WR.Bind(M.Trinket2)
  WR.Bind(M.Healthstone)
  WR.Bind(M.PotionOfSpectralAgility)
  
  -- Macros
  WR.Bind(M.BarbedShotMouseover)
  WR.Bind(M.BindingShotCursor)
  WR.Bind(M.CobraShotMouseover)
  WR.Bind(M.CounterShotMouseover)
  WR.Bind(M.IntimidationMouseover)
  WR.Bind(M.KillShotMouseover)
  WR.Bind(M.SerpentStingMouseover)
  WR.Bind(M.MisdirectionFocus)
end

local function OnInit ()
  WR.Print("Beast Mastery by Worldy.")
  AutoBind()
end

WR.SetAPL(253, APL, OnInit)
