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
  local SpellBM = Spell.Monk.Brewmaster
  local SpellWW = Spell.Monk.Windwalker
-- Lua

--- ============================ CONTENT ============================
-- Brewmaster, ID: 268
local BMOldSpellIsCastable
BMOldSpellIsCastable = HL.AddCoreOverride ("Spell.IsCastable",
  function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
    local BaseCheck = BMOldSpellIsCastable(self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
    if self == SpellBM.TouchOfDeath then
      return BaseCheck and self:IsUsable()
    else
      return BaseCheck
    end
  end
, 268)

-- Windwalker, ID: 269

-- Mistweaver, ID: 270

-- Example (Arcane Mage)
-- HL.AddCoreOverride ("Spell.IsCastableP", 
-- function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
--   if Range then
--     local RangeUnit = ThisUnit or Target;
--     return self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0 and RangeUnit:IsInRange( Range, AoESpell );
--   elseif self == SpellArcane.MarkofAluneth then
--     return self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0 and not Player:IsCasting(self);
--   else
--     return self:IsLearned() and self:CooldownRemainsP( BypassRecovery, Offset or "Auto") == 0;
--   end;
-- end
-- , 62);
