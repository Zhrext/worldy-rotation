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
local Macro      = WR.Macro
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Cast       = WR.Cast
local Press      = WR.Press
-- lua
local GetTime    = GetTime
-- File Locals
local Hunter     = WR.Commons.Hunter

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.Hunter.Marksmanship
local I = Item.Hunter.Marksmanship
local M = Macro.Hunter.Marksmanship

-- Define array of summon_pet spells
local SummonPetSpells = { S.SummonPet, S.SummonPet2, S.SummonPet3, S.SummonPet4, S.SummonPet5 }

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  I.DMDDance:ID(),
  I.DMDDanceBox:ID(),
  I.DMDInferno:ID(),
  I.DMDInfernoBox:ID(),
  I.DMDRime:ID(),
  I.DMDRimeBox:ID(),
  I.DMDWatcher:ID(),
  I.DMDWatcherBox:ID(),
  I.DecorationofFlame:ID(),
  I.GlobeofJaggedIce:ID(),
  I.ManicGrieftorch:ID(),
  I.StormeatersBoon:ID(),
  I.WindscarWhetstone:ID(),
}

-- Trinket Item Objects
local equip = Player:GetEquipment()
local trinket1 = (equip[13]) and Item(equip[13]) or Item(0)
local trinket2 = (equip[14]) and Item(equip[14]) or Item(0)

-- Rotation Var
local SteadyShotTracker = { LastCast = 0, Count = 0 }
local BossFightRemains = 11111
local FightRemains = 11111

-- Enemy Range Variables
local Enemies40y
local Enemies10ySplash
local EnemiesCount10ySplash
local TargetInRange40y

-- GUI Settings
local Everyone = WR.Commons.Everyone;
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Hunter.Commons,
  Commons2 = WR.GUISettings.APL.Hunter.Commons2,
  Marksmanship = WR.GUISettings.APL.Hunter.Marksmanship
};

-- Variables
local VarCAExecute = Target:HealthPercentage() > 70 and S.CarefulAim:IsAvailable()

-- Interrupts
local StunInterrupts = {
  { S.Intimidation, "Cast Intimidation (Interrupt)", function () return true; end },
};

HL:RegisterForEvent(function()
  equip = Player:GetEquipment()
  trinket1 = (equip[13]) and Item(equip[13]) or Item(0)
  trinket2 = (equip[14]) and Item(equip[14]) or Item(0)
end, "PLAYER_EQUIPMENT_CHANGED")

