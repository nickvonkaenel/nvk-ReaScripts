-- @noindex
-- @nomain
-- stylua: ignore start

--[[
    This file is a template for defining naming conventions used with
    "nvk_FOLDER_ITEMS - Rename". If set as the User Categories file
    in the settings, it will be automatically loaded and executed.

    You can define variables in Lua here. The script looks for specific
    global variables:

    Required globals:
      - CATEGORIES
      - CATEGORY_IDS

    Optional globals:
      - CATEGORIES_VERSION
      - CATEGORIES_OPTIONS
      - UCS_USER_CATEGORIES
      - UCS_VENDOR_CATEGORIES

    Any other globals you define will be ignored and won’t interfere
    with the script. Avoid changing Lua’s built-in library globals.

    The CATEGORIES table is a hierarchical set of definitions that controls
    how category fields are displayed, validated, and output in the final name.
    CATEGORY_IDS sets the order of categories, while nested tables inside
    CATEGORIES let you change behavior dynamically depending on the values
    selected. This allows you to enforce consistent naming schemes, provide
    tooltips, hide or disable categories, add subcategories, and customize
    formatting without modifying the main script.

    In short: CATEGORY_IDS defines the skeleton of the naming structure,
    and CATEGORIES fills in the behavior and values for each step. By combining
    them, you can create tailored naming workflows that guide users through
    structured choices while still supporting reusable tables, conditional
    logic, and global overrides.

    Example:
    If the user selects "AI" in the Type category, the data in
    CATEGORIES.Type.AI will be loaded. That table defines Group values,
    renames Set to "Name," and supplies Object tables like Foley or Vox.
    Each of those can further define their own Action, Identifier, and Loop
    behaviors. As the user narrows choices, settings cascade down, shaping
    both the UI and the final naming output.
]]


CATEGORIES_VERSION = 1.0 -- Allows for future changes to the format of the CATEGORIES table without breaking existing user category files. This current format is a bit convoluted so it might get refactored.

CATEGORIES_OPTIONS = {   -- Global settings for when user categories are enabled -- can delete if you just want to use the defaults or what is previously selected
    _ICON = "j",         -- Overrides icon to be used for user categories. Choose a character from the icons.otf file found in nvk-ReaScripts/SHARED/Data/fonts
    _CAPITALIZE = 1,     -- Capitalize option for user categories. 0 = Off, 1 = First, 2 = All, 3 = Mock, 4, = None (lowercase)
    _SPACES = 1,         -- Replace spaces option for user categories. 0 = Off, 1 = Underscore, 2 = Hyphen, 3 = Remove
    _NUMBER = true,      -- Number option for user categories. If true, numbers will be added to the end of the name
}

CATEGORY_IDS = { -- Determines order of categories and also the name if not specified in CATEGORIES table. Note: these should not be used as ids for value tables. If that is an issue then it's recommended you use the _NAME field and create a more unique id name
    "Type",
    "Group",
    "Set",
    "Object",
    "Action",
    "Identifier",
    "Loop",
}

