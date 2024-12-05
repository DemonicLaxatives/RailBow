local filter = {
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

if mods["elevated-rails"] then
  table.insert(filter, "rail-ramp")       
  for _, rail in pairs(base_rail_list) do
    table.insert(filter, "elevated-" .. rail)
  end
end

if mods["naked-rails-f2"] then
    for _, rail in pairs(base_rail_list) do
        table.insert(filter, "naked-"..rail)     
        table.insert(filter, "sleepy-"..rail)
    end    
end

table.insert(filter, "rail-signal")
table.insert(filter, "rail-chain-signal")

data:extend({
  {
    type = "selection-tool",
    name = "railbow-selection-tool",
    icon = "__RailBow__/graphics/railbow-selection-tool.png",
    icon_size = 64,
    select = {
      border_color = { r = 1, g = 0.5, b = 0 },
      cursor_box_type = "train-visualization",
      mode = "any-entity",
      entity_filters = filter
    },

    alt_select = {
      border_color = { r = 1, g = 0.5, b = 0 },
      cursor_box_type = "train-visualization",
      mode = "any-entity",
      entity_filters = filter
    },
    

    stack_size = 1,
    flags = {"hide-from-bonus-gui", "only-in-cursor", "not-stackable"},
  }
})