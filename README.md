# changelog

**Author:** Cashia
**Version:** 1.0
**Minetest Version:** 5.5+
**Dependencies:** None 
---

## Overview

**Changelog** provides an in-game terminal GUI to track all mod activity on the server.  
It features:

- Per-player changelog history — players only see new entries they haven’t viewed
- Mod detection — tracks installed, updated, and removed mods
- Daily server logs — stored in `/server_changelog/YYYY-MM-DD.log`
- UTC timestamps for all events
- Pagination for mods and history
- Home buttons to easily return to the main terminal
- Compact exit button and smooth interface for all screens

The mod is highly configurable and uses default settings if no config is provided.

---

## Installation

1. Place the `changelog` folder into your server’s `mods` directory
2. (Optional) Customize `settings.lua` to override default colors, page sizes, buttons, and features
3. Start your server. The terminal GUI will open automatically when players join

---

## Commands

- `/changelog` — Opens the main terminal GUI
- Buttons in the GUI:
  - « / » — Navigate pages in the changelog, mods, or history
  - ⌂ Home — Return to main console
  - ✖ Exit — Close the GUI

---

## Config Options

Defaults are built-in, but you can create a `settings.lua` to override:

```lua
-- Example: settings.lua
return {
    colors = {
        bg = "#101010",
        panel = "#202020",
        accent = "#FF00FF"
    },
    pages = {
        changelog = 5,
        mods = 8,
        history = 5
    },
    buttons = {
        main_width = 1.5,
        exit_width = 1.5
    },
    features = {
        logging = true,
        detect_updates = true,
        detect_removals = true,
        player_history = true
    }
}
```
---

## Features

- Per-player tracking: Each player only sees mods they haven’t viewed yet
- Circular pagination:
  - Press "»" on the last page to loop back to page 1
  - Press "«" on page 1 to loop to the last page
- Daily logging: All mod events are saved in separate files by date in `/server_changelog/`
- Home button: Returns to the main console screen
- Exit button: Closes the GUI quickly and smoothly
- Automatic mod change detection: Detects new, updated, and removed mods

---


## Notes
- Fully configurable via `settings.lua` but defaults are included
- Ideal for servers that want a clean mod tracking system with a smooth in-game interface
