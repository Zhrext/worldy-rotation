--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local HL         = HeroLib
local Cache      = HeroCache
local Utils      = HL.Utils
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
-- lua
local mathfloor  = math.floor
local stringformat = string.format
-- WoW API
local GetTotemInfo = GetTotemInfo
local GetTime      = GetTime


-- Define S/I for spell and item arrays
local S = Spell.Paladin.Holy
local I = Item.Paladin.Holy
local M = Macro.Paladin.Holy

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
}

-- Rotation Var
local Enemies8y, Enemies30y
local EnemiesCount8y, EnemiesCount30y

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Paladin.Commons,
  Holy = WR.GUISettings.APL.Paladin.Holy
}

local function EvaluateCycleJudgment201(TargetUnit)
  return TargetUnit:DebuffRefreshable(S.JudgmentDebuff)
end

local function ConsecrationTimeRemaining()
  for index=1,4 do
    local _, totemName, startTime, duration = GetTotemInfo(index)
    if totemName == S.Consecration:Name() then
      return (mathfloor(startTime + duration - GetTime() + 0.5)) or 0
    end
  end
  return 0
end

local function EvaluateCycleGlimmer(TargetUnit)
  return TargetUnit:DebuffRefreshable(S.GlimmerofLightDebuff)
end

local function HandleNightFaeBlessings()
  local Seasons = {S.BlessingofSpring, S.BlessingofSummer, S.BlessingofAutumn, S.BlessingofWinter}
  for _, i in pairs(Seasons) do
    if i:IsCastable() then
      if Press(M.BlessingofSummerPlayer) then return "blessing_of_the_seasons"; end
    end
  end
end

local function Trinket()
  local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
  if Trinket1ToUse then
    if Press(M.Trinket1, nil, nil, true) then return "trinket1"; end
  end
  local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
  if Trinket2ToUse then
    if Press(M.Trinket2, nil, nil, true) then return "trinket2"; end
  end
end

local function Interrupt()
  -- Manually added: Interrupts
  if not Player:IsCasting() and not Player:IsChanneling() then
    local ShouldReturn = Everyone.Interrupt(S.Rebuke, 5, true); if ShouldReturn then return ShouldReturn; end
    ShouldReturn = Everyone.InterruptWithStun(S.HammerofJustice, 8); if ShouldReturn then return ShouldReturn; end
  end
end

local function Dispel()
  if not Focus or not Focus:Exists() or not Focus:IsInRange(40) or not Everyone.DispellableFriendlyUnit() then return; end
  -- cleanse
  if S.Cleanse:IsReady() then
    if Press(M.CleanseFocus) then return "cleanse dispel"; end
  end
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  -- potion
  -- Manually removed, as potion is not needed in precombat any longer
  -- Manually added: consecration if in melee
  if S.Consecration:IsCastable() and Target:IsInMeleeRange(9) then
    if Press(S.Consecration) then return "consecrate precombat 4"; end
  end
  -- Manually added: judgment if at range
  if S.Judgment:IsReady() then
    if Press(S.Judgment, not Target:IsSpellInRange(S.Judgment)) then return "judgment precombat 6"; end
  end
end

local function Defensive()
  if Player:HealthPercentage() <= Settings.Holy.HP.LoH and S.LayonHands:IsCastable() then
    if Press(M.LayonHandsPlayer) then return "lay_on_hands defensive"; end
  end
  if S.DivineProtection:IsCastable() and Player:HealthPercentage() <= Settings.Holy.HP.DP then
    if Press(S.DivineProtection) then return "divine protection"; end
  end
  if S.WordofGlory:IsReady() and Player:HealthPercentage() <= Settings.Holy.HP.WoG and not Player:HealingAbsorbed() then
    if Press(M.WordofGloryPlayer) then return "WOG self"; end
  end
  -- healthstone
  if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
    if Press(M.Healthstone, nil, nil, true) then return "healthstone"; end
  end
end

