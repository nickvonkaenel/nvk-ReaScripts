-- SOURCE --
local r = reaper

---Sets or clears the Folder Items per-track override on every selected track. The override is
---stored in the track's P_EXT state so both the Lua and native (NVK) engines read the same flag.
---@param value integer 1 forces folder items on, -1 forces them off, 0 clears the override (auto)
---@param label string undo description, shown in the undo history
local function set_track_override(value, label)
    local trackCount = r.CountSelectedTracks(0)
    if trackCount == 0 then
        return
    end
    r.Undo_BeginBlock()
    for i = 0, trackCount - 1 do
        local track = r.GetSelectedTrack(0, i)
        r.GetSetMediaTrackInfo_String(
            track,
            'P_EXT:nvk_folder_items_override',
            value == 0 and '' or tostring(value),
            true
        )
    end
    -- The undo point bumps the project state count, which makes the running Folder Items
    -- engine (Lua defer loop or native timer) re-run its fix pass and apply the override.
    r.Undo_EndBlock(label, 1) -- 1 = UNDO_STATE_TRACKCFG; P_EXT lives in the track chunk
end

return set_track_override
