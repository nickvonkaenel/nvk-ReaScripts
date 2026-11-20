--[[
Description: nvk_SHARED
Version: 5.2.2
About:
    # nvk_SHARED

    nvk_SHARED is a common library for all scripts in the nvk-ReaScripts repository. It contains functions and data that are used by multiple scripts and is required to run them.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
    5.2.2
        Appearance and controls
            - Search installed REAPER actions by name or command ID directly in Startup Actions and other action pickers
            - Support editing matching appearance settings and keyboard shortcuts directly in Preferences search
            - Add Light and Dark themes and accent presets in Preferences, with an option to give each script its own appearance
            - Combine theme and style editing in one Advanced window with Save and Cancel; remove the whole-theme color sliders
            - Add nvk_SANS and nvk_MONO fonts, searchable font previews, and global font and zoom settings
            - Refresh Preferences, toolbars, presets, selectors and color pickers, with improved readability at different sizes
            - Remove the animated Party Mode theme
            - Add custom waveform gradients, opacity and docked-theme brightness controls; move Waveform color into Preferences
            - Improve preset menus, confirm removal, and save edits to inactive presets
            - Add Reset all settings and Clear all user data, preserving saved presets and user work during a settings reset
            - Preserve theme and accent changes made in other scripts while appearance settings are open
            - Use the script background when Match REAPER when docked is off, unless a custom docked background is set
        Windows and shortcuts
            - Show which actions will lose a keyboard shortcut before reassigning it or restoring default bindings
            - Reopen single-instance windows without REAPER’s running-script prompt when a compatible nvk_API is installed
            - Improve docking, FX pickers, keyboard shortcuts, macOS shortcut labels and Startup Actions organization
            - Add Disable drag to dock in Preferences and let Tab and Shift+Tab move between number fields
            - Show full dropdown names and values on hover, keyboard focus outlines, and built-in shortcut restrictions
            - Keep long toolbar hover text readable and explain how to retry a failed FX screenshot capture
            - Keep screenshot menus stable while hovering over their controls
            - Fix trackpad scrolling stepping unevenly on controls and prevent controls from opening the empty-space context menu
            - Add a License section to paid scripts' Preferences and fix Open License Manager reporting that nvk_SHARED is missing
        Reliability
            - Keep overlapping child items in a folder selection when a later, shorter item ends before the folder
            - Fix take detection missing later sounds when REAPER returns only part of a waveform
            - Preserve existing files when copying audio fails and reduce memory used for large copies
            - Restore MCP tools and rendering when SWS and js_ReaScriptAPI are absent
            - Recognize a single-space item name as unnamed
            - Ignore Vordio video clips and captions that were previously tagged as folder items
            - Fix errors when scrolling dialogs
            - Save settings safely, recover after a failure, and keep presets and user data safe if a script closes during a settings reset
            - Fix settings saves on full disks and loading from network installations or Windows paths with non-English characters
            - Fix freezes in small or scrolled windows, delayed freezes after opening, and Windows scripts closing while still focused
            - Add optional anonymous error reporting and show complete errors in the console
            - Fix REAPER no longer redrawing after a script error during an edit
            - Improve performance with large item selections, highlighted search results and long font lists
            - Preserve curved fades and automatic crossfade curves in REAPER 7.82 and later
            - Fix take navigation with empty, reversed or looping items and different playback rates; preserve take markers during analysis
            - Preserve unrelated automation selections, take polarity and MIDI source lengths during item operations
            - Fix marker, region and envelope errors after undo or deletion; leave unrelated empty items on folder tracks alone
            - Scroll focused tracks below pinned tracks and fix render-stat weekday text on non-English systems
        Updates and requirements
            - Show when REAPER still needs to restart to load an installed update
            - Recommend the optional nvk_API extension once on supported ReaPack installations
            - Add automatic updates in Preferences, including beta versions, Check for updates and What's new after an update
            - Prompt once per session when installed packages need updating together, while keeping older scripts working
            - Improve update checks on older systems and behind firewalls or proxies, with explanations when a check fails
            - Order update versions as ReaPack does, including releases following beta versions
            - Support the nvk tools installer without ReaPack and move updated actions to their correct action-list section
            - Make SWS and js_ReaScriptAPI optional for supported functionality when nvk_API is installed
            - Requires ReaImGui 0.10.0.3 or newer
    4.4.1
        Error when trying to activate a license in the upgrade popup
    4.4.0
        Allow for disabling close if unfocused in command pallette mode
        Fix for duplicated markers when undoing folder item duplication
        Move region ends when moving markers with ripple in nvk_VARIATIONS
    4.3.0
        Improve behavior when nvk_SEARCH is set to always on top and a project is loaded with prompts in the same location as the script. Not completely fixed, recommend not using 'Always on Top' if possible
    4.2.0
        Minor visual improvements
        Can now reset style sliders to default value with right-click
    4.0.0
        Support for new take detection behavior and scripts
        Codebase refactoring - make sure to update all your scripts to the latest version
        Various minor improvements and bug fixes
        Support for latest version of ReaImGui, font improvements
        Script unfocused color improvements, a little bit more clear when script does not have focus
    For full changelog, visit https://nvk.tools/docs/shared#changelog
Provides:
    Data/**/*.lua
    Data/modules.pack
    Data/fonts/THIRD_PARTY_NOTICES.txt
    Data/fonts/OFL-RedditSans.txt
    Data/fonts/nvk_SANS-Regular.ttf
    Data/fonts/nvk_SANS-Bold.ttf
    Data/fonts/nvk_SANS-RegularTabular.ttf
    Data/fonts/nvk_MONO-Regular.ttf
    **/*.otf
    [main] *.lua
--]]
