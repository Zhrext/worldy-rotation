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
  local Mouseover = Unit.MouseOver;
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
  local HealableNpcIDs = { };
  function Commons.TargetIsValidHealableNpc()
    return Target:Exists() and not Player:CanAttack(Target) and not Target:IsDeadOrGhost() and Utils.ValueIsInArray(HealableNpcIDs, Target:NPCID());
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

-- Explosive
do
  local ExplosiveNPCID = 120651
  function Commons.HandleExplosive(Spell, Macro)
    if Target:NPCID() == ExplosiveNPCID and Spell:IsReady() then
      if WR.Press(Spell, not Target:IsSpellInRange(Spell)) then return "Handle Explosive"; end
    end
    if Macro then
      if Mouseover and Mouseover:NPCID() == ExplosiveNPCID and Spell:IsReady() then
        if WR.Press(Macro, not Mouseover:IsSpellInRange(Spell)) then return "Handle Explosive Mouseover"; end
      end
    end
  end
end

-- Interrupt
do
  local InterruptWhitelistIDs = {
    396812,
    388392,
    388863,
    377389,
    396640,
    387843,
    209413,
    207980,
    208165,
    198595,
    198959,
    215433,
    199726,
    198750,
    373017,
    392451,
    385310,
    152818,
    -- 154327, -- Domination Manual Interrupt
    156776,
    156722,
    398206,
    156718,
    153524,
    397888,
    397889,
    395859,
    396073,
    397914,
    387564,
    375602,
    386546,
    377488,
    373932,
    384365,
    386024,
    387411,
    387606,
    384808,
    373395,
    376725,
  };
  local StunWhitelistIDs = {
    210261,
    372749,
    372735,
    370225,
    386526,
    384476,
    383823,
    386490,
    387615,
    382077,
  };
  function Commons.Interrupt(Spell, Range, OffGCD, Unit, Macro)
    if not Unit then
      Unit = Target;
    end
    if Settings.Enabled.Interrupt and Unit:IsInterruptible() and (Unit:CastPercentage() >= Settings.Threshold.Interrupt or Unit:IsChanneling()) and (not Settings.Enabled.InterruptOnlyWhitelist or Utils.ValueIsInArray(InterruptWhitelistIDs, Unit:CastSpellID()) or Utils.ValueIsInArray(InterruptWhitelistIDs, Unit:ChannelSpellID())) then
      if Spell:IsCastable() then
        if Macro then
          if WR.Press(Macro, not Unit:IsInRange(Range), nil, OffGCD) then return "Cast " .. Spell:Name() .. " (Interrupt)"; end
        else
          if WR.Press(Spell, not Unit:IsInRange(Range), nil, OffGCD) then return "Cast " .. Spell:Name() .. " (Interrupt)"; end
        end
      end
    end
  end
  function Commons.InterruptWithStun(Spell, Range, OffGCD, Unit, Macro)
    if not Unit then
      Unit = Target;
    end
    if Settings.Enabled.InterruptWithStun and (Unit:CastPercentage() >= Settings.Threshold.Interrupt or Unit:IsChanneling()) then
      if (Settings.Enabled.InterruptOnlyWhitelist and (Utils.ValueIsInArray(StunWhitelistIDs, Unit:CastSpellID()) or Utils.ValueIsInArray(StunWhitelistIDs, Unit:ChannelSpellID()))) or (not Settings.Enabled.InterruptOnlyWhitelist and Unit:CanBeStunned()) then
        if Spell:IsCastable() then
          if Macro then
            if WR.Press(Macro, not Unit:IsInRange(Range), nil, OffGCD) then return "Cast " .. Spell:Name() .. " (Interrupt With Stun)"; end
          else
            if WR.Press(Spell, not Unit:IsInRange(Range), nil, OffGCD) then return "Cast " .. Spell:Name() .. " (Interrupt With Stun)"; end
          end
        end
      end
    end
  end
end

-- Target If Helper
function Commons.CastTargetIf(Object, Enemies, TargetIfMode, TargetIfCondition, Condition, OutofRange, OffGCD, DisplayStyle, MouseoverMacro, Immovable)
  local TargetCondition = (not Condition or (Condition and Condition(Target)))
  if (Immovable and Player:IsMoving()) then return false; end
  if not WR.AoEON() and TargetCondition then
    return WR.Cast(Object, OffGCD, DisplayStyle, OutofRange);
  end
  if WR.AoEON() then
    local BestUnit, BestConditionValue = nil, nil
    for _, CycleUnit in pairs(Enemies) do
      if not CycleUnit:IsFacingBlacklisted() and not CycleUnit:IsUserCycleBlacklisted() and (CycleUnit:AffectingCombat() or CycleUnit:IsDummy())
        and (not BestConditionValue or Utils.CompareThis(TargetIfMode, TargetIfCondition(CycleUnit), BestConditionValue)) then
        BestUnit, BestConditionValue = CycleUnit, TargetIfCondition(CycleUnit);
      end
    end
    if BestUnit then
      if BestUnit:GUID() == Target:GUID() and TargetCondition then
        return WR.Cast(Object, OffGCD, DisplayStyle, OutofRange);
      elseif BestUnit:GUID() == Mouseover:GUID() and MouseoverMacro and ((Condition and Condition(Mouseover)) or not Condition) then
        return WR.Press(MouseoverMacro, OutofRange, nil, OffGCD);
      end
    end
    if TargetCondition then
      return WR.Cast(Object, OffGCD, DisplayStyle, OutofRange);
    elseif MouseoverMacro and ((Condition and Condition(Mouseover)) or not Condition) then
      return WR.Press(MouseoverMacro, OutofRange, nil, OffGCD);
    end
  end
