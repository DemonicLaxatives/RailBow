local font_start = "[font=default-semibold][color=255, 230, 192]"
local font_end = "[/color][/font]"
local line_start = "\n  •   "

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
    name = "railbow-selection-tool",
    type = "selection-tool",
    order = "c[automated-construction]-s[railbow-selection-tool]",
    select = { --normal
      border_color = { r = 0, g = 1, b = 0 },
      cursor_box_type = "train-visualization",
      mode = "any-entity",
      entity_filters = filter
    },
    
    alt_select = { --forced
      border_color = { r = 0, g = 0, b = 1 },
      cursor_box_type = "train-visualization",
      mode = "any-entity",
      entity_filters = filter
    },
    reverse_select = { --remove_tiles
      border_color = { r = 1, g = 0, b = 0 },
      cursor_box_type = "not-allowed",
      mode = "deconstruct",
      entity_filters = filter
    },
    alt_reverse_select = { --remove_ents
      border_color = { r = 1, g = 0.5, b = 0 },
      cursor_box_type = "not-allowed",
      mode = "deconstruct",
      entity_filters = filter
    },
    icon = "__RailBow-Refracted__/graphics/railbow-selection-tool.png",
    icon_size = 64,
    stack_size = 1,
    subgroup = "tool",
    hidden = false,
    flags = {"not-stackable", "only-in-cursor", "spawnable"},
    localised_description = {
      "",
      {"item-description.railbow-selection-tool"},
      "\n",
      font_start,
      {"gui.instruction-when-in-cursor"},
      ":",
      line_start,
      {"item-description.railbow-selection-tool-place-tiles", "__CONTROL_LEFT_CLICK__"},
      line_start,
      {"item-description.railbow-selection-tool-place-forced", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_LEFT_CLICK__"},
      line_start,
      {"item-description.railbow-selection-tool-remove-tiles", "__CONTROL_RIGHT_CLICK__"},
      line_start,
      {"item-description.railbow-selection-tool-remove-ents", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_RIGHT_CLICK__"},
      "\n",
      font_end,
    }
  },
  {
    name = "railbow-get-selection-tool",
    type = "shortcut",
    order = "b[blueprints]-s[railbow-selection-tool]",
    action = "spawn-item",
    item_to_spawn = "railbow-selection-tool",
    icon = "__RailBow-Refracted__/graphics/railbow-selection-shortcut.png",
    icon_size = 64,
    small_icon = "__RailBow-Refracted__/graphics/railbow-selection-shortcut.png",
    small_icon_size = 64,
    style = "blue",
    associated_control_input = "railbow-get-selection-tool",
    localised_name = {
      "",
      {"item-description.railbow-selection-tool"},
      "\n",
      font_start,
      {"gui.instruction-when-in-cursor"},
      ":",
      line_start,
      {"item-description.railbow-selection-tool-place-tiles", "__CONTROL_LEFT_CLICK__"},
      line_start,
      {"item-description.railbow-selection-tool-place-forced", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_LEFT_CLICK__"},
      line_start,
      {"item-description.railbow-selection-tool-remove-tiles", "__CONTROL_RIGHT_CLICK__"},
      line_start,
      {"item-description.railbow-selection-tool-remove-ents", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_RIGHT_CLICK__"},
      font_end,
    }
  },
  {
    type = "custom-input",
    name = "railbow-get-selection-tool",
    order = "a",
    key_sequence = "N",
    action = "spawn-item",
    item_to_spawn = "railbow-selection-tool",
    consuming = "game-only",
    factoriopedia_description = {"fpedia-description.railbow-get-selection-tool-shortcut"},
  },
  {
    type = "custom-input",
    name = "railbow-open-gui",
    order = "b",
    key_sequence = "Shift + N",
    action = "lua",
    consuming = "game-only",
    factoriopedia_description = {"fpedia-description.railbow-open-gui"},
  }
})