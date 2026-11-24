local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

-- THEME
local Theme = {
	Background = Color3.fromRGB(11, 11, 14),
	Panel      = Color3.fromRGB(23, 24, 28),
	PanelHover = Color3.fromRGB(28, 29, 35),
	Card       = Color3.fromRGB(31, 32, 37),
	Border     = Color3.fromRGB(44, 45, 52),
	TrackOff   = Color3.fromRGB(62, 63, 72),
	Text       = Color3.fromRGB(245, 245, 247),
	SubText    = Color3.fromRGB(200, 200, 206),
	Muted      = Color3.fromRGB(139, 141, 152),
	Accent     = Color3.fromRGB(255, 255, 255),
	AccentSoft = Color3.fromRGB(46, 47, 54),
	AccentLine = Color3.fromRGB(110, 112, 124),
	Green      = Color3.fromRGB(74, 222, 128),
	GreenSoft  = Color3.fromRGB(24, 58, 42),
	Orange     = Color3.fromRGB(245, 158, 11),
	Blue       = Color3.fromRGB(96, 165, 250),
	Red        = Color3.fromRGB(239, 68, 68),
}

local ThemePresets = {
	White   = {Accent = Color3.fromRGB(255, 255, 255), AccentSoft = Color3.fromRGB(46, 47, 54),  AccentLine = Color3.fromRGB(110, 112, 124)},
	Violet  = {Accent = Color3.fromRGB(167, 139, 250), AccentSoft = Color3.fromRGB(44, 38, 82),  AccentLine = Color3.fromRGB(88, 74, 160)},
	Ocean   = {Accent = Color3.fromRGB(56, 189, 248),  AccentSoft = Color3.fromRGB(20, 48, 74),  AccentLine = Color3.fromRGB(40, 110, 160)},
	Emerald = {Accent = Color3.fromRGB(52, 211, 153),  AccentSoft = Color3.fromRGB(18, 60, 48),  AccentLine = Color3.fromRGB(30, 125, 95)},
	Rose    = {Accent = Color3.fromRGB(251, 113, 133), AccentSoft = Color3.fromRGB(76, 28, 42),  AccentLine = Color3.fromRGB(165, 60, 82)},
	Amber   = {Accent = Color3.fromRGB(251, 191, 36),  AccentSoft = Color3.fromRGB(72, 54, 14),  AccentLine = Color3.fromRGB(150, 112, 20)},
}
local ThemeOrder = {"White", "Violet", "Ocean", "Emerald", "Rose", "Amber"}
local THEME_KEYS = {"Background", "Panel", "PanelHover", "Card", "Border", "TrackOff", "Accent", "AccentSoft", "AccentLine"}

-- HELPERS
local function create(className, props, children)
	local obj = Instance.new(className)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			obj[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

local function tween(obj, props, duration)
	TweenService:Create(obj, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function apply(obj, props, animate)
	if animate then
		tween(obj, props)
	else
		for k, v in pairs(props) do
			obj[k] = v
		end
	end
end

local function corner(radius)
	return create("UICorner", {CornerRadius = UDim.new(0, radius)})
end

local function stroke(color, transparency)
	return create("UIStroke", {
		Color = color or Theme.Border,
		Thickness = 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(l, t, r, b)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
	})
end

local function listLayout(pad, direction)
	return create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, pad or 0),
		FillDirection = direction or Enum.FillDirection.Vertical,
	})
end

local function newLabel(props)
	local p = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextColor3 = Theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}
	for k, v in pairs(props) do
		p[k] = v
	end
	return create("TextLabel", p)
end

local Surfaces, SurfaceAlpha, themeHooks = {}, 0, {}

local function surface(obj, factor)
	factor = factor or 1
	table.insert(Surfaces, {obj = obj, f = factor})
	obj.BackgroundTransparency = SurfaceAlpha * factor
	return obj
end

local function colorKey(c)
	return math.floor(c.R * 255 + 0.5) * 65536 + math.floor(c.G * 255 + 0.5) * 256 + math.floor(c.B * 255 + 0.5)
end

local function accentGradient()
	local a = Theme.Accent
	if 0.299 * a.R + 0.587 * a.G + 0.114 * a.B > 0.8 then
		return ColorSequence.new(a:Lerp(Color3.new(0, 0, 0), 0.62), a:Lerp(Color3.new(0, 0, 0), 0.38))
	end
	return ColorSequence.new(a:Lerp(Color3.new(0, 0, 0), 0.25), a:Lerp(Color3.new(1, 1, 1), 0.12))
end

local function accentOutline()
	return Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.35)
end

-- background panel (ZIndex 0)
local function panelBg(parent)
	return surface(create("Frame", {
		Name = "Bg", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0, ZIndex = 0, Parent = parent,
	}, {corner(12), stroke()}), 1)
end

-- icon outline 
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
end

local function popCard(parent, name)
	local slot = create("Frame", {
		Name = name or "Card", Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = parent,
	})
	local pop = create("Frame", {
		Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = slot,
	})
	create("UIScale", {Scale = 1, Parent = pop})
	local bg = panelBg(pop)
	return slot, pop, bg
end

local AUTO_Y = Enum.AutomaticSize.Y
local HOVER_SCALE = 1.03 

-- CLASSES
local library = {}
local page = {}
local section = {}
library.__index = library
page.__index = page
section.__index = section
library.Theme = Theme
library.ThemePresets = ThemePresets
library.ThemeOrder = ThemeOrder

function library:connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self._conns, c)
	return c
end

local function makeDraggable(lib, handle, target)
	local dragging, dragStart, startPos
	lib:connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	lib:connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			if lib.state == "minimized" then
				lib.normalPos = target.Position
			end
		end
	end)
end

local function windowButton(parent, x, hoverColor)
	local b = create("TextButton", {
		Position = UDim2.new(0, x, 0, 0), Size = UDim2.new(0, 24, 0, 24),
		BackgroundColor3 = hoverColor, BackgroundTransparency = 1, BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Parent = parent,
	}, {corner(7)})
	b.MouseEnter:Connect(function() tween(b, {BackgroundTransparency = 0}, 0.12) end)
	b.MouseLeave:Connect(function() tween(b, {BackgroundTransparency = 1}, 0.12) end)
	return b
end

-- WINDOW
local MIN_W, MIN_H = 320, 260
local MINI_BAR_H = 48
local MINIMIZED_H = MINI_BAR_H + 20 
local CHIP_PAD, CHIP_ICON, CHIP_GAP = 8, 14, 6 

