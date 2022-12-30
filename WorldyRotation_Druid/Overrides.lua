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
local SpellResto = Spell.Druid.Restoration
-- Lua

--- ============================ CONTENT ============================
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
