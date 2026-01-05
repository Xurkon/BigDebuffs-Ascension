# BigDebuffs Changelog

## Version 6.9 - Ascension Raid/Nameplate Support

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

