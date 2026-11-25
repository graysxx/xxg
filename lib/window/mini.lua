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