-- @noindex
OS = reaper.GetOS()
sep = OS:match "Win" and "\\" or "/"
local info = debug.getinfo(1, 'S')
local libPath = info.source:match [[^@?(.*[\\/])[^\\/]-$]] .. "Data" .. sep

loadfile(libPath .. "scythe.lua")()
GUI = require("gui.core")
Color = require("public.color")
Table = require("public.table")
Text = require("public.text")

Scythe.developerMode = false
Scythe.version = false
Scythe.args.printErrors = true

------------------------------------
-------- Functions -----------------
------------------------------------

Table.stringify = function(t, maxDepth, currentDepth)
    local ret = {}
    maxDepth = maxDepth or 2
    currentDepth = currentDepth or 0

    for n, v in pairs(t) do
        ret[#ret + 1] = string.rep("  ", currentDepth)

        if type(v) == "table" then
            ret[#ret] = ret[#ret] .. "table:"

            if (not maxDepth or currentDepth < maxDepth) and not v.__noRecursion then
                ret[#ret + 1] = Table.stringify(v, maxDepth, currentDepth + 1)
            end
        else
            ret[#ret] = ret[#ret] .. tostring(v)
        end
    end

    return table.concat(ret, ", ")
end

local function getValuesForLayer(layerNum)

    local layer = layers[layerNum]

    local values = {}
    local val

    for key, elm in pairs(layer.elements) do
        if elm.val then
            val = elm:val()
            if key == "colorPicker" then val = Color.toRgba(val) end
        else
            val = "n/a"
        end
        if type(val) == "table" then
            if key == "colorPicker" then
                val[4] = nil
                val = "Color.fromRgba(" .. Table.stringify(val) .. ")"
            else
                val = "{" .. Table.stringify(val) .. "}"
            end
        elseif type(val) == "string" then
            val = "\"" .. val .. "\""
        end
        if key == "FolderNamesFrame" then val = nil end
        if val then values[#values + 1] = "layers[" .. layerNum .. "].elements." .. key .. ":val(" .. tostring(val) .. ")" end
    end
    return table.concat(values, " ")
end

local function getValuesForLayerSimple(layerNum)

    local layer = layers[layerNum]

    local values = {}
    local val

    for key, elm in pairs(layer.elements) do
        if elm.val then
            val = elm:val()
            if key == "colorPicker" then val = Color.toRgba(val) end
        else
            val = "n/a"
        end
        if type(val) == "table" then
            if key == "colorPicker" then
                val[4] = nil
                val = "reaper.ColorToNative(" .. Table.stringify(val) .. ")"
            else
                val = "{" .. Table.stringify(val) .. "}"
            end
        elseif type(val) == "string" then
            val = "\"" .. val .. "\""
        end
        if key == "FolderNamesFrame" then val = nil end
        if val then values[#values + 1] = key .. " = " .. tostring(val) end
    end
    return table.concat(values, " ")
end

local function SaveSettings()
    local s = ""
    local ss = ""
    for i = 3, 12 do
        s = s .. getValuesForLayer(i) .. " "
        ss = ss .. getValuesForLayerSimple(i) .. " "
    end
    if s ~= lastS or ss ~= lastSS then
        lastS = s
        lastSS = ss
        if reaper.HasExtState("nvk_FOLDER_ITEMS", "settings") then reaper.DeleteExtState("nvk_FOLDER_ITEMS", "settings", true) end
        reaper.SetExtState("nvk_FOLDER_ITEMS", "settings", s, true)
        if reaper.HasExtState("nvk_FOLDER_ITEMS", "settingsSimple") then
            reaper.DeleteExtState("nvk_FOLDER_ITEMS", "settingsSimple", true)
        end
        reaper.SetExtState("nvk_FOLDER_ITEMS", "settingsSimple", ss, true)
        reaper.SetExtState("nvk_FOLDER_ITEMS", "settingsChanged", "1", false)
    end
end

local function ResetSettings()
    if reaper.ShowMessageBox("Reset all settings for nvk_FOLDER_ITEMS?", "", 1) == 1 then
        if reaper.HasExtState("nvk_FOLDER_ITEMS", "settingsSimple") then
            reaper.DeleteExtState("nvk_FOLDER_ITEMS", "settingsSimple", true)
        end
        if reaper.HasExtState("nvk_FOLDER_ITEMS_RENDER", "settingsSimple") then
            reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settingsSimple", true)
        end
        if reaper.HasExtState("nvk_FOLDER_ITEMS", "settings") then reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settings", true) end
        if reaper.HasExtState("nvk_FOLDER_ITEMS_RENDER", "settings") then
            reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settings", true)
        end
        if reaper.HasExtState("nvk_FOLDER_ITEMS - Rename", "settings") then
            reaper.DeleteExtState("nvk_FOLDER_ITEMS - Rename", "settings", true)
        end
        if reaper.HasExtState("nvk_FOLDER_ITEMS - Rename", "window") then
            reaper.DeleteExtState("nvk_FOLDER_ITEMS - Rename", "window", true)
        end
        if reaper.HasExtState("nvk_FOLDER_ITEMS - Add new items to existing folder", "mm", true) then
            reaper.DeleteExtState("nvk_FOLDER_ITEMS - Add new items to existing folder", "mm", true)
        end
        if reaper.HasExtState("nvk_FOLDER_ITEMS - Add new items to existing folder - Rename", "mm", true) then
            reaper.DeleteExtState("nvk_FOLDER_ITEMS - Add new items to existing folder - Rename", "mm", true)
        end
        load(defaultSettings)()
    end
end

local function ResetMM()
    if reaper.ShowMessageBox("Reset double click mouse modifiers for media item and track control panel?", "", 1) == 1 then
        reaper.SetMouseModifier("MM_CTX_ITEM_DBLCLK", 0, -1)
        reaper.SetMouseModifier("MM_CTX_TCP_DBLCLK", 0, -1)
    end
end

local function SetMM()
    if reaper.ShowMessageBox("Set double click mouse modifiers for media item and track control panel to open and close folders?", "", 1) ==
      1 then
        reaper.SetMouseModifier("MM_CTX_ITEM_DBLCLK", 0, "_RS1c447db7464d8df46396f85586a8318b48d38290")
        reaper.SetMouseModifier("MM_CTX_TCP_DBLCLK", 0, "_RSae53e82103070421e24e021a91259f582a5341a6")
    end
end

local function ResetExpMM()
    if reaper.ShowMessageBox("Reset double click mouse modifiers for track?", "", 1) == 1 then
        reaper.SetMouseModifier("MM_CTX_TRACK_CLK", 2, -1)
        reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 1, -1)
        reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 2, -1)
        reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 3, -1)
    end
end

local function SetExpMM()
    if reaper.ShowMessageBox(
      "Set double click mouse modifiers for track to reposition in various ways when holding shift, control, and control-shift?", "", 1) ==
      1 then
        reaper.SetMouseModifier("MM_CTX_TRACK_CLK", 2, 5)
        reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 1, "_RSba76bf36e02c39153288adbc45f32eed35cfc0e6")
        reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 2, "_RS65c58d9b53b4816c225d4bac8e054de02583de93")
        reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 3, "_RS4bbc610d8b42ac43a7dec7806cfc0eda9434dd40")
    end
