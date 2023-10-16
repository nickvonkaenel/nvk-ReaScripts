-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
item_table = {}
for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  track = reaper.GetMediaItemTrack(item)
  track_depth = reaper.GetTrackDepth(track)
  parent = reaper.GetParentTrack(track)
  while parent do
    track_depth = reaper.GetTrackDepth(parent)
    compact = reaper.GetMediaTrackInfo_Value(parent, "I_FOLDERCOMPACT")
    parent = reaper.GetParentTrack(parent)
    if compact == 2 then
      table.insert(item_table, item)
      parent = nil
    end
  end
end

for j = 1, #item_table do
  item = item_table[j]
  reaper.SetMediaItemSelected(item, false)
end

reaper.UpdateArrange()
end

scrName = ({ reaper.get_action_context() })[2]:match".+[/\\](.+)"
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
