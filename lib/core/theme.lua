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

	return function(L)
		L.Theme = {
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

		L.ThemePresets = {
			White   = {Accent = Color3.fromRGB(255, 255, 255), AccentSoft = Color3.fromRGB(46, 47, 54),  AccentLine = Color3.fromRGB(110, 112, 124)},
			Violet  = {Accent = Color3.fromRGB(167, 139, 250), AccentSoft = Color3.fromRGB(44, 38, 82),  AccentLine = Color3.fromRGB(88, 74, 160)},
			Ocean   = {Accent = Color3.fromRGB(56, 189, 248),  AccentSoft = Color3.fromRGB(20, 48, 74),  AccentLine = Color3.fromRGB(40, 110, 160)},
			Emerald = {Accent = Color3.fromRGB(52, 211, 153),  AccentSoft = Color3.fromRGB(18, 60, 48),  AccentLine = Color3.fromRGB(30, 125, 95)},
			Rose    = {Accent = Color3.fromRGB(251, 113, 133), AccentSoft = Color3.fromRGB(76, 28, 42),  AccentLine = Color3.fromRGB(165, 60, 82)},
			Amber   = {Accent = Color3.fromRGB(251, 191, 36),  AccentSoft = Color3.fromRGB(72, 54, 14),  AccentLine = Color3.fromRGB(150, 112, 20)},
		}
		L.ThemeOrder = {"White", "Violet", "Ocean", "Emerald", "Rose", "Amber"}
		L.THEME_KEYS = {"Background", "Panel", "PanelHover", "Card", "Border", "TrackOff", "Accent", "AccentSoft", "AccentLine"}
	end
end