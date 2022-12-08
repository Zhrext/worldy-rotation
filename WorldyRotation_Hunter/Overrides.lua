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
local SpellBM = Spell.Hunter.BeastMastery
-- Lua
local mathmax = math.max
-- WoW API
local GetTime = GetTime

--- ============================ CONTENT ============================
-- Beast Mastery, ID: 253
local OldBMIsCastable
OldBMIsCastable = HL.AddCoreOverride("Spell.IsCastable",
function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
  local BaseCheck = OldBMIsCastable(self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
  if self == SpellBM.SummonPet then
    return (not Pet:IsActive()) and BaseCheck
  elseif self == SpellBM.KillShot then
    return BaseCheck and self:IsUsable()
  else
    return BaseCheck
  end
end
, 253)

local BMPetBuffRemains
BMPetBuffRemains = HL.AddCoreOverride ("Pet.BuffRemains",
function (self, Spell, AnyCaster, Offset)
  local BaseCheck = BMPetBuffRemains(self, Spell, AnyCaster, Offset)
  -- For short duration pet buffs, if we are in the process of casting an instant spell, fake the duration calculation until we know what it is
  -- This is due to the fact that instant spells don't trigger SPELL_CAST_START and we could have a refresh in progress 50-150ms before we know about it
  if Spell == SpellBM.FrenzyBuff then
    if Player:IsPrevCastPending() then
      return BaseCheck + (GetTime() - Player:GCDStartTime())
    end
  elseif Spell == SpellBM.BeastCleaveBuff then
    -- If the player buff has duration, grab that one instead. It can be applid a few MS earlier due to latency
    BaseCheck = mathmax(BaseCheck, Player:BuffRemains(SpellBM.BeastCleavePlayerBuff))
    if Player:IsPrevCastPending() then
      return BaseCheck + (GetTime() - Player:GCDStartTime())
    end
  end
  return BaseCheck
end
, 253)
