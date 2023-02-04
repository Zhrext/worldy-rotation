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
local SpellFeral = Spell.Druid.Feral
local SpellResto = Spell.Druid.Restoration
-- Lua

--- ============================ CONTENT ============================
-- Balance, ID: 102
HL.AddCoreOverride ("Player.AstralPowerP",
  function ()
    local AP = Player:AstralPower()
    if not Player:IsCasting() then
      return AP
    else
      if Player:IsCasting(SpellBalance.Wrath) or Player:IsCasting(SpellBalance.Starfire) or Player:IsCasting(SpellBalance.StellarFlare) then
        return AP + 8
      elseif Player:IsCasting(SpellBalance.NewMoon) then
        return AP + 10
      elseif Player:IsCasting(SpellBalance.HalfMoon) then
        return AP + 20
      elseif Player:IsCasting(SpellBalance.FullMoon) then
        return AP + 40
      else
        return AP
      end
    end
  end
, 102)

local BalOldSpellIsCastable
BalOldSpellIsCastable = HL.AddCoreOverride ("Spell.IsCastable",
  function (self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    local RangeOK = true
    if Range then
      local RangeUnit = ThisUnit or Target
      RangeOK = RangeUnit:IsInRange( Range, AoESpell )
    end
    local BaseCheck = BalOldSpellIsCastable(self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    if self == SpellBalance.MoonkinForm then
      return BaseCheck and Player:BuffDown(self)
    elseif self == SpellBalance.StellarFlare then
      return BaseCheck and not Player:IsCasting(self)
    elseif self == SpellBalance.Wrath or self == SpellBalance.Starfire then
      return BaseCheck and not (Player:IsCasting(self) and self:Count() == 1)
    elseif self == SpellBalance.WarriorofElune then
      return BaseCheck and Player:BuffDown(self)
    elseif self == SpellBalance.NewMoon or self == SpellBalance.HalfMoon or self == SpellBalance.FullMoon then
      return BaseCheck and not Player:IsCasting(self)
    else
      return BaseCheck
    end
  end
, 102)

-- Feral, ID: 103
local FeralOldSpellIsCastable
FeralOldSpellIsCastable = HL.AddCoreOverride ("Spell.IsCastable",
  function (self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    local BaseCheck = FeralOldSpellIsCastable(self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    if self == SpellFeral.CatForm or self == SpellFeral.MoonkinForm then
      return BaseCheck and Player:BuffDown(self)
    elseif self == SpellFeral.Prowl then
      return BaseCheck and self:IsUsable()
    else
      return BaseCheck
    end
  end
, 103)

-- Restoration, ID: 105
local RestoOldSpellIsCastable
RestoOldSpellIsCastable = HL.AddCoreOverride ("Spell.IsCastable",
  function (self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    local BaseCheck = RestoOldSpellIsCastable(self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    if self == SpellResto.CatForm or self == SpellResto.MoonkinForm then
      return BaseCheck and Player:BuffDown(self)
    else
      return BaseCheck
    end
  end
, 105)
