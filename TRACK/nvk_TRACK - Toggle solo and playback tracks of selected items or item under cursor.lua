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
run(function()
    local soloed = false
    for i = 0, r.CountTracks(0) - 1 do
        local track = r.GetTrack(0, i)
        if r.GetMediaTrackInfo_Value(track, 'I_SOLO') > 0 then
            soloed = true
            break
        end
    end

    local x, y = r.GetMousePosition()
    local pos = reaper.GetSet_ArrangeView2(0, false, x, x + 1, 0, 0)
    local item = Item(r.GetItemFromPoint(x, y, false))
    if item then
        local items = item:ChildItems(true)
        local tracks = items.tracks
        local tracks_selected = Tracks.Selected()
        if items == Items.Selected() and tracks == tracks_selected then
            if tracks_selected == Tracks.All().solo then
                r.Main_OnCommand(1016, 0) -- Transport: Stop
                Tracks.UnsoloAll()
                return
            else
                tracks:Solo(true)
                r.SetEditCurPos(pos, false, true)
            end
        else
            items:Select(true)
            tracks:Select():Solo(true)
            if pos < items.minpos + 1 then
                r.SetEditCurPos(items.minpos, false, true)
            else
                r.SetEditCurPos(pos, false, true)
            end
        end
        r.Main_OnCommand(1007, 0) -- Transport: Play
    else
        if soloed then
            r.Main_OnCommand(1016, 0) -- Transport: Stop
            Tracks.UnsoloAll()
            return
        end
        if r.CountSelectedMediaItems(0) > 0 then
            r.Main_OnCommand(1007, 0) -- Transport: Play
            local items = Items.Selected()
            if pos < items.minpos then
                r.SetEditCurPos(items.minpos, false, true)
            end
            items.tracks:Select():Solo(true)
        else
            r.Main_OnCommand(7, 0) -- Track: Toggle solo for selected tracks
        end
    end
end)
