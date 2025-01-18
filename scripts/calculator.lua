local math2d = require("__core__.lualib.math2d")
local masks = require("scripts.masks.masks")
local drive_directions = require("scripts.direction")

local function entity_pos_to_built_pos(entity)
    return math2d.position.add(entity.position, {0.5, 0.5})
end

local function weight(d)
    return 1/(math.abs(d)^6)
end

---@param railbow_calculation RailBowCalculation
---@return RailBowCalculation
local function do_mask_accumulation(railbow_calculation)
    local mask_calculation = railbow_calculation.mask_calculation
    local iteration_state = mask_calculation.iteration_state

    if mask_calculation.rails[1] == nil then           -- prevent crash when only selecting rail signal
        iteration_state.calculation_complete = true
        return railbow_calculation
    end

    local rail_calculations_per_tick = settings.global["railbow-rail-calculations-per-tick"].value

    local i0 = iteration_state.last_step + 1
    local i1 = math.min(iteration_state.last_step + rail_calculations_per_tick, iteration_state.n_steps)

    local p0 = mask_calculation.p0
    local tile_min = mask_calculation.tiles_min
    local tile_max = mask_calculation.tiles_max
    local tile_map = mask_calculation.tile_map
    local tile_array = mask_calculation.tile_array

    for i = i0, i1 do
        local entity = mask_calculation.rails[i]
        local pos_i = entity_pos_to_built_pos(entity)
        local mask = masks[entity.name]
        if mask then
            mask = mask[entity.direction]
            for d, elem_i in pairs(mask) do
                local d_map = drive_directions.mapper[mask_calculation.drive_directions[entity.unit_number]]
                local d_ = d_map(d)
                if d_ >= tile_min or d_ <= tile_max then
                    local w = weight(d)
                    for _, elem_j in pairs(elem_i) do
                        local pos_j = math2d.position.add(pos_i, elem_j.pos)
                        if not tile_map[pos_j.x] then
                            tile_map[pos_j.x] = {}
                        end
                        if not tile_map[pos_j.x][pos_j.y] then
                            tile_map[pos_j.x][pos_j.y] = {}
                            table.insert(tile_array, {pos_j.x, pos_j.y})
                        end
                        if not tile_map[pos_j.x][pos_j.y][d_] then
                            tile_map[pos_j.x][pos_j.y][d_] = 0.0
                        end
                        if elem_j.o then
                            tile_map[pos_j.x][pos_j.y][d_] = tile_map[pos_j.x][pos_j.y][d_] + w/2
                        else
                            tile_map[pos_j.x][pos_j.y][d_] = tile_map[pos_j.x][pos_j.y][d_] + w
                        end
                    end
                end
            end
        end
    end
    iteration_state.last_step = i1
    if iteration_state.last_step == iteration_state.n_steps then
        iteration_state.calculation_complete = true
        railbow_calculation.tile_calculation.iteration_state.n_steps = #tile_array
    end
    mask_calculation.tile_map = tile_map
    mask_calculation.tile_array = tile_array
    mask_calculation.iteration_state = iteration_state
    railbow_calculation.mask_calculation = mask_calculation
    return railbow_calculation
end

---@param tile Tile
---@param railbow_calculation RailBowCalculation
---@param area_size integer
local function remove_environmental_single(tile, railbow_calculation, area_size)


    local surface = railbow_calculation.mask_calculation.rails[1].surface
    local player = game.players[railbow_calculation.player_index]
    tile_pos1 = math2d.position.add(tile.position, {-area_size, -area_size})
    tile_pos2 = math2d.position.add(tile.position, {area_size, area_size}) -- make a area_size*2 square area to find entities in

    if railbow_calculation.rb_debug then
        rendering.draw_rectangle{
            color={0, 0, 1, 0.2},--rgba
            left_top=tile_pos1,
            right_bottom=tile_pos2,
            surface=surface,time_to_live=3600,--60 seconds
            draw_on_ground=true
        }
    end

    if #railbow_calculation.tile_calculation.entity_remove_filter == 0 then return end
    wald = surface.find_entities_filtered
    {
        area = {tile_pos1, tile_pos2},
        type = railbow_calculation.tile_calculation.entity_remove_filter
    }

    for _, eiche in pairs(wald) do
        if eiche ~= nil and eiche.valid then
            if not (eiche.type == "simple-entity" and not eiche.prototype.count_as_rock_for_filtered_deconstruction)
            then
                if railbow_calculation.rb_debug then rendering.draw_circle {
                    color={0,1,0,0.1},
                    radius=0.1,
                    filled=true,
                    target=eiche.position,
                    surface = surface,
                    time_to_live=3600--60 seconds
                } end

                if railbow_calculation.tile_calculation.instant_build then
                    eiche.destroy()
                else
                    eiche.order_deconstruction(player.force, player)
                end
            end
        end
    end
end


--- @param tile_weights table<integer, number>
--- @return integer
local function weighted_tile_vote(tile_weights)
    local max = 0
    local max_d = 0
    for d, w in pairs(tile_weights) do
        if w > max then
            max = w
            max_d = d
        end
    end
    return max_d
end

function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

