--[[
Description: nvk_SEARCH
Version: 1.10.4
About:
  # nvk_SEARCH

  This script is used to quickly search for FX, chains, actions, projects, etc in Reaper. Requires REAPER 7 or higher.
Author: nvk
Links:
  REAPER forum thread https://forum.cockos.com/showthread.php?t=286729
  User Guide: https://nvk.tools/doc/nvk_SEARCH
Changelog:
  + 1.10.4
    + Trial improvements
  + 1.10.3
    + Open take source file in right-click context menu
  + 1.10.2
    - Fixed: crash when adding fx to the master track
  + 1.10.1
    + Removing 'reveal hidden tracks' setting as it seems pointless. If you don't want a track to be revealed, don't select it.
    + Fully collapsed tracks will now be revealed by uncollapsing the parent track when searched
  + 1.10.0
    + Updating layout of preferences, consolidating some categories and moving things around
    + FX - Alt mode: option to change what happens when alt is held while adding fx. Can now switch to the alt key determining whether to add fx to an item or track. This overrides the default behavior of adding depending on focus.
  + 1.9.7
    - Fix crash when sorting results by name with unnamed markers in the project
    - Certain keyboard shortcuts not working after opening the preferences window
  + 1.9.6
    - Theme import not working on Windows
  + 1.9.5
    - Results not updating when re-opening script in persistent mode with an existing search
  + 1.9.4
    + FX menu popup no longer displays unless mouse is moved since it could be annoying if the mouse happened to be there on startup
    + Context menu option to add any fx as instrument track not just VSTi, AUi, etc
    + Esc key now closes the preferences window if it's focused (esc always closes script will still close everything)
  + 1.9.3
    - Context menu for alt add fx not working
    + Option to load last search on startup
    + Better handling of disabled checkboxes (show override setting)
  + 1.9.2
    + Improved behavior when dragging to re-order folders, results, fx
    - Palette mode UI could be positioned incorrectly if opening with a filter
    + New scripts for opening with a specific filter enabled
  + 1.9.1
    + Persistent mode: with this enabled, the script will stay open until quit. It will reopen whenever it's run again, but won't have to rescan everything. This makes the startup time instantaneous. It will also remember the last search and any selected results. To fully close the script, use the quit hotkey.
    + New option: Rescan results - mostly useful for persistent mode, in case you add new fx or actions while the script is open. This will rescan the results without having to restart the script.
    + New option: Always on top - useful in case script is hidden behind other windows such as pinned fx.
    - Fixed: couldn't rename folders because search would get focused from text entry.
  + 1.9.0
    + Command Palette mode: minimal search window with no sidebar or results until search is performed. Hides a lot of the UI. Can be toggled with the keyboard shortcut.
    + Alphanumeric input now focuses the search bar from anywhere
    + New shortcut options
    - Fixed: search string help text now honors disabled result types
    - Fixed: crash with alt-click on 'All' folder
    - Fixed: enter on empty search could add fx
    - Fixed: docking preferences script in main script window could cause script to break
    - Fixed: FX window still shown even if 'show fx window after insertion' is disabled with certain Reaper preferences
  + 1.8.1
    + New option: FX - Always add to track
    + Themes: import/export and save as global default
    + Load time optimizations
    - Fixed: preferences being closed could unfocus the script and cause it to close
  + 1.8.0
    + Sort methods for results. Choose from relevance (new optimized search algorithm), order (results display in default order they are scanned), name (alphabetical a-z), or last modified date (if applicable)
    + Improved hover text
    + New option: Active filter disables filter keys
    + New option: Actions - only show main section
    + Show favorite icon in recent results (was confusing that you could favorite/unfavorite recent results without the icon)
    - JSFX not showing up in sidebar FX list
    + Changing label JSFX to JS in certain cases
    + Capitalizing type names for more consistent display
    + New keyboard shortcuts and slight changes to naming for open and open in external editor
    - Fixed: cursor context could be lost when window is closed and re-opened (determing if cursor is on item or track)
  + 1.7.0
    + Fx types now display in order of user preference in sidebar
    + New option to 'Close if unfocused' in preferences
    + Possible fix for crash with certain takes that have invalid source media
    + New option in settings to import user folders from FX Browser into sidebar
    + Search algorithm tweaked to hopefully give more useful results
  + 1.6.6
    - Fixed: actions not showing up in folders unless 'show command id' was enabled
    - Fixed: crash when showing script in finder
    + Open script option in context menu to open script in a text editor (or whatever is set as the default program for .lua files)
  + 1.6.5
    - Fixed: alternate fx add mode was not working properly
  + 1.6.4
    - Fixed: when adding fx from sidebar to current selected folder, the folder was not being updated
  + 1.6.3
    - Fixed: incorrect link to forum thread
  + 1.6.2
    - Fixed: cleared recent projects list was still showing up in results
  + 1.6.1
    - Improved speed of adding multiple fx in a row with enter
  + 1.6.0
    + New feature: add custom project paths in preferences
      + Paths will be scanned recursively for .rpp files on add. They can be rescanned manually. Recent project files will still show up in the results so this won't need to be done often.
      + Scanned projects can be sorted by name or last modified date (note: last modified date can slow down startup times if there are a lot of projects)
      + When adding a path, a new folder will be created with that project path in the sidebar. FYI, if removed from this folder, it may be re-added next time a project path is added or removed.
      + Recent projects will show up first in the results
    + Rearranged preferences to make better use of space and fit new projects feature
    + Preferences no longer behaves as a popup, and must be manually closed. It will reopen if the script is restarted while it is open.
    + Tooltips when hovering over folders and project paths that are too long to display
    - Fixed: Esc key was not closing the keyboard shortcut popup
  + 1.5.3
    - Fixed: Crash with project names that are just .rpp
  + 1.5.2
    - Crash when adding fx
  + 1.5.1
    - Fix for possible crash with some project names
  + 1.5.0
    + Multiple selection of items allowing for adding multiple FX at once or dragging/removing multiple results from a folder
    + New options: open projects in new tab, hide project patch, keep search on folder change
    + New context menu option: Open project/track template in new tab
    + Display user keyboard shortcuts in context menu
    + FX duplicates are now removed in order of fx display options
    + VST3 and VST3i are now separate from VST and VSTi
    + Projects added to folders are now saved permanently
    - Fixed: certain C++ extensions could cause actions to not be scanned properly
    + Rearranged preferences
    + Favorites section: favorites can be displayed at the top in their own section regardless of result type
    + Favorites can now be rearranged with drag and drop
    + Support for matching multiple words in quotes
    + Menu bar: show fx window after insertion
    + Option to disable certain results from being displayed with alt-click
    + If filter is set to an excluded result type, it will show the results regardless of global settings, allowing you to temporarily find results that are normally hidden
    + Alt fx add (insert fx for non-inst fx and create midi track for inst fx) with alt + enter or alt + drag to track (can alt-click from sidebar fx list or alt-double click from results list)
    + FX can be added to master track by dragging directly on the master track
    + To add fx to monitor fx chain, hold alt while dragging the fx to the master track
    + Context menu to add fx to master track or monitor fx chain
    + More compact keyboard shortcuts name display
    ! Toggle favorites mouse click modifier changed to ctrl/cmd+shift instead of alt
    + Exclude filters from search with hyphen prefix i.e. "-f" will exclude fx from the results
  + 1.0.3
    + Drag and drop all valid results to folders, not just FX
    + New option: reveal hidden tracks when selected in results list
  + 1.0.2
    - Fixed: Crash on load for certain systems due to actions.dat loading out of order
  + 1.0.1
    - Fixed: Duplicate tooltip on hover esc always closes script option
    - Fixed: AU plugins not adding properly
  + 1.0.0
    + Initial release
Provides:
  **/*.dat
  **/*.otf
  [main] *.lua
--]]
STARTUP_TIME = reaper.time_precise()
SCRIPT_FOLDER = 'search'
r = reaper
if not r.APIExists('EnumInstalledFX') then
    r.MB('Please update to REAPER 7 or higher to use the script.', 'nvk_SEARCH', 0)
    return
end
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
