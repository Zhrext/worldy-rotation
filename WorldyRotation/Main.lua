--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, WR = ...;
-- HeroLib
local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Player = Unit.Player;
local Spell = HL.Spell;
local GUI = HL.GUI;
local CreatePanelOption = GUI.CreatePanelOption;

-- Lua
local mathmax = math.max;
local mathmin = math.min;
local tableinsert = table.insert;
local tonumber = tonumber;
local tostring = tostring;
local type = type;
-- File Locals
local PrevResult, CurrResult;

-- Commons
local Everyone = WR.Commons.Everyone

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
WR.MainFrame.Textures = {};
WR.MainFrame.Macros = {};

function WR.MainFrame:Resize ()
  local _, screenHeight = GetPhysicalScreenSize()
  local scaleFactor = 768 / screenHeight
  if self:GetScale() ~= scaleFactor then
    self:SetScale(scaleFactor)
  end
end

function WR.MainFrame:CreatePixelTexture (pixel)
  WR.MainFrame.Textures[pixel] = WR.MainFrame:CreateTexture();
  WR.MainFrame.Textures[pixel]:SetColorTexture(0,0,0,1);
  WR.MainFrame.Textures[pixel]:SetPoint("TOPLEFT", WR.MainFrame, pixel, 0);
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
  self.Textures[pixel]:SetColorTexture(r/255, g/255, b/255, 1);
end

function WR.MainFrame:ChangeBind (Bind)
  local BindEx = WR.GetBindInfo(Bind);
  self:ChangePixel(2, BindEx.Key);
  self:ChangePixel(3, BindEx.Mod1);
  self:ChangePixel(4, BindEx.Mod2);
end

function WR.MainFrame:AddMacroFrame (Object)
  self.Macros[Object.MacroID] = CreateFrame("Button", Object.MacroID, self, "SecureActionButtonTemplate");
  self.Macros[Object.MacroID]:SetAttribute("type", "macro");
  self.Macros[Object.MacroID]:SetAttribute("macrotext", Object.MacroText);
  self.Macros[Object.MacroID]:RegisterForClicks("AnyDown");
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

      WR.ToggleFrame:Init();

      -- Load additionnal settings
      local CP_General = GUI.GetPanelByName("General")
      if CP_General then
        CreatePanelOption("Button", CP_General, "ButtonMove", "Lock/Unlock", "Enable the moving of the frames.", function() WR.ToggleFrame:ToggleLock(); end);
      end

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

--- ======= TOGGLE FRAME =======
WR.ToggleFrame = CreateFrame("Frame", "WorldyRotation_ToggleFrame", UIParent);
WR.ToggleFrame:SetFrameStrata(WR.MainFrame:GetFrameStrata());
WR.ToggleFrame:SetFrameLevel(WR.MainFrame:GetFrameLevel() - 1);
WR.ToggleFrame:SetSize(64, 20);
WR.ToggleFrame:SetPoint("CENTER", 0, 0);
WR.ToggleFrame:SetClampedToScreen(true);

function WR.ToggleFrame:Unlock ()
  -- Unlock the UI
  self:EnableMouse(true);
  self:SetMovable(true);
  WorldyRotationDB.Locked = false;
end
function WR.ToggleFrame:Lock ()
  self:EnableMouse(false);
  self:SetMovable(false);
  WorldyRotationDB.Locked = true;
end
function WR.ToggleFrame:ToggleLock ()
  if WorldyRotationDB.Locked then
    self:Unlock();
    WR.Print("UI is now |cff00ff00unlocked|r.");
  else
    self:Lock ();
    WR.Print("UI is now |cffff0000locked|r.");
  end
end

function WR.ToggleFrame:Init ()
  -- Frame Init
  self:SetFrameStrata(WR.MainFrame:GetFrameStrata());
  self:SetFrameLevel(WR.MainFrame:GetFrameLevel() - 1);
  self:SetWidth(64);
  self:SetHeight(20);

  -- Anchor based on Settings
  if WorldyRotationDB and WorldyRotationDB.ToggleFramePos then
    self:SetPoint(WorldyRotationDB.ToggleFramePos[1], WorldyRotationDB.ToggleFramePos[2], WorldyRotationDB.ToggleFramePos[3], WorldyRotationDB.ToggleFramePos[4], WorldyRotationDB.ToggleFramePos[5]);
  else
    self:SetPoint("CENTER", 0, 0);
  end

  -- Start Move
  local function StartMove (self)
    if self:IsMovable() then
      self:StartMoving();
    end
  end
  self:SetScript("OnMouseDown", StartMove);
  -- Stop Move
  local function StopMove (self)
    self:StopMovingOrSizing();
    if not WorldyRotationDB then WorldyRotationDB = {}; end
    local point, relativeTo, relativePoint, xOffset, yOffset, relativeToName;
    point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint();
    if not relativeTo then
      relativeToName = "UIParent";
    else
      relativeToName = relativeTo:GetName();
    end
    WorldyRotationDB.ToggleFramePos = {
      point,
      relativeToName,
      relativePoint,
      xOffset,
      yOffset
    };
  end
  self:SetScript("OnMouseUp", StopMove);
  self:SetScript("OnHide", StopMove);
  self:Lock();
  self:Show();

  -- Button Creation
  self.Button = {};
  self:AddButton("O", 1, "On/Off", "toggle");
  self:AddButton("C", 2, "CDs", "cds");
  self:AddButton("A", 3, "AoE", "aoe");
