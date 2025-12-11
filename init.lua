-- changelog/init.lua
-- Sleek, in-game terminal GUI to track all mod activity on the server.  
-- Author: Cashia ©2025

local changelog = {}
local player_pages = {}
local mod_hashes = {}
local CONFIG = {}

-- Load config or set defaults
local config_path = minetest.get_modpath("changelog").."/settings.lua"
local ok, loaded = pcall(dofile, config_path)
if ok and loaded then
    CONFIG = loaded
else
    CONFIG = {
        colors = {
            bg = "#050512",
            panel = "#0A0B23",
            accent = "#5A63F1",
            text = "#E9EDFF",
            text_soft = "#C7CCF7"
        },
        pages = {
            changelog = 5,
            mods = 5,
            history = 5
        }
    }
end

-- Utility
local function utc_time()
    return os.date("!%Y-%m-%d %H:%M:%S UTC")
end

local function get_unseen_entries(player)
    local name = player:get_player_name()
    local entries = changelog
    if not player_pages[name] then player_pages[name] = 1 end
    return entries
end

-- Forms
local function formspec_base()
    local C = CONFIG.colors
    return
        "formspec_version[4]"..
        "size[12,12]"..
        "bgcolor["..C.bg.."]"..
        "style_type[label;textcolor="..C.text.."]"..
        "style_type[button;textcolor="..C.text_soft..";bordercolor="..C.accent.."]"
end

local function header_block(title)
    local C = CONFIG.colors
    return
        "box[0.3,0.3;11.4,1.5;"..C.panel.."]"..
        "label[0.5,0.5;"..title.."]"
end

local function terminal_panel(text)
    local C = CONFIG.colors
    return
        "box[0.3,2.2;11.4,7.2;"..C.panel.."]"..
        "textarea[0.5,2.4;11,7;;"..text..";]"
end

local function footer_buttons(has_prev_next)
    local C = CONFIG.colors
    local base = ""
    if has_prev_next then
        base = base..
            "button[0.5,9.8;1.5,0.9;prev;«]"..
            "button[2.2,9.8;1.5,0.9;home;⌂]"..
            "button[3.9,9.8;1.5,0.9;next;»]"
    else
        base = base.."button[2.2,9.8;1.5,0.9;home;⌂]"
    end
    base = base.."button[9.5,9.8;1.5,0.9;exit;✖]"
    return base
end

local function generate_text(entries, page, per_page)
    local start_idx = (page-1)*per_page+1
    local text = ""
    for i=start_idx, math.min(start_idx+per_page-1, #entries) do
        local e = entries[i]
        text = text.."> "..e.."\n"
    end
    return text
end

-- GUI functions
local function show_main(player)
    local name = player:get_player_name()
    local entries = get_unseen_entries(player)
    local per_page = CONFIG.pages.changelog
    local total_pages = math.max(1, math.ceil(#entries / per_page))
    if not player_pages[name] then player_pages[name] = 1 end
    local page = player_pages[name]

    local text = generate_text(entries, page, per_page)
    local fs = formspec_base()..
               header_block("[SERVER SYS.CONSOLE]")..
               terminal_panel(text)..
               footer_buttons(#entries > per_page)
    minetest.show_formspec(name, "changelog:main", fs)
end

local function show_mods(player, page)
    local name = player:get_player_name()
    local mods = minetest.get_modnames()
    page = page or 1
    local per_page = CONFIG.pages.mods
    local total_pages = math.max(1, math.ceil(#mods / per_page))
    local start_idx = (page-1)*per_page+1
    local text = ""
    for i=start_idx, math.min(start_idx+per_page-1, #mods) do
        text = text.."> "..mods[i].."\n"
    end
    local fs = formspec_base()..
               header_block("[SERVER MOD LIST]")..
               terminal_panel(text)..
               footer_buttons(#mods > per_page)
    player_pages[name] = page
    minetest.show_formspec(name, "changelog:mods", fs)
end

local function show_history(player, page)
    local name = player:get_player_name()
    local history = player_history[name] or {}
    page = page or 1
    local per_page = CONFIG.pages.history
    local total_pages = math.max(1, math.ceil(#history / per_page))
    local start_idx = (page-1)*per_page+1
    local text = ""
    for i=start_idx, math.min(start_idx+per_page-1, #history) do
        text = text.."> "..history[i].."\n"
    end
    local fs = formspec_base()..
               header_block("[SERVER SYS.HISTORY]")..
               terminal_panel(text)..
               footer_buttons(#history > per_page)
    player_pages[name] = page
    minetest.show_formspec(name, "changelog:history", fs)
end

-- Event handling
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if formname == "changelog:main" then
        local entries = get_unseen_entries(player)
        local per_page = CONFIG.pages.changelog
        local total_pages = math.max(1, math.ceil(#entries / per_page))
        if fields.next then
            player_pages[name] = (player_pages[name] % total_pages) + 1
            show_main(player)
        elseif fields.prev then
            player_pages[name] = ((player_pages[name]-2+total_pages) % total_pages) + 1
            show_main(player)
        elseif fields.home then
            player_pages[name] = 1
            show_main(player)
        elseif fields.mods then
            show_mods(player,1)
        elseif fields.history then
            show_history(player,1)
        end
    elseif formname == "changelog:mods" then
        local mods = minetest.get_modnames()
        local per_page = CONFIG.pages.mods
        local total_pages = math.max(1, math.ceil(#mods / per_page))
        if fields.next then
            player_pages[name] = (player_pages[name] % total_pages) + 1
            show_mods(player, player_pages[name])
        elseif fields.prev then
            player_pages[name] = ((player_pages[name]-2+total_pages) % total_pages) + 1
            show_mods(player, player_pages[name])
        elseif fields.home then
            show_main(player)
        end
    elseif formname == "changelog:history" then
        local history = player_history[name] or {}
        local per_page = CONFIG.pages.history
        local total_pages = math.max(1, math.ceil(#history / per_page))
        if fields.next then
            player_pages[name] = (player_pages[name] % total_pages) + 1
            show_history(player, player_pages[name])
        elseif fields.prev then
            player_pages[name] = ((player_pages[name]-2+total_pages) % total_pages) + 1
            show_history(player, player_pages[name])
        elseif fields.home then
            show_main(player)
        end
    elseif fields.exit then
        -- formspec closes automatically
    end
end)

-- Show main GUI on join
minetest.register_on_joinplayer(function(player)
    minetest.after(1,function()
        show_main(player)
    end)
end)
