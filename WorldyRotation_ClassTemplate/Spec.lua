--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local HL = HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
local MultiSpell = HL.MultiSpell
local Item = HL.Item
-- WorldyRotation
local WR = WorldyRotation
local AoEON = WR.AoEON
local CDsON = WR.CDsON
local Cast = WR.Cast
-- Lua

--- ============================ CONTENT ============================
--- ======= APL LOCALS =======
-- Commons
local Everyone = WR.Commons.Everyone
local Class = WR.Commons.Class

-- GUI Settings
local Settings = {
  General = WR.GUISettings.General,
  Commons = WR.GUISettings.APL.Class.Commons,
  Spec = WR.GUISettings.APL.Class.Spec
}

-- Spells
local S = Spell.Class.Spec

-- Items
local I = Item.Class.Spec
local TrinketsOnUseExcludes = {
  --  I.TrinketName:ID(),
}

-- Enemies

-- Rotation Variables

-- Interrupts


--- ======= HELPERS =======


--- ======= ACTION LISTS =======
-- Put here action lists only if they are called multiple times in the APL
-- If it's only put one time, it's doing a closure call for nothing.


--- ======= MAIN =======
local function APL()
  -- Rotation Variables Update

  -- Unit Update

  -- Defensives

  -- Out of Combat
  if not Player:AffectingCombat() then
    -- Flask
    -- Food
    -- Rune
    -- PrePot w/ Bossmod Countdown
    -- Opener
    if Everyone.TargetIsValid() then

    end
    return
  end

  -- In Combat
  if Everyone.TargetIsValid() then

    return
  end
end

local function OnInit()
end

WR.SetAPL(000, APL, OnInit)


--- ======= SIMC =======
-- Last Update: 12/31/2999

-- APL goes here
