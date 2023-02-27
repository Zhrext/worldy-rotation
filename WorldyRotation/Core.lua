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
  local Spell = HL.Spell;
  local Item = HL.Item;
  -- Lua
  local error = error
  local tableinsert = table.insert;
  local tableremove = table.remove;
  local mathmin = math.min;
  local mathmax = math.max;
  local pairs = pairs;
  local print = print;
  local select = select;
  local setmetatable = setmetatable
  local stringlower = string.lower;
  local strsplit = strsplit;
  local strsplittable = strsplittable;
  local tostring = tostring;
  local type = type
  -- File Locals


--- ======= GLOBALIZE =======
  -- Addon
  WorldyRotation = WR;

--- ============================ CONTENT ============================
--- ======= CORE =======
  -- Print with WR Prefix
  function WR.Print (...)
    print("[|cFFFF6600Worldy Rotation|r]", ...);
  end

  -- Defines the APL
  WR.APLs = {};
  WR.APLInits = {};
  function WR.SetAPL (Spec, APL, APLInit)
    WR.APLs[Spec] = APL;
    WR.APLInits[Spec] = APLInit;
  end

  -- Define Macro
  local function Class()
    local Class = {}
    Class.__index = Class
    setmetatable(Class, {
      __call =
      function(self, ...)
        local Object = {}
        setmetatable(Object, self)
        Object:New(...)
        return Object
      end
    })
    return Class
  end

  local Macro = Class()
  WR.Macro = Macro
  
  function Macro:New(MacroID, MacroText)
    if type(MacroID) ~= "string" then error("Invalid MacroID.") end
    if type(MacroText) ~= "string" then error("Invalid MacroText.") end
  
    -- Attributes
    self.MacroID = MacroID
    self.MacroText = MacroText
  end

--- ======= CASTS =======
  -- Main Cast
do
  local SilenceIDs = {
    377004,
    397892,
    196543,
    381516,
  };
  local QuakingDebuffId = Spell(240447);
  local PoolResource = 999910;
  local SpellQueueWindow = tonumber(C_CVar.GetCVar("SpellQueueWindow"));
  function WR.Press(Object, OutofRange, Immovable, OffGCD)
    local SpellID = Object.SpellID;
    local ItemID = Object.ItemID;
    local MacroID = Object.MacroID;
    local Usable = MacroID or Object:IsUsable();
    local ShowPooling = Object.SpellID == PoolResource;
    local TargetIsCastingSilence = Target:Exists() and Utils.ValueIsInArray(SilenceIDs, Target:CastSpellID());
    if ShowPooling then
      WR.MainFrame:ChangeBind(nil);
      Object.LastDisplayTime = GetTime();
      return true;
    end
    
    local PrecastWindow = mathmin(mathmax(SpellQueueWindow - HL.Latency(), 75), 150);
    if not Usable or OutofRange or (Immovable and (Player:IsMoving() or Player:DebuffUp(QuakingDebuffId, true) or TargetIsCastingSilence)) or (not OffGCD and (Player:CastEnd() - PrecastWindow > 0 or Player:GCDRemains() - PrecastWindow > 0)) then
      WR.MainFrame:ChangeBind(nil);
      Object.LastDisplayTime = GetTime();
      return false;
    end

    local Bind;
    if SpellID then
      Bind = WR.SpellBinds[SpellID];
      if not Bind then
        WR.Print(Object:Name() .. " is not bound.");
      end
    elseif ItemID then
      Bind = WR.ItemBinds[ItemID];
      if not Bind then
        WR.Print(Object:Name() .. " is not bound.");
      end
    elseif MacroID then
      Bind = WR.MacroBinds[MacroID];
      if not Bind then
        WR.Print(Object.MacroID .. " is not bound.");
      end
    end

    WR.MainFrame:ChangeBind(Bind);
    Object.LastDisplayTime = GetTime();
    return true;
  end
  function WR.Cast(Object, OffGCD, DisplayStyle, OutofRange, CustomTime)
    return WR.Press(Object, OutofRange, nil, OffGCD);
  end
  function WR.CastAnnotated(Object, OffGCD, Text)
    return WR.Press(Object, nil, nil, OffGCD);
  end
  function WR.CastPooling(Object, CustomTime, OutofRange)
    return WR.Press(Object, OutofRange);
  end
  function WR.CastSuggested(Object, OutofRange)
    return WR.Press(Object, OutofRange);
  end
end