function library.new(title, subtitle, version)
	local guiName = "ProjectControlPanel"
	Surfaces, SurfaceAlpha, themeHooks = {}, 0, {}

	pcall(function()
		local old = game:GetService("CoreGui"):FindFirstChild(guiName)
		if old then old:Destroy() end
	end)
	pcall(function()
		local old = LocalPlayer.PlayerGui:FindFirstChild(guiName)
		if old then old:Destroy() end
	end)

	local screen = create("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local okParent = pcall(function() screen.Parent = game:GetService("CoreGui") end)
	if not okParent then
		screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local W, H = math.min(440, vp.X - 20), math.min(580, vp.Y - 20)

	-- Root
	local root = create("Frame", {
		Name = "Root",
		Position = UDim2.fromOffset(math.floor((vp.X - W) / 2), math.floor((vp.Y - H) / 2)),
		Size = UDim2.fromOffset(W, H),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	local main = create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = root,
	}, {corner(14), stroke(), padding(10, 10, 10, 10)})
	local scale = create("UIScale", {Scale = 0, Parent = main})
	surface(main, 1)

	-- header card
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 108),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Parent = main,
	}, {corner(12), stroke(), padding(12, 10, 12, 10)})

	surface(header, 1)

	local icon = create("Frame", {
		Name = "Icon",
		Position = UDim2.new(0, 0, 0, 2),
		Size = UDim2.new(0, 36, 0, 36),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Parent = header,
	}, {corner(10), stroke()})
	for i = -1, 1 do
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, i * 5),
			Size = UDim2.new(0, 14, 0, 2),
			BackgroundColor3 = Theme.SubText,
			BorderSizePixel = 0,
			Parent = icon,
		}, {corner(1)})
	end

	local titleLabel = newLabel({
		Name = "Title", Text = title or "PROJECT",
		Position = UDim2.new(0, 46, 0, 2), Size = UDim2.new(1, -190, 0, 18),
		Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
	})
	local subLabel = newLabel({
		Name = "Subtitle", Text = subtitle or "Control Panel",
		Position = UDim2.new(0, 46, 0, 20), Size = UDim2.new(1, -190, 0, 16),
		TextSize = 11, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
	})

	-- badge 
	local badge = newLabel({
		Name = "Version", Text = version or "v1.0.0",
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -92, 0, 7),
		Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0, BackgroundColor3 = Theme.AccentSoft,
		TextColor3 = Theme.Accent, TextSize = 10, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Center, Parent = header,
	})
	corner(10).Parent = badge
	padding(8, 0, 8, 0).Parent = badge
	stroke(Theme.AccentLine).Parent = badge

	--minimize, maximize, close
	local controls = create("Frame", {
		Name = "Controls", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 15),
		Size = UDim2.new(0, 80, 0, 24), BackgroundTransparency = 1, ZIndex = 5, Parent = main,
	})
	local minBtn = windowButton(controls, 0, Theme.Card)
	local maxBtn = windowButton(controls, 28, Theme.Card)
	local closeBtn = windowButton(controls, 56, Theme.Red)

	create("Frame", { -- minimize
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 3), Size = UDim2.new(0, 10, 0, 2),
		BackgroundColor3 = Theme.SubText, BorderSizePixel = 0, Parent = minBtn,
	}, {corner(1)})
	create("Frame", { -- maximize
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1, BorderSizePixel = 0, Parent = maxBtn,
	}, {corner(2), create("UIStroke", {Color = Theme.SubText, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})})
	for _, rot in ipairs({45, -45}) do -- close
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 2),
			Rotation = rot, BackgroundColor3 = Theme.SubText, BorderSizePixel = 0, Parent = closeBtn,
		}, {corner(1)})
	end

	create("Frame", {
		Name = "Divider", Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = header,
	})

	local tabs = create("ScrollingFrame", {
		Name = "Tabs", Position = UDim2.new(0, 0, 0, 54), Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X, Parent = header,
	}, {
		padding(1, 0, 1, 0),
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6),
			FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})

	-- mini bar
	local mini = create("Frame", {
		Name = "Mini", Size = UDim2.new(1, 0, 0, MINI_BAR_H), BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0, Visible = false, Parent = main,
	}, {corner(12), stroke(), padding(10, 0, 10, 0)})
	surface(mini, 1)
	local miniAvatar = create("ImageLabel", {
		Position = UDim2.new(0, 0, 0.5, -16), Size = UDim2.new(0, 32, 0, 32),
		BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = mini,
	}, {corner(16), stroke()})
	local miniName = newLabel({Text = "DisplayName", Position = UDim2.new(0, 42, 0.5, -16), Size = UDim2.new(0, 104, 0, 17),
		Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = mini})
	local miniDisplay = newLabel({Text = "@Username", Position = UDim2.new(0, 42, 0.5, 1), Size = UDim2.new(0, 104, 0, 15),
		TextSize = 10, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = mini})
	local miniChips = create("Frame", {
		Name = "Chips", Position = UDim2.new(0, 156, 0, 0), Size = UDim2.new(1, -156 - 94, 1, 0),
		BackgroundTransparency = 1, Parent = mini,
	}, {create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6),
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
	})})
	local chips = {}
	local function textWidth(sample)
		local ok, size = pcall(function()
			return TextService:GetTextSize(sample, 12, Enum.Font.GothamBold, Vector2.new(1000, 20))
		end)
		return ok and math.ceil(size.X) or (#sample * 8)
	end
	-- chip = icon 
	local function addChip(key, iconName, iconColor, sample, order, visible)
		local width = CHIP_PAD * 2 + CHIP_ICON + CHIP_GAP + textWidth(sample)
		local chip = create("Frame", {
			Name = key, Size = UDim2.new(0, width, 0, 30), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
			LayoutOrder = order, Visible = visible, Parent = miniChips,
		}, {corner(8), stroke(Theme.Border, 0.4)})
		surface(chip, 0.5)
		makeIcon(iconName, chip, iconColor, CHIP_ICON).Position = UDim2.new(0, CHIP_PAD, 0.5, -CHIP_ICON / 2)
		local val = newLabel({Text = "--", Position = UDim2.new(0, CHIP_PAD + CHIP_ICON + CHIP_GAP, 0, 0),
			Size = UDim2.new(1, -(CHIP_PAD * 2 + CHIP_ICON + CHIP_GAP), 1, 0), TextSize = 12,
			Font = Enum.Font.GothamBold, Parent = chip})
		chips[key] = {frame = chip, value = val, width = width}
	end
	addChip("ping", "signal", Theme.Green, "999 ms", 1, true)
	addChip("fps", "chart", Theme.Accent, "999 FPS", 2, true)
	addChip("afk", "clock", Theme.Blue, "00:00:00", 3, false) 

	local body = create("Frame", {
		Name = "Body", Position = UDim2.new(0, 0, 0, 118), Size = UDim2.new(1, 0, 1, -118),
		BackgroundTransparency = 1, Parent = main,
	})

	local self = setmetatable({
		screen = screen, container = screen, root = root, main = main, scale = scale,
		header = header, tabs = tabs, body = body, badge = badge, titleLabel = titleLabel, subLabel = subLabel,
		controls = controls, mini = mini, miniAvatar = miniAvatar, miniName = miniName, miniDisplay = miniDisplay, chips = chips,
		pages = {}, focusedPage = nil, listening = false,
		shown = true, closing = false, state = "normal",
		normalSize = UDim2.fromOffset(W, H), normalPos = root.Position,
		_conns = {}, _hovers = {}, _handles = {}, _token = 0, _geoToken = 0,
	}, library)

	screen.Destroying:Connect(function()
		for _, c in ipairs(self._conns) do
			c:Disconnect()
		end
	end)

	-- window
	closeBtn.MouseButton1Click:Connect(function() task.spawn(function() self:Close() end) end)
	minBtn.MouseButton1Click:Connect(function() self:Minimize() end)
	maxBtn.MouseButton1Click:Connect(function() self:Maximize() end)

	-- header
	makeDraggable(self, header, root)
	makeDraggable(self, mini, root)

	-- 
	self.toasts = create("Frame", {
		Name = "Toasts", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18),
		Size = UDim2.new(0, 300, 1, -18), BackgroundTransparency = 1, ZIndex = 50, Parent = screen,
	}, {create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})})

	-- resize
	local T, C = 6, 14
	local handleDefs = {
		{Vector2.new(0, 0), UDim2.new(0, 0, 0, C),  UDim2.new(0, T, 1, -2 * C), -1,  0},
		{Vector2.new(1, 0), UDim2.new(1, 0, 0, C),  UDim2.new(0, T, 1, -2 * C),  1,  0},
		{Vector2.new(0, 0), UDim2.new(0, C, 0, 0),  UDim2.new(1, -2 * C, 0, T),  0, -1},
		{Vector2.new(0, 1), UDim2.new(0, C, 1, 0),  UDim2.new(1, -2 * C, 0, T),  0,  1},
		{Vector2.new(0, 0), UDim2.new(0, 0, 0, 0),  UDim2.new(0, C, 0, C),      -1, -1},
		{Vector2.new(1, 0), UDim2.new(1, 0, 0, 0),  UDim2.new(0, C, 0, C),       1, -1},
		{Vector2.new(0, 1), UDim2.new(0, 0, 1, 0),  UDim2.new(0, C, 0, C),      -1,  1},
		{Vector2.new(1, 1), UDim2.new(1, 0, 1, 0),  UDim2.new(0, C, 0, C),       1,  1},
	}
	for _, def in ipairs(handleDefs) do
		local dx, dy = def[4], def[5]
		local h = create("TextButton", {
			Name = "ResizeHandle", AnchorPoint = def[1], Position = def[2], Size = def[3],
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 10, Parent = root,
		})
		table.insert(self._handles, h)
		h.InputBegan:Connect(function(input)
			if self.state ~= "normal" then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local m0 = input.Position
			local s0 = root.AbsoluteSize
			local p0 = root.Position
			local x0, y0 = p0.X.Offset, p0.Y.Offset
			local screenSize = screen.AbsoluteSize
			local maxW, maxH = math.min(1100, screenSize.X), math.min(900, screenSize.Y)
			local conn
			conn = UserInputService.InputChanged:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
					local d = i.Position - m0
					local w, hgt, x, y = s0.X, s0.Y, x0, y0
					if dx ~= 0 then
						w = math.clamp(s0.X + dx * d.X, MIN_W, maxW)
						if dx < 0 then x = x0 + (s0.X - w) end
					end
					if dy ~= 0 then
						hgt = math.clamp(s0.Y + dy * d.Y, MIN_H, maxH)
						if dy < 0 then y = y0 + (s0.Y - hgt) end
					end
					root.Size = UDim2.fromOffset(w, hgt)
					root.Position = UDim2.fromOffset(x, y)
				end
			end)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					conn:Disconnect()
				end
			end)
		end)
	end

	-- hover 
	self:connect(RunService.Heartbeat, function()
		self:_updateHover()
		local p = self.focusedPage
		if p and p._dirty and self.state ~= "minimized" then
			if p:_relayout() then p._dirty = false end
		end
	end)

	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_applyResponsive() end)
	self:_applyResponsive()

	self:_animate(true)

	return self
