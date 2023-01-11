--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroLib
local HL               = HeroLib
local WR               = WorldyRotation
local Cache            = HeroCache
local Unit             = HL.Unit
local Player           = Unit.Player
local Target           = Unit.Target
local Spell            = HL.Spell
local Item             = HL.Item
-- Lua
local GetTime          = GetTime
-- File Locals
WR.Commons.DemonHunter = {}
local DemonHunter      = WR.Commons.DemonHunter
local SpellVDH         = Spell.DemonHunter.Vengeance


--- ============================ CONTENT ============================
--- ======= NON-COMBATLOG =======

--- ======= COMBATLOG =======

-------------------
----- DGB CDR -----
-------------------
HL:RegisterForSelfCombatEvent(
  function (...)
    local SourceGUID, _, _, _, _, _, _, _, SpellID, _, _, Amount = select(4, ...);

    if SourceGUID == Player:GUID() then
      if SpellID == 391345 then
        DemonHunter.DGBCDR = (Amount / 100) * 60;
        DemonHunter.DGBCDRLastUpdate = GetTime();
      end
    end
  end
  , "SPELL_ENERGIZE"
)
