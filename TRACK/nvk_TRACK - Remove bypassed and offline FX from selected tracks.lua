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
-- FX inside containers (REAPER 7) are removed too (discord:1379698273761103882). Their addresses come from
-- container_item.N and change whenever an item in that container is deleted, so each FX is found again by its index
-- path from the top of the chain just before it is used. A bypassed or offline container goes with everything in it.
local function container_count(track, address)
    if not reaper.TrackFX_GetNamedConfigParm then
        return nil
    end
    local ok, count = reaper.TrackFX_GetNamedConfigParm(track, address, 'container_count')
    return ok and tonumber(count) or nil
end

local function resolve(track, path)
    local address = path[1]
    if #path > 1 and not reaper.TrackFX_GetNamedConfigParm then
        return nil
    end
    for depth = 2, #path do
        local ok, item = reaper.TrackFX_GetNamedConfigParm(track, address, 'container_item.' .. path[depth])
        address = ok and tonumber(item)
        if not address then
            return nil
        end
    end
    return address
end

local function remove_from_chain(track, prefix)
    local count
    if #prefix == 0 then
        count = reaper.TrackFX_GetCount(track)
    else
        count = container_count(track, resolve(track, prefix)) or 0
    end
    for index = count - 1, 0, -1 do
        local path = { table.unpack(prefix) }
        path[#path + 1] = index
        local address = resolve(track, path)
        if address then
            if not reaper.TrackFX_GetEnabled(track, address) or reaper.TrackFX_GetOffline(track, address) then
                reaper.TrackFX_Delete(track, address)
            elseif container_count(track, address) then
                remove_from_chain(track, path)
            end
        end
    end
end

run(function()
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
        remove_from_chain(reaper.GetSelectedTrack(0, i), {})
    end
end)
