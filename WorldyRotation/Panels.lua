--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, WR = ...;
  -- HeroLib
  local HL = HeroLib;
  local Utils = HL.Utils;
  -- Lua
  local stringformat = string.format;
  local stringgmatch = string.gmatch;
  local strsplit = strsplit;
  local tableconcat = table.concat;
  -- File Locals
  local CreatePanelOption = HL.GUI.CreatePanelOption;
  local StringToNumberIfPossible = Utils.StringToNumberIfPossible;


--- ============================ CONTENT ============================
  WR.GUI = {};

  function WR.GUI.LoadSettingsRecursively (Table, KeyChain)
    local KeyChain = KeyChain or "";
    for Key, Value in pairs(Table) do
      -- Generate the NewKeyChain
      local NewKeyChain;
      if KeyChain ~= "" then
        NewKeyChain = KeyChain .. "." .. Key;
      else
        NewKeyChain = Key;
      end
      -- Continue the table browsing
      if type(Value) == "table" then
        WR.GUI.LoadSettingsRecursively(Value, NewKeyChain);
      -- Update the value
      else
        -- Check if the final key is a string or a number (the case for table values with numeric index)
        local ParsedKey = StringToNumberIfPossible(Key);
        -- Load the saved value
        local DBSetting = WorldyRotationDB.GUISettings[NewKeyChain];
        -- If the saved value exists, take it
        if DBSetting ~= nil then
          Table[ParsedKey] = DBSetting;
        -- Else, save the default value
        else
          WorldyRotationDB.GUISettings[NewKeyChain] = Value;
        end
      end
    end
  end

  do
    local CreateARPanelOption = {
      Enabled = function (Panel, Setting, Name)
        CreatePanelOption("CheckButton", Panel, Setting, "Use: " .. Name, "Enable if you want to use " .. Name .. ".");
      end,
      Threshold = function(Panel, Setting, Name)
        CreatePanelOption("Slider", Panel, Setting, {0, 100, 1}, "Threshold: " .. Name, "Set the threshold of " .. Name .. ". Set to 0 to disable.");
      end,
      HP = function(Panel, Setting, Name)
        CreatePanelOption("Slider", Panel, Setting, {0, 100, 1}, "HP: " .. Name, "Set the HP threshold of " .. Name .. ". Set to 0 to disable.");
      end,
      AoE = function(Panel, Setting, Name)
        CreatePanelOption("Slider", Panel, Setting, {0, 5, 1}, "AoE: " .. Name, "Set the AoE count of " .. Name .. ". Set to 0 to disable.");
      end,
      AoEGroup = function(Panel, Setting, Name)
        CreatePanelOption("Slider", Panel, Setting, {1, 5, 1}, "Group: " .. Name, "Set the AoE group count of " .. Name .. ".");
      end,
      AoERaid = function(Panel, Setting, Name)
        CreatePanelOption("Slider", Panel, Setting, {1, 20, 1}, "Raid: " .. Name, "Set the AoE raid count of " .. Name .. ".");
      end,
    };
    function WR.GUI.CreateARPanelOption (Type, Panel, Setting, ...)
      CreateARPanelOption[Type](Panel, Setting, ...);
    end

    function WR.GUI.CreateARPanelOptions (Panel, Settings)
      -- Find the corresponding setting table
      local SettingsSplit = {strsplit(".", Settings)};
      local SettingsTable = WR.GUISettings;
      for i = 1, #SettingsSplit do
        SettingsTable = SettingsTable[SettingsSplit[i]];
      end
      -- Iterate over all options available
      for Type, _ in pairs(CreateARPanelOption) do
        SettingsType = SettingsTable[Type];
        if SettingsType then
          for SettingName, _ in pairs(SettingsType) do
            -- Split the key on uppercase matches
            local Name = "";
            for Word in stringgmatch(SettingName, "[A-Z][a-z]+") do
              if Name == "" then
                Name = Word;
              else
                Name = Name .. " " .. Word;
              end
            end
            -- Rewrite the setting string
            local Setting = tableconcat({Settings, Type, SettingName}, ".");
            -- Construct the option
            WR.GUI.CreateARPanelOption(Type, Panel, Setting, Name);
          end
        end
      end
    end
  end
