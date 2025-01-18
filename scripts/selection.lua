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

---@param player LuaPlayer|any
---@param event EventData|any
---@param selection_tool_mode string
local function set_up_calculation(player, event, selection_tool_mode)
    local selection_tool = storage.railbow_tools[player.index]
    local selected_preset = selection_tool.presets[selection_tool.selected_preset]
    local tiles = selected_preset.tiles

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

    local signals, rails = seperate_signals_and_rails(event.entities)

    if #rails <= 0 then -- no need to go any further with no rails
        return
    end

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

    local entity_remove_filter = {}

    if selected_preset.remove_trees then
        table.insert(entity_remove_filter, "tree")
        table.insert(entity_remove_filter, "simple-entity")
    end
    if selected_preset.remove_cliffs then
        table.insert(entity_remove_filter, "cliff")
    end

    --- @type TileCalculation
    local tile_calculation = {
        instant_build = instant_build,
        iteration_state = {
            n_steps = 0,
            last_step = 0,
            calculation_complete = false
        },
        entity_remove_filter = entity_remove_filter,
        mode = selection_tool_mode
    }

    local rb_debug
    if settings.get_player_settings(player)["railbow-debug"].value then rb_debug = true rendering.clear("RailBow-Refracted") end

    --- @type RailBowCalculation
    local railbow_calculation = {
        player_index = player.index,
        mask_calculation = mask_calculation,
        tile_calculation = tile_calculation,
        rb_debug = rb_debug
    }

    table.insert(storage.railbow_calculation_queue, railbow_calculation)
end

---@param player any
---@param event EventData|table
local function check_valid(player, event)
        if event.item ~= "railbow-selection-tool" then
            return false
        end
        if not player then
            return false
        end
        if settings.get_player_settings(player)["railbow-debug"].value then log(serpent.block(event.area)) end
        rendering.clear("RailBow-Refracted")
        if not next(event.entities) then
            return false
        end
        return true
    end

---@param event EventData.on_player_selected_area
local function on_player_selected_area(event)
    local player = game.get_player(event.player_index)
    if not check_valid(player, event) then return end
    set_up_calculation(player, event, "normal")
end

---@param event EventData.on_player_alt_selected_area
local function on_player_alt_selected_area(event)
    local player = game.get_player(event.player_index)
    if not check_valid(player, event) then return end
    set_up_calculation(player, event, "shift")
end

---@param event EventData.on_player_reverse_selected_area
local function on_player_reverse_selected_area(event)
    local player = game.get_player(event.player_index)
    if not check_valid(player, event) then return end
    set_up_calculation(player, event, "remove_tiles")
end

---@param event EventData.on_player_alt_reverse_selected_area
local function on_player_alt_reverse_selected_area(event)
    local player = game.get_player(event.player_index)
    if not check_valid(player, event) then return end
    set_up_calculation(player, event, "remove_ents")
end

local selection = {}

selection.events = {
    [defines.events.on_player_selected_area] = on_player_selected_area,
    [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
    [defines.events.on_player_reverse_selected_area] = on_player_reverse_selected_area,
    [defines.events.on_player_alt_reverse_selected_area] = on_player_alt_reverse_selected_area
}

return selection