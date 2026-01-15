# BigDebuffs Changelog

## Version 6.9.3 - Raid Frame Positioning & Test Mode Improvements (by Hutsh)

### New Features

**X/Y Position Control for Raid Frames**
- Added **Offset X** slider to Options UI for horizontal positioning control (-100 to +100)
- Added **Offset Y** slider to Options UI for vertical positioning control (-100 to +100)
- Sliders provide precise control over BigDebuffs icon placement on raid frames
- Settings persist across /reload and relogs via AceDB
- Real-time preview when adjusting sliders

**Test Mode Improvements**
- Completely redesigned raid frame test mode for better visualization
- Test frames now show mock raid frame backgrounds (60x40 pixels with borders)
- BigDebuffs icons positioned on backgrounds using actual offsetX/offsetY configuration
- Labels display current offset values (e.g., "raid1 (X:20 Y:-15)")
- Entire background+icon units are draggable for repositioning
- Visual feedback updates in real-time when adjusting position sliders

### Bug Fixes

- Fixed test mode not applying offsetX/offsetY configuration to test frames
- Fixed test mode visual representation to accurately show how icons will appear on real raid frames

### Technical Changes

- Modified `Options.lua` (lines 1422-1443): Added offsetX and offsetY range sliders to raid frame options
- Rewrote `CreateRaidTestFrames()` in `BigDebuffs_AscensionFix.lua` (lines 569-637):
  - Creates background frames using WoW backdrop API to represent raid frames
  - Positions icon frames relative to backgrounds using offsetX/offsetY values
  - Two-level structure: frame (background) + iconFrame (BigDebuffs icon)
  - Cross-references via `frame.iconFrame` and `iconFrame.background`
  - Updated grid spacing to 75 pixels for better visibility

### Notes

- The Alpha/Opacity slider for raid frames already existed (no changes needed)
- Backend configuration (`offsetX = 0, offsetY = 0`) was already present in `BigDebuffs.lua`
- Backend positioning code was already functional in `BigDebuffs_AscensionFix.lua`
- This update adds UI controls and proper test mode visualization for existing functionality

---

## Version 6.9.2 - Test Mode Fix

### Bug Fixes

- Fixed test mode not displaying movable frames for Raid and Nameplate configurations
- When test mode is enabled, 5 raid test frames (raid1-raid5) now appear for positioning
- When test mode is enabled, 1 nameplate test frame appears for positioning
- Test frames can be dragged to desired positions and positions are saved

---

## Version 6.9.1 - Locale Fixes (by Xurkon)

### Bug Fixes

- Fixed missing locale entries for nameplate options (snare, silence, disarm, etc.)
- Added 22 missing locale strings for nameplate aura type toggles

---

## Version 6.9 - Ascension Raid/Nameplate Support (by Xurkon)

### New Features

**Raid Frame Support**
- Added support for raid units (raid1-raid40)
- Integrated LibGetFrame-1.0 for dynamic raid frame detection
- Works with ANY raid frame addon: ElvUI, Grid, Grid2, VuhDo, HealBot, Blizzard CompactRaidFrames, Shadowed Unit Frames, PitBull4, Lime, and more
- New "Raid Frames" tab in Options UI for configuration
- Configurable icon size and aura types for raid frames

**Nameplate Support**
- Added nameplate support using Ascension's backported C_NamePlate API
- Registers for NAME_PLATE_UNIT_ADDED and NAME_PLATE_UNIT_REMOVED events
- Scheduled timer for continuous aura updates on nameplates
- New "Nameplates" tab in Options UI for configuration
- Configurable icon size and aura types for nameplates

### Technical Changes

- Added `raid` and `nameplate` configuration sections to defaults
- Added `raid1` through `raid40` to tracked units table
- Added `AttachRaidFrame()` function using LibGetFrame.GetUnitFrame()
- Added `AttachNamePlateFrame()` function using C_NamePlate.GetNamePlateForUnit()
- Added `UpdateNameplates()` scheduled timer for continuous updates
- Added `NAME_PLATE_UNIT_ADDED` and `NAME_PLATE_UNIT_REMOVED` event handlers
- Updated `UNIT_AURA` to route raid and nameplate units to appropriate handlers
- Updated `GetAuraPriority` to handle raid and nameplate config lookup
- Added Raid Frames and Nameplates tabs to Options.lua
- Bundled LibGetFrame-1.0 library

### Files Modified

- `BigDebuffs.lua` - Added raid/nameplate defaults and raid units to units table
- `BigDebuffs_AscensionFix.lua` - Added LibGetFrame integration, nameplate handlers, and raid frame support
- `Options.lua` - Added Raid Frames and Nameplates configuration tabs
- `embeds.xml` - Added LibGetFrame-1.0 include
- `Libs/LibGetFrame-1.0/` - Added library files

