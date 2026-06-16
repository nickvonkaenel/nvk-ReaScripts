-- @noindex
-- Toggles the FX windows for the focused track or item.
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    local context = r.GetCursorContext()
    if context == 1 then -- arrange
        local item = Item.Selected()
        if item then
            local visible = false
            for i = 0, item.fxcount - 1 do
                if r.TakeFX_GetOpen(item.mediatake, i) then
                    visible = true
                    break
                end
            end
            for i = 0, item.fxcount - 1 do
                r.TakeFX_Show(item.mediatake, i, 0)
                r.TakeFX_Show(item.mediatake, i, visible and 2 or 3)
            end
            r.SetCursorContext(1)
            return
        end
    end
    local track = Track.Selected()
    if track then
        local visible = false
        for i = 0, track.fxcount - 1 do
            if r.TrackFX_GetOpen(track.mediatrack, i) then
                visible = true
                break
            end
        end
        for i = 0, track.fxcount - 1 do
            r.TrackFX_Show(track.mediatrack, i, 0)
            r.TrackFX_Show(track.mediatrack, i, visible and 2 or 3)
        end
        r.SetCursorContext(0)
    end
end)
