-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
r.set_action_options(3)

local function unsolo_after_playback_stop()
    if r.GetPlayState() & 1 == 1 then
        r.defer(unsolo_after_playback_stop)
    else
        Tracks.UnsoloAll()
    end
end

run(function()
    local x, y = r.GetMousePosition()
    local _, arrange_end = r.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
    local mouse_pos = r.GetSet_ArrangeView2(0, false, x, x + 1, 0, 0)
    local item = Item(r.GetItemFromPoint(x, y, false))
    if not item then
        local media_track, info = r.GetThingFromPoint(x, y)
        local track = Track(media_track)
        if track then
            track:Select(true)
            if info:find('tcp') or info:find('mcp') then
                if track.solo then
                    track.solo = false
                else
                    track.solo = true
                end
                return
            else
                item = track:NextItemAfterPos(mouse_pos)
            end
        end
    end
    if item and item.pos <= arrange_end then
        item.track:Select(true)
        local items = item:ChildItems(true)
        local tracks = items.tracks
        items:Select(true)
        tracks:Solo(true, true)
        if mouse_pos < items.minpos + 1 then
            r.SetEditCurPos(items.minpos, false, true)
        else
            r.SetEditCurPos(mouse_pos, false, true)
        end
        r.Main_OnCommand(1007, 0) -- Transport: Play
        r.defer(unsolo_after_playback_stop)
    else
        if r.CountSelectedMediaItems(0) > 0 then
            local items = Items.Selected()
            local tracks = items.tracks
            r.SetEditCurPos(items.minpos, false, true)
            tracks:Solo(true, true)
            assert(tracks:First()):Select(true)
            r.Main_OnCommand(1007, 0) -- Transport: Play
            r.defer(unsolo_after_playback_stop)
        else
            r.Main_OnCommand(7, 0) -- Track: Toggle solo for selected tracks
        end
    end
end)
