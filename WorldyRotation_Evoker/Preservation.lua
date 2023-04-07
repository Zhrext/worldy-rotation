--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local HL            = HeroLib
local Cache         = HeroCache
local Utils         = HL.Utils
local Unit          = HL.Unit
local Player        = Unit.Player
local Target        = Unit.Target
local Focus         = Unit.Focus
local Mouseover     = Unit.MouseOver
local Pet           = Unit.Pet
local Spell         = HL.Spell
local Item          = HL.Item
-- WorldyRotation
local WR            = WorldyRotation
local AoEON         = WR.AoEON
local Cast          = WR.Cast
local CastPooling   = WR.CastPooling
local CastAnnotated = WR.CastAnnotated
local CastSuggested = WR.CastSuggested
local CDsON         = WR.CDsON
local Press         = WR.Press
local Bind          = WR.Bind
local Macro         = WR.Macro
-- Num/Bool Helper Functions
local num           = WR.Commons.Everyone.num
local bool          = WR.Commons.Everyone.bool
-- lua
local stringformat = string.format
-- wow api
local GetUnitEmpowerStageDuration = GetUnitEmpowerStageDuration

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.Evoker.Preservation
local I = Item.Evoker.Preservation
local M = Macro.Evoker.Preservation

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
}

-- GUI Settings
local Everyone = WR.Commons.Everyone
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Evoker.Commons,
  Preservation = WR.GUISettings.APL.Evoker.Preservation
}

-- Trinket Item Objects
local equip = Player:GetEquipment()
local trinket1 = equip[13] and Item(equip[13]) or Item(0)
local trinket2 = equip[14] and Item(equip[14]) or Item(0)

-- Rotation Var
local Enemies25y
local Enemies8ySplash
local EnemiesCount8ySplash
local BossFightRemains = 11111
local FightRemains = 11111
local Immovable
local FBEmpower = 0
local DBEmpower = 0
local SBEmpower = 0
local LowUnitsCount = 0

-- Update Equipment
HL:RegisterForEvent(function()
  equip = Player:GetEquipment()
  trinket1 = equip[13] and Item(equip[13]) or Item(0)
  trinket2 = equip[14] and Item(equip[14]) or Item(0)
end, "PLAYER_EQUIPMENT_CHANGED")

-- Reset variables after fights
HL:RegisterForEvent(function()
  BossFightRemains = 11111
  FightRemains = 11111
end, "PLAYER_REGEN_ENABLED")

local function Precombat()
  -- flask
  -- augmentation
  -- food
  -- snapshot_stats
  -- living_flame
  if S.LivingFlame:IsCastable() then
    if Press(S.LivingFlame, not Target:IsInRange(25), Immovable) then return "living_flame precombat"; end
  end
  -- azure_strike
  if S.AzureStrike:IsCastable() then
    if Press(S.AzureStrike, not Target:IsSpellInRange(S.AzureStrike)) then return "azure_strike precombat"; end
  end
end

local function Defensive()
  -- obsidian_scales
  if S.ObsidianScales:IsCastable() and Player:BuffDown(S.ObsidianScales) and (Player:HealthPercentage() < Settings.Commons.HP.ObsidianScales) then
    if Press(S.ObsidianScales) then return "obsidian_scales defensives"; end
  end
  -- healthstone
  if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
    if Press(M.Healthstone, nil, nil, true) then return "healthstone"; end
  end
end

local function Dispel()
  if not Focus or not Focus:Exists() or not Focus:IsInRange(30) or not Everyone.DispellableFriendlyUnit() then return; end
  -- naturalize
  if S.Naturalize:IsReady() and (Everyone.UnitHasMagicDebuff(Focus) or Everyone.UnitHasDiseaseDebuff(Focus)) then
    if Press(M.NaturalizeFocus) then return "naturalize dispel"; end
  end
  -- cauterizing_flame
  if S.CauterizingFlame:IsReady() and (Everyone.UnitHasCurseDebuff(Focus) or Everyone.UnitHasDiseaseDebuff(Focus)) then
    if Press(M.CauterizingFlameFocus) then return "cauterizing_flame dispel"; end
  end