local function CooldownDamage()
  -- avenging_wrath
  if Settings.Holy.Enabled.AvengingWrathOffensively and S.AvengingWrath:IsCastable() then
    if Press(S.AvengingWrath) then return "avenging_wrath cooldowns 4"; end
  end
  -- blessing_of_the_seasons
  local ShouldReturn = HandleNightFaeBlessings(); if ShouldReturn then return ShouldReturn; end
  -- divine_toll
  if Settings.Holy.Enabled.DivineTollOffensively and S.DivineToll:IsCastable() then
    if Press(S.DivineToll) then return "divine_toll cooldowns 8"; end
  end
  -- potion,if=buff.avenging_wrath.up
  -- blood_fury,if=buff.avenging_wrath.up
  if S.BloodFury:IsCastable() then
    if Press(S.BloodFury) then return "blood_fury cooldowns 12"; end
  end
  -- berserking,if=buff.avenging_wrath.up
  if S.Berserking:IsCastable() then
    if Press(S.Berserking) then return "berserking cooldowns 14"; end
  end
  -- holy_avenger,if=buff.avenging_wrath.up
  if S.HolyAvenger:IsCastable() then
    if Press(S.HolyAvenger) then return "holy_avenger cooldowns 16"; end
  end
  -- use_items,if=buff.avenging_wrath.up
  if Settings.General.Enabled.Trinkets then
    local ShouldReturn = Trinket(); if ShouldReturn then return ShouldReturn; end
  end
  -- seraphim
  if S.Seraphim:IsReady() then
    if Press(S.Seraphim) then return "seraphim cooldowns 18"; end
  end
end

local function Damage()
  if CDsON() then
    -- cooldown_damage
    local ShouldReturn = CooldownDamage(); if ShouldReturn then return ShouldReturn; end
  end
  -- shield_of_the_righteous,if=buff.avenging_wrath.up|buff.holy_avenger.up|!talent.awakening.enabled
  if S.ShieldoftheRighteous:IsReady() and (Player:BuffUp(S.AvengingWrathBuff) or Player:BuffUp(S.HolyAvenger) or not S.Awakening:IsAvailable()) then
    if Press(S.ShieldoftheRighteous, not Target:IsInMeleeRange(5)) then return "shield_of_the_righteous priority 2"; end
  end
  -- hammer_of_wrath,if=holy_power<5&spell_targets.consecration=2
  if S.HammerofWrath:IsReady() and (Player:HolyPower() < 5 and EnemiesCount8y == 2) then
    if Press(S.HammerofWrath, not Target:IsSpellInRange(S.HammerofWrath)) then return "hammer_of_wrath priority 4"; end
  end
  -- lights_hammer,if=spell_targets.lights_hammer>=2
  if S.LightsHammer:IsCastable() and (EnemiesCount8y >= 2) then
    if Press(M.LightsHammerPlayer, not Target:IsInMeleeRange(8)) then return "lights_hammer priority 6"; end
  end
  -- consecration,if=spell_targets.consecration>=2&!consecration.up
  if S.Consecration:IsCastable() and (EnemiesCount8y >= 2 and ConsecrationTimeRemaining() <= 0) then
    if Press(S.Consecration, not Target:IsInMeleeRange(8)) then return "consecration priority 8"; end
  end
  -- light_of_dawn,if=talent.awakening.enabled&spell_targets.consecration<=5&(holy_power>=5|(buff.holy_avenger.up&holy_power>=3))
  if S.LightofDawn:IsReady() and (S.Awakening:IsAvailable() and EnemiesCount8y <= 5 and (Player:HolyPower() >= 5 or (Player:BuffUp(S.HolyAvenger) and Player:HolyPower() >= 3))) then
    if Press(S.LightofDawn, not Target:IsSpellInRange(S.LightofDawn)) then return "light_of_dawn priority 10"; end
  end
  -- shield_of_the_righteous,if=spell_targets.consecration>5
  if S.ShieldoftheRighteous:IsReady() and (EnemiesCount8y > 5) then
    if Press(S.ShieldoftheRighteous, not Target:IsInMeleeRange(5)) then return "shield_of_the_righteous priority 12"; end
  end
  -- hammer_of_wrath
  if S.HammerofWrath:IsReady() then
    if Press(S.HammerofWrath, not Target:IsSpellInRange(S.HammerofWrath)) then return "hammer_of_wrath priority 14"; end
  end
  -- judgment
  if S.Judgment:IsReady() then
    if Press(S.Judgment, not Target:IsSpellInRange(S.Judgment)) then return "judgment priority 16"; end
  end
  -- lights_hammer
  if S.LightsHammer:IsCastable() then
    if Press(M.LightsHammerPlayer, not Target:IsInMeleeRange(8)) then return "lights_hammer priority 18"; end
  end
  -- consecration,if=!consecration.up
  if S.Consecration:IsCastable() and (ConsecrationTimeRemaining() <= 0) then
    if Press(S.Consecration, not Target:IsInMeleeRange(8)) then return "consecration priority 20"; end
  end
  -- holy_shock,damage=1
  if Settings.Holy.Enabled.HolyShockOffensively and S.HolyShock:IsReady() then
    if Press(S.HolyShock, not Target:IsSpellInRange(S.HolyShock)) then return "holy_shock priority 22"; end
  end
  -- crusader_strike,if=cooldown.crusader_strike.charges=2
  if S.CrusaderStrike:IsReady() and (S.CrusaderStrike:Charges() == 2) then
    if Press(S.CrusaderStrike, not Target:IsInMeleeRange(5)) then return "crusader_strike priority 24"; end
  end
  -- holy_prism,target=self,if=active_enemies>=2
  if S.HolyPrism:IsReady() and (EnemiesCount8y >= 2) then
    if Press(M.HolyPrismPlayer) then return "holy_prism on self priority 26"; end
  end
  -- holy_prism
  if S.HolyPrism:IsReady() then
    if Press(S.HolyPrism, not Target:IsSpellInRange(S.HolyPrism)) then return "holy_prism priority 28"; end
  end
  -- arcane_torrent
  if S.ArcaneTorrent:IsCastable() then
    if Press(S.ArcaneTorrent) then return "arcane_torrent priority 30"; end
  end
  -- light_of_dawn,if=talent.awakening.enabled&spell_targets.consecration<=5
  if S.LightofDawn:IsReady() and (S.Awakening:IsAvailable() and EnemiesCount8y <= 5) then
    if Press(S.LightofDawn, not Target:IsSpellInRange(S.LightofDawn)) then return "light_of_dawn priority 32"; end
  end
  -- crusader_strike
  if S.CrusaderStrike:IsReady() then
    if Press(S.CrusaderStrike, not Target:IsInMeleeRange(5)) then return "crusader_strike priority 34"; end
  end
  -- consecration
  if S.Consecration:IsReady() then
    if Press(S.Consecration, not Target:IsInMeleeRange(8)) then return "consecration priority 36"; end
  end
