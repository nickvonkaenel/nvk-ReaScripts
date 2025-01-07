--[[
Description: nvk_THEME
Version: 1.0.1
Author: nvk
About:
    # nvk_THEME

    nvk_THEME is a premium Reaper theme in the style of the nvk.tools suite of scripts. It was designed by the talented Gwen Terrien (@terromino). It is not only an improvement on the look and feel of Reaper, but it also adds additional functionality with custom transport, track FX, and channel output buttons as well as an automatic track coloring script for the ultimate Reaper aesthetic.
Author: nvk
Links:
    Store Page https://gum.co/nvk_THEME
    User Guide https://nvk.tools/docs/theme
Changelog:
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
