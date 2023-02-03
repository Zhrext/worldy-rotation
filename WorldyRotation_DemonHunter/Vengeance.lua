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
local Target        = Unit.Target
local Mouseover     = Unit.MouseOver
local Pet           = Unit.Pet
local Spell         = HL.Spell
local Item          = HL.Item
-- WorldyRotation
local WR            = WorldyRotation
local AoEON         = WR.AoEON
local Bind          = WR.Bind
local CDsON         = WR.CDsON
local Cast          = WR.Cast
local CastSuggested = WR.CastSuggested
local CastAnnotated = WR.CastAnnotated
local Press         = WR.Press
local Macro         = WR.Macro
-- Commons
local Everyone      = WR.Commons.Everyone
-- Num/Bool Helper Functions
local num           = Everyone.num
local bool          = Everyone.bool
-- File locals
local DemonHunter   = WR.Commons.DemonHunter
DemonHunter.DGBCDR  = 0
DemonHunter.DGBCDRLastUpdate = 0
-- lua
local GetTime       = GetTime

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Define S/I for spell and item arrays
local S = Spell.DemonHunter.Vengeance
local I = Item.DemonHunter.Vengeance
local M = Macro.DemonHunter.Vengeance

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
}

-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.DemonHunter.Commons,
  Vengeance = WR.GUISettings.APL.DemonHunter.Vengeance
}

-- Rotation Var
local SoulFragments, LastSoulFragmentAdjustment
local SoulFragmentsAdjusted = 0
local IsInMeleeRange, IsInAoERange
local ActiveMitigationNeeded
local IsTanking
local Enemies8yMelee
local EnemiesCount8yMelee
-- DBG High Roll check
local VarDGBHighRoll = false
-- Vars for ramp functions
local VarSubAPL = false
local VarHuntRamp = false
local VarEDRamp = false
local VarSCRamp = false
local VarFD = false
-- Vars to calculate SpB Fragments generated
local VarSpiritBombFragmentsInMeta = (S.Fracture:IsAvailable()) and 3 or 4
local VarSpiritBombFragmentsNotInMeta = (S.Fracture:IsAvailable()) and 4 or 5
local VarSpiritBombFragments = 0
-- Vars for Frailty checks
local VarFrailtyDumpFuryRequirement = 0
local VarFrailtyTargetRequirement = 0
-- Vars for Pooling checks
local VarPoolingForED = false
local VarPoolingForFDFelDev = false
local VarPoolingForSC = false
local VarPoolingForTheHunt = false
local VarPoolingFury = false
-- GCDMax for... gcd.max
local GCDMax = 0
-- Fodder
local FodderToTheFlamesDeamonIds = {
  169421,
  169425,
  168932,
  169426,
  169429,
  169428,
  169430
}

HL:RegisterForEvent(function()
  VarDGBHighRoll = false
  VarSubAPL = false
  VarHuntRamp = false
  VarEDRamp = false
  VarSCRamp = false
  VarFD = false
  VarPoolingForED = false
  VarPoolingForFDFelDev = false
  VarPoolingForSC = false
  VarPoolingForTheHunt = false
  VarPoolingFury = false
end, "PLAYER_REGEN_ENABLED")

HL:RegisterForEvent(function()
  VarSpiritBombFragmentsInMeta = (S.Fracture:IsAvailable()) and 3 or 4
  VarSpiritBombFragmentsNotInMeta = (S.Fracture:IsAvailable()) and 4 or 5
end, "PLAYER_EQUIPMENT_CHANGED", "PLAYER_TALENT_UPDATE")

-- Soul Fragments function taking into consideration aura lag
local function UpdateSoulFragments()
  SoulFragments = Player:BuffStack(S.SoulFragments)

  -- Casting Spirit Bomb immediately updates the buff
  -- May no longer be needed, as Spirit Bomb instantly removes the buff now
  if S.SpiritBomb:TimeSinceLastCast() < Player:GCD() then
    SoulFragmentsAdjusted = 0
  end

  -- Check if we have cast Soul Carver, Fracture, or Shear within the last GCD and haven't "snapshot" yet
  if SoulFragmentsAdjusted == 0 then
    local MetaMod = (Player:BuffUp(S.MetamorphosisBuff)) and 1 or 0
    if S.SoulCarver:IsAvailable() and S.SoulCarver:TimeSinceLastCast() < Player:GCD() and S.SoulCarver.LastCastTime ~= LastSoulFragmentAdjustment then
      SoulFragmentsAdjusted = math.min(SoulFragments + 2, 5)
      LastSoulFragmentAdjustment = S.SoulCarver.LastCastTime
    elseif S.Fracture:IsAvailable() and S.Fracture:TimeSinceLastCast() < Player:GCD() and S.Fracture.LastCastTime ~= LastSoulFragmentAdjustment then
      SoulFragmentsAdjusted = math.min(SoulFragments + 2 + MetaMod, 5)
      LastSoulFragmentAdjustment = S.Fracture.LastCastTime
    elseif S.Shear:TimeSinceLastCast() < Player:GCD() and S.Fracture.Shear ~= LastSoulFragmentAdjustment then
      SoulFragmentsAdjusted = math.min(SoulFragments + 1 + MetaMod, 5)
      LastSoulFragmentAdjustment = S.Shear.LastCastTime
    end
  else
    -- If we have a soul fragement "snapshot", see if we should invalidate it based on time
    local Prev = Player:PrevGCD(1)
    if Prev == 207407 and S.SoulCarver:TimeSinceLastCast() >= Player:GCD() then
      SoulFragmentsAdjusted = 0
    elseif Prev == 263642 and S.Fracture:TimeSinceLastCast() >= Player:GCD() then
      SoulFragmentsAdjusted = 0
    elseif Prev == 203782 and S.Shear:TimeSinceLastCast() >= Player:GCD() then
      SoulFragmentsAdjusted = 0
    end
  end

  -- If we have a higher Soul Fragment "snapshot", use it instead
  if SoulFragmentsAdjusted > SoulFragments then
    SoulFragments = SoulFragmentsAdjusted
  elseif SoulFragmentsAdjusted > 0 then
    -- Otherwise, the "snapshot" is invalid, so reset it if it has a value
    -- Relevant in cases where we use a generator two GCDs in a row
    SoulFragmentsAdjusted = 0
  end