end

local function CooldownHealing()
  if not Focus or not Focus:Exists() or not Focus:IsInRange(40) then return; end
  -- avenging_wrath
  if S.AvengingWrath:IsCastable() then
    if Press(S.AvengingWrath) then return "avenging_wrath cooldown_healing"; end
  end
  -- beacon_of_virtue
  if S.BeaconofVirtue:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "BeaconofVirtue") then
    if Press(M.BeaconofVirtueFocus) then return "beacon_of_virtue cooldown_healing"; end
  end
  -- divine_toll
  if S.DivineToll:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "DivineToll") then
    if Press(M.DivineTollFocus) then return "divine_toll cooldown_healing"; end
  end
  -- holy_shock
  if S.HolyShock:IsReady() and Focus:HealthPercentage() <= Settings.Holy.Healing.HP.HolyShock then
    if Press(M.HolyShockFocus) then return "holy_shock cooldown_healing"; end
  end
end

local function AoEHealing()
  -- beacon_of_virtue
  if S.BeaconofVirtue:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "BeaconofVirtue") then
    if Press(M.BeaconofVirtueFocus) then return "beacon_of_virtue aoe_healing"; end
  end
  -- word_of_glory
  if S.WordofGlory:IsReady() and Player:BuffUp(S.EmpyreanLegacyBuff) and (Focus:HealthPercentage() <= Settings.Holy.Healing.HP.WordofGlory or Everyone.AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "LightofDawn")) then
    if Press(M.WordofGloryFocus) then return "word_of_glory aoe_healing"; end
  end
  -- word_of_glory
  if S.WordofGlory:IsReady() and Player:BuffUp(S.UnendingLightBuff) and Focus:HealthPercentage() <= Settings.Holy.Healing.HP.WordofGlory then
    if Press(M.WordofGloryFocus) then return "word_of_glory aoe_healing"; end
  end
  -- light_of_dawn
  if S.LightofDawn:IsReady() and (Everyone.AreUnitsBelowHealthPercentage(Settings.Holy.Healing, "LightofDawn") or Everyone.FriendlyUnitsBelowHealthPercentageCount(Settings.Holy.Healing.HP.WordofGlory) > 2) then
    if Press(S.LightofDawn) then return "light_of_dawn aoe_healing"; end
  end
  -- word_of_glory
  if S.WordofGlory:IsReady() and Focus:HealthPercentage() <= Settings.Holy.Healing.HP.WordofGlory and Everyone.FriendlyUnitsBelowHealthPercentageCount(Settings.Holy.Healing.HP.WordofGlory) < 3 then
    if Press(M.WordofGloryFocus) then return "word_of_glory aoe_healing"; end
  end
  if Everyone.TargetIsValid() then
    -- consecration
    if S.Consecration:IsCastable() and S.GoldenPath:IsAvailable() and ConsecrationTimeRemaining() <= 0 then
      if Press(S.Consecration, not Target:IsInMeleeRange(8)) then return "consecration aoe_healing"; end
    end
    -- judgment
    if S.Judgment:IsReady() and S.JudgmentofLight:IsAvailable() and Target:DebuffDown(S.JudgmentofLightDebuff) then
      if Press(S.Judgment, not Target:IsSpellInRange(S.Judgment)) then return "judgment aoe_healing"; end
    end
 end