end

local function Interrupt()
  -- Manually added: Interrupts
  if not Player:IsCasting() and not Player:IsChanneling() then
    local ShouldReturn = Everyone.Interrupt(S.Quell, 10, true); if ShouldReturn then return ShouldReturn; end
    ShouldReturn = Everyone.InterruptWithStun(S.TailSwipe, 8); if ShouldReturn then return ShouldReturn; end
    ShouldReturn = Everyone.Interrupt(S.Quell, 10, true, Mouseover, M.QuellMouseover); if ShouldReturn then return ShouldReturn; end
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

local function Damage()
  -- living_flame,if=leaping_flames.up
  if S.LivingFlame:IsCastable() and Player:BuffUp(S.LeapingFlamesBuff) then
    if Press(S.LivingFlame, not Target:IsSpellInRange(S.LivingFlame), Immovable) then return "living_flame_leaping_flames damage"; end
  end
  -- fire_breath
  if S.FireBreath:IsReady() then
    if EnemiesCount8ySplash <= 2 then
      FBEmpower = 1
    elseif EnemiesCount8ySplash <= 4 then
      FBEmpower = 2
    elseif EnemiesCount8ySplash <= 6 then
      FBEmpower = 3
    else
      FBEmpower = 4
    end
    if Press(M.FireBreathMacro, not Target:IsInRange(30), true, nil, true) then return "fire_breath damage " .. FBEmpower; end
  end
  if S.Disintegrate:IsReady() and Player:BuffUp(S.EssenceBurstBuff) then
    if Press(S.Disintegrate, not Target:IsSpellInRange(S.Disintegrate), Immovable) then return "disintegrate damage"; end
  end
  -- deep_breath - manual usage
  -- living_flame
  if S.LivingFlame:IsCastable() then
    if Press(S.LivingFlame, not Target:IsSpellInRange(S.LivingFlame), Immovable) then return "living_flame damage"; end
  end
  -- azure_strike
  if S.AzureStrike:IsCastable() then
    if Press(S.AzureStrike, not Target:IsSpellInRange(S.AzureStrike)) then return "azure_strike damage"; end
  end
end

local function Cooldown()
  if not Focus or not Focus:Exists() or not Focus:IsInRange(30) then return; end
  -- trinket
  local ShouldReturn = Trinket(); if ShouldReturn then return ShouldReturn; end
  -- stasis
  if S.Stasis:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Preservation.Healing, "Stasis") then
    if Press(S.Stasis) then return "stasis cooldown"; end
  end
  -- stasis_reactivate
  if S.StasisReactivate:IsReady() and (Everyone.AreUnitsBelowHealthPercentage(Settings.Preservation.Healing, "Stasis") or (Player:BuffUp(S.StasisBuff) and Player:BuffRemains(S.StasisBuff) < 3)) then
    if Press(S.StasisReactivate) then return "stasis_reactivate cooldown"; end
  end
  -- tip_the_scales
  if S.TipTheScales:IsCastable() then
    -- dream_breath
    if S.DreamBreath:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Preservation.Healing, "DreamBreath") then
      if Press(M.TipTheScalesDreamBreath) then return "dream_breath cooldown"; end
    -- spirit_bloom
    elseif S.Spiritbloom:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Preservation.Healing, "Spiritbloom") then
      if Press(M.TipTheScalesSpiritbloom) then return "spirit_bloom cooldown"; end
    end
  end
  -- dream_flight - manual usage
  -- rewind
  if S.Rewind:IsCastable() and Everyone.AreUnitsBelowHealthPercentage(Settings.Preservation.Healing, "Rewind") then
    if Press(S.Rewind) then return "rewind cooldown"; end
  end
  -- time_dilation
  if S.TimeDilation:IsCastable() and Focus:HealthPercentage() <= Settings.Preservation.Healing.HP.TimeDilation then
    if Press(M.TimeDilationFocus) then return "time_dilation cooldown"; end
  end
  -- fire_breath
  if S.FireBreath:IsReady() then
    if EnemiesCount8ySplash <= 2 then
      FBEmpower = 1
    elseif EnemiesCount8ySplash <= 4 then
      FBEmpower = 2
    elseif EnemiesCount8ySplash <= 6 then
      FBEmpower = 3
    else
      FBEmpower = 4
    end
    if Press(M.FireBreathMacro, not Target:IsInRange(30), true, nil, true) then return "fire_breath cds " .. FBEmpower; end
  end