end

-- WINDOW BEHAVIOR
local function isThemed(obj, stopAt)
	local p = obj
	while p and p ~= stopAt do
		if p:GetAttribute("NoTheme") then return false end
		p = p.Parent
	end
	return true
end

function library:setTheme(name)
	local preset = ThemePresets[name]
	if not preset then return end
	local map = {}
	for _, k in ipairs(THEME_KEYS) do
		if preset[k] then map[colorKey(Theme[k])] = preset[k] end
	end
	for _, k in ipairs(THEME_KEYS) do
		if preset[k] then Theme[k] = preset[k] end
	end

	local function remap(obj, prop)
		local ok, c = pcall(function() return obj[prop] end)
		if ok and typeof(c) == "Color3" then
			local new = map[colorKey(c)]
			if new then obj[prop] = new end
		end
	end
	for _, obj in ipairs(self.screen:GetDescendants()) do
		if isThemed(obj, self.screen) then
			if obj:IsA("UIStroke") then
				remap(obj, "Color")
			elseif obj:IsA("GuiObject") then
				remap(obj, "BackgroundColor3")
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					remap(obj, "TextColor3")
				elseif obj:IsA("TextBox") then
					remap(obj, "TextColor3")
					remap(obj, "PlaceholderColor3")
				end
				if obj:IsA("ScrollingFrame") then remap(obj, "ScrollBarImageColor3") end
			end
		end
	end
	for _, hook in ipairs(themeHooks) do pcall(hook) end
	self.themeName = name
end

function library:setCustomTheme(color)
	local taken = {}
	for _, k in ipairs({"Background", "Panel", "PanelHover", "Card", "Border", "TrackOff", "Text", "SubText", "Muted",
		"Green", "GreenSoft", "Orange", "Blue", "Red"}) do
		taken[colorKey(Theme[k])] = true
	end

	local function unique(c)
		for _ = 1, 8 do
			if not taken[colorKey(c)] then break end
			c = Color3.fromRGB(math.min(255, math.floor(c.R * 255 + 0.5) + 1), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
		end
		taken[colorKey(c)] = true
		return c
	end
	ThemePresets.Custom = {
		Accent = unique(color),
		AccentSoft = unique(color:Lerp(Theme.Background, 0.8)),
		AccentLine = unique(color:Lerp(Color3.new(0, 0, 0), 0.45)),
	}
	self:setTheme("Custom")
end

-- a = 0 
function library:setBackgroundTransparency(a)
	a = math.clamp(a, 0, 1)
	SurfaceAlpha = a
	for _, sf in ipairs(Surfaces) do
		sf.obj.BackgroundTransparency = a * sf.f
	end
end

-- LANGUAGE
library.Languages = {"English", "Indonesia"}
local langCodes = {English = "en", Indonesia = "id"}
local langLookup, langHooks, currentLang = {}, {}, "en"

local function indexText(t, entry)
	if type(t) ~= "string" then return end
	langLookup[t] = langLookup[t] or {e = entry, up = false}
	local u = string.upper(t)
	langLookup[u] = langLookup[u] or {e = entry, up = true} 
end

-- list 
function library:addStrings(list)
	for _, t in ipairs(list) do
		local e = {en = t.en or t[1], id = t.id or t[2]}
		indexText(e.en, e)
		indexText(e.id, e)
	end
end

function library:tr(text)
	if type(text) ~= "string" then return text end
	local hit = langLookup[text]
	if not hit then return text end
	local out = hit.e[currentLang] or hit.e.en or text
	return hit.up and string.upper(out) or out
end

function library:getLanguage() return currentLang end
function library:onLanguage(fn) table.insert(langHooks, fn) end

function library:setLanguage(name)
	local code = langCodes[name]
	if not code then return end
	currentLang = code
	for _, obj in ipairs(self.screen:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			local t = self:tr(obj.Text)
			if t ~= obj.Text then obj.Text = t end
		elseif obj:IsA("TextBox") then
			local t = self:tr(obj.PlaceholderText)
			if t ~= obj.PlaceholderText then obj.PlaceholderText = t end
		end
	end
	for _, hook in ipairs(langHooks) do pcall(hook, code) end
end

-- Popup 
function library:notify(text, kind)
	if self.closing then return end
	kind = kind or "success"
	text = self:tr(text)
	self._toastId = (self._toastId or 0) + 1

	local slot = create("Frame", {
		Name = "Slot", Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1,
		LayoutOrder = self._toastId, Parent = self.toasts,
	})
	local card = create("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -22), Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, GroupTransparency = 1, Parent = slot,
	}, {corner(12), stroke(Theme.Border)})

	local tint, soft, iconName
	if kind == "error" then
		tint, soft, iconName = Theme.Red, Color3.fromRGB(76, 28, 28), "cross"
	elseif kind == "info" then
		tint, soft, iconName = Theme.Accent, Theme.AccentSoft, "info"
	else
		tint, soft, iconName = Theme.Green, Theme.GreenSoft, "check"
	end
	local tile = create("Frame", {
		Position = UDim2.new(0, 10, 0.5, -13), Size = UDim2.new(0, 26, 0, 26),
		BackgroundColor3 = soft, BorderSizePixel = 0, Parent = card,
	}, {corner(13)})
	makeIcon(iconName, tile, tint, 14).Position = UDim2.new(0.5, -7, 0.5, -7)
	newLabel({Text = text, Position = UDim2.new(0, 46, 0, 0), Size = UDim2.new(1, -58, 1, 0),
		Font = Enum.Font.GothamMedium, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})

	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 0), GroupTransparency = 0}):Play()
	task.delay(2.4, function()
		if not card.Parent then return end
		local tw = TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0, -16), GroupTransparency = 1})
		tw.Completed:Connect(function() slot:Destroy() end)
		tw:Play()
	end)
end

function library:_refreshCanvas()
	for _, p in ipairs(self.pages) do
		p.container.AutomaticCanvasSize = Enum.AutomaticSize.None
		p.container.AutomaticCanvasSize = Enum.AutomaticSize.Y
		p._dirty = true
	end
end

function library:_width()
	return self.root.Size.X.Offset
end

function library:_applyResponsive()
	local compact = self.root.AbsoluteSize.X < 400
	self.badge.Visible = not compact
	local reserve = compact and 140 or 190
	self.titleLabel.Size = UDim2.new(1, -reserve, 0, 18)
	self.subLabel.Size = UDim2.new(1, -reserve, 0, 16)
end

function library:_animate(show)
	self._token = self._token + 1
	local token = self._token
	if show then
		self.root.Visible = true
		local tw = TweenService:Create(self.scale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
		tw.Completed:Connect(function()
			if token == self._token then self:_refreshCanvas() end
		end)
		tw:Play()
		return tw
	else
		local tw = TweenService:Create(self.scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
		tw.Completed:Connect(function()
			if token == self._token then self.root.Visible = false end
		end)
		tw:Play()
		return tw
	end
end

function library:toggle()
	if self.closing then return end
	self.shown = not self.shown
	self:_animate(self.shown)
end

function library:Close()
	if self.closing then return end
	self.closing = true
	self.shown = false
	local tw = self:_animate(false)
	tw.Completed:Wait()
	if self.OnClose then
		pcall(self.OnClose)
	end
	if self.screen.Parent then
		self.screen:Destroy()
	end
end

function library:Destroy()
	self:Close()
end

function library:_setHandles(visible)
	for _, h in ipairs(self._handles) do
		h.Visible = visible
	end
end

function library:_saveGeometry()
	self.normalSize = UDim2.fromOffset(self.root.AbsoluteSize.X, self.root.AbsoluteSize.Y)
	self.normalPos = self.root.Position
end

function library:_goTo(size, pos)
	local tw = TweenService:Create(self.root, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = size, Position = pos})
	tw:Play()
	return tw
end

function library:_setMiniMode(on)
	self.header.Visible = not on
	self.mini.Visible = on
	self.body.Visible = not on
	self.controls.Position = on and UDim2.new(1, -10, 0, 12) or UDim2.new(1, -12, 0, 15)
end

-- data bar mini
function library:setMiniProfile(info)
	self.miniName.Text = info.DisplayName or "DisplayName"
	self.miniDisplay.Text = "@" .. (info.Name or "Username")
	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, info.UserId,
			Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if ok and url then self.miniAvatar.Image = url end
	end)
