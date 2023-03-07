--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC        = HeroDBC.DBC
-- HeroLib
local HL         = HeroLib
local Cache      = HeroCache
local Unit       = HL.Unit
local Player     = Unit.Player
local Target     = Unit.Target
local Pet        = Unit.Pet
local Spell      = HL.Spell
local MultiSpell = HL.MultiSpell
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
-- WoW API
local UnitHealthMax = UnitHealthMax


--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Spells
local S = Spell.Monk.Brewmaster
local I = Item.Monk.Brewmaster
local M = Macro.Monk.Brewmaster

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  I.AlgetharPuzzleBox:ID(),
}

-- Rotation Var
local Enemies5y
local Enemies8y
local EnemiesCount8
local IsTanking

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Monk = WR.Commons.Monk
local Settings = {
  General    = WR.GUISettings.General,
  Commons    = WR.GUISettings.APL.Monk.Commons,
  Brewmaster = WR.GUISettings.APL.Monk.Brewmaster
}

local function Trinkets()
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
  -- use_item,name=algethar_puzzle_box
  if I.AlgetharPuzzleBox:IsEquippedAndReady() then
    if Press(M.AlgetharPuzzleBox, nil, true) then return "algethar_puzzle_box trinkets"; end
  end
end

-- I am going keep this function in place in case it is needed in the future.
-- The code is sound for a smoothing of damage intake.
-- However this is not needed in the current APL.
-- Hijacked this function to easily handle the APL's multiple purify lines -- Cilraaz
local function ShouldPurify()
  -- Old return. Leaving this hear for now, in case we want to revert.
  --return S.PurifyingBrew:ChargesFractional() >= 1.8 and (Player:DebuffUp(S.HeavyStagger) or Player:DebuffUp(S.ModerateStagger) or Player:DebuffUp(S.LightStagger))
  local StaggerFull = Player:StaggerFull() or 0
  -- if there's no stagger, just exist so we don't have to calculate anything
  if StaggerFull == 0 then return false end
  local StaggerCurrent = 0
  local StaggerSpell = nil
  if Player:BuffUp(S.LightStagger) then
    StaggerSpell = S.LightStagger
  elseif Player:BuffUp(S.ModerateStagger) then
    StaggerSpell = S.ModerateStagger
  elseif Player:BuffUp(S.HeavyStagger) then
    StaggerSpell = S.HeavyStagger
  end
  if StaggerSpell then
    local spellTable = Player:DebuffInfo(StaggerSpell, false, true)
    StaggerCurrent = spellTable.points[2]
  end
  -- if=stagger.amounttototalpct>=0.7&(((target.cooldown.pause_action.remains>=20|time<=10|target.cooldown.pause_action.duration=0)&cooldown.invoke_niuzao_the_black_ox.remains<5)|buff.invoke_niuzao_the_black_ox.up)
  -- APL Note: Cast PB during the Niuzao window, but only if recently hit.
  if ((StaggerCurrent > 0 and StaggerCurrent >= StaggerFull * 0.7) and (S.InvokeNiuzaoTheBlackOx:CooldownRemains() < 5 or Player:BuffUp(S.InvokeNiuzaoTheBlackOx))) then
    return true
  end
  -- if=buff.invoke_niuzao_the_black_ox.up&buff.invoke_niuzao_the_black_ox.remains<8
  if (Player:BuffUp(S.InvokeNiuzaoTheBlackOx) and Player:BuffRemains(S.InvokeNiuzaoTheBlackOx) < 8) then
    return true
  end
  -- if=cooldown.purifying_brew.charges_fractional>=1.8&(cooldown.invoke_niuzao_the_black_ox.remains>10|buff.invoke_niuzao_the_black_ox.up)
  if (S.PurifyingBrew:ChargesFractional() >= 1.8 and (S.InvokeNiuzaoTheBlackOx:CooldownRemains() > 10 or Player:BuffUp(S.InvokeNiuzaoTheBlackOx))) then
    return true
  end
  return false
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  -- potion
  -- chi_burst,if=!covenant.night_fae
  if S.ChiBurst:IsCastable() and (CovenantID ~= 3) then
    if Press(S.ChiBurst, not Target:IsInMeleeRange(8), true) then return "chi_burst precombat 6"; end
  end
  -- chi_wave
  if S.ChiWave:IsCastable() then
    if Press(S.ChiWave, not Target:IsInMeleeRange(8), true) then return "chi_wave precombat 10"; end
  end
  -- Manually added openers
  if S.RushingJadeWind:IsCastable() then
    if Press(S.RushingJadeWind, not Target:IsInMeleeRange(8)) then return "rushing_jade_wind precombat 4"; end
  end
  if S.KegSmash:IsCastable() then 
    if Press(S.KegSmash, not Target:IsInRange(40)) then return "keg_smash precombat 8"; end
  end
