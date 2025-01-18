local drive_directions = require("scripts.direction")
local math2d = require("__core__.lualib.math2d")
																						   
local rail_list = {
    "curved-rail-a",
    "curved-rail-b",
    "straight-rail",
    "half-diagonal-rail",
}
local static base_rail_list = {
    "curved-rail-a",
    "curved-rail-b",
    "straight-rail",
    "half-diagonal-rail",
}

if script.active_mods["elevated-rails"] then
	table.insert(rail_list, "rail-ramp")
	for _, rail in pairs(base_rail_list) do
        table.insert(rail_list, "elevated-"..rail)
    end  
	log("elevated rails found and added")
end

if script.active_mods["naked-rails-f2"] then
    for _, rail in pairs(base_rail_list) do
        table.insert(rail_list, "naked-"..rail)     
        table.insert(rail_list, "sleepy-"..rail)
    end
	log("naked rails found and added")
end
local signal_list = {"rail-signal", "rail-chain-signal"}

local function contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

table.contains = contains

local function seperate_signals_and_rails(entities)
    local signals = {}
    local rails = {}
    for _, entity in pairs(entities) do
        if table.contains(rail_list, entity.type) then
            table.insert(rails, entity)
        elseif table.contains(signal_list, entity.type) then
            table.insert(signals, entity)
        end
    end
    return signals, rails
end

local function entity_pos_to_built_pos(entity)
	if entity ~= nil then                    --prevent crash when only selecting rail signal
		return math2d.position.add(entity.position, {0.5, 0.5})
	end
end

local function set_up_calculation(player, e)
    local selection_tool = storage.railbow_tools[player.index]
    local tiles = selection_tool.presets[selection_tool.selected_preset].tiles

    local has_tiles = false
    for _, tile in pairs(tiles) do
        if tile ~= nil then
            has_tiles = true
            break
        end
    end
    if not has_tiles then
        return
    end

    --- @type table<integer, string>
    local tiles_copy = {}
    local tiles_min = 10
    local tiles_max = -10
    for i, tile in pairs(tiles) do
        tiles_copy[i] = tile
        if tile ~= nil then
            if i < tiles_min then
                tiles_min = i
            end
            if i > tiles_max then
                tiles_max = i
            end
        end
    end

    local signals, rails = seperate_signals_and_rails(e.entities)

    --- @type MaskCalculation
    local mask_calculation = {
        tiles = tiles_copy,
        tiles_min = tiles_min,
        tiles_max = tiles_max,
        rails = rails,
        drive_directions = drive_directions.get_all(signals, rails),
        p0 = entity_pos_to_built_pos(rails[1]),
        tile_map = {},
        tile_array = {},
        iteration_state = {
            n_steps = #rails,
            last_step = 0,
            calculation_complete = false
        }
    }

    local instant_build = false
    if settings.get_player_settings(player)["railbow-instant-build"].value then
        if player.cheat_mode then
            instant_build = true
        elseif player.controller_type == defines.controllers.editor then
            instant_build = true
        elseif player.controller_type == defines.controllers.god then
            instant_build = true
        end
    end

    --- @type TileCalculation
    local tile_calculation = {
        instant_build = instant_build,
        iteration_state = {
            n_steps = 0,
            last_step = 0,
            calculation_complete = false
        }
    }

    --- @type RailBowCalculation
    local railbow_calculation = {
        player_index = player.index,
        inventory = game.create_inventory(1),
        mask_calculation = mask_calculation,
        tile_calculation = tile_calculation
    }

    table.insert(storage.railbow_calculation_queue, railbow_calculation)
end

local function on_player_selected_area(e)
    if e.item ~= "railbow-selection-tool" then
        return
    end
    if not next(e.entities) then
        return
    end
    local player = game.get_player(e.player_index)
    if not player then
        return
    end
    set_up_calculation(player, e)
end

local selection = {}

selection.events = {
    [defines.events.on_player_selected_area] = on_player_selected_area
}

return selection