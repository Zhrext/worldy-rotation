--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local HL = HeroLib
local Cache = HeroCache
local WR = WorldyRotation
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
WR.Commons.Hunter = {}
local Hunter = WR.Commons.Hunter
-- Lua
local pairs = pairs
local select = select
local wipe = wipe
local GetTime = HL.GetTime
-- Spells
local SpellBM = Spell.Hunter.BeastMastery

-- Animal Companion Listener
do
  Hunter.PetTable = {
    LastPetSpellID = 0,
    LastPetSpellCount = 0
  }

  local DestGUID, SpellID;
  local PetGUIDs = {};

  HL:RegisterForSelfCombatEvent(
    function (...)
      if SpellBM.AnimalCompanion:IsAvailable() then
        DestGUID, _, _, _, SpellID = select(8, ...);
        if (SpellID == SpellBM.BeastCleavePetBuff:ID() and Hunter.PetTable.LastPetSpellID == SpellBM.MultiShot:ID())
        or (SpellID == SpellBM.FrenzyPetBuff:ID() and Hunter.PetTable.LastPetSpellID == SpellBM.BarbedShot:ID())
        or (SpellID == SpellBM.BestialWrathPetBuff:ID() and Hunter.PetTable.LastPetSpellID == SpellBM.BestialWrath:ID()) then
          if not PetGUIDs[DestGUID] then
            PetGUIDs[DestGUID] = true
            Hunter.PetTable.LastPetSpellCount = Hunter.PetTable.LastPetSpellCount + 1
          end
        end
      end
    end
    , "SPELL_AURA_APPLIED", "SPELL_AURA_REFRESH", "SPELL_AURA_APPLIED_DOSE"
  )

  HL:RegisterForSelfCombatEvent(
    function (...)
      if SpellBM.AnimalCompanion:IsAvailable() then
        SpellID = select(12, ...)
        if SpellID == SpellBM.MultiShot:ID() or SpellID == SpellBM.BarbedShot:ID() or SpellID == SpellBM.BestialWrath:ID() then
          PetGUIDs = {}
          Hunter.PetTable.LastPetSpellID = SpellID
          Hunter.PetTable.LastPetSpellCount = 0
        end
      end
    end
    , "SPELL_CAST_SUCCESS"
  )
end

-- Focused Trickery Counter (Tier 28 4pc bonus)
Hunter.FTCount = 0

