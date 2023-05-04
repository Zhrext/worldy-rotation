--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
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
local Bind       = WR.Bind
local Macro      = WR.Macro
local AoEON      = WR.AoEON
local CDsON      = WR.CDsON
local Cast       = WR.Cast
local Press      = WR.Press
-- Num/Bool Helper Functions
local num        = WR.Commons.Everyone.num
local bool       = WR.Commons.Everyone.bool

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Hunter.Commons,
  Survival = WR.GUISettings.APL.Hunter.Survival
}

-- Spells
local S = Spell.Hunter.Survival

-- Items
local I = Item.Hunter.Survival
local OnUseExcludes = {
  I.AlgetharPuzzleBox:ID(),
  I.ManicGrieftorch:ID(),
}

-- Macros
local M = Macro.Hunter.Survival

-- Trinket Item Objects
local equip = Player:GetEquipment()
local trinket1 = (equip[13]) and Item(equip[13]) or Item(0)
local trinket2 = (equip[14]) and Item(equip[14]) or Item(0)

-- Check when equipment changes
HL:RegisterForEvent(function()
  equip = Player:GetEquipment()
  trinket1 = (equip[13]) and Item(equip[13]) or Item(0)
  trinket2 = (equip[14]) and Item(equip[14]) or Item(0)
end, "PLAYER_EQUIPMENT_CHANGED")

-- Rotation Var
local SummonPetSpells = { S.SummonPet, S.SummonPet2, S.SummonPet3, S.SummonPet4, S.SummonPet5 }
local EnemyCount8ySplash, EnemyList
local BossFightRemains = 11111
local FightRemains = 11111
local MBRSCost = S.MongooseBite:IsAvailable() and S.MongooseBite:Cost() or S.RaptorStrike:Cost()

HL:RegisterForEvent(function()
  MBRSCost = S.MongooseBite:IsAvailable() and S.MongooseBite:Cost() or S.RaptorStrike:Cost()
end, "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB")

