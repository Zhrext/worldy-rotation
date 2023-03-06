--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroLib
local HL = HeroLib
local Cache = HeroCache
local WR = WorldyRotation
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
local Mage = WR.Commons.Mage
-- Lua
local select = select
-- WoW API
local GetTime = GetTime
local C_Timer = C_Timer

  -- Arguments Variables
  HL.RoPTime = 0

  --------------------------
  -------- Frost -----------
  --------------------------

  local FrozenOrbFirstHit = true
  local FrozenOrbHitTime = 0

  HL:RegisterForSelfCombatEvent(function(...)
    local spellID = select(12, ...)
    if spellID == 84721 and FrozenOrbFirstHit then
      FrozenOrbFirstHit = false
      FrozenOrbHitTime = GetTime()
      C_Timer.After(10, function()
        FrozenOrbFirstHit = true
        FrozenOrbHitTime = 0
      end)
    end
  end, "SPELL_DAMAGE")

  function Player:FrozenOrbGroundAoeRemains()
    return math.max((FrozenOrbHitTime - (GetTime() - 10) - HL.RecoveryTimer()), 0)
  end

  local brain_freeze_active = false

  HL:RegisterForSelfCombatEvent(function(...)
    local spellID = select(12, ...)
    if spellID == Spell.Mage.Frost.Flurry:ID() then
     brain_freeze_active =     Player:BuffUp(Spell.Mage.Frost.BrainFreezeBuff)
                           or  Spell.Mage.Frost.BrainFreezeBuff:TimeSinceLastRemovedOnPlayer() < 0.1
    end
  end, "SPELL_CAST_SUCCESS")

  function Player:BrainFreezeActive()
    if self:IsCasting(Spell.Mage.Frost.Flurry) then
     return false
    else
     return brain_freeze_active
   end
  end
