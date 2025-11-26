-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --

local function CloseTrackFX(track)
    local fx = reaper.TrackFX_GetCount(track)
    for i = 0, fx - 1 do
        if reaper.TrackFX_GetOpen(track, i) then reaper.TrackFX_SetOpen(track, i, 0) end
        if reaper.TrackFX_GetChainVisible(track) ~= -1 then reaper.TrackFX_Show(track, 0, 0) end
    end

    local rec_fx = reaper.TrackFX_GetRecCount(track)
    for i = 0, rec_fx - 1 do
        local i_rec = i + 16777216
        if reaper.TrackFX_GetOpen(track, i_rec) then reaper.TrackFX_SetOpen(track, i_rec, 0) end
        if reaper.TrackFX_GetRecChainVisible(track) ~= -1 then reaper.TrackFX_Show(track, i_rec, 0) end
    end
end

local function CloseTakeFX(take)
    if not take then return end
    local fx = reaper.TakeFX_GetCount(take)
    for i = 0, fx - 1 do
        if reaper.TakeFX_GetOpen(take, i) then reaper.TakeFX_SetOpen(take, i, 0) end
        if reaper.TakeFX_GetChainVisible(take) ~= -1 then reaper.TakeFX_Show(take, 0, 0) end
    end
end

run(function()
    for i = 0, reaper.CountTracks() - 1 do
        local track = reaper.GetTrack(0, i)
        CloseTrackFX(track)
        for j = 0, reaper.CountTrackMediaItems(track) - 1 do
            local item = reaper.GetTrackMediaItem(track, j)
            local takes = reaper.GetMediaItemNumTakes(item)
            for k = 0, takes - 1 do
                CloseTakeFX(reaper.GetTake(item, k))
            end
        end
    end
end)