end
------------------------------------
-------- Colors --------------------
------------------------------------
local Theme = require("gui.theme")
Theme.colors["highlight"] = {19, 189, 153, 255}
Color.addColorsFromRgba(Theme.colors)

------------------------------------
-------- Window settings -----------
------------------------------------
local window = GUI.createWindow({
    name = "nvk_FOLDER_ITEMS - Settings",
    x = 0,
    y = 0,
    w = 424,
    h = 286,
    anchor = "mouse",
    corner = "TL"
})

layers = table.pack(GUI.createLayers({
    name = "Layer1",
    z = 1
}, {
    name = "Layer2",
    z = 2
}, {
    name = "Layer3",
    z = 3
}, {
    name = "Layer4",
    z = 4
}, {
    name = "Layer5",
    z = 5
}, {
    name = "Layer6",
    z = 6
}, {
    name = "Layer7",
    z = 7
}, {
    name = "Layer8",
    z = 8
}, {
    name = "Layer9",
    z = 9
}, {
    name = "Layer10",
    z = 10
}, {
    name = "Layer11",
    z = 11
}, {
    name = "Layer12",
    z = 12
}))

window:addLayers(table.unpack(layers))

------------------------------------
-------- Global elements -----------
------------------------------------

layers[1]:addElements(GUI.createElements({
    name = "tabs",
    type = "Tabs",
    x = 0,
    y = 0,
    w = 64,
    h = 20,
    tabW = 100,
    tabs = {
        {
            label = "Main",
            layers = {layers[3], layers[4]}
        }, {
            label = "Fades",
            layers = {layers[5], layers[6]}
        }, {
            label = "Folder",
            layers = {layers[7], layers[8]}
            -- }, {
            --     label = "Render",
            --     layers = {layers[9], layers[10]}
        }, {
            label = "Other",
            layers = {layers[11], layers[12]}
        }
    },
    pad = 16
}))

