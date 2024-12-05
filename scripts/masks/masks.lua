local curved_rail_a = require("scripts.masks.curved_rail_a")
local curved_rail_b = require("scripts.masks.curved_rail_b")
local straight_rail = require("scripts.masks.straight_rail")
local half_diagonal_rail = require("scripts.masks.half_diagonal_rail")

--- @class TileInfo
--- @field pos Vector
--- @field n Vector
--- @field o boolean

--- @class Mask
--- @field table table<integer, TileInfo[]>|nil

local masks = {
    ["curved-rail-a"] = curved_rail_a,
    ["curved-rail-b"] = curved_rail_b,
    ["straight-rail"] = straight_rail,
    ["half-diagonal-rail"] = half_diagonal_rail,
}

if script.active_mods["elevated-rails"] then
    masks["elevated-curved-rail-a"] = masks["curved-rail-a"]
    masks["elevated-curved-rail-b"] = masks["curved-rail-b"]
    masks["elevated-straight-rail"] = masks["straight-rail"]
    masks["elevated-half-diagonal-rail"] = masks["half-diagonal-rail"]
    masks["rail-ramp"] = require("scripts.masks.rail_ramp")
end

if script.active_mods["naked-rails-f2"] then
    masks["naked-curved-rail-a"] = masks["curved-rail-a"]
    masks["naked-curved-rail-b"] = masks["curved-rail-b"]
    masks["naked-straight-rail"] = masks["straight-rail"]
    masks["naked-half-diagonal-rail"] = masks["half-diagonal-rail"]    
    masks["sleepy-curved-rail-a"] = masks["curved-rail-a"]
    masks["sleepy-curved-rail-b"] = masks["curved-rail-b"]
    masks["sleepy-straight-rail"] = masks["straight-rail"]
    masks["sleepy-half-diagonal-rail"] = masks["half-diagonal-rail"]
end

return masks
