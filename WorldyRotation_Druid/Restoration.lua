--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC           = HeroDBC.DBC
-- HeroLib
local HL            = HeroLib
local Cache         = HeroCache
local Utils         = HL.Utils
local Unit          = HL.Unit
local Player        = Unit.Player
local Pet           = Unit.Pet
local Target        = Unit.Target
local Focus         = Unit.Focus
local Mouseover     = Unit.MouseOver
local Spell         = HL.Spell
local MultiSpell    = HL.MultiSpell
local Item          = HL.Item
-- WorldyRotation
local WR            = WorldyRotation
local AoEON         = WR.AoEON
local Bind          = WR.Bind
local CDsON         = WR.CDsON
local Cast          = WR.Cast
local Press         = WR.Press
local Macro         = WR.Macro
-- Num/Bool Helper Functions
local num           = WR.Commons.Everyone.num
local bool          = WR.Commons.Everyone.bool
-- Lua
local stringformat = string.format

-- Commons
local Everyone = WR.Commons.Everyone

-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Druid.Commons,
  Restoration = WR.GUISettings.APL.Druid.Restoration
}

-- Spells
local S = Spell.Druid.Restoration

-- Items
local I = Item.Druid.Restoration
local OnUseExcludes = {
  --  I.TrinketName:ID(),
}

-- Macros
local M = Macro.Druid.Restoration

-- Enemies Variables
local Enemies8ySplash, EnemiesCount8ySplash
local BossFightRemains = 11111
local FightRemains = 11111

-- Eclipse Variables
local EclipseInAny = false
local EclipseInBoth = false
local EclipseInLunar = false
local EclipseInSolar = false
local EclipseLunarNext = false
local EclipseSolarNext = false
local EclipseAnyNext = false

-- Trinket Item Objects
local equip = Player:GetEquipment()
local trinket1 = (equip[13]) and Item(equip[13]) or Item(0)
local trinket2 = (equip[14]) and Item(equip[14]) or Item(0)

HL:RegisterForEvent(function()
  equip = Player:GetEquipment()
  trinket1 = (equip[13]) and Item(equip[13]) or Item(0)
  trinket2 = (equip[14]) and Item(equip[14]) or Item(0)
end, "PLAYER_EQUIPMENT_CHANGED")

