-- changelog/init.lua
-- Sleek, in-game terminal GUI to track all mod activity on the server.  
-- Author: Cashia ©2025

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)


-- === DEFAULT CONFIG ====
local DEFAULT_CONFIG = {
    colors = {
        bg        = "#050512",
        panel     = "#0A0B23",
        border    = "#5A63F1",
        text      = "#E9EDFF",
        text_soft = "#C7CCF7",
        accent    = "#5A63F1",
    },
    pages = {
        changelog = 7,
        mods      = 10,
        history   = 7,
    },
    buttons = {
        main_width = 1.5,
        exit_width = 1.5,
    },
    form = {
        w = 12,
        h = 12,
    },
    titles = {
        main    = "[SERVER SYS.CONSOLE]",
        mods    = "[SERVER MOD LIST]",
        history = "[SERVER SYS.HISTORY]",
    },
    features = {
        logging         = true,
        detect_updates  = true,
        detect_removals = true,
        player_history  = true,
    }
}


-- load user config if exists
local user_config
local settings_file = modpath.."/settings.lua"
local f = io.open(settings_file, "r")
if f then
    f:close()
    user_config = dofile(settings_file)
else
    user_config = {}
end

-- merge defaults with user config
local function merge(defaults, user)
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            user[k] = user[k] or {}
            merge(v, user[k])
        else
            user[k] = user[k] ~= nil and user[k] or v
        end
    end
end
merge(DEFAULT_CONFIG, user_config)
local CONFIG = user_config
local C = CONFIG.colors

-- === STORAGE===
local storage = minetest.get_mod_storage()
local changelog_data = minetest.deserialize(storage:get_string("changelog_data") or "{}") or {}
local player_history = minetest.deserialize(storage:get_string("player_history") or "{}") or {}
local mod_hashes = minetest.deserialize(storage:get_string("mod_hashes") or "{}") or {}
local player_pages, player_mod_pages, player_history_pages = {}, {}, {}


-- === LOGGING SETUP: DAILY LOGS ===
local log_folder = minetest.get_worldpath().."/server_changelog"
if not os.rename(log_folder, log_folder) then minetest.mkdir(log_folder) end

local function write_log(entry)
    if CONFIG.features.logging then
        local date_str = os.date("!%Y-%m-%d", entry.time)
        local file_path = log_folder.."/"..date_str..".log"
        local line = string.format("[%s UTC] Mod %s %s\n",
            os.date("!%H:%M:%S", entry.time),
            entry.mod,
            entry.event
        )
        local file = io.open(file_path,"a")
        if file then
            file:write(line)
            file:close()
        end
    end
end


-- === UTILITY FUNCTIONS ===
local function save_data(key, table_data)
    storage:set_string(key, minetest.serialize(table_data))
end

local function hash_file(filepath)
    local file = io.open(filepath,"rb")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return minetest.sha1(content)
end

local function add_mod_event(modname,event_type)
    local entry = {mod=modname,event=event_type,time=os.time()}
    table.insert(changelog_data,entry)
    save_data("changelog_data",changelog_data)
    write_log(entry)
end

local function record_player_view(player,entry)
    if CONFIG.features.player_history then
        local name = player:get_player_name()
        player_history[name] = player_history[name] or {}
        table.insert(player_history[name],entry.time)
        save_data("player_history",player_history)
    end
end

local function get_unseen_entries(player)
    local name = player:get_player_name()
    local seen = player_history[name] or {}
    local unseen = {}
    for _,entry in ipairs(changelog_data) do
        local already_seen = false
        for _,t in ipairs(seen) do if t==entry.time then already_seen=true break end end
        if not already_seen then table.insert(unseen,entry) end
    end
    return unseen
end


-- === PAGINATION FUNCTIONS ===

