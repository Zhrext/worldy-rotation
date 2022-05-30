--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, WR = ...;
  -- HeroLib
  local HL = HeroLib;
  -- File Locals
  local GUI = HL.GUI;
  local CreatePanel = GUI.CreatePanel;
  local CreateChildPanel = GUI.CreateChildPanel;
  local CreatePanelOption = GUI.CreatePanelOption;


--- ============================ CONTENT ============================
  -- Default settings
  WR.GUISettings = {
    General = {
      -- Main Frame Strata
      MainFrameStrata = "BACKGROUND",
      -- Interrupt
      InterruptEnabled = false,
      InterruptWithStun = false, -- EXPERIMENTAL
      --
      NotEnoughManaEnabled = false,
      RotationDebugOutput = false,
    },
    APL = {}
  };

  function WR.GUI.CorePanelSettingsInit ()
    -- GUI
    local ARPanel = CreatePanel(WR.GUI, "WorldyRotation", "PanelFrame", WR.GUISettings, WorldyRotationDB.GUISettings);
    -- Child Panel
    local CP_General = CreateChildPanel(ARPanel, "General");
    -- Controls
    CreatePanelOption("Dropdown", CP_General, "General.MainFrameStrata", {"HIGH", "MEDIUM", "LOW", "BACKGROUND"}, "Main Frame Strata", "Choose the frame strata to use for icons.", {ReloadRequired = true});
    CreatePanelOption("CheckButton", CP_General, "General.InterruptEnabled", "Interrupt", "Enable if you want to interrupt.");
    CreatePanelOption("CheckButton", CP_General, "General.InterruptWithStun", "Interrupt With Stun", "EXPERIMENTAL: Enable if you want to interrupt with stuns.");
    CreatePanelOption("CheckButton", CP_General, "General.RotationDebugOutput", "Debug Output", "DEBUG: Enable if you want output rotation selection as text for debugging purposes.");
  end
