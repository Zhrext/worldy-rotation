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
