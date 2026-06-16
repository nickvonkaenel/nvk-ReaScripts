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

    local init_item = Item(r.GetItemFromPoint(x, y, false))
    if init_item then
        local items = init_item:ChildItems(true)
        for _, item in ipairs(items) do
            if item.video then
                local vol = item.vol
                if vol > 0 then
                    item.vol = 0
                    item:SetExtState('nvk_TOGGLEVOL', vol)
                else
                    item.vol = tonumber(item:GetExtState('nvk_TOGGLEVOL')) or 1
                end
            else
                item.mute = not item.mute
            end
        end
        return
    end

    local media_track, info = r.GetThingFromPoint(x, y)
    if media_track and info then
        local init_track = Track(media_track)
        assert(init_track, 'Invalid track')
        if info:find('^tcp') or info:find('^mcp') or r.CountSelectedMediaItems(0) == 0 then
            local tracks = init_track:Children(true)
            for _, track in ipairs(tracks) do
                track.mute = not track.mute
            end
            return
        end
    end
    local items = Items.Selected()
    for _, item in ipairs(items) do
        item.mute = not item.mute
    end
end)
