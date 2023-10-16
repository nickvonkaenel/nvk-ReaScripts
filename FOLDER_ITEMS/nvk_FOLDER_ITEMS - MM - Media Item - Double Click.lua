--@noindex
--USER CONFIG--
--SETUP--
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
--SCRIPT--
function Main()
	if reaper.CountSelectedMediaItems(0) > 0 then
		local item = reaper.GetSelectedMediaItem(0, 0)
		local track = reaper.GetMediaItem_Track(item)
		local take = reaper.GetActiveTake(item)
        if take then
            local src = reaper.GetMediaItemTake_Source(take)
            local typebuf = reaper.GetMediaSourceType(src, "")
            if typebuf == "MIDI" or typebuf == "MIDIPOOL" then
                reaper.Main_OnCommand(40153, 0) --open in midi editor
            elseif typebuf == "RPP_PROJECT" then
                itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                reaper.Main_OnCommand(41816, 0) --open project in new tab
                startPos, endPos = GetSubprojectStartAndEnd()
                if startPos and endPos then
                    loopStart = startPos + offset
                    loopEnd = loopStart + itemLen
                    curPos = reaper.GetCursorPosition()
                    reaper.MoveEditCursor(loopStart - curPos, false) --have to add this since edit cursor is bugged
                end
            elseif reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 and typebuf == "EMPTY" then
                ToggleVisibility(track)
                reaper.SelectAllMediaItems(0, false)
                reaper.SetMediaItemSelected(item, true)
                groupSelect(item)
                reaper.Main_OnCommand(40034, 0) --select all items in group
            elseif doubleClickCreateRegions and typebuf == "WAVE" then
                SelectTakeRegion(take, src)
            else
                reaper.Main_OnCommand(40009, 0) --show media item/take properties
            end
        else
            reaper.Main_OnCommand(40850, 0) --show notes for items
        end
	end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
