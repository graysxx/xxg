return function(L)
	local Players, UserInputService, TweenService, RunService, TextService = L.Players, L.UserInputService, L.TweenService, L.RunService, L.TextService
	local LocalPlayer = L.LocalPlayer
	local Theme, ThemePresets, ThemeOrder, THEME_KEYS = L.Theme, L.ThemePresets, L.ThemeOrder, L.THEME_KEYS
	local create, tween, apply, corner, stroke, padding, listLayout, newLabel = L.create, L.tween, L.apply, L.corner, L.stroke, L.padding, L.listLayout, L.newLabel
	local surface, colorKey, accentGradient, accentOutline, panelBg = L.surface, L.colorKey, L.accentGradient, L.accentOutline, L.panelBg
	local makeIcon, popCard, makeDraggable, windowButton = L.makeIcon, L.popCard, L.makeDraggable, L.windowButton
	local AUTO_Y, HOVER_SCALE = L.AUTO_Y, L.HOVER_SCALE
	local MIN_W, MIN_H, MINI_BAR_H, MINIMIZED_H = L.MIN_W, L.MIN_H, L.MINI_BAR_H, L.MINIMIZED_H
	local CHIP_PAD, CHIP_ICON, CHIP_GAP = L.CHIP_PAD, L.CHIP_ICON, L.CHIP_GAP
	local library, page, section = L.library, L.page, L.section
	local Surfaces, themeHooks, S = L.Surfaces, L.themeHooks, L.S
	local newRow = L.newRow

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
					local h = measureOf(it, inv) - (it.growCur or 0) 
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
				local extra = target - natural[c]
				local growers = 0
				for _, e in ipairs(list) do
					if e.it.grow then growers = growers + 1 end
				end
				for _, e in ipairs(list) do
					local add
					if growers > 0 then
						add = e.it.grow and extra / growers or 0 
					else
						add = extra / #list
					end
					add = math.floor(add)
					if e.it.grow and e.it.growCur ~= add then
						e.it.growCur = add
						e.it.grow(add)
					end
					e.it.frame.Size = UDim2.new(1, 0, 0, math.floor(e.h + add))
				end
			end
		end
		return true
	end
end