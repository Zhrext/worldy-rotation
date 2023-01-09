--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, WR = ...;
  -- HeroLib
  local HL = HeroLib;
  local Cache, Utils = HeroCache, HL.Utils;
  local Unit = HL.Unit;
  local Player = Unit.Player;
  local Focus = Unit.Focus;
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
-- Num/Bool helper functions
function Commons.num(val)
  if val then return 1 else return 0 end
end

function Commons.bool(val)
  return val ~= 0
end

-- Is the current target valid?
function Commons.TargetIsValid()
  return Target:Exists() and Player:CanAttack(Target) and not Target:IsDeadOrGhost();
end

-- Is the current target a valid npc healable unit?
do
  Commons.HealableNpcIDs = {};
  function Commons.TargetIsValidHealableNpc()
    return Target:Exists() and not Player:CanAttack(Target) and not Target:IsDeadOrGhost() and Utils.ValueIsInArray(Commons.HealableNpcIDs, Target:NPCID());
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
  local ExplosiveNPCID = 120651;
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
  Commons.InterruptWhitelistIDs = {
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
  Commons.StunWhitelistIDs = {
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
    if Settings.Enabled.Interrupt and Unit:IsInterruptible() and (Unit:CastPercentage() >= Settings.Threshold.Interrupt or Unit:IsChanneling()) and (not Settings.Enabled.InterruptOnlyWhitelist or Utils.ValueIsInArray(Commons.InterruptWhitelistIDs, Unit:CastSpellID()) or Utils.ValueIsInArray(Commons.InterruptWhitelistIDs, Unit:ChannelSpellID())) then
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
      if (Settings.Enabled.InterruptOnlyWhitelist and (Utils.ValueIsInArray(Commons.StunWhitelistIDs, Unit:CastSpellID()) or Utils.ValueIsInArray(Commons.StunWhitelistIDs, Unit:ChannelSpellID()))) or (not Settings.Enabled.InterruptOnlyWhitelist and Unit:CanBeStunned()) then
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

-- CycleUnit
function Commons.CastCycle(Object, Enemies, Condition, OutofRange, OffGCD, DisplayStyle, MouseoverMacro, Immovable)
  if (Immovable and Player:IsMoving()) then return false; end
  if not WR.AoEON() and Condition(Target) then
    return WR.Cast(Object, OffGCD, DisplayStyle, OutofRange);
  end
  if WR.AoEON() then
    local BestUnit, BestConditionValue = nil, nil;
    for _, CycleUnit in pairs(Enemies) do
      if not CycleUnit:IsFacingBlacklisted() and not CycleUnit:IsUserCycleBlacklisted() and Condition(CycleUnit) then
        BestUnit, BestConditionValue = CycleUnit, Condition(CycleUnit);
      end
    end
    if BestUnit then
      if BestUnit:GUID() == Target:GUID() then
        return WR.Cast(Object, OffGCD, DisplayStyle, OutofRange);
      elseif Mouseover and Mouseover:Exists() and BestUnit:GUID() == Mouseover:GUID() and MouseoverMacro then
        return WR.Press(MouseoverMacro, OutofRange, nil, OffGCD);
      end
    end
    if Condition(Target) then
      return WR.Cast(Object, OffGCD, DisplayStyle, OutofRange);
    elseif Mouseover and Mouseover:Exists() and MouseoverMacro and Condition(Mouseover) then
      return WR.Press(MouseoverMacro, OutofRange, nil, OffGCD);
    end
  end
end

-- Target If Helper
function Commons.CastTargetIf(Object, Enemies, TargetIfMode, TargetIfCondition, Condition, OutofRange, OffGCD, DisplayStyle, MouseoverMacro, Immovable)
  local TargetCondition = (not Condition or (Condition and Condition(Target)));
  if (Immovable and Player:IsMoving()) then return false; end
  if not WR.AoEON() and TargetCondition then
    return WR.Cast(Object, OffGCD, DisplayStyle, OutofRange);
  end
  if WR.AoEON() then
    local BestUnit, BestConditionValue = nil, nil;
    for _, CycleUnit in pairs(Enemies) do
      if not CycleUnit:IsFacingBlacklisted() and not CycleUnit:IsUserCycleBlacklisted() and (CycleUnit:AffectingCombat() or CycleUnit:IsDummy())
        and (not BestConditionValue or Utils.CompareThis(TargetIfMode, TargetIfCondition(CycleUnit), BestConditionValue)) then
        BestUnit, BestConditionValue = CycleUnit, TargetIfCondition(CycleUnit);
      end
    end
    if BestUnit then
      if BestUnit:GUID() == Target:GUID() and TargetCondition then
        return WR.Cast(Object, OffGCD, DisplayStyle, OutofRange);
      elseif Mouseover and Mouseover:Exists() and BestUnit:GUID() == Mouseover:GUID() and MouseoverMacro and ((Condition and Condition(Mouseover)) or not Condition) then
        return WR.Press(MouseoverMacro, OutofRange, nil, OffGCD);
      end
    end
    if TargetCondition then
      return WR.Cast(Object, OffGCD, DisplayStyle, OutofRange);
    elseif Mouseover and Mouseover:Exists() and MouseoverMacro and ((Condition and Condition(Mouseover)) or not Condition) then
      return WR.Press(MouseoverMacro, OutofRange, nil, OffGCD);
    end
  end
end

-- CC
do
  Commons.CrowdControlUnitIDs = { };
  function Commons.CrowdControl(Spell, Range, OffGCD, Unit, Macro)
    if not Unit then
      Unit = Target;
    end
    if Settings.Enabled.CrowdControl and Utils.ValueIsInArray(Commons.CrowdControlUnitIDs, Unit:NPCID()) and Unit:IsMoving() then
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
  Commons.MitigateIDs = {
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
    return Utils.ValueIsInArray(Commons.MitigateIDs, Target:CastSpellID()) or Utils.ValueIsInArray(Commons.MitigateIDs, Target:ChannelSpellID());
  end
end

-- Dispel Buffs
do
  Commons.DispellableEnrageBuffIDs = {
    Spell(390938),
    Spell(397410),
    Spell(190225),
    Spell(396018),
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
    Spell(392454),
    Spell(398151),
    Spell(386223),
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
  Commons.DispellableMagicDebuffs = {
    Spell(388392),
    Spell(391977),
    -- Manual
    --Spell(374352),
    Spell(207278),
    Spell(207981),
    Spell(372682),
    Spell(392641),
    Spell(397878),
    Spell(114803),
    Spell(395872),
    Spell(386549),
    Spell(377488),
    Spell(386025),
    Spell(384686),
    Spell(376827),
  };
  function Commons.UnitHasMagicDebuff(U)
    for i = 1, #Commons.DispellableMagicDebuffs do
      if U:DebuffUp(Commons.DispellableMagicDebuffs[i], true) then
        return true;
      end
    end
    return false;
  end

  Commons.DispellableDiseaseDebuffs = {};
  function Commons.UnitHasDiseaseDebuff(U)
    for i = 1, #Commons.DispellableDiseaseDebuffs do
      if U:DebuffUp(Commons.DispellableDiseaseDebuffs[i], true) then
        return true;
      end
    end
    return false;
  end

  Commons.DispellableCurseDebuffs = {
    Spell(387615),
  };
  function Commons.UnitHasCurseDebuff(U)
    for i = 1, #Commons.DispellableCurseDebuffs do
      if U:DebuffUp(Commons.DispellableCurseDebuffs[i], true) then
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

do
  Commons.DispellableDebuffs = {};
  -- Get dispellable friendly units.
  function Commons.DispellableFriendlyUnits()
    local FriendlyUnits = Commons.FriendlyUnits();
    local DispellableUnits = {};
    for i = 1, #FriendlyUnits do
      local DispellableUnit = FriendlyUnits[i];
      for j = 1, #Commons.DispellableDebuffs do
        if DispellableUnit:DebuffUp(Commons.DispellableDebuffs[j], true) then
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

-- Mind Control Blacklist
do
  Commons.MindControllSpells = {};
  function Commons.IsMindControlled(FriendlyUnit)
    if FriendlyUnit and FriendlyUnit:Exists() and not FriendlyUnit:IsDeadOrGhost() then
      for i = 1, #Commons.MindControllSpells do
        if FriendlyUnit:DebuffUp(Commons.MindControllSpells[i], true) then
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

-- Get friendly units with a buff.
function Commons.FriendlyUnitsWithBuffCount(Buff, OnlyTanks, OnlyNonTanks)
  local Count = 0;
  local FriendlyUnits = Commons.FriendlyUnits();
  for i = 1, #FriendlyUnits do
    local FriendlyUnit = FriendlyUnits[i];
    if FriendlyUnit:Exists() and not FriendlyUnit:IsDeadOrGhost() and (not OnlyTanks or Commons.UnitGroupRole(FriendlyUnit) == "TANK") and (not OnlyNonTanks or (not Commons.UnitGroupRole(FriendlyUnit) == "TANK")) then
      if FriendlyUnit:BuffUp(Buff) and not FriendlyUnit:BuffRefreshable(Buff) then
        Count = Count + 1;
      end
    end
  end
  return Count;
end

-- Get friendly units without a buff.
function Commons.FriendlyUnitsWithoutBuffCount(Buff, OnlyTanks, OnlyNonTanks)
  local FriendlyUnits = Commons.FriendlyUnits();
  local Count = #FriendlyUnits;
  for i = 1, #FriendlyUnits do
    local FriendlyUnit = FriendlyUnits[i];
    if FriendlyUnit:Exists() and not FriendlyUnit:IsDeadOrGhost() and (not OnlyTanks or Commons.UnitGroupRole(FriendlyUnit) == "TANK") and (not OnlyNonTanks or (not Commons.UnitGroupRole(FriendlyUnit) == "TANK")) then
      if FriendlyUnit:BuffUp(Buff) and not FriendlyUnit:BuffRefreshable(Buff) then
        Count = Count - 1;
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

-- Get Focus Unit
function Commons.GetFocusUnit(IncludeDispellableUnits)
  if Commons.TargetIsValidHealableNpc() then return Target; end
  if Commons.IsSoloMode() then return Player; end
  if IncludeDispellableUnits then
    local DispellableFriendlyUnit = Commons.DispellableFriendlyUnit();
    if DispellableFriendlyUnit then
      return DispellableFriendlyUnit;
    end
  end
  local LowestFriendlyUnit = Commons.LowestFriendlyUnit();
  if LowestFriendlyUnit then return LowestFriendlyUnit; end
end

-- Focus Unit
function Commons.FocusUnit(IncludeDispellableUnits, Macros)
  local NewFocusUnit = Commons.GetFocusUnit(IncludeDispellableUnits);
  if NewFocusUnit ~= nil and (Focus == nil or not Focus:Exists() or NewFocusUnit:GUID() ~= Focus:GUID() or not Focus:IsInRange(40)) then
    local FocusUnitKey = "Focus" .. Utils.UpperCaseFirst(NewFocusUnit:ID())
    if WR.Press(Macros[FocusUnitKey], nil, nil, true) then return "focus " .. NewFocusUnit:ID() .. " focus_unit 1"; end
  end
end

-- Settings Utils
function Commons.AreUnitsBelowHealthPercentage(SettingTable, SettingName)
  if Commons.IsSoloMode() or (Player:IsInParty() and not Player:IsInRaid()) then
    return Commons.FriendlyUnitsBelowHealthPercentageCount(SettingTable.HP[SettingName]) >= SettingTable.AoEGroup[SettingName]
  elseif Player:IsInRaid() then
    return Commons.FriendlyUnitsBelowHealthPercentageCount(SettingTable.HP[SettingName]) >= SettingTable.AoERaid[SettingName]
  end
end

-- Group Buffs
function Commons.GroupBuffMissing(spell)
  local range = 40;
  local buffIDs = { 381732, 381741, 381746, 381748, 381749, 381750, 381751, 381752, 381753, 381754, 381756, 381757, 381758 };
  if spell:Name() == "Battle Shout" then range = 100; end
  local Group;
  if UnitInRaid("player") then
    Group = Unit.Raid;
  elseif UnitInParty("player") then
    Group = Unit.Party;
  else
    return false;
  end
  for _, Char in pairs(Group) do
    if spell:Name() == "Blessing of the Bronze" then
      if Char:Exists() and Char:IsInRange(range) then
        for _, v in pairs(buffIDs) do
          if Char:BuffUp(HL.Spell(v)) then return false; end
        end
        return true;
      end
    else
      if Char:Exists() and Char:IsInRange(range) and Char:BuffDown(spell, true) then
        return true;
      end
    end
  end
  return false;
end

-- Timers
do
  Commons.Timers = {};
  function Commons.InitTimers()
    if IsAddOnLoaded("DBM-Core") then
      -- Currently unsupported.
    elseif IsAddOnLoaded("BigWigs") then
      local startTimerCallback = function(...)
        local _, _, spellId, _, duration, icon = ...;
        if spellId == nil then
          if icon == 134062 then
            spellId = "Break";
          elseif icon == 132337 then
            spellId = "Pull";
          else
            return;
          end
        end
        
        for i = 0, #Commons.Timers do
          if Commons.Timers[i] ~= nil and Commons.Timers[i].id == spellId then
            Commons.Timers[i].time = GetTime() + duration;
            return;
          end
        end
        
        local timer = {};
        timer.id = spellId;
        timer.time = GetTime() + duration;
        tableinsert(Commons.Timers, timer);
      end
      local stopTimerCallback = function(...)
        local _, _, spellId = ...;
        for i = 0, #Commons.Timers do
          if Commons.Timers[i] ~= nil and Commons.Timers[i].id == spellId then
            Commons.Timers[i] = nil;
            return;
          end
        end
      end
      local cleanupTimersCallback = function(...)
        for i = 0, #Commons.Timers do
          Commons.Timers[i] = nil;
        end
      end
      local callback = {};
      BigWigsLoader.RegisterMessage(callback, "BigWigs_StartBar", startTimerCallback);
      BigWigsLoader.RegisterMessage(callback, "BigWigs_StopBar", stopTimerCallback);
      BigWigsLoader.RegisterMessage(callback, "BigWigs_StopBars", cleanupTimersCallback);
      BigWigsLoader.RegisterMessage(callback, "BigWigs_OnBossDisable", cleanupTimersCallback);
      BigWigsLoader.RegisterMessage(callback, "BigWigs_OnPluginDisable", cleanupTimersCallback);
    end
  end
  
  function Commons.PulseTimers()
    if IsAddOnLoaded("DBM-Core") then
      -- Currently unsupported.
    elseif IsAddOnLoaded("BigWigs") then
      for i = 0, #Commons.Timers do
        if Commons.Timers[i] ~= nil then
          if Commons.Timers[i].time < GetTime() then
            Commons.Timers[i] = nil;
          end
        end
      end
    end
  end

  function Commons.GetTimer(spellId)
    for i = 0, #Commons.Timers do
      if Commons.Timers[i] ~= nil and Commons.Timers[i].id == spellId then
        local time = Commons.Timers[i].time - GetTime();
        if time < 0 then
          return nil;
        else
          return time;
        end
      end
    end
    return nil;
  end

  function Commons.GetPullTimer()
    return Commons.GetTimer("Pull");
  end
  
  function Commons.GetBreakTimer()
    return Commons.GetTimer("Break");
  end
end