layers[2]:addElements(GUI.createElement({
    name = "frmTabBackground",
    type = "Frame",
    x = 0,
    y = 0,
    w = 448,
    h = 20
}))

------------------------------------
-------- Setup ---------------------
------------------------------------

gMarkersY = 36
gMarkersW = 200
gMarkersH = 24 * 6 + 4
gNamesH = 24 * 3 + 4
gNamesY = gMarkersY + gMarkersH + 12

gFIH = 24 * 5 + 2

fadeTimeCaption = "Fades when trimming items:"
fadeTimeCaptionW = Text.getTextWidth(fadeTimeCaption, 3)
markerColorCaption = "Marker color:"
markerColorCaptionW = Text.getTextWidth(markerColorCaption, 3)
fadeLengthCaption = "Minimum fade length (in seconds):"
fadeLengthCaptionW = Text.getTextWidth(fadeLengthCaption, 3)
renderFolderCaption = "Custom render folder:"
renderFolderCaptionW = Text.getTextWidth(renderFolderCaption, 3)
replaceSpacesCaption = "Replace spaces punctuation:"
replaceSpacesCaptionW = Text.getTextWidth(replaceSpacesCaption, 3)

gFadeY = 36
gFadeH = window.h - 48

fadeTimeVal = 3

gFolderY = 36
gFolderH = window.h - 48
-- gFolderH = gMarkersH
-- gFolderW = Text.getTextWidth("Collapse after creation", 3)+40
gFolderW = window.w - 24

-- gRenderX = gMarkersX
gRenderY = gFolderY
-- gRenderW = Text.getTextWidth("Save render settings in item notes", 3)+40
gRenderW = window.w - 24
-- gRenderH = 24*4+20
gRenderH = gFadeH

gMMW = 150
gMMBtnW = gMMW / 2 - 6
gMMH = 40
gMMY = 54 + gFIH
gMMX = (window.w - gMarkersW - gMMW) / 3
gMarkersX = gMMX + gMMW + gMMX
------------------------------------
---------- Tab 1 Main --------------
------------------------------------

layers[3]:addElements(GUI.createElements({
    name = "btnSettingsReset",
    type = "Button",
    x = gMMX + 4,
    y = gMMY + gMMH + 30,
    w = gMMW - 8,
    h = gMMH / 2,
    caption = "Reset to Default",
    func = ResetSettings
}, {
    name = "btnMMReset",
    type = "Button",
    x = gMMX + gMMW / 2 - gMMBtnW - 2,
    y = gMMY + 14,
    w = gMMBtnW,
    h = gMMH / 2,
    caption = "Reset",
    func = ResetMM
}, {
    type = "Button",
    name = "btnMMSet",
    x = gMMX + gMMW / 2 + 2,
    y = gMMY + 14,
    w = gMMBtnW,
    h = gMMH / 2,
    caption = "Set",
    func = SetMM
}, {
    name = "MarkersColorMenu",
    type = "Menubox",
    x = gMarkersX + 10 + markerColorCaptionW,
    y = gMarkersY + gMarkersH - 28,
    w = gMarkersW - 18 - markerColorCaptionW,
    h = 20,
    caption = markerColorCaption,
    options = {"Custom color", "Item color", "Theme color"}
}, {
    name = "colorPicker",
    type = "ColorPicker",
    x = gMarkersX + gMarkersW - 30,
    y = gMarkersY + 16,
    w = 24,
    h = 24,
    caption = "Custom color:",
    color = markerColor
}, {
    name = "replaceSpaces",
    type = "Textbox",
    x = gMarkersX + 8 + replaceSpacesCaptionW,
    y = gNamesY + gNamesH - 28,
    w = gMarkersW - 12 - replaceSpacesCaptionW,
    h = 20,
    caption = replaceSpacesCaption,
    retval = "_",
    validateOnType = true,
    validator = function(str)
        if string.len(str) > 1 then
            return false
        else
            return str:match("%W")
        end
    end
}))

