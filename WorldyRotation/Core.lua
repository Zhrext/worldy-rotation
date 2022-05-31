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
  local tableinsert = table.insert;
  local tableremove = table.remove;
  local mathmin = math.min;
  local print = print;
  local select = select;
  local stringlower = string.lower;
  local strsplit = strsplit;
  local strsplittable = strsplittable;
  local tostring = tostring;
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

--- ======= CASTS =======
  -- Main Cast
  WR.CastOffGCDOffset = 1;
  function WR.Cast (Object, OutofRange, Immovable)
    local Bind = nil;
    local SpellID = Object.SpellID;
    local ItemID = Object.ItemID;
    local MacroID = Object.MacroID;
    if SpellID then
      Bind = WR.SpellBinds[SpellID];
    elseif ItemID then
      Bind = WR.ItemBinds[ItemID];
    elseif MacroID then
      Bind = WR.MacroBinds[MacroID];
    end
    
    local PoolResource = 999910
    local Usable = MacroID or Object:IsUsable();
    local ShowPooling = Object.SpellID == PoolResource

    if ShowPooling or not Usable or OutofRange or (Immovable and Player:IsMoving()) then
      WR.MainFrame:ChangeBind(nil);
    else
      WR.MainFrame:ChangeBind(Bind);
    end
    
    Object.LastDisplayTime = GetTime();
    return true;
  end

--- ======= BINDS =======
  -- Main Bind
  do
    WR.SpellBinds = {};
    WR.ItemBinds = {};
    WR.MacroBinds = {};
    local FreeBinds = {};
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
    local SetupKeys = true;
    function WR.Bind (Object)
      if SetupKeys then
        WR.AddFreeBinds(CommonKeys);
        WR.AddFreeBinds(UncommonKeys);
        WR.AddFreeBinds(RareKeys);
        SetupKeys = false;
      end
      local Bind = FreeBinds[#FreeBinds];
      tableremove(FreeBinds, #FreeBinds);
      WR.Unbind(Bind);
      local SpellID = Object.SpellID;
      local ItemID = Object.ItemID;
      local MacroID = Object.MacroID;
      if SpellID then
        SetBindingSpell(Bind:gsub(":", "-"), Object:Name());
        WR.SpellBinds[SpellID] = Bind;
      elseif ItemID then
        SetBindingItem(Bind:gsub(":", "-"), Object:Name());
        WR.ItemBinds[ItemID] = Bind;
      elseif MacroID then
        WR.MainFrame:AddMacroFrame(Object);
        SetBindingClick(Bind:gsub(":", "-"), MacroID);
        WR.MacroBinds[MacroID] = Bind;
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
        tableinsert(FreeBinds, Keys[i]);
        for j = 1, #ModifierKeys do
          tableinsert(FreeBinds, ModifierKeys[j] .. Keys[i]);
        end
        for j = 1, #ModifierKeyCombs do
          tableinsert(FreeBinds, ModifierKeyCombs[j] .. Keys[i]);
        end
      end
    end
  end

--- ======= COMMANDS =======
  -- Command Handler
  function WR.CmdHandler (Message)
    local Argument = strsplit(" ", stringlower(Message));
    if Argument == "toggle" then
      WorldyRotationCharDB.Toggles[1] = not WorldyRotationCharDB.Toggles[1];
      WR.Print("WorldyRotation is now "..(WorldyRotationCharDB.Toggles[1] and "|cff00ff00enabled|r." or "|cffff0000disabled|r."));
      WR.MainFrame:ChangePixel(1, WR.ON());
    elseif Argument == "cds" then
      WorldyRotationCharDB.Toggles[2] = not WorldyRotationCharDB.Toggles[2];
      WR.Print("CDs are now "..(WorldyRotationCharDB.Toggles[2] and "|cff00ff00enabled|r." or "|cffff0000disabled|r."));
    elseif Argument == "aoe" then
      WorldyRotationCharDB.Toggles[3] = not WorldyRotationCharDB.Toggles[3];
      WR.Print("AoE is now "..(WorldyRotationCharDB.Toggles[3] and "|cff00ff00enabled|r." or "|cffff0000disabled|r."));
    elseif Argument == "help" then
      WR.Print("|cffffff00--[Toggles]--|r");
      WR.Print("  On/Off: |cff8888ff/wr toggle|r");
      WR.Print("  CDs: |cff8888ff/wr cds|r");
      WR.Print("  AoE: |cff8888ff/wr aoe|r");
    else
      WR.Print("Invalid arguments.");
      WR.Print("Type |cff8888ff/wr help|r for more infos.");
    end
  end
  SLASH_WORLDYROTATION1 = "/wr"
  SlashCmdList["WORLDYROTATION"] = WR.CmdHandler;

  -- Get if the main toggle is on.
  function WR.ON ()
    return WorldyRotationCharDB.Toggles[1];
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