end

-- key: "ping" | "fps" | "afk"
function library:setMini(key, value, color)
	local chip = self.chips[key]
	if not chip then return end
	local wasVisible = chip.frame.Visible
	if value == nil then
		chip.frame.Visible = false
	else
		chip.frame.Visible = true
		chip.value.Text = tostring(value)
		if color then chip.value.TextColor3 = color end
	end
	if wasVisible ~= chip.frame.Visible then self:_resizeMini() end
end

function library:_miniWidth()
	local total, count = 0, 0
	for _, c in pairs(self.chips) do
		if c.frame.Visible then
			total = total + c.width
			count = count + 1
		end
	end
	if count > 1 then total = total + 6 * (count - 1) end
	return total + 284 
end

function library:_resizeMini(basePos)
	if self.state ~= "minimized" then return end
	self._geoToken = self._geoToken + 1
	local vp = self.screen.AbsoluteSize
	local w = math.min(self:_miniWidth(), vp.X - 20)
	local cur = basePos or self.root.Position
	local x = math.clamp(cur.X.Offset, 10, math.max(10, vp.X - w - 10))
	self:_goTo(UDim2.fromOffset(w, MINIMIZED_H), UDim2.fromOffset(x, cur.Y.Offset))
end

function library:Minimize()
	if self.closing then return end
	self._geoToken = self._geoToken + 1

	if self.state == "minimized" then 
		self.state = "normal"
		self:_setMiniMode(false)
		self:_goTo(self.normalSize, self.normalPos)
		self:_setHandles(true)
		return
	end

	if self.state == "normal" then self:_saveGeometry() end
	self.state = "minimized"
	self:_setMiniMode(true)
	self:_setHandles(false)
	self:_resizeMini(self.normalPos)
end

function library:Maximize()
	if self.closing then return end
	self._geoToken = self._geoToken + 1

	if self.state == "maximized" then 
		self.state = "normal"
		self:_goTo(self.normalSize, self.normalPos)
		self:_setHandles(true)
		return
	end

	if self.state == "normal" then self:_saveGeometry() end
	self.state = "maximized"
	self:_setMiniMode(false)
	self:_setHandles(false)
	local vp = self.screen.AbsoluteSize
	local w, h = math.min(vp.X - 40, 1000), math.min(vp.Y - 40, 760)
	self:_goTo(UDim2.fromOffset(w, h), UDim2.fromOffset(math.floor((vp.X - w) / 2), math.floor((vp.Y - h) / 2)))
end

-- HOVER
function library:_registerHover(card, bg, pg, pop)
	table.insert(self._hovers, {
		card = card, bg = bg, stroke = bg:FindFirstChildOfClass("UIStroke"), page = pg,
		scale = pop and pop:FindFirstChildOfClass("UIScale"), hot = false,
	})
end

local function setHover(h, hot)
	local quad = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if h.scale then
		local ti = hot and TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out) or quad
		TweenService:Create(h.scale, ti, {Scale = hot and HOVER_SCALE or 1}):Play()
	end
	TweenService:Create(h.bg, quad, {BackgroundColor3 = hot and Theme.PanelHover or Theme.Panel}):Play()
	if h.stroke then TweenService:Create(h.stroke, quad, {Color = hot and Theme.AccentLine or Theme.Border}):Play() end
end

function library:_updateHover()
	local active = self.shown and not self.closing and self.state ~= "minimized" and self.scale.Scale > 0.95
	local m = UserInputService:GetMouseLocation()
	for _, h in ipairs(self._hovers) do
		local inside = false
		if active and h.page == self.focusedPage and h.card.Parent then
			local c = h.page.container
			local cp, cs = c.AbsolutePosition, c.AbsoluteSize
			if m.X >= cp.X and m.X <= cp.X + cs.X and m.Y >= cp.Y and m.Y <= cp.Y + cs.Y then
				local p, s = h.card.AbsolutePosition, h.card.AbsoluteSize
				inside = m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
			end
		end
		if inside ~= h.hot then
			h.hot = inside
			setHover(h, inside)
		end
	end
end

-- PAGES
function library:addPage(title)
	local p = page.new(self, title)
	table.insert(self.pages, p)
	p.button.MouseButton1Click:Connect(function()
		self:SelectPage(p)
	end)
	return p
end

function library:SelectPage(target)
	for _, p in ipairs(self.pages) do
		local active = (p == target)
		p.container.Visible = active
		p:_setActive(active)
	end
	self.focusedPage = target
	if target then target._dirty = true end
end

function page.new(lib, title)
	local button = create("TextButton", {
		Name = title,
		AutoButtonColor = false,
		Size = UDim2.new(0, 0, 0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.AccentSoft,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Text = title,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		LayoutOrder = #lib.pages + 1,
		Parent = lib.tabs,
	}, {
		corner(9), padding(12, 0, 12, 0),
		create("UIStroke", {
			Name = "Stroke", Color = Theme.AccentLine, Thickness = 1, Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})

	local container = create("ScrollingFrame", {
		Name = title,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Border,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = lib.body,
	}, {listLayout(10), padding(7, 7, 11, 7)})

	local self = setmetatable({
		library = lib, button = button, container = container, sections = {}, _order = 0,
		items = {}, flowItems = {}, columns = {}, cols = 0, _updaters = {}, _dirty = true, _active = false,
	}, page)

	-- hover navbar
	button.MouseEnter:Connect(function()
		if self._active then return end
		tween(button, {BackgroundTransparency = 0.55, TextColor3 = Theme.SubText}, 0.12)
		tween(button.Stroke, {Transparency = 0.6}, 0.12)
	end)
	button.MouseLeave:Connect(function()
		if self._active then return end
		tween(button, {BackgroundTransparency = 1, TextColor3 = Theme.Muted}, 0.12)
		tween(button.Stroke, {Transparency = 1}, 0.12)
	end)

	-- "Flow"
	self.flow = create("Frame", {
		Name = "Flow", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1,
		LayoutOrder = 1000000, Parent = container,
	}, {create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10),
		FillDirection = Enum.FillDirection.Horizontal,
	})})
	container:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self._dirty = true end)
	self:_setColumns(1)
	return self
end

function page:_next()
	self._order = self._order + 1
	return self._order
end

local function measureOf(it, inv)
	local m = it.measure
	if typeof(m) == "Instance" then return m.AbsoluteSize.Y * (inv or 1) end
	return m or 0
end

function page:_register(frame, full, measure)
	local it = {frame = frame, full = full and true or false, measure = measure}
	table.insert(self.items, it)
	if it.full then
		frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self._dirty = true end)
	else
		local colH = {}
		for c = 1, #self.columns do colH[c] = 0 end
		for _, other in ipairs(self.flowItems) do
			for c, col in ipairs(self.columns) do
				if other.frame.Parent == col then colH[c] = colH[c] + math.max(measureOf(other), 60) + 10 end
			end
		end
		local best = 1
		for c = 2, #self.columns do
			if colH[c] < colH[best] then best = c end
		end
		table.insert(self.flowItems, it)
		frame.LayoutOrder = #self.flowItems
		frame.Parent = self.columns[best]
		if typeof(measure) == "Instance" then
			measure:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self._dirty = true end)
		end
	end
	self._dirty = true
end