HL:RegisterForEvent(function()
  SteadyShotTracker = { LastCast = 0, Count = 0 }
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

HL:RegisterForEvent(function()
  S.SerpentSting:RegisterInFlight()
  S.SteadyShot:RegisterInFlight()
  S.AimedShot:RegisterInFlight()
end, "LEARNED_SPELL_IN_TAB")
S.SerpentSting:RegisterInFlight()
S.SteadyShot:RegisterInFlight()
S.AimedShot:RegisterInFlight()

--Functions
local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

-- TODO(mrdmnd) - if you're casting (aimed or rapid fire) with volley up, you actually only have trick shots for next
-- aimed shot if volley buff is still up at the end of the cast. also conceivably build in buffer here.
-- test Player:BuffRemains(S.VolleyBuff) against S.Trueshot:ExecuteTime() for more accuracy
local function TrickShotsBuffCheck()
  return (Player:BuffUp(S.TrickShotsBuff) and not Player:IsCasting(S.AimedShot) and not Player:IsChanneling(S.RapidFire)) or Player:BuffUp(S.VolleyBuff)
end

-- Update our SteadyFocus count
local function SteadyFocusUpdate()
  -- The LastCast < GetTime - CastTime check is to try to not double count a single cast
  if (SteadyShotTracker.Count == 0 or SteadyShotTracker.Count == 1) and Player:IsCasting(S.SteadyShot) and SteadyShotTracker.LastCast < GetTime() - S.SteadyShot:CastTime() then
    SteadyShotTracker.LastCast = GetTime()
    SteadyShotTracker.Count = SteadyShotTracker.Count + 1
  end
  -- Reset the counter if we cast anything that's not SteadyShot
  if not (Player:IsCasting(S.SteadyShot) or Player:PrevGCDP(1, S.SteadyShot)) then SteadyShotTracker.Count = 0 end
  -- Reset the counter if the last time we had the buff is newer than the last time we cast SteadyShot
  if S.SteadyFocusBuff.LastAppliedOnPlayerTime > SteadyShotTracker.LastCast then SteadyShotTracker.Count = 0 end
end

local function EvaluateTargetIfFilterSerpentRemains(TargetUnit)
  -- target_if=min:remains
  return (TargetUnit:DebuffRemains(S.SerpentStingDebuff))
end

local function EvaluateTargetIfFilterAimedShot(TargetUnit)
  -- target_if=min:dot.serpent_sting.remains+action.serpent_sting.in_flight_to_target*99
  return (TargetUnit:DebuffRemains(S.SerpentStingDebuff) + num(S.SerpentSting:InFlight()) * 99)
end

local function EvaluateTargetIfFilterLatentPoison(TargetUnit)
  -- target_if=max:debuff.latent_poison.stack
  return (TargetUnit:DebuffStack(S.LatentPoisonDebuff))
end

local function EvaluateTargetIfSerpentSting(TargetUnit)
  -- if=refreshable&!talent.serpentstalkers_trickery&buff.trueshot.down
  return (TargetUnit:DebuffRefreshable(S.SerpentStingDebuff) and (not S.SerpentstalkersTrickery:IsAvailable()))
end

local function EvaluateTargetIfSerpentSting2(TargetUnit)
  -- if=refreshable&talent.hydras_bite&!talent.serpentstalkers_trickery
  return (TargetUnit:DebuffRefreshable(S.SerpentStingDebuff) and S.HydrasBite:IsAvailable() and not S.SerpentstalkersTrickery:IsAvailable())
end

local function EvaluateTargetIfSerpentSting3(TargetUnit)
  -- if=refreshable&talent.poison_injection&!talent.serpentstalkers_trickery
  return (TargetUnit:DebuffRefreshable(S.SerpentStingDebuff) and S.PoisonInjection:IsAvailable() and not S.SerpentstalkersTrickery:IsAvailable())
end

local function EvaluateTargetIfAimedShot(TargetUnit)
  -- if=talent.serpentstalkers_trickery&((buff.precise_shots.down|(buff.trueshot.up|full_recharge_time<gcd+cast_time)&(!talent.chimaera_shot|active_enemies<2))|buff.trick_shots.remains>execute_time&active_enemies>1)
  return (S.SerpentstalkersTrickery:IsAvailable() and ((Player:BuffDown(S.PreciseShotsBuff) or (Player:BuffUp(S.TrueshotBuff) or S.AimedShot:FullRechargeTime() < Player:GCD() + S.AimedShot:CastTime()) and ((not S.ChimaeraShot:IsAvailable()) or EnemiesCount10ySplash < 2)) or Player:BuffRemains(S.TrickShotsBuff) > S.AimedShot:ExecuteTime() and EnemiesCount10ySplash > 1))
end

local function EvaluateTargetIfAimedShot2(TargetUnit)
  -- if=(buff.precise_shots.down|(buff.trueshot.up|full_recharge_time<gcd+cast_time)&(!talent.chimaera_shot|active_enemies<2))|buff.trick_shots.remains>execute_time&active_enemies>1
  return ((Player:BuffDown(S.PreciseShotsBuff) or (Player:BuffUp(S.TrueshotBuff) or S.AimedShot:FullRechargeTime() < Player:GCD() + S.AimedShot:CastTime()) and ((not S.ChimaeraShot:IsAvailable()) or EnemiesCount10ySplash < 2)) or Player:BuffRemains(S.TrickShotsBuff) > S.AimedShot:ExecuteTime() and EnemiesCount10ySplash > 1)
end

local function EvaluateTargetIfAimedShot3(TargetUnit)
  -- if=talent.serpentstalkers_trickery&(buff.trick_shots.remains>=execute_time&(buff.precise_shots.down|buff.trueshot.up|full_recharge_time<cast_time+gcd))
  return (S.SerpentstalkersTrickery:IsAvailable() and (Player:BuffRemains(S.TrickShotsBuff) >= S.AimedShot:ExecuteTime() and (Player:BuffDown(S.PreciseShotsBuff) or Player:BuffUp(S.TrueshotBuff) or S.AimedShot:FullRechargeTime() < S.AimedShot:CastTime() + Player:GCD())))
end

local function EvaluateTargetIfAimedShot4(TargetUnit)
  -- if=(buff.trick_shots.remains>=execute_time&(buff.precise_shots.down|buff.trueshot.up|full_recharge_time<cast_time+gcd))
  return (Player:BuffRemains(S.TrickShotsBuff) >= S.AimedShot:ExecuteTime() and (Player:BuffDown(S.PreciseShotsBuff) or Player:BuffUp(S.TrueshotBuff) or S.AimedShot:FullRechargeTime() < S.AimedShot:CastTime() + Player:GCD()))
end

local function Precombat()
  -- flask
  -- augmentation
  -- food
  -- misdirection
  if Focus:Exists() and S.Misdirection:IsReady() then
    if WR.Press(M.MisdirectionFocus) then return "misdirection precombat 0"; end
  end
  -- summon_pet,if=talent.kill_command|talent.beast_master
  if S.SummonPet:IsCastable() and (S.KillCommand:IsAvailable() or S.BeastMaster:IsAvailable()) then
    if Cast(SummonPetSpells[Settings.Commons2.SummonPetSlot], Settings.Commons2.GCDasOffGCD.SummonPet) then return "Summon Pet"; end
  end
  -- snapshot_stats
  -- double_tap,precast_time=10
  if S.DoubleTap:IsReady() and CDsON() then
    if Cast(S.DoubleTap, Settings.Marksmanship.GCDasOffGCD.DoubleTap) then return "double_tap opener"; end
  end
  -- aimed_shot,if=active_enemies<3&(!talent.volley|active_enemies<2)
  if S.AimedShot:IsReady() and (not Player:IsCasting(S.AimedShot)) and (EnemiesCount10ySplash < 3 and ((not S.Volley:IsAvailable()) or EnemiesCount10ySplash < 2)) then
    if Press(S.AimedShot, not TargetInRange40y, true) then return "aimed_shot opener"; end
  end
  -- wailing_arrow,if=active_enemies>2|!talent.steady_focus
  if S.WailingArrow:IsReady() and (not Player:IsCasting(S.WailingArrow)) and (EnemiesCount10ySplash > 2 or not S.SteadyFocus:IsAvailable()) then
    if Press(S.WailingArrow, not TargetInRange40y, true) then return "wailing_arrow opener"; end
  end
  -- steady_shot,if=active_enemies>2|talent.volley&active_enemies=2
  if S.SteadyShot:IsCastable() and (EnemiesCount10ySplash > 2 or S.Volley:IsAvailable() and EnemiesCount10ySplash == 2) then
    if Cast(S.SteadyShot, nil, nil, not TargetInRange40y) then return "steady_shot opener"; end
  end
end

local function Cds()
  -- berserking,if=fight_remains<13
  if S.Berserking:IsReady() and (FightRemains < 13) then
    if Cast(S.Berserking, Settings.Commons.OffGCDasOffGCD.Racials) then return "berserking cds 2"; end
  end
  -- blood_fury,if=buff.trueshot.up|cooldown.trueshot.remains>30|fight_remains<16
  if S.BloodFury:IsReady() and (Player:BuffUp(S.TrueshotBuff) or S.Trueshot:CooldownRemains() > 30 or FightRemains < 16) then
    if Cast(S.BloodFury, Settings.Commons.OffGCDasOffGCD.Racials) then return "blood_fury cds 4"; end
  end
  -- ancestral_call,if=buff.trueshot.up|cooldown.trueshot.remains>30|fight_remains<16
  if S.AncestralCall:IsReady() and (Player:BuffUp(S.TrueshotBuff) or S.Trueshot:CooldownRemains() > 30 or FightRemains < 16) then
    if Cast(S.AncestralCall, Settings.Commons.OffGCDasOffGCD.Racials) then return "ancestral_call cds 6"; end
  end
  -- fireblood,if=buff.trueshot.up|cooldown.trueshot.remains>30|fight_remains<9
  if S.Fireblood:IsReady() and (Player:BuffUp(S.TrueshotBuff) or S.Trueshot:CooldownRemains() > 30 or FightRemains < 9) then
    if Cast(S.Fireblood, Settings.Commons.OffGCDasOffGCD.Racials) then return "fireblood cds 8"; end
  end
  -- lights_judgment,if=buff.trueshot.down
  if S.LightsJudgment:IsReady() and (Player:BuffDown(S.TrueshotBuff)) then
    if Cast(S.LightsJudgment, Settings.Commons.GCDasOffGCD.Racials, nil, not Target:IsSpellInRange(S.LightsJudgment)) then return "lights_judgment cds 10"; end
  end
  -- potion,if=buff.trueshot.up&(buff.bloodlust.up|target.health.pct<20)|fight_remains<26
  if Settings.Commons.Enabled.Potions and (Player:BuffUp(S.TrueshotBuff) and (Player:BloodlustUp() or Target:HealthPercentage() < 20) or FightRemains < 26) then
    local PotionSelected = Everyone.PotionSelected()
    if PotionSelected and PotionSelected:IsReady() then
      if Cast(PotionSelected, nil, Settings.Commons.DisplayStyle.Potions) then return "potion cds 12"; end
    end
  end
end

local function St()
  -- steady_shot,if=talent.steady_focus&(steady_focus_count&buff.steady_focus.remains<5|buff.steady_focus.down&!buff.trueshot.up)
  if S.SteadyShot:IsCastable() and (S.SteadyFocus:IsAvailable() and (SteadyShotTracker.Count == 1 and Player:BuffRemains(S.SteadyFocusBuff) < 5 or Player:BuffDown(S.SteadyFocusBuff) and Player:BuffDown(S.TrueshotBuff) and SteadyShotTracker.Count ~= 2)) then
    if Cast(S.SteadyShot, nil, nil, not TargetInRange40y) then return "steady_shot st 2"; end
  end
  -- kill_shot
  if S.KillShot:IsReady() then
    if Cast(S.KillShot, nil, nil, not TargetInRange40y) then return "kill_shot st 4"; end
  end
  -- kill_shot_mouseover
  if Mouseover:Exists() and S.KillShot:IsCastable() and Mouseover:HealthPercentage() <= 20  then
    if Press(M.KillShotMouseover, not Mouseover:IsSpellInRange(S.KillShot)) then return "kill_shot_mouseover cleave 38"; end
  end
  -- steel_trap
  if Settings.Commons.UseSteelTrap and S.SteelTrap:IsCastable() and Target:GUID() == Mouseover:GUID() then
    if Press(M.SteelTrapCursor, not Target:IsInRange(40)) then return "steel_trap st 6"; end
  end
  -- serpent_sting,target_if=min:dot.serpent_sting.remains,if=refreshable&!talent.serpentstalkers_trickery&buff.trueshot.down
  if S.SerpentSting:IsReady() and (Player:BuffDown(S.TrueshotBuff)) then
    if Everyone.CastTargetIf(S.SerpentSting, Enemies40y, "min", EvaluateTargetIfFilterSerpentRemains, EvaluateTargetIfSerpentSting, not TargetInRange40y, nil, nil, M.SerpentStingMouseover) then return "serpent_sting st 8"; end
  end
  -- explosive_shot
  if S.ExplosiveShot:IsReady() then
    if Cast(S.ExplosiveShot, nil, nil, not TargetInRange40y) then return "explosive_shot st 10"; end
  end
  -- double_tap,if=(cooldown.rapid_fire.remains<gcd|ca_active|!talent.streamline)&(!raid_event.adds.exists|raid_event.adds.up&(raid_event.adds.in<10&raid_event.adds.remains<3|raid_event.adds.in>cooldown|active_enemies>1)|!raid_event.adds.up&(raid_event.adds.count=1|raid_event.adds.in>cooldown))
  if S.DoubleTap:IsReady() and ((S.RapidFire:CooldownRemains() < Player:GCD() or Target:HealthPercentage() > 70 or not S.Streamline:IsAvailable())) and CDsON() then
    if Cast(S.DoubleTap, Settings.Marksmanship.GCDasOffGCD.DoubleTap) then return "double_tap st 12"; end
  end
  -- stampede
  if S.Stampede:IsCastable() and CDsON() then
    if Cast(S.Stampede, nil, nil, not Target:IsInRange(30)) then return "stampede st 14"; end
  end
  -- death_chakram
  if S.DeathChakram:IsReady() and CDsON() then
    if Cast(S.DeathChakram, nil, Settings.Commons.DisplayStyle.Signature, not TargetInRange40y) then return "dark_chakram st 16"; end
  end
  -- wailing_arrow,if=active_enemies>1
  if S.WailingArrow:IsReady() and (EnemiesCount10ySplash > 1) then
    if Press(S.WailingArrow, not TargetInRange40y, true) then return "wailing_arrow st 18"; end
  end
  -- volley
  if Settings.Marksmanship.UseVolley and S.Volley:IsReady() and Mouseover:GUID() == Target:GUID() then
    if Cast(M.VolleyCursor, Settings.Marksmanship.GCDasOffGCD.Volley, nil, not TargetInRange40y)  then return "volley st 20"; end
  end
  -- rapid_fire,if=talent.surging_shots|buff.double_tap.up&talent.streamline&!ca_active
  if S.RapidFire:IsCastable() and (S.SurgingShots:IsAvailable() or Player:BuffUp(S.DoubleTapBuff) and S.Streamline:IsAvailable() and Target:HealthPercentage() < 70) then
    if Cast(S.RapidFire, nil, nil, not TargetInRange40y) then return "rapid_fire st 22"; end
  end
  -- trueshot,if=!raid_event.adds.exists|!raid_event.adds.up&(raid_event.adds.duration+raid_event.adds.in<25|raid_event.adds.in>60)|raid_event.adds.up&raid_event.adds.remains>10|active_enemies>1|fight_remains<25
  if S.Trueshot:IsReady() and CDsON() then
    if Press(S.Trueshot, not TargetInRange40y, nil, true) then return "trueshot st 24"; end
  end
  -- multishot,if=buff.bombardment.up&buff.trick_shots.down&active_enemies>1|talent.salvo&buff.salvo.down&!talent.volley
  if S.MultiShot:IsReady() and (Player:BuffUp(S.BombardmentBuff) and (not TrickShotsBuffCheck()) and EnemiesCount10ySplash > 1 or S.Salvo:IsAvailable() and not S.Volley:IsAvailable()) then
    if Cast(S.MultiShot, nil, nil, not TargetInRange40y) then return "multishot st 26"; end
  end
  -- aimed_shot,target_if=min:dot.serpent_sting.remains+action.serpent_sting.in_flight_to_target*99,if=talent.serpentstalkers_trickery&((buff.precise_shots.down|(buff.trueshot.up|full_recharge_time<gcd+cast_time)&(!talent.chimaera_shot|active_enemies<2))|buff.trick_shots.remains>execute_time&active_enemies>1)
  if S.AimedShot:IsReady() then
    if Everyone.CastTargetIf(S.AimedShot, Enemies40y, "min", EvaluateTargetIfFilterAimedShot, EvaluateTargetIfAimedShot, not TargetInRange40y, nil, nil, M.AimedShotMouseover, true) then return "aimed_shot st 28"; end
  end
  -- aimed_shot,target_if=max:debuff.latent_poison.stack,if=(buff.precise_shots.down|(buff.trueshot.up|full_recharge_time<gcd+cast_time)&(!talent.chimaera_shot|active_enemies<2))|buff.trick_shots.remains>execute_time&active_enemies>1
  if S.AimedShot:IsReady() then
    if Everyone.CastTargetIf(S.AimedShot, Enemies40y, "max", EvaluateTargetIfFilterLatentPoison, EvaluateTargetIfAimedShot2, not TargetInRange40y, nil, nil, M.AimedShotMouseover, true) then return "aimed_shot st 30"; end
  end
  -- steady_shot,if=talent.steady_focus&buff.steady_focus.remains<execute_time*2
  -- Note: Added SteadyShotTracker.Count ~= 2 so we don't suggest this during the cast that will grant us SteadyFocusBuff
  if S.SteadyShot:IsCastable() and (S.SteadyFocus:IsAvailable() and Player:BuffRemains(S.SteadyFocusBuff) < S.SteadyShot:ExecuteTime() * 2) and SteadyShotTracker.Count ~= 2 then
    if Cast(S.SteadyShot, nil, nil, not TargetInRange40y) then return "steady_shot st 32"; end
  end
  -- rapid_fire
  if S.RapidFire:IsCastable() then
    if Cast(S.RapidFire, nil, nil, not TargetInRange40y) then return "rapid_fire st 34"; end
  end
  -- wailing_arrow,if=buff.trueshot.down
  if S.WailingArrow:IsReady() and (Player:BuffDown(S.TrueshotBuff)) then
    if Press(S.WailingArrow, not TargetInRange40y, true) then return "wailing_arrow st 36"; end
  end
  -- chimaera_shot,if=buff.precise_shots.up|focus>cost+action.aimed_shot.cost
  if S.ChimaeraShot:IsReady() and (Player:BuffUp(S.PreciseShotsBuff) or Player:FocusP() > S.ChimaeraShot:Cost() + S.AimedShot:Cost()) then
    if Cast(S.ChimaeraShot, nil, nil, not TargetInRange40y) then return "chimaera_shot st 38"; end
  end
  -- arcane_shot,if=buff.precise_shots.up|focus>cost+action.aimed_shot.cost
  if S.ArcaneShot:IsReady() and (Player:BuffUp(S.PreciseShotsBuff) or Player:FocusP() > S.ArcaneShot:Cost() + S.AimedShot:Cost()) then
    if Cast(S.ArcaneShot, nil, nil, not TargetInRange40y) then return "arcane_shot st 40"; end
  end
  -- bag_of_tricks,if=buff.trueshot.down
  if S.BagofTricks:IsReady() then
    if Cast(S.BagofTricks, Settings.Commons.GCDasOffGCD.Racials, nil, not Target:IsSpellInRange(S.BagofTricks)) then return "bag_of_tricks st 42"; end
  end
  -- steady_shot
  if S.SteadyShot:IsCastable() then
    if Cast(S.SteadyShot, nil, nil, not TargetInRange40y) then return "steady_shot st 44"; end
  end
end

local function Trickshots()
  -- steady_shot,if=talent.steady_focus&steady_focus_count&buff.steady_focus.remains<8
  if S.SteadyShot:IsCastable() and (S.SteadyFocus:IsAvailable() and SteadyShotTracker.Count == 1 and Player:BuffRemains(S.SteadyFocusBuff) < 8) then
    if Cast(S.SteadyShot, nil, nil, not TargetInRange40y) then return "steady_shot trickshots 2"; end
  end
  -- kill_shot,if=buff.razor_fragments.up
  if S.KillShot:IsReady() then
    if Cast(S.KillShot, nil, nil, not TargetInRange40y) then return "kill_shot trickshots 4"; end
  end
  -- kill_shot_mouseover
  if Mouseover:Exists() and S.KillShot:IsCastable() and Mouseover:HealthPercentage() <= 20  then
    if Press(M.KillShotMouseover, not Mouseover:IsSpellInRange(S.KillShot)) then return "kill_shot_mouseover cleave 38"; end
  end
  -- double_tap,if=cooldown.rapid_fire.remains<gcd|ca_active|!talent.streamline
  if S.DoubleTap:IsReady() and (S.RapidFire:CooldownRemains() < Player:GCD() or Target:HealthPercentage() > 70 or not S.Streamline:IsAvailable()) and CDsON() then
    if Cast(S.DoubleTap, Settings.Marksmanship.GCDasOffGCD.DoubleTap) then return "double_tap trickshots 6"; end
  end
  -- explosive_shot
  if S.ExplosiveShot:IsReady() then
    if Cast(S.ExplosiveShot, nil, nil, not TargetInRange40y) then return "explosive_shot trickshots 8"; end
  end
  -- death_chakram
  if S.DeathChakram:IsReady() and CDsON() then
    if Cast(S.DeathChakram, nil, Settings.Commons.DisplayStyle.Signature, not TargetInRange40y) then return "death_chakram trickshots 10"; end
  end
  -- stampede
  if S.Stampede:IsReady() and CDsON() then
    if Cast(S.Stampede, nil, nil, not Target:IsInRange(30)) then return "stampede trickshots 12"; end
  end
  -- wailing_arrow
  if S.WailingArrow:IsReady() then
    if Press(S.WailingArrow, not TargetInRange40y, true) then return "wailing_arrow trickshots 14"; end
  end
  -- serpent_sting,target_if=min:dot.serpent_sting.remains,if=refreshable&talent.hydras_bite&!talent.serpentstalkers_trickery
  if S.SerpentSting:IsReady() then
    if Everyone.CastTargetIf(S.SerpentSting, Enemies40y, "min", EvaluateTargetIfFilterSerpentRemains, EvaluateTargetIfSerpentSting2, not TargetInRange40y, nil, nil, M.SerpentStingMouseover) then return "serpent_sting trickshots 16"; end
  end
  -- barrage,if=active_enemies>7
  if S.Barrage:IsReady() and (EnemiesCount10ySplash > 7) and CDsON() then
    if Cast(S.Barrage, nil, nil, not TargetInRange40y) then return "barrage trickshots 18"; end
  end
  -- volley
  if Settings.Marksmanship.UseVolley and S.Volley:IsReady() and Mouseover:GUID() == Target:GUID() then
    if Cast(M.VolleyCursor, Settings.Marksmanship.GCDasOffGCD.Volley)  then return "volley trickshots 20"; end
  end
  -- trueshot
  if S.Trueshot:IsReady() and CDsON() then
    if Press(S.Trueshot, not TargetInRange40y, false, true) then return "trueshot trickshots 22"; end
  end
  -- rapid_fire,if=buff.trick_shots.remains>=execute_time&(talent.surging_shots|buff.double_tap.up&talent.streamline&!ca_active)
  if S.RapidFire:IsCastable() and (Player:BuffRemains(S.TrickShotsBuff) >= S.RapidFire:ExecuteTime() and (S.SurgingShots:IsAvailable() or Player:BuffUp(S.DoubleTapBuff) and S.Streamline:IsAvailable() and Target:HealthPercentage() < 70)) then
    if Cast(S.RapidFire, nil, nil, not TargetInRange40y) then return "rapid_fire trickshots 24"; end
  end
  -- aimed_shot,target_if=min:dot.serpent_sting.remains+action.serpent_sting.in_flight_to_target*99,if=talent.serpentstalkers_trickery&(buff.trick_shots.remains>=execute_time&(buff.precise_shots.down|buff.trueshot.up|full_recharge_time<cast_time+gcd))
  if S.AimedShot:IsReady() then
    if Everyone.CastTargetIf(S.AimedShot, Enemies40y, "min", EvaluateTargetIfFilterAimedShot, EvaluateTargetIfAimedShot3, not TargetInRange40y, nil, nil, M.AimedShotMouseover, true) then return "aimed_shot trickshots 26"; end
  end
  -- aimed_shot,target_if=max:debuff.latent_poison.stack,if=(buff.trick_shots.remains>=execute_time&(buff.precise_shots.down|buff.trueshot.up|full_recharge_time<cast_time+gcd))
  if S.AimedShot:IsReady() then
    if Everyone.CastTargetIf(S.AimedShot, Enemies40y, "max", EvaluateTargetIfFilterLatentPoison, EvaluateTargetIfAimedShot4, not TargetInRange40y, nil, nil, M.AimedShotMouseover, true) then return "aimed_shot trickshots 28"; end
  end
  -- rapid_fire,if=buff.trick_shots.remains>=execute_time
  if S.RapidFire:IsCastable() and (Player:BuffRemains(S.TrickShotsBuff) >= S.RapidFire:ExecuteTime()) then
    if Cast(S.RapidFire, nil, nil, not TargetInRange40y) then return "rapid_fire trickshots 30"; end
  end
  -- chimaera_shot,if=buff.trick_shots.up&buff.precise_shots.up&focus>cost+action.aimed_shot.cost&active_enemies<4
  if S.ChimaeraShot:IsReady() and (Player:BuffUp(S.TrickShotsBuff) and Player:BuffUp(S.PreciseShotsBuff) and Player:FocusP() > S.ChimaeraShot:Cost() + S.AimedShot:Cost() and EnemiesCount10ySplash < 4) then
    if Cast(S.ChimaeraShot, nil, nil, not TargetInRange40y) then return "chimaera_shot trickshots 32"; end
  end
  -- multishot,if=buff.trick_shots.down|(buff.precise_shots.up|buff.bulletstorm.stack=10)&focus>cost+action.aimed_shot.cost
  if S.MultiShot:IsReady() and ((not TrickShotsBuffCheck()) or (Player:BuffUp(S.PreciseShotsBuff) or Player:BuffStack(S.BulletstormBuff) == 10) and Player:FocusP() > S.MultiShot:Cost() + S.AimedShot:Cost()) then
    if Cast(S.MultiShot, nil, nil, not TargetInRange40y) then return "multishot trickshots 34"; end
  end
  -- serpent_sting,target_if=min:dot.serpent_sting.remains,if=refreshable&talent.poison_injection&!talent.serpentstalkers_trickery
  if S.SerpentSting:IsReady() then
    if Everyone.CastTargetIf(S.SerpentSting, Enemies40y, "min", EvaluateTargetIfFilterSerpentRemains, EvaluateTargetIfSerpentSting3, not TargetInRange40y, nil, nil, M.SerpentStingMouseover) then return "serpent_sting trickshots 36"; end
  end
  -- steel_trap
  if Settings.Commons.UseSteelTrap and S.SteelTrap:IsCastable() and Target:GUID() == Mouseover:GUID() then
    if Press(M.SteelTrapCursor, not Target:IsInRange(40)) then return "steel_trap trickshots 38"; end
  end
  -- kill_shot,if=focus>cost+action.aimed_shot.cost
  if S.KillShot:IsReady() and (Player:FocusP() > S.KillShot:Cost() + S.AimedShot:Cost()) then
    if Cast(S.KillShot, nil, nil, not TargetInRange40y) then return "kill_shot trickshots 40"; end
  end
  -- multishot,if=focus>cost+action.aimed_shot.cost
  if S.MultiShot:IsReady() and (Player:FocusP() > S.MultiShot:Cost() + S.AimedShot:Cost()) then
    if Cast(S.MultiShot, nil, nil, not TargetInRange40y) then return "multishot trickshots 42"; end
  end
  -- bag_of_tricks,if=buff.trueshot.down
  if S.BagofTricks:IsReady() and (Player:BuffDown(S.Trueshot)) then
    if Cast(S.BagofTricks, Settings.Commons.GCDasOffGCD.Racials, nil, not Target:IsSpellInRange(S.BagofTricks)) then return "bag_of_tricks trickshots 44"; end
  end
  -- steady_shot
  if S.SteadyShot:IsCastable() then
    if Cast(S.SteadyShot, nil, nil, not TargetInRange40y) then return "steady_shot trickshots 46"; end
  end
end

local function Trinkets()
  local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
  if Trinket1ToUse and Player:BuffUp(S.TrueshotBuff) then
    if WR.Press(M.Trinket1, nil, nil, true) then return "trinket1 trinket 2"; end
  end
  local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
  if Trinket2ToUse and Player:BuffUp(S.TrueshotBuff) then
    if WR.Press(M.Trinket2, nil, nil, true) then return "trinket2 trinket 4"; end
  end
  -- use_item,name=manic_grieftorch,if=pet.main.buff.frenzy.remains>execute_time
    if I.ManicGrieftorch:IsEquippedAndReady() then
      if Cast(I.ManicGrieftorch, nil, Settings.Commons.DisplayStyle.Trinkets) then return "manic_grieftorch trinkets 6"; end
    end
    -- use_item,name=darkmoon_deck_box_rime
    if I.DMDRime:IsEquippedAndReady() then
      if Cast(I.DMDRime, nil, Settings.Commons.DisplayStyle.Trinkets) then return "darkmoon_deck_box_rime trinkets 8"; end
    end
    if I.DMDRimeBox:IsEquippedAndReady() then
      if Cast(I.DMDRimeBox, nil, Settings.Commons.DisplayStyle.Trinkets) then return "darkmoon_deck_box_rime trinkets 10"; end
    end
    -- use_item,name=darkmoon_deck_box_inferno
    if I.DMDInferno:IsEquippedAndReady() then
      if Cast(I.DMDInferno, nil, Settings.Commons.DisplayStyle.Trinkets) then return "darkmoon_deck_box_inferno trinkets 12"; end
    end
    if I.DMDInfernoBox:IsEquippedAndReady() then
      if Cast(I.DMDInfernoBox, nil, Settings.Commons.DisplayStyle.Trinkets) then return "darkmoon_deck_box_inferno trinkets 14"; end
    end
    -- use_item,name=darkmoon_deck_box_dance
    if I.DMDDance:IsEquippedAndReady() then
      if Cast(I.DMDDance, nil, Settings.Commons.DisplayStyle.Trinkets) then return "darkmoon_deck_box_dance trinkets 16"; end
    end
    if I.DMDDanceBox:IsEquippedAndReady() then
      if Cast(I.DMDDanceBox, nil, Settings.Commons.DisplayStyle.Trinkets) then return "darkmoon_deck_box_dance trinkets 18"; end
    end
    -- use_item,name=darkmoon_deck_box_watcher
    if I.DMDWatcher:IsEquippedAndReady() then
      if Cast(I.DMDWatcher, nil, Settings.Commons.DisplayStyle.Trinkets) then return "darkmoon_deck_box_watcher trinkets 20"; end
    end
    if I.DMDWatcherBox:IsEquippedAndReady() then
      if Cast(I.DMDWatcherBox, nil, Settings.Commons.DisplayStyle.Trinkets) then return "darkmoon_deck_box_watcher trinkets 22"; end
    end
    -- use_item,name=decoration_of_flame
    if I.DecorationofFlame:IsEquippedAndReady() then
      if Cast(I.DecorationofFlame, nil, Settings.Commons.DisplayStyle.Trinkets) then return "decoration_of_flame trinkets 24"; end
    end
    -- use_item,name=stormeaters_boon
    if I.StormeatersBoon:IsEquippedAndReady() then
      if Cast(I.StormeatersBoon, nil, Settings.Commons.DisplayStyle.Trinkets) then return "stormeaters_boon trinkets 26"; end
    end
    -- use_item,name=windscar_whetstone
    if I.WindscarWhetstone:IsEquippedAndReady() then
      if Cast(I.WindscarWhetstone, nil, Settings.Commons.DisplayStyle.Trinkets) then return "windscar_whetstone trinkets 28"; end
    end
    -- use_item,name=globe_of_jagged_ice
    if I.GlobeofJaggedIce:IsEquippedAndReady() then
      if Cast(I.GlobeofJaggedIce, nil, Settings.Commons.DisplayStyle.Trinkets) then return "globe_of_jagged_ice trinkets 30"; end
    end
end

--- ======= ACTION LISTS =======
local function APL()
  TargetInRange40y = Target:IsSpellInRange(S.AimedShot) -- Ranged abilities; Distance varies by Mastery
  Enemies40y = Player:GetEnemiesInRange(S.AimedShot.MaximumRange)
  Enemies10ySplash = Target:GetEnemiesInSplashRange(10)
  if AoEON() then
    EnemiesCount10ySplash = #Enemies10ySplash
  else
    EnemiesCount10ySplash = 1
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies10ySplash, false)
    end
  end

  if Everyone.TargetIsValid() then
    SteadyFocusUpdate()
    -- call precombat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- Self heal, if below setting value
    if S.Exhilaration:IsReady() and Player:HealthPercentage() <= Settings.Commons2.ExhilarationHP then
      if Cast(S.Exhilaration, Settings.Commons2.GCDasOffGCD.Exhilaration) then return "exhilaration"; end
    end
    -- Interrupts
    if not Player:IsCasting() and not Player:IsChanneling() then
      local ShouldReturn = Everyone.Interrupt(S.CounterShot, 40, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.Intimidation, 40); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.Interrupt(S.CounterShot, 40, true, Mouseover, M.CounterShotMouseover); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.Intimidation, 40, false, Mouseover, M.IntimidationMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- Explosives
    if (Settings.Commons.Enabled.HandleExplosives) then
      local ShouldReturn = Everyone.HandleExplosive(S.ArcaneShot, M.ArcaneShotMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- auto_shot
    -- trinkets
    if Settings.Commons.Enabled.Trinkets and CDsON() then
      local ShouldReturn = Trinkets(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=cds
    if (CDsON()) then
      local ShouldReturn = Cds(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=st,if=active_enemies<3|!talent.trick_shots
    if (EnemiesCount10ySplash < 3 or not S.TrickShots:IsAvailable()) then
      local ShouldReturn = St(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=trickshots,if=active_enemies>2
    if (EnemiesCount10ySplash > 2) then
      local ShouldReturn = Trickshots(); if ShouldReturn then return ShouldReturn; end
    end
    -- Pool Focus if nothing else to do
    if Press(S.PoolFocus) then return "Pooling Focus"; end
  end
end

local function AutoBind()
  -- Spell Binds
  WR.Bind(S.SteadyShot)
  WR.Bind(S.AimedShot)
  WR.Bind(S.ArcaneShot)
  WR.Bind(S.ArcaneTorrent)
  WR.Bind(S.ArcanePulse)
  WR.Bind(S.BagofTricks)
  WR.Bind(S.BurstingShot)
  WR.Bind(S.Barrage)
  WR.Bind(S.ChimaeraShot)
  WR.Bind(S.BloodFury)
  WR.Bind(S.DoubleTap)
  WR.Bind(S.CounterShot)
  WR.Bind(S.DeathChakram)
  WR.Bind(S.Exhilaration)
  WR.Bind(S.ExplosiveShot)
  WR.Bind(S.Flare)
  WR.Bind(S.Intimidation)
  WR.Bind(S.KillCommand)
  WR.Bind(S.KillShot)
  WR.Bind(S.MendPet)
  WR.Bind(S.MultiShot)
  WR.Bind(S.RapidFire)
  WR.Bind(S.RevivePet)
  WR.Bind(S.SerpentSting)
  WR.Bind(S.Stampede)
  WR.Bind(S.SteelTrap)
  WR.Bind(S.TarTrap)
  WR.Bind(S.Trueshot)
  WR.Bind(S.SummonPet)
  WR.Bind(S.SummonPet2)
  WR.Bind(S.SummonPet3)
  WR.Bind(S.SummonPet4)
  WR.Bind(S.SummonPet5)
  WR.Bind(S.Volley)
  
  -- Bind Items
  WR.Bind(M.Trinket1)
  WR.Bind(M.Trinket2)
  WR.Bind(M.Healthstone)
  
  -- Macros
  WR.Bind(M.AimedShotMouseover)
  WR.Bind(M.ArcaneShotMouseover)
  WR.Bind(M.BindingShotCursor)
  WR.Bind(M.CounterShotMouseover)
  WR.Bind(M.IntimidationMouseover)
  WR.Bind(M.KillShotMouseover)
  WR.Bind(M.SerpentStingMouseover)
  WR.Bind(M.SteelTrapCursor)
  WR.Bind(M.MisdirectionFocus)
  WR.Bind(M.VolleyCursor)
end

local function Init ()
  WR.Print("Marksmanship by Worldy.")
  AutoBind()
end

WR.SetAPL(254, APL, Init)