HL:RegisterForEvent(function()
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

-- PMultiplier Registration
local function ComputeRakePMultiplier()
  return Player:StealthUp(true, true) and 1.6 or 1
end
S.Rake:RegisterPMultiplier(S.RakeDebuff, ComputeRakePMultiplier)

-- Helper Functions
local function EclipseCheck()
  EclipseInAny = (Player:BuffUp(S.EclipseSolar) or Player:BuffUp(S.EclipseLunar))
  EclipseInBoth = (Player:BuffUp(S.EclipseSolar) and Player:BuffUp(S.EclipseLunar))
  EclipseInLunar = (Player:BuffUp(S.EclipseLunar) and Player:BuffDown(S.EclipseSolar))
  EclipseInSolar = (Player:BuffUp(S.EclipseSolar) and Player:BuffDown(S.EclipseLunar))
  EclipseLunarNext = (not EclipseInAny and (S.Starfire:Count() == 0 and S.Wrath:Count() > 0 or Player:IsCasting(S.Wrath))) or EclipseInSolar
  EclipseSolarNext = (not EclipseInAny and (S.Wrath:Count() == 0 and S.Starfire:Count() > 0 or Player:IsCasting(S.Starfire))) or EclipseInLunar
  EclipseAnyNext = (not EclipseInAny and S.Wrath:Count() > 0 and S.Starfire:Count() > 0)
end

local function EvaluateCycleCatSunfire(TargetUnit)
  return (TargetUnit:DebuffRefreshable(S.SunfireDebuff) and FightRemains > 5)
end

local function EvaluateCycleCatMoonfire(TargetUnit)
  return (TargetUnit:DebuffRefreshable(S.MoonfireDebuff) and FightRemains > 12 and (((EnemiesCount8ySplash <= 4 or Player:Energy() < 50) and Player:BuffDown(S.HeartOfTheWild)) or ((EnemiesCount8ySplash <= 4 or Player:Energy() < 50) and Player:BuffUp(S.HeartOfTheWild))) and TargetUnit:DebuffDown(S.MoonfireDebuff) or (Player:PrevGCD(1, S.Sunfire) and (TargetUnit:DebuffUp(S.MoonfireDebuff) and TargetUnit:DebuffRemains(S.MoonfireDebuff) < TargetUnit:DebuffDuration(S.MoonfireDebuff) * 0.8 or TargetUnit:DebuffDown(S.MoonfireDebuff)) and EnemiesCount8ySplash == 1))
end

local function EvaluateCycleOwlDoT(TargetUnit)
  return (TargetUnit:DebuffRefreshable(S.MoonfireDebuff) and TargetUnit:TimeToDie() > 5)
end

local function EvaluateCycleCatRip(TargetUnit)
  return ((TargetUnit:DebuffRefreshable(S.Rip) or Player:Energy() > 90 and TargetUnit:DebuffRemains(S.Rip) <= 10) and (Player:ComboPoints() == 5 and TargetUnit:TimeToDie() > TargetUnit:DebuffRemains(S.Rip) + 24 or (TargetUnit:DebuffRemains(S.Rip) + Player:ComboPoints() * 4 < TargetUnit:TimeToDie() and TargetUnit:DebuffRemains(S.Rip) + 4 + Player:ComboPoints() * 4 > TargetUnit:TimeToDie())) or TargetUnit:DebuffDown(S.Rip) and Player:ComboPoints() > 2 + EnemiesCount8ySplash * 2)
end

local function EvaluateCycleCatRake(TargetUnit)
  return ((TargetUnit:DebuffDown(S.RakeDebuff) or TargetUnit:DebuffRefreshable(S.RakeDebuff)) and TargetUnit:TimeToDie() > 10 and Player:ComboPoints() < 5)
end

local function EvaluateCycleCatRake2(TargetUnit)
  return (TargetUnit:DebuffUp(S.AdaptiveSwarmDebuff))
end

local function HotsCount()
  return Everyone.FriendlyUnitsWithBuffCount(S.Rejuvenation) + Everyone.FriendlyUnitsWithBuffCount(S.Regrowth) + Everyone.FriendlyUnitsWithBuffCount(S.Wildgrowth)
end

local function PossibleRejuvenationCount()
  return Everyone.FriendlyUnitsWithoutBuffCount(S.Rejuvenation)
end

local function EvaluateSwiftmend(TargetUnit)
  return TargetUnit:BuffUp(S.Rejuvenation) or TargetUnit:BuffUp(S.Regrowth) or TargetUnit:BuffUp(S.Wildgrowth)
end

local function Trinkets()
  local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
  if Trinket1ToUse and (Player:BuffUp(S.HeartOfTheWild) or Player:BuffUp(S.IncarnationBuff) or Player:BloodlustUp() or BossFightRemains < 60) then
    if Press(M.Trinket1, nil, nil, true) then return "trinket1 trinkets 2"; end
  end
  local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
  if Trinket2ToUse and (Player:BuffUp(S.HeartOfTheWild) or Player:BuffUp(S.IncarnationBuff) or Player:BloodlustUp() or BossFightRemains < 60) then
    if Press(M.Trinket2, nil, nil, true) then return "trinket2 trinkets 4"; end
  end
end

local function Cat()
  -- rake,if=buff.shadowmeld.up|buff.prowl.up
  if S.Rake:IsReady() and (Player:StealthUp(false, true)) then
    if Press(S.Rake, not Target:IsInMeleeRange(10)) then return "rake cat 2"; end
  end
  -- use_items,if=!buff.prowl.up&!buff.shadowmeld.up
  if Settings.General.Enabled.Trinkets and (not Player:StealthUp(false, true)) then
      local ShouldReturn = Trinkets(); if ShouldReturn then return ShouldReturn; end
  end
  -- auto_attack,if=!buff.prowl.up&!buff.shadowmeld.up
  -- Note: Not handled...
  if S.AdaptiveSwarm:IsCastable() then
    -- adaptive_swarm,target_if=dot.adaptive_swarm_damage.stack=2&dot.adaptive_swarm_damage.remains>2
    if Press(S.AdaptiveSwarm, not Target:IsSpellInRange(S.AdaptiveSwarm)) then return "adaptive_swarm cat"; end
  end
  -- convoke_the_spirits,if=(buff.heart_of_the_wild.up|cooldown.heart_of_the_wild.remains>60-30*runeforge.celestial_spirits|!talent.heart_of_the_wild.enabled)&buff.cat_form.up&energy<50&(combo_points<5&dot.rip.remains>5|spell_targets.swipe_cat>1)
  if Settings.Restoration.Damage.Enabled.ConvokeTheSpirits and S.ConvokeTheSpirits:IsCastable() and CDsON() and ((Player:BuffUp(S.HeartOfTheWild) or S.HeartOfTheWild:CooldownRemains() > 60 or not S.HeartOfTheWild:IsAvailable()) and Player:BuffUp(S.CatForm) and Player:Energy() < 50 and (Player:ComboPoints() < 5 and Target:DebuffRemains(S.Rip) > 5 or EnemiesCount8ySplash > 1)) then
    if Press(S.ConvokeTheSpirits, not Target:IsInRange(30)) then return "convoke_the_spirits cat 18"; end
  end
  -- sunfire,target_if=(refreshable&target.time_to_die>5)&!prev_gcd.1.cat_form
  if S.Sunfire:IsReady() and Player:BuffDown(S.CatForm) and Target:TimeToDie() > 5 and ((not S.Rip:IsAvailable() or Target:DebuffUp(S.Rip)) or Player:Energy() < 30) then
    if Everyone.CastCycle(S.Sunfire, Enemies8ySplash, EvaluateCycleCatSunfire, not Target:IsSpellInRange(S.Sunfire), nil, nil, M.SunfireMouseover) then return "sunfire cat 20"; end
  end
  -- moonfire,target_if=(refreshable&time_to_die>12&(((spell_targets.swipe_cat<=4+4*covenant.necrolord|energy<50)&!buff.heart_of_the_wild.up)|((spell_targets.swipe_cat<=4|energy<50)&buff.heart_of_the_wild.up))&!ticking|(prev_gcd.1.sunfire&remains<duration*0.8&spell_targets.sunfire=1))&!prev_gcd.1.cat_form
  if S.Moonfire:IsReady() and Player:BuffDown(S.CatForm) and Target:TimeToDie() > 5 and ((not S.Rip:IsAvailable() or Target:DebuffUp(S.Rip)) or Player:Energy() < 30) then
    if Everyone.CastCycle(S.Moonfire, Enemies8ySplash, EvaluateCycleCatMoonfire, not Target:IsSpellInRange(S.Moonfire), nil, nil, M.MoonfireMouseover) then return "moonfire cat 22"; end
  end
  -- sunfire,if=prev_gcd.1.moonfire&remains<duration*0.8
  -- Manually added
  if S.Sunfire:IsReady() and Target:DebuffDown(S.SunfireDebuff) and Target:TimeToDie() > 5  then
    if Press(S.Sunfire, not Target:IsSpellInRange(S.Sunfire)) then return "sunfire cat 24"; end
  end
  -- Manually added
  if S.Moonfire:IsReady() and Player:BuffDown(S.CatForm) and Target:DebuffDown(S.MoonfireDebuff) and Target:TimeToDie() > 5  then
    if Press(S.Moonfire, not Target:IsSpellInRange(S.Moonfire)) then return "moonfire cat 24"; end
  end
  -- starsurge,if=!buff.cat_form.up
  if S.Starsurge:IsReady() and (Player:BuffDown(S.CatForm)) then
    if Press(S.Starsurge, not Target:IsSpellInRange(S.Starsurge)) then return "starsurge cat 26"; end
  end
  -- heart_of_the_wild,if=(cooldown.convoke_the_spirits.remains<30|!covenant.night_fae)&!buff.heart_of_the_wild.up&dot.sunfire.ticking&(dot.moonfire.ticking|spell_targets.swipe_cat>4+2*covenant.necrolord)
  if S.HeartOfTheWild:IsCastable() and CDsON() and ((S.ConvokeTheSpirits:CooldownRemains() < 30 or not S.ConvokeTheSpirits:IsAvailable()) and Player:BuffDown(S.HeartOfTheWild) and Target:DebuffUp(S.SunfireDebuff) and (Target:DebuffUp(S.MoonfireDebuff) or EnemiesCount8ySplash > 4)) then
    if Press(S.HeartOfTheWild) then return "heart_of_the_wild cat 26"; end
  end
  -- cat_form,if=!buff.cat_form.up&energy>50
  if S.CatForm:IsReady() and (Player:BuffDown(S.CatForm) and Player:Energy() >= 30) then
    if Press(S.CatForm) then return "cat_form cat 28"; end
  end
  -- ferocious_bite,if=(combo_points>3&target.1.time_to_die<3|combo_points=5&energy>=50&dot.rip.remains>10)
  if S.FerociousBite:IsReady() and ((Player:ComboPoints() > 3 and Target:TimeToDie() < 10) or (Player:ComboPoints() == 5 and Player:Energy() >= 25 and (not S.Rip:IsAvailable() or Target:DebuffRemains(S.Rip) > 5))) then
    if Press(S.FerociousBite, not Target:IsInMeleeRange(5)) then return "ferocious_bite cat 32"; end
  end
  -- rip,target_if=((refreshable|energy>90&remains<=10)&(combo_points=5&time_to_die>remains+24|(remains+combo_points*4<time_to_die&remains+4+combo_points*4>time_to_die))|!ticking&combo_points>2+spell_targets.swipe_cat*2)&spell_targets.swipe_cat<11
  if S.Rip:IsAvailable() and S.Rip:IsReady() and (EnemiesCount8ySplash < 11) and EvaluateCycleCatRip(Target) then
    if Press(S.Rip, not Target:IsInMeleeRange(5)) then return "rip cat 34"; end
  end
  if S.Thrash:IsReady() and EnemiesCount8ySplash >= 2 and Target:DebuffRefreshable(S.ThrashDebuff) then
    if Press(S.Thrash, not Target:IsInMeleeRange(8)) then return "thrash cat"; end
  end
  -- rake,target_if=refreshable&time_to_die>10&(combo_points<5|remains<1)&spell_targets.swipe_cat<5
  if S.Rake:IsReady() and EvaluateCycleCatRake(Target) then
    if Press(S.Rake, not Target:IsInMeleeRange(5)) then return "rake cat 36"; end
  end
  -- rake,target_if=dot.adaptive_swarm_damage.ticking&runeforge.draught_of_deep_focus,if=(combo_points<5|energy>90)&runeforge.draught_of_deep_focus&dot.rake.pmultiplier<=persistent_multiplier
  if S.Rake:IsReady() and ((Player:ComboPoints() < 5 or Player:Energy() > 90) and Target:PMultiplier(S.Rake) <= Player:PMultiplier(S.Rake)) and EvaluateCycleCatRake2(Target) then
    if Press(S.Rake, not Target:IsInMeleeRange(5)) then return "rake cat 40"; end
  end
  -- swipe_cat,if=spell_targets.swipe_cat>=2
  if S.Swipe:IsReady() and (EnemiesCount8ySplash >= 2) then
    if Press(S.Swipe, not Target:IsInMeleeRange(8)) then return "swipe cat 38"; end
  end
  -- shred,if=combo_points<5|energy>90
  if S.Shred:IsReady() and (Player:ComboPoints() < 5 or Player:Energy() > 90) then
    if Press(S.Shred, not Target:IsInMeleeRange(5)) then return "shred cat 42"; end
  end
end

local function Owl()
  -- heart_of_the_wild,if=(cooldown.convoke_the_spirits.remains<30|cooldown.convoke_the_spirits.remains>90|!covenant.night_fae)&!buff.heart_of_the_wild.up
  if S.HeartOfTheWild:IsCastable() and CDsON() and ((S.ConvokeTheSpirits:CooldownRemains() < 30 or S.ConvokeTheSpirits:CooldownRemains() > 90 or not S.ConvokeTheSpirits:IsAvailable()) and Player:BuffDown(S.HeartOfTheWild)) then
    if Press(S.HeartOfTheWild) then return "heart_of_the_wild owl 2"; end
  end
  -- moonkin_form,if=!buff.moonkin_form.up
  if S.MoonkinForm:IsReady() and (Player:BuffDown(S.MoonkinForm)) then
    if Press(S.MoonkinForm) then return "moonkin_form owl 4"; end
  end
  -- starsurge,if=spell_targets.starfire<6|!eclipse.in_lunar&spell_targets.starfire<8
  if S.Starsurge:IsReady() and (EnemiesCount8ySplash < 6 or (not EclipseInLunar) and EnemiesCount8ySplash < 8) then
    if Press(S.Starsurge, not Target:IsSpellInRange(S.Starsurge)) then return "starsurge owl 8"; end
  end
  -- moonfire,target_if=refreshable&target.time_to_die>5&(spell_targets.starfire<5|!eclipse.in_lunar&spell_targets.starfire<7)
  if S.Moonfire:IsReady() and (EnemiesCount8ySplash < 5 or (not EclipseInLunar) and EnemiesCount8ySplash < 7) then
    if Everyone.CastCycle(S.Moonfire, Enemies8ySplash, EvaluateCycleOwlDoT, not Target:IsSpellInRange(S.Moonfire), nil, nil, M.MoonfireMouseover) then return "moonfire owl 10"; end
  end
  -- sunfire,target_if=refreshable&target.time_to_die>5
  if S.Sunfire:IsReady() then
    if Everyone.CastCycle(S.Sunfire, Enemies8ySplash, EvaluateCycleOwlDoT, not Target:IsSpellInRange(S.Sunfire), nil, nil, M.SunfireMouseover) then return "sunfire owl 12"; end
  end
  -- wrath,if=eclipse.in_solar&spell_targets.starfire=1|eclipse.lunar_next|eclipse.any_next&spell_targets.starfire>1
  if S.Wrath:IsReady() and (Player:BuffDown(S.CatForm) or not Target:IsInMeleeRange(8)) and (EclipseInSolar and EnemiesCount8ySplash == 1 or EclipseLunarNext or EclipseAnyNext and EnemiesCount8ySplash > 1) then
    if Press(S.Wrath, not Target:IsSpellInRange(S.Wrath), true) then return "wrath owl 14"; end
  end
  -- starfire
  if S.Starfire:IsReady() then
    if Press(S.Starfire, not Target:IsSpellInRange(S.Starfire), true) then return "starfire owl 16"; end
  end
end

local function Damage()
  -- Explosives
  if (Settings.Commons.Enabled.HandleExplosives) then
    local ShouldReturn = Everyone.HandleExplosive(S.Moonfire, M.MoonfireMouseover); if ShouldReturn then return ShouldReturn; end
  end
  -- Eclipse Check
  EclipseCheck()
  -- run_action_list,name=cat,if=talent.feral_affinity.enabled
  if S.FeralAffinity:IsAvailable() and Target:IsInMeleeRange(8) then
    local ShouldReturn = Cat(); if ShouldReturn then return ShouldReturn; end
  end
  if S.AdaptiveSwarm:IsCastable() then
    -- adaptive_swarm,target_if=dot.adaptive_swarm_damage.stack=2&dot.adaptive_swarm_damage.remains>2
    if Press(S.AdaptiveSwarm, not Target:IsSpellInRange(S.AdaptiveSwarm)) then return "adaptive_swarm main"; end
  end
  -- run_action_list,name=owl,if=talent.balance_affinity.enabled
  if S.BalanceAffinity:IsAvailable() then
    local ShouldReturn = Owl(); if ShouldReturn then return ShouldReturn; end
  end
  -- sunfire,target_if=refreshable
  if S.Sunfire:IsReady() and (Target:DebuffRefreshable(S.SunfireDebuff)) then
    if Press(S.Sunfire, not Target:IsSpellInRange(S.Sunfire)) then return "sunfire main 24"; end
  end
  -- moonfire,target_if=refreshable
  if S.Moonfire:IsReady() and (Target:DebuffRefreshable(S.MoonfireDebuff)) then
    if Press(S.Moonfire, not Target:IsSpellInRange(S.Moonfire)) then return "moonfire main 26"; end
  end
  -- starsurge,if=!buff.cat_form.up
  if S.Starsurge:IsReady() and (Player:BuffDown(S.CatForm)) then
    if Press(S.Starsurge, not Target:IsSpellInRange(S.Starsurge)) then return "starsurge main 28"; end
  end
  -- starfire
  if S.Starfire:IsReady() and EnemiesCount8ySplash > 2 then
    if Press(S.Starfire, not Target:IsSpellInRange(S.Starfire), true) then return "starfire owl 16"; end
  end
  -- wrath
  if S.Wrath:IsReady() and (Player:BuffDown(S.CatForm) or not Target:IsInMeleeRange(8)) then
    if Press(S.Wrath, not Target:IsSpellInRange(S.Wrath), true) then return "wrath main 30"; end
  end
  -- moonfire
  if S.Moonfire:IsReady() and (Player:BuffDown(S.CatForm) or not Target:IsInMeleeRange(8)) then
    if Press(S.Moonfire, not Target:IsSpellInRange(S.Moonfire)) then return "moonfire main 32"; end
  end
  -- Manually added: Pool if nothing to do
  if (true) then
    if Press(S.Pool) then return "Wait/Pool Resources"; end
  end
end

local function Dispel()
  -- natures_cure
  if Focus and Everyone.DispellableFriendlyUnit() and S.NaturesCure:IsReady() then
    if Cast(M.NaturesCureFocus) then return "natures_cure dispel 2"; end
  end
end

local function Defensive()
  -- barkskin
  if Player:HealthPercentage() <= Settings.Restoration.Defensive.HP.Barkskin and S.Barkskin:IsReady() then
    if Press(S.Barkskin, nil, nil, true) then return "barkskin defensive 2"; end
  end
  -- healthstone
  if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
    if Press(M.Healthstone, nil, nil, true) then return "healthstone defensive 4"; end
  end
end

local function Ramp()
  if not Focus or not Focus:Exists() or Focus:IsDeadOrGhost() or not Focus:IsInRange(40) then return; end
  -- rejuvenation_swiftmend
  if S.Swiftmend:IsReady() and not EvaluateSwiftmend(Focus) and Player:BuffDown(S.SoulOfTheForestBuff) then
    if Press(M.RejuvenationFocus) then return "rejuvenation ramp"; end
  end
  -- swiftmend
  if S.Swiftmend:IsReady() and EvaluateSwiftmend(Focus) then
    if Press(M.SwiftmendFocus) then return "swiftmend ramp"; end
  end
  -- wildgrowth
  if Player:BuffUp(S.SoulOfTheForestBuff) and S.Wildgrowth:IsReady() then
    if Press(M.WildgrowthFocus, nil, true) then return "wildgrowth ramp"; end
  end
  -- innervate
  if S.Innervate:IsReady() and Player:BuffDown(S.Innervate) then
    if Press(M.InnervatePlayer, nil, nil, true) then return "innervate ramp"; end
  end
  -- rejuvenation_cycle
  if Player:BuffUp(S.Innervate) and PossibleRejuvenationCount() > 0 and Mouseover and Mouseover:Exists() and Mouseover:BuffRefreshable(S.Rejuvenation) then
    if Press(M.RejuvenationMouseover) then return "rejuvenation_cycle ramp"; end
  end
end

local function Healing()
  if not Focus or not Focus:Exists() or Focus:IsDeadOrGhost() or not Focus:IsInRange(40) then return; end
  -- trinkets
  if Settings.General.Enabled.Trinkets then
    local ShouldReturn = Trinkets(); if ShouldReturn then return ShouldReturn; end
  end
  -- natures_vigil
  if Settings.Restoration.Damage.Enabled.NaturesVigil and Player:AffectingCombat() and HotsCount() > 3 and S.NaturesVigil:IsReady() then
    if Press(S.NaturesVigil, nil, nil, true) then return "natures_vigil healing"; end
  end
  -- swiftmend
  if S.Swiftmend:IsReady() and Player:BuffDown(S.SoulOfTheForestBuff) and EvaluateSwiftmend(Focus) and Focus:HealthPercentage() <= Settings.Restoration.HealingTwo.HP.Swiftmend then
    if Press(M.SwiftmendFocus) then return "swiftmend healing"; end
  end
  -- wildgrowth_sotf
  if Player:BuffUp(S.SoulOfTheForestBuff) and S.Wildgrowth:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Restoration.HealingTwo, "WildgrowthSotF") then
    if Press(M.WildgrowthFocus, nil, true) then return "wildgrowth_sotf healing"; end
  end
  -- flourish,if=flourish.buff.down
  if Player:AffectingCombat() and S.Flourish:IsReady() and Player:BuffDown(S.Flourish) and HotsCount() > 4 and Everyone.AreUnitsBelowHealthPercentage(Settings.Restoration.HealingOne, "Flourish") then
    if Press(S.Flourish, nil, nil, true) then return "flourish healing"; end
  end
  -- tranquility
  if Player:AffectingCombat() and S.Tranquility:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Restoration.HealingTwo, "Tranquility") then
    if Press(S.Tranquility, nil, true) then return "tranquility healing"; end
  end
  -- tranquility_tree
  if Player:AffectingCombat() and S.Tranquility:IsReady() and Player:BuffUp(S.IncarnationBuff) and Everyone.AreUnitsBelowHealthPercentage(Settings.Restoration.HealingTwo, "TranquilityTree") then
    if Press(S.Tranquility, nil, true) then return "tranquility_tree healing"; end
  end
  -- convoke_the_spirits_hp
  if Player:AffectingCombat() and S.ConvokeTheSpirits:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Restoration.HealingOne, "ConvokeTheSpirits") then
    if Press(S.ConvokeTheSpirits) then return "convoke_the_spirits healing"; end
  end
  -- cenarion_ward
  if S.CenarionWard:IsReady() and Focus:HealthPercentage() <= Settings.Restoration.HealingOne.HP.CenarionWard then
    if Press(M.CenarionWardFocus) then return "cenarion_ward healing"; end
  end
  -- regrowth_swiftness
  if Player:BuffUp(S.NaturesSwiftness) and S.Regrowth:IsCastable() then
    if Press(M.RegrowthFocus) then return "regrowth_swiftness healing"; end
  end
  -- natures_swiftness
  if S.NaturesSwiftness:IsReady() and Focus:HealthPercentage() <= Settings.Restoration.HealingOne.HP.NaturesSwiftness then
    if Press(S.NaturesSwiftness) then return "natures_swiftness healing"; end
  end
  -- ironbark
  if S.IronBark:IsReady() and Focus:HealthPercentage() <= Settings.Restoration.HealingOne.HP.IronBark then
    if Press(M.IronBarkFocus) then return "iron_bark healing"; end
  end
  if S.AdaptiveSwarm:IsCastable() and Player:AffectingCombat() then
    -- adaptive_swarm
    if Press(M.AdaptiveSwarmFocus) then return "adaptive_swarm healing"; end
  end
  -- lifebloom
  if Player:AffectingCombat() and Everyone.UnitGroupRole(Focus) == "TANK" and Everyone.FriendlyUnitsWithBuffCount(S.Lifebloom, true) < 1 and (Focus:HealthPercentage() <= Settings.Restoration.HealingOne.HP.LifebloomTank - (num(Player:BuffUp(S.CatForm)) * 15)) and S.Lifebloom:IsCastable() and Focus:BuffRefreshable(S.Lifebloom) then
    if Press(M.LifebloomFocus) then return "lifebloom healing"; end
  end
  -- lifebloom,if=unit.hp&undergrowth.available|!tank.lifebloom.ticking
  if Player:AffectingCombat() and Everyone.UnitGroupRole(Focus) ~= "TANK" and Everyone.FriendlyUnitsWithBuffCount(S.Lifebloom, nil, true) < 1 and (S.Undergrowth:IsAvailable() or Everyone.IsSoloMode()) and (Focus:HealthPercentage() <= Settings.Restoration.HealingOne.HP.Lifebloom - (num(Player:BuffUp(S.CatForm)) * 15)) and S.Lifebloom:IsCastable() and Focus:BuffRefreshable(S.Lifebloom) then
    if Press(M.LifebloomFocus) then return "lifebloom healing"; end
  end
  -- efflorescence,if=unit.hp
  if Player:AffectingCombat() and Settings.Restoration.HealingOne.Enabled.Efflorescence and Focus:HealthPercentage() <= Settings.Restoration.HealingOne.HP.Efflorescence and S.Efflorescence:TimeSinceLastCast() > 30 and Focus:GUID() == Mouseover:GUID() then
    if Press(M.EfflorescenceCursor) then return "efflorescence healing"; end
  end
  -- wildgrowth
  if S.Wildgrowth:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Restoration.HealingTwo, "Wildgrowth") and (not S.Swiftmend:IsAvailable() or not S.Swiftmend:IsReady()) then
    if Press(M.WildgrowthFocus, nil, true) then return "wildgrowth healing"; end
  end
  -- regrowth_hp
  if S.Regrowth:IsCastable() and Focus:HealthPercentage() <= Settings.Restoration.HealingTwo.HP.Regrowth then
    if Press(M.RegrowthFocus, nil, true) then return "regrowth healing"; end
  end
  -- rejuvenation_cycle
  if Player:BuffUp(S.Innervate) and PossibleRejuvenationCount() > 0 and Mouseover and Mouseover:Exists() and Mouseover:BuffRefreshable(S.Rejuvenation) then
    if Press(M.RejuvenationMouseover) then return "rejuvenation_cycle healing"; end
  end
  -- rejuvenation
  if S.Rejuvenation:IsCastable() and Focus:BuffRefreshable(S.Rejuvenation) and Focus:HealthPercentage() <= Settings.Restoration.HealingTwo.HP.Rejuvenation then
    if Press(M.RejuvenationFocus) then return "rejuvenation healing"; end
  end
  -- regrowth
  if S.Regrowth:IsCastable() and Focus:BuffUp(S.Rejuvenation) and Focus:HealthPercentage() <= Settings.Restoration.HealingTwo.HP.RegrowthRefresh then
    if Press(M.RegrowthFocus, nil, true) then return "regrowth healing"; end
  end
