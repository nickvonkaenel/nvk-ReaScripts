--[[
Description: nvk_CREATE
Version: 1.8.2
About:
  # nvk_CREATE

  nvk_CREATE gives you a whole new way to find and import audio files from your Media Explorer databases.
  -Search multiple databases simultaneously with instant results as you type.
  -Automatically trim and add take markers to items.
  -Multi-layer mode allows you to intelligently create layered assets based on your search string with settings for length, pitch randomization, reverse, and insertion mode.
  -Swap out assets in your project based on the search string used for that item or the name of the track with the replace script.
  -And more!
Author: nvk, Neutronic
Links:
  Store Page https://gum.co/nvk_CREATE
  User Guide https://reapleton.com/doc/nvk_CREATE
  REAPER forum thread https://forum.cockos.com/showthread.php?t=259057
  Neutronic's REAPER forum profile https://forum.cockos.com/member.php?u=66313
  Neutronic's GitHub ReaScripts repository https://github.com/Neutronic/ReaScripts
Provides:
  Data/*.dat
  Data/inv.cur
  [jsfx] *.jsfx
  [main] *.lua
Changelog:
  1.8
    - Importing items now respects user setting for copying imported media items to project
    - Fix for not being able to change take offset in item peaks view if the take contained stretch markers
    - 1440p zoom option
    - Support for beta sws extension with more robust playback
    - Possible fix for item fades being affected by replace script
    - Replace no longer works on locked items
    - Greatly improved search speeds after first completed search
    - Fixed bug where adding a new item over an existing item would delete the existing item
  1.7.3 Respect project setting for preserve pitch enabled on items, playback preview pdc now accounts for bypassed fx
  1.7.2 Alt-drag from waveform view now only adds the selected variation
  1.7.1 Fixed crash when cancelling apply track fx, improvements to search speed, fixed bug where zoom wasn't working when using spectral peaks, now you can zoom in and out in all waveform views, selection playback now loops if setting enabled
  1.7
    - Zoom and preview selected item peaks. Mousewheel scroll now zooms in and out of item peaks preview and clicking outside the selection will preview. Shift-click will preview inside selection. While zoomed in, dragging the selection to the corner will automatically scroll the window. Shift-scroll will move the view left or right when zoomed in
    - Alt double-click in item peaks window will move sound to the new region without changing the length or position of the item (keeping snap offset the same)
    - Old mousewheel behavior in item peaks can still be used by holding control (for now, might get rid of this since it's not that useful)
    - Improved performance with Soundminer and multi-layer mode as well as replace script
    - Fixed bug where take markers would still be created with replace script
    - Fixed bug where sometimes take markers wouldn't be removed from replaced items
    - Playback preview line now compensates for pdc when previewing through track
    - Ctrl/cmd when dragging retrospective record selection will now apply track fx
    - Behavior change when holding shift and dragging a sound into the project. If dragging a result, shift will override the auto-trim setting. If dragging a selection from the waveform view and holding control, shift will only process that specific area. Shift by itself shouldn't have any effect when dragging from waveform view for now.
    - Disable auto-naming of multi-layer tracks by Reaper
  1.6.5 Fixed bug introduced in 1.6.4 if SWS not installed
  1.6.4 Option to allow for empty searches with replace script, lock button to keep focus on playback peaks for retrospective recording, option to disable take markers/snap offsets
  1.6.3 Option to focus arrange after mouse drag-drop
  1.6.2 Adding option in config file to set fade in time and changing default fade in time from 0.01 to 0.001 for better transients
  1.6.1 Minor bug fixes
  1.6
    - Undocked split-view (new option): features of docked mode while not docked.
    - Docked split-view option removed, added option for split: disabled instead.
    - Hold shift when dragging or inserting item to override trim setting. If auto-trim is enabled, it will be disabled and vice-versa.
    - New keyboard shortcuts for docking/undocking, enable undocked split mode, and focus arrange window
    - Demo time would expire if attempted to input license key.
    - Improved licensing UX
    - Fix issue when dragging retrospective recording into project with 0 results found
  1.5.2 Licensing Improvements
  1.5.1
    -Fix issue with nvk_RECORD tutorial restarting
    -Turn on 'resolve Soundminer file paths' by default
  1.5
    -nvk_RECORD (Retrospective Recording): Click on the playback preview mode to enable nvk_RECORD. When you don't have any items selected, you will be able to right-click-drag to make a selection and then click-drag to bring it into your project. You can also preview by clicking and holding down the mousebutton.
    -Soundminer Integration: nvk_CREATE now allows you to select Soundminer as a database. Simply install the latest version of Soundminer and the Soundminer REAPER integration and then open the script. With Soundminer open, you will be able to search the current Soundminer database. You can also filter results with Soundminer and then bring them up in nvk_CREATE by doing a blank search. Great for making a custom filter for multi-layer mode.
    -Colors: choose from a number of custom themes for your waveform or highlight colors or create your own by selecting 'custom'. You can also now change themes/colors with F11/F12 and modifier keys.
    -Filters: You can now add filters to your search (channel count, sample rate, bit rate, file length, region length). For example, if you only wanted to find files that were above 48k, you could search for "growl 48k+" and it would only return files that match "growl" and are 48k or above. Improved functionality of NOT, OR, and "" searches. Now you can do things like: growl or roar tiger or leopard or lion not "sound ideas". You can also use the Soundminer format for searches eg: "rock (heavy, metal, hard) -pop" 
    -New options:
      -Waveform: Select waveform color.
      -Highlight: Select highlight color.
      -Split: you can now force a specific split orientation. Automatic will decide which orientation to use depending on the script window dimensions.
      -Particle effects: Enables particle effects on retrospective record playback line.
      -Preview pitch: Change the playback pitch when previewing sounds. Mostly there for hotkey reference since it gets reset every time you close and re-open the script.
      -Disable auto-search: script won't complete search until you press enter. Useful for very large Soundminer databases where searching as you type might not be performant.
      -Show full file-path: results will display the full-file path instead of just the file name. You can also view the full-file path without this option during playback in the tooltip area at the top of the script.
      -Save multi-layer state: when closing the script, if you have multi-layer mode open it will be open next time you open the script.
      -Retro waveforms: gives the waveforms a retro look and slightly reduces cpu use
    -Improvements/fixes:
      -7-day trial available now to test before purchasing the script
      -Better calculation of results to display after turning multi-layer mode on and off while docked.
      -Spacebar starts/stops timeline playback in more situations where it makes sense.
      -Waveform appearance improved (anti-aliased, fill to zero line)
      -Keyboard input now processed on same frame as graphics display (might slightly improve responsiveness)
      -Issue with editing selected items that had playrate other than 1
      -Fixed mouse cursor bugs when showing selected item peaks
      -Crash when running multi-layer mode without any matches
      -Display channel count, bit rate, and sample rate after file metadata
      -Fixed lag occuring when using pin to top icon
      -Various optimizations:
        -Improved load time of dbcache
        -Improved speed of peak generation in REAPER 6.43+, taking advantage of new multi-core peak generation.
        -Deferred functions close instantly when exiting script (if possible)
        -Removed unnecessary global variables.
        -Reduced draw calls.
        -Refactored peak analysis functions to improve responsiveness of script
    -Changes:
      -Removed result placeholders while docked option. Didn't seem that useful and was causing bugs.
  1.1.2 Database selection now saves immediately to config instead of at script close so replace script can use new database immediately. Bug fixes.
  1.1.1 Various bug fixes
  1.1 Right-click drag to create time selections in waveforms (first pass on this feature, planning to improve). Various bug fixes.
  1.0.4 Fix for databases not being found due to incorrect REAPER.ini, crash when pressing F3 with no databases selected, default to not combining variations for new users, multi-layer now shows count of generated multi-layer variations in tooltips, can no longer favorite databases (it didn't work anyway), error when selecting empty item while script is docked
  1.0.3 File names with quotes no longer break things 2: Electric Boogaloo
  1.0.2 File names with quotes no longer break things
  1.0.1 Bug fixes, licensing improvements 
  1.0 Initial Release
--]]
local info = debug.getinfo(1,'S')
dofile(info.source:match[[^@?(.*[\\/])[^\\/]-$]].."Data/main.dat")