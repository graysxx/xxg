return {order = 50, build = function(ctx, tab)
	local UI, E = ctx.UI, ctx.emotes
	local section = tab:addSection("Play by ID")

	local function playFromText(text)
		local id = tonumber((tostring(text):gsub("%D", "")))
		if not id then
			UI:notify("Invalid emote ID", "error")
			return
		end
		E.play(id, nil)
	end

	local box = section:addTextBox("Emote ID", "Enter Emote ID", function(text, enter)
		if enter then playFromText(text) end
	end)
	section:addButton("Play Emote ID", function() playFromText(box:Get()) end)
end}