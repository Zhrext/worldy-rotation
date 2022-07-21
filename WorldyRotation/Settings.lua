--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local WR = ...;
  -- HeroLib
  local HL = HeroLib;
  -- File Locals
  local GUI = HL.GUI;
  local CreatePanel = GUI.CreatePanel;
  local CreateChildPanel = GUI.CreateChildPanel;
  local CreatePanelOption = GUI.CreatePanelOption;
  local CreateARPanelOptions = WR.GUI.CreateARPanelOptions


--- ============================ CONTENT ============================
  -- Default settings
  WR.GUISettings = {
    General = {
      -- Main Frame Strata
      MainFrameStrata = "BACKGROUND",
      Enabled = {
        -- Pause
        ShiftKeyPause = false,
        -- Interrupt
        Interrupt = false,
        InterruptWithStun = false, -- EXPERIMENTAL
        InterruptOnlyWhitelist = false,
        -- CrowdControl
        CrowdControl = false,
        -- Dispel
        DispelBuffs = false,
        DispelDebuffs = false,
        -- Misc
        Racials = false,
        Potions = false,
        Trinkets = false,
        -- Debug
        RotationDebugOutput = false,
      },
      Threshold = {
        -- Interrupt
        Interrupt = 60,
      },
      HP = {
        Healthstone = 40,
        PhialOfSerenity = 40,
      },
    },
    APL = {}
  };

  function WR.GUI.CorePanelSettingsInit ()
    -- GUI
    local WRPanel = CreatePanel(WR.GUI, "WorldyRotation", "PanelFrame", WR.GUISettings, WorldyRotationDB.GUISettings);
    -- Child Panel
    local CP_General = CreateChildPanel(WRPanel, "General");
    -- Controls
    CreatePanelOption("Dropdown", CP_General, "General.MainFrameStrata", {"HIGH", "MEDIUM", "LOW", "BACKGROUND"}, "Main Frame Strata", "Choose the frame strata to use for icons.", {ReloadRequired = true});
    CreateARPanelOptions(CP_General, "General")
  end
