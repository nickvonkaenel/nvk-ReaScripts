--[[
Description: nvk_THEME
Version: 1.1.4
Author: nvk
About:
    # nvk_THEME

    nvk_THEME is a premium Reaper theme in the style of the nvk.tools suite of scripts. It was designed by the talented Gwen Terrien (@terromino). It is not only an improvement on the look and feel of Reaper, but it also adds additional functionality with custom transport, track FX, and channel output buttons as well as an automatic track coloring script for the ultimate Reaper aesthetic.
Author: nvk
Links:
    Store Page https://gum.co/nvk_THEME
    User Guide https://nvk.tools/docs/theme
Changelog:
    1.1.4
        Use track default settings when inserting track
    1.1.3
        UI jank when searching for FX in custom FX button section (requires update to nvk_SHARED)
    1.1.2
        Reduce large gradient color jumps with folders with less than 3 child tracks
        A few minor track color theme tweaks
    1.1.1
        Refactoring child track color gradients. Now allows for both gradient modes simultaneously and for control over the child track colors without a gradient.
        Optimized track color performance
        New script: Track Colors - Insert track and apply colors. Improves default insert track behavior and also applies the nvk_THEME track colors so that there aren't any UI flashes. Can also be used instead of the manual color apply script if you only want updates when a new track is added.
        Streamlining included Track Colors themes
    1.1.0
        Add gradients to child tracks with Track Colors. Three modes: None, Brightness, and Next color.
        Execute actions instead of inserting FX with custom FX buttons
        Reduced default padding between buttons for slightly more compact theme, can be adjusted in the theme settings if the old padding amount is preferred or you want to reduce it further
        Multi-row TCP fx inserts
        Option for MCP FX inserts of the side of the track along with custom width
        Adjust FX inserts, FX parameters, and send list inserts height in master MCP
        Change MCP and master MCP meter size
        Change button padding in all layouts
        Fix mcp latch preview env button
        Fix UI interactions with theme parameters with the same label
        Automatically show embedded FX UI in TCP for custom FX
        Improved tooltips
    1.0.2
        Fix AU plugins not working as custom FX on some systems
    1.0.1
        Checkbox to show FX inserts in track panel
        Option to show embedded FX UI in TCP for custom FX
    1.0.0 Initial release
Provides:
    [main] *.lua
    **/*.dat
    [theme] nvk_THEME_Dark.ReaperThemeZip
    [theme] nvk_THEME_Light.ReaperThemeZip
--]]

-- SETUP --
local r = reaper
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local last_theme = r.GetLastColorThemeFile()
if not last_theme:find 'nvk_THEME' then
    local init_theme = os_is.mac and 'nvk_THEME_Dark' or 'nvk_THEME_Light'
    r.OpenColorThemeFile(init_theme .. '.ReaperThemeZip')
end