end

-- Melee Is In Range w/ Movement Handlers
local function UpdateIsInMeleeRange()
  if S.Felblade:TimeSinceLastCast() < Player:GCD()
  or S.InfernalStrike:TimeSinceLastCast() < Player:GCD() then
    IsInMeleeRange = true
    IsInAoERange = true
    return
  end

  IsInMeleeRange = Target:IsInMeleeRange(5)
  IsInAoERange = IsInMeleeRange or EnemiesCount8yMelee > 0
end

local function Precombat()
  -- flask
  -- augmentation
  -- food
  -- variable,name=sub_apl_in_progress,value=0
  -- variable,name=the_hunt_ramp_in_progress,value=0
  -- variable,name=elysian_decree_ramp_in_progress,value=0
  -- variable,name=soul_carver_ramp_in_progress,value=0
  -- variable,name=fiery_demise_in_progress,value=0
  -- variable,name=spirit_bomb_soul_fragments_not_in_meta,op=setif,value=4,value_else=5,condition=talent.fracture.enabled
  -- variable,name=spirit_bomb_soul_fragments_in_meta,op=setif,value=3,value_else=4,condition=talent.fracture.enabled
  -- Note: Handling variable resets via PLAYER_REGEN_ENABLED/PLAYER_TALENT_UPDATE/PLAYER_EQUIPMENT_CHANGED registrations
  -- snapshot_stats
  -- sigil_of_flame
  if (not S.ConcentratedSigils:IsAvailable()) and S.SigilOfFlame:IsCastable() then
    if Press(M.SigilOfFlamePlayer, not Target:IsInMeleeRange(8)) then return "sigil_of_flame precombat 2"; end
  end
  -- immolation_aura
  if S.ImmolationAura:IsCastable() then
    if Press(S.ImmolationAura, not Target:IsInMeleeRange(8)) then return "immolation_aura precombat 4"; end
  end
  -- Manually added: First attacks
  if S.InfernalStrike:IsCastable() then
    if Press(M.InfernalStrikePlayer, not Target:IsInMeleeRange(8)) then return "infernal_strike precombat 6"; end
  end
  if S.Fracture:IsCastable() and IsInMeleeRange then
    if Press(S.Fracture) then return "fracture precombat 8"; end
  end
  if S.Shear:IsCastable() and IsInMeleeRange then
    if Press(S.Shear) then return "shear precombat 10"; end
  end
end

local function Defensives()
  -- Demon Spikes
  if S.DemonSpikes:IsCastable() and Player:BuffDown(S.DemonSpikesBuff) and Player:BuffDown(S.MetamorphosisBuff) and (EnemiesCount8yMelee == 1 and Player:BuffDown(S.FieryBrandDebuff) or EnemiesCount8yMelee > 1) then
    if S.DemonSpikes:ChargesFractional() > 1.9 then
      if Press(S.DemonSpikes) then return "demon_spikes defensives (Capped)"; end
    elseif (ActiveMitigationNeeded or Player:HealthPercentage() <= Settings.Vengeance.HP.DemonSpikes) then
      if Press(S.DemonSpikes) then return "demon_spikes defensives (Danger)"; end
    end
  end
  -- Metamorphosis,if=!buff.metamorphosis.up|target.time_to_die<15
  if S.Metamorphosis:IsCastable() and Player:HealthPercentage() <= Settings.Vengeance.HP.Metamorphosis and (Player:BuffDown(S.MetamorphosisBuff) or Target:TimeToDie() < 15) then
    if Press(S.Metamorphosis) then return "metamorphosis defensives"; end
  end
  -- Fiery Brand
  if S.FieryBrand:IsCastable() and (ActiveMitigationNeeded or Player:HealthPercentage() <= Settings.Vengeance.HP.FieryBrand) then
    if Press(S.FieryBrand, not Target:IsSpellInRange(S.FieryBrand)) then return "fiery_brand defensives"; end
  end
  -- healthstone
  if Player:HealthPercentage() <= Settings.General.HP.Healthstone and I.Healthstone:IsReady() then
    if Press(M.Healthstone, nil, nil, true) then return "healthstone defensives"; end
  end