end

local function Combat()
  -- dispel
  if Settings.General.Enabled.DispelBuffs or Settings.General.Enabled.DispelDebuffs then
    local ShouldReturn = Dispel(); if ShouldReturn then return ShouldReturn; end
  end
  -- defensive
  local ShouldReturn = Defensive(); if ShouldReturn then return ShouldReturn; end
  -- ramp
  if WR.Toggle(4) then
    ShouldReturn = Ramp(); if ShouldReturn then return ShouldReturn; end
  end
  -- healing
  ShouldReturn = Healing(); if ShouldReturn then return ShouldReturn; end
  -- damage
  if Everyone.TargetIsValid() then
    ShouldReturn = Damage(); if ShouldReturn then return ShouldReturn; end
  end
end

local function OutOfCombat()
  -- dispel
  if Settings.General.Enabled.DispelBuffs or Settings.General.Enabled.DispelDebuffs then
    local ShouldReturn = Dispel(); if ShouldReturn then return ShouldReturn; end
  end
  -- healing
  if Settings.Commons.Enabled.OutOfCombatHealing then
    local ShouldReturn = Healing(); if ShouldReturn then return ShouldReturn; end
  end
  -- mark_of_the_wild
  if Settings.Commons.Enabled.MarkOfTheWild and S.MarkOfTheWild:IsCastable() and (Player:BuffDown(S.MarkOfTheWild, true) or Everyone.GroupBuffMissing(S.MarkOfTheWild)) then
    if Press(M.MarkOfTheWildPlayer) then return "mark_of_the_wild"; end
  end
  if Everyone.TargetIsValid() and Target:AffectingCombat() then
    -- rake,if=buff.shadowmeld.up|buff.prowl.up
    if S.Rake:IsReady() and (Player:StealthUp(false, true)) then
      if Press(S.Rake, not Target:IsInMeleeRange(10)) then return "rake"; end
    end
  end
