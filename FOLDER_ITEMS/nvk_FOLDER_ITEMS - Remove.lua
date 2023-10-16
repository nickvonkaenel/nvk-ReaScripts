-- @noindex
-- USER CONFIG --
selectItemUnderMouse = true --this script doesn't really do much without this set to true, just deletes items or tracks
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    if selectItemUnderMouse then
        reaper.Main_OnCommand(40296, 0) -- select all tracks
        reaper.Main_OnCommand(40769, 0) -- unselect everything (have to select all tracks first else some envelope tracks can be selected)
        item = GetItemUnderMouseCursor()
    else
        if reaper.GetCursorContext() == 0 then
            reaper.Main_OnCommand(40005, 0) -- remove track
        else
            reaper.Main_OnCommand(40006, 0) -- remove items
        end
        return
    end

    if item then
        reaper.SetMediaItemSelected(item, true)
        groupSelect(item)
        local env = reaper.GetTrackEnvelopeByName(reaper.GetMediaItemTrack(item), "Volume")
        if env then
            local autoitemIdx = GetAutoitem(env, reaper.GetMediaItemInfo_Value(item, "D_POSITION"))
            if autoitemIdx then
                reaper.GetSetAutomationItemInfo(env, autoitemIdx, "D_UISEL", 1, true)
            end
        end
        reaper.Main_OnCommand(40006, 0) -- remove items
        return
    end

    if SelectAutomationItemUnderMouseCursor() then
        reaper.Main_OnCommand(40006, 0) -- remove items
        return
    end
    window, segment, details = reaper.BR_GetMouseCursorContext()
    if window == "tcp" or window == "unknown" then
        if segment == "track" then
            reaper.Main_OnCommand(41110, 0) -- select track under mouse
            reaper.Main_OnCommand(40005, 0) -- remove track
        elseif segment == "envelope" then
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SEL_ENV_MOUSE"), 0) -- select envelope track under mouse cursor
            if reaper.GetSelectedEnvelope(0) then
                reaper.Main_OnCommand(40065, 0) -- clear envelope
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVEALLSELITEMS1"), 0)
Main()
reaper.Main_OnCommand(41110, 0) -- select track under mouse
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTALLSELITEMS1"), 0)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
