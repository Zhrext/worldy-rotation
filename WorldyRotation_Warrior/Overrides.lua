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
local SpellFury             = Spell.Warrior.Fury
local SpellArms             = Spell.Warrior.Arms
local SpellProt             = Spell.Warrior.Protection
-- Lua

--- ============================ CONTENT ============================
-- Arms, ID: 71
local ArmsOldSpellIsCastable
ArmsOldSpellIsCastable = HL.AddCoreOverride ("Spell.IsCastable",
  function (self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    local BaseCheck = ArmsOldSpellIsCastable(self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    if self == SpellArms.Charge then
      return BaseCheck and (self:Charges() >= 1 and (Player:AffectingCombat() and (not Target:IsInRange(8)) and Target:IsInRange(25) or not Player:AffectingCombat()))
    else
      return BaseCheck
    end
  end
, 71)

-- Fury, ID: 72
local FuryOldSpellIsCastable
FuryOldSpellIsCastable = HL.AddCoreOverride ("Spell.IsCastable",
  function (self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    local BaseCheck = FuryOldSpellIsCastable(self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    if self == SpellFury.Charge then
      return BaseCheck and (self:Charges() >= 1 and (Player:AffectingCombat() and (not Target:IsInRange(8)) and Target:IsInRange(25) or not Player:AffectingCombat()))
    else
      return BaseCheck
    end
  end
, 72)

local FuryOldSpellIsReady
FuryOldSpellIsReady = HL.AddCoreOverride ("Spell.IsReady",
  function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
    local BaseCheck = FuryOldSpellIsReady(self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
    if self == SpellFury.Rampage then
      if Player:PrevGCDP(1, SpellFury.Bladestorm) then
        return self:IsCastable() and Player:Rage() >= self:Cost()
      else
        return BaseCheck
      end
    else
      return BaseCheck
    end
  end
, 72)

-- Protection, ID: 73
local ProtOldSpellIsCastable
ProtOldSpellIsCastable = HL.AddCoreOverride ("Spell.IsCastable",
  function (self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    local BaseCheck = ProtOldSpellIsCastable(self, BypassRecovery, Range, AoESpell, ThisUnit, Offset)
    if self == SpellProt.Charge then
      return BaseCheck and (self:Charges() >= 1 and (not Target:IsInRange(8)))
    elseif self == SpellProt.HeroicThrow or self == SpellProt.TitanicThrow then
      return BaseCheck and (not Target:IsInRange(8))
    elseif self == SpellProt.Avatar then
      return BaseCheck and (Player:BuffDown(SpellProt.AvatarBuff))
    elseif self == SpellProt.Intervene then
      return BaseCheck and (Player:IsInParty() or Player:IsInRaid())
    else
      return BaseCheck
    end
  end
, 73)