end

local function HuntRamp()
  -- the_hunt,if=debuff.frailty.stack>=variable.frailty_target_requirement
  if CDsON() and S.TheHunt:IsCastable() and (Target:DebuffStack(S.FrailtyDebuff) >= VarFrailtyTargetRequirement) then
    if Press(S.TheHunt, not Target:IsInRange(50)) then return "the_hunt huntramp 2"; end
  end
  -- spirit_bomb,if=!variable.pooling_fury&soul_fragments>=variable.spirit_bomb_soul_fragments&spell_targets>1
  if S.SpiritBomb:IsReady() and ((not VarPoolingFury) and SoulFragments >= VarSpiritBombFragments and EnemiesCount8yMelee > 1) then
    if Press(S.SpiritBomb, not Target:IsInMeleeRange(8)) then return "spirit_bomb huntramp 4"; end
  end
  -- soul_cleave,if=!variable.pooling_fury&(soul_fragments<=1&spell_targets>1|spell_targets<2)
  if S.SoulCleave:IsReady() and ((not VarPoolingFury) and (SoulFragments <= 1 and EnemiesCount8yMelee > 1 or EnemiesCount8yMelee < 2)) then
    if Press(S.SoulCleave, not Target:IsInMeleeRange(8)) then return "soul_cleave huntramp 6"; end
  end
  -- sigil_of_flame
  if S.SigilOfFlame:IsCastable() then
    if S.ConcentratedSigils:IsAvailable() then
      if Press(S.SigilOfFlame, not IsInAoERange) then return "sigil_of_flame huntramp 8 (Concentrated)"; end
    else
      if Press(M.SigilOfFlamePlayer, not Target:IsInMeleeRange(8)) then return "sigil_of_flame huntramp 8 (Normal)"; end
    end
  end
  -- fracture
  if S.Fracture:IsCastable() then
    if Press(S.Fracture, not IsInMeleeRange) then return "fracture huntramp 10"; end
  end
  -- shear
  if S.Shear:IsCastable() then
    if Press(S.Shear, not IsInMeleeRange) then return "shear huntramp 12"; end
  end
  -- throw_glaive
  if S.ThrowGlaive:IsCastable() and Target:AffectingCombat() then
    if Press(S.ThrowGlaive, not Target:IsSpellInRange(S.ThrowGlaive)) then return "throw_glaive huntramp 14"; end
  end
  -- felblade
  if S.Felblade:IsCastable() then
    if Press(S.Felblade, not Target:IsSpellInRange(S.Felblade)) then return "felblade huntramp 16"; end
  end
end

local function EDRamp()
  -- elysian_decree,if=debuff.frailty.stack>=variable.frailty_target_requirement
  if S.ElysianDecree:IsCastable() and (Target:DebuffStack(S.FrailtyDebuff) >= VarFrailtyTargetRequirement) then
    if Press(S.ElysianDecree, not Target:IsInRange(30)) then return "elysian_decree edramp 2"; end
  end
  -- spirit_bomb,if=!variable.pooling_fury&soul_fragments>=variable.spirit_bomb_soul_fragments&spell_targets>1
  if S.SpiritBomb:IsReady() and ((not VarPoolingFury) and SoulFragments >= VarSpiritBombFragments and EnemiesCount8yMelee > 1) then
    if Press(S.SpiritBomb, not Target:IsInMeleeRange(8)) then return "spirit_bomb edramp 4"; end
  end
  -- soul_cleave,if=!variable.pooling_fury&(soul_fragments<=1&spell_targets>1|spell_targets<2)
  if S.SoulCleave:IsReady() and ((not VarPoolingFury) and (SoulFragments <= 1 and EnemiesCount8yMelee > 1 or EnemiesCount8yMelee < 2)) then
    if Press(S.SoulCleave, not Target:IsInMeleeRange(8)) then return "soul_cleave edramp 6"; end
  end
  -- sigil_of_flame
  if S.SigilOfFlame:IsCastable() then
    if S.ConcentratedSigils:IsAvailable() then
      if Press(S.SigilOfFlame, not IsInAoERange) then return "sigil_of_flame edramp 8 (Concentrated)"; end
    else
      if Press(M.SigilOfFlamePlayer, not Target:IsInMeleeRange(8)) then return "sigil_of_flame edramp 8 (Normal)"; end
    end
  end
  -- fracture
  if S.Fracture:IsCastable() then
    if Press(S.Fracture, not IsInMeleeRange) then return "fracture edramp 10"; end
  end
  -- shear
  if S.Shear:IsCastable() then
    if Press(S.Shear, not IsInMeleeRange) then return "shear edramp 12"; end
  end
  -- throw_glaive
  if S.ThrowGlaive:IsCastable() and Target:AffectingCombat() then
    if Press(S.ThrowGlaive, not Target:IsSpellInRange(S.ThrowGlaive)) then return "throw_glaive edramp 14"; end
  end
  -- felblade
  if S.Felblade:IsCastable() then
    if Press(S.Felblade, not Target:IsSpellInRange(S.Felblade)) then return "felblade edramp 16"; end
  end
