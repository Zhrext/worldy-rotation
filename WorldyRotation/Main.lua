--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, WR = ...;
  -- HeroLib
  local HL = HeroLib;
  local Cache = HeroCache;
  local Unit = HL.Unit;
  local Player = Unit.Player;
  local Target = Unit.Target;
  local Spell = HL.Spell;
  local Item = HL.Item;
  local GUI = HL.GUI;
  local CreatePanelOption = GUI.CreatePanelOption;

  -- Lua
  local mathmax = math.max;
  local mathmin = math.min;
  local pairs = pairs;
  local select = select;
  local tonumber = tonumber;
  local type = type;
  -- File Locals
  local PrevResult, CurrResult;

--- ============================ CONTENT ============================
--- ======= BINDINGS =======
  BINDING_HEADER_WORLDYROTATION = "WorldyRotation";
  BINDING_NAME_WORLDYROTATION_TOGGLE = "Toggle On/Off";
  BINDING_NAME_WORLDYROTATION_CDS = "Toggle CDs";
  BINDING_NAME_WORLDYROTATION_AOE = "Toggle AoE";

--- ======= MAIN FRAME =======
  WR.MainFrame = CreateFrame("Frame", "WorldyRotation_MainFrame", UIParent);
  WR.MainFrame:SetFrameStrata(WR.GUISettings.General.MainFrameStrata);
  WR.MainFrame:SetFrameLevel(10);
  WR.MainFrame:SetSize(5, 1); -- 1 Validation | 2 Toggle | 3 Cds | 4 AoE | 5 Keybind
  WR.MainFrame:SetPoint("TOPLEFT", 0, 0);
  WR.MainFrame:SetIgnoreParentAlpha(true);
  WR.MainFrame:SetIgnoreParentScale(true);
  WR.MainFrame:SetClampedToScreen(true);
  WR.MainFrame.t = {};

  function WR.MainFrame:Resize ()
    local _, screenHeight = GetPhysicalScreenSize()
    local scaleFactor = 768 / screenHeight
    if self:GetScale() ~= scaleFactor then
      self:SetScale(scaleFactor)
    end
  end

  function WR.MainFrame:CreatePixelTexture (pixel)
    WR.MainFrame.t[pixel] = WR.MainFrame:CreateTexture();
    WR.MainFrame.t[pixel]:SetColorTexture(0,0,0,1);
    WR.MainFrame.t[pixel]:SetPoint("TOPLEFT", WR.MainFrame, pixel, 0);
  end

  function WR.MainFrame:ChangePixel (pixel, data)
    local number;
    if data == nil then
      number = 0;
    elseif type(data) == "boolean" then
      number = data and 1 or 0;
    else
      number = tonumber(data);
    end
    local c = mathmin(mathmax(number, 0), 16777216);
    local b = c%256;
    local g = ((c-b)/256)%256;
    local r = ((c-b)/65536)-(g/256);
    self.t[pixel]:SetColorTexture(r/255, g/255, b/255, 1);
  end

  function WR.MainFrame:ChangeKeybind (keybind)
    local bind = WR.GetKeybindInfo(keybind);
    self:ChangePixel(2, bind.key);
    self:ChangePixel(3, bind.mod1);
    self:ChangePixel(4, bind.mod2);
  end

  -- AddonLoaded
  WR.MainFrame:RegisterEvent("ADDON_LOADED");
  WR.MainFrame:RegisterEvent("VARIABLES_LOADED");
  WR.MainFrame:RegisterEvent("UI_SCALE_CHANGED");
  WR.MainFrame:SetScript("OnEvent", function (self, Event, Arg1)
      if Event == "ADDON_LOADED" then
        if Arg1 == "WorldyRotation" then
          -- Panels
          if type(WorldyRotationDB) ~= "table" then
            WorldyRotationDB = {};
          end
          if type(WorldyRotationCharDB) ~= "table" then
            WorldyRotationCharDB = {};
          end
          if type(WorldyRotationDB.GUISettings) ~= "table" then
            WorldyRotationDB.GUISettings = {};
          end
          if type(WorldyRotationCharDB.GUISettings) ~= "table" then
            WorldyRotationCharDB.GUISettings = {};
          end
          if type(WorldyRotationCharDB.Toggles) ~= "table" then
            WorldyRotationCharDB.Toggles = {};
          end
          WR.GUI.LoadSettingsRecursively(WR.GUISettings);
          WR.GUI.CorePanelSettingsInit();
          -- UI
          WR.MainFrame:SetFrameStrata(WR.GUISettings.General.MainFrameStrata);
          WR.MainFrame:Show();
          -- Pixel
          for i=0, 4 do
            WR.MainFrame:CreatePixelTexture(i);
            if type(WorldyRotationCharDB.Toggles[i]) ~= "boolean" then
              WorldyRotationCharDB.Toggles[i] = true;
            end
          end
          WR.MainFrame:ChangePixel(0, 424242);
          WR.MainFrame:ChangePixel(1, WR.ON());

          -- Modules
          C_Timer.After(2, function ()
              WR.MainFrame:UnregisterEvent("ADDON_LOADED");
              WR.PulseInit();
            end
          );
        end
      elseif Event == "VARIABLES_LOADED" or Event == "UI_SCALE_CHANGED" then
        WR.MainFrame:Resize()
      end
    end
  );

