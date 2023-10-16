-- @noindex
-- If you have no items selected, toggles the width envelope of selected tracks. With items selected will add/remove the effect you set below to the active take. To get the parameter name then 
-- USER CONFIG --
fxName = "Ozone Imager 2"
paramName = "Width"
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    itemCount = reaper.CountSelectedMediaItems(0)
    tracks = SaveSelectedTracks()
    if itemCount > 0 then
        for i = 0, itemCount - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            local take = reaper.GetActiveTake(item)
                if take then
                local fxadded, fx = AddTakeFxByName(take, fxName)
                if not fx then return end
                if fxadded then
                    widthEnv = GetTakeFXParamByName(take, fx, paramName, true)
                else
                    reaper.TakeFX_Delete(take, fx)
                end
            end
        end
    else
        for i, track in ipairs(tracks) do
            reaper.Main_OnCommand(40297, 0) --unselect all tracks
            reaper.SetOnlyTrackSelected(track)
            br_env = reaper.GetTrackEnvelopeByName(track, "Width")
            if br_env ~= nil then
                local width_env = reaper.BR_EnvAlloc(br_env, false)
                local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type,
                    faderScaling = reaper.BR_EnvGetProperties(width_env, true, true, true, true, 0, 0, 0, 0, 0, 0, true)
                if visible == true then
                    reaper.Main_OnCommand(41870, 0) --select width envelope
                    reaper.UpdateArrange()
                    reaper.PreventUIRefresh(-1)
                    reaper.Main_OnCommand(40065, 0) --clear envelope
                    reaper.PreventUIRefresh(1)
                    -- visible = false
                else
                    reaper.Main_OnCommand(41870, 0) --select width envelope
                    -- if visible == false then
                    --     visible = true
                    -- end
                end
                -- reaper.BR_EnvSetProperties(width_env, active, visible, armed, inLane, laneHeight, defaultShape,
                --     faderScaling)
                -- reaper.BR_EnvFree(width_env, 1)
            else
                reaper.Main_OnCommand(41870, 0) --select width envelope
            end
        end
    end
    RestoreSelectedTracks(tracks)
end

scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
