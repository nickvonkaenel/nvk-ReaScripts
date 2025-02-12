-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local tracks = {}

local function SoloRcv(track)
    tracks[track] = true
    if r.GetSetMediaTrackInfo_String(track, 'P_EXT:nvk_TRACK_AUTOMUTE', '', false) then
        r.SetMediaTrackInfo_Value(track, 'B_MUTE', 0)
        r.GetSetMediaTrackInfo_String(track, 'P_EXT:nvk_TRACK_AUTOMUTE', '', true)
    end
    local num_rcvs = r.GetTrackNumSends(track, -1)
    for i = 0, num_rcvs - 1 do
        local tr = r.GetTrackSendInfo_Value(track, -1, i, 'P_SRCTRACK')
        if not tracks[tr] then SoloRcv(tr) end
    end
    local num_snds = r.GetTrackNumSends(track, 0)
    for i = 0, num_snds - 1 do
        local tr = r.GetTrackSendInfo_Value(track, 0, i, 'P_DESTTRACK')
        if not tracks[tr] then SoloRcv(tr) end
    end
    local trackCount = r.GetNumTracks()
    local parentTrackDepth = r.GetTrackDepth(track)
    local trackidx = r.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
    local tr = r.GetTrack(0, trackidx)
    if not tr then return end
    local depth = r.GetTrackDepth(tr)
    while depth > parentTrackDepth do
        if not tracks[tr] then SoloRcv(tr) end
        trackidx = trackidx + 1
        if trackidx == trackCount then break end
        tr = r.GetTrack(0, trackidx)
        depth = r.GetTrackDepth(tr)
    end
    tr = r.GetParentTrack(track)
    if tr and not tracks[tr] then SoloRcv(tr) end
end

local function UnsoloTracks()
    r.SoloAllTracks(0)
    for i = 0, r.CountTracks(0) - 1 do
        local track = r.GetTrack(0, i)
        if r.GetSetMediaTrackInfo_String(track, 'P_EXT:nvk_TRACK_AUTOMUTE', '', false) then
            r.SetMediaTrackInfo_Value(track, 'B_MUTE', 0)
            r.GetSetMediaTrackInfo_String(track, 'P_EXT:nvk_TRACK_AUTOMUTE', '', true)
        end
    end
end

local function SoloTracks()
    local focus = r.GetCursorContext()
    local itemCount = r.CountSelectedMediaItems(0)
    local selTrackCount = r.CountSelectedTracks(0)
    for i = 0, r.CountTracks(0) - 1 do
        local track = r.GetTrack(0, i)
        if
            r.GetMediaTrackInfo_Value(track, 'B_MUTE') == 0
            and r.GetMediaTrackInfo_Value(track, 'B_SOLO_DEFEAT') == 0
        then
            r.GetSetMediaTrackInfo_String(track, 'P_EXT:nvk_TRACK_AUTOMUTE', '1', true)
            r.SetMediaTrackInfo_Value(track, 'B_MUTE', 1)
        else
            --r.GetSetMediaTrackInfo_String(track, "P_EXT:nvk_TRACK_AUTOMUTE", "", true)
        end
    end
    if (focus == 0 or itemCount == 0) and selTrackCount > 0 then
        for i = 0, r.CountSelectedTracks(0) - 1 do
            local track = r.GetSelectedTrack(0, i)
            r.CSurf_OnSoloChangeEx(track, 1, false)
            SoloRcv(track)
        end
    elseif itemCount > 0 then
        for i = 0, itemCount - 1 do
            local item = r.GetSelectedMediaItem(0, i)
            local track = r.GetMediaItem_Track(item)
            r.CSurf_OnSoloChangeEx(track, 1, false)
            SoloRcv(track)
        end
    else
        UnsoloTracks()
    end
end

run(function()
    if r.AnyTrackSolo(0) then
        UnsoloTracks()
    else
        SoloTracks()
    end
end)
