--[[
Description: nvk_SEARCH
Version: 2.2.1
About:
    # nvk_SEARCH

    This script is used to quickly search for FX, chains, actions, projects, etc in Reaper. Requires REAPER 7 or higher.
Author: nvk
Links:
    REAPER forum thread https://forum.cockos.com/showthread.php?t=286729
    User Guide: https://nvk.tools/docs/search
Changelog:
    2.2.1
        Search and browse
            - Redesign results with compact and detailed views, clearer metadata and a resizable Browse and Tags sidebar
            - Add an optional sidebar Add button showing where results will go, with more FX insertion options
            - Rename collections to Tags; tag results from their context menu and assign custom icons and colors
            - Add Tab-to-browse filters, visible search scopes, Suggested results, a New filter and optional recency/frequency ranking
            - Improve fuzzy matching, synonyms and relevance sorting, and explain which settings and extensions fuzzy matching needs
            - Search by action shortcut, assign shortcuts from results and view toggle states
            - Add searches for Project Templates, Subprojects, Take Markers and individual FX formats
            - Respect REAPER's Hidden FX folder in REAPER 7.83 and later
            - Double-click the header to collapse SEARCH; typing or launching it again expands it
            - Ctrl+R performs a full refresh and rescan; use the heart button to favorite results
        nvk_MINIMENU and Visual FX
            - Add a keyboard-driven launcher with folders, shortcuts, recents, a Chain Library, persistent and stay-open modes
            - Import and export layouts, REAPER toolbars and FX favorites; undo, redo, repeat or randomize commands
            - Browse FX with thumbnails or full-interface previews, bulk capture, custom PNGs and graphical JSFX
            - Recapture screenshots for multiple selected effects, including selections across plug-in formats
            - Insert into FX containers, target or replace focused chains and reveal plug-in paths
            - Show Visual FX cards with names below their previews; capture screenshots of scripts as well as effects
            - Open preview layout and capture settings beside Visual results; resize previews with Ctrl/Cmd+scroll
            - Visual FX requires the nvk_API extension package from ReaPack
        Improvements and fixes
            - Keep launch shortcuts from reaching REAPER when reopening SEARCH
            - Build the index in the background and improve large-library performance, keyboard navigation and drag-and-drop
            - Save tags, favorites and settings as they change so a REAPER crash no longer loses them
            - Keep narrow windows readable, confirm tag removal and keep MiniMenu entries stationary when batch actions appear
            - Keep persistent searches, filters, favorites and project results current after reopening, rescanning or changing projects
            - Fix the New filter disappearing after rescans and searches ignoring the character after a closing quote
            - Fix Enter on scrolled-out results, FX-slot actions, Clear folders and inserting AU plug-ins without manufacturer names
            - Fix MiniMenu FX-favorites import and removed project directories remaining searchable
            - Fix errors with pinned folders, deleted project objects, saved settings without ReaPack and Windows paths with non-English characters
            - Apply Instrument tracks auto-arm when selected to existing tracks receiving an instrument
    1.20.0
        Added 'Take Marker' as a result type
        Fix error when adding fx to a folder with the right click menu when an empty folder name exists
    1.19.1
        Improve behavior when nvk_SEARCH is set to always on top and a project is loaded with prompts in the same location as the script. Not completely fixed, recommend not using 'Always on Top' if possible
    1.19.0
        Updated layout for preferences window
        Reduce flicker when opening palette mode
    1.18.3
        Adding subprojects as a result type. Filter key for project templates is now 'n' instead of 's'.
    1.18.2
        Selecting multiple results and pressing enter will now add all of them properly
        Sidebar can now be moved to the right side of the window
        Font improvements
    1.18.1
        Fix for error when timestamps aren't parsed correctly
        New tracks added with drag and drop will now be selected and set to last touched in order to match behavior of the built-in FX browser
        Error when parsing smart fx folders with no string match
    1.18.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    For full changelog, visit https://nvk.tools/docs/search#changelog
Provides:
    Data/**/*.lua
    Data/modules.pack
    [main] *.lua
--]]
STARTUP_TIME = reaper.time_precise()
SCRIPT_FOLDER = 'search'
r = reaper
if not r.APIExists('InsertTrackInProject') then
    r.MB('Please update to REAPER 7.18 or higher to use the script.', 'nvk_SEARCH', 0)
    return
