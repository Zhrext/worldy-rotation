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

  -- Find a setting recursively
  local function FindSetting(InitialKey, ...)
    local Keys = { ... }
    local SettingTable = InitialKey
    for i = 1, #Keys - 1 do
      SettingTable = SettingTable[Keys[i]]
    end
    -- Check if the final key is a string or a number (the case for table values with numeric index)
    local ParsedKey = StringToNumberIfPossible(Keys[#Keys])
    return SettingTable, ParsedKey
  end
  
  -- Filter tooltips based on Optionals input
  local function FilterTooltip(Tooltip, Optionals)
    local Tooltip = Tooltip
    if Optionals then
      if Optionals["ReloadRequired"] then
        Tooltip = Tooltip .. "\n\n|cFFFF0000This option requires a reload to take effect.|r"
      end
    end
    return Tooltip
  end
  
  -- Anchor a tooltip to a frame
  local function AnchorTooltip(Frame, Tooltip)
    Frame:SetScript("OnEnter",
      function(self)
        Mixin(GameTooltip, BackdropTemplateMixin)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:SetBackdropColor(0, 0, 0, 1)
        GameTooltip:SetText(Tooltip, nil, nil, nil, 1, true)
        GameTooltip:Show()
      end)
    Frame:SetScript("OnLeave",
      function(self)
        GameTooltip:Hide()
      end)
  end

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
  
  local LastOptionAttached = {}
  function WR.GUI.SetDropdownValues(Dropdown, Values, SelectedValue)
    local function Initialize(Self, Level)
      local Info = UIDropDownMenu_CreateInfo()
      for Key, Value in pairs(Values) do
        Info = UIDropDownMenu_CreateInfo()
        Info.text = Value
        Info.value = Value
        Info.func = UpdateSetting
        UIDropDownMenu_AddButton(Info, Level)
      end
    end
  
    UIDropDownMenu_Initialize(Dropdown, Initialize)
    UIDropDownMenu_SetSelectedValue(Dropdown, SelectedValue)
  end
  
  function WR.GUI.CreateDropdown(Parent, Setting, SavedVariablesTable, Values, Text, Tooltip, Optionals)
    -- Constructor
    local Dropdown = CreateFrame("Frame", "$parent_" .. Setting, Parent, "UIDropDownMenuTemplate")
    Parent[Setting] = Dropdown
    Dropdown.SettingTable, Dropdown.SettingKey = FindSetting(Parent.SettingsTable, strsplit(".", Setting))
    Dropdown.SavedVariablesTable, Dropdown.SavedVariablesKey = SavedVariablesTable, Setting
  
    -- Setting update
    local UpdateSetting
    if Optionals and Optionals["ReloadRequired"] then
      UpdateSetting = function(self)
        UIDropDownMenu_SetSelectedID(Dropdown, self:GetID())
        if Dropdown.SavedVariablesTable[Dropdown.SavedVariablesKey] ~= UIDropDownMenu_GetText(Dropdown) then
          Dropdown.SavedVariablesTable[Dropdown.SavedVariablesKey] = UIDropDownMenu_GetText(Dropdown)
          ReloadUI()
        end
      end
    else
      UpdateSetting = function(self)
        UIDropDownMenu_SetSelectedID(Dropdown, self:GetID())
        local SettingValue = UIDropDownMenu_GetText(Dropdown)
        Dropdown.SettingTable[Dropdown.SettingKey] = SettingValue
        Dropdown.SavedVariablesTable[Dropdown.SavedVariablesKey] = SettingValue
      end
    end
  
    -- Frame init
    if not LastOptionAttached[Parent.name] then
      Dropdown:SetPoint("TOPLEFT", 0, -30)
    else
      Dropdown:SetPoint("TOPLEFT", LastOptionAttached[Parent.name][1], "BOTTOMLEFT", LastOptionAttached[Parent.name][2] - 15, LastOptionAttached[Parent.name][3] - 20)
    end
    LastOptionAttached[Parent.name] = { Dropdown, 15, 0 }
  
    local function Initialize(Self, Level)
      local Info = UIDropDownMenu_CreateInfo()
      for Key, Value in pairs(Values) do
        Info = UIDropDownMenu_CreateInfo()
        Info.text = Value
        Info.value = Value
        Info.func = UpdateSetting
        UIDropDownMenu_AddButton(Info, Level)
      end
    end
  
    UIDropDownMenu_Initialize(Dropdown, Initialize)
    UIDropDownMenu_SetSelectedValue(Dropdown, Dropdown.SavedVariablesTable[Dropdown.SavedVariablesKey])
    UIDropDownMenu_JustifyText(Dropdown, "LEFT")
  
    local Title = Dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    Parent[Setting .. "DropdownTitle"] = Title
    Title:SetPoint("BOTTOMLEFT", Dropdown, "TOPLEFT", 20, 5)
    Title:SetJustifyH("LEFT")
    Title:SetText("|c00dfb802" .. Text .. "|r")
  
    AnchorTooltip(Dropdown, FilterTooltip(Tooltip, Optionals))
    return Dropdown
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
