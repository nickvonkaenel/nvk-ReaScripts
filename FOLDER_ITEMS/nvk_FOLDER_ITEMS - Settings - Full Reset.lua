-- @noindex
-- This will remove all settings stored including mouse modifiers for nvk_FOLDER_ITEMS in case anything gets messed up. Won't affect license registration.
-- USER CONFIG --
-- SETUP --
if reaper.ShowMessageBox("Reset all settings for nvk_FOLDER_ITEMS?", "", 1) == 1 then
    if reaper.HasExtState("nvk_FOLDER_ITEMS", "settingsSimple") then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS", "settingsSimple", true)
    end
    if reaper.HasExtState("nvk_FOLDER_ITEMS_RENDER", "settingsSimple") then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settingsSimple", true)
    end
    if reaper.HasExtState("nvk_FOLDER_ITEMS", "settings") then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settings", true)
    end
    if reaper.HasExtState("nvk_FOLDER_ITEMS_RENDER", "settings") then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settings", true)
    end
    if reaper.HasExtState("nvk_FOLDER_ITEMS - Rename", "settings") then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS - Rename", "settings", true)
    end
    if reaper.HasExtState("nvk_FOLDER_ITEMS - Rename", "window") then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS - Rename", "window", true)
    end
end


if reaper.ShowMessageBox("Reset all double click mouse modifiers for track?", "", 1) == 1 then
    if reaper.HasExtState("nvk_FOLDER_ITEMS - Add new items to existing folder", "mm", true) then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS - Add new items to existing folder", "mm", true)
    end
    if reaper.HasExtState("nvk_FOLDER_ITEMS - Add new items to existing folder - Rename", "mm", true) then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS - Add new items to existing folder - Rename", "mm", true)
    end
    reaper.SetMouseModifier("MM_CTX_TRACK_CLK", 2, -1)
    reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 0, -1)
    reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 1, -1)
    reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 2, -1)
    reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 3, -1)
end
