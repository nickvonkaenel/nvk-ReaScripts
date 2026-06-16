-- @noindex
-- Mutes folder items, items, tracks or selected items, or tracks depending on where the mouse is hovering.
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
    local x, y = r.GetMousePosition()

    local item = Item(r.GetItemFromPoint(x, y, false))
    if item then
        local items = item:ChildItems(true)
        for _, i in ipairs(items) do
            i.mute = not i.mute
        end
        return
    end

    local media_track, info = r.GetThingFromPoint(x, y)
    if media_track and info then
        local track = Track(media_track)
        assert(track, 'Invalid track')
        if info:find('^tcp') or info:find('^mcp') or r.CountSelectedMediaItems(0) == 0 then
            local tracks = track:Children(true)
            for _, t in ipairs(tracks) do
                t.mute = not t.mute
            end
            return
        end
    end
    local items = Items.Selected()
    for _, i in ipairs(items) do
        i.mute = not i.mute
    end
end)