function page:_setColumns(n)
	local heights = {}
	for i, it in ipairs(self.flowItems) do heights[i] = measureOf(it) end
	for _, it in ipairs(self.flowItems) do it.frame.Parent = nil end
	for _, c in ipairs(self.columns) do c:Destroy() end
	self.columns = {}
	self.cols = n
	for c = 1, n do
		self.columns[c] = create("Frame", {
			Name = "Col" .. c, LayoutOrder = c,
			Size = UDim2.new(1 / n, -(10 * (n - 1)) / n, 0, 0), AutomaticSize = AUTO_Y,
			BackgroundTransparency = 1, Parent = self.flow,
		}, {listLayout(10)})
	end
	local colH = {}
	for c = 1, n do colH[c] = 0 end
	for i, it in ipairs(self.flowItems) do
		local c = 1
		for k = 2, n do
			if colH[k] < colH[c] then c = k end
		end
		it.frame.LayoutOrder = i
		it.frame.Parent = self.columns[c]
		colH[c] = colH[c] + math.max(heights[i], 60) + 10
	end
	self._dirty = true
end

function page:_relayout()
	local lib = self.library
	local rw = lib.root.AbsoluteSize.X
	if rw <= 0 then return false end
	local k = lib.main.AbsoluteSize.X / rw 
	if k < 0.15 then return false end
	local inv = 1 / k
	local w = lib.root.Size.X.Offset - 20
	local vh = lib.root.Size.Y.Offset - 138
	if w <= 0 or vh <= 0 then return false end

	for _, f in ipairs(self._updaters) do f(w - 18) end

	local cols = math.clamp(math.floor((w - 8) / 310), 1, math.max(1, #self.flowItems))
	if cols ~= self.cols then
		self:_setColumns(cols)
		return false
	end

	local used = 14
	for _, it in ipairs(self.items) do
		if it.full then used = used + it.frame.AbsoluteSize.Y * inv + 10 end
	end
	local target = vh - used
	local natural, lists = {}, {}
	for c, col in ipairs(self.columns) do
		local sum, list = 0, {}
		for _, it in ipairs(self.flowItems) do
			if it.frame.Parent == col then
				local h = measureOf(it, inv)
				table.insert(list, {it = it, h = h})
				sum = sum + h
			end
		end
		sum = sum + 10 * math.max(#list - 1, 0)
		natural[c], lists[c] = sum, list
		target = math.max(target, sum)
	end
	for c, list in ipairs(lists) do
		if #list > 0 then
			local share = (target - natural[c]) / #list
			for _, e in ipairs(list) do
				e.it.frame.Size = UDim2.new(1, 0, 0, math.floor(e.h + share))
			end
		end
	end
	return true
end

function page:_setActive(active)
	self._active = active
	apply(self.button, {
		BackgroundTransparency = active and 0 or 1,
		TextColor3 = active and Theme.Accent or Theme.Muted,
	}, true)
	apply(self.button.Stroke, {Transparency = active and 0 or 1}, true)
end

function page:addSection(title)
	local s = section.new(self, title)
	table.insert(self.sections, s)
	return s
end

-- components
function page:addHeading(overline, title, subtitle)
	local f = create("Frame", {
		Name = "Heading", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
		BackgroundTransparency = 1, LayoutOrder = self:_next(), Parent = self.container,
	}, {listLayout(3)})
	newLabel({Text = string.upper(overline or ""), Size = UDim2.new(1, 0, 0, 14), TextSize = 10,
		Font = Enum.Font.GothamMedium, TextColor3 = Theme.Muted, LayoutOrder = 1, Parent = f})
	newLabel({Text = title or "", Size = UDim2.new(1, 0, 0, 26), Font = Enum.Font.GothamBold,
		TextSize = 18, LayoutOrder = 2, Parent = f})
	local sub = newLabel({Text = subtitle or "", Size = UDim2.new(1, 0, 0, 16), TextSize = 11,
		TextColor3 = Theme.Muted, LayoutOrder = 3, Parent = f})
	self:_register(f, true)
	return {Instance = f, Subtitle = sub}
end

-- defs: {{Key, Title, Color, Value, Status, StatusColor}
function page:addStats(defs)
	local n = #defs
	local GAP, CELL_H = 10, 84
	local grid = create("Frame", {
		Name = "Stats", Size = UDim2.new(1, 0, 0, CELL_H), BackgroundTransparency = 1,
		LayoutOrder = self:_next(), Parent = self.container,
	})

	local result, cells = {}, {}
	for i, def in ipairs(defs) do
		local cell, pop, bg = popCard(grid, def.Key or def.Title)
		cells[i] = cell
		local inner = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = pop,
		}, {padding(12, 10, 12, 10)})

		local hasIcon = def.Icon ~= nil
		if hasIcon then
			makeIcon(def.Icon, inner, def.Color or Theme.Accent, 14).Position = UDim2.new(0, 0, 0, 1)
		else
			create("Frame", {
				Position = UDim2.new(0, 0, 0, 5), Size = UDim2.new(0, 6, 0, 6),
				BackgroundColor3 = def.Color or Theme.Accent, BorderSizePixel = 0, Parent = inner,
			}, {corner(3)})
		end
		newLabel({Text = def.Title, Position = UDim2.new(0, hasIcon and 20 or 12, 0, 0), Size = UDim2.new(1, hasIcon and -20 or -12, 0, 16),
			TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})
		local value = newLabel({Text = def.Value or "--", Position = UDim2.new(0, 0, 0, 18),
			Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.GothamBold, TextSize = 21,
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})
		local status = newLabel({Text = def.Status or "", Position = UDim2.new(0, 0, 0, 48),
			Size = UDim2.new(1, 0, 0, 14), TextSize = 10, TextColor3 = def.StatusColor or Theme.Muted,
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})

		self.library:_registerHover(cell, bg, self, pop)
		result[def.Key or i] = {
			Instance = cell,
			Set = function(_, v, s, c)
				if v ~= nil then
					v = tostring(v)
					value.Text = v
					value.TextSize = (#v > 11) and 16 or 21 
				end
				if s ~= nil then status.Text = self.library:tr(s) end
				if c ~= nil then status.TextColor3 = c end
			end,
		}
	end

	local lastCols = 0
	local function arrange(w)
		local best = 1
		for c = 2, n do
			if (w - GAP * (c - 1)) / c >= 150 then best = c end
		end
		if best == lastCols then return end
		lastCols = best
		local rows = math.ceil(n / best)
		grid.Size = UDim2.new(1, 0, 0, rows * CELL_H + (rows - 1) * GAP)
		for i, cell in ipairs(cells) do
			local row, col = math.floor((i - 1) / best), (i - 1) % best
			local inRow = (row < rows - 1) and best or (n - (rows - 1) * best)
			cell.Size = UDim2.new(1 / inRow, -GAP * (inRow - 1) / inRow, 0, CELL_H)
			cell.Position = UDim2.new(col / inRow, col * GAP / inRow, 0, row * (CELL_H + GAP))
		end
	end
	table.insert(self._updaters, arrange)
	arrange(self.library:_width() - 38)
	self:_register(grid, true)
	return result
end

function page:addAccountCard(info)
	local card, pop, bg = popCard(self.container, "Account")
	local inner = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = pop,
	}, {padding(14, 14, 14, 12)})

	local avatar = create("ImageLabel", {
		Size = UDim2.new(0, 44, 0, 44), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = inner,
	}, {corner(22), stroke()})
	task.spawn(function()
		local okThumb, url = pcall(Players.GetUserThumbnailAsync, Players, info.UserId,
			Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if okThumb and url then avatar.Image = url end
	end)

	makeIcon("user", inner, Theme.SubText, 12).Position = UDim2.new(0, 58, 0, 1)
	newLabel({Text = "ACCOUNT INFORMATION", Position = UDim2.new(0, 74, 0, 0), Size = UDim2.new(1, -74, 0, 14),
		TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Theme.SubText, Parent = inner})
	newLabel({Text = info.DisplayName or "DisplayName", Position = UDim2.new(0, 58, 0, 14), Size = UDim2.new(1, -58, 0, 18),
		Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})
	newLabel({Text = "@" .. (info.Name or "Username"), Position = UDim2.new(0, 58, 0, 32),
		Size = UDim2.new(1, -58, 0, 14), TextSize = 11, TextColor3 = Theme.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})

	create("Frame", {Position = UDim2.new(0, 0, 0, 62), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = inner})

	newLabel({Text = "USER ID", Position = UDim2.new(0, 0, 0, 74), Size = UDim2.new(0.5, 0, 0, 14),
		TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Theme.SubText, Parent = inner})
	newLabel({Text = tostring(info.UserId or "0"), Position = UDim2.new(0, 0, 0, 90), Size = UDim2.new(0.5, 0, 0, 18),
		Font = Enum.Font.GothamBold, TextSize = 12, Parent = inner})
	newLabel({Text = "ACCOUNT STATUS", Position = UDim2.new(0.5, 0, 0, 74), Size = UDim2.new(0.5, 0, 0, 14),
		TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Theme.SubText, Parent = inner})
	newLabel({Text = "• " .. (info.Status or "Active"), Position = UDim2.new(0.5, 0, 0, 90), Size = UDim2.new(0.5, 0, 0, 18),
		Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Green, Parent = inner})

	self.library:_registerHover(card, bg, self, pop)
	self:_register(card, false, 132)
	return card
end

function page:addNewsCard(title, items)
	local card, pop, bg = popCard(self.container, "News")
	local content = create("Frame", {
		Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, Parent = pop,
	}, {padding(12, 12, 12, 12), listLayout(8)})

	local head = create("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 0, Parent = content})
	makeIcon("news", head, Theme.Accent, 14).Position = UDim2.new(0, 0, 0.5, -7)
	newLabel({Text = title or "What's New", Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(0.6, -22, 1, 0), Font = Enum.Font.GothamBold, TextSize = 13, Parent = head})

	for i, item in ipairs(items or {}) do
		local isNews = (item.Kind == "news")
		local entry = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, LayoutOrder = i,
			BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = content,
		}, {corner(8), padding(10, 10, 10, 10), listLayout(5)})
		surface(entry, 0.5)

		local meta = create("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 1, Parent = entry},
			{listLayout(6, Enum.FillDirection.Horizontal)})
		local badge = newLabel({
			Text = string.upper(item.Kind or "update"), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 0, BackgroundColor3 = isNews and Theme.GreenSoft or Theme.AccentSoft,
			TextColor3 = isNews and Theme.Green or Theme.Accent, Font = Enum.Font.GothamMedium, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1, Parent = meta,
		})
		corner(5).Parent = badge
		padding(8, 0, 8, 0).Parent = badge
		newLabel({Text = item.Date or "", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 11, TextColor3 = Theme.SubText, LayoutOrder = 2, Parent = meta})

		newLabel({Text = item.Title or "", Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold,
			TextSize = 13, LayoutOrder = 2, Parent = entry})
		newLabel({Text = item.Text or "", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top, TextSize = 11, TextColor3 = Theme.Muted, LayoutOrder = 3, Parent = entry})
	end

	self.library:_registerHover(card, bg, self, pop)
	self:_register(card, false, content)
	return card
end

function page:addVersionCard(info)
	local card, pop, bg = popCard(self.container, "Version")
	local content = create("Frame", {
		Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, Parent = pop,
	}, {padding(12, 12, 12, 12), listLayout(6)})

	local head = create("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 0, Parent = content})
	makeIcon("info", head, Theme.Accent, 14).Position = UDim2.new(0, 0, 0.5, -7)
	newLabel({Text = "Version", Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, -22, 1, 0),
		Font = Enum.Font.GothamBold, TextSize = 13, Parent = head})

	local function row(order, label, value, color)
		local r = surface(create("Frame", {
			Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
			LayoutOrder = order, Parent = content,
		}, {corner(8), stroke(Theme.Border, 0.4)}), 0.5)
		newLabel({Text = label, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, -12, 1, 0),
			TextSize = 11, TextColor3 = Theme.Muted, Parent = r})
		return newLabel({Text = value, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0),
			Size = UDim2.new(0.5, -12, 1, 0), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = color or Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
	end
	row(1, "UI Version", info.Version or "-")
	row(2, "Last update", info.Updated or "-")
	local statusLabel = row(3, "Status", info.Status or "Not checked", info.StatusColor or Theme.Muted)

	self.library:_registerHover(card, bg, self, pop)
	self:_register(card, false, content)
	return {SetStatus = function(_, text, color)
		statusLabel.Text = self.library:tr(text)
		if color then statusLabel.TextColor3 = color end
	end}
end

-- SECTION
function section.new(pg, title)
	local card, pop, bg = popCard(pg.container, title)
	local content = create("Frame", {
		Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
		BackgroundTransparency = 1, Parent = pop,
	}, {padding(12, 12, 12, 12), listLayout(6)})

	newLabel({Name = "Title", Text = string.upper(title), Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.Muted, LayoutOrder = 0, Parent = content})

	pg.library:_registerHover(card, bg, pg, pop)
	pg:_register(card, false, content)
	return setmetatable({page = pg, library = pg.library, container = content, _order = 0}, section)
end

local function newRow(sec, height, className, extra)
	sec._order = sec._order + 1
	local props = {
		Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
		LayoutOrder = sec._order, Parent = sec.container,
	}
	for k, v in pairs(extra or {}) do
		props[k] = v
	end
	return surface(create(className or "Frame", props, {corner(8), stroke(Theme.Border, 0.4)}), 0.5)
end

function section:addLabel(text)
	self._order = self._order + 1
	return newLabel({
		Text = text, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top, TextSize = 11, TextColor3 = Theme.Muted,
		LayoutOrder = self._order, Parent = self.container,
	})
end

function section:addInfo(title, value)
	local row = newRow(self, 36, "Frame", {Name = "Info"})
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, -12, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
	local val = newLabel({Text = value or "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.5, -12, 1, 0), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right, Parent = row})
	return {Instance = row, Set = function(_, text, color)
		val.Text = tostring(text)
		if color then val.TextColor3 = color end
	end}
end

function section:addColorPicker(title, default, callback)
	local lib = self.library
	local color = default or Theme.Accent
	local h, s, v = Color3.toHSV(color)
	local open = false
	local D, SQ, R_MID, THICK, N = 160, 84, 71, 14, 90
	local PANEL_H = 176

	self._order = self._order + 1
	local holder = create("Frame", {
		Name = "ColorPicker", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ClipsDescendants = true,
		LayoutOrder = self._order, Parent = self.container,
	})
	local head = surface(create("Frame", {
		Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = holder,
	}, {corner(8), stroke(Theme.Border, 0.4)}), 0.5)
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -150, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = head})
	local arrow = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1, Text = ">", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Theme.Muted, Rotation = 90, Parent = head,
	})
	local hexBox = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0.5, 0), Size = UDim2.new(0, 74, 0, 22),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 11,
		TextColor3 = Theme.Text, ClearTextOnFocus = false, PlaceholderText = "#RRGGBB", PlaceholderColor3 = Theme.Muted,
		Text = "", Parent = head,
	}, {corner(6), stroke(Theme.Border)})
	local preview = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -114, 0.5, 0), Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = color, BorderSizePixel = 0, Parent = head,
	}, {corner(9), stroke(Theme.Border)})
	preview:SetAttribute("NoTheme", true)

	local panel = surface(create("Frame", {
		Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, PANEL_H),
		BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = holder,
	}, {corner(8), stroke(Theme.Border, 0.4)}), 0.5)

	local wheel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, D, 0, D),
		BackgroundTransparency = 1, Parent = panel,
	})
	wheel:SetAttribute("NoTheme", true)

	for i = 0, N - 1 do
		local ang = (i + 0.5) / N * 2 * math.pi
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, D / 2 + R_MID * math.cos(ang), 0, D / 2 + R_MID * math.sin(ang)),
			Size = UDim2.new(0, THICK, 0, 7), Rotation = math.deg(ang),
			BackgroundColor3 = Color3.fromHSV((i + 0.5) / N, 1, 1), BorderSizePixel = 0, Parent = wheel,
		})
	end

	local sq = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, D / 2, 0, D / 2), Size = UDim2.new(0, SQ, 0, SQ),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Parent = wheel,
	}, {corner(5)})
	create("Frame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sq,
	}, {corner(5), create("UIGradient", {Transparency = NumberSequence.new(0, 1)})})
	create("Frame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sq,
	}, {corner(5), create("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)})})

	local function marker()
		return create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 14, 0, 14), BorderSizePixel = 0, ZIndex = 3, Parent = wheel,
		}, {corner(7), create("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})})
	end
	local hueMarker, svMarker = marker(), marker()

	local area = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = wheel,
	})

	local function hexOf(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function render(exact)
		color = exact or Color3.fromHSV(h, s, v)
		sq.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		local ang = h * 2 * math.pi
		hueMarker.Position = UDim2.new(0, D / 2 + R_MID * math.cos(ang), 0, D / 2 + R_MID * math.sin(ang))
		hueMarker.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svMarker.Position = UDim2.new(0, D / 2 - SQ / 2 + s * SQ, 0, D / 2 - SQ / 2 + (1 - v) * SQ)
		svMarker.BackgroundColor3 = color
		preview.BackgroundColor3 = color
		hexBox.Text = hexOf(color)
	end

	local lastFire = 0
	local function fire(force)
		if not callback then return end
		local now = os.clock()
		if force or now - lastFire > 0.12 then 
			lastFire = now
			task.spawn(callback, color)
		end
	end

	local mode
	local function update(pos)
		local c = area.AbsolutePosition + area.AbsoluteSize / 2
		local dx, dy = pos.X - c.X, pos.Y - c.Y
		if mode == "hue" then
			h = (math.atan2(dy, dx) / (2 * math.pi)) % 1
		elseif mode == "sv" then
			s = math.clamp(dx / SQ + 0.5, 0, 1)
			v = 1 - math.clamp(dy / SQ + 0.5, 0, 1)
		end
		render()
		fire(false)
	end
	area.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local c = area.AbsolutePosition + area.AbsoluteSize / 2
			local dx, dy = input.Position.X - c.X, input.Position.Y - c.Y
			local dist = math.sqrt(dx * dx + dy * dy)
			if dist >= R_MID - THICK / 2 - 6 and dist <= R_MID + THICK / 2 + 6 then
				mode = "hue"
			elseif math.abs(dx) <= SQ / 2 + 4 and math.abs(dy) <= SQ / 2 + 4 then
				mode = "sv"
			else
				mode = nil
			end
			if mode then update(input.Position) end
		end
	end)
	lib:connect(UserInputService.InputChanged, function(input)
		if mode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position)
		end
	end)
	lib:connect(UserInputService.InputEnded, function(input)
		if mode and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			mode = nil
			fire(true)
		end
	end)

	hexBox.FocusLost:Connect(function()
		local txt = hexBox.Text:gsub("[#%s]", "")
		if #txt == 3 then
			txt = txt:sub(1, 1):rep(2) .. txt:sub(2, 2):rep(2) .. txt:sub(3, 3):rep(2)
		end
		if #txt == 6 and txt:match("^%x+$") then
			local parsed = Color3.fromRGB(tonumber(txt:sub(1, 2), 16), tonumber(txt:sub(3, 4), 16), tonumber(txt:sub(5, 6), 16))
			h, s, v = Color3.toHSV(parsed)
			render(parsed)
			fire(true)
		else
			hexBox.Text = hexOf(color)
		end
	end)

	arrow.MouseButton1Click:Connect(function()
		open = not open
		tween(holder, {Size = UDim2.new(1, 0, 0, open and (40 + PANEL_H) or 36)}, 0.22)
		tween(arrow, {Rotation = open and 270 or 90}, 0.22)
	end)

	render(color)
	local api = {Instance = holder}
	function api:Set(c, silent)
		h, s, v = Color3.toHSV(c)
		render(c)
		if not silent then fire(true) end
	end
	return api
