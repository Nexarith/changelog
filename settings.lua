-- changelog/settings.lua
-- Configuration template for changelog mod

local CONFIG = {}


-- theme colors
CONFIG.colors = {
    bg        = "#050512",
    panel     = "#0A0B23",
    border    = "#5A63F1",
    text      = "#E9EDFF",
    text_soft = "#C7CCF7",
    accent    = "#5A63F1",
}

-- form size
CONFIG.form = {
    w = 12,
    h = 12,
}

-- button size
CONFIG.buttons = {
    main_width  = 1.5,
    small_width = 1.5,
    exit_width  = 1.5,
}

-- page size
CONFIG.pages = {
    changelog = 6,
    mods      = 10,
    history   = 6,
}

-- feature toggles
CONFIG.features = {
    logging          = true,
    detect_removals  = true,
    detect_updates   = true,
    player_history   = true,
}


--  titles (bold aesthetic ✦…✦)
CONFIG.titles = {
    main    = "✦ SERVER SYS.CONSOLE ✦",
    mods    = "✦ SERVER MOD LIST ✦",
    history = "✦ SERVER SYS.HISTORY ✦",
}

return CONFIG