end

local function Defensives()
  if S.CelestialBrew:IsCastable() and (Player:BuffDown(S.BlackoutComboBuff) and Player:IncomingDamageTaken(1999) > (UnitHealthMax("player") * 0.1 + Player:StaggerLastTickDamage(4)) and Player:BuffStack(S.ElusiveBrawlerBuff) < 2) then
    if Press(S.CelestialBrew) then return "Celestial Brew"; end
  end
  if S.PurifyingBrew:IsCastable() and ShouldPurify() then
    if Press(S.PurifyingBrew) then return "Purifying Brew"; end
  end
  if S.ExpelHarm:IsCastable() and Player:HealthPercentage() <= 80 then
    if Press(S.ExpelHarm) then return "Expel Harm"; end
  end
  if S.DampenHarm:IsCastable() and Player:BuffDown(S.FortifyingBrewBuff) and Player:HealthPercentage() <= 35 then
    if Press(S.DampenHarm) then return "Dampen Harm"; end
  end
  if S.FortifyingBrew:IsCastable() and Player:BuffDown(S.DampenHarmBuff) and Player:HealthPercentage() <= 25 then
    if Press(S.FortifyingBrew) then return "Fortifying Brew"; end
  end
end

--- ======= ACTION LISTS =======
local function APL()
  -- Unit Update
  Enemies5y = Player:GetEnemiesInMeleeRange(5) -- Multiple Abilities
  Enemies8y = Player:GetEnemiesInMeleeRange(8) -- Multiple Abilities
  EnemiesCount8 = #Enemies8y -- AOE Toogle

  -- Are we tanking?
  IsTanking = Player:IsTankingAoE(8) or Player:IsTanking(Target)

  --- In Combat
  if Everyone.TargetIsValid() then
    -- Precombat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- Interrupts
    if not Player:IsCasting() and not Player:IsChanneling() then
      local ShouldReturn = Everyone.Interrupt(S.SpearHandStrike, 8, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.LegSweep, 8); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.Interrupt(S.SpearHandStrike, 40, true, Mouseover, M.SpearHandStrikeMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- Explosives
    if Settings.General.Enabled.HandleExplosives then
      local ShouldReturn = Everyone.HandleExplosive(S.TigerPalm, M.TigerPalmMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- Defensives
    if IsTanking then
      local ShouldReturn = Defensives(); if ShouldReturn then return ShouldReturn; end
    end
    if CDsON() then
      if S.SummonWhiteTigerStatue:IsCastable() then
        if Press(M.SummonWhiteTigerStatuePlayer, not Target:IsInMeleeRange(5)) then return "summon_white_tiger_statue main 4"; end
      end
      -- use_items
      if Settings.General.Enabled.Trinkets and CDsON() then
        local ShouldReturn = Trinkets(); if ShouldReturn then return ShouldReturn; end
      end
      -- blood_fury
      if S.BloodFury:IsCastable() then
        if Press(S.BloodFury) then return "blood_fury main 6"; end
      end
      -- berserking
      if S.Berserking:IsCastable() then
        if Press(S.Berserking) then return "berserking main 8"; end
      end
      -- lights_judgment
      if S.LightsJudgment:IsCastable() then
        if Press(S.LightsJudgment, not Target:IsInRange(40)) then return "lights_judgment main 10"; end
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
        if Press(S.BagofTricks, not Target:IsInRange(40)) then return "bag_of_tricks main 16"; end
      end
      -- invoke_niuzao_the_black_ox,if=buff.recent_purifies.value>=health.max*0.05&(target.cooldown.pause_action.remains>=20|time<=10|target.cooldown.pause_action.duration=0)
      -- APL Note: Cast Niuzao when we'll get at least 20 seconds of uptime. This is specific to the default enemy APL and will need adjustments for other enemies.
      -- Note: Using BossFilteredFightRemains instead of the above calculation
      if S.InvokeNiuzaoTheBlackOx:IsCastable() and HL.BossFilteredFightRemains(">", 25) then
        if Press(S.InvokeNiuzaoTheBlackOx, not Target:IsInRange(40)) then return "invoke_niuzao_the_black_ox main 18"; end
      end
      -- touch_of_death,if=target.health.pct<=15
      if S.TouchofDeath:IsCastable() and (Target:HealthPercentage() <= 15) then
        if Press(S.TouchofDeath, not Target:IsInMeleeRange(5)) then return "touch_of_death main 20"; end
      end
      -- weapons_of_order
      if S.WeaponsOfOrder:IsCastable() then
        if Press(S.WeaponsOfOrder) then return "weapons_of_order main 22"; end
      end
      -- bonedust_brew,if=!debuff.bonedust_brew_debuff.up
      if S.BonedustBrew:IsCastable() and (Target:DebuffDown(S.BonedustBrew)) then
        if Press(M.BoneDustBrewPlayer, not Target:IsInMeleeRange(8)) then return "bonedust_brew main 26"; end
      end
    end
    -- purifying_brew,if=stagger.amounttototalpct>=0.7&(((target.cooldown.pause_action.remains>=20|time<=10|target.cooldown.pause_action.duration=0)&cooldown.invoke_niuzao_the_black_ox.remains<5)|buff.invoke_niuzao_the_black_ox.up)
    -- purifying_brew,if=buff.invoke_niuzao_the_black_ox.up&buff.invoke_niuzao_the_black_ox.remains<8
    -- purifying_brew,if=cooldown.purifying_brew.charges_fractional>=1.8&(cooldown.invoke_niuzao_the_black_ox.remains>10|buff.invoke_niuzao_the_black_ox.up)
    -- Handled via ShouldPurify()
    if CDsON() then
      -- black_ox_brew,if=cooldown.purifying_brew.charges_fractional<0.5
      if S.BlackOxBrew:IsCastable() and S.PurifyingBrew:ChargesFractional() < 0.5 then
        if Press(S.BlackOxBrew) then return "black_ox_brew main 28"; end
      end
      -- black_ox_brew,if=(energy+(energy.regen*cooldown.keg_smash.remains))<40&buff.blackout_combo.down&cooldown.keg_smash.up
      if S.BlackOxBrew:IsCastable() and (Player:Energy() + (Player:EnergyRegen() * S.KegSmash:CooldownRemains())) < 40 and Player:BuffDown(S.BlackoutComboBuff) and S.KegSmash:CooldownUp() then
        if Press(S.BlackOxBrew) then return "black_ox_brew main 30"; end
      end
    end
    -- keg_smash,if=spell_targets>=2
    if S.KegSmash:IsCastable() and (EnemiesCount8 >= 2) then
      if Press(S.KegSmash, not Target:IsSpellInRange(S.KegSmash)) then return "keg_smash main 34"; end
    end
    -- celestial_brew,if=buff.blackout_combo.down&incoming_damage_1999ms>(health.max*0.1+stagger.last_tick_damage_4)&buff.elusive_brawler.stack<2
    -- Handled via Defensives()
    -- exploding_keg
    if S.ExplodingKeg:IsCastable() then
      if Press(M.ExplodingKegPlayer, not Target:IsInMeleeRange(8)) then return "exploding_keg 39"; end
    end
    -- tiger_palm,if=talent.rushing_jade_wind.enabled&buff.blackout_combo.up&buff.rushing_jade_wind.up
    if S.TigerPalm:IsReady() and (S.RushingJadeWind:IsAvailable() and Player:BuffUp(S.BlackoutComboBuff) and Player:BuffUp(S.RushingJadeWind)) then
      if Press(S.TigerPalm, not Target:IsInMeleeRange(5)) then return "tiger_palm main 40"; end
    end
    -- breath_of_fire,if=buff.charred_passions.down&runeforge.charred_passions.equipped
    if S.BreathOfFire:IsCastable() and (CharredPassionsEquipped and Player:BuffDown(S.CharredPassions)) then
      if Press(S.BreathOfFire, not Target:IsInRange(12)) then return "breath_of_fire main 42"; end
    end
    -- blackout_kick
    if S.BlackoutKick:IsCastable() then
      if Press(S.BlackoutKick, not Target:IsInMeleeRange(5)) then return "blackout_kick main 44"; end
    end
    -- rising_sun_kick
    if S.RisingSunKick:IsCastable() then
      if Press(S.RisingSunKick, not Target:IsInMeleeRange(5)) then return "rising_sun_kick main 46"; end
    end
    --keg_smash
    if S.KegSmash:IsReady() then
      if Press(S.KegSmash, not Target:IsSpellInRange(S.KegSmash)) then return "keg_smash main 46"; end
    end
    -- chi_burst,if=cooldown.faeline_stomp.remains>2&spell_targets>=2
    if S.ChiBurst:IsCastable() and (S.FaelineStomp:CooldownRemains() > 2 and EnemiesCount8 >= 2) then
      if Press(S.ChiBurst, not Target:IsInMeleeRange(8)) then return "chi_burst main 48"; end
    end
    -- touch_of_death
    if S.TouchofDeath:IsCastable() and CDsON() then
      if Press(S.TouchofDeath, not Target:IsInMeleeRange(5)) then return "touch_of_death main 52"; end
    end
  -- rushing_jade_wind,if=buff.rushing_jade_wind.down
    if S.RushingJadeWind:IsCastable() and (Player:BuffDown(S.RushingJadeWind)) then
      if Press(S.RushingJadeWind, not Target:IsInMeleeRange(8)) then return "rushing_jade_wind main 54"; end
    end
    -- spinning_crane_kick,if=buff.charred_passions.up
    if S.SpinningCraneKick:IsReady() and (Player:BuffUp(S.CharredPassions)) then
      if Press(S.SpinningCraneKick, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick main 56"; end
    end
    -- breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&dot.breath_of_fire_dot.refreshable))
    if S.BreathOfFire:IsCastable() and (Player:BuffDown(S.BlackoutComboBuff) and (Player:BloodlustDown() or (Player:BloodlustUp() and Target:BuffRefreshable(S.BreathOfFireDotDebuff)))) then
      if Press(S.BreathOfFire, not Target:IsInMeleeRange(8)) then return "breath_of_fire main 58"; end
    end
    -- chi_burst
    if S.ChiBurst:IsCastable() then
      if Press(S.ChiBurst, not Target:IsInMeleeRange(8)) then return "chi_burst main 60"; end
    end
    -- chi_wave
    if S.ChiWave:IsCastable() then
      if Press(S.ChiWave, not Target:IsInMeleeRange(8)) then return "chi_wave main 62"; end
    end
    -- spinning_crane_kick,if=!runeforge.shaohaos_might.equipped&active_enemies>=3&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+execute_time)))>=65&(!talent.spitfire.enabled|!runeforge.charred_passions.equipped)
    if S.SpinningCraneKick:IsCastable() and (not ShaohaosMightEquipped and EnemiesCount8 >= 3 and S.KegSmash:CooldownRemains() > Player:GCD() and (Player:Energy() + (Player:EnergyRegen() * (S.KegSmash:CooldownRemains() + S.SpinningCraneKick:ExecuteTime()))) >= 65 and ((not S.Spitfire:IsAvailable()) or not CharredPassionsEquipped)) then
      if Press(S.SpinningCraneKick, not Target:IsInMeleeRange(8)) then return "spinning_crane_kick main 64"; end
    end
    -- tiger_palm,if=!talent.blackout_combo&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+gcd)))>=65
    if S.TigerPalm:IsCastable() and (not S.BlackoutCombo:IsAvailable() and S.KegSmash:CooldownRemains() > Player:GCD() and (Player:Energy() + (Player:EnergyRegen() * (S.KegSmash:CooldownRemains() + Player:GCD()))) >= 65) then
      if Press(S.TigerPalm, not Target:IsSpellInRange(S.TigerPalm)) then return "tiger_palm main 66"; end
    end
    -- arcane_torrent,if=energy<31
    if S.ArcaneTorrent:IsCastable() and CDsON() and (Player:Energy() < 31) then
      if Press(S.ArcaneTorrent, not Target:IsInMeleeRange(8)) then return "arcane_torrent main 68"; end
    end
    -- rushing_jade_wind
    if S.RushingJadeWind:IsCastable() then
      if Press(S.RushingJadeWind, not Target:IsInMeleeRange(8)) then return "rushing_jade_wind main 72"; end
    end
    -- Manually added Pool filler
    if Press(S.PoolEnergy) then return "Pool Energy"; end
  end
