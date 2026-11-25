local function line(parent, x1, y1, x2, y2, thick, color)
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	return create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, (x1 + x2) / 2, 0, (y1 + y2) / 2),
		Size = UDim2.new(0, len + thick * 0.4, 0, thick),
		Rotation = math.deg(math.atan2(dy, dx)),
		BackgroundColor3 = color, BorderSizePixel = 0, Parent = parent,
	}, {corner(thick / 2)})
end

local function makeIcon(name, parent, color, px)
	local k = px / 16
	local th = math.max(1.4, 1.6 * k)
	local f = create("Frame", {
		Name = "Icon_" .. name, Size = UDim2.new(0, px, 0, px), BackgroundTransparency = 1, Parent = parent,
	})
	local function L(x1, y1, x2, y2) return line(f, x1 * k, y1 * k, x2 * k, y2 * k, th, color) end
	local function ring(cx, cy, r, filled)
		local d = 2 * r * k
		local c = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, cx * k, 0, cy * k), Size = UDim2.new(0, d, 0, d),
			BackgroundColor3 = color, BackgroundTransparency = filled and 0 or 1, BorderSizePixel = 0, Parent = f,
		}, {corner(d / 2)})
		if not filled then
			create("UIStroke", {Color = color, Thickness = th, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = c})
		end
		return c
	end
	local function shoulders(cx, top, w) 
		local clip = create("Frame", {
			Position = UDim2.new(0, (cx - w / 2) * k - th, 0, top * k - th),
			Size = UDim2.new(0, w * k + 2 * th, 0, (w / 2) * k + th),
			BackgroundTransparency = 1, ClipsDescendants = true, Parent = f,
		})
		create("Frame", {
			Position = UDim2.new(0, th, 0, th), Size = UDim2.new(0, w * k, 0, w * k), BackgroundTransparency = 1, Parent = clip,
		}, {corner(w * k / 2), create("UIStroke", {Color = color, Thickness = th, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})})
	end

	if name == "signal" then
		for i, h in ipairs({4, 7, 10, 13}) do
			create("Frame", {
				Position = UDim2.new(0, (1.5 + (i - 1) * 3.7) * k, 0, (14 - h) * k), Size = UDim2.new(0, 2.4 * k, 0, h * k),
				BackgroundColor3 = color, BorderSizePixel = 0, Parent = f,
			}, {corner(1)})
		end
	elseif name == "chart" then
		L(2, 2, 2, 14); L(2, 14, 14, 14)
		L(4.5, 10.5, 7.5, 6.5); L(7.5, 6.5, 10, 9); L(10, 9, 13.5, 4)
	elseif name == "user" then
		ring(8, 5, 2.8); shoulders(8, 9.5, 10)
	elseif name == "users" then
		ring(11.6, 5.2, 1.9); shoulders(11.6, 9.4, 5.4)
		ring(5.8, 5, 2.4); shoulders(5.8, 9.3, 8.4)
	elseif name == "news" then
		create("Frame", {
			Position = UDim2.new(0, 2 * k, 0, 2 * k), Size = UDim2.new(0, 12 * k, 0, 12 * k), BackgroundTransparency = 1, Parent = f,
		}, {corner(2.5 * k), create("UIStroke", {Color = color, Thickness = th, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})})
		L(5, 5.5, 11, 5.5); L(5, 8, 11, 8); L(5, 10.5, 8.5, 10.5)
	elseif name == "info" then
		ring(8, 8, 6.2); ring(8, 5, 0.9, true); L(8, 7.4, 8, 11.2)
	elseif name == "clock" then
		ring(8, 8, 6.2); L(8, 8, 8, 4.6); L(8, 8, 10.6, 9.4)
	elseif name == "check" then
		L(3.5, 8.5, 6.8, 11.8); L(6.8, 11.8, 12.6, 4.6)
	elseif name == "cross" then
		L(4, 4, 12, 12); L(12, 4, 4, 12)
	end
	return f
L.makeIcon = makeIcon
end