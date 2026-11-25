return function(L)
	L.Players = game:GetService("Players")
	L.UserInputService = game:GetService("UserInputService")
	L.TweenService = game:GetService("TweenService")
	L.RunService = game:GetService("RunService")
	L.TextService = game:GetService("TextService")
	L.LocalPlayer = L.Players.LocalPlayer

	local Theme, TweenService = L.Theme, L.TweenService

	local function create(className, props, children)
		local obj = Instance.new(className)
		local parent
		for k, v in pairs(props or {}) do
			if k == "Parent" then parent = v else obj[k] = v end
		end
		for _, child in ipairs(children or {}) do child.Parent = obj end
		if parent then obj.Parent = parent end
		return obj
	end

	local function tween(obj, props, duration)
		TweenService:Create(obj, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
	end

	local function apply(obj, props, animate)
		if animate then
			tween(obj, props)
		else
			for k, v in pairs(props) do obj[k] = v end
		end
	end

	local function corner(radius)
		return create("UICorner", {CornerRadius = UDim.new(0, radius)})
	end

	local function stroke(color, transparency)
		return create("UIStroke", {
			Color = color or Theme.Border, Thickness = 1, Transparency = transparency or 0,
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
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, pad or 0),
			FillDirection = direction or Enum.FillDirection.Vertical,
		})
	end

	local function newLabel(props)
		local p = {
			BackgroundTransparency = 1, BorderSizePixel = 0, Font = Enum.Font.Gotham,
			TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
		}
		for k, v in pairs(props) do p[k] = v end
		return create("TextLabel", p)
	end

	L.create, L.tween, L.apply, L.corner, L.stroke, L.padding, L.listLayout, L.newLabel =
		create, tween, apply, corner, stroke, padding, listLayout, newLabel
end