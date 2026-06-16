-- @noindex
-- Removes folder items, items, tracks, envelopes, automation items, or FX depending on where the mouse is hovering.
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
        if item.folder then
            item:DeleteVolumeAutoItem():ChildItems(true):Delete()
        else
            item:Delete()
        end
        return
    end
    local media_track, info = r.GetThingFromPoint(x, y)
    if media_track and info then
        local track = Track(media_track)
        assert(track, 'Invalid track')
        if info:find('^tcp') or info:find('^mcp') then
            track:Children(true):Delete()
        elseif info:find('^env') then -- includes envcp
            local env_idx = math.floor(assert(tonumber(info:match('%d+$')), 'Invalid envelope index'))
            local env = assert(track:EnvelopeByIdx(env_idx), 'Invalid envelope')
            if info:find('envelope') then
                local mouse_pos = r.GetSet_ArrangeView2(0, false, x, x + 1)
                for i = 0, env.num_autoitems - 1 do
                    local auto_item = AutoItem(env, i)
                    if mouse_pos >= auto_item.pos and mouse_pos < auto_item.rgnend then
                        auto_item:Delete()
                        return
                    end
                end
            end
            assert(track:EnvelopeByIdx(env_idx), 'Invalid Envelope'):Delete()
        elseif info:find('^fx') then
            track:FX_Delete(math.floor(assert(tonumber(info:match('%d+$')), 'Invalid fx index')))
        end
    end
end)