end

function section:addSwatches(title, options, default, callback)
	local selected = default
	local row = newRow(self, 44, "Frame", {Name = "Swatches"})
	local labelW = UDim2.new(1, -(#options * 26 + 28), 0, 16)
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 6), Size = labelW, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
	local nameLabel = newLabel({Text = selected or "", Position = UDim2.new(0, 12, 0, 22), Size = UDim2.new(1, -(#options * 26 + 28), 0, 14),
		TextSize = 10, TextColor3 = Theme.Muted, Parent = row})
	local holder = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, #options * 26 - 6, 0, 20), BackgroundTransparency = 1, Parent = row,
	}, {listLayout(6, Enum.FillDirection.Horizontal)})

	local buttons = {}
	local function render()
		for name, b in pairs(buttons) do
			b.stroke.Transparency = (name == selected) and 0 or 1
		end
		nameLabel.Text = selected or "Custom"
	end
	for i, opt in ipairs(options) do
		local btn = create("TextButton", {
			Size = UDim2.new(0, 20, 0, 20), BackgroundColor3 = opt.Color, BorderSizePixel = 0,
			Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = holder,
		}, {corner(10)})
		local st = create("UIStroke", {
			Color = Color3.fromRGB(150, 150, 165), Thickness = 2, Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn,
		})
		btn:SetAttribute("NoTheme", true) 
		st:SetAttribute("NoTheme", true)
		buttons[opt.Name] = {btn = btn, stroke = st}
		btn.MouseButton1Click:Connect(function()
			selected = opt.Name
			render()
			if callback then task.spawn(callback, opt.Name) end
		end)
	end
	render()
	local api = {Instance = row}
	function api:Set(name, silent) 
		selected = name
		render()
		if name and not silent and callback then task.spawn(callback, name) end
	end
	return api
end

function section:addButton(title, callback)
	local btn = newRow(self, 34, "TextButton", {
		Name = "Button", Text = title, AutoButtonColor = false,
		Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Text,
	})
	btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.AccentSoft}) end)
	btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Theme.Card}) end)
	btn.MouseButton1Click:Connect(function()
		if callback then
			task.spawn(callback, function(newTitle) btn.Text = newTitle end)
		end
	end)
	return btn
