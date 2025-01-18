data:extend({
    {
    type = "int-setting",
    name = "railbow-rail-calculations-per-tick",
    setting_type = "runtime-global",
    default_value = 50,
    minimum_value = 1,
    maximum_value = 1000,
    order = "a",
    localised_name = {"settings-name.railbow-rail-calculations-per-tick"},
    localised_description = {"settings-description.railbow-rail-calculations-per-tick"}
    },
    {
    type = "int-setting",
    name = "railbow-tile-calculations-per-tick",
    setting_type = "runtime-global",
    default_value = 1000,
    minimum_value = 100,
    maximum_value = 100000,
    order = "b",
    localised_name = {"settings-name.railbow-tile-calculations-per-tick"},
    localised_description = {"settings-description.railbow-tile-calculations-per-tick"}
    },
    {
        type = "bool-setting",
        name = "railbow-instant-build",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "c",
        localised_name = {"settings-name.railbow-instant-build"},
        localised_description = {"settings-description.railbow-instant-build"}
    },
    {
        type = "bool-setting",
        name = "railbow-default-place-landfill",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "d",
        localised_name = {"settings-name.railbow-default-place-landfill"},
        localised_description = {"settings-description.railbow-default-place-landfill"}
    },
    {
        type = "bool-setting",
        name = "railbow-default-remove-trees",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "e",
        localised_name = {"settings-name.railbow-default-remove-trees"},
        localised_description = {"settings-description.railbow-default-remove-trees"}
    },
    {
        type = "bool-setting",
        name = "railbow-default-remove-cliffs",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "f",
        localised_name = {"settings-name.railbow-default-remove-cliffs"},
        localised_description = {"settings-description.railbow-default-remove-cliffs"}
    },
    {
        type = "bool-setting",
        name = "railbow-debug",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "zzz",
        localised_name = {"settings-name.railbow-debug"},
    },
})