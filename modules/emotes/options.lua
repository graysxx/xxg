return {order = 10, build = function(ctx, tab)
	local E = ctx.emotes
	local section = tab:addSection("Emote Options")
	section:addToggle("Keep Emote While Moving", false, function(v) E.opts.keepMoving = v end)
	section:addToggle("Loop Emote", false, function(v)
		E.opts.loopEmote = v
		E.setLoop(v)
	end)
	section:addSlider("Emote Speed", 100, 0, 5000, function(v) E.setSpeed(v / 100) end, "%")
	section:addButton("Stop Emote", E.stop)
end}