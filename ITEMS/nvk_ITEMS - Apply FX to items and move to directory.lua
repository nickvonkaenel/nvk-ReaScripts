-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
  local directoryPath = reaper.GetExtState(scrName, "path")
  local items = SaveSelectedItems()
  if directoryPath and directoryPath~= "" and #items > 0 then
    for i, item in ipairs(items) do
      reaper.SelectAllMediaItems(0, false) --unselect all items
      reaper.SetMediaItemSelected(item, true)
      local initTake = reaper.GetActiveTake(item)
      reaper.Main_OnCommand(40209, 0) --Item: Apply track/take FX to items
      local take = reaper.GetActiveTake(item) --get new take
      if take ~= initTake then --check if render finished successfully
        path, name = GetSourcePathName(take)
        reaper.Main_OnCommand(40129, 0) --delete active take from items
        reaper.SetActiveTake(initTake) --restore initial take
        if path then
          retval, newPath = CopyFile(path..sep..name, directoryPath..sep..name)
          if retval and newPath then
            --reaper.ShowConsoleMsg(newPath) --Success: new path here is the new file name
          end
        end
      end
    end
  else
    local retval, folder
    if reaper.APIExists("JS_Dialog_BrowseForFolder") then
      retval, folder = reaper.JS_Dialog_BrowseForFolder("Path to save items", directoryPath )
    else
      retval, folder = reaper.GetUserInputs("Path to save items", 1, "Paste path here:,extrawidth=500", directoryPath)
      if folder:sub(-1,-1) == "\\" or folder:sub(-1,-1) == "/" then
        folder = folder:sub(1,-2)
      end
    end
    if retval then
      reaper.SetExtState(scrName, "path", folder, true)
    end
  end
end
      
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
