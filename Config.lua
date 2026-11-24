return {
	Title = "XXG",
	Subtitle = "Control Panel",
	Version = "v1.0.0",
	Updated = "November 22, 2026",
	VersionURL = "",

	Modules = {"Dashboard", "Vehicle", "AutoDrive", "Misc", "Player", "Target", "Noclip", "Spectate", "Emotes", "Settings", "ConfigManager"},

	ConfigFolder = "XXGControlPanel", 

	Defaults = {
		Theme = "White",              -- White | Violet | Ocean | Emerald | Rose | Amber
		Transparency = 40,            -- 0 .. 90
		Language = "English",         -- English | Indonesia
		ToggleKey = Enum.KeyCode.RightBracket,
	},

	NewsTitle = "What's New",
	News = {
		{Kind = "update", Date = "November 22, 2026", Title = "Version 1.0.0", Text = "Improved interface, added new features and performance optimizations."},
	},

	Discord = {Code = "fufqtW7Zs"},
}