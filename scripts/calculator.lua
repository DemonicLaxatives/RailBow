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

    local rail_calculations_per_tick = settings.global["railbow-rail-calculations-per-tick"].value
    local i0 = iteration_state.last_step + 1
    local i1 = math.min(iteration_state.last_step + rail_calculations_per_tick, iteration_state.n_steps)

    local p0 = mask_calculation.p0
    local tile_min = mask_calculation.tiles_min
    local tile_max = mask_calculation.tiles_max
    local tile_map = mask_calculation.tile_map
    local tile_array = mask_calculation.tile_array
    local offset = not railbow_calculation.tile_calculation.instant_build

    for i = i0, i1 do
        local entity = mask_calculation.rails[i]
        local pos_i = entity_pos_to_built_pos(entity)
        if offset then
            pos_i = math2d.position.subtract(entity_pos_to_built_pos(entity), p0)
        end
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

---@param railbow_calculation RailBowCalculation
---@return RailBowCalculation
local function do_tile_picking(railbow_calculation)
    local mask_calculation = railbow_calculation.mask_calculation
    local tile_calculation = railbow_calculation.tile_calculation

    local iteration_state = tile_calculation.iteration_state
    local blueprint_tiles = {}
    local tile_map = mask_calculation.tile_map
    local tile_array = mask_calculation.tile_array
    local tiles = mask_calculation.tiles

    local tile_calculations_per_tick = settings.global["railbow-tile-calculations-per-tick"].value
    local i0 = iteration_state.last_step + 1
    local i1 = math.min(iteration_state.last_step + tile_calculations_per_tick, iteration_state.n_steps)

    for i = i0, i1 do
        local pos = {x = tile_array[i][1], y = tile_array[i][2]}
        local tile_weights = tile_map[pos.x][pos.y]
        local d = methods.vote(tile_weights)
        local name = tiles[d]
        if name then
            table.insert(blueprint_tiles, {name = name, position = pos})
        end
    end
	if railbow_calculation.mask_calculation.rails[1] ~= nil then           -- prevent crash when only selecting rail signal
		if tile_calculation.instant_build then
			railbow_calculation.mask_calculation.rails[1].surface.set_tiles(blueprint_tiles)
		else
				railbow_calculation.inventory.insert({name = "blueprint", count = 1})
				local blueprint = railbow_calculation.inventory[1]
				blueprint.blueprint_absolute_snapping = true
				blueprint.blueprint_snap_to_grid = {x = 1, y = 1}
				blueprint.blueprint_position_relative_to_grid = { x = 0, y = 0 }
				blueprint.set_blueprint_tiles(blueprint_tiles)

					blueprint.build_blueprint{
							surface = railbow_calculation.mask_calculation.rails[1].surface,
							force = game.players[railbow_calculation.player_index].force,
							position = railbow_calculation.mask_calculation.p0,
							force_build = true,
							by_player = game.players[railbow_calculation.player_index],
							create_build_effect_smoke = false,
					}
			railbow_calculation.inventory.clear()
		end
	else
		return
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