end

local function SCRamp()
  -- soul_carver,if=debuff.frailty.stack>=variable.frailty_target_requirement
  if S.SoulCarver:IsCastable() and (Target:DebuffStack(S.FrailtyDebuff) >= VarFrailtyTargetRequirement) then
    if Press(S.SoulCarver, not IsInMeleeRange) then return "soul_carver scramp 2"; end
  end
  -- spirit_bomb,if=!variable.pooling_fury&soul_fragments>=variable.spirit_bomb_soul_fragments&spell_targets>1
  if S.SpiritBomb:IsReady() and ((not VarPoolingFury) and SoulFragments >= VarSpiritBombFragments and EnemiesCount8yMelee > 1) then
    if Press(S.SpiritBomb, not Target:IsInMeleeRange(8)) then return "spirit_bomb scramp 4"; end
  end
  -- soul_cleave,if=!variable.pooling_fury&(soul_fragments<=1&spell_targets>1|spell_targets<2)
  if S.SoulCleave:IsReady() and ((not VarPoolingFury) and (SoulFragments <= 1 and EnemiesCount8yMelee > 1 or EnemiesCount8yMelee < 2)) then
    if Press(S.SoulCleave, not Target:IsInMeleeRange(8)) then return "soul_cleave scramp 6"; end
  end
  -- sigil_of_flame
  if S.SigilOfFlame:IsCastable() then
    if S.ConcentratedSigils:IsAvailable() then
      if Press(S.SigilOfFlame, not IsInAoERange) then return "sigil_of_flame scramp 8 (Concentrated)"; end
    else
      if Press(M.SigilOfFlamePlayer, not Target:IsInMeleeRange(8)) then return "sigil_of_flame scramp 8 (Normal)"; end
    end
  end
  -- fracture
  if S.Fracture:IsCastable() then
    if Press(S.Fracture, not IsInMeleeRange) then return "fracture scramp 10"; end
  end
  -- shear
  if S.Shear:IsCastable() then
    if Press(S.Shear, not IsInMeleeRange) then return "shear scramp 12"; end
  end
  -- throw_glaive
  if S.ThrowGlaive:IsCastable() and Target:AffectingCombat()then
    if Press(S.ThrowGlaive, not Target:IsSpellInRange(S.ThrowGlaive)) then return "throw_glaive scramp 14"; end
  end
  -- felblade
  if S.Felblade:IsCastable() then
    if Press(S.Felblade, not Target:IsSpellInRange(S.Felblade)) then return "felblade scramp 16"; end
  end
end

local function FD()
  -- fiery_brand,if=!fiery_brand_dot_primary_ticking&fury>=30
  if CDsON() and S.FieryBrand:IsCastable() and (Target:DebuffDown(S.FieryBrandDebuff) and Player:Fury() >= 30) then
    if Press(S.FieryBrand, not Target:IsInRange(30)) then return "fiery_brand fd 2"; end
  end
  -- immolation_aura,if=fiery_brand_dot_primary_ticking
  if S.ImmolationAura:IsCastable() and (Target:DebuffUp(S.FieryBrandDebuff)) then
    if Press(S.ImmolationAura, not Target:IsInMeleeRange(8)) then return "immolation_aura fd 4"; end
  end
  -- soul_carver,if=fiery_brand_dot_primary_ticking&debuff.frailty.stack>=variable.frailty_target_requirement&soul_fragments<=3
  -- Note: Removing Frailty stack requirement for now, as we never generate enough stacks during FB
  if S.SoulCarver:IsCastable() and (Target:DebuffUp(S.FieryBrandDebuff) and SoulFragments <= 3) then
    if Press(S.SoulCarver, not IsInMeleeRange) then return "soul_carver fd 6"; end
  end
  -- fel_devastation,if=fiery_brand_dot_primary_ticking&fiery_brand_dot_primary_remains<=2
  if CDsON() and S.FelDevastation:IsReady() and (Target:DebuffUp(S.FieryBrandDebuff) and Target:DebuffRemains(S.FieryBrandDebuff) <= 2) then
    if Press(S.FelDevastation, not Target:IsInMeleeRange(8)) then return "fel_devastation fd 8"; end
  end
  -- spirit_bomb,if=!variable.pooling_fury&soul_fragments>=variable.spirit_bomb_soul_fragments&(spell_targets>1|dot.fiery_brand.ticking)
  if S.SpiritBomb:IsReady() and ((not VarPoolingFury) and SoulFragments >= VarSpiritBombFragments and (EnemiesCount8yMelee > 1 or Target:DebuffUp(S.FieryBrandDebuff))) then
    if Press(S.SpiritBomb, not Target:IsInMeleeRange(8)) then return "spirit_bomb fd 10"; end
  end
  -- soul_cleave,if=!variable.pooling_fury&(soul_fragments<=1&spell_targets>1|spell_targets<2)
  if S.SoulCleave:IsReady() and ((not VarPoolingFury) and (SoulFragments <= 1 and EnemiesCount8yMelee > 1 or EnemiesCount8yMelee < 2)) then
    if Press(S.SoulCleave, not Target:IsInMeleeRange(8)) then return "soul_cleave fd 12"; end
  end
  -- sigil_of_flame,if=dot.fiery_brand.ticking
  if S.SigilOfFlame:IsCastable() and (Target:DebuffUp(S.FieryBrandDebuff)) then
    if S.ConcentratedSigils:IsAvailable() then
      if Press(S.SigilOfFlame, not IsInAoERange) then return "sigil_of_flame fd 14 (Concentrated)"; end
    else
      if Press(M.SigilOfFlamePlayer, not Target:IsInMeleeRange(8)) then return "sigil_of_flame fd 14 (Normal)"; end
    end
  end
  -- fracture
  if S.Fracture:IsCastable() then
    if Press(S.Fracture, not IsInMeleeRange) then return "fracture fd 16"; end
  end
  -- shear
  if S.Shear:IsCastable() then
    if Press(S.Shear, not IsInMeleeRange) then return "shear fd 18"; end
  end
  -- throw_glaive
  if S.ThrowGlaive:IsCastable() and Target:AffectingCombat() then
    if Press(S.ThrowGlaive, not Target:IsSpellInRange(S.ThrowGlaive)) then return "throw_glaive fd 20"; end
  end
  -- felblade
  if S.Felblade:IsCastable() then
    if Press(S.Felblade, not Target:IsSpellInRange(S.Felblade)) then return "felblade fd 20"; end
  end
