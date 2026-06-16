-- @noindex
-- Copy items, tracks, automation items under the mouse cursor, falls back to built-in copy command if nothing found under mouse that can be copied
-- USER CONFIG --
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
    local media_track, info = r.GetThingFromPoint(x, y)
    if item then
        return item:Copy()
    end
    if media_track and info then
        local track = Track(media_track)
        assert(track, 'Invalid track')
        if info:find('^tcp') or info:find('^mcp') then
            return track:Children(true):Copy()
        elseif info:find('^env') then -- includes envcp
            local env_idx = math.floor(assert(tonumber(info:match('%d+$')), 'Invalid envelope index'))
            local env = assert(track:EnvelopeByIdx(env_idx), 'Invalid envelope')
            if info:find('envelope') then
                local mouse_pos = r.GetSet_ArrangeView2(0, false, x, x + 1)
                for i = 0, env.num_autoitems - 1 do
                    local auto_item = AutoItem(env, i)
                    if mouse_pos >= auto_item.pos and mouse_pos < auto_item.rgnend then
                        return auto_item:Copy()
                    end
                end
            end
        end
    end

    -- fallback if mouse is not over anything that can be copied
    r.Main_OnCommand(40057, 0) -- Edit: Copy items/tracks/envelope points (depending on focus) ignoring time selection
end)
