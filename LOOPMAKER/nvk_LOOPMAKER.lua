--[[
Description: nvk_LOOPMAKER
Version: 2.7.1
About:
    # nvk_LOOPMAKER
    nvk_LOOPMAKER Creates perfect zero-crossing loops out of selected items. If Loop Count is set to a number higher than 1, it will create multiple loops out of a single item that can be played back to back with sample accurate transitions.
Author: nvk
Links:
    Store Page https://nvk.tools/loopmaker
    User Guide https://nvk.tools/docs/loopmaker
Changelog:
    2.7.1
        - Clarify installer instructions when nvk_SHARED is missing or needs an update
    2.7.0
        - Redesign the window around Loop and Shepard Tone modes, with collapsible Position and Name settings and persistent Cancel and Apply controls
        - Add a waveform loop view: drag the splice marker to choose the zero-crossing search and edit the crossfade in a magnified seam view
        - Play the loop preview with a visible play position; step through selected items with the Left and Right arrow keys
        - Drag or type crossfade length and curve, nudge them with Alt+arrow keys, and keep them editable with Live preview off
        - In Shepard Tone mode, drag the overview to change pitch, enter semitones per loop and edit the fade curve
        - Keep Loop count and Shepard Tone slice count independent, preserving existing preset counts
        - Show per-item zero-crossing and crossfade results, including seams that cannot be crossfaded
        - Undo and redo settings with Cmd+Z and Cmd+Shift+Z; undo immediately after Apply restores the original items
        - Keep settings usable in docked or narrow windows, with clear explanations for disabled controls and items too short to loop
        - Ask how to handle items outside the time selection, restoring a cleared time selection when canceled
        - Disable time-selection fitting for Shepard Tone or multiple items on one track; disable Apply when there is nothing to loop
        - Add New order for shuffled loops; rename Second snap to Snap to whole seconds; Z selects Loop and the P, C and N shortcuts are removed
        - Remove source extensions and trailing tags by default; when keeping extensions, put loop numbers and suffixes before them
        - Fix crossfade curves in REAPER 7.81 and later, preserve them through undo and cancellation, and avoid extra fades from split-crossfade preferences
        - Fix prefixes, suffixes and separators in item names, and crossfade shortcuts when Max fade limits the length
        - Improve live preview responsiveness with several items selected and support custom installation paths
    2.5.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    For full changelog, visit https://nvk.tools/docs/loopmaker#changelog
Provides:
    Data/**/*.lua
    Data/modules.pack
    [main] *.lua
--]]
SCRIPT_FOLDER = 'loopmaker'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