end

local function AutoBind()
  -- Spell Binds
  Bind(S.ArcaneTorrent)
  Bind(S.BagofTricks)
  Bind(S.BreathOfFire)
  Bind(S.BlackOxBrew)
  Bind(S.BloodFury)
  Bind(S.BlackoutKick)
  Bind(S.CelestialBrew)
  Bind(S.ChiBurst)
  Bind(S.ChiWave)
  Bind(S.DampenHarm)
  Bind(S.ExpelHarm)
  Bind(S.FortifyingBrew)
  Bind(S.InvokeNiuzaoTheBlackOx)
  Bind(S.LegSweep)
  Bind(S.KegSmash)
  Bind(S.RisingSunKick)
  Bind(S.RushingJadeWind)
  Bind(S.PurifyingBrew)
  Bind(S.TigerPalm)
  Bind(S.SpearHandStrike)
  Bind(S.SpinningCraneKick)
  Bind(S.TouchofDeath)
  Bind(S.WeaponsOfOrder)
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  Bind(M.AlgetharPuzzleBox)
  -- Macros
  Bind(M.BoneDustBrewPlayer)
  Bind(M.DetoxMouseover)
  Bind(M.ExplodingKegPlayer)
  Bind(M.RingOfPeaceCursor)
  Bind(M.SpearHandStrikeMouseover)
  Bind(M.SummonWhiteTigerStatuePlayer)
  Bind(M.TigerPalmMouseover)
end

local function Init()
  WR.Print("Brewmaster Monk rotation by Worldy.")
  AutoBind()
end

WR.SetAPL(268, APL, Init)
