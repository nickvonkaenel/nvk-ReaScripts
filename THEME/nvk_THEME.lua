--[[
Description: nvk_THEME
Version: 1.4.7
Author: nvk
About:
    # nvk_THEME

    nvk_THEME is a premium Reaper theme in the style of the nvk.tools suite of scripts. It was designed by the talented Gwen Terrien (@terromino). It is not only an improvement on the look and feel of Reaper, but it also adds additional functionality with custom transport, track FX, and channel output buttons as well as an automatic track coloring script for the ultimate Reaper aesthetic.
Author: nvk
Links:
    Store Page https://gum.co/nvk_THEME
    User Guide https://nvk.tools/docs/theme
Changelog:
    1.4.7
        New script to color selected items to a random track color
    1.4.6
        Improved behavior with custom fx buttons and embedded tcp fx ui
    1.4.5
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
    1.4.4
        New actions to load theme tab presets
    1.4.3
        Fixed error when using custom track name colors on folder tracks
    1.4.2
        New options for importing/exporting theme colors (nvktracktheme, SWSColor, clipboard)
    1.4.1
        Fixed midi inline editor background colors
        Added meter color to dedicated sends section
        Added midi inline editor icons (+hidpi)
        Improvements to theme settings preservation
    1.4.0
        Full color mode for mixer tracks
        New transport buttons for enabling track colors, next theme, previous theme
        Meter width values are now rounded to the nearest odd number for better appearance
        Color values could not update in real-time with changes depending on previous settings before recent update
        Preserve theme settings when switching between themes while the settings script is closed
        Mixer track colors now update immediately when changing settings
        Preserve theme settings when copying cfg files
        Improved import/export track color theme behavior
        Custom track name colors now work with child tracks
        Prompt to automatically color tracks when opening a project was still coloring them even if no was selected
        Option to always add new instance of custom FX (default is to toggle the UI if it's already added)
    1.3.1
        Notify if nvk_SHARED is not updated to the required version
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
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

local last_theme = r.GetLastColorThemeFile()
if not last_theme:find 'nvk_THEME' then
    local init_theme = os_is.mac and 'nvk_THEME_Dark' or 'nvk_THEME_Light'
    r.OpenColorThemeFile(init_theme .. '.ReaperThemeZip')
end
