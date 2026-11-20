--[[
Description: nvk_THEME
Version: 1.6.6
Author: nvk
About:
    # nvk_THEME

    nvk_THEME is a premium Reaper theme in the style of the nvk.tools suite of scripts. It was designed by the talented Gwen Terrien (@terromino). It is not only an improvement on the look and feel of Reaper, but it also adds additional functionality with custom transport, track FX, and channel output buttons as well as an automatic track coloring script for the ultimate Reaper aesthetic.
Author: nvk
Links:
    Store Page https://nvk.tools/theme
    User Guide https://nvk.tools/docs/theme
Changelog:
    1.6.6
        - Clarify installer instructions when nvk_SHARED is missing or needs an update
    1.6.5
        - Search for REAPER actions when assigning a custom button
        - Update Dark and Light themes to 1.8.1 and add Quiet Dark and Quiet Light variants with bundled fonts
        - Add controls for fixed lanes, pinned tracks, meter visibility, track-name labels and button rows
        - Drag track-panel FX inserts into empty slots with a new FX-list option
        - Add automatic track coloring, improved randomized palettes and per-preset Track Colors settings
        - Discover custom theme variants and refresh Settings and Track Colors with layout previews and responsive sections
        - Improve track-color modes, control rows, Transport layouts and palette color editing
        - Remove the custom splash screen
        - Use the first matching wildcard track-color rule and preserve manual colors without requiring Confirm on new project
        - Fix saving, importing, switching and discarding track-color settings, including clipboard import and use with other REAPER themes
        - Keep three-digit track numbers readable at large label sizes and fix panel alignment, fader sizing, mixer saturation and Transport visibility
        - Prevent automatic coloring from stalling plug-in windows in large projects on every parameter change
        - Improve settings recovery, prevent freezes in small or scrolled windows and support custom installation paths
    1.5.2
        Error when selecting transport settings section
    1.5.1
        Fix sizing of independent track colors window
        Disable the gradient checkbox when it would have no effect
    1.5.0
        TCP redesigned: you can now toggle widgets based on conditions on three separate layouts
        Time base: item images, transport images and new transport button added to accomodate the new REAPER feature
        Pinned tracks: added images and widget behavior linked to the new REAPER feature
        Tempo base: added new quarter, half and dotted modes to the transport tempo base options
        Font sizes: all fonts sizes have been bumped up to account for more range of readability
        Widgets react to font size: some transport and tcp widgets now account for bigger font sizes
        Added transport next and previous buttons (home and end button alternative, you can toggle them by right clicking on the < > buttons in the transport)
        Redesigned settings script layout to better fit on smaller screens
        New options for randomizing track colors: randomize all colors and randomize starting color
    1.4.9
        Changing excluded words in the track color targets now updates the track colors
    1.4.8
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
        Option to color tracks by their depth in the track hierarchy
    For full changelog, see https://nvk.tools/docs/theme#changelog
Provides:
    [main] *.lua
    Data/**/*.lua
    Data/modules.pack
    Data/img/*.png
    [theme] nvk_THEME_Dark.ReaperThemeZip
    [theme] nvk_THEME_Light.ReaperThemeZip
    [theme] nvk_THEME_Quiet_Dark.ReaperThemeZip
    [theme] nvk_THEME_Quiet_Light.ReaperThemeZip
    Data/fonts/nvk_SANS-RegularTabular.ttf
    Data/fonts/nvk_SANS-RegularUI.ttf
    Data/fonts/OFL-RedditSans.txt
    Data/fonts/README.txt
--]]
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

local last_theme = r.GetLastColorThemeFile()
if not last_theme:find('nvk_THEME') then
    local init_theme = os_is.mac and 'nvk_THEME_Dark' or 'nvk_THEME_Light'
    r.OpenColorThemeFile(init_theme .. '.ReaperThemeZip')
end
