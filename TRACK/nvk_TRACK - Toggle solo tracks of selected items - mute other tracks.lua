-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function SoloRcv(track)
  tracks[track] = true
  --reaper.CSurf_OnSoloChangeEx(track, 1, false)
  if reaper.GetSetMediaTrackInfo_String(track, "P_EXT:nvk_TRACK_AUTOMUTE", "", false) then
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0)
    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:nvk_TRACK_AUTOMUTE", "", true)
  end
  local num_rcvs = reaper.GetTrackNumSends(track,-1)
  for i = 0, num_rcvs - 1 do
    local tr = reaper.GetTrackSendInfo_Value(track, -1, i, "P_SRCTRACK")
    if not tracks[tr] then SoloRcv(tr) end
  end
  local num_snds = reaper.GetTrackNumSends(track,0)
  for i = 0, num_snds - 1 do
    local tr = reaper.GetTrackSendInfo_Value(track, 0, i, "P_DESTTRACK")
    if not tracks[tr] then SoloRcv(tr) end
  end
  local trackCount = reaper.GetNumTracks()
  local parentTrackDepth = reaper.GetTrackDepth(track)
  local trackidx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
  local tr = reaper.GetTrack(0, trackidx)
  if not tr then return end
  local depth = reaper.GetTrackDepth(tr)
  while depth > parentTrackDepth do
    if not tracks[tr] then SoloRcv(tr) end
    trackidx = trackidx + 1
    if trackidx == trackCount then
      break
    end
    tr = reaper.GetTrack(0, trackidx)
    depth = reaper.GetTrackDepth(tr)
  end
  tr = reaper.GetParentTrack(track)
  if tr and not tracks[tr] then SoloRcv(tr) end
end

function SoloTracks()
  
  local focus = reaper.GetCursorContext()
  local itemCount = reaper.CountSelectedMediaItems(0)
  local selTrackCount = reaper.CountSelectedTracks(0)
  for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    if reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 0 and reaper.GetMediaTrackInfo_Value(track, "B_SOLO_DEFEAT") == 0 then
      reaper.GetSetMediaTrackInfo_String(track, "P_EXT:nvk_TRACK_AUTOMUTE", "1", true)
      reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1)
    else
      --reaper.GetSetMediaTrackInfo_String(track, "P_EXT:nvk_TRACK_AUTOMUTE", "", true)
    end
  end
  if (focus == 0 or itemCount == 0) and selTrackCount > 0 then
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
      local track = reaper.GetSelectedTrack(0, i)
      reaper.CSurf_OnSoloChangeEx(track, 1, false)
      SoloRcv(track)
    end
  elseif itemCount > 0 then
    for i = 0, itemCount - 1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      local track = reaper.GetMediaItem_Track(item)
      reaper.CSurf_OnSoloChangeEx(track, 1, false)
      SoloRcv(track)
    end
  else
    UnsoloTracks()
  end
end

function UnsoloTracks()
  reaper.SoloAllTracks(0)
  for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    if reaper.GetSetMediaTrackInfo_String(track, "P_EXT:nvk_TRACK_AUTOMUTE", "", false) then
      reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0)
      reaper.GetSetMediaTrackInfo_String(track, "P_EXT:nvk_TRACK_AUTOMUTE", "", true)
    end
  end
end

function Main()
  tracks = {}
  if reaper.AnyTrackSolo(0) then
    UnsoloTracks()
  else
    SoloTracks()
  end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