end
-- Arm the launch keyboard guard inside the launching key's own event, before anything slow loads: until the new
-- window actually holds OS keyboard focus, keystrokes would otherwise fall through to REAPER's main window and run
-- whatever shortcuts they are bound to (github.com/cfillion/reaimgui/issues/26). While armed, the guard both blocks
-- and records the keys; Data/scripts/search/data/keyguard.lua replays them and releases the guard. nvk_API's ordered
-- native capture is preferred (typed order, repeats of the same key, a natively enforced deadline); js_ReaScriptAPI's
-- key intercept is the fallback. Either way the arm-time atexit frees the keyboard if loading fails before
-- keyguard.lua takes ownership by clearing the handoff global.
--
-- The guard is needed even on the nvk_GUI fork, which creates the window and gives it OS keyboard focus inside the
-- script's first defer callback (Present): keys typed during this synchronous load are dispatched from the event
-- queue to REAPER's main window as soon as this file returns, BEFORE the first defer tick can create the window.
-- No window or focus improvement can reach those keys; only intercepting them here, inside the launching key's own
-- event, can (verified 2026-08-31: with arming skipped on the fork, a Backspace+S burst still ran S's split
-- binding). The fork does shorten the guarded window and makes the focus-based release deterministic.
KEYGUARD_T0 = nil
KEYGUARD_NATIVE = nil
if r.APIExists('NVK_KeyCapture_Begin') and r.NVK_KeyCapture_Begin(2.5) then
    KEYGUARD_NATIVE = STARTUP_TIME
    r.atexit(function()
        if KEYGUARD_NATIVE then
            KEYGUARD_NATIVE = nil
            r.NVK_KeyCapture_End()
        end
    end)
elseif r.APIExists('JS_VKeys_Intercept') then
    KEYGUARD_T0 = STARTUP_TIME
    r.JS_VKeys_Intercept(-1, 1)
    r.atexit(function()
        if KEYGUARD_T0 then
            KEYGUARD_T0 = nil
            r.JS_VKeys_Intercept(-1, -1)
        end
    end)
end
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    -- This launch bounced: off the single-instance gate when the persistent instance will reopen (the gate leaves
    -- state at 'reopen'), or off a real load failure. Hand the armed guard to the running instance on a bounce and
    -- release it outright on a failure, so it can never outlive the launch it belonged to.
    local bounced = r.GetExtState('nvk_SEARCH', 'state') == 'reopen'
    if KEYGUARD_NATIVE then
        local t0 = KEYGUARD_NATIVE
        KEYGUARD_NATIVE = nil
        if bounced then
            -- The capture is global in the extension and its deadline is enforced natively, so the handoff is just
            -- an offer to take over polling; nothing here needs to stand watch.
            r.SetExtState('nvk_SEARCH', 'keyguard_native', tostring(t0), false)
        else
            r.NVK_KeyCapture_End()
        end
    elseif KEYGUARD_T0 then
        local t0 = KEYGUARD_T0
        KEYGUARD_T0 = nil
        local released = false
        local function release_guard()
            if released then
                return
            end
            released = true
            r.JS_VKeys_Intercept(-1, -1)
        end
        if not bounced then
            release_guard()
            return
        end
        r.atexit(release_guard)
        -- A crashed earlier handoff can leave a stale ADOPTED signal behind; it must not answer this offer.
        r.DeleteExtState('nvk_SEARCH', 'keyguard_adopted', false)
        r.SetExtState('nvk_SEARCH', 'keyguard', tostring(t0), false)
        local function watchdog()
            if r.HasExtState('nvk_SEARCH', 'keyguard_adopted') then
                -- The instance holds its own intercept now; dropping this one leaves the count above zero.
                r.DeleteExtState('nvk_SEARCH', 'keyguard_adopted', false)
                release_guard()
            elseif r.time_precise() - t0 > 1.0 then
                r.DeleteExtState('nvk_SEARCH', 'keyguard', false)
                release_guard()
            else
                r.defer(watchdog)
            end
        end
        watchdog()
    end
    return
end