HL:RegisterForEvent(function()
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

-- Bombs
local Bombs = { S.WildfireBomb, S.ShrapnelBomb, S.PheromoneBomb, S.VolatileBomb }
local BombDebuffs = { S.WildfireBombDebuff, S.ShrapnelBombDebuff, S.PheromoneBombDebuff, S.VolatileBombDebuff }

-- Function to see if we're going to cap focus
local function CheckFocusCap(SpellCastTime, GenFocus)
  local GeneratedFocus = GenFocus or 0
  return (Player:Focus() + Player:FocusCastRegen(SpellCastTime) + GeneratedFocus < Player:FocusMax())
end

-- CastCycle/CastTargetIf functions
local function EvaluateTargetIfFilterSerpentStingRemains(TargetUnit)
  -- target_if=min:remains
  return (TargetUnit:DebuffRemains(S.SerpentStingDebuff))
end

local function EvaluateTargetIfFilterBloodseekerRemains(TargetUnit)
  -- target_if=min:bloodseeker.remains
  return (TargetUnit:DebuffRemains(S.BloodseekerDebuff))
end

local function EvaluateTargetIfFilterLatentStacks(TargetUnit)
  -- target_if=max:debuff.latent_poison.stack
  return (TargetUnit:DebuffStack(S.LatentPoisonDebuff))
end

local function EvaluateTargetIfKillCommandST(TargetUnit)
  -- if=cooldown.wildfire_bomb.full_recharge_time<2*gcd&debuff.shredded_armor.down&set_bonus.tier30_4pc
  -- Note: All but debuff check handled before CastTargetIf.
  return (TargetUnit:DebuffDown(S.ShreddedArmorDebuff))
end

local function EvaluateTargetIfKillCommandST2(TargetUnit)
  -- if=full_recharge_time<gcd&focus+cast_regen<focus.max&(cooldown.flanking_strike.remains|!talent.flanking_strike)|debuff.shredded_armor.down&set_bonus.tier30_4pc
  return (S.KillCommand:FullRechargeTime() < Player:GCD() and CheckFocusCap(S.KillCommand:ExecuteTime(), 21) and (S.FlankingStrike:CooldownDown() or not S.FlankingStrike:IsAvailable()) or TargetUnit:DebuffDown(S.ShreddedArmorDebuff) and Player:HasTier(30, 4))
end

local function EvaluateTargetIfRaptorStrikeCleave(TargetUnit)
  -- if=debuff.latent_poison.stack>8
  return (TargetUnit:DebuffStack(S.LatentPoisonDebuff) > 8)
end

local function EvaluateTargetIfSerpentStingCleave(TargetUnit)
  -- if=refreshable&target.time_to_die>8&(!talent.vipers_venom|talent.hydras_bite)
  return (TargetUnit:DebuffRefreshable(S.SerpentStingDebuff) and TargetUnit:TimeToDie() > 8 and ((not S.VipersVenom:IsAvailable()) or S.HydrasBite:IsAvailable()))
end

local function EvaluateTargetIfSerpentStingST(TargetUnit)
  -- if=!dot.serpent_sting.ticking&target.time_to_die>7&!talent.vipers_venom
  return (TargetUnit:DebuffDown(S.SerpentStingDebuff) and TargetUnit:TimeToDie() > 7)
end

local function EvaluateTargetIfSerpentStingST2(TargetUnit)
  -- if=refreshable&!talent.vipers_venom
  return (TargetUnit:DebuffRefreshable(S.SerpentStingDebuff))
end

local function Precombat()
  -- flask
  -- augmentation
  -- food
  -- variable,name=mb_rs_cost,op=setif,value=action.mongoose_bite.cost,value_else=action.raptor_strike.cost,condition=talent.mongoose_bite
  -- Defined with profile variables
  -- summon_pet
  -- Moved to Pet Management section in APL()
  -- snapshot_stat
  -- misdirection
  if Focus:Exists() and S.Misdirection:IsReady() then
    if Press(M.MisdirectionFocus) then return "misdirection precombat 0"; end
  end
  -- use_item,name=algethar_puzzle_box
  if I.AlgetharPuzzleBox:IsEquippedAndReady() then
    if Press(M.AlgetharPuzzleBox, nil, true) then return "algethar_puzzle_box precombat 1"; end
  end
  -- steel_trap,precast_time=2
  if S.SteelTrap:IsCastable() and Target:DebuffDown(S.SteelTrapDebuff) then
    if Press(S.SteelTrap, not Target:IsInRange(40)) then return "steel_trap precombat 2"; end
  end
  -- Manually added: harpoon
  if S.Harpoon:IsCastable() and (Player:BuffDown(S.AspectoftheEagle) or not Target:IsInRange(30)) then
    if Press(S.Harpoon, not Target:IsSpellInRange(S.Harpoon)) then return "harpoon precombat 4"; end
  end
  -- Manually added: mongoose_bite or raptor_strike
  if Target:IsInMeleeRange(5) or (Player:BuffUp(S.AspectoftheEagle) and Target:IsInRange(40)) then
    if S.MongooseBite:IsReady() then
      if Press(S.MongooseBite) then return "mongoose_bite precombat 6"; end
    elseif S.RaptorStrike:IsReady() then
      if Press(S.RaptorStrike) then return "raptor_strike precombat 8"; end
    end
  end
end

local function Trinkets()
  if I.AlgetharPuzzleBox:IsEquippedAndReady() and (Player:GCDRemains() > Player:GCD() - 0.6) then
    if Press(M.AlgetharPuzzleBox, nil, true) then return "algethar_puzzle_box cds 17"; end
  end
  -- use_item,name=manic_grieftorch,use_off_gcd=1,if=gcd.remains>gcd.max-0.1&!buff.spearhead.up
  if I.ManicGrieftorch:IsEquippedAndReady() and (Player:GCDRemains() > Player:GCD() - 0.6 and Player:BuffDown(S.SpearheadBuff)) then
    if Press(M.ManicGrieftorch, nil, true) then return "manic_grieftorch cds 18"; end
  end
  -- use_items,slots=trinket1,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<31
  local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
  if Trinket1ToUse then
    if Press(M.Trinket1, nil, nil, true) then return "trinket1 trinket 2"; end
  end
  -- use_items,slots=trinket2,if=buff.call_of_the_wild.up|!talent.call_of_the_wild&(buff.bestial_wrath.up&(buff.bloodlust.up|target.health.pct<20))|fight_remains<31
  local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
  if Trinket2ToUse then
    if Press(M.Trinket2, nil, nil, true) then return "trinket2 trinket 4"; end
  end
end

local function CDs()
  -- blood_fury,if=buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault
  if S.BloodFury:IsCastable() and (Player:BuffUp(S.CoordinatedAssault) or Player:BuffUp(S.SpearheadBuff) or (not S.Spearhead:IsAvailable()) and not S.CoordinatedAssault:IsAvailable()) then
    if Press(S.BloodFury) then return "blood_fury cds 2"; end
  end
  -- harpoon,if=talent.terms_of_engagement.enabled&focus<focus.max
  if S.Harpoon:IsCastable() and (S.TermsofEngagement:IsAvailable() and Player:Focus() < Player:FocusMax()) then
    if Press(S.Harpoon, not Target:IsSpellInRange(S.Harpoon)) then return "harpoon cds 2"; end
  end
  if (Player:BuffUp(S.CoordinatedAssault) or Player:BuffUp(S.SpearheadBuff) or (not S.Spearhead:IsAvailable()) and not S.CoordinatedAssault:IsAvailable()) then
    -- ancestral_call,if=buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault
    if S.AncestralCall:IsCastable() then
      if Press(S.AncestralCall) then return "ancestral_call cds 6"; end
    end
    -- fireblood,if=buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault
    if S.Fireblood:IsCastable() then
      if Press(S.Fireblood) then return "fireblood cds 8"; end
    end
  end
  -- lights_judgment
  if S.LightsJudgment:IsCastable() then
    if Press(S.LightsJudgment, not Target:IsSpellInRange(S.LightsJudgment)) then return "lights_judgment cds 10"; end
  end
  -- bag_of_tricks,if=cooldown.kill_command.full_recharge_time>gcd
  if S.BagofTricks:IsCastable() and (S.KillCommand:FullRechargeTime() > Player:GCD()) then
    if Press(S.BagofTricks, not Target:IsSpellInRange(S.BagofTricks)) then return "bag_of_tricks cds 12"; end
  end
  -- berserking,if=buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault|time_to_die<13
  if S.Berserking:IsCastable() and (Player:BuffUp(S.CoordinatedAssault) or Player:BuffUp(S.SpearheadBuff) or (not S.Spearhead:IsAvailable()) and (not S.CoordinatedAssault:IsAvailable()) or FightRemains < 13) then
    if Press(S.Berserking) then return "berserking cds 14"; end
  end
  -- muzzle
  -- Handled via Interrupt in APL()
  -- potion,if=target.time_to_die<30|buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault
  -- TODO
  -- use_item,name=algethar_puzzle_box,use_off_gcd=1,if=gcd.remains>gcd.max-0.1
  -- Note: Widened the available window by half a second to account for player reaction.
  -- use_items
  local ShouldReturn = Trinkets(); if ShouldReturn then return ShouldReturn; end
  -- aspect_of_the_eagle,if=target.distance>=6
  if S.AspectoftheEagle:IsCastable() and Settings.Survival.AspectOfTheEagle and not Target:IsInRange(6) then
    if Press(S.AspectoftheEagle) then return "aspect_of_the_eagle cds 19"; end
  end
end

local function Cleave()
  -- kill_command,if=debuff.shredded_armor.down&set_bonus.tier30_4pc
  if S.KillCommand:IsCastable() and (Target:DebuffDown(S.ShreddedArmorDebuff) and Player:HasTier(30, 4)) then
    if Press(S.KillCommand, not Target:IsSpellInRange(S.KillCommand)) then return "kill_command cleave 1"; end
  end
  -- wildfire_bomb,if=full_recharge_time<gcd|talent.bombardier&!cooldown.coordinated_assault.remains
  if (S.WildfireBomb:FullRechargeTime() < Player:GCD() or S.Bombardier:IsAvailable() and S.CoordinatedAssault:CooldownUp()) then
    for _, Bomb in pairs(Bombs) do
      if Bomb:IsCastable() then
        if Press(Bomb, not Target:IsSpellInRange(Bomb)) then return "wildfire_bomb cleave 2"; end
      end
    end
  end
  -- death_chakram
  if S.DeathChakram:IsCastable() then
    if Press(S.DeathChakram, not Target:IsSpellInRange(S.DeathChakram)) then return "death_chakram cleave 4"; end
  end
  -- stampede
  if S.Stampede:IsCastable() and CDsON() then
    if Press(S.Stampede, not Target:IsSpellInRange(S.Stampede)) then return "stampede cleave 6"; end
  end
  -- coordinated_assault
  if S.CoordinatedAssault:IsCastable() and CDsON() then
    if Press(S.CoordinatedAssault, not Target:IsSpellInRange(S.CoordinatedAssault)) then return "coordinated_assault cleave 8"; end
  end
  -- kill_shot,if=buff.coordinated_assault_empower.up
  if S.KillShot:IsReady() and (Player:BuffUp(S.CoordinatedAssaultBuff)) then
    if Press(S.KillShot, not Target:IsSpellInRange(S.KillShot)) then return "kill_shot cleave 10"; end
  end
  -- explosive_shot
  if S.ExplosiveShot:IsReady() then
    if Press(S.ExplosiveShot, not Target:IsSpellInRange(S.ExplosiveShot)) then return "explosive_shot cleave 12"; end
  end
  -- carve,if=cooldown.wildfire_bomb.full_recharge_time>spell_targets%2
  if S.Carve:IsReady() and (S.WildfireBomb:FullRechargeTime() > EnemyCount8ySplash / 2) then
    if Press(S.Carve, not Target:IsInMeleeRange(5)) then return "carve cleave 14"; end
  end
  -- butchery,if=full_recharge_time<gcd|dot.shrapnel_bomb.ticking&(dot.internal_bleeding.stack<2|dot.shrapnel_bomb.remains<gcd)
  if S.Butchery:IsReady() and (S.Butchery:FullRechargeTime() < Player:GCD() or Target:DebuffUp(S.ShrapnelBombDebuff) and (Target:DebuffStack(S.InternalBleedingDebuff) < 2 or Target:DebuffRemains(S.ShrapnelBombDebuff) < Player:GCD())) then
    if Press(S.Butchery, not Target:IsInMeleeRange(8)) then return "butchery cleave 16"; end
  end
  -- wildfire_bomb,if=!dot.wildfire_bomb.ticking
  for BombNum, Bomb in pairs(Bombs) do
    if Bomb:IsCastable() and (Target:DebuffDown(BombDebuffs[BombNum])) then
      if Press(Bomb, not Target:IsSpellInRange(Bomb)) then return "wildfire_bomb cleave 18"; end
    end
  end
  -- fury_of_the_eagle
  if S.FuryoftheEagle:IsCastable() then
    if Press(S.FuryoftheEagle, not Target:IsInMeleeRange(5)) then return "fury_of_the_eagle cleave 22"; end
  end
  -- carve,if=dot.shrapnel_bomb.ticking
  if S.Carve:IsReady() and (Target:DebuffUp(S.ShrapnelBombDebuff)) then
    if Press(S.Carve, not Target:IsInMeleeRange(5)) then return "carve cleave 24"; end
  end
  -- flanking_strike,if=focus+cast_regen<focus.max
  if S.FlankingStrike:IsCastable() and (CheckFocusCap(S.FlankingStrike:ExecuteTime(), 30)) then
    if Press(S.FlankingStrike, not Target:IsSpellInRange(S.FlankingStrike)) then return "flanking_strike cleave 26"; end
  end
  -- butchery,if=(!next_wi_bomb.shrapnel|!talent.wildfire_infusion)
  if S.Butchery:IsReady() and ((not S.ShrapnelBomb:IsCastable()) or not S.WildfireInfusion:IsAvailable()) then
    if Press(S.Butchery, not Target:IsInMeleeRange(8)) then return "butchery cleave 28"; end
  end
  -- mongoose_bite,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>8
  if S.MongooseBite:IsReady() then
    if Everyone.CastTargetIf(S.MongooseBite, EnemyList, "max", EvaluateTargetIfFilterLatentStacks, EvaluateTargetIfRaptorStrikeCleave, not Target:IsInMeleeRange(5)) then return "mongoose_bite cleave 30"; end
  end
  -- raptor_strike,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>8
  if S.RaptorStrike:IsReady() then
    if Everyone.CastTargetIf(S.RaptorStrike, EnemyList, "max", EvaluateTargetIfFilterLatentStacks, EvaluateTargetIfRaptorStrikeCleave, not Target:IsInMeleeRange(5)) then return "raptor_strike cleave 32"; end
  end
  -- kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max&full_recharge_time<gcd
  if S.KillCommand:IsCastable() and (CheckFocusCap(S.KillCommand:ExecuteTime()) and S.KillCommand:FullRechargeTime() < Player:GCD()) then
    if Everyone.CastTargetIf(S.KillCommand, EnemyList, "min", EvaluateTargetIfFilterBloodseekerRemains, nil, not Target:IsSpellInRange(S.KillCommand)) then return "kill_command cleave 34"; end
  end
  -- carve
  if S.Carve:IsReady() then
    if Press(S.Carve, not Target:IsInMeleeRange(5)) then return "carve cleave 36"; end
  end
  -- kill_shot,if=!buff.coordinated_assault.up
  if S.KillShot:IsReady() and (Player:BuffDown(S.CoordinatedAssaultBuff)) then
    if Press(S.KillShot, not Target:IsSpellInRange(S.KillShot)) then return "kill_shot cleave 38"; end
  end
  -- steel_trap,if=focus+cast_regen<focus.max
  if S.SteelTrap:IsCastable() and (CheckFocusCap(S.SteelTrap:ExecuteTime())) then
    if Press(S.SteelTrap, not Target:IsInRange(40)) then return "steel_trap cleave 40"; end
  end
  -- spearhead
  if S.Spearhead:IsCastable() and CDsON() then
    if Press(S.Spearhead, not Target:IsSpellInRange(S.Spearhead)) then return "spearhead cleave 41"; end
  end
  -- mongoose_bite,target_if=min:dot.serpent_sting.remains,if=buff.spearhead.remains
  if S.MongooseBite:IsReady() and (Player:BuffUp(S.SpearheadBuff)) then
    if Everyone.CastTargetIf(S.MongooseBite, EnemyList, "min", EvaluateTargetIfFilterSerpentStingRemains, nil, not Target:IsInMeleeRange(5)) then return "mongoose_bite cleave 42"; end
  end
  -- serpent_sting,target_if=min:remains,if=refreshable&target.time_to_die>8&(!talent.vipers_venom|talent.hydras_bite)
  if S.SerpentSting:IsReady() then
    if Everyone.CastTargetIf(S.SerpentSting, EnemyList, "min", EvaluateTargetIfFilterSerpentStingRemains, EvaluateTargetIfSerpentStingCleave, not Target:IsSpellInRange(S.SerpentSting)) then return "serpent_sting cleave 42"; end
  end
  -- mongoose_bite,target_if=min:dot.serpent_sting.remains
  if S.MongooseBite:IsReady() then
    if Everyone.CastTargetIf(S.MongooseBite, EnemyList, "min", EvaluateTargetIfFilterSerpentStingRemains, nil, not Target:IsInMeleeRange(5)) then return "mongoose_bite cleave 44"; end
  end
  -- raptor_strike,target_if=min:dot.serpent_sting.remains
  if S.RaptorStrike:IsReady() then
    if Everyone.CastTargetIf(S.RaptorStrike, EnemyList, "min", EvaluateTargetIfFilterSerpentStingRemains, nil, not Target:IsInMeleeRange(5)) then return "raptor_strike cleave 46"; end
  end
end

local function ST()
  -- death_chakram,if=focus+cast_regen<focus.max|talent.spearhead&!cooldown.spearhead.remains
  if S.DeathChakram:IsCastable() and (CheckFocusCap(S.DeathChakram:ExecuteTime()) or S.Spearhead:IsAvailable() and S.Spearhead:CooldownUp()) then
    if Press(S.DeathChakram, not Target:IsSpellInRange(S.DeathChakram)) then return "death_chakram st 2"; end
  end
  -- spearhead,if=focus+action.kill_command.cast_regen>focus.max-10&(cooldown.death_chakram.remains|!talent.death_chakram)
  if S.Spearhead:IsCastable() and CDsON() and (Player:Focus() + Player:FocusCastRegen(S.KillCommand:ExecuteTime()) + 21 > Player:FocusMax() - 10 and (S.DeathChakram:CooldownDown() or not S.DeathChakram:IsAvailable())) then
    if Press(S.Spearhead, not Target:IsSpellInRange(S.Spearhead)) then return "spearhead st 4"; end
  end
  -- kill_shot,if=buff.coordinated_assault_empower.up
  if S.KillShot:IsReady() and (Player:BuffUp(S.CoordinatedAssaultBuff)) then
    if Press(S.KillShot, not Target:IsSpellInRange(S.KillShot)) then return "kill_shot st 6"; end
  end
  -- wildfire_bomb,if=(raid_event.adds.in>cooldown.wildfire_bomb.full_recharge_time-(cooldown.wildfire_bomb.full_recharge_time%3.5)&debuff.shredded_armor.up&(full_recharge_time<2*gcd|talent.bombardier&!cooldown.coordinated_assault.remains|talent.bombardier&buff.coordinated_assault.up&buff.coordinated_assault.remains<2*gcd)|!raid_event.adds.exists&time_to_die<7)&set_bonus.tier30_4pc
  if (Target:DebuffUp(S.ShreddedArmorDebuff) and (S.WildfireBomb:FullRechargeTime() < 2 * Player:GCD() or S.Bombardier:IsAvailable() and S.CoordinatedAssault:CooldownUp() or S.Bombardier:IsAvailable() and Player:BuffUp(S.CoordinatedAssaultBuff) and Player:BuffRemains(S.CoordinatedAssaultBuff) < 2 * Player:GCD()) or FightRemains < 7) then
    for _, Bomb in pairs(Bombs) do
      if Bomb:IsCastable() then
        if Press(Bomb, not Target:IsSpellInRange(Bomb)) then return "wildfire_bomb st 7"; end
      end
    end
  end
  -- kill_command,target_if=min:bloodseeker.remains,if=full_recharge_time<gcd&focus+cast_regen<focus.max&buff.deadly_duo.stack>1
  if S.KillCommand:IsCastable() and (S.KillCommand:FullRechargeTime() < Player:GCD() and CheckFocusCap(S.KillCommand:ExecuteTime(), 21) and Player:BuffStack(S.DeadlyDuoBuff) > 1) then
    if Everyone.CastTargetIf(S.KillCommand, EnemyList, "min", EvaluateTargetIfFilterBloodseekerRemains, nil, not Target:IsSpellInRange(S.KillCommand)) then return "kill_command st 8"; end
  end
  -- kill_command,target_if=min:bloodseeker.remains,if=cooldown.wildfire_bomb.full_recharge_time<2*gcd&debuff.shredded_armor.down&set_bonus.tier30_4pc
  if S.KillCommand:IsCastable() and (S.WildfireBomb:FullRechargeTime() < 2 * Player:GCD() and Player:HasTier(30, 4)) then
    if Everyone.CastTargetIf(S.KillCommand, EnemyList, "min", EvaluateTargetIfFilterBloodseekerRemains, EvaluateTargetIfKillCommandST, not Target:IsSpellInRange(S.KillCommand)) then return "kill_command st 9"; end
  end
  -- mongoose_bite,if=buff.spearhead.remains
  if S.MongooseBite:IsReady() and (Player:BuffUp(S.SpearheadBuff)) then
    if Press(S.MongooseBite, not Target:IsInMeleeRange(5)) then return "mongoose_bite st 10"; end
  end
  -- mongoose_bite,if=active_enemies=1&target.time_to_die<focus%(variable.mb_rs_cost-cast_regen)*gcd|buff.mongoose_fury.up&buff.mongoose_fury.remains<gcd
  if S.MongooseBite:IsReady() and (EnemyCount8ySplash == 1 and Target:TimeToDie() < Player:Focus() / (MBRSCost - Player:FocusCastRegen(S.MongooseBite:ExecuteTime())) * Player:GCD() or Player:BuffUp(S.MongooseFuryBuff) and Player:BuffRemains(S.MongooseFuryBuff) < Player:GCD()) then
    if Press(S.MongooseBite, not Target:IsInMeleeRange(5)) then return "mongoose_bite st 12"; end
  end
  -- kill_shot,if=!buff.coordinated_assault.up
  if S.KillShot:IsReady() and (Player:BuffDown(S.CoordinatedAssaultBuff)) then
    if Press(S.KillShot, not Target:IsSpellInRange(S.KillShot)) then return "kill_shot st 14"; end
  end
  -- raptor_strike,if=active_enemies=1&target.time_to_die<focus%(variable.mb_rs_cost-cast_regen)*gcd
  if S.RaptorStrike:IsReady() and (EnemyCount8ySplash == 1 and Target:TimeToDie() < Player:Focus() / (MBRSCost - Player:FocusCastRegen(S.RaptorStrike:ExecuteTime())) * Player:GCD()) then
    if Press(S.RaptorStrike, not Target:IsInMeleeRange(5)) then return "raptor_strike st 16"; end
  end
  -- serpent_sting,target_if=min:remains,if=!dot.serpent_sting.ticking&target.time_to_die>7&!talent.vipers_venom
  if S.SerpentSting:IsReady() and (not S.VipersVenom:IsAvailable()) then
    if Everyone.CastTargetIf(S.SerpentSting, EnemyList, "min", EvaluateTargetIfFilterSerpentStingRemains, EvaluateTargetIfSerpentStingST, not Target:IsSpellInRange(S.SerpentSting)) then return "serpent_sting st 18"; end
  end
  -- mongoose_bite,if=talent.alpha_predator&buff.mongoose_fury.up&buff.mongoose_fury.remains<focus%(variable.mb_rs_cost-cast_regen)*gcd
  if S.MongooseBite:IsReady() and (S.AlphaPredator:IsAvailable() and Player:BuffUp(S.MongooseFuryBuff) and Player:BuffRemains(S.MongooseFuryBuff) < Player:Focus() / (MBRSCost - Player:FocusCastRegen(S.MongooseBite:ExecuteTime())) * Player:GCD()) then
    if Press(S.MongooseBite, not Target:IsInMeleeRange(5)) then return "mongoose_bite st 20"; end
  end
  -- flanking_strike,if=focus+cast_regen<focus.max
  if S.FlankingStrike:IsCastable() and (CheckFocusCap(S.FlankingStrike:ExecuteTime(), 30)) then
    if Press(S.FlankingStrike, not Target:IsSpellInRange(S.FlankingStrike)) then return "flanking_strike st 22"; end
  end
  -- stampede
  if S.Stampede:IsCastable() and CDsON() then
    if Press(S.Stampede, not Target:IsSpellInRange(S.Stampede)) then return "stampede st 23"; end
  end
  -- coordinated_assault,if=!talent.coordinated_kill&target.health.pct<20&(!buff.spearhead.remains&cooldown.spearhead.remains|!talent.spearhead)|talent.coordinated_kill&(!buff.spearhead.remains&cooldown.spearhead.remains|!talent.spearhead)
  if S.CoordinatedAssault:IsCastable() and CDsON() and ((not S.CoordinatedKill:IsAvailable()) and Target:HealthPercentage() < 20 and (Player:BuffDown(S.SpearheadBuff) and S.Spearhead:CooldownDown() or not S.Spearhead:IsAvailable()) or S.CoordinatedKill:IsAvailable() and (Player:BuffDown(S.SpearheadBuff) and S.Spearhead:CooldownDown() or not S.Spearhead:IsAvailable())) then
    if Press(S.CoordinatedAssault, not Target:IsSpellInRange(S.CoordinatedAssault)) then return "coordinated_assault st 24"; end
  end
  -- kill_command,target_if=min:bloodseeker.remains,if=full_recharge_time<gcd&focus+cast_regen<focus.max&(cooldown.flanking_strike.remains|!talent.flanking_strike)|debuff.shredded_armor.down&set_bonus.tier30_4pc
  if S.KillCommand:IsCastable() then
    if Everyone.CastTargetIf(S.KillCommand, EnemyList, "min", EvaluateTargetIfFilterBloodseekerRemains, EvaluateTargetIfKillCommandST2, not Target:IsSpellInRange(S.KillCommand)) then return "kill_command st 28"; end
  end
  -- mongoose_bite,if=dot.shrapnel_bomb.ticking
  if S.MongooseBite:IsReady() and (Target:DebuffUp(S.ShrapnelBombDebuff)) then
    if Press(S.MongooseBite, not Target:IsInMeleeRange(5)) then return "mongoose_bite st 30"; end
  end
  -- serpent_sting,target_if=min:remains,if=refreshable&!talent.vipers_venom
  if S.SerpentSting:IsReady() and (not S.VipersVenom:IsAvailable()) then
    if Everyone.CastTargetIf(S.SerpentSting, EnemyList, "min", EvaluateTargetIfFilterSerpentStingRemains, EvaluateTargetIfSerpentStingST2, not Target:IsSpellInRange(S.SerpentSting)) then return "serpent_sting st 32"; end
  end
  -- wildfire_bomb,if=raid_event.adds.in>cooldown.wildfire_bomb.full_recharge_time-(cooldown.wildfire_bomb.full_recharge_time%3.5)&full_recharge_time<gcd&(!set_bonus.tier29_2pc|active_enemies>1)
  if (S.WildfireBomb:FullRechargeTime() < Player:GCD() and ((not Player:HasTier(29, 2)) or EnemyCount8ySplash > 1)) then
    for _, Bomb in pairs(Bombs) do
      if Bomb:IsCastable() then
        if Press(Bomb, not Target:IsSpellInRange(Bomb)) then return "wildfire_bomb st 34"; end
      end
    end
  end
  -- mongoose_bite,target_if=max:debuff.latent_poison.stack,if=buff.mongoose_fury.up
  if S.MongooseBite:IsReady() and (Player:BuffUp(S.MongooseFuryBuff)) then
    if Everyone.CastTargetIf(S.MongooseBite, EnemyList, "max", EvaluateTargetIfFilterLatentStacks, nil, not Target:IsInMeleeRange(5)) then return "mongoose_bite st 36"; end
  end
  -- explosive_shot,if=talent.ranger
  if S.ExplosiveShot:IsReady() and (S.Ranger:IsAvailable()) then
    if Press(S.ExplosiveShot, not Target:IsSpellInRange(S.ExplosiveShot)) then return "explosive_shot st 37"; end
  end
  -- wildfire_bomb,if=raid_event.adds.in>cooldown.wildfire_bomb.full_recharge_time-(cooldown.wildfire_bomb.full_recharge_time%3.5)&(full_recharge_time<gcd|!dot.wildfire_bomb.ticking&set_bonus.tier30_4pc)
  for BombNum, Bomb in pairs(Bombs) do
    if Bomb:IsCastable() then
      if (S.WildfireBomb:FullRechargeTime() < Player:GCD() or Target:DebuffDown(BombDebuffs[BombNum]) and Player:HasTier(30, 4)) then
        if Press(Bomb, not Target:IsSpellInRange(Bomb)) then return "wildfire_bomb st 38"; end
      end
    end
  end
  -- mongoose_bite,target_if=max:debuff.latent_poison.stack,if=focus+action.kill_command.cast_regen>focus.max-10|set_bonus.tier30_4pc
  if S.MongooseBite:IsReady() and (Player:Focus() + Player:FocusCastRegen(S.KillCommand:ExecuteTime()) + 21 > Player:FocusMax() - 10 or Player:HasTier(30, 4)) then
    if Everyone.CastTargetIf(S.MongooseBite, EnemyList, "max", EvaluateTargetIfFilterLatentStacks, nil, not Target:IsInMeleeRange(5)) then return "mongoose_bite st 40"; end
  end
  -- raptor_strike,target_if=max:debuff.latent_poison.stack
  if S.RaptorStrike:IsReady() then
    if Everyone.CastTargetIf(S.RaptorStrike, EnemyList, "max", EvaluateTargetIfFilterLatentStacks, nil, not Target:IsInMeleeRange(5)) then return "raptor_strike st 46"; end
  end
  -- steel_trap
  if S.SteelTrap:IsCastable() then
    if Press(S.SteelTrap, not Target:IsInRange(40)) then return "steel_trap st 48"; end
  end
  -- wildfire_bomb,if=!dot.wildfire_bomb.ticking
  for BombNum, Bomb in pairs(Bombs) do
    if Bomb:IsCastable() and (Target:DebuffDown(BombDebuffs[BombNum])) then
      if Press(Bomb, not Target:IsSpellInRange(Bomb)) then return "wildfire_bomb st 50"; end
    end
  end
  -- kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max
  if S.KillCommand:IsCastable() and (CheckFocusCap(S.KillCommand:ExecuteTime(), 21)) then
    if Everyone.CastTargetIf(S.KillCommand, EnemyList, "min", EvaluateTargetIfFilterBloodseekerRemains, nil, not Target:IsSpellInRange(S.KillCommand)) then return "kill_command st 52"; end
  end
  -- coordinated_assault,if=!talent.coordinated_kill&time_to_die>140
  if S.CoordinatedAssault:IsCastable() and ((not S.CoordinatedKill:IsAvailable()) and Target:TimeToDie() > 140) then
    if Press(S.CoordinatedAssault, not Target:IsSpellInRange(S.CoordinatedAssault)) then return "coordinated_assault st 54"; end
  end
  -- fury_of_the_eagle,interrupt=1
  if S.FuryoftheEagle:IsCastable() then
    if Press(S.FuryoftheEagle, not Target:IsInMeleeRange(5)) then return "fury_of_the_eagle st 56"; end
  end
end

local function APL()
  -- Target Count Checking
  local EagleUp = Player:BuffUp(S.AspectoftheEagle)
  if AoEON() then
    if EagleUp and not Target:IsInMeleeRange(8) then
      EnemyCount8ySplash = Target:GetEnemiesInSplashRangeCount(8)
    else
      EnemyCount8ySplash = #Player:GetEnemiesInRange(8)
    end
  else
    EnemyCount8ySplash = 1
  end

  if EagleUp then
    EnemyList = Player:GetEnemiesInRange(40)
  else
    EnemyList = Player:GetEnemiesInRange(8)
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(EnemyList, false)
    end
  end

  -- Pet Management; Conditions handled via override
  if not (Player:IsMounted() or Player:IsInVehicle()) then
    if S.RevivePet:IsCastable() then
      if Press(S.RevivePet, nil, true) then return "Revive Pet"; end
    end
    if S.SummonPet:IsCastable() then
      if Press(SummonPetSpells[Settings.Commons.SummonPetSlot]) then return "Summon Pet"; end
    end
    if S.MendPet:IsCastable() then
      if Press(S.MendPet) then return "Mend Pet"; end
    end
  end

  if Everyone.TargetIsValid() then
    -- Out of Combat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- Exhilaration
    if S.Exhilaration:IsCastable() and Player:HealthPercentage() <= Settings.Commons.HP.Exhilaration then
      if Press(S.Exhilaration) then return "Exhilaration"; end
    end
    -- healthstone
    if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
      if Press(M.Healthstone, nil, nil, true) then return "healthstone defensive 3"; end
    end
    -- Interrupts
    if not Player:IsCasting() and not Player:IsChanneling() then
      local ShouldReturn = Everyone.Interrupt(S.Muzzle, 5, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.Intimidation, 40); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.Interrupt(S.Muzzle, 5, true, Mouseover, M.MuzzleMouseover); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.Intimidation, 40, nil, Mouseover, M.IntimidationMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- Dispels
    if Settings.General.Enabled.DispelBuffs and S.TranquilizingShot:IsReady() and not Player:IsCasting() and not Player:IsChanneling() and (Everyone.UnitHasEnrageBuff(Target) or Everyone.UnitHasMagicBuff(Target)) then
      if Press(S.TranquilizingShot, not Target:IsSpellInRange(S.TranquilizingShot)) then return "dispel"; end
    end
    -- auto_attack
    -- Manually added: If out of range, use Aspect of the Eagle, otherwise Harpoon to get back into range
    if not EagleUp and not Target:IsInMeleeRange(8) then
      if S.AspectoftheEagle:IsCastable() then
        if Press(S.AspectoftheEagle) then return "aspect_of_the_eagle oor"; end
      end
      if S.Harpoon:IsCastable() then
        if Press(S.Harpoon, not Target:IsSpellInRange(S.Harpoon)) then return "harpoon oor"; end
      end
    end
    -- call_action_list,name=cds
    if (CDsON()) then
      local ShouldReturn = CDs(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=st,if=active_enemies<3
    if (EnemyCount8ySplash < 3) then
      local ShouldReturn = ST(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=cleave,if=active_enemies>2
    if (EnemyCount8ySplash > 2) then
      local ShouldReturn = Cleave(); if ShouldReturn then return ShouldReturn; end
    end
    -- arcane_torrent
    if S.ArcaneTorrent:IsCastable() and CDsON() then
      if Press(S.ArcaneTorrent, not Target:IsInRange(8)) then return "arcane_torrent main 888"; end
    end
    -- PoolFocus if nothing else to do
    if Press(S.PoolFocus) then return "Pooling Focus"; end
  end
end

local function AutoBind()
  -- Spell Binds  
  Bind(S.AspectoftheEagle)
  Bind(S.ArcaneTorrent)
  Bind(S.ArcanePulse)
  Bind(S.BagofTricks)
  Bind(S.Berserking)
  Bind(S.BloodFury)
  Bind(S.Butchery)
  Bind(S.CoordinatedAssault)
  Bind(S.Muzzle)
  Bind(S.DeathChakram)
  Bind(S.Exhilaration)
  Bind(S.ExplosiveShot)
  Bind(S.Harpoon)
  Bind(S.FuryoftheEagle)
  Bind(S.FlankingStrike)
  Bind(S.Intimidation)
  Bind(S.KillCommand)
  Bind(S.KillShot)
  Bind(S.MendPet)
  Bind(S.MongooseBite)
  Bind(S.RaptorStrike)
  Bind(S.RevivePet)
  Bind(S.SerpentSting)
  Bind(S.Stampede)
  Bind(S.Spearhead)
  Bind(S.SteelTrap)
  Bind(S.TranquilizingShot)
  Bind(S.SummonPet)
  Bind(S.SummonPet2)
  Bind(S.SummonPet3)
  Bind(S.SummonPet4)
  Bind(S.SummonPet5)
  Bind(S.WildfireBomb)
  Bind(S.ShrapnelBomb)
  Bind(S.PheromoneBomb)
  Bind(S.VolatileBomb)
  
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  
  Bind(M.AlgetharPuzzleBox)
  Bind(M.ManicGrieftorch)
  
  -- Macros
  Bind(M.BindingShotCursor)
  Bind(M.MuzzleMouseover)
  Bind(M.IntimidationMouseover)
  Bind(M.MisdirectionFocus)
end

local function OnInit ()
  WR.Print("Survival Hunter rotation by Worldy.")
  AutoBind()
end

WR.SetAPL(255, APL, OnInit)
