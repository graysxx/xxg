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