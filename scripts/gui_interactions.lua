local gui_elements = require("scripts.gui_elements")
local util = require("__core__.lualib.util")

local lib = {}
---@param player LuaPlayer
---@param tiles table<integer, string>|nil
---@param preset_name string|nil
function lib.add_preset(player, tiles, preset_name)
    local railbow_tool = storage.railbow_tools[player.index]
    local presets = railbow_tool.presets
    local n_presets = #presets

    if not tiles then
        tiles = {}
    end

    if not preset_name then
        preset_name = "preset_" .. n_presets + 1
    end

    local new_preset = {
        name = preset_name,
        tiles = tiles,
        mode = "vote"
    }
    table.insert(storage.railbow_tools[player.index].presets, new_preset)
    
    local list = player.gui.screen.railbow_window.configuration_flow.selection_frame.preset_list
    gui_elements.preset_selector(list, n_presets + 1)
end

--- @param flow LuaGuiElement
function lib.open_preset(flow)
    if flow.tile_selection_frame then
        flow.tile_selection_frame.destroy()
    end
    local tile_selection_frame = gui_elements.tile_selection_frame(flow)
    gui_elements.elem_choose_header(tile_selection_frame)
    gui_elements.choose_elem_table(tile_selection_frame)

    local player = game.get_player(flow.player_index)
    if not player then return end
    local buttons = player.gui.screen.railbow_window.configuration_flow.selection_frame.header
    buttons.copy_preset_button.enabled = true
    buttons.export_preset_button.enabled = true
end

--- @param player LuaPlayer
function lib.close_preset(player)
    local railbow_tool = storage.railbow_tools[player.index]
    local conf = player.gui.screen.railbow_window.configuration_flow
    if conf.tile_selection_frame then
        conf.tile_selection_frame.destroy()
    end
    railbow_tool.opened_preset = nil

    local buttons = conf.selection_frame.header
    buttons.copy_preset_button.enabled = false
    buttons.export_preset_button.enabled = false
end

--- @param player LuaPlayer
--- @param index integer
function lib.change_selected_preset(player, index)
    local railbow_tool = storage.railbow_tools[player.index]
    local gui_list = player.gui.screen.railbow_window.configuration_flow.selection_frame.preset_list
    gui_list["preset_flow_" .. railbow_tool.selected_preset].preset_selection.state = false
    gui_list["preset_flow_" .. index].preset_selection.state = true
    railbow_tool.selected_preset = index
end

--- @param player LuaPlayer
--- @param index integer
--- @param toggled boolean
function lib.change_opened_preset(player, index, toggled)
    local railbow_tool = storage.railbow_tools[player.index]

    local conflow = player.gui.screen.railbow_window.configuration_flow

    local previous_index = railbow_tool.opened_preset
    if not toggled then
        lib.close_preset(player)
        return
    end
    railbow_tool.opened_preset = index
    lib.change_selected_preset(player, index)
    if not previous_index then
        lib.open_preset(conflow)
        return
    end
    
    local old_flow = conflow.selection_frame.preset_list["preset_flow_" .. previous_index]
    old_flow.preset_button.toggled = false

    if not railbow_tool.presets[index].tiles then
        railbow_tool.presets[index].tiles = {}
    end

    local opened_tiles = railbow_tool.presets[index].tiles
    local frame = conflow.tile_selection_frame

    frame.header.preset_name.text = railbow_tool.presets[index].name

    for i, element in pairs(frame.table.children) do
        if string.find(element.name, "tile_selector_") then
            local index_ = tonumber(element.name:match("([+-]?%d+)$"))
            if index_ then
                local status, _ = pcall(function()
                    element.elem_value = opened_tiles[index_]
                end)
                if not status then
                    player.print("[color=red]Error: Invalid tile in preset, defaulting to nil.[/color]")
                    element.elem_value = nil
                    opened_tiles[index_] = nil
                end
            end
        end
    end

end

function lib.delete_preset(player)
    local railbow_tool = storage.railbow_tools[player.index]
    local opened_preset = railbow_tool.opened_preset
    local selected_preset = railbow_tool.selected_preset
    local presets = railbow_tool.presets
    local n_presets = #presets

    if n_presets == 1 then
        player.print("You can't delete the last preset.")
        return
    end

    table.remove(presets, opened_preset)
    if opened_preset <= selected_preset then
        if selected_preset == 1 then
            railbow_tool.selected_preset = 1
        else
            railbow_tool.selected_preset = selected_preset - 1
        end
    end

    railbow_tool.opened_preset = nil
    lib.close_preset(player)

    gui_elements.populate_preset_list(player.gui.screen.railbow_window.configuration_flow.selection_frame.preset_list)
end

function lib.copy_preset(player)
    local railbow_tool = storage.railbow_tools[player.index]
    local opened_preset = railbow_tool.opened_preset
    if not opened_preset then return end
    local presets = railbow_tool.presets
    local n_presets = #presets

    local new_preset = {
        name = presets[opened_preset].name .. " - copy",
        tiles = util.table.deepcopy(presets[opened_preset].tiles),
        mode = "vote"
    }

    table.insert(presets, new_preset)
    gui_elements.preset_selector(player.gui.screen.railbow_window.configuration_flow.selection_frame.preset_list, n_presets + 1)
end

function lib.tile_selector_clicked(event)
    local element = event.element
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then return end
    if not element.name:find("tile_selector_") then return end

    local index = tonumber(element.name:match("([+-]?%d+)$"))
    if not index then return end

    local railbow_tool = storage.railbow_tools[player_index]
    local window = player.gui.screen.railbow_window
    local frame = window.configuration_flow.tile_selection_frame
    local selector = frame.table["tile_selector_" .. index]
    if event.shift then
        if event.button == defines.mouse_button_type.right then
            railbow_tool.copied_tile = railbow_tool.presets[railbow_tool.opened_preset].tiles[index]
            selector.elem_value = railbow_tool.copied_tile
        elseif event.button == defines.mouse_button_type.left then
            if railbow_tool.copied_tile then
                railbow_tool.presets[railbow_tool.opened_preset].tiles[index] = railbow_tool.copied_tile
                selector.elem_value = railbow_tool.copied_tile
                return true
            end
        end
    else
        if event.button == defines.mouse_button_type.right then
            railbow_tool.presets[railbow_tool.opened_preset].tiles[index] = nil
            selector.elem_value = nil
        end
    end
    return false
end

--- @param player LuaPlayer
function lib.import_preset(player)
    local import_string = player.gui.screen.import_string_window.import_string_flow.import_string_input.text
    local json = helpers.decode_string(import_string)
    if not json then
        player.print("[color=red]Error: Invalid import string, not a json.[/color]")
        return
    end
    local preset = helpers.json_to_table(json)
    if not preset then
        player.print("[color=red]Error: Invalid import string, not a table.[/color]")
        return
    end
    if not preset.name or not preset.tiles then
        player.print("[color=red]Error: Invalid import string, missing fields.[/color]")
        return
    end
    local tiles = {}
    for i, tile in pairs(preset.tiles) do
        j = tonumber(i)
        if j then
            tiles[j] ="invalid" --- tile
        end
    end
    lib.add_preset(player, tiles, preset.name)
end

return lib