end

-- APL Main
local function APL()
  Enemies8yMelee = Player:GetEnemiesInMeleeRange(8)
  if (AoEON()) then
    EnemiesCount8yMelee = #Enemies8yMelee
  else
    EnemiesCount8yMelee = 1
  end

  UpdateSoulFragments()
  UpdateIsInMeleeRange()

  ActiveMitigationNeeded = Player:ActiveMitigationNeeded()
  IsTanking = Player:IsTankingAoE(8) or Player:IsTanking(Target)

  if Everyone.TargetIsValid() then
    -- Explosives
    if (Settings.General.Enabled.HandleExplosives) then
      local ShouldReturn = Everyone.HandleExplosive(S.ThrowGlaive, M.ThrowGlaiveMouseover); if ShouldReturn then return ShouldReturn; end
    end
    -- FodderToTheFlames
    if S.ThrowGlaive:IsCastable() and Utils.ValueIsInArray(FodderToTheFlamesDeamonIds, Target:NPCID()) then
      if Press(S.ThrowGlaive, not Target:IsSpellInRange(S.ThrowGlaive)) then return "fodder to the flames"; end
    end
    -- Check DGB CDR value
    if (S.DarkglareBoon:IsAvailable() and Player:PrevGCD(1, S.FelDevastation) and (DemonHunter.DGBCDRLastUpdate == 0 or GetTime() - DemonHunter.DGBCDRLastUpdate < 5)) then
      if DemonHunter.DGBCDR >= 18 then
        VarDGBHighRoll = true
      else
        VarDGBHighRoll = false
      end
    end
    -- Calculate GCDMax
    GCDMax = Player:GCD() + 0.5
    -- Precombat
    if not Player:AffectingCombat() then
      local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
    end
    -- auto_attack
    -- disrupt,if=target.debuff.casting.react (Interrupts)
    if not Player:IsCasting() and not Player:IsChanneling() then
      local ShouldReturn = Everyone.Interrupt(S.Disrupt, 10, true); if ShouldReturn then return ShouldReturn; end
      ShouldReturn = Everyone.InterruptWithStun(S.ChaosNova, 8); if ShouldReturn then return ShouldReturn; end
    end
    -- Manually added: Defensives
    if (IsTanking) then
      local ShouldReturn = Defensives(); if ShouldReturn then return ShouldReturn; end
    end
    -- infernal_strike,use_off_gcd=1
    if S.InfernalStrike:IsCastable() and ((not Settings.Vengeance.Enabled.ConserveInfernalStrike) or S.InfernalStrike:ChargesFractional() > 1.9) and (S.InfernalStrike:TimeSinceLastCast() > 2) then
      if Press(M.InfernalStrikePlayer, not Target:IsInMeleeRange(8)) then return "infernal_strike main 2"; end
    end
    -- demon_spikes,use_off_gcd=1,if=!buff.demon_spikes.up&!cooldown.pause_action.remainsif=!buff.demon_spikes.up&!cooldown.pause_action.remains
    -- Note: Handled via Defensives()
    -- metamorphosis,if=!buff.metamorphosis.up&!dot.fiery_brand.ticking
    if CDsON() and S.Metamorphosis:IsCastable() and Settings.Vengeance.Enabled.MetaOffensively and (Player:BuffDown(S.MetamorphosisBuff) and Target:DebuffDown(S.FieryBrandDebuff)) then
      if Press(S.Metamorphosis, not IsInMeleeRange) then return "metamorphosis main 4"; end
    end
    -- fiery_brand,if=!talent.fiery_demise.enabled&!dot.fiery_brand.ticking
    if CDsON() and S.FieryBrand:IsCastable() and Settings.Vengeance.Enabled.FieryBrandOffensively and ((not S.FieryDemise:IsAvailable()) and Target:DebuffDown(S.FieryBrandDebuff)) then
      if Press(S.FieryBrand, not Target:IsSpellInRange(S.FieryBrand)) then return "fiery_brand main 6"; end
    end
    -- fel_devastation,if=!talent.fiery_demise.enabled
    if CDsON() and S.FelDevastation:IsReady() and (not S.FieryDemise:IsAvailable()) then
      if Press(S.FelDevastation, not Target:IsInMeleeRange(8)) then return "fel_devastation main 7"; end
    end
    -- bulk_extraction
    if S.BulkExtraction:IsCastable() then
      if Press(S.BulkExtraction, not Target:IsInMeleeRange(8)) then return "bulk_extraction main 8"; end
    end
    -- potion
    -- trinkets
    if CDsON() and Settings.General.Enabled.Trinkets and Target:IsInMeleeRange(8) then
      -- use_item,slot=trinket1
      local Trinket1ToUse = Player:GetUseableTrinkets(OnUseExcludes, 13)
      if Trinket1ToUse then
        if Press(M.Trinket1, nil, nil, true) then return "trinket1 main 12"; end
      end
      -- use_item,slot=trinket2
      local Trinket2ToUse = Player:GetUseableTrinkets(OnUseExcludes, 14)
      if Trinket2ToUse then
        if Press(M.Trinket2, nil, nil, true) then return "trinket2 main 14"; end
      end
    end
    -- variable,name=spirit_bomb_soul_fragments,op=setif,value=variable.spirit_bomb_soul_fragments_in_meta,value_else=variable.spirit_bomb_soul_fragments_not_in_meta,condition=buff.metamorphosis.up
    VarSpiritBombFragments = (Player:BuffUp(S.MetamorphosisBuff)) and VarSpiritBombFragmentsInMeta or VarSpiritBombFragmentsNotInMeta
    -- variable,name=frailty_target_requirement,op=setif,value=5,value_else=6,condition=spell_targets.spirit_bomb>1
    VarFrailtyTargetRequirement = (EnemiesCount8yMelee > 1) and 5 or 6
    -- variable,name=frailty_dump_fury_requirement,op=setif,value=action.spirit_bomb.cost+(action.soul_cleave.cost*2),value_else=action.soul_cleave.cost*3,condition=spell_targets.spirit_bomb>1
    VarFrailtyDumpFuryRequirement = (EnemiesCount8yMelee > 1) and (S.SpiritBomb:Cost() + (S.SoulCleave:Cost() * 2)) or (S.SoulCleave:Cost() * 3)
    -- variable,name=pooling_for_the_hunt,value=talent.the_hunt.enabled&cooldown.the_hunt.remains<(gcd.max*2)&fury<variable.frailty_dump_fury_requirement&debuff.frailty.stack<=1
    VarPoolingForTheHunt = (S.TheHunt:IsAvailable() and S.TheHunt:CooldownRemains() < (GCDMax * 2) and Player:Fury() < VarFrailtyDumpFuryRequirement and Target:DebuffStack(S.FrailtyDebuff) <= 1)
    -- variable,name=pooling_for_elysian_decree,value=talent.elysian_decree.enabled&cooldown.elysian_decree.remains<(gcd.max*2)&fury<variable.frailty_dump_fury_requirement&debuff.frailty.stack<=1
    VarPoolingForED = (S.ElysianDecree:IsAvailable() and S.ElysianDecree:CooldownRemains() < (GCDMax * 2) and Player:Fury() < VarFrailtyDumpFuryRequirement and Target:DebuffStack(S.FrailtyDebuff) <= 1)
    -- variable,name=pooling_for_soul_carver,value=talent.soul_carver.enabled&cooldown.soul_carver.remains<(gcd.max*2)&fury<variable.frailty_dump_fury_requirement&debuff.frailty.stack<=1
    VarPoolingForSC = (S.SoulCarver:IsAvailable() and S.SoulCarver:CooldownRemains() < (GCDMax * 2) and Player:Fury() < VarFrailtyDumpFuryRequirement and Target:DebuffStack(S.FrailtyDebuff) <= 1)
    -- variable,name=pooling_for_fiery_demise_fel_devastation,value=talent.fiery_demise.enabled&cooldown.fel_devastation.remains<(gcd.max*2)&dot.fiery_brand.ticking&fury<(action.fel_devastation.cost+action.spirit_bomb.cost)
    VarPoolingForFDFelDev = (S.FieryDemise:IsAvailable() and S.FelDevastation:CooldownRemains() < (GCDMax * 2) and Target:DebuffUp(S.FieryBrandDebuff) and Player:Fury() < S.FelDevastation:Cost() + 40)
    -- variable,name=pooling_fury,value=variable.pooling_for_the_hunt|variable.pooling_for_elysian_decree|variable.pooling_for_soul_carver|variable.pooling_for_fiery_demise_fel_devastation
    VarPoolingFury = (VarPoolingForTheHunt or VarPoolingForED or VarPoolingForSC or VarPoolingForFDFelDev)
    -- variable,name=sub_apl_in_progress,value=variable.the_hunt_ramp_in_progress|variable.elysian_decree_ramp_in_progress|variable.soul_carver_ramp_in_progress|variable.fiery_demise_in_progress
    VarSubAPL = (VarHuntRamp or VarEDRamp or VarSCRamp or VarFD)
    -- variable,name=the_hunt_ramp_in_progress,value=1,if=talent.the_hunt.enabled&cooldown.the_hunt.remains<=10&!variable.sub_apl_in_progress
    if CDsON() and S.TheHunt:IsAvailable() and S.TheHunt:CooldownRemains() <= 10 and not VarSubAPL then
      VarHuntRamp = true
    end
    -- variable,name=the_hunt_ramp_in_progress,value=0,if=talent.the_hunt.enabled&cooldown.the_hunt.remains>10
    if S.TheHunt:IsAvailable() and S.TheHunt:CooldownRemains() > 10 then
      VarHuntRamp = false
    end
    -- variable,name=elysian_decree_ramp_in_progress,value=1,if=talent.elysian_decree.enabled&cooldown.elysian_decree.remains<=10&!variable.sub_apl_in_progress
    if CDsON() and S.ElysianDecree:IsAvailable() and S.ElysianDecree:CooldownRemains() <= 10 and not VarSubAPL then
      VarEDRamp = true
    end
    -- variable,name=elysian_decree_ramp_in_progress,value=0,if=talent.elysian_decree.enabled&cooldown.elysian_decree.remains>10
    if S.ElysianDecree:IsAvailable() and S.ElysianDecree:CooldownRemains() > 10 then
      VarEDRamp = false
    end
    -- variable,name=soul_carver_ramp_in_progress,value=1,if=talent.soul_carver.enabled&!talent.fiery_demise.enabled&cooldown.soul_carver.remains<=10&!variable.sub_apl_in_progress
    if S.SoulCarver:IsAvailable() and (not S.FieryDemise:IsAvailable()) and S.SoulCarver:CooldownRemains() <= 10 and not VarSubAPL then
      VarSCRamp = true
    end
    -- variable,name=soul_carver_ramp_in_progress,value=0,if=talent.soul_carver.enabled&!talent.fiery_demise.enabled&cooldown.soul_carver.remains>10
    if S.SoulCarver:IsAvailable() and S.SoulCarver:CooldownRemains() > 10 then
      VarSCRamp = false
    end
    -- variable,name=fiery_demise_in_progress,value=1,if=talent.fiery_brand.enabled&talent.fiery_demise.enabled&cooldown.fiery_brand.charges_fractional>=1&cooldown.immolation_aura.remains<=2&!variable.sub_apl_in_progress&((talent.fel_devastation.enabled&cooldown.fel_devastation.remains<=10)|(talent.soul_carver.enabled&cooldown.soul_carver.remains<=10))
    if CDsON() and S.FieryBrand:IsAvailable() and S.FieryDemise:IsAvailable() and S.FieryBrand:ChargesFractional() >= 1 and S.ImmolationAura:CooldownRemains() <= 2 and (not VarSubAPL) and ((S.FelDevastation:IsAvailable() and S.FelDevastation:CooldownRemains() <= 10) or (S.SoulCarver:IsAvailable() and S.SoulCarver:CooldownRemains() <= 10)) then
      VarFD = true
    end
    -- variable,name=fiery_demise_in_progress,value=0,if=talent.fiery_brand.enabled&talent.fiery_demise.enabled&cooldown.fiery_brand.charges_fractional<1.65&((talent.fel_devastation.enabled&cooldown.fel_devastation.remains>10)|(talent.soul_carver.enabled&cooldown.soul_carver.remains>10))
    if S.FieryBrand:IsAvailable() and S.FieryDemise:IsAvailable() and S.FieryBrand:ChargesFractional() < 1.65 and Target:DebuffDown(S.FieryBrandDebuff) and ((S.FelDevastation:IsAvailable() and S.FelDevastation:CooldownRemains() > 10) or ((not S.FelDevastation:IsAvailable()) and S.SoulCarver:IsAvailable() and S.SoulCarver:CooldownRemains() > 10)) then
      VarFD = false
    end
    -- run_action_list,name=the_hunt_ramp,if=variable.the_hunt_ramp_in_progress
    if VarHuntRamp then
      local ShouldReturn = HuntRamp(); if ShouldReturn then return ShouldReturn; end
      if Press(S.Pool) then return "Pool for HuntRamp()"; end
    end
    -- run_action_list,name=elysian_decree_ramp,if=variable.elysian_decree_ramp_in_progress
    if VarEDRamp then
      local ShouldReturn = EDRamp(); if ShouldReturn then return ShouldReturn; end
      if Press(S.Pool) then return "Pool for EDRamp()"; end
    end
    -- run_action_list,name=soul_carver_without_fiery_demise_ramp,if=variable.soul_carver_ramp_in_progress
    if VarSCRamp then
      local ShouldReturn = SCRamp(); if ShouldReturn then return ShouldReturn; end
      if Press(S.Pool) then return "Pool for SCRamp()"; end
    end
    -- run_action_list,name=fiery_demise_window,if=variable.fiery_demise_in_progress
    if VarFD then
      local ShouldReturn = FD(); if ShouldReturn then return ShouldReturn; end
      if Press(S.Pool) then return "Pool for FD()"; end
    end
    -- spirit_bomb,if=soul_fragments>=variable.spirit_bomb_soul_fragments&spell_targets>1
    if S.SpiritBomb:IsReady() and (SoulFragments >= VarSpiritBombFragments and EnemiesCount8yMelee > 1) then
      if Press(S.SpiritBomb, not Target:IsInMeleeRange(8)) then return "spirit_bomb main 18"; end
    end
    -- soul_cleave,if=soul_fragments<=1&spell_targets>1|spell_targets<2
    if S.SoulCleave:IsReady() and (SoulFragments <= 1 and EnemiesCount8yMelee > 1 or EnemiesCount8yMelee < 2) then
      if Press(S.SoulCleave, not Target:IsSpellInRange(S.SoulCleave)) then return "soul_cleave main 20"; end
    end
    -- immolation_aura,if=fury.deficit>=10&(((talent.fiery_demise.enabled&talent.soul_carver.enabled&cooldown.soul_carver.remains>10)|!talent.soul_carver.enabled)|!talent.fiery_demise.enabled)
    if S.ImmolationAura:IsCastable() and (Player:FuryDeficit() >= 10 and (((S.FieryDemise:IsAvailable() and S.SoulCarver:IsAvailable() and S.SoulCarver:CooldownRemains() > 10) or not S.SoulCarver:IsAvailable()) or not S.FieryDemise:IsAvailable())) then
      if Press(S.ImmolationAura, not Target:IsInMeleeRange(8)) then return "immolation_aura main 22"; end
    end
    -- sigil_of_flame
    if S.SigilOfFlame:IsCastable() and ((IsInAoERange or not S.ConcentratedSigils:IsAvailable()) and Target:DebuffRefreshable(S.SigilOfFlameDebuff)) then
      if S.ConcentratedSigils:IsAvailable() then
        if Press(S.SigilOfFlame, not IsInAoERange) then return "sigil_of_flame main 28 (Concentrated)"; end
      else
        if Press(M.SigilOfFlamePlayer, not Target:IsInMeleeRange(8)) then return "sigil_of_flame main 28 (Normal)"; end
      end
    end
    -- fracture
    if S.Fracture:IsCastable() and IsInMeleeRange then
      if Press(S.Fracture) then return "fracture main 32"; end
    end
    -- shear
    if S.Shear:IsCastable() and IsInMeleeRange then
      if Press(S.Shear) then return "shear main 30"; end
    end
    -- throw_glaive
    if S.ThrowGlaive:IsCastable() and Target:AffectingCombat() then
      if Press(S.ThrowGlaive, not Target:IsSpellInRange(S.ThrowGlaive)) then return "throw_glaive main 34"; end
    end
    -- felblade
    if S.Felblade:IsCastable() then
      if Press(S.Felblade, not Target:IsSpellInRange(S.Felblade)) then return "felblade main 24"; end
    end
    -- If nothing else to do, show the Pool icon
    if Press(S.Pool) then return "Wait/Pool Resources"; end
  end
end

local function AutoBind()
  -- Spell Binds
  Bind(S.BulkExtraction)
  Bind(S.DemonSpikes)
  Bind(S.ChaosNova)
  Bind(S.Disrupt)
  Bind(S.Felblade)
  Bind(S.FelDevastation)
  Bind(S.FieryBrand)
  Bind(S.Fracture)
  Bind(S.ImmolationAura)
  Bind(S.Metamorphosis)
  Bind(S.SigilOfFlame)
  Bind(S.SoulCleave)
  Bind(S.SoulCarver)
  Bind(S.Shear)
  Bind(S.SpiritBomb)
  Bind(S.TheHunt)
  Bind(S.ThrowGlaive)
  
  -- Bind Items
  Bind(M.Trinket1)
  Bind(M.Trinket2)
  Bind(M.Healthstone)
  
  -- Macros
  Bind(M.InfernalStrikePlayer)
  Bind(M.SigilOfFlamePlayer)
  Bind(M.SigilOfSilencePlayer)
  Bind(M.ThrowGlaiveMouseover)
end

local function Init()
  WR.Print("Vengeance Demon Hunter by Worldy.")
  AutoBind()
end

WR.SetAPL(581, APL, Init);