end

local function APL()
  -- FocusUnit
  if Player:AffectingCombat() or Settings.General.Enabled.DispelDebuffs then
    local includeDispellableUnits = Settings.General.Enabled.DispelDebuffs and S.NaturesCure:IsReady()
    local ShouldReturn = Everyone.FocusUnit(includeDispellableUnits, M); if ShouldReturn then return ShouldReturn; end
  end
  
  if Player:IsMounted() then return; end
  
  -- Enemies Update
  if AoEON() then
    Enemies8ySplash = Target:GetEnemiesInSplashRange(8)
    EnemiesCount8ySplash = #Enemies8ySplash
  else
    Enemies8ySplash = {}
    EnemiesCount8ySplash = 1
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies8ySplash, false)
    end
  end
  
  -- revive
  if Target and Target:Exists() and Target:IsAPlayer() and Target:IsDeadOrGhost() and not Player:CanAttack(Target) then
    local DeadFriendlyUnitsCount = Everyone.DeadFriendlyUnitsCount()
    if Player:AffectingCombat() then
      if S.Rebirth:IsReady() then
        if Press(S.Rebirth, nil, true) then return "rebirth"; end
      end
    else
      if DeadFriendlyUnitsCount > 1 then
        if Press(S.Revitalize, nil, true) then return "revitalize"; end
      else
        if Press(S.Revive, not Target:IsInRange(40), true) then return "revive"; end
      end
    end
  end
  
  if not Player:IsChanneling() then
    if Player:AffectingCombat() then
      -- Combat
      local ShouldReturn = Combat(); if ShouldReturn then return ShouldReturn; end
    else
      -- OutOfCombat
      local ShouldReturn = OutOfCombat(); if ShouldReturn then return ShouldReturn; end
    end
  end