--- ======= BINDS =======
  -- Main Bind
  do
    local CommonKeys = {
      "1", "2", "3", "4", "5", "6", "J", "K", "L"
    };
    local UncommonKeys = {
      "F1", "F2", "F3", "F4", "F5", "F6",
      "Numpad 0", "Numpad 1", "Numpad 2", "Numpad 3", "Numpad 4", "Numpad 5", "Numpad 6", "Numpad 7", "Numpad 8", "Numpad 9", "Numpad +", "Numpad -",
      "[", "]", "\\", ";", "'", "`", ",", ".", "/"
    };
    local RareKeys = {
      "7", "8", "9", "0", "-", "=",
      "F7", "F8", "F9", "F10", "F11", "F12"
    };
    local ModifierKeys = {
      "SHIFT:", "CTRL:", "ALT:"
    };
    local ModifierKeyCombs = {
      "CTRL:SHIFT:", "ALT:SHIFT:"
    };
    WR.SpellBinds = {};
    WR.ItemBinds = {};
    WR.MacroBinds = {};
    WR.SpellObjects = {};
    WR.ItemObjects = {};
    WR.MacroObjects = {};
    WR.FreeBinds = {};
    WR.SetupFreeBinds = true;
    HL:RegisterForEvent(function()
      WR.Rebind();
    end, "ACTIVE_PLAYER_SPECIALIZATION_CHANGED");
    function WR.Bind (Object)
      if WR.SetupFreeBinds then
        WR.AddFreeBinds(CommonKeys);
        WR.AddFreeBinds(UncommonKeys);
        WR.AddFreeBinds(RareKeys);
        WR.SetupFreeBinds = false;
      end
      if Object.SpellTable ~= nil then
        for i, Spell in pairs(Object.SpellTable) do
          WR.Bind(Spell);
        end
        return;
      end
      local Bind = WR.FreeBinds[#WR.FreeBinds];
      tableremove(WR.FreeBinds, #WR.FreeBinds);
      WR.Unbind(Bind);
      local SpellID = Object.SpellID;
      local ItemID = Object.ItemID;
      local MacroID = Object.MacroID;
      if SpellID then
        SetBindingSpell(Bind:gsub(":", "-"), Object:Name());
        WR.SpellBinds[SpellID] = Bind;
        WR.SpellObjects[SpellID] = Object;
      elseif ItemID then
        SetBindingItem(Bind:gsub(":", "-"), Object:Name());
        WR.ItemBinds[ItemID] = Bind;
        WR.ItemObjects[ItemID] = Object;
      elseif MacroID then
        WR.MainFrame:AddMacroFrame(Object);
        SetBindingClick(Bind:gsub(":", "-"), MacroID);
        WR.MacroBinds[MacroID] = Bind;
        WR.MacroObjects[MacroID] = Object;
      end
    end
    function WR.Unbind (Key)
      local NumBindings = GetNumBindings();
      for i = 1, NumBindings do
        local Key1, Key2 = GetBindingKey(GetBinding(i));
        if Key1 == Key or Key2 == Key then
          SetBinding(Key);
        end
      end
    end
    function WR.AddFreeBinds (Keys)
      for i = 1, #Keys do
        tableinsert(WR.FreeBinds, Keys[i]);
        for j = 1, #ModifierKeys do
          tableinsert(WR.FreeBinds, ModifierKeys[j] .. Keys[i]);
        end
        for j = 1, #ModifierKeyCombs do
          tableinsert(WR.FreeBinds, ModifierKeyCombs[j] .. Keys[i]);
        end
      end
    end
    function WR.Rebind ()
      WR.FreeBinds = {};
      WR.SetupFreeBinds = true;
      for Id, _ in pairs(WR.SpellBinds) do
        WR.Bind(WR.SpellObjects[Id]);
      end
      for Id, _ in pairs(WR.ItemBinds) do
        WR.Bind(WR.ItemObjects[Id]);
      end
      for Id, _ in pairs(WR.MacroBinds) do
        WR.Bind(WR.MacroObjects[Id]);
      end
    end
  end

--- ======= COMMANDS =======
  -- Command Handler
  function WR.CmdHandler (Message)
    local Argument, Argument1 = strsplit(" ", Message);
    local ArgumentLower = stringlower(Argument);
    for k, v in pairs(WR.Toggles) do
      local Toggle = k;
      local Index = v;
      if ArgumentLower == Toggle then
        WorldyRotationCharDB.Toggles[Index] = not WorldyRotationCharDB.Toggles[Index];
        WR.Print("WorldyRotation: " .. Toggle .. " is now "..(WorldyRotationCharDB.Toggles[Index] and "|cff00ff00enabled|r." or "|cffff0000disabled|r."));
        WR.ToggleFrame:UpdateButtonText(Index);
        if ArgumentLower == "toggle" then
          WR.MainFrame:ChangePixel(1, WR.ON());
        end
        return;
      end
    end
    if ArgumentLower == "lock" then
      WR.ToggleFrame:ToggleLock();
    elseif ArgumentLower == "break" then
      WR.Break();
    elseif ArgumentLower == "cast" and Argument1 then
      local Bind = WR.SpellBinds[tonumber(Argument1)];
      WR.MainFrame:ChangeBind(Bind);
      WR.Timer.Pulse = GetTime() + 0.150;
    elseif ArgumentLower == "use" and Argument1 then
      local Bind = WR.ItemBinds[tonumber(Argument1)];
      WR.MainFrame:ChangeBind(Bind);
      WR.Timer.Pulse = GetTime() + 0.150;
    elseif ArgumentLower == "macro" and Argument1 then
      local Bind = WR.MacroBinds[tostring(Argument1)];
      WR.MainFrame:ChangeBind(Bind);
      WR.Timer.Pulse = GetTime() + 0.150;
    elseif ArgumentLower == "help" then
      WR.Print("|cffffff00--[Toggles]--|r");
      WR.Print("  On/Off: |cff8888ff/wr toggle|r");
      WR.Print("  CDs: |cff8888ff/wr cds|r");
      WR.Print("  AoE: |cff8888ff/wr aoe|r");
      WR.Print("  Un-/Lock: |cff8888ff/wr lock|r");
      WR.Print("  Break: |cff8888ff/wr break|r");
      WR.Print("  Cast: |cff8888ff/wr cast <SpellID>|r");
      WR.Print("  Use: |cff8888ff/wr use <ItemID>|r");
      WR.Print("  Macro: |cff8888ff/wr macro <MacroID>|r");
    else
      WR.Print("Invalid arguments.");
      WR.Print("Type |cff8888ff/wr help|r for more infos.");
    end
  end
  SLASH_WORLDYROTATION1 = "/wr"
  SlashCmdList["WORLDYROTATION"] = WR.CmdHandler;

  -- Add a toggle
  function WR.AddToggle(Toggle)
    table.insert(WR.Toggles, Toggle);
  end

  -- Get if the main toggle is on.
  function WR.ON ()
    return WorldyRotationCharDB.Toggles[1];
  end
  
  function WR.Toggle (Index)
   return WorldyRotationCharDB.Toggles[Index];
  end

  -- Get if the CDs are enabled.
  function WR.CDsON ()
    return WorldyRotationCharDB.Toggles[2];
  end

  -- Get if the AoE is enabled.
  do
    local AoEImmuneNPCID = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Mythic+ Affixes
          -- Fel Explosives (7.2 Patch)
          [120651] = true
    }
    -- Disable the AoE if we target an unit that is immune to AoE spells.
    function WR.AoEON ()
      return WorldyRotationCharDB.Toggles[3] and not AoEImmuneNPCID[Target:NPCID()];
    end
  end

  -- Get bind info.
  do
    local KeyCode = {
      ["1"] = 2,
      ["2"] = 3,
      ["3"] = 4,
      ["4"] = 5,
      ["5"] = 6,
      ["6"] = 7,
      ["7"] = 8,
      ["8"] = 9,
      ["9"] = 10,
      ["0"] = 11,
      ["-"] = 12,
      ["="] = 13,
      ["Q"] = 16,
      ["W"] = 17,
      ["E"] = 18,
      ["R"] = 19,
      ["T"] = 20,
      ["Y"] = 21,
      ["U"] = 22,
      ["I"] = 23,
      ["O"] = 24,
      ["P"] = 25,
      ["["] = 26,
      ["]"] = 27,
      ["CTRL"] = 29,
      ["A"] = 30,
      ["S"] = 31,
      ["D"] = 32,
      ["F"] = 33,
      ["G"] = 34,
      ["H"] = 35,
      ["J"] = 36,
      ["K"] = 37,
      ["L"] = 38,
      [";"] = 39,
      ["'"] = 40,
      ["`"] = 41,
      ["SHIFT"] = 42,
      ["\\"] = 43,
      ["Z"] = 44,
      ["X"] = 45,
      ["C"] = 46,
      ["V"] = 47,
      ["B"] = 48,
      ["N"] = 49,
      ["M"] = 50,
      [","] = 51,
      ["."] = 52,
      ["/"] = 53,
      ["Numpad /"] = 53,
      ["Numpad *"] = 55,
      ["ALT"] = 56,
      [" "] = 57,
      ["F1"] = 59,
      ["F2"] = 60,
      ["F3"] = 61,
      ["F4"] = 62,
      ["F5"] = 63,
      ["F6"] = 64,
      ["F7"] = 65,
      ["F8"] = 66,
      ["F9"] = 67,
      ["F10"] = 68,
      ["Numpad 7"] = 71,
      ["Numpad 8"] = 72,
      ["Numpad 9"] = 73,
      ["Numpad 9"] = 73,
      ["Numpad -"] = 74,
      ["Numpad 4"] = 75,
      ["Numpad 5"] = 76,
      ["Numpad 6"] = 77,
      ["Numpad +"] = 78,
      ["Numpad 1"] = 79,
      ["Numpad 2"] = 80,
      ["Numpad 3"] = 81,
      ["Numpad 0"] = 82,
      ["F11"] = 87,
      ["F12"] = 88,
    }
    function WR.GetBindInfo(Bind)
      local Key, Mod1, Mod2;
      if Bind ~= nil then
        local BindParts = strsplittable(":", Bind);
        if #BindParts == 1 then
          Key = BindParts[1];
        elseif #BindParts == 2 then
          Mod1 = BindParts[1];
          Key = BindParts[2];
        elseif #BindParts == 3 then
          Mod1 = BindParts[1];
          Mod2 = BindParts[2];
          Key = BindParts[3];
        end
      end
      local BindEx = {};
      if Key then
        BindEx.Key = KeyCode[tostring(Key)];
      end
      if Mod1 then
        BindEx.Mod1 = KeyCode[tostring(Mod1)];
      end
      if Mod2 then
        BindEx.Mod2 = KeyCode[tostring(Mod2)];
      end
      return BindEx;
    end
  end
