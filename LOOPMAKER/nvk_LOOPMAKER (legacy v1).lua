-- @noindex

-- USER CONFIG -- (some of these are overridden by your last used settings when you use the script)
doPrompt = true --set to false if don't want settings prompt and just want script to run with defaults
loopCount = 1 --default loop count
loopSpace = 0 --default space between loops
glue = 0 --default glue setting
minFadeLen = 0.01 --won't run if can't make fades larger than this
maxFadeLen = 12 --maxiumum fade length
ratioFadeLen = 2 --default ratio of fade length to item length. Higher value produce longer fade times. Must be between 1-5
matchOverlappingItems = true --if all items are overlapping with the first item match lengths and positions
UNDERSCORE = '_' --can change to space if don't want underscore
appendString = 'Loop' --if want to add string such as '_Loop' to rendered items
appendNumbers = 1 -- if want to append numbers (or keep numbers)
lengthFloor = false --trim lengths to nearest second
disableMouseClickRemoveLoop = false --if set to true, will temporarily change your settings while the script is running to allow for mouse clicks to select items.
shepSlope = 0 -- shepard tone slope
keepName = false -- don't change name at all (overrides other settings)
-- SCRIPT --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
dofile(DATA_PATH .. 'loopmaker.dat')
if not functionsLoaded then return end