end

local function AoEHealing()
  -- emerald_blossom
  if S.EmeraldBlossom:IsCastable() and Everyone.AreUnitsBelowHealthPercentage(Settings.Preservation.Healing, "EmeraldBlossom") then
    if Press(M.EmeraldBlossomFocus) then return "emerald_blossom aoe_healing"; end
  end
  -- verdant_embrace
  if WR.Toggle(4) and S.VerdantEmbrace:IsReady() and Focus:HealthPercentage() <= Settings.Preservation.Healing.HP.VerdantEmbrace then
    if Press(M.VerdantEmbraceFocus) then return "verdant_embrace aoe_healing"; end
  end
  -- dream_breath
  if S.DreamBreath:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Preservation.Healing, "DreamBreath") then
    if LowUnitsCount <= 2 then
      DBEmpower = 1
    else
      DBEmpower = 2
    end
    if Press(M.DreamBreathMacro, nil, true) then return "dream_breath aoe_healing"; end
  end
  -- spirit_bloom
  if S.Spiritbloom:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Preservation.Healing, "Spiritbloom") then
    if LowUnitsCount > 2 then
      SBEmpower = 3
    else
      SBEmpower = 1
    end
    if Press(M.SpiritbloomFocus, nil, true) then return "spirit_bloom aoe_healing"; end
  end
  -- living_flame,if=leaping_flames.up
  if S.LivingFlame:IsCastable() and Player:BuffUp(S.LeapingFlamesBuff) and Focus:HealthPercentage() <= Settings.Preservation.Healing.HP.LivingFlame then
    if Press(M.LivingFlameFocus, not Focus:IsSpellInRange(S.LivingFlame), Immovable) then return "living_flame_leaping_flames aoe_healing"; end
  end
end

local function STHealing()
  -- reversion
  if S.Reversion:IsReady() and Everyone.UnitGroupRole(Focus) ~= "TANK" and Everyone.FriendlyUnitsWithBuffCount(S.Reversion) < 1 and Focus:HealthPercentage() <= Settings.Preservation.Healing.HP.Reversion then
    if Press(M.ReversionFocus) then return "reversion_tank st_healing"; end
  end
  -- reversion_tank
  if S.Reversion:IsReady() and Everyone.UnitGroupRole(Focus) == "TANK" and Everyone.FriendlyUnitsWithBuffCount(S.Reversion, true, false) < 1 and Focus:HealthPercentage() <= Settings.Preservation.Healing.HP.ReversionTank then
    if Press(M.ReversionFocus) then return "reversion_tank st_healing"; end
  end
  -- temporal_anomaly
  if S.TemporalAnomaly:IsReady() and Everyone.AreUnitsBelowHealthPercentage(Settings.Preservation.Healing, "TemporalAnomaly") then
    if Press(S.TemporalAnomaly, not Focus:IsInRange(30), Immovable) then return "temporal_anomaly st_healing"; end
  end
  -- echo
  if S.Echo:IsReady() and not Focus:BuffUp(S.Echo) and Focus:HealthPercentage() <= Settings.Preservation.Healing.HP.Echo then
    if Press(M.EchoFocus) then return "echo st_healing"; end
  end
  -- living_flame
  if S.LivingFlame:IsReady() and Focus:HealthPercentage() <= Settings.Preservation.Healing.HP.LivingFlame then
    if Press(M.LivingFlameFocus, not Focus:IsSpellInRange(S.LivingFlame), Immovable) then return "living_flame st_healing"; end
  end