end

-- CC
do
  local CrowdControlUnitIDs = { };
  function Commons.CrowdControl(Spell, Range, OffGCD, Unit, Macro)
    if not Unit then
      Unit = Target;
    end
    if Settings.Enabled.CrowdControl and Utils.ValueIsInArray(CrowdControlUnitIDs, Unit:NPCID()) and Unit:IsMoving() then
      if Spell:IsCastable() then
        if Macro then
          if WR.Press(Macro, not Unit:IsInRange(Range), nil, OffGCD) then return "Cast " .. Spell:Name() .. " (Crowd Control)"; end
        else
          if WR.Press(Spell, not Unit:IsInRange(Range), nil, OffGCD) then return "Cast " .. Spell:Name() .. " (Crowd Control)"; end
        end
      end
    end
  end
end

-- Mitigate
do
  local MitigateIDs = {
    388911,
    193092,
    193668,
    381514,
    396019,
    397904,
    106823,
    106841,
    389804,
    377105,
    384978,
    384686,
    382836,
  };
  function Commons.ShouldMitigate()
    return Utils.ValueIsInArray(MitigateIDs, Target:CastSpellID()) or Utils.ValueIsInArray(MitigateIDs, Target:ChannelSpellID());
  end
end

-- Dispel Buffs
do
  Commons.DispellableEnrageBuffIDs = {
    390938,
    397410,
    190225,
    396018,
  };
  function Commons.UnitHasEnrageBuff(U)
    for i = 1, #Commons.DispellableEnrageBuffIDs do
      if U:BuffUp(Commons.DispellableEnrageBuffIDs[i], true) then
        return true;
      end
    end
    return false;
  end

  Commons.DispellableMagicBuffIDs = {
    392454,
    398151,
    386223,
  };
  function Commons.UnitHasMagicBuff(U)
    for i = 1, #Commons.DispellableMagicBuffIDs do
      if U:BuffUp(Commons.DispellableMagicBuffIDs[i], true) then
        return true;
      end
    end
    return false;
  end
end

-- Dispel Debuffs
do
  Commons.DispellableMagicDebuffIDs = {};
  function Commons.UnitHasMagicDebuff(U)
    for i = 1, #Commons.DispellableMagicDebuffIDs do
      if U:DebuffUp(Commons.DispellableMagicDebuffIDs[i], true) then
        return true;
      end
    end
    return false;
  end

  Commons.DispellableDiseaseDebuffIDs = {};
  function Commons.UnitHasDiseaseDebuff(U)
    for i = 1, #Commons.DispellableDiseaseDebuffIDs do
      if U:DebuffUp(Commons.DispellableDiseaseDebuffIDs[i], true) then
        return true;
      end
    end
    return false;
  end

  Commons.DispellableCurseDebuffIDs = {};
  function Commons.UnitHasCurseDebuff(U)
    for i = 1, #Commons.DispellableCurseDebuffIDs do
      if U:DebuffUp(Commons.DispellableCurseDebuffIDs[i], true) then
        return true;
      end
    end
    return false;
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
function Commons.DispellableFriendlyUnits(DispellableDebuffs)
  local FriendlyUnits = Commons.FriendlyUnits();
  local DispellableUnits = {};
  for i = 1, #FriendlyUnits do
    local DispellableUnit = FriendlyUnits[i];
    for j = 1, #DispellableDebuffs do
      if DispellableUnit:DebuffUp(DispellableDebuffs[j], true) then
        tableinsert(DispellableUnits, DispellableUnit);
      end
    end
  end
  return DispellableUnits;
end
function Commons.DispellableFriendlyUnit(DispellableDebuffs)
  local DispellableFriendlyUnits = Commons.DispellableFriendlyUnits(DispellableDebuffs);
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

-- Get assigned unit role.
function Commons.UnitGroupRole(GroupUnit)
  if GroupUnit:IsAPlayer() then
    return UnitGroupRolesAssigned(GroupUnit:ID());
  end
end

-- Mind Control Blacklist
do
  local MindControllSpells = { };
  function Commons.IsMindControlled(FriendlyUnit)
    if FriendlyUnit and FriendlyUnit:Exists() and not FriendlyUnit:IsDeadOrGhost() then
      for i = 1, #MindControllSpells do
        if FriendlyUnit:DebuffUp(MindControllSpells[i], true) then
          return true;
        end
      end
    end
    return false;
  end
end


-- Get lowest friendly unit.
function Commons.LowestFriendlyUnit()
  local LowestUnit;
  local FriendlyUnits = Commons.FriendlyUnits();
  for i = 1, #FriendlyUnits do
    local FriendlyUnit = FriendlyUnits[i];
    if FriendlyUnit and FriendlyUnit:Exists() and not FriendlyUnit:IsDeadOrGhost() and FriendlyUnit:IsInRange(40) and not Commons.IsMindControlled(FriendlyUnit) then
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
