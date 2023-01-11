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
local SpellHavoc              = Spell.DemonHunter.Havoc
local SpellVengeance          = Spell.DemonHunter.Vengeance
-- Lua

--- ============================ CONTENT ============================
-- Havoc, ID: 577
local HavocOldSpellIsCastable
HavocOldSpellIsCastable = HL.AddCoreOverride ("Spell.IsCastable",
  function (self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    local BaseCheck = HavocOldSpellIsCastable(self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    if self == SpellHavoc.Metamorphosis then
      local HMIA = WR.GUISettings.APL.DemonHunter.Havoc.HideMetaIfActive
      return BaseCheck and ((HMIA and Player:BuffDown(SpellHavoc.MetamorphosisBuff)) or not HMIA)
    else
      return BaseCheck
    end
  end
, 577)

-- Vengeance, ID: 581
local VengOldSpellIsCastable
VengOldSpellIsCastable = HL.AddCoreOverride ("Spell.IsCastable",
  function (self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    local BaseCheck = VengOldSpellIsCastable(self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    if self == SpellVengeance.FieryBrand then
      return BaseCheck and Target:DebuffDown(SpellVengeance.FieryBrandDebuff)
    elseif self == SpellVengeance.TheHunt then
      return BaseCheck and not Player:IsCasting(self)
    else
      return BaseCheck
    end
  end
, 581)
