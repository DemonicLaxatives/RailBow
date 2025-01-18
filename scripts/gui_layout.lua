local gui_elements = require("scripts.gui_elements")
local gui_interactions = require("scripts.gui_interactions")

local lib = {}

--- @param player LuaPlayer
function lib.create_railbow_window(player)
    local railbow_tool = storage.railbow_tools[player.index]

    local frame = player.gui.screen.add{
        type = "frame",
        name = "railbow_window",
        direction = "vertical"
    }
    frame.location = {75, 75}
    player.opened = frame

    gui_elements.main_title_bar(frame, "titles.railbow-gui-title")

    frame.add{
        type = "flow",
        name = "configuration_flow",
        direction = "horizontal"
    }
    
    local selection_frame = gui_elements.preset_selection_frame(frame.configuration_flow)
    gui_elements.preset_list_header(selection_frame)
    local preset_list = gui_elements.preset_list(selection_frame)
    gui_elements.populate_preset_list(preset_list)

    if railbow_tool.opened_preset then
        gui_interactions.open_preset(frame.configuration_flow)
    end
end

function lib.create_export_string_window(player)
    if player.gui.screen.export_string_window then
        player.gui.screen.export_string_window.destroy()
    end
    local frame = player.gui.screen.add{
        type = "frame",
        name = "export_string_window",
        direction = "vertical"
    }
    frame.location = {75, 75}

    gui_elements.main_title_bar(frame, "titles.railbow-export-preset")

    frame.add{
        type = "flow",
        name = "export_string_flow",
        direction = "horizontal"
    }

    gui_elements.export_string_input(frame.export_string_flow)
end

function lib.create_import_string_window(player)
    if player.gui.screen.import_string_window then
        player.gui.screen.import_string_window.destroy()
    end
    local frame = player.gui.screen.add{
        type = "frame",
        name = "import_string_window",
        direction = "vertical"
    }
    frame.location = {75, 75}

    gui_elements.main_title_bar(frame, "titles.railbow-import-preset")

    frame.add{
        type = "flow",
        name = "import_string_flow",
        direction = "vertical"
    }

    gui_elements.import_string_input(frame.import_string_flow)
    gui_elements.import_string_button(frame.import_string_flow)
end

return lib