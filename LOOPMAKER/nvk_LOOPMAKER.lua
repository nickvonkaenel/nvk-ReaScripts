-- @description nvk_LOOPMAKER
-- @author nvk
-- @version 1.2.6
-- @changelog
--   1.2.6 Fixed: auto-crossfade on split setting caused loops to have fades when they shouldn't
--   1.2.3 Minor bug fixes
--   1.2.2 Fix issue where length floor setting wouldn't work if rendering multiple loops per item
--   1.2.1 Compatibility with new Render Smart script
--   1.2 New experimental feature: Shepard Tone
--      -If shepard tone is set to value other than 0, a special loop will be created which sounds as though the loop is constantly pitching up or down depending on the setting. All other settings are ignored while using this option, and only one loop is created per selected item.
--      -Fix issues if ripple editing is enabled
--      -Licensing improvements - trial
--   1.1.7 Fixed bug if "Trim content behind media items when editing" is enabled when making multiple loops (requires SWS Extension)
--   1.1.6 More licensing improvements
--   1.1.5 Licensing improvements
--   1.1.4 Experimental option in script flags to not remove loop points with mouse click while script is running. Fixing bug when no zero crossings are found in item.
--   1.1.3 Minor fixes
--   1.1.2 Fixing bugs with multiple loops and time selection
--   1.1.1 Time selection now works with multiple loops per item
--   1.1 New feature: if you make a time selection and only have one item per track selected (and are only making one loop per item), nvk_LOOPMAKER will automatically fit your loops to the time selection, extending and duplicating if necessary.
-- @link
--   Store Page https://gum.co/nvk_LOOPMAKER
-- @screenshot https://reapleton.com/images/nvk_loopmaker.gif
-- @about
--   # nvk_LOOPMAKER
--
--   nvk_LOOPMAKER Creates perfect loops out of selected items using zero-crossing. If Loop Count is set to a number higher than 1, it will create multiple loops out of a single item that can be played back to back with sample accurate transitions.
--
--   Click the "Website" button for more info
-- @provides
--   **/*.dat

-- USER CONFIG -- (some of these are overridden by your last used settings when you use the script)
doPrompt = true --set to false if don't want settings prompt and just want script to run with defaults
loopCount = 1 --default loop count
loopSpace = 0 --default space between loops
glue = 0 --default glue setting
minFadeLen = 0.01 --won't run if can't make fades larger than this
maxFadeLen = 12 --maxiumum fade length
ratioFadeLen = 2 --default ratio of fade length to item length. Higher value produce longer fade times. Must be between 1-5
matchOverlappingItems = true --if all items are overlapping with the first item match lengths and positions
underscore = "_" --can change to space if don't want underscore
appendString = "Loop" --if want to add string such as '_Loop' to rendered items
appendNumbers = 1 -- if want to append numbers (or keep numbers)
lengthFloor = false --trim lengths to nearest second
disableMouseClickRemoveLoop = false --if set to true, will temporarily change your settings while the script is running to allow for mouse clicks to select items.
shepSlope = 0 -- shepard tone slope
keepName = false -- don't change name at all (overrides other settings)
-- SCRIPT --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'loopmaker.dat')
if not functionsLoaded then return end
