local layout = require("scripts.gui_layout")
local interactions = require("scripts.gui_interactions")
local elements = require("scripts.gui_elements")

local function close_main_gui(player)
    if player.gui.screen.railbow_window then
        player.gui.screen.railbow_window.destroy()
    end
    if player.gui.screen.export_string_window then
        player.gui.screen.export_string_window.destroy()
    end
    if player.gui.screen.import_string_window then
        player.gui.screen.import_string_window.destroy()
    end
end

local function open_gui(player)
    if player.gui.screen.railbow_window then
        close_main_gui(player)
    else
        layout.create_railbow_window(player)
    end
end

local function gui_click(e)
    local element = e.element
    if not element.valid then return end
    local player = game.get_player(e.player_index)
    if not player then return end

    if element.get_mod() ~= "RailBow" then return end
    if element.name == "railbow_button" then
        open_gui(player)
    elseif element.name == "close_button" then
        local window = element.parent.parent
        if window then
            if window.name == "railbow_window" then
                close_main_gui(player)
            else
                window.destroy()
            end
        end
    elseif element.name == "add_preset_button" then
        interactions.add_preset(player)
    elseif element.name == "preset_button" then
        local index = tonumber(element.parent.name:match("([+-]?%d+)$"))
        if index then
            interactions.change_opened_preset(player, index, element.toggled)
        end
    elseif element.name == "delete_preset_button" then
        interactions.delete_preset(player)
    elseif element.name == "copy_preset_button" then
        interactions.copy_preset(player)
    elseif element.name:find("tile_selector_") then
        local reset_gui = interactions.tile_selector_clicked(e)
        if reset_gui then
            close_main_gui(player)
            open_gui(player)
        end
    elseif element.name == "export_preset_button" then
        layout.create_export_string_window(player)
    elseif element.name == "import_preset_button" then
        layout.create_import_string_window(player)
    elseif element.name == "import_string_button" then
        interactions.import_preset(player)
        element.parent.parent.destroy()
    end
end

local function gui_closed(e)
    local player = game.get_player(e.player_index)
    if not player then return end
    if e.element and e.element.name == "railbow_window" then
        close_main_gui(player)
    end
end

local function selector_changed(event)
    local element = event.element
    local player_index = event.player_index
    if string.find(element.name, "tile_selector_") then
        local index = tonumber(element.name:match("([+-]?%d+)$"))
        if index then
            if element.elem_value then
                local opened_preset = storage.railbow_tools[player_index].opened_preset
                storage.railbow_tools[player_index].presets[opened_preset].tiles[index] = element.elem_value
            end
        end
    end
end

local function text_changed(event)
    local element = event.element
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then return end
    if element.name == "preset_name" then
        local railbow_tool = storage.railbow_tools[player_index]
        local opened_preset = railbow_tool.opened_preset
        railbow_tool.presets[opened_preset].name = element.text
        player.gui.screen.railbow_window.configuration_flow.selection_frame.preset_list["preset_flow_" .. opened_preset].preset_button.caption = element.text
    end
end

local function checked_state_changed(event)
    local element = event.element
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then return end
    if element.name == "preset_selection" then
        local index = tonumber(element.parent.name:match("([+-]?%d+)$"))
        if index then
            interactions.change_selected_preset(player, index)
        end
    end
end

local gui = {}

gui.events = {
    [defines.events.on_gui_click] = gui_click,
    [defines.events.on_gui_elem_changed] = selector_changed,
    [defines.events.on_gui_closed] = gui_closed,
    [defines.events.on_gui_confirmed] = text_changed,
    [defines.events.on_gui_checked_state_changed] = checked_state_changed,
}

return gui