end
-- Add a button
WR.Toggles = {};
function WR.ToggleFrame:AddButton (Text, i, Tooltip, CmdArg)
  WR.Toggles[CmdArg] = i;
  
  local ButtonFrame = CreateFrame("Button", "$parentButton"..tostring(i), self);
  ButtonFrame:SetFrameStrata(self:GetFrameStrata());
  ButtonFrame:SetFrameLevel(self:GetFrameLevel() - 1);
  ButtonFrame:SetWidth(20);
  ButtonFrame:SetHeight(20);
  ButtonFrame:SetPoint("LEFT", self, "LEFT", 20*(i-1)+i, 0);

  -- Button Tooltip (Optional)
  if Tooltip then
    ButtonFrame:SetScript("OnEnter",
        function ()
          Mixin(GameTooltip, BackdropTemplateMixin);
          GameTooltip:SetOwner(WR.ToggleFrame, "ANCHOR_BOTTOM", 0, 0);
          GameTooltip:ClearLines();
          GameTooltip:SetBackdropColor(0, 0, 0, 1);
          GameTooltip:SetText(Tooltip, nil, nil, nil, 1, true);
          GameTooltip:Show();
        end
    );
    ButtonFrame:SetScript("OnLeave",
        function ()
          GameTooltip:Hide();
        end
    );
  end

  -- Button Text
  ButtonFrame:SetNormalFontObject("GameFontNormalSmall");
  ButtonFrame.text = Text;

  -- Button Texture
  local NormalTexture = ButtonFrame:CreateTexture();
  NormalTexture:SetTexture("Interface/Buttons/UI-Silver-Button-Up");
  NormalTexture:SetTexCoord(0, 0.625, 0, 0.7875);
  NormalTexture:SetAllPoints();
  ButtonFrame:SetNormalTexture(NormalTexture);
  local HighlightTexture = ButtonFrame:CreateTexture();
  HighlightTexture:SetTexture("Interface/Buttons/UI-Silver-Button-Highlight");
  HighlightTexture:SetTexCoord(0, 0.625, 0, 0.7875);
  HighlightTexture:SetAllPoints();
  ButtonFrame:SetHighlightTexture(HighlightTexture);
  local PushedTexture = ButtonFrame:CreateTexture();
  PushedTexture:SetTexture("Interface/Buttons/UI-Silver-Button-Down");
  PushedTexture:SetTexCoord(0, 0.625, 0, 0.7875);
  PushedTexture:SetAllPoints();
  ButtonFrame:SetPushedTexture(PushedTexture);

  -- Button Setting
  if type(WorldyRotationCharDB) ~= "table" then
    WorldyRotationCharDB = {};
  end
  if type(WorldyRotationCharDB.Toggles) ~= "table" then
    WorldyRotationCharDB.Toggles = {};
  end
  if type(WorldyRotationCharDB.Toggles[i]) ~= "boolean" then
    WorldyRotationCharDB.Toggles[i] = true;
  end

  -- OnClick Callback
  ButtonFrame:SetScript("OnMouseDown",
      function (self, Button)
        if Button == "LeftButton" then
          WR.CmdHandler(CmdArg);
        end
      end
  );

  self.Button[i] = ButtonFrame;

  WR.ToggleFrame:UpdateButtonText(i);

  ButtonFrame:Show();
end
-- Update a button text
function WR.ToggleFrame:UpdateButtonText (i)
  if WorldyRotationCharDB.Toggles[i] then
    self.Button[i]:SetFormattedText("|cff00ff00%s|r", self.Button[i].text);
  else
    self.Button[i]:SetFormattedText("|cffff0000%s|r", self.Button[i].text);
  end
end