end

local function STHealing()
  -- word_of_glory
  if S.WordofGlory:IsReady() and Focus:HealthPercentage() <= Settings.Holy.Healing.HP.WordofGlory then
    if Press(M.WordofGloryFocus) then return "word_of_glory aoe_healing"; end
  end
  -- divine_favor
  if S.DivineFavor:IsReady() and Focus:HealthPercentage() <= Settings.Holy.Healing.HP.HolyLight then
    if Press(S.DivineFavor) then return "divine_favor cooldown_healing"; end
  end
  -- flash_of_light
  if S.FlashofLight:IsCastable() and Focus:HealthPercentage() <= Settings.Holy.Healing.HP.FlashofLight then
    if Press(M.FlashofLightFocus) then return "flash_of_light st_healing"; end
  end
  -- holy_light
  if S.HolyLight:IsCastable() and Focus:HealthPercentage() <= Settings.Holy.Healing.HP.HolyLight then
    if Press(M.HolyLightFocus) then return "holy_light st_healing"; end
  end
end

local function Healing()
  if not Focus or not Focus:Exists() or not Focus:IsInRange(40) then return; end
  -- aoe_healing
  local ShouldReturn = AoEHealing(); if ShouldReturn then return ShouldReturn; end
  -- st_healing
  ShouldReturn = STHealing(); if ShouldReturn then return ShouldReturn; end
end

local function Combat()
  -- dispel
  if Settings.General.Enabled.DispelBuffs or Settings.General.Enabled.DispelDebuffs then
    local ShouldReturn = Dispel(); if ShouldReturn then return ShouldReturn; end
  end
  -- defensive
  local ShouldReturn = Defensive(); if ShouldReturn then return ShouldReturn; end
  -- cooldown
  ShouldReturn = CooldownHealing(); if ShouldReturn then return ShouldReturn; end
  -- interrupt
  ShouldReturn = Interrupt(); if ShouldReturn then return ShouldReturn; end
  -- healing
  ShouldReturn = Healing(); if ShouldReturn then return ShouldReturn; end
  -- damage
  if Everyone.TargetIsValid() then
    -- cooldown_damage
    ShouldReturn = CooldownDamage(); if ShouldReturn then return ShouldReturn; end
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
  -- devotion_aura
  if S.DevotionAura:IsCastable() and Player:BuffDown(S.DevotionAura) then
    if Press(S.DevotionAura) then return "devotion_aura"; end
  end
  -- precombat
  if Everyone.TargetIsValid() then
    local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
  end