--- @param tile_weights table<integer, number>
--- @return integer
local function weighted_tile_average(tile_weights)
    local total = 0
    local sum = 0
    for d, w in pairs(tile_weights) do
        total = total + w
        sum = sum + w * d
    end
    local result = round(sum / total)
    if result == 0 then
        return 1
    end
    return result
end

--- @param tile_weights table<integer, number>
--- @return integer
local function nearest_tile(tile_weights)
    local min = math.huge
    local min_d = 0
    for d, _ in pairs(tile_weights) do
        if math.abs(d) < min then
            min = math.abs(d)
            min_d = d
        end
    end
    return min_d
end

local methods = {
    vote = weighted_tile_vote,
    average = weighted_tile_average,
    nearest = nearest_tile
}

---@param field table
---@param key string
local function field_contains(field, key)
    return field[key] ~= nil
end

---@param railbow_calculation RailBowCalculation
---@return RailBowCalculation
local function do_tile_picking(railbow_calculation)
    local mask_calculation = railbow_calculation.mask_calculation
    local tile_calculation = railbow_calculation.tile_calculation

    local blueprint_tiles = {}
    local tile_map = mask_calculation.tile_map
    local tiles = mask_calculation.tiles

    local surface = mask_calculation.rails[1].surface
    local player = game.players[railbow_calculation.player_index]
    local force = player.force
    local rb_debug = railbow_calculation.rb_debug

    local tile_calculations_per_tick
    local iteration_state = tile_calculation.iteration_state
    if rb_debug then tile_calculations_per_tick = 10 else
    tile_calculations_per_tick = settings.global["railbow-tile-calculations-per-tick"].value end
    local i0 = iteration_state.last_step + 1
    local i1 = math.min(iteration_state.last_step + tile_calculations_per_tick, iteration_state.n_steps)


    local tile_array = mask_calculation.tile_array
    for i = i0, i1 do
        local pos = {x = tile_array[i][1], y = tile_array[i][2]}
        local tile_weights = mask_calculation.tile_map[pos.x][pos.y]
        local d = methods.vote(tile_weights)
        local name = mask_calculation.tiles[d]
        if name then
            table.insert(blueprint_tiles, {name = name, position = pos})
            remove_environmental_single({name = name, position = pos}, railbow_calculation, 2)
        end
    end

    local build_mode = tile_calculation.mode

    if tile_calculation.instant_build and (build_mode == "normal" or build_mode == "shift") then
            surface.set_tiles(blueprint_tiles,true,false,true,false,player,0)
    else
        local old_tile = nil
        local default_cover = nil
        local foundation_built = false
        local skip_placement = false

        for _, new_tile in pairs(blueprint_tiles) do
            skip_placement = false
            old_tile = surface.get_tile(new_tile.position.x, new_tile.position.y)
            for _, tile_ghost in pairs(old_tile.get_tile_ghosts()) do
                if tile_ghost.ghost_name == new_tile.name then
                    tile_ghost.cancel_deconstruction(force, player)
                    skip_placement = true
                end
                if (build_mode == "remove_tiles") then
                    tile_ghost.order_deconstruction(force,player)
                    tile_ghost.destroy()
                end
            end

            if (old_tile.name == new_tile.name) and (build_mode == "normal" or build_mode == "shift") then
                    old_tile.cancel_deconstruction(force, player)
                skip_placement = true
            end

            if (build_mode == "remove_tiles") then
                old_tile.order_deconstruction(force, player)
            elseif (not skip_placement) and (build_mode == "normal" or build_mode == "shift") then
                default_cover = old_tile.prototype.default_cover_tile
                if (build_mode == "shift" and default_cover ~= nil) then
                    surface.create_entity {
                        name        = "tile-ghost",
                        inner_name  = default_cover.name,
                        position    = new_tile.position,
                        force       = player.force,
                        remove_colliding_decoratives = true,
                        player      = player,
                        raise_built = true
                    }
                    foundation_built = true
                end

                if field_contains(old_tile.prototype.collision_mask.layers, "ground_tile") or foundation_built then
                    surface.create_entity {
                        name        = "tile-ghost",
                        inner_name  = new_tile.name,
                        position    = new_tile.position,
                        force       = player.force,
                        remove_colliding_decoratives = true,
                        player      = player,
                        raise_built = true
                    }
                end
            end
        end
    end
    iteration_state.last_step = i1
    if iteration_state.last_step == iteration_state.n_steps then
        iteration_state.calculation_complete = true
    end
    tile_calculation.iteration_state = iteration_state
    railbow_calculation.tile_calculation = tile_calculation
    return railbow_calculation
end

local function work()
    if not storage.railbow_calculation_queue then
        return
    end
    local railbow_calculation = storage.railbow_calculation_queue[1]
    if not railbow_calculation then
        return
    end

    if not railbow_calculation.mask_calculation.iteration_state.calculation_complete then
        storage.railbow_calculation_queue[1] = do_mask_accumulation(railbow_calculation)
        return
    end

    if railbow_calculation.mask_calculation.iteration_state.calculation_complete then
        if not railbow_calculation.tile_calculation.iteration_state.calculation_complete then
            storage.railbow_calculation_queue[1] = do_tile_picking(railbow_calculation)
            return
        end
    end
    table.remove(storage.railbow_calculation_queue, 1)
end

local calculator = {}

calculator.events = {
    [defines.events.on_tick] = work
}

return calculator