local function get_paged_entries(player,page)
    local unseen = get_unseen_entries(player)
    local page_size = CONFIG.pages.changelog
    local total_pages = math.max(1, math.ceil(#unseen / page_size))
    page = ((page-1) % total_pages) + 1
    local start_idx = (page-1)*page_size + 1
    local end_idx = math.min(#unseen, start_idx + page_size - 1)
    local text = ""
    for i=start_idx, end_idx do
        local entry = unseen[i]
        text = text .. "> Mod " .. entry.mod .. " " .. entry.event .. " @ " .. os.date("!%Y-%m-%d %H:%M:%S UTC", entry.time) .. "\n"
        record_player_view(player, entry)
    end
    return text,page,total_pages
end

local function get_paged_mods(player,page)
    local mods = minetest.get_modnames()
    local page_size = CONFIG.pages.mods
    local total_pages = math.max(1, math.ceil(#mods / page_size))
    page = ((page-1) % total_pages) + 1
    local start_idx = (page-1)*page_size + 1
    local end_idx = math.min(#mods, start_idx + page_size - 1)
    local text = ""
    for i=start_idx, end_idx do text = text .. "> " .. mods[i] .. "\n" end
    return text,page,total_pages
end

local function get_paged_history(player,page)
    local entries = changelog_data
    local page_size = CONFIG.pages.history
    local total_pages = math.max(1, math.ceil(#entries / page_size))
    page = ((page-1) % total_pages) + 1
    local start_idx = (page-1)*page_size + 1
    local end_idx = math.min(#entries, start_idx + page_size - 1)
    local text = ""
    for i=start_idx, end_idx do
        local entry = entries[i]
        text = text .. "> Mod " .. entry.mod .. " " .. entry.event .. " @ " .. os.date("!%Y-%m-%d %H:%M:%S UTC", entry.time) .. "\n"
    end
    return text,page,total_pages
end


-- === GUI FUNCTIONS ===
local function formspec_base()
    return "formspec_version[4]"..
           "size["..CONFIG.form.w..","..CONFIG.form.h.."]"..
           "bgcolor["..C.bg.."]"..
           "style_type[label;textcolor="..C.text.."]"..
           "style_type[button;textcolor="..C.text_soft..";bordercolor="..C.accent.."]"
end

local function header_block(title)
    return "box[0.3,0.3;11.4,1.5;"..C.panel.."]"..
           "label[0.5,0.5;"..title.."]"
end

-- Main terminal panel
local function terminal_panel_for(player)
    local page = player_pages[player:get_player_name()] or 1
    local text,page,total_pages = get_paged_entries(player,page)
    return "box[0.3,2.2;11.4,7.2;"..C.panel.."]"..
           "textarea[0.5,2.4;11,7;;"..text..";]"..
           "label[5.2,9.5;Page "..page.."/"..total_pages.."]"
end

local function main_footer()
    return "button[0.5,9.8;"..CONFIG.buttons.main_width..",0.9;prev;«]"..
           "button[2.2,9.8;"..CONFIG.buttons.main_width..",0.9;next;»]"..
           "button[4.0,9.8;2.5,0.9;history;History]"..
           "button[6.8,9.8;2.5,0.9;mods;Mods]"..
           "button[9.5,9.8;"..CONFIG.buttons.exit_width..",0.9;exit;✖]"
end

local function main_gui(player)
    return formspec_base()..header_block(CONFIG.titles.main)..terminal_panel_for(player)..main_footer()
end

-- Mods GUI
local function mods_gui(player)
    local name = player:get_player_name()
    local page = player_mod_pages[name] or 1
    local text,page,total_pages = get_paged_mods(player,page)
    local formspec =
        formspec_base()..
        header_block(CONFIG.titles.mods)..
        "box[0.3,2.2;11.4,7.2;"..C.panel.."]"..
        "textarea[0.5,2.4;11,7;;"..text..";]"..
        "label[5.2,9.5;Page "..page.."/"..total_pages.."]"..
        "button[0.5,9.8;"..CONFIG.buttons.main_width..",0.9;prev_mods;«]"..
        "button[2.2,9.8;"..CONFIG.buttons.main_width..",0.9;next_mods;»]"..
        "button[4.0,9.8;1.5,0.9;home_mods;⌂]"..
        "button[9.5,9.8;"..CONFIG.buttons.exit_width..",0.9;exit;✖]"
    minetest.show_formspec(name,"changelog:mods_gui",formspec)
end

-- History GUI
local function history_gui(player)
    local name = player:get_player_name()
    local page = player_history_pages[name] or 1
    local text,page,total_pages = get_paged_history(player,page)
    local formspec =
        formspec_base()..
        header_block(CONFIG.titles.history)..
        "box[0.3,2.2;11.4,7.2;"..C.panel.."]"..
        "textarea[0.5,2.4;11,7;;"..text..";]"..
        "label[5.2,9.5;Page "..page.."/"..total_pages.."]"..
        "button[0.5,9.8;"..CONFIG.buttons.main_width..",0.9;prev_history;«]"..
        "button[2.2,9.8;"..CONFIG.buttons.main_width..",0.9;next_history;»]"..
        "button[4.0,9.8;1.5,0.9;home_history;⌂]"..
        "button[9.5,9.8;"..CONFIG.buttons.exit_width..",0.9;exit;✖]"
    minetest.show_formspec(name,"changelog:history_gui",formspec)
end

-- Show main GUI
local function show(player)
    minetest.show_formspec(player:get_player_name(),"changelog:main",main_gui(player))
end


-- Handle button clicks
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    player_pages[name] = player_pages[name] or 1
    player_mod_pages[name] = player_mod_pages[name] or 1
    player_history_pages[name] = player_history_pages[name] or 1

    if formname=="changelog:main" then
        local unseen = get_unseen_entries(player)
        local total_pages = math.max(1, math.ceil(#unseen/CONFIG.pages.changelog))
        if fields.next then
            player_pages[name] = (player_pages[name] % total_pages) + 1
            show(player)
        elseif fields.prev then
            player_pages[name] = ((player_pages[name]-2+total_pages) % total_pages) + 1
            show(player)
        elseif fields.history then
            player_history_pages[name] = 1
            history_gui(player)
        elseif fields.mods then
            player_mod_pages[name] = 1
            mods_gui(player)
        elseif fields.exit then
            minetest.close_formspec(name,"changelog:main")
        end

    elseif formname=="changelog:mods_gui" then
        local mods = minetest.get_modnames()
        local total_pages = math.max(1, math.ceil(#mods / CONFIG.pages.mods))
        if fields.next_mods then
            player_mod_pages[name] = (player_mod_pages[name] % total_pages) + 1
            mods_gui(player)
        elseif fields.prev_mods then
            player_mod_pages[name] = ((player_mod_pages[name]-2+total_pages) % total_pages) + 1
            mods_gui(player)
        elseif fields.home_mods then
            show(player)
        elseif fields.exit then
            minetest.close_formspec(name,"changelog:mods_gui")
        end

    elseif formname=="changelog:history_gui" then
        local total_pages = math.max(1, math.ceil(#changelog_data / CONFIG.pages.history))
        if fields.next_history then
            player_history_pages[name] = (player_history_pages[name] % total_pages) + 1
            history_gui(player)
        elseif fields.prev_history then
            player_history_pages[name] = ((player_history_pages[name]-2+total_pages) % total_pages) + 1
            history_gui(player)
        elseif fields.home_history then
            show(player)
        elseif fields.exit then
            minetest.close_formspec(name,"changelog:history_gui")
        end
    end
end)


-- Show GUI on join
minetest.register_on_joinplayer(function(player)
    minetest.after(1,function() show(player) end)
end)


-- Chat command
minetest.register_chatcommand("changelog",{
    description="Open Etheria Changelog Terminal",
    func=function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false,"Player not found." end
        show(player)
        return true,"Opening Changelog Terminal..."
    end
})


-- Detect mod changes
local function detect_mod_changes()
    local current_mods = {}
    local mods = minetest.get_modnames()
    for _,modname in ipairs(mods) do
        current_mods[modname] = true
        local path = minetest.get_modpath(modname)
        if path then
            local hash = hash_file(path.."/init.lua")
            if hash then
                local old = mod_hashes[modname]
                if not old then add_mod_event(modname,"installed")
                elseif CONFIG.features.detect_updates and old~=hash then add_mod_event(modname,"updated") end
                mod_hashes[modname] = hash
            end
        end
    end
    if CONFIG.features.detect_removals then
        for old_mod,_ in pairs(mod_hashes) do
            if not current_mods[old_mod] then
                add_mod_event(old_mod,"removed")
                mod_hashes[old_mod] = nil
            end
        end
    end
    save_data("mod_hashes",mod_hashes)
end

minetest.register_on_mods_loaded(function() detect_mod_changes() end)