end

local function Healing()
  if not Focus or not Focus:Exists() or not Focus:IsInRange(30) then return; end
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
  ShouldReturn = Cooldown(); if ShouldReturn then return ShouldReturn; end
  -- interrupt
  ShouldReturn = Interrupt(); if ShouldReturn then return ShouldReturn; end
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
  -- blessing_of_the_bronze
  if Settings.Commons.Enabled.BlessingoftheBronze and S.BlessingoftheBronze:IsCastable() and (Player:BuffDown(S.BlessingoftheBronzeBuff) or Everyone.GroupBuffMissing(S.BlessingoftheBronzeBuff)) then
    if Press(S.BlessingoftheBronze) then return "blessing_of_the_bronze precombat"; end
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
    local includeDispellableUnits = Settings.General.Enabled.DispelDebuffs and S.Naturalize:IsReady()
    local ShouldReturn = Everyone.FocusUnit(includeDispellableUnits, M, 30); if ShouldReturn then return ShouldReturn; end
  end
  
  Immovable = Player:BuffRemains(S.HoverBuff) < 2
  LowUnitsCount = Everyone.FriendlyUnitsBelowHealthPercentageCount(85)
  Enemies25y = Player:GetEnemiesInRange(25)
  Enemies8ySplash = Target:GetEnemiesInSplashRange(8)
  if (AoEON()) then
    EnemiesCount8ySplash = #Enemies8ySplash
  else
    EnemiesCount8ySplash = 1
  end

  if Everyone.TargetIsValid() or Player:AffectingCombat() then
    -- Calculate fight_remains
    BossFightRemains = HL.BossFightRemains(nil, true)
    FightRemains = BossFightRemains
    if FightRemains == 11111 then
      FightRemains = HL.FightRemains(Enemies25y, false)
    end
  end
  
  if Player:IsChanneling(S.FireBreath) then
    local FBCastTime = (FBEmpower > 0 and GetUnitEmpowerStageDuration("player", 0) or 0)
                        + (FBEmpower > 1 and GetUnitEmpowerStageDuration("player", 1) or 0)
                        + (FBEmpower > 2 and GetUnitEmpowerStageDuration("player", 2) or 0)
                        + (FBEmpower > 3 and GetUnitEmpowerStageDuration("player", 3) or 0)
    if (GetTime() - Player:ChannelStart()) * 1000 > FBCastTime or (LowUnitsCount > 1 and ((GetTime() - Player:ChannelStart()) * 1000 > GetUnitEmpowerStageDuration("player", 0))) then
      if Press(M.FireBreathMacro, nil, nil, true) then return "FB " .. FBCastTime; end
    end
    if CastAnnotated(S.Pool, false, "WAIT") then return "Pool for FB " .. FBCastTime; end
  end
  if Player:IsChanneling(S.DreamBreath) then
    local DBCastTime = (DBEmpower > 0 and GetUnitEmpowerStageDuration("player", 0) or 0)
                        + (DBEmpower > 1 and GetUnitEmpowerStageDuration("player", 1) or 0)
                        + (DBEmpower > 2 and GetUnitEmpowerStageDuration("player", 2) or 0)
                        + (DBEmpower > 3 and GetUnitEmpowerStageDuration("player", 3) or 0)
    if (GetTime() - Player:ChannelStart()) * 1000 > DBCastTime then
      if Press(M.DreamBreathMacro, nil, nil, true) then return "DB " .. DBCastTime; end
    end
    if CastAnnotated(S.Pool, false, "WAIT") then return "Pool for DB " .. DBCastTime; end
  end
  if Player:IsChanneling(S.Spiritbloom) then
    local SBCastTime = (SBEmpower > 0 and GetUnitEmpowerStageDuration("player", 0) or 0)
                        + (SBEmpower > 1 and GetUnitEmpowerStageDuration("player", 1) or 0)
                        + (SBEmpower > 2 and GetUnitEmpowerStageDuration("player", 2) or 0)
                        + (SBEmpower > 3 and GetUnitEmpowerStageDuration("player", 3) or 0)
    if (GetTime() - Player:ChannelStart()) * 1000 > SBCastTime then
      if Press(M.SpiritbloomFocus, nil, nil, true) then return "SB " .. SBCastTime; end
    end
    if CastAnnotated(S.Pool, false, "WAIT") then return "Pool for SB " .. SBCastTime; end
  end
  
  -- explosives
  if Settings.General.Enabled.HandleExplosives then
    local ShouldReturn = Everyone.HandleExplosive(S.AzureStrike, M.AzureStrikeMouseover); if ShouldReturn then return ShouldReturn; end
  end
  
  -- revive
  if Target and Target:Exists() and Target:IsAPlayer() and Target:IsDeadOrGhost() and not Player:CanAttack(Target) then
    local DeadFriendlyUnitsCount = Everyone.DeadFriendlyUnitsCount()
    if not Player:AffectingCombat() then
      if DeadFriendlyUnitsCount > 1 then
        if Press(S.MassReturn, nil, true) then return "mass_return"; end
      else
        if Press(S.Return, not Target:IsInRange(30), true) then return "return"; end
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
  Bind(S.AzureStrike)
  Bind(S.BlessingoftheBronze)
  Bind(S.DeepBreath)
  Bind(S.DreamBreath)
  Bind(S.DreamFlight)
  Bind(S.Disintegrate)
  Bind(S.FireBreath)
  Bind(S.LivingFlame)
  Bind(S.ObsidianScales)
  Bind(S.Stasis)
  Bind(S.StasisReactivate)
  Bind(S.TailSwipe)
  Bind(S.TemporalAnomaly)
  Bind(S.Rewind)
  Bind(S.Return)
  Bind(S.MassReturn)
  Bind(S.WingBuffet)
  Bind(S.Quell)
  
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  
  -- Macros
  Bind(M.AzureStrikeMouseover)
  Bind(M.CauterizingFlameFocus)
  Bind(M.DeepBreathCursor)
  Bind(M.DreamBreathMacro)
  Bind(M.DreamFlightCursor)
  Bind(M.EchoFocus)
  Bind(M.EmeraldBlossomFocus)
  Bind(M.FireBreathMacro)
  Bind(M.LivingFlameFocus)
  Bind(M.NaturalizeFocus)
  Bind(M.SpiritbloomFocus)
  Bind(M.ReversionFocus)
  Bind(M.QuellMouseover)
  Bind(M.TipTheScalesDreamBreath)
  Bind(M.TipTheScalesSpiritbloom)
  Bind(M.TimeDilationFocus)
  Bind(M.VerdantEmbraceFocus)
  
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
  WR.Print("Preservation Evoker by Worldy.")
  AutoBind()
  Everyone.DispellableDebuffs = Utils.MergeTable(Everyone.DispellableDebuffs, Everyone.DispellableMagicDebuffs)
  Everyone.DispellableDebuffs = Utils.MergeTable(Everyone.DispellableDebuffs, Everyone.DispellableDiseaseDebuffs)
  Everyone.DispellableDebuffs = Utils.MergeTable(Everyone.DispellableDebuffs, Everyone.DispellableCurseDebuffs)
  WR.ToggleFrame:AddButton("V", 4, "VerdantEmbrace", "ve")
end

WR.SetAPL(1468, APL, Init);
