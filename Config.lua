return {
	-- identitas
	Title = "XXG",
	Subtitle = "Control Panel",
	Version = "v1.0.0",
	Updated = "November 22, 2026",
	VersionURL = "",              -- link raw file teks berisi nomor versi terbaru (kosong = tidak dicek)

	-- modul yang dimuat, sesuai urutan tab. Hapus satu nama untuk menonaktifkan modul itu.
	-- Urutan penting: Dashboard sebelum Misc, Misc sebelum Player, Settings sebelum ConfigManager.
	Modules = {"Dashboard", "Vehicle", "Games", "Misc", "Player", "Settings", "ConfigManager"},

	ConfigFolder = "ProjectControlPanel", -- folder penyimpanan config di workspace executor

	-- pengaturan awal
	Defaults = {
		Theme = "White",              -- White | Violet | Ocean | Emerald | Rose | Amber
		Transparency = 40,            -- 0 .. 90
		Language = "English",         -- English | Indonesia
		ToggleKey = Enum.KeyCode.RightBracket,
	},

	-- kartu "What's New" di Dashboard
	NewsTitle = "What's New",
	News = {
		{Kind = "update", Date = "November 22, 2026", Title = "Version 1.0.0", Text = "Improved interface, added new features and performance optimizations."},
	},

	-- tombol Discord di Settings (hapus tabel ini untuk menyembunyikan card-nya)
	Discord = {Code = "fufqtW7Zs"},

	-- halaman khusus game: [PlaceId] = {Page = nama tab, Feature = nama fitur (opsional)}
	Games = {
		[3351674303] = {Page = "Wayfort", Feature = "DrivingEmpire"},
		[891852901]  = {Page = "Greenville"},
		[54865335]   = {Page = "Westover"},
		[5232896677] = {Page = "Pacifico"},
	},
}