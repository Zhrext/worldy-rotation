--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, WR = ...;
  -- HeroLib
  local HL = HeroLib;
  local Cache, Utils = HeroCache, HL.Utils;
  local Unit = HL.Unit;
  local Player = Unit.Player;
  local Target = Unit.Target;
  local Party = Unit.Party;
  local Raid = Unit.Raid;
  local Spell = HL.Spell;
  local Item = HL.Item;
  -- Lua
  local pairs = pairs;
  local stringformat = string.format
  local tableinsert = table.insert;
  -- File Locals
  WR.Commons = {};
  local Commons = {};
  WR.Commons.Everyone = Commons;
  local Settings = WR.GUISettings.General;
  local AbilitySettings = WR.GUISettings.Abilities;

--- ============================ CONTENT ============================
-- Is the current target valid?
function Commons.TargetIsValid()
  return Target:Exists() and Player:CanAttack(Target) and not Target:IsDeadOrGhost();
end

-- Is the current target a valid npc healable unit?
do
  local HealableNpcIDs = {
    182822,
    184493,
  };
  function Commons.TargetIsValidHealableNpc()
    return Target:Exists() and not Player:CanAttack(Target) and not Target:IsDeadOrGhost() and Utils.ValueIsInArray(HealableNpcIDs, Target:ID());
  end
end

-- Is the current unit valid during cycle?
function Commons.UnitIsCycleValid(Unit, BestUnitTTD, TimeToDieOffset)
  return not Unit:IsFacingBlacklisted() and not Unit:IsUserCycleBlacklisted() and (not BestUnitTTD or Unit:FilteredTimeToDie(">", BestUnitTTD, TimeToDieOffset));
end

-- Is it worth to DoT the unit?
function Commons.CanDoTUnit(Unit, HealthThreshold)
  return Unit:Health() >= HealthThreshold or Unit:IsDummy();
end

-- Interrupt
function Commons.Interrupt(Range, Spell, Setting, StunSpells)
  if Settings.InterruptEnabled and Target:IsInterruptible() and Target:IsInRange(Range) then
    if Spell:IsCastable() then
      if WR.Cast(Spell, Setting) then return "Cast " .. Spell:Name() .. " (Interrupt)"; end
    elseif Settings.InterruptWithStun and Target:CanBeStunned() then
      if StunSpells then
        for i = 1, #StunSpells do
          if StunSpells[i][1]:IsCastable() and StunSpells[i][3]() then
            if WR.Cast(StunSpells[i][1]) then return StunSpells[i][2]; end
          end
        end
      end
    end
  end
end

-- Is in Solo Mode?
function Commons.IsSoloMode()
  return not Player:IsInRaid() and not Player:IsInParty();
end

-- Get friendly units.
do
  local PartyUnits = {};
  local RaidUnits = {};
  function Commons.FriendlyUnits()
    if #PartyUnits == 0 then
      tableinsert(PartyUnits, Player);
      for i = 1, 4 do
        local PartyUnitKey = stringformat("party%d", i);
        tableinsert(PartyUnits, Party[PartyUnitKey]);
      end
    end
    if #RaidUnits == 0 then
      for i = 1, 40 do
        local RaidUnitKey = stringformat("raid%d", i);
        tableinsert(RaidUnits, Raid[RaidUnitKey]);
      end
    end
    if Commons.IsSoloMode() then
      return {Player};
    elseif Player:IsInParty() and not Player:IsInRaid() then
      return PartyUnits;
    elseif Player:IsInRaid() then
      return RaidUnits;
    end
    return {};
  end
end