end

function section:addTextBox(title, placeholder, callback)
	local row = newRow(self, 36, "Frame", {Name = "TextBox"})
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.4, -12, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
	local box = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.6, -14, 0, 22),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 11,
		TextColor3 = Theme.Text, PlaceholderText = placeholder or "", PlaceholderColor3 = Theme.Muted,
		ClearTextOnFocus = false, ClipsDescendants = true, Text = "", Parent = row,
	}, {corner(6), stroke(Theme.Border), padding(8, 0, 8, 0)})
	box.FocusLost:Connect(function(enter)
		if callback then task.spawn(callback, box.Text, enter) end
	end)
	local api = {Instance = row}
	function api:Get() return box.Text end
	function api:Set(t) box.Text = t or "" end
	return api
end

function section:addGrid(height, cellW, cellH)
	cellW, cellH = cellW or 84, cellH or 104
	local row = newRow(self, height or 220, "Frame", {Name = "Grid", ClipsDescendants = true})
	local scroll = create("ScrollingFrame", {
		Position = UDim2.new(0, 6, 0, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = row,
	}, {create("UIGridLayout", {
		CellSize = UDim2.fromOffset(cellW, cellH), CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})})
	local status = newLabel({
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, -24, 0, 40),
		TextSize = 11, TextColor3 = Theme.Muted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false, ZIndex = 3, Parent = row,
	})

	local count = 0
	local api = {Instance = row}
	function api:Clear()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		count = 0
	end
	function api:SetStatus(text)
		text = text or ""
		status.Text = self.library and self.library:tr(text) or text
		status.Visible = text ~= ""
	end
	function api:Add(image, text, onClick, fav)
		count = count + 1
		local cell = create("TextButton", {
			Name = "Cell", AutoButtonColor = false, Text = "", BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0, LayoutOrder = count, Parent = scroll,
		}, {corner(8), stroke(Theme.Border, 0.4)})
		local img = create("ImageLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0.5, -30, 0, 6), Size = UDim2.fromOffset(60, 60),
			Image = image or "", ScaleType = Enum.ScaleType.Fit, Parent = cell,
		})
		newLabel({
			Text = text or "", Position = UDim2.new(0, 4, 0, 68), Size = UDim2.new(1, -8, 0, cellH - 72),
			TextSize = 10, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, Parent = cell,
		})
		cell.MouseEnter:Connect(function() tween(cell, {BackgroundColor3 = Theme.AccentSoft}) end)
		cell.MouseLeave:Connect(function() tween(cell, {BackgroundColor3 = Theme.Panel}) end)
		cell.MouseButton1Click:Connect(function()
			if onClick then task.spawn(onClick) end
		end)

		local paint
		if fav then
			local on = fav.on and true or false
			local btn = create("TextButton", {
				Name = "Fav", AutoButtonColor = false, Text = "", BackgroundTransparency = 1,
				Position = UDim2.new(1, -22, 0, 3), Size = UDim2.fromOffset(18, 18), ZIndex = 3, Parent = cell,
			})
			btn:SetAttribute("NoTheme", true) -- warna bintang tetap kuning walau tema berganti
			local parts = {}
			for _, rot in ipairs({0, 45}) do -- dua kotak diputar 45 derajat = bentuk bintang
				table.insert(parts, create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(10, 10),
					Rotation = rot, BorderSizePixel = 0, ZIndex = 3, Parent = btn,
				}, {create("UIStroke", {Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})}))
			end
			paint = function(state)
				if not btn.Parent then return false end -- sel sudah dihapus
				on = state and true or false
				for _, sq in ipairs(parts) do
					sq.BackgroundColor3 = Color3.fromRGB(251, 191, 36)
					sq.BackgroundTransparency = on and 0 or 1
					sq.UIStroke.Color = on and Color3.fromRGB(251, 191, 36) or Theme.Muted
				end
				return true
			end
			paint(on)
			btn.MouseButton1Click:Connect(function()
				paint(not on)
				if fav.onToggle then task.spawn(fav.onToggle, on) end
			end)
		end
		return img, paint
	end
	api.library = self.library
	return api