layers[4]:addElements(GUI.createElements({
    name = "FIChecklist",
    type = "Checklist",
    x = gMMX,
    y = gMarkersY,
    w = gMMW,
    h = gFIH - 24,
    caption = "Folder Items",
    options = {"Auto-select", "Disable", "Top-level only"},
    dir = "v",
    frame = true,
    pad = 6
}, {
    name = "SettingsChecklist",
    type = "Checklist",
    x = gMMX,
    y = gMMY + gMMH + 16,
    w = gMMW,
    h = gMMH,
    caption = "Settings",
    options = {},
    dir = "v",
    frame = true
}, {
    name = "MMChecklist",
    type = "Checklist",
    x = gMMX,
    y = gMMY,
    w = gMMW,
    h = gMMH,
    caption = "Mouse Modifiers",
    options = {},
    dir = "v",
    frame = true
}, {
    name = "MarkersChecklist",
    type = "Checklist",
    x = gMarkersX,
    y = gMarkersY,
    w = gMarkersW,
    h = gMarkersH,
    caption = "Markers",
    options = {"On", "Regions", "Subprojects", "Variations"},
    dir = "v",
    frame = true,
    pad = 6
}, {
    name = "NameChecklist",
    type = "Checklist",
    x = gMarkersX,
    y = gNamesY,
    w = gMarkersW,
    h = gNamesH,
    caption = "Names",
    options = {"Name in notes (large names)"},
    dir = "v",
    frame = true,
    pad = 6
}))
------------------------------------
-------- Tab 2 Fades ---------------
------------------------------------

layers[5]:addElements(GUI.createElements({
    name = "FadeTimeMenu",
    type = "Menubox",
    x = 12 + 8 + fadeTimeCaptionW,
    y = gFadeY + 108,
    w = window.w - 40 - fadeTimeCaptionW,
    h = 20,
    caption = fadeTimeCaption,
    options = {"Preserve start time", "Preserve length when extending", "Always preserve length"},
    retval = fadeTimeVal
}, {
    name = "FadeLength",
    type = "Textbox",
    x = 12 + 8 + fadeLengthCaptionW,
    y = gFadeY + 136,
    w = window.w - 40 - fadeLengthCaptionW,
    h = 20,
    caption = fadeLengthCaption,
    retval = "0.01"
}))

layers[6]:addElements(GUI.createElements({
    name = "FadeChecklist",
    type = "Checklist",
    x = 12,
    y = gFadeY,
    w = window.w - 24,
    h = gFadeH,
    caption = "Fades",
    options = {
        "Folder item fades write automation instead of fading child items", "Folder item fades only increase length of child items",
        "Change fade time relatively when item length changes"
    },
    dir = "v",
    frame = true,
    pad = 8
}))

------------------------------------
-------- Tab 3 Folders -------------
------------------------------------
fIgnoreCaption = "Excluded words:"
fIgnoreCaptionW = Text.getTextWidth(fIgnoreCaption, 3)
fOnlyCaption = "Required words:"
fOnlyCaptionW = Text.getTextWidth(fOnlyCaption, 3)

layers[7]:addElements(GUI.createElements({
    name = "FolderNamesIgnore",
    type = "Textbox",
    x = 15 + fIgnoreCaptionW,
    y = gFolderY + gFolderH / 2 + 12,
    w = window.w - 28 - fIgnoreCaptionW,
    h = 20,
    caption = fIgnoreCaption,
    retval = "video renders unused",
    validateOnType = true,
    validator = function(str) return not str:match("%p") end
}, {
    name = "FolderNamesOnly",
    type = "Textbox",
    x = 15 + fOnlyCaptionW,
    y = gFolderY + gFolderH / 2 + 40,
    w = window.w - 28 - fOnlyCaptionW,
    h = 20,
    caption = fOnlyCaption,
    retval = "",
    validateOnType = true,
    validator = function(str) return not str:match("%p") end
}))

fChecklistH = 26 * 4 + 6

layers[8]:addElements(GUI.createElements({
    name = "FolderNamesFrame",
    type = "Frame",
    x = 12,
    y = gFolderY + gFolderH / 2 + 68,
    w = window.w - 24,
    h = gFolderH / 2,
    color = "background",
    font = 3,
    pad = 0,
    bg = "background",
    textColor = "gray",
    text = "Instructions: create a list of words to either exclude or require in folder track names when creating folder items (case-insensitive)"
}, {
    name = "FolderChecklist",
    type = "Checklist",
    x = 12,
    y = gFolderY,
    w = gFolderW,
    h = fChecklistH,
    caption = "Folder",
    options = {
        "Collapse tracks after creating a new folder", "Rename folder track after creation",
        "Rename folder items after creation (overrides previous setting)"
    },
    dir = "v",
    frame = true,
    pad = 8
}))

