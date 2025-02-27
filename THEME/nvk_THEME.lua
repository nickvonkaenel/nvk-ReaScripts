--[[
Description: nvk_THEME
Version: 1.3.0
Author: nvk
About:
    # nvk_THEME

    nvk_THEME is a premium Reaper theme in the style of the nvk.tools suite of scripts. It was designed by the talented Gwen Terrien (@terromino). It is not only an improvement on the look and feel of Reaper, but it also adds additional functionality with custom transport, track FX, and channel output buttons as well as an automatic track coloring script for the ultimate Reaper aesthetic.
Author: nvk
Links:
    Store Page https://gum.co/nvk_THEME
    User Guide https://nvk.tools/docs/theme
Changelog:
    1.3.0
        IMPORTANT: "Selection overlay strength" has been renamed to "Selected track brightness" for clarity. It also now covers a wider range of brightness levels so you will need to adjust it if you have a custom setting.
        THEME:
            New transport toolbar buttons (project bay, track colors, rename, render, subprojects)
            TCP FX inserts text margin
            Fix scrollbars for themable windows in dark theme
            Changed red clipped meter color and text color when clipped
            Muted tracks and items are less dark
            Fix appearance of default toolbar save icon at 200%
            Fix for 150% and 200% master tcp layout jank in last update
        SETTINGS:
            Removing "Auto-update" checkbox from track colors section
            Adding "Automatically color tracks" checkbox to track colors section which runs the script "nvk_THEME - Track Colors - Apply - Auto"
            New script: "nvk_THEME - Track Colors" - opens just the track colors settings rather than the entire theme settings
            Allow for asterisk (*) wildcard in custom track name colors i.e. "bass*" and "*guitar" will both match a track with the name "bass guitar" while "guitar*" would not and "*guitar*" would match any track with "guitar" in the name
            Added a button to the settings to open the theme tweaker
    1.2.7
        Error when disabling parent track coloring in settings
    For full changelog, see https://nvk.tools/docs/theme#changelog
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
