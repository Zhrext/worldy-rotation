--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroLib
local HL = HeroLib
local WR = WorldyRotation
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
-- Lua

-- WoW API
local GetTime = GetTime
-- File Locals
WR.Commons.Evoker = {}
local Evoker = WR.Commons.Evoker
Evoker.FirestormTracker = {}

--- ============================ CONTENT ============================
--- ======= NON-COMBATLOG =======
HL:RegisterForEvent(
  function(Event, Arg1, Arg2)
    -- Ensure it's the player
    if Arg1 ~= "player"then
      return
    end

    if Arg2 == "ESSENCE" then
      Cache.Persistent.Player.LastPowerUpdate = GetTime()
    end
  end,
  "UNIT_POWER_UPDATE"
)

HL:RegisterForSelfCombatEvent(
   function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
     if SpellID == 369374 then
       Evoker.FirestormTracker[DestGUID] = GetTime()
     end
   end,
   "SPELL_DAMAGE"
 )
 
 HL:RegisterForCombatEvent(
   function(_, _, _, _, _, _, _, DestGUID)
     if Evoker.FirestormTracker[DestGUID] then
       Evoker.FirestormTracker[DestGUID] = nil
     end
   end,
   "UNIT_DIED",
   "UNIT_DESTROYED"
 )
