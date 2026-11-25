return {order = 0, page = false, build = function(ctx)
	local D = ctx.Cfg.Defaults or {}
	ctx.settings = {
		resetters = {},
		theme = ctx.UI.ThemePresets[D.Theme] and D.Theme or "White",
		transparency = D.Transparency or 40,
		language = D.Language or "English",
		key = D.ToggleKey or Enum.KeyCode.RightBracket,
	}
end}