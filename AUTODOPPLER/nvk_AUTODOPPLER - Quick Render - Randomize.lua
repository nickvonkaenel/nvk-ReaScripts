--@noindex

QuickRenderRandom = true
scrPath, scrName = ({ reaper.get_action_context() })[2]:match '(.-)([^/\\]+).lua$'
dofile(scrPath .. 'nvk_AUTODOPPLER - Quick Render.lua')
