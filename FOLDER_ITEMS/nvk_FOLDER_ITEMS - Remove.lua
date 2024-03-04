-- @noindex
-- USER CONFIG --
selectItemUnderMouse = true --this script doesn't really do much without this set to true, just deletes items or tracks
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local item
    if selectItemUnderMouse then
        reaper.Main_OnCommand(40296, 0) -- select all tracks
        reaper.Main_OnCommand(40769, 0) -- unselect everything (have to select all tracks first else some envelope tracks can be selected)
        item = GetItemUnderMouseCursor()
    else
        if reaper.GetCursorContext() == 0 then
            reaper.Main_OnCommand(40005, 0) -- remove track
        else
            reaper.Main_OnCommand(40006, 0) -- remove items
        end
        return
    end

    if item then
        reaper.SetMediaItemSelected(item, true)
        groupSelect(item)
        local env = reaper.GetTrackEnvelopeByName(reaper.GetMediaItemTrack(item), "Volume")
        if env then
            local autoitemIdx = GetAutoitem(env, reaper.GetMediaItemInfo_Value(item, "D_POSITION"))
            if autoitemIdx then
                reaper.GetSetAutomationItemInfo(env, autoitemIdx, "D_UISEL", 1, true)
            end
        end
        local track = Track(r.GetMediaItem_Track(item))
        local compact_tracks = track:UncompactChildren(true) -- store tracks to compact after, a v7 compatibility thing with hidden tracks
        reaper.Main_OnCommand(40006, 0) -- remove items
        compact_tracks:Compact()
        return
    end

    if SelectAutomationItemUnderMouseCursor() then
        reaper.Main_OnCommand(40006, 0) -- remove items
        return
    end
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    if window == "tcp" or window == "unknown" then
        if segment == "track" then
            reaper.Main_OnCommand(41110, 0) -- select track under mouse
            reaper.Main_OnCommand(40005, 0) -- remove track
        elseif segment == "envelope" then
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SEL_ENV_MOUSE"), 0) -- select envelope track under mouse cursor
            if reaper.GetSelectedEnvelope(0) then
                reaper.Main_OnCommand(40065, 0) -- clear envelope
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
local items = Items()
Main()
reaper.Main_OnCommand(41110, 0) -- select track under mouse
items.sel = true
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
