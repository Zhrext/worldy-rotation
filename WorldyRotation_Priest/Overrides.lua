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
local SpellDisc    = Spell.Priest.Discipline
-- Lua
-- WoW API
local UnitPower         = UnitPower

--- ============================ CONTENT ============================
-- Discipline, ID: 256
local OldDiscIsCastable
OldDiscIsCastable = HL.AddCoreOverride("Spell.IsCastable",
  function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
    local BaseCheck = OldDiscIsCastable(self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
    if self == SpellDisc.MindBlast or self == SpellDisc.Schism then
      return BaseCheck and (not Player:IsCasting(self))
    elseif self == SpellDisc.Smite or self == SpellDisc.DivineStar or self == SpellDisc.Halo or self == SpellDisc.Penance or self == SpellDisc.PowerWordSolace then
      return BaseCheck and (not Player:BuffUp(SpellDisc.ShadowCovenantBuff))
    else
      return BaseCheck
    end
  end
, 256)

-- Holy, ID: 257

-- Shadow, ID: 258

-- Example (Arcane Mage)
-- HL.AddCoreOverride ("Spell.IsCastableP", 
-- function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
--   if Range then
--     local RangeUnit = ThisUnit or Target
--     return self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0 and RangeUnit:IsInRange( Range, AoESpell )
--   elseif self == SpellArcane.MarkofAluneth then
--     return self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0 and not Player:IsCasting(self)
--   else
--     return self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0
--   end
-- end
-- , 62)