------------------------------------
-------- Tab 4 Renders -------------
------------------------------------
-- layers[9]:addElements(GUI.createElements({
--     name = "RenderFolder",
--     type = "Textbox",
--     x = 16 + renderFolderCaptionW + 8,
--     y = gRenderY + 108,
--     w = gRenderW - renderFolderCaptionW - 20,
--     h = 20,
--     caption = renderFolderCaption,
--     retval = "Renders"
-- }))

-- layers[10]:addElements(GUI.createElements({
--     name = "RenderChecklist",
--     type = "Checklist",
--     x = 12,
--     y = gFolderY,
--     w = gRenderW,
--     h = gRenderH,
--     caption = "Render",
--     options = {"Create RENDERS folder at top of project (else bottom of project)", "Only render top-level folder items",
--                "Save render settings with items"},
--     dir = "v",
--     frame = true,
--     pad = 8
-- }))

------------------------------------
-------- Tab 5 Experimental --------
------------------------------------
gEMMX = 212
gEMMY = 156
gEMMW = gMMW + 60
gEMMBtnW = gMMBtnW + 30

layers[11]:addElements(GUI.createElements({
    name = "btnExpMMReset",
    type = "Button",
    x = window.w - gEMMW - 8,
    y = window.h - gMMH,
    w = gEMMBtnW,
    h = gMMH / 2,
    caption = "Reset",
    func = ResetExpMM
}, {
    type = "Button",
    name = "btnExpMMSet",
    x = window.w - 16 - gEMMBtnW,
    y = window.h - gMMH,
    w = gEMMBtnW,
    h = gMMH / 2,
    caption = "Set",
    func = SetExpMM
}))

layers[12]:addElements(GUI.createElements({
    name = "ExperimentalChecklist",
    type = "Checklist",
    x = 12,
    y = gFolderY,
    w = gFolderW,
    h = gFolderH,
    caption = "⚠Experimental⚠",
    options = {
        "Automatically open & close video window", "Larger item notes", "Only show subproject markers for items on top-level tracks",
        "Double-click item to create/select take regions", "Disable automatic naming and numbering of new folder items"
    },
    dir = "v",
    frame = true,
    pad = 8
}, {
    name = "ExpMMChecklist",
    type = "Checklist",
    x = window.w - gEMMW - 12,
    y = window.h - gMMH - 12,
    w = gEMMW,
    h = gMMH,
    caption = "Reposition Mouse Modifiers",
    options = {},
    dir = "v",
    frame = true
}))

defaultSettings =
  [[settings=layers[3].elements.replaceSpaces:val("_") layers[3].elements.colorPicker:val(Color.fromRgba(128.0, 128.0, 128.0)) layers[3].elements.MarkersColorMenu:val(1) layers[4].elements.FIChecklist:val({true, false}) layers[4].elements.MMChecklist:val({}) layers[4].elements.SettingsChecklist:val({}) layers[4].elements.MarkersChecklist:val({true, false, false, false}) layers[4].elements.NameChecklist:val({false, false}) layers[5].elements.FadeLength:val("0.01") layers[5].elements.FadeTimeMenu:val(3) layers[6].elements.FadeChecklist:val({false, true, true}) layers[7].elements.FolderNamesIgnore:val("video renders unused") layers[7].elements.FolderNamesOnly:val("") layers[8].elements.FolderChecklist:val({false, false, false})    layers[12].elements.ExperimentalChecklist:val({false, false, false}) layers[12].elements.ExpMMChecklist:val({})]]

if reaper.HasExtState("nvk_FOLDER_ITEMS", "settings") then
    settings = reaper.GetExtState("nvk_FOLDER_ITEMS", "settings")
    reaper.DeleteExtState("nvk_FOLDER_ITEMS", "settings", true)
else
    settings = defaultSettings
end

if reaper.HasExtState("nvk_FOLDER_ITEMS", "settingsSimple") then reaper.DeleteExtState("nvk_FOLDER_ITEMS", "settingsSimple", true) end

settings = string.gsub(settings, "layers%[9%]%.elements%.RenderFolder.-%)", "")
settings = string.gsub(settings, "layers%[10%]%.elements%.RenderChecklist.-%)", "")

------------------------------------
-------- Main functions ------------
------------------------------------

local function Main()

    -- Prevent the user from resizing the window
    if window.state.resized then
        -- If the window's size has been changed, reopen it
        -- at the current position with the size we specified
        window:reopen({
            w = window.w,
            h = window.h
        })
    end
    SaveSettings()

end

-- Open the script window and initialize a few things
window:open()

load(settings)()

-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main

-- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.funcTime = 0.1

-- Start the main loop
GUI.Main()
