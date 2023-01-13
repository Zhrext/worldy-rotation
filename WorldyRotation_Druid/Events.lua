--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroLib
local HL = HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
-- Lua

-- File Locals
SpellBalance = Spell.Druid.Balance
HL.Druid = {}
HL.Druid.FullMoonLastCast = nil
HL.Druid.OrbitBreakerStacks = 0

--- ============================ CONTENT ============================
-- Orbit Breaker Tracking
HL:RegisterForSelfCombatEvent(function(dmgTime, _, _, _, _, _, _, _, _, _, _, spellID)
  if spellID == 202497 then
    HL.Druid.OrbitBreakerStacks = HL.Druid.OrbitBreakerStacks + 1
  end
  if spellID == 274283 then
    if (not SpellBalance.NewMoon:IsAvailable()) or (SpellBalance.NewMoon:IsAvailable() and (HL.Druid.FullMoonLastCast == nil or dmgTime - HL.Druid.FullMoonLastCast > 1.5)) then
      HL.Druid.OrbitBreakerStacks = 0
    end
  end
end, "SPELL_DAMAGE")

HL:RegisterForSelfCombatEvent(function(castTime, _, _, _, _, _, _, _, _, _, _, spellID)
  if spellID == 274283 then
    HL.Druid.FullMoonLastCast = castTime
  end
end, "SPELL_CAST_SUCCESS")