end

local function AutoBind()
  -- Bind Spells
  Bind(S.AdaptiveSwarm)
  Bind(S.Barkskin)
  Bind(S.BearForm)
  Bind(S.CatForm)
  Bind(S.ConvokeTheSpirits)
  Bind(S.FerociousBite)
  Bind(S.Flourish)
  Bind(S.HeartOfTheWild)
  Bind(S.NaturesSwiftness)
  Bind(S.NaturesVigil)
  Bind(S.MassEntanglement)
  Bind(S.Moonfire)
  Bind(S.MoonkinForm)
  Bind(S.Prowl)
  Bind(S.Rake)
  Bind(S.Rip)
  Bind(S.Rebirth)
  Bind(S.Revive)
  Bind(S.Revitalize)
  Bind(S.Shred)
  Bind(S.SkullBash)
  Bind(S.StampedingRoar)
  Bind(S.Starfire)
  Bind(S.Starsurge)
  Bind(S.Sunfire)
  Bind(S.Swipe)
  Bind(S.Tranquility)
  Bind(S.Thrash)
  Bind(S.WildCharge)
  Bind(S.Wrath)
  
  -- Bind Macros
  Bind(M.AdaptiveSwarmFocus)
  Bind(M.CenarionWardFocus)
  Bind(M.EfflorescenceCursor)
  Bind(M.InnervatePlayer)
  Bind(M.IronBarkFocus)
  Bind(M.LifebloomFocus)
  Bind(M.MarkOfTheWildPlayer)
  Bind(M.MoonfireMouseover)
  Bind(M.NaturesCureFocus)
  Bind(M.NaturesCureMouseover)
  Bind(M.RebirthMouseover)
  Bind(M.RegrowthFocus)
  Bind(M.RejuvenationFocus)
  Bind(M.RejuvenationMouseover)
  Bind(M.SunfireMouseover)
  Bind(M.SwiftmendFocus)
  Bind(M.WildgrowthFocus)
  Bind(M.UrsolsVortexCursor)
  
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  
  -- Bind Focus Macros
  Bind(M.FocusTarget)
  Bind(M.FocusPlayer)
  for i = 1, 4 do
    local FocusUnitKey = stringformat("FocusParty%d", i)
    Bind(M[FocusUnitKey])
  end
  for i = 1, 40 do
    local FocusUnitKey = stringformat("FocusRaid%d", i)
    Bind(M[FocusUnitKey])
  end
end

local function OnInit()
  WR.Print("Restoration Druid Rotation by Worldy.")
  AutoBind()
  Everyone.DispellableDebuffs = Utils.MergeTable(Everyone.DispellableDebuffs, Everyone.DispellableMagicDebuffs)
  if S.ImprovedNaturesCure:IsAvailable() then
    Everyone.DispellableDebuffs = Utils.MergeTable(Everyone.DispellableDebuffs, Everyone.DispellableDiseaseDebuffs)
    Everyone.DispellableDebuffs = Utils.MergeTable(Everyone.DispellableDebuffs, Everyone.DispellableCurseDebuffs)
  end
  WR.ToggleFrame:AddButton("R", 4, "Ramp", "ramp")
end

WR.SetAPL(105, APL, OnInit)