--- ======= MAIN =======
local EnabledRotation = {
  ---- Death Knight
  -- [250]   = "WorldyRotation_DeathKnight",   -- Blood
  --  [251]   = "WorldyRotation_DeathKnight",   -- Frost
  --  [252]   = "WorldyRotation_DeathKnight",   -- Unholy
  ---- Demon Hunter
  [577]   = "WorldyRotation_DemonHunter",   -- Havoc
  [581]   = "WorldyRotation_DemonHunter",   -- Vengeance
  ---- Druid
  [102]   = "WorldyRotation_Druid",         -- Balance
  --  [103]   = "WorldyRotation_Druid",         -- Feral
  --  [104]   = "WorldyRotation_Druid",         -- Guardian
    [105]   = "WorldyRotation_Druid",         -- Restoration
  ---- Hunter
    [253]   = "WorldyRotation_Hunter",        -- Beast Mastery
    [254]   = "WorldyRotation_Hunter",        -- Marksmanship
    --[255]   = "WorldyRotation_Hunter",        -- Survival
  ---- Mage
  --  [62]    = "WorldyRotation_Mage",          -- Arcane
  --  [63]    = "WorldyRotation_Mage",          -- Fire
  --  [64]    = "WorldyRotation_Mage",          -- Frost
  ---- Monk
  --  [268]   = "WorldyRotation_Monk",          -- Brewmaster
      [269]   = "WorldyRotation_Monk",          -- Windwalker
  --  [270]   = "WorldyRotation_Monk",          -- Mistweaver
  ---- Paladin
  --  [65]    = "WorldyRotation_Paladin",       -- Holy
  --  [66]    = "WorldyRotation_Paladin",       -- Protection
  --  [70]    = "WorldyRotation_Paladin",       -- Retribution
  -- Priest
  --  [256]   = "WorldyRotation_Priest",        -- Discipline
  --    [257]   = "WorldyRotation_Priest",        -- Holy
  --  [258]   = "WorldyRotation_Priest",        -- Shadow
  ---- Rogue
  --  [259]   = "WorldyRotation_Rogue",         -- Assassination
  --  [261]   = "WorldyRotation_Rogue",         -- Subtlety
  [260]   = "WorldyRotation_Rogue",         -- Outlaw
  ---- Shaman
  --  [262]   = "WorldyRotation_Shaman",        -- Elemental
  --  [263]   = "WorldyRotation_Shaman",        -- Enhancement
  --  [264]   = "WorldyRotation_Shaman",        -- Restoration
  ---- Warlock
  --  [265]   = "WorldyRotation_Warlock",       -- Affliction
  --  [266]   = "WorldyRotation_Warlock",       -- Demonology
  --  [267]   = "WorldyRotation_Warlock",       -- Destruction
  ---- Warrior
  --[71]    = "WorldyRotation_Warrior",       -- Arms
  --[72]    = "WorldyRotation_Warrior",       -- Fury
  [73]    = "WorldyRotation_Warrior"        -- Protection
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
      Everyone.InitTimers();
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

    Everyone.PulseTimers();
    
    -- Check if the current spec is available (might not always be the case)
    -- Especially when switching from area (open world -> instance)
    local SpecID = Cache.Persistent.Player.Spec[1];
    if SpecID then
      -- Check if we are ready to cast something to save FPS.
      if WR.ON() and WR.Ready() and not WR.Pause() then
        HL.CacheHasBeenReset = false;
        Cache.Reset();
        -- Rotational Debug Output
        if WR.GUISettings.General.Enabled.RotationDebugOutput then
          CurrResult = WR.APLs[SpecID]();
          if CurrResult and CurrResult ~= PrevResult then
            WR.Print(CurrResult);
            PrevResult = CurrResult;
          elseif CurrResult == nil then
            WR.MainFrame:ChangeBind(nil);
            PrevResult = nil;
          end
        else
          if WR.APLs[SpecID]() == nil then
            WR.MainFrame:ChangeBind(nil);
          end
        end
      else
        WR.MainFrame:ChangeBind(nil);
        PrevResult = nil;
      end
    end
  end
end

function WR.Ready ()
  return not Player:IsDeadOrGhost() and not Player:IsMounted() and not Player:IsInVehicle() and not C_PetBattles.IsInBattle() and not ACTIVE_CHAT_EDIT_BOX;
end

function WR.Pause()
  return WR.GUISettings.General.Enabled.ShiftKeyPause and IsShiftKeyDown();
end

function WR.Break()
  WR.ChangePulseTimer(Player:GCD() + 0.05);
end

-- Used to force a short/long pulse wait, it also resets the icons.
function WR.ChangePulseTimer (Offset)
  WR.MainFrame:ChangeBind(nil);
  WR.Timer.Pulse = GetTime() + Offset;
end