--- ======= MAIN =======
  local EnabledRotation = {
    ---- Death Knight
    --  [250]   = "WorldyRotation_DeathKnight",   -- Blood
    --  [251]   = "WorldyRotation_DeathKnight",   -- Frost
    --  [252]   = "WorldyRotation_DeathKnight",   -- Unholy
    ---- Demon Hunter
    --  [577]   = "WorldyRotation_DemonHunter",   -- Havoc
    --  [581]   = "WorldyRotation_DemonHunter",   -- Vengeance
    ---- Druid
    --  [102]   = "WorldyRotation_Druid",         -- Balance
    --  [103]   = "WorldyRotation_Druid",         -- Feral
    --  [104]   = "WorldyRotation_Druid",         -- Guardian
    --  [105]   = "WorldyRotation_Druid",         -- Restoration
    ---- Hunter
    --  [253]   = "WorldyRotation_Hunter",        -- Beast Mastery
    --  [254]   = "WorldyRotation_Hunter",        -- Marksmanship
    --  [255]   = "WorldyRotation_Hunter",        -- Survival
    ---- Mage
    --  [62]    = "WorldyRotation_Mage",          -- Arcane
    --  [63]    = "WorldyRotation_Mage",          -- Fire
    --  [64]    = "WorldyRotation_Mage",          -- Frost
    ---- Monk
    --  [268]   = "WorldyRotation_Monk",          -- Brewmaster
    --  [269]   = "WorldyRotation_Monk",          -- Windwalker
    --  [270]   = "WorldyRotation_Monk",          -- Mistweaver
    ---- Paladin
    --  [65]    = "WorldyRotation_Paladin",       -- Holy
    --  [66]    = "WorldyRotation_Paladin",       -- Protection
    --  [70]    = "WorldyRotation_Paladin",       -- Retribution
    -- Priest
      [256]   = "WorldyRotation_Priest",        -- Discipline
    --  [257]   = "WorldyRotation_Priest",        -- Holy
    --  [258]   = "WorldyRotation_Priest",        -- Shadow
    ---- Rogue
    --  [259]   = "WorldyRotation_Rogue",         -- Assassination
    --  [260]   = "WorldyRotation_Rogue",         -- Outlaw
    --  [261]   = "WorldyRotation_Rogue",         -- Subtlety
    ---- Shaman
    --  [262]   = "WorldyRotation_Shaman",        -- Elemental
    --  [263]   = "WorldyRotation_Shaman",        -- Enhancement
    --  [264]   = "WorldyRotation_Shaman",        -- Restoration
    ---- Warlock
    --  [265]   = "WorldyRotation_Warlock",       -- Affliction
    --  [266]   = "WorldyRotation_Warlock",       -- Demonology
    --  [267]   = "WorldyRotation_Warlock",       -- Destruction
    ---- Warrior
    --  [71]    = "WorldyRotation_Warrior",       -- Arms
    --  [72]    = "WorldyRotation_Warrior",       -- Fury
    --  [73]    = "WorldyRotation_Warrior"        -- Protection
  };
  local LatestSpecIDChecked = 0;
  function WR.PulseInit ()
    local Spec = GetSpecialization();
    -- Delay by 1 second until the WoW API returns a valid value.
    if Spec == nil then
      HL.PulseInitialized = false;
      C_Timer.After(1, function ()
          WR.PulseInit();
        end
      );
    else
      -- Force a refresh from the Core
      Cache.Persistent.Player.Spec = {GetSpecializationInfo(Spec)};
      local SpecID = Cache.Persistent.Player.Spec[1];

      -- Delay by 1 second until the WoW API returns a valid value.
      if SpecID == nil then
        HL.PulseInitialized = false;
        C_Timer.After(1, function ()
            WR.PulseInit();
          end
        );
      else
        -- Load the Class Module if it's possible and not already loaded
        if EnabledRotation[SpecID] and not IsAddOnLoaded(EnabledRotation[SpecID]) then
          LoadAddOn(EnabledRotation[SpecID]);
          HL.LoadOverrides(SpecID)
        end

        -- Check if there is a Rotation for this Spec
        if LatestSpecIDChecked ~= SpecID then
          if EnabledRotation[SpecID] and WR.APLs[SpecID] then
            WR.MainFrame:Show();
            WR.MainFrame:SetScript("OnUpdate", WR.Pulse);
            -- Spec Registers
            -- Spells
            Player:RegisterListenedSpells(SpecID);
            HL.UnregisterAuraTracking();
            -- Enums Filters
            Player:FilterTriggerGCD(SpecID);
            Spell:FilterProjectileSpeed(SpecID);
            -- Module Init Function
            if WR.APLInits[SpecID] then
              WR.APLInits[SpecID]();
            end
            -- Special Checks
            if GetCVar("nameplateShowEnemies") ~= "1" then
              WR.Print("It looks like enemy nameplates are disabled, you should enable them in order to get proper AoE rotation.");
            end
          else
            WR.Print("No Rotation found for this class/spec (SpecID: ".. SpecID .. "), addon disabled. This is likely due to the rotation being unsupported at this time. Please check supported rotations.");
            WR.MainFrame:Hide();
            WR.MainFrame:SetScript("OnUpdate", nil);
          end
          LatestSpecIDChecked = SpecID;
        end
        if not HL.PulseInitialized then HL.PulseInitialized = true; end
      end
    end
  end

  WR.Timer = {
    Pulse = 0
  };
  function WR.Pulse ()
    if GetTime() > WR.Timer.Pulse then
      WR.Timer.Pulse = GetTime() + HL.Timer.PulseOffset;

      -- Check if the current spec is available (might not always be the case)
      -- Especially when switching from area (open world -> instance)
      local SpecID = Cache.Persistent.Player.Spec[1];
      if SpecID then
        -- Check if we are ready to cast something to save FPS.
        if WR.ON() and WR.Ready() then
          HL.CacheHasBeenReset = false;
          Cache.Reset();
          -- Rotational Debug Output
          if WR.GUISettings.General.RotationDebugOutput then
            CurrResult = WR.APLs[SpecID]();
            if CurrResult and CurrResult ~= PrevResult then
              WR.Print(CurrResult);
              PrevResult = CurrResult;
            elseif CurrResult == nil then
              WR.MainFrame:ChangeKeybind(nil);
              PrevResult = nil;
            end
          else
            WR.APLs[SpecID]();
          end
        end
      end
    end
  end

  -- Is the player ready ?
  function WR.Ready ()
    return not Player:IsDeadOrGhost() and not Player:IsMounted() and not Player:IsInVehicle() and not C_PetBattles.IsInBattle();
  end

  -- Used to force a short/long pulse wait, it also resets the icons.
  function WR.ChangePulseTimer (Offset)
    WR.MainFrame:ChangeKeybind(nil);
    WR.Timer.Pulse = GetTime() + Offset;
  end
