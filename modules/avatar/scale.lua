return {order = 20, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local defs = {
		{"Height", "BodyHeightScale", 100, 50, 200},
		{"Width", "BodyWidthScale", 100, 50, 200},
		{"Depth", "BodyDepthScale", 100, 50, 200},
		{"Head Size", "HeadScale", 100, 50, 200},
		{"Proportion", "BodyProportionScale", 0, 0, 100},
		{"Body Type", "BodyTypeScale", 0, 0, 100},
	}

	local section = tab:addSection("Body Scale")
	local sliders = {}
	for _, d in ipairs(defs) do
		local title, valueName, default, min, max = d[1], d[2], d[3], d[4], d[5]
		sliders[#sliders + 1] = {slider = section:addSlider(title, default, min, max, function(v)
			local h = A.humanoid()
			local nv = h and h:FindFirstChild(valueName)
			if nv then
				nv.Value = v / 100
			else
				UI:notify("Body scale needs an R15 avatar", "error")
			end
		end, "%"), default = default}
	end

	section:addButton("Reset Scale", function()
		for _, s in ipairs(sliders) do s.slider:Set(s.default) end
		UI:notify("Body scale reset", "success")
	end)
end}