end

-- APL Main
local function APL()
  if Player:IsMounted() then return; end
  
  -- FocusUnit
  if Player:AffectingCombat() or Settings.General.Enabled.DispelDebuffs then
    local includeDispellableUnits = Settings.General.Enabled.DispelDebuffs and S.Cleanse:IsReady()
    local ShouldReturn = Everyone.FocusUnit(includeDispellableUnits, M); if ShouldReturn then return ShouldReturn; end
  end
  
  Enemies8y = Player:GetEnemiesInMeleeRange(8)
  Enemies30y = Player:GetEnemiesInRange(30)
  if AoEON() then
    EnemiesCount8y = #Enemies8y
    EnemiesCount30y = #Enemies30y
  else
    EnemiesCount8y = 1
    EnemiesCount30y = 1
  end
  
  -- explosives
  if Settings.General.Enabled.HandleExplosives then
    local ShouldReturn = Everyone.HandleExplosive(S.CrusaderStrike, M.CrusaderStrikeMouseover, 8); if ShouldReturn then return ShouldReturn; end
    ShouldReturn = Everyone.HandleExplosive(S.Judgment, M.JudgmentMouseover, 30); if ShouldReturn then return ShouldReturn; end
  end
    
  -- revive
  if Target and Target:Exists() and Target:IsAPlayer() and Target:IsDeadOrGhost() and not Player:CanAttack(Target) then
    local DeadFriendlyUnitsCount = Everyone.DeadFriendlyUnitsCount()
    if Player:AffectingCombat() then
      if S.Intercession:IsReady() then
        if Press(S.Intercession, nil, true) then return "intercession"; end
      end
    else
      if DeadFriendlyUnitsCount > 1 then
        if Press(S.Absolution, nil, true) then return "absolution"; end
      else
        if Press(S.Redemption, not Target:IsInRange(40), true) then return "redemption"; end
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
  -- Spell Binds
  Bind(S.Absolution)
  Bind(S.ArcaneTorrent)
  Bind(S.AvengingWrath)
  Bind(S.Berserking)
  Bind(S.BloodFury)
  Bind(S.BlessingofFreedom)
  Bind(S.BlessingofProtection)
  Bind(S.BlindingLight)
  Bind(S.CrusaderStrike)
  Bind(S.Consecration)
  Bind(S.DevotionAura)
  Bind(S.DivineFavor)
  Bind(S.DivineToll)
  Bind(S.DivineShield)
  Bind(S.HammerofJustice)
  Bind(S.HammerofWrath)
  Bind(S.HolyAvenger)
  Bind(S.HolyPrism)
  Bind(S.HolyShock)
  Bind(S.LightofDawn)
  Bind(S.Intercession)
  Bind(S.Redemption)
  Bind(S.Rebuke)
  Bind(S.Seraphim)
  Bind(S.ShieldoftheRighteous)
  Bind(S.Judgment)
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  -- Macros
  Bind(M.BeaconofVirtueFocus)
  Bind(M.BlessingofFreedomMouseover)
  Bind(M.BlessingofProtectionMouseover)
  Bind(M.BlessingofSummerPlayer)
  Bind(M.BlessingofSacrificeFocus)
  Bind(M.FlashofLightFocus)
  Bind(M.CleanseMouseover)
  Bind(M.CleanseFocus)
  Bind(M.CrusaderStrikeMouseover)
  Bind(M.DivineTollFocus)
  Bind(M.HolyLightFocus)
  Bind(M.HolyShockFocus)
  Bind(M.HolyPrismPlayer)
  Bind(M.LayonHandsFocus)
  Bind(M.LightsHammerPlayer)
  Bind(M.JudgmentMouseover)
  Bind(M.WordofGloryFocus)
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

local function Init()
  WR.Print("Holy Paladin by Worldy.")
  AutoBind()
  Everyone.DispellableDebuffs = Utils.MergeTable(Everyone.DispellableDebuffs, Everyone.DispellableMagicDebuffs)
  Everyone.DispellableDebuffs = Utils.MergeTable(Everyone.DispellableDebuffs, Everyone.DispellableDiseaseDebuffs)
end

WR.SetAPL(65, APL, Init)