-- Get dispellable friendly units.
do
  local DispellableDebuffs = {
    Spell(325885), -- Anguished Cries
    Spell(325224), -- Anima Injection
    Spell(321968), -- Bewildering Pollen
    Spell(327882), -- Blightbeak
    Spell(324859), -- Bramblethorn Entanglement
    Spell(317963), -- Burden of Knowledge
    Spell(322358), -- Burning Strain
    Spell(243237), -- Burst
    Spell(360148), -- Bursting Dread
    Spell(338729), -- Charged Anima
    Spell(328664), -- Chilled
    Spell(323347), -- Clinging Darkness
    Spell(320512), -- Corroded Claws
    Spell(319070), -- Corrosive Gunk
    Spell(325725), -- Cosmic Artifice
    Spell(365297), -- Crushing Prism
    Spell(327481), -- Dark Lance
    Spell(324652), -- Debilitating Plague
    Spell(330700), -- Decaying Blight
    Spell(364522), -- Devouring Blood
    Spell(356324), -- Empowered Glyph of Restraint
    Spell(328331), -- Forced Confession
    -- NOTE(Worldy): Manually.
    -- 320788, -- Frozen Binds
    Spell(320248), -- Genetic Alteration
    Spell(355915), -- Glyph of Restraint
    Spell(364031), -- Gloom
    Spell(338353), -- Goresplatter
    Spell(328180), -- Gripping Infection
    Spell(346286), -- Hazardous Liquids
    Spell(320596), -- Heaving Retch
    Spell(332605), -- Hex
    Spell(328002), -- Hurl Spores
    Spell(357029), -- Hyperlight Bomb
    Spell(317661), -- Insidious Venom
    Spell(327648), -- Internal Strife
    Spell(322818), -- Lost Confidence
    Spell(319626), -- Phantasmal Parasite
    Spell(349954), -- Purification Protocol
    Spell(324293), -- Rasping Scream
    Spell(328756), -- Repulsive Visage
    -- NOTE(Worldy): Manually.
    -- 360687, -- Runecarver's Deathtouch
    Spell(355641), -- Scintillate
    Spell(332707), -- Shadow Word: Pain
    Spell(334505), -- Shimmerdust Sleep
    Spell(339237), -- Sinlight Visions
    Spell(325701), -- Siphon Life
    Spell(329110), -- Slime Injection
    Spell(333708), -- Soul Corruption
    Spell(322557), -- Soul Split
    Spell(356031), -- Stasis Beam
    Spell(326632), -- Stony Veins
    Spell(353835), -- Suppression
    Spell(326607), -- Turn to Stone
    Spell(360241), -- Unsettling Dreams
    Spell(340026), -- Wailing Grief
    Spell(320529), -- Wasting Blight
    Spell(341949), -- Withering Blight
    Spell(321038), -- Wrack Soul
  };
  function Commons.DispellableFriendlyUnits()
    local FriendlyUnits = Commons.FriendlyUnits();
    local DispellableUnits = {};
    for i = 1, #FriendlyUnits do
      for j = 1, #DispellableDebuffs do
        local DispellableUnit = FriendlyUnits[i];
        if DispellableUnit:DebuffUp(DispellableDebuffs[j]) then
          tableinsert(DispellableUnits, DispellableUnit);
        end
      end
    end
    return DispellableUnits;
  end
  function Commons.DispellableFriendlyUnit()
    local DispellableFriendlyUnits = Commons.DispellableFriendlyUnits();
    local DispellableFriendlyUnitsCount = #DispellableFriendlyUnits;
    if DispellableFriendlyUnitsCount > 0 then
      for i = 1, DispellableFriendlyUnitsCount do
        local DispellableFriendlyUnit = DispellableFriendlyUnits[i];
        if not Commons.UnitGroupRole(DispellableFriendlyUnit) == "TANK" then
          return DispellableFriendlyUnit;
        end
      end
      return DispellableFriendlyUnits[1];
    end
  end
end

-- Get assigned unit role.
function Commons.UnitGroupRole(GroupUnit)
  if GroupUnit:IsAPlayer() then
    return UnitGroupRolesAssigned(GroupUnit:ID());
  end
end

-- Get lowest friendly unit.
function Commons.LowestFriendlyUnit()
  local LowestUnit;
  local FriendlyUnits = Commons.FriendlyUnits();
  for i = 1, #FriendlyUnits do
    local FriendlyUnit = FriendlyUnits[i];
    if FriendlyUnit and FriendlyUnit:Exists() and not FriendlyUnit:IsDeadOrGhost() and FriendlyUnit:IsInRange(40) then
      if not LowestUnit or FriendlyUnit:HealthPercentage() < LowestUnit:HealthPercentage() then
        LowestUnit = FriendlyUnit;
      end
    end
  end
  return LowestUnit;
end

-- Get friendly units count below health percentage.
function Commons.FriendlyUnitsBelowHealthPercentageCount(HealthPercentage)
  local Count = 0;
  local FriendlyUnits = Commons.FriendlyUnits();
  for i = 1, #FriendlyUnits do
    local FriendlyUnit = FriendlyUnits[i];
    if FriendlyUnit:Exists() and not FriendlyUnit:IsDeadOrGhost() and FriendlyUnit:IsInRange(40) then
      if FriendlyUnit:HealthPercentage() <= HealthPercentage then
        Count = Count + 1;
      end
    end
  end
  return Count;
end

-- Get dead friendly units count.
function Commons.DeadFriendlyUnitsCount()
  local Count = 0;
  local FriendlyUnits = Commons.FriendlyUnits();
  for i = 1, #FriendlyUnits do
    local FriendlyUnit = FriendlyUnits[i];
    if FriendlyUnit:IsDeadOrGhost() then
      Count = Count + 1;
    end
  end
  return Count;
end