end

function section:addToggle(title, default, callback)
	local active = default and true or false
	local row = newRow(self, 36, "TextButton", {Name = "Toggle", Text = "", AutoButtonColor = false})
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -64, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
	local track = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 36, 0, 20),
		BackgroundColor3 = Theme.TrackOff, BorderSizePixel = 0, Parent = row,
	}, {corner(10)})
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.new(0, 14, 0, 14),
		BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = track,
	}, {corner(7)})

	local function knobColor()
		local a = Theme.Accent
		local light = 0.299 * a.R + 0.587 * a.G + 0.114 * a.B > 0.75
		return (active and light) and Theme.Background or Theme.Text
	end
	local function render(animate)
		apply(track, {BackgroundColor3 = active and Theme.Accent or Theme.TrackOff}, animate)
		apply(knob, {
			Position = active and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = knobColor(),
		}, animate)
	end
	render(false)
	table.insert(themeHooks, function() render(false) end)

	local api = {Instance = row}
	function api:Set(v)
		active = v and true or false
		render(true)
		if callback then task.spawn(callback, active) end
	end
	function api:Get() return active end

	row.MouseButton1Click:Connect(function() api:Set(not active) end)
	return api
end

function section:addSlider(title, default, min, max, callback, suffix)
	suffix = suffix or ""
	local value = math.clamp(default or min, min, max)
	local row = newRow(self, 60, "Frame", {Name = "Slider"})
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -24, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})

	local track = create("Frame", {
		Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 24),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = row,
	}, {corner(9), stroke(Theme.AccentLine)})

	local pct0 = (value - min) / (max - min)
	local grad = create("UIGradient", {Color = accentGradient()})
	local fillStroke = create("UIStroke", {
		Color = accentOutline(), Thickness = 1, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	local fill = create("Frame", {
		Name = "Fill", Size = UDim2.new(pct0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0, Visible = pct0 > 0, Parent = track,
	}, {corner(9), grad, fillStroke})
	table.insert(themeHooks, function()
		grad.Color = accentGradient()
		fillStroke.Color = accentOutline()
	end)
	fill:SetAttribute("NoTheme", true)

	local box = create("TextBox", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Theme.Text, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.65,
		ClearTextOnFocus = false, TextEditable = false, Text = tostring(value) .. suffix, ZIndex = 3, Parent = track,
	})
	local hit = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		ZIndex = 4, Parent = track,
	})

	local function setValue(v)
		v = math.clamp(v, min, max)
		box.Text = tostring(v) .. suffix
		local pct = (v - min) / (max - min)
		fill.Visible = pct > 0
		tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.05)
		if v ~= value then
			value = v
			if callback then task.spawn(callback, value) end
		end
	end

	local function fromX(x)
		local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		setValue(math.floor(min + (max - min) * pct))
	end

	local dragging, lastClick = false, 0
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local now = os.clock()
			if now - lastClick < 0.35 then 
				lastClick = 0
				dragging = false
				hit.Visible = false
				box.TextEditable = true
				box.Text = tostring(value)
				task.defer(function() box:CaptureFocus() end)
				return
			end
			lastClick = now
			dragging = true
			fromX(input.Position.X)
		end
	end)
	self.library:connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	self.library:connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	box.FocusLost:Connect(function()
		box.TextEditable = false
		hit.Visible = true
		local n = tonumber(string.match(box.Text, "-?%d+%.?%d*"))
		if n then
			setValue(math.floor(n))
		else
			box.Text = tostring(value) .. suffix
		end
	end)

	local api = {Instance = row}
	function api:Set(v) setValue(v) end
	return api
end

-- respectProcessed 
function section:addKeybind(title, default, callback, changedCallback, respectProcessed)
	local lib = self.library
	local key = default
	local row = newRow(self, 36, "Frame", {Name = "Keybind"})
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
	local btn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 76, 0, 22),
		BackgroundColor3 = Theme.AccentSoft, BorderSizePixel = 0, AutoButtonColor = false,
		Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.Accent,
		Text = key and key.Name or "None", Parent = row,
	}, {corner(6), stroke(Theme.AccentLine)})

	-- callback
	lib:connect(UserInputService.InputBegan, function(input, processed)
		if lib.listening then return end
		if respectProcessed and processed then return end
		if key and input.KeyCode == key and callback then
			task.spawn(callback)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		if lib.listening then return end
		lib.listening = true
		btn.Text = "..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			conn:Disconnect()
			if input.KeyCode == Enum.KeyCode.Escape then
				btn.Text = key and key.Name or "None"
			else
				key = input.KeyCode
				btn.Text = key.Name
				if changedCallback then task.spawn(changedCallback, input) end
			end
			task.defer(function() lib.listening = false end)
		end)
	end)

	local api = {Instance = row}
	function api:Set(newKey, silent)
		key = newKey
		btn.Text = key and key.Name or "None"
		if not silent and changedCallback then task.spawn(changedCallback, {KeyCode = key}) end
	end
	return api
end

function section:addDropdown(title, list, callback)
	list = list or {}
	local ITEM_H, MAX_VISIBLE = 28, 3
	local open, count = false, 0

	local holder = create("Frame", {
		Name = "Dropdown", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
		ClipsDescendants = true, LayoutOrder = (function() self._order = self._order + 1 return self._order end)(),
		Parent = self.container,
	})

	local head = create("Frame", {
		Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = holder,
	}, {corner(8), stroke(Theme.Border, 0.4)})
	surface(head, 0.5)
	local box = create("TextBox", {
		Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1,
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, PlaceholderText = title,
		PlaceholderColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = true,
		Text = "", Parent = head,
	})
	local arrow = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1, Text = ">", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Theme.Muted, Rotation = 90, Parent = head,
	})
	local listFrame = create("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false, Parent = holder,
	}, {corner(8), stroke(Theme.Border, 0.4), padding(4, 4, 4, 4), listLayout(2)})

	local function relayout()
		local rows = math.min(count, MAX_VISIBLE)
		local h = rows > 0 and (rows * (ITEM_H + 2) + 6) or 0
		listFrame.Size = UDim2.new(1, 0, 0, h)
		listFrame.Visible = open and rows > 0
		tween(holder, {Size = UDim2.new(1, 0, 0, open and (40 + h) or 36)}, 0.2)
		tween(arrow, {Rotation = open and 270 or 90}, 0.2)
	end

	local function rebuild(filter)
		filter = (filter or ""):lower()
		for _, c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		count = 0
		for _, value in ipairs(list) do
			if filter == "" or tostring(value):lower():find(filter, 1, true) then
				count = count + 1
				local item = create("TextButton", {
					Size = UDim2.new(1, -6, 0, ITEM_H), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
					AutoButtonColor = false, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(value), LayoutOrder = count, Parent = listFrame,
				}, {corner(6), padding(10, 0, 0, 0)})
				item.MouseEnter:Connect(function() tween(item, {BackgroundColor3 = Theme.AccentSoft}) end)
				item.MouseLeave:Connect(function() tween(item, {BackgroundColor3 = Theme.Panel}) end)
				item.MouseButton1Click:Connect(function()
					box.Text = tostring(value)
					open = false
					relayout()
					if callback then
						task.spawn(callback, value, function(t) box.Text = t end)
					end
				end)
			end
		end
		relayout()
	end

	box.Focused:Connect(function()
		open = true
		rebuild("")
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if box:IsFocused() then rebuild(box.Text) end
	end)
	arrow.MouseButton1Click:Connect(function()
		open = not open
		if open then rebuild("") else relayout() end
	end)

	local api = {Instance = holder}
	function api:Set(text) 
		box.Text = text or ""
	end
	function api:Get() return box.Text end
	function api:Refresh() 
		open = false
		box:ReleaseFocus()
		for _, c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		count = 0
		rebuild("")
	end
	return api
end

return library