-- CATEGORY MODS ARE FOR REFERENCE ONLY. THESE VALUES CAN BE SET IN THE CATEGORIES TABLE IN A _CATEGORY_ID table --
local CATEGORY_MODS = {                        -- Strings to be used for categories. CATEGORY and VALUE should be replaced by the category and value IDs. A category is anything from CATEGORY_IDS i.e. Type, Group, Set, etc.
    VALUE = {                                  -- A value is anything from a _VALUES table i.e. Wpn, Atk, Def, etc. You can nest category_ids in the value table to apply settings to it if the value is selected
        CATEGORY_ID = {}                       -- If value is selected, the category settings in nested category tables will be applied
    },
    _NAME = "String",                          -- Changes name of category
    _TOOLTIP = "String",                       -- Adds a tooltip string to the category that will be displayed if hovered by the user
    _DEFAULT = "String",                       -- Sets default value of category
    _PREPEND = "String",                       -- Adds a string to the beginning of the category value
    _APPEND = "String",                        -- Adds a string to the end of the category value
    _FORMAT = 0,                               -- Sets format of category. 1 = Numbers only, 2 = Letters only, 3 = Numbers and letters, 0 = Any character (default)
    _FORMAT_NUMBER = "%02d",                   -- Sets format string of category. See string.format for more info
    _DISABLE = true,                           -- Disables category from being edited. Useful for forcing a DEFAULT string to be used
    _HIDE = true,                              -- Hides category from being displayed. User input and DEFAULT will be ignored
    _NO_OUTPUT = true,                         -- Prevents category from being added to output string. Useful for categories which only control settings for other categories
    _NO_SPACER = true,                         -- Prevents category from adding a spacer to the output string
    _REQUIRED = true,                          -- Shows that category is required with an asterisk on the name (might warn user if not filled out)
    _NUMBER = true,                            -- If enabled, numbers will be added at the end of the current category instead of the end of the string
    _MAXLENGTH = 0,                            -- Sets maximum length of input value string. 0 = Off
    _SPACES = 0,                               -- Replace spaces option for category value. 0 = Off, 1 = Underscore, 2 = Hyphen, 3 = Remove
    _CAPITALIZE = 0,                           -- Capitalize option for category. 0 = Off, 1 = First, 2 = All, 3 = Mock, 4, = None (lowercase)
    _VALUES = { "Value1", "Value2" },          -- Values must be added as a array-like table of strings
    _VALUE_TOOLTIPS = { Value1 = "Tooltip1" }, -- Value tooltips must be added as a dictionary-like table of strings. Will be shown as help text in the value dropdown
    _SUBCATEGORIES = {                         -- Spawns new categories after the current category
        {                                      -- Subcategory tables added in order of appearance
            _NAME = "String",                  -- Sets name of subcategory (required)
            _VALUES = { "Value1", "Value2" },  -- Determines order to display options of current subcategory values (required to display values, VALUE tables can't be used)
        }
    },
    _OPTIONS = {         -- Global setting overrides for when user values are enabled
        _CAPITALIZE = 1, -- Capitalize option for user categories. 0 = Off, 1 = First, 2 = All, 3 = Mock, 4, = None (lowercase)
        _SPACES = 1,     -- Replace spaces option for user categories. 0 = Off, 1 = Underscore, 2 = Hyphen, 3 = Remove
        _NUMBER = true,  -- Number option for user categories. If true, numbers will be added to the end of the name
    },
}

local length_values = { -- Since we are using lua we can define reusable tables or variables
    "L0", -- Extra Short
    "L1", -- Short
    "L2", -- Medium
    "L3", -- Long
    "L4", -- Extra Long
}

local length_tooltips = {
    L0 = "Extra Short", -- Extra Short
    L1 = "Short",       -- Short
    L2 = "Medium",      -- Medium
    L3 = "Long",        -- Long
    L4 = "Extra Long",  -- Extra Long
}

local SUBCATEGORY = { -- We can even define reusable subcategories. These can show up as additional fields when needed.
    Size = {
        _NAME = "Size",
        _TOOLTIP = "Size of the object\n0 = Tiny\n1 = Small\n2 = Medium\n3 = Large\n4 = Huge", -- This tooltip is shown when hovering the category. Can include new lines if desired for formatting.
        _VALUES = {
            "S0", -- Tiny
            "S1", -- Small
            "S2", -- Medium
            "S3", -- Large
            "S4", -- Huge
        },
        _VALUE_TOOLTIPS = {
            S0 = "Tiny",   -- Tiny
            S1 = "Small",  -- Small
            S2 = "Medium", -- Medium
            S3 = "Large",  -- Large
            S4 = "Huge",   -- Huge
        }
    },
    Power = {
        _NAME = "Power",
        _TOOLTIP = "Intensity of the sound\n0 = Weak\n1 = Low\n2 = Medium\n3 = High\n4 = Extreme",
        _VALUES = {
            "P0", -- Weak
            "P1", -- Low
            "P2", -- Medium
            "P3", -- High
            "P4", -- Extreme
        },
        _VALUE_TOOLTIPS = {
            P0 = "Weak",    -- Weak
            P1 = "Low",     -- Low
            P2 = "Medium",  -- Medium
            P3 = "High",    -- High
            P4 = "Extreme", -- Extreme
        }
    },
    Length = {
        _NAME = "Length",
        _TOOLTIP = "Length of the sound\n0 = Extra Short\n1 = Short\n2 = Medium\n3 = Long\n4 = Extra Long",
        _VALUES = length_values, -- Here we use the previously defined table
        _VALUE_TOOLTIPS = length_tooltips, -- Here we use the previously defined table
    },
    Material = {
        _NAME = "Material",
        _VALUES = {
            "Concrete",
            "Dirt",
            "Glass",
            "Grass",
            "Gravel",
            "Ice",
            "Metal",
            "Mud",
            "Rock",
            "Sand",
            "Tar",
            "Tile",
            "Water",
            "Wood",
        }
    },
}

CATEGORIES = {
    -- Here we are defining a category called Type. It isn't added to the output string, but determines the autocomplete behavior for the rest of the name.
    Type = {
        _VALUES = {
            "AI",
            "Level",
        },
        _NO_OUTPUT = true, -- this category will not be added to output string
        _REQUIRED = true,  -- show that category is required
        AI = { -- When the AI category is selected, the values in this table will be used for settings and autocomplete options
            Group = { -- We define that values that show up in the Group category for AI
                _VALUES = { -- values here will show up as autocomplete options
                    "Cre",
                    "Hmn",
                    "Veh",
                },
                _VALUE_TOOLTIPS = { -- we can add corresponding tooltips for the values
                    Cre = "Creature",
                    Hmn = "Humanoid",
                    Veh = "Vehicle",
                },
                Cre = {
                    Set = {
                        _VALUES = {
                            "Bird",
                            "Bull",
                            "Cat",
                            "Cow",
                            "Deer",
                            "Dog",
                            "Dragon",
                            "Horse",
                            "Lion",
                            "Pig",
                            "Sheep",
                            "Wolf",
                        },
                    },
                },
            },
            Set = {
                _NAME = "Name", -- changes Set category name to more specific name for all AI type
            },
            Object = {
                _TOOLTIP =
                "Ability = attacks, powers, etc.\nFoley = footsteps, movement, bodyfalls, etc.\nVox = vocals.",
                _VALUES = {
                    "Ability",
                    "Foley",
                    "Vox",
                },
                Foley = { -- Here we are defining specific behavior if Foley is used for the Object Category
                    Action = {
                        _VALUES = {
                            "Bodyfall",
                            "Footstep",
                            "Movement",
                        },
                        Bodyfall = {
                            Loop = { _HIDE = true, }, -- we hide the Loop category since it's not used in this object. Deeper nested settings will override settings defined elsewhere.
                        },
                        Footstep = {
                            Identifier = {
                                _NAME = "Stride", -- Rename the category to something more descriptive
                                _VALUES = {
                                    "Walk",
                                    "Jog",
                                    "Run",
                                    "Jump",
                                    "Land",
                                },
                                _SUBCATEGORIES = {
                                    SUBCATEGORY.Material, -- making use of reusable subcategories so we don't have to repeat ourselves
                                },
                            },
                            Loop = { _HIDE = true, },
                        },
                        Jump = {
                            Identifier = {
                                _SUBCATEGORIES = {
                                    SUBCATEGORY.Material,
                                },
                            },
                            Loop = { _HIDE = true, },
                        },
                        Land = {
                            Identifier = {
                                _SUBCATEGORIES = {
                                    SUBCATEGORY.Length,
                                },
                            },
                            Loop = { _HIDE = true, },
                        },
                        Movement = {},
                    },
                },
                Vox = {
                    Action = {
                        _VALUES = {
                            "Breath",
                            "Death",
                            "Grunt",
                            "Roar",
                        },
                        Breath = {
                            Identifier = {
                                _NAME = "Intensity",
                                _VALUES = {
                                    "Idle",
                                    "Light",
                                    "Medium",
                                    "Heavy",
                                    "Max",
                                },

                                _SUBCATEGORIES = {
                                    {
                                        _NAME = "BreathType",
                                        _VALUES = {
                                            "Inhale",
                                            "Exhale",
                                        },
                                    },
                                },
                            },
                        }
                    },
                },
            },
            Identifier = {
                _SUBCATEGORIES = { --These subcategories will get created for AI types
                    SUBCATEGORY.Power,
                    SUBCATEGORY.Length,
                },
            },
            Loop = {
                _VALUES = {
                    "Loop",
                    "Start",
                    "Stop",
                },
            },
        },
        Level = {
            Group = {
                _NAME = "Area",
                _VALUES = {
                    "Global",
                    "Overworld",
                    "Ruins",
                    "Ocean",
                }
            },
            Set = {
                _VALUES = {
                    "Amb",
                    "Obj",
                },
                Amb = {
                    Object = {
                        _NAME = "Implementation",
                        _TOOLTIP = "Bed = Background\nEmit = Emitter",
                        _VALUES = {
                            "Bed",
                            "Emit",
                        },
                        _VALUE_TOOLTIPS = {
                            Bed = "Background",
                            Emit = "Emitter",
                        },
                        Bed = {
                            Action = {
                                _NAME = "Space",
                                _TOOLTIP = "Int = Interior\nExt = Exterior",
                                _VALUES = {
                                    "Int",
                                    "Ext",
                                },
                                _VALUE_TOOLTIPS = {
                                    Int = "Interior",
                                    Ext = "Exterior",
                                },
                            },
                            Identifier = {
                                _NAME = "Description",
                                _REQUIRED = true,
                            },
                            Loop = {
                                _VALUES = {
                                    "Loop",
                                },
                                _DEFAULT = "Loop", -- Setting a default value since it's almost always going to be Loop
                            }
                        },
                        Emit = {
                            Action = {
                                _NAME = "Category",
                            },
                            Identifier = {
                                _NAME = "Description",
                                _REQUIRED = true,
                            },
                        },
                    },
                },
                Obj = {
                    Loop = {
                        _VALUES = {
                            "Loop",
                            "Start",
                            "Stop",
                        },
                    },
                },
            },
        },
    },
    -- If we wanted to have values that always show up in major categories, we can add them here. We could also just define some global settings as seen here.
    Group = {
        _REQUIRED = true,
    },
    Set = {
        _REQUIRED = true,
    },
    Object = {
        _REQUIRED = true,
    },
    Action = {
        _REQUIRED = true,
    },
    Identifier = {
    },
    Loop = {},
}

UCS_USER_CATEGORIES = { -- Custom User categories for UCS, for easily standardizing/sharing categories. Uncomment to use.
    -- { id = "CMBAtck", description = "Combat attack sounds" },
    -- { id = "CMBDefn", description = "Combat defense/blocking sounds" },
    -- { id = "CMBImpt", description = "Combat impact/hit sounds" },
    -- { id = "CMBMisc", description = "Other combat-related sounds that don't fit other categories" },
}

UCS_VENDOR_CATEGORIES = { -- Custom Vendor categories for UCS. Uncomment to use.
    -- { id = "VNDWhsh", description = "Vendor whoosh" },
}

-- stylua: ignore end
