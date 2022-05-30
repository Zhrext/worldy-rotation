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
  local mathmin = math.min;
  local print = print;
  local select = select;
  local stringlower = string.lower;
  local strsplit = strsplit;
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
    -- TODO(Worldy): Extend this section with auto bind behavior.
    local KeybindAction = nil;
    local Keybind = nil;
    local SpellID = Object.SpellID;
    if SpellID then
      KeybindAction = HL.Action.FindBySpellID(SpellID);
      if KeybindAction then
        Keybind = KeybindAction.HotKey;
      end
    end
    local ItemID = Object.ItemID;
    if ItemID then
      KeybindAction = HL.Action.FindByItemID(ItemID);
      if KeybindAction then
        Keybind = KeybindAction.HotKey;
      end
    end
    
    local PoolResource = 999910
    local Usable = Object:IsUsable();
    local ShowPooling = Object.SpellID == PoolResource

    if ShowPooling or not Usable or OutofRange or (Immovable and Player:IsMoving()) then
      WR.MainFrame:ChangeKeybind(nil);
    else
      WR.MainFrame:ChangeKeybind(Keybind);
    end
    
    Object.LastDisplayTime = GetTime();
    return true;
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

  -- Get keybind info.
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
      ["N/"] = 53,
      ["N*"] = 55,
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
      ["N7"] = 71,
      ["N8"] = 72,
      ["N9"] = 73,
      ["N9"] = 73,
      ["N-"] = 74,
      ["N4"] = 75,
      ["N5"] = 76,
      ["N6"] = 77,
      ["N+"] = 78,
      ["N1"] = 79,
      ["N2"] = 80,
      ["N3"] = 81,
      ["N0"] = 82,
      ["F11"] = 87,
      ["F12"] = 88,
    }
    function WR.GetKeybindInfo(keybind)
      local key, mod1, mod2;
      if keybind ~= nil then
        for i = 1, #keybind do
          local isEnd = i == #keybind;
          local c = keybind:sub(i, i);
          if isEnd then
            key = c;
          else
            if c == "A" then
              mod1 = "ALT";
            elseif c == "C" then
              mod1 = "CTRL";
            elseif c == "S" then
              mod2 = "SHIFT";
            elseif c == "M" then
              WR.Print("Keybind '" .. keybind .. "' is not supported.");
            elseif c == "N" or c == "F" then
              key = c .. keybind:sub(i+1, i+1);
              break;
            end
          end
        end
      end
      local bind = {};
      if key then
        bind.key = KeyCode[tostring(key)];
      end
      if mod1 then
        bind.mod1 = KeyCode[tostring(mod1)];
      end
      if mod2 then
        bind.mod2 = KeyCode[tostring(mod2)];
      end
      return bind;
    end
  end
