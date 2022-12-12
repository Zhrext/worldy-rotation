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
local SpellMM = Spell.Hunter.Marksmanship
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

-- Marksmanship, ID: 254
local OldMMIsCastable
OldMMIsCastable = HL.AddCoreOverride("Spell.IsCastable",
function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
  local BaseCheck = OldMMIsCastable(self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
  if self == SpellMM.SummonPet then
    return (not Pet:IsActive()) and (not Pet:IsDeadOrGhost()) and BaseCheck
  else
    return BaseCheck
  end
end
, 254)

local OldMMIsReady
OldMMIsReady = HL.AddCoreOverride("Spell.IsReady",
function (self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
  local BaseCheck = OldMMIsReady(self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
  if self == SpellMM.AimedShot then
    local ShouldCastAS = ((not Player:IsCasting(SpellMM.AimedShot)) and SpellMM.AimedShot:Charges() == 1 or SpellMM.AimedShot:Charges() > 1)
    if WR.GUISettings.APL.Hunter.Marksmanship.HideAimedWhileMoving then
      return BaseCheck and ShouldCastAS and ((not Player:IsMoving()) or Player:BuffUp(SpellMM.LockandLoadBuff))
    else
      return BaseCheck and ShouldCastAS
    end
  elseif self == SpellMM.WailingArrow then
    return BaseCheck and (not Player:IsCasting(self))
  else
    return BaseCheck
  end
end
, 254)

local OldMMBuffRemains
OldMMBuffRemains = HL.AddCoreOverride("Player.BuffRemains",
  function(self, Spell, AnyCaster, Offset)
    if Spell == SpellMM.TrickShotsBuff and (Player:IsCasting(SpellMM.AimedShot) or Player:IsChanneling(SpellMM.RapidFire)) then
      return 0
    else
      return OldMMBuffRemains(self, Spell, AnyCaster, Offset)
    end
  end
, 254)

local OldMMBuffDown
OldMMBuffDown = HL.AddCoreOverride("Player.BuffDown",
  function(self, Spell, AnyCaster, Offset)
    if Spell == SpellMM.PreciseShotsBuff and Player:IsCasting(SpellMM.AimedShot) then
      return false
    else
      return OldMMBuffDown(self, Spell, AnyCaster, Offset)
    end
  end
, 254)

HL.AddCoreOverride("Player.FocusP",
  function()
    local Focus = Player:Focus() + Player:FocusRemainingCastRegen()
    if not Player:IsCasting() then
      return Focus
    else
      if Player:IsCasting(SpellMM.SteadyShot) then
        return Focus + 10
      elseif Player:IsChanneling(SpellMM.RapidFire) then
        return Focus + 7
      elseif Player:IsCasting(SpellMM.WailingArrow) then
        return Focus - 15
      elseif Player:IsCasting(SpellMM.AimedShot) then
        return Focus - 35
      end
    end
  end
, 254)
