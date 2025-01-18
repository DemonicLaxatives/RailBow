local handler = require("__core__.lualib.event_handler")
local mod_gui = require("mod-gui")

--- @class IterationState
--- @field n_steps integer
--- @field last_step integer
--- @field calculation_complete boolean

--- @class MaskCalculation
--- @field tiles table<integer, string>
--- @field tiles_min integer
--- @field tiles_max integer
--- @field rails LuaEntity[]
--- @field drive_directions table<integer, integer>
--- @field p0 [integer, integer]
--- @field tile_map table<integer, table<integer, table<integer, number>>>
--- @field tile_array [integer, integer][]
--- @field iteration_state IterationState

--- @class TileCalculation
--- @field instant_build boolean
--- @field entity_remove_filter table<string>
--- @field mode string
--- @field iteration_state IterationState

--- @class RailBowCalculation
--- @field player_index integer
--- @field mask_calculation MaskCalculation
--- @field tile_calculation TileCalculation
--- @field rb_debug boolean

--- @class RailBowConfig
--- @field name string
--- @field tiles table<integer, string>
--- @field remove_trees boolean
--- @field remove_cliffs boolean

--- @class RailBowSelectionTool
--- @field presets RailBowConfig[]
--- @field selected_preset integer
--- @field opened_preset integer|nil
--- @field copied_tile string|nil

local function initialize_global(player)
    if not player then
        return
    end

    if not storage.railbow_tools[player.index] then
        local init_tiles = {}
        for i = -8, 8 do
            if i ~= 0 then
                init_tiles[i] = nil
            end
        end

        --- @type RailBowConfig
        local init_config = {
            name = "default",
            tiles = init_tiles,
            mode = "vote",
            remove_trees = true,
            remove_cliffs = false
        }

        storage.railbow_tools[player.index] = {
            presets = {init_config},
            selected_preset = 1,
            opened_preset = nil,
            copied_tile = nil
        }
    end
end

local function create_button(player)
    if not player then return end
    local button_flow = mod_gui.get_button_flow(player)
    if not button_flow.railbow_button then
        button_flow.add{
            type = "sprite-button",
            name = "railbow_button",
            sprite = "item/railbow-selection-tool",
            tooltip = {"tooltips.railbow-open-gui"}, 
            style=mod_gui.button_style
        }
    end
end
---@param event EventData.on_player_created
local function on_player_created(event)
    local player = game.get_player(event.player_index)
    initialize_global(player)
    create_button(player)
end
---@param event EventData.on_player_removed
local function on_player_removed(event)
    storage.railbow_tools[event.player_index] = nil
    for i, data in pairs(storage.railbow_calculation_queue) do
        if data.player_index == event.player_index then
            table.remove(storage.railbow_calculation_queue, i)
        end
    end
end

local function on_init()
    --- @type table<integer, RailBowSelectionTool>
    storage.railbow_tools = {}
    --- @type RailBowCalculation[]
    storage.railbow_calculation_queue = {}
    
    for _, player in pairs(game.players) do
        initialize_global(player)
        create_button(player)
    end
end


local control = {}

control.on_init = on_init

control.events = {
    [defines.events.on_player_created] = on_player_created,
    [defines.events.on_player_removed] = on_player_removed
}

handler.add_libraries({
    control,
    require("scripts.selection"),
    require("scripts.gui"),
    require("scripts.calculator"),
})