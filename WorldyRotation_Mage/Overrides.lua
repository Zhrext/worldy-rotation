--- ============================ HEADER ============================
-- HeroLib
local HL      = HeroLib
local Cache   = HeroCache
local Unit    = HL.Unit
local Player  = Unit.Player
local Pet     = Unit.Pet
local Target  = Unit.Target
local Spell   = HL.Spell
local Item    = HL.Item
-- WorldyRotation
local WR      = WorldyRotation
-- Spells
local SpellFrost  = Spell.Mage.Frost

local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Mage.Commons,
  Frost = WR.GUISettings.APL.Mage.Frost,
}

-- Util
local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

--- ============================ CONTENT ============================
-- Mage
local RopDuration = SpellFrost.RuneofPower:BaseDuration()

local function ROPRemains(ROP)
  return math.max(RopDuration - ROP:TimeSinceLastAppliedOnPlayer() - Player:GCD(),0)
end

-- Frost, ID: 64
local FrostOldSpellIsCastable
FrostOldSpellIsCastable = HL.AddCoreOverride("Spell.IsCastable",
  function (self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    local MovingOK = true
    if self:CastTime() > 0 and Player:IsMoving() and Settings.Commons.MovingRotation then
      if self == SpellFrost.Blizzard and Player:BuffUp(SpellFrost.FreezingRain) then
        MovingOK = true
      else
        return false
      end
    end

    local RangeOK = true
    if Range then
      local RangeUnit = ThisUnit or Target
      RangeOK = RangeUnit:IsInRange( Range, AoESpell )
    end
    if self == SpellFrost.GlacialSpike then
      return self:IsLearned() and RangeOK and MovingOK and not Player:IsCasting(self) and (Player:BuffUp(SpellFrost.GlacialSpikeBuff) or (Player:BuffStack(SpellFrost.IciclesBuff) == 5))
    else
      local BaseCheck = FrostOldSpellIsCastable(self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
      if self == SpellFrost.SummonWaterElemental then
        return BaseCheck and not Pet:IsActive()
      elseif self == SpellFrost.RuneofPower then
        return BaseCheck and not Player:IsCasting(self) and Player:BuffDown(SpellFrost.RuneofPowerBuff)
      elseif self == SpellFrost.MirrorsofTorment then
        return BaseCheck and not Player:IsCasting(self)
      elseif self == SpellFrost.RadiantSpark then
        return BaseCheck and not Player:IsCasting(self)    
      elseif self == SpellFrost.ShiftingPower then
        return BaseCheck and not Player:IsCasting(self)    
      elseif self == SpellFrost.Deathborne then
        return BaseCheck and not Player:IsCasting(self)
      else
        return BaseCheck
      end
    end
  end
, 64)

local FrostOldSpellCooldownRemains
FrostOldSpellCooldownRemains = HL.AddCoreOverride("Spell.CooldownRemains",
  function (self, BypassRecovery, Offset)
    if self == SpellFrost.Blizzard and Player:IsCasting(self) then
      return 8
    elseif self == SpellFrost.Ebonbolt and Player:IsCasting(self) then
      return 45
    else
      return FrostOldSpellCooldownRemains(self, BypassRecovery, Offset)
    end
  end
, 64)

local FrostOldPlayerBuffStack
FrostOldPlayerBuffStack = HL.AddCoreOverride("Player.BuffStackP",
  function (self, Spell, AnyCaster, Offset)
    local BaseCheck = Player:BuffStack(Spell)
    if Spell == SpellFrost.IciclesBuff then
      return self:IsCasting(SpellFrost.GlacialSpike) and 0 or math.min(BaseCheck + (self:IsCasting(SpellFrost.Frostbolt) and 1 or 0), 5)
    elseif Spell == SpellFrost.GlacialSpikeBuff then
      return self:IsCasting(SpellFrost.GlacialSpike) and 0 or BaseCheck
    elseif Spell == SpellFrost.WintersReachBuff then
      return self:IsCasting(SpellFrost.Flurry) and 0 or BaseCheck
    elseif Spell == SpellFrost.FingersofFrostBuff then
      if SpellFrost.IceLance:InFlight() then
        if BaseCheck == 0 then
          return 0
        else
          return BaseCheck - 1
        end
      else
        return BaseCheck
      end
    else
      return BaseCheck
    end
  end
, 64)

local FrostOldPlayerBuffUp
FrostOldPlayerBuffUp = HL.AddCoreOverride("Player.BuffUpP",
  function (self, Spell, AnyCaster, Offset)
    local BaseCheck = Player:BuffUp(Spell)
    if Spell == SpellFrost.FingersofFrostBuff then
      if SpellFrost.IceLance:InFlight() then
        return Player:BuffStack(Spell) >= 1
      else
        return BaseCheck
      end
    else
      return BaseCheck
    end
  end
, 64)

local FrostOldPlayerBuffDown
FrostOldPlayerBuffDown = HL.AddCoreOverride("Player.BuffDownP",
  function (self, Spell, AnyCaster, Offset)
    local BaseCheck = Player:BuffDown(Spell)
    if Spell == SpellFrost.FingersofFrostBuff then
      if SpellFrost.IceLance:InFlight() then
        return Player:BuffStack(Spell) == 0
      else
        return BaseCheck
      end
    else
      return BaseCheck
    end
  end
, 64)

local FrostOldTargetDebuffStack
FrostOldTargetDebuffStack = HL.AddCoreOverride("Target.DebuffStack",
  function (self, Spell, AnyCaster, Offset)
    local BaseCheck = FrostOldTargetDebuffStack(self, Spell, AnyCaster, Offset)
    if Spell == SpellFrost.WintersChillDebuff then
      if SpellFrost.Flurry:InFlight() then
        return 2
      elseif SpellFrost.IceLance:InFlight() then
        if BaseCheck == 0 then
          return 0
        else
          return BaseCheck - 1
        end
      else
        return BaseCheck
      end
    else
      return BaseCheck
    end
  end
, 64)

local FrostOldTargetDebuffRemains
FrostOldTargetDebuffRemains = HL.AddCoreOverride("Target.DebuffRemains",
  function (self, Spell, AnyCaster, Offset)
    local BaseCheck = FrostOldTargetDebuffRemains(self, Spell, AnyCaster, Offset)
    if Spell == SpellFrost.WintersChillDebuff then
      return SpellFrost.Flurry:InFlight() and 6 or BaseCheck
    else
      return BaseCheck
    end
  end
, 64)

local FrostOldPlayerAffectingCombat
FrostOldPlayerAffectingCombat = HL.AddCoreOverride("Player.AffectingCombat",
  function (self)
    return SpellFrost.Frostbolt:InFlight() or FrostOldPlayerAffectingCombat(self)
  end